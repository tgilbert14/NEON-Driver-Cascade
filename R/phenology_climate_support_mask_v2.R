# One-way, values-free climate support for the sealed Phenology v2 family.
#
# This module is deliberately self-contained. It accepts only an exact logical
# response-presence mask and monthly temperature rows, and it never returns an
# annual temperature or any quantity from which an effect can be calculated.
# Archived climate-file identity and Git authority are checked by the later
# Seal-3B runner before it passes an explicitly verified site to this function.

PHENOLOGY_V2_CLIMATE_MASK_MODE <- "seal1-synthetic-climate-mask"
PHENOLOGY_V2_CLIMATE_MASK_YEARS <- 2013:2025
PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS <- c("temp", "temp_spring")
PHENOLOGY_V2_CLIMATE_MASK_RESPONSE_SCHEMA <- c(
  "site", "year", "response_fit_eligible", "response_present")

.phenology_v2_mask_abort <- function(code, message) {
  stop(structure(
    list(message = as.character(message), call = NULL, code = as.character(code)),
    class = c("phenology_v2_error", "error", "condition")))
}

.phenology_v2_mask_assert_frame <- function(x, label, code) {
  if (!is.data.frame(x))
    .phenology_v2_mask_abort(code, sprintf("%s must be a data frame", label))
  n <- tryCatch(nrow(x), error = function(e) NA_integer_)
  if (length(n) != 1L || is.na(n) || is.null(names(x)) ||
      anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x)) ||
      any(vapply(x, length, integer(1)) != n))
    .phenology_v2_mask_abort(
      code, sprintf("%s must be rectangular with unique, nonblank columns", label))
  invisible(n)
}

.phenology_v2_mask_assert_site <- function(site) {
  if (!is.character(site) || length(site) != 1L || is.na(site) ||
      !nzchar(site) || !identical(site, trimws(site)) ||
      !grepl("^[A-Za-z0-9._-]+$", site))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_site",
      "site must be one nonblank, canonical ASCII identifier")
  site
}

# A mask run is intentionally unsuitable for a general analysis session. The
# exact Seal-1 mode is a capability token, and effect-producing symbols in a
# caller frame or the module environment make the process fail closed. The
# dedicated test/receipt runner supplies a fresh R process for this role.
.phenology_v2_mask_assert_process_lock <- function(mode) {
  if (!is.character(mode) || length(mode) != 1L || is.na(mode) ||
      !identical(mode, PHENOLOGY_V2_CLIMATE_MASK_MODE))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_mode",
      sprintf("mode must be exactly '%s'", PHENOLOGY_V2_CLIMATE_MASK_MODE))

  loaded_effect_namespaces <- intersect(c("survival", "metafor"), loadedNamespaces())
  if (length(loaded_effect_namespaces))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_effect_lock",
      sprintf("fresh climate-mask process loaded forbidden namespace: %s",
              paste(loaded_effect_namespaces, collapse = ", ")))

  exact <- c(
    "cor", "cor.test", "cov", "cov2cor", "lm", "glm", "binom.test",
    "p.adjust", "rma", "rma.uni", "link_stat", "site_links",
    "pooled_links", "cascade_meta")
  function_pattern <- paste0(
    "(^|_)(effect|effects|correlation|association|vote|votes|pooled|",
    "metafor|meta_analysis|link_stat)(_|$)")
  value_pattern <- paste0(
    "(^|_)(response_value|response_values|annual_response|",
    "annual_responses|fitted_value|fitted_values|prediction|predictions)(_|$)")
  stats_namespace <- asNamespace("stats")
  forbidden_function_identities <- lapply(
    c("cor", "cor.test", "cov", "cov2cor", "lm", "glm",
      "binom.test", "p.adjust"),
    get, envir = stats_namespace, inherits = FALSE
  )

  frames <- c(sys.frames(), list(environment(.phenology_v2_mask_assert_process_lock),
                                 .GlobalEnv))
  seen <- list()
  missing_object <- new.env(parent = emptyenv())
  for (frame in frames) {
    if (!is.environment(frame) || identical(frame, baseenv()) ||
        isNamespace(frame)) next
    duplicate_frame <- any(vapply(seen, identical, logical(1), y = frame))
    if (duplicate_frame) next
    seen[[length(seen) + 1L]] <- frame
    object_names <- setdiff(ls(envir = frame, all.names = TRUE), "...")
    for (name in object_names) {
      forbidden_value <- grepl(value_pattern, name, ignore.case = TRUE, perl = TRUE)
      forbidden_name <- name %in% exact ||
        grepl(function_pattern, name, ignore.case = TRUE, perl = TRUE)
      object <- tryCatch(
        get(name, envir = frame, inherits = FALSE),
        error = function(e) missing_object
      )
      if (identical(object, missing_object)) next
      forbidden_identity <- is.function(object) && any(vapply(
        forbidden_function_identities, identical, logical(1L), y = object
      ))
      if (forbidden_value || forbidden_identity ||
          (forbidden_name && is.function(object)))
        .phenology_v2_mask_abort(
          "phenology_v2_mask_effect_lock",
          sprintf("fresh climate-mask process contains forbidden symbol '%s'", name))
    }
  }
  invisible(TRUE)
}

