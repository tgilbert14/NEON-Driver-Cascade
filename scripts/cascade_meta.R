# ===========================================================================
# NEON Driver Cascade — cascade_meta.R
# A COMPANION random-effects meta-analysis of the cascade's ONE well-replicated
# rung: warmer conditions -> earlier green-up. It does NOT replace the pooled
# direction summary; it sits beside it (About > Methods / the report) and adds
# what the sign tally cannot: a pooled effect size, small-sample-adjusted
# uncertainty, a between-site prediction interval and heterogeneity summary,
# plus a multiplicity-adjusted directional diagnostic. The family evolved while these data were being
# inspected, so this one-sided result is not a preregistered confirmatory test.
#
# SCOPE (Cass's sign-off, 2026-06): green-up rung ONLY.
#   * temp        -> greenup_doy   (annual-mean stand-in)
#   * temp_spring -> greenup_doy   (March-May contemporaneous proxy; may include post-onset weather)
# WHY ONLY THIS RUNG:
#   1. A random-effects meta-analysis needs enough sites for tau^2 / I^2 to mean
#      anything. Green-up is the only rung with broad site support; the consumer
#      rungs are too sparse for I^2 to be an interpretable heterogeneity test.
#   2. The consumer signals (mammal_cpue, bird_index) are WITHIN-SITE indices.
#      A correlation r between two indices is scale-free, so z-pooling r does not
#      smuggle magnitude across sites — BUT 1/(n-3) weighting + tiny site counts
#      make the pool meaningless there, and the descriptive binomial direction
#      summary is the more transparent cross-site statistic for an index.
#      We do NOT run this model on those rungs.
#   `conf` (strong/moderate/weak/none) is a hand-assigned literature label, NOT a
#   calibrated effect-size prior, so it is NEVER used as a Bayesian prior here.
#
# Run from the NEON-Driver-Cascade dir:  Rscript scripts/cascade_meta.R
# Reads data/cascade.rds (the precomputed suite_links). Writes a small companion
# bundle data/cascade_meta.rds the About>Methods panel can surface (optional).
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
setwd_repo_root()
source("scripts/generation_guard.R", local = TRUE)

CASCADE_META_INFERENCE_SCHEMA <- "cascade-meta-reml-knha-holm-prediction-v1"
CASCADE_META_MULTIPLICITY_FAMILY <- c(
  "temp|greenup_doy", "temp_spring|greenup_doy")
LOCAL_META_INPUT_PATHS <- c(
  "scripts/cascade_meta.R", "scripts/generation_guard.R",
  "R/cascade_helpers.R")
cascade_meta_local_input_inventory <- function(paths) {
  if (any(!file.exists(paths)))
    stop(sprintf("local meta input(s) missing: %s",
                 paste(paths[!file.exists(paths)], collapse = ", ")),
         call. = FALSE)
  data.frame(relative_path = paths, md5 = unname(tools::md5sum(paths)),
             stringsAsFactors = FALSE)
}
LOCAL_META_INPUTS <- cascade_meta_local_input_inventory(LOCAL_META_INPUT_PATHS)
assert_local_meta_inputs_unchanged <- function() {
  current <- cascade_meta_local_input_inventory(LOCAL_META_INPUT_PATHS)
  if (!identical(LOCAL_META_INPUTS, current))
    stop("local executable meta inputs changed during generation; discard and rerun scripts/rebuild_all.R",
         call. = FALSE)
  invisible(TRUE)
}
META_SCRIPT_MD5 <- LOCAL_META_INPUTS$md5[
  match("scripts/cascade_meta.R", LOCAL_META_INPUTS$relative_path)]

suppressPackageStartupMessages({ library(dplyr) })
if (!requireNamespace("metafor", quietly = TRUE))
  stop("metafor is required for the companion random-effects analysis", call. = FALSE)

eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv) # schema/tier constants and %||%
assert_local_meta_inputs_unchanged()

GREENUP_LINKS <- list(
  c(from = "temp",        to = "greenup_doy"),
  c(from = "temp_spring", to = "greenup_doy"))
MIN_SITES <- 5L   # below this, a random-effects pool is not interpretable; report binomial only

