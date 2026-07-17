# ===========================================================================
# NEON Cross-Product Response Atlas — global.R
# The capstone of the NEONize family: a cross-product response atlas of
# direct weather-response associations, co-displayed by measurement layer.
# assembled from seven sibling apps' bundles (mammals, birds, plants, veg,
# phenology, mosquitoes, beetles). Short annual series, so the design STATES
# PRIORS and is n-gated.
# ===========================================================================
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(dplyr)
  library(plotly)
  library(htmltools)
  library(shinyjs)
  library(shinycssloaders)
  library(DT)
})
# The generated manifest is promoted last. Verifying its complete file map
# before sourcing local code or deserializing any RDS makes an interrupted
# multi-file promotion fail closed instead of serving a mixed generation.
.cascade_deploy_files <- c(
  "global.R",
  "ui.R",
  "server.R",
  "R/cascade_helpers.R",
  "R/site_metadata.R",
  "www/cascade.css",
  "www/cascade.js",
  "www/styles.css",
  "data/cascade.rds",
  "data/search_index.rds",
  "data/cascade_meta.rds",
  "data/neon-cascade-codebook.csv"
)
.cascade_integrity_fail <- function(fmt, ...) {
  stop(sprintf(
    "Runtime deploy integrity check failed: %s",
    sprintf(fmt, ...)
  ), call. = FALSE)
}
.cascade_verify_runtime_integrity <- function(
    manifest_path = "manifest.json",
    deploy_files = .cascade_deploy_files) {
  if (!requireNamespace("jsonlite", quietly = TRUE))
    .cascade_integrity_fail("jsonlite is unavailable.")

  manifest_info <- suppressWarnings(file.info(manifest_path, extra_cols = FALSE))
  manifest_link <- Sys.readlink(manifest_path)
  if (!file.exists(manifest_path) || nrow(manifest_info) != 1L ||
      is.na(manifest_info$isdir[[1L]]) || manifest_info$isdir[[1L]] ||
      (!is.na(manifest_link) && nzchar(manifest_link)))
    .cascade_integrity_fail("manifest.json is missing, linked, or not a regular file.")

  manifest <- tryCatch(
    jsonlite::fromJSON(manifest_path, simplifyVector = FALSE),
    error = function(e) {
      .cascade_integrity_fail("manifest.json is malformed: %s", conditionMessage(e))
    }
  )
  expected_root <- c(
    "version", "locale", "platform", "metadata", "packages", "files", "users"
  )
  root_names <- names(manifest)
  if (!is.list(manifest) || is.null(root_names) || anyNA(root_names) ||
      any(!nzchar(root_names)) || anyDuplicated(root_names) ||
      !setequal(root_names, expected_root))
    .cascade_integrity_fail("manifest root is malformed or differs from the approved schema.")

  records <- manifest$files
  record_names <- names(records)
  if (!is.list(records) || is.null(record_names) || !length(record_names) ||
      anyNA(record_names) || any(!nzchar(record_names)) || anyDuplicated(record_names))
    .cascade_integrity_fail("manifest file records are malformed.")

  missing <- setdiff(deploy_files, record_names)
  unexpected <- setdiff(record_names, deploy_files)
  if (length(missing) || length(unexpected))
    .cascade_integrity_fail(
      "manifest file surface differs (missing: %s; unexpected: %s).",
      if (length(missing)) paste(sort(missing, method = "radix"), collapse = ", ") else "none",
      if (length(unexpected)) paste(sort(unexpected, method = "radix"), collapse = ", ") else "none"
    )

  expected_md5 <- vapply(deploy_files, function(path) {
    record <- records[[path]]
    checksum <- if (is.list(record)) record$checksum else NULL
    if (!is.list(record) || !identical(names(record), "checksum") ||
        !is.character(checksum) || length(checksum) != 1L || is.na(checksum) ||
        !grepl("^[0-9a-f]{32}$", checksum))
      .cascade_integrity_fail("manifest checksum record is malformed for %s.", path)
    checksum
  }, character(1))

  info <- suppressWarnings(file.info(deploy_files, extra_cols = FALSE))
  links <- Sys.readlink(deploy_files)
  invalid <- !file.exists(deploy_files) | is.na(info$isdir) | info$isdir |
    (!is.na(links) & nzchar(links))
  if (any(invalid))
    .cascade_integrity_fail(
      "deploy path is missing, linked, or not a regular file: %s.",
      paste(deploy_files[invalid], collapse = ", ")
    )

  actual_md5 <- unname(tools::md5sum(deploy_files))
  mismatch <- is.na(actual_md5) | actual_md5 != unname(expected_md5)
  if (any(mismatch))
    .cascade_integrity_fail(
      "checksum mismatch for %s.",
      paste(deploy_files[mismatch], collapse = ", ")
    )
  invisible(TRUE)
}
.cascade_verify_runtime_integrity()
rm(.cascade_verify_runtime_integrity, .cascade_integrity_fail, .cascade_deploy_files)

