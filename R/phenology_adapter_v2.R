# Driver-owned Phenology v2 adapter.
#
# Seal 1 boundary: definitions in this file are pure and synthetic-only. They do
# not read files, inspect Git, load sibling code, touch climate data, or calculate
# an effect. Later sealed runners may supply already verified inert bundle objects.

PHENOLOGY_V2_TARGET_PHASES <- c(
  "Breaking leaf buds", "Initial growth", "Emerging needles",
  "Breaking needle buds"
)
PHENOLOGY_V2_DRIVER_YEARS <- 2013:2025
PHENOLOGY_V2_ALLOWED_STATUS <- c("yes", "no", "uncertain")
PHENOLOGY_V2_SEAL1_MODE <- "seal1-synthetic-response"

PHENOLOGY_V2_CALENDAR_STATES <- c(
  "inside_driver_window", "outside_driver_window"
)
PHENOLOGY_V2_TAXONOMY_STATES <- c(
  "eligible_species", "taxon_rank_ineligible",
  "roster_unmatched_taxon_unknown"
)
PHENOLOGY_V2_OBSERVATION_STATES <- c(
  "bounded_onset", "left_censored_onset", "right_censored_no_yes",
  "uncertain_only", "status_conflict_only", "ambiguous_competing_phase",
  "structural_unscored"
)
PHENOLOGY_V2_ELIGIBILITY_STATES <- c(
  "pending", "model_row", "species_year_excluded", "recurrence_excluded",
  "connected_panel_excluded"
)
PHENOLOGY_V2_COMPAT_CENSOR_STATES <- c(
  "compat_bounded", "compat_left_censored", "compat_no_finite_onset"
)
PHENOLOGY_V2_ANNUAL_RESPONSE_STATES <- c(
  "supported", "insufficient_observed_species",
  "insufficient_timing_individuals", "no_retained_panel"
)
PHENOLOGY_V2_REASON_CODES <- c(
  "source_row_added", "source_row_removed", "source_value_changed",
  "source_day_missing", "source_day_disagrees_with_date",
  "visit_status_conflict", "roster_identity_unresolved",
  "historical_plot_disagreement", "calendar_window",
  "compat_censor_state_changed", "v2_observation_state_changed",
  "taxon_identity_changed", "species_year_support", "species_recurrence",
  "connected_component", "annual_support", "cadence_audit_changed",
  "thin_greenup", "model_support"
)

phenology_v2_fail <- function(code, message) {
  condition <- structure(
    list(message = sprintf("[%s] %s", code, message), call = NULL, code = code),
    class = c("phenology_v2_error", "error", "condition")
  )
  stop(condition)
}

phenology_v2_assert_seal1 <- function(mode = PHENOLOGY_V2_SEAL1_MODE,
                                      effect_locked = TRUE) {
  if (length(mode) != 1L || is.na(mode) ||
      !identical(as.character(mode), PHENOLOGY_V2_SEAL1_MODE) ||
      length(effect_locked) != 1L || !isTRUE(effect_locked)) {
    phenology_v2_fail(
      "effect_lock",
      "Phenology v2 Seal 1 accepts only the locked synthetic-response mode"
    )
  }
  if ("metafor" %in% loadedNamespaces()) {
    phenology_v2_fail(
      "effect_namespace_loaded",
      "metafor must not be loaded in the adapter/response process"
    )
  }
  invisible(TRUE)
}

phenology_v2_nonblank <- function(x) {
  value <- as.character(x)
  !is.na(x) & !is.na(value) & nzchar(trimws(value))
}

phenology_v2_scalar_nonblank <- function(x, label) {
  if (length(x) != 1L || !phenology_v2_nonblank(x))
    phenology_v2_fail("invalid_site_identity", sprintf("%s must be one nonblank value", label))
  as.character(x)
}

phenology_v2_forbidden_climate_name <- function(x) {
  token <- gsub(
    "[^a-z0-9]", "", tolower(enc2utf8(as.character(x)))
  )
  token %in% c("env", "environment", "temp", "tempc", "tempspring") |
    grepl("climate|temperature|precip", token, perl = TRUE)
}

phenology_v2_forbidden_effect_name <- function(x) {
  token <- gsub(
    "[^a-z0-9]", "", tolower(enc2utf8(as.character(x)))
  )
  grepl(
    paste0(
      "effect|correlation|association|coefficient|pvalue|pval|vote|direction|",
      "pooled|sitelink|metafor|rma"
    ),
    token,
    perl = TRUE
  )
}

phenology_v2_forbidden_payload_name <- function(x) {
  token <- gsub(
    "[^a-z0-9]", "", tolower(enc2utf8(as.character(x)))
  )
  phenology_v2_forbidden_climate_name(x) |
    phenology_v2_forbidden_effect_name(x) |
    grepl(
      paste0(
        "response|model|prediction"
      ),
      token,
      perl = TRUE
    )
}

phenology_v2_package_altrep <- function(x) {
  injected <- getOption("phenology.v2.package_altrep_probe", NULL)
  if (!is.null(injected)) {
    if (!is.function(injected))
      phenology_v2_fail("invalid_altrep_probe", "ALTREP test probe must be a function")
    answer <- injected(x)
    if (length(answer) != 1L || is.na(answer))
      phenology_v2_fail("invalid_altrep_probe", "ALTREP test probe must return one boolean")
    return(isTRUE(answer))
  }

  # Base R exposes no stable high-level ALTREP predicate. Its diagnostic header
  # does distinguish known package-backed classes; base compact sequences and
  # deferred string conversion are deliberately not classified as package-backed.
  header <- tryCatch(
    capture.output(.Internal(inspect(x)))[1L],
    error = function(e) ""
  )
  grepl(
    "(?:vroom_|arrow_|fst_|qs_|altrep.*(?:package|class)|materialized\\s*=)",
    tolower(header), perl = TRUE
  )
}

phenology_v2_validate_frame <- function(x, label, nonempty = FALSE) {
  if (!is.data.frame(x))
    phenology_v2_fail("malformed_container", sprintf("%s must be a data frame", label))
  if (is.null(names(x)) || anyNA(names(x)) ||
      any(!nzchar(names(x))) || anyDuplicated(names(x)))
    phenology_v2_fail("duplicate_or_blank_columns", sprintf("%s must have unique nonblank column names", label))
  if (nonempty && nrow(x) == 0L)
    phenology_v2_fail("empty_required_table", sprintf("%s must be nonempty", label))
  if (nrow(x) > 0L && any(lengths(x) == 0L))
    phenology_v2_fail("zero_length_column", sprintf("%s has a zero-length column", label))
  if (any(lengths(x) != nrow(x)))
    phenology_v2_fail("nonrectangular_table", sprintf("%s is not rectangular", label))
  for (column in names(x)) {
    value <- x[[column]]
    if ((is.list(value) && !is.data.frame(value)) || !is.null(dim(value)))
      phenology_v2_fail(
        "incompatible_column",
        sprintf("%s$%s must be a one-dimensional atomic vector", label, column)
      )
    if (phenology_v2_package_altrep(value))
      phenology_v2_fail("package_altrep_column", sprintf("%s$%s is package-backed ALTREP", label, column))
  }
  invisible(x)
}

phenology_v2_require_columns <- function(x, required, label) {
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    phenology_v2_fail(
      "missing_required_field",
      sprintf("%s lacks field(s): %s", label, paste(missing, collapse = ", "))
    )
  }
  invisible(x)
}

phenology_v2_integer <- function(x, label, allow_na = FALSE) {
  if (!is.numeric(x) || is.logical(x) || is.complex(x))
    phenology_v2_fail("incompatible_type", sprintf("%s must be numeric integer-compatible", label))
  invalid_na <- !allow_na & is.na(x)
  invalid_value <- !is.na(x) & (!is.finite(x) | x != trunc(x))
  if (any(invalid_na | invalid_value))
    phenology_v2_fail("invalid_integer", sprintf("%s contains invalid integer values", label))
  as.integer(x)
}

phenology_v2_parse_date <- function(x, label) {
  if (inherits(x, "POSIXt"))
    phenology_v2_fail("invalid_date", sprintf("%s must not be a timezone-bearing datetime", label))
  raw <- as.character(x)
  parsed <- suppressWarnings(tryCatch(as.Date(raw), error = function(e) rep(as.Date(NA), length(raw))))
  if (length(parsed) != length(raw) || any(is.na(parsed)))
    phenology_v2_fail("invalid_date", sprintf("%s contains an invalid date", label))
  parsed
}

phenology_v2_doy <- function(date) {
  as.integer(format(date, "%j", tz = "UTC"))
}

phenology_v2_key <- function(...) {
  values <- list(...)
  if (!length(values)) return(character())
  n <- unique(lengths(values))
  if (length(n) != 1L)
    phenology_v2_fail("internal_key_length", "key columns have unequal lengths")
  encoded <- lapply(values, function(x) {
    value <- enc2utf8(as.character(x))
    missing <- is.na(x) | is.na(value)
    bytes <- nchar(value, type = "bytes", allowNA = TRUE)
    out <- paste0(bytes, "#", value)
    out[missing] <- "-1#"
    out
  })
  do.call(paste, c(encoded, sep = "\u001f"))
}

phenology_v2_groups <- function(key) {
  if (!length(key)) return(list())
  split(seq_along(key), factor(key, levels = unique(key)), drop = TRUE)
}