source_bundle_md5 <- unname(tools::md5sum("data/cascade.rds"))
cascade <- readRDS("data/cascade.rds")
SOURCE_LOCAL_BUILD_INPUT_PATHS <- c(
  "scripts/build_cascade.R", "scripts/generation_guard.R",
  "scripts/source_snapshot.R", "R/cascade_helpers.R",
  "R/site_metadata.R", "R/source_adapters.R")
source_local_build_inputs <- cascade$meta$local_build_inputs
if (!is.data.frame(source_local_build_inputs) ||
    !identical(names(source_local_build_inputs), c("relative_path", "md5")) ||
    !identical(as.character(source_local_build_inputs$relative_path),
               SOURCE_LOCAL_BUILD_INPUT_PATHS) ||
    anyNA(source_local_build_inputs$md5) ||
    !all(grepl("^[0-9a-f]{32}$", as.character(source_local_build_inputs$md5))))
  stop("cascade.rds has malformed local executable-input lineage; rebuild cascade.rds first",
       call. = FALSE)
if (!identical(source_local_build_inputs,
               cascade_meta_local_input_inventory(SOURCE_LOCAL_BUILD_INPUT_PATHS)))
  stop("cascade.rds was built by different local executable inputs; use scripts/rebuild_all.R",
       call. = FALSE)
bundle_toolchain <- cascade$meta$build_toolchain
if (!is.data.frame(bundle_toolchain) ||
    length(setdiff(c("component", "version"), names(bundle_toolchain))) ||
    nrow(bundle_toolchain) != 3L ||
    anyDuplicated(as.character(bundle_toolchain$component)) ||
    !setequal(as.character(bundle_toolchain$component), c("R", "dplyr", "tibble")) ||
    anyNA(bundle_toolchain$version) ||
    any(!nzchar(as.character(bundle_toolchain$version))))
  stop("cascade.rds has an incomplete build toolchain; rebuild cascade.rds first",
       call. = FALSE)
bundle_versions <- stats::setNames(as.character(bundle_toolchain$version),
                                  as.character(bundle_toolchain$component))
current_versions <- c(
  R = as.character(getRversion()),
  dplyr = as.character(utils::packageVersion("dplyr")),
  tibble = as.character(utils::packageVersion("tibble")))
if (!identical(unname(bundle_versions[names(current_versions)]),
               unname(current_versions)))
  stop("companion meta-analysis must run with the same R/dplyr/tibble versions as cascade.rds; use scripts/rebuild_all.R",
       call. = FALSE)
if (!identical(cascade$meta$build_script_md5 %||% NA_character_,
               unname(tools::md5sum("scripts/build_cascade.R"))) ||
    !identical(cascade$meta$source_adapters_md5 %||% NA_character_,
               unname(tools::md5sum("R/source_adapters.R"))))
  stop("cascade.rds was built by different local adapter/build logic; use scripts/rebuild_all.R",
       call. = FALSE)

sl <- cascade$suite_links
stopifnot(all(c("from","to","r","n","sign_match","expected","biome_class","domain","site",
                "sign_match_detrended","sign_match_change",
                "sign_match_outcome_alt") %in% names(sl)))
if (!identical(cascade$meta$prior_family_version %||% NA_character_, PRIOR_FAMILY_VERSION) ||
    !identical(cascade$meta$prior_family_status %||% NA_character_, PRIOR_FAMILY_STATUS)) {
  stop("cascade.rds prior-family disclosure is missing or incompatible; rebuild cascade.rds first",
       call. = FALSE)
}
if (!identical(cascade$meta$trend_sensitivity_version %||% NA_character_, TREND_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$trend_sensitivity_note %||% NA_character_, TREND_SENSITIVITY_NOTE)) {
  stop("cascade.rds trend-sensitivity lineage is missing or incompatible; rebuild cascade.rds first",
       call. = FALSE)
}
if (!identical(cascade$meta$estimator_sensitivity_version %||% NA_character_, ESTIMATOR_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$estimator_sensitivity_note %||% NA_character_, ESTIMATOR_SENSITIVITY_NOTE)) {
  stop("cascade.rds estimator-sensitivity lineage is missing or incompatible; rebuild cascade.rds first",
       call. = FALSE)
}
if (!identical(cascade$meta$spatial_sensitivity_version %||% NA_character_, SPATIAL_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$spatial_sensitivity_note %||% NA_character_, SPATIAL_SENSITIVITY_NOTE)) {
  stop("cascade.rds spatial-sensitivity lineage is missing or incompatible; rebuild cascade.rds first",
       call. = FALSE)
}
if (!identical(cascade$meta$greenup_index_version %||% NA_character_, GREENUP_INDEX_VERSION) ||
    !identical(cascade$meta$greenup_index_note %||% NA_character_, GREENUP_INDEX_NOTE)) {
  stop("cascade.rds green-up index lineage is missing or incompatible; rebuild cascade.rds first",
       call. = FALSE)
}

