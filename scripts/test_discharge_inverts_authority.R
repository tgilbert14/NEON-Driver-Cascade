#!/usr/bin/env Rscript

# Values-free authority check for the response side of Discharge Gate F0.
# The exact Inverts commit is a metadata-only partial clone: this script verifies
# its commit/tree identities but never requests or deserializes a response blob.
# The committed, values-free site-year receipt is the only response panel read.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("usage: test_discharge_inverts_authority.R <metadata-only-inverts-repo>",
       call. = FALSE)
}

repo <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
authority <- "ff23e994e289982c747b91e48c5ff0907c1672d2"
expected_root_tree <- "b09c9b54aa5b81290ab6a2dc98072421eae66b03"
expected_data_tree <- "812be54ac172fe2febaa5a192f90070e87e3fbf0"
expected_sites_tree <- "080534caad4eb76cdaf0b5a56704ed4e890ed16a"
ledger_path <- "docs/receipts/discharge-inverts-response-site-years.tsv"
expected_ledger_sha256 <-
  "79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296"
expected_ledger_blob <- "c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8"

git <- Sys.which("git")
if (!nzchar(git)) stop("git is required", call. = FALSE)

run_command <- function(command, arguments, label) {
  output <- suppressWarnings(system2(
    command, arguments, stdout = TRUE, stderr = TRUE
  ))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L)
    stop(sprintf("%s failed:\n%s", label, paste(output, collapse = "\n")),
         call. = FALSE)
  output
}

run_git <- function(arguments, label = "Git metadata query") {
  run_command(git, c("-C", shQuote(repo), arguments), label)
}

one_git_line <- function(arguments, label) {
  output <- run_git(arguments, label)
  if (length(output) != 1L || !nzchar(output[[1L]]))
    stop(sprintf("invalid %s", label), call. = FALSE)
  output[[1L]]
}

assert_no_local_blobs <- function(label) {
  types <- run_git(
    c("cat-file", "--batch-all-objects",
      shQuote("--batch-check=%(objecttype)")),
    sprintf("%s object inventory", label))
  if (any(types == "blob"))
    stop(sprintf("%s unexpectedly contains a fetched blob object", label),
         call. = FALSE)
  invisible(TRUE)
}

assert_no_local_blobs("metadata-only Inverts authority before verification")

commit <- one_git_line(
  c("rev-parse", shQuote(paste0(authority, "^{commit}"))), "authority commit")
root_tree <- one_git_line(
  c("rev-parse", shQuote(paste0(authority, "^{tree}"))), "root tree")
data_tree <- one_git_line(
  c("rev-parse", shQuote(paste0(authority, ":data"))), "data tree")
sites_tree <- one_git_line(
  c("rev-parse", shQuote(paste0(authority, ":data/sites"))),
  "data/sites tree")

stopifnot(
  identical(commit, authority),
  identical(root_tree, expected_root_tree),
  identical(data_tree, expected_data_tree),
  identical(sites_tree, expected_sites_tree),
  identical(one_git_line(c("cat-file", "-t", commit), "commit type"),
            "commit"),
  identical(one_git_line(c("cat-file", "-t", root_tree), "root tree type"),
            "tree"),
  identical(one_git_line(c("cat-file", "-t", data_tree), "data tree type"),
            "tree"),
  identical(one_git_line(c("cat-file", "-t", sites_tree), "sites tree type"),
            "tree")
)

if (!file.exists(ledger_path) || file.access(ledger_path, mode = 4L) != 0L)
  stop("the committed values-free Inverts authority receipt is unavailable",
       call. = FALSE)

sha256sum <- Sys.which("sha256sum")
if (nzchar(sha256sum)) {
  hash_output <- run_command(
    sha256sum, shQuote(ledger_path), "SHA-256 authority receipt check")
} else {
  shasum <- Sys.which("shasum")
  if (!nzchar(shasum)) stop("sha256sum or shasum is required", call. = FALSE)
  hash_output <- run_command(
    shasum, c("-a", "256", shQuote(ledger_path)),
    "SHA-256 authority receipt check")
}
if (length(hash_output) != 1L)
  stop("invalid SHA-256 authority receipt output", call. = FALSE)
ledger_sha256 <- strsplit(trimws(hash_output[[1L]]), "[[:space:]]+")[[1L]][[1L]]
ledger_blob <- run_command(
  git, c("hash-object", "--no-filters", shQuote(ledger_path)),
  "Git blob authority receipt check")
if (length(ledger_blob) != 1L ||
    !identical(ledger_sha256, expected_ledger_sha256) ||
    !identical(ledger_blob[[1L]], expected_ledger_blob))
  stop("the values-free Inverts authority receipt identity has drifted",
       call. = FALSE)

source("scripts/discharge_feasibility_contract.R", local = FALSE)
panel <- utils::read.delim(
  ledger_path,
  header = TRUE,
  sep = "\t",
  quote = "",
  comment.char = "",
  colClasses = c(siteID = "character", utc_calendar_year = "integer"),
  check.names = FALSE,
  stringsAsFactors = FALSE)

discharge_f0_assert_exact_inverts_authority(panel)
assert_no_local_blobs("metadata-only Inverts authority after verification")

cat(sprintf(
  paste0("OK: exact values-free Inverts authority %s / data/sites %s; ",
         "ledger sha256=%s; no response blob fetched or read.\n"),
  substr(authority, 1L, 8L), substr(sites_tree, 1L, 8L), ledger_sha256
))
