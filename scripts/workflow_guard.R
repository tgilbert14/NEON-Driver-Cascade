# Trusted workflow guard for immutable sibling locks and validated artifact receipts.
# The publisher only invokes verify-receipt; that path never deserializes RDS files.

ARTIFACT_RECEIPT_SCHEMA <- "cascade-artifact-receipt-v1"
ARTIFACT_RECEIPT_NAME <- "artifact-receipt.tsv"
ARTIFACT_FILES <- c(
  "data/cascade.rds",
  "data/search_index.rds",
  "data/cascade_meta.rds",
  "data/neon-cascade-codebook.csv")
SOURCE_LOCK <- data.frame(
  product = c("mammal", "plant", "veg", "bird", "phe", "mosq", "beetle"),
  directory = c("App-NEON-Small-Mammal-Tracker", "NEON-Plant-Diversity",
                "NEON-Veg-Structure", "NEON-Breeding-Birds",
                "NEON-Plant-Phenology", "NEON-Mosquito-Pulse",
                "NEON-Ground-Beetle-Tracker"),
  repo = c("App-NEON-Small-Mammal-Tracker", "NEON-Plant-Diversity",
           "NEON-Veg-Structure", "NEON-Breeding-Birds",
           "NEON-Plant-Phenology", "NEON-Mosquito-Pulse",
           "NEON-Ground-Beetle-Tracker"),
  origin = c(
    "github.com/tgilbert14/neon-small-mammal-tracker-app",
    "github.com/tgilbert14/neon-plant-diversity",
    "github.com/tgilbert14/neon-vegetation-structure-explorer",
    "github.com/tgilbert14/neon-breeding-birds",
    "github.com/tgilbert14/neon-plant-phenology-explorer",
    "github.com/tgilbert14/neon-mosquito-pulse",
    "github.com/tgilbert14/neon-ground-beetle-tracker"),
  stringsAsFactors = FALSE)

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
workflow_fail <- function(fmt, ...) stop(sprintf(fmt, ...), call. = FALSE)
valid_sha <- function(x) is.character(x) && length(x) == 1L &&
  grepl("^[0-9a-f]{40}$", x)

write_lf_lines <- function(lines, path) {
  text <- enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))
  con <- file(path, open = "wb")
  tryCatch(writeBin(charToRaw(text), con), finally = close(con))
  invisible(TRUE)
}

relative_entries <- function(root) {
  paths <- list.files(root, recursive = TRUE, all.files = TRUE,
                      full.names = FALSE, include.dirs = TRUE, no.. = TRUE)
  sort(gsub("\\\\", "/", paths), method = "radix")
}

assert_data_directory <- function(root) {
  path <- file.path(root, "data")
  info <- file.info(path)
  link <- Sys.readlink(path)
  if (nrow(info) != 1L || is.na(info$isdir) || !info$isdir ||
      (!is.na(link) && nzchar(link)))
    workflow_fail("artifact data entry is not a regular, non-symbolic-link directory")
  invisible(path)
}

assert_regular_files <- function(root, relative) {
  paths <- file.path(root, relative)
  info <- file.info(paths)
  regular <- file_test("-f", paths)
  links <- Sys.readlink(paths)
  if (any(!file.exists(paths)) || any(is.na(info$isdir)) || any(info$isdir) ||
      any(is.na(regular) | !regular) || any(!is.na(links) & nzchar(links)))
    workflow_fail("artifact set contains a missing, non-regular, or symbolic-link entry")
  invisible(paths)
}

sha256_files <- function(root, relative) {
  exe <- Sys.which("sha256sum")
  if (!nzchar(exe)) workflow_fail("sha256sum is required by the workflow receipt guard")
  vapply(file.path(root, relative), function(path) {
    out <- system2(exe, c("--binary", shQuote(normalizePath(path, winslash = "/"))),
                   stdout = TRUE, stderr = TRUE)
    status <- attr(out, "status") %||% 0L
    hash <- if (length(out)) strsplit(trimws(out[1]), "[[:space:]]+")[[1L]][1L] else ""
    if (status != 0L || !grepl("^[0-9a-f]{64}$", hash))
      workflow_fail("could not compute SHA-256 for %s", path)
    hash
  }, character(1), USE.NAMES = FALSE)
}

