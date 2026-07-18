# Verify the exact deploy surface, canonical bytes, package provenance, and hashes.
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible())
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1]), winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible())
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}
setwd_repo_root()

if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("jsonlite is required to verify manifest.json", call. = FALSE)
if (!file.exists("manifest.json")) stop("manifest.json is missing", call. = FALSE)
source("scripts/manifest_files.R", local = TRUE)
source("scripts/manifest_policy.R", local = TRUE)
manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
result <- validate_manifest_policy(manifest, DEPLOY_APP_FILES, check_checksums = TRUE)
validate_manifest_library(manifest)
cat(sprintf("manifest.json verified: %d trusted packages, %d canonical deploy files.\n",
            result$packages, result$files))
