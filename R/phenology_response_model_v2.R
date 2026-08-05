# Pure, response-only Phenology v2 interval model.
#
# Seal 1 permits only synthetic inputs.  This module therefore defines functions
# only: it performs no file I/O, cannot discover a sibling checkout, and contains
# no association, vote, pooling, or effect path.  The public input is deliberately
# narrow so a response fit cannot acquire an exposure column by accident.

.phenology_v2_response_abort <- function(code, message) {
  stop(structure(
    list(message = as.character(message), call = NULL, code = as.character(code)),
    class = c(paste0("phenology_v2_", code), "phenology_v2_error",
              "error", "condition")))
}

.phenology_v2_response_schema <- c(
  "site", "individualID", "scientificName", "year",
  "lower_doy", "upper_doy", "annual_response_supported")

.phenology_v2_assert_effect_lock <- function(effect_locked) {
  if (!identical(effect_locked, TRUE))
    .phenology_v2_response_abort(
      "effect_lock", "Phenology v2 response code is sealed in effect-locked mode")
  if ("metafor" %in% loadedNamespaces())
    .phenology_v2_response_abort(
      "effect_namespace_loaded",
      "metafor must not be loaded in the response-only process")
  invisible(TRUE)
}

.phenology_v2_is_plain_frame <- function(x) {
  is.data.frame(x) &&
    !length(setdiff(names(attributes(x)), c("names", "row.names", "class")))
}

.phenology_v2_validate_model_rows <- function(model_rows, allow_empty = TRUE) {
  if (!.phenology_v2_is_plain_frame(model_rows) ||
      !identical(names(model_rows), .phenology_v2_response_schema)) {
    .phenology_v2_response_abort(
      "model_rows_schema",
      sprintf("model rows must be a plain data frame with exact columns: %s",
              paste(.phenology_v2_response_schema, collapse = ", ")))
  }
  if (any(vapply(model_rows, function(x) !is.null(dim(x)), logical(1L))))
    .phenology_v2_response_abort(
      "model_rows_schema", "model-row columns must be one-dimensional vectors")

  if (!nrow(model_rows)) {
    if (!isTRUE(allow_empty))
      .phenology_v2_response_abort("response_fit_ineligible",
                                   "no retained response-model rows")
    return(invisible(model_rows))
  }

  is_character <- vapply(model_rows[c("site", "individualID", "scientificName")],
                         is.character, logical(1L))
  if (!all(is_character) ||
      anyNA(model_rows$site) || anyNA(model_rows$individualID) ||
      anyNA(model_rows$scientificName) ||
      any(!nzchar(trimws(model_rows$site))) ||
      any(!nzchar(trimws(model_rows$individualID))) ||
      any(!nzchar(trimws(model_rows$scientificName)))) {
    .phenology_v2_response_abort(
      "model_rows_key", "site, individualID, and scientificName must be nonblank character keys")
  }

  if (length(unique(model_rows$site)) != 1L)
    .phenology_v2_response_abort("model_rows_key",
                                 "one response fit may contain exactly one site")

  if (!is.numeric(model_rows$year) || anyNA(model_rows$year) ||
      any(!is.finite(model_rows$year)) ||
      any(model_rows$year != as.integer(model_rows$year)) ||
      any(model_rows$year < 2013L | model_rows$year > 2025L)) {
    .phenology_v2_response_abort(
      "model_rows_key", "year must be an integer-valued 2013-2025 key")
  }

  if (!is.numeric(model_rows$lower_doy) || !is.numeric(model_rows$upper_doy) ||
      anyNA(model_rows$upper_doy) || any(!is.finite(model_rows$upper_doy)) ||
      any(model_rows$upper_doy < 1 | model_rows$upper_doy > 366) ||
      any(!is.na(model_rows$lower_doy) &
            (!is.finite(model_rows$lower_doy) |
               model_rows$lower_doy < 1 | model_rows$lower_doy > 366)) ||
      any(!is.na(model_rows$lower_doy) &
            model_rows$lower_doy >= model_rows$upper_doy)) {
    .phenology_v2_response_abort(
      "model_rows_schema",
      "upper bounds must be finite DOY 1-366 and bounded lower bounds must be strictly smaller")
  }

  if (!is.logical(model_rows$annual_response_supported) ||
      anyNA(model_rows$annual_response_supported)) {
    .phenology_v2_response_abort(
      "model_rows_schema", "annual_response_supported must be complete logical data")
  }

  key <- paste(model_rows$site, model_rows$individualID,
               as.integer(model_rows$year), sep = "\r")
  if (anyDuplicated(key))
    .phenology_v2_response_abort(
      "model_rows_duplicate", "model rows must be unique at site x individualID x year")

  by_year <- split(seq_len(nrow(model_rows)), as.character(model_rows$year))
  for (idx in by_year) {
    supplied <- unique(model_rows$annual_response_supported[idx])
    expected <- length(unique(model_rows$scientificName[idx])) >= 2L &&
      length(unique(model_rows$individualID[idx])) >= 6L
    if (length(supplied) != 1L || !identical(supplied[[1L]], expected))
      .phenology_v2_response_abort(
        "model_rows_schema",
        "annual_response_supported must equal the registered two-species/six-individual gate")
  }

  invisible(model_rows)
}

