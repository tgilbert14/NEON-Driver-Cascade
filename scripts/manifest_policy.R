# Shared trusted policy for canonical deploy bytes and manifest validation.
# This file never deserializes an RDS payload, so a write-enabled publisher can
# source it without executing or interpreting data supplied by a build job.

MANIFEST_SCHEMA_VERSION <- 1L
MANIFEST_R_VERSION <- "4.5.2"
MANIFEST_ROOT_FIELDS <- c("version", "locale", "platform", "metadata",
                          "packages", "files", "users")
MANIFEST_METADATA_FIELDS <- c("appmode", "primary_rmd", "primary_html",
                              "content_category", "has_parameters")
MANIFEST_FATAL_PACKAGES <- c("neonUtilities", "arrow")
MANIFEST_BASE_PACKAGES <- c(
  "R", "base", "compiler", "datasets", "graphics", "grDevices", "grid",
  "methods", "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils")
MANIFEST_ALLOWED_REPOSITORY_HOSTS <- c(
  "cloud.r-project.org", "cran.r-project.org", "cran.rstudio.com",
  "packagemanager.posit.co")
MANIFEST_STANDARD_REMOTE_CORE_FIELDS <- c(
  "RemoteType", "RemoteRepos", "RemotePkgRef", "RemoteRef", "RemoteSha")
MANIFEST_STANDARD_REMOTE_OPTIONAL_FIELDS <- "RemotePkgPlatform"
MANIFEST_STANDARD_REMOTE_FIELDS <- c(
  MANIFEST_STANDARD_REMOTE_CORE_FIELDS,
  MANIFEST_STANDARD_REMOTE_OPTIONAL_FIELDS)
MANIFEST_ALLOWED_REMOTE_PKG_PLATFORMS <-
  "x86_64-pc-linux-gnu-ubuntu-24.04"
MANIFEST_CANONICAL_RSPM_REPOSITORY <-
  "https://packagemanager.posit.co/cran/__linux__/noble/2026-07-15"
MANIFEST_ALLOWED_SOURCE_LOCALES <- c("en_US", "C")

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x

.manifest_fail <- function(fmt, ...)
  stop(sprintf(fmt, ...), call. = FALSE)

.scalar_character <- function(x)
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)

.exact_names <- function(x, expected)
  is.list(x) && !is.null(names(x)) && !anyDuplicated(names(x)) &&
    setequal(names(x), expected) && length(names(x)) == length(expected)

normalize_rsconnect_manifest_locale <- function(manifest_text) {
  if (!.scalar_character(manifest_text))
    .manifest_fail("generated manifest text must be one nonempty string")
  if (!validUTF8(manifest_text))
    .manifest_fail("generated manifest text must be valid UTF-8")
  Encoding(manifest_text) <- "UTF-8"
  if (!requireNamespace("jsonlite", quietly = TRUE))
    .manifest_fail("jsonlite is required to normalize manifest locale")

  source_manifest <- tryCatch(
    jsonlite::fromJSON(manifest_text, simplifyVector = FALSE),
    error = function(error)
      .manifest_fail("cannot parse generated manifest before locale normalization: %s",
                     conditionMessage(error)))
  if (!.exact_names(source_manifest, MANIFEST_ROOT_FIELDS) ||
      !.scalar_character(source_manifest$locale) ||
      !(source_manifest$locale %in% MANIFEST_ALLOWED_SOURCE_LOCALES))
    .manifest_fail("generated manifest source locale is missing or unapproved")

  source_line <- sprintf('  "locale": "%s",', source_manifest$locale)
  matches <- gregexpr(source_line, manifest_text, fixed = TRUE)[[1L]]
  count <- if (length(matches) == 1L && identical(matches[[1L]], -1L)) 0L else length(matches)
  if (count != 1L)
    .manifest_fail("generated manifest must contain exactly one canonical root locale line")

  normalized_text <- sub(source_line, '  "locale": "en_US",',
                         manifest_text, fixed = TRUE)
  normalized_manifest <- tryCatch(
    jsonlite::fromJSON(normalized_text, simplifyVector = FALSE),
    error = function(error)
      .manifest_fail("cannot parse generated manifest after locale normalization: %s",
                     conditionMessage(error)))
  expected_manifest <- source_manifest
  expected_manifest$locale <- "en_US"
  if (!identical(normalized_manifest, expected_manifest))
    .manifest_fail("manifest locale normalization changed another field")
  normalized_text
}

