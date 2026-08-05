# Independent, synthetic-only Seal-1 contracts for the Phenology v2 adapter.
#
# With no arguments this file is only an orchestrator.  It launches the three
# registered surfaces in fresh R processes so response values and climate
# values can never coexist.  The child modes are intentionally explicit:
#
#   static-lock       parsed-source/effect-lock and public-API contracts
#   adapter-response  visit, opportunity, support, and response-only fixtures
#   climate-mask      values-free climate-support-mask fixtures

setwd_repo_root <- function() {
  if (file.exists("global.R"))
    return(invisible(normalizePath(".", winslash = "/", mustWork = TRUE)))

  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[[1L]]),
                            winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}

ROOT <- setwd_repo_root()

ok <- function(label, detail = "OK")
  cat(sprintf("[PASS] %-62s %s\n", label, detail))

fail <- function(label, detail = "") {
  suffix <- if (nzchar(detail)) paste0(": ", detail) else ""
  stop(sprintf("[FAIL] %s%s", label, suffix), call. = FALSE)
}

check <- function(value, label, detail = "") {
  if (!isTRUE(value)) fail(label, detail)
  ok(label, detail)
  invisible(TRUE)
}

check_identical <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    fail(label, sprintf("actual=%s expected=%s",
                        paste(capture.output(dput(actual)), collapse = " "),
                        paste(capture.output(dput(expected)), collapse = " ")))
  }
  ok(label)
  invisible(TRUE)
}

check_near <- function(actual, expected, label, tolerance = 1e-12) {
  good <- length(actual) == length(expected) &&
    all((is.na(actual) & is.na(expected)) |
          (is.finite(actual) & is.finite(expected) &
             abs(actual - expected) <= tolerance))
  check(good, label, sprintf("tolerance %.3g", tolerance))
}

condition_code <- function(e) {
  code <- e$code
  if (is.null(code)) code <- attr(e, "phenology_v2_error_code", exact = TRUE)
  if (is.null(code)) {
    cls <- class(e)
    cls <- cls[grepl("^phenology_v2_", cls)]
    if (length(cls)) code <- sub("^phenology_v2_", "", cls[[1L]])
  }
  if (!length(code) || is.na(code[[1L]]) || !nzchar(as.character(code[[1L]])))
    return(NA_character_)
  as.character(code[[1L]])
}

expect_error_code <- function(expr, code, label) {
  failure <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) e)
  if (!inherits(failure, "error")) fail(label, "expression succeeded")
  actual <- condition_code(failure)
  if (!identical(actual, code)) {
    fail(label, sprintf("error code '%s', expected '%s' (%s)",
                        actual, code, conditionMessage(failure)))
  }
  ok(label, code)
  invisible(failure)
}

capture_warnings <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

required_modules <- c(
  adapter = "R/phenology_adapter_v2.R",
  response = "R/phenology_response_model_v2.R",
  climate = "R/phenology_climate_support_mask_v2.R"
)

required_api <- c(
  adapter = "phenology_v2_adapt_bundle",
  weight = "phenology_v2_equal_cell_weights",
  response = "phenology_v2_fit_site_response",
  presence = "phenology_v2_response_presence",
  join = "phenology_v2_join_driver_calendar",
  climate = "phenology_v2_build_climate_support_mask"
)

forbidden_artifacts <- c(
  "data/cascade.rds",
  "data/search_index.rds",
  "data/cascade_meta.rds",
  "data/neon-cascade-codebook.csv",
  "manifest.json"
)

artifact_md5 <- function() {
  missing <- forbidden_artifacts[!file.exists(forbidden_artifacts)]
  if (length(missing))
    fail("artifact no-mutation baseline", paste("missing", paste(missing, collapse = ", ")))
  unname(tools::md5sum(forbidden_artifacts))
}

source_modules <- function(paths, climate_mode = FALSE) {
  env <- new.env(parent = globalenv())
  trip <- function(symbol) {
    force(symbol)
    function(...) stop(structure(
      list(message = sprintf("effect lock intercepted forbidden symbol: %s", symbol),
           call = NULL, code = "effect_lock"),
      class = c("phenology_v2_effect_lock", "error", "condition")))
  }
  if (!climate_mode) {
    for (name in c("source", "sys.source", "site_links", "pooled_links",
                   "binom.test", "p.adjust", "cor", "rma", "readRDS",
                   "phenology_v2_build_climate_support_mask", "temp",
                   "temp_spring", "climate"))
      assign(name, trip(name), envir = env)
  }
  for (path in paths)
    base::sys.source(path, envir = env, keep.source = FALSE)
  env
}

call_api <- function(env, name, ...) {
  if (!exists(name, envir = env, mode = "function", inherits = FALSE))
    fail("public API", sprintf("missing %s", name))
  get(name, envir = env, inherits = FALSE)(...)
}

with_replaced_binding <- function(env, name, replacement, code) {
  original <- get(name, envir = env, inherits = FALSE)
  assign(name, replacement, envir = env)
  on.exit(assign(name, original, envir = env), add = TRUE)
  force(code)
}

require_table <- function(result, name) {
  if (!is.list(result) || is.null(result[[name]]) ||
      !is.data.frame(result[[name]]))
    fail("adapter table contract", sprintf("missing data.frame '%s'", name))
  result[[name]]
}

pick_col <- function(x, choices, label = paste(choices, collapse = "/")) {
  found <- intersect(choices, names(x))
  if (length(found) != 1L)
    fail(label, sprintf("expected exactly one column, found: %s",
                        paste(found, collapse = ", ")))
  found[[1L]]
}

col_value <- function(x, choices) x[[pick_col(x, choices)]][[1L]]

canonical_frame <- function(x) {
  if (!is.data.frame(x)) return(x)
  # `source_row` is a trace back to the caller's original inert-table ordinal,
  # not a scientific key or canonical output field.  Compare its cardinality
  # separately and compare every content-derived field here.
  if ("source_row" %in% names(x)) x$source_row <- NULL
  names(x) <- enc2utf8(names(x))
  if (!nrow(x)) return(x[, sort(names(x), method = "radix"), drop = FALSE])
  cols <- sort(names(x), method = "radix")
  x <- x[, cols, drop = FALSE]
  keys <- lapply(x, function(v) {
    if (inherits(v, "Date")) return(format(v, "%Y-%m-%d"))
    if (is.factor(v)) return(as.character(v))
    if (is.numeric(v)) return(sprintf("%.17g", v))
    ifelse(is.na(v), "<NA>", enc2utf8(as.character(v)))
  })
  ord <- do.call(order, c(keys, list(method = "radix", na.last = TRUE)))
  x <- x[ord, , drop = FALSE]
  rownames(x) <- NULL
  x
}

canonical_result <- function(x) {
  if (is.data.frame(x)) return(canonical_frame(x))
  if (is.list(x)) {
    nms <- sort(names(x), method = "radix")
    return(setNames(lapply(x[nms], canonical_result), nms))
  }
  x
}

same_canonical <- function(x, y)
  identical(serialize(canonical_result(x), NULL, version = 3L),
            serialize(canonical_result(y), NULL, version = 3L))

response_numeric_receipt <- function(payload) {
  if (!requireNamespace("digest", quietly = TRUE))
    fail("response numerical receipt", "locked digest package unavailable")
  check_identical(as.character(utils::packageVersion("digest")), "0.6.39",
                  "locked digest package version")
  expected <- c(
    "model_rows", "prediction_grid", "annual_response", "diagnostics")
  check_identical(names(payload), expected,
                  "response numerical receipt field allowlist")
  check(all(vapply(payload, is.data.frame, logical(1L))),
        "response numerical receipt contains tables only")
  canonical_bytes <- serialize(
    canonical_result(payload), NULL, version = 3L)
  receipt <- digest::digest(
    canonical_bytes, algo = "sha256", serialize = FALSE)
  check(length(receipt) == 1L &&
          grepl("^[0-9a-f]{64}$", receipt, perl = TRUE),
        "response numerical receipt is opaque SHA-256")
  receipt
}

target_phases <- c(
  "Breaking leaf buds", "Initial growth", "Emerging needles",
  "Breaking needle buds"
)