.phenology_v2_mask_validate_response <- function(response_mask) {
  .phenology_v2_mask_assert_frame(
    response_mask, "response_mask", "phenology_v2_mask_response_schema")
  if (!identical(names(response_mask),
                 PHENOLOGY_V2_CLIMATE_MASK_RESPONSE_SCHEMA))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_schema",
      paste0(
        "response_mask columns must be exactly, in order: ",
        paste(PHENOLOGY_V2_CLIMATE_MASK_RESPONSE_SCHEMA, collapse = ", ")))
  if (!nrow(response_mask))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_key", "response_mask must not be empty")
  if (!is.character(response_mask$site) || !is.null(dim(response_mask$site)) ||
      anyNA(response_mask$site) ||
      any(!nzchar(response_mask$site)) ||
      any(response_mask$site != trimws(response_mask$site)) ||
      any(!grepl("^[A-Za-z0-9._-]+$", response_mask$site)))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_type",
      "response_mask$site must contain canonical character identifiers")
  if (!is.integer(response_mask$year) || !is.null(dim(response_mask$year)) ||
      anyNA(response_mask$year) ||
      any(!response_mask$year %in% PHENOLOGY_V2_CLIMATE_MASK_YEARS))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_type",
      "response_mask$year must be integer and inside 2013-2025")
  logical_fields <- c("response_fit_eligible", "response_present")
  plain_logical <- vapply(
    response_mask[logical_fields],
    function(x) is.logical(x) && is.null(dim(x)), logical(1))
  if (any(!plain_logical) ||
      anyNA(response_mask$response_fit_eligible) ||
      anyNA(response_mask$response_present))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_type",
      "response mask state columns must be nonmissing logical vectors")
  key <- paste(response_mask$site, response_mask$year, sep = "\r")
  if (anyDuplicated(key))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_key",
      "response_mask contains a duplicate site x year key")
  fit_by_site <- split(response_mask$response_fit_eligible, response_mask$site)
  if (any(vapply(fit_by_site, function(x) length(unique(x)) != 1L, logical(1))))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_state",
      "response_fit_eligible must be constant within site")
  if (any(response_mask$response_present &
          !response_mask$response_fit_eligible))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_state",
      "response_present cannot be true for a response-ineligible site")
  present_by_site <- split(response_mask$response_present, response_mask$site)
  eligible_by_site <- vapply(fit_by_site, function(x) unique(x)[[1L]], logical(1))
  present_count_by_site <- vapply(present_by_site, sum, integer(1))
  if (any(eligible_by_site & present_count_by_site < 6L))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_state",
      "a response-fit-eligible site must expose at least six response years")
  response_mask
}

.phenology_v2_mask_parse_date <- function(x) {
  if (inherits(x, "Date")) {
    token <- as.character(x)
  } else if (is.character(x) && is.null(dim(x))) {
    token <- x
  } else {
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_type",
      "env$date must be Date or exact YYYY-MM-DD character data")
  }
  shape_ok <- !is.na(token) & grepl(
    "^[0-9]{4}-(0[1-9]|1[0-2])-([0][1-9]|[12][0-9]|3[01])$", token,
    perl = TRUE)
  parsed <- suppressWarnings(as.Date(token, format = "%Y-%m-%d"))
  round_trip <- !is.na(parsed) & format(parsed, "%Y-%m-%d") == token
  if (any(!shape_ok | !round_trip))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_date",
      "env$date contains a missing, invalid, or noncanonical date")
  data.frame(
    year = as.integer(substr(token, 1L, 4L)),
    month = as.integer(substr(token, 6L, 7L)),
    stringsAsFactors = FALSE)
}

.phenology_v2_mask_parse_ym <- function(x) {
  if (!is.character(x) || !is.null(dim(x)))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_type",
      "env$ym must contain exact YYYY-MM character data")
  valid <- !is.na(x) & grepl("^[0-9]{4}-(0[1-9]|1[0-2])$", x, perl = TRUE)
  if (any(!valid))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_date",
      "env$ym contains a missing, invalid, or noncanonical year-month")
  data.frame(
    year = as.integer(substr(x, 1L, 4L)),
    month = as.integer(substr(x, 6L, 7L)),
    stringsAsFactors = FALSE)
}

