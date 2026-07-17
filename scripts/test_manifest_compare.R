# Focused fixtures for the trusted cross-platform manifest comparator.
if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("jsonlite is required to test manifest comparison", call. = FALSE)
source("scripts/manifest_files.R", local = TRUE)
source("scripts/manifest_policy.R", local = TRUE)
baseline <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
# Manifest freshness is verified separately; keep these comparator fixtures self-contained.
for (path in DEPLOY_APP_FILES)
  baseline$files[[path]]$checksum <- unname(tools::md5sum(path))
expect_error <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")
clone <- function(value) unserialize(serialize(value, NULL))

implicit_provenance <- clone(baseline)
for (package in names(implicit_provenance$packages))
  implicit_provenance$packages[[package]]$description[
    MANIFEST_STANDARD_REMOTE_FIELDS] <- NULL
validate_manifest_policy(implicit_provenance, DEPLOY_APP_FILES,
                         check_checksums = TRUE)

explicit_provenance <- clone(implicit_provenance)
for (package in names(explicit_provenance$packages)) {
  record <- explicit_provenance$packages[[package]]
  record$description$RemoteType <- "standard"
  record$description$RemoteRepos <- record$Repository
  record$description$RemotePkgRef <- package
  record$description$RemoteRef <- package
  record$description$RemoteSha <- record$description$Version
  explicit_provenance$packages[[package]] <- record
}
validate_manifest_policy(explicit_provenance, DEPLOY_APP_FILES,
                         check_checksums = TRUE)
compare_manifest_reproducibility(
  implicit_provenance, explicit_provenance, DEPLOY_APP_FILES,
  check_checksums = TRUE)
compare_manifest_reproducibility(
  explicit_provenance, implicit_provenance, DEPLOY_APP_FILES,
  check_checksums = TRUE)

