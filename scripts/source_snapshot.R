# ===========================================================================
# Immutable sibling-source materialization for the transactional cascade build.
#
# The caller first records and validates live sibling provenance and inventories.
# This module then reads only the recorded Git commit objects: it archives the
# approved data subtrees, validates the tar boundary before extraction, and
# verifies every extracted RDS byte against the recorded inventory.  The
# resulting sibling layout is kept inside the staged app so later contract tests
# can consume the exact same source snapshot as the builder.
# ===========================================================================

CASCADE_SOURCE_SNAPSHOT_METHOD <- "git-archive-recorded-commit-v1"

.cascade_snapshot_fail <- function(fmt, ...) {
  stop(sprintf(fmt, ...), call. = FALSE)
}

.cascade_snapshot_products <- c(
  "mammal", "plant", "veg", "bird", "phe", "mosq", "beetle")

.cascade_snapshot_path_key <- function(path) {
  path <- gsub("\\\\", "/", path)
  if (.Platform$OS.type == "windows") tolower(path) else path
}

.cascade_snapshot_same_path <- function(left, right) {
  identical(.cascade_snapshot_path_key(left),
            .cascade_snapshot_path_key(right))
}

.cascade_snapshot_linked <- function(path) {
  link <- Sys.readlink(path)
  !is.na(link) & nzchar(link)
}

.cascade_snapshot_exists <- function(path) {
  file.exists(path) || dir.exists(path) || .cascade_snapshot_linked(path)
}

.cascade_snapshot_safe_relative <- function(path, allow_trailing_slash = FALSE) {
  if (!is.character(path) || !length(path) || anyNA(path) ||
      any(!nzchar(path)) || any(!validUTF8(path))) {
    return(rep(FALSE, length(path)))
  }
  original <- path
  if (allow_trailing_slash) path <- sub("/$", "", path)
  segments <- strsplit(path, "/", fixed = TRUE)
  vapply(seq_along(path), function(i) {
    value <- path[i]
    parts <- segments[[i]]
    trailing_ok <- !endsWith(original[i], "/") ||
      (allow_trailing_slash && !endsWith(sub("/$", "", original[i]), "/"))
    nzchar(value) && trailing_ok &&
      !startsWith(value, "/") &&
      !grepl("\\\\|:|[[:cntrl:]]", value) &&
      !grepl("//", value, fixed = TRUE) &&
      length(parts) > 0L && all(nzchar(parts)) &&
      !any(parts %in% c(".", ".."))
  }, logical(1))
}

.cascade_snapshot_read_raw <- function(path) {
  info <- file.info(path)
  if (nrow(info) != 1L || is.na(info$size) || info$isdir ||
      .cascade_snapshot_linked(path)) {
    .cascade_snapshot_fail("cannot read non-regular snapshot work file '%s'",
                           path)
  }
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, what = "raw", n = info$size)
}

.cascade_snapshot_split_nul <- function(bytes, label) {
  if (!length(bytes)) return(character())
  nul <- which(as.integer(bytes) == 0L)
  if (!length(nul) || tail(nul, 1L) != length(bytes))
    .cascade_snapshot_fail("%s is not a complete NUL-delimited Git response",
                           label)
  starts <- c(1L, head(nul, -1L) + 1L)
  ends <- nul - 1L
  values <- Map(function(first, last) {
    if (last < first) return("")
    rawToChar(bytes[first:last])
  }, starts, ends)
  unlist(values, use.names = FALSE)
}