.read_raw_file <- function(path) {
  info <- file.info(path)
  link <- Sys.readlink(path)
  if (nrow(info) != 1L || is.na(info$size) || !is.finite(info$size) || info$isdir ||
      (!is.na(link) && nzchar(link)))
    .manifest_fail("cannot stat regular deploy file: %s", path)
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, what = "raw", n = info$size)
}

.assert_regular_deploy_files <- function(files) {
  for (path in files) {
    link <- Sys.readlink(path)
    regular <- file_test("-f", path)
    if (!file.exists(path) || length(regular) != 1L || is.na(regular) || !regular ||
        (!is.na(link) && nzchar(link)))
      .manifest_fail("deploy entry is not a regular, non-symbolic-link file: %s", path)
  }
  invisible(TRUE)
}

.lf_raw <- function(bytes) {
  values <- as.integer(bytes)
  if (!length(values)) return(raw())
  out <- integer(length(values))
  i <- 1L
  j <- 1L
  while (i <= length(values)) {
    if (values[i] == 13L) {
      out[j] <- 10L
      if (i < length(values) && values[i + 1L] == 10L) i <- i + 1L
    } else {
      out[j] <- values[i]
    }
    i <- i + 1L
    j <- j + 1L
  }
  as.raw(out[seq_len(j - 1L)])
}

manifest_text_files <- function(files)
  files[grepl("\\.(r|css|js|csv)$", files, ignore.case = TRUE)]

canonicalize_deploy_text <- function(files) {
  for (path in manifest_text_files(files)) {
    if (!file.exists(path)) .manifest_fail("approved deploy file is missing: %s", path)
    before <- .read_raw_file(path)
    if (any(as.integer(before) == 0L))
      .manifest_fail("text deploy file contains a NUL byte: %s", path)
    if (!validUTF8(rawToChar(before)))
      .manifest_fail("text deploy file is not valid UTF-8: %s", path)
    after <- .lf_raw(before)
    if (!identical(before, after)) {
      con <- file(path, open = "wb")
      tryCatch(writeBin(after, con), finally = close(con))
      message("normalized CR/CRLF to canonical LF: ", path)
    }
  }
  invisible(files)
}

assert_canonical_deploy_text <- function(files) {
  for (path in manifest_text_files(files)) {
    bytes <- .read_raw_file(path)
    values <- as.integer(bytes)
    if (any(values == 0L)) .manifest_fail("text deploy file contains a NUL byte: %s", path)
    if (any(values == 13L)) .manifest_fail("text deploy file is not canonical LF: %s", path)
    if (!validUTF8(rawToChar(bytes)))
      .manifest_fail("text deploy file is not valid UTF-8: %s", path)
  }
  invisible(TRUE)
}

.literal_package <- function(x) {
  if (is.symbol(x)) return(as.character(x))
  if (is.character(x) && length(x) == 1L && !is.na(x)) return(x)
  NULL
}

.walk_package_refs <- function(node, refs = character()) {
  if (!is.call(node) && !is.expression(node) && !is.pairlist(node)) return(refs)
  parts <- as.list(node)
  if (is.call(node) && length(parts)) {
    op <- if (is.symbol(parts[[1L]])) as.character(parts[[1L]]) else ""
    if (op %in% c("::", ":::") && length(parts) >= 2L) {
      pkg <- .literal_package(parts[[2L]])
      if (!is.null(pkg)) refs <- c(refs, pkg)
    }
    if (op %in% c("library", "require", "requireNamespace", "loadNamespace",
                  "getNamespace", "asNamespace", "getExportedValue",
                  "packageVersion", "find.package") &&
        length(parts) >= 2L) {
      args <- parts[-1L]
      arg_names <- names(args) %||% rep("", length(args))
      idx <- match("package", arg_names, nomatch = 0L)
      target <- if (idx > 0L) args[[idx]] else args[[1L]]
      pkg <- .literal_package(target)
      if (!is.null(pkg)) refs <- c(refs, pkg)
    }
  }
  for (i in seq_along(parts)) {
    if (!identical(parts[[i]], quote(expr = ))) refs <- .walk_package_refs(parts[[i]], refs)
  }
  refs
}