# Fisher-z transform with its conventional sampling variance. n>=6 guarantees a
# finite SE (var = 1/(n-3)); we also clamp r off the +/-1 boundary so atanh()
# stays finite. That variance treats paired years as effectively independent and
# does NOT model within-site serial dependence, so this RMA is a sensitivity
# companion rather than stronger evidence than the gap-aware per-site analysis.
fisher_z <- function(r) atanh(pmax(pmin(r, 0.999), -0.999))

meta_one <- function(from, to) {
  link_rows <- sl |>
    filter(.data$from == !!from, .data$to == !!to)
  prior_signs <- unique(link_rows$prior_sign[is.finite(link_rows$prior_sign)])
  if (length(prior_signs) != 1L || !prior_signs %in% c(-1, 1))
    stop(sprintf("%s -> %s does not have one stable +/-1 prior direction", from, to), call. = FALSE)
  prior_sign <- as.integer(prior_signs)
  d_effect <- link_rows |>
    filter(.data$expected %in% TRUE, .data$n >= 6, is.finite(.data$r))
  d_vote <- d_effect |> filter(!is.na(.data$sign_match))
  sensitivity_count <- function(column) {
    if (!column %in% names(d_vote)) return(list(sites = 0L, k = 0L))
    v <- d_vote[[column]]; ok <- !is.na(v)
    list(sites = as.integer(sum(ok)), k = as.integer(sum(v[ok])))
  }
  trend_sensitivity <- list(
    version = TREND_SENSITIVITY_VERSION,
    note = TREND_SENSITIVITY_NOTE,
    raw = list(sites = nrow(d_vote), k = as.integer(sum(d_vote$sign_match))),
    detrended = sensitivity_count("sign_match_detrended"),
    change = sensitivity_count("sign_match_change"))
  estimator_sensitivity <- list(
    version = ESTIMATOR_SENSITIVITY_VERSION,
    note = ESTIMATOR_SENSITIVITY_NOTE,
    outcome_alt = sensitivity_count("sign_match_outcome_alt"))
  domain_counts <- domain_majority_counts(d_vote)
  spatial_sensitivity <- list(
    version = SPATIAL_SENSITIVITY_VERSION,
    note = SPATIAL_SENSITIVITY_NOTE,
    domains = domain_counts$domains,
    k_domain = domain_counts$k_domain,
    domain_ties = domain_counts$domain_ties)
  if (nrow(d_effect) < MIN_SITES) {
    return(list(from = from, to = to, prior_sign = prior_sign,
                sites = nrow(d_effect), poolable = FALSE,
                trend_sensitivity = trend_sensitivity,
                estimator_sensitivity = estimator_sensitivity,
                spatial_sensitivity = spatial_sensitivity,
                note = sprintf("only %d vote-eligible sites with finite effects (<%d) — not enough to pool a random-effects meta-analysis; report the exploratory direction counts only.",
                               nrow(d_effect), MIN_SITES)))
  }
  d <- d_effect
  d <- d |> mutate(z = fisher_z(.data$r), vi = 1 / (.data$n - 3))
  # ---- frequentist random-effects meta-analysis (metafor::rma) -------------
  # REML estimates heterogeneity; Knapp-Hartung uses a k-p t reference and is
  # deliberately conservative for this small site sample. Prediction intervals
  # lead interpretation because they expose between-site dispersion.
  fit <- metafor::rma(yi = d$z, vi = d$vi, method = "REML", test = "knha")
  pred <- stats::predict(fit)
  pooled_r <- tanh(as.numeric(fit$b))
  ci_r <- tanh(c(fit$ci.lb, fit$ci.ub))
  pi_r <- tanh(c(pred$pi.lb, pred$pi.ub))
  se_z <- as.numeric(fit$se)
  t_test <- as.numeric(fit$b) / se_z
  df <- as.integer(fit$k - fit$p)
  p_one <- if (prior_sign < 0L) stats::pt(t_test, df = df) else
    stats::pt(t_test, df = df, lower.tail = FALSE)
  rma_out <- list(
    pooled_r = as.numeric(pooled_r), ci_r = as.numeric(ci_r),
    pi_r = as.numeric(pi_r), se_z = se_z, t_stat = as.numeric(t_test),
    df = df, p_one_sided = as.numeric(p_one),
    p_one_sided_holm = NA_real_,
    test_method = "REML random-effects with Knapp-Hartung inference",
    inference_role = "exploratory sensitivity; prediction interval and heterogeneity precede directional p-values",
    I2 = as.numeric(fit$I2), tau2 = as.numeric(fit$tau2),
    Q = as.numeric(fit$QE), Q_p = as.numeric(fit$QEp), k = as.integer(fit$k))

  # ---- Bayesian partial-pool (brms), OPTIONAL --------------------------------
  # Same model, Bayesian: borrows strength across sites, returns a true posterior
  # P(direction). biome_class enters only as a GROUPING factor (not a prior). With a
  # handful of biome classes a (1|biome_class/site) term can be near-singular, so we
  # use (1|site) and report biome as context (Cass + McElreath Ch13 caution).
  brms_out <- NULL
  if (requireNamespace("brms", quietly = TRUE) && isTRUE(getOption("cascade_meta.run_brms", FALSE))) {
    bd <- d |> mutate(se_z = sqrt(.data$vi))
    bfit <- brms::brm(
      brms::bf(z | se(se_z) ~ 1 + (1 | site)),
      data = bd,
      prior = c(brms::prior(normal(0, 1), class = "Intercept"),     # weakly-informative on z
                brms::prior(exponential(2), class = "sd")),         # regularizes tau with a finite site sample
      chains = 4, iter = 4000, warmup = 1000,
      control = list(adapt_delta = 0.99), seed = 1, refresh = 0)
    # convergence gate — never read a number from an unconverged chain
    # Missing diagnostics, weak ESS/R-hat, or any divergent transition abort
    # generation instead of attaching estimates to a converged=FALSE flag.
    s <- posterior::summarise_draws(bfit)
    diag_fields <- c("rhat", "ess_bulk", "ess_tail")
    diag_complete <- is.data.frame(s) && nrow(s) > 0L &&
      all(diag_fields %in% names(s)) &&
      all(vapply(s[diag_fields], function(x) all(is.finite(x)), logical(1)))
    nuts <- brms::nuts_params(bfit)
    nuts_complete <- is.data.frame(nuts) &&
      all(c("Parameter", "Value") %in% names(nuts)) &&
      any(nuts$Parameter == "divergent__")
    ndiv <- if (nuts_complete)
      sum(nuts$Parameter == "divergent__" & nuts$Value > 0) else NA_integer_
    ok <- diag_complete && all(s$rhat < 1.01) &&
      all(s$ess_bulk > 400) && all(s$ess_tail > 400) &&
      is.finite(ndiv) && ndiv == 0L
    if (!ok)
      stop(sprintf(
        "optional brms companion failed diagnostics (complete=%s, divergences=%s); no Bayesian estimates were published",
        diag_complete && nuts_complete, as.character(ndiv)), call. = FALSE)
    draws <- brms::as_draws_df(bfit)
    brms_out <- list(
      converged = TRUE, divergences = as.integer(ndiv),
      pooled_r = as.numeric(tanh(mean(draws$b_Intercept))),
      cri_r = as.numeric(tanh(stats::quantile(draws$b_Intercept, c(0.05, 0.95)))),
      posterior_prob_stated_direction = as.numeric(if (prior_sign < 0L)
        mean(draws$b_Intercept < 0) else mean(draws$b_Intercept > 0)))
  }

  list(from = from, to = to, prior_sign = prior_sign,
       sites = nrow(d), poolable = TRUE,
       median_r = as.numeric(stats::median(d$r)),
       sign_match_k = as.integer(sum(d_vote$sign_match)), sign_match_n = nrow(d_vote),
       sign_match = sprintf("%d/%d sites", sum(d_vote$sign_match), nrow(d_vote)),
       trend_sensitivity = trend_sensitivity,
       estimator_sensitivity = estimator_sensitivity,
       spatial_sensitivity = spatial_sensitivity,
       rma = rma_out, brms = brms_out)
}