.phenology_v2_mask_validate_climate <- function(env, site) {
  .phenology_v2_mask_assert_frame(
    env, "env", "phenology_v2_mask_climate_container")
  if (!"temp_c" %in% names(env))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_schema", "env lacks required field 'temp_c'")
  date_fields <- intersect(c("date", "ym"), names(env))
  if (!length(date_fields))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_schema",
      "env must contain date or ym")
  if (!is.numeric(env$temp_c) || is.logical(env$temp_c) ||
      !is.null(dim(env$temp_c)))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_type",
      "env$temp_c must be one numeric scalar per row")

  permitted <- c("site", "temp_c", "date", "ym", "precip_mm",
                 "fruiting_pct", "fruiting_pct_n")
  extra <- setdiff(names(env), permitted)
  unused <- setdiff(names(env), c("site", "temp_c", "date", "ym"))
  nested_unused <- vapply(
    env[unused], function(x) is.list(x) || is.environment(x) ||
      is.function(x) || !is.null(dim(x)), logical(1))
  # The archived env schema is closed. Rejecting every unknown field is the only
  # fail-closed way to prevent a numeric response from bypassing the one-way
  # process boundary under an innocuous or camelCase name.
  bad_fields <- unique(c(extra, unused[nested_unused]))
  if (length(bad_fields))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_response_leak",
      sprintf(
        "env contains a forbidden response/effect-like or nested field: %s",
        paste(bad_fields, collapse = ", ")))

  if ("site" %in% names(env)) {
    if (!is.character(env$site) || anyNA(env$site) ||
        any(env$site != site))
      .phenology_v2_mask_abort(
        "phenology_v2_mask_climate_site",
        "env$site disagrees with the explicitly verified file site")
  }

  by_date <- if ("date" %in% date_fields)
    .phenology_v2_mask_parse_date(env$date) else NULL
  by_ym <- if ("ym" %in% date_fields)
    .phenology_v2_mask_parse_ym(env$ym) else NULL
  if (!is.null(by_date) && !is.null(by_ym) && !identical(by_date, by_ym))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_date_authority",
      "env$date and env$ym do not identify identical year-month keys")
  keys <- if (!is.null(by_date)) by_date else by_ym
  keep <- keys$year %in% PHENOLOGY_V2_CLIMATE_MASK_YEARS
  keys <- keys[keep, , drop = FALSE]
  temp_c <- as.numeric(env$temp_c[keep])
  month_key <- paste(keys$year, keys$month, sep = "\r")
  if (anyDuplicated(month_key))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_climate_duplicate_month",
      "env contains a duplicate site x year x month row inside 2013-2025")
  climate <- data.frame(
    year = as.integer(keys$year), month = as.integer(keys$month),
    temp_c = temp_c, stringsAsFactors = FALSE)
  climate <- climate[
    order(climate$year, climate$month, method = "radix"), , drop = FALSE
  ]
  rownames(climate) <- NULL
  climate
}

.phenology_v2_mask_annual_qc <- function(climate) {
  years <- sort(unique(climate$year), method = "radix")
  if (!length(years))
    return(data.frame(
      year = integer(), contrast = character(), climate_complete = logical(),
      climate_range_valid = logical(), climate_mad_qc_pass = logical(),
      climate_available = logical(), stringsAsFactors = FALSE))

  rows <- vector("list", length(years) *
                   length(PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS))
  at <- 0L
  for (contrast in PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS) {
    required_months <- if (identical(contrast, "temp")) 1:12 else 3:5
    required_n <- length(required_months)
    for (year in years) {
      at <- at + 1L
      take <- climate$year == year & climate$month %in% required_months
      values <- climate$temp_c[take]
      valid <- is.finite(values) & values > -40 & values < 50
      complete <- length(values) == required_n
      range_valid <- complete && sum(valid) == required_n
      rows[[at]] <- data.frame(
        year = as.integer(year), contrast = contrast,
        climate_complete = complete,
        climate_range_valid = range_valid,
        climate_mad_qc_pass = FALSE,
        climate_available = FALSE,
        .annual_mean = if (range_valid) mean(values) else NA_real_,
        stringsAsFactors = FALSE)
    }
  }
  annual <- do.call(rbind, rows)
  rownames(annual) <- NULL

  for (contrast in PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS) {
    in_contrast <- annual$contrast == contrast
    finite <- in_contrast & is.finite(annual$.annual_mean)
    pass <- finite
    values <- annual$.annual_mean[finite]
    if (length(values) >= 4L) {
      centre <- stats::median(values)
      threshold <- max(6, 3 * stats::mad(values))
      pass[finite] <- abs(values - centre) <= threshold
    }
    annual$climate_mad_qc_pass[in_contrast] <- pass[in_contrast]
    annual$climate_available[in_contrast] <- pass[in_contrast]
  }
  annual$.annual_mean <- NULL
  annual
}