manifest_direct_packages <- function(files) {
  r_files <- files[grepl("\\.r$", files, ignore.case = TRUE)]
  refs <- character()
  for (path in r_files) refs <- .walk_package_refs(parse(path, keep.source = FALSE), refs)
  sort(unique(refs), method = "radix")
}

.repository_host <- function(url) {
  if (!.scalar_character(url)) return(NA_character_)
  if (grepl("[[:space:][:cntrl:]]", url)) return(NA_character_)
  hit <- regexec("^https://([A-Za-z0-9.-]+)(?:/[^?#[:cntrl:]]*)?$", url, perl = TRUE)
  match <- regmatches(url, hit)[[1L]]
  if (length(match) >= 2L) tolower(match[2L]) else NA_character_
}

.trusted_repository <- function(url)
  .repository_host(url) %in% MANIFEST_ALLOWED_REPOSITORY_HOSTS

.validate_standard_cran_provenance <- function(description, package) {
  core_present <- MANIFEST_STANDARD_REMOTE_CORE_FIELDS %in% names(description)
  platform_present <- MANIFEST_STANDARD_REMOTE_OPTIONAL_FIELDS %in% names(description)
  provenance_names <- names(description)[grepl(
    "^(Remote|Github|GitLab|Bitbucket)", names(description),
    ignore.case = TRUE, perl = TRUE)]
  unexpected <- setdiff(provenance_names, MANIFEST_STANDARD_REMOTE_FIELDS)
  if (length(unexpected))
    .manifest_fail("unexpected package provenance field(s) for %s: %s",
                   package, paste(unexpected, collapse = ", "))
  if (any(core_present) && !all(core_present))
    .manifest_fail("partial standard CRAN provenance: %s", package)
  if (isTRUE(platform_present) && !all(core_present))
    .manifest_fail("RemotePkgPlatform requires explicit standard CRAN provenance: %s",
                   package)
  if (all(core_present) &&
      (!identical(description$RemoteType, "standard") ||
       !identical(description$RemotePkgRef, package) ||
       !identical(description$RemoteRef, package) ||
       !identical(description$RemoteSha, description$Version) ||
       !.trusted_repository(description$RemoteRepos)))
    .manifest_fail("explicit standard CRAN provenance is invalid: %s", package)
  if (isTRUE(platform_present) &&
      (!.scalar_character(description$RemotePkgPlatform) ||
       !(description$RemotePkgPlatform %in%
         MANIFEST_ALLOWED_REMOTE_PKG_PLATFORMS)))
    .manifest_fail("RemotePkgPlatform is invalid or untrusted: %s", package)
  if (identical(description$Repository, "RSPM") &&
      (!all(core_present) ||
       !identical(description$RemoteRepos,
                  MANIFEST_CANONICAL_RSPM_REPOSITORY)))
    .manifest_fail("RSPM provenance is not the canonical pinned snapshot: %s",
                   package)
  invisible(if (all(core_present)) "explicit" else "implicit")
}

.built_r_compatible <- function(built) {
  if (!.scalar_character(built)) return(FALSE)
  hit <- regexec("^R ([0-9]+)\\.([0-9]+)\\.[0-9]+; [^;[:cntrl:]]*; [^;[:cntrl:]]+; [^;[:cntrl:]]+$",
                 built, perl = TRUE)
  matched <- regmatches(built, hit)[[1L]]
  target <- strsplit(MANIFEST_R_VERSION, ".", fixed = TRUE)[[1L]]
  length(matched) == 3L && length(target) == 3L &&
    identical(matched[2:3], target[1:2])
}

.imports_package <- function(record, package) {
  description <- record$description
  text <- paste(c(description$Depends, description$Imports), collapse = ",")
  grepl(sprintf("(^|[,[:space:]])%s([[:space:](,]|$)", package), text,
        ignore.case = TRUE, perl = TRUE)
}