phenology_v2_bind <- function(rows, template) {
  rows <- rows[lengths(rows) > 0L]
  if (!length(rows)) return(template[0, , drop = FALSE])
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

phenology_v2_radix_order <- function(...) {
  order(..., method = "radix", na.last = TRUE)
}

phenology_v2_canonical_table_bytes <- function(x, key = names(x)) {
  phenology_v2_validate_frame(x, "canonical table", nonempty = FALSE)
  if (!all(key %in% names(x)) || anyDuplicated(key))
    phenology_v2_fail("invalid_canonical_key", "canonical key must name unique table columns")
  if (nrow(x) && length(key)) {
    order_args <- lapply(key, function(column) x[[column]])
    order_args$method <- "radix"
    order_args$na.last <- TRUE
    x <- x[do.call(order, order_args), , drop = FALSE]
  }
  encode_column <- function(value) {
    if (inherits(value, "Date")) {
      token <- ifelse(is.na(value), "NA", as.character(as.integer(value)))
      return(paste0("D:", token))
    }
    if (is.factor(value)) {
      text <- enc2utf8(as.character(value))
      token <- ifelse(is.na(text), "NA", paste0(nchar(text, type = "bytes"), "#", text))
      return(paste0("F:", token))
    }
    if (is.character(value)) {
      text <- enc2utf8(value)
      token <- ifelse(is.na(text), "NA", paste0(nchar(text, type = "bytes"), "#", text))
      return(paste0("C:", token))
    }
    if (is.logical(value))
      return(paste0("L:", ifelse(is.na(value), "NA", ifelse(value, "1", "0"))))
    if (is.integer(value))
      return(paste0("I:", ifelse(is.na(value), "NA", as.character(value))))
    if (is.numeric(value)) {
      token <- rep(NA_character_, length(value))
      token[is.na(value) & !is.nan(value)] <- "NA"
      token[is.nan(value)] <- "NaN"
      token[is.infinite(value) & value > 0] <- "+Inf"
      token[is.infinite(value) & value < 0] <- "-Inf"
      finite <- is.finite(value)
      token[finite] <- sprintf("%a", value[finite])
      return(paste0("N:", token))
    }
    phenology_v2_fail("unsupported_canonical_type", "canonical table contains an unsupported column type")
  }
  header <- paste0("COL:", nchar(enc2utf8(names(x)), type = "bytes"), "#", enc2utf8(names(x)))
  rows <- if (nrow(x)) {
    encoded <- lapply(x, encode_column)
    apply(as.data.frame(encoded, stringsAsFactors = FALSE), 1L, paste, collapse = "\u001f")
  } else character()
  charToRaw(enc2utf8(paste(c(header, rows, ""), collapse = "\n")))
}

phenology_v2_validate_bundle <- function(bundle, site) {
  site <- phenology_v2_scalar_nonblank(site, "site")
  required_members <- c("obs", "inds", "meta", "ind_summary", "trend")
  if (!is.list(bundle) || is.data.frame(bundle) || is.null(names(bundle)) ||
      anyNA(names(bundle)) || any(!nzchar(names(bundle))) ||
      anyDuplicated(names(bundle))) {
    phenology_v2_fail("malformed_container", "Phenology bundle must be a uniquely named list")
  }
  missing <- setdiff(required_members, names(bundle))
  if (length(missing))
    phenology_v2_fail("missing_bundle_member", sprintf("bundle lacks member(s): %s", paste(missing, collapse = ", ")))
  extra_members <- setdiff(names(bundle), required_members)
  bad_members <- extra_members[
    phenology_v2_forbidden_payload_name(extra_members)
  ]
  for (member in setdiff(extra_members, bad_members)) {
    value <- bundle[[member]]
    nested_names <- if (is.list(value) || is.data.frame(value)) names(value) else NULL
    if (length(nested_names) && any(phenology_v2_forbidden_payload_name(nested_names)))
      bad_members <- c(bad_members, member)
  }
  if (length(bad_members))
    phenology_v2_fail(
      "effect_lock",
      sprintf(
        "Phenology bundle contains a forbidden climate/response/effect payload: %s",
        paste(sort(unique(bad_members), method = "radix"), collapse = ", ")
      )
    )

  phenology_v2_validate_frame(bundle$obs, sprintf("%s obs", site), nonempty = TRUE)
  phenology_v2_validate_frame(bundle$inds, sprintf("%s inds", site), nonempty = TRUE)
  phenology_v2_validate_frame(bundle$ind_summary, sprintf("%s ind_summary", site), nonempty = FALSE)
  if (!is.null(bundle$trend))
    phenology_v2_validate_frame(bundle$trend, sprintf("%s trend", site), nonempty = TRUE)

  if (!is.list(bundle$meta) || is.data.frame(bundle$meta) || is.null(names(bundle$meta)) ||
      anyNA(names(bundle$meta)) || any(!nzchar(names(bundle$meta))) ||
      anyDuplicated(names(bundle$meta)))
    phenology_v2_fail("conflicting_metadata", sprintf("%s meta must be a uniquely named list", site))
  missing_meta <- setdiff(c("site", "lat", "lng", "years"), names(bundle$meta))
  if (length(missing_meta))
    phenology_v2_fail("missing_required_field",
                      sprintf("%s meta lacks field(s): %s", site,
                              paste(missing_meta, collapse = ", ")))
  extra_meta <- setdiff(names(bundle$meta), c("site", "lat", "lng", "years"))
  if (any(phenology_v2_forbidden_payload_name(extra_meta)))
    phenology_v2_fail(
      "effect_lock",
      "Phenology metadata contains a forbidden climate/response/effect payload"
    )
  if (length(bundle$meta$site) != 1L || !identical(as.character(bundle$meta$site), site))
    phenology_v2_fail("site_identity_conflict", sprintf("file site %s disagrees with meta$site", site))
  if (length(bundle$meta$lat) != 1L || length(bundle$meta$lng) != 1L ||
      !is.numeric(bundle$meta$lat) || !is.numeric(bundle$meta$lng) ||
      !is.finite(bundle$meta$lat) || !is.finite(bundle$meta$lng))
    phenology_v2_fail("conflicting_metadata", sprintf("%s meta coordinates must be finite scalars", site))
  phenology_v2_integer(bundle$meta$years, sprintf("%s meta$years", site), allow_na = FALSE)

  obs_required <- c(
    "individualID", "plotID", "scientificName", "growthForm", "year", "date",
    "dayOfYear", "phenophaseName", "status", "intensity", "is_species"
  )
  inds_required <- c(
    "individualID", "scientificName", "growthForm", "plotID", "lat", "lng",
    "nativeStatusCode", "taxonRank", "is_species"
  )
  phenology_v2_require_columns(bundle$obs, obs_required, sprintf("%s obs", site))
  phenology_v2_require_columns(bundle$inds, inds_required, sprintf("%s inds", site))
  bad_source_columns <- c(
    setdiff(names(bundle$obs), obs_required)[
      phenology_v2_forbidden_payload_name(setdiff(names(bundle$obs), obs_required))
    ],
    setdiff(names(bundle$inds), inds_required)[
      phenology_v2_forbidden_payload_name(setdiff(names(bundle$inds), inds_required))
    ]
  )
  comparison_columns <- c(
    names(bundle$ind_summary),
    if (is.null(bundle$trend)) character() else names(bundle$trend)
  )
  bad_comparison_columns <- comparison_columns[
    phenology_v2_forbidden_climate_name(comparison_columns)
  ]
  if (length(c(bad_source_columns, bad_comparison_columns)))
    phenology_v2_fail(
      "effect_lock",
      sprintf(
        "Phenology bundle tables contain a forbidden climate/effect payload: %s",
        paste(
          sort(unique(c(bad_source_columns, bad_comparison_columns)),
               method = "radix"),
          collapse = ", "
        )
      )
    )
  if (!is.null(bundle$trend)) {
    phenology_v2_require_columns(bundle$trend, c("scientificName", "year", "onset", "n"),
                                 sprintf("%s trend", site))
    trend <- bundle$trend
    trend_key <- if (is.character(trend$scientificName) &&
                       is.numeric(trend$year))
      phenology_v2_key(trend$scientificName, trend$year) else character()
    if (!is.character(trend$scientificName) ||
        any(!phenology_v2_nonblank(trend$scientificName)) ||
        !is.numeric(trend$year) || is.logical(trend$year) ||
        anyNA(trend$year) || any(!is.finite(trend$year)) ||
        any(trend$year != trunc(trend$year)) ||
        any(!trend$year %in% PHENOLOGY_V2_DRIVER_YEARS) ||
        !is.numeric(trend$n) || is.logical(trend$n) ||
        anyNA(trend$n) || any(!is.finite(trend$n)) ||
        any(trend$n != trunc(trend$n)) || any(trend$n < 3) ||
        !is.numeric(trend$onset) || is.logical(trend$onset) ||
        anyNA(trend$onset) || any(!is.finite(trend$onset)) ||
        any(trend$onset < 1 | trend$onset > 366) ||
        anyDuplicated(trend_key))
      phenology_v2_fail(
        "invalid_trend_support",
        sprintf(
          "%s trend requires unique nonblank species/year keys, finite DOY 1-366, and integer n >= 3",
          site
        )
      )
  }
  invisible(bundle)
}

phenology_v2_normalize_source <- function(bundle, site) {
  obs <- bundle$obs
  inds <- bundle$inds
  n <- nrow(obs)

  if (!all(phenology_v2_nonblank(obs$individualID)))
    phenology_v2_fail("blank_observation_identity", sprintf("%s obs has blank individualID", site))
  if (!all(phenology_v2_nonblank(obs$plotID)))
    phenology_v2_fail("blank_plot_identity", sprintf("%s obs has blank plotID", site))
  if (!all(phenology_v2_nonblank(obs$phenophaseName)))
    phenology_v2_fail("blank_phenophase", sprintf("%s obs has blank phenophaseName", site))
  status <- as.character(obs$status)
  if (any(is.na(status) | !status %in% PHENOLOGY_V2_ALLOWED_STATUS))
    phenology_v2_fail("unsupported_status", sprintf("%s obs contains a non-exact status token", site))
  year <- phenology_v2_integer(obs$year, sprintf("%s obs$year", site))
  date <- phenology_v2_parse_date(obs$date, sprintf("%s obs$date", site))
  date_year <- as.integer(format(date, "%Y", tz = "UTC"))
  if (any(date_year != year))
    phenology_v2_fail("date_year_mismatch", sprintf("%s obs date/year values disagree", site))
  visit_doy <- phenology_v2_doy(date)

  source_doy <- obs$dayOfYear
  if (!is.numeric(source_doy) || is.logical(source_doy) || is.complex(source_doy))
    phenology_v2_fail("invalid_source_doy_type", sprintf("%s obs$dayOfYear must be numeric", site))
  if (any(is.nan(source_doy)))
    phenology_v2_fail("invalid_source_doy_nan", sprintf("%s obs$dayOfYear contains NaN", site))
  present_doy <- !is.na(source_doy)
  if (any(present_doy & (!is.finite(source_doy) | source_doy != trunc(source_doy) |
                         source_doy < 1 | source_doy > 366)))
    phenology_v2_fail("invalid_source_doy_value", sprintf("%s obs$dayOfYear contains an invalid nonmissing value", site))
  source_doy <- as.integer(source_doy)

  if (!is.logical(obs$is_species))
    phenology_v2_fail("invalid_species_flag", sprintf("%s obs$is_species must be logical", site))
  if (!all(phenology_v2_nonblank(inds$individualID)) || anyDuplicated(as.character(inds$individualID)))
    phenology_v2_fail("duplicate_roster_identity", sprintf("%s roster identities must be unique and nonblank", site))
  if (!all(phenology_v2_nonblank(inds$plotID)))
    phenology_v2_fail("blank_plot_identity", sprintf("%s roster has blank plotID", site))
  if (!is.logical(inds$is_species))
    phenology_v2_fail("invalid_species_flag", sprintf("%s inds$is_species must be logical", site))
  if (!is.numeric(inds$lat) || !is.numeric(inds$lng) ||
      any(!is.finite(inds$lat) | !is.finite(inds$lng)))
    phenology_v2_fail("invalid_roster_coordinates", sprintf("%s roster coordinates must be finite", site))

  roster_match <- match(as.character(obs$individualID), as.character(inds$individualID))
  matched <- !is.na(roster_match)
  tax_char_missing <- !phenology_v2_nonblank(obs$scientificName) &
    !phenology_v2_nonblank(obs$growthForm)
  tax_flag_missing <- is.na(obs$is_species)
  asserted_unmatched <- !matched & !(tax_char_missing & tax_flag_missing)
  if (any(asserted_unmatched))
    phenology_v2_fail("unmatched_asserted_taxonomy", sprintf("%s has an unmatched identity asserting taxonomy", site))

  compare_character <- function(field) {
    ix <- which(matched & phenology_v2_nonblank(obs[[field]]))
    if (!length(ix)) return(invisible(TRUE))
    roster <- inds[[field]][roster_match[ix]]
    if (any(!phenology_v2_nonblank(roster) |
            as.character(obs[[field]][ix]) != as.character(roster)))
      phenology_v2_fail("roster_taxonomy_conflict", sprintf("%s obs/roster %s values disagree", site, field))
    invisible(TRUE)
  }
  compare_character("scientificName")
  compare_character("growthForm")
  ix_flag <- which(matched & !is.na(obs$is_species))
  if (length(ix_flag)) {
    roster_flag <- inds$is_species[roster_match[ix_flag]]
    if (any(is.na(roster_flag) | obs$is_species[ix_flag] != roster_flag))
      phenology_v2_fail("roster_taxonomy_conflict", sprintf("%s obs/roster is_species values disagree", site))
  }

  stable_scientific <- rep(NA_character_, n)
  stable_growth <- rep(NA_character_, n)
  stable_species <- rep(NA, n)
  stable_roster_plot <- rep(NA_character_, n)
  if (any(matched)) {
    stable_scientific[matched] <- as.character(inds$scientificName[roster_match[matched]])
    stable_growth[matched] <- as.character(inds$growthForm[roster_match[matched]])
    stable_species[matched] <- inds$is_species[roster_match[matched]]
    stable_roster_plot[matched] <- as.character(inds$plotID[roster_match[matched]])
  }

  rows <- data.frame(
    site = rep(site, n),
    individualID = as.character(obs$individualID),
    plotID = as.character(obs$plotID),
    roster_plotID = stable_roster_plot,
    scientificName = stable_scientific,
    growthForm = stable_growth,
    is_species = stable_species,
    source_scientificName = as.character(obs$scientificName),
    source_growthForm = as.character(obs$growthForm),
    source_is_species = obs$is_species,
    year = year, date = date, visit_doy = visit_doy,
    source_doy = source_doy,
    source_doy_missing = is.na(source_doy),
    source_doy_mismatch = present_doy & source_doy != visit_doy,
    phenophaseName = as.character(obs$phenophaseName),
    status = status, intensity = obs$intensity,
    roster_matched = matched,
    plot_history_mismatch = matched & as.character(obs$plotID) != stable_roster_plot,
    stringsAsFactors = FALSE
  )
  intensity_sort <- enc2utf8(as.character(rows$intensity))
  rows <- rows[phenology_v2_radix_order(rows$site, rows$year, rows$individualID,
                                        rows$phenophaseName, rows$date, rows$plotID,
                                        rows$source_scientificName,
                                        rows$source_growthForm, rows$source_is_species,
                                        rows$source_doy, rows$status, intensity_sort),
               , drop = FALSE]
  rownames(rows) <- NULL
  rows$source_row <- seq_len(nrow(rows))
  rows <- rows[c("source_row", setdiff(names(rows), "source_row"))]
  rows
}

phenology_v2_normalize_visits <- function(source_rows) {
  key <- phenology_v2_key(source_rows$site, source_rows$individualID,
                          source_rows$phenophaseName, source_rows$date)
  groups <- phenology_v2_groups(key)
  template <- data.frame(
    site = character(), individualID = character(), plotID = character(),
    scientificName = character(), growthForm = character(), is_species = logical(),
    year = integer(), date = as.Date(character()), visit_doy = integer(),
    phenophaseName = character(), visit_status = character(),
    source_row_count = integer(), duplicate_same_status = logical(),
    source_doy_missing_rows = integer(), source_doy_mismatch_rows = integer(),
    source_doy_distinct = integer(), plot_history_mismatch_rows = integer(),
    roster_matched = logical(), stringsAsFactors = FALSE
  )
  rows <- lapply(groups, function(ix) {
    d <- source_rows[ix, , drop = FALSE]
    if (length(unique(d$plotID)) != 1L)
      phenology_v2_fail("conflicting_visit_plots", "one exact visit has conflicting nonblank plots")
    for (field in c("year", "visit_doy", "scientificName", "growthForm", "is_species", "roster_matched")) {
      values <- unique(d[[field]])
      values <- values[!is.na(values)]
      if (length(values) > 1L)
        phenology_v2_fail("conflicting_visit_metadata", sprintf("one exact visit has conflicting %s", field))
    }
    statuses <- sort(unique(d$status), method = "radix")
    visit_status <- if (length(statuses) == 1L) statuses else "visit_status_conflict"
    finite_source <- sort(unique(d$source_doy[!is.na(d$source_doy)]), method = "radix")
    data.frame(
      site = d$site[1L], individualID = d$individualID[1L], plotID = d$plotID[1L],
      scientificName = d$scientificName[1L], growthForm = d$growthForm[1L],
      is_species = d$is_species[1L], year = d$year[1L], date = d$date[1L],
      visit_doy = d$visit_doy[1L], phenophaseName = d$phenophaseName[1L],
      visit_status = visit_status, source_row_count = nrow(d),
      duplicate_same_status = nrow(d) > 1L && length(statuses) == 1L,
      source_doy_missing_rows = sum(d$source_doy_missing),
      source_doy_mismatch_rows = sum(d$source_doy_mismatch),
      source_doy_distinct = length(finite_source),
      plot_history_mismatch_rows = sum(d$plot_history_mismatch),
      roster_matched = d$roster_matched[1L], stringsAsFactors = FALSE
    )
  })
  out <- phenology_v2_bind(rows, template)
  out <- out[phenology_v2_radix_order(out$site, out$year, out$individualID,
                                      out$phenophaseName, out$date), , drop = FALSE]
  rownames(out) <- NULL
  out
}

phenology_v2_phase_records <- function(visits) {
  target <- visits[visits$phenophaseName %in% PHENOLOGY_V2_TARGET_PHASES, , drop = FALSE]
  template <- data.frame(
    site = character(), individualID = character(), scientificName = character(),
    growthForm = character(), phenophaseName = character(), year = integer(),
    phase_state = character(), lower_doy = numeric(), upper_doy = numeric(),
    midpoint_doy = numeric(), interval_days = numeric(), first_yes = numeric(),
    last_no = numeric(), uncertain_visits = integer(), conflict_visits = integer(),
    stringsAsFactors = FALSE
  )
  if (!nrow(target)) return(template)
  key <- phenology_v2_key(target$site, target$individualID, target$scientificName,
                          target$growthForm, target$phenophaseName, target$year)
  rows <- lapply(phenology_v2_groups(key), function(ix) {
    d <- target[ix, , drop = FALSE]
    yes <- d$visit_doy[d$visit_status == "yes"]
    no <- d$visit_doy[d$visit_status == "no"]
    uncertain_n <- sum(d$visit_status == "uncertain")
    conflict_n <- sum(d$visit_status == "visit_status_conflict")
    first_yes <- if (length(yes)) min(yes) else NA_real_
    preceding <- if (length(yes)) no[no < first_yes] else numeric()
    if (length(yes) && length(preceding)) {
      state <- "bounded"
      lower <- max(preceding)
      upper <- first_yes
      midpoint <- (lower + upper) / 2
      width <- upper - lower
    } else if (length(yes)) {
      state <- "left_censored"
      lower <- NA_real_
      upper <- first_yes
      midpoint <- NA_real_
      width <- NA_real_
    } else if (length(no)) {
      state <- "right_censored_no_yes"
      lower <- max(no)
      upper <- Inf
      midpoint <- NA_real_
      width <- NA_real_
    } else if (conflict_n > 0L) {
      state <- "status_conflict_only"
      lower <- upper <- midpoint <- width <- NA_real_
    } else {
      state <- "uncertain_only"
      lower <- upper <- midpoint <- width <- NA_real_
    }
    if (identical(state, "bounded") &&
        (!is.finite(lower) || !is.finite(upper) || lower < 1 || upper > 366 || lower >= upper))
      phenology_v2_fail("invalid_interval", "bounded phase interval is not strictly increasing inside 1-366")
    data.frame(
      site = d$site[1L], individualID = d$individualID[1L],
      scientificName = d$scientificName[1L], growthForm = d$growthForm[1L],
      phenophaseName = d$phenophaseName[1L], year = d$year[1L],
      phase_state = state, lower_doy = lower, upper_doy = upper,
      midpoint_doy = midpoint, interval_days = width, first_yes = first_yes,
      last_no = if (length(no)) max(no) else NA_real_,
      uncertain_visits = uncertain_n, conflict_visits = conflict_n,
      stringsAsFactors = FALSE
    )
  })
  out <- phenology_v2_bind(rows, template)
  out <- out[phenology_v2_radix_order(out$site, out$year, out$individualID,
                                      out$phenophaseName), , drop = FALSE]
  rownames(out) <- NULL
  out
}

phenology_v2_compatibility_phases <- function(source_rows) {
  d <- source_rows[
    source_rows$phenophaseName %in% PHENOLOGY_V2_TARGET_PHASES &
      source_rows$status %in% c("yes", "no") & !is.na(source_rows$source_doy),
    , drop = FALSE
  ]
  template <- data.frame(
    site = character(), individualID = character(), scientificName = character(),
    growthForm = character(), phenophaseName = character(), year = integer(),
    compat_onset = numeric(), compat_left_censored = logical(),
    first_yes = numeric(), stringsAsFactors = FALSE
  )
  if (!nrow(d)) return(template)
  key <- phenology_v2_key(d$site, d$individualID, d$source_scientificName,
                          d$source_growthForm, d$phenophaseName, d$year)
  rows <- lapply(phenology_v2_groups(key), function(ix) {
    x <- d[ix, , drop = FALSE]
    yes <- x$source_doy[x$status == "yes"]
    no <- x$source_doy[x$status == "no"]
    if (!length(yes)) return(NULL)
    first <- min(yes)
    preceding <- no[no < first]
    left <- !length(preceding)
    onset <- if (left) first else (max(preceding) + first) / 2
    data.frame(
      site = x$site[1L], individualID = x$individualID[1L],
      scientificName = x$source_scientificName[1L],
      growthForm = x$source_growthForm[1L], phenophaseName = x$phenophaseName[1L],
      year = x$year[1L], compat_onset = onset,
      compat_left_censored = left, first_yes = first,
      stringsAsFactors = FALSE
    )
  })
  out <- phenology_v2_bind(rows, template)
  out <- out[phenology_v2_radix_order(out$site, out$year, out$individualID,
                                      out$phenophaseName, out$scientificName), , drop = FALSE]
  rownames(out) <- NULL
  out
}

phenology_v2_compatibility_individual_years <- function(phases) {
  template <- data.frame(
    site = character(), individualID = character(), year = integer(),
    scientificName = character(), compat_onset = numeric(),
    compat_censor_state = character(), compat_interval_days = numeric(),
    stringsAsFactors = FALSE
  )
  if (!nrow(phases)) return(template)
  key <- phenology_v2_key(phases$site, phases$individualID, phases$year)
  rows <- lapply(phenology_v2_groups(key), function(ix) {
    d <- phases[ix, , drop = FALSE]
    onset <- min(d$compat_onset)
    tied <- which(d$compat_onset == onset)
    taxa <- sort(unique(as.character(d$scientificName[tied])), method = "radix", na.last = TRUE)
    taxa <- taxa[!is.na(taxa) & nzchar(taxa)]
    widths <- 2 * (d$first_yes[tied] - d$compat_onset[tied])
    widths <- widths[is.finite(widths)]
    left <- any(d$compat_left_censored[tied] %in% TRUE)
    data.frame(
      site = d$site[1L], individualID = d$individualID[1L], year = d$year[1L],
      scientificName = if (length(taxa)) taxa[1L] else NA_character_,
      compat_onset = onset,
      compat_censor_state = if (left) "compat_left_censored" else "compat_bounded",
      compat_interval_days = if (length(widths)) max(widths) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  out <- phenology_v2_bind(rows, template)
  out <- out[phenology_v2_radix_order(out$site, out$year, out$individualID), , drop = FALSE]
  rownames(out) <- NULL
  out
}

phenology_v2_individual_years <- function(source_rows, phases, compatibility) {
  key <- phenology_v2_key(source_rows$site, source_rows$individualID, source_rows$year)
  groups <- phenology_v2_groups(key)
  template <- data.frame(
    site = character(), individualID = character(), year = integer(),
    scientificName = character(), growthForm = character(), is_species = logical(),
    calendar_state = character(), taxonomy_state = character(),
    v2_observation_state = character(), v2_eligibility_state = character(),
    compat_censor_state = character(), terminal_state = character(),
    lower_doy = numeric(), upper_doy = numeric(), midpoint_doy = numeric(),
    interval_days = numeric(), compat_onset = numeric(),
    compat_interval_days = numeric(), target_phase_count = integer(),
    uncertain_visits = integer(), conflict_visits = integer(),
    stringsAsFactors = FALSE
  )
  rows <- lapply(groups, function(ix) {
    d <- source_rows[ix, , drop = FALSE]
    stable_taxa <- unique(d$scientificName[phenology_v2_nonblank(d$scientificName)])
    stable_growth <- unique(d$growthForm[phenology_v2_nonblank(d$growthForm)])
    stable_rank <- unique(d$is_species[!is.na(d$is_species)])
    if (length(stable_taxa) > 1L || length(stable_growth) > 1L || length(stable_rank) > 1L)
      phenology_v2_fail("roster_taxonomy_conflict", "one plant-year has unstable roster taxonomy")
    scientific <- if (length(stable_taxa)) stable_taxa[1L] else NA_character_
    growth <- if (length(stable_growth)) stable_growth[1L] else NA_character_
    rank <- if (length(stable_rank)) stable_rank[1L] else NA
    unmatched <- !any(d$roster_matched)
    taxonomy <- if (unmatched) {
      "roster_unmatched_taxon_unknown"
    } else if (isTRUE(rank) && phenology_v2_nonblank(scientific)) {
      "eligible_species"
    } else {
      "taxon_rank_ineligible"
    }
    calendar <- if (d$year[1L] %in% PHENOLOGY_V2_DRIVER_YEARS)
      "inside_driver_window" else "outside_driver_window"

    phase_ix <- which(phases$site == d$site[1L] &
                        phases$individualID == d$individualID[1L] &
                        phases$year == d$year[1L])
    p <- phases[phase_ix, , drop = FALSE]
    lower <- upper <- midpoint <- width <- NA_real_
    if (!nrow(p)) {
      observation <- "structural_unscored"
    } else {
      ambiguous <- p$phase_state %in% c("uncertain_only", "status_conflict_only")
      informative <- p$phase_state %in% c("bounded", "left_censored", "right_censored_no_yes")
      if (all(p$phase_state == "uncertain_only")) {
        observation <- "uncertain_only"
      } else if (all(p$phase_state == "status_conflict_only")) {
        observation <- "status_conflict_only"
      } else if (any(ambiguous) || !any(informative)) {
        observation <- "ambiguous_competing_phase"
      } else {
        info <- p[informative, , drop = FALSE]
        algebra_lower <- ifelse(info$phase_state == "left_censored", -Inf, info$lower_doy)
        algebra_upper <- ifelse(info$phase_state == "right_censored_no_yes", Inf, info$upper_doy)
        envelope_lower <- min(algebra_lower)
        envelope_upper <- min(algebra_upper)
        if (all(info$phase_state == "right_censored_no_yes")) {
          observation <- "right_censored_no_yes"
          lower <- envelope_lower
          upper <- Inf
        } else if (is.infinite(envelope_lower) && envelope_lower < 0 && is.finite(envelope_upper)) {
          observation <- "left_censored_onset"
          lower <- NA_real_
          upper <- envelope_upper
        } else if (is.finite(envelope_lower) && is.finite(envelope_upper)) {
          if (envelope_lower < 1 || envelope_upper > 366 || envelope_lower >= envelope_upper)
            phenology_v2_fail("impossible_interval_envelope", "earliest-phase envelope is not strictly increasing")
          observation <- "bounded_onset"
          lower <- envelope_lower
          upper <- envelope_upper
          midpoint <- (lower + upper) / 2
          width <- upper - lower
        } else {
          phenology_v2_fail("impossible_interval_envelope", "earliest-phase envelope has impossible bounds")
        }
      }
    }

    compat_ix <- which(compatibility$site == d$site[1L] &
                         compatibility$individualID == d$individualID[1L] &
                         compatibility$year == d$year[1L])
    if (length(compat_ix) > 1L)
      phenology_v2_fail("duplicate_compatibility_key", "compatibility individual-year key is duplicated")
    if (length(compat_ix)) {
      compat_state <- compatibility$compat_censor_state[compat_ix]
      compat_onset <- compatibility$compat_onset[compat_ix]
      compat_width <- compatibility$compat_interval_days[compat_ix]
    } else {
      compat_state <- "compat_no_finite_onset"
      compat_onset <- compat_width <- NA_real_
    }
    terminal <- if (calendar == "outside_driver_window") {
      "outside_driver_window"
    } else if (taxonomy != "eligible_species") {
      taxonomy
    } else {
      observation
    }
    data.frame(
      site = d$site[1L], individualID = d$individualID[1L], year = d$year[1L],
      scientificName = scientific, growthForm = growth, is_species = rank,
      calendar_state = calendar, taxonomy_state = taxonomy,
      v2_observation_state = observation, v2_eligibility_state = "pending",
      compat_censor_state = compat_state, terminal_state = terminal,
      lower_doy = lower, upper_doy = upper, midpoint_doy = midpoint,
      interval_days = width, compat_onset = compat_onset,
      compat_interval_days = compat_width, target_phase_count = nrow(p),
      uncertain_visits = if (nrow(p)) sum(p$uncertain_visits) else 0L,
      conflict_visits = if (nrow(p)) sum(p$conflict_visits) else 0L,
      stringsAsFactors = FALSE
    )
  })
  out <- phenology_v2_bind(rows, template)
  if (any(!out$calendar_state %in% PHENOLOGY_V2_CALENDAR_STATES) ||
      any(!out$taxonomy_state %in% PHENOLOGY_V2_TAXONOMY_STATES) ||
      any(!out$v2_observation_state %in% PHENOLOGY_V2_OBSERVATION_STATES) ||
      any(!out$compat_censor_state %in% PHENOLOGY_V2_COMPAT_CENSOR_STATES))
    phenology_v2_fail("invalid_state_vocabulary", "adapter emitted an undeclared ledger state")
  out <- out[phenology_v2_radix_order(out$site, out$year, out$individualID), , drop = FALSE]
  rownames(out) <- NULL
  out
}

phenology_v2_select_component <- function(cells) {
  template <- data.frame(
    scientificName = character(), year = integer(), component = integer(),
    selected = logical(), stringsAsFactors = FALSE
  )
  if (!nrow(cells)) return(template)
  phenology_v2_require_columns(cells, c("scientificName", "year"), "incidence cells")
  cells <- unique(cells[c("scientificName", "year")])
  if (any(!phenology_v2_nonblank(cells$scientificName)) || any(!is.finite(cells$year)))
    phenology_v2_fail("invalid_incidence_cell", "incidence cells require finite years and named species")
  cells$year <- as.integer(cells$year)
  cells <- cells[phenology_v2_radix_order(cells$scientificName, cells$year), , drop = FALSE]
  species_nodes <- paste0("S:", cells$scientificName)
  year_nodes <- paste0("Y:", cells$year)
  all_nodes <- sort(unique(c(species_nodes, year_nodes)), method = "radix")
  adjacency <- setNames(vector("list", length(all_nodes)), all_nodes)
  for (i in seq_len(nrow(cells))) {
    s <- species_nodes[i]
    y <- year_nodes[i]
    adjacency[[s]] <- unique(c(adjacency[[s]], y))
    adjacency[[y]] <- unique(c(adjacency[[y]], s))
  }
  unseen <- setNames(rep(TRUE, length(all_nodes)), all_nodes)
  components <- list()
  while (any(unseen)) {
    start <- names(unseen)[which(unseen)[1L]]
    queue <- start
    members <- character()
    unseen[start] <- FALSE
    while (length(queue)) {
      node <- queue[1L]
      queue <- queue[-1L]
      members <- c(members, node)
      next_nodes <- sort(adjacency[[node]], method = "radix")
      next_nodes <- next_nodes[unseen[next_nodes]]
      if (length(next_nodes)) {
        unseen[next_nodes] <- FALSE
        queue <- c(queue, next_nodes)
      }
    }
    components[[length(components) + 1L]] <- sort(unique(members), method = "radix")
  }
  component_id <- integer(nrow(cells))
  score <- vector("list", length(components))
  for (i in seq_along(components)) {
    members <- components[[i]]
    component_id[species_nodes %in% members & year_nodes %in% members] <- i
    taxa <- sub("^S:", "", members[startsWith(members, "S:")])
    cell_n <- sum(species_nodes %in% members & year_nodes %in% members)
    score[[i]] <- data.frame(
      component = i, n_species = length(taxa), n_cells = cell_n,
      lexical_species = sort(taxa, method = "radix")[1L],
      stringsAsFactors = FALSE
    )
  }
  score <- do.call(rbind, score)
  winner <- score$component[
    order(-score$n_species, -score$n_cells, score$lexical_species,
          method = "radix")[1L]
  ]
  out <- data.frame(
    scientificName = cells$scientificName, year = cells$year,
    component = component_id, selected = component_id == winner,
    stringsAsFactors = FALSE
  )
  selected_nodes <- c(paste0("S:", out$scientificName[out$selected]),
                      paste0("Y:", out$year[out$selected]))
  selected_rows <- which(out$selected)
  if (length(selected_rows)) {
    reachable <- components[[winner]]
    if (!setequal(unique(selected_nodes), reachable))
      phenology_v2_fail("disconnected_selected_panel", "selected incidence panel is disconnected")
  }
  out
}

phenology_v2_assign_v2_panel <- function(plant_years) {
  candidate <- plant_years$calendar_state == "inside_driver_window" &
    plant_years$v2_observation_state %in% c("bounded_onset", "left_censored_onset")
  plant_years$v2_eligibility_state <- "pending"
  taxon_excluded <- candidate & plant_years$taxonomy_state != "eligible_species"
  plant_years$v2_eligibility_state[taxon_excluded] <- "pending"
  eligible <- plant_years[candidate & plant_years$taxonomy_state == "eligible_species", , drop = FALSE]
  if (!nrow(eligible)) {
    model_rows <- plant_years[0, c("site", "individualID", "year", "scientificName",
                                  "lower_doy", "upper_doy", "v2_observation_state"), drop = FALSE]
    return(list(plant_years = plant_years, model_rows = model_rows,
                cells = data.frame(scientificName = character(), year = integer(),
                                   n_individuals = integer(), n_bounded = integer(),
                                   cell_eligible = logical(), recurrent = logical(),
                                   component = integer(), selected = logical(),
                                   stringsAsFactors = FALSE)))
  }
  key <- phenology_v2_key(eligible$scientificName, eligible$year)
  cell_rows <- lapply(phenology_v2_groups(key), function(ix) {
    d <- eligible[ix, , drop = FALSE]
    data.frame(
      scientificName = d$scientificName[1L], year = d$year[1L],
      n_individuals = length(unique(d$individualID)),
      n_bounded = sum(d$v2_observation_state == "bounded_onset"),
      stringsAsFactors = FALSE
    )
  })
  cells <- do.call(rbind, cell_rows)
  rownames(cells) <- NULL
  cells$cell_eligible <- cells$n_individuals >= 3L & cells$n_bounded >= 1L
  eligible_years <- cells[cells$cell_eligible, , drop = FALSE]
  recurrence <- if (nrow(eligible_years))
    table(eligible_years$scientificName) else integer()
  cells$recurrent <- cells$cell_eligible &
    cells$scientificName %in% names(recurrence)[recurrence >= 3L]
  recurrent_cells <- cells[cells$recurrent, c("scientificName", "year"), drop = FALSE]
  components <- phenology_v2_select_component(recurrent_cells)
  cells$component <- 0L
  cells$selected <- FALSE
  if (nrow(components)) {
    match_key <- phenology_v2_key(cells$scientificName, cells$year)
    component_key <- phenology_v2_key(components$scientificName, components$year)
    m <- match(match_key, component_key)
    hit <- !is.na(m)
    cells$component[hit] <- components$component[m[hit]]
    cells$selected[hit] <- components$selected[m[hit]]
  }
  candidate_ix <- which(candidate & plant_years$taxonomy_state == "eligible_species")
  candidate_key <- phenology_v2_key(plant_years$scientificName[candidate_ix],
                                    plant_years$year[candidate_ix])
  cell_key <- phenology_v2_key(cells$scientificName, cells$year)
  cm <- match(candidate_key, cell_key)
  if (any(is.na(cm)))
    phenology_v2_fail("panel_assignment_failure", "timing candidate lacks a species-year cell")
  disposition <- ifelse(!cells$cell_eligible[cm], "species_year_excluded",
                        ifelse(!cells$recurrent[cm], "recurrence_excluded",
                               ifelse(!cells$selected[cm], "connected_panel_excluded", "model_row")))
  plant_years$v2_eligibility_state[candidate_ix] <- disposition
  model_rows <- plant_years[plant_years$v2_eligibility_state == "model_row",
                            c("site", "individualID", "year", "scientificName",
                              "lower_doy", "upper_doy", "v2_observation_state"),
                            drop = FALSE]
  model_rows <- model_rows[phenology_v2_radix_order(model_rows$site, model_rows$year,
                                                    model_rows$scientificName,
                                                    model_rows$individualID), , drop = FALSE]
  rownames(model_rows) <- NULL
  list(plant_years = plant_years, model_rows = model_rows, cells = cells)
}

phenology_v2_compatibility_panel <- function(plant_years) {
  bounded <- plant_years[
    plant_years$calendar_state == "inside_driver_window" &
      plant_years$taxonomy_state == "eligible_species" &
      plant_years$compat_censor_state == "compat_bounded",
    , drop = FALSE
  ]
  cell_template <- data.frame(
    scientificName = character(), year = integer(), species_onset = numeric(),
    n_individuals = integer(), cell_eligible = logical(), recurrent = logical(),
    component = integer(), selected = logical(), stringsAsFactors = FALSE
  )
  if (!nrow(bounded))
    return(list(cells = cell_template, contributors = bounded, species_reference = numeric()))
  key <- phenology_v2_key(bounded$scientificName, bounded$year)
  rows <- lapply(phenology_v2_groups(key), function(ix) {
    d <- bounded[ix, , drop = FALSE]
    data.frame(
      scientificName = d$scientificName[1L], year = d$year[1L],
      species_onset = stats::median(d$compat_onset),
      n_individuals = length(unique(d$individualID)),
      stringsAsFactors = FALSE
    )
  })
  cells <- do.call(rbind, rows)
  rownames(cells) <- NULL
  cells$cell_eligible <- cells$n_individuals >= 3L
  recurrence <- table(cells$scientificName[cells$cell_eligible])
  cells$recurrent <- cells$cell_eligible &
    cells$scientificName %in% names(recurrence)[recurrence >= 3L]
  components <- phenology_v2_select_component(
    cells[cells$recurrent, c("scientificName", "year"), drop = FALSE]
  )
  cells$component <- 0L
  cells$selected <- FALSE
  if (nrow(components)) {
    m <- match(phenology_v2_key(cells$scientificName, cells$year),
               phenology_v2_key(components$scientificName, components$year))
    hit <- !is.na(m)
    cells$component[hit] <- components$component[m[hit]]
    cells$selected[hit] <- components$selected[m[hit]]
  }
  selected_keys <- phenology_v2_key(cells$scientificName[cells$selected],
                                    cells$year[cells$selected])
  contributor_keys <- phenology_v2_key(bounded$scientificName, bounded$year)
  contributors <- bounded[contributor_keys %in% selected_keys, , drop = FALSE]
  selected_cells <- cells[cells$selected, , drop = FALSE]
  references <- if (nrow(selected_cells)) {
    vapply(
      split(selected_cells$species_onset,
            factor(selected_cells$scientificName,
                   levels = sort(unique(selected_cells$scientificName), method = "radix"))),
      stats::median, numeric(1)
    )
  } else numeric()
  list(cells = cells, contributors = contributors, species_reference = references)
}

phenology_v2_compatibility_annual <- function(plant_years, panel) {
  site <- unique(plant_years$site)
  if (length(site) != 1L)
    phenology_v2_fail("invalid_site_partition", "compatibility annual builder requires one site")
  years <- PHENOLOGY_V2_DRIVER_YEARS
  out <- data.frame(
    site = rep(site, length(years)), year = years,
    greenup_doy_compat = rep(NA_real_, length(years)),
    greenup_doy_additive_compat = rep(NA_real_, length(years)),
    compat_n_onsets = rep(NA_integer_, length(years)),
    compat_n_left_censored = rep(NA_integer_, length(years)),
    compat_n_excluded_umbrella = rep(NA_integer_, length(years)),
    compat_n_individuals = rep(NA_integer_, length(years)),
    compat_n_species = rep(NA_integer_, length(years)),
    compat_reference_doy = rep(NA_real_, length(years)),
    compat_interval_median_days = rep(NA_real_, length(years)),
    compat_interval_p90_days = rep(NA_real_, length(years)),
    compat_interval_max_days = rep(NA_real_, length(years)),
    stringsAsFactors = FALSE
  )
  inside <- plant_years$calendar_state == "inside_driver_window"
  candidates <- plant_years[inside &
                              plant_years$compat_censor_state != "compat_no_finite_onset",
                            , drop = FALSE]
  contributors <- panel$contributors
  selected_cells <- panel$cells[panel$cells$selected, , drop = FALSE]
  reference <- panel$species_reference
  anchor <- if (length(reference)) stats::median(reference) else NA_real_

  for (i in seq_along(years)) {
    year <- years[i]
    year_candidates <- candidates[candidates$year == year, , drop = FALSE]
    if (!nrow(year_candidates)) next
    if (is.finite(anchor)) out$compat_reference_doy[i] <- anchor
    out$compat_n_onsets[i] <- nrow(year_candidates)
    out$compat_n_left_censored[i] <- sum(
      year_candidates$compat_censor_state == "compat_left_censored"
    )
    final <- contributors[contributors$year == year, , drop = FALSE]
    out$compat_n_individuals[i] <- nrow(final)
    out$compat_n_species[i] <- length(unique(final$scientificName))
    out$compat_n_excluded_umbrella[i] <- out$compat_n_onsets[i] -
      out$compat_n_left_censored[i] - out$compat_n_individuals[i]
    if (out$compat_n_excluded_umbrella[i] < 0L)
      phenology_v2_fail("compatibility_reconciliation", "compatibility exclusion umbrella is negative")
    widths <- final$compat_interval_days[is.finite(final$compat_interval_days)]
    if (length(widths)) {
      out$compat_interval_median_days[i] <- stats::median(widths)
      out$compat_interval_p90_days[i] <- unname(stats::quantile(widths, 0.9, type = 7))
      out$compat_interval_max_days[i] <- max(widths)
    }
    if (nrow(final) >= 6L && length(unique(final$scientificName)) >= 2L) {
      year_cells <- selected_cells[selected_cells$year == year, , drop = FALSE]
      deviations <- year_cells$species_onset - reference[year_cells$scientificName]
      out$greenup_doy_compat[i] <- anchor + stats::median(deviations)
    }
  }

  if (nrow(selected_cells)) {
    species_levels <- sort(unique(selected_cells$scientificName), method = "radix")
    year_levels <- sort(unique(selected_cells$year), method = "radix")
    fit_data <- selected_cells
    fit_data$scientificName <- factor(fit_data$scientificName, levels = species_levels)
    fit_data$year <- as.integer(fit_data$year)
    design <- stats::model.matrix(~ scientificName + factor(year), data = fit_data)
    expected_rank <- length(species_levels) + length(year_levels) - 1L
    if (qr(design)$rank != expected_rank || ncol(design) != expected_rank)
      phenology_v2_fail("compatibility_rank_failure", "compatibility additive design is rank deficient")
    warnings <- character()
    fit <- withCallingHandlers(
      stats::lm(
        species_onset ~ scientificName + factor(year), data = fit_data,
        na.action = stats::na.fail, singular.ok = FALSE, model = TRUE,
        x = TRUE, y = TRUE
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    if (length(warnings))
      phenology_v2_fail("compatibility_fit_warning", paste(warnings, collapse = " | "))
    grid <- expand.grid(
      scientificName = species_levels, year = year_levels,
      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
    )
    grid$scientificName <- factor(grid$scientificName, levels = species_levels)
    predicted <- stats::predict(fit, newdata = grid)
    if (length(predicted) != nrow(grid) || any(!is.finite(predicted)))
      phenology_v2_fail("compatibility_prediction_failure", "compatibility additive predictions are nonfinite")
    grid$prediction <- as.numeric(predicted)
    for (i in seq_along(years)) {
      year <- years[i]
      if (!is.finite(out$greenup_doy_compat[i])) next
      out$greenup_doy_additive_compat[i] <- stats::median(
        grid$prediction[grid$year == year]
      )
    }
    if (!identical(is.finite(out$greenup_doy_compat),
                   is.finite(out$greenup_doy_additive_compat)))
      phenology_v2_fail("compatibility_missingness_failure", "primary/additive compatibility keys differ")
  }
  finite_width <- is.finite(out$compat_interval_median_days)
  if (any(finite_width &
          !(out$compat_interval_median_days <= out$compat_interval_p90_days &
              out$compat_interval_p90_days <= out$compat_interval_max_days)))
    phenology_v2_fail("interval_summary_order", "compatibility interval summaries are unordered")
  out
}

phenology_v2_leaf_active <- function(source_rows, plant_years, roster_n) {
  d <- source_rows[
    source_rows$phenophaseName == "Leaves" & source_rows$status == "yes" &
      !is.na(source_rows$source_doy),
    , drop = FALSE
  ]
  template <- data.frame(
    site = character(), individualID = character(), scientificName = character(),
    year = integer(), leaf_active_days_7d = numeric(),
    stringsAsFactors = FALSE
  )
  if (nrow(d)) {
    d$week <- floor((d$source_doy - 1L) / 7L) + 1L
    key <- phenology_v2_key(d$site, d$individualID, d$source_scientificName, d$year)
    rows <- lapply(phenology_v2_groups(key), function(ix) {
      x <- d[ix, , drop = FALSE]
      data.frame(
        site = x$site[1L], individualID = x$individualID[1L],
        scientificName = x$source_scientificName[1L], year = x$year[1L],
        leaf_active_days_7d = 7 * length(unique(x$week)),
        stringsAsFactors = FALSE
      )
    })
    individual <- phenology_v2_bind(rows, template)
  } else individual <- template
  individual <- individual[
    phenology_v2_radix_order(
      individual$site, individual$year, individual$scientificName,
      individual$individualID
    ),
    , drop = FALSE
  ]
  rownames(individual) <- NULL
  plant_years$leaf_active_days_7d <- NA_real_
  if (nrow(individual)) {
    m <- match(
      phenology_v2_key(plant_years$site, plant_years$individualID, plant_years$year),
      phenology_v2_key(individual$site, individual$individualID, individual$year)
    )
    hit <- !is.na(m)
    plant_years$leaf_active_days_7d[hit] <- individual$leaf_active_days_7d[m[hit]]
  }
  # Coverage is roster-based: the narrow all-taxonomy-null unmatched exception
  # remains auditable opportunity, but it is not one of the verified tagged
  # plants in the denominator and therefore cannot enter the numerator.
  finite_onset_ids <- unique(plant_years$individualID[
    plant_years$compat_censor_state != "compat_no_finite_onset" &
      plant_years$taxonomy_state != "roster_unmatched_taxon_unknown"
  ])
  coverage <- length(finite_onset_ids) / roster_n
  if (!is.finite(coverage) || coverage < 0 || coverage > 1)
    phenology_v2_fail("invalid_greenup_coverage", "app-style green-up coverage is outside 0-1")
  thin_greenup <- coverage < 0.50
  support_template <- data.frame(
    site = character(), scientificName = character(), year = integer(),
    n_positive_individuals = integer(), thin_greenup = logical(),
    leaf_active_supported = logical(), stringsAsFactors = FALSE
  )
  support_input <- individual[
    phenology_v2_nonblank(individual$scientificName) &
      individual$year %in% PHENOLOGY_V2_DRIVER_YEARS,
    , drop = FALSE
  ]
  if (nrow(support_input)) {
    support_key <- phenology_v2_key(
      support_input$site, support_input$scientificName, support_input$year
    )
    support_rows <- lapply(phenology_v2_groups(support_key), function(ix) {
      d <- support_input[ix, , drop = FALSE]
      n_positive <- length(unique(d$individualID))
      data.frame(
        site = d$site[1L], scientificName = d$scientificName[1L],
        year = d$year[1L], n_positive_individuals = as.integer(n_positive),
        thin_greenup = thin_greenup,
        leaf_active_supported = thin_greenup && n_positive >= 3L,
        stringsAsFactors = FALSE
      )
    })
    leaf_support <- phenology_v2_bind(support_rows, support_template)
    leaf_support <- leaf_support[
      phenology_v2_radix_order(
        leaf_support$site, leaf_support$year, leaf_support$scientificName
      ),
      , drop = FALSE
    ]
    rownames(leaf_support) <- NULL
  } else leaf_support <- support_template
  list(
    individual_years = individual,
    support = leaf_support,
    plant_years = plant_years,
    coverage = coverage,
    thin_greenup = thin_greenup
  )
}

phenology_v2_annual_support <- function(plant_years, model_rows, source_rows, visits) {
  site <- unique(plant_years$site)
  if (length(site) != 1L)
    phenology_v2_fail("invalid_site_partition", "annual support requires one site")
  years <- PHENOLOGY_V2_DRIVER_YEARS
  out <- data.frame(
    site = rep(site, length(years)), year = years,
    v2_n_monitored = integer(length(years)),
    v2_n_target_scored = integer(length(years)),
    v2_n_timing_candidates = integer(length(years)),
    v2_n_bounded = integer(length(years)),
    v2_n_left_censored = integer(length(years)),
    v2_n_right_censored = integer(length(years)),
    v2_n_uncertain_only = integer(length(years)),
    v2_n_status_conflict_only = integer(length(years)),
    v2_n_ambiguous_competing_phase = integer(length(years)),
    v2_n_structural_unscored = integer(length(years)),
    v2_n_taxon_excluded = integer(length(years)),
    v2_n_species_year_excluded = integer(length(years)),
    v2_n_recurrence_excluded = integer(length(years)),
    v2_n_connected_panel_excluded = integer(length(years)),
    v2_n_model_individuals = integer(length(years)),
    v2_n_model_species = integer(length(years)),
    v2_annual_response_state = rep("no_retained_panel", length(years)),
    v2_n_conflicting_visits = integer(length(years)),
    v2_n_source_doy_missing = integer(length(years)),
    v2_n_source_doy_mismatch = integer(length(years)),
    v2_n_roster_unmatched = integer(length(years)),
    v2_n_plot_history_mismatch = integer(length(years)),
    v2_interval_median_days = rep(NA_real_, length(years)),
    v2_interval_p90_days = rep(NA_real_, length(years)),
    v2_interval_max_days = rep(NA_real_, length(years)),
    left_censored_share = rep(NA_real_, length(years)),
    exclusion_share = rep(NA_real_, length(years)),
    censor_burden_warning = logical(length(years)),
    exclusion_burden_warning = logical(length(years)),
    typical_cadence_warning = logical(length(years)),
    extreme_cadence_warning = logical(length(years)),
    annual_response_supported = logical(length(years)),
    stringsAsFactors = FALSE
  )
  for (i in seq_along(years)) {
    year <- years[i]
    d <- plant_years[plant_years$year == year &
                       plant_years$calendar_state == "inside_driver_window", , drop = FALSE]
    out$v2_n_monitored[i] <- nrow(d)
    out$v2_n_target_scored[i] <- sum(d$v2_observation_state != "structural_unscored")
    out$v2_n_bounded[i] <- sum(d$v2_observation_state == "bounded_onset")
    out$v2_n_left_censored[i] <- sum(d$v2_observation_state == "left_censored_onset")
    out$v2_n_right_censored[i] <- sum(d$v2_observation_state == "right_censored_no_yes")
    out$v2_n_uncertain_only[i] <- sum(d$v2_observation_state == "uncertain_only")
    out$v2_n_status_conflict_only[i] <- sum(d$v2_observation_state == "status_conflict_only")
    out$v2_n_ambiguous_competing_phase[i] <- sum(d$v2_observation_state == "ambiguous_competing_phase")
    out$v2_n_structural_unscored[i] <- sum(d$v2_observation_state == "structural_unscored")
    candidate <- d$v2_observation_state %in% c("bounded_onset", "left_censored_onset")
    out$v2_n_timing_candidates[i] <- sum(candidate)
    out$v2_n_taxon_excluded[i] <- sum(candidate & d$taxonomy_state != "eligible_species")
    out$v2_n_species_year_excluded[i] <- sum(d$v2_eligibility_state == "species_year_excluded")
    out$v2_n_recurrence_excluded[i] <- sum(d$v2_eligibility_state == "recurrence_excluded")
    out$v2_n_connected_panel_excluded[i] <- sum(d$v2_eligibility_state == "connected_panel_excluded")
    md <- model_rows[model_rows$year == year, , drop = FALSE]
    out$v2_n_model_individuals[i] <- nrow(md)
    out$v2_n_model_species[i] <- length(unique(md$scientificName))
    bounded_widths <- d$interval_days[
      d$v2_eligibility_state == "model_row" & is.finite(d$interval_days)
    ]
    if (length(bounded_widths)) {
      out$v2_interval_median_days[i] <- stats::median(bounded_widths)
      out$v2_interval_p90_days[i] <- unname(stats::quantile(bounded_widths, 0.9, type = 7))
      out$v2_interval_max_days[i] <- max(bounded_widths)
      out$typical_cadence_warning[i] <- out$v2_interval_median_days[i] > 14
      out$extreme_cadence_warning[i] <- out$v2_interval_max_days[i] > 30
    }
    if (nrow(md)) {
      if (out$v2_n_model_species[i] < 2L) {
        out$v2_annual_response_state[i] <- "insufficient_observed_species"
      } else if (out$v2_n_model_individuals[i] < 6L) {
        out$v2_annual_response_state[i] <- "insufficient_timing_individuals"
      } else {
        out$v2_annual_response_state[i] <- "supported"
        out$annual_response_supported[i] <- TRUE
      }
    }
    vv <- visits[
      visits$year == year &
        visits$phenophaseName %in% PHENOLOGY_V2_TARGET_PHASES,
      , drop = FALSE
    ]
    ss <- source_rows[source_rows$year == year, , drop = FALSE]
    out$v2_n_conflicting_visits[i] <- sum(vv$visit_status == "visit_status_conflict")
    out$v2_n_source_doy_missing[i] <- sum(ss$source_doy_missing)
    out$v2_n_source_doy_mismatch[i] <- sum(ss$source_doy_mismatch)
    out$v2_n_roster_unmatched[i] <- sum(d$taxonomy_state == "roster_unmatched_taxon_unknown")
    out$v2_n_plot_history_mismatch[i] <- sum(ss$plot_history_mismatch)
    if (out$v2_n_timing_candidates[i] > 0L) {
      out$left_censored_share[i] <- out$v2_n_left_censored[i] / out$v2_n_timing_candidates[i]
      excluded <- out$v2_n_taxon_excluded[i] + out$v2_n_species_year_excluded[i] +
        out$v2_n_recurrence_excluded[i] + out$v2_n_connected_panel_excluded[i]
      out$exclusion_share[i] <- excluded / out$v2_n_timing_candidates[i]
      out$censor_burden_warning[i] <- out$left_censored_share[i] >= 0.50
      out$exclusion_burden_warning[i] <- out$exclusion_share[i] >= 0.50
      if (out$v2_n_timing_candidates[i] != out$v2_n_taxon_excluded[i] +
          out$v2_n_species_year_excluded[i] + out$v2_n_recurrence_excluded[i] +
          out$v2_n_connected_panel_excluded[i] + out$v2_n_model_individuals[i])
        phenology_v2_fail("v2_candidate_reconciliation", "timing-candidate dispositions do not reconcile")
    }
    if (out$v2_n_timing_candidates[i] != out$v2_n_bounded[i] + out$v2_n_left_censored[i])
      phenology_v2_fail("v2_candidate_reconciliation", "bounded plus left-censored counts do not reconcile")
  }
  if (any(!out$v2_annual_response_state %in% PHENOLOGY_V2_ANNUAL_RESPONSE_STATES))
    phenology_v2_fail("invalid_state_vocabulary", "annual support emitted an undeclared state")
  finite_width <- is.finite(out$v2_interval_median_days)
  if (any(finite_width &
          !(out$v2_interval_median_days <= out$v2_interval_p90_days &
              out$v2_interval_p90_days <= out$v2_interval_max_days)))
    phenology_v2_fail("interval_summary_order", "v2 interval summaries are unordered")
  response_fit_eligible <- nrow(model_rows) > 0L & sum(out$annual_response_supported) >= 6L
  list(annual = out, response_fit_eligible = response_fit_eligible)
}

phenology_v2_adapt_bundle <- function(bundle, site,
                                      mode = PHENOLOGY_V2_SEAL1_MODE,
                                      effect_locked = TRUE) {
  phenology_v2_assert_seal1(mode, effect_locked)
  site <- phenology_v2_scalar_nonblank(site, "site")
  phenology_v2_validate_bundle(bundle, site)

  source_rows <- phenology_v2_normalize_source(bundle, site)
  visits <- phenology_v2_normalize_visits(source_rows)
  phases <- phenology_v2_phase_records(visits)
  compatibility_phases <- phenology_v2_compatibility_phases(source_rows)
  compatibility_individual_years <-
    phenology_v2_compatibility_individual_years(compatibility_phases)
  plant_years <- phenology_v2_individual_years(
    source_rows, phases, compatibility_individual_years
  )
  v2_panel <- phenology_v2_assign_v2_panel(plant_years)
  plant_years <- v2_panel$plant_years
  compatibility_panel <- phenology_v2_compatibility_panel(plant_years)
  compatibility_annual <- phenology_v2_compatibility_annual(
    plant_years, compatibility_panel
  )
  leaf <- phenology_v2_leaf_active(source_rows, plant_years, nrow(bundle$inds))
  plant_years <- leaf$plant_years
  support <- phenology_v2_annual_support(
    plant_years, v2_panel$model_rows, source_rows, visits
  )

  # Emit the adapter/model boundary in the exact response-module schema. The
  # observation state remains on the plant-year ledger; the likelihood receives
  # only keys, interval bounds, and the pre-fit annual support decision.
  model_rows <- v2_panel$model_rows
  if (nrow(model_rows)) {
    annual_index <- match(model_rows$year, support$annual$year)
    if (anyNA(annual_index))
      phenology_v2_fail(
        "model_rows_calendar",
        "a retained model row lacks a registered annual-support key"
      )
    model_rows$annual_response_supported <-
      support$annual$annual_response_supported[annual_index]
  } else {
    model_rows$annual_response_supported <- logical()
  }
  model_rows <- model_rows[c(
    "site", "individualID", "scientificName", "year",
    "lower_doy", "upper_doy", "annual_response_supported"
  )]

  target_visits <- visits$phenophaseName %in% PHENOLOGY_V2_TARGET_PHASES
  audit_counts <- data.frame(
    site = site,
    source_rows = nrow(source_rows), visits = nrow(visits),
    duplicate_visit_grains = sum(target_visits & visits$source_row_count > 1L),
    mixed_status_visit_grains = sum(target_visits & visits$visit_status == "visit_status_conflict"),
    visits_with_multiple_source_doys = sum(target_visits & visits$source_doy_distinct > 1L),
    source_doy_missing_rows = sum(source_rows$source_doy_missing),
    source_doy_mismatch_rows = sum(source_rows$source_doy_mismatch),
    roster_unmatched_rows = sum(!source_rows$roster_matched),
    roster_unmatched_individuals = length(unique(source_rows$individualID[!source_rows$roster_matched])),
    plot_history_mismatch_rows = sum(source_rows$plot_history_mismatch),
    monitored_plant_years = nrow(plant_years),
    target_scored_plant_years = sum(plant_years$v2_observation_state != "structural_unscored"),
    stringsAsFactors = FALSE
  )
  site_summary <- data.frame(
    site = site,
    response_fit_eligible = support$response_fit_eligible,
    annual_response_supported_years = sum(support$annual$annual_response_supported),
    compatibility_finite_years = sum(is.finite(compatibility_annual$greenup_doy_compat)),
    compatibility_site_screen = sum(is.finite(compatibility_annual$greenup_doy_compat)) >= 6L,
    app_greenup_coverage = leaf$coverage,
    thin_greenup = leaf$thin_greenup,
    stringsAsFactors = FALSE
  )

  result <- list(
    source_rows = source_rows,
    visits = visits,
    phases = phases,
    plant_years = plant_years,
    compatibility_individual_years = compatibility_individual_years,
    compatibility_annual = compatibility_annual,
    model_rows = model_rows,
    annual_support = support$annual,
    leaf_active = leaf$individual_years,
    leaf_active_support = leaf$support,
    audit_counts = audit_counts,
    site_summary = site_summary
  )
  expected_names <- c(
    "source_rows", "visits", "phases", "plant_years",
    "compatibility_individual_years", "compatibility_annual", "model_rows",
    "annual_support", "leaf_active", "leaf_active_support", "audit_counts",
    "site_summary"
  )
  if (!identical(names(result), expected_names))
    phenology_v2_fail("adapter_output_schema", "adapter result names drifted")
  result
}

phenology_v2_join_driver_calendar <- function(
    adapter_annual, driver_calendar, required_audit_keys = NULL,
    mode = PHENOLOGY_V2_SEAL1_MODE, effect_locked = TRUE) {
  phenology_v2_assert_seal1(mode, effect_locked)
  expected_rows <- 510L
  expected_sites <- 46L
  phenology_v2_validate_frame(adapter_annual, "adapter annual table", nonempty = FALSE)
  phenology_v2_validate_frame(driver_calendar, "Driver calendar", nonempty = TRUE)
  phenology_v2_require_columns(adapter_annual, c("site", "year"), "adapter annual table")
  phenology_v2_require_columns(driver_calendar, c("site", "year"), "Driver calendar")
  if (!identical(names(driver_calendar), c("site", "year")))
    phenology_v2_fail(
      "effect_lock",
      "the sealed Driver calendar must be an exact site/year key skeleton"
    )
  adapter_payload <- setdiff(names(adapter_annual), c("site", "year"))
  if (any(
    phenology_v2_forbidden_climate_name(adapter_payload) |
      phenology_v2_forbidden_effect_name(adapter_payload)
  ))
    phenology_v2_fail(
      "effect_lock",
      "the adapter annual table contains a forbidden climate/effect payload"
    )
  if (nrow(driver_calendar) != expected_rows ||
      length(unique(driver_calendar$site)) != expected_sites)
    phenology_v2_fail(
      "driver_calendar_topology",
      sprintf("Driver calendar must contain exactly %d rows across %d sites",
              expected_rows, expected_sites)
    )
  normalize_key <- function(x, label) {
    if (!is.character(x$site) || any(!phenology_v2_nonblank(x$site)))
      phenology_v2_fail("driver_calendar_key", sprintf("%s has invalid site keys", label))
    year <- phenology_v2_integer(x$year, sprintf("%s$year", label))
    if (any(!year %in% PHENOLOGY_V2_DRIVER_YEARS))
      phenology_v2_fail("driver_calendar_key", sprintf("%s has out-of-window years", label))
    key <- phenology_v2_key(x$site, year)
    if (anyDuplicated(key))
      phenology_v2_fail("duplicate_site_year", sprintf("%s has duplicate site x year keys", label))
    list(year = year, key = key)
  }
  driver_key <- normalize_key(driver_calendar, "Driver calendar")
  adapter_key <- normalize_key(adapter_annual, "adapter annual table")
  driver_calendar$year <- driver_key$year
  adapter_annual$year <- adapter_key$year
  if (length(setdiff(unique(adapter_annual$site), unique(driver_calendar$site))))
    phenology_v2_fail("driver_calendar_topology", "adapter introduced a non-Driver site")
  if (!is.null(required_audit_keys)) {
    phenology_v2_validate_frame(required_audit_keys, "required audit keys", nonempty = FALSE)
    phenology_v2_require_columns(required_audit_keys, c("site", "year"), "required audit keys")
    if (!identical(names(required_audit_keys), c("site", "year")))
      phenology_v2_fail(
        "effect_lock", "required audit keys must be an exact site/year skeleton"
      )
    required <- normalize_key(required_audit_keys, "required audit keys")$key
    if (length(setdiff(required, driver_key$key)) ||
        length(setdiff(required, adapter_key$key)))
      phenology_v2_fail("audit_key_loss", "a required audit key is absent from the calendar or adapter")
  }
  match_index <- match(driver_key$key, adapter_key$key)
  payload <- adapter_payload
  if (length(intersect(payload, names(driver_calendar))))
    phenology_v2_fail("calendar_column_collision", "adapter payload collides with Driver calendar columns")
  out <- driver_calendar
  for (column in payload) out[[column]] <- adapter_annual[[column]][match_index]
  out <- out[phenology_v2_radix_order(out$site, out$year), , drop = FALSE]
  rownames(out) <- NULL
  if (nrow(out) != expected_rows ||
      length(unique(out$site)) != expected_sites ||
      anyDuplicated(phenology_v2_key(out$site, out$year)))
    phenology_v2_fail("driver_calendar_topology", "joined Driver calendar topology drifted")
  out
}
