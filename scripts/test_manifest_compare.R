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

manifest_text <- readChar("manifest.json", file.info("manifest.json")$size,
                          useBytes = TRUE)
canonical_locale_line <- '  "locale": "en_US",'
if (!grepl(canonical_locale_line, manifest_text, fixed = TRUE))
  stop("manifest locale fixture requires the canonical root line", call. = FALSE)
for (source_locale in MANIFEST_ALLOWED_SOURCE_LOCALES) {
  source_text <- sub(canonical_locale_line,
                     sprintf('  "locale": "%s",', source_locale),
                     manifest_text, fixed = TRUE)
  if (!identical(charToRaw(normalize_rsconnect_manifest_locale(source_text)),
                 charToRaw(manifest_text)))
    stop(sprintf("manifest locale normalization failed for %s", source_locale),
         call. = FALSE)
}
for (source_locale in c("POSIX", "fr_FR", "")) {
  source_text <- sub(canonical_locale_line,
                     sprintf('  "locale": "%s",', source_locale),
                     manifest_text, fixed = TRUE)
  if (!expect_error(normalize_rsconnect_manifest_locale(source_text)))
    stop(sprintf("manifest locale policy accepted %s", source_locale),
         call. = FALSE)
}
array_locale <- sub(canonical_locale_line, '  "locale": ["en_US"],',
                    manifest_text, fixed = TRUE)
if (!expect_error(normalize_rsconnect_manifest_locale(array_locale)))
  stop("manifest locale policy accepted an array", call. = FALSE)
duplicate_locale <- sub(
  canonical_locale_line,
  paste(canonical_locale_line, canonical_locale_line, sep = "\n"),
  manifest_text, fixed = TRUE)
if (!expect_error(normalize_rsconnect_manifest_locale(duplicate_locale)))
  stop("manifest locale policy accepted duplicate root fields", call. = FALSE)
nested_locale <- sub(
  '"Type": "Package",',
  paste('"Type": "Package",', '        "locale": "preserve-me",', sep = "\n"),
  manifest_text, fixed = TRUE)
nested_source <- sub(canonical_locale_line, '  "locale": "C",',
                     nested_locale, fixed = TRUE)
if (!identical(charToRaw(normalize_rsconnect_manifest_locale(nested_source)),
               charToRaw(nested_locale)))
  stop("manifest locale normalization changed a nested field", call. = FALSE)

implicit_provenance <- clone(baseline)
for (package in names(implicit_provenance$packages)) {
  record <- implicit_provenance$packages[[package]]
  record$description[MANIFEST_STANDARD_REMOTE_FIELDS] <- NULL
  record$description$Repository <- "CRAN"
  implicit_provenance$packages[[package]] <- record
}
validate_manifest_policy(implicit_provenance, DEPLOY_APP_FILES,
                         check_checksums = TRUE)

explicit_cran <- clone(implicit_provenance)
for (package in names(explicit_cran$packages)) {
  record <- explicit_cran$packages[[package]]
  record$description$RemoteType <- "standard"
  record$description$RemoteRepos <- "https://cran.r-project.org"
  record$description$RemotePkgRef <- package
  record$description$RemoteRef <- package
  record$description$RemoteSha <- record$description$Version
  explicit_cran$packages[[package]] <- record
}
validate_manifest_policy(explicit_cran, DEPLOY_APP_FILES, check_checksums = TRUE)
compare_manifest_reproducibility(
  implicit_provenance, explicit_cran, DEPLOY_APP_FILES, check_checksums = TRUE)
compare_manifest_reproducibility(
  explicit_cran, implicit_provenance, DEPLOY_APP_FILES, check_checksums = TRUE)

explicit_rspm <- clone(explicit_cran)
for (package in names(explicit_rspm$packages)) {
  record <- explicit_rspm$packages[[package]]
  record$Repository <- MANIFEST_CANONICAL_RSPM_REPOSITORY
  record$description$Repository <- "RSPM"
  record$description$RemoteRepos <- MANIFEST_CANONICAL_RSPM_REPOSITORY
  record$description$RemotePkgPlatform <-
    MANIFEST_ALLOWED_REMOTE_PKG_PLATFORMS[[1L]]
  record$description$Built <-
    "R 4.5.9; x86_64-pc-linux-gnu; 2030-01-01 00:00:00 UTC; unix"
  explicit_rspm$packages[[package]] <- record
}
validate_manifest_policy(explicit_rspm, DEPLOY_APP_FILES, check_checksums = TRUE)
compare_manifest_reproducibility(
  implicit_provenance, explicit_rspm, DEPLOY_APP_FILES, check_checksums = TRUE)
compare_manifest_reproducibility(
  explicit_rspm, implicit_provenance, DEPLOY_APP_FILES, check_checksums = TRUE)

rspm_without_platform <- clone(explicit_rspm)
for (package in names(rspm_without_platform$packages))
  rspm_without_platform$packages[[package]]$description[
    MANIFEST_STANDARD_REMOTE_OPTIONAL_FIELDS] <- NULL
