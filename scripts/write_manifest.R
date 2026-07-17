# Generate the lean Posit Connect manifest from the exact approved deploy surface.
source("scripts/generation_guard.R", local = TRUE)
setwd_root <- function() {
  if (file.exists("global.R")) return(invisible())
  if (file.exists("../global.R")) { setwd(".."); return(invisible()) }
  stop("run from the app root (global.R not found)", call. = FALSE)
}
setwd_root()

if (!requireNamespace("rsconnect", quietly = TRUE))
  stop("rsconnect is required to write manifest.json", call. = FALSE)
if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("jsonlite is required to validate manifest.json", call. = FALSE)

source("scripts/manifest_files.R", local = TRUE)
source("scripts/manifest_policy.R", local = TRUE)
missing <- DEPLOY_APP_FILES[!file.exists(DEPLOY_APP_FILES)]
if (length(missing))
  stop(sprintf("approved deploy file(s) missing: %s", paste(missing, collapse = ", ")),
       call. = FALSE)

# The checksum contract is byte-exact and platform-independent. Normalize text
# before rsconnect hashes it; verification rejects any later CR/CRLF drift.
canonicalize_deploy_text(DEPLOY_APP_FILES)
rsconnect::writeManifest(appDir = ".", appFiles = DEPLOY_APP_FILES)
manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
result <- validate_manifest_policy(manifest, DEPLOY_APP_FILES, check_checksums = TRUE)
validate_manifest_library(manifest)
cat(sprintf("manifest.json written and verified: %d packages, %d files.\n",
            result$packages, result$files))
