#!/usr/bin/env Rscript

# Synthetic-only executable contract for Discharge feasibility Gate F0.
# Discharge/opportunity fixtures are invented and contain no NEON payload or
# ecological response value. The direct-boundary fixture contains only the frozen
# two-column, values-free response authority embedded by the pure contract.

source("scripts/discharge_feasibility_contract.R", local = TRUE)

fail <- function(message) stop(message, call. = FALSE)

expect_true <- function(value, message) {
  if (!identical(value, TRUE)) fail(message)
}

expect_identical <- function(actual, expected, message) {
  if (!identical(actual, expected))
    fail(sprintf("%s\nactual: %s\nexpected: %s", message,
                 paste(capture.output(str(actual)), collapse = " "),
                 paste(capture.output(str(expected)), collapse = " ")))
}

expect_error_code <- function(fun, expected, message) {
  error <- tryCatch({
    fun()
    NULL
  }, discharge_f0_error = function(e) e)
  if (is.null(error)) fail(sprintf("%s: expected error %s", message, expected))
  if (!identical(error$code, expected))
    fail(sprintf("%s: expected %s, got %s", message, expected, error$code))
  invisible(error)
}

utc <- function(x) {
  value <- as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  attr(value, "tzone") <- "UTC"
  value
}

recycle <- function(x, n) {
  if (!n) return(x[FALSE])
  rep_len(x, n)
}

corrected_table <- function(site = character(), location = character(),
                            time = character(), value = numeric(),
                            final = 0, science = 0, correction = 0) {
  n <- length(time)
  data.frame(
    siteID = as.character(recycle(site, n)),
    namedLocation = as.character(recycle(location, n)),
    endDateTime = utc(time),
    dischargeContinuous = as.numeric(recycle(value, n)),
    dischargeFinalQF = as.numeric(recycle(final, n)),
    dischargeFinalQFSciRvw = as.numeric(recycle(science, n)),
    dischargeCorrectionApplied = as.numeric(recycle(correction, n)),
    stringsAsFactors = FALSE)
}

legacy_table <- function(site = character(), location = character(),
                         time = character(), value = numeric(),
                         final = 0, science = 0) {
  n <- length(time)
  data.frame(
    siteID = as.character(recycle(site, n)),
    namedLocation = as.character(recycle(location, n)),
    endDate = utc(time),
    maxpostDischarge = as.numeric(recycle(value, n)),
    dischargeFinalQF = as.numeric(recycle(final, n)),
    dischargeFinalQFSciRvw = as.numeric(recycle(science, n)),
    stringsAsFactors = FALSE)
}

inverts_table <- function(site = character(), time = character(),
                          water_type = "stream", eligible = TRUE) {
  n <- length(time)
  data.frame(
    siteID = as.character(recycle(site, n)),
    collectDate = utc(time),
    aquaticSiteType = as.character(recycle(water_type, n)),
    density_eligible = as.logical(recycle(eligible, n)),
    synthetic_outcome_must_be_ignored = I(recycle(list(stop), n)),
    stringsAsFactors = FALSE)
}

empty_corrected <- corrected_table()
empty_legacy <- legacy_table()
empty_inverts <- inverts_table()