.phenology_v2_canonical_model_rows <- function(model_rows) {
  species <- sort(unique(enc2utf8(model_rows$scientificName)), method = "radix")
  years <- sort(unique(as.integer(model_rows$year)))
  model_rows$scientificName <- factor(enc2utf8(model_rows$scientificName),
                                      levels = species)
  model_rows$year <- as.integer(model_rows$year)
  ord <- order(model_rows$scientificName, model_rows$year,
               enc2utf8(model_rows$individualID), model_rows$lower_doy,
               model_rows$upper_doy, method = "radix", na.last = TRUE)
  model_rows <- model_rows[ord, , drop = FALSE]
  rownames(model_rows) <- NULL
  attr(model_rows, "phenology_v2_species_levels") <- species
  attr(model_rows, "phenology_v2_year_levels") <- years
  model_rows
}

# Return registered equal-species-year-cell likelihood weights in input order.
phenology_v2_equal_cell_weights <- function(model_rows, effect_locked = TRUE) {
  .phenology_v2_assert_effect_lock(effect_locked)
  .phenology_v2_validate_model_rows(model_rows, allow_empty = TRUE)
  if (!nrow(model_rows)) return(numeric())

  cell <- paste(enc2utf8(model_rows$scientificName),
                as.integer(model_rows$year), sep = "\r")
  cell_n <- table(factor(cell, levels = sort(unique(cell), method = "radix")))
  n_rows <- nrow(model_rows)
  n_cells <- length(cell_n)
  weights <- n_rows / (n_cells * as.numeric(cell_n[cell]))

  tolerance <- 1e-12 * max(1, n_rows)
  cell_sum <- vapply(split(weights, cell), sum, numeric(1L))
  valid <- all(is.finite(weights) & weights > 0) &&
    abs(sum(weights) - n_rows) <= tolerance &&
    abs(mean(weights) - 1) <= 1e-12 &&
    all(abs(cell_sum - n_rows / n_cells) <= tolerance)
  if (!valid)
    .phenology_v2_response_abort(
      "model_rows_schema", "equal-cell likelihood weights failed their registered invariants")
  unname(weights)
}

.phenology_v2_survreg <- function(formula, data, dist, weights, robust, cluster,
                                  na.action, control, model, x, y) {
  fit <- do.call(survival::survreg, list(
    formula = formula, data = data, dist = dist, weights = weights,
    robust = robust, cluster = cluster, na.action = na.action,
    control = control, model = model, x = x, y = y))
  fit
}

.phenology_v2_predict <- function(object, ...)
  stats::predict(object, ...)

.phenology_v2_capture_conditions <- function(expr) {
  warnings <- character()
  error <- NULL
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }),
    error = function(e) {
      error <<- e
      NULL
    })
  list(value = value, warnings = warnings, error = error)
}

.phenology_v2_validate_panel <- function(model_rows) {
  cell <- interaction(model_rows$scientificName, model_rows$year,
                      drop = TRUE, lex.order = TRUE)
  cell_rows <- split(seq_len(nrow(model_rows)), cell)
  bad_cell <- vapply(cell_rows, function(idx) {
    length(unique(model_rows$individualID[idx])) < 3L ||
      !any(!is.na(model_rows$lower_doy[idx]))
  }, logical(1L))
  if (any(bad_cell))
    .phenology_v2_response_abort(
      "response_fit_ineligible",
      "every retained species-year cell requires three individuals and a bounded anchor")

  recurrence <- tapply(model_rows$year, model_rows$scientificName,
                       function(x) length(unique(x)))
  if (any(recurrence < 3L))
    .phenology_v2_response_abort(
      "response_fit_ineligible", "every retained species must recur in at least three eligible years")

  supported_years <- unique(model_rows$year[model_rows$annual_response_supported])
  if (length(supported_years) < 6L)
    .phenology_v2_response_abort(
      "response_fit_ineligible", "response_fit_eligible requires six supported years")

  invisible(TRUE)
}