.cascade_snapshot_parse_tree <- function(bytes, product) {
  records <- .cascade_snapshot_split_nul(
    bytes, sprintf("%s ls-tree output", product))
  if (!length(records))
    .cascade_snapshot_fail("recorded %s commit has an empty data tree", product)

  parsed <- lapply(records, function(record) {
    tab <- regexpr("\t", record, fixed = TRUE)[1L]
    if (is.na(tab) || tab < 1L)
      .cascade_snapshot_fail("recorded %s tree contains a malformed entry",
                             product)
    header <- substr(record, 1L, tab - 1L)
    path <- substr(record, tab + 1L, nchar(record, type = "bytes"))
    fields <- strsplit(header, " ", fixed = TRUE)[[1L]]
    if (length(fields) != 3L ||
        !grepl("^[0-9]{6}$", fields[1L]) ||
        !grepl("^[a-z]+$", fields[2L]) ||
        !grepl("^[0-9a-f]{40}$", fields[3L])) {
      .cascade_snapshot_fail("recorded %s tree contains malformed metadata",
                             product)
    }
    c(mode = fields[1L], type = fields[2L],
      object = fields[3L], path = path)
  })
  tree <- as.data.frame(do.call(rbind, parsed), stringsAsFactors = FALSE)

  if (any(!.cascade_snapshot_safe_relative(tree$path)) ||
      anyDuplicated(tree$path)) {
    .cascade_snapshot_fail(
      "recorded %s tree contains an unsafe or duplicate path", product)
  }
  allowed_root <- tree$path == "data/sites" |
    startsWith(tree$path, "data/sites/")
  if (identical(product, "mammal")) {
    allowed_root <- allowed_root | tree$path == "data/env" |
      startsWith(tree$path, "data/env/")
  }
  if (any(!allowed_root))
    .cascade_snapshot_fail(
      "recorded %s tree escaped the requested archive roots", product)

  # A Git symlink is a blob with mode 120000 and a submodule is a commit with
  # mode 160000.  Reject both before tar extraction, along with every other
  # non-regular tree entry.  Executable regular files remain safe.
  if (any(tree$type != "blob") ||
      any(!tree$mode %in% c("100644", "100755"))) {
    .cascade_snapshot_fail(
      "recorded %s archive subtree contains a symlink, submodule, or non-regular entry",
      product)
  }
  tree
}

.cascade_snapshot_parse_octal <- function(field, label) {
  values <- as.integer(field)
  if (length(values) && bitwAnd(values[1L], 128L) != 0L)
    .cascade_snapshot_fail("%s uses an unsupported base-256 tar integer", label)
  values <- values[values != 0L]
  text <- trimws(if (length(values)) rawToChar(as.raw(values)) else "")
  if (!nzchar(text)) return(0)
  if (!grepl("^[0-7]+$", text))
    .cascade_snapshot_fail("%s is not a valid tar octal integer", label)
  digits <- utf8ToInt(text) - utf8ToInt("0")
  value <- 0
  for (digit in digits) value <- value * 8 + digit
  if (!is.finite(value) || value < 0 || value > 2^53)
    .cascade_snapshot_fail("%s exceeds the exact supported tar range", label)
  value
}

.cascade_snapshot_validate_tar_types <- function(tarfile, product) {
  info <- file.info(tarfile)
  if (nrow(info) != 1L || is.na(info$size) || info$isdir ||
      info$size < 1024 || info$size %% 512 != 0 ||
      .cascade_snapshot_linked(tarfile)) {
    .cascade_snapshot_fail("%s git archive is missing or not a regular tar file",
                           product)
  }

  con <- file(tarfile, open = "rb")
  on.exit(close(con), add = TRUE)
  total <- as.numeric(info$size)
  offset <- 0
  saw_member <- FALSE
  saw_trailer <- FALSE

  while (offset < total) {
    header <- readBin(con, what = "raw", n = 512L)
    if (length(header) != 512L)
      .cascade_snapshot_fail("%s tar archive has a truncated header", product)
    offset <- offset + 512

    if (all(as.integer(header) == 0L)) {
      second <- readBin(con, what = "raw", n = 512L)
      if (length(second) != 512L || any(as.integer(second) != 0L))
        .cascade_snapshot_fail(
          "%s tar archive lacks the required two-block trailer", product)
      offset <- offset + 512
      while (offset < total) {
        chunk <- readBin(con, what = "raw",
                         n = min(65536, total - offset))
        if (!length(chunk) || any(as.integer(chunk) != 0L))
          .cascade_snapshot_fail(
            "%s tar archive has non-zero data after its trailer", product)
        offset <- offset + length(chunk)
      }
      saw_trailer <- TRUE
      break
    }

    saw_member <- TRUE
    stored_checksum <- .cascade_snapshot_parse_octal(
      header[149:156], sprintf("%s tar checksum", product))
    checksum_header <- header
    checksum_header[149:156] <- as.raw(rep(32L, 8L))
    actual_checksum <- sum(as.integer(checksum_header))
    if (!identical(as.numeric(stored_checksum), as.numeric(actual_checksum)))
      .cascade_snapshot_fail("%s tar archive has an invalid header checksum",
                             product)

    type_value <- as.integer(header[157L])
    type <- if (type_value == 0L) "" else rawToChar(header[157L])
    # x/g are PAX metadata records emitted by Git for portable long paths.
    # Links and every device/special member type are deliberately rejected.
    if (!type %in% c("", "0", "5", "x", "g"))
      .cascade_snapshot_fail(
        "%s tar archive contains forbidden member type '%s'",
        product, type)

    payload <- .cascade_snapshot_parse_octal(
      header[125:136], sprintf("%s tar member size", product))
    padded <- ceiling(payload / 512) * 512
    if (!is.finite(padded) || offset + padded > total)
      .cascade_snapshot_fail("%s tar archive has a truncated payload", product)
    if (padded > 0) {
      offset <- offset + padded
      seek(con, where = offset, origin = "start")
    }
  }

  if (!saw_member || !saw_trailer)
    .cascade_snapshot_fail("%s tar archive is empty or unterminated", product)
  invisible(TRUE)
}