make_obs <- function(individualID = "P1", plotID = "TEST_001",
                     scientificName = "Alpha alba", growthForm = "tree",
                     year = 2018L, date = "2018-04-01", dayOfYear = 91,
                     phenophaseName = "Breaking leaf buds", status = "yes",
                     intensity = NA_character_, is_species = TRUE) {
  n <- max(length(individualID), length(plotID), length(scientificName),
           length(growthForm), length(year), length(date), length(dayOfYear),
           length(phenophaseName), length(status), length(intensity),
           length(is_species))
  data.frame(
    individualID = rep_len(individualID, n),
    plotID = rep_len(plotID, n),
    scientificName = rep_len(scientificName, n),
    growthForm = rep_len(growthForm, n),
    year = rep_len(year, n),
    date = rep_len(date, n),
    dayOfYear = rep_len(dayOfYear, n),
    phenophaseName = rep_len(phenophaseName, n),
    status = rep_len(status, n),
    intensity = rep_len(intensity, n),
    is_species = rep_len(is_species, n),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

roster_from_obs <- function(obs, add = NULL) {
  keep <- !duplicated(obs$individualID) & !is.na(obs$individualID)
  x <- obs[keep, c("individualID", "scientificName", "growthForm", "plotID",
                   "is_species"), drop = FALSE]
  x$lat <- 35
  x$lng <- -111
  x$nativeStatusCode <- NA_character_
  x$taxonRank <- ifelse(is.na(x$is_species), NA_character_,
                        ifelse(x$is_species, "species", "genus"))
  x <- x[, c("individualID", "scientificName", "growthForm", "plotID",
             "lat", "lng", "nativeStatusCode", "taxonRank", "is_species")]
  if (!is.null(add)) x <- rbind(x, add)
  rownames(x) <- NULL
  x
}

make_bundle <- function(obs, inds = roster_from_obs(obs), site = "TEST",
                        years = sort(unique(suppressWarnings(as.integer(obs$year))))) {
  list(
    obs = obs,
    inds = inds,
    meta = list(site = site, lat = 35, lng = -111, years = years),
    ind_summary = data.frame(),
    trend = NULL
  )
}

adapt <- function(env, obs, inds = roster_from_obs(obs), site = "TEST")
  call_api(env, required_api[["adapter"]], make_bundle(obs, inds, site), site,
           effect_locked = TRUE)

phase_pair <- function(id, species, year, no_doy, yes_doy,
                       phase = target_phases[[1L]], plot = "TEST_001",
                       growth = "tree") {
  dates <- as.Date(sprintf("%04d-01-01", year)) + c(no_doy, yes_doy) - 1L
  make_obs(
    individualID = id, plotID = plot, scientificName = species,
    growthForm = growth, year = year, date = format(dates, "%Y-%m-%d"),
    dayOfYear = c(no_doy, yes_doy), phenophaseName = phase,
    status = c("no", "yes"), is_species = TRUE
  )
}

left_visit <- function(id, species, year, yes_doy,
                       phase = target_phases[[1L]], plot = "TEST_001") {
  date <- as.Date(sprintf("%04d-01-01", year)) + yes_doy - 1L
  make_obs(id, plot, species, "tree", year, format(date, "%Y-%m-%d"),
           yes_doy, phase, "yes", is_species = TRUE)
}

panel_obs <- function(years = 2018:2023, species = c("Alpha alba", "Beta beta"),
                      n_by_cell = 3L, left_first = FALSE) {
  rows <- list()
  k <- 0L
  for (sp in species) {
    for (yr in years) {
      n <- if (length(n_by_cell) == 1L) n_by_cell else
        n_by_cell[[paste(sp, yr, sep = "|")]]
      if (is.null(n) || is.na(n) || n <= 0L) next
      for (i in seq_len(n)) {
        k <- k + 1L
        id <- sprintf("%s_%04d_%02d", gsub("[^A-Za-z]", "", sp), yr, i)
        yes <- 90L + match(sp, species) * 7L + (yr - min(years)) + i
        row <- if (isTRUE(left_first) && i == 1L)
          left_visit(id, sp, yr, yes) else
          phase_pair(id, sp, yr, yes - 8L, yes)
        rows[[k]] <- row
      }
    }
  }
  do.call(rbind, rows)
}

fixture_seen <- setNames(rep(FALSE, 38L), as.character(seq_len(38L)))
fixture_names <- c(
  "same-status duplicate collapse",
  "mixed-status visit conflict and row-order invariance",
  "multiple source DOYs retain one date clock",
  "missing source DOY separates v2 and compatibility",
  "disagreeing source/date clocks stay separate",
  "same week in different years stays distinct",
  "uncertain visits do not define bounds",
  "bounded interval and compatibility midpoint",
  "first-visit yes is left-censored",
  "all-no is right-censored and not a likelihood zero",
  "no target phase is structural-unscored",
  "uninformative competing phase is ambiguous",
  "earliest-phase interval envelope algebra",
  "v1 tied censor and maximum-width compatibility",
  "v2 taxonomic conflict fails",
  "all-taxonomy-null unmatched identity is retained",
  "taxonomy-asserting unmatched identity fails",
  "historical roster/observation plot mismatch is audited",
  "conflicting plots inside a visit fail",
  "species-rank exclusions",
  "species-year three-individual and bounded-anchor boundary",
  "annual two-species/six-individual boundary",
  "three-year recurrence boundary",
  "connected-panel deterministic tie breaks",
  "abundance resistance and equal-species standardization",
  "equal-cell weight invariants",
  "individual clustering and no plot design term",
  "rank-deficient and full-rank designs",
  "fit failures, coding, and row-order invariance",
  "typed empty support without warnings",
  "leaf weeks 1, 1, 2, and 15 yield 21 days",
  "uncapped week 53 behavior",
  "leaf no/uncertain without yes is missing",
  "multiple flushes remain additive",
  "coverage threshold changes context only",
  "five/six supported-year fit boundary",
  "one-way climate mask overlap boundaries",
  "malformed inputs fail closed"
)

fixture <- function(id, code) {
  stopifnot(length(id) == 1L, id >= 1L, id <= 38L)
  force(code)
  fixture_seen[[as.character(id)]] <<- TRUE
  ok(sprintf("fixture %02d", id), fixture_names[[id]])
  invisible(TRUE)
}

finish_fixtures <- function(ids) {
  missing <- ids[!fixture_seen[as.character(ids)]]
  check(!length(missing), "fixture registry complete",
        if (length(missing)) paste("missing", paste(missing, collapse = ", "))
        else sprintf("%d fixtures", length(ids)))
}

ast_calls <- function(expr) {
  found <- character()
  visit <- function(x) {
    if (is.call(x)) {
      head <- x[[1L]]
      if (is.symbol(head)) found <<- c(found, as.character(head))
      if (is.call(head) && length(head) == 3L &&
          as.character(head[[1L]]) %in% c("::", ":::")) {
        found <<- c(found, paste0(as.character(head[[2L]]),
                                  as.character(head[[1L]]),
                                  as.character(head[[3L]])))
      }
      lapply(as.list(x), visit)
    } else if (is.expression(x) || is.pairlist(x)) {
      lapply(as.list(x), visit)
    }
    invisible(NULL)
  }
  visit(expr)
  unique(found)
}

ast_symbols <- function(expr) {
  found <- character()
  visit <- function(x) {
    if (is.symbol(x)) found <<- c(found, as.character(x))
    if (is.call(x) || is.expression(x) || is.pairlist(x))
      lapply(as.list(x), visit)
    invisible(NULL)
  }
  visit(expr)
  unique(found)
}

sha256_file <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else
    if (nzchar(Sys.which("shasum"))) "shasum" else ""
  if (!nzchar(command)) fail("SHA-256 baseline", "no sha256sum or shasum")
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args = args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status", exact = TRUE)
  if (!is.null(status) && status != 0L)
    fail("SHA-256 baseline", paste(output, collapse = "\n"))
  sub("[[:space:]].*$", "", output[[1L]])
}

run_static_lock <- function() {
  missing <- required_modules[!file.exists(required_modules)]
  check(!length(missing), "Seal-1 module surface",
        if (length(missing)) paste("missing", paste(missing, collapse = ", "))
        else paste(basename(required_modules), collapse = ", "))

  parsed <- lapply(required_modules, function(path)
    parse(file = path, keep.source = FALSE, encoding = "UTF-8"))

  effect_calls <- c(
    "source", "sys.source", "readRDS", "site_links", "pooled_links",
    "binom.test", "stats::binom.test", "p.adjust", "stats::p.adjust",
    "cor", "stats::cor", "rma", "metafor::rma"
  )
  mutation_calls <- c(
    "save", "saveRDS", "write.csv", "write.csv2", "write.table",
    "writeLines", "writeBin", "file.create", "file.copy", "file.rename",
    "unlink", "dir.create"
  )
  for (name in names(parsed)) {
    calls <- ast_calls(parsed[[name]])
    bad <- intersect(c(effect_calls, mutation_calls), calls)
    check(!length(bad), sprintf("%s AST effect/write lock", name),
          if (length(bad)) paste(bad, collapse = ", ") else "no forbidden calls")
  }

  response_symbols <- ast_symbols(parsed[["response"]])
  leaked <- intersect(
    c("temp", "temp_c", "temp_spring", "precip", "precip_mm",
      "fruiting_pct", "climate", "environment"),
    response_symbols
  )
  check(!length(leaked), "response module climate-object lock",
        if (length(leaked)) paste(leaked, collapse = ", ") else "no climate symbols")

  climate_symbols <- ast_symbols(parsed[["climate"]])
  leaked <- intersect(
    c("greenup_doy_interval_std", "greenup_doy", "response_value",
      "coefficient", "effect", "p_value", "correlation"),
    climate_symbols
  )
  check(!length(leaked), "climate module numeric-response/effect lock",
        if (length(leaked)) paste(leaked, collapse = ", ") else "mask-only symbols")

  adapter_env <- source_modules(required_modules[c("adapter", "response")])
  climate_env <- source_modules(required_modules[["climate"]], climate_mode = TRUE)
  for (name in required_api[c("adapter", "weight", "response", "presence", "join")])
    check(exists(name, envir = adapter_env, mode = "function", inherits = FALSE),
          sprintf("public API %s", name))
  check(exists(required_api[["climate"]], envir = climate_env,
               mode = "function", inherits = FALSE),
        sprintf("public API %s", required_api[["climate"]]))

  expected_sha256 <- c(
    "data/cascade.rds" = "47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe",
    "data/search_index.rds" = "a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e",
    "data/cascade_meta.rds" = "00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de",
    "data/neon-cascade-codebook.csv" = "a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3",
    "manifest.json" = "92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79"
  )
  actual_sha256 <- vapply(names(expected_sha256), sha256_file, character(1L))
  check_identical(unname(actual_sha256), unname(expected_sha256),
                  "registered generated-artifact baseline")

  ok("static-lock mode", "effect paths unreachable and artifacts read-only")
}

one_row <- function(x, filters, label) {
  keep <- rep(TRUE, nrow(x))
  for (name in names(filters)) {
    if (!name %in% names(x)) fail(label, paste("missing key", name))
    want <- filters[[name]]
    keep <- keep & if (is.na(want)) is.na(x[[name]]) else x[[name]] == want
  }
  rows <- x[keep, , drop = FALSE]
  if (nrow(rows) != 1L)
    fail(label, sprintf("expected one row, found %d", nrow(rows)))
  rows
}

state_is <- function(x, expected, choices, label) {
  actual <- as.character(x[[pick_col(x, choices, label)]])
  check(identical(actual, expected), label,
        sprintf("actual=%s expected=%s", paste(actual, collapse = ","),
                paste(expected, collapse = ",")))
}

numeric_is <- function(x, expected, choices, label, tolerance = 1e-12) {
  check_near(as.numeric(x[[pick_col(x, choices, label)]]), expected,
             label, tolerance)
}

logical_is <- function(x, expected, choices, label) {
  actual <- as.logical(x[[pick_col(x, choices, label)]])
  check_identical(actual, as.logical(expected), label)
}

run_adapter_observation_fixtures <- function(env) {
  # 1. Exact same-status source duplicates collapse at the visit grain.
  obs <- rbind(
    make_obs(date = "2018-04-01", dayOfYear = 91, status = "no"),
    make_obs(date = "2018-04-01", dayOfYear = 91, status = "no"),
    make_obs(date = "2018-04-11", dayOfYear = 101, status = "yes")
  )
  result <- adapt(env, obs)
  fixture(1, {
    check(nrow(require_table(result, "source_rows")) == 3L,
          "duplicate fixture preserves source rows")
    check(nrow(require_table(result, "visits")) == 2L,
          "same-status duplicates collapse once")
  })

  # 2. Every mixed token combination is a conflict and order independent.
  obs <- rbind(
    make_obs(date = "2018-04-01", dayOfYear = 91,
             status = c("no", "yes")),
    make_obs(date = "2018-04-08", dayOfYear = 98,
             status = c("uncertain", "yes")),
    make_obs(date = "2018-04-15", dayOfYear = 105,
             status = c("no", "uncertain"))
  )
  direct <- adapt(env, obs)
  reverse <- adapt(env, obs[nrow(obs):1L, , drop = FALSE])
  fixture(2, {
    visits <- require_table(direct, "visits")
    state <- as.character(visits[[pick_col(
      visits, c("visit_state", "visit_status", "status_state"),
      "visit conflict state")]])
    check(nrow(visits) == 3L && all(state == "visit_status_conflict"),
          "all mixed-status combinations conflict")
    check(same_canonical(direct, reverse), "mixed-status row-order invariance")
  })

  # 3. Source-clock multiplicity cannot multiply the date-derived visit.
  obs <- make_obs(date = "2018-04-01", dayOfYear = c(90, 91), status = "yes")
  result <- adapt(env, obs)
  fixture(3, {
    visits <- require_table(result, "visits")
    check(nrow(visits) == 1L, "multiple source DOYs leave one v2 visit")
    numeric_is(visits, 91, c("visit_doy", "date_doy"),
               "date-derived visit clock")
  })

  # 4. Missing source DOY is valid for v2 and unavailable for compatibility.
  obs <- make_obs(date = "2018-04-01", dayOfYear = NA_real_, status = "yes")
  result <- adapt(env, obs)
  fixture(4, {
    py <- require_table(result, "plant_years")
    state_is(py, "left_censored_onset", "v2_observation_state",
             "missing-source-DOY v2 state")
    state_is(py, "compat_no_finite_onset", "compat_censor_state",
             "missing-source-DOY compatibility state")
    numeric_is(py, 91, c("upper_doy", "individual_upper"),
               "missing-source-DOY date bound")
  })

  # 5. A valid but disagreeing source clock remains namespaced.
  obs <- rbind(
    make_obs(date = "2018-04-01", dayOfYear = 100, status = "no"),
    make_obs(date = "2018-04-11", dayOfYear = 120, status = "yes")
  )
  result <- adapt(env, obs)
  fixture(5, {
    py <- require_table(result, "plant_years")
    numeric_is(py, 91, c("lower_doy", "individual_lower"),
               "v2 lower bound uses date")
    numeric_is(py, 101, c("upper_doy", "individual_upper"),
               "v2 upper bound uses date")
    compat <- require_table(result, "compatibility_individual_years")
    numeric_is(compat, 110, c("compat_onset", "compat_onset_doy", "onset"),
               "compatibility midpoint uses source DOY")
    src <- require_table(result, "source_rows")
    mismatch <- src[[pick_col(src,
      c("source_doy_mismatch", "source_doy_disagrees_with_date"),
      "source/date mismatch flag")]]
    check(all(mismatch), "source/date disagreements are audited")
  })

  # 6. Year is part of the leaf-active opportunity key.
  obs <- rbind(
    make_obs(year = 2018L, date = "2018-01-01", dayOfYear = 1,
             phenophaseName = "Leaves", status = "yes"),
    make_obs(year = 2019L, date = "2019-01-01", dayOfYear = 1,
             phenophaseName = "Leaves", status = "yes")
  )
  result <- adapt(env, obs)
  fixture(6, {
    leaf <- require_table(result, "leaf_active")
    check(nrow(leaf) == 2L && identical(sort(as.integer(leaf$year)), 2018:2019),
          "same leaf week remains distinct across years")
    days <- leaf[[pick_col(leaf, "leaf_active_days_7d")]]
    check(identical(sort(as.numeric(days)), c(7, 7)),
          "each annual leaf opportunity receives one week")
  })

  # 7-8. Uncertain visits never alter a bounded yes/no interval.
  obs <- rbind(
    make_obs(date = "2018-04-01", dayOfYear = 91, status = "no"),
    make_obs(date = "2018-04-06", dayOfYear = 96, status = "uncertain"),
    make_obs(date = "2018-04-11", dayOfYear = 101, status = "yes")
  )
  result <- adapt(env, obs)
  fixture(7, {
    phase <- require_table(result, "phases")
    numeric_is(phase, 91, "lower_doy", "uncertain excluded from lower bound")
    numeric_is(phase, 101, "upper_doy", "uncertain excluded from upper bound")
  })
  fixture(8, {
    phase <- require_table(result, "phases")
    state <- as.character(phase[[pick_col(phase,
      c("phase_state", "v2_phase_state"))]])
    check(state %in% c("bounded", "bounded_onset"),
          "bounded phase state")
    numeric_is(phase, 96, "midpoint_doy", "bounded midpoint")
    numeric_is(phase, 10, "interval_days", "bounded width")
    compat <- require_table(result, "compatibility_individual_years")
    numeric_is(compat, 96, c("compat_onset", "compat_onset_doy", "onset"),
               "exact compatibility midpoint")
  })

  # 9. First-visit yes is a left bound, never an exact point response.
  result <- adapt(env, make_obs(date = "2018-04-11", dayOfYear = 101,
                                status = "yes"))
  fixture(9, {
    py <- require_table(result, "plant_years")
    state_is(py, "left_censored_onset", "v2_observation_state",
             "first yes remains left-censored")
    lower <- py[[pick_col(py, c("lower_doy", "individual_lower"))]]
    check(all(is.na(lower) | is.infinite(lower) & lower < 0),
          "left-censored lower bound is unknown")
    numeric_is(py, 101, c("upper_doy", "individual_upper"),
               "left-censored upper bound")
  })

  # 10. All-no is an audit row and never a zero-valued likelihood row.
  obs <- rbind(
    make_obs(date = "2018-04-01", dayOfYear = 91, status = "no"),
    make_obs(date = "2018-04-11", dayOfYear = 101, status = "no")
  )
  result <- adapt(env, obs)
  fixture(10, {
    py <- require_table(result, "plant_years")
    state_is(py, "right_censored_no_yes", "v2_observation_state",
             "all-no observation state")
    check(nrow(require_table(result, "model_rows")) == 0L,
          "right-censored all-no excluded from likelihood")
    upper <- py[[pick_col(py, c("upper_doy", "individual_upper"))]]
    check(all(is.na(upper) | is.infinite(upper) & upper > 0),
          "all-no has no finite onset")
  })

  # 11. Opportunity persists even when no target phase was monitored.
  result <- adapt(env, make_obs(phenophaseName = "Leaves", status = "yes"))
  fixture(11, {
    py <- require_table(result, "plant_years")
    state_is(py, "structural_unscored", "v2_observation_state",
             "no-target opportunity state")
  })

  # 12. A wholly uninformative target phase competes with an informative one.
  obs <- rbind(
    phase_pair("P1", "Alpha alba", 2018L, 91L, 101L,
               target_phases[[1L]]),
    make_obs(phenophaseName = target_phases[[2L]], date = "2018-03-20",
             dayOfYear = 79, status = "uncertain")
  )
  result <- adapt(env, obs)
  conflict_obs <- rbind(
    phase_pair("P1", "Alpha alba", 2018L, 91L, 101L,
               target_phases[[1L]]),
    make_obs(phenophaseName = target_phases[[2L]], date = "2018-03-20",
             dayOfYear = 79, status = c("no", "yes"))
  )
  conflict_result <- adapt(env, conflict_obs)
  fixture(12, {
    py <- require_table(result, "plant_years")
    state_is(py, "ambiguous_competing_phase", "v2_observation_state",
             "uncertain competing phase blocks convenient interval")
    check(nrow(require_table(result, "model_rows")) == 0L,
          "ambiguous competing phase excluded from likelihood")
    conflict_py <- require_table(conflict_result, "plant_years")
    state_is(conflict_py, "ambiguous_competing_phase", "v2_observation_state",
             "conflict-only competing phase blocks convenient interval")
    check(conflict_py$conflict_visits == 1L &&
            nrow(require_table(conflict_result, "model_rows")) == 0L,
          "competing visit conflict remains audited and ineligible")
  })

  # 13. Independent earliest-phase oracle for bounded/left/right mixtures.
  obs <- rbind(
    phase_pair("B", "Alpha alba", 2018L, 100L, 110L, target_phases[[1L]]),
    phase_pair("B", "Alpha alba", 2018L, 90L, 120L, target_phases[[2L]]),
    left_visit("L", "Alpha alba", 2018L, 105L, target_phases[[1L]]),
    phase_pair("L", "Alpha alba", 2018L, 100L, 115L, target_phases[[2L]]),
    make_obs("R", scientificName = "Alpha alba", year = 2018L,
             date = "2018-04-10", dayOfYear = 100,
             phenophaseName = target_phases[[1L]], status = "no"),
    make_obs("R", scientificName = "Alpha alba", year = 2018L,
             date = "2018-04-20", dayOfYear = 110,
             phenophaseName = target_phases[[2L]], status = "no"),
    phase_pair("M", "Alpha alba", 2018L, 100L, 120L,
               target_phases[[1L]]),
    make_obs("M", scientificName = "Alpha alba", year = 2018L,
             date = "2018-03-31", dayOfYear = 90,
             phenophaseName = target_phases[[2L]], status = "no")
  )
  result <- adapt(env, obs)
  fixture(13, {
    py <- require_table(result, "plant_years")
    bounded <- one_row(py, list(individualID = "B", year = 2018L),
                       "bounded envelope row")
    numeric_is(bounded, 90, c("lower_doy", "individual_lower"),
               "bounded envelope lower=min(lower)")
    numeric_is(bounded, 110, c("upper_doy", "individual_upper"),
               "bounded envelope upper=min(upper)")
    left <- one_row(py, list(individualID = "L", year = 2018L),
                    "left envelope row")
    state_is(left, "left_censored_onset", "v2_observation_state",
             "left phase preserves left censoring")
    numeric_is(left, 105, c("upper_doy", "individual_upper"),
               "left envelope upper=min(upper)")
    right <- one_row(py, list(individualID = "R", year = 2018L),
                     "right envelope row")
    state_is(right, "right_censored_no_yes", "v2_observation_state",
             "all-right phases stay right-censored")
    numeric_is(right, 100, c("lower_doy", "individual_lower"),
               "right envelope lower=min(lower)")
    mixed <- one_row(py, list(individualID = "M", year = 2018L),
                     "bounded/right envelope row")
    state_is(mixed, "bounded_onset", "v2_observation_state",
             "bounded plus right-censored phase remains bounded")
    numeric_is(mixed, 90, c("lower_doy", "individual_lower"),
               "right-censored phase widens earliest lower bound")
    numeric_is(mixed, 120, c("upper_doy", "individual_upper"),
               "bounded phase supplies finite earliest upper bound")
  })

  # 14. Compatibility ties conservatively preserve censoring and widest width.
  obs <- rbind(
    phase_pair("P1", "Alpha alba", 2018L, 100L, 120L,
               target_phases[[1L]]),
    left_visit("P1", "Alpha alba", 2018L, 110L,
               target_phases[[2L]])
  )
  result <- adapt(env, obs)
  compatibility_collapse <- get(
    "phenology_v2_compatibility_individual_years", envir = env,
    inherits = FALSE)
  tied_taxa <- data.frame(
    site = c("TEST", "TEST"),
    individualID = c("P1", "P1"),
    scientificName = c("Zulu zeta", "Alpha alba"),
    growthForm = c("tree", "tree"),
    phenophaseName = target_phases[1:2],
    year = c(2018L, 2018L),
    compat_onset = c(110, 110),
    compat_left_censored = c(FALSE, TRUE),
    first_yes = c(120, 110),
    stringsAsFactors = FALSE
  )
  lexical_tie <- compatibility_collapse(tied_taxa)
  fixture(14, {
    compat <- require_table(result, "compatibility_individual_years")
    state_is(compat, "compat_left_censored", "compat_censor_state",
             "any tied left censor wins")
    numeric_is(compat, 110, c("compat_onset", "compat_onset_doy", "onset"),
               "tied compatibility onset")
    numeric_is(compat, 20,
               c("compat_interval_days", "compat_onset_interval_days",
                 "interval_days"),
               "maximum tied compatibility width")
    check(identical(as.character(compat$scientificName), "Alpha alba"),
          "single-taxon compatibility identity")
    check(identical(lexical_tie$scientificName, "Alpha alba"),
          "radix-lexical taxon wins a true cross-taxon tie")
    state_is(lexical_tie, "compat_left_censored", "compat_censor_state",
             "cross-taxon tied left censor remains conservative")
    numeric_is(lexical_tie, 20, "compat_interval_days",
               "cross-taxon tie preserves maximum width")
  })

  # 15. V2 cannot use v1 lexical behavior to settle a taxonomic conflict.
  obs <- rbind(
    make_obs(scientificName = "Alpha alba", status = "no"),
    make_obs(scientificName = "Beta beta", date = "2018-04-11",
             dayOfYear = 101, status = "yes")
  )
  inds <- roster_from_obs(obs[1L, , drop = FALSE])
  fixture(15, expect_error_code(
    adapt(env, obs, inds), "roster_taxonomy_conflict", "v2 taxonomy conflict"))

  # 16. Only the all-taxonomy-null unmatched exception is retained.
  obs <- make_obs(individualID = "UNKNOWN", scientificName = NA_character_,
                  growthForm = NA_character_, is_species = NA,
                  status = "yes")
  seed <- make_obs(individualID = "ROSTER", scientificName = "Alpha alba")
  inds <- roster_from_obs(seed)
  result <- adapt(env, obs, inds)
  fixture(16, {
    py <- require_table(result, "plant_years")
    state_is(py, "roster_unmatched_taxon_unknown", "taxonomy_state",
             "all-null unmatched taxonomy state")
    check(nrow(py) == 1L, "all-null unmatched opportunity retained")
    numeric_is(result$site_summary, 0, "app_greenup_coverage",
               "unmatched-only onset cannot enter roster coverage")
  })

  # 17. Any asserted taxonomy on an unmatched identity fails closed.
  obs <- make_obs(individualID = "UNKNOWN", scientificName = "Alpha alba",
                  growthForm = NA_character_, is_species = NA)
  fixture(17, expect_error_code(
    adapt(env, obs, inds), "unmatched_asserted_taxonomy", "asserting unmatched identity"))

  # 18. Historical plot movement is valid context and explicitly audited.
  obs <- phase_pair("P1", "Alpha alba", 2018L, 91L, 101L,
                    plot = "TEST_002")
  inds <- roster_from_obs(obs)
  inds$plotID <- "TEST_001"
  result <- adapt(env, obs, inds)
  fixture(18, {
    src <- require_table(result, "source_rows")
    mismatch <- src[[pick_col(src,
      c("plot_history_mismatch", "plot_roster_mismatch"),
      "plot-history mismatch flag")]]
    check(all(mismatch), "historical plot mismatch accepted and audited")
  })

  # 19. One exact visit cannot claim two nonblank plots.
  obs <- rbind(
    make_obs(plotID = "TEST_001", status = "yes"),
    make_obs(plotID = "TEST_002", status = "yes")
  )
  inds <- roster_from_obs(obs[1L, , drop = FALSE])
  fixture(19, expect_error_code(
    adapt(env, obs, inds), "conflicting_visit_plots", "visit plot conflict"))

  # 20. A resolved non-species rank is an opportunity but not a candidate.
  obs <- make_obs(is_species = FALSE)
  inds <- roster_from_obs(obs)
  result <- adapt(env, obs, inds)
  fixture(20, {
    py <- require_table(result, "plant_years")
    state_is(py, "taxon_rank_ineligible", "taxonomy_state",
             "non-species taxonomy state")
    check(nrow(require_table(result, "model_rows")) == 0L,
          "non-species row excluded from likelihood")
  })
}

all_left_panel <- function(years = 2018:2020, species = "Alpha alba", n = 3L) {
  rows <- list()
  at <- 0L
  for (sp in species) for (yr in years) for (i in seq_len(n)) {
    at <- at + 1L
    rows[[at]] <- left_visit(
      sprintf("%s_%04d_%02d", substr(sp, 1L, 1L), yr, i), sp, yr,
      100L + (yr - min(years)) + i)
  }
  do.call(rbind, rows)
}

anchored_panel <- function(years = 2018:2020, species = "Alpha alba", n = 3L) {
  rows <- list()
  at <- 0L
  for (sp in species) for (yr in years) for (i in seq_len(n)) {
    at <- at + 1L
    id <- sprintf("%s_%04d_%02d", substr(sp, 1L, 1L), yr, i)
    yes <- 100L + (yr - min(years)) + match(sp, species) + i
    rows[[at]] <- if (i == 1L) phase_pair(id, sp, yr, yes - 7L, yes) else
      left_visit(id, sp, yr, yes)
  }
  do.call(rbind, rows)
}

constant_panel <- function(years = 2018:2020,
                           counts = c("Alpha alba" = 3L, "Beta beta" = 3L)) {
  rows <- list()
  at <- 0L
  for (sp in names(counts)) for (yr in years) for (i in seq_len(counts[[sp]])) {
    at <- at + 1L
    onset <- 90L + 10L * match(sp, names(counts)) + (yr - min(years))
    rows[[at]] <- phase_pair(
      sprintf("%s_%04d_%02d", substr(sp, 1L, 1L), yr, i), sp, yr,
      onset - 10L, onset)
  }
  do.call(rbind, rows)
}

make_fit_rows <- function(site = "TEST", years = 2018:2023,
                          species = c("Alpha alba", "Beta beta"),
                          individuals = 1:3, full_grid = TRUE) {
  rows <- expand.grid(
    scientificName = species, year = as.integer(years), individual = individuals,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  if (!isTRUE(full_grid)) {
    half <- ceiling(length(years) / 2)
    rows <- rows[
      (rows$scientificName %in% species[seq_len(length(species) / 2)] &
         rows$year %in% years[seq_len(half)]) |
        (rows$scientificName %in% species[-seq_len(length(species) / 2)] &
           rows$year %in% years[-seq_len(half)]), , drop = FALSE]
  }
  species_index <- match(rows$scientificName, species)
  rows$site <- site
  rows$individualID <- sprintf("%s_%02d", substr(rows$scientificName, 1L, 1L),
                               rows$individual)
  rows$lower_doy <- 80 + 8 * species_index + (rows$year - min(years)) + rows$individual
  rows$upper_doy <- rows$lower_doy + 8
  rows$annual_response_supported <- TRUE
  rows <- rows[, c("site", "individualID", "scientificName", "year",
                   "lower_doy", "upper_doy", "annual_response_supported")]
  rownames(rows) <- NULL
  rows
}

adapter_panel_obs <- function(rows = make_fit_rows()) {
  pieces <- lapply(seq_len(nrow(rows)), function(i) {
    phase_pair(
      rows$individualID[[i]], rows$scientificName[[i]], rows$year[[i]],
      rows$lower_doy[[i]], rows$upper_doy[[i]])
  })
  do.call(rbind, pieces)
}

# Test-owned numerical oracle for the exact registered response fit.  This code
# deliberately does not call a production weight, canonicalization, fit, or
# prediction helper.
test_owned_interval_oracle <- function(rows) {
  species_levels <- sort(unique(enc2utf8(rows$scientificName)), method = "radix")
  year_levels <- sort(unique(as.integer(rows$year)))
  x <- rows
  x$scientificName <- factor(enc2utf8(x$scientificName), levels = species_levels)
  x$year <- as.integer(x$year)
  x <- x[order(x$scientificName, x$year, enc2utf8(x$individualID),
               x$lower_doy, x$upper_doy, method = "radix", na.last = TRUE),
         , drop = FALSE]
  rownames(x) <- NULL

  cell <- paste(as.character(x$scientificName), x$year, sep = "\r")
  n_rows <- nrow(x)
  n_cells <- length(unique(cell))
  n_in_cell <- as.numeric(table(cell)[cell])
  model_weight <- n_rows / (n_cells * n_in_cell)
  individualID <- x$individualID
  fit <- survival::survreg(
    survival::Surv(lower_doy, upper_doy, type = "interval2") ~
      scientificName + factor(year),
    data = x,
    dist = "gaussian",
    weights = model_weight,
    robust = TRUE,
    cluster = individualID,
    na.action = stats::na.fail,
    control = survival::survreg.control(
      maxiter = 30L,
      rel.tolerance = 1e-9,
      toler.chol = 1e-10,
      outer.max = 10L
    ),
    model = TRUE, x = TRUE, y = TRUE
  )
  grid <- expand.grid(
    scientificName = species_levels,
    year = year_levels,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$scientificName <- factor(grid$scientificName, levels = species_levels)
  grid$year <- as.integer(grid$year)
  grid <- grid[order(grid$year, grid$scientificName, method = "radix"),
               , drop = FALSE]
  prediction <- as.numeric(stats::predict(fit, newdata = grid, type = "lp"))
  annual <- vapply(split(prediction, grid$year), stats::median, numeric(1L))
  prediction_grid <- data.frame(
    scientificName = as.character(grid$scientificName),
    year = as.integer(grid$year),
    lp_doy = unname(prediction),
    stringsAsFactors = FALSE)
  list(
    fit = fit,
    model_rows = x,
    model_weight = unname(model_weight),
    prediction_grid = prediction_grid,
    annual = data.frame(
      year = as.integer(names(annual)),
      greenup_doy_interval_std = unname(annual),
      stringsAsFactors = FALSE
    )
  )
}

weight_vector <- function(x) {
  if (is.numeric(x) && is.null(dim(x))) return(as.numeric(x))
  if (is.data.frame(x) && "model_weight" %in% names(x))
    return(as.numeric(x$model_weight))
  if (is.list(x) && !is.null(x$model_weight)) return(as.numeric(x$model_weight))
  fail("equal-cell weight API", "expected a numeric vector or model_weight field")
}

fit_annual <- function(x) {
  if (!is.list(x) || !is.data.frame(x$annual_response))
    fail("response fit API", "missing annual_response data frame")
  x$annual_response
}

canonical_model_values <- function(x) {
  out <- data.frame(
    site = as.character(x$site),
    individualID = as.character(x$individualID),
    scientificName = as.character(x$scientificName),
    year = as.integer(x$year),
    lower_doy = as.numeric(x$lower_doy),
    upper_doy = as.numeric(x$upper_doy),
    annual_response_supported = as.logical(x$annual_response_supported),
    stringsAsFactors = FALSE
  )
  out <- out[order(out$site, out$scientificName, out$year,
                   out$individualID, method = "radix"), , drop = FALSE]
  rownames(out) <- NULL
  out
}

same_model_values <- function(x, y)
  identical(canonical_model_values(x), canonical_model_values(y))

run_adapter_support_fixtures <- function(env) {
  # 21. Cell support requires three distinct timing individuals and one anchor.
  two <- adapt(env, panel_obs(2018:2020, "Alpha alba", 2L))
  unanchored <- adapt(env, all_left_panel())
  anchored <- adapt(env, anchored_panel())
  fixture(21, {
    check(all(two$plant_years$v2_eligibility_state == "species_year_excluded"),
          "two-individual cells excluded")
    check(all(unanchored$plant_years$v2_eligibility_state ==
                "species_year_excluded"),
          "three left-censored rows without bounded anchor excluded")
    check(nrow(anchored$model_rows) == 9L &&
            all(anchored$plant_years$v2_eligibility_state == "model_row"),
          "three-individual anchored recurrent cells retained")
  })

  # 22. The annual response boundary is two retained species and six plants.
  supported <- adapt(env, anchored_panel(2018:2023,
                                         c("Alpha alba", "Beta beta"), 3L))
  one_species <- adapt(env, anchored_panel(2018:2023, "Alpha alba", 3L))
  fixture(22, {
    row <- one_row(supported$annual_support, list(year = 2018L),
                   "six-individual annual row")
    state_is(row, "supported", "v2_annual_response_state",
             "two species/six individuals supported")
    check(row$v2_n_model_species == 2L && row$v2_n_model_individuals == 6L,
          "annual support exact count boundary")
    row <- one_row(one_species$annual_support, list(year = 2018L),
                   "one-species annual row")
    state_is(row, "insufficient_observed_species", "v2_annual_response_state",
             "one observed species abstains")
  })

  # 23. Two eligible years are not recurrence; three are.
  obs <- rbind(
    anchored_panel(2018:2019, "Alpha alba", 3L),
    anchored_panel(2018:2020, "Beta beta", 3L)
  )
  result <- adapt(env, obs)
  fixture(23, {
    alpha <- result$plant_years$scientificName == "Alpha alba"
    beta <- result$plant_years$scientificName == "Beta beta"
    check(all(result$plant_years$v2_eligibility_state[alpha] ==
                "recurrence_excluded"), "two-year species excluded by recurrence")
    check(all(result$plant_years$v2_eligibility_state[beta] == "model_row"),
          "three-year species satisfies recurrence")
  })

  # 24. Exercise all three component-ranking keys directly on synthetic cells.
  select_component <- get("phenology_v2_select_component", envir = env,
                          inherits = FALSE)
  component_cells <- function(species, years) {
    do.call(rbind, Map(function(sp, yr) data.frame(
      scientificName = sp, year = as.integer(yr), stringsAsFactors = FALSE),
      species, years))
  }
  many_species <- rbind(
    expand.grid(scientificName = c("Alpha", "Beta"), year = 2018:2020,
                stringsAsFactors = FALSE),
    expand.grid(scientificName = c("Gamma", "Delta", "Epsilon"),
                year = 2021:2023, stringsAsFactors = FALSE)
  )
  many_cells <- rbind(
    expand.grid(scientificName = c("Alpha", "Beta"), year = 2018:2020,
                stringsAsFactors = FALSE),
    expand.grid(scientificName = c("Gamma", "Delta"), year = 2021:2023,
                stringsAsFactors = FALSE),
    data.frame(scientificName = "Gamma", year = 2024L)
  )
  lexical <- rbind(
    expand.grid(scientificName = c("Alpha", "Beta"), year = 2018:2020,
                stringsAsFactors = FALSE),
    expand.grid(scientificName = c("Gamma", "Delta"), year = 2021:2023,
                stringsAsFactors = FALSE)
  )
  a <- select_component(many_species)
  b <- select_component(many_cells)
  c <- select_component(lexical)
  fixture(24, {
    check(setequal(unique(a$scientificName[a$selected]),
                   c("Delta", "Epsilon", "Gamma")),
          "component tie-break 1 greatest species count")
    check(setequal(unique(b$scientificName[b$selected]), c("Delta", "Gamma")),
          "component tie-break 2 greatest cell count")
    check(setequal(unique(c$scientificName[c$selected]), c("Alpha", "Beta")),
          "component tie-break 3 lexical species")
  })

  # 25. Unequal abundance cannot change equal-species compatibility output.
  balanced <- adapt(env, constant_panel())
  abundant <- adapt(env, constant_panel(
    counts = c("Alpha alba" = 9L, "Beta beta" = 3L)))
  fixture(25, {
    b <- balanced$compatibility_annual
    a <- abundant$compatibility_annual
    keep <- is.finite(b$greenup_doy_compat)
    source_support <- !is.na(b$compat_n_onsets)
    check(identical(keep, is.finite(a$greenup_doy_compat)),
          "abundance shift preserves compatibility support keys")
    check_near(a$greenup_doy_compat[keep], b$greenup_doy_compat[keep],
               "equal-species index resists abundance shift", 1e-15)
    check(identical(is.finite(b$compat_reference_doy), source_support) &&
            sum(source_support) == 3L,
          "compatibility reference is finite only on source-support years")
  })

  # 26. Independent equal-cell weight oracle and exact tolerances.
  rows <- make_fit_rows()
  extra <- rows[rows$scientificName == "Alpha alba" & rows$year == 2018L, , drop = FALSE]
  extra$individualID <- paste0(extra$individualID, "_extra")
  rows <- rbind(rows, extra)
  weights <- weight_vector(call_api(env, required_api[["weight"]], rows))
  cell <- paste(rows$scientificName, rows$year, sep = "|")
  n <- nrow(rows)
  cells <- unique(cell)
  expected <- n / (length(cells) * as.numeric(table(cell)[cell]))
  fixture(26, {
    check_near(weights, expected, "registered equal-cell formula", 1e-15)
    tol <- 1e-12 * max(1, n)
    check(all(weights > 0), "model weights positive")
    check(abs(sum(weights) - n) <= tol, "model weight sum equals N")
    check(abs(mean(weights) - 1) <= 1e-12, "model weight mean equals one")
    totals <- tapply(weights, cell, sum)
    check(all(abs(totals - n / length(cells)) <= tol),
          "each species-year cell has equal total weight")
  })

  # 27. Stable individuals repeat across years; plot is absent from the design.
  rows <- make_fit_rows()
  fit <- call_api(env, required_api[["response"]], rows)
  fixture(27, {
    check(anyDuplicated(rows$individualID) > 0L,
          "response fixture contains repeated individual clusters")
    model <- if (is.list(fit) && inherits(fit$fit, "survreg")) fit$fit else NULL
    check(!is.null(model), "response fit object retained for synthetic audit")
    check(!any(grepl("plot", colnames(model$x), ignore.case = TRUE)),
          "plot absent from primary model design")
    check(is.matrix(model$naive.var) && is.matrix(model$var) &&
            fit$diagnostics$n_clusters == length(unique(rows$individualID)),
          "repeated individuals produce clustered robust covariance")
  })

  # 28. A disconnected fixed-effect design fails rank; a full grid fits.
  deficient <- make_fit_rows(
    species = c("Alpha", "Beta", "Gamma", "Delta"), full_grid = FALSE)
  compatibility_annual_builder <- get(
    "phenology_v2_compatibility_annual", envir = env, inherits = FALSE)
  deficient_compatibility_panel <- list(
    cells = data.frame(
      scientificName = c(rep("Alpha alba", 3L), rep("Beta beta", 3L)),
      year = c(2018:2020, 2021:2023),
      species_onset = c(90:92, 110:112),
      selected = TRUE,
      stringsAsFactors = FALSE
    ),
    contributors = balanced$plant_years[0, , drop = FALSE],
    species_reference = c("Alpha alba" = 91, "Beta beta" = 111)
  )
  fixture(28, {
    expect_error_code(
      call_api(env, required_api[["response"]], deficient),
      "response_rank_deficient", "rank-deficient interval design")
    check(nrow(fit_annual(fit)) == 6L, "full-rank design emits six years")
    expect_error_code(
      compatibility_annual_builder(
        balanced$plant_years, deficient_compatibility_panel),
      "compatibility_rank_failure", "rank-deficient compatibility design")
    compat <- balanced$compatibility_annual
    check(identical(is.finite(compat$greenup_doy_compat),
                    is.finite(compat$greenup_doy_additive_compat)) &&
            sum(is.finite(compat$greenup_doy_additive_compat)) == 3L,
          "full-rank compatibility design emits the same finite keys")
  })

  # 29. Failure gates are named, while coding and input order are invariant.
  reversed <- rows[nrow(rows):1L, , drop = FALSE]
  refit <- call_api(env, required_api[["response"]], reversed)
  canonicalize <- get(".phenology_v2_canonical_model_rows", envir = env,
                      inherits = FALSE)
  canonical_rows <- canonicalize(reversed)
  response_source <- paste(
    deparse(body(get(required_api[["response"]], env))),
    deparse(body(get(".phenology_v2_fit_once", env))),
    collapse = " ")
  required_failure_codes <- c(
    "response_fit_warning", "response_nonconvergence",
    "response_covariance_invalid", "response_prediction_invalid"
  )
  oracle_rows <- make_fit_rows()
  influential <- oracle_rows[
    oracle_rows$scientificName == "Alpha alba" & oracle_rows$year == 2018L,
    , drop = FALSE]
  influential$individualID <- paste0(influential$individualID, "_influential")
  influential$lower_doy <- c(135, 140, 145)
  influential$upper_doy <- influential$lower_doy + 8
  oracle_rows <- rbind(oracle_rows, influential)
  numerical_oracle <- test_owned_interval_oracle(oracle_rows)
  execution <- new.env(parent = emptyenv())
  execution$arguments <- list()
  execution$predictions <- list()
  original_survreg <- get(".phenology_v2_survreg", envir = env,
                          inherits = FALSE)
  original_prediction <- get(".phenology_v2_predict", envir = env,
                             inherits = FALSE)
  capture_survreg <- function(formula, data, dist, weights, robust, cluster,
                              na.action, control, model, x, y) {
    execution$arguments[[length(execution$arguments) + 1L]] <- list(
      formula = formula, data = data, dist = dist,
      weights = unname(as.numeric(weights)), robust = robust,
      cluster = as.character(cluster), na.action = na.action,
      control = control, model = model, x = x, y = y)
    original_survreg(
      formula = formula, data = data, dist = dist, weights = weights,
      robust = robust, cluster = cluster, na.action = na.action,
      control = control, model = model, x = x, y = y)
  }
  capture_prediction <- function(object, ...) {
    dots <- list(...)
    value <- original_prediction(object, ...)
    execution$predictions[[length(execution$predictions) + 1L]] <- list(
      newdata = dots$newdata, type = dots$type,
      value = unname(as.numeric(value)))
    value
  }
  with_replaced_binding(
    env, ".phenology_v2_survreg", capture_survreg,
    with_replaced_binding(
      env, ".phenology_v2_predict", capture_prediction,
      execution$fit <- call_api(env, required_api[["response"]], oracle_rows)))
  production_oracle_fit <- execution$fit
  production_prediction_grids <- lapply(execution$predictions, function(x)
    data.frame(
      scientificName = as.character(x$newdata$scientificName),
      year = as.integer(x$newdata$year),
      lp_doy = x$value,
      stringsAsFactors = FALSE))
  fixture(29, {
    check(all(vapply(required_failure_codes, grepl, logical(1L),
                     x = response_source, fixed = TRUE)),
          "registered fit-failure codes are executable branches")
    check(same_canonical(fit_annual(fit), fit_annual(refit)),
          "response is invariant to input row order")
    check_identical(levels(canonical_rows$scientificName),
                    sort(unique(rows$scientificName), method = "radix"),
                    "factor reference coding is radix-frozen internally")
    factor_input <- reversed
    factor_input$scientificName <- factor(
      factor_input$scientificName,
      levels = rev(sort(unique(factor_input$scientificName), method = "radix")))
    expect_error_code(call_api(env, required_api[["response"]], factor_input),
                      "model_rows_key",
                      "caller-supplied factor reference coding rejected")
    annual <- fit_annual(fit)
    response <- annual[[pick_col(annual, "greenup_doy_interval_std")]]
    check(all(is.finite(response) & response >= 1 & response <= 366),
          "all synthetic annual predictions inside 1-366")

    check(length(execution$arguments) == 2L,
          "determinism gate executes the registered model exactly twice")
    executed <- execution$arguments[[1L]]
    repeated_execution <- execution$arguments[[2L]]
    formula_text <- gsub(
      "[[:space:]]+", "",
      paste(deparse(executed$formula), collapse = ""))
    expected_formula <- gsub(
      "[[:space:]]+", "",
      paste(deparse(quote(
        survival::Surv(lower_doy, upper_doy, type = "interval2") ~
          scientificName + factor(year))), collapse = ""))
    control <- executed$control
    check(identical(formula_text, expected_formula) &&
            identical(executed$dist, "gaussian") &&
            identical(executed$robust, TRUE) &&
            identical(executed$na.action, stats::na.fail) &&
            identical(executed$model, TRUE) &&
            identical(executed$x, TRUE) &&
            identical(executed$y, TRUE) &&
            is.list(control) && identical(control$maxiter, 30L) &&
            identical(control$rel.tolerance, 1e-9) &&
            identical(control$toler.chol, 1e-10) &&
            identical(control$outer.max, 10L),
          "exact frozen survreg formula, arguments, and controls")
    production_rows <- production_oracle_fit$model_rows
    oracle_keys <- paste(
      as.character(numerical_oracle$model_rows$scientificName),
      numerical_oracle$model_rows$year,
      numerical_oracle$model_rows$individualID, sep = "|")
    production_keys <- paste(
      production_rows$scientificName, production_rows$year,
      production_rows$individualID, sep = "|")
    check_identical(production_keys, oracle_keys,
                    "production and oracle canonical model-row keys")
    check_near(production_rows$model_weight,
               numerical_oracle$model_weight,
               "fitted model consumes test-owned equal-cell weights", 1e-15)
    check_near(executed$weights,
               numerical_oracle$model_weight,
               "executed survreg receives registered model weights", 1e-15)
    check_identical(executed$cluster,
                    numerical_oracle$model_rows$individualID,
                    "executed survreg receives stable individual clusters")
    check(identical(executed$weights, repeated_execution$weights) &&
            identical(executed$cluster, repeated_execution$cluster) &&
            identical(executed$control, repeated_execution$control),
          "both determinism fits execute identical weights, clusters, and controls")
    check(length(execution$predictions) == 2L &&
            all(vapply(execution$predictions, function(x)
              identical(x$type, "lp"), logical(1L))),
          "determinism gate executes two full-grid LP predictions")
    check_identical(production_prediction_grids[[1L]],
                    production_prediction_grids[[2L]],
                    "two production full-grid LP vectors are exactly identical")
    production_grid <- production_prediction_grids[[1L]]
    oracle_grid <- numerical_oracle$prediction_grid
    check_identical(
      production_grid[c("scientificName", "year")],
      oracle_grid[c("scientificName", "year")],
      "production and oracle full-grid keys")
    prediction_tolerance <- 1e-8 + 1e-8 * numerical_oracle$fit$scale
    check_near(production_grid$lp_doy, oracle_grid$lp_doy,
               "every production LP agrees with the test-owned oracle",
               prediction_tolerance)
    production_annual <- production_oracle_fit$annual_response
    oracle_match <- match(production_annual$year,
                          numerical_oracle$annual$year)
    check(!anyNA(oracle_match) && all(
      abs(production_annual$greenup_doy_interval_std -
            numerical_oracle$annual$greenup_doy_interval_std[oracle_match]) <=
        prediction_tolerance),
      "production annual response agrees with test-owned numerical oracle",
      sprintf("tolerance %.3g", prediction_tolerance))

    with_replaced_binding(
      env,
      ".phenology_v2_survreg",
      function(formula, data, dist, weights, robust, cluster, na.action,
               control, model, x, y) {
        warning("synthetic fit warning")
        fit$fit
      },
      expect_error_code(call_api(env, required_api[["response"]], rows),
                        "response_fit_warning", "fit warning fails closed"))
    with_replaced_binding(
      env,
      ".phenology_v2_survreg",
      function(formula, data, dist, weights, robust, cluster, na.action,
               control, model, x, y) {
        value <- fit$fit
        value$fail <- "synthetic nonconvergence"
        value
      },
      expect_error_code(call_api(env, required_api[["response"]], rows),
                        "response_nonconvergence",
                        "nonconvergence fails closed"))
    with_replaced_binding(
      env,
      ".phenology_v2_survreg",
      function(formula, data, dist, weights, robust, cluster, na.action,
               control, model, x, y) {
        value <- fit$fit
        value$var[[1L]] <- NA_real_
        value
      },
      expect_error_code(call_api(env, required_api[["response"]], rows),
                        "response_covariance_invalid",
                        "invalid robust covariance fails closed"))
    with_replaced_binding(
      env,
      ".phenology_v2_predict",
      function(object, ...) {
        dots <- list(...)
        rep(400, nrow(dots$newdata))
      },
      expect_error_code(call_api(env, required_api[["response"]], rows),
                        "response_prediction_invalid",
                        "out-of-range prediction fails closed"))
    prediction_counter <- 0L
    original_predict <- get(".phenology_v2_predict", envir = env,
                            inherits = FALSE)
    with_replaced_binding(
      env,
      ".phenology_v2_predict",
      function(object, ...) {
        prediction_counter <<- prediction_counter + 1L
        original_predict(object, ...) + prediction_counter * 1e-8
      },
      expect_error_code(call_api(env, required_api[["response"]], rows),
                        "response_nondeterministic",
                        "two-fit nondeterminism fails closed"))

    presence <- call_api(env, required_api[["presence"]], fit)
    check_identical(names(presence),
                    c("site", "year", "response_fit_eligible",
                      "response_present"),
                    "values-free response-presence schema")
    check(!any(vapply(presence, is.double, logical(1L))),
          "response-presence mask contains no numeric response")
    too_few_present <- fit_annual(fit)
    too_few_present$greenup_doy_interval_std[[1L]] <- NA_real_
    too_few_present$annual_response_supported[[1L]] <- FALSE
    too_few_present$response_present[[1L]] <- FALSE
    too_few_present$response_fit_eligible <- TRUE
    expect_error_code(
      call_api(env, required_api[["presence"]], too_few_present),
      "response_presence_schema",
      "eligible response mask requires at least six present years")
    false_eligibility <- fit_annual(fit)
    false_eligibility$response_fit_eligible <- FALSE
    expect_error_code(
      call_api(env, required_api[["presence"]], false_eligibility),
      "response_presence_schema",
      "ineligible response mask cannot contain a present year")
    diagnostic_disagreement <- fit
    diagnostic_disagreement$annual_response$response_fit_eligible <- FALSE
    expect_error_code(
      call_api(env, required_api[["presence"]], diagnostic_disagreement),
      "response_presence_schema",
      "annual and diagnostic eligibility must agree")
    malformed_annual_eligibility <- fit
    malformed_annual_eligibility$annual_response$response_fit_eligible <- "TRUE"
    expect_error_code(
      call_api(env, required_api[["presence"]], malformed_annual_eligibility),
      "response_presence_schema",
      "annual eligibility type is checked even with diagnostics")
  })

  # 30. Empty contributors retain typed annual abstentions without warnings.
  empty_result <- capture_warnings(adapt(
    env, make_obs(phenophaseName = "Leaves", status = "no")))
  fixture(30, {
    check(!length(empty_result$warnings), "empty contributors emit no warning")
    annual <- empty_result$value$annual_support
    check(is.integer(annual$v2_n_model_individuals) &&
            is.character(annual$v2_annual_response_state) &&
            is.logical(annual$annual_response_supported),
          "empty annual support fields retain declared types")
    check(all(annual$v2_annual_response_state == "no_retained_panel") &&
            !any(annual$annual_response_supported),
          "empty annual support is explicit abstention")
    typed_na_fields <- c(
      "v2_interval_median_days", "v2_interval_p90_days",
      "v2_interval_max_days", "left_censored_share", "exclusion_share")
    check(all(vapply(annual[typed_na_fields], function(x)
      is.numeric(x) && all(is.na(x)), logical(1L))),
      "zero-denominator v2 support fields are typed NA, never zero")
    compat <- empty_result$value$compatibility_annual
    compat_na_fields <- c(
      "greenup_doy_compat", "greenup_doy_additive_compat",
      "compat_n_onsets", "compat_n_left_censored",
      "compat_n_excluded_umbrella", "compat_n_individuals",
      "compat_n_species", "compat_reference_doy",
      "compat_interval_median_days", "compat_interval_p90_days",
      "compat_interval_max_days")
    check(all(vapply(compat[compat_na_fields], function(x)
      (is.numeric(x) || is.integer(x)) && all(is.na(x)), logical(1L))),
      "empty compatibility support fields are typed NA, never zero")
    empty_rows <- make_fit_rows()[0, , drop = FALSE]
    empty_weights <- weight_vector(call_api(env, required_api[["weight"]], empty_rows))
    check(is.numeric(empty_weights) && !length(empty_weights),
          "empty weight surface is typed numeric(0)")
  })

  # 31. Day 1/2 share a week; days 8 and 100 add two more weeks.
  days <- c(1L, 2L, 8L, 100L)
  dates <- as.Date("2018-01-01") + days - 1L
  result <- adapt(env, make_obs(
    date = format(dates, "%Y-%m-%d"), dayOfYear = days,
    phenophaseName = "Leaves", status = "yes"))
  fixture(31, numeric_is(result$leaf_active, 21, "leaf_active_days_7d",
                         "leaf days 1,2,8,100 produce 21"))

  # 32. Week 53 is not clipped; all 53 distinct bins produce 371 days.
  days <- c(seq.int(1L, 365L, by = 7L), 366L)
  dates <- as.Date("2020-01-01") + days - 1L
  result <- adapt(env, make_obs(
    year = 2020L, date = format(dates, "%Y-%m-%d"), dayOfYear = days,
    phenophaseName = "Leaves", status = "yes"))
  fixture(32, numeric_is(result$leaf_active, 371, "leaf_active_days_7d",
                         "week 53 remains uncapped"))

  # 33. Observed no/uncertain leaf rows do not imply zero active days.
  obs <- rbind(
    make_obs(phenophaseName = "Leaves", status = "no"),
    make_obs(date = "2018-04-08", dayOfYear = 98,
             phenophaseName = "Leaves", status = "uncertain")
  )
  result <- adapt(env, obs)
  leaf_conflict <- adapt(env, make_obs(
    phenophaseName = "Leaves", status = c("no", "yes")))
  fixture(33, {
    py <- result$plant_years
    check(is.na(py$leaf_active_days_7d[[1L]]),
          "leaf no/uncertain remains missing, never zero")
    check(nrow(result$leaf_active) == 0L,
          "no positive leaf contributor row emitted")
    conflict_year <- one_row(
      leaf_conflict$annual_support, list(year = 2018L),
      "non-target leaf conflict audit row")
    check(conflict_year$v2_n_conflicting_visits == 0L,
          "non-target Leaves conflicts do not enter target-phase conflict counts")
  })

  # 34. Separated positive weeks remain additive across flushes.
  days <- c(10L, 80L, 220L)
  dates <- as.Date("2018-01-01") + days - 1L
  result <- adapt(env, make_obs(
    date = format(dates, "%Y-%m-%d"), dayOfYear = days,
    phenophaseName = "Leaves", status = "yes"))
  fixture(34, numeric_is(result$leaf_active, 21, "leaf_active_days_7d",
                         "multi-flush weeks remain additive"))

  # 35. Coverage changes only the preselected leaf context stratum.  The
  # response panel is fully bounded so this adapter-to-response boundary remains
  # numerically stable even on the oldest supported survival runtime.
  coverage_target <- adapter_panel_obs()
  leaf_keys <- coverage_target[
    !duplicated(coverage_target$individualID) & coverage_target$year == 2018L,
    , drop = FALSE]
  leaf_keys <- rbind(
    head(leaf_keys[leaf_keys$scientificName == "Alpha alba", , drop = FALSE], 2L),
    head(leaf_keys[leaf_keys$scientificName == "Beta beta", , drop = FALSE], 3L)
  )
  leaf_obs <- make_obs(
    individualID = leaf_keys$individualID,
    plotID = leaf_keys$plotID,
    scientificName = leaf_keys$scientificName,
    growthForm = leaf_keys$growthForm,
    year = 2018L,
    date = "2018-06-01",
    dayOfYear = 152L,
    phenophaseName = "Leaves",
    status = "yes",
    is_species = TRUE
  )
  coverage_obs_known <- rbind(coverage_target, leaf_obs)
  observed_roster <- roster_from_obs(coverage_obs_known)
  unknown_leaf <- make_obs(
    individualID = "UNMATCHED_LEAF",
    scientificName = "   ", growthForm = "   ",
    year = 2018L, date = "2018-06-08", dayOfYear = 159L,
    phenophaseName = "Leaves", status = "yes", is_species = NA
  )
  coverage_obs <- rbind(coverage_obs_known, unknown_leaf)
  n_observed_plants <- nrow(observed_roster)
  make_coverage_roster <- function(total) {
    stopifnot(total >= n_observed_plants)
    extra_n <- total - n_observed_plants
    if (!extra_n) return(observed_roster)
    extra <- roster_from_obs(make_obs(
      individualID = sprintf("ROSTER_ONLY_%03d", seq_len(extra_n)),
      scientificName = sprintf("Roster species %03d", seq_len(extra_n))))
    rbind(observed_roster, extra)
  }
  below_total <- 2L * n_observed_plants + 1L
  at_total <- 2L * n_observed_plants
  above_total <- 2L * n_observed_plants - 1L
  below <- adapt(env, coverage_obs, make_coverage_roster(below_total))
  at <- adapt(env, coverage_obs, make_coverage_roster(at_total))
  above <- adapt(env, coverage_obs, make_coverage_roster(above_total))
  reversed_below_roster <- make_coverage_roster(below_total)
  reversed_below <- adapt(
    env, coverage_obs[nrow(coverage_obs):1L, , drop = FALSE],
    reversed_below_roster[nrow(reversed_below_roster):1L, , drop = FALSE])
  fixture(35, {
    check_near(c(below$site_summary$app_greenup_coverage,
                 at$site_summary$app_greenup_coverage,
                 above$site_summary$app_greenup_coverage),
               n_observed_plants / c(below_total, at_total, above_total),
               "coverage values around one-half", 1e-15)
    check_identical(c(below$site_summary$thin_greenup,
                      at$site_summary$thin_greenup,
                      above$site_summary$thin_greenup),
                    c(TRUE, FALSE, FALSE),
                    "coverage threshold is strict below 0.50")
    check(same_canonical(below$plant_years, at$plant_years) &&
            same_canonical(at$plant_years, above$plant_years),
          "coverage stratum does not rewrite primary ledger")
    check(same_canonical(below$model_rows, at$model_rows) &&
            same_canonical(at$model_rows, above$model_rows) &&
            same_canonical(below$annual_support, at$annual_support) &&
            same_canonical(at$annual_support, above$annual_support),
          "coverage stratum does not alter model rows or annual support")
    primary_summary <- c(
      "response_fit_eligible", "annual_response_supported_years",
      "compatibility_finite_years", "compatibility_site_screen")
    check(all(unlist(below$site_summary[primary_summary]) ==
                unlist(at$site_summary[primary_summary])) &&
            all(unlist(at$site_summary[primary_summary]) ==
                  unlist(above$site_summary[primary_summary])) &&
            isTRUE(below$site_summary$response_fit_eligible),
          "coverage changes no primary or compatibility eligibility")
    expected_leaf_schema <- c(
      "site", "scientificName", "year", "n_positive_individuals",
      "thin_greenup", "leaf_active_supported")
    check_identical(names(below$leaf_active_support), expected_leaf_schema,
                    "values-free leaf-active support schema")
    below_alpha <- one_row(
      below$leaf_active_support,
      list(scientificName = "Alpha alba", year = 2018L),
      "two-positive leaf support row")
    below_beta <- one_row(
      below$leaf_active_support,
      list(scientificName = "Beta beta", year = 2018L),
      "three-positive leaf support row")
    check(below_alpha$n_positive_individuals == 2L &&
            !below_alpha$leaf_active_supported &&
            below_beta$n_positive_individuals == 3L &&
            below_beta$leaf_active_supported,
          "leaf-active support boundary is exactly three positive individuals")
    all_leaf_support <- rbind(
      transform(below$leaf_active_support, coverage = "below"),
      transform(at$leaf_active_support, coverage = "at"),
      transform(above$leaf_active_support, coverage = "above"))
    check(identical(unique(below$leaf_active_support$thin_greenup), TRUE) &&
            identical(unique(at$leaf_active_support$thin_greenup), FALSE) &&
            identical(unique(above$leaf_active_support$thin_greenup), FALSE) &&
            all(all_leaf_support$leaf_active_supported ==
                  (all_leaf_support$thin_greenup &
                     all_leaf_support$n_positive_individuals >= 3L)),
          "leaf-active context is enabled only below 0.50 coverage")
    check(any(!nzchar(trimws(below$leaf_active$scientificName))) &&
            all(nzchar(trimws(below$leaf_active_support$scientificName))),
          "blank-name leaf audit rows are omitted from support context")
    check(identical(below$leaf_active, reversed_below$leaf_active) &&
            identical(below$leaf_active_support,
                      reversed_below$leaf_active_support),
          "leaf-active audit and support are invariant to input row order")
    coverage_fits <- lapply(
      list(below, at, above),
      function(x) call_api(env, required_api[["response"]], x$model_rows))
    coverage_presence <- lapply(
      coverage_fits,
      function(x) call_api(env, required_api[["presence"]], x))
    check(same_canonical(fit_annual(coverage_fits[[1L]]),
                         fit_annual(coverage_fits[[2L]])) &&
            same_canonical(fit_annual(coverage_fits[[2L]]),
                           fit_annual(coverage_fits[[3L]])) &&
            same_canonical(coverage_presence[[1L]], coverage_presence[[2L]]) &&
            same_canonical(coverage_presence[[2L]], coverage_presence[[3L]]),
          "coverage stratum changes neither response values nor presence mask")
  })

  # 36. Exactly six supported years unlock fitting; five do not.
  five <- make_fit_rows(years = 2018:2022)
  six <- make_fit_rows(years = 2018:2023)
  partial_adapter <- adapt(env, adapter_panel_obs(five))
  fixture(36, {
    off_panel <- one_row(
      partial_adapter$annual_support, list(year = 2023L),
      "partially supported site off-panel year")
    check(off_panel$v2_n_model_individuals == 0L &&
            identical(off_panel$v2_annual_response_state, "no_retained_panel") &&
            !off_panel$annual_response_supported,
          "off-panel year is no-retained-panel inside a partially supported site")
    expect_error_code(call_api(env, required_api[["response"]], five),
                      "response_fit_ineligible", "five-year fit boundary")
    sites <- list(
      TESTA = transform(six, site = "TESTA"),
      TESTB = transform(six, site = "TESTB")
    )
    attempts <- 0L
    fits <- lapply(sites, function(x) {
      attempts <<- attempts + 1L
      call_api(env, required_api[["response"]], x)
    })
    check(attempts == length(sites) && all(vapply(
      fits, function(x) nrow(fit_annual(x)) == 6L, logical(1L))),
      "all response-fit-eligible sites attempted")
  })
  list(
    model_rows = production_oracle_fit$model_rows,
    prediction_grid = production_prediction_grids[[1L]],
    annual_response = production_oracle_fit$annual_response,
    diagnostics = production_oracle_fit$diagnostics)
}

monthly_env <- function(site = "TEST", years = 2018:2023,
                        value = 10) {
  keys <- expand.grid(
    year = as.integer(years), month = 1:12,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  data.frame(
    site = site,
    date = as.Date(sprintf("%04d-%02d-01", keys$year, keys$month)),
    temp_c = rep_len(as.numeric(value), nrow(keys)),
    stringsAsFactors = FALSE
  )
}

response_mask <- function(site = "TEST", years = 2018:2023,
                          present = TRUE, eligible = TRUE) {
  data.frame(
    site = rep(site, length(years)),
    year = as.integer(years),
    response_fit_eligible = rep_len(as.logical(eligible), length(years)),
    response_present = rep_len(as.logical(present), length(years)),
    stringsAsFactors = FALSE
  )
}

run_climate_fixture <- function(env) {
  mask_api <- required_api[["climate"]]
  call_mask <- function(climate, mask, site = unique(mask$site),
                        mode = "seal1-synthetic-climate-mask")
    call_api(env, mask_api, climate, mask, site, mode = mode)

  climate <- monthly_env()
  mask6 <- response_mask(present = TRUE)
  five_climate <- climate[
    climate$date < as.Date("2023-01-01"), , drop = FALSE]
  five <- call_mask(five_climate, mask6)
  six <- call_mask(climate[nrow(climate):1L, , drop = FALSE], mask6)
  six_ordered <- call_mask(climate, mask6)

  # One within-site outlier is removed only after complete/range-valid means.
  outlier_climate <- climate
  outlier_climate$temp_c[outlier_climate$date >= as.Date("2023-01-01")] <- 30
  outlier <- call_mask(outlier_climate, mask6)

  missing_annual_climate <- climate[
    climate$date != as.Date("2018-12-01"), , drop = FALSE]
  missing_annual <- call_mask(missing_annual_climate, mask6)
  missing_spring_climate <- climate[
    climate$date != as.Date("2019-04-01"), , drop = FALSE]
  missing_spring <- call_mask(missing_spring_climate, mask6)
  boundary_climate <- climate
  boundary_climate$temp_c[
    boundary_climate$date == as.Date("2020-03-01")] <- -40
  boundary_climate$temp_c[
    boundary_climate$date == as.Date("2021-05-01")] <- 50
  boundary <- call_mask(boundary_climate, mask6)
  near_boundary_climate <- climate
  near_boundary_climate$temp_c[
    near_boundary_climate$date == as.Date("2020-03-01")] <- -39.999
  near_boundary_climate$temp_c[
    near_boundary_climate$date == as.Date("2021-05-01")] <- 49.999
  near_boundary <- call_mask(near_boundary_climate, mask6)

  # This annual mean lies on the retained absolute-deviation boundary.  The
  # deliberately ill-conditioned monthly values make floating summation order
  # observable unless validation canonicalizes year/month before aggregation.
  edge_values <- c(
    -16.103751334537286, -6.5085932804881601, 11.556656994943973,
    41.737884683949872, -21.848029570491054, 40.854274867722765,
    45.019884823944423, 19.471479728231206, 16.620005722811445,
    -34.438359230460136, -21.461700208212715, -24.109245385895484)
  edge_values <- edge_values +
    (6 - (mean(edge_values) + mean(rev(edge_values))) / 2)
  edge_climate <- monthly_env(years = 2018:2023, value = 0)
  edge_year <- edge_climate$date >= as.Date("2021-01-01") &
    edge_climate$date < as.Date("2022-01-01")
  edge_climate$temp_c[edge_year] <-
    rev(edge_values)
  edge_mask <- response_mask(years = 2018:2023, present = TRUE)
  edge_ordered <- call_mask(edge_climate, edge_mask)
  edge_reversed <- call_mask(
    edge_climate[nrow(edge_climate):1L, , drop = FALSE], edge_mask)

  # The mask builder is one-site-at-a-time; aggregate only values-free counts.
  site_masks <- lapply(c("SITEA", "SITEB", "SITEC"), function(site) {
    call_mask(monthly_env(site), response_mask(site, present = TRUE), site)
  })
  counts <- do.call(rbind, lapply(site_masks, `[[`, "counts"))

  fixture(37, {
    check_identical(names(six), c("support", "counts", "digest_material"),
                    "climate-mask result surface")
    check_identical(names(six$support), c(
      "site", "year", "contrast", "response_fit_eligible",
      "response_present", "climate_complete", "climate_range_valid",
      "climate_mad_qc_pass", "climate_available", "overlap"),
      "values-free climate support schema")
    check_identical(names(six$counts), c(
      "site", "contrast", "response_fit_eligible", "n_response_present",
      "n_climate_complete", "n_climate_range_valid",
      "n_climate_mad_qc_pass", "n_climate_available", "n_overlap"),
      "values-free climate count schema")
    check(is.raw(six$digest_material), "climate digest material is opaque raw bytes")
    check(setequal(unique(six$support$contrast), c("temp", "temp_spring")),
          "exact two registered climate contrasts")
    check(all(five$counts$n_overlap == 5L) && all(six$counts$n_overlap == 6L),
          "five/six overlap boundary")
    support_decision <- function(x, contrast) {
      eligible <- x$contrast == contrast & x$response_fit_eligible &
        x$n_overlap >= 6L
      length(unique(x$site[eligible])) >= 3L
    }
    first_two <- counts[counts$site %in% c("SITEA", "SITEB"), , drop = FALSE]
    check(all(vapply(c("temp", "temp_spring"), function(contrast)
      !support_decision(first_two, contrast), logical(1L))) &&
        all(vapply(c("temp", "temp_spring"), function(contrast)
          support_decision(counts, contrast), logical(1L))),
      "two sites HOLD while three sites PROCEED")
    outlier_rows <- outlier$support$year == 2023L
    check(all(outlier$support$climate_complete[outlier_rows]) &&
            all(outlier$support$climate_range_valid[outlier_rows]) &&
            !any(outlier$support$climate_mad_qc_pass[outlier_rows]) &&
            !any(outlier$support$climate_available[outlier_rows]),
          "within-site MAD rule removes a complete in-range outlier")
    annual_2018 <- one_row(
      missing_annual$support,
      list(year = 2018L, contrast = "temp"),
      "missing annual month row")
    spring_2018 <- one_row(
      missing_annual$support,
      list(year = 2018L, contrast = "temp_spring"),
      "complete spring row")
    check(!annual_2018$climate_complete &&
            !annual_2018$climate_range_valid &&
            spring_2018$climate_complete &&
            spring_2018$climate_range_valid,
          "annual temperature requires 12/12 while spring requires only March-May")
    annual_2019 <- one_row(
      missing_spring$support,
      list(year = 2019L, contrast = "temp"),
      "missing April annual row")
    spring_2019 <- one_row(
      missing_spring$support,
      list(year = 2019L, contrast = "temp_spring"),
      "missing April spring row")
    check(!annual_2019$climate_complete && !spring_2019$climate_complete,
          "missing spring month fails both 12/12 and 3/3 completeness")
    boundary_rows <- boundary$support$year %in% c(2020L, 2021L)
    near_boundary_rows <- near_boundary$support$year %in% c(2020L, 2021L)
    check(all(boundary$support$climate_complete[boundary_rows]) &&
            !any(boundary$support$climate_range_valid[boundary_rows]) &&
            all(near_boundary$support$climate_range_valid[near_boundary_rows]),
          "temperature range is strictly -40 < temp < 50")
    check(same_canonical(six$support, six_ordered$support) &&
            same_canonical(six$counts, six_ordered$counts) &&
            identical(six$digest_material, six_ordered$digest_material),
          "full climate result and digest invariant to monthly row order")
    edge_annual <- one_row(
      edge_ordered$support, list(year = 2021L, contrast = "temp"),
      "floating-order MAD boundary row")
    check(edge_annual$climate_mad_qc_pass &&
            same_canonical(edge_ordered$support, edge_reversed$support) &&
            same_canonical(edge_ordered$counts, edge_reversed$counts) &&
            identical(edge_ordered$digest_material,
                      edge_reversed$digest_material),
          "equality-retained MAD boundary is invariant to monthly row order")
    forbidden_output <- c(
      "temp_c", "temp", "temp_spring", "greenup_doy",
      "greenup_doy_interval_std", "response_value", "effect",
      "correlation", "coefficient", "p_value"
    )
    check(!any(forbidden_output %in% names(six$support)) &&
            !any(forbidden_output %in% names(six$counts)),
          "no response/climate numeric co-residence in mask output")

    leaked <- climate
    leaked$greenup_doy_interval_std <- seq_len(nrow(leaked))
    expect_error_code(call_mask(leaked, mask6),
                      "phenology_v2_mask_climate_response_leak",
                      "numeric response leak rejected")
    camel_leaked <- climate
    camel_leaked$greenupDOY <- seq_len(nrow(camel_leaked))
    expect_error_code(call_mask(camel_leaked, mask6),
                      "phenology_v2_mask_climate_response_leak",
                      "camelCase numeric response leak rejected")
    five_present <- response_mask(
      present = c(rep(TRUE, 5L), FALSE), eligible = TRUE)
    expect_error_code(call_mask(climate, five_present),
                      "phenology_v2_mask_response_state",
                      "eligible climate mask requires six response years")
    ineligible_present <- response_mask(present = TRUE, eligible = FALSE)
    expect_error_code(call_mask(climate, ineligible_present),
                      "phenology_v2_mask_response_state",
                      "ineligible climate mask cannot contain a response year")
    expect_error_code(call_mask(climate, mask6, mode = "unsealed"),
                      "phenology_v2_mask_mode", "wrong mask mode rejected")

    call_with_effect_symbol <- function() {
      correlation <- function(...) 0
      call_mask(climate, mask6)
    }
    expect_error_code(call_with_effect_symbol(),
                      "phenology_v2_mask_effect_lock",
                      "effect-capable caller rejected")
    rm(call_with_effect_symbol)
    call_with_alias <- function() {
      harmless <- stats::cor
      call_mask(climate, mask6)
    }
    expect_error_code(call_with_alias(),
                      "phenology_v2_mask_effect_lock",
                      "aliased effect primitive rejected by function identity")
  })
}

run_malformed_fixture <- function(env) {
  good <- make_bundle(make_obs())
  call_bundle <- function(bundle, site = "TEST")
    call_api(env, required_api[["adapter"]], bundle, site, effect_locked = TRUE)

  cases <- list(
    list("unnamed/non-list bundle", "malformed_container",
         function() call_bundle(data.frame(x = 1))),
    list("missing bundle member", "missing_bundle_member", function() {
      x <- good
      x$trend <- NULL
      x <- x[names(x) != "trend"]
      call_bundle(x)
    }),
    list("climate-named bundle member", "effect_lock", function() {
      x <- good
      x$climate <- data.frame(temp_c = 10)
      call_bundle(x)
    }),
    list("effect-named bundle member", "effect_lock", function() {
      x <- good
      x$posterEffect <- 1
      call_bundle(x)
    }),
    list("climate column on observations", "effect_lock", function() {
      x <- good
      x$obs$temp_c <- 10
      call_bundle(x)
    }),
    list("effect column on roster", "effect_lock", function() {
      x <- good
      x$inds$annualResponse <- 100
      call_bundle(x)
    }),
    list("climate column on individual summary", "effect_lock", function() {
      x <- good
      x$ind_summary <- data.frame(climateIndex = numeric())
      call_bundle(x)
    }),
    list("climate column on trend comparison", "effect_lock", function() {
      x <- good
      x$trend <- data.frame(
        scientificName = "Alpha alba", year = 2018L,
        onset = 100, n = 3L, tempSpring = 10)
      call_bundle(x)
    }),
    list("whitespace-only site identity", "invalid_site_identity", function() {
      x <- good
      x$meta$site <- "   "
      call_bundle(x, "   ")
    }),
    list("whitespace-only observation identity", "blank_observation_identity", function() {
      x <- good
      x$obs$individualID <- "   "
      call_bundle(x)
    }),
    list("whitespace-only observation plot", "blank_plot_identity", function() {
      x <- good
      x$obs$plotID <- "   "
      call_bundle(x)
    }),
    list("whitespace-only roster identity", "duplicate_roster_identity", function() {
      x <- good
      x$inds$individualID <- "   "
      call_bundle(x)
    }),
    list("whitespace-only roster plot", "blank_plot_identity", function() {
      x <- good
      x$inds$plotID <- "   "
      call_bundle(x)
    }),
    list("asserted taxon against whitespace roster taxon",
         "roster_taxonomy_conflict", function() {
      x <- good
      x$inds$scientificName <- "   "
      call_bundle(x)
    }),
    list("duplicate roster identity", "duplicate_roster_identity", function() {
      x <- good
      x$inds <- rbind(x$inds, x$inds)
      call_bundle(x)
    }),
    list("conflicting metadata", "site_identity_conflict", function() {
      x <- good
      x$meta$site <- "OTHER"
      call_bundle(x)
    }),
    list("invalid date", "invalid_date", function() {
      x <- good
      x$obs$date <- "2018-02-30"
      call_bundle(x)
    }),
    list("date/year mismatch", "date_year_mismatch", function() {
      x <- good
      x$obs$year <- 2019L
      call_bundle(x)
    }),
    list("nonnumeric source DOY", "invalid_source_doy_type", function() {
      x <- good
      x$obs$dayOfYear <- "91"
      call_bundle(x)
    }),
    list("NaN source DOY", "invalid_source_doy_nan", function() {
      x <- good
      x$obs$dayOfYear <- NaN
      call_bundle(x)
    }),
    list("positive infinite source DOY", "invalid_source_doy_value", function() {
      x <- good
      x$obs$dayOfYear <- Inf
      call_bundle(x)
    }),
    list("negative infinite source DOY", "invalid_source_doy_value", function() {
      x <- good
      x$obs$dayOfYear <- -Inf
      call_bundle(x)
    }),
    list("fractional source DOY", "invalid_source_doy_value", function() {
      x <- good
      x$obs$dayOfYear <- 91.5
      call_bundle(x)
    }),
    list("zero source DOY", "invalid_source_doy_value", function() {
      x <- good
      x$obs$dayOfYear <- 0
      call_bundle(x)
    }),
    list("source DOY above 366", "invalid_source_doy_value", function() {
      x <- good
      x$obs$dayOfYear <- 367
      call_bundle(x)
    }),
    list("unsupported status", "unsupported_status", function() {
      x <- good
      x$obs$status <- "maybe"
      call_bundle(x)
    }),
    list("missing required observation field", "missing_required_field", function() {
      x <- good
      x$obs$individualID <- NULL
      call_bundle(x)
    }),
    list("duplicate observation columns", "duplicate_or_blank_columns", function() {
      x <- good
      names(x$obs)[2L] <- names(x$obs)[1L]
      call_bundle(x)
    }),
    list("incompatible list column", "incompatible_column", function() {
      x <- good
      x$obs$intensity <- I(list(list("nested")))
      call_bundle(x)
    }),
    list("dimensioned atomic column", "incompatible_column", function() {
      x <- good
      x$obs$dayOfYear <- I(matrix(91, ncol = 1L))
      call_bundle(x)
    }),
    list("empty nonnull trend", "empty_required_table", function() {
      x <- good
      x$trend <- data.frame(scientificName = character(), year = integer(),
                            onset = numeric(), n = integer())
      call_bundle(x)
    })
  )
  valid_trend <- data.frame(
    scientificName = "Alpha alba", year = 2018L, onset = 100, n = 3L,
    stringsAsFactors = FALSE)
  trend_mutations <- list(
    "nonnumeric trend taxon" = transform(valid_trend, scientificName = 1),
    "blank trend taxon" = transform(valid_trend, scientificName = "   "),
    "duplicate trend key" = rbind(valid_trend, valid_trend),
    "fractional trend year" = transform(valid_trend, year = 2018.5),
    "out-of-window trend year" = transform(valid_trend, year = 2026L),
    "nonfinite trend onset" = transform(valid_trend, onset = Inf),
    "out-of-range trend onset" = transform(valid_trend, onset = 0),
    "fractional trend support" = transform(valid_trend, n = 3.5),
    "under-threshold trend support" = transform(valid_trend, n = 2L)
  )

  fixture(38, {
    for (case in cases)
      expect_error_code(case[[3L]](), case[[2L]], case[[1L]])
    for (label in names(trend_mutations)) {
      x <- good
      x$trend <- trend_mutations[[label]]
      expect_error_code(call_bundle(x), "invalid_trend_support", label)
    }

    blank_taxon <- good
    blank_taxon$obs$scientificName <- "   "
    blank_taxon$inds$scientificName <- "   "
    blank_taxon_result <- call_bundle(blank_taxon)
    check_identical(
      as.character(blank_taxon_result$plant_years$taxonomy_state),
      "taxon_rank_ineligible",
      "both-whitespace taxon remains an explicit rank-ineligible opportunity")

    previous <- getOption("phenology.v2.package_altrep_probe")
    on.exit(options(phenology.v2.package_altrep_probe = previous), add = TRUE)
    options(phenology.v2.package_altrep_probe = function(x) is.integer(x))
    expect_error_code(call_bundle(good), "package_altrep_column",
                      "package-backed ALTREP probe")
    options(phenology.v2.package_altrep_probe = previous)
  })
}

run_cross_cutting_contracts <- function(env) {
  # The five opportunity axes remain orthogonal under terminal-state priority.
  obs <- phase_pair("P1", "Alpha alba", 2012L, 90L, 100L)
  obs$is_species <- FALSE
  inds <- roster_from_obs(obs)
  result <- adapt(env, obs, inds)
  py <- result$plant_years
  check_identical(as.character(py$calendar_state), "outside_driver_window",
                  "calendar axis retained")
  check_identical(as.character(py$taxonomy_state), "taxon_rank_ineligible",
                  "taxonomy axis retained")
  check_identical(as.character(py$v2_observation_state), "bounded_onset",
                  "observation axis retained")
  check_identical(as.character(py$compat_censor_state), "compat_bounded",
                  "compatibility axis retained")
  check_identical(as.character(py$terminal_state), "outside_driver_window",
                  "terminal partition priority")

  vocabulary <- list(
    calendar_state = c("inside_driver_window", "outside_driver_window"),
    taxonomy_state = c("eligible_species", "taxon_rank_ineligible",
                       "roster_unmatched_taxon_unknown"),
    v2_observation_state = c(
      "bounded_onset", "left_censored_onset", "right_censored_no_yes",
      "uncertain_only", "status_conflict_only", "ambiguous_competing_phase",
      "structural_unscored"),
    v2_eligibility_state = c(
      "pending", "model_row", "species_year_excluded",
      "recurrence_excluded", "connected_panel_excluded"),
    compat_censor_state = c(
      "compat_bounded", "compat_left_censored", "compat_no_finite_onset")
  )
  for (name in names(vocabulary))
    check(all(as.character(py[[name]]) %in% vocabulary[[name]]),
          sprintf("exact %s vocabulary", name))

  # Exact threshold equality is warning-positive and does not alter model rows.
  obs <- rbind(
    phase_pair("B", "Alpha alba", 2018L, 90L, 100L),
    left_visit("L", "Alpha alba", 2018L, 105L)
  )
  warning_result <- adapt(env, obs)
  yr <- one_row(warning_result$annual_support, list(year = 2018L),
                "diagnostic threshold row")
  check_near(yr$left_censored_share, 0.5,
             "left-censored diagnostic denominator", 1e-15)
  check(isTRUE(yr$censor_burden_warning),
        "left-censored share exactly 0.50 warns")
  check(all(warning_result$plant_years$v2_observation_state %in%
              c("bounded_onset", "left_censored_onset")),
        "diagnostic warning does not rewrite observation states")

  # Cadence warnings use strict interval-width boundaries and remain diagnostic.
  cadence_rows <- make_fit_rows()
  cadence_width <- rep(8, nrow(cadence_rows))
  cadence_width[cadence_rows$year == 2018L] <- 14
  cadence_width[cadence_rows$year == 2019L] <- 15
  cadence_width[cadence_rows$year == 2020L] <- 10
  cadence_width[which(cadence_rows$year == 2020L)[1L]] <- 30
  cadence_width[cadence_rows$year == 2021L] <- 10
  cadence_width[which(cadence_rows$year == 2021L)[1L]] <- 31
  cadence_rows$lower_doy <- cadence_rows$upper_doy - cadence_width
  cadence <- adapt(env, adapter_panel_obs(cadence_rows))
  cadence_annual <- cadence$annual_support[
    cadence$annual_support$year %in% 2018:2023, , drop = FALSE]
  check_near(cadence_annual$v2_interval_median_days,
             c(14, 15, 10, 10, 8, 8),
             "cadence median boundaries", 1e-15)
  check_near(cadence_annual$v2_interval_p90_days,
             c(14, 15, 20, 20.5, 8, 8),
             "cadence p90 summaries", 1e-15)
  check_near(cadence_annual$v2_interval_max_days,
             c(14, 15, 30, 31, 8, 8),
             "cadence maximum boundaries", 1e-15)
  check_identical(cadence_annual$typical_cadence_warning,
                  c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
                  "typical cadence warning is strict above 14 days")
  check_identical(cadence_annual$extreme_cadence_warning,
                  c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE),
                  "extreme cadence warning is strict above 30 days")
  check(nrow(cadence$model_rows) == nrow(cadence_rows) &&
          all(cadence_annual$v2_n_model_individuals == 6L) &&
          all(cadence_annual$annual_response_supported) &&
          same_model_values(cadence$model_rows, cadence_rows),
        "cadence warnings alter neither model membership nor eligibility")

  # Candidate counts reconcile through disjoint terminal dispositions.
  panel <- adapt(env, adapter_panel_obs())
  annual <- panel$annual_support
  check(all(annual$v2_n_timing_candidates ==
              annual$v2_n_bounded + annual$v2_n_left_censored),
        "candidate observation-count reconciliation")
  check(all(annual$v2_n_timing_candidates ==
              annual$v2_n_taxon_excluded +
              annual$v2_n_species_year_excluded +
              annual$v2_n_recurrence_excluded +
              annual$v2_n_connected_panel_excluded +
              annual$v2_n_model_individuals),
        "candidate terminal-disposition reconciliation")

  expected_tables <- c(
    "source_rows", "visits", "phases", "plant_years",
    "compatibility_individual_years", "compatibility_annual", "model_rows",
    "annual_support", "leaf_active", "leaf_active_support", "audit_counts",
    "site_summary")
  check_identical(names(panel), expected_tables, "adapter named-table surface")
  mixed_state_panel <- adapt(env, anchored_panel(
    2018:2020, c("Alpha alba", "Beta beta"), 3L))
  retained_states <- mixed_state_panel$plant_years$v2_observation_state[
    mixed_state_panel$plant_years$v2_eligibility_state == "model_row"]
  check_identical(sort(unique(retained_states), method = "radix"),
                  c("bounded_onset", "left_censored_onset"),
                  "likelihood observation states remain on the plant-year ledger")
  expected_model_schema <- c(
    "site", "individualID", "scientificName", "year",
    "lower_doy", "upper_doy", "annual_response_supported")
  check_identical(names(panel$model_rows), expected_model_schema,
                  "adapter emits the exact response-module schema")
  check(same_model_values(panel$model_rows, make_fit_rows()),
        "adapter response handoff preserves all registered model values")
  direct_fit <- call_api(env, required_api[["response"]], panel$model_rows)
  direct_presence <- call_api(env, required_api[["presence"]], direct_fit)
  check(nrow(fit_annual(direct_fit)) == 6L &&
          all(fit_annual(direct_fit)$response_present) &&
          nrow(direct_presence) == 6L && all(direct_presence$response_present),
        "adapter model rows fit directly and emit six response-presence years")

  driver_calendar <- expand.grid(
    site = sprintf("SITE%02d", seq_len(46L)), year = 2013:2025,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  driver_calendar <- driver_calendar[seq_len(510L), , drop = FALSE]
  joined <- call_api(
    env, required_api[["join"]], driver_calendar, driver_calendar,
    required_audit_keys = driver_calendar)
  check(identical(names(joined), c("site", "year")) &&
          nrow(joined) == 510L && length(unique(joined$site)) == 46L,
        "key-only Driver calendar join preserves the registered topology")
  expect_error_code(
    call_api(env, required_api[["join"]], driver_calendar,
             transform(driver_calendar, temp_c = 10)),
    "effect_lock", "Driver calendar climate payload rejected")
  expect_error_code(
    call_api(env, required_api[["join"]],
             transform(driver_calendar, tempSpring = 10), driver_calendar),
    "effect_lock", "adapter annual climate payload rejected")
  expect_error_code(
    call_api(env, required_api[["join"]],
             transform(driver_calendar, correlation = 0), driver_calendar),
    "effect_lock", "adapter annual correlation payload rejected")
  expect_error_code(
    call_api(env, required_api[["join"]],
             transform(driver_calendar, p_value = 1), driver_calendar),
    "effect_lock", "adapter annual p-value payload rejected")
  expect_error_code(
    call_api(env, required_api[["join"]], driver_calendar, driver_calendar,
             required_audit_keys = transform(driver_calendar, audit = TRUE)),
    "effect_lock", "required audit keys permit no payload columns")

  # Dynamic capability lock: unlocked adapter execution is impossible.
  expect_error_code(
    call_api(env, required_api[["adapter"]], make_bundle(make_obs()), "TEST",
             effect_locked = FALSE),
    "effect_lock", "adapter defaults fail closed when unlocked")

  # Full-panel randomized-order and locale structural parity.
  utf8_species <- c(paste0(intToUtf8(197L), "lpha alba"), "Beta beta")
  Encoding(utf8_species) <- "UTF-8"
  obs <- anchored_panel(2018:2023, utf8_species, 3L)
  direct <- adapt(env, obs)
  set.seed(90210)
  shuffled <- adapt(env, obs[sample.int(nrow(obs)), , drop = FALSE])
  check(same_canonical(direct, shuffled), "full adapter randomized-order parity")

  previous_locale <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", previous_locale)), add = TRUE)
  c_locale <- suppressWarnings(Sys.setlocale("LC_COLLATE", "C"))
  c_result <- adapt(env, obs)
  utf8_locale <- ""
  for (candidate in c("C.UTF-8", "en_US.UTF-8", "en_US.utf8")) {
    utf8_locale <- suppressWarnings(Sys.setlocale("LC_COLLATE", candidate))
    if (nzchar(utf8_locale)) break
  }
  check(nzchar(c_locale) && nzchar(utf8_locale),
        "C and UTF-8 locale fixtures available")
  utf8_result <- adapt(env, obs)
  check(same_canonical(c_result, utf8_result),
        "C/UTF-8 locale structural parity")
  suppressWarnings(Sys.setlocale("LC_COLLATE", previous_locale))
}

run_adapter_response_mode <- function() {
  env <- source_modules(required_modules[c("adapter", "response")])
  run_adapter_observation_fixtures(env)
  receipt_payload <- run_adapter_support_fixtures(env)
  run_malformed_fixture(env)
  run_cross_cutting_contracts(env)
  finish_fixtures(c(1:36, 38L))
  receipt <- response_numeric_receipt(receipt_payload)
  cat(sprintf("[RECEIPT] response-numeric-sha256 %s\n", receipt))
  ok("adapter-response mode", "synthetic-only and effect-locked")
}

run_climate_mask_mode <- function() {
  env <- source_modules(required_modules[["climate"]], climate_mode = TRUE)
  run_climate_fixture(env)
  finish_fixtures(37L)
  ok("climate-mask mode", "values-free one-way support only")
}

script_path <- function() {
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(arg)) fail("fresh-process orchestrator", "cannot resolve --file")
  normalizePath(sub("^--file=", "", arg[[1L]]),
                winslash = "/", mustWork = TRUE)
}

run_orchestrator <- function() {
  before <- artifact_md5()
  executable <- file.path(R.home("bin"), "Rscript")
  script <- script_path()
  modes <- c("static-lock", "adapter-response", "climate-mask")
  run_clean_child <- function(mode) {
    stdout_path <- tempfile(sprintf("phenology-v2-%s-stdout-", mode))
    stderr_path <- tempfile(sprintf("phenology-v2-%s-stderr-", mode))
    on.exit(unlink(c(stdout_path, stderr_path)), add = TRUE)
    status <- system2(
      executable,
      args = c("--vanilla", shQuote(script), mode),
      stdout = stdout_path, stderr = stderr_path,
      env = c(
        "OPENBLAS_NUM_THREADS=1", "OMP_NUM_THREADS=1", "MKL_NUM_THREADS=1",
        "VECLIB_MAXIMUM_THREADS=1", "RCPP_PARALLEL_NUM_THREADS=1"
      )
    )
    read_raw <- function(path) {
      size <- file.info(path)$size
      if (is.na(size) || size == 0) return(raw())
      readBin(path, what = "raw", n = as.integer(size))
    }
    list(status = status, stdout = read_raw(stdout_path),
         stderr = read_raw(stderr_path))
  }
  for (mode in modes) {
    first <- run_clean_child(mode)
    second <- run_clean_child(mode)
    cat(rawToChar(first$stdout))
    if (length(first$stderr)) cat(rawToChar(first$stderr), file = stderr())
    if (!isTRUE(first$status == 0L) || !isTRUE(second$status == 0L))
      fail(sprintf("fresh child mode %s", mode),
           sprintf("exit statuses %s/%s", first$status, second$status))
    check(identical(first$stdout, second$stdout),
          sprintf("two-clean-run stdout %s", mode), "byte-identical")
    check(identical(first$stderr, second$stderr),
          sprintf("two-clean-run stderr %s", mode), "byte-identical")
    ok(sprintf("fresh child mode %s", mode), "two clean executions")
  }
  after <- artifact_md5()
  check_identical(after, before, "adapter tests do not mutate generated artifacts")
  ok("PHENOLOGY V2 SEAL-1 SYNTHETIC CONTRACTS",
     "38 fixtures reproduced across six clean process executions")
}

mode <- commandArgs(trailingOnly = TRUE)
if (!length(mode)) {
  run_orchestrator()
} else if (length(mode) != 1L) {
  fail("test mode", "expected zero or one mode argument")
} else {
  switch(
    mode,
    "static-lock" = run_static_lock(),
    "adapter-response" = run_adapter_response_mode(),
    "climate-mask" = run_climate_mask_mode(),
    fail("test mode", sprintf("unsupported mode '%s'", mode))
  )
}