.manifest_dependencies <- function(record, package) {
  description <- record$description
  fields <- description[c("Depends", "Imports", "LinkingTo")]
  fields <- fields[!vapply(fields, is.null, logical(1))]
  if (!length(fields)) return(character())
  if (any(!vapply(fields, .scalar_character, logical(1))))
    .manifest_fail("manifest dependency metadata is malformed: %s", package)
  entries <- trimws(unlist(strsplit(unlist(fields, use.names = FALSE), ",", fixed = TRUE),
                           use.names = FALSE))
  entries <- entries[nzchar(entries)]
  pattern <- "^([A-Za-z][A-Za-z0-9.]*)[[:space:]]*(?:\\([^()]+\\))?$"
  hits <- regexec(pattern, entries, perl = TRUE)
  matches <- regmatches(entries, hits)
  if (any(lengths(matches) != 2L))
    .manifest_fail("manifest dependency metadata is malformed: %s", package)
  dependencies <- vapply(matches, `[`, character(1), 2L)
  sort(unique(dependencies[!tolower(dependencies) %in% tolower(MANIFEST_BASE_PACKAGES)]),
       method = "radix")
}

validate_manifest_library <- function(manifest) {
  if (!identical(as.character(getRversion()), MANIFEST_R_VERSION))
    .manifest_fail("runtime R version differs from manifest platform (runtime=%s manifest=%s)",
                   as.character(getRversion()), MANIFEST_R_VERSION)
  packages <- manifest$packages
  expected <- vapply(packages, function(record) record$description$Version, character(1))
  actual <- vapply(names(expected), function(package) {
    path <- suppressWarnings(find.package(package, quiet = TRUE))
    if (!length(path)) return(NA_character_)
    description <- tryCatch(
      suppressWarnings(utils::packageDescription(package, lib.loc = dirname(path))),
      error = function(e) NULL)
    version <- if (is.list(description)) description[["Version"]] else NULL
    if (.scalar_character(version)) version else NA_character_
  }, character(1))
  missing <- names(actual)[is.na(actual)]
  mismatched <- names(actual)[!is.na(actual) & actual != expected]
  if (length(missing))
    .manifest_fail("manifest package(s) missing from the runtime library: %s",
                   paste(missing, collapse = ", "))
  if (length(mismatched))
    .manifest_fail("runtime package version drift: %s",
                   paste(sprintf("%s=%s (manifest %s)", mismatched, actual[mismatched],
                                 expected[mismatched]), collapse = ", "))
  invisible(TRUE)
}