.phenology_v2_mask_digest_material <- function(support, counts) {
  bool <- function(x) ifelse(x, "1", "0")
  support_lines <- paste(
    support$site, support$year, support$contrast,
    bool(support$response_fit_eligible), bool(support$response_present),
    bool(support$climate_complete), bool(support$climate_range_valid),
    bool(support$climate_mad_qc_pass), bool(support$climate_available),
    bool(support$overlap), sep = "\t")
  count_lines <- paste(
    counts$site, counts$contrast, bool(counts$response_fit_eligible),
    counts$n_response_present, counts$n_climate_complete,
    counts$n_climate_range_valid, counts$n_climate_mad_qc_pass,
    counts$n_climate_available, counts$n_overlap, sep = "\t")
  text <- paste(c(
    "phenology-v2-climate-support-mask-v1",
    paste(c("support", names(support)), collapse = "\t"),
    support_lines,
    paste(c("counts", names(counts)), collapse = "\t"),
    count_lines), collapse = "\n")
  charToRaw(enc2utf8(paste0(text, "\n")))
}

# Build one verified site's values-free support mask. `env` may retain unrelated
# archived climate columns, but they are ignored; response/effect-like and nested
# extras are rejected. The returned object contains only keys, booleans, counts,
# and canonical bytes suitable for an external SHA-256 implementation.
phenology_v2_build_climate_support_mask <- function(
    env, response_mask, site,
    mode = "seal1-synthetic-climate-mask") {
  .phenology_v2_mask_assert_process_lock(mode)
  site <- .phenology_v2_mask_assert_site(site)
  response_mask <- .phenology_v2_mask_validate_response(response_mask)
  response_site <- response_mask[response_mask$site == site, , drop = FALSE]
  if (!nrow(response_site))
    .phenology_v2_mask_abort(
      "phenology_v2_mask_response_key",
      "response_mask has no site x year keys for the requested site")
  climate <- .phenology_v2_mask_validate_climate(env, site)
  annual <- .phenology_v2_mask_annual_qc(climate)

  support <- do.call(rbind, lapply(
    PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS,
    function(contrast) data.frame(
      site = response_site$site,
      year = response_site$year,
      contrast = rep(contrast, nrow(response_site)),
      response_fit_eligible = response_site$response_fit_eligible,
      response_present = response_site$response_present,
      stringsAsFactors = FALSE)))
  support <- merge(
    support, annual,
    by = c("year", "contrast"), all.x = TRUE, sort = FALSE)
  support$site <- as.character(support$site)
  qc_fields <- c("climate_complete", "climate_range_valid",
                 "climate_mad_qc_pass", "climate_available")
  for (field in qc_fields) {
    support[[field]][is.na(support[[field]])] <- FALSE
    support[[field]] <- as.logical(support[[field]])
  }
  support$overlap <- support$response_present & support$climate_available
  contrast_order <- match(support$contrast,
                          PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS)
  support <- support[order(support$site, support$year, contrast_order,
                           method = "radix"), c(
    "site", "year", "contrast", "response_fit_eligible", "response_present",
    "climate_complete", "climate_range_valid", "climate_mad_qc_pass",
    "climate_available", "overlap"), drop = FALSE]
  rownames(support) <- NULL

  counts <- do.call(rbind, lapply(
    PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS, function(contrast) {
      x <- support[support$contrast == contrast, , drop = FALSE]
      data.frame(
        site = site, contrast = contrast,
        response_fit_eligible = unique(x$response_fit_eligible),
        n_response_present = as.integer(sum(x$response_present)),
        n_climate_complete = as.integer(sum(x$climate_complete)),
        n_climate_range_valid = as.integer(sum(x$climate_range_valid)),
        n_climate_mad_qc_pass = as.integer(sum(x$climate_mad_qc_pass)),
        n_climate_available = as.integer(sum(x$climate_available)),
        n_overlap = as.integer(sum(x$overlap)),
        stringsAsFactors = FALSE)
    }))
  counts <- counts[order(match(counts$contrast,
                               PHENOLOGY_V2_CLIMATE_MASK_CONTRASTS),
                         method = "radix"), , drop = FALSE]
  rownames(counts) <- NULL

  result <- list(
    support = support,
    counts = counts,
    digest_material = .phenology_v2_mask_digest_material(support, counts))
  class(result) <- c("phenology_v2_climate_support_mask", "list")
  result
}
