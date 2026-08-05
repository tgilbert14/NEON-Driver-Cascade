# Pure, effect-blind support contract for Continuous Discharge Gate F0.
#
# This module accepts only in-memory tables. It performs no acquisition, reads no
# files, computes no discharge magnitude summary, and exposes no ecological
# value or effect. The only use of either discharge field is a row-wise
# finiteness test required by the frozen binary support predicate.

DISCHARGE_F0_CONTRACT_VERSION <- "discharge-feasibility-f0-v1"
DISCHARGE_F0_MINIMUM_SITES <- 3L
DISCHARGE_F0_MINIMUM_COMMON_YEARS <- 6L
DISCHARGE_F0_EXCLUDED_SITES <- c("TOMB", "TOOK")
DISCHARGE_F0_DECISIONS <- c("REOPEN_REVIEW", "HOLD")
DISCHARGE_F0_HUMAN_DISPOSITIONS <- c(
  REOPEN_REVIEW = "REOPEN INDEPENDENT REVIEW",
  HOLD = "HOLD / DO NOT BUILD")
DISCHARGE_F0_ORDINARY_CUTOVER_UTC <- "2021-10-01T00:00:00Z"
DISCHARGE_F0_BIGC_CUTOVER_UTC <- "2020-10-01T00:00:00Z"
DISCHARGE_F0_INVERTS_PROJECTION_STATES <- c(
  "eligible_stream", "density_eligibility_missing", "density_ineligible",
  "aquatic_site_type_missing", "non_stream_aquatic_site_type")

DISCHARGE_F0_RESPONSE_LEDGER_FIELDS <- c(
  "siteID", "utc_calendar_year", "discharge_site_year_present",
  "qc_pass_record_present_in_utc_year", "source_regime")

DISCHARGE_F0_EXACT_INVERTS_YEARS <- list(
  ARIK = 2014:2024,
  BIGC = c(2018L, 2019L, 2021:2024),
  BLDE = c(2018:2021, 2023L, 2024L),
  BLUE = c(2017:2019, 2021:2024),
  CARI = 2016:2024,
  COMO = 2015:2024,
  CUPE = 2015:2024,
  GUIL = 2015:2024,
  HOPB = 2016:2024,
  KING = 2015:2024,
  LECO = 2015:2024,
  LEWI = 2016:2024,
  MART = 2018:2024,
  MAYF = 2014:2024,
  MCDI = 2017:2024,
  MCRA = 2017:2024,
  OKSR = 2016:2024,
  POSE = 2014:2024,
  PRIN = 2016:2024,
  REDB = 2015:2024,
  SYCA = c(2017L, 2019:2024),
  TECR = c(2019L, 2021:2024),
  WALK = 2015:2024,
  WLOU = 2017:2024)

DISCHARGE_F0_EXACT_INVERTS_SITE_COUNTS <- vapply(
  DISCHARGE_F0_EXACT_INVERTS_YEARS, length, integer(1L))

DISCHARGE_F0_15_MIN_FIELDS <- c(
  "siteID", "namedLocation", "endDateTime", "dischargeContinuous",
  "dischargeFinalQF", "dischargeFinalQFSciRvw",
  "dischargeCorrectionApplied")

DISCHARGE_F0_LEGACY_FIELDS <- c(
  "siteID", "namedLocation", "endDate", "maxpostDischarge",
  "dischargeFinalQF", "dischargeFinalQFSciRvw")

DISCHARGE_F0_INVERTS_FIELDS <- c(
  "siteID", "collectDate", "aquaticSiteType", "density_eligible")

DISCHARGE_F0_SITE_YEAR_FIELDS <- c(
  "siteID", "namedLocation", "utc_calendar_year", "source_regime",
  "n_active_published_records", "n_usable_records",
  "n_corrected_15_min_published_records",
  "n_corrected_15_min_usable_records",
  "n_historical_1_min_published_records",
  "n_historical_1_min_usable_records",
  "n_active_published_utc_days", "n_usable_utc_days",
  "n_active_published_utc_months", "n_usable_utc_months",
  "qc_pass_record_present_in_utc_year",
  "corrected_15_min_only_sensitivity")

.discharge_f0_abort <- function(code, message) {
  stop(structure(
    list(message = as.character(message), call = NULL, code = as.character(code)),
    class = c("discharge_f0_error", "error", "condition")))
}

.discharge_f0_assert_frame <- function(x, label) {
  if (!is.data.frame(x))
    .discharge_f0_abort(
      "required_table_missing", sprintf("%s must be a data frame", label))
  if (!identical(attr(x, "class", exact = TRUE), "data.frame"))
    .discharge_f0_abort(
      "unexpected_field_class",
      sprintf("%s must be a plain data.frame with no extended class", label))
  n <- tryCatch(nrow(x), error = function(e) NA_integer_)
  if (length(n) != 1L || is.na(n) || is.null(names(x)) ||
      anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x)) ||
      any(vapply(x, length, integer(1L)) != n))
    .discharge_f0_abort(
      "malformed_rectangular_table",
      sprintf("%s must be rectangular with unique, nonblank columns", label))
  invisible(n)
}

.discharge_f0_assert_required_fields <- function(x, required, label) {
  missing <- setdiff(required, names(x))
  if (length(missing))
    .discharge_f0_abort(
      "required_field_missing",
      sprintf("%s lacks required field(s): %s",
              label, paste(missing, collapse = ", ")))
  invisible(TRUE)
}

.discharge_f0_preflight_tomb <- function(x, required, label) {
  .discharge_f0_assert_frame(x, label)
  .discharge_f0_assert_required_fields(x, "siteID", label)
  if (.discharge_f0_plain_character(x$siteID) &&
      any(!is.na(x$siteID) & x$siteID == "TOMB"))
    .discharge_f0_abort(
      "tomb_requires_separate_contract",
      sprintf("%s contains TOMB, whose USGS table requires a separate contract",
              label))
  .discharge_f0_assert_required_fields(x, required, label)
  invisible(TRUE)
}

.discharge_f0_plain_character <- function(x) {
  is.character(x) && is.null(dim(x)) &&
    is.null(attr(x, "class", exact = TRUE))
}

.discharge_f0_plain_numeric <- function(x) {
  is.numeric(x) && is.null(dim(x)) && !is.object(x)
}

.discharge_f0_plain_integer <- function(x) {
  is.integer(x) && is.null(dim(x)) && !is.object(x)
}

