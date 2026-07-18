# Prove that app boot rejects a mixed generation before any RDS is deserialized.
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[[1L]]),
                            winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}

main <- function() {
  setwd_repo_root()
  source("scripts/manifest_files.R", local = TRUE)
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("jsonlite is required for the runtime-integrity fixtures", call. = FALSE)

  original_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  fixture_parent <- tempfile("cascade-runtime-integrity-")
  dir.create(fixture_parent, recursive = TRUE)
  on.exit({
    setwd(original_root)
    unlink(fixture_parent, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  copy_fixture <- function(label) {
    root <- file.path(fixture_parent, label)
    dir.create(root, recursive = TRUE)
    for (path in c(DEPLOY_APP_FILES, "manifest.json")) {
      target <- file.path(root, path)
      dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
      if (!file.copy(file.path(original_root, path), target,
                     overwrite = TRUE, copy.date = TRUE))
        stop(sprintf("could not copy runtime-integrity fixture: %s", path),
             call. = FALSE)
    }
    root
  }

  write_raw <- function(path, bytes) {
    con <- file(path, open = "wb")
    on.exit(close(con), add = TRUE)
    writeBin(bytes, con)
  }

  append_raw <- function(path, bytes) {
    con <- file(path, open = "ab")
    on.exit(close(con), add = TRUE)
    writeBin(bytes, con)
  }

  write_json <- function(path, value) {
    jsonlite::write_json(value, path, auto_unbox = TRUE, pretty = TRUE,
                         null = "null", digits = NA)
  }

  read_manifest <- function(root) {
    jsonlite::fromJSON(file.path(root, "manifest.json"), simplifyVector = FALSE)
  }

  run_guard <- function(root) {
    read_called <- FALSE
    env <- new.env(parent = globalenv())
    env$readRDS <- function(...) {
      read_called <<- TRUE
      stop("readRDS sentinel was invoked", call. = FALSE)
    }
    old_wd <- setwd(root)
    failure <- tryCatch({
      sys.source("global.R", envir = env, keep.source = FALSE)
      NULL
    }, error = function(e) e)
    setwd(old_wd)
    list(failure = failure, read_called = read_called)
  }

  assert_rejected_before_rds <- function(label, mutate, expected) {
    root <- copy_fixture(label)
    mutate(root)
    result <- run_guard(root)
    failure <- result$failure
    if (!inherits(failure, "error") ||
        !grepl(expected, conditionMessage(failure), fixed = TRUE))
      stop(sprintf(
        "fixture '%s' was not rejected as expected: %s",
        label,
        if (inherits(failure, "error")) conditionMessage(failure) else "boot succeeded"
      ), call. = FALSE)
    if (isTRUE(result$read_called))
      stop(sprintf("fixture '%s' reached readRDS before rejection", label),
           call. = FALSE)
    invisible(TRUE)
  }

  assert_rejected_before_rds(
    "missing-manifest",
    function(root) unlink(file.path(root, "manifest.json"), force = TRUE),
    "manifest.json is missing, linked, or not a regular file"
  )
  assert_rejected_before_rds(
    "truncated-manifest",
    function(root) write_raw(file.path(root, "manifest.json"), charToRaw("{")),
    "manifest.json is malformed"
  )
  assert_rejected_before_rds(
    "scalar-manifest-root",
    function(root) write_raw(file.path(root, "manifest.json"), charToRaw("1")),
    "manifest root is malformed or differs from the approved schema"
  )
  assert_rejected_before_rds(
    "duplicate-root-key",
    function(root) write_raw(
      file.path(root, "manifest.json"),
      charToRaw(paste0(
        '{"version":1,"locale":"en_US","platform":"4.5.2",',
        '"metadata":{},"packages":{},"files":{},"files":{},"users":null}'
      ))
    ),
    "manifest root is malformed or differs from the approved schema"
  )
  assert_rejected_before_rds(
    "duplicate-file-key",
    function(root) write_raw(
      file.path(root, "manifest.json"),
      charToRaw(paste0(
        '{"version":1,"locale":"en_US","platform":"4.5.2",',
        '"metadata":{},"packages":{},"files":{',
        '"global.R":{"checksum":"', strrep("0", 32L), '"},',
        '"global.R":{"checksum":"', strrep("0", 32L), '"}',
        '},"users":null}'
      ))
    ),
    "manifest file records are malformed"
  )
  assert_rejected_before_rds(
    "malformed-checksum",
    function(root) {
      manifest <- read_manifest(root)
      manifest$files[["global.R"]]$checksum <- "not-an-md5"
      write_json(file.path(root, "manifest.json"), manifest)
    },
    "manifest checksum record is malformed for global.R"
  )
  assert_rejected_before_rds(
    "missing-file-record",
    function(root) {
      manifest <- read_manifest(root)
      manifest$files[["www/styles.css"]] <- NULL
      write_json(file.path(root, "manifest.json"), manifest)
    },
    "manifest file surface differs"
  )
  assert_rejected_before_rds(
    "extra-file-record",
    function(root) {
      manifest <- read_manifest(root)
      manifest$files[["unexpected.txt"]] <- list(checksum = strrep("0", 32L))
      write_json(file.path(root, "manifest.json"), manifest)
    },
    "manifest file surface differs"
  )

  generated <- c(
    "data/cascade.rds",
    "data/search_index.rds",
    "data/cascade_meta.rds",
    "data/neon-cascade-codebook.csv"
  )
  for (i in seq_along(generated)) {
    path <- generated[[i]]
    assert_rejected_before_rds(
      sprintf("mutated-generated-%d", i),
      local({
        target <- path
        function(root) append_raw(file.path(root, target), as.raw(0L))
      }),
      sprintf("checksum mismatch for %s", path)
    )
  }

  # Build a second coherent, byte-distinct family with identical R objects,
  # then simulate every cut point in the production data-first/manifest-last
  # promotion order. Only all-old and all-new may reach the readRDS sentinel.
  alternate_root <- copy_fixture("alternate-coherent-family")
  for (path in generated[grepl("[.]rds$", generated)]) {
    value <- readRDS(file.path(alternate_root, path))
    saveRDS(value, file.path(alternate_root, path),
            ascii = FALSE, version = 2L, compress = "gzip")
  }
  append_raw(
    file.path(alternate_root, "data", "neon-cascade-codebook.csv"),
    charToRaw("\n# coherent alternate serialization fixture\n")
  )
  alternate_manifest <- read_manifest(alternate_root)
  for (path in generated) {
    alternate_manifest$files[[path]]$checksum <- unname(tools::md5sum(
      file.path(alternate_root, path)
    ))
  }
  write_json(file.path(alternate_root, "manifest.json"), alternate_manifest)

  promotion_order <- c(generated, "manifest.json")
  for (cut in 0:length(promotion_order)) {
    cut_root <- copy_fixture(sprintf("promotion-cut-%d", cut))
    if (cut > 0L) {
      for (path in promotion_order[seq_len(cut)]) {
        if (!file.copy(file.path(alternate_root, path), file.path(cut_root, path),
                       overwrite = TRUE, copy.date = TRUE))
          stop(sprintf("could not prepare promotion cut %d at %s", cut, path),
               call. = FALSE)
      }
    }
    result <- run_guard(cut_root)
    coherent <- cut %in% c(0L, length(promotion_order))
    if (coherent) {
      if (!isTRUE(result$read_called) || !inherits(result$failure, "error") ||
          !grepl("Cannot read data/cascade.rds: readRDS sentinel was invoked",
                 conditionMessage(result$failure), fixed = TRUE))
        stop(sprintf("coherent promotion cut %d did not pass the integrity guard", cut),
             call. = FALSE)
    } else {
      if (isTRUE(result$read_called) || !inherits(result$failure, "error") ||
          !grepl("Runtime deploy integrity check failed: checksum mismatch",
                 conditionMessage(result$failure), fixed = TRUE))
        stop(sprintf("mixed promotion cut %d was not rejected before readRDS", cut),
             call. = FALSE)
    }
  }

  cat(sprintf(
    paste0(
      "RUNTIME INTEGRITY FAULT TESTS PASSED: %d malformed/mutated fixtures ",
      "and %d ordered promotion cuts verified before RDS load.\n"
    ),
    8L + length(generated), length(promotion_order) + 1L
  ))
}

main()
