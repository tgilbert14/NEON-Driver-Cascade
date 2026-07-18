# ===========================================================================
# Rebuild every deployable cascade artifact in an isolated generation.
#
# Nothing in the working tree changes until cascade -> search -> companion meta
# -> contracts -> manifest -> manifest verification -> integrity fault tests ->
# application smoke -> final manifest verification all succeed in staging.
# Promotion is checksum-verified and rollback-protected; the manifest is promoted
# last, and app boot verifies its full file map before sourcing local code or
# deserializing any RDS.
# ===========================================================================
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1]), winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}

main <- function() {
  original_wd <- getwd()
  ROOT <- setwd_repo_root()

  # A repo-local directory creation is the single atomic operation that elects
  # one publisher. Without it, two individually valid rebuilds can interleave
  # their backup, promotion, and rollback phases into a mixed artifact family.
  lock_dir <- file.path(ROOT, ".cascade-rebuild.lock")
  lock_host <- unname(Sys.info()[["nodename"]])
  if (is.null(lock_host) || is.na(lock_host) || !nzchar(lock_host)) lock_host <- "unknown-host"
  lock_token <- paste(lock_host, Sys.getpid(),
                      format(Sys.time(), "%Y%m%dT%H%M%OS6Z", tz = "UTC"), sep = "|")
  if (!dir.create(lock_dir, showWarnings = FALSE)) {
    owner_path <- file.path(lock_dir, "owner.txt")
    owner <- if (file.exists(owner_path)) {
      tryCatch(paste(readLines(owner_path, warn = FALSE, encoding = "UTF-8"),
                     collapse = "; "), error = function(e) "unreadable")
    } else "unknown"
    stop(sprintf("another cascade rebuild owns '%s' (owner: %s). If no rebuild is running, remove this stale lock explicitly.",
                 lock_dir, owner), call. = FALSE)
  }
  owner_path <- file.path(lock_dir, "owner.txt")
  owner_ok <- tryCatch({
    writeLines(c(lock_token,
                 paste0("root=", ROOT),
                 paste0("started_utc=", format(Sys.time(), "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"))),
               owner_path, useBytes = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (!isTRUE(owner_ok)) {
    unlink(lock_dir, recursive = TRUE, force = TRUE)
    stop("could not record cascade rebuild lock ownership", call. = FALSE)
  }
  on.exit({
    recorded <- if (file.exists(owner_path))
      tryCatch(readLines(owner_path, warn = FALSE, encoding = "UTF-8"),
               error = function(e) character()) else character()
    if (length(recorded) && identical(recorded[1L], lock_token)) {
      unlink(lock_dir, recursive = TRUE, force = TRUE)
      if (dir.exists(lock_dir))
        warning("CRITICAL: could not remove the cascade rebuild lock", call. = FALSE)
    } else if (dir.exists(lock_dir)) {
      warning("cascade rebuild lock ownership changed; refusing to remove it", call. = FALSE)
    }
  }, add = TRUE)
  artifacts <- c(
    "data/cascade.rds",
    "data/search_index.rds",
    "data/cascade_meta.rds",
    "data/neon-cascade-codebook.csv",
    "manifest.json")
  if (!identical(tail(artifacts, 1L), "manifest.json"))
    stop("promotion invariant violated: manifest.json must be last", call. = FALSE)

  # Capture the complete code/deploy surface as raw bytes before staging. The
  # generation is written from this in-memory snapshot, not from live files,
  # and promotion is refused if any path or byte changes while children run.
  code_surface <- function() {
    nested <- unlist(lapply(c("R", "scripts", "www"), function(dir) {
      root <- file.path(ROOT, dir)
      if (!dir.exists(root)) return(character())
      found <- list.files(root, recursive = TRUE, all.files = TRUE,
                          full.names = FALSE, include.dirs = FALSE, no.. = TRUE)
      found <- gsub("\\\\", "/", found)
      found <- found[!grepl("(^|/)__pycache__(/|$)|[.]py[cod]$", found,
                             ignore.case = TRUE)]
      file.path(dir, found)
    }), use.names = FALSE)
    optional_top <- c("global.R", "ui.R", "server.R", ".gitattributes",
                      ".Rprofile", "renv.lock")
    top <- optional_top[file.exists(file.path(ROOT, optional_top))]
    paths <- sort(unique(gsub("\\\\", "/", c(nested, top))), method = "radix")
    absolute <- file.path(ROOT, paths)
    info <- file.info(absolute)
    links <- Sys.readlink(absolute)
    if (!length(paths) || any(!file.exists(absolute)) || anyNA(info$isdir) ||
        any(info$isdir) || any(!is.na(links) & nzchar(links)))
      stop("build code surface contains a missing, directory, or symbolic-link entry",
           call. = FALSE)
    paths
  }
  read_raw_file <- function(path) {
    info <- file.info(path)
    if (nrow(info) != 1L || is.na(info$size) || info$isdir)
      stop(sprintf("cannot read regular file '%s'", path), call. = FALSE)
    con <- file(path, open = "rb")
    on.exit(close(con), add = TRUE)
    readBin(con, what = "raw", n = info$size)
  }
  assert_regular_files <- function(paths, label, allow_missing = FALSE) {
    exists <- file.exists(paths)
    links <- Sys.readlink(paths)
    linked <- !is.na(links) & nzchar(links)
    present <- exists | dir.exists(paths) | linked
    if (!allow_missing && any(!present))
      stop(sprintf("%s contains missing path(s): %s", label,
                   paste(paths[!present], collapse = ", ")), call. = FALSE)
    inspect <- present
    info <- file.info(paths)
    unsafe <- inspect & (is.na(info$isdir) | info$isdir | linked |
                         is.na(info$size) | !is.finite(info$size))
    if (any(unsafe))
      stop(sprintf("%s contains a directory, symbolic link, or non-regular path: %s",
                   label, paste(paths[unsafe], collapse = ", ")), call. = FALSE)
    invisible(TRUE)
  }

  code_paths <- code_surface()
  code_snapshot <- stats::setNames(
    lapply(file.path(ROOT, code_paths), read_raw_file), code_paths)
  assert_code_unchanged <- function() {
    current <- code_surface()
    if (!identical(current, names(code_snapshot)))
      stop("build code inventory changed during isolated generation", call. = FALSE)
    same <- vapply(current, function(path)
      identical(read_raw_file(file.path(ROOT, path)), code_snapshot[[path]]),
      logical(1))
    if (!all(same))
      stop(sprintf("build code changed during isolated generation: %s",
                   paste(current[!same], collapse = ", ")), call. = FALSE)
    invisible(TRUE)
  }

  generation_env_names <- c("CASCADE_GENERATION_ROOT", "CASCADE_GENERATION_TOKEN",
                            "CASCADE_ROOT")
  generation_env_before <- Sys.getenv(generation_env_names, unset = NA_character_)

  stage_root <- tempfile("cascade-generation-")
  dir.create(stage_root, recursive = TRUE)
  backup_root <- tempfile("cascade-promotion-backup-")
  dir.create(backup_root, recursive = TRUE)
  promotion_files <- stats::setNames(character(length(artifacts)), artifacts)
  existed <- stats::setNames(rep(FALSE, length(artifacts)), artifacts)
  previous_md5 <- stats::setNames(rep(NA_character_, length(artifacts)), artifacts)
  promotion_started <- FALSE
  promotion_complete <- FALSE
  backup_name <- function(path) file.path(backup_root, gsub("[/\\\\]", "__", path))

  on.exit({
    try(setwd(original_wd), silent = TRUE)
    for (name in generation_env_names) {
      previous <- unname(generation_env_before[[name]])
      if (is.na(previous)) Sys.unsetenv(name)
      else do.call(Sys.setenv, stats::setNames(list(previous), name))
    }

    if (promotion_started && !promotion_complete) {
      message("Artifact promotion failed; restoring the previous artifact family.")
      restore_failed <- character()
      for (path in artifacts) {
        target <- file.path(ROOT, path)
        ok <- if (isTRUE(existed[[path]])) {
          copied <- file.copy(backup_name(path), target, overwrite = TRUE, copy.date = TRUE)
          isTRUE(copied) && identical(unname(tools::md5sum(target)), previous_md5[[path]])
        } else if (file.exists(target)) {
          unlink(target, force = TRUE)
          !file.exists(target)
        } else TRUE
        if (!isTRUE(ok)) restore_failed <- c(restore_failed, path)
      }
      if (length(restore_failed))
        warning(sprintf("CRITICAL: failed to restore artifact(s): %s",
                        paste(restore_failed, collapse = ", ")), call. = FALSE)
    }
    pending <- unname(promotion_files[nzchar(promotion_files)])
    if (length(pending)) unlink(pending, force = TRUE)
    unlink(c(stage_root, backup_root), recursive = TRUE, force = TRUE)
  }, add = TRUE, after = FALSE)

  copy_one <- function(from, to) {
    dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(from, to, overwrite = TRUE, copy.date = TRUE))
      stop(sprintf("could not stage '%s'", from), call. = FALSE)
  }

  write_snapshot_file <- function(relative, bytes) {
    target <- file.path(stage_root, relative)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    con <- file(target, open = "wb")
    ok <- tryCatch({ writeBin(bytes, con); TRUE },
                   error = function(e) FALSE, finally = close(con))
    if (!isTRUE(ok))
      stop(sprintf("could not write staged code snapshot '%s'", relative), call. = FALSE)
    invisible(TRUE)
  }

  for (path in names(code_snapshot)) write_snapshot_file(path, code_snapshot[[path]])
  if (!dir.create(file.path(stage_root, "data"), showWarnings = FALSE))
    stop("could not create empty staged data directory", call. = FALSE)

  generation_token <- paste(
    basename(tempfile("cascade-capability-")), Sys.getpid(),
    format(Sys.time(), "%Y%m%d%H%M%OS6", tz = "UTC"), sep = "-")
  write_snapshot_file(".cascade-generation-token",
                      charToRaw(enc2utf8(paste0(generation_token, "\n"))))
  Sys.setenv(CASCADE_GENERATION_ROOT = normalizePath(stage_root, winslash = "/"),
             CASCADE_GENERATION_TOKEN = generation_token)

  rscript <- file.path(R.home("bin"), "Rscript")
  run_stage <- function(label, script) {
    cat(sprintf("\n===== %s =====\n", label))
    status <- system2(rscript, c("--vanilla", shQuote(script)))
    if (!identical(status, 0L))
      stop(sprintf("%s failed with exit status %s", label, status), call. = FALSE)
    invisible(TRUE)
  }

  # Stage 1 publishes this exact marker only after all seven recorded Git trees
  # have been safely extracted and byte-verified. Later raw-source oracles must
  # read that same immutable tree, never the live worktrees checked before build.
  activate_source_snapshot <- function() {
    marker <- file.path(stage_root, ".cascade-source-snapshot-root")
    assert_regular_files(marker, "immutable source snapshot marker")
    if (!identical(read_raw_file(marker),
                   charToRaw(".cascade-source-snapshot\n")))
      stop("immutable source snapshot marker is malformed", call. = FALSE)
    snapshot_root <- file.path(stage_root, ".cascade-source-snapshot")
    root_info <- file.info(snapshot_root)
    root_link <- Sys.readlink(snapshot_root)
    if (!dir.exists(snapshot_root) || is.na(root_info$isdir) || !root_info$isdir ||
        (!is.na(root_link) && nzchar(root_link)))
      stop("immutable source snapshot root is missing, linked, or not a directory",
           call. = FALSE)
    snapshot_root <- normalizePath(snapshot_root, winslash = "/", mustWork = TRUE)
    stage_path <- normalizePath(stage_root, winslash = "/", mustWork = TRUE)
    path_key <- function(path)
      if (.Platform$OS.type == "windows") tolower(path) else path
    if (!identical(path_key(dirname(snapshot_root)), path_key(stage_path)))
      stop("immutable source snapshot escaped the staged generation", call. = FALSE)
    repos <- c(
      "App-NEON-Small-Mammal-Tracker", "NEON-Plant-Diversity",
      "NEON-Veg-Structure", "NEON-Breeding-Birds",
      "NEON-Plant-Phenology", "NEON-Mosquito-Pulse",
      "NEON-Ground-Beetle-Tracker")
    repo_paths <- file.path(snapshot_root, repos)
    repo_info <- file.info(repo_paths)
    repo_links <- Sys.readlink(repo_paths)
    if (any(!dir.exists(repo_paths)) || anyNA(repo_info$isdir) ||
        any(!repo_info$isdir) || any(!is.na(repo_links) & nzchar(repo_links)))
      stop("immutable source snapshot has a missing, linked, or invalid repository directory",
           call. = FALSE)
    resolved <- normalizePath(repo_paths, winslash = "/", mustWork = TRUE)
    if (any(vapply(dirname(resolved), function(path)
          !identical(path_key(path), path_key(snapshot_root)), logical(1))) ||
        anyDuplicated(path_key(resolved)))
      stop("immutable source repository layout escaped its snapshot root",
           call. = FALSE)
    Sys.setenv(CASCADE_ROOT = snapshot_root)
    invisible(snapshot_root)
  }

  setwd(stage_root)
  run_stage("1/9 build cascade bundle", "scripts/build_cascade.R")
  activate_source_snapshot()
  run_stage("2/9 build search index", "scripts/build_search_index.R")
  run_stage("3/9 build companion meta-analysis", "scripts/cascade_meta.R")
  run_stage("4/9 run artifact contracts", "scripts/test_helpers.R")
  run_stage("5/9 write lean deploy manifest", "scripts/write_manifest.R")
  run_stage("6/9 verify complete deploy manifest", "scripts/verify_manifest.R")
  run_stage("7/9 reject malformed and mixed runtime generations", "scripts/test_boot_integrity.R")
  run_stage("8/9 load the exact staged application", "scripts/smoke_app.R")
  run_stage("9/9 reverify manifest after application smoke", "scripts/verify_manifest.R")
  setwd(original_wd)

  missing <- artifacts[!file.exists(file.path(stage_root, artifacts))]
  if (length(missing))
    stop(sprintf("validated generation omitted artifact(s): %s", paste(missing, collapse = ", ")),
         call. = FALSE)
  assert_regular_files(file.path(stage_root, artifacts), "validated generation")
  stage_md5 <- unname(tools::md5sum(file.path(stage_root, artifacts)))
  if (anyNA(stage_md5)) stop("could not fingerprint the validated generation", call. = FALSE)

  assert_code_unchanged()
  assert_regular_files(file.path(ROOT, artifacts), "live artifact family",
                       allow_missing = TRUE)

  # Copy each validated output to a same-volume temporary file before changing
  # any live target. A failed copy cannot truncate a deployed artifact.
  for (i in seq_along(artifacts)) {
    path <- artifacts[i]
    target <- file.path(ROOT, path)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    pending <- tempfile(paste0(".", basename(path), "-pending-"), tmpdir = dirname(target))
    copy_one(file.path(stage_root, path), pending)
    if (!identical(unname(tools::md5sum(pending)), stage_md5[i]))
      stop(sprintf("staged promotion checksum mismatch for '%s'", path), call. = FALSE)
    promotion_files[[path]] <- pending
  }

  existed <- stats::setNames(file.exists(file.path(ROOT, artifacts)), artifacts)
  previous_md5[existed] <- unname(tools::md5sum(file.path(ROOT, artifacts[existed])))
  if (anyNA(previous_md5[existed]))
    stop("could not fingerprint the live artifact family before promotion", call. = FALSE)
  for (path in artifacts[existed]) {
    copy_one(file.path(ROOT, path), backup_name(path))
    if (!identical(unname(tools::md5sum(backup_name(path))), previous_md5[[path]]))
      stop(sprintf("backup checksum mismatch for '%s'", path), call. = FALSE)
  }

  promotion_started <- TRUE
  for (path in artifacts)
    if (!file.copy(promotion_files[[path]], file.path(ROOT, path),
                   overwrite = TRUE, copy.date = TRUE))
      stop(sprintf("could not promote validated artifact '%s'", path), call. = FALSE)

  promoted_md5 <- unname(tools::md5sum(file.path(ROOT, artifacts)))
  if (!identical(promoted_md5, stage_md5))
    stop("promoted artifact family does not match the validated generation", call. = FALSE)

  # A staged manifest is useful only if it also verifies against the still-live
  # deploy code after promotion. Keep rollback armed through this final check.
  setwd(ROOT)
  cat("\n===== post-promotion root manifest verification =====\n")
  root_status <- system2(rscript, c("--vanilla", shQuote("scripts/verify_manifest.R")))
  if (!identical(root_status, 0L))
    stop(sprintf("post-promotion manifest verification failed with exit status %s", root_status),
         call. = FALSE)
  assert_code_unchanged()
  cat(sprintf("\nCOMPLETE: validated artifact generation promoted to %s\n", ROOT))
  promotion_complete <- TRUE
}

main()