.discharge_f0_plain_logical <- function(x) {
  is.logical(x) && is.null(dim(x)) && !is.object(x)
}

.discharge_f0_assert_identity <- function(site, location, label) {
  if (!.discharge_f0_plain_character(site) ||
      !.discharge_f0_plain_character(location))
    .discharge_f0_abort(
      "unexpected_field_class",
      sprintf("%s identity fields must be plain character vectors", label))
  site_ok <- !is.na(site) & grepl("^[A-Z0-9]{4}$", site, perl = TRUE)
  location_ok <- !is.na(location) & nzchar(location) &
    location == trimws(location) &
    !grepl("[\\r\\n\\t]", location, perl = TRUE)
  if (any(!site_ok) || any(!location_ok))
    .discharge_f0_abort(
      "site_identity_ambiguous",
      sprintf("%s contains a missing or noncanonical site/location identity",
              label))
  invisible(TRUE)
}

.discharge_f0_parse_utc <- function(x, field, allow_missing = FALSE) {
  if (identical(attr(x, "class", exact = TRUE), c("POSIXct", "POSIXt")) &&
      is.double(unclass(x)) && is.null(dim(x))) {
    zone <- attr(x, "tzone", exact = TRUE)
    if (!is.character(zone) || length(zone) != 1L || is.na(zone) ||
        !identical(zone, "UTC"))
      .discharge_f0_abort(
        "invalid_utc_time",
        sprintf("%s must carry the explicit UTC time zone", field))
    parsed <- x
  } else if (.discharge_f0_plain_character(x)) {
    canonical <- !is.na(x) & grepl(
      paste0("^[0-9]{4}-(0[1-9]|1[0-2])-",
             "(0[1-9]|[12][0-9]|3[01])T",
             "([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"),
      x, perl = TRUE)
    parsed <- suppressWarnings(as.POSIXct(
      x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
    round_trip <- !is.na(parsed) &
      format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC") == x
    if (any(!canonical | !round_trip))
      .discharge_f0_abort(
        "invalid_utc_time",
        sprintf("%s must contain canonical explicit-UTC instants", field))
  } else {
    .discharge_f0_abort(
      "unexpected_field_class",
      sprintf("%s must be POSIXct[UTC] or canonical UTC character data", field))
  }

  bad <- !is.finite(as.numeric(parsed))
  if (!allow_missing && any(bad))
    .discharge_f0_abort(
      "invalid_utc_time", sprintf("%s contains a missing or invalid instant", field))
  parsed
}

.discharge_f0_assert_measurement <- function(x, field) {
  if (!.discharge_f0_plain_numeric(x))
    .discharge_f0_abort(
      "unexpected_field_class", sprintf("%s must be a plain numeric vector", field))
  invisible(TRUE)
}

.discharge_f0_validate_flag <- function(x, field, allow_missing = TRUE) {
  if (!.discharge_f0_plain_numeric(x))
    .discharge_f0_abort(
      "unexpected_field_class", sprintf("%s must be a plain numeric vector", field))
  if (any(is.nan(x)) || any(is.infinite(x)) ||
      any(!is.na(x) & !x %in% c(0, 1)) || (!allow_missing && anyNA(x)))
    .discharge_f0_abort(
      "unexpected_qc_token",
      sprintf("%s contains a token outside its frozen 0/1 state domain", field))
  invisible(TRUE)
}

.discharge_f0_exact_time_key <- function(site, location, timestamp) {
  paste(site, location, sprintf("%.17g", as.numeric(timestamp)), sep = "\r")
}

.discharge_f0_validate_source_table <- function(x, kind) {
  label <- if (identical(kind, "corrected_15_min")) {
    "csd_15_min"
  } else if (identical(kind, "historical_1_min")) {
    "csd_continuousDischarge"
  } else {
    .discharge_f0_abort("required_table_missing", "unknown discharge table kind")
  }
  required <- if (identical(kind, "corrected_15_min")) {
    DISCHARGE_F0_15_MIN_FIELDS
  } else {
    DISCHARGE_F0_LEGACY_FIELDS
  }
  time_field <- if (identical(kind, "corrected_15_min")) {
    "endDateTime"
  } else {
    "endDate"
  }
  value_field <- if (identical(kind, "corrected_15_min")) {
    "dischargeContinuous"
  } else {
    "maxpostDischarge"
  }

  .discharge_f0_preflight_tomb(x, required, label)
  .discharge_f0_assert_identity(x$siteID, x$namedLocation, label)
  timestamp <- .discharge_f0_parse_utc(x[[time_field]],
                                       sprintf("%s$%s", label, time_field))
  ordinary_cutover <- as.POSIXct(
    DISCHARGE_F0_ORDINARY_CUTOVER_UTC,
    format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  bigc_cutover <- as.POSIXct(
    DISCHARGE_F0_BIGC_CUTOVER_UTC,
    format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  cutover <- rep(ordinary_cutover, nrow(x))
  cutover[x$siteID == "BIGC"] <- bigc_cutover
  chronology_invalid <- if (identical(kind, "corrected_15_min")) {
    timestamp < cutover
  } else {
    timestamp >= cutover
  }
  if (any(chronology_invalid))
    .discharge_f0_abort(
      "source_regime_chronology_mismatch",
      paste0(
        label, " violates the RELEASE-2026 source chronology: corrected rows ",
        "must be at or after the site cutover and legacy rows strictly before it"))
  .discharge_f0_assert_measurement(
    x[[value_field]], sprintf("%s$%s", label, value_field))
  .discharge_f0_validate_flag(
    x$dischargeFinalQF, sprintf("%s$dischargeFinalQF", label),
    allow_missing = TRUE)
  .discharge_f0_validate_flag(
    x$dischargeFinalQFSciRvw,
    sprintf("%s$dischargeFinalQFSciRvw", label), allow_missing = TRUE)
  if (identical(kind, "corrected_15_min"))
    .discharge_f0_validate_flag(
      x$dischargeCorrectionApplied,
      sprintf("%s$dischargeCorrectionApplied", label), allow_missing = TRUE)

  key <- .discharge_f0_exact_time_key(x$siteID, x$namedLocation, timestamp)
  if (anyDuplicated(key))
    .discharge_f0_abort(
      "duplicate_source_key",
      sprintf("%s contains a duplicate site/location/UTC-time key", label))

  final_clear <- !is.na(x$dischargeFinalQF) & x$dischargeFinalQF == 0
  science_clear <- is.na(x$dischargeFinalQFSciRvw) |
    x$dischargeFinalQFSciRvw == 0
  correction_clear <- if (identical(kind, "corrected_15_min")) {
    x$dischargeCorrectionApplied %in% c(0, 1)
  } else {
    rep(TRUE, nrow(x))
  }
  usable <- is.finite(x[[value_field]]) & final_clear & science_clear &
    correction_clear

  data.frame(
    siteID = x$siteID,
    namedLocation = x$namedLocation,
    utc_timestamp = timestamp,
    utc_calendar_year = as.integer(format(timestamp, "%Y", tz = "UTC")),
    utc_month = format(timestamp, "%Y-%m", tz = "UTC"),
    utc_day = format(timestamp, "%Y-%m-%d", tz = "UTC"),
    water_year = as.integer(format(timestamp, "%Y", tz = "UTC")) +
      as.integer(as.integer(format(timestamp, "%m", tz = "UTC")) >= 10L),
    source_table = rep(label, nrow(x)),
    source_kind = rep(kind, nrow(x)),
    active_published_record = rep(TRUE, nrow(x)),
    usable_record = usable,
    measurement_finite = is.finite(x[[value_field]]),
    final_qf_clear = final_clear,
    science_review_clear = science_clear,
    stringsAsFactors = FALSE)
}

.discharge_f0_check_identity_map <- function(records) {
  if (!nrow(records)) return(invisible(TRUE))
  site_to_location <- split(records$namedLocation, records$siteID)
  location_to_site <- split(records$siteID, records$namedLocation)
  # TOOK is the documented inflow/outflow special case. Preserve both raw
  # locations so the primary gate can exclude the site explicitly; ambiguity at
  # any other site remains a source-family failure.
  ordinary_sites <- setdiff(names(site_to_location), "TOOK")
  ambiguous_site <- any(vapply(
    site_to_location[ordinary_sites],
    function(x) length(unique(x)) != 1L, logical(1L)))
  ambiguous_location <- any(vapply(
    location_to_site, function(x) length(unique(x)) != 1L, logical(1L)))
  if (ambiguous_site || ambiguous_location)
    .discharge_f0_abort(
      "site_identity_ambiguous",
      "siteID and namedLocation must form an unambiguous one-to-one map")
  invisible(TRUE)
}

.discharge_f0_check_period_overlap <- function(records) {
  corrected <- records[records$source_kind == "corrected_15_min", , drop = FALSE]
  historical <- records[records$source_kind == "historical_1_min", , drop = FALSE]
  if (!nrow(corrected) || !nrow(historical)) return(invisible(TRUE))
  corrected_keys <- unique(paste(
    corrected$siteID, corrected$namedLocation, sep = "\r"))
  historical_keys <- unique(paste(
    historical$siteID, historical$namedLocation, sep = "\r"))
  shared <- intersect(corrected_keys, historical_keys)
  for (key in shared) {
    corrected_time <- as.numeric(corrected$utc_timestamp[
      paste(corrected$siteID, corrected$namedLocation, sep = "\r") == key])
    historical_time <- as.numeric(historical$utc_timestamp[
      paste(historical$siteID, historical$namedLocation, sep = "\r") == key])
    if (max(corrected_time) >= min(historical_time) &&
        max(historical_time) >= min(corrected_time))
      .discharge_f0_abort(
        "main_table_period_overlap",
        "corrected and historical main-table periods overlap at a site/location")
  }
  invisible(TRUE)
}

.discharge_f0_sort_records <- function(records) {
  if (!nrow(records)) return(records)
  order_index <- order(
    records$siteID, records$namedLocation, records$utc_timestamp,
    records$source_kind, method = "radix")
  records <- records[order_index, , drop = FALSE]
  rownames(records) <- NULL
  records
}

.discharge_f0_groups <- function(x, fields) {
  if (!nrow(x)) return(list())
  key <- do.call(paste, c(x[fields], sep = "\r"))
  run <- cumsum(c(TRUE, key[-1L] != key[-length(key)]))
  split(seq_len(nrow(x)), run)
}

.discharge_f0_source_regime <- function(records, indices) {
  corrected <- any(records$usable_record[indices] &
                     records$source_kind[indices] == "corrected_15_min")
  historical <- any(records$usable_record[indices] &
                      records$source_kind[indices] == "historical_1_min")
  if (corrected && historical) return("mixed_corrected_and_historical")
  if (corrected) return("corrected_15_min_only")
  if (historical) return("historical_uncorrected_1_min_only")
  NA_character_
}

.discharge_f0_empty_site_years <- function() {
  data.frame(
    siteID = character(), namedLocation = character(),
    utc_calendar_year = integer(), source_regime = character(),
    n_active_published_records = integer(), n_usable_records = integer(),
    n_corrected_15_min_published_records = integer(),
    n_corrected_15_min_usable_records = integer(),
    n_historical_1_min_published_records = integer(),
    n_historical_1_min_usable_records = integer(),
    n_active_published_utc_days = integer(), n_usable_utc_days = integer(),
    n_active_published_utc_months = integer(), n_usable_utc_months = integer(),
    qc_pass_record_present_in_utc_year = logical(),
    corrected_15_min_only_sensitivity = logical(),
    stringsAsFactors = FALSE)
}

.discharge_f0_build_site_years <- function(records) {
  if (!nrow(records)) return(.discharge_f0_empty_site_years())
  records <- records[order(
    records$siteID, records$namedLocation, records$utc_calendar_year,
    records$utc_timestamp, records$source_kind, method = "radix"), , drop = FALSE]
  groups <- .discharge_f0_groups(
    records, c("siteID", "namedLocation", "utc_calendar_year"))
  rows <- lapply(groups, function(indices) {
    corrected <- records$source_kind[indices] == "corrected_15_min"
    historical <- records$source_kind[indices] == "historical_1_min"
    usable <- records$usable_record[indices]
    data.frame(
      siteID = records$siteID[indices[[1L]]],
      namedLocation = records$namedLocation[indices[[1L]]],
      utc_calendar_year = records$utc_calendar_year[indices[[1L]]],
      source_regime = .discharge_f0_source_regime(records, indices),
      n_active_published_records = as.integer(length(indices)),
      n_usable_records = as.integer(sum(usable)),
      n_corrected_15_min_published_records = as.integer(sum(corrected)),
      n_corrected_15_min_usable_records = as.integer(sum(corrected & usable)),
      n_historical_1_min_published_records = as.integer(sum(historical)),
      n_historical_1_min_usable_records = as.integer(sum(historical & usable)),
      n_active_published_utc_days = as.integer(length(unique(
        records$utc_day[indices]))),
      n_usable_utc_days = as.integer(length(unique(
        records$utc_day[indices][usable]))),
      n_active_published_utc_months = as.integer(length(unique(
        records$utc_month[indices]))),
      n_usable_utc_months = as.integer(length(unique(
        records$utc_month[indices][usable]))),
      qc_pass_record_present_in_utc_year = any(usable),
      corrected_15_min_only_sensitivity = any(corrected & usable),
      stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  result$utc_calendar_year <- as.integer(result$utc_calendar_year)
  integer_fields <- setdiff(
    names(result)[grepl("^n_", names(result))], character())
  for (field in integer_fields) result[[field]] <- as.integer(result[[field]])
  result$qc_pass_record_present_in_utc_year <-
    as.logical(result$qc_pass_record_present_in_utc_year)
  result$corrected_15_min_only_sensitivity <-
    as.logical(result$corrected_15_min_only_sensitivity)
  rownames(result) <- NULL
  result
}

.discharge_f0_empty_water_years <- function() {
  data.frame(
    siteID = character(), namedLocation = character(), water_year = integer(),
    source_regime = character(), n_active_published_records = integer(),
    n_usable_records = integer(),
    utc_water_year_label_sensitivity = logical(),
    stringsAsFactors = FALSE)
}

.discharge_f0_build_water_years <- function(records) {
  if (!nrow(records)) return(.discharge_f0_empty_water_years())
  records <- records[order(
    records$siteID, records$namedLocation, records$water_year,
    records$utc_timestamp, records$source_kind, method = "radix"), , drop = FALSE]
  groups <- .discharge_f0_groups(
    records, c("siteID", "namedLocation", "water_year"))
  rows <- lapply(groups, function(indices) {
    usable <- records$usable_record[indices]
    data.frame(
      siteID = records$siteID[indices[[1L]]],
      namedLocation = records$namedLocation[indices[[1L]]],
      water_year = records$water_year[indices[[1L]]],
      source_regime = .discharge_f0_source_regime(records, indices),
      n_active_published_records = as.integer(length(indices)),
      n_usable_records = as.integer(sum(usable)),
      utc_water_year_label_sensitivity = any(usable),
      stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  result$water_year <- as.integer(result$water_year)
  result$n_active_published_records <-
    as.integer(result$n_active_published_records)
  result$n_usable_records <- as.integer(result$n_usable_records)
  result$utc_water_year_label_sensitivity <-
    as.logical(result$utc_water_year_label_sensitivity)
  rownames(result) <- NULL
  result
}

.discharge_f0_source_diagnostics <- function(records) {
  kinds <- c("corrected_15_min", "historical_1_min")
  tables <- c("csd_15_min", "csd_continuousDischarge")
  rows <- lapply(seq_along(kinds), function(i) {
    part <- records[records$source_kind == kinds[[i]], , drop = FALSE]
    usable <- part$usable_record
    published_site_years <- if (nrow(part)) {
      unique(paste(part$siteID, part$utc_calendar_year, sep = "\r"))
    } else character()
    usable_site_years <- if (any(usable)) {
      unique(paste(part$siteID[usable], part$utc_calendar_year[usable], sep = "\r"))
    } else character()
    data.frame(
      source_table = tables[[i]], source_kind = kinds[[i]],
      n_active_published_records = as.integer(nrow(part)),
      n_usable_records = as.integer(sum(usable)),
      n_active_missing_or_nonfinite_records =
        as.integer(sum(!part$measurement_finite)),
      n_final_qf_not_clear_records = as.integer(sum(!part$final_qf_clear)),
      n_science_review_not_clear_records =
        as.integer(sum(!part$science_review_clear)),
      n_active_published_sites = as.integer(length(unique(part$siteID))),
      n_usable_sites = as.integer(length(unique(part$siteID[usable]))),
      n_active_published_site_years = as.integer(length(published_site_years)),
      n_usable_site_years = as.integer(length(usable_site_years)),
      stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

# Values-free discharge projection. Extra source columns are permitted but never
# read; all required table-specific fields, classes, flag domains, keys, and UTC
# interpretations are enforced before any support result is returned.
discharge_f0_project_discharge <- function(
    csd_15_min, csd_continuousDischarge) {
  # Inspect both table identities before either table's measurement or QC
  # fields. A TOMB row anywhere in the main-table family wins fail-closed.
  .discharge_f0_preflight_tomb(
    csd_15_min, DISCHARGE_F0_15_MIN_FIELDS, "csd_15_min")
  .discharge_f0_preflight_tomb(
    csd_continuousDischarge, DISCHARGE_F0_LEGACY_FIELDS,
    "csd_continuousDischarge")
  corrected <- .discharge_f0_validate_source_table(
    csd_15_min, "corrected_15_min")
  historical <- .discharge_f0_validate_source_table(
    csd_continuousDischarge, "historical_1_min")
  records <- rbind(corrected, historical)
  records <- .discharge_f0_sort_records(records)
  .discharge_f0_check_identity_map(records)
  .discharge_f0_check_period_overlap(records)

  list(
    contract_version = DISCHARGE_F0_CONTRACT_VERSION,
    site_years = .discharge_f0_build_site_years(records),
    site_water_years = .discharge_f0_build_water_years(records),
    source_regime_diagnostics = .discharge_f0_source_diagnostics(records))
}

.discharge_f0_empty_inverts <- function() {
  data.frame(siteID = character(), utc_calendar_year = integer(),
             stringsAsFactors = FALSE)
}

.discharge_f0_empty_inverts_receipt <- function() {
  data.frame(
    state = DISCHARGE_F0_INVERTS_PROJECTION_STATES,
    n_rows = rep(0L, length(DISCHARGE_F0_INVERTS_PROJECTION_STATES)),
    stringsAsFactors = FALSE)
}

.discharge_f0_assert_inverts_panel <- function(inverts_site_years) {
  .discharge_f0_assert_frame(inverts_site_years, "Inverts site-year panel")
  if (!identical(names(inverts_site_years),
                 c("siteID", "utc_calendar_year")))
    .discharge_f0_abort(
      "response_authority_mismatch",
      "Inverts site-year panel does not match the exact values-free schema")
  if (!.discharge_f0_plain_character(inverts_site_years$siteID) ||
      !is.integer(inverts_site_years$utc_calendar_year) ||
      is.object(inverts_site_years$utc_calendar_year) ||
      !is.null(dim(inverts_site_years$utc_calendar_year)))
    .discharge_f0_abort(
      "unexpected_field_class", "Inverts site-year key classes drifted")
  if (anyNA(inverts_site_years$siteID) ||
      any(!grepl("^[A-Z0-9]{4}$", inverts_site_years$siteID, perl = TRUE)) ||
      anyNA(inverts_site_years$utc_calendar_year) ||
      any(inverts_site_years$utc_calendar_year < 1000L |
          inverts_site_years$utc_calendar_year > 9999L))
    .discharge_f0_abort(
      "site_identity_ambiguous",
      "Inverts site-year panel contains a noncanonical exact key")
  key <- paste(inverts_site_years$siteID,
               inverts_site_years$utc_calendar_year, sep = "\r")
  if (anyDuplicated(key))
    .discharge_f0_abort(
      "response_authority_mismatch",
      "Inverts site-year panel contains a duplicate exact key")
  invisible(TRUE)
}

.discharge_f0_expected_inverts_panel <- function() {
  rows <- lapply(names(DISCHARGE_F0_EXACT_INVERTS_YEARS), function(site) {
    data.frame(
      siteID = rep(site, length(DISCHARGE_F0_EXACT_INVERTS_YEARS[[site]])),
      utc_calendar_year = as.integer(DISCHARGE_F0_EXACT_INVERTS_YEARS[[site]]),
      stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, rows)
  result <- result[order(
    result$siteID, result$utc_calendar_year, method = "radix"), , drop = FALSE]
  rownames(result) <- NULL
  result
}

# Integrity assertion for the exact, already values-free Inverts response
# authority. This function reads neither files nor ecological response values;
# its only content check is the frozen site-year roster and per-site row counts.
discharge_f0_assert_exact_inverts_authority <- function(panel) {
  .discharge_f0_assert_inverts_panel(panel)
  ordered_panel <- panel[order(
    panel$siteID, panel$utc_calendar_year, method = "radix"), , drop = FALSE]
  rownames(ordered_panel) <- NULL
  expected_panel <- .discharge_f0_expected_inverts_panel()
  observed <- table(factor(
    panel$siteID, levels = names(DISCHARGE_F0_EXACT_INVERTS_SITE_COUNTS)))
  unknown_sites <- setdiff(unique(panel$siteID),
                           names(DISCHARGE_F0_EXACT_INVERTS_SITE_COUNTS))
  observed_counts <- setNames(as.integer(observed), names(observed))
  n_at_floor <- as.integer(sum(observed_counts >=
                                 DISCHARGE_F0_MINIMUM_COMMON_YEARS))
  if (nrow(panel) != 210L || length(unique(panel$siteID)) != 24L ||
      length(unknown_sites) ||
      !identical(observed_counts, DISCHARGE_F0_EXACT_INVERTS_SITE_COUNTS) ||
      n_at_floor != 23L || !identical(ordered_panel, expected_panel))
    .discharge_f0_abort(
      "response_210_24_23_mismatch",
      paste0(
        "exact Inverts response authority must retain 210 site-years, 24 sites, ",
        "23 sites at or above six years, and every frozen exact site-year key"))
  invisible(TRUE)
}

.discharge_f0_reduce_inverts <- function(opportunities) {
  .discharge_f0_assert_frame(opportunities, "inverts opportunities")
  .discharge_f0_assert_required_fields(
    opportunities, DISCHARGE_F0_INVERTS_FIELDS, "inverts opportunities")
  if (!.discharge_f0_plain_character(opportunities$siteID) ||
      !.discharge_f0_plain_character(opportunities$aquaticSiteType) ||
      !is.logical(opportunities$density_eligible) ||
      is.object(opportunities$density_eligible) ||
      !is.null(dim(opportunities$density_eligible)))
    .discharge_f0_abort(
      "unexpected_field_class",
      "Inverts opportunity identity, water type, and eligibility classes drifted")
  collect_date_posix <- identical(
    attr(opportunities$collectDate, "class", exact = TRUE),
    c("POSIXct", "POSIXt")) &&
    is.double(unclass(opportunities$collectDate)) &&
    is.null(dim(opportunities$collectDate))
  if (!collect_date_posix &&
      !.discharge_f0_plain_character(opportunities$collectDate))
    .discharge_f0_abort(
      "unexpected_field_class",
      "Inverts collectDate must be POSIXct[UTC] or canonical UTC character data")

  density_missing <- is.na(opportunities$density_eligible)
  density_ineligible <- !density_missing & !opportunities$density_eligible
  water_missing <- !density_missing & opportunities$density_eligible &
    is.na(opportunities$aquaticSiteType)
  nonstream <- !density_missing & opportunities$density_eligible &
    !is.na(opportunities$aquaticSiteType) &
    opportunities$aquaticSiteType != "stream"
  keep <- !density_missing & opportunities$density_eligible &
    !is.na(opportunities$aquaticSiteType) &
    opportunities$aquaticSiteType == "stream"

  receipt <- .discharge_f0_empty_inverts_receipt()
  receipt$n_rows <- as.integer(c(
    sum(keep), sum(density_missing), sum(density_ineligible),
    sum(water_missing), sum(nonstream)))
  if (sum(receipt$n_rows) != nrow(opportunities))
    .discharge_f0_abort(
      "response_authority_mismatch",
      "Inverts projection states failed to partition all input rows")

  if (!any(keep))
    return(list(site_years = .discharge_f0_empty_inverts(),
                projection_receipt = receipt))

  site <- opportunities$siteID[keep]
  timestamp <- .discharge_f0_parse_utc(
    opportunities$collectDate[keep], "inverts opportunities$collectDate")
  if (!.discharge_f0_plain_character(site) || anyNA(site) ||
      any(!grepl("^[A-Z0-9]{4}$", site, perl = TRUE)))
    .discharge_f0_abort(
      "site_identity_ambiguous",
      "an eligible Inverts stream opportunity has an invalid exact siteID")
  year <- as.integer(format(timestamp, "%Y", tz = "UTC"))
  result <- unique(data.frame(
    siteID = site, utc_calendar_year = year, stringsAsFactors = FALSE))
  result <- result[order(
    result$siteID, result$utc_calendar_year, method = "radix"), , drop = FALSE]
  rownames(result) <- NULL
  .discharge_f0_assert_inverts_panel(result)
  list(site_years = result, projection_receipt = receipt)
}

# Exact values-free projection of the released Inverts opportunity ledger. Only
# the four named opportunity fields are accessed. Any outcome/density/taxonomy
# columns present in the input are intentionally ignored.
discharge_f0_project_inverts <- function(opportunities) {
  .discharge_f0_reduce_inverts(opportunities)$site_years
}

.discharge_f0_assert_site_year_panel <- function(
    discharge_site_years, inverts_site_years) {
  .discharge_f0_assert_frame(discharge_site_years, "discharge site-year panel")
  if (!identical(names(discharge_site_years), DISCHARGE_F0_SITE_YEAR_FIELDS))
    .discharge_f0_abort(
      "required_field_missing",
      "discharge site-year panel does not match the frozen values-free schema")
  .discharge_f0_assert_inverts_panel(inverts_site_years)
  count_fields <- DISCHARGE_F0_SITE_YEAR_FIELDS[
    grepl("^n_", DISCHARGE_F0_SITE_YEAR_FIELDS)]
  if (!.discharge_f0_plain_character(discharge_site_years$siteID) ||
      !.discharge_f0_plain_character(discharge_site_years$namedLocation) ||
      !.discharge_f0_plain_character(discharge_site_years$source_regime) ||
      !.discharge_f0_plain_integer(discharge_site_years$utc_calendar_year) ||
      !.discharge_f0_plain_logical(
        discharge_site_years$qc_pass_record_present_in_utc_year) ||
      anyNA(discharge_site_years$qc_pass_record_present_in_utc_year) ||
      !.discharge_f0_plain_logical(
        discharge_site_years$corrected_15_min_only_sensitivity) ||
      anyNA(discharge_site_years$corrected_15_min_only_sensitivity) ||
      any(!vapply(discharge_site_years[count_fields],
                  .discharge_f0_plain_integer, logical(1L))))
    .discharge_f0_abort(
      "unexpected_field_class",
      "discharge site-year key, state, regime, or count classes drifted")
  if (anyNA(discharge_site_years$siteID) ||
      any(!grepl("^[A-Z0-9]{4}$", discharge_site_years$siteID, perl = TRUE)) ||
      anyNA(discharge_site_years$namedLocation) ||
      any(!nzchar(discharge_site_years$namedLocation)) ||
      any(discharge_site_years$namedLocation !=
            trimws(discharge_site_years$namedLocation)) ||
      any(grepl("[\\r\\n\\t]", discharge_site_years$namedLocation,
                perl = TRUE)) ||
      anyNA(discharge_site_years$utc_calendar_year) ||
      any(discharge_site_years$utc_calendar_year < 1000L |
          discharge_site_years$utc_calendar_year > 9999L))
    .discharge_f0_abort(
      "site_identity_ambiguous", "site-year panel contains an incomplete key")
  if (any(discharge_site_years$siteID == "TOMB"))
    .discharge_f0_abort(
      "tomb_requires_separate_contract",
      "TOMB cannot enter a main-table discharge site-year panel")
  allowed_regimes <- c(
    "corrected_15_min_only", "historical_uncorrected_1_min_only",
    "mixed_corrected_and_historical")
  if (any(!is.na(discharge_site_years$source_regime) &
          !discharge_site_years$source_regime %in% allowed_regimes))
    .discharge_f0_abort(
      "site_year_panel_invariant_mismatch",
      "discharge site-year panel contains an unknown source regime")
  if (any(vapply(discharge_site_years[count_fields], anyNA, logical(1L))) ||
      any(vapply(discharge_site_years[count_fields],
                 function(x) any(x < 0L), logical(1L))))
    .discharge_f0_abort(
      "site_year_panel_invariant_mismatch",
      "discharge site-year count fields must be complete and nonnegative")

  d <- discharge_site_years
  count_invariant <-
    d$n_active_published_records ==
      d$n_corrected_15_min_published_records +
      d$n_historical_1_min_published_records &
    d$n_usable_records == d$n_corrected_15_min_usable_records +
      d$n_historical_1_min_usable_records &
    d$n_active_published_records >= 1L &
    d$n_usable_records <= d$n_active_published_records &
    d$n_corrected_15_min_usable_records <=
      d$n_corrected_15_min_published_records &
    d$n_historical_1_min_usable_records <=
      d$n_historical_1_min_published_records &
    d$n_active_published_utc_days >= 1L &
    d$n_active_published_utc_days <= d$n_active_published_records &
    d$n_usable_utc_days <= d$n_usable_records &
    d$n_usable_utc_days <= d$n_active_published_utc_days &
    d$n_active_published_utc_months >= 1L &
    d$n_active_published_utc_months <= d$n_active_published_utc_days &
    d$n_usable_utc_months <= d$n_usable_utc_days &
    d$n_usable_utc_months <= d$n_active_published_utc_months &
    (d$n_usable_utc_days > 0L) == (d$n_usable_records > 0L) &
    (d$n_usable_utc_months > 0L) == (d$n_usable_records > 0L)
  corrected_pass <- d$n_corrected_15_min_usable_records > 0L
  historical_pass <- d$n_historical_1_min_usable_records > 0L
  expected_regime <- rep(NA_character_, nrow(d))
  expected_regime[corrected_pass & !historical_pass] <-
    "corrected_15_min_only"
  expected_regime[!corrected_pass & historical_pass] <-
    "historical_uncorrected_1_min_only"
  expected_regime[corrected_pass & historical_pass] <-
    "mixed_corrected_and_historical"
  regime_matches <-
    (is.na(d$source_regime) & is.na(expected_regime)) |
    (!is.na(d$source_regime) & !is.na(expected_regime) &
       d$source_regime == expected_regime)
  state_invariant <-
    d$qc_pass_record_present_in_utc_year == (d$n_usable_records > 0L) &
    d$corrected_15_min_only_sensitivity == corrected_pass &
    regime_matches
  bigc <- d$siteID == "BIGC"
  corrected_before_cutover_year <-
    ((!bigc & d$utc_calendar_year <= 2020L) |
       (bigc & d$utc_calendar_year <= 2019L)) &
    d$n_corrected_15_min_published_records > 0L
  legacy_after_cutover_year <-
    ((!bigc & d$utc_calendar_year >= 2022L) |
       (bigc & d$utc_calendar_year >= 2021L)) &
    d$n_historical_1_min_published_records > 0L
  if (any(!count_invariant) || any(!state_invariant) ||
      any(corrected_before_cutover_year) || any(legacy_after_cutover_year))
    .discharge_f0_abort(
      "site_year_panel_invariant_mismatch",
      paste0(
        "discharge site-year counts, binary support states, and source regimes ",
        "must agree exactly"))

  site_to_location <- split(d$namedLocation, d$siteID)
  ordinary_sites <- setdiff(names(site_to_location), "TOOK")
  location_to_site <- split(d$siteID, d$namedLocation)
  if (any(vapply(site_to_location[ordinary_sites],
                 function(x) length(unique(x)) != 1L, logical(1L))) ||
      any(vapply(location_to_site,
                 function(x) length(unique(x)) != 1L, logical(1L))))
    .discharge_f0_abort(
      "site_identity_ambiguous",
      "site-year panel siteID/namedLocation mapping is ambiguous")
  # The two registered special sites are excluded before the primary floor is
  # evaluated. TOOK may therefore have more than one raw namedLocation row for a
  # site-year without turning its deliberate exclusion into a family-wide
  # failure. No ordinary site may have a duplicate site-year key.
  discharge_primary <- !discharge_site_years$siteID %in%
    DISCHARGE_F0_EXCLUDED_SITES
  discharge_key <- paste(
    discharge_site_years$siteID[discharge_primary],
    discharge_site_years$utc_calendar_year[discharge_primary], sep = "\r")
  if (anyDuplicated(discharge_key))
    .discharge_f0_abort(
      "site_identity_ambiguous", "site-year panel contains a duplicate exact key")
  invisible(TRUE)
}

.discharge_f0_empty_response_ledger <- function() {
  data.frame(
    siteID = character(), utc_calendar_year = integer(),
    discharge_site_year_present = logical(),
    qc_pass_record_present_in_utc_year = logical(), source_regime = character(),
    stringsAsFactors = FALSE)
}

.discharge_f0_empty_site_support <- function() {
  data.frame(
    siteID = character(), n_common_primary_years = integer(),
    site_clears_primary_floor = logical(), stringsAsFactors = FALSE)
}

.discharge_f0_common_support <- function(discharge_panel, inverts_site_years) {
  if (!nrow(inverts_site_years))
    return(list(
      response_anchored_ledger = .discharge_f0_empty_response_ledger(),
      common_site_years = .discharge_f0_empty_inverts(),
      site_support = .discharge_f0_empty_site_support()))

  inverts_site_years <- inverts_site_years[order(
    inverts_site_years$siteID, inverts_site_years$utc_calendar_year,
    method = "radix"), , drop = FALSE]
  rownames(inverts_site_years) <- NULL
  inverts_key <- paste(
    inverts_site_years$siteID, inverts_site_years$utc_calendar_year, sep = "\r")
  discharge_key <- paste(
    discharge_panel$siteID, discharge_panel$utc_calendar_year, sep = "\r")
  matched <- match(inverts_key, discharge_key)
  present <- !is.na(matched)
  qc_pass <- rep(FALSE, nrow(inverts_site_years))
  source_regime <- rep(NA_character_, nrow(inverts_site_years))
  if (any(present)) {
    qc_pass[present] <-
      discharge_panel$qc_pass_record_present_in_utc_year[matched[present]]
    source_regime[present] <- discharge_panel$source_regime[matched[present]]
  }
  ledger <- data.frame(
    siteID = inverts_site_years$siteID,
    utc_calendar_year = inverts_site_years$utc_calendar_year,
    discharge_site_year_present = present,
    qc_pass_record_present_in_utc_year = qc_pass,
    source_regime = source_regime,
    stringsAsFactors = FALSE)
  if (!identical(names(ledger), DISCHARGE_F0_RESPONSE_LEDGER_FIELDS))
    .discharge_f0_abort(
      "site_year_panel_invariant_mismatch",
      "response-anchored primary ledger schema drifted")

  common <- ledger[
    ledger$qc_pass_record_present_in_utc_year,
    c("siteID", "utc_calendar_year"), drop = FALSE]
  rownames(common) <- NULL
  response_sites <- sort(unique(inverts_site_years$siteID), method = "radix")
  counts <- vapply(
    response_sites,
    function(site) sum(common$siteID == site), integer(1L))
  site_support <- data.frame(
    siteID = response_sites,
    n_common_primary_years = as.integer(counts),
    site_clears_primary_floor = as.integer(counts) >=
      DISCHARGE_F0_MINIMUM_COMMON_YEARS,
    stringsAsFactors = FALSE)
  list(
    response_anchored_ledger = ledger,
    common_site_years = common,
    site_support = site_support)
}

# The primary exact-key gate. TOMB and TOOK are always removed before the floor
# is counted. The only possible scientific dispositions are REOPEN_REVIEW/HOLD.
discharge_f0_evaluate_gate <- function(discharge_site_years, inverts_site_years) {
  .discharge_f0_assert_site_year_panel(
    discharge_site_years, inverts_site_years)
  primary <- data.frame(
    siteID = discharge_site_years$siteID,
    utc_calendar_year = discharge_site_years$utc_calendar_year,
    discharge_site_year_present = rep(TRUE, nrow(discharge_site_years)),
    qc_pass_record_present_in_utc_year =
      discharge_site_years$qc_pass_record_present_in_utc_year,
    source_regime = discharge_site_years$source_regime,
    stringsAsFactors = FALSE)
  excluded_discharge <- primary$siteID %in% DISCHARGE_F0_EXCLUDED_SITES
  excluded_inverts <- inverts_site_years$siteID %in% DISCHARGE_F0_EXCLUDED_SITES
  excluded_counts <- data.frame(
    siteID = DISCHARGE_F0_EXCLUDED_SITES,
    reason = c("tomb_requires_separate_contract",
               "took_requires_named_location_crosswalk"),
    n_discharge_site_years = as.integer(vapply(
      DISCHARGE_F0_EXCLUDED_SITES,
      function(site) sum(primary$siteID == site), integer(1L))),
    n_inverts_site_years = as.integer(vapply(
      DISCHARGE_F0_EXCLUDED_SITES,
      function(site) sum(inverts_site_years$siteID == site), integer(1L))),
    stringsAsFactors = FALSE)
  primary <- primary[!excluded_discharge, , drop = FALSE]
  inverts_allowed <- inverts_site_years[!excluded_inverts, , drop = FALSE]
  support <- .discharge_f0_common_support(primary, inverts_allowed)
  n_clearing <- as.integer(sum(support$site_support$site_clears_primary_floor))
  decision <- if (n_clearing >= DISCHARGE_F0_MINIMUM_SITES) {
    "REOPEN_REVIEW"
  } else {
    "HOLD"
  }
  if (!decision %in% DISCHARGE_F0_DECISIONS)
    .discharge_f0_abort("effect_path_attempted", "invalid feasibility disposition")
  human_disposition <- unname(DISCHARGE_F0_HUMAN_DISPOSITIONS[[decision]])
  if (!is.character(human_disposition) || length(human_disposition) != 1L ||
      is.na(human_disposition) || !nzchar(human_disposition))
    .discharge_f0_abort(
      "effect_path_attempted", "invalid human feasibility disposition")

  list(
    decision = decision,
    human_disposition = human_disposition,
    minimum_sites = DISCHARGE_F0_MINIMUM_SITES,
    minimum_common_years = DISCHARGE_F0_MINIMUM_COMMON_YEARS,
    n_common_primary_site_years = as.integer(nrow(support$common_site_years)),
    n_sites_with_common_primary_years =
      as.integer(sum(support$site_support$n_common_primary_years > 0L)),
    n_response_sites_evaluated = as.integer(nrow(support$site_support)),
    n_sites_clearing_primary_floor = n_clearing,
    response_anchored_primary_ledger = support$response_anchored_ledger,
    common_primary_site_years = support$common_site_years,
    site_support = support$site_support,
    excluded_site_counts = excluded_counts)
}

.discharge_f0_sensitivity_receipt <- function(
    discharge_panel, inverts_site_years, label) {
  allowed_discharge <- discharge_panel[
    !discharge_panel$siteID %in% DISCHARGE_F0_EXCLUDED_SITES, , drop = FALSE]
  allowed_inverts <- inverts_site_years[
    !inverts_site_years$siteID %in% DISCHARGE_F0_EXCLUDED_SITES, , drop = FALSE]
  support <- .discharge_f0_common_support(allowed_discharge, allowed_inverts)
  data.frame(
    sensitivity = label,
    n_common_site_years = as.integer(nrow(support$common_site_years)),
    n_sites_with_common_years = as.integer(sum(
      support$site_support$n_common_primary_years > 0L)),
    n_response_sites_evaluated = as.integer(nrow(support$site_support)),
    n_sites_at_or_above_six_common_years = as.integer(sum(
      support$site_support$site_clears_primary_floor)),
    can_change_primary_decision = FALSE,
    stringsAsFactors = FALSE)
}

# Shared in-memory reduction. The response boundary is already a two-column,
# values-free site-year ledger; no raw opportunity or ecological outcome field
# can enter this path.
.discharge_f0_run_contract <- function(
    csd_15_min, csd_continuousDischarge, inverts_site_years,
    inverts_projection_receipt) {
  discharge <- discharge_f0_project_discharge(
    csd_15_min, csd_continuousDischarge)
  .discharge_f0_assert_inverts_panel(inverts_site_years)
  gate <- discharge_f0_evaluate_gate(
    discharge$site_years, inverts_site_years)

  corrected_panel <- data.frame(
    siteID = discharge$site_years$siteID,
    utc_calendar_year = discharge$site_years$utc_calendar_year,
    discharge_site_year_present = rep(TRUE, nrow(discharge$site_years)),
    qc_pass_record_present_in_utc_year =
      discharge$site_years$corrected_15_min_only_sensitivity,
    source_regime = ifelse(
      discharge$site_years$corrected_15_min_only_sensitivity,
      "corrected_15_min_only", NA_character_),
    stringsAsFactors = FALSE)
  water_panel <- data.frame(
    siteID = discharge$site_water_years$siteID,
    utc_calendar_year = discharge$site_water_years$water_year,
    discharge_site_year_present = rep(TRUE, nrow(discharge$site_water_years)),
    qc_pass_record_present_in_utc_year =
      discharge$site_water_years$utc_water_year_label_sensitivity,
    source_regime = discharge$site_water_years$source_regime,
    stringsAsFactors = FALSE)
  sensitivity_counts <- rbind(
    .discharge_f0_sensitivity_receipt(
      corrected_panel, inverts_site_years,
      "corrected_15_min_only_sensitivity"),
    .discharge_f0_sensitivity_receipt(
      water_panel, inverts_site_years, "utc_water_year_label_sensitivity"))
  rownames(sensitivity_counts) <- NULL

  list(
    contract_version = DISCHARGE_F0_CONTRACT_VERSION,
    discharge = discharge,
    inverts_site_years = inverts_site_years,
    inverts_projection_receipt = inverts_projection_receipt,
    primary_gate = gate,
    sensitivity_counts = sensitivity_counts,
    app_path_called = FALSE,
    effect_path_called = FALSE,
    estimator_path_called = FALSE,
    prior_path_called = FALSE,
    vote_path_called = FALSE,
    driver_artifact_path_called = FALSE)
}

# Production-facing F1/F2 boundary: consume the committed values-free Inverts
# authority directly and require its exact frozen roster before discharge work.
discharge_feasibility_contract <- function(
    csd_15_min, csd_continuousDischarge, inverts_site_years) {
  discharge_f0_assert_exact_inverts_authority(inverts_site_years)
  receipt <- .discharge_f0_empty_inverts_receipt()
  receipt$n_rows[receipt$state == "eligible_stream"] <-
    as.integer(nrow(inverts_site_years))
  .discharge_f0_run_contract(
    csd_15_min, csd_continuousDischarge, inverts_site_years, receipt)
}

# Synthetic-fixture adapter. This is the only top-level helper that accepts the
# four opportunity fields; it projects them to the exact values-free boundary
# before running the same effect-blind reduction.
discharge_feasibility_contract_from_opportunities <- function(
    csd_15_min, csd_continuousDischarge, inverts_opportunities) {
  reduced <- .discharge_f0_reduce_inverts(inverts_opportunities)
  .discharge_f0_run_contract(
    csd_15_min, csd_continuousDischarge, reduced$site_years,
    reduced$projection_receipt)
}