.phenology_v2_design_gate <- function(model_rows) {
  design <- stats::model.matrix(~ scientificName + factor(year), data = model_rows)
  expected <- length(levels(model_rows$scientificName)) +
    length(unique(model_rows$year)) - 1L
  rank <- qr(design, LAPACK = FALSE)$rank
  if (ncol(design) != expected || rank != expected)
    .phenology_v2_response_abort(
      "response_rank_deficient",
      sprintf("response design rank is %d; expected %d", rank, expected))
  list(design = design, rank = as.integer(rank), expected = as.integer(expected))
}

.phenology_v2_fit_once <- function(model_rows, prediction_grid) {
  individualID <- model_rows$individualID
  model_weight <- model_rows$model_weight
  captured <- .phenology_v2_capture_conditions(
    .phenology_v2_survreg(
      survival::Surv(lower_doy, upper_doy, type = "interval2") ~
        scientificName + factor(year),
      data = model_rows,
      dist = "gaussian",
      weights = model_weight,
      robust = TRUE,
      cluster = individualID,
      na.action = stats::na.fail,
      control = survival::survreg.control(
        maxiter = 30L,
        rel.tolerance = 1e-9,
        toler.chol = 1e-10,
        outer.max = 10L),
      model = TRUE,
      x = TRUE,
      y = TRUE))

  if (length(captured$warnings))
    .phenology_v2_response_abort(
      "response_fit_warning",
      sprintf("survreg warning: %s", paste(captured$warnings, collapse = " | ")))
  if (!is.null(captured$error) || !inherits(captured$value, "survreg")) {
    detail <- if (is.null(captured$error)) "survreg returned an invalid fit" else
      conditionMessage(captured$error)
    .phenology_v2_response_abort("response_fit_failure", detail)
  }

  fit <- captured$value
  convergence_ok <- is.null(fit$fail) &&
    (is.null(fit$converged) || identical(fit$converged, TRUE)) &&
    length(fit$iter) >= 1L && all(is.finite(fit$iter)) &&
    all(is.finite(fit$loglik)) && all(is.finite(fit$coefficients)) &&
    length(fit$scale) == 1L && is.finite(fit$scale) && fit$scale > 0
  if (!convergence_ok)
    .phenology_v2_response_abort(
      "response_nonconvergence", "survreg did not satisfy the registered finite convergence gates")

  n_parameters <- length(fit$coefficients) + 1L
  covariance_ok <- is.matrix(fit$var) &&
    identical(dim(fit$var), c(n_parameters, n_parameters)) &&
    all(is.finite(fit$var)) &&
    max(abs(fit$var - t(fit$var))) <= 1e-10 &&
    all(diag(fit$var) > 0) &&
    is.matrix(fit$naive.var) &&
    identical(dim(fit$naive.var), c(n_parameters, n_parameters)) &&
    all(is.finite(fit$naive.var))
  if (!covariance_ok)
    .phenology_v2_response_abort(
      "response_covariance_invalid",
      "the pinned robust covariance, including estimated scale, is invalid")

  predicted <- .phenology_v2_capture_conditions(
    .phenology_v2_predict(fit, newdata = prediction_grid, type = "lp"))
  if (length(predicted$warnings))
    .phenology_v2_response_abort(
      "response_fit_warning",
      sprintf("prediction warning: %s", paste(predicted$warnings, collapse = " | ")))
  if (!is.null(predicted$error))
    .phenology_v2_response_abort("response_prediction_invalid",
                                 conditionMessage(predicted$error))
  prediction <- as.numeric(predicted$value)
  if (length(prediction) != nrow(prediction_grid) ||
      any(!is.finite(prediction)) || any(prediction < 1 | prediction > 366))
    .phenology_v2_response_abort(
      "response_prediction_invalid", "full-grid latent-location predictions must lie within DOY 1-366")

  list(fit = fit, prediction = prediction)
}