eval(parse(file = "R/site_metadata.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
.cascade_runtime_ctype <- cascade_activate_utf8_ctype()
cascade_assert_artifact_text(neon_sites, "runtime site metadata")

CASCADE_PATH <- "data/cascade.rds"
if (!file.exists(CASCADE_PATH)) {
  stop("Required data bundle data/cascade.rds is missing; run scripts/rebuild_all.R.", call. = FALSE)
}
CASCADE <- tryCatch(readRDS(CASCADE_PATH), error = function(e) {
  stop(sprintf("Cannot read data/cascade.rds: %s", conditionMessage(e)), call. = FALSE)
})
cascade_assert_artifact_text(CASCADE, "data/cascade.rds")
required_bundle_parts <- c("annual", "signals", "priors", "suite_links", "pooled", "site_meta", "codebook", "meta")
missing_bundle_parts <- setdiff(required_bundle_parts, names(CASCADE))
if (length(missing_bundle_parts)) {
  stop(sprintf("cascade.rds is incomplete (missing: %s); run scripts/rebuild_all.R.",
               paste(missing_bundle_parts, collapse = ", ")), call. = FALSE)
}
if (!identical(CASCADE$meta$schema_version %||% "<unstamped>", CASCADE_BUNDLE_SCHEMA_VERSION)) {
  stop(sprintf("cascade.rds schema '%s' != code '%s' — run scripts/rebuild_all.R.",
               CASCADE$meta$schema_version %||% "<unstamped>", CASCADE_BUNDLE_SCHEMA_VERSION), call. = FALSE)
}
if (!identical(CASCADE$meta$prior_family_version %||% "<unstamped>", PRIOR_FAMILY_VERSION) ||
    !identical(CASCADE$meta$prior_family_status %||% "<unstamped>", PRIOR_FAMILY_STATUS)) {
  stop("cascade.rds has an unstamped or mismatched prior-family disclosure; run scripts/rebuild_all.R.",
       call. = FALSE)
}
if (!identical(CASCADE$meta$greenup_index_version %||% "<unstamped>", GREENUP_INDEX_VERSION) ||
    !identical(CASCADE$meta$greenup_index_note %||% "<unstamped>", GREENUP_INDEX_NOTE)) {
  stop("cascade.rds has missing or mismatched retrospective green-up lineage; run scripts/rebuild_all.R.",
       call. = FALSE)
}
.expected_source_snapshot_method <- "git-archive-recorded-commit-v1"
if (!identical(CASCADE$meta$source_snapshot_method %||% "<unstamped>",
               .expected_source_snapshot_method))
  stop("cascade.rds has missing or mismatched immutable-source lineage; run scripts/rebuild_all.R.",
       call. = FALSE)
.source_products <- CASCADE$meta$source_products
.source_inputs <- CASCADE$meta$source_inputs
.local_build_inputs <- CASCADE$meta$local_build_inputs
.build_toolchain <- CASCADE$meta$build_toolchain
.vote_overlap <- CASCADE$meta$vote_overlap
.expected_source_products <- c("mammal", "plant", "veg", "bird", "phe", "mosq", "beetle")
.expected_source_origins <- c(
  mammal = "github.com/tgilbert14/neon-small-mammal-tracker-app",
  plant = "github.com/tgilbert14/neon-plant-diversity",
  veg = "github.com/tgilbert14/neon-vegetation-structure-explorer",
  bird = "github.com/tgilbert14/neon-breeding-birds",
  phe = "github.com/tgilbert14/neon-plant-phenology-explorer",
  mosq = "github.com/tgilbert14/neon-mosquito-pulse",
  beetle = "github.com/tgilbert14/neon-ground-beetle-tracker")
.expected_local_build_paths <- c(
  "scripts/build_cascade.R", "scripts/generation_guard.R",
  "scripts/source_snapshot.R", "R/cascade_helpers.R",
  "R/site_metadata.R", "R/source_adapters.R")
if (!is.data.frame(.local_build_inputs) ||
    !identical(names(.local_build_inputs), c("relative_path", "md5")) ||
    !identical(as.character(.local_build_inputs$relative_path),
               .expected_local_build_paths) ||
    anyNA(.local_build_inputs$md5) ||
    !all(grepl("^[0-9a-f]{32}$", as.character(.local_build_inputs$md5))))
  stop("cascade.rds has malformed local executable-input lineage; run scripts/rebuild_all.R.",
       call. = FALSE)
.local_build_hashes <- stats::setNames(
  as.character(.local_build_inputs$md5),
  as.character(.local_build_inputs$relative_path))
if (!is.data.frame(.source_products) ||
    length(setdiff(c("product", "repo", "origin", "commit", "commit_epoch", "clean", "n_site_files"), names(.source_products))) ||
    !is.data.frame(.source_inputs) ||
    length(setdiff(c("product", "relative_path", "md5", "bytes"), names(.source_inputs))) ||
    !is.data.frame(.build_toolchain) ||
    length(setdiff(c("component", "version"), names(.build_toolchain))) ||
    !is.data.frame(.vote_overlap) ||
    length(setdiff(c("from", "to", "n_sites_eligible"), names(.vote_overlap))))
  stop("cascade.rds has incomplete source provenance or vote-overlap audit; run scripts/rebuild_all.R.",
       call. = FALSE)
if (nrow(.source_products) != length(.expected_source_products) ||
    !setequal(as.character(.source_products$product), .expected_source_products) ||
    anyDuplicated(as.character(.source_products$product)) ||
    anyNA(.source_products$repo) || any(!nzchar(as.character(.source_products$repo))) ||
    anyNA(.source_products$origin) || any(!nzchar(as.character(.source_products$origin))) ||
    !setequal(paste(.source_products$product, .source_products$origin, sep = "|"),
              paste(names(.expected_source_origins), .expected_source_origins, sep = "|")) ||
    !is.logical(.source_products$clean) || anyNA(.source_products$clean) ||
    !all(.source_products$clean) ||
    anyNA(.source_products$commit) ||
    !all(grepl("^[0-9a-f]{40}$", as.character(.source_products$commit))) ||
    !is.numeric(.source_products$commit_epoch) || anyNA(.source_products$commit_epoch) ||
    !all(is.finite(.source_products$commit_epoch) & .source_products$commit_epoch >= 0) ||
    !is.numeric(.source_products$n_site_files) || anyNA(.source_products$n_site_files) ||
    !all(is.finite(.source_products$n_site_files) &
         .source_products$n_site_files == floor(.source_products$n_site_files) &
         .source_products$n_site_files > 0) ||
    !nrow(.source_inputs) ||
    anyNA(.source_inputs$product) || any(!nzchar(as.character(.source_inputs$product))) ||
    !setequal(as.character(.source_inputs$product), .expected_source_products) ||
    anyNA(.source_inputs$relative_path) || any(!nzchar(as.character(.source_inputs$relative_path))) ||
    anyDuplicated(paste(.source_inputs$product, .source_inputs$relative_path, sep = "|")) ||
    anyNA(.source_inputs$md5) ||
    !all(grepl("^[0-9a-f]{32}$", as.character(.source_inputs$md5))) ||
    !is.numeric(.source_inputs$bytes) || anyNA(.source_inputs$bytes) ||
    !all(is.finite(.source_inputs$bytes) & .source_inputs$bytes >= 0 &
         .source_inputs$bytes == floor(.source_inputs$bytes)) ||
    nrow(.vote_overlap) != 2L ||
    anyDuplicated(paste(.vote_overlap$from, .vote_overlap$to, sep = "|")) ||
    !setequal(paste(.vote_overlap$from, .vote_overlap$to, sep = "|"),
              c("temp|greenup_doy", "temp_spring|greenup_doy")) ||
    !is.numeric(.vote_overlap$n_sites_eligible) || anyNA(.vote_overlap$n_sites_eligible) ||
    !all(is.finite(.vote_overlap$n_sites_eligible) &
         .vote_overlap$n_sites_eligible == floor(.vote_overlap$n_sites_eligible) &
         .vote_overlap$n_sites_eligible > 0) ||
    nrow(.build_toolchain) != 3L ||
    anyNA(.build_toolchain$component) || any(!nzchar(as.character(.build_toolchain$component))) ||
    anyDuplicated(as.character(.build_toolchain$component)) ||
    !setequal(as.character(.build_toolchain$component), c("R", "dplyr", "tibble")) ||
    anyNA(.build_toolchain$version) || any(!nzchar(as.character(.build_toolchain$version))))
  stop("cascade.rds source provenance, toolchain, or vote-overlap audit is malformed; run scripts/rebuild_all.R.",
       call. = FALSE)
.toolchain_versions <- stats::setNames(as.character(.build_toolchain$version),
                                      as.character(.build_toolchain$component))
.local_build_logic_mismatch <- any(vapply(
  .expected_local_build_paths, function(path)
    file.exists(path) &&
      !identical(unname(tools::md5sum(path)),
                 unname(.local_build_hashes[[path]])), logical(1)))
if (length(CASCADE$meta$build_script_md5) != 1L ||
    !grepl("^[0-9a-f]{32}$", CASCADE$meta$build_script_md5 %||% "") ||
    length(CASCADE$meta$source_adapters_md5) != 1L ||
    !grepl("^[0-9a-f]{32}$", CASCADE$meta$source_adapters_md5 %||% "") ||
    !identical(CASCADE$meta$build_script_md5,
               unname(.local_build_hashes[["scripts/build_cascade.R"]])) ||
    !identical(CASCADE$meta$source_adapters_md5,
               unname(.local_build_hashes[["R/source_adapters.R"]])) ||
    .local_build_logic_mismatch)
  stop("cascade.rds build-logic lineage differs from the running source; run scripts/rebuild_all.R.",
       call. = FALSE)
.expected_built_when <- format(
  as.POSIXct(max(.source_products$commit_epoch), origin = "1970-01-01", tz = "UTC"),
  "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
if (!identical(CASCADE$meta$built_when, .expected_built_when))
  stop("cascade.rds build timestamp does not match its source commits; run scripts/rebuild_all.R.",
       call. = FALSE)
if (!identical(CASCADE$meta$trend_sensitivity_version %||% "<unstamped>", TREND_SENSITIVITY_VERSION) ||
    !identical(CASCADE$meta$trend_sensitivity_note %||% "<unstamped>", TREND_SENSITIVITY_NOTE) ||
    !identical(CASCADE$meta$estimator_sensitivity_version %||% "<unstamped>", ESTIMATOR_SENSITIVITY_VERSION) ||
    !identical(CASCADE$meta$estimator_sensitivity_note %||% "<unstamped>", ESTIMATOR_SENSITIVITY_NOTE)) {
  stop("cascade.rds has missing or mismatched sensitivity lineage; run scripts/rebuild_all.R.",
       call. = FALSE)
}
if (!identical(CASCADE$meta$spatial_sensitivity_version %||% "<unstamped>", SPATIAL_SENSITIVITY_VERSION) ||
    !identical(CASCADE$meta$spatial_sensitivity_note %||% "<unstamped>", SPATIAL_SENSITIVITY_NOTE)) {
  stop("cascade.rds has missing or mismatched spatial-sensitivity lineage; run scripts/rebuild_all.R.",
       call. = FALSE)
}
# Stale-tiered-bundle guard (2026-06): refuse to boot on a bundle whose tier rule does not match
# the running code, so a change to link_stat()'s tier definition can never silently ride on a
# stale precompute (the incident that showed 7 "consistent" cells the circular-shift null no
# longer produces). Rebuild with: Rscript scripts/rebuild_all.R
if (!is.null(CASCADE) && exists("TIER_RULE_VERSION")) {
  .bundle_rule <- CASCADE$meta$tier_rule %||% "<unstamped>"
  if (!identical(.bundle_rule, TIER_RULE_VERSION))
    stop(sprintf("cascade.rds tier rule '%s' != code '%s' — run scripts/rebuild_all.R",
                 .bundle_rule, TIER_RULE_VERSION), call. = FALSE)
}
ANNUAL <- CASCADE$annual
SIGNALS <- CASCADE$signals
PRIORS <- CASCADE$priors
# Precomputed cross-site scoreboard, pooled summary, and site context.
SUITE_LINKS <- CASCADE$suite_links
POOLED <- CASCADE$pooled
SITE_META <- CASCADE$site_meta
# machine-readable codebook (emitted by build_cascade.R from the SIGNALS keep-vector).
# It is part of the required artifact contract; silently deriving a partial
# fallback would hide a mixed or incomplete rebuild.
CODEBOOK <- CASCADE$codebook

# Lightweight boot-time structural guard. The offline suite is deeper, but the
# deployed app should fail with one actionable message instead of discovering a
# malformed bundle only after a user opens a tab or requests a download.
.bundle_problem <- NULL
.need <- function(x, cols) setdiff(cols, names(x))
.signal_need <- c("key", "label", "layer", "unit", "higher_is", "ladder")
.annual_need <- unique(c("site", "year", as.character(SIGNALS$key), as.character(CODEBOOK$key)))
.suite_need <- c("site", "domain", "from", "to", "lag", "n", "r", "lo", "hi", "p", "p_floor",
                 "n_null", "series_span", "n_detrended", "r_detrended", "sign_match_detrended",
                 "n_change", "r_change", "sign_match_change", "n_outcome_alt", "r_outcome_alt",
                 "sign_match_outcome_alt", "prior_sign", "sign_match", "ci_excludes_zero", "tier",
                 "verdict", "expected", "expected_class", "conf", "note", "biome", "biome_class")
.prior_need <- c("from", "to", "lag", "sign", "expected_class", "conf", "note")
.pooled_need <- c("from", "to", "lag", "expected_class", "sites", "k", "p", "p_holm", "p_fdr",
                  "sites_detrended", "k_detrended", "sites_change", "k_change",
                   "sites_outcome_alt", "k_outcome_alt", "domains", "k_domain", "domain_ties",
                   "median_r", "poolable")
.miss <- c(.need(SIGNALS, .signal_need), .need(ANNUAL, .annual_need), .need(PRIORS, .prior_need),
           .need(SUITE_LINKS, .suite_need), .need(POOLED, .pooled_need),
           .need(SITE_META, c("site", "domain", "biome", "biome_class", "biome_label",
                              "biome_class_basis", "biome_class_method")),
           .need(CODEBOOK, c("key", "label", "unit", "na_meaning", "n_gate")))
if (length(.miss)) .bundle_problem <- sprintf("missing required field(s): %s", paste(unique(.miss), collapse = ", "))
if (is.null(.bundle_problem)) {
  .prior_id <- paste(PRIORS$from, PRIORS$to, PRIORS$lag, sep = "|")
  .suite_id <- paste(SUITE_LINKS$from, SUITE_LINKS$to, SUITE_LINKS$lag, sep = "|")
  .pooled_id <- paste(POOLED$from, POOLED$to, POOLED$lag, sep = "|")
  .annual_fields <- setdiff(names(ANNUAL), c("site", "year"))
  if (!nrow(SIGNALS) || !nrow(ANNUAL) || !nrow(PRIORS) || !nrow(SUITE_LINKS) ||
      !nrow(POOLED) || !nrow(SITE_META) || !nrow(CODEBOOK)) {
    .bundle_problem <- "one or more required bundle tables are empty"
  } else if (anyDuplicated(as.character(SIGNALS$key)) ||
             anyDuplicated(as.character(CODEBOOK$key)) ||
             anyDuplicated(as.character(SITE_META$site)) ||
             anyDuplicated(.prior_id) || anyDuplicated(.pooled_id)) {
    .bundle_problem <- "duplicate signal, codebook, site, prior, or pooled keys"
  } else if (!setequal(as.character(CODEBOOK$key), .annual_fields) ||
             !all(as.character(SIGNALS$key) %in% as.character(CODEBOOK$key))) {
    .bundle_problem <- "codebook and signal keys do not exactly cover annual fields"
  } else if (!is.numeric(PRIORS$sign) || anyNA(PRIORS$sign) ||
             !all(is.finite(PRIORS$sign) & PRIORS$sign %in% c(-1L, 1L)) ||
             !is.numeric(PRIORS$lag) || anyNA(PRIORS$lag) ||
             !all(is.finite(PRIORS$lag) & PRIORS$lag == floor(PRIORS$lag) & PRIORS$lag >= 0) ||
             anyNA(PRIORS$expected_class) ||
             !all(PRIORS$expected_class %in% c("all", "none")) ||
             anyNA(PRIORS$conf) || any(!nzchar(as.character(PRIORS$conf))) ||
             anyNA(PRIORS$note) || any(!nzchar(as.character(PRIORS$note)))) {
    .bundle_problem <- "prior signs, lags, confidence grades, notes, or eligibility classes violate the current build-locked contract"
  } else if (!setequal(unique(.suite_id), .prior_id) ||
             nrow(POOLED) != nrow(PRIORS) || !setequal(.pooled_id, .prior_id)) {
    .bundle_problem <- "suite/pooled link catalogs do not match the current build-locked pairings"
  } else {
    .suite_prior_row <- match(.suite_id, .prior_id)
    .pooled_prior_row <- match(.pooled_id, .prior_id)
    .expected_here <- PRIORS$expected_class[.suite_prior_row] != "none" &
      (PRIORS$expected_class[.suite_prior_row] == "all" |
         PRIORS$expected_class[.suite_prior_row] == SUITE_LINKS$biome_class)
    if (anyNA(.suite_prior_row) || anyNA(.pooled_prior_row) ||
        !is.numeric(SUITE_LINKS$prior_sign) || anyNA(SUITE_LINKS$prior_sign) ||
        !all(is.finite(SUITE_LINKS$prior_sign) & SUITE_LINKS$prior_sign %in% c(-1L, 1L)) ||
        anyNA(SUITE_LINKS$tier) ||
        !all(as.character(SUITE_LINKS$tier) %in% names(TIER_META)) ||
        anyNA(SUITE_LINKS$verdict) || any(!nzchar(as.character(SUITE_LINKS$verdict))) ||
        anyNA(SUITE_LINKS$conf) || any(!nzchar(as.character(SUITE_LINKS$conf))) ||
        anyNA(SUITE_LINKS$note) || any(!nzchar(as.character(SUITE_LINKS$note))) ||
        !is.numeric(POOLED$median_r) ||
        !all(is.na(POOLED$median_r) | is.finite(POOLED$median_r)) ||
        !identical(as.integer(SUITE_LINKS$prior_sign),
                   as.integer(PRIORS$sign[.suite_prior_row])) ||
        !identical(as.character(SUITE_LINKS$expected_class),
                   as.character(PRIORS$expected_class[.suite_prior_row])) ||
        !identical(as.character(SUITE_LINKS$conf),
                   as.character(PRIORS$conf[.suite_prior_row])) ||
        !identical(as.character(SUITE_LINKS$note),
                   as.character(PRIORS$note[.suite_prior_row])) ||
        !identical(as.logical(SUITE_LINKS$expected), as.logical(.expected_here)) ||
        !identical(as.character(POOLED$expected_class),
                   as.character(PRIORS$expected_class[.pooled_prior_row])))
      .bundle_problem <- "suite/pooled rows do not reproduce current build-locked fields and eligibility"
  }
}
if (is.null(.bundle_problem) && (anyDuplicated(paste(ANNUAL$site, ANNUAL$year, sep = "|")) ||
    anyDuplicated(paste(SUITE_LINKS$site, SUITE_LINKS$from, SUITE_LINKS$to, SUITE_LINKS$lag, sep = "|"))))
  .bundle_problem <- "duplicate annual site-years or suite site-prior rows"
if (is.null(.bundle_problem) && nrow(SUITE_LINKS) != length(unique(ANNUAL$site)) * nrow(PRIORS))
  .bundle_problem <- "suite is not a complete site × prior grid"
if (is.null(.bundle_problem) && !setequal(unique(ANNUAL$site), unique(SITE_META$site)))
  .bundle_problem <- "annual and bundled site metadata do not cover the same sites"
if (is.null(.bundle_problem)) {
  .domain_by_site <- stats::setNames(as.character(SITE_META$domain), SITE_META$site)
  .suite_domain <- unname(.domain_by_site[as.character(SUITE_LINKS$site)])
  if (anyNA(.suite_domain) || anyNA(SUITE_LINKS$domain) ||
      !identical(as.character(SUITE_LINKS$domain), .suite_domain))
    .bundle_problem <- "suite NEON-domain membership does not match bundled site metadata"
}
if (!is.null(.bundle_problem))
  stop(sprintf("cascade.rds failed its runtime contract (%s); run scripts/rebuild_all.R.", .bundle_problem), call. = FALSE)
# signals shown on the main ladder (seasonal climate signals are ladder=FALSE)
LADDER_KEYS <- if ("ladder" %in% names(SIGNALS)) SIGNALS$key[SIGNALS$ladder %in% TRUE] else SIGNALS$key

# ---- Search-the-atlas index (small, bundled, precomputed) -----------------------
# One small .rds loaded ONCE at boot, like site_index in the sibling apps; the Search
# tab filters it in memory (no live fetch, instant). Built by scripts/build_search_index.R
# from the committed cascade bundle. Holds: links (one row per site x prior, with the
# per-site diagnostics + registry eligibility), link_catalog (the autocomplete), site_strength
# (how many vote-eligible priors resolve per site), prior_pooled (the pooled screen).
SEARCH_INDEX_PATH <- "data/search_index.rds"
if (!file.exists(SEARCH_INDEX_PATH)) {
  stop("Required derived index data/search_index.rds is missing; run scripts/rebuild_all.R.", call. = FALSE)
}
SEARCH_IDX <- tryCatch(readRDS(SEARCH_INDEX_PATH), error = function(e) {
  stop(sprintf("Cannot read data/search_index.rds: %s", conditionMessage(e)), call. = FALSE)
})
cascade_assert_artifact_text(SEARCH_IDX, "data/search_index.rds")
# A stale search index is worse than no search: it can expose obsolete priors and
# p-values while every other tab reads the current bundle. Refuse to boot unless
# the index declares the current schema and fingerprints this exact cascade.rds.
.cascade_md5 <- unname(tools::md5sum(CASCADE_PATH))
.search_parts <- c("links", "link_catalog", "site_strength", "prior_pooled", "schema_version",
                   "source_bundle_md5", "source_bundle_rows", "source_bundle_priors",
                   "trend_sensitivity_version", "trend_sensitivity_note",
                   "estimator_sensitivity_version", "estimator_sensitivity_note",
                   "spatial_sensitivity_version", "spatial_sensitivity_note",
                   "greenup_index_version", "greenup_index_note")
.search_link_fields <- c("link_id", "site", "domain", "n", "r", "p", "p_floor", "n_null", "series_span",
                         "n_detrended", "r_detrended", "sign_match_detrended",
                         "n_change", "r_change", "sign_match_change",
                         "n_outcome_alt", "r_outcome_alt", "sign_match_outcome_alt",
                         "ci_excludes_zero", "tier", "year_min", "year_max", "site_year_min", "site_year_max")
.search_pooled_fields <- c("link_id", "sites", "k", "p_raw", "p_holm", "p_fdr", "median_r", "poolable",
                           "sites_detrended", "k_detrended", "sites_change", "k_change",
                           "sites_outcome_alt", "k_outcome_alt", "domains", "k_domain", "domain_ties")
if (length(setdiff(.search_parts, names(SEARCH_IDX))) ||
    length(setdiff(.search_link_fields, names(SEARCH_IDX$links))) ||
    length(setdiff(.search_pooled_fields, names(SEARCH_IDX$prior_pooled))) ||
    nrow(SEARCH_IDX$links) != nrow(SUITE_LINKS) ||
    !identical(SEARCH_IDX$schema_version, SEARCH_INDEX_SCHEMA_VERSION) ||
    !identical(SEARCH_IDX$source_bundle_md5, .cascade_md5) ||
    !identical(as.integer(SEARCH_IDX$source_bundle_rows), as.integer(nrow(SUITE_LINKS))) ||
    !identical(as.integer(SEARCH_IDX$source_bundle_priors), as.integer(nrow(PRIORS))) ||
    !identical(SEARCH_IDX$trend_sensitivity_version, TREND_SENSITIVITY_VERSION) ||
    !identical(SEARCH_IDX$trend_sensitivity_note, TREND_SENSITIVITY_NOTE) ||
    !identical(SEARCH_IDX$estimator_sensitivity_version, ESTIMATOR_SENSITIVITY_VERSION) ||
    !identical(SEARCH_IDX$estimator_sensitivity_note, ESTIMATOR_SENSITIVITY_NOTE) ||
    !identical(SEARCH_IDX$spatial_sensitivity_version, SPATIAL_SENSITIVITY_VERSION) ||
    !identical(SEARCH_IDX$spatial_sensitivity_note, SPATIAL_SENSITIVITY_NOTE) ||
    !identical(SEARCH_IDX$greenup_index_version, GREENUP_INDEX_VERSION) ||
    !identical(SEARCH_IDX$greenup_index_note, GREENUP_INDEX_NOTE)) {
  stop("data/search_index.rds is stale relative to data/cascade.rds; run scripts/rebuild_all.R.",
       call. = FALSE)
}
SRCH_LINKS <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$links else data.frame()
SRCH_CATALOG <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$link_catalog else data.frame()
SRCH_STR <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$site_strength else data.frame()
SRCH_POOLED <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$prior_pooled else data.frame()

# The companion meta-analysis is another derivative of cascade.rds. Treat it as
# a required, lineage-checked artifact rather than quietly displaying a stale
# effect estimate beside a freshly rebuilt sign test.
CASCADE_META_PATH <- "data/cascade_meta.rds"
if (!file.exists(CASCADE_META_PATH)) {
  stop("Required derived artifact data/cascade_meta.rds is missing; run scripts/rebuild_all.R.", call. = FALSE)
}
CASCADE_META <- tryCatch(readRDS(CASCADE_META_PATH), error = function(e) {
  stop(sprintf("Cannot read data/cascade_meta.rds: %s", conditionMessage(e)), call. = FALSE)
})
.expected_meta_inference_schema <- "cascade-meta-reml-knha-holm-prediction-v1"
.expected_meta_family <- c("temp|greenup_doy", "temp_spring|greenup_doy")
.meta_toolchain <- attr(CASCADE_META, "build_toolchain")
.meta_local_inputs <- attr(CASCADE_META, "local_meta_inputs")
.meta_source_local_build_inputs <- attr(CASCADE_META, "source_local_build_inputs")
.expected_local_meta_paths <- c(
  "scripts/cascade_meta.R", "scripts/generation_guard.R",
  "R/cascade_helpers.R")
.meta_local_inputs_ok <- is.data.frame(.meta_local_inputs) &&
  identical(names(.meta_local_inputs), c("relative_path", "md5")) &&
  identical(as.character(.meta_local_inputs$relative_path),
            .expected_local_meta_paths) &&
  !anyNA(.meta_local_inputs$md5) &&
  all(grepl("^[0-9a-f]{32}$", as.character(.meta_local_inputs$md5)))
.meta_local_hashes <- if (.meta_local_inputs_ok) stats::setNames(
  as.character(.meta_local_inputs$md5),
  as.character(.meta_local_inputs$relative_path)) else character()
.meta_local_logic_mismatch <- .meta_local_inputs_ok && any(vapply(
  .expected_local_meta_paths, function(path)
    file.exists(path) &&
      !identical(unname(tools::md5sum(path)),
                 unname(.meta_local_hashes[[path]])), logical(1)))
.meta_brms_run <- is.list(CASCADE_META) && any(vapply(
  CASCADE_META, function(x) is.list(x) && !is.null(x$brms), logical(1)))
.meta_expected_components <- c("R", "dplyr", "tibble", "metafor",
  if (.meta_brms_run) c("brms", "posterior"))
.meta_toolchain_ok <- is.data.frame(.meta_toolchain) &&
  !length(setdiff(c("component", "version"), names(.meta_toolchain))) &&
  nrow(.meta_toolchain) == length(.meta_expected_components) &&
  !anyDuplicated(as.character(.meta_toolchain$component)) &&
  setequal(as.character(.meta_toolchain$component), .meta_expected_components) &&
  !anyNA(.meta_toolchain$version) &&
  all(nzchar(as.character(.meta_toolchain$version)))
.meta_versions <- if (.meta_toolchain_ok) stats::setNames(
  as.character(.meta_toolchain$version),
  as.character(.meta_toolchain$component)) else character()
.meta_keys_ok <- is.list(CASCADE_META) && length(CASCADE_META) == 2L &&
  setequal(vapply(CASCADE_META, function(x)
    if (is.list(x)) paste(x$from %||% "", x$to %||% "", sep = "|") else "",
    character(1)), .expected_meta_family)
.meta_rows_ok <- .meta_keys_ok && all(vapply(CASCADE_META, function(x) {
  if (!is.list(x) || length(x$poolable) != 1L || is.na(x$poolable))
    return(FALSE)
  b <- x$brms
  if (!is.null(b)) {
    brms_ok <- is.list(b) &&
      identical(b$converged, TRUE) &&
      length(b$divergences) == 1L && identical(as.integer(b$divergences), 0L) &&
      length(b$pooled_r) == 1L && is.finite(b$pooled_r) &&
      b$pooled_r >= -1 && b$pooled_r <= 1 &&
      length(b$cri_r) == 2L && all(is.finite(b$cri_r)) &&
      b$cri_r[1] <= b$cri_r[2] && all(b$cri_r >= -1 & b$cri_r <= 1) &&
      length(b$posterior_prob_stated_direction) == 1L &&
      is.finite(b$posterior_prob_stated_direction) &&
      b$posterior_prob_stated_direction >= 0 &&
      b$posterior_prob_stated_direction <= 1
    if (!brms_ok) return(FALSE)
  }
  if (!isTRUE(x$poolable)) return(is.null(x$rma) && is.null(b))
  r <- x$rma
  need <- c("pooled_r", "ci_r", "pi_r", "se_z", "t_stat", "df",
            "p_one_sided", "p_one_sided_holm", "test_method",
            "inference_role", "I2", "tau2", "Q", "Q_p", "k")
  is.list(r) && !length(setdiff(need, names(r))) &&
    length(r$pooled_r) == 1L && is.finite(r$pooled_r) &&
    length(r$ci_r) == 2L && all(is.finite(r$ci_r)) &&
    r$ci_r[1] <= r$ci_r[2] &&
    length(r$pi_r) == 2L && all(is.finite(r$pi_r)) &&
    r$pi_r[1] <= r$pi_r[2] &&
    all(c(r$ci_r, r$pi_r, r$pooled_r) >= -1 &
          c(r$ci_r, r$pi_r, r$pooled_r) <= 1) &&
    length(r$se_z) == 1L && is.finite(r$se_z) && r$se_z > 0 &&
    length(r$t_stat) == 1L && is.finite(r$t_stat) &&
    length(r$k) == 1L && is.finite(r$k) && r$k >= 5 &&
    identical(as.integer(r$df), as.integer(r$k - 1L)) &&
    length(r$p_one_sided) == 1L && is.finite(r$p_one_sided) &&
    r$p_one_sided >= 0 && r$p_one_sided <= 1 &&
    length(r$p_one_sided_holm) == 1L && is.finite(r$p_one_sided_holm) &&
    r$p_one_sided_holm >= r$p_one_sided && r$p_one_sided_holm <= 1 &&
    identical(r$test_method,
              "REML random-effects with Knapp-Hartung inference") &&
    length(r$inference_role) == 1L && nzchar(r$inference_role) &&
    length(r$I2) == 1L && is.finite(r$I2) && r$I2 >= 0 && r$I2 <= 100 &&
    length(r$tau2) == 1L && is.finite(r$tau2) && r$tau2 >= 0 &&
    length(r$Q) == 1L && is.finite(r$Q) && r$Q >= 0 &&
    length(r$Q_p) == 1L && is.finite(r$Q_p) && r$Q_p >= 0 && r$Q_p <= 1
}, logical(1)))

if (!is.list(CASCADE_META) || length(CASCADE_META) != 2L ||
    !identical(attr(CASCADE_META, "schema_version"), CASCADE_META_SCHEMA_VERSION) ||
    !identical(attr(CASCADE_META, "inference_schema"),
               .expected_meta_inference_schema) ||
    !identical(attr(CASCADE_META, "multiplicity_method"), "holm") ||
    !identical(attr(CASCADE_META, "multiplicity_family"),
               .expected_meta_family) ||
    !.meta_toolchain_ok || !.meta_rows_ok ||
    !.meta_local_inputs_ok || .meta_local_logic_mismatch ||
    !identical(.meta_source_local_build_inputs, .local_build_inputs) ||
    !identical(attr(CASCADE_META, "source_snapshot_method"),
               CASCADE$meta$source_snapshot_method) ||
    !identical(attr(CASCADE_META, "source_bundle_md5"), .cascade_md5) ||
    !identical(attr(CASCADE_META, "source_bundle_schema"), CASCADE_BUNDLE_SCHEMA_VERSION) ||
    !identical(attr(CASCADE_META, "tier_rule"), TIER_RULE_VERSION) ||
    !identical(attr(CASCADE_META, "prior_family_version"), PRIOR_FAMILY_VERSION) ||
    !identical(attr(CASCADE_META, "prior_family_status"), PRIOR_FAMILY_STATUS) ||
    !identical(attr(CASCADE_META, "trend_sensitivity_version"), TREND_SENSITIVITY_VERSION) ||
    !identical(attr(CASCADE_META, "trend_sensitivity_note"), TREND_SENSITIVITY_NOTE) ||
    !identical(attr(CASCADE_META, "estimator_sensitivity_version"), ESTIMATOR_SENSITIVITY_VERSION) ||
    !identical(attr(CASCADE_META, "estimator_sensitivity_note"), ESTIMATOR_SENSITIVITY_NOTE) ||
    !identical(attr(CASCADE_META, "spatial_sensitivity_version"), SPATIAL_SENSITIVITY_VERSION) ||
    !identical(attr(CASCADE_META, "spatial_sensitivity_note"), SPATIAL_SENSITIVITY_NOTE) ||
    !identical(attr(CASCADE_META, "greenup_index_version"), GREENUP_INDEX_VERSION) ||
    !identical(attr(CASCADE_META, "greenup_index_note"), GREENUP_INDEX_NOTE) ||
    !identical(attr(CASCADE_META, "source_build_script_md5"),
               CASCADE$meta$build_script_md5) ||
    !identical(attr(CASCADE_META, "source_adapters_md5"),
               CASCADE$meta$source_adapters_md5) ||
    length(attr(CASCADE_META, "meta_script_md5")) != 1L ||
    !grepl("^[0-9a-f]{32}$", attr(CASCADE_META, "meta_script_md5") %||% "") ||
    !identical(attr(CASCADE_META, "meta_script_md5"),
               unname(.meta_local_hashes[["scripts/cascade_meta.R"]])) ||
    (file.exists("scripts/cascade_meta.R") &&
      !identical(attr(CASCADE_META, "meta_script_md5"),
                 unname(tools::md5sum("scripts/cascade_meta.R")))) ||
    !identical(attr(CASCADE_META, "r_version"), unname(.toolchain_versions[["R"]])) ||
    !identical(attr(CASCADE_META, "dplyr_version"), unname(.toolchain_versions[["dplyr"]])) ||
    !identical(attr(CASCADE_META, "tibble_version"), unname(.toolchain_versions[["tibble"]])) ||
    !identical(attr(CASCADE_META, "r_version"), unname(.meta_versions[["R"]])) ||
    !identical(attr(CASCADE_META, "dplyr_version"), unname(.meta_versions[["dplyr"]])) ||
    !identical(attr(CASCADE_META, "tibble_version"), unname(.meta_versions[["tibble"]])) ||
    !identical(attr(CASCADE_META, "metafor_version"), unname(.meta_versions[["metafor"]]))) {
  stop("data/cascade_meta.rds is stale relative to data/cascade.rds; run scripts/rebuild_all.R.", call. = FALSE)
}
# autocomplete choices: link label -> link_id (richest/most-confident priors first is fine;
# leave alphabetical for findability). Empty-safe.
search_link_choices <- function() {
  if (!nrow(SRCH_CATALOG)) {
    return(character(0))
  }
  stats::setNames(SRCH_CATALOG$link_id, SRCH_CATALOG$link_label)
}
# site short name for the result tables (falls back to the code)
srch_site_name <- function(code) {
  r <- neon_sites[neon_sites$site == code, ]
  if (nrow(r)) r$name[1] else code
}

site_annual <- function(site) ANNUAL[ANNUAL$site == site, , drop = FALSE]
site_bclass <- function(site) {
  r <- SITE_META[SITE_META$site == site, "biome_class", drop = TRUE]
  if (length(r) == 1L && !is.na(r) && nzchar(r)) as.character(r)
  else stop(sprintf("Bundled biome class is missing for site '%s'; run scripts/rebuild_all.R.", site), call. = FALSE)
}
site_blabel <- function(site) {
  r <- SITE_META[SITE_META$site == site, "biome_label", drop = TRUE]
  if (length(r) == 1L && !is.na(r) && nzchar(r)) as.character(r)
  else stop(sprintf("Bundled biome label is missing for site '%s'; run scripts/rebuild_all.R.", site), call. = FALSE)
}
site_bclass_basis <- function(site) {
  r <- SITE_META[SITE_META$site == site, "biome_class_basis", drop = TRUE]
  if (length(r) == 1L && !is.na(r) && nzchar(r)) as.character(r) else "classification basis unavailable"
}
site_bclass_method <- function(site) {
  r <- SITE_META[SITE_META$site == site, "biome_class_method", drop = TRUE]
  if (length(r) == 1L && !is.na(r) && nzchar(r)) as.character(r) else BIOME_CLASS_METHOD
}
is_desert <- function(site) identical(site_bclass(site), "water-limited")
# conditional woody structure (live basal area m2/ha) — intermittent per-site context
site_ba <- function(site) {
  r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_ha" %in% names(r) && is.finite(r$veg_ba_ha[1])) r$veg_ba_ha[1] else NA_real_
}
site_ba_se <- function(site) {
  r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_se" %in% names(r) && is.finite(r$veg_ba_se[1])) r$veg_ba_se[1] else NA_real_
}
# read the precomputed direct-pair rows for a site (no live recompute / permutations)
site_links_cached <- function(site) {
  if (nrow(SUITE_LINKS) && "site" %in% names(SUITE_LINKS)) {
    r <- SUITE_LINKS[SUITE_LINKS$site == site, , drop = FALSE]
    if (nrow(r)) {
      return(r)
    }
  }
  stop(sprintf("Precomputed link rows are missing for site '%s'; run scripts/rebuild_all.R.", site),
       call. = FALSE)
}

# layer count per site (for picker richness) + default to the richest
site_layer_count <- function(site) sum(layers_present(site_annual(site), SIGNALS))
ALL_SITES <- sort(unique(ANNUAL$site))
N_PRECIP_SITES <- length(unique(ANNUAL$site[is.finite(ANNUAL$precip)]))
SITE_LAYERS <- vapply(ALL_SITES, site_layer_count, integer(1))
# sites worth exploring = >=3 measurement layers; default to a richly covered site
# (one that actually has the phenology hinge — that's the point of the app)
RICH_SITES <- ALL_SITES[SITE_LAYERS >= 3]
.has_phen <- function(s) unname(layers_present(site_annual(s), SIGNALS)["phenology"])
DEFAULT_SITE <- {
  full <- ALL_SITES[vapply(ALL_SITES, .has_phen, logical(1)) & SITE_LAYERS >= 4]
  cand <- if (length(full)) full else if (length(RICH_SITES)) RICH_SITES else ALL_SITES
  # Default to SRER because the seasonal-rain aggregation problem is the app's
  # clearest teaching case. The choice is thematic, not selected for a favorable
  # statistic; all site-level results remain short-series screens.
  if ("SRER" %in% cand) {
    "SRER"
  } else if ("SCBI" %in% cand) {
    "SCBI"
  } else {
    sc <- vapply(cand, function(s) sum(vapply(SIGNALS$key, function(k) sum(is.finite(site_annual(s)[[k]])), integer(1))), integer(1))
    cand[which.max(sc)]
  }
}

# ---- Desert-night creative system (matches the DDL suite cover) -----------------
# Dark sky + teal/coral/gold. Key NAMES are kept (server.R references DDL$sky etc.),
# only the VALUES are remapped to the desert palette so the charts re-theme with one edit.
DDL <- list(
  navy = "#0e1d40", navy2 = "#16345e", teal = "#2dd4bf", bright = "#5eead4",
  cardinal = "#fb8a7e", coral = "#fb8a7e", gold = "#ffd24a", gold2 = "#e0b43a",
  sky = "#43b8e8", green = "#5fb56a", green2 = "#9bd24a",
  ink = "#eaf2ff", muted = "#9fb0cf", bg = "#070d1f", paper = "#0e1d40", line = "rgba(255,255,255,0.12)"
)
# Light "desert-day" base is the DEFAULT (input_dark_mode mode="light"); the user can
# toggle to the dark desert-night showcase. The navy hero command band stays navy in both.
# Avoid adding a startup font-fetching helper here: it can make cold starts depend on network availability.
# This system-only stack deliberately has no runtime network font dependency.
APP_FONT_STACK <- "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
APP_FONT_COLLECTION <- font_collection(
  "system-ui", "-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif")
app_theme <- bs_theme(
  version = 5, bg = "#eef3fb", fg = "#16243a",
  primary = "#0b6f68", secondary = "#b74338", success = "#287a3b", info = "#176b98",
  warning = "#9a7200", danger = "#b74338",
  base_font = APP_FONT_COLLECTION, heading_font = APP_FONT_COLLECTION,
  "border-radius" = "12px"
)

asset_url <- function(path) {
  f <- file.path("www", path)
  v <- if (file.exists(f)) as.integer(as.numeric(file.mtime(f))) else 0L
  sprintf("%s?v=%s", path, v)
}
spin <- function(x, ...) shinycssloaders::withSpinner(x, color = DDL$sky, type = 6)
info_pop <- function(title, ..., placement = "auto") {
  bslib::popover(
    tags$span(class = "info-dot", `aria-label` = paste("More information:", title),
              title = title, bsicons::bs_icon("info-circle")),
    ..., title = title, placement = placement
  )
}

# ---- Sources panel: the literature behind every prior + method (About tab) ----
# Folded by default so it informs without overwhelming. Grouped to the priors/methods.
cascade_sources <- function() {
  ref <- function(...) tags$li(htmltools::HTML(paste0(...)))
  grp <- function(title, ...) htmltools::tagList(tags$h4(title), tags$ol(...))
  div(
    class = "about-card", h3(bsicons::bs_icon("journal-text"), " Sources"),
    tags$p(
      class = "src-lead",
      "The displayed directions and lags are literature-motivated contrasts locked for this build, not claims that every cited review establishes a universal signed linear response. The family evolved while these data were inspected, so it is not preregistered; non-green-up pairings are context-only and every estimate remains exploratory. Selected references:"
    ),
    tags$details(
      class = "src-panel",
      tags$summary(bsicons::bs_icon("book"), " Show the reference list"),
      div(
        class = "src-body",
        grp(
          "Candidate bottom-up pathway framing (conceptual; no cascade is tested here)",
          ref("Power (1992). Top-down and bottom-up forces in food webs. <i>Ecology</i>."),
          ref("Polis, Sears, Huxel, Strong &amp; Maron (2000). When is a trophic cascade a trophic cascade? <i>TREE</i>."),
          ref("Hunter &amp; Price (1992). Playing chutes and ladders: bottom-up and top-down forces. <i>Ecology</i>.")
        ),
        grp(
          "Dryland rain, resources, and granivore dynamics (contextual; often complex/nonlinear)",
          ref("Meserve, Kelt, Milstead &amp; Guti&eacute;rrez (2003). Thirteen years of shifting top-down and bottom-up control. <i>BioScience</i>."),
          ref("Previtali, Lima, Meserve, Kelt &amp; Guti&eacute;rrez (2009). Population dynamics of two sympatric rodents in a variable environment. <i>Ecology</i>."),
          ref("Brown &amp; Ernest (2002). Rain and rodents: complex dynamics of desert consumers. <i>BioScience</i>."),
          ref("Ernest, Brown &amp; Parmenter (2000). Rodents, plants, and precipitation. <i>Oikos</i>."),
          ref("Holmgren et al. (2006). Extreme climatic events shape arid and semiarid ecosystems. <i>Front. Ecol. Environ.</i>"),
          ref("Holmgren, Scheffer, Ezcurra, Guti&eacute;rrez &amp; Mohren (2001). El Ni&ntilde;o effects on terrestrial ecosystems. <i>TREE</i>.")
        ),
        grp(
          "Precipitation to plant production / richness",
          ref("Noy-Meir (1973). Desert ecosystems: environment and producers. <i>Annu. Rev. Ecol. Syst.</i>"),
          ref("Huxman et al. (2004). Convergence across biomes to a common rain-use efficiency. <i>Nature</i>.")
        ),
        grp(
          "Temperature / spring warmth to green-up onset (phenology priors)",
          ref("Richardson et al. (2013). Climate change, phenology, and phenological control of vegetation feedbacks. <i>Agric. For. Meteorol.</i>"),
          ref("Cleland, Chuine, Menzel, Mooney &amp; Schwartz (2007). Shifting plant phenology in response to global change. <i>TREE</i>."),
          ref("Piao et al. (2019). Plant phenology and global climate change. <i>Glob. Change Biol.</i>")
        ),
        grp(
          "Temperature / rain and mosquito traits (context-only; not a universal positive catch response)",
          ref("Ciota, Matacchiero, Kilpatrick &amp; Kramer (2014). Effect of temperature on life-history traits of Culex mosquitoes. <i>J. Med. Entomol.</i>"),
          ref("Shaman &amp; Day (2007). Reproductive phase locking of mosquito populations in response to rainfall. <i>PLoS ONE</i>.")
        ),
        grp(
          "Temperature / moisture and ground-beetle ecology (context-only; effort denominator is incomplete)",
          ref("Thiele (1977). <i>Carabid Beetles in Their Environments</i>. Springer."),
          ref("L&ouml;vei &amp; Sunderland (1996). Ecology and behavior of ground beetles. <i>Annu. Rev. Entomol.</i>.")
        ),
        grp(
          "Why we post NO green-up to bird prior (cited for the absence)",
          ref("Both, Bouwhuis, Lessells &amp; Visser (2006). Climate change and population declines in a migratory bird. <i>Nature</i>."),
          ref("Visser &amp; Both (2005). Shifts in phenology: the need for a yardstick. <i>Proc. R. Soc. B</i>."),
          ref("Cole, Long, Zelazowski, Szulkin &amp; Sheldon (2015). Predicting bird phenology from satellite green-up. <i>Ecol. Evol.</i> (see also Mayor et al. 2017; Youngflesh et al. 2021).")
        ),
        grp(
          "Inference methods",
          ref("Edgington &amp; Onghena (2007). <i>Randomization Tests</i> (4th ed.). Permutation test for tiny-n correlation."),
          ref("Politis &amp; Romano (1992). <a href='https://statistics.stanford.edu/technical-reports/circular-block-resampling-procedure-stationary-data' target='_blank' rel='noopener'>A circular block-resampling procedure for stationary data</a>. In <i>Exploring the Limits of Bootstrap</i>, pp. 263&ndash;270."),
          ref("Sokal &amp; Rohlf (1995). <i>Biometry</i> (3rd ed.). Binomial sign test for direction agreement."),
          ref("Pickett (1989). Space-for-time substitution. In <i>Long-Term Studies in Ecology</i>."),
          ref("Damgaard (2019). A critique of the space-for-time substitution practice. <i>TREE</i>.")
        ),
        grp(
          "Continental design (NEON macrosystems)",
          ref("Keller, Schimel, Hargrove &amp; Hoffman (2008). A continental strategy for NEON. <i>Front. Ecol. Environ.</i>"),
          ref("Heffernan et al. (2014). Macrosystems ecology. <i>Front. Ecol. Environ.</i>")
        )
      )
    )
  )
}

# ---- the suite huddle: a tiny cluster of sibling mascots (the cascade has no single
# creature, so it gets a "tiny suite" — a consumer, a flier, and a producer — used once
# as a first-visit onboarding nudge in the corner). Flat, no-gradient, reused-safe SVGs. ----
MASCOT_HUDDLE <- htmltools::HTML('<span class="cg-mascots" aria-hidden="true"><svg class="mascot mascot-bird" viewBox="0 0 120 120"><g fill="#f0b94a"><path d="M54,30 L57,16 L62,30 Z"/><path d="M62,30 L65,14 L70,30 Z"/></g><ellipse cx="60" cy="66" rx="32" ry="33" fill="#ffce5a"/><ellipse cx="60" cy="76" rx="19" ry="21" fill="#fff3d6"/><g class="mascot-ear-l"><path d="M30,58 Q14,66 22,86 Q34,80 40,64 Z" fill="#e0714a"/></g><g class="mascot-ear-r"><path d="M90,58 Q106,66 98,86 Q86,80 80,64 Z" fill="#e0714a"/></g><path d="M54,68 L66,68 L60,80 Z" fill="#f0993a"/><g class="mascot-eyes"><circle cx="50" cy="60" r="6.5" fill="#2a160a"/><circle cx="70" cy="60" r="6.5" fill="#2a160a"/><circle cx="48" cy="57.5" r="2.4" fill="#fff"/><circle cx="68" cy="57.5" r="2.4" fill="#fff"/></g></svg><svg class="mascot mascot-mouse" viewBox="0 0 120 120"><g class="mascot-ear-l"><circle cx="42" cy="34" r="14" fill="#5aa0d8"/><circle cx="43" cy="36" r="8" fill="#ffd24a"/></g><g class="mascot-ear-r"><circle cx="78" cy="34" r="14" fill="#5aa0d8"/><circle cx="77" cy="36" r="8" fill="#ffd24a"/></g><path d="M88,82 Q110,94 113,72" fill="none" stroke="#5a93c8" stroke-width="4" stroke-linecap="round"/><ellipse cx="60" cy="66" rx="32" ry="33" fill="#5aa0d8"/><ellipse cx="60" cy="76" rx="20" ry="22" fill="#eaf2ff"/><path d="M55,70 Q60,68 65,70 Q62,77 60,77 Q58,77 55,70 Z" fill="#fb8a7e"/><g class="mascot-eyes"><circle cx="50" cy="60" r="6.5" fill="#0a1a2e"/><circle cx="70" cy="60" r="6.5" fill="#0a1a2e"/><circle cx="48" cy="57.5" r="2.4" fill="#fff"/><circle cx="68" cy="57.5" r="2.4" fill="#fff"/></g></svg><svg class="mascot mascot-sprout" viewBox="0 0 120 120"><path d="M60,60 L60,30" stroke="#4aa050" stroke-width="4" stroke-linecap="round"/><g class="mascot-ear-l"><path d="M60,36 C40,24 24,30 22,46 C40,52 56,46 60,36 Z" fill="#5fd16a"/></g><g class="mascot-ear-r"><path d="M60,36 C80,24 96,30 98,46 C80,52 64,46 60,36 Z" fill="#5fd16a"/></g><ellipse cx="60" cy="76" rx="28" ry="26" fill="#d8cf9e"/><g class="mascot-eyes"><circle cx="51" cy="72" r="6" fill="#3a2a12"/><circle cx="69" cy="72" r="6" fill="#3a2a12"/><circle cx="49" cy="69.5" r="2.2" fill="#fff"/><circle cx="67" cy="69.5" r="2.2" fill="#fff"/></g></svg></span>')

# ---- concept glossary: a tappable ⓘ that explains a term in plain English ----
# cpop("trophic") drops a small info dot that pops the definition. Sprinkled on the
# concepts a newcomer hits first (the trophic-layer boxes, lag, z-score, biome…).
CONCEPT <- list(
  trophic   = list(t = "Measurement layer", b = "A visual group for related annual signals: weather, green-up timing, plant observations, or animal observations. Stacking these layers does not test a food-web path or mediation."),
  climate   = list(t = "Weather summaries", b = "Complete annual or named seasonal temperature and precipitation summaries. They are candidate explanatory variables, not automatically antecedent exposures or proven drivers."),
  phenology = list(t = "Green-up timing index", b = "A DOY-anchored, composition-adjusted index from bounded, non-left-censored onset-interval midpoint estimates. Repeated species are centered on their own timing and weighted equally; smaller means earlier, but the value is not a pooled observed date. Excluding left-censored records avoids treating upper bounds as dates, but it is not an interval-censored model and can select observations according to visit timing and cadence."),
  producer  = list(t = "Plant observations", b = "Plant richness, cover, and fruiting summaries. Richness is composition, not productivity, and the current atlas has no defensible annual production or seed-resource rung for a mediated cascade test."),
  consumer  = list(t = "Animal detection and catch summaries", b = "Small-mammal and mosquito summaries use explicit trapping effort. The bird index divides detections by observed point-count occasions and may omit zero-detection visits; the beetle denominator contains catch-bearing events only. These are not interchangeable abundance measures, and seasonal climate labels do not imply a matched response window."),
  lag       = list(t = "A lag", b = "A calendar offset. A 1-year lag pairs this year's candidate driver with next year's response. The offset encodes a proposed pathway; annual alignment does not prove that pathway. Named seasonal climate windows are separate signals."),
  zscore    = list(t = "Standardised (z-score)", b = "Each signal is rescaled so 0 = its own average year and +1 = one standard deviation above. Signals in different units can then share one axis, so you compare the TIMING of the bumps, not their heights."),
  biome     = list(t = "Descriptive site-group heuristic", b = "The internal water-/temperature-limited key is not measured climate or resource limitation. It is a keyword rule over the one-line site bio: desert, sagebrush, or semi-desert enters the dryland group; every other site enters the default group. Current vote-eligible green-up links include all sites; the group remains descriptive context."),
  signmatch = list(t = "Direction match", b = "Does a direct pairwise association point in its stated literature-motivated direction? Within a site this is descriptive because links reuse years and variables. Cross-site raw-level signs are shown with detrended and consecutive-change sensitivities."),
  expected  = list(t = "“Vote-eligible”", b = "A direct association allowed to enter the exploratory site-vote summary. Most displayed plant and animal pairings are context-only because their effort, response window, proxy, or directional basis is not strong enough for inferential voting."),
  pulse     = list(t = "The year trace", b = "Choose a year to inspect direct pairings available then. A response layer marks whether it moved in the stated direction. This one-year view is an anecdote, not a recursively inferred food-web path or evidence by itself."),
  standing  = list(t = "Conditional woody structure", b = "Live basal area (m²/ha) is averaged only among plots containing qualifying stem records. The source cannot distinguish sampled-zero from unsampled plots, so zero-stem and unobserved plots are not imputed; plot-support denominators remain visible. This intermittent structural context is neither site-wide standing stock, annual productivity, nor a causal rung."),
  permp     = list(t = "The permutation p", b = "A gap-aware circular-shift null: the response is rotated over the full calendar grid, with missing years retained, to preserve order, annual spacing, and its gap pattern while breaking the original alignment. Its exact floor is 1/(valid null shifts + 1), reported per link. It is a coarse diagnostic, not a per-site significance claim and does not set the verdict. Across-site exact-binomial p-values are reported raw and Holm-adjusted."),
  bootci    = list(t = "The bootstrap interval", b = "Circular moving-block bootstrap interval (wide at this n; indicative, not a precision claim). It resamples contiguous wrapped blocks on the full calendar grid, retaining missing years, to preserve annual spacing and short-range temporal structure while showing how unstable the relationship is.")
)
cpop <- function(key, placement = "auto") {
  c <- CONCEPT[[key]]
  if (is.null(c)) {
    return(NULL)
  }
  bslib::popover(
    tags$span(class = "concept-i", `aria-label` = paste("More information:", c$t),
              title = c$t, bsicons::bs_icon("info-circle")),
    tags$p(c$b), title = c$t, placement = placement
  )
}
insight_banner <- function(icon, ..., tone = "navy") {
  div(class = paste("chart-insight", paste0("ci-", tone)), bsicons::bs_icon(icon), div(class = "ci-text", ...))
}
# section-to-section handoff chip (turns parallel tabs into a guided sequence)
handoff <- function(label, tab) {
  div(
    class = "tab-handoff",
    tags$a(
      href = "#", class = "handoff-chip",
      `data-shiny-input` = "gotoTab", `data-shiny-value` = tab,
      label, " ", bsicons::bs_icon("arrow-right-circle-fill")
    )
  )
}
card_head <- function(icon, title, ...) {
  bslib::card_header(class = "with-info",
    tags$h3(class = "ch-title", bsicons::bs_icon(icon), " ", title), ...)
}
fmt_int <- function(x) format(round(as.numeric(x)), big.mark = ",", trim = TRUE)
sig_label <- function(k) {
  r <- SIGNALS[SIGNALS$key == k, ]
  if (nrow(r)) r$label[1] else k
}
sig_unit <- function(k) {
  r <- SIGNALS[SIGNALS$key == k, ]
  if (nrow(r)) r$unit[1] else ""
}
# compact label for the dense cross-site scoreboard
sig_abbr <- function(k) {
  m <- c(
    temp = "Temp", precip = "Rain", precip_winter = "Winter rain",
    precip_monsoon = "Monsoon", temp_spring = "Spring temp", greenup_doy = "Green-up", fruiting_pct = "Fruiting",
    plant_richness = "Richness", plant_intro_pct = "Invasion", mammal_cpue = "Rodents", mammal_mnka = "Rodents",
    bird_index = "Birds", bird_richness = "Bird rich.",
    mosq_activity = "Mosquitoes", beetle_activity = "Beetles"
  )
  if (k %in% names(m)) unname(m[k]) else k
}

# ---- Pulse Tracer: for a selected climate year t0, which direct prior links respond? ----
pulse_direction <- function(z) {
  if (length(z) != 1L || !is.finite(z) || abs(z) <= sqrt(.Machine$double.eps))
    return(NA_integer_)
  as.integer(sign(z))
}
# Follows available annual and seasonal climate signals over direct prior links. Uses
# the SAME ladder_layer() z-scores the static ladder draws (one z implementation, no
# drift). verdict = did the response at t0+lag move the way the prior predicts, GIVEN
# this year's driver anomaly? predicted response sign = sign(prior_sign * driver_z).
pulse_paths <- function(ann_site, t0, biome = NULL) {
  if (is.null(t0) || is.na(t0)) {
    return(NULL)
  }
  z <- do.call(rbind, Filter(Negate(is.null), lapply(
    c("climate", "phenology", "producer", "consumer"),
    function(L) ladder_layer(ann_site, SIGNALS, L)
  )))
  # Seasonal climate drivers stay off the crowded timeline. Add their z-scores
  # to the lookup for contextual plotting, while the registry's `all`/`none`
  # contract below ensures context-only rows never animate as vote-eligible paths.
  seasonal_keys <- intersect(c("precip_winter", "precip_monsoon", "temp_spring"), names(ann_site))
  seasonal_z <- lapply(seasonal_keys, function(k) {
    v <- ann_site[[k]]
    if (sum(is.finite(v)) < 3) return(NULL)
    data.frame(year = ann_site$year, key = k, label = sig_label(k), raw = v,
               z = zscore(v), stringsAsFactors = FALSE)
  })
  seasonal_z <- do.call(rbind, Filter(Negate(is.null), seasonal_z))
  if (!is.null(seasonal_z) && nrow(seasonal_z)) z <- rbind(z, seasonal_z)
  if (is.null(z) || !nrow(z)) {
    return(NULL)
  }
  zv <- function(key, yr) {
    v <- z$z[z$key == key & z$year == yr]
    if (length(v)) v[1] else NA_real_
  }
  climate_keys <- intersect(c("precip", "temp", "precip_winter", "precip_monsoon", "temp_spring"), unique(z$key))
  rows <- lapply(seq_len(nrow(PRIORS)), function(i) {
    pr <- PRIORS[i, ]
    if ("expected_class" %in% names(PRIORS)) {
      ec <- PRIORS$expected_class[i]
      if (!is.na(ec) && !identical(as.character(ec), "all")) {
        return(NULL)
      }
    }
    if (!(pr$from %in% climate_keys)) {
      return(NULL)
    }
    zf <- zv(pr$from, t0)
    if (!is.finite(zf)) {
      return(NULL)
    }
    zt <- zv(pr$to, t0 + pr$lag)
    src_direction <- pulse_direction(zf)
    dst_direction <- pulse_direction(zt)
    predicted <- if (is.na(src_direction)) NA_integer_ else as.integer(pr$sign * src_direction)
    verdict <- if (!is.finite(zt)) "nodata"
      else if (is.na(predicted) || is.na(dst_direction)) "neutral"
      else if (dst_direction == predicted) "match" else "miss"
    data.frame(
      from = pr$from, to = pr$to, lag = pr$lag, src_z = round(zf, 2),
      dst_year = t0 + pr$lag, dst_z = if (is.finite(zt)) round(zt, 2) else NA_real_,
      verdict = verdict, stringsAsFactors = FALSE
    )
  })
  do.call(rbind, Filter(Negate(is.null), rows))
}

# site dropdown choices, most measurement layers first ("SRER — Santa Rita … (4 layers)")
cascade_site_choices <- function() {
  ord <- order(-SITE_LAYERS, ALL_SITES)
  s <- ALL_SITES[ord]
  lay <- SITE_LAYERS[ord]
  nm <- vapply(seq_along(s), function(i) {
    row <- neon_sites[neon_sites$site == s[i], ]
    sprintf("%s · %s · %d layer%s", s[i], if (nrow(row)) row$name[1] else s[i], lay[i], if (lay[i] == 1) "" else "s")
  }, character(1))
  stats::setNames(s, nm)
}