write_approved_sources <- function(output_path) {
  rows <- apply(SOURCE_LOCK[c("product", "directory", "origin")], 1L,
                paste, collapse = "\t")
  write_lf_lines(rows, output_path)
}

write_source_lock <- function(bundle_path, output_path) {
  bundle <- readRDS(bundle_path)
  products <- bundle$meta$source_products
  required <- c("product", "repo", "origin", "commit", "clean")
  if (!is.data.frame(products) || length(setdiff(required, names(products))) ||
      nrow(products) != nrow(SOURCE_LOCK) || anyDuplicated(products$product) ||
      !setequal(products$product, SOURCE_LOCK$product))
    workflow_fail("committed cascade source provenance is incomplete")
  products <- products[match(SOURCE_LOCK$product, products$product), , drop = FALSE]
  if (!identical(as.character(products$repo), SOURCE_LOCK$repo) ||
      !identical(as.character(products$origin), SOURCE_LOCK$origin) ||
      !all(products$clean %in% TRUE) ||
      any(!grepl("^[0-9a-f]{40}$", products$commit)))
    workflow_fail("committed cascade source provenance does not match the seven approved origins")
  lock <- data.frame(product = SOURCE_LOCK$product,
                     directory = SOURCE_LOCK$directory,
                     origin = SOURCE_LOCK$origin,
                     commit = as.character(products$commit),
                     stringsAsFactors = FALSE)
  rows <- apply(lock, 1L, paste, collapse = "\t")
  write_lf_lines(rows, output_path)
  invisible(lock)
}

write_receipt <- function(base_sha, root, receipt_path) {
  if (!valid_sha(base_sha)) workflow_fail("base SHA must be 40 lowercase hexadecimal characters")
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  receipt_parent <- normalizePath(dirname(receipt_path), winslash = "/", mustWork = TRUE)
  if (!identical(receipt_parent, root) || !identical(basename(receipt_path), ARTIFACT_RECEIPT_NAME))
    workflow_fail("receipt path must be the fixed artifact-root receipt")
  receipt_path <- file.path(root, ARTIFACT_RECEIPT_NAME)
  expected_surface <- sort(c("data", ARTIFACT_FILES), method = "radix")
  actual <- relative_entries(root)
  if (!identical(actual, expected_surface))
    workflow_fail("artifact staging surface mismatch (missing: %s; unexpected: %s)",
                  paste(setdiff(expected_surface, actual), collapse = ", "),
                  paste(setdiff(actual, expected_surface), collapse = ", "))
  assert_data_directory(root)
  assert_regular_files(root, ARTIFACT_FILES)
  codebook_path <- file.path(root, "data/neon-cascade-codebook.csv")
  codebook <- readBin(codebook_path, "raw", n = file.info(codebook_path)$size)
  if (any(as.integer(codebook) %in% c(0L, 13L)))
    workflow_fail("codebook must be NUL-free canonical LF before receipt hashing")
  hashes <- sha256_files(root, ARTIFACT_FILES)
  lines <- c(ARTIFACT_RECEIPT_SCHEMA,
             paste("base", base_sha, sep = "\t"),
             paste("sha256", hashes, ARTIFACT_FILES, sep = "\t"))
  write_lf_lines(lines, receipt_path)
  invisible(TRUE)
}

