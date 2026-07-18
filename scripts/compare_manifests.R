# Compare two policy-valid manifests by their cross-platform deploy semantics.
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1L]),
                            winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}
setwd_repo_root()
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L)
  stop("usage: compare_manifests.R BASELINE_MANIFEST CANDIDATE_MANIFEST",
       call. = FALSE)
if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("jsonlite is required to compare manifests", call. = FALSE)
source("scripts/manifest_files.R", local = TRUE)
source("scripts/manifest_policy.R", local = TRUE)
read_manifest <- function(path) {
  if (!file.exists(path)) stop(sprintf("manifest is missing: %s", path), call. = FALSE)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}
result <- compare_manifest_reproducibility(
  read_manifest(args[1L]), read_manifest(args[2L]), DEPLOY_APP_FILES,
  check_checksums = TRUE)
cat(sprintf("manifest semantics reproduce: %d packages, %d deploy checksums.\n",
            result$packages, result$files))