package <- names(explicit_provenance$packages)[1L]
for (field in MANIFEST_STANDARD_REMOTE_FIELDS) {
  partial <- clone(explicit_provenance)
  partial$packages[[package]]$description[[field]] <- NULL
  if (!expect_error(validate_manifest_policy(
        partial, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted missing explicit provenance field %s", field),
         call. = FALSE)
  singleton <- clone(implicit_provenance)
  singleton$packages[[package]]$description[[field]] <-
    explicit_provenance$packages[[package]]$description[[field]]
  if (!expect_error(validate_manifest_policy(
        singleton, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted singleton provenance field %s", field),
         call. = FALSE)
}
null_provenance <- clone(implicit_provenance)
null_provenance$packages[[package]]$description["RemoteType"] <- list(NULL)
if (!expect_error(validate_manifest_policy(
      null_provenance, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a named null provenance field", call. = FALSE)

invalid_values <- list(
  RemoteType = "github",
  RemoteRepos = "https://example.invalid/cran",
  RemotePkgRef = "wrong-package",
  RemoteRef = "wrong-package",
  RemoteSha = "999.0.0")
for (field in names(invalid_values)) {
  invalid <- clone(explicit_provenance)
  invalid$packages[[package]]$description[[field]] <- invalid_values[[field]]
  if (!expect_error(validate_manifest_policy(
        invalid, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted invalid provenance field %s", field),
         call. = FALSE)
}
for (url in c("http://cran.r-project.org",
              "https://cran.r-project.org/path with space",
              "https://cran.r-project.org/path\ncontrol")) {
  invalid <- clone(explicit_provenance)
  invalid$packages[[package]]$description$RemoteRepos <- url
  if (!expect_error(validate_manifest_policy(
        invalid, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop("manifest policy accepted an unsafe RemoteRepos URL", call. = FALSE)
}
rogue_fields <- c("RemoteHost", "RemoteRepo", "GithubRepo", "GitLabRepo",
                  "BitbucketRepo", "Remotes", "remotetype")
for (field in rogue_fields) {
  for (base in list(implicit_provenance, explicit_provenance)) {
    rogue <- clone(base)
    rogue$packages[[package]]$description[[field]] <- "attacker-controlled"
    if (!expect_error(validate_manifest_policy(
          rogue, DEPLOY_APP_FILES, check_checksums = TRUE)))
      stop(sprintf("manifest policy accepted unexpected provenance field %s", field),
           call. = FALSE)
  }
}

core_drift <- clone(implicit_provenance)
core_drift$packages[[package]]$Source <- "github"
if (!expect_error(validate_manifest_policy(
      core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a non-CRAN package source", call. = FALSE)
core_drift <- clone(implicit_provenance)
core_drift$packages[[package]]$Repository <- "https://example.invalid/cran"
if (!expect_error(validate_manifest_policy(
      core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted an untrusted outer repository", call. = FALSE)
core_drift <- clone(implicit_provenance)
core_drift$packages[[package]]$description$Repository <- "OTHER"
if (!expect_error(validate_manifest_policy(
      core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a non-CRAN DESCRIPTION repository", call. = FALSE)
core_drift <- clone(implicit_provenance)
core_drift$packages[[package]]$description$Package <- "wrong-package"
if (!expect_error(validate_manifest_policy(
      core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a package key/DESCRIPTION mismatch", call. = FALSE)

cross_platform <- clone(explicit_provenance)

for (package in names(cross_platform$packages)) {
  record <- cross_platform$packages[[package]]
  record$Repository <- "https://packagemanager.posit.co/cran/latest"
  record$description$RemoteRepos <- "https://cran.r-project.org"
  record$description$Built <- "R 4.5.9; x86_64-pc-linux-gnu; 2030-01-01 00:00:00 UTC; unix"
  cross_platform$packages[[package]] <- record
}
compare_manifest_reproducibility(baseline, cross_platform, DEPLOY_APP_FILES,
                                 check_checksums = TRUE)
checksum_case <- clone(baseline)
for (path in names(checksum_case$files))
  checksum_case$files[[path]]$checksum <- toupper(checksum_case$files[[path]]$checksum)
compare_manifest_reproducibility(baseline, checksum_case, DEPLOY_APP_FILES,
                                 check_checksums = TRUE)

root_drift <- clone(baseline)
root_drift$locale <- "C"
if (!expect_error(compare_manifest_reproducibility(
      baseline, root_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest comparator accepted root drift", call. = FALSE)
metadata_drift <- clone(baseline)
metadata_drift$metadata$has_parameters <- TRUE
if (!expect_error(compare_manifest_reproducibility(
      baseline, metadata_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest comparator accepted metadata drift", call. = FALSE)
checksum_drift <- clone(baseline)
checksum_path <- names(checksum_drift$files)[1L]
checksum_drift$files[[checksum_path]]$checksum <- paste(rep("0", 32L), collapse = "")
if (!expect_error(compare_manifest_reproducibility(
      baseline, checksum_drift, DEPLOY_APP_FILES, check_checksums = FALSE)))
  stop("manifest comparator accepted deploy checksum drift", call. = FALSE)
version_drift <- clone(implicit_provenance)
package <- names(version_drift$packages)[1L]
version_drift$packages[[package]]$description$Version <- "999.0.0"
if (!expect_error(compare_manifest_reproducibility(
      baseline, version_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest comparator accepted package-version drift", call. = FALSE)

dependency_drift <- clone(baseline)
dependency_package <- names(Filter(function(record)
  !is.null(record$description$Imports), dependency_drift$packages))[1L]
existing <- .manifest_dependencies(
  dependency_drift$packages[[dependency_package]], dependency_package)
extra <- setdiff(names(dependency_drift$packages),
                 c(dependency_package, existing))[1L]
if (!length(extra) || is.na(extra))
  stop("could not construct dependency drift fixture", call. = FALSE)
dependency_drift$packages[[dependency_package]]$description$Imports <- paste(
  dependency_drift$packages[[dependency_package]]$description$Imports,
  extra, sep = ", ")
if (!expect_error(compare_manifest_reproducibility(
      baseline, dependency_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest comparator accepted dependency-graph drift", call. = FALSE)

duplicate_description <- clone(baseline)
package <- names(duplicate_description$packages)[1L]
description <- duplicate_description$packages[[package]]$description
names(description)[2L] <- names(description)[1L]
duplicate_description$packages[[package]]$description <- description
if (!expect_error(validate_manifest_policy(
      duplicate_description, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted duplicate DESCRIPTION keys", call. = FALSE)

whitespace_repository <- clone(baseline)
package <- names(whitespace_repository$packages)[1L]
whitespace_repository$packages[[package]]$Repository <-
  "https://packagemanager.posit.co/cran/path with space"
if (!expect_error(validate_manifest_policy(
      whitespace_repository, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a repository URL containing whitespace", call. = FALSE)
cat("MANIFEST COMPARATOR FIXTURES PASSED\n")