res <- lapply(GREENUP_LINKS, function(g) meta_one(g[["from"]], g[["to"]]))
raw_p <- vapply(res, function(x)
  if (!is.null(x$rma)) x$rma$p_one_sided else NA_real_, numeric(1))
available <- which(is.finite(raw_p))
if (length(available)) {
  adjusted <- stats::p.adjust(raw_p[available], method = "holm",
                              n = length(GREENUP_LINKS))
  for (i in seq_along(available))
    res[[available[i]]]$rma$p_one_sided_holm <- as.numeric(adjusted[i])
}
ran_brms <- any(vapply(res, function(x) !is.null(x$brms), logical(1)))
companion_toolchain <- data.frame(
  component = c("R", "dplyr", "tibble", "metafor"),
  version = c(as.character(getRversion()),
              as.character(utils::packageVersion("dplyr")),
              as.character(utils::packageVersion("tibble")),
              as.character(utils::packageVersion("metafor"))),
  stringsAsFactors = FALSE)
if (ran_brms)
  companion_toolchain <- rbind(
    companion_toolchain,
    data.frame(component = c("brms", "posterior"),
               version = c(as.character(utils::packageVersion("brms")),
                           as.character(utils::packageVersion("posterior"))),
               stringsAsFactors = FALSE))

attr(res, "schema_version") <- CASCADE_META_SCHEMA_VERSION
attr(res, "inference_schema") <- CASCADE_META_INFERENCE_SCHEMA
attr(res, "multiplicity_method") <- "holm"
attr(res, "multiplicity_family") <- CASCADE_META_MULTIPLICITY_FAMILY
attr(res, "source_bundle_md5") <- source_bundle_md5
attr(res, "source_bundle_schema") <- cascade$meta$schema_version %||% NA_character_
attr(res, "tier_rule") <- cascade$meta$tier_rule %||% NA_character_
attr(res, "prior_family_version") <- PRIOR_FAMILY_VERSION
attr(res, "prior_family_status") <- PRIOR_FAMILY_STATUS
attr(res, "greenup_index_version") <- GREENUP_INDEX_VERSION
attr(res, "greenup_index_note") <- GREENUP_INDEX_NOTE
attr(res, "trend_sensitivity_version") <- TREND_SENSITIVITY_VERSION
attr(res, "trend_sensitivity_note") <- TREND_SENSITIVITY_NOTE
attr(res, "estimator_sensitivity_version") <- ESTIMATOR_SENSITIVITY_VERSION
attr(res, "estimator_sensitivity_note") <- ESTIMATOR_SENSITIVITY_NOTE
attr(res, "spatial_sensitivity_version") <- SPATIAL_SENSITIVITY_VERSION
attr(res, "spatial_sensitivity_note") <- SPATIAL_SENSITIVITY_NOTE
attr(res, "built") <- cascade$meta$built_when
attr(res, "source_snapshot_method") <- cascade$meta$source_snapshot_method
attr(res, "source_build_script_md5") <- cascade$meta$build_script_md5
attr(res, "source_adapters_md5") <- cascade$meta$source_adapters_md5
attr(res, "source_local_build_inputs") <- source_local_build_inputs
attr(res, "local_meta_inputs") <- LOCAL_META_INPUTS
attr(res, "meta_script_md5") <- META_SCRIPT_MD5
attr(res, "build_toolchain") <- companion_toolchain
attr(res, "r_version") <- as.character(getRversion())
attr(res, "dplyr_version") <- as.character(utils::packageVersion("dplyr"))
attr(res, "tibble_version") <- as.character(utils::packageVersion("tibble"))
attr(res, "metafor_version") <- as.character(utils::packageVersion("metafor"))

