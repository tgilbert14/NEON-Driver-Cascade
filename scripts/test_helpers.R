# ===========================================================================
# Repository/data contract tests for the complete cascade artifact family.
# These are intentionally dependency-light and fail on the first broken
# invariant. They never switch to a machine-specific checkout.
# ===========================================================================
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1]), winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}
ROOT <- setwd_repo_root()

suppressPackageStartupMessages(library(dplyr))
eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "R/site_metadata.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "R/source_adapters.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)

ok <- function(label, detail = "OK") cat(sprintf("[PASS] %-55s %s\n", label, detail))
fail <- function(label, detail = "")
  stop(sprintf("[FAIL] %s%s", label, if (nzchar(detail)) paste0(": ", detail) else ""), call. = FALSE)
check <- function(value, label, detail = "") {
  if (!isTRUE(value)) fail(label, detail)
  ok(label, detail)
  invisible(TRUE)
}
check_cols <- function(x, cols, label) {
  missing <- setdiff(cols, names(x))
  check(!length(missing), label,
        if (length(missing)) paste("missing", paste(missing, collapse = ", ")) else sprintf("%d columns", length(cols)))
}
link_id <- function(x) paste(x$from, x$to, x$lag, sep = "|")
is_integerish <- function(x) all(is.na(x) | (is.finite(x) & x == floor(x)))
same_num <- function(a, b, tolerance = 1e-10) {
  length(a) == length(b) && all((is.na(a) & is.na(b)) |
    (is.finite(a) & is.finite(b) & abs(a - b) <= tolerance))
}

# Independent monthly-environment oracle. This is deliberately test-owned:
# production builders are never sourced, and raw sibling bundles are treated as
# inert data. It reproduces only the documented completeness, alignment, robust
# outlier, and fruiting gates that the committed annual artifact promises.
oracle_env_bundle <- function(e, site = "TEST", min_year = -Inf, max_year = Inf) {
  required <- c("temp_c", "precip_mm", "fruiting_pct", "fruiting_pct_n")
  missing <- setdiff(required, names(e))
  if (length(missing) || !any(c("date", "ym") %in% names(e)))
    stop(sprintf("environment fixture lacks required field(s): %s",
                 paste(c(missing,
                         if (!any(c("date", "ym") %in% names(e))) "date/ym"),
                       collapse = ", ")), call. = FALSE)

  e$.date <- as.Date(if ("date" %in% names(e)) e$date else paste0(e$ym, "-01"))
  e$year <- suppressWarnings(as.integer(format(e$.date, "%Y")))
  e$month <- suppressWarnings(as.integer(format(e$.date, "%m")))
  e_all <- e[is.finite(e$year) & is.finite(e$month), , drop = FALSE]
  e <- e_all[e_all$year >= min_year & e_all$year <= max_year, , drop = FALSE]
  if (!nrow(e)) return(NULL)
  if (anyDuplicated(paste(e$year, e$month, sep = "-")))
    stop("environment fixture has duplicate year-month rows", call. = FALSE)

  annual_oracle <- e %>%
    group_by(.data$year) %>%
    summarise(
      temp_n_months = sum(is.finite(.data$temp_c) &
                            .data$temp_c > -40 & .data$temp_c < 50),
      precip_n_months = sum(is.finite(.data$precip_mm) &
                              .data$precip_mm >= 0 & .data$precip_mm < 2000),
      temp = {
        ok <- is.finite(.data$temp_c) & .data$temp_c > -40 & .data$temp_c < 50
        if (sum(ok) == 12L) mean(.data$temp_c[ok]) else NA_real_
      },
      precip = {
        ok <- is.finite(.data$precip_mm) &
          .data$precip_mm >= 0 & .data$precip_mm < 2000
        if (sum(ok) == 12L) sum(.data$precip_mm[ok]) else NA_real_
      },
      fruiting_n_eligible_months = sum(is.finite(.data$fruiting_pct) &
        is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5),
      fruiting_peak_n_individuals = {
        ok <- is.finite(.data$fruiting_pct) &
          is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5
        if (!any(ok)) NA_real_ else {
          peak <- max(.data$fruiting_pct[ok])
          min(.data$fruiting_pct_n[ok & .data$fruiting_pct == peak])
        }
      },
      fruiting_pct = {
        ok <- is.finite(.data$fruiting_pct) &
          is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5
        if (any(ok)) max(.data$fruiting_pct[ok]) else NA_real_
      },
      .groups = "drop")

  robust_na <- function(x) {
    finite <- is.finite(x)
    if (sum(finite) >= 4L) {
      centre <- stats::median(x[finite])
      threshold <- max(6, 3 * stats::mad(x[finite]))
      x[finite & abs(x - centre) > threshold] <- NA_real_
    }
    x
  }
  annual_oracle$temp <- robust_na(annual_oracle$temp)

  climate <- e_all
  climate$precip_mm[!(is.finite(climate$precip_mm) &
                        climate$precip_mm >= 0 & climate$precip_mm < 2000)] <- NA_real_
  climate$temp_c[!(is.finite(climate$temp_c) &
                     climate$temp_c > -40 & climate$temp_c < 50)] <- NA_real_
  climate$winter_year <- ifelse(climate$month >= 10L,
                                climate$year + 1L, climate$year)
  winter <- climate %>%
    filter(.data$month %in% c(10L, 11L, 12L, 1L, 2L, 3L)) %>%
    group_by(year = .data$winter_year) %>%
    summarise(
      precip_winter_n_months = sum(!is.na(.data$precip_mm)),
      precip_winter = if (precip_winter_n_months == 6L)
        sum(.data$precip_mm) else NA_real_,
      .groups = "drop")
  monsoon <- climate %>%
    filter(.data$month %in% 7:9) %>%
    group_by(year = .data$year) %>%
    summarise(
      precip_monsoon_n_months = sum(!is.na(.data$precip_mm)),
      precip_monsoon = if (precip_monsoon_n_months == 3L)
        sum(.data$precip_mm) else NA_real_,
      .groups = "drop")
  spring <- climate %>%
    filter(.data$month %in% 3:5) %>%
    group_by(year = .data$year) %>%
    summarise(
      temp_spring_n_months = sum(!is.na(.data$temp_c)),
      temp_spring = if (temp_spring_n_months == 3L)
        mean(.data$temp_c) else NA_real_,
      .groups = "drop")
  seasonal <- Reduce(function(a, b) full_join(a, b, by = "year",
                                               relationship = "one-to-one"),
                     list(winter, monsoon, spring))
  seasonal <- seasonal[is.finite(seasonal$year) &
                         seasonal$year >= min_year &
                         seasonal$year <= max_year, , drop = FALSE]
  seasonal$temp_spring <- robust_na(seasonal$temp_spring)

  full_join(annual_oracle, seasonal, by = "year",
            relationship = "one-to-one") %>%
    mutate(site = site, .before = 1) %>%
    arrange(.data$year)
}

# Synthetic oracle tests make every completeness and QC branch non-vacuous,
# even if a future raw snapshot happens not to contain a partial window.
env_fixture <- expand.grid(year = 2018:2023, month = 1:12,
                           KEEP.OUT.ATTRS = FALSE)
env_fixture <- env_fixture[!(env_fixture$year == 2023 & env_fixture$month == 12) &
                           !(env_fixture$year == 2021 & env_fixture$month %in% c(4, 8)), ]
env_fixture$date <- as.Date(sprintf("%04d-%02d-01",
                                    env_fixture$year, env_fixture$month))
env_fixture$temp_c <- ifelse(env_fixture$year == 2022, 30, 10)
env_fixture$precip_mm <- ifelse(
  env_fixture$year == 2019, 100 + env_fixture$month,
  ifelse(env_fixture$year == 2020, 200 + env_fixture$month,
         env_fixture$month))
env_fixture$fruiting_pct <- ifelse(env_fixture$month == 6, 70, 99)
env_fixture$fruiting_pct_n <- ifelse(env_fixture$month == 6, 5L, 4L)
env_oracle <- oracle_env_bundle(env_fixture)
env_2020 <- env_oracle[env_oracle$year == 2020, , drop = FALSE]
env_2021 <- env_oracle[env_oracle$year == 2021, , drop = FALSE]
env_2022 <- env_oracle[env_oracle$year == 2022, , drop = FALSE]
check(nrow(env_2020) == 1L && env_2020$temp_n_months == 12L &&
        env_2020$precip_n_months == 12L && env_2020$temp == 10 &&
        env_2020$precip == 2478,
      "environment oracle enforces complete 12-month annual summaries")
check(env_2021$temp_n_months == 10L && env_2021$precip_n_months == 10L &&
        is.na(env_2021$temp) && is.na(env_2021$precip),
      "environment oracle rejects partial annual windows")
check(env_2020$precip_winter_n_months == 6L &&
        env_2020$precip_winter == 939,
      "winter oracle credits Oct-Dec to the year the six-month window ends")
check(env_2020$precip_monsoon_n_months == 3L &&
        env_2020$precip_monsoon == 624 &&
        env_2021$precip_monsoon_n_months == 2L &&
        is.na(env_2021$precip_monsoon) &&
        env_2021$temp_spring_n_months == 2L &&
        is.na(env_2021$temp_spring),
      "seasonal oracle enforces complete 3-month monsoon and spring windows")
check(env_2022$temp_n_months == 12L && is.na(env_2022$temp) &&
        env_2022$temp_spring_n_months == 3L && is.na(env_2022$temp_spring),
      "annual and spring temperatures apply the within-site MAD gate")
check(env_2020$fruiting_pct == 70 &&
        env_2020$fruiting_n_eligible_months == 1L &&
        env_2020$fruiting_peak_n_individuals == 5L,
      "fruiting oracle exposes unequal observed-month opportunity and peak support")

# A historical cutoff must be applied before robust QC. Without the cutoff,
# later warm years change the median and rescue the 2021 value.
cutoff_fixture <- expand.grid(year = 2018:2026, month = 1:12,
                              KEEP.OUT.ATTRS = FALSE)
cutoff_fixture$date <- as.Date(sprintf("%04d-%02d-01",
                                       cutoff_fixture$year,
                                       cutoff_fixture$month))
cutoff_fixture$temp_c <- ifelse(cutoff_fixture$year <= 2020, 0, 10)
cutoff_fixture$precip_mm <- 1
cutoff_fixture$fruiting_pct <- NA_real_
cutoff_fixture$fruiting_pct_n <- NA_real_
cutoff_limited <- oracle_env_bundle(cutoff_fixture, min_year = 2018,
                                    max_year = 2021)
cutoff_full <- oracle_env_bundle(cutoff_fixture)
check(max(cutoff_limited$year) == 2021L &&
        is.na(cutoff_limited$temp[cutoff_limited$year == 2021L]) &&
        is.finite(cutoff_full$temp[cutoff_full$year == 2021L]) &&
        is.na(cutoff_limited$temp_spring[cutoff_limited$year == 2021L]) &&
        is.finite(cutoff_full$temp_spring[cutoff_full$year == 2021L]),
      "annual and seasonal MAD thresholds exclude out-of-window years")

# Unit fixtures exercise the reviewed local source adapters themselves.
phen_fixture <- data.frame(
  individualID = c("A", "A", "A", "B", "B", "C", "D"),
  scientificName = c(rep("Species alpha", 3), rep("Species beta", 2),
                     "Species gamma", "Species delta"),
  growthForm = "tree",
  phenophaseName = c(rep(GREENUP[1], 5), "Open flowers", GREENUP[1]),
  year = 2020L,
  status = c("no", "yes", "yes", "yes", "no", "yes", "no"),
  dayOfYear = c(100, 110, 115, 120, 130, 90, 80),
  stringsAsFactors = FALSE)
phen_onset <- cascade_onset(phen_fixture, GREENUP)
phen_a <- phen_onset[phen_onset$individualID == "A", , drop = FALSE]
phen_b <- phen_onset[phen_onset$individualID == "B", , drop = FALSE]
check(nrow(phen_onset) == 2L && phen_a$onset_doy == 105 &&
        identical(phen_a$left_censored, FALSE) && phen_a$first_yes == 110 &&
        phen_b$onset_doy == 120 && identical(phen_b$left_censored, TRUE),
      "local phenology adapter reconstructs bounded and left-censored onset records")

# Order-adversarial phase rows exercise the production collapse used by ann_phe.
# Each group's first row is later than two tied minima; one later tied row is
# censored and another is the widest bounded interval.
phen_tie_fixture <- data.frame(
  individualID = rep(c("CENSORED", "WIDE"), each = 3),
  scientificName = rep(c("Species alpha", "Species beta"), each = 3),
  year = 2020L,
  onset_doy = c(120, 100, 100, 140, 110, 110),
  left_censored = c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE),
  first_yes = c(122, 110, 100, 142, 115, 125),
  stringsAsFactors = FALSE)
phen_tie_collapsed <- cascade_individual_year_onset(phen_tie_fixture)
phen_tie_censored <- phen_tie_collapsed[
  phen_tie_collapsed$individualID == "CENSORED", , drop = FALSE]
phen_tie_wide <- phen_tie_collapsed[
  phen_tie_collapsed$individualID == "WIDE", , drop = FALSE]
check(nrow(phen_tie_collapsed) == 2L &&
        phen_tie_censored$onset_doy == 100 &&
        identical(phen_tie_censored$left_censored, TRUE) &&
        phen_tie_censored$onset_interval_days == 20 &&
        phen_tie_wide$onset_doy == 110 &&
        identical(phen_tie_wide$left_censored, FALSE) &&
        phen_tie_wide$onset_interval_days == 30,
      paste("production phenology collapse uses all raw tied-minimum phases",
            "independently of input order"))