# Fit the sole registered response-only interval model for one eligible site.
phenology_v2_fit_site_response <- function(model_rows, effect_locked = TRUE,
                                           verify_determinism = TRUE) {
  .phenology_v2_assert_effect_lock(effect_locked)
  if (!identical(verify_determinism, TRUE))
    .phenology_v2_response_abort(
      "effect_lock", "the registered two-fit determinism gate cannot be disabled")
  if (!requireNamespace("survival", quietly = TRUE))
    .phenology_v2_response_abort("runtime_mismatch", "the pinned survival namespace is unavailable")

  .phenology_v2_validate_model_rows(model_rows, allow_empty = FALSE)
  model_rows$model_weight <- phenology_v2_equal_cell_weights(
    model_rows, effect_locked = TRUE)
  model_rows <- .phenology_v2_canonical_model_rows(model_rows)
  .phenology_v2_validate_panel(model_rows)
  design <- .phenology_v2_design_gate(model_rows)

  species <- attr(model_rows, "phenology_v2_species_levels", exact = TRUE)
  years <- attr(model_rows, "phenology_v2_year_levels", exact = TRUE)
  prediction_grid <- expand.grid(
    scientificName = species,
    year = years,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE)
  prediction_grid$scientificName <- factor(prediction_grid$scientificName,
                                           levels = species)
  prediction_grid$year <- as.integer(prediction_grid$year)
  prediction_grid <- prediction_grid[
    order(prediction_grid$year, prediction_grid$scientificName,
          method = "radix"), , drop = FALSE]
  rownames(prediction_grid) <- NULL

  first <- .phenology_v2_fit_once(model_rows, prediction_grid)
  second <- .phenology_v2_fit_once(model_rows, prediction_grid)
  deterministic <- identical(unname(first$prediction), unname(second$prediction)) &&
    identical(unname(first$fit$coefficients), unname(second$fit$coefficients)) &&
    identical(unname(first$fit$scale), unname(second$fit$scale))
  if (!deterministic)
    .phenology_v2_response_abort(
      "response_nondeterministic", "two canonical response fits did not reproduce exactly")

  grid_year <- split(seq_len(nrow(prediction_grid)), prediction_grid$year)
  annual_value <- vapply(grid_year, function(idx)
    stats::median(first$prediction[idx]), numeric(1L))
  annual_year <- as.integer(names(annual_value))
  support <- vapply(annual_year, function(year) {
    idx <- model_rows$year == year
    unique(model_rows$annual_response_supported[idx])[[1L]]
  }, logical(1L))
  emitted <- ifelse(support, unname(annual_value), NA_real_)
  site <- as.character(model_rows$site[[1L]])
  annual <- data.frame(
    site = rep(site, length(annual_year)),
    year = annual_year,
    greenup_doy_interval_std = as.numeric(emitted),
    annual_response_supported = support,
    response_present = support & is.finite(emitted),
    stringsAsFactors = FALSE)

  returned_rows <- model_rows
  returned_rows$scientificName <- as.character(returned_rows$scientificName)
  attr(returned_rows, "phenology_v2_species_levels") <- NULL
  attr(returned_rows, "phenology_v2_year_levels") <- NULL

  diagnostics <- data.frame(
    site = site,
    response_fit_eligible = TRUE,
    design_rank = design$rank,
    expected_rank = design$expected,
    converged = TRUE,
    fit_warning = FALSE,
    covariance_valid = TRUE,
    predictions_in_range = TRUE,
    fitted_scale = as.numeric(first$fit$scale),
    n_model_rows = nrow(model_rows),
    n_species = length(species),
    n_panel_years = length(years),
    n_supported_years = sum(support),
    n_clusters = length(unique(model_rows$individualID)),
    stringsAsFactors = FALSE)

  list(
    annual_response = annual,
    model_rows = returned_rows,
    diagnostics = diagnostics,
    fit = first$fit)
}