verify_receipt <- function(base_sha, root, receipt_path) {
  if (!valid_sha(base_sha)) workflow_fail("expected base SHA is malformed")
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  receipt_parent <- normalizePath(dirname(receipt_path), winslash = "/", mustWork = TRUE)
  receipt_name <- basename(receipt_path)
  if (!identical(receipt_parent, root) || !identical(receipt_name, ARTIFACT_RECEIPT_NAME))
    workflow_fail("receipt path must be the fixed artifact-root receipt")
  receipt_path <- file.path(root, receipt_name)
  actual <- relative_entries(root)
  expected_surface <- sort(c("data", ARTIFACT_FILES, receipt_name), method = "radix")
  if (!identical(actual, expected_surface))
    workflow_fail("downloaded artifact surface mismatch (missing: %s; unexpected: %s)",
                  paste(setdiff(expected_surface, actual), collapse = ", "),
                  paste(setdiff(actual, expected_surface), collapse = ", "))
  assert_data_directory(root)
  assert_regular_files(root, c(ARTIFACT_FILES, receipt_name))
  bytes <- readBin(receipt_path, "raw", n = file.info(receipt_path)$size)
  if (any(as.integer(bytes) %in% c(0L, 13L))) workflow_fail("receipt is not canonical LF text")
  lines <- readLines(receipt_path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) != 2L + length(ARTIFACT_FILES) ||
      !identical(lines[1L], ARTIFACT_RECEIPT_SCHEMA))
    workflow_fail("artifact receipt schema or row count is invalid")
  base <- strsplit(lines[2L], "\t", fixed = TRUE)[[1L]]
  if (length(base) != 2L || !identical(base[1L], "base") || !identical(base[2L], base_sha))
    workflow_fail("artifact receipt base does not match the immutable workflow SHA")
  records <- strsplit(lines[-c(1L, 2L)], "\t", fixed = TRUE)
  if (any(lengths(records) != 3L)) workflow_fail("artifact receipt row is malformed")
  algorithms <- vapply(records, `[`, character(1), 1L)
  hashes <- vapply(records, `[`, character(1), 2L)
  paths <- vapply(records, `[`, character(1), 3L)
  if (any(algorithms != "sha256") || any(!grepl("^[0-9a-f]{64}$", hashes)) ||
      !identical(paths, ARTIFACT_FILES) || anyDuplicated(paths))
    workflow_fail("artifact receipt checksums or paths are malformed")
  actual_hashes <- sha256_files(root, paths)
  if (!identical(hashes, actual_hashes))
    workflow_fail("artifact receipt SHA-256 mismatch: %s",
                  paste(paths[hashes != actual_hashes], collapse = ", "))
  invisible(TRUE)
}

workflow_guard_self_test <- function() {
  root <- tempfile("cascade-workflow-guard-")
  dir.create(file.path(root, "data"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  for (relative in ARTIFACT_FILES)
    writeBin(charToRaw(relative), file.path(root, relative))
  base_sha <- paste(rep("0", 40L), collapse = "")
  receipt <- file.path(root, ARTIFACT_RECEIPT_NAME)
  write_receipt(base_sha, root, receipt)
  verify_receipt(base_sha, root, receipt)

  dir.create(file.path(root, "unexpected-empty-directory"))
  if (!inherits(try(verify_receipt(base_sha, root, receipt), silent = TRUE), "try-error"))
    workflow_fail("receipt guard accepted an unexpected empty directory")
  unlink(file.path(root, "unexpected-empty-directory"), recursive = TRUE, force = TRUE)

  writeBin(charToRaw("tampered"), file.path(root, ARTIFACT_FILES[[1L]]))
  if (!inherits(try(verify_receipt(base_sha, root, receipt), silent = TRUE), "try-error"))
    workflow_fail("receipt guard accepted a payload checksum mismatch")
  cat("WORKFLOW RECEIPT GUARD FIXTURES PASSED\n")
  invisible(TRUE)
}

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) workflow_fail("usage: workflow_guard.R <approved-sources|source-lock|write-receipt|verify-receipt|self-test> ...")
command <- args[1L]
if (identical(command, "approved-sources") && length(args) == 2L) {
  write_approved_sources(args[2L])
} else if (identical(command, "source-lock") && length(args) == 3L) {
  write_source_lock(args[2L], args[3L])
} else if (identical(command, "write-receipt") && length(args) == 4L) {
  write_receipt(args[2L], args[3L], args[4L])
} else if (identical(command, "verify-receipt") && length(args) == 4L) {
  verify_receipt(args[2L], args[3L], args[4L])
} else if (identical(command, "self-test") && length(args) == 1L) {
  workflow_guard_self_test()
} else {
  workflow_fail("invalid workflow_guard.R command or argument count")
}