.cascade_snapshot_git_status <- function(result) {
  if (is.numeric(result) && length(result) == 1L && !is.na(result))
    return(as.integer(result))
  status <- attr(result, "status")
  if (is.null(status)) 0L else as.integer(status[1L])
}

.cascade_snapshot_write_lf <- function(path, line) {
  bytes <- charToRaw(enc2utf8(paste0(line, "\n")))
  con <- file(path, open = "wb")
  ok <- tryCatch({
    writeBin(bytes, con)
    TRUE
  }, error = function(e) FALSE, finally = close(con))
  if (!isTRUE(ok))
    .cascade_snapshot_fail("could not write source snapshot marker")
  invisible(TRUE)
}

# Materialize and return an immutable sibling source tree.
#
# live_app is the named seven-product path list recorded by build_cascade.R.
# source_products must contain product/repo/commit/clean/n_site_files.
# source_inputs must contain product/relative_path/md5 and exactly one byte-size
# column named bytes, byte_size, or size_bytes.
# git_system2 is the caller's HOME-stabilized system2 wrapper.
#
# The staged app is CASCADE_GENERATION_ROOT when set, otherwise getwd().  The
# caller owns the completed snapshot and removes it only with the whole staged
# generation after source-backed tests have finished.
cascade_materialize_source_snapshot <- function(
    live_app, source_products, source_inputs, git_system2) {
  if (!is.function(git_system2))
    .cascade_snapshot_fail("git_system2 must be a function")

  staged_app <- Sys.getenv("CASCADE_GENERATION_ROOT", unset = "")
  if (!nzchar(staged_app)) staged_app <- getwd()
  staged_app <- normalizePath(staged_app, winslash = "/", mustWork = TRUE)
  current <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  if (!.cascade_snapshot_same_path(staged_app, current))
    .cascade_snapshot_fail(
      "source snapshots must be materialized from the staged app root")
  stage_info <- file.info(staged_app)
  if (is.na(stage_info$isdir) || !stage_info$isdir ||
      .cascade_snapshot_linked(staged_app))
    .cascade_snapshot_fail("staged app root is not a canonical real directory")

  required_products <- c(
    "product", "repo", "commit", "clean", "n_site_files")
  if (!is.data.frame(source_products) ||
      length(setdiff(required_products, names(source_products))) ||
      nrow(source_products) != length(.cascade_snapshot_products) ||
      anyNA(source_products$product) ||
      anyDuplicated(as.character(source_products$product)) ||
      !setequal(as.character(source_products$product),
                .cascade_snapshot_products)) {
    .cascade_snapshot_fail(
      "source_products must contain exactly the seven unique required products")
  }
  source_products <- source_products[
    match(.cascade_snapshot_products, as.character(source_products$product)),
    , drop = FALSE]
  rownames(source_products) <- NULL

  if (!is.list(live_app) || is.null(names(live_app)) ||
      anyNA(names(live_app)) || anyDuplicated(names(live_app)) ||
      !setequal(names(live_app), .cascade_snapshot_products)) {
    .cascade_snapshot_fail(
      "live_app must name exactly the seven unique required products")
  }
  live_app <- live_app[.cascade_snapshot_products]

  commits <- as.character(source_products$commit)
  repos <- as.character(source_products$repo)
  if (anyNA(commits) || any(!grepl("^[0-9a-f]{40}$", commits)))
    .cascade_snapshot_fail(
      "every source snapshot commit must be exactly 40 lowercase hexadecimal characters")
  if (anyNA(repos) || any(!nzchar(repos)) ||
      any(!.cascade_snapshot_safe_relative(repos)) ||
      any(grepl("/", repos, fixed = TRUE)) ||
      any(repos %in% c(".", "..")) ||
      anyDuplicated(if (.Platform$OS.type == "windows") tolower(repos) else repos)) {
    .cascade_snapshot_fail("source repository basenames are unsafe or duplicated")
  }
  if (!is.logical(source_products$clean) ||
      anyNA(source_products$clean) || any(!source_products$clean))
    .cascade_snapshot_fail(
      "source_products must attest a clean worktree for every source")
  if (!is.numeric(source_products$n_site_files) ||
      anyNA(source_products$n_site_files) ||
      any(!is.finite(source_products$n_site_files)) ||
      any(source_products$n_site_files < 1) ||
      any(source_products$n_site_files !=
          floor(source_products$n_site_files))) {
    .cascade_snapshot_fail("source product file counts are invalid")
  }

  size_columns <- intersect(c("bytes", "byte_size", "size_bytes"),
                            names(source_inputs))
  required_inputs <- c("product", "relative_path", "md5")
  if (!is.data.frame(source_inputs) ||
      length(setdiff(required_inputs, names(source_inputs))) ||
      length(size_columns) != 1L || !nrow(source_inputs)) {
    .cascade_snapshot_fail(
      "source_inputs must include product, relative_path, md5, and one byte-size column")
  }
  size_column <- size_columns[1L]
  input_product <- as.character(source_inputs$product)
  input_path <- as.character(source_inputs$relative_path)
  input_md5 <- as.character(source_inputs$md5)
  input_bytes <- source_inputs[[size_column]]
  if (anyNA(input_product) ||
      !setequal(unique(input_product), .cascade_snapshot_products) ||
      anyNA(input_path) || any(!.cascade_snapshot_safe_relative(input_path)) ||
      anyDuplicated(paste(input_product, input_path, sep = "|")) ||
      anyNA(input_md5) || any(!grepl("^[0-9a-f]{32}$", input_md5)) ||
      !is.numeric(input_bytes) || anyNA(input_bytes) ||
      any(!is.finite(input_bytes)) || any(input_bytes <= 0) ||
      any(input_bytes != floor(input_bytes)) || any(input_bytes > 2^53)) {
    .cascade_snapshot_fail("source input inventory is malformed or duplicated")
  }

  direct_site <- grepl("^data/sites/[^/]+[.]rds$", input_path)
  direct_env <- grepl("^data/env/[^/]+[.]rds$", input_path)
  if (any(!direct_site & !(input_product == "mammal" & direct_env)) ||
      !any(input_product == "mammal" & direct_env)) {
    .cascade_snapshot_fail(
      "source input inventory must contain only direct site RDS files plus mammal env RDS files")
  }
  for (i in seq_along(.cascade_snapshot_products)) {
    product <- .cascade_snapshot_products[i]
    site_count <- sum(input_product == product & direct_site)
    if (site_count != as.numeric(source_products$n_site_files[i]))
      .cascade_snapshot_fail(
        "%s site-file inventory count does not match source_products", product)
  }
  if (.Platform$OS.type == "windows" &&
      anyDuplicated(tolower(paste(input_product, input_path, sep = "|"))))
    .cascade_snapshot_fail(
      "source input paths collide on a case-insensitive filesystem")

  live_paths <- vapply(.cascade_snapshot_products, function(product) {
    value <- live_app[[product]]
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(value) || !dir.exists(value))
      .cascade_snapshot_fail("live %s source path is missing", product)
    link <- Sys.readlink(value)
    if (!is.na(link) && nzchar(link))
      .cascade_snapshot_fail("live %s source path is a symbolic link", product)
    canonical <- normalizePath(value, winslash = "/", mustWork = TRUE)
    info <- file.info(canonical)
    if (is.na(info$isdir) || !info$isdir)
      .cascade_snapshot_fail("live %s source path is not a directory", product)
    canonical
  }, character(1))
  names(live_paths) <- .cascade_snapshot_products
  for (i in seq_along(.cascade_snapshot_products)) {
    product <- .cascade_snapshot_products[i]
    if (!identical(basename(live_paths[[product]]), repos[i]))
      .cascade_snapshot_fail(
        "live %s source basename does not match recorded provenance", product)
  }

  git <- Sys.which("git")
  if (!nzchar(git))
    .cascade_snapshot_fail("git is required to create immutable source snapshots")

  snapshot_relative <- ".cascade-source-snapshot"
  if (!.cascade_snapshot_safe_relative(snapshot_relative))
    .cascade_snapshot_fail("internal source snapshot path is unsafe")
  snapshot_root <- file.path(staged_app, snapshot_relative)
  marker_path <- file.path(staged_app, ".cascade-source-snapshot-root")
  if (.cascade_snapshot_exists(snapshot_root) ||
      .cascade_snapshot_exists(marker_path))
    .cascade_snapshot_fail(
      "staged app already contains a source snapshot or root marker")

  temp_root <- tempfile(".cascade-source-snapshot-build-", tmpdir = staged_app)
  if (!dir.create(temp_root, recursive = FALSE, showWarnings = FALSE))
    .cascade_snapshot_fail("could not create temporary source snapshot root")
  temp_root <- normalizePath(temp_root, winslash = "/", mustWork = TRUE)
  if (!startsWith(.cascade_snapshot_path_key(temp_root),
                  paste0(.cascade_snapshot_path_key(staged_app), "/")))
    .cascade_snapshot_fail("temporary source snapshot escaped the staged app")

  scratch <- character()
  success <- FALSE
  published_snapshot <- FALSE
  published_marker <- FALSE
  on.exit({
    if (length(scratch)) unlink(scratch, force = TRUE)
    if (dir.exists(temp_root))
      unlink(temp_root, recursive = TRUE, force = TRUE)
    if (!success && published_marker && .cascade_snapshot_exists(marker_path))
      unlink(marker_path, force = TRUE)
    if (!success && published_snapshot && .cascade_snapshot_exists(snapshot_root))
      unlink(snapshot_root, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  git_call <- function(repo, args, stdout = FALSE, label) {
    stderr_path <- tempfile(".cascade-git-stderr-", tmpdir = staged_app)
    scratch <<- c(scratch, stderr_path)
    result <- tryCatch(
      suppressWarnings(git_system2(
        git, c("-C", shQuote(repo), args),
        stdout = stdout, stderr = stderr_path)),
      error = function(e) structure(1L, error = conditionMessage(e)))
    status <- .cascade_snapshot_git_status(result)
    if (is.na(status) || status != 0L)
      .cascade_snapshot_fail("%s failed for source repository '%s'",
                             label, basename(repo))
    result
  }

  git_raw <- function(repo, args, label) {
    output <- tempfile(".cascade-git-stdout-", tmpdir = staged_app)
    scratch <<- c(scratch, output)
    git_call(repo, args, stdout = output, label = label)
    .cascade_snapshot_read_raw(output)
  }

  git_lines <- function(repo, args, label) {
    bytes <- git_raw(repo, args, label)
    if (!length(bytes)) return(character())
    text <- rawToChar(bytes)
    lines <- strsplit(gsub("\r\n", "\n", text, fixed = TRUE),
                      "\n", fixed = TRUE)[[1L]]
    lines[nzchar(lines)]
  }

  for (i in seq_along(.cascade_snapshot_products)) {
    product <- .cascade_snapshot_products[i]
    repo <- live_paths[[product]]
    commit <- commits[i]
    repo_name <- repos[i]

    top <- git_lines(repo, c("rev-parse", "--show-toplevel"),
                     sprintf("%s repository-root validation", product))
    if (length(top) != 1L) .cascade_snapshot_fail(
      "%s repository root response is malformed", product)
    top <- normalizePath(top[1L], winslash = "/", mustWork = TRUE)
    if (!.cascade_snapshot_same_path(top, repo))
      .cascade_snapshot_fail(
        "live %s path is not the canonical Git worktree root", product)

    head <- git_lines(repo, c("rev-parse", "--verify", "HEAD"),
                      sprintf("%s HEAD validation", product))
    if (length(head) != 1L || !identical(head[1L], commit))
      .cascade_snapshot_fail(
        "live %s HEAD no longer matches recorded provenance", product)
    object_type <- git_lines(repo, c("cat-file", "-t", commit),
                             sprintf("%s commit validation", product))
    if (!identical(object_type, "commit"))
      .cascade_snapshot_fail(
        "recorded %s object is unavailable or is not a commit", product)

    archive_roots <- "data/sites"
    if (identical(product, "mammal"))
      archive_roots <- c(archive_roots, "data/env")
    dirty <- git_raw(
      repo,
      c("status", "--porcelain=v1", "-z", "--untracked-files=normal",
        "--", archive_roots),
      sprintf("%s archived-data cleanliness validation", product))
    if (length(dirty))
      .cascade_snapshot_fail(
        "live %s archived data changed after provenance was recorded", product)
    tree_bytes <- git_raw(
      repo,
      c("ls-tree", "-r", "-z", "--full-tree", commit, "--",
        archive_roots),
      sprintf("%s immutable tree inventory", product))
    tree <- .cascade_snapshot_parse_tree(tree_bytes, product)
    tree_paths <- sort(tree$path, method = "radix")

    expected <- source_inputs[input_product == product, , drop = FALSE]
    expected_paths <- sort(as.character(expected$relative_path),
                           method = "radix")
    rds_like <- grepl("[.]rds$", tree_paths, ignore.case = TRUE)
    if (any(rds_like & !endsWith(tree_paths, ".rds")))
      .cascade_snapshot_fail(
        "recorded %s tree contains a non-canonical RDS suffix", product)
    tree_rds <- sort(tree_paths[endsWith(tree_paths, ".rds")],
                     method = "radix")
    if (!identical(tree_rds, expected_paths))
      .cascade_snapshot_fail(
        "recorded %s commit RDS set differs from source_inputs", product)

    tarfile <- tempfile(
      paste0(".cascade-", product, "-"), tmpdir = staged_app,
      fileext = ".tar")
    scratch <- c(scratch, tarfile)
    git_call(
      repo,
      c("archive", "--format=tar", "--output", shQuote(tarfile),
        commit, "--", archive_roots),
      stdout = FALSE, label = sprintf("%s git archive", product))
    if (!file.exists(tarfile) || .cascade_snapshot_linked(tarfile))
      .cascade_snapshot_fail("%s git archive did not create a regular file",
                             product)
    archive_md5 <- unname(tools::md5sum(tarfile))
    if (is.na(archive_md5))
      .cascade_snapshot_fail("could not fingerprint %s git archive", product)

    .cascade_snapshot_validate_tar_types(tarfile, product)
    members <- tryCatch(
      utils::untar(tarfile, list = TRUE),
      error = function(e) character())
    if (!length(members) ||
        any(!.cascade_snapshot_safe_relative(
          members, allow_trailing_slash = TRUE)) ||
        anyDuplicated(members)) {
      .cascade_snapshot_fail(
        "%s tar archive contains an unsafe, empty, or duplicate member list",
        product)
    }
    member_paths <- sub("/$", "", members)
    allowed_member <- member_paths == "data" |
      member_paths == "data/sites" |
      startsWith(member_paths, "data/sites/")
    if (identical(product, "mammal")) {
      allowed_member <- allowed_member |
        member_paths == "data/env" |
        startsWith(member_paths, "data/env/")
    }
    if (any(!allowed_member))
      .cascade_snapshot_fail(
        "%s tar archive member escaped its requested roots", product)
    tar_files <- sort(members[!endsWith(members, "/")], method = "radix")
    if (!identical(tar_files, tree_paths))
      .cascade_snapshot_fail(
        "%s tar file set differs from its recorded Git tree", product)
    if (!identical(unname(tools::md5sum(tarfile)), archive_md5))
      .cascade_snapshot_fail("%s tar archive changed during validation",
                             product)

    destination <- file.path(temp_root, repo_name)
    if (!dir.create(destination, recursive = FALSE, showWarnings = FALSE))
      .cascade_snapshot_fail(
        "could not create %s snapshot repository directory", product)
    status <- tryCatch(
      suppressWarnings(utils::untar(
        tarfile, exdir = destination, restore_times = FALSE)),
      error = function(e) 1L)
    if (!isTRUE(as.integer(status) == 0L))
      .cascade_snapshot_fail("%s tar extraction failed", product)
    if (!identical(unname(tools::md5sum(tarfile)), archive_md5))
      .cascade_snapshot_fail("%s tar archive changed during extraction",
                             product)

    entries <- list.files(
      destination, recursive = TRUE, all.files = TRUE,
      full.names = FALSE, include.dirs = TRUE, no.. = TRUE)
    entries <- gsub("\\\\", "/", entries)
    if (!length(entries) ||
        any(!.cascade_snapshot_safe_relative(entries)))
      .cascade_snapshot_fail(
        "extracted %s snapshot contains an unsafe or empty path set", product)
    absolute_entries <- file.path(destination, entries)
    entry_info <- file.info(absolute_entries)
    links <- Sys.readlink(absolute_entries)
    linked <- !is.na(links) & nzchar(links)
    if (any(!file.exists(absolute_entries)) || anyNA(entry_info$isdir) ||
        any(linked)) {
      .cascade_snapshot_fail(
        "extracted %s snapshot contains a missing or symbolic-link entry",
        product)
    }
    file_rows <- !entry_info$isdir
    if (any(file_rows & !file_test("-f", absolute_entries)))
      .cascade_snapshot_fail(
        "extracted %s snapshot contains a non-regular file", product)
    extracted_files <- sort(entries[file_rows], method = "radix")
    if (!identical(extracted_files, tree_paths))
      .cascade_snapshot_fail(
        "extracted %s file set differs from its recorded Git tree", product)

    expected <- expected[
      match(expected_paths, as.character(expected$relative_path)),
      , drop = FALSE]
    extracted_inputs <- file.path(destination, expected_paths)
    input_info <- file.info(extracted_inputs)
    input_links <- Sys.readlink(extracted_inputs)
    if (any(!file.exists(extracted_inputs)) || anyNA(input_info$isdir) ||
        any(input_info$isdir) ||
        any(!is.na(input_links) & nzchar(input_links)) ||
        any(!file_test("-f", extracted_inputs))) {
      .cascade_snapshot_fail(
        "extracted %s RDS inventory contains a missing, linked, or non-regular file",
        product)
    }
    actual_md5 <- unname(tools::md5sum(extracted_inputs))
    actual_bytes <- as.numeric(input_info$size)
    expected_md5 <- as.character(expected$md5)
    expected_bytes <- as.numeric(expected[[size_column]])
    if (anyNA(actual_md5) || !identical(actual_md5, expected_md5) ||
        !identical(actual_bytes, expected_bytes)) {
      .cascade_snapshot_fail(
        "extracted %s RDS bytes differ from source_inputs", product)
    }
  }

  if (.cascade_snapshot_exists(snapshot_root))
    .cascade_snapshot_fail(
      "source snapshot destination appeared during materialization")
  if (!file.rename(temp_root, snapshot_root))
    .cascade_snapshot_fail(
      "could not publish the completed source snapshot inside staging")
  published_snapshot <- TRUE

  marker_temp <- tempfile(
    ".cascade-source-snapshot-root-", tmpdir = staged_app)
  scratch <- c(scratch, marker_temp)
  .cascade_snapshot_write_lf(marker_temp, snapshot_relative)
  if (.cascade_snapshot_exists(marker_path))
    .cascade_snapshot_fail(
      "source snapshot root marker appeared during materialization")
  if (!file.rename(marker_temp, marker_path))
    .cascade_snapshot_fail("could not publish source snapshot root marker")
  published_marker <- TRUE

  marker_bytes <- .cascade_snapshot_read_raw(marker_path)
  if (!identical(marker_bytes,
                 charToRaw(paste0(snapshot_relative, "\n"))))
    .cascade_snapshot_fail("source snapshot root marker is malformed")

  snapshot_root <- normalizePath(
    snapshot_root, winslash = "/", mustWork = TRUE)
  snapshot_app <- stats::setNames(
    vapply(repos, function(repo)
      normalizePath(file.path(snapshot_root, repo),
                    winslash = "/", mustWork = TRUE),
      character(1)),
    .cascade_snapshot_products)

  success <- TRUE
  list(
    app = snapshot_app,
    root = snapshot_root,
    method = CASCADE_SOURCE_SNAPSHOT_METHOD,
    marker = normalizePath(marker_path, winslash = "/", mustWork = TRUE))
}