# Remove numeric response values and return the one-way mask input only.
phenology_v2_response_presence <- function(response, effect_locked = TRUE) {
  .phenology_v2_assert_effect_lock(effect_locked)
  eligible <- NULL
  diagnostic_site <- NULL
  if (is.list(response) && !is.data.frame(response)) {
    if (is.null(response$annual_response) || !is.data.frame(response$annual_response) ||
        is.null(response$diagnostics) || !is.data.frame(response$diagnostics))
      .phenology_v2_response_abort(
        "response_presence_schema", "a response result requires annual_response and diagnostics tables")
    annual <- response$annual_response
    if (nrow(response$diagnostics) != 1L ||
        !"site" %in% names(response$diagnostics) ||
        !is.character(response$diagnostics$site) ||
        !is.null(dim(response$diagnostics$site)) ||
        length(response$diagnostics$site) != 1L ||
        is.na(response$diagnostics$site[[1L]]) ||
        !nzchar(trimws(response$diagnostics$site[[1L]])) ||
        !is.logical(response$diagnostics$response_fit_eligible) ||
        length(response$diagnostics$response_fit_eligible) != 1L ||
        is.na(response$diagnostics$response_fit_eligible[[1L]]))
      .phenology_v2_response_abort(
        "response_presence_schema", "response diagnostics lack one strict eligibility value")
    eligible <- response$diagnostics$response_fit_eligible[[1L]]
    diagnostic_site <- response$diagnostics$site[[1L]]
  } else {
    annual <- response
  }

  required <- c("site", "year", "greenup_doy_interval_std",
                "annual_response_supported", "response_present")
  optional <- "response_fit_eligible"
  if (!.phenology_v2_is_plain_frame(annual) ||
      !(identical(names(annual), required) ||
          identical(names(annual), c(required, optional)))) {
    .phenology_v2_response_abort(
      "response_presence_schema", "annual response has an unexpected response-only schema")
  }
  if (any(vapply(annual, function(x) !is.null(dim(x)), logical(1L))))
    .phenology_v2_response_abort(
      "response_presence_schema",
      "annual response columns must be one-dimensional vectors")
  if (!is.character(annual$site) || anyNA(annual$site) ||
      any(!nzchar(trimws(annual$site))) ||
      length(unique(annual$site)) != 1L ||
      !is.numeric(annual$year) || anyNA(annual$year) ||
      any(!is.finite(annual$year)) || any(annual$year != as.integer(annual$year)) ||
      any(!annual$year %in% 2013:2025) ||
      !is.numeric(annual$greenup_doy_interval_std) ||
      !is.logical(annual$annual_response_supported) ||
      anyNA(annual$annual_response_supported) ||
      !is.logical(annual$response_present) || anyNA(annual$response_present)) {
    .phenology_v2_response_abort(
      "response_presence_schema", "annual response keys and booleans are malformed")
  }
  if (!is.null(diagnostic_site) &&
      !identical(unique(annual$site), diagnostic_site))
    .phenology_v2_response_abort(
      "response_presence_schema",
      "response diagnostics and annual response identify different sites")
  finite_response <- is.finite(annual$greenup_doy_interval_std)
  if (any(!is.na(annual$greenup_doy_interval_std) & !finite_response) ||
      any(finite_response &
            (annual$greenup_doy_interval_std < 1 |
               annual$greenup_doy_interval_std > 366)) ||
      !identical(finite_response, annual$annual_response_supported))
    .phenology_v2_response_abort(
      "response_presence_schema",
      "finite in-range response values must occur exactly in supported years")
  expected_present <- annual$annual_response_supported &
    finite_response
  if (!identical(annual$response_present, expected_present))
    .phenology_v2_response_abort(
      "response_presence_schema", "response_present does not match the registered numeric response missingness")
  if (anyDuplicated(paste(annual$site, as.integer(annual$year), sep = "\r")))
    .phenology_v2_response_abort(
      "response_presence_schema", "response-presence keys must be unique at site x year")

  annual_eligible <- NULL
  if (optional %in% names(annual)) {
    if (!is.logical(annual[[optional]]) || anyNA(annual[[optional]]) ||
        length(unique(annual[[optional]])) != 1L)
      .phenology_v2_response_abort(
        "response_presence_schema", "response_fit_eligible must be one strict site-level logical")
    annual_eligible <- annual[[optional]][[1L]]
  }
  if (is.null(eligible)) {
    if (!is.null(annual_eligible)) {
      eligible <- annual_eligible
    } else {
      # A standalone annual table can only be emitted by a successful site fit.
      eligible <- TRUE
    }
  } else if (!is.null(annual_eligible) &&
             !identical(eligible, annual_eligible)) {
    .phenology_v2_response_abort(
      "response_presence_schema",
      "response diagnostics and annual response disagree on fit eligibility")
  }
  if ((!isTRUE(eligible) && any(annual$response_present)) ||
      (isTRUE(eligible) && sum(annual$response_present) < 6L))
    .phenology_v2_response_abort(
      "response_presence_schema",
      "response presence must agree with the six-year site-fit eligibility gate"
    )

  out <- data.frame(
    site = enc2utf8(annual$site),
    year = as.integer(annual$year),
    response_fit_eligible = rep(as.logical(eligible), nrow(annual)),
    response_present = annual$response_present,
    stringsAsFactors = FALSE)
  out <- out[order(enc2utf8(out$site), out$year, method = "radix"), , drop = FALSE]
  rownames(out) <- NULL
  out
}