cat("\n==== CASCADE COMPANION META-ANALYSIS (green-up rung only) ====\n")
cat("Companion sensitivity analysis to the exploratory cross-site direction summary.\n")
for (r in res) {
  cat(sprintf("\n%s -> %s  (%d sites)\n", r$from, r$to, r$sites))
  if (!isTRUE(r$poolable)) { cat("  ", r$note, "\n"); next }
  cat(sprintf("  descriptive sign agreement: %s · median r = %+.2f\n", r$sign_match, r$median_r))
  cat(sprintf("  trend sensitivity: raw %d/%d · detrended %d/%d · consecutive-change %d/%d\n",
              r$trend_sensitivity$raw$k, r$trend_sensitivity$raw$sites,
              r$trend_sensitivity$detrended$k, r$trend_sensitivity$detrended$sites,
              r$trend_sensitivity$change$k, r$trend_sensitivity$change$sites))
  cat(sprintf("  green-up estimator sensitivity: additive outcome %d/%d stated directions (same raw-vote sites; no extra p)\n",
              r$estimator_sensitivity$outcome_alt$k,
              r$estimator_sensitivity$outcome_alt$sites))
  cat(sprintf("  spatial sensitivity: %d/%d NEON-domain majority votes; %d tied domain%s abstain%s (no extra p)\n",
              r$spatial_sensitivity$k_domain, r$spatial_sensitivity$domains,
              r$spatial_sensitivity$domain_ties,
              if (r$spatial_sensitivity$domain_ties == 1L) "" else "s",
              if (r$spatial_sensitivity$domain_ties == 1L) "s" else ""))
  if (!is.null(r$rma)) cat(sprintf(
    "  REML + Knapp-Hartung pooled r = %+.3f  CI [%.3f, %.3f]  prediction [%.3f, %.3f]  I^2 = %.1f%%  raw one-sided p = %.4g  Holm p = %.4g  (k = %d, df = %d)\n",
    r$rma$pooled_r, r$rma$ci_r[1], r$rma$ci_r[2],
    r$rma$pi_r[1], r$rma$pi_r[2], r$rma$I2,
    r$rma$p_one_sided, r$rma$p_one_sided_holm, r$rma$k, r$rma$df))
  else cat("  (install 'metafor' for the frequentist random-effects pool)\n")
  if (!is.null(r$brms)) cat(sprintf(
    "  brms          pooled r = %+.3f  [%.3f, %.3f]  posterior Pr(earlier) = %.3f  converged = %s  divergences = %d\n",
    r$brms$pooled_r, r$brms$cri_r[1], r$brms$cri_r[2], r$brms$posterior_prob_stated_direction, r$brms$converged, r$brms$divergences))
}
cat("\nHonest framing: prediction intervals and heterogeneity are the primary companion\n",
    "outputs. Directional p-values use Knapp-Hartung t inference and Holm adjustment\n",
    "across the two build-locked green-up contrasts. Smaller values align with the\n",
    "exploratory family's earlier-green-up direction. The family\n",
    "was co-developed while these data were inspected, so this is not confirmatory.\n",
    "Only the optional brms\n",
    "field is a posterior probability. Neither upgrades a per-site verdict, and this\n",
    "companion is run only where the green-up site count supports it. Fisher-z sampling\n",
    "variance assumes effectively independent paired years and does not model within-site\n",
    "serial dependence, which is why this remains a sensitivity analysis.\n", sep = "")

assert_local_meta_inputs_unchanged()
res <- cascade_normalize_artifact_text(res)
cascade_assert_artifact_text(res, "data/cascade_meta.rds")
saveRDS(res, "data/cascade_meta.rds")
cat("\nwrote data/cascade_meta.rds (companion; the About>Methods panel may surface it)\n")

# To run the Bayesian companion too (slower; needs brms + cmdstanr/rstan):
#   options(cascade_meta.run_brms = TRUE); source("scripts/cascade_meta.R")