validate_manifest_policy(rspm_without_platform, DEPLOY_APP_FILES,
                         check_checksums = TRUE)
compare_manifest_reproducibility(
  implicit_provenance, rspm_without_platform, DEPLOY_APP_FILES,
  check_checksums = TRUE)

package <- names(explicit_cran$packages)[1L]
for (field in MANIFEST_STANDARD_REMOTE_CORE_FIELDS) {
  partial <- clone(explicit_cran)
  partial$packages[[package]]$description[[field]] <- NULL
  if (!expect_error(validate_manifest_policy(
        partial, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted missing explicit provenance field %s", field),
         call. = FALSE)
  singleton <- clone(implicit_provenance)
  singleton$packages[[package]]$description[[field]] <-
    explicit_cran$packages[[package]]$description[[field]]
  if (!expect_error(validate_manifest_policy(
        singleton, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted singleton provenance field %s", field),
         call. = FALSE)
}
platform_only <- clone(implicit_provenance)
platform_only$packages[[package]]$description$RemotePkgPlatform <-
  MANIFEST_ALLOWED_REMOTE_PKG_PLATFORMS[[1L]]
if (!expect_error(validate_manifest_policy(
      platform_only, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted platform metadata without core provenance",
       call. = FALSE)
null_platform <- clone(explicit_rspm)
null_platform$packages[[package]]$description["RemotePkgPlatform"] <- list(NULL)
if (!expect_error(validate_manifest_policy(
      null_platform, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a named null platform field", call. = FALSE)
invalid_platform_values <- list(
  empty = "",
  missing = NA_character_,
  wrong_os = "aarch64-apple-darwin20",
  near_miss = "x86_64-pc-linux-gnu-ubuntu-24.04.1",
  whitespace = "x86_64-pc-linux-gnu-ubuntu-24.04 ",
  vector = rep(MANIFEST_ALLOWED_REMOTE_PKG_PLATFORMS[[1L]], 2L))
for (case in names(invalid_platform_values)) {
  invalid <- clone(explicit_rspm)
  invalid$packages[[package]]$description$RemotePkgPlatform <-
    invalid_platform_values[[case]]
  if (!expect_error(validate_manifest_policy(
        invalid, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted invalid platform case %s", case),
         call. = FALSE)
}

null_provenance <- clone(explicit_cran)
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
  invalid <- clone(explicit_cran)
  invalid$packages[[package]]$description[[field]] <- invalid_values[[field]]
  if (!expect_error(validate_manifest_policy(
        invalid, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop(sprintf("manifest policy accepted invalid provenance field %s", field),
         call. = FALSE)
}
for (url in c("http://cran.r-project.org",
              "https://cran.r-project.org/path with space",
              "https://cran.r-project.org/path\ncontrol")) {
  invalid <- clone(explicit_cran)
  invalid$packages[[package]]$description$RemoteRepos <- url
  if (!expect_error(validate_manifest_policy(
        invalid, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop("manifest policy accepted an unsafe RemoteRepos URL", call. = FALSE)
}
rogue_fields <- c("RemoteHost", "RemoteRepo", "GithubRepo", "GitLabRepo",
                  "BitbucketRepo", "Remotes", "remotetype")
for (field in rogue_fields) {
  for (base in list(implicit_provenance, explicit_cran, explicit_rspm)) {
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
for (value in list("OTHER", "", NA_character_, c("CRAN", "RSPM"))) {
  core_drift <- clone(implicit_provenance)
  core_drift$packages[[package]]$description$Repository <- value
  if (!expect_error(validate_manifest_policy(
        core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
    stop("manifest policy accepted an invalid DESCRIPTION repository",
         call. = FALSE)
}
core_drift <- clone(implicit_provenance)
core_drift$packages[[package]]$description$Package <- "wrong-package"
if (!expect_error(validate_manifest_policy(
      core_drift, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted a package key/DESCRIPTION mismatch", call. = FALSE)

rspm_implicit <- clone(implicit_provenance)
rspm_implicit$packages[[package]]$description$Repository <- "RSPM"
if (!expect_error(validate_manifest_policy(
      rspm_implicit, DEPLOY_APP_FILES, check_checksums = TRUE)))
  stop("manifest policy accepted implicit RSPM provenance", call. = FALSE)
rspm_latest <- clone(explicit_rspm)
rspm_latest$packages[[package]]$description$RemoteRepos <-
  "https://packagemanager.posit.co/cran/latest"
if (!expect_error(validate_manifest_policy(
      rspm_latest, DEPLOY_APP_FILES, check_checksums = TRUE)) ||
    !expect_error(compare_manifest_reproducibility(
      implicit_provenance, rspm_latest, DEPLOY_APP_FILES,
      check_checksums = TRUE)))
  stop("manifest policy normalized an unpinned RSPM record", call. = FALSE)
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