phen_empty_warnings <- character()
phen_empty_collapse <- withCallingHandlers(
  cascade_individual_year_onset(phen_tie_fixture[0, , drop = FALSE]),
  warning = function(w) {
    phen_empty_warnings <<- c(phen_empty_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
check(!length(phen_empty_warnings) && !nrow(phen_empty_collapse) &&
        identical(names(phen_empty_collapse),
                  c("individualID", "year", "onset_doy", "left_censored",
                    "scientificName", "onset_interval_days")),
      "zero phase-level rows return a typed empty onset table without warnings")

expect_error <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")
expected_plant_schema <- c(
  "year", "is_species", "scientificName", "percentCover", "plotID",
  "subplotID", "scale", "bout", "nativeStatusCode")
check(identical(CASCADE_PLANT_OCC_REQUIRED, expected_plant_schema),
      "plant occurrence adapter publishes an explicit exact schema")
plant_stub <- as.data.frame(stats::setNames(
  replicate(length(expected_plant_schema), logical(0), simplify = FALSE),
  expected_plant_schema), optional = TRUE)
check(expect_error(cascade_bundle_table(1, "occ", "plant", "TEST")) &&
        expect_error(cascade_bundle_table(list(), "occ", "plant", "TEST")) &&
        expect_error(cascade_bundle_table(list(occ = 1), "occ", "plant", "TEST")) &&
        expect_error(cascade_require_columns(
          plant_stub[, setdiff(names(plant_stub), "percentCover"), drop = FALSE],
          CASCADE_PLANT_OCC_REQUIRED, "plant fixture")),
      "existing malformed product bundles and plant schemas fail closed")
expected_mammal_tokens <- c(
  "1 - trap not set",
  "2 - trap disturbed/door closed but empty",
  "3 - trap door open or closed w/ spoor left",
  "4 - more than 1 capture in one trap",
  "5 - capture", "6 - trap set and empty")
expected_mammal_schema <- c(
  "collectDate", "nightuid", "plotID", "trapCoordinate", "trapStatus",
  "tagID", "remarks")
check(identical(CASCADE_MAMMAL_REQUIRED, expected_mammal_schema) &&
        identical(names(CASCADE_MAMMAL_TRAP_EFFORT), expected_mammal_tokens) &&
        identical(unname(CASCADE_MAMMAL_TRAP_EFFORT), c(0, 0.5, 0.5, 1, 1, 1)) &&
        identical(cascade_mammal_trap_effort(expected_mammal_tokens),
                  c(0, 0.5, 0.5, 1, 1, 1)) &&
        identical(cascade_mammal_trap_effort(
          c("  1 - TRAP NOT SET  ", "5 - CAPTURE")), c(0, 1)) &&
        all(vapply(c(
          "1 - trap not set garbage",
          "3 - trap door open w/ spoor left",
          "4 - >1 capture in one trap",
          "7 - trap set and empty", "", NA_character_),
          function(token) expect_error(cascade_mammal_trap_effort(token)),
          logical(1))) &&
        expect_error(cascade_data_frame(
          list(data = data.frame()), "mammal fixture")),
      "mammal contract locks the six exact pinned tokens and direct data-frame container")

mammal_fixture <- data.frame(
  collectDate = rep("2020-06-01", 8L),
  nightuid = c("MULTI", "MULTI", "DOUBLE", "DOUBLE",
               "PLACEHOLDER", "PLACEHOLDER", "REPEAT", "REPEAT"),
  plotID = rep("TEST_001", 8L),
  trapCoordinate = c("A1", "A1", "B1", "B1", "X10", "X10", "C1", "C2"),
  trapStatus = c(
    "4 - more than 1 capture in one trap", "5 - capture",
    "6 - trap set and empty", "1 - trap not set",
    "5 - capture", "6 - trap set and empty",
    "5 - capture", "5 - capture"),
  tagID = c("M1", "M2", NA, NA, "P1", NA, "REPEAT", "REPEAT"),
  remarks = c(
    NA, NA,
    rep("double trap method (two traps set at each location)", 2L),
    NA, NA, NA, NA),
  stringsAsFactors = FALSE)
mammal_fixture_events <- cascade_mammal_effort_events(
  mammal_fixture, rep(2020L, nrow(mammal_fixture)), "mammal fixture")
mammal_fixture_rules <- table(mammal_fixture_events$effort_rule)
check(nrow(mammal_fixture_events) == 6L &&
        sum(mammal_fixture_events$trap_effort) == 6 &&
        unname(mammal_fixture_rules["canonical-multi-capture-one-trap"]) == 1L &&
        unname(mammal_fixture_rules["reviewed-double-trap-rows"]) == 1L &&
        unname(mammal_fixture_rules["placeholder-row-level"]) == 2L &&
        unname(mammal_fixture_rules["canonical-single"]) == 2L &&
        sum(cascade_mammal_tag_present(mammal_fixture$tagID)) == 5L &&
        length(unique(trimws(mammal_fixture$tagID[
          cascade_mammal_tag_present(mammal_fixture$tagID)]))) == 4L,
      paste("mammal resolver separates one-trap multi-captures, exact reviewed",
            "double traps, placeholders, and repeated tags at distinct events"))
check(identical(CASCADE_MAMMAL_GRID_COORDINATE_RE,
                "^[A-J](?:[1-9]|10)$") &&
        identical(CASCADE_MAMMAL_PLACEHOLDER_COORDINATE_RE,
                  "^(?:[A-J]X|X(?:[1-9]|10)|XX)$") &&
        identical(CASCADE_MAMMAL_REVIEWED_MULTI_TRAP_MARKERS, c(
          "trap accidentally double set",
          "double trap method (two traps set at each location)")) &&
        identical(unname(cascade_mammal_multi_trap_marker(c(
          "TRAP ACCIDENTALLY DOUBLE SET after deployment",
          "double trap method (two traps set at each location) were used",
          "trap double set"))), c(1L, 2L, 0L)),
      "mammal coordinate grammar and two reviewed remark substrings are exact")

mammal_duplicate_fixture <- function(status, tag, remarks = NA_character_,
                                      coordinate = "A1") {
  n <- length(status)
  data.frame(
    collectDate = rep("2020-06-01", n),
    nightuid = rep("AMBIGUOUS", n), plotID = rep("TEST_001", n),
    trapCoordinate = rep(coordinate, n), trapStatus = status,
    tagID = tag, remarks = rep(remarks, length.out = n),
    stringsAsFactors = FALSE)
}
mammal_fixture_errors <- list(
  mammal_duplicate_fixture(rep("5 - capture", 2L), c("A", "B")),
  mammal_duplicate_fixture(
    c("6 - trap set and empty", "1 - trap not set"), c(NA, NA)),
  mammal_duplicate_fixture(
    rep("4 - more than 1 capture in one trap", 2L), c("A", "A")),
  mammal_duplicate_fixture(
    c("4 - more than 1 capture in one trap", "5 - capture"), c("A", NA)),
  mammal_duplicate_fixture(
    c("4 - more than 1 capture in one trap", "5 - capture"), c("A", "B"),
    "trap accidentally double set"),
  mammal_duplicate_fixture(
    rep("5 - capture", 3L), c("A", "B", "C"),
    "trap accidentally double set"),
  mammal_duplicate_fixture(
    rep("5 - capture", 2L), c("A", "A"),
    "trap accidentally double set"),
  within(mammal_duplicate_fixture(
    rep("4 - more than 1 capture in one trap", 2L), c("A", "B")), {
      collectDate <- c("2020-06-01", "2020-06-02")
    }),
  mammal_duplicate_fixture("5 - capture", "A", coordinate = "K1"),
  mammal_duplicate_fixture(
    rep("5 - capture", 2L), c("A", "B"), "trap double set"))
check(all(vapply(mammal_fixture_errors, function(x)
        expect_error(cascade_mammal_effort_events(
          x, rep(2020L, nrow(x)), "ambiguous mammal fixture")), logical(1))),
      "mammal resolver fails closed on every unreviewed duplicate/key ambiguity")

cutoff_epoch <- as.numeric(as.POSIXct(
  "2026-07-01 00:00:00", tz = "UTC"))
cutoff_default <- cascade_resolve_last_complete_year("", cutoff_epoch)
cutoff_explicit <- cascade_resolve_last_complete_year("2024", cutoff_epoch)
check(identical(cutoff_default$year, 2025L) &&
        identical(cutoff_default$source_year, 2025L) &&
        identical(cutoff_default$basis,
                  "UTC year(max source commit epoch) - 1") &&
        identical(cutoff_explicit$year, 2024L) &&
        identical(cutoff_explicit$basis,
                  "explicit CASCADE_LAST_COMPLETE_YEAR") &&
        all(vapply(c("2026", "9999", " 2024", "2024 ", "abcd", ""),
          function(value) {
            if (!nzchar(value))
              return(expect_error(cascade_resolve_last_complete_year(
                value, cutoff_epoch, min_year = 2026L)))
            expect_error(cascade_resolve_last_complete_year(value, cutoff_epoch))
          }, logical(1))),
      "complete-year resolver is deterministic and rejects malformed/future overrides")

# Same individualID in different plots is two design records. A giant live shrub
# with a stemDiameter must not leak into the selected forest size design, and a
# record-bearing plot without a qualifying live stem must remain an audited
# denominator without being imputed as a zero.
tree_fixture <- data.frame(
  individualID = c("T1", "T1", "T2", "T2", "T3", "T1", "T4", "T5"),
  plotID = c("P1", "P1", "P2", "P2", "P2", "P2", "P1", "P3"),
  date = as.Date(c("2020-01-01", "2021-01-01", "2021-01-01",
                   "2021-01-01", "2021-01-01", "2020-06-01",
                   "2021-01-01", "2021-01-01")),
  scientificName = c("Species alpha", "Species alpha", "Species beta",
                     "Species beta", "Species gamma", "Species alpha",
                     "Species delta", "Species epsilon"),
  live = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  growthForm = c("single bole tree", "single bole tree",
                 "single bole tree", "single bole tree", "single shrub",
                 "single bole tree", "single shrub", "single bole tree"),
  stemDiameter = c(10, 12, 20, 15, NA, 10, 100, 30),
  basalStemDiameter = c(NA, NA, NA, NA, 40, NA, 1, NA),
  stringsAsFactors = FALSE)
tree_snapshot_fixture <- cascade_tree_snapshot(tree_fixture)
tree_plots <- data.frame(plotID = c("P1", "P2", "P3"),
                         area_trees = c(1000, 1000, 1000),
                         area_shrub = c(100, 100, 100))
tree_evidence <- cascade_structure_evidence(tree_snapshot_fixture, tree_plots)
tree_type <- cascade_classify_structure(tree_snapshot_fixture, tree_plots)
tree_spec <- cascade_size_spec(tree_type)
tree_selected <- cascade_woody_only(cascade_live_only(tree_snapshot_fixture),
                                    tree_spec)
tree_site <- cascade_stand_site(tree_snapshot_fixture, tree_plots, tree_spec)
expected_p1 <- pi * (12 / 200)^2 / 0.1
expected_p2 <- pi * ((20 / 200)^2 + (15 / 200)^2 + (10 / 200)^2) / 0.1
check(nrow(tree_snapshot_fixture) == 7L &&
        sum(tree_snapshot_fixture$individualID == "T1") == 2L &&
        sum(tree_snapshot_fixture$individualID == "T2") == 2L &&
        tree_type == "forest" && nrow(tree_selected) == 4L &&
        tree_site$n_plots == 2L && tree_site$n_record_plots == 3L &&
        tree_site$n_area_eligible_plots == 3L &&
        isTRUE(all.equal(tree_site$ba_ha, mean(c(expected_p1, expected_p2)),
                         tolerance = 1e-15)) &&
        isTRUE(all.equal(tree_site$ba_se,
                         stats::sd(c(expected_p1, expected_p2)) / sqrt(2),
                         tolerance = 1e-15)) &&
        identical(tree_site$basis, CASCADE_VEG_STAND_BASIS),
      "vegetation adapter uses composite identities, selected forms, and explicit conditional denominators")
stem_state_fixture <- tree_fixture[3:4, , drop = FALSE]
stem_state_fixture$live[2] <- FALSE
stem_state_fixture$growthForm[2] <- "single shrub"
species_conflict_fixture <- tree_fixture[3:4, , drop = FALSE]
species_conflict_fixture$scientificName[2] <- "Different species"
check(nrow(cascade_tree_snapshot(stem_state_fixture)) == 2L &&
        expect_error(cascade_tree_snapshot(species_conflict_fixture)),
      "latest stem rows retain stem-specific state but reject conflicting whole-plant species")

duplicate_plots <- rbind(tree_plots, tree_plots[1, , drop = FALSE])
conflicting_plots <- rbind(
  tree_plots,
  transform(tree_plots[1, , drop = FALSE], area_trees = 2000))
check(expect_error(cascade_stand_site(tree_snapshot_fixture, duplicate_plots,
                                      tree_spec)) &&
        expect_error(cascade_stand_site(tree_snapshot_fixture, conflicting_plots,
                                        tree_spec)),
      "vegetation adapter rejects duplicate and conflicting plot-area records")

complete_support <- cascade_vegetation_design_support(
  tree_snapshot_fixture, tree_plots)
no_overlap_plots <- transform(tree_plots, plotID = paste0("Q", seq_len(nrow(tree_plots))))
no_overlap_support <- cascade_vegetation_design_support(
  tree_snapshot_fixture, no_overlap_plots)
partial_plots <- tree_plots
partial_plots$plotID[partial_plots$plotID == "P3"] <- "Q3"
partial_support <- cascade_vegetation_design_support(
  tree_snapshot_fixture, partial_plots)
check(isTRUE(complete_support$supported) &&
        nrow(complete_support$snapshot) == nrow(tree_snapshot_fixture) &&
        complete_support$n_record_plots == 3L &&
        complete_support$n_matched_record_plots == 3L &&
        complete_support$n_unmatched_record_plots == 0L &&
        !isTRUE(no_overlap_support$supported) &&
        nrow(no_overlap_support$snapshot) == 0L &&
        no_overlap_support$n_record_plots == 3L &&
        no_overlap_support$n_matched_record_plots == 0L &&
        no_overlap_support$n_unmatched_record_plots == 3L &&
        no_overlap_support$n_unmatched_record_rows == nrow(tree_snapshot_fixture) &&
        !isTRUE(partial_support$supported) &&
        nrow(partial_support$snapshot) == 0L &&
        partial_support$n_matched_record_plots == 2L &&
        partial_support$n_unmatched_record_plots == 1L &&
        partial_support$n_unmatched_record_rows == 1L &&
        identical(partial_support$basis, CASCADE_VEG_DESIGN_BASIS) &&
        expect_error(cascade_vegetation_design_support(
          tree_snapshot_fixture, duplicate_plots)) &&
        expect_error(cascade_structure_evidence(
          tree_snapshot_fixture, partial_plots)),
      "vegetation design support refuses area imputation and any partial-site estimate")

# Raw summed BA favors the tree, but normalizing each design by its own area
# correctly selects shrubland.
flip_snap <- data.frame(
  individualID = c("TREE", "SHRUB"), plotID = c("PT", "PS"),
  date = as.Date(c("2021-01-01", "2021-01-01")), live = TRUE,
  growthForm = c("single bole tree", "single shrub"),
  stemDiameter = c(20, NA), basalStemDiameter = c(NA, 10))
flip_plots <- data.frame(
  plotID = c("PT", "PS"), area_trees = c(10000, 10000),
  area_shrub = c(100, 100))
flip_evidence <- cascade_structure_evidence(flip_snap, flip_plots)
check(pi * (20 / 200)^2 > pi * (10 / 200)^2 &&
        flip_evidence$tree_ba_ha < flip_evidence$shrub_ba_ha &&
        identical(flip_evidence$type, "shrubland") &&
        identical(flip_evidence$basis, CASCADE_VEG_CLASSIFICATION_BASIS),
      "vegetation structure classification compares design-area-normalized evidence")

# Test-owned vegetation oracle: no production adapter call is used to derive the
# expected raw-source values below.
oracle_veg_bundle <- function(b, site) {
  tree_need <- c("individualID", "plotID", "date", "scientificName",
                 "live", "growthForm", "stemDiameter", "basalStemDiameter")
  plot_need <- c("plotID", "area_trees", "area_shrub")
  if (!is.list(b) || is.data.frame(b) ||
      !is.data.frame(b$trees) || !is.data.frame(b$plots) ||
      length(setdiff(tree_need, names(b$trees))) ||
      length(setdiff(plot_need, names(b$plots))))
    stop(sprintf("%s vegetation oracle received a malformed bundle", site),
         call. = FALSE)
  trees <- b$trees
  plots <- b$plots
  if (!nrow(trees)) return(NULL)
  bad_key <- is.na(trees$plotID) | !nzchar(trimws(as.character(trees$plotID))) |
    is.na(trees$individualID) |
    !nzchar(trimws(as.character(trees$individualID)))
  measurement_date <- tryCatch(as.Date(trees$date), error = function(e)
    rep(as.Date(NA), nrow(trees)))
  if (any(bad_key) || anyNA(measurement_date) ||
      anyNA(plots$plotID) || any(!nzchar(trimws(as.character(plots$plotID)))) ||
      anyDuplicated(as.character(plots$plotID)))
    stop(sprintf("%s vegetation oracle found invalid keys/dates/plot areas", site),
         call. = FALSE)
  composite <- paste(trees$plotID, trees$individualID, sep = "\r")
  date_number <- as.numeric(measurement_date)
  latest <- ave(date_number, composite, FUN = max)
  snap <- trees[date_number == latest, , drop = FALSE]
  snap_composite <- paste(snap$plotID, snap$individualID, sep = "\r")
  species <- ifelse(is.na(snap$scientificName), "<NA>",
                    trimws(as.character(snap$scientificName)))
  species_n <- tapply(species, snap_composite,
                      function(x) length(unique(x)))
  if (any(species_n != 1L))
    stop(sprintf("%s vegetation oracle found conflicting latest species", site),
         call. = FALSE)
  record_plot <- as.character(snap$plotID)
  record_ids <- unique(record_plot)
  row_match <- match(record_plot, as.character(plots$plotID))
  record_match <- match(record_ids, as.character(plots$plotID))
  n_unmatched_plots <- sum(is.na(record_match))
  n_unmatched_rows <- sum(is.na(row_match))
  if (n_unmatched_plots > 0L) {
    # Literal test-owned eligibility rules quantify the source evidence, but no
    # class or per-hectare value is derived when any record plot lacks an area.
    tree_d <- suppressWarnings(as.numeric(snap$stemDiameter))
    shrub_d <- suppressWarnings(as.numeric(snap$basalStemDiameter))
    qualifying <- snap$live %in% TRUE & (
      (snap$growthForm %in% c("single bole tree", "multi-bole tree", "small tree") &
         is.finite(tree_d) & tree_d > 0 & tree_d >= 10) |
      (snap$growthForm %in% c("single shrub", "small shrub", "sapling", "small tree") &
         is.finite(shrub_d) & shrub_d > 0))
    return(data.frame(
      site = site, expected_ba = NA_real_, expected_se = NA_real_,
      expected_type = NA_character_, expected_n_plots = 0L,
      expected_record_plots = length(record_ids),
      expected_matched_record_plots = sum(!is.na(record_match)),
      expected_area_eligible_plots = 0L,
      expected_unmatched_record_plots = n_unmatched_plots,
      expected_unmatched_record_rows = n_unmatched_rows,
      expected_tree_class_ba_ha = NA_real_,
      expected_shrub_class_ba_ha = NA_real_,
      expected_tree_class_plots = NA_integer_,
      expected_shrub_class_plots = NA_integer_,
      expected_stand_basis = CASCADE_VEG_STAND_BASIS,
      expected_class_basis = CASCADE_VEG_CLASSIFICATION_BASIS,
      expected_design_status = "unsupported-unmatched-plots",
      expected_design_basis = CASCADE_VEG_DESIGN_BASIS,
      source_unmatched_qualifying_rows = sum(qualifying & is.na(row_match)),
      source_unmatched_plot_ids = paste(sort(record_ids[is.na(record_match)]),
                                          collapse = ','),
      stringsAsFactors = FALSE))
  }

  component <- function(forms, diameter, minimum, area_name) {
    x <- suppressWarnings(as.numeric(snap[[diameter]]))
    keep <- snap$live %in% TRUE & snap$growthForm %in% forms &
      is.finite(x) & x > 0 & x >= minimum
    stems <- snap[keep, , drop = FALSE]
    x <- x[keep]
    if (!nrow(stems)) return(list(ba_ha = 0, n_plots = 0L))
    used <- unique(as.character(stems$plotID))
    area <- suppressWarnings(as.numeric(
      plots[[area_name]][match(used, as.character(plots$plotID))]))
    if (any(!is.finite(area) | area <= 0))
      stop(sprintf("%s vegetation oracle found invalid used area", site),
           call. = FALSE)
    eligible <- area > 50
    if (!any(eligible)) return(list(ba_ha = 0, n_plots = 0L))
    keep_stem <- as.character(stems$plotID) %in% used[eligible]
    list(ba_ha = sum(pi * (x[keep_stem] / 200)^2) /
           (sum(area[eligible]) / 10000),
         n_plots = as.integer(sum(eligible)))
  }
  tree <- component(c("single bole tree", "multi-bole tree", "small tree"),
                    "stemDiameter", 10, "area_trees")
  shrub <- component(c("single shrub", "small shrub", "sapling", "small tree"),
                     "basalStemDiameter", 0, "area_shrub")
  type <- if (tree$ba_ha == 0 && shrub$ba_ha == 0) "forest" else
    if (tree$ba_ha >= shrub$ba_ha) "forest" else "shrubland"
  spec <- if (type == "forest")
    list(forms = c("single bole tree", "multi-bole tree", "small tree"),
         diameter = "stemDiameter", minimum = 10, area = "area_trees") else
    list(forms = c("single shrub", "small shrub", "sapling", "small tree"),
         diameter = "basalStemDiameter", minimum = 0, area = "area_shrub")
  diameter <- suppressWarnings(as.numeric(snap[[spec$diameter]]))
  selected <- snap$live %in% TRUE & snap$growthForm %in% spec$forms &
    is.finite(diameter) & diameter > 0 & diameter >= spec$minimum
  stems <- snap[selected, , drop = FALSE]
  diameter <- diameter[selected]
  if (!nrow(stems)) return(NULL)
  by_plot <- split(seq_len(nrow(stems)), as.character(stems$plotID))
  ba_m2 <- vapply(by_plot, function(ix)
    sum(pi * (diameter[ix] / 200)^2), numeric(1))
  used <- names(ba_m2)
  area <- suppressWarnings(as.numeric(
    plots[[spec$area]][match(used, as.character(plots$plotID))]))
  if (any(!is.finite(area) | area <= 0))
    stop(sprintf("%s vegetation oracle found invalid stand area", site),
         call. = FALSE)
  eligible <- area > 50
  if (!any(eligible)) return(NULL)
  ba_ha <- ba_m2[eligible] / (area[eligible] / 10000)
  record_ids <- unique(as.character(snap$plotID))
  record_area <- suppressWarnings(as.numeric(
    plots[[spec$area]][match(record_ids, as.character(plots$plotID))]))
  data.frame(
    site = site, expected_ba = mean(ba_ha),
    expected_se = if (length(ba_ha) > 1L)
      stats::sd(ba_ha) / sqrt(length(ba_ha)) else NA_real_,
    expected_type = type, expected_n_plots = length(ba_ha),
    expected_record_plots = length(record_ids),
    expected_matched_record_plots = length(record_ids),
    expected_area_eligible_plots =
      sum(is.finite(record_area) & record_area > 50),
    expected_unmatched_record_plots = 0L,
    expected_unmatched_record_rows = 0L,
    expected_tree_class_ba_ha = tree$ba_ha,
    expected_shrub_class_ba_ha = shrub$ba_ha,
    expected_tree_class_plots = tree$n_plots,
    expected_shrub_class_plots = shrub$n_plots,
    expected_stand_basis = CASCADE_VEG_STAND_BASIS,
    expected_class_basis = CASCADE_VEG_CLASSIFICATION_BASIS,
    expected_design_status = "supported",
    expected_design_basis = CASCADE_VEG_DESIGN_BASIS,
    source_unmatched_qualifying_rows = 0L,
    source_unmatched_plot_ids = '',
    stringsAsFactors = FALSE)
}

adapter_source <- paste(readLines("R/source_adapters.R", warn = FALSE), collapse = "\n")
build_source <- paste(readLines("scripts/build_cascade.R", warn = FALSE), collapse = "\n")
check(!grepl("source\\s*\\(", adapter_source),
      "reviewed source adapters never execute sibling repository code")
check(all(vapply(c(
        'cascade_bundle_table(b, "occ", "plant", site)',
        'cascade_bundle_table(b, "obs", "bird", site)',
        'cascade_bundle_table(b, "obs", "mosquito", site)',
        'cascade_bundle_table(b, "effort_week", "mosquito", site)',
        'cascade_bundle_table(b, "trees", "vegetation", site)',
        'cascade_bundle_table(b, "plots", "vegetation", site)'),
      grepl, logical(1), x = build_source, fixed = TRUE)) &&
        grepl("cascade_data_frame(d, sprintf(\"%s beetle bundle\", site))",
              build_source, fixed = TRUE),
      "every existing plant/bird/mosquito/vegetation/beetle bundle fails closed")
check(!grepl("round\\s*\\(", build_source),
      "analytical annual fields retain full precision in the built artifact")
check(!grepl("cascade_(tree_snapshot|classify_structure|stand|woody|vegetation_design)",
             paste(deparse(body(oracle_veg_bundle)), collapse = "\n")),
      "vegetation source oracle is independent of production adapter formulas")

required_files <- c("data/cascade.rds", "data/search_index.rds",
                    "data/cascade_meta.rds", "data/neon-cascade-codebook.csv")
check(all(file.exists(required_files)), "all generated artifacts exist",
      paste(basename(required_files), collapse = ", "))

cascade <- readRDS("data/cascade.rds")
search <- readRDS("data/search_index.rds")
meta_companion <- readRDS("data/cascade_meta.rds")
check(!length(cascade_artifact_text_issues(cascade, "cascade")) &&
        !length(cascade_artifact_text_issues(search, "search")) &&
        !length(cascade_artifact_text_issues(meta_companion, "meta")),
      "all RDS character fields satisfy the UTF-8 serialization contract")
cross_locale_read <- local({
  old_ctype <- Sys.getlocale("LC_CTYPE")
  on.exit(suppressWarnings(Sys.setlocale("LC_CTYPE", old_ctype)), add = TRUE)
  active <- ""
  for (candidate in c(".UTF-8", "C.UTF-8", "en_US.UTF-8")) {
    selected <- suppressWarnings(Sys.setlocale("LC_CTYPE", candidate))
    if (!is.na(selected) && nzchar(selected) && grepl("UTF-?8", selected, ignore.case = TRUE)) {
      active <- selected
      break
    }
  }
  if (!nzchar(active)) return(list(ok = FALSE, locale = "no UTF-8 locale available"))
  reopened <- tryCatch(
    lapply(c("data/cascade.rds", "data/search_index.rds", "data/cascade_meta.rds"), readRDS),
    error = identity)
  ok <- is.list(reopened) && !inherits(reopened, "error") &&
    !length(cascade_artifact_text_issues(reopened, "cross-locale"))
  list(ok = ok, locale = active)
})
check(cross_locale_read$ok, "RDS artifacts reopen under an independent UTF-8 locale",
      cross_locale_read$locale)
raw_arrow <- rawToChar(as.raw(c(0xE2, 0x86, 0x92)))
raw_dash <- rawToChar(as.raw(c(0xE2, 0x80, 0x93)))
encoding_fixture <- list(arrow = raw_arrow, dash = raw_dash)
encoding_issues <- cascade_artifact_text_issues(encoding_fixture, "unknown")
check(sum(grepl("unmarked non-ASCII", encoding_issues, fixed = TRUE)) == 2L,
      "unmarked UTF-8 text is rejected consistently across locales")
foreign_fixture <- rawToChar(as.raw(c(0xE2, 0x86, 0x92)))
Encoding(foreign_fixture) <- "latin1"
foreign_issues <- cascade_artifact_text_issues(list(arrow = foreign_fixture), "foreign-mark")
check(sum(grepl("unmarked non-ASCII", foreign_issues, fixed = TRUE)) == 1L &&
        sum(grepl("changes during UTF-8 serialization", foreign_issues, fixed = TRUE)) == 1L,
      "foreign-marked text that changes during UTF-8 serialization is rejected")
encoding_fixture <- cascade_normalize_artifact_text(encoding_fixture)
check(!length(cascade_artifact_text_issues(encoding_fixture, "normalized")) &&
        identical(Encoding(encoding_fixture$arrow), "UTF-8") &&
        identical(charToRaw(enc2utf8(encoding_fixture$arrow)), as.raw(c(0xE2, 0x86, 0x92))),
      "artifact normalization preserves bytes and marks non-ASCII UTF-8")
control_fixture <- list(label = paste0("bad", intToUtf8(6L), intToUtf8(18L)))
check(length(cascade_artifact_text_issues(control_fixture, "control")) == 1L &&
        grepl("6,18", cascade_artifact_text_issues(control_fixture, "control"), fixed = TRUE),
      "artifact text contract rejects C0 control code points")
bundle_md5 <- unname(tools::md5sum("data/cascade.rds"))

check_cols(cascade, c("annual", "signals", "priors", "codebook", "suite_links",
                      "pooled", "site_meta", "meta"), "cascade top-level schema")
check(identical(cascade$meta$schema_version, CASCADE_BUNDLE_SCHEMA_VERSION), "cascade schema version",
      cascade$meta$schema_version %||% "<missing>")
check(identical(cascade$meta$tier_rule, TIER_RULE_VERSION), "bundle/helper tier-rule parity",
      TIER_RULE_VERSION)
check(identical(cascade$meta$prior_family_version, PRIOR_FAMILY_VERSION),
      "bundle/helper prior-family version parity", PRIOR_FAMILY_VERSION)
check(identical(cascade$meta$prior_family_status, PRIOR_FAMILY_STATUS),
      "bundle carries exploratory prior-family disclosure")
check(identical(cascade$meta$greenup_index_version, GREENUP_INDEX_VERSION) &&
        identical(cascade$meta$greenup_index_note, GREENUP_INDEX_NOTE) &&
        grepl("future refreshes can revise historical", cascade$meta$greenup_index_note,
              fixed = TRUE),
      "bundle carries retrospective green-up snapshot lineage")
check(identical(cascade$meta$trend_sensitivity_version, TREND_SENSITIVITY_VERSION) &&
        identical(cascade$meta$trend_sensitivity_note, TREND_SENSITIVITY_NOTE),
      "bundle carries exact trend-sensitivity lineage")
check(identical(cascade$meta$estimator_sensitivity_version, ESTIMATOR_SENSITIVITY_VERSION) &&
        identical(cascade$meta$estimator_sensitivity_note, ESTIMATOR_SENSITIVITY_NOTE),
      "bundle carries exact estimator-sensitivity lineage")
check(identical(cascade$meta$spatial_sensitivity_version, SPATIAL_SENSITIVITY_VERSION) &&
        identical(cascade$meta$spatial_sensitivity_note, SPATIAL_SENSITIVITY_NOTE) &&
        identical(unname(cascade$meta$data_caveats[["spatial_sensitivity"]]),
                  SPATIAL_SENSITIVITY_NOTE),
      "bundle carries exact spatial-sensitivity lineage")
check(is.finite(cascade$meta$last_complete_year), "last-complete-year recorded",
      as.character(cascade$meta$last_complete_year))

annual <- cascade$annual
signals <- cascade$signals
priors <- cascade$priors
suite <- cascade$suite_links
pooled <- cascade$pooled
site_meta <- cascade$site_meta

annual_sites <- sort(unique(annual$site))
check(!anyDuplicated(site_meta$site) && setequal(site_meta$site, annual_sites) &&
        setequal(site_meta$site, unique(suite$site)),
      "site metadata has exact annual/suite site parity")
expected_biome <- vapply(site_meta$site, biome_of, character(1))
expected_class <- vapply(site_meta$site, biome_class, character(1))
expected_label <- vapply(site_meta$site, biome_label, character(1))
expected_basis <- vapply(site_meta$site, biome_class_basis, character(1))
domain_row <- match(site_meta$site, neon_sites$site)
expected_domain <- as.character(neon_sites$domain[domain_row])
check(!anyNA(domain_row) && !anyNA(expected_domain) &&
        identical(as.character(site_meta$domain), expected_domain) &&
        identical(as.character(site_meta$biome), unname(expected_biome)) &&
        identical(as.character(site_meta$biome_class), unname(expected_class)) &&
        identical(as.character(site_meta$biome_label), unname(expected_label)) &&
        identical(as.character(site_meta$biome_class_basis), unname(expected_basis)) &&
        all(as.character(site_meta$biome_class_method) == BIOME_CLASS_METHOD) &&
        identical(unname(cascade$meta$data_caveats[["biome_class"]]), BIOME_CLASS_METHOD),
      "bundled grouping fields/method match current site-metadata heuristic")
check_cols(site_meta,
  c("veg_ba_ha", "veg_ba_se", "veg_type", "veg_n_plots",
    "veg_record_plots", "veg_matched_record_plots",
    "veg_area_eligible_plots", "veg_unmatched_record_plots",
    "veg_unmatched_record_rows", "veg_class_tree_ba_ha",
    "veg_class_shrub_ba_ha", "veg_class_tree_plots",
    "veg_class_shrub_plots", "veg_stand_basis", "veg_class_basis",
    "veg_design_status", "veg_design_basis"),
  "vegetation conditional-estimand audit schema")
veg_present <- is.finite(site_meta$veg_ba_ha)
veg_supported <- site_meta$veg_design_status %in% "supported"
veg_unsupported <- site_meta$veg_design_status %in%
  "unsupported-unmatched-plots"
check(all(!veg_present |
        (veg_supported & site_meta$veg_n_plots >= 1L &
          site_meta$veg_n_plots <= site_meta$veg_area_eligible_plots &
          site_meta$veg_area_eligible_plots <= site_meta$veg_record_plots &
          site_meta$veg_matched_record_plots == site_meta$veg_record_plots &
          site_meta$veg_unmatched_record_plots == 0L &
          site_meta$veg_unmatched_record_rows == 0L &
          site_meta$veg_stand_basis == CASCADE_VEG_STAND_BASIS &
          site_meta$veg_class_basis == CASCADE_VEG_CLASSIFICATION_BASIS)) &&
        all(!veg_unsupported |
          (!veg_present & is.na(site_meta$veg_type) &
            site_meta$veg_n_plots == 0L &
            site_meta$veg_area_eligible_plots == 0L &
            site_meta$veg_unmatched_record_plots > 0L &
            site_meta$veg_matched_record_plots +
              site_meta$veg_unmatched_record_plots ==
                site_meta$veg_record_plots)) &&
        all(!(veg_supported | veg_unsupported) |
          site_meta$veg_design_basis == CASCADE_VEG_DESIGN_BASIS) &&
        identical(unname(cascade$meta$data_caveats[["veg_ba_ha"]]),
                  CASCADE_VEG_STAND_BASIS) &&
        identical(unname(cascade$meta$data_caveats[["veg_type"]]),
                  CASCADE_VEG_CLASSIFICATION_BASIS) &&
        identical(unname(cascade$meta$data_caveats[["veg_design_support"]]),
                  CASCADE_VEG_DESIGN_BASIS),
      "vegetation context fails closed with used/eligible/record/design audits")
signal_cols <- as.character(signals$key)
support_cols <- c(
  "temp_n_months", "precip_n_months", "precip_winter_n_months",
  "precip_monsoon_n_months", "temp_spring_n_months",
  "fruiting_n_eligible_months", "fruiting_peak_n_individuals",
  "greenup_doy_additive",
  "greenup_onset_interval_median_days", "greenup_onset_interval_p90_days",
  "greenup_onset_interval_max_days",
  "greenup_n_onsets", "greenup_n_left_censored", "greenup_n_taxon_excluded",
  "greenup_n_individuals", "greenup_n_species", "greenup_reference_doy",
  "plant_n_plots", "plant_n_sampling_units",
  "plant_unknown_pct", "mammal_trap_nights", "mammal_captures",
  "mammal_placeholder_trap_rows", "mammal_multi_capture_trap_events",
  "mammal_reviewed_double_trap_events",
  "bird_observed_point_visits", "bird_nonflyover_birds", "bird_flyover_birds",
  "mosq_trap_nights", "mosq_total_catch",
  "beetle_catch_event_trap_nights", "beetle_total_catch")
check_cols(annual, c("site", "year", signal_cols, support_cols), "annual signal/support schema")
emitted_cols <- setdiff(names(annual), c("site", "year"))
check(setequal(emitted_cols, c(signal_cols, support_cols)),
      "annual emits only documented signal/support fields",
      sprintf("%d fields", length(emitted_cols)))
check(!anyDuplicated(paste(annual$site, annual$year, sep = "|")), "annual site-year key is unique",
      sprintf("%d rows", nrow(annual)))
check(all(annual$year >= cascade$meta$min_year & annual$year <= cascade$meta$last_complete_year),
      "annual years obey recorded cutoff",
      sprintf("%d-%d", min(annual$year), max(annual$year)))

month_contracts <- list(
  temp = c(count = "temp_n_months", needed = 12L, max = 12L),
  precip = c(count = "precip_n_months", needed = 12L, max = 12L),
  precip_winter = c(count = "precip_winter_n_months", needed = 6L, max = 6L),
  precip_monsoon = c(count = "precip_monsoon_n_months", needed = 3L, max = 3L),
  temp_spring = c(count = "temp_spring_n_months", needed = 3L, max = 3L))
for (key in names(month_contracts)) {
  spec <- month_contracts[[key]]
  count <- annual[[spec[["count"]]]]
  needed <- as.integer(spec[["needed"]]); max_n <- as.integer(spec[["max"]])
  check(is_integerish(count) && all(is.na(count) | (count >= 0 & count <= max_n)),
        sprintf("%s month support is valid", key))
  present <- is.finite(annual[[key]])
  check(all(!present) || all(is.finite(count[present]) & count[present] == needed),
        sprintf("%s requires a complete month window", key), sprintf("%d/%d", needed, max_n))
}

fruiting_opportunity <- annual$fruiting_n_eligible_months
fruiting_present <- is.finite(annual$fruiting_pct)
check(is_integerish(fruiting_opportunity) &&
        all(is.na(fruiting_opportunity) |
              fruiting_opportunity >= 0 & fruiting_opportunity <= 12) &&
        all(!fruiting_present |
              (fruiting_opportunity >= 1L &
                 is.finite(annual$fruiting_peak_n_individuals) &
                 annual$fruiting_peak_n_individuals >= 5)) &&
        all(fruiting_present |
              is.na(annual$fruiting_peak_n_individuals)),
      "opportunistic fruiting peak exposes eligible-month and peak-individual support")
check(grepl("Opportunistic maximum", unname(
        cascade$meta$data_caveats[["fruiting_pct"]]), fixed = TRUE),
      "fruiting caveat rejects fixed-season annual interpretation")

check(all(is.na(annual$plant_intro_pct) | annual$plant_intro_pct >= 0 & annual$plant_intro_pct <= 100),
      "introduced-cover range is valid")
check(all(is.na(annual$plant_unknown_pct) | annual$plant_unknown_pct >= 0 & annual$plant_unknown_pct <= 100),
      "unknown-cover range is valid")
greenup_present <- is.finite(annual$greenup_doy)
greenup_support <- is.finite(annual$greenup_n_onsets)
greenup_count_cols <- c("greenup_n_onsets", "greenup_n_left_censored",
                        "greenup_n_taxon_excluded", "greenup_n_individuals",
                        "greenup_n_species")
check(all(vapply(annual[greenup_count_cols], is_integerish, logical(1))) &&
        all(!greenup_support | (annual$greenup_n_onsets ==
          annual$greenup_n_left_censored + annual$greenup_n_taxon_excluded +
            annual$greenup_n_individuals)),
      "green-up censor/taxon/contributor audit buckets reconcile exactly")
check(all(!greenup_present) ||
        all(annual$greenup_n_individuals[greenup_present] >= 6L &
              annual$greenup_n_species[greenup_present] >= 2L &
              is.finite(annual$greenup_reference_doy[greenup_present])),
      "green-up index obeys connected repeated-species and contributor gates")
reference_counts <- vapply(split(annual$greenup_reference_doy, annual$site), function(x)
  length(unique(x[is.finite(x)])), integer(1))
check(all(reference_counts <= 1L), "green-up DOY reference is fixed within each site")
check(identical(is.finite(annual$greenup_doy), is.finite(annual$greenup_doy_additive)),
      "primary/additive green-up estimators have exactly the same finite keys")
greenup_width_cols <- c("greenup_onset_interval_median_days",
                        "greenup_onset_interval_p90_days",
                        "greenup_onset_interval_max_days")
has_greenup_contributors <- is.finite(annual$greenup_n_individuals) &
  annual$greenup_n_individuals > 0L
check(all(vapply(annual[greenup_width_cols], function(x)
          identical(is.finite(x), has_greenup_contributors), logical(1))) &&
        all(!has_greenup_contributors |
              (annual$greenup_onset_interval_median_days >= 0 &
                 annual$greenup_onset_interval_median_days <=
                   annual$greenup_onset_interval_p90_days &
                 annual$greenup_onset_interval_p90_days <=
                   annual$greenup_onset_interval_max_days)),
      "green-up contributor interval-width keys and ordering reconcile exactly")
present <- is.finite(annual$bird_index)
check(all(!present) || same_num(
        annual$bird_index[present],
        annual$bird_nonflyover_birds[present] /
          annual$bird_observed_point_visits[present], tolerance = 1e-15),
      "bird index uses observed point-count occasions and excludes flyovers")
present <- is.finite(annual$mammal_cpue)
check(all(!present) || same_num(
        annual$mammal_cpue[present],
        100 * annual$mammal_captures[present] /
          annual$mammal_trap_nights[present], tolerance = 1e-15),
      "mammal CPUE support reproduces index")
mammal_rule_support <- c(
  "mammal_placeholder_trap_rows", "mammal_multi_capture_trap_events",
  "mammal_reviewed_double_trap_events")
mammal_effort_present <- is.finite(annual$mammal_trap_nights)
check(all(vapply(annual[mammal_rule_support], is_integerish, logical(1))) &&
        all(vapply(annual[mammal_rule_support], function(x)
          identical(is.finite(x), mammal_effort_present), logical(1))) &&
        all(vapply(annual[mammal_rule_support], function(x)
          all(is.na(x) | x >= 0), logical(1))),
      paste("mammal effort exposes nonnegative integer placeholder, multi-capture,",
            "and reviewed-double-trap audit counts on every effort calendar row"))
present <- is.finite(annual$mosq_activity)
check(all(!present) || same_num(
        annual$mosq_activity[present],
        annual$mosq_total_catch[present] /
          annual$mosq_trap_nights[present], tolerance = 1e-15),
      "mosquito effort support reproduces index")
present <- is.finite(annual$beetle_activity)
check(all(!present) || same_num(
        annual$beetle_activity[present],
        100 * annual$beetle_total_catch[present] /
          annual$beetle_catch_event_trap_nights[present], tolerance = 1e-15),
      "beetle recorded-effort support reproduces index")

# All seven source products must have exact, nonempty provenance and output coverage.
products <- c("mammal", "plant", "veg", "bird", "phe", "mosq", "beetle")
expected_origins <- c(
  mammal = "github.com/tgilbert14/neon-small-mammal-tracker-app",
  plant = "github.com/tgilbert14/neon-plant-diversity",
  veg = "github.com/tgilbert14/neon-vegetation-structure-explorer",
  bird = "github.com/tgilbert14/neon-breeding-birds",
  phe = "github.com/tgilbert14/neon-plant-phenology-explorer",
  mosq = "github.com/tgilbert14/neon-mosquito-pulse",
  beetle = "github.com/tgilbert14/neon-ground-beetle-tracker")
sp <- cascade$meta$source_products
pc <- cascade$meta$product_coverage
si <- cascade$meta$source_inputs
lbi <- cascade$meta$local_build_inputs
bt <- cascade$meta$build_toolchain
vo <- cascade$meta$vote_overlap

check_cols(sp, c("product", "repo", "origin", "commit", "commit_epoch",
                 "clean", "n_site_files"), "source-product provenance schema")
check(nrow(sp) == length(products) && !anyDuplicated(sp$product) &&
        setequal(as.character(sp$product), products),
      "exactly seven source products are fingerprinted",
      paste(sort(sp$product), collapse = ", "))
check(!anyNA(sp$repo) && all(nzchar(as.character(sp$repo))) &&
        !anyNA(sp$origin) && all(nzchar(as.character(sp$origin))) &&
        setequal(paste(sp$product, sp$origin, sep = "|"),
                 paste(names(expected_origins), expected_origins, sep = "|")),
      "source repositories carry exact canonical origins")
check(!anyNA(sp$commit) && all(grepl("^[0-9a-f]{40}$", sp$commit)),
      "all source git commits are recorded")
check(is.numeric(sp$commit_epoch) && !anyNA(sp$commit_epoch) &&
        all(is.finite(sp$commit_epoch) & sp$commit_epoch >= 0),
      "all source commit epochs are finite")
check(is.numeric(sp$n_site_files) && !anyNA(sp$n_site_files) &&
        all(is.finite(sp$n_site_files) &
              sp$n_site_files == floor(sp$n_site_files) &
              sp$n_site_files > 0),
      "all source products contain a positive integer count of site bundles")
check(is.logical(sp$clean) && !anyNA(sp$clean) && all(sp$clean),
      "all fingerprinted source repositories were clean")
expected_built_when <- format(
  as.POSIXct(max(sp$commit_epoch), origin = "1970-01-01", tz = "UTC"),
  "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
check(identical(cascade$meta$built_when, expected_built_when),
      "bundle build timestamp is a deterministic function of source commits",
      expected_built_when)
check(identical(cascade$meta$source_snapshot_method,
                "git-archive-recorded-commit-v1"),
      "bundle records immutable Git-object source materialization")
expected_cutoff_epoch <- max(sp$commit_epoch)
expected_source_cutoff <- as.integer(format(
  as.POSIXct(expected_cutoff_epoch, origin = "1970-01-01", tz = "UTC"),
  "%Y", tz = "UTC")) - 1L
check(identical(as.numeric(cascade$meta$last_complete_year_source_epoch),
                as.numeric(expected_cutoff_epoch)) &&
        cascade$meta$last_complete_year_basis %in%
          c("UTC year(max source commit epoch) - 1",
            "explicit CASCADE_LAST_COMPLETE_YEAR") &&
        as.integer(cascade$meta$last_complete_year) <= expected_source_cutoff &&
        (cascade$meta$last_complete_year_basis !=
           "UTC year(max source commit epoch) - 1" ||
           identical(as.integer(cascade$meta$last_complete_year),
                     expected_source_cutoff)) &&
        grepl("cascade_resolve_last_complete_year(", build_source, fixed = TRUE),
      "cutoff is strict and deterministic from source provenance unless explicitly overridden")
expected_local_build_paths <- c(
  "scripts/build_cascade.R", "scripts/generation_guard.R",
  "scripts/source_snapshot.R", "R/cascade_helpers.R",
  "R/site_metadata.R", "R/source_adapters.R")
check(is.data.frame(lbi) &&
        identical(names(lbi), c("relative_path", "md5")) &&
        identical(as.character(lbi$relative_path),
                  expected_local_build_paths) &&
        identical(as.character(lbi$md5),
                  unname(tools::md5sum(expected_local_build_paths))) &&
        identical(cascade$meta$build_script_md5,
                  lbi$md5[lbi$relative_path == "scripts/build_cascade.R"]) &&
        identical(cascade$meta$source_adapters_md5,
                  lbi$md5[lbi$relative_path == "R/source_adapters.R"]),
      "bundle fingerprints every local executable build input")

check_cols(si, c("product", "relative_path", "md5", "bytes"),
           "source-input fingerprint schema")
input_key <- paste(si$product, si$relative_path, sep = "|")
check(nrow(si) > 0L && !anyNA(si$product) &&
        all(nzchar(as.character(si$product))) &&
        setequal(as.character(si$product), products) &&
        !anyNA(si$relative_path) && all(nzchar(as.character(si$relative_path))) &&
        !anyDuplicated(input_key) && !anyNA(si$md5) &&
        all(grepl("^[0-9a-f]{32}$", as.character(si$md5))) &&
        is.numeric(si$bytes) && !anyNA(si$bytes) &&
        all(is.finite(si$bytes) & si$bytes >= 0 &
              si$bytes == floor(si$bytes)) &&
        all(table(factor(si$product, levels = products)) > 0L),
      "every required tracked source input has one exact nonempty fingerprint",
      sprintf("%d files", nrow(si)))

check_cols(bt, c("component", "version"), "bundle build-toolchain schema")
check(nrow(bt) == 3L && !anyDuplicated(bt$component) &&
        setequal(as.character(bt$component), c("R", "dplyr", "tibble")) &&
        !anyNA(bt$version) && all(nzchar(as.character(bt$version))),
      "bundle records the complete nonempty R/dplyr/tibble build toolchain")

check_cols(pc, c("product", "signal", "n_nonmissing", "n_sites"),
           "product-coverage schema")
expected_coverage_keys <- c(
  "mammal|mammal_cpue", "plant|plant_richness", "bird|bird_index",
  "phe|greenup_doy", "mosq|mosq_activity", "beetle|beetle_activity",
  "mammal|temp", "mammal|precip", "mammal|temp_spring", "veg|veg_ba_ha")
coverage_key <- paste(pc$product, pc$signal, sep = "|")
check(nrow(pc) == length(expected_coverage_keys) &&
        !anyDuplicated(coverage_key) &&
        setequal(coverage_key, expected_coverage_keys) &&
        setequal(as.character(pc$product), products),
      "product coverage has the exact product-signal inventory")
coverage_expected <- lapply(seq_len(nrow(pc)), function(i) {
  key <- as.character(pc$signal[i])
  if (identical(key, "veg_ba_ha")) {
    c(n_nonmissing = sum(is.finite(site_meta$veg_ba_ha)),
      n_sites = sum(is.finite(site_meta$veg_ba_ha)))
  } else {
    c(n_nonmissing = sum(is.finite(annual[[key]])),
      n_sites = length(unique(annual$site[is.finite(annual[[key]])])))
  }
})
coverage_expected <- do.call(rbind, coverage_expected)
check(identical(as.integer(pc$n_nonmissing),
                as.integer(coverage_expected[, "n_nonmissing"])) &&
        identical(as.integer(pc$n_sites),
                  as.integer(coverage_expected[, "n_sites"])) &&
        all(pc$n_nonmissing > 0 & pc$n_sites > 0),
      "every product coverage row is non-vacuous and exactly recomputed")
climate_coverage <- pc[pc$product == "mammal" &
                         pc$signal %in% c("temp", "precip", "temp_spring"), ,
                       drop = FALSE]
check(nrow(climate_coverage) == 3L &&
        setequal(climate_coverage$signal, c("temp", "precip", "temp_spring")) &&
        all(climate_coverage$n_nonmissing > 0 & climate_coverage$n_sites > 0),
      "annual and spring climate coverage is explicitly non-vacuous")

check_cols(vo, c("from", "to", "n_sites_eligible"),
           "vote-eligible overlap schema")
vote_key <- paste(vo$from, vo$to, sep = "|")
expected_vote_key <- c("temp|greenup_doy", "temp_spring|greenup_doy")
expected_vote_sites <- vapply(vo$from, function(from) {
  paired <- tapply(is.finite(annual[[from]]) & is.finite(annual$greenup_doy),
                   annual$site, sum)
  sum(paired >= 6L)
}, integer(1))
check(nrow(vo) == 2L && !anyDuplicated(vote_key) &&
        setequal(vote_key, expected_vote_key) &&
        identical(as.integer(vo$n_sites_eligible),
                  as.integer(expected_vote_sites)) &&
        all(vo$n_sites_eligible > 0L),
      "both vote-eligible climate/green-up links have nonempty six-year site overlap")

expected_suite_rows <- length(unique(annual$site)) * nrow(priors)
suite_key <- paste(suite$site, suite$from, suite$to, suite$lag, sep = "|")
check(nrow(suite) == expected_suite_rows, "suite is a complete site x prior grid",
      sprintf("%d = %d sites x %d priors", nrow(suite), length(unique(annual$site)), nrow(priors)))
check(!anyDuplicated(suite_key), "suite site-prior key is unique")
check(setequal(unique(suite$site), unique(annual$site)), "annual/suite site parity")
check(setequal(unique(link_id(suite)), link_id(priors)), "suite/prior link parity")
check(identical(as.character(suite$domain),
                as.character(site_meta$domain[match(suite$site, site_meta$site)])),
      "suite rows carry the strict site-to-NEON-domain mapping")
check_cols(priors, c("from", "to", "lag", "sign", "expected_class",
                    "conf", "note"), "registered-prior schema")
check(is.numeric(priors$sign) && !anyNA(priors$sign) &&
        all(is.finite(priors$sign) & priors$sign %in% c(-1L, 1L)) &&
        !anyNA(priors$conf) && all(nzchar(as.character(priors$conf))) &&
        !anyNA(priors$note) && all(nzchar(as.character(priors$note))),
      "registered prior signs, confidence grades, and notes are complete")
check(all(suite$tier %in% names(TIER_META)), "suite tiers are known")
check_cols(suite, c("prior_sign", "verdict", "conf", "note"),
           "suite prior/verdict schema")
check(is.numeric(suite$prior_sign) && !anyNA(suite$prior_sign) &&
        all(is.finite(suite$prior_sign) & suite$prior_sign %in% c(-1L, 1L)) &&
        !anyNA(suite$verdict) && all(nzchar(as.character(suite$verdict))) &&
        !anyNA(suite$conf) && all(nzchar(as.character(suite$conf))) &&
        !anyNA(suite$note) && all(nzchar(as.character(suite$note))),
      "suite prior signs, verdicts, confidence grades, and notes are complete")
check_cols(suite, c("p_floor", "n_null", "series_span", "ci_excludes_zero",
                    "n_detrended", "r_detrended", "sign_match_detrended",
                    "n_change", "r_change", "sign_match_change",
                    "n_outcome_alt", "r_outcome_alt", "sign_match_outcome_alt"),
           "suite randomization-audit schema")

# Independently derive every non-Monte-Carlo site-link field from the bundled
# annual table. This catches a stale or partially rebuilt suite even when its
# row count and schema still look valid.
suite_derived <- lapply(seq_len(nrow(suite)), function(i) {
  row <- suite[i, , drop = FALSE]
  a <- annual[annual$site == row$site, , drop = FALSE]
  g <- lag_grid(a, row$from, row$to, row$lag)
  m <- if (nrow(g)) g[is.finite(g$x) & is.finite(g$y), , drop = FALSE] else g
  r <- if (nrow(m) >= 3L) suppressWarnings(stats::cor(m$x, m$y)) else NA_real_
  if (!is.finite(r)) r <- NA_real_
  sensitivity <- link_trend_sensitivity(
    g, row$prior_sign,
    raw_eligible = nrow(m) >= 6L && is.finite(r) && !is.na(row$sign_match))
  alt <- list(n = 0L, r = NA_real_, sign = NA)
  if (identical(as.character(row$to), "greenup_doy")) {
    ga <- lag_grid(a, row$from, "greenup_doy_additive", row$lag)
    ma <- if (nrow(ga)) ga[is.finite(ga$x) & is.finite(ga$y), , drop = FALSE] else ga
    ra <- if (nrow(ma) >= 3L) suppressWarnings(stats::cor(ma$x, ma$y)) else NA_real_
    if (!is.finite(ra)) ra <- NA_real_
    sign_alt <- if (is.finite(ra) && abs(ra) > sqrt(.Machine$double.eps))
      sign(ra) == sign(row$prior_sign) else NA
    alt <- list(n = nrow(ma), r = ra, sign = sign_alt)
  }
  data.frame(
    n = nrow(m), r = r, series_span = nrow(g),
    n_detrended = sensitivity$n_detrended,
    r_detrended = sensitivity$r_detrended,
    sign_match_detrended = sensitivity$sign_match_detrended,
    n_change = sensitivity$n_change,
    r_change = sensitivity$r_change,
    sign_match_change = sensitivity$sign_match_change,
    n_outcome_alt = alt$n,
    r_outcome_alt = alt$r,
    sign_match_outcome_alt = alt$sign,
    year_min = if (nrow(m)) min(m$year) else NA_integer_,
    year_max = if (nrow(m)) max(m$year) else NA_integer_)
})
suite_derived <- dplyr::bind_rows(suite_derived)
check(identical(as.integer(suite$n), as.integer(suite_derived$n)) &&
        same_num(suite$r, suite_derived$r, tolerance = 1e-15) &&
        identical(as.integer(suite$series_span), as.integer(suite_derived$series_span)),
      "every suite effect/count/span recomputes from bundled annual data")
check(identical(as.integer(suite$n_detrended), as.integer(suite_derived$n_detrended)) &&
        same_num(suite$r_detrended, suite_derived$r_detrended, tolerance = 1e-12) &&
        identical(as.logical(suite$sign_match_detrended),
                  as.logical(suite_derived$sign_match_detrended)) &&
        identical(as.integer(suite$n_change), as.integer(suite_derived$n_change)) &&
        same_num(suite$r_change, suite_derived$r_change, tolerance = 1e-12) &&
        identical(as.logical(suite$sign_match_change),
                  as.logical(suite_derived$sign_match_change)),
      "every suite detrended/change sensitivity recomputes exactly")
check(identical(as.integer(suite$n_outcome_alt), as.integer(suite_derived$n_outcome_alt)) &&
        same_num(suite$r_outcome_alt, suite_derived$r_outcome_alt, tolerance = 1e-15) &&
        identical(as.logical(suite$sign_match_outcome_alt),
                  as.logical(suite_derived$sign_match_outcome_alt)) &&
        all(suite$n_outcome_alt[suite$to == "greenup_doy"] ==
              suite$n[suite$to == "greenup_doy"]) &&
        all(suite$n_outcome_alt[suite$to != "greenup_doy"] == 0L) &&
        all(is.na(suite$r_outcome_alt[suite$to != "greenup_doy"])) &&
        all(is.na(suite$sign_match_outcome_alt[suite$to != "greenup_doy"])),
      "every suite alternate-outcome sensitivity recomputes exactly")

prior_row <- match(link_id(suite), link_id(priors))
expected_here <- priors$expected_class[prior_row] == "all" |
  priors$expected_class[prior_row] == suite$biome_class
check(!anyNA(prior_row) &&
        identical(as.integer(suite$prior_sign), as.integer(priors$sign[prior_row])) &&
        identical(as.character(suite$expected_class),
                  as.character(priors$expected_class[prior_row])) &&
        identical(as.character(suite$conf), as.character(priors$conf[prior_row])) &&
        identical(as.character(suite$note), as.character(priors$note[prior_row])) &&
        identical(as.logical(suite$expected), as.logical(expected_here)),
      "suite prior fields and biome-expected flags recompute exactly")

expected_sign_match <- rep(NA, nrow(suite))
directional <- is.finite(suite$r) & abs(suite$r) > sqrt(.Machine$double.eps)
expected_sign_match[directional] <- sign(suite$r[directional]) == sign(suite$prior_sign[directional])
check(identical(as.logical(suite$sign_match), as.logical(expected_sign_match)),
      "suite direction votes use full-precision nonzero effects")
expected_tier <- vapply(seq_len(nrow(suite)), function(i) {
  if (suite$n[i] < 3L) return("insufficient")
  if (suite$n[i] < 6L) return("exploratory")
  if (!is.finite(suite$r[i]) || is.na(suite$sign_match[i])) return("neutral")
  if (isTRUE(suite$sign_match[i]) && isTRUE(suite$ci_excludes_zero[i])) return("consistent")
  if (isTRUE(suite$sign_match[i])) "apparent" else "counter"
}, character(1))
check(identical(as.character(suite$tier), expected_tier),
      "every suite tier follows the current n/direction/CI rule")
vote_prior <- priors$expected_class == "all"
expected_vote_ids <- c("temp|greenup_doy|0", "temp_spring|greenup_doy|0")
check(sum(vote_prior) == 2L && setequal(link_id(priors[vote_prior, , drop = FALSE]),
                                       expected_vote_ids) &&
        all(priors$expected_class[!vote_prior] == "none") &&
        !any(priors$expected_class %in% c("water-limited", "temperature-limited")),
      "only the two green-up temperature contrasts are vote-eligible")
richness_prior <- priors$from == "plant_richness" | priors$to == "plant_richness"
check(all(priors$expected_class[richness_prior] == "none"),
      "raw plant-richness links are context-only until effort-standardized")
richness_to_mammal <- priors$from == "plant_richness" & priors$to == "mammal_cpue"
check(sum(richness_to_mammal) == 1L && priors$conf[richness_to_mammal] == "none",
      "effort-confounded richness-to-mammal prior carries no confidence grade")

finite_p <- is.finite(suite$p)
check(all(!finite_p | suite$n >= 6), "per-site p-values obey n>=6 gate")
check(all(suite$series_span >= suite$n & suite$n_null >= 0L),
      "calendar span/null counts dominate complete-pair counts")
check(all(!finite_p | (is.finite(suite$p_floor) & suite$n_null > 0L &
                         abs(suite$p_floor - 1 / (suite$n_null + 1L)) < 1e-12 &
                         suite$p >= suite$p_floor - 1e-12 & suite$p <= 1)),
      "circular p-values obey their full-precision link-specific floor")
check(all(!finite_p | suite$n_null <= suite$series_span - 1L),
      "valid circular null shifts cannot exceed calendar span minus one")
check(all(suite$ci_excludes_zero %in% c(TRUE, FALSE, NA)),
      "CI boundary audit is explicitly stored")
finite_ci <- is.finite(suite$lo) & is.finite(suite$hi)
ci_expected <- mapply(ci_excludes_zero, suite$lo[finite_ci], suite$hi[finite_ci])
check(all(suite$ci_excludes_zero[finite_ci] == ci_expected),
      "stored CI boundary flag matches full-precision interval endpoints")

check_cols(pooled, c("from", "to", "lag", "sites", "k", "p", "p_holm", "p_fdr",
                     "poolable", "median_r", "sites_detrended", "k_detrended",
                     "sites_change", "k_change", "sites_outcome_alt",
                     "k_outcome_alt", "domains", "k_domain", "domain_ties"),
           "pooled inference schema")
check(nrow(pooled) == nrow(priors), "zero-supported priors remain visible in pooled table")
check(setequal(link_id(pooled), link_id(priors)), "pooled/prior link parity")
adj <- is.finite(pooled$p)
check(all(!adj | pooled$p_holm + 1e-12 >= pooled$p), "Holm p-values do not undercut raw p")
check(all(!adj | pooled$p_fdr + 1e-12 >= pooled$p), "FDR p-values do not undercut raw p")
expected_median <- vapply(seq_len(nrow(pooled)), function(i) {
  keep <- suite$from == pooled$from[i] & suite$to == pooled$to[i] &
    suite$lag == pooled$lag[i] & suite$expected %in% TRUE &
    suite$n >= 6L & is.finite(suite$r)
  if (any(keep)) stats::median(suite$r[keep]) else NA_real_
}, numeric(1))
check(same_num(pooled$median_r, expected_median, tolerance = 1e-15),
      "pooled median effects retain full suite precision")
expected_sensitivity <- lapply(seq_len(nrow(pooled)), function(i) {
  keep <- suite$from == pooled$from[i] & suite$to == pooled$to[i] &
    suite$lag == pooled$lag[i] & suite$expected %in% TRUE &
    suite$n >= 6L & !is.na(suite$sign_match)
  d <- suite[keep, , drop = FALSE]
  by_domain <- split(as.logical(d$sign_match), as.character(d$domain), drop = TRUE)
  margin <- vapply(by_domain, function(v) sum(v) - sum(!v), integer(1))
  data.frame(
    sites_detrended = sum(!is.na(d$sign_match_detrended)),
    k_detrended = sum(d$sign_match_detrended %in% TRUE),
    sites_change = sum(!is.na(d$sign_match_change)),
    k_change = sum(d$sign_match_change %in% TRUE),
    sites_outcome_alt = sum(!is.na(d$sign_match_outcome_alt)),
    k_outcome_alt = sum(d$sign_match_outcome_alt %in% TRUE),
    domains = sum(margin != 0L),
    k_domain = sum(margin > 0L),
    domain_ties = sum(margin == 0L))
})
expected_sensitivity <- dplyr::bind_rows(expected_sensitivity)
check(identical(as.integer(pooled$sites_detrended), as.integer(expected_sensitivity$sites_detrended)) &&
        identical(as.integer(pooled$k_detrended), as.integer(expected_sensitivity$k_detrended)) &&
        identical(as.integer(pooled$sites_change), as.integer(expected_sensitivity$sites_change)) &&
        identical(as.integer(pooled$k_change), as.integer(expected_sensitivity$k_change)) &&
        all(pooled$k_detrended <= pooled$sites_detrended &
              pooled$sites_detrended <= pooled$sites &
              pooled$k_change <= pooled$sites_change & pooled$sites_change <= pooled$sites),
      "pooled trend sensitivities are exact counts on raw-eligible sites")
check(identical(as.integer(pooled$sites_outcome_alt),
                as.integer(expected_sensitivity$sites_outcome_alt)) &&
        identical(as.integer(pooled$k_outcome_alt),
                  as.integer(expected_sensitivity$k_outcome_alt)) &&
        all(pooled$k_outcome_alt <= pooled$sites_outcome_alt &
              pooled$sites_outcome_alt <= pooled$sites) &&
        all(pooled$sites_outcome_alt[pooled$to != "greenup_doy"] == 0L) &&
        !any(grepl("outcome_alt.*p|p.*outcome_alt", names(pooled))),
      "pooled alternate-outcome sensitivity is an exact count on raw-vote sites")
check(identical(as.integer(pooled$domains), as.integer(expected_sensitivity$domains)) &&
        identical(as.integer(pooled$k_domain), as.integer(expected_sensitivity$k_domain)) &&
        identical(as.integer(pooled$domain_ties),
                  as.integer(expected_sensitivity$domain_ties)) &&
        all(pooled$k_domain <= pooled$domains &
              pooled$domains + pooled$domain_ties <= pooled$sites) &&
        !any(grepl("domain.*p|p.*domain", names(pooled))),
      "pooled NEON-domain majorities exactly collapse the raw site-vote population")
expected_raw <- vapply(which(adj), function(i)
  stats::binom.test(pooled$k[i], pooled$sites[i], 0.5, alternative = "greater")$p.value,
  numeric(1))
check(isTRUE(all.equal(pooled$p[adj], expected_raw, tolerance = 1e-15)),
      "pooled raw exact p-values retain full precision")
check(isTRUE(all.equal(pooled$p_holm[adj], stats::p.adjust(pooled$p[adj], "holm"), tolerance = 1e-15)) &&
        isTRUE(all.equal(pooled$p_fdr[adj], stats::p.adjust(pooled$p[adj], "BH"), tolerance = 1e-15)),
      "pooled multiplicity adjustments use unrounded raw p-values")

# Search is a pure, fingerprinted projection of this exact cascade bundle.
check_cols(search, c("links", "link_catalog", "site_strength", "prior_pooled",
                     "schema_version", "source_bundle_md5", "source_bundle_rows",
                     "source_bundle_priors", "trend_sensitivity_version",
                     "trend_sensitivity_note", "estimator_sensitivity_version",
                     "estimator_sensitivity_note", "spatial_sensitivity_version",
                     "spatial_sensitivity_note", "greenup_index_version",
                     "greenup_index_note", "n_sites", "n_links"),
           "search-index schema")
check(identical(search$schema_version, SEARCH_INDEX_SCHEMA_VERSION), "search schema version")
check(identical(search$built, cascade$meta$built_when),
      "search build stamp matches deterministic source snapshot")
check(identical(search$source_bundle_md5, bundle_md5), "search/cascade source hash parity", bundle_md5)
check(search$source_bundle_rows == nrow(suite) && search$source_bundle_priors == nrow(priors),
      "search source dimensions match cascade")
check(identical(search$trend_sensitivity_version, TREND_SENSITIVITY_VERSION) &&
        identical(search$trend_sensitivity_note, TREND_SENSITIVITY_NOTE) &&
        identical(search$estimator_sensitivity_version, ESTIMATOR_SENSITIVITY_VERSION) &&
        identical(search$estimator_sensitivity_note, ESTIMATOR_SENSITIVITY_NOTE) &&
        identical(search$spatial_sensitivity_version, SPATIAL_SENSITIVITY_VERSION) &&
        identical(search$spatial_sensitivity_note, SPATIAL_SENSITIVITY_NOTE) &&
        identical(search$greenup_index_version, GREENUP_INDEX_VERSION) &&
        identical(search$greenup_index_note, GREENUP_INDEX_NOTE),
      "search carries exact sensitivity lineage")
check(nrow(search$links) == nrow(suite), "search/suite row parity")
check_cols(search$links, c("p_floor", "n_null", "series_span", "ci_excludes_zero",
                           "n_detrended", "r_detrended", "sign_match_detrended",
                           "n_change", "r_change", "sign_match_change",
                           "n_outcome_alt", "r_outcome_alt", "sign_match_outcome_alt",
                           "year_min", "year_max", "site_year_min", "site_year_max"),
           "search link audit/paired-year schema")
search_key <- paste(search$links$site, search$links$driver, search$links$response,
                    search$links$lag, sep = "|")
check(setequal(search_key, suite_key), "search/suite site-link key parity")
suite_order <- match(search_key, suite_key)
check(!anyNA(suite_order) && same_num(search$links$r, suite$r[suite_order], tolerance = 1e-15) &&
        same_num(search$links$p, suite$p[suite_order], tolerance = 1e-15) &&
        identical(as.character(search$links$domain),
                  as.character(suite$domain[suite_order])),
      "search preserves full-precision suite effects and p-values")
check(identical(as.integer(search$links$n_detrended), as.integer(suite$n_detrended[suite_order])) &&
        same_num(search$links$r_detrended, suite$r_detrended[suite_order], tolerance = 1e-15) &&
        identical(as.logical(search$links$sign_match_detrended),
                  as.logical(suite$sign_match_detrended[suite_order])) &&
        identical(as.integer(search$links$n_change), as.integer(suite$n_change[suite_order])) &&
        same_num(search$links$r_change, suite$r_change[suite_order], tolerance = 1e-15) &&
        identical(as.logical(search$links$sign_match_change),
                  as.logical(suite$sign_match_change[suite_order])) &&
        identical(as.integer(search$links$n_outcome_alt),
                  as.integer(suite$n_outcome_alt[suite_order])) &&
        same_num(search$links$r_outcome_alt, suite$r_outcome_alt[suite_order], tolerance = 1e-15) &&
        identical(as.logical(search$links$sign_match_outcome_alt),
                  as.logical(suite$sign_match_outcome_alt[suite_order])),
      "search preserves exact trend and alternate-outcome site sensitivities")
check(same_num(search$links$year_min, suite_derived$year_min[suite_order], tolerance = 0) &&
        same_num(search$links$year_max, suite_derived$year_max[suite_order], tolerance = 0),
      "search paired-year bounds exactly match each link's complete pairs")
paired <- is.finite(search$links$year_min) | is.finite(search$links$year_max)
check(all(!paired | (is.finite(search$links$year_min) & is.finite(search$links$year_max) &
                       search$links$year_min <= search$links$year_max &
                       search$links$site_year_min <= search$links$year_min &
                       search$links$year_max <= search$links$site_year_max)),
      "search paired-year bounds stay within site-record bounds")
check(nrow(search$link_catalog) == nrow(priors), "search/prior catalogue parity")
check(setequal(search$link_catalog$link_id, link_id(priors)), "search/prior link-id parity")
check(!"is_signif" %in% names(search$links) && "is_aligned" %in% names(search$links),
      "search cannot resurrect obsolete per-site significance")
check_cols(search$prior_pooled,
           c("sites_detrended", "k_detrended", "sites_change", "k_change",
             "sites_outcome_alt", "k_outcome_alt", "domains", "k_domain",
             "domain_ties"),
           "search pooled-sensitivity schema")
search_pooled_order <- match(search$prior_pooled$link_id, link_id(pooled))
check(!anyNA(search_pooled_order) &&
        identical(as.integer(search$prior_pooled$sites_detrended),
                  as.integer(pooled$sites_detrended[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$k_detrended),
                  as.integer(pooled$k_detrended[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$sites_change),
                  as.integer(pooled$sites_change[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$k_change),
                  as.integer(pooled$k_change[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$sites_outcome_alt),
                  as.integer(pooled$sites_outcome_alt[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$k_outcome_alt),
                  as.integer(pooled$k_outcome_alt[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$domains),
                  as.integer(pooled$domains[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$k_domain),
                  as.integer(pooled$k_domain[search_pooled_order])) &&
        identical(as.integer(search$prior_pooled$domain_ties),
                  as.integer(pooled$domain_ties[search_pooled_order])),
      "search pooled sensitivities are exact cascade projections")

# Companion meta-analysis remains a list for server compatibility; lineage is in attributes.
check(is.list(meta_companion) && length(meta_companion) == 2L, "green-up meta result shape")
check(identical(attr(meta_companion, "schema_version"), CASCADE_META_SCHEMA_VERSION), "meta schema version")
check(identical(attr(meta_companion, "built"), cascade$meta$built_when) &&
        identical(attr(meta_companion, "source_snapshot_method"),
                  cascade$meta$source_snapshot_method),
      "meta build stamp and immutable-source lineage match the cascade snapshot")
check(identical(attr(meta_companion, "source_bundle_md5"), bundle_md5),
      "meta/cascade source hash parity", bundle_md5)
check(identical(attr(meta_companion, "inference_schema"),
                "cascade-meta-reml-knha-holm-prediction-v1") &&
        identical(attr(meta_companion, "multiplicity_method"), "holm") &&
        identical(attr(meta_companion, "multiplicity_family"),
                  c("temp|greenup_doy", "temp_spring|greenup_doy")),
      "meta companion persists exact KH/prediction/Holm inference schema")
toolchain_versions <- stats::setNames(as.character(bt$version),
                                     as.character(bt$component))
meta_toolchain <- attr(meta_companion, "build_toolchain")
meta_local_inputs <- attr(meta_companion, "local_meta_inputs")
meta_source_local_build_inputs <- attr(meta_companion, "source_local_build_inputs")
expected_local_meta_paths <- c(
  "scripts/cascade_meta.R", "scripts/generation_guard.R",
  "R/cascade_helpers.R")
ran_brms <- any(vapply(meta_companion, function(x) !is.null(x$brms), logical(1)))
expected_meta_components <- c("R", "dplyr", "tibble", "metafor",
                              if (ran_brms) c("brms", "posterior"))
meta_versions <- if (is.data.frame(meta_toolchain))
  stats::setNames(as.character(meta_toolchain$version),
                  as.character(meta_toolchain$component)) else character()
check(is.data.frame(meta_toolchain) &&
        !anyDuplicated(meta_toolchain$component) &&
        setequal(as.character(meta_toolchain$component),
                 expected_meta_components) &&
        !anyNA(meta_toolchain$version) &&
        all(nzchar(as.character(meta_toolchain$version))) &&
        identical(attr(meta_companion, "r_version"),
                  unname(toolchain_versions[["R"]])) &&
        identical(attr(meta_companion, "dplyr_version"),
                  unname(toolchain_versions[["dplyr"]])) &&
        identical(attr(meta_companion, "tibble_version"),
                  unname(toolchain_versions[["tibble"]])) &&
        identical(attr(meta_companion, "r_version"),
                  unname(meta_versions[["R"]])) &&
        identical(attr(meta_companion, "dplyr_version"),
                  unname(meta_versions[["dplyr"]])) &&
        identical(attr(meta_companion, "tibble_version"),
                  unname(meta_versions[["tibble"]])) &&
        identical(attr(meta_companion, "metafor_version"),
                  unname(meta_versions[["metafor"]])),
      "meta companion records every direct nonempty build package")
check(identical(meta_source_local_build_inputs, lbi) &&
        is.data.frame(meta_local_inputs) &&
        identical(names(meta_local_inputs), c("relative_path", "md5")) &&
        identical(as.character(meta_local_inputs$relative_path),
                  expected_local_meta_paths) &&
        identical(as.character(meta_local_inputs$md5),
                  unname(tools::md5sum(expected_local_meta_paths))) &&
        identical(attr(meta_companion, "source_build_script_md5"),
                  cascade$meta$build_script_md5) &&
        identical(attr(meta_companion, "source_adapters_md5"),
                  cascade$meta$source_adapters_md5) &&
        identical(attr(meta_companion, "meta_script_md5"),
                  meta_local_inputs$md5[
                    meta_local_inputs$relative_path == "scripts/cascade_meta.R"]),
      "meta companion fingerprints source and every local executable meta input")
if (ran_brms)
  check(all(vapply(meta_companion, function(x) {
          b <- x$brms
          is.null(b) || (identical(b$converged, TRUE) &&
            identical(as.integer(b$divergences), 0L) &&
            is.finite(b$pooled_r) && length(b$cri_r) == 2L &&
            all(is.finite(b$cri_r)) &&
            is.finite(b$posterior_prob_stated_direction))
        }, logical(1))),
        "optional Bayesian estimates exist only after complete convergence diagnostics")
check(identical(attr(meta_companion, "tier_rule"), TIER_RULE_VERSION), "meta/helper tier-rule parity")
check(identical(attr(meta_companion, "prior_family_version"), PRIOR_FAMILY_VERSION),
      "meta/helper prior-family version parity")
check(identical(attr(meta_companion, "prior_family_status"), PRIOR_FAMILY_STATUS),
      "meta carries exploratory prior-family disclosure")
check(identical(attr(meta_companion, "greenup_index_version"), GREENUP_INDEX_VERSION) &&
        identical(attr(meta_companion, "greenup_index_note"), GREENUP_INDEX_NOTE),
      "meta carries retrospective green-up snapshot lineage")
check(identical(attr(meta_companion, "trend_sensitivity_version"), TREND_SENSITIVITY_VERSION) &&
        identical(attr(meta_companion, "trend_sensitivity_note"), TREND_SENSITIVITY_NOTE),
      "meta carries exact trend-sensitivity lineage")
check(identical(attr(meta_companion, "estimator_sensitivity_version"),
                ESTIMATOR_SENSITIVITY_VERSION) &&
        identical(attr(meta_companion, "estimator_sensitivity_note"),
                  ESTIMATOR_SENSITIVITY_NOTE),
      "meta carries exact estimator-sensitivity lineage")
check(identical(attr(meta_companion, "spatial_sensitivity_version"),
                SPATIAL_SENSITIVITY_VERSION) &&
        identical(attr(meta_companion, "spatial_sensitivity_note"),
                  SPATIAL_SENSITIVITY_NOTE),
      "meta carries exact spatial-sensitivity lineage")
rma_rows <- Filter(function(x) !is.null(x$rma), meta_companion)
check(length(rma_rows) > 0L && all(vapply(rma_rows, function(x)
        is.finite(x$rma$p_one_sided) && x$rma$p_one_sided >= 0 &&
          x$rma$p_one_sided <= 1 &&
          is.finite(x$rma$p_one_sided_holm) &&
          x$rma$p_one_sided_holm >= x$rma$p_one_sided &&
          x$rma$p_one_sided_holm <= 1 &&
          identical(x$rma$test_method,
                    "REML random-effects with Knapp-Hartung inference") &&
          length(x$rma$pi_r) == 2L && all(is.finite(x$rma$pi_r)) &&
          x$rma$pi_r[1] <= x$rma$pi_r[2] &&
          is.finite(x$rma$I2) && x$rma$I2 >= 0 && x$rma$I2 <= 100 &&
          is.finite(x$rma$tau2) && x$rma$tau2 >= 0 &&
          is.finite(x$rma$Q) && x$rma$Q >= 0 &&
          is.finite(x$rma$Q_p) && x$rma$Q_p >= 0 && x$rma$Q_p <= 1 &&
          is.null(x$rma$p_direction_predicted), logical(1))),
      "frequentist meta output leads with prediction/KH and exposes Holm-adjusted one-sided sensitivity p-values")
expected_meta <- lapply(rma_rows, function(x) {
  d <- suite[suite$from == x$from & suite$to == x$to &
               suite$expected %in% TRUE & suite$n >= 6L &
               is.finite(suite$r), , drop = FALSE]
  d_vote <- d[!is.na(d$sign_match), , drop = FALSE]
  z <- atanh(pmax(pmin(d$r, 0.999), -0.999))
  vi <- 1 / (d$n - 3)
  fit <- metafor::rma(yi = z, vi = vi, method = "REML", test = "knha")
  pred <- stats::predict(fit)
  t_test <- as.numeric(fit$b) / as.numeric(fit$se)
  df <- as.integer(fit$k - fit$p)
  p <- if (x$prior_sign < 0L) stats::pt(t_test, df = df) else
    stats::pt(t_test, df = df, lower.tail = FALSE)
  list(x = x, d = d, d_vote = d_vote, fit = fit, pred = pred,
       t_test = t_test, df = df, p = p)
})
expected_holm <- stats::p.adjust(
  vapply(expected_meta, function(z) z$p, numeric(1)),
  method = "holm", n = 2L)
meta_p_ok <- vapply(seq_along(expected_meta), function(i) {
  e <- expected_meta[[i]]
  x <- e$x; d <- e$d; d_vote <- e$d_vote; fit <- e$fit
  expected_ci <- tanh(c(fit$ci.lb, fit$ci.ub))
  expected_pi <- tanh(c(e$pred$pi.lb, e$pred$pi.ub))
  isTRUE(all.equal(x$median_r, stats::median(d$r), tolerance = 1e-15)) &&
    identical(as.integer(x$sites), as.integer(nrow(d))) &&
    identical(as.integer(x$sign_match_n), as.integer(nrow(d_vote))) &&
    identical(as.integer(x$sign_match_k), as.integer(sum(d_vote$sign_match))) &&
    isTRUE(all.equal(x$rma$pooled_r, tanh(as.numeric(fit$b)),
                     tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$ci_r, as.numeric(expected_ci),
                     tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$pi_r, as.numeric(expected_pi),
                     tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$se_z, as.numeric(fit$se),
                     tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$t_stat, e$t_test, tolerance = 1e-15)) &&
    identical(as.integer(x$rma$df), e$df) &&
    isTRUE(all.equal(x$rma$p_one_sided, e$p, tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$p_one_sided_holm, expected_holm[i],
                     tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$I2, as.numeric(fit$I2), tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$tau2, as.numeric(fit$tau2), tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$Q, as.numeric(fit$QE), tolerance = 1e-15)) &&
    isTRUE(all.equal(x$rma$Q_p, as.numeric(fit$QEp), tolerance = 1e-15))
}, logical(1))
check(all(meta_p_ok),
      "meta effects, KH intervals/tests, prediction intervals, and Holm family retain full metafor precision")
meta_sensitivity_ok <- vapply(meta_companion, function(x) {
  d_effect <- suite[suite$from == x$from & suite$to == x$to & suite$expected %in% TRUE &
                      suite$n >= 6L & is.finite(suite$r), , drop = FALSE]
  d <- d_effect[!is.na(d_effect$sign_match), , drop = FALSE]
  s <- x$trend_sensitivity
  identical(s$version, TREND_SENSITIVITY_VERSION) && identical(s$note, TREND_SENSITIVITY_NOTE) &&
    identical(as.integer(s$raw$sites), as.integer(nrow(d))) &&
    identical(as.integer(s$raw$k), as.integer(sum(d$sign_match))) &&
    identical(as.integer(s$detrended$sites), as.integer(sum(!is.na(d$sign_match_detrended)))) &&
    identical(as.integer(s$detrended$k), as.integer(sum(d$sign_match_detrended %in% TRUE))) &&
    identical(as.integer(s$change$sites), as.integer(sum(!is.na(d$sign_match_change)))) &&
    identical(as.integer(s$change$k), as.integer(sum(d$sign_match_change %in% TRUE)))
}, logical(1))
check(all(meta_sensitivity_ok), "meta trend-sensitivity counts match source suite rows")
meta_estimator_ok <- vapply(meta_companion, function(x) {
  d_effect <- suite[suite$from == x$from & suite$to == x$to & suite$expected %in% TRUE &
                      suite$n >= 6L & is.finite(suite$r), , drop = FALSE]
  d <- d_effect[!is.na(d_effect$sign_match), , drop = FALSE]
  s <- x$estimator_sensitivity
  identical(s$version, ESTIMATOR_SENSITIVITY_VERSION) &&
    identical(s$note, ESTIMATOR_SENSITIVITY_NOTE) &&
    identical(as.integer(s$outcome_alt$sites),
              as.integer(sum(!is.na(d$sign_match_outcome_alt)))) &&
    identical(as.integer(s$outcome_alt$k),
              as.integer(sum(d$sign_match_outcome_alt %in% TRUE)))
}, logical(1))
check(all(meta_estimator_ok), "meta estimator-sensitivity counts match source suite rows")
meta_spatial_ok <- vapply(meta_companion, function(x) {
  d_effect <- suite[suite$from == x$from & suite$to == x$to & suite$expected %in% TRUE &
                      suite$n >= 6L & is.finite(suite$r), , drop = FALSE]
  d <- d_effect[!is.na(d_effect$sign_match), , drop = FALSE]
  by_domain <- split(as.logical(d$sign_match), as.character(d$domain), drop = TRUE)
  margin <- vapply(by_domain, function(v) sum(v) - sum(!v), integer(1))
  s <- x$spatial_sensitivity
  identical(s$version, SPATIAL_SENSITIVITY_VERSION) &&
    identical(s$note, SPATIAL_SENSITIVITY_NOTE) &&
    identical(as.integer(s$domains), as.integer(sum(margin != 0L))) &&
    identical(as.integer(s$k_domain), as.integer(sum(margin > 0L))) &&
    identical(as.integer(s$domain_ties), as.integer(sum(margin == 0L)))
}, logical(1))
check(all(meta_spatial_ok), "meta spatial-sensitivity counts match raw suite domains")
meta_source <- paste(readLines("scripts/cascade_meta.R", warn = FALSE), collapse = "\n")
check(!grepl("round\\s*\\(", meta_source),
      "meta artifact generation never rounds before presentation (including optional brms)")
check(!grepl("posterior_prob_predicted", meta_source, fixed = TRUE),
      "optional Bayesian meta field uses stated-direction framing")
global_source <- paste(readLines("global.R", warn = FALSE), collapse = "\n")
check(!grepl("library\\s*\\(\\s*metafor|requireNamespace\\s*\\(\\s*[\"']metafor",
             global_source),
      "runtime validates persisted meta schema without loading metafor")

csv_codebook <- utils::read.csv("data/neon-cascade-codebook.csv", stringsAsFactors = FALSE,
                                check.names = FALSE, encoding = "UTF-8")
check(!length(cascade_artifact_text_issues(csv_codebook, "codebook CSV")),
      "codebook CSV satisfies the UTF-8 serialization contract")
check(identical(as.data.frame(cascade$codebook), csv_codebook), "RDS/CSV codebook parity")
check(!anyDuplicated(cascade$codebook$key), "codebook keys are unique")
check(setequal(cascade$codebook$key, emitted_cols),
      "codebook exactly covers annual signal/support fields",
      sprintf("%d fields", nrow(cascade$codebook)))
check(all(!is.na(cascade$codebook$unit) & nzchar(cascade$codebook$unit) &
            !is.na(cascade$codebook$na_meaning) & nzchar(cascade$codebook$na_meaning) &
            !is.na(cascade$codebook$n_gate) & nzchar(cascade$codebook$n_gate)),
      "every codebook field publishes unit, NA meaning, and gate")
check(all(cascade$codebook$n_gate[cascade$codebook$key %in% c("temp", "precip")] ==
            "12 of 12 distinct months"), "codebook publishes complete annual climate gate")
fruiting_codebook <- cascade$codebook[cascade$codebook$key %in%
  c("fruiting_pct", "fruiting_n_eligible_months",
    "fruiting_peak_n_individuals"), , drop = FALSE]
check(nrow(fruiting_codebook) == 3L &&
        grepl("Opportunistic observed-month",
              fruiting_codebook$label[fruiting_codebook$key == "fruiting_pct"],
              fixed = TRUE) &&
        all(grepl("context.?only|audit", fruiting_codebook$n_gate)),
      "codebook names fruiting as an opportunistic context-only peak with support")
greenup_codebook <- cascade$codebook[cascade$codebook$key %in%
  c("greenup_doy", "greenup_doy_additive"), , drop = FALSE]
check(nrow(greenup_codebook) == 2L &&
        all(grepl("future refreshes can revise historical",
                  greenup_codebook$na_meaning, fixed = TRUE)),
      "both green-up estimators disclose retrospective snapshot revision")
gate_by_key <- stats::setNames(cascade$codebook$n_gate, cascade$codebook$key)
check(identical(unname(gate_by_key["plant_intro_pct"]), "total scored cover > 0") &&
        identical(unname(gate_by_key["mammal_mnka"]), "trapping records present; zero tags allowed") &&
        identical(unname(gate_by_key["bird_index"]), "1+ observed point-visit/yr"),
      "codebook publishes exact cover/tag/point-visit gates")
mammal_codebook <- cascade$codebook[cascade$codebook$key %in% c(
  "mammal_trap_nights", "mammal_captures",
  "mammal_placeholder_trap_rows", "mammal_multi_capture_trap_events",
  "mammal_reviewed_double_trap_events"), , drop = FALSE]
check(nrow(mammal_codebook) == 5L &&
        grepl("A-J x 1-10", mammal_codebook$na_meaning[
          mammal_codebook$key == "mammal_trap_nights"], fixed = TRUE) &&
        grepl("AX-JX, X1-X10, or XX", mammal_codebook$na_meaning[
          mammal_codebook$key == "mammal_placeholder_trap_rows"], fixed = TRUE) &&
        grepl("two locked reviewed", mammal_codebook$na_meaning[
          mammal_codebook$key == "mammal_reviewed_double_trap_events"],
          fixed = TRUE),
      "mammal codebook publishes exact physical-event and uncertainty rules")

# Exact helper regressions: n-gates, finite randomization floor, and zero-inclusive CI boundary.
check(!ci_excludes_zero(0, 0.5) && !ci_excludes_zero(-0.5, 0) &&
        !ci_excludes_zero(-0.5, 0.5), "CI endpoints touching zero include zero")
check(ci_excludes_zero(0.01, 0.5) && ci_excludes_zero(-0.5, -0.01),
      "strictly one-sided CIs exclude zero")
check(isTRUE(all.equal(perm_p_circular(1:6, 1:6), 1 / 6, tolerance = 1e-15)),
      "exact circular p retains the full-precision n=6 floor", "p=1/6")
tiny <- data.frame(year = 1:5, x = 1:5, y = c(1, 3, 2, 5, 4))
check(identical(link_stat(tiny[1:2, ], "x", "y", 0, 1)$tier, "insufficient"),
      "n<3 link is insufficient")
thin <- link_stat(tiny, "x", "y", 0, 1)
check(identical(thin$tier, "exploratory") && is.na(thin$p), "n=3-5 link remains exploratory")
precision_series <- data.frame(year = 1:5, x = 1:5,
                               y = c(0.2, 1.7, -0.4, 4.2, 3.1))
precision_r <- stats::cor(precision_series$x, precision_series$y)
precision_stat <- link_stat(precision_series, "x", "y", 0L, 1L)
check(abs(precision_r - round(precision_r, 2)) > 1e-6 &&
        isTRUE(all.equal(precision_stat$r, precision_r, tolerance = 1e-15)),
      "link statistics retain non-display correlation precision")

# Deterministic site/prior streams must neither depend on nor mutate a caller's
# RNG configuration. This protects byte-stable uncertainty from interactive RNG
# settings without coupling every site to one identical bootstrap stream.
rng_contract <- function() {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) outer_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  outer_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(outer_kind))
    if (had_seed) assign(".Random.seed", outer_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)

  rng_data <- data.frame(site = "RNG1", year = 1:8, x = c(1,3,2,5,4,7,6,9),
                         y = c(2,1,4,3,7,5,9,8))
  rng_prior <- data.frame(from = "x", to = "y", sign = 1L, lag = 0L,
                          conf = "none", expected_class = "all", note = "test")
  RNGkind(kind = "L'Ecuyer-CMRG", normal.kind = "Inversion", sample.kind = "Rejection")
  set.seed(913L); before_seed <- get(".Random.seed", envir = .GlobalEnv)
  before_kind <- RNGkind(); first <- site_links(rng_data, rng_prior)
  state_kept <- identical(before_seed, get(".Random.seed", envir = .GlobalEnv)) &&
    identical(before_kind, RNGkind())
  set.seed(2L); second_before <- get(".Random.seed", envir = .GlobalEnv)
  second <- site_links(rng_data, rng_prior)
  second_kept <- identical(second_before, get(".Random.seed", envir = .GlobalEnv))

  rm(".Random.seed", envir = .GlobalEnv)
  invisible(site_links(rng_data, rng_prior))
  absent_kept <- !exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  list(state_kept = state_kept && second_kept && absent_kept,
       reproducible = identical(first, second),
       distinct_streams = stable_link_seed("RNG1", "x", "y", 0L, TIER_RULE_VERSION) !=
         stable_link_seed("RNG2", "x", "y", 0L, TIER_RULE_VERSION))
}
rng_result <- rng_contract()
check(rng_result$state_kept, "site-link RNG preserves caller seed/kind (including absent seed)")
check(rng_result$reproducible, "site-link uncertainty is reproducible across caller RNG states")
check(rng_result$distinct_streams, "different sites receive distinct deterministic RNG streams")

set.seed(42)
bs <- circular_block_boot_cor(1:8, c(1, 3, 2, 5, 4, 7, 6, 8), reps = 50L)
check(length(bs) == 50L && any(is.finite(bs)), "circular block bootstrap returns finite replicates")

gap <- data.frame(year = c(2013:2015, 2017:2019),
                  x = c(1, 2, 3, 5, 6, 7), y = c(1, 3, 2, 6, 5, 7))
gap_grid <- lag_grid(gap, "x", "y", 0L)
check(identical(gap_grid$year, 2013:2019) && nrow(gap_grid) == 7L &&
        is.na(gap_grid$x[gap_grid$year == 2016]) && is.na(gap_grid$y[gap_grid$year == 2016]),
      "lag grid preserves missing calendar years as explicit NAs")

padded <- data.frame(year = 2010:2020, x = NA_real_, y = NA_real_)
padded$x[padded$year %in% 2012:2018] <- seq_len(7)
padded$y[padded$year %in% 2013:2019] <- seq_len(7)
padded$x[padded$year == 2015] <- NA_real_
padded$y[padded$year == 2016] <- NA_real_
padded_grid <- lag_grid(padded, "x", "y", 0L)
check(identical(padded_grid$year, 2013:2018) &&
        is.na(padded_grid$x[padded_grid$year == 2015]) &&
        is.na(padded_grid$y[padded_grid$year == 2016]),
      "lag grid trims exterior structural padding but retains interior gaps")
set.seed(7)
gap_stat <- link_stat(gap, "x", "y", 0L, 1L)
check(gap_stat$n == 6L && gap_stat$series_span == 7L && gap_stat$n_null <= 6L &&
        isTRUE(all.equal(gap_stat$p_floor, 1 / (gap_stat$n_null + 1L), tolerance = 1e-15)),
      "link audit distinguishes complete pairs from calendar span/null resolution")

manual_gap_sensitivity <- link_trend_sensitivity(
  gap_grid, 1L, raw_eligible = gap_stat$n >= 6L && !is.na(gap_stat$sign_match))
complete_gap <- gap_grid[is.finite(gap_grid$x) & is.finite(gap_grid$y), , drop = FALSE]
manual_rx <- residuals(lm(x ~ year, data = complete_gap))
manual_ry <- residuals(lm(y ~ year, data = complete_gap))
consecutive_gap <- gap_grid$year[-1L] == gap_grid$year[-nrow(gap_grid)] + 1L &
  is.finite(gap_grid$x[-1L]) & is.finite(gap_grid$x[-nrow(gap_grid)]) &
  is.finite(gap_grid$y[-1L]) & is.finite(gap_grid$y[-nrow(gap_grid)])
check(manual_gap_sensitivity$n_detrended == nrow(complete_gap) &&
        same_num(manual_gap_sensitivity$r_detrended, stable_cor(manual_rx, manual_ry), 1e-15) &&
        manual_gap_sensitivity$n_change == sum(consecutive_gap),
      "trend sensitivity uses identical pairs and never differences across a gap")

# The lag explorer's max-null must ignore years where only unrelated products
# have records. Exterior padding cannot change the adjusted p; interior response
# gaps remain in the bounded response grid.
exp_base <- data.frame(year = 2013:2018,
                       x = c(1, 3, 2, 6, 4, 7),
                       y = c(2, 1, 4, 3, 7, 6))
exp_combos <- list(list(col = "x", lag = 0L))
exp_observed <- stats::cor(exp_base$x, exp_base$y)
exp_trimmed_p <- exp_adj_p(exp_base, "y", exp_combos, exp_observed)
exp_padded <- data.frame(year = 2010:2020, x = NA_real_, y = NA_real_)
ix <- match(exp_base$year, exp_padded$year)
exp_padded$x[ix] <- exp_base$x; exp_padded$y[ix] <- exp_base$y
exp_padded_p <- exp_adj_p(exp_padded, "y", exp_combos, exp_observed)
check(is.finite(exp_trimmed_p) &&
        isTRUE(all.equal(exp_trimmed_p, exp_padded_p, tolerance = 1e-15)),
      "lag-explorer null trims exterior response padding")
exp_no_null <- data.frame(year = 1:4, x = c(1, 2, NA, NA), y = 1:4)
check(is.na(exp_adj_p(exp_no_null, "y", exp_combos, observed_r = 0.5)),
      "lag-explorer adjusted p is NA when no finite null maximum exists")

neutral_series <- data.frame(year = 1:6, x = 1:6)
neutral_series$y <- (neutral_series$x - 3.5)^2
set.seed(11)
neutral_stat <- link_stat(neutral_series, "x", "y", 0L, 1L)
check(abs(neutral_stat$r) <= sqrt(.Machine$double.eps) &&
        identical(neutral_stat$tier, "neutral") && is.na(neutral_stat$sign_match),
      "effectively zero correlation is a neutral tie with no direction vote")
constant_series <- data.frame(year = 1:6, x = rep(4, 6), y = 1:6)
constant_stat <- link_stat(constant_series, "x", "y", 0L, 1L)
check(constant_stat$n == 6L && is.na(constant_stat$r) &&
        identical(constant_stat$tier, "neutral") && is.na(constant_stat$sign_match),
      "constant n>=6 series has no usable direction and is neutral")
constant_thin <- data.frame(year = 1:5, x = rep(4, 5), y = 1:5)
constant_thin_stat <- link_stat(constant_thin, "x", "y", 0L, 1L)
check(constant_thin_stat$n == 5L && is.na(constant_thin_stat$r) &&
        identical(constant_thin_stat$tier, "exploratory") &&
        is.na(constant_thin_stat$sign_match) && is.na(constant_thin_stat$p),
      "constant n=5 series remains exploratory with no verdict")
neutral_links <- rbind(
  data.frame(from = "x", to = "y", lag = 0L, expected_class = "all",
             expected = TRUE, n = neutral_stat$n, r = neutral_stat$r,
             sign_match = neutral_stat$sign_match),
  data.frame(from = "constant_x", to = "y", lag = 0L, expected_class = "all",
             expected = TRUE, n = constant_stat$n, r = constant_stat$r,
             sign_match = constant_stat$sign_match))
neutral_tally <- signmatch_score(neutral_links)
neutral_pool <- pooled_links(neutral_links, min_sites = 1L)
check(neutral_tally$n == 0L && neutral_tally$k == 0L &&
        all(neutral_pool$sites == 0L & neutral_pool$k == 0L &
              !neutral_pool$poolable & is.na(neutral_pool$p)) &&
        neutral_pool$median_r[neutral_pool$from == "x"] == 0,
      "constant/tie rows abstain from sign tests while finite zero stays in effect summaries")
global_source <- paste(readLines("global.R", warn = FALSE), collapse = "\n")
server_source <- paste(readLines("server.R", warn = FALSE), collapse = "\n")
check(grepl('else if (is.na(predicted) || is.na(dst_direction)) "neutral"',
            global_source, fixed = TRUE) &&
        grepl('tot <- sum(paths$verdict %in% c("match", "miss"))',
              server_source, fixed = TRUE) &&
        grepl('abstain <- sum(paths$verdict == "neutral")',
              server_source, fixed = TRUE) &&
        grepl('if (pr$verdict %in% c("nodata", "neutral")) next',
              server_source, fixed = TRUE),
      "pulse exact-zero states abstain from markers and direction denominators")

context_prior <- data.frame(
  from = "x", to = "y", lag = 0L, sign = 1L, conf = "none",
  expected_class = "none", note = "context-only", stringsAsFactors = FALSE)
context_link <- site_links(transform(neutral_series, site = "TEST"), context_prior,
                           biome = NULL, nperm = 5L)
check(identical(context_link$expected, FALSE),
      "explicit context-only prior never becomes vote-eligible when biome is NULL")

spatial_fixture <- data.frame(
  domain = c("D01", "D01", "D02", "D02", "D03"),
  sign_match = c(TRUE, FALSE, TRUE, TRUE, FALSE))
spatial_fixture_count <- domain_majority_counts(spatial_fixture)
check(identical(spatial_fixture_count,
                list(domains = 2L, k_domain = 1L, domain_ties = 1L)),
      "NEON-domain sensitivity gives one majority vote and makes ties abstain")

phen_qc_fixture <- data.frame(
  year = c(2020L, 2021L), greenup_doy = c(150, 152),
  greenup_n_onsets = c(11L, 11L), greenup_n_left_censored = c(3L, 3L),
  greenup_n_taxon_excluded = c(2L, 2L), greenup_n_individuals = c(6L, 6L),
  greenup_n_species = c(2L, 2L),
  greenup_onset_interval_median_days = c(6, 16),
  greenup_onset_interval_p90_days = c(12, 18),
  greenup_onset_interval_max_days = c(45, 20))
phen_qc <- cascade_qc(phen_qc_fixture, data.frame(), site = "QC")
phen_qc_keys <- vapply(phen_qc$flags, `[[`, character(1), "key")
check(all(c("greenup_censor_burden", "greenup_composition_exclusions",
            "greenup_wide_typical_intervals", "greenup_wide_intervals") %in% phen_qc_keys) &&
        all(c("greenup_censor_burden", "greenup_composition_exclusions",
              "greenup_wide_typical_intervals", "greenup_wide_intervals") %in% names(phen_qc$sets)),
      "phenology QC exposes censor, composition-exclusion, typical-width, and extreme-width audits")

# When sibling sources are available, recompute corrected aggregations from their
# committed schemas rather than merely checking arithmetic within the derived file.
source_root <- Sys.getenv("CASCADE_ROOT", unset = "")
generation_capability_present <- any(nzchar(Sys.getenv(
  c("CASCADE_GENERATION_ROOT", "CASCADE_GENERATION_TOKEN"), unset = "")))
if (generation_capability_present &&
    (!nzchar(source_root) || !dir.exists(source_root)))
  fail("source-level product recomputations",
       "CASCADE_ROOT is mandatory during capability-authorized release generation")
if (nzchar(source_root) && !dir.exists(source_root))
  fail("source-level product recomputations",
       sprintf("CASCADE_ROOT does not exist: %s", source_root))
if (nzchar(source_root)) {
  build_window <- function(x) {
    x[is.finite(x$year) & x$year >= cascade$meta$min_year &
        x$year <= cascade$meta$last_complete_year, , drop = FALSE]
  }
  product_key <- function(x) paste(x$site, x$year, sep = "|")
  check_calendar <- function(derived, expected, label) {
    dk <- product_key(derived); ek <- product_key(expected)
    check(!anyDuplicated(dk) && !anyDuplicated(ek) && setequal(dk, ek), label,
          sprintf("%d site-years", length(ek)))
  }

  # Recompute every climate and fruiting field from the inert monthly mammal
  # overlays. This is the raw-data oracle for 12/12 annual, 6/6 water-year
  # winter, 3/3 monsoon/spring, within-site MAD, and >=5-individual fruiting.
  env_dir <- file.path(source_root, "App-NEON-Small-Mammal-Tracker",
                       "data", "env")
  env_files <- list.files(env_dir, pattern = "\\.rds$", full.names = TRUE)
  env_expected <- dplyr::bind_rows(lapply(env_files, function(path) {
    site <- sub("\\.rds$", "", basename(path))
    if (!site %in% annual_sites) return(NULL)
    oracle_env_bundle(readRDS(path), site = site,
                      min_year = cascade$meta$min_year,
                      max_year = cascade$meta$last_complete_year)
  }))
  env_expected <- build_window(env_expected)
  env_fields <- c(
    "temp_n_months", "precip_n_months", "temp", "precip", "fruiting_pct",
    "fruiting_n_eligible_months", "fruiting_peak_n_individuals",
    "precip_winter_n_months", "precip_winter",
    "precip_monsoon_n_months", "precip_monsoon",
    "temp_spring_n_months", "temp_spring")
  expected_env_keys <- product_key(env_expected)
  env_derived <- annual[product_key(annual) %in% expected_env_keys,
                        c("site", "year", env_fields), drop = FALSE]
  check(nrow(env_expected) > 0L &&
          all(vapply(c("temp", "precip", "precip_winter",
                       "precip_monsoon", "temp_spring", "fruiting_pct"),
                     function(key) any(is.finite(env_expected[[key]])),
                     logical(1))),
        "raw environment oracle has non-vacuous climate and fruiting coverage",
        sprintf("%d source site-years", nrow(env_expected)))
  check_calendar(env_derived, env_expected,
                 "raw environment/derived support-calendar parity")
  observed_env <- merge(env_derived, env_expected, by = c("site", "year"),
                        all = FALSE, suffixes = c(".derived", ".expected"))
  env_exact <- vapply(env_fields, function(key) {
    same_num(observed_env[[paste0(key, ".derived")]],
             observed_env[[paste0(key, ".expected")]], tolerance = 1e-15)
  }, logical(1))
  check(nrow(observed_env) == nrow(env_expected) && all(env_exact),
        "climate completeness, water-year alignment, MAD, and fruiting gates match raw overlays",
        paste(env_fields[!env_exact], collapse = ", "))

  plant_dir <- file.path(source_root, "NEON-Plant-Diversity", "data", "sites")
  plant_files <- list.files(plant_dir, pattern = "\\.rds$", full.names = TRUE)
  plant_expected <- do.call(rbind, lapply(plant_files, function(path) {
    b <- readRDS(path)
    if (!is.list(b) || is.data.frame(b) || !is.data.frame(b$occ) ||
        length(setdiff(expected_plant_schema, names(b$occ))))
      stop(sprintf("malformed raw plant bundle: %s", path), call. = FALSE)
    d <- b$occ[b$occ$is_species %in% TRUE, , drop = FALSE]
    if (!nrow(d)) return(NULL)
    do.call(rbind, lapply(split(d, d$year), function(y) {
      total <- sum(y$percentCover, na.rm = TRUE)
      data.frame(site = sub("\\.rds$", "", basename(path)), year = y$year[1],
                 expected = if (total > 0) 100 *
                   sum(y$percentCover[y$nativeStatusCode == "I"],
                       na.rm = TRUE) / total else NA_real_)
    }))
  }))
  plant_expected <- build_window(plant_expected)
  plant_derived <- annual[is.finite(annual$plant_n_sampling_units),
                          c("site", "year", "plant_intro_pct"), drop = FALSE]
  check_calendar(plant_derived, plant_expected,
                 "plant source/derived support-calendar parity")
  observed <- merge(plant_derived, plant_expected,
                    by = c("site", "year"), all = FALSE)
  same <- same_num(observed$plant_intro_pct, observed$expected,
                   tolerance = 1e-15)
  check(nrow(observed) > 0 && all(same),
        "introduced cover matches source I-only recomputation",
        sprintf("%d source site-years", nrow(observed)))

  phe_dir <- file.path(source_root, "NEON-Plant-Phenology", "data", "sites")
  phe_files <- list.files(phe_dir, pattern = "\\.rds$", full.names = TRUE)

  # Independent graph traversal for the connected species-year panel. This is
  # intentionally separate from the builder's fixed-point implementation.
  test_largest_incidence_component <- function(x) {
    if (is.null(x) || !nrow(x)) return(x)
    unseen <- sort(unique(as.character(x$scientificName)), method = "radix")
    components <- list()
    while (length(unseen)) {
      queue <- unseen[1]; members <- character()
      while (length(queue)) {
        current <- queue[1]; queue <- queue[-1]
        if (current %in% members) next
        members <- c(members, current)
        connected_years <- unique(x$year[x$scientificName == current])
        neighbours <- sort(unique(as.character(
          x$scientificName[x$year %in% connected_years])), method = "radix")
        queue <- unique(c(queue, setdiff(neighbours, members)))
      }
      members <- sort(members, method = "radix")
      rows <- x[x$scientificName %in% members, , drop = FALSE]
      components[[length(components) + 1L]] <- list(
        rows = rows, n_species = length(members), n_records = nrow(rows),
        first_species = members[1])
      unseen <- setdiff(unseen, members)
    }
    rank <- data.frame(
      component = seq_along(components),
      n_species = vapply(components, function(z) z$n_species, integer(1)),
      n_records = vapply(components, function(z) z$n_records, integer(1)),
      first_species = vapply(components, function(z) z$first_species, character(1)),
      stringsAsFactors = FALSE)
    winner <- rank$component[order(-rank$n_species, -rank$n_records,
                                   rank$first_species, method = "radix")][1]
    components[[winner]]$rows
  }

  # Reconstruct both green-up estimators and every support bucket directly from
  # one raw phenology bundle. Onset reconstruction uses the reviewed local
  # adapter shared with the builder; selection, connectivity, and aggregation
  # are independently recomputed here as an artifact oracle.
  test_greenup_bundle <- function(b, site, min_year = cascade$meta$min_year,
                                  max_year = cascade$meta$last_complete_year) {
    o <- cascade_onset(b$obs, GREENUP)
    if (is.null(o) || !nrow(o)) return(NULL)
    o <- o[is.finite(o$year) & is.finite(o$onset_doy) &
             o$year >= min_year & o$year <= max_year, , drop = FALSE]
    if (!nrow(o)) return(NULL)

    individual_year <- o %>%
      group_by(.data$individualID, .data$year) %>%
      summarise(
        .min_onset_doy = min(.data$onset_doy),
        left_censored = {
          tied <- .data$onset_doy == min(.data$onset_doy)
          any(.data$left_censored[tied] %in% TRUE)
        },
        scientificName = {
          tied <- .data$onset_doy == min(.data$onset_doy)
          sort(unique(as.character(.data$scientificName[tied])),
               method = "radix")[1]
        },
        onset_interval_days = {
          tied <- .data$onset_doy == min(.data$onset_doy)
          widths <- 2 * (.data$first_yes[tied] - .data$onset_doy[tied])
          widths <- widths[is.finite(widths)]
          if (length(widths)) max(widths) else NA_real_
        },
        .groups = "drop") %>%
      rename(onset_doy = .min_onset_doy)
    taxon_map <- b$obs %>%
      group_by(.data$individualID, .data$scientificName) %>%
      summarise(is_species = any(.data$is_species %in% TRUE), .groups = "drop")
    individual_year <- individual_year %>%
      left_join(taxon_map, by = c("individualID", "scientificName"),
                relationship = "many-to-one")

    audit <- individual_year %>%
      group_by(.data$year) %>%
      summarise(greenup_n_onsets = dplyr::n(),
                greenup_n_left_censored = sum(.data$left_censored %in% TRUE),
                .groups = "drop")
    uncensored_species <- individual_year %>%
      filter(!(.data$left_censored %in% TRUE), .data$is_species %in% TRUE,
             !is.na(.data$scientificName), nzchar(.data$scientificName))
    species_year <- uncensored_species %>%
      group_by(.data$scientificName, .data$year) %>%
      summarise(species_onset = stats::median(.data$onset_doy),
                n_individuals = dplyr::n_distinct(.data$individualID),
                .groups = "drop") %>%
      filter(.data$n_individuals >= 3L)
    recurrent <- species_year %>%
      count(.data$scientificName, name = "n_eligible_years") %>%
      filter(.data$n_eligible_years >= 3L)
    eligible <- species_year %>%
      semi_join(recurrent, by = "scientificName")
    eligible <- test_largest_incidence_component(eligible)
    contributors <- uncensored_species %>%
      semi_join(eligible, by = c("scientificName", "year"))
    if (nrow(contributors) &&
        any(!is.finite(contributors$onset_interval_days) |
              contributors$onset_interval_days < 0))
      stop(sprintf("%s source-oracle contributors have invalid onset intervals", site),
           call. = FALSE)
    support <- if (!nrow(contributors)) {
      tibble::tibble(
        year = integer(), greenup_n_individuals = integer(),
        greenup_n_species = integer(),
        greenup_onset_interval_median_days = numeric(),
        greenup_onset_interval_p90_days = numeric(),
        greenup_onset_interval_max_days = numeric())
    } else {
      contributors %>%
        group_by(.data$year) %>%
        summarise(greenup_n_individuals = dplyr::n_distinct(.data$individualID),
                  greenup_n_species = dplyr::n_distinct(.data$scientificName),
                  greenup_onset_interval_median_days = stats::median(
                    .data$onset_interval_days),
                  greenup_onset_interval_p90_days = as.numeric(stats::quantile(
                    .data$onset_interval_days, 0.9, names = FALSE, type = 7)),
                  greenup_onset_interval_max_days = max(.data$onset_interval_days),
                  .groups = "drop")
    }

    indexed <- tibble::tibble(year = integer(), primary = numeric())
    additive <- tibble::tibble(year = integer(), additive = numeric())
    reference <- NA_real_
    if (nrow(eligible)) {
      centered <- eligible %>%
        group_by(.data$scientificName) %>%
        mutate(species_reference = stats::median(.data$species_onset)) %>%
        ungroup()
      reference <- centered %>%
        distinct(.data$scientificName, .data$species_reference) %>%
        summarise(value = stats::median(.data$species_reference)) %>%
        pull("value")
      indexed <- centered %>%
        group_by(.data$year) %>%
        summarise(primary = reference + stats::median(
          .data$species_onset - .data$species_reference), .groups = "drop")

      species <- sort(unique(as.character(eligible$scientificName)), method = "radix")
      years <- sort(unique(eligible$year))
      if (length(species) >= 2L) {
        model_data <- eligible
        model_data$scientificName <- factor(as.character(model_data$scientificName),
                                            levels = species)
        fit <- stats::lm(species_onset ~ scientificName + factor(year),
                         data = model_data)
        check(fit$rank == length(species) + length(years) - 1L,
              sprintf("synthetic/source %s phenology additive design is full rank", site))
        grid <- expand.grid(scientificName = species, year = years,
                            KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
        grid$prediction <- as.numeric(stats::predict(fit, newdata = grid))
        additive <- grid %>%
          group_by(.data$year) %>%
          summarise(additive = stats::median(.data$prediction), .groups = "drop")
      }
    }

    out <- audit %>%
      left_join(support, by = "year", relationship = "one-to-one") %>%
      left_join(indexed, by = "year", relationship = "one-to-one") %>%
      left_join(additive, by = "year", relationship = "one-to-one") %>%
      mutate(
        greenup_n_individuals = dplyr::coalesce(.data$greenup_n_individuals, 0L),
        greenup_n_species = dplyr::coalesce(.data$greenup_n_species, 0L),
        greenup_n_taxon_excluded = .data$greenup_n_onsets -
          .data$greenup_n_left_censored - .data$greenup_n_individuals,
        greenup_reference_doy = reference,
        greenup_doy = ifelse(.data$greenup_n_individuals >= 6L &
                               .data$greenup_n_species >= 2L & is.finite(.data$primary),
                             .data$primary, NA_real_),
        greenup_doy_additive = ifelse(.data$greenup_n_individuals >= 6L &
                                        .data$greenup_n_species >= 2L &
                                        is.finite(.data$additive),
                                      .data$additive, NA_real_),
        site = site, .before = 1) %>%
      select("site", "year", "greenup_doy", "greenup_doy_additive",
             "greenup_n_onsets", "greenup_n_left_censored",
             "greenup_n_taxon_excluded", "greenup_n_individuals",
             "greenup_n_species", "greenup_reference_doy",
             "greenup_onset_interval_median_days",
             "greenup_onset_interval_p90_days",
             "greenup_onset_interval_max_days")
    stopifnot(identical(is.finite(out$greenup_doy),
                        is.finite(out$greenup_doy_additive)))
    out
  }

  phe_expected <- dplyr::bind_rows(lapply(phe_files, function(path)
    test_greenup_bundle(readRDS(path), sub("\\.rds$", "", basename(path)))))
  phe_expected <- build_window(phe_expected)
  phe_cols <- c("greenup_doy", "greenup_doy_additive", "greenup_n_onsets",
                "greenup_n_left_censored", "greenup_n_taxon_excluded",
                "greenup_n_individuals", "greenup_n_species",
                "greenup_reference_doy", "greenup_onset_interval_median_days",
                "greenup_onset_interval_p90_days",
                "greenup_onset_interval_max_days")
  phe_derived <- annual[is.finite(annual$greenup_n_onsets),
                        c("site", "year", phe_cols), drop = FALSE]
  check_calendar(phe_derived, phe_expected,
                 "phenology source/derived support-calendar parity")
  names(phe_expected)[match(phe_cols, names(phe_expected))] <- paste0(phe_cols, "_expected")
  observed <- merge(phe_derived, phe_expected, by = c("site", "year"), all = FALSE)
  phe_exact <- vapply(phe_cols, function(key)
    same_num(observed[[key]], observed[[paste0(key, "_expected")]], tolerance = 1e-15),
    logical(1))
  check(nrow(observed) > 0 && all(phe_exact),
        "green-up primary/additive estimators and audit fields match raw-source recomputation",
        sprintf("%d source site-years; %d exact fields", nrow(observed), length(phe_cols)))

  # Synthetic raw observations expose failure modes that can be rare in a
  # particular source snapshot: tied censoring, abundance-composition shifts,
  # and disconnected species-year panels.
  synthetic_cells_to_obs <- function(cells) {
    dplyr::bind_rows(lapply(seq_len(nrow(cells)), function(i) {
      ids <- paste0(gsub("[^A-Za-z0-9]", "_", cells$scientificName[i]), "_",
                    seq_len(cells$n[i]))
      dplyr::bind_rows(lapply(ids, function(id) data.frame(
        individualID = id, scientificName = cells$scientificName[i],
        growthForm = "Deciduous broadleaf", phenophaseName = "Breaking leaf buds",
        year = cells$year[i], dayOfYear = c(cells$onset[i] - 2, cells$onset[i] + 2),
        status = c("no", "yes"), is_species = TRUE, stringsAsFactors = FALSE)))
    }))
  }
  fixture_years <- seq.int(cascade$meta$last_complete_year - 5L,
                           cascade$meta$last_complete_year)
  check(min(fixture_years) >= cascade$meta$min_year,
        "phenology synthetic fixture lies within the recorded build window")

  censor_obs <- data.frame(
    individualID = "censored_1", scientificName = "Alpha species",
    growthForm = "Deciduous broadleaf",
    # The alphabetically first phase is later (DOY 120). Two subsequent phases
    # tie at DOY 100; the last is left-censored and must censor the whole year.
    phenophaseName = rep(c("Breaking leaf buds", "Emerging needles",
                           "Initial growth"), each = 2),
    year = fixture_years[1],
    dayOfYear = c(110, 130, 90, 110, 100, 120),
    status = c("no", "yes", "no", "yes", "yes", "no"),
    is_species = TRUE, stringsAsFactors = FALSE)
  censor_warnings <- character()
  censor_result <- withCallingHandlers(
    test_greenup_bundle(list(obs = censor_obs), "CENSOR"),
    warning = function(w) {
      censor_warnings <<- c(censor_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  check(!length(censor_warnings) && nrow(censor_result) == 1L &&
          censor_result$greenup_n_onsets == 1L &&
          censor_result$greenup_n_left_censored == 1L &&
          censor_result$greenup_n_taxon_excluded == 0L &&
          censor_result$greenup_n_individuals == 0L &&
          is.na(censor_result$greenup_doy) &&
          all(is.na(censor_result[greenup_width_cols])),
        paste("tied earliest phases propagate left censoring and zero final",
              "contributors emit three NA interval summaries without warnings"))

  composition_cells <- expand.grid(
    scientificName = c("Alpha species", "Beta species"),
    year = fixture_years[1:3], stringsAsFactors = FALSE)
  composition_cells$onset <- c(100, 200, 110, 210, 90, 190)
  composition_cells$n <- c(3L, 9L, 9L, 3L, 3L, 9L)
  composition_obs <- synthetic_cells_to_obs(composition_cells)
  tie_rows <- composition_obs$individualID == "Alpha_species_1" &
    composition_obs$year == fixture_years[1]
  composition_obs$dayOfYear[tie_rows & composition_obs$status == "no"] <- 95
  composition_obs$dayOfYear[tie_rows & composition_obs$status == "yes"] <- 105
  tied_phase <- composition_obs[tie_rows, , drop = FALSE]
  tied_phase$phenophaseName <- "Initial growth"
  # The later tied phase is wider; selecting only the first tied row returns 10
  # instead of the required conservative 20-day interval audit.
  tied_phase$dayOfYear[tied_phase$status == "no"] <- 90
  tied_phase$dayOfYear[tied_phase$status == "yes"] <- 110
  composition_obs <- rbind(composition_obs, tied_phase)
  composition_result <- test_greenup_bundle(
    list(obs = composition_obs), "COMPOSITION") %>%
    arrange(.data$year)
  check(same_num(composition_result$greenup_doy, c(150, 160, 140), tolerance = 1e-12) &&
          same_num(composition_result$greenup_doy_additive, c(150, 160, 140),
                   tolerance = 1e-12) &&
          identical(as.integer(composition_result$greenup_n_individuals),
                    c(12L, 12L, 12L)) &&
          same_num(composition_result$greenup_onset_interval_median_days,
                   c(4, 4, 4), tolerance = 1e-15) &&
          same_num(composition_result$greenup_onset_interval_p90_days,
                   c(4, 4, 4), tolerance = 1e-15) &&
          same_num(composition_result$greenup_onset_interval_max_days,
                   c(20, 4, 4), tolerance = 1e-15),
        "green-up estimators resist abundance shifts and tied phases retain the widest interval")

  connectivity_cells <- rbind(
    expand.grid(scientificName = c("Alpha species", "Beta species"),
                year = fixture_years[1:3], stringsAsFactors = FALSE),
    expand.grid(scientificName = c("Gamma species", "Delta species"),
                year = fixture_years[4:6], stringsAsFactors = FALSE))
  connectivity_cells$onset <- rep(c(100, 200), 6L)
  connectivity_cells$n <- 3L
  connectivity_result <- test_greenup_bundle(
    list(obs = synthetic_cells_to_obs(connectivity_cells)), "CONNECTIVITY") %>%
    arrange(.data$year)
  check(identical(which(is.finite(connectivity_result$greenup_doy)), 1:3) &&
          all(connectivity_result$greenup_n_individuals[1:3] == 6L) &&
          all(connectivity_result$greenup_n_individuals[4:6] == 0L) &&
          all(connectivity_result$greenup_n_taxon_excluded[4:6] == 6L) &&
          all(connectivity_result$greenup_onset_interval_max_days[1:3] == 4) &&
          all(is.na(connectivity_result$greenup_onset_interval_max_days[4:6])),
        "lexical tie-break selects one coherent connected species-year panel")

  mammal_dir <- file.path(source_root, "App-NEON-Small-Mammal-Tracker", "data", "sites")
  mammal_files <- list.files(mammal_dir, pattern = "\\.rds$", full.names = TRUE)
  mammal_seen_tokens <- character()
  raw_mammal_effort <- c(
    "1 - trap not set" = 0,
    "2 - trap disturbed/door closed but empty" = 0.5,
    "3 - trap door open or closed w/ spoor left" = 0.5,
    "4 - more than 1 capture in one trap" = 1,
    "5 - capture" = 1,
    "6 - trap set and empty" = 1)
  mammal_raw_rule_counts <- c(
    placeholder_rows = 0L, multi_capture_events = 0L,
    reviewed_double_trap_events = 0L)
  mammal_same_night_tag_groups <- 0L
  mammal_same_event_tag_groups <- 0L
  mammal_same_night_tag_coordinate_conflicts <- 0L
  mammal_tagged_half_effort_rows <- 0L
  mammal_untagged_status5_rows <- 0L
  mammal_expected <- do.call(rbind, lapply(mammal_files, function(path) {
    d <- readRDS(path)
    mammal_need <- c("collectDate", "nightuid", "plotID", "trapCoordinate",
                     "trapStatus", "tagID", "remarks")
    if (!is.data.frame(d) || length(setdiff(mammal_need, names(d))))
      stop(sprintf("raw mammal bundle is not the direct data-frame schema: %s",
                   path), call. = FALSE)
    year <- suppressWarnings(as.integer(format(as.Date(d$collectDate), "%Y")))
    if (any(!is.finite(year)))
      stop(sprintf("raw mammal bundle has invalid collectDate: %s", path),
           call. = FALSE)
    token <- tolower(trimws(as.character(d$trapStatus)))
    mammal_seen_tokens <<- union(mammal_seen_tokens, token)
    effort <- unname(raw_mammal_effort[token])
    if (anyNA(effort))
      stop(sprintf("raw mammal bundle has non-exact trapStatus: %s", path),
           call. = FALSE)

    coordinate <- as.character(d$trapCoordinate)
    bad_key <- is.na(d$nightuid) | !nzchar(as.character(d$nightuid)) |
      is.na(d$plotID) | !nzchar(as.character(d$plotID)) |
      is.na(d$trapCoordinate) | !nzchar(coordinate)
    if (any(bad_key))
      stop(sprintf("raw mammal bundle has incomplete trap key: %s", path),
           call. = FALSE)
    # Deliberately literal and independent of the production adapter constants.
    canonical <- grepl("^[A-J](?:[1-9]|10)$", coordinate, perl = TRUE)
    placeholder <- grepl("^(?:[A-J]X|X(?:[1-9]|10)|XX)$",
                         coordinate, perl = TRUE)
    if (any(!(canonical | placeholder)))
      stop(sprintf("raw mammal bundle has unreviewed trap coordinate: %s", path),
           call. = FALSE)
    physical_event <- paste(year, d$nightuid, d$plotID, coordinate, sep = "|")
    duplicate_canonical <- canonical &
      (duplicated(physical_event) |
         duplicated(physical_event, fromLast = TRUE))
    duplicate_groups <- split(which(duplicate_canonical),
                              physical_event[duplicate_canonical])

    tag <- trimws(as.character(d$tagID))
    cap_flag <- !is.na(d$tagID) & nzchar(tag)
    marker <- vapply(tolower(as.character(d$remarks)), function(value) {
      if (is.na(value)) return(0L)
      hit <- c(
        grepl("trap accidentally double set", value, fixed = TRUE),
        grepl("double trap method (two traps set at each location)",
              value, fixed = TRUE))
      if (sum(hit) == 1L) which(hit) else 0L
    }, integer(1))

    keep <- rep(TRUE, nrow(d))
    resolved_effort <- effort
    effort_rule <- ifelse(placeholder, "placeholder-row-level",
                          "canonical-single")
    for (ix in duplicate_groups) {
      capture_status <- token[ix] %in% c(
        "4 - more than 1 capture in one trap", "5 - capture")
      has_status4 <- any(
        token[ix] == "4 - more than 1 capture in one trap")
      one_trap_multi <- all(capture_status) && has_status4 &&
        all(cap_flag[ix]) && !anyDuplicated(tag[ix]) &&
        all(marker[ix] == 0L)
      reviewed_double <- length(ix) == 2L && all(marker[ix] > 0L) &&
        length(unique(marker[ix])) == 1L && !has_status4 &&
        !anyDuplicated(tag[ix][cap_flag[ix]]) &&
        length(unique(as.character(d$collectDate[ix]))) == 1L
      first <- ix[[1L]]
      if (one_trap_multi) {
        resolved_effort[first] <- 1
        effort_rule[first] <- "canonical-multi-capture-one-trap"
        keep[ix[-1L]] <- FALSE
      } else if (reviewed_double) {
        resolved_effort[first] <- sum(effort[ix])
        effort_rule[first] <- "reviewed-double-trap-rows"
        keep[ix[-1L]] <- FALSE
      } else {
        stop(sprintf(
          "raw mammal bundle has unreviewed duplicated canonical event %s: %s",
          physical_event[first], path), call. = FALSE)
      }
    }

    mammal_raw_rule_counts <<- mammal_raw_rule_counts + c(
      placeholder_rows = sum(placeholder),
      multi_capture_events = sum(
        effort_rule[keep] == "canonical-multi-capture-one-trap"),
      reviewed_double_trap_events = sum(
        effort_rule[keep] == "reviewed-double-trap-rows"))
    same_night_tag_key <- paste(
      year[cap_flag], d$nightuid[cap_flag], d$plotID[cap_flag],
      tag[cap_flag], sep = "|")
    repeated_tag_keys <- unique(same_night_tag_key[
      duplicated(same_night_tag_key) |
        duplicated(same_night_tag_key, fromLast = TRUE)])
    mammal_same_night_tag_groups <<- mammal_same_night_tag_groups +
      length(repeated_tag_keys)
    capture_coordinate <- coordinate[cap_flag]
    mammal_same_night_tag_coordinate_conflicts <<-
      mammal_same_night_tag_coordinate_conflicts +
      sum(vapply(repeated_tag_keys, function(key)
        anyDuplicated(capture_coordinate[same_night_tag_key == key]) > 0L,
        logical(1)))
    same_event_tag_key <- paste(
      year[cap_flag], d$nightuid[cap_flag], d$plotID[cap_flag],
      capture_coordinate, tag[cap_flag], sep = "|")
    mammal_same_event_tag_groups <<- mammal_same_event_tag_groups +
      sum(table(same_event_tag_key) > 1L)
    mammal_tagged_half_effort_rows <<- mammal_tagged_half_effort_rows +
      sum(cap_flag & token %in% c(
        "2 - trap disturbed/door closed but empty",
        "3 - trap door open or closed w/ spoor left"))
    mammal_untagged_status5_rows <<- mammal_untagged_status5_rows +
      sum(!cap_flag & token == "5 - capture")

    years <- sort(unique(year))
    out <- data.frame(
      year = years,
      expected_tn = vapply(years, function(y)
        sum(resolved_effort[keep & year == y]), numeric(1)),
      expected_captures = vapply(years, function(y)
        sum(cap_flag[year == y]), integer(1)),
      expected_placeholder_rows = vapply(years, function(y)
        sum(placeholder & year == y), integer(1)),
      expected_multi_capture_events = vapply(years, function(y)
        sum(keep & year == y &
              effort_rule == "canonical-multi-capture-one-trap"), integer(1)),
      expected_reviewed_double_trap_events = vapply(years, function(y)
        sum(keep & year == y &
              effort_rule == "reviewed-double-trap-rows"), integer(1)),
      stringsAsFactors = FALSE)
    out$expected_cpue <- ifelse(out$expected_tn > 0,
                                100 * out$expected_captures / out$expected_tn, NA_real_)
    out$site <- sub("\\.rds$", "", basename(path)); out
  }))
  check(identical(sort(mammal_seen_tokens), sort(expected_mammal_tokens)),
        "pinned mammal sources expose exactly the six locked trapStatus tokens")
  check(identical(as.integer(mammal_raw_rule_counts), c(376L, 392L, 2L)) &&
          mammal_same_night_tag_groups == 79L &&
          mammal_same_event_tag_groups == 0L &&
          mammal_same_night_tag_coordinate_conflicts == 0L &&
          mammal_tagged_half_effort_rows == 10L &&
          mammal_untagged_status5_rows == 1L,
        paste("pinned mammal sources expose the reviewed placeholder/event",
              "rules and preserve tagged handling-row semantics"),
        sprintf("placeholder=%d; multi-capture=%d; double-trap=%d; repeated-tag-distinct-coordinate=%d",
                mammal_raw_rule_counts[["placeholder_rows"]],
                mammal_raw_rule_counts[["multi_capture_events"]],
                mammal_raw_rule_counts[["reviewed_double_trap_events"]],
                mammal_same_night_tag_groups))
  mammal_expected <- build_window(mammal_expected)
  mammal_derived <- annual[is.finite(annual$mammal_trap_nights) |
                             is.finite(annual$mammal_captures),
                           c("site", "year", "mammal_cpue",
                             "mammal_trap_nights", "mammal_captures",
                             "mammal_placeholder_trap_rows",
                             "mammal_multi_capture_trap_events",
                             "mammal_reviewed_double_trap_events"),
                           drop = FALSE]
  check_calendar(mammal_derived, mammal_expected,
                 "mammal source/derived support-calendar parity")
  observed <- merge(mammal_derived,
                    mammal_expected, by = c("site", "year"), all = FALSE)
  check(nrow(observed) > 0 && same_num(observed$mammal_trap_nights, observed$expected_tn) &&
          same_num(observed$mammal_captures, observed$expected_captures) &&
          same_num(observed$mammal_cpue, observed$expected_cpue) &&
          same_num(observed$mammal_placeholder_trap_rows,
                   observed$expected_placeholder_rows) &&
          same_num(observed$mammal_multi_capture_trap_events,
                   observed$expected_multi_capture_events) &&
          same_num(observed$mammal_reviewed_double_trap_events,
                   observed$expected_reviewed_double_trap_events),
        "mammal CPUE and effort-rule audits match independent raw-source recomputation",
        sprintf("%d source site-years", nrow(observed)))

  bird_dir <- file.path(source_root, "NEON-Breeding-Birds", "data", "sites")
  bird_files <- list.files(bird_dir, pattern = "\\.rds$", full.names = TRUE)
  bird_expected <- do.call(rbind, lapply(bird_files, function(path) {
    b <- readRDS(path); d <- b$obs
    if (is.null(d) || !nrow(d)) return(NULL)
    fly <- grepl("flyover", tolower(as.character(d$detectionMethod))); fly[is.na(fly)] <- FALSE
    visit <- paste(d$pointkey, d$eventID, sep = "|")
    do.call(rbind, lapply(split(seq_len(nrow(d)), d$year), function(ix) {
      nvis <- length(unique(visit[ix]))
      data.frame(site = sub("\\.rds$", "", basename(path)), year = d$year[ix[1]],
                 expected = if (nvis) sum(d$clusterSize[ix][!fly[ix]], na.rm = TRUE) / nvis else NA_real_)
    }))
  }))
  bird_expected <- build_window(bird_expected)
  bird_derived <- annual[is.finite(annual$bird_observed_point_visits),
                         c("site", "year", "bird_index"), drop = FALSE]
  check_calendar(bird_derived, bird_expected,
                 "bird source/derived support-calendar parity")
  observed <- merge(bird_derived, bird_expected,
                    by = c("site", "year"), all = FALSE)
  same <- same_num(observed$bird_index, observed$expected,
                   tolerance = 1e-15)
  check(nrow(observed) > 0 && all(same),
        "bird index matches non-flyover observed-visit recomputation",
        sprintf("%d source site-years", nrow(observed)))

  mosq_dir <- file.path(source_root, "NEON-Mosquito-Pulse", "data", "sites")
  mosq_files <- list.files(mosq_dir, pattern = "\\.rds$", full.names = TRUE)
  mosq_expected <- do.call(rbind, lapply(mosq_files, function(path) {
    b <- readRDS(path); ew <- b$effort_week
    eff <- stats::aggregate(as.numeric(ew$trap_nights), list(year = ew$year), sum, na.rm = TRUE)
    names(eff)[2] <- "expected_tn"
    o <- b$obs
    tg <- if ("is_target" %in% names(o)) o[o$is_target %in% TRUE, , drop = FALSE] else o
    catch <- if (nrow(tg)) {
      z <- stats::aggregate(as.numeric(tg$count), list(year = tg$year), sum, na.rm = TRUE)
      names(z)[2] <- "expected_catch"; z
    } else data.frame(year = integer(0), expected_catch = numeric(0))
    out <- merge(eff, catch, by = "year", all = TRUE)
    out$expected_catch[is.na(out$expected_catch) & is.finite(out$expected_tn)] <- 0
    out$expected_activity <- ifelse(out$expected_tn > 0,
                                    out$expected_catch / out$expected_tn, NA_real_)
    out$site <- sub("\\.rds$", "", basename(path)); out
  }))
  mosq_expected <- build_window(mosq_expected)
  mosq_derived <- annual[is.finite(annual$mosq_trap_nights) |
                           is.finite(annual$mosq_total_catch),
                         c("site", "year", "mosq_activity", "mosq_trap_nights", "mosq_total_catch"),
                         drop = FALSE]
  check_calendar(mosq_derived, mosq_expected,
                 "mosquito source/derived support-calendar parity")
  observed <- merge(mosq_derived,
                    mosq_expected, by = c("site", "year"), all = FALSE)
  check(nrow(observed) > 0 && same_num(observed$mosq_trap_nights, observed$expected_tn) &&
          same_num(observed$mosq_total_catch, observed$expected_catch) &&
          same_num(observed$mosq_activity, observed$expected_activity),
        "mosquito index matches effort-calendar source recomputation",
        sprintf("%d source site-years", nrow(observed)))
  check(any(observed$expected_tn > 0 & observed$expected_catch == 0 & observed$mosq_activity == 0),
        "mosquito effort-only zero-catch years remain explicit zeroes")

  beetle_dir <- file.path(source_root, "NEON-Ground-Beetle-Tracker", "data", "sites")
  beetle_files <- list.files(beetle_dir, pattern = "\\.rds$", full.names = TRUE)
  beetle_expected <- do.call(rbind, lapply(beetle_files, function(path) {
    d <- readRDS(path); d$year <- suppressWarnings(as.integer(format(as.Date(d$collectDate), "%Y")))
    d$individualCount <- suppressWarnings(as.numeric(d$individualCount))
    d$trapnights <- suppressWarnings(as.numeric(d$trapnights))
    d <- d[is.finite(d$year) & is.finite(d$individualCount) & d$individualCount > 0 &
             !is.na(d$scientificName) & nzchar(d$scientificName), , drop = FALSE]
    if (!nrow(d)) return(NULL)
    event <- !duplicated(paste(d$year, d$plotID, d$collectDate, d$trapnights, sep = "|"))
    eff <- stats::aggregate(d$trapnights[event], list(year = d$year[event]), sum, na.rm = TRUE)
    names(eff)[2] <- "expected_tn"
    catch <- stats::aggregate(d$individualCount, list(year = d$year), sum, na.rm = TRUE)
    names(catch)[2] <- "expected_catch"
    out <- merge(eff, catch, by = "year", all = TRUE)
    out$expected_activity <- ifelse(out$expected_tn > 0,
                                    100 * out$expected_catch / out$expected_tn, NA_real_)
    out$site <- sub("\\.rds$", "", basename(path)); out
  }))
  beetle_expected <- build_window(beetle_expected)
  beetle_derived <- annual[is.finite(annual$beetle_catch_event_trap_nights) |
                             is.finite(annual$beetle_total_catch),
                           c("site", "year", "beetle_activity",
                             "beetle_catch_event_trap_nights", "beetle_total_catch"),
                           drop = FALSE]
  check_calendar(beetle_derived, beetle_expected,
                 "beetle source/derived support-calendar parity")
  observed <- merge(beetle_derived,
                    beetle_expected, by = c("site", "year"), all = FALSE)
  check(nrow(observed) > 0 && same_num(observed$beetle_catch_event_trap_nights, observed$expected_tn) &&
          same_num(observed$beetle_total_catch, observed$expected_catch) &&
          same_num(observed$beetle_activity, observed$expected_activity),
        "beetle index matches catch-event source recomputation",
        sprintf("%d source site-years", nrow(observed)))

  veg_dir <- file.path(source_root, "NEON-Veg-Structure", "data", "sites")
  veg_files <- list.files(veg_dir, pattern = "\\.rds$", full.names = TRUE)
  veg_expected <- dplyr::bind_rows(lapply(veg_files, function(path) {
    site <- sub("\\.rds$", "", basename(path))
    if (!site %in% annual_sites) return(NULL)
    oracle_veg_bundle(readRDS(path), site)
  }))
  unsupported_veg <- veg_expected[
    veg_expected$expected_unmatched_record_plots > 0L, , drop = FALSE]
  expected_wood_unmatched_ids <- paste(c(
    "WOOD_008", "WOOD_009", "WOOD_012", "WOOD_014", "WOOD_015",
    "WOOD_016", "WOOD_018", "WOOD_019", "WOOD_045", "WOOD_056",
    "WOOD_057", "WOOD_061", "WOOD_070", "WOOD_071"), collapse = ",")
  check(nrow(unsupported_veg) == 1L && unsupported_veg$site == "WOOD" &&
          is.na(unsupported_veg$expected_ba) &&
          is.na(unsupported_veg$expected_type) &&
          unsupported_veg$expected_n_plots == 0L &&
          unsupported_veg$expected_record_plots == 14L &&
          unsupported_veg$expected_matched_record_plots == 0L &&
          unsupported_veg$expected_area_eligible_plots == 0L &&
          unsupported_veg$expected_unmatched_record_plots == 14L &&
          unsupported_veg$expected_unmatched_record_rows == 452L &&
          unsupported_veg$source_unmatched_qualifying_rows == 411L &&
          unsupported_veg$source_unmatched_plot_ids ==
            expected_wood_unmatched_ids &&
          unsupported_veg$expected_design_status ==
            "unsupported-unmatched-plots",
        "pinned vegetation source has exactly one reviewed unsupported design",
        "WOOD: 452 rows/14 plots unmatched; 411 qualifying rows unscalable")
  veg_derived <- site_meta[is.finite(site_meta$veg_record_plots),
                           c("site", "veg_ba_ha", "veg_ba_se", "veg_type",
                             "veg_n_plots", "veg_record_plots",
                             "veg_matched_record_plots",
                             "veg_area_eligible_plots",
                             "veg_unmatched_record_plots",
                             "veg_unmatched_record_rows",
                             "veg_class_tree_ba_ha",
                             "veg_class_shrub_ba_ha",
                             "veg_class_tree_plots",
                             "veg_class_shrub_plots",
                             "veg_stand_basis", "veg_class_basis",
                             "veg_design_status", "veg_design_basis"),
                           drop = FALSE]
  check(!anyDuplicated(veg_expected$site) && !anyDuplicated(veg_derived$site) &&
          setequal(veg_expected$site, veg_derived$site),
        "vegetation source/derived site coverage parity",
        sprintf("%d sites", nrow(veg_expected)))
  observed <- merge(veg_derived, veg_expected, by = "site", all = FALSE)
  check(nrow(observed) > 0 &&
          same_num(observed$veg_ba_ha, observed$expected_ba) &&
          same_num(observed$veg_ba_se, observed$expected_se) &&
          same_num(observed$veg_n_plots, observed$expected_n_plots) &&
          same_num(observed$veg_record_plots, observed$expected_record_plots) &&
          same_num(observed$veg_matched_record_plots,
                   observed$expected_matched_record_plots) &&
          same_num(observed$veg_area_eligible_plots,
                   observed$expected_area_eligible_plots) &&
          same_num(observed$veg_unmatched_record_plots,
                   observed$expected_unmatched_record_plots) &&
          same_num(observed$veg_unmatched_record_rows,
                   observed$expected_unmatched_record_rows) &&
          same_num(observed$veg_class_tree_ba_ha,
                   observed$expected_tree_class_ba_ha) &&
          same_num(observed$veg_class_shrub_ba_ha,
                   observed$expected_shrub_class_ba_ha) &&
          same_num(observed$veg_class_tree_plots,
                   observed$expected_tree_class_plots) &&
          same_num(observed$veg_class_shrub_plots,
                   observed$expected_shrub_class_plots) &&
          identical(as.character(observed$veg_type),
                    as.character(observed$expected_type)) &&
          identical(as.character(observed$veg_stand_basis),
                    as.character(observed$expected_stand_basis)) &&
          identical(as.character(observed$veg_class_basis),
                    as.character(observed$expected_class_basis)) &&
          identical(as.character(observed$veg_design_status),
                    as.character(observed$expected_design_status)) &&
          identical(as.character(observed$veg_design_basis),
                    as.character(observed$expected_design_basis)),
        "vegetation context/design audits match independent source recomputation",
        sprintf("%d source sites", nrow(observed)))} else {
  cat("[SKIP] source-level product recomputations (CASCADE_ROOT not set)\n")
}

cat(sprintf("\nALL CASCADE CONTRACT TESTS PASSED (%s)\n", ROOT))