# Three exact sites x six common UTC calendar years clears only the review gate.
primary_sites <- c("ARIK", "BIGC", "BLUE")
legacy_grid <- expand.grid(
  siteID = primary_sites, year = 2018:2020,
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
corrected_grid <- expand.grid(
  siteID = primary_sites, year = 2021:2023,
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
legacy <- legacy_table(
  legacy_grid$siteID, paste0(legacy_grid$siteID, ".AOS"),
  sprintf("%d-06-30T12:00:00Z", legacy_grid$year), value = 1)
corrected <- corrected_table(
  corrected_grid$siteID, paste0(corrected_grid$siteID, ".AOS"),
  sprintf("%d-12-01T12:00:00Z", corrected_grid$year), value = 1,
  correction = rep(c(0, 1), length.out = nrow(corrected_grid)))
response_grid <- expand.grid(
  siteID = primary_sites, year = 2018:2023,
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
inverts <- inverts_table(
  response_grid$siteID,
  sprintf("%d-07-15T08:30:00Z", response_grid$year))

passed <- discharge_feasibility_contract_from_opportunities(
  corrected, legacy, inverts)
expect_identical(passed$contract_version, DISCHARGE_F0_CONTRACT_VERSION,
                 "contract version is frozen")
expect_identical(passed$primary_gate$decision, "REOPEN_REVIEW",
                 "three sites x six years reopens review only")
expect_identical(passed$primary_gate$human_disposition,
                 "REOPEN INDEPENDENT REVIEW",
                 "review token maps to the frozen human disposition")
expect_identical(passed$primary_gate$n_common_primary_site_years, 18L,
                 "primary common support count")
expect_identical(passed$primary_gate$n_sites_clearing_primary_floor, 3L,
                 "primary site floor count")
expect_true(all(passed$primary_gate$site_support$n_common_primary_years == 6L),
            "each primary site has six distinct common years")
expect_identical(
  names(passed$primary_gate$response_anchored_primary_ledger),
  DISCHARGE_F0_RESPONSE_LEDGER_FIELDS,
  "primary response-anchored ledger has the exact frozen fields")
expect_identical(
  nrow(passed$primary_gate$response_anchored_primary_ledger), 18L,
  "primary ledger retains every response site-year")
expect_true(all(
  passed$primary_gate$response_anchored_primary_ledger$
    discharge_site_year_present) && all(
  passed$primary_gate$response_anchored_primary_ledger$
    qc_pass_record_present_in_utc_year),
  "all fully supported response anchors retain explicit TRUE states")
expect_true(!passed$app_path_called && !passed$effect_path_called &&
              !passed$estimator_path_called && !passed$prior_path_called &&
              !passed$vote_path_called && !passed$driver_artifact_path_called,
            "all app/estimator/effect/prior/vote/artifact paths remain false")
expect_true(all(!passed$sensitivity_counts$can_change_primary_decision),
            "sensitivities are structurally non-rescuing")

# The primary ledger is total over response authority: a five-year site remains
# below the floor and an exact response site with no discharge row remains with
# explicit FALSE/FALSE states and a zero count.
boundary_response <- rbind(
  passed$inverts_site_years[
    passed$inverts_site_years$siteID %in% c("ARIK", "BIGC"), , drop = FALSE],
  head(passed$inverts_site_years[
    passed$inverts_site_years$siteID == "BLUE", , drop = FALSE], 5L),
  data.frame(siteID = "CARI", utc_calendar_year = 2022L,
             stringsAsFactors = FALSE))
boundary_response <- boundary_response[order(
  boundary_response$siteID, boundary_response$utc_calendar_year,
  method = "radix"), , drop = FALSE]
rownames(boundary_response) <- NULL
boundary_gate <- discharge_f0_evaluate_gate(
  passed$discharge$site_years, boundary_response)
expect_identical(boundary_gate$decision, "HOLD",
                 "two six-year sites plus one five-year site remains HOLD")
expect_identical(boundary_gate$human_disposition, "HOLD / DO NOT BUILD",
                 "HOLD token maps to the frozen human disposition")
expect_identical(boundary_gate$n_response_sites_evaluated, 4L,
                 "all four response sites are counted, including zero support")
expect_identical(
  boundary_gate$site_support$n_common_primary_years[
    boundary_gate$site_support$siteID == "BLUE"], 5L,
  "five common years stays strictly below the six-year floor")
expect_identical(
  boundary_gate$site_support$n_common_primary_years[
    boundary_gate$site_support$siteID == "CARI"], 0L,
  "response site with no discharge support remains an explicit zero")
false_anchor <- boundary_gate$response_anchored_primary_ledger[
  boundary_gate$response_anchored_primary_ledger$siteID == "CARI", ,
  drop = FALSE]
expect_identical(false_anchor$discharge_site_year_present, FALSE,
                 "absent discharge site-year is explicit FALSE")
expect_identical(false_anchor$qc_pass_record_present_in_utc_year, FALSE,
                 "absent discharge site-year cannot become QC support")
expect_true(is.na(false_anchor$source_regime),
            "absent discharge site-year has no invented source regime")

# File and row order cannot change any public values-free output.
reordered <- discharge_feasibility_contract_from_opportunities(
  corrected[rev(seq_len(nrow(corrected))), , drop = FALSE],
  legacy[rev(seq_len(nrow(legacy))), , drop = FALSE],
  inverts[rev(seq_len(nrow(inverts))), , drop = FALSE])
expect_identical(reordered, passed, "contract output is row-order invariant")

# Output cannot expose raw record timestamps or either discharge field.
recursive_names <- function(x) {
  if (!is.list(x)) return(character())
  unique(c(names(x), unlist(lapply(x, recursive_names), use.names = FALSE)))
}
public_names <- recursive_names(passed)
forbidden_public <- c(
  "records", "utc_timestamp", "dischargeContinuous", "maxpostDischarge",
  "sample_density_m2", "total_estimated_count")
expect_true(!any(forbidden_public %in% public_names),
            "public result contains no raw timestamp or ecological value field")

# A finite QC-clear zero qualifies; missing, nonfinite, flagged, and unreviewed
# corrected records stay active opportunities but do not qualify.
state_times <- sprintf("2022-01-%02dT00:00:00Z", 1:7)
state_table <- corrected_table(
  rep("SYCA", 7), rep("SYCA.AOS", 7), state_times,
  value = c(0, NA, Inf, 4, 5, 6, 7),
  final = c(0, 0, 0, 1, 0, 0, 0),
  science = c(NA, 0, 0, 0, 1, 0, 0),
  correction = c(0, 0, 0, 0, 0, 1, NA))
states <- discharge_f0_project_discharge(state_table, empty_legacy)
state_year <- states$site_years[1L, , drop = FALSE]
expect_identical(state_year$n_active_published_records, 7L,
                 "all published active rows remain opportunities")
expect_identical(state_year$n_usable_records, 2L,
                 "only finite zero and finite reviewed correction qualify")
expect_identical(state_year$qc_pass_record_present_in_utc_year, TRUE,
                 "finite QC-clear zero establishes record presence")
expect_identical(state_year$n_active_published_utc_days, 7L,
                 "active day diagnostic is values-free")
expect_identical(state_year$n_usable_utc_days, 2L,
                 "usable day diagnostic is values-free")

# Historical and corrected regimes remain explicit, including a mixed UTC year.
mixed <- discharge_f0_project_discharge(
  corrected_table("ARIK", "ARIK.AOS", "2021-12-01T00:00:00Z", 1),
  legacy_table("ARIK", "ARIK.AOS", "2021-01-01T00:00:00Z", 1))
expect_identical(mixed$site_years$source_regime,
                 "mixed_corrected_and_historical",
                 "a transition calendar year preserves both source regimes")
october <- discharge_f0_project_discharge(
  corrected_table("ARIK", "ARIK.AOS", "2023-10-01T00:00:00Z", 1),
  empty_legacy)
expect_identical(october$site_water_years$water_year, 2024L,
                 "UTC October 1 belongs to the ending water-year label")

# Exact Inverts projection uses only eligible rows classified exactly as stream.
response_fixture <- inverts_table(
  c("ARIK", "ARIK", "BIGC", "BLUE", "SYCA", "TECR", "WLOU"),
  c("2020-01-01T00:00:00Z", "2020-06-01T00:00:00Z",
    "2021-01-01T00:00:00Z", "2022-01-01T00:00:00Z",
    "2023-01-01T00:00:00Z", "2023-02-01T00:00:00Z",
    "2023-03-01T00:00:00Z"),
  water_type = c(
    "stream", "stream", "river", "wadeable stream", "stream", NA, "stream"),
  eligible = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, NA))
response_reduction <- .discharge_f0_reduce_inverts(response_fixture)
response_projection <- response_reduction$site_years
expect_identical(response_projection,
                 data.frame(siteID = "ARIK", utc_calendar_year = 2020L,
                            stringsAsFactors = FALSE),
                 "Inverts projector is exact-stream, eligible, UTC-year, distinct")
expect_identical(
  response_reduction$projection_receipt,
  data.frame(
    state = DISCHARGE_F0_INVERTS_PROJECTION_STATES,
    n_rows = c(2L, 1L, 1L, 1L, 2L), stringsAsFactors = FALSE),
  "Inverts projection emits a bounded, exhaustive five-state row receipt")
expect_identical(sum(response_reduction$projection_receipt$n_rows),
                 nrow(response_fixture),
                 "Inverts projection receipt accounts for every input row")

# TOOK's two named locations are retained only long enough for explicit gate
# exclusion. TOMB may appear in response authority but never in either main
# discharge table.
took <- corrected_table(
  c("TOOK", "TOOK"), c("TOOK.INFLOW", "TOOK.OUTFLOW"),
  c("2022-01-01T00:00:00Z", "2022-01-01T00:15:00Z"), c(1, 1))
special_discharge <- discharge_f0_project_discharge(took, empty_legacy)
special_inverts <- discharge_f0_project_inverts(inverts_table(
  c("TOOK", "TOMB"),
  c("2022-07-01T00:00:00Z", "2022-07-01T00:00:00Z")))
special_gate <- discharge_f0_evaluate_gate(
  special_discharge$site_years, special_inverts)
expect_identical(special_gate$decision, "HOLD",
                 "special sites cannot clear the primary gate")
expect_identical(special_gate$n_common_primary_site_years, 0L,
                 "special sites contribute no primary common year")
expect_true(all(special_gate$excluded_site_counts$n_inverts_site_years == 1L),
            "TOMB and TOOK exclusions are explicit")
expect_identical(
  special_gate$excluded_site_counts$reason,
  c("tomb_requires_separate_contract",
    "took_requires_named_location_crosswalk"),
  "special-site exclusions retain their exact registered reason tokens")

# Two otherwise eligible sites remain HOLD; sensitivity receipts cannot rescue.
two_site <- passed$discharge$site_years[
  passed$discharge$site_years$siteID %in% primary_sites[1:2], , drop = FALSE]
two_response <- passed$inverts_site_years[
  passed$inverts_site_years$siteID %in% primary_sites[1:2], , drop = FALSE]
two_gate <- discharge_f0_evaluate_gate(two_site, two_response)
expect_identical(two_gate$decision, "HOLD",
                 "two sites x six years remains HOLD")
expect_identical(two_gate$n_sites_clearing_primary_floor, 2L,
                 "HOLD still reports the exact support count")

# Empty, schema-valid sources are scientific absence rather than acquisition
# failure and therefore yield HOLD.
empty_result <- discharge_feasibility_contract_from_opportunities(
  empty_corrected, empty_legacy, empty_inverts)
expect_identical(empty_result$primary_gate$decision, "HOLD",
                 "empty valid source family is HOLD")
expect_identical(
  empty_result$inverts_projection_receipt,
  .discharge_f0_empty_inverts_receipt(),
  "empty opportunity family still emits every stable projection state")

# The production-facing contract consumes the committed two-column values-free
# ledger directly and asserts the frozen 210-row / 24-site / 23-at-floor roster.
authority_panel <- .discharge_f0_expected_inverts_panel()
expect_true(discharge_f0_assert_exact_inverts_authority(authority_panel),
            "exact response authority assertion accepts every frozen site-year")
direct_boundary <- discharge_feasibility_contract(
  empty_corrected, empty_legacy, authority_panel)
expect_identical(direct_boundary$primary_gate$n_response_sites_evaluated, 24L,
                 "direct values-free boundary retains all 24 response sites")
expect_true(all(
  !direct_boundary$primary_gate$response_anchored_primary_ledger$
    discharge_site_year_present),
  "direct values-free boundary retains 210 explicit false discharge states")
expect_true(all(direct_boundary$primary_gate$site_support$
                  n_common_primary_years == 0L),
            "direct values-free boundary counts all zero-support sites")
authority_short <- authority_panel[-1L, , drop = FALSE]
expect_error_code(
  function() discharge_f0_assert_exact_inverts_authority(authority_short),
  "response_210_24_23_mismatch", "exact response roster count drift")
authority_wrong_year <- authority_panel
authority_wrong_year$utc_calendar_year[[1L]] <- 2001L
expect_error_code(
  function() discharge_f0_assert_exact_inverts_authority(authority_wrong_year),
  "response_210_24_23_mismatch",
  "same-count response roster with a wrong year fails closed")

# Fail-closed adversarial source and key fixtures.
# RELEASE-2026 chronology is exact at both ordinary and BIGC cutovers.
ordinary_boundary <- discharge_f0_project_discharge(
  corrected_table(
    "ARIK", "ARIK.AOS", "2021-10-01T00:00:00Z", 1),
  legacy_table(
    "ARIK", "ARIK.AOS", "2021-09-30T23:59:59Z", 1))
expect_identical(ordinary_boundary$site_years$source_regime,
                 "mixed_corrected_and_historical",
                 "ordinary cutover accepts corrected at and legacy before boundary")
bigc_boundary <- discharge_f0_project_discharge(
  corrected_table(
    "BIGC", "BIGC.AOS", "2020-10-01T00:00:00Z", 1),
  legacy_table(
    "BIGC", "BIGC.AOS", "2020-09-30T23:59:59Z", 1))
expect_identical(bigc_boundary$site_years$source_regime,
                 "mixed_corrected_and_historical",
                 "BIGC has the exact earlier WY2021 cutover")
ordinary_early_corrected <- corrected_table(
  "ARIK", "ARIK.AOS", "2021-09-30T23:59:59Z", 1)
expect_error_code(
  function() discharge_f0_project_discharge(
    ordinary_early_corrected, empty_legacy),
  "source_regime_chronology_mismatch",
  "ordinary corrected row before RELEASE-2026 cutover")
ordinary_late_legacy <- legacy_table(
  "ARIK", "ARIK.AOS", "2021-10-01T00:00:00Z", 1)
expect_error_code(
  function() discharge_f0_project_discharge(
    empty_corrected, ordinary_late_legacy),
  "source_regime_chronology_mismatch",
  "ordinary legacy row at RELEASE-2026 cutover")
bigc_early_corrected <- corrected_table(
  "BIGC", "BIGC.AOS", "2020-09-30T23:59:59Z", 1)
expect_error_code(
  function() discharge_f0_project_discharge(
    bigc_early_corrected, empty_legacy),
  "source_regime_chronology_mismatch", "BIGC corrected row before its cutover")
bigc_late_legacy <- legacy_table(
  "BIGC", "BIGC.AOS", "2020-10-01T00:00:00Z", 1)
expect_error_code(
  function() discharge_f0_project_discharge(
    empty_corrected, bigc_late_legacy),
  "source_regime_chronology_mismatch", "BIGC legacy row at its cutover")

# TOMB is rejected before the main-table value and QC predicates can inspect or
# classify its deliberately malformed measurement/QC fields.
tomb_corrected <- corrected_table(
  "TOMB", "TOMB.AOS", "2022-01-01T00:00:00Z", 1)
tomb_corrected$dischargeContinuous <- "not-main-table-data"
tomb_corrected$dischargeFinalQF <- 2
expect_error_code(
  function() discharge_f0_project_discharge(tomb_corrected, empty_legacy),
  "tomb_requires_separate_contract", "TOMB corrected-table short circuit")
tomb_legacy <- legacy_table(
  "TOMB", "TOMB.AOS", "2020-01-01T00:00:00Z", 1)
tomb_legacy$maxpostDischarge <- "not-main-table-data"
tomb_legacy$dischargeFinalQF <- 2
expect_error_code(
  function() discharge_f0_project_discharge(empty_corrected, tomb_legacy),
  "tomb_requires_separate_contract", "TOMB legacy-table short circuit")
tomb_special_shape <- data.frame(siteID = "TOMB", stringsAsFactors = FALSE)
expect_error_code(
  function() discharge_f0_project_discharge(
    tomb_special_shape, empty_legacy),
  "tomb_requires_separate_contract",
  "TOMB is rejected before ordinary main-table schema projection")
bad_other_table_qc <- corrected_table(
  "ARIK", "ARIK.AOS", "2022-01-01T00:00:00Z", 1, final = 2)
expect_error_code(
  function() discharge_f0_project_discharge(bad_other_table_qc, tomb_legacy),
  "tomb_requires_separate_contract",
  "TOMB family preflight occurs before another table's QC inspection")

duplicate <- corrected_table(
  c("ARIK", "ARIK"), c("ARIK.AOS", "ARIK.AOS"),
  c("2022-01-01T00:00:00Z", "2022-01-01T00:00:00Z"), c(1, 1))
expect_error_code(
  function() discharge_f0_project_discharge(duplicate, empty_legacy),
  "duplicate_source_key", "duplicate source key")

overlap_corrected <- corrected_table(
  "ARIK", "ARIK.AOS", "2021-06-01T00:00:00Z", 1)
overlap_legacy <- legacy_table(
  c("ARIK", "ARIK"), c("ARIK.AOS", "ARIK.AOS"),
  c("2021-01-01T00:00:00Z", "2021-12-01T00:00:00Z"), c(1, 1))
expect_error_code(
  function() discharge_f0_project_discharge(
    overlap_corrected, overlap_legacy),
  "source_regime_chronology_mismatch",
  "cross-table overlap is preempted by exact source chronology")

ambiguous <- corrected_table(
  c("ARIK", "ARIK"), c("ARIK.AOS", "ARIK.OTHER"),
  c("2022-01-01T00:00:00Z", "2022-01-02T00:00:00Z"), c(1, 1))
expect_error_code(
  function() discharge_f0_project_discharge(ambiguous, empty_legacy),
  "site_identity_ambiguous", "ordinary multi-location site")

extended_frame <- corrected
class(extended_frame) <- c("tbl_df", "tbl", "data.frame")
expect_error_code(
  function() discharge_f0_project_discharge(extended_frame, legacy),
  "unexpected_field_class", "extended data.frame class is forbidden")

extended_time <- corrected
class(extended_time$endDateTime) <- c("clock_time", "POSIXct", "POSIXt")
expect_error_code(
  function() discharge_f0_project_discharge(extended_time, legacy),
  "unexpected_field_class", "extended POSIXct class is forbidden")

bad_time <- corrected_table(
  "ARIK", "ARIK.AOS", "2022-01-01T00:00:00Z", 1)
bad_time$endDateTime <- "2022-01-01 00:00:00"
expect_error_code(
  function() discharge_f0_project_discharge(bad_time, empty_legacy),
  "invalid_utc_time", "timestamp without explicit UTC")

bad_final <- corrected
bad_final$dischargeFinalQF[[1L]] <- 2
expect_error_code(
  function() discharge_f0_project_discharge(bad_final, legacy),
  "unexpected_qc_token", "unknown final-QF token")

bad_science <- corrected
bad_science$dischargeFinalQFSciRvw[[1L]] <- 2
expect_error_code(
  function() discharge_f0_project_discharge(bad_science, legacy),
  "unexpected_qc_token", "unknown science-review token")

bad_correction <- corrected
bad_correction$dischargeCorrectionApplied[[1L]] <- 2
expect_error_code(
  function() discharge_f0_project_discharge(bad_correction, legacy),
  "unexpected_qc_token", "unknown correction-state token")

character_flag <- corrected
character_flag$dischargeFinalQF <- as.character(character_flag$dischargeFinalQF)
expect_error_code(
  function() discharge_f0_project_discharge(character_flag, legacy),
  "unexpected_field_class", "semantic flag coercion is forbidden")

missing_field <- corrected
missing_field$dischargeContinuous <- NULL
expect_error_code(
  function() discharge_f0_project_discharge(missing_field, legacy),
  "required_field_missing", "required discharge field")

bad_response_class <- inverts
bad_response_class$density_eligible <- as.integer(
  bad_response_class$density_eligible)
expect_error_code(
  function() discharge_f0_project_inverts(bad_response_class),
  "unexpected_field_class", "Inverts eligibility must remain logical")

# Caller-supplied values-free panels are not trusted merely because their
# columns are named correctly: counts, binaries, source labels, and exact key
# classes must be mutually consistent.
bad_panel_count <- passed$discharge$site_years
bad_panel_count$n_usable_records[[1L]] <-
  bad_panel_count$n_usable_records[[1L]] + 1L
expect_error_code(
  function() discharge_f0_evaluate_gate(
    bad_panel_count, passed$inverts_site_years),
  "site_year_panel_invariant_mismatch", "caller panel count inconsistency")

bad_panel_regime <- passed$discharge$site_years
bad_panel_regime$source_regime[[1L]] <- "corrected_15_min_only"
expect_error_code(
  function() discharge_f0_evaluate_gate(
    bad_panel_regime, passed$inverts_site_years),
  "site_year_panel_invariant_mismatch", "caller panel source-regime drift")

bad_panel_binary <- passed$discharge$site_years
bad_panel_binary$qc_pass_record_present_in_utc_year[[1L]] <- FALSE
expect_error_code(
  function() discharge_f0_evaluate_gate(
    bad_panel_binary, passed$inverts_site_years),
  "site_year_panel_invariant_mismatch", "caller panel binary/count drift")

bad_panel_days <- passed$discharge$site_years
bad_panel_days$n_usable_utc_days[[1L]] <- 0L
expect_error_code(
  function() discharge_f0_evaluate_gate(
    bad_panel_days, passed$inverts_site_years),
  "site_year_panel_invariant_mismatch", "caller panel record/day drift")

bad_panel_chronology <- passed$discharge$site_years
bad_panel_chronology$n_corrected_15_min_published_records[[1L]] <- 1L
bad_panel_chronology$n_historical_1_min_published_records[[1L]] <- 0L
bad_panel_chronology$n_corrected_15_min_usable_records[[1L]] <- 1L
bad_panel_chronology$n_historical_1_min_usable_records[[1L]] <- 0L
bad_panel_chronology$source_regime[[1L]] <- "corrected_15_min_only"
bad_panel_chronology$corrected_15_min_only_sensitivity[[1L]] <- TRUE
expect_error_code(
  function() discharge_f0_evaluate_gate(
    bad_panel_chronology, passed$inverts_site_years),
  "site_year_panel_invariant_mismatch",
  "caller panel cannot place corrected records before cutover year")

bad_inverts_panel <- passed$inverts_site_years
bad_inverts_panel$utc_calendar_year <-
  as.numeric(bad_inverts_panel$utc_calendar_year)
expect_error_code(
  function() discharge_f0_evaluate_gate(
    passed$discharge$site_years, bad_inverts_panel),
  "unexpected_field_class", "caller response ledger year class drift")

cat(paste0(
  "DISCHARGE FEASIBILITY F0 SYNTHETIC CONTRACT PASSED: ",
  "record-presence only; 3x6 review gate; TOMB/TOOK excluded; ",
  "sensitivities non-rescuing; no ecological values or effects emitted.\n"))