validate_manifest_policy <- function(manifest, deploy_files, check_checksums = TRUE) {
  missing <- deploy_files[!file.exists(deploy_files)]
  if (length(missing))
    .manifest_fail("approved deploy file(s) missing: %s", paste(missing, collapse = ", "))
  if (anyDuplicated(deploy_files) || any(!nzchar(deploy_files)))
    .manifest_fail("approved deploy file allowlist is empty or duplicated")
  .assert_regular_deploy_files(deploy_files)
  assert_canonical_deploy_text(deploy_files)

  if (!.exact_names(manifest, MANIFEST_ROOT_FIELDS))
    .manifest_fail("manifest root fields differ from the approved schema")
  if (!is.numeric(manifest$version) || length(manifest$version) != 1L ||
      is.na(manifest$version) ||
      !identical(as.numeric(manifest$version), as.numeric(MANIFEST_SCHEMA_VERSION)))
    .manifest_fail("manifest version must be %d", MANIFEST_SCHEMA_VERSION)
  if (!identical(manifest$locale, "en_US")) .manifest_fail("manifest locale must be en_US")
  if (!identical(manifest$platform, MANIFEST_R_VERSION))
    .manifest_fail("manifest R platform must be %s (found %s)", MANIFEST_R_VERSION,
                   manifest$platform %||% "<missing>")
  if (!is.null(manifest$users)) .manifest_fail("manifest users must be null")

  metadata <- manifest$metadata
  if (!.exact_names(metadata, MANIFEST_METADATA_FIELDS) ||
      !identical(metadata$appmode, "shiny") ||
      !is.null(metadata$primary_rmd) || !is.null(metadata$primary_html) ||
      !is.null(metadata$content_category) ||
      !is.logical(metadata$has_parameters) || length(metadata$has_parameters) != 1L ||
      is.na(metadata$has_parameters) || isTRUE(metadata$has_parameters))
    .manifest_fail("manifest metadata must describe a parameter-free Shiny app")

  entries <- manifest$files
  actual_files <- names(entries)
  if (!is.list(entries) || is.null(actual_files) || anyDuplicated(actual_files) ||
      !setequal(actual_files, deploy_files) || length(actual_files) != length(deploy_files)) {
    .manifest_fail("manifest deploy surface mismatch (missing: %s; unexpected: %s)",
                   paste(setdiff(deploy_files, actual_files), collapse = ", "),
                   paste(setdiff(actual_files, deploy_files), collapse = ", "))
  }
  for (path in deploy_files) {
    entry <- entries[[path]]
    if (!.exact_names(entry, "checksum") || !.scalar_character(entry$checksum) ||
        !grepl("^[0-9a-fA-F]{32}$", entry$checksum))
      .manifest_fail("manifest file record is malformed: %s", path)
  }

  packages <- manifest$packages
  package_names <- names(packages)
  if (!is.list(packages) || !length(packages) || is.null(package_names) ||
      any(!nzchar(package_names)) || anyDuplicated(tolower(package_names)))
    .manifest_fail("manifest packages must be a nonempty uniquely named object")
  if (any(!grepl("^[A-Za-z][A-Za-z0-9.]*$", package_names)))
    .manifest_fail("manifest contains an invalid package key")

  leaked <- package_names[tolower(package_names) %in% tolower(MANIFEST_FATAL_PACKAGES)]
  if (length(leaked))
    .manifest_fail("forbidden deploy package(s): %s", paste(leaked, collapse = ", "))

  for (package in package_names) {
    record <- packages[[package]]
    description <- if (is.list(record)) record$description else NULL
    if (!.exact_names(record, c("Source", "Repository", "description")) ||
        !identical(record$Source, "CRAN") || !.trusted_repository(record$Repository) ||
        !is.list(description) || is.null(names(description)) ||
        any(!nzchar(names(description))) || anyDuplicated(names(description)) ||
        !identical(description$Package, package) ||
        !.scalar_character(description$Version) ||
        !grepl("^[0-9]+(?:[.-][A-Za-z0-9]+)*$", description$Version, perl = TRUE) ||
        !.scalar_character(description$Repository) ||
        !(description$Repository %in% c("CRAN", "RSPM")) ||
        !.built_r_compatible(description$Built))
      .manifest_fail("manifest package record is incomplete or untrusted: %s", package)
    .validate_standard_cran_provenance(description, package)
  }
  dependency_map <- setNames(lapply(package_names, function(package)
    .manifest_dependencies(packages[[package]], package)), package_names)
  declared_lower <- tolower(package_names)
  missing_dependencies <- unique(unlist(lapply(package_names, function(package) {
    dependencies <- dependency_map[[package]]
    dependencies[!tolower(dependencies) %in% declared_lower]
  }), use.names = FALSE))
  if (length(missing_dependencies))
    .manifest_fail("mandatory recursive package dependency record(s) missing: %s",
                   paste(sort(missing_dependencies, method = "radix"), collapse = ", "))

  direct <- manifest_direct_packages(deploy_files)
  direct_external <- direct[!tolower(direct) %in% tolower(MANIFEST_BASE_PACKAGES)]
  missing_direct <- direct_external[!tolower(direct_external) %in% tolower(package_names)]
  if (length(missing_direct))
    .manifest_fail("direct runtime package reference(s) missing from manifest: %s",
                   paste(missing_direct, collapse = ", "))
  direct_fatal <- direct[tolower(direct) %in% tolower(MANIFEST_FATAL_PACKAGES)]
  if (length(direct_fatal))
    .manifest_fail("forbidden direct runtime package reference(s): %s",
                   paste(direct_fatal, collapse = ", "))
  if ("data.table" %in% tolower(direct))
    .manifest_fail("data.table is forbidden as a direct runtime dependency")
  if ("data.table" %in% tolower(package_names)) {
    plotly <- package_names[tolower(package_names) == "plotly"]
    if (length(plotly) != 1L || !.imports_package(packages[[plotly]], "data.table"))
      .manifest_fail("data.table may appear only as plotly's declared transitive dependency")
  }

  reachable <- character()
  queue <- package_names[match(tolower(direct_external), declared_lower, nomatch = 0L)]
  while (length(queue)) {
    package <- queue[[1L]]
    queue <- queue[-1L]
    if (package %in% reachable) next
    reachable <- c(reachable, package)
    dependencies <- dependency_map[[package]]
    indexes <- match(tolower(dependencies), declared_lower, nomatch = 0L)
    queue <- c(queue, package_names[indexes[indexes > 0L]])
  }
  unreachable <- setdiff(package_names, reachable)
  if (length(unreachable))
    .manifest_fail("manifest package graph contains unreachable package record(s): %s",
                   paste(sort(unreachable, method = "radix"), collapse = ", "))

  if (isTRUE(check_checksums)) {
    for (path in deploy_files) {
      expected <- entries[[path]]$checksum
      actual <- unname(tools::md5sum(path))
      if (!identical(tolower(expected), tolower(actual)))
        .manifest_fail("manifest checksum mismatch for %s (manifest=%s actual=%s)",
                       path, expected, actual)
    }
  }

  invisible(list(files = length(entries), packages = length(packages),
                 direct = direct_external))
}
# rsconnect records installation provenance (repository URL and Built metadata)
# in addition to the deploy contract. Those values legitimately differ between
# trusted Windows and Linux installations even when the locked runtime graph is
# identical. Both inputs are policy-validated before this projection is used.
.manifest_dependency_projection <- function(record) {
  fields <- c("Depends", "Imports", "LinkingTo")
  stats::setNames(lapply(fields, function(field) {
    value <- record$description[[field]]
    if (is.null(value)) return(character())
    entries <- trimws(unlist(strsplit(value, ",", fixed = TRUE), use.names = FALSE))
    entries <- gsub("[[:space:]]+", " ", entries)
    sort(unique(entries[nzchar(entries)]), method = "radix")
  }), fields)
}

manifest_reproducibility_projection <- function(manifest) {
  file_names <- sort(names(manifest$files), method = "radix")
  package_names <- sort(names(manifest$packages), method = "radix")
  files <- stats::setNames(vapply(file_names, function(path)
    tolower(manifest$files[[path]]$checksum), character(1)), file_names)
  packages <- stats::setNames(lapply(package_names, function(package) {
    record <- manifest$packages[[package]]
    list(
      source = record$Source,
      package = record$description$Package,
      version = record$description$Version,
      # CRAN and RSPM are equivalent labels only after the complete record has
      # independently passed the strict standard-CRAN provenance policy above.
      repository = "standard-CRAN",
      remote_type = "standard",
      remote_package = package,
      remote_ref = package,
      remote_sha = record$description$Version,
      dependencies = .manifest_dependency_projection(record))
  }), package_names)
  list(
    root = manifest[c("version", "locale", "platform", "users")],
    metadata = manifest$metadata[MANIFEST_METADATA_FIELDS],
    files = files,
    packages = packages)
}

compare_manifest_reproducibility <- function(baseline, candidate, deploy_files,
                                             check_checksums = TRUE) {
  validate_manifest_policy(baseline, deploy_files,
                           check_checksums = check_checksums)
  validate_manifest_policy(candidate, deploy_files,
                           check_checksums = check_checksums)
  expected <- manifest_reproducibility_projection(baseline)
  actual <- manifest_reproducibility_projection(candidate)
  sections <- c("root", "metadata", "files", "packages")
  changed <- sections[!vapply(sections, function(section)
    identical(expected[[section]], actual[[section]]), logical(1))]
  if (length(changed))
    .manifest_fail("manifest semantic reproducibility mismatch: %s",
                   paste(changed, collapse = ", "))
  invisible(list(files = length(expected$files),
                 packages = length(expected$packages)))
}