# ===========================================================================
# NEON Driver Cascade — cascade_meta.R
# A COMPANION random-effects meta-analysis of the cascade's ONE well-replicated
# rung: warmer springs -> earlier green-up. It does NOT replace the binomial
# sign-test headline; it sits beside it (About > Methods / the report) and adds
# what the sign tally cannot: a pooled effect size, a posterior/CI probability
# of direction, and a between-site heterogeneity (I^2) test.
#
# SCOPE (Cass's sign-off, 2026-06): green-up rung ONLY.
#   * temp        -> greenup_doy   (annual-mean stand-in; ~32 sites)
#   * temp_spring -> greenup_doy   (mechanistic spring window; fewer sites)
# WHY ONLY THIS RUNG:
#   1. A random-effects meta-analysis needs enough sites for tau^2 / I^2 to mean
#      anything. Green-up is the only rung with ~32 sites; the consumer rungs have
#      1-6 sites, where I^2 is noise dressed as a heterogeneity test.
#   2. The consumer signals (mammal_cpue, bird_index) are WITHIN-SITE indices.
#      A correlation r between two indices is scale-free, so z-pooling r does not
#      smuggle magnitude across sites — BUT 1/(n-3) weighting + tiny site counts
#      make the pool meaningless there, and the binomial sign test is the honest
#      cross-site statistic for an index. We do NOT run this on those rungs.
#   `conf` (strong/moderate/weak) is a hand-assigned literature label, NOT a
#   calibrated effect-size prior, so it is NEVER used as a Bayesian prior here.
#
# Run from the NEON-Driver-Cascade dir:  Rscript scripts/cascade_meta.R
# Reads data/cascade.rds (the precomputed suite_links). Writes a small companion
# bundle data/cascade_meta.rds the About>Methods panel can surface (optional).
# ===========================================================================
suppressPackageStartupMessages({ library(dplyr) })

GREENUP_LINKS <- list(
  c(from = "temp",        to = "greenup_doy"),
  c(from = "temp_spring", to = "greenup_doy"))
MIN_SITES <- 5L   # below this, a random-effects pool is not interpretable; report binomial only

cascade <- readRDS("data/cascade.rds")
sl <- cascade$suite_links
stopifnot(all(c("from","to","r","n","sign_match","expected","biome_class","site") %in% names(sl)))

# Fisher-z transform with its known sampling variance. n>=6 guarantees a finite se
# (var = 1/(n-3)); we also clamp r off the +-1 boundary so atanh() stays finite.
fisher_z <- function(r) atanh(pmax(pmin(r, 0.999), -0.999))

meta_one <- function(from, to) {
  d <- sl |>
    filter(.data$from == !!from, .data$to == !!to,
           .data$expected %in% TRUE, .data$n >= 6, is.finite(.data$r), !is.na(.data$sign_match))
  if (nrow(d) < MIN_SITES) {
    return(list(from = from, to = to, sites = nrow(d), poolable = FALSE,
                note = sprintf("only %d expected, testable sites (<%d) — not enough to pool a random-effects meta-analysis; the binomial sign test is the honest cross-site read here.",
                               nrow(d), MIN_SITES)))
  }
  d <- d |> mutate(z = fisher_z(.data$r), vi = 1 / (.data$n - 3))

  # ---- frequentist random-effects meta-analysis (metafor::rma) -------------
  rma_out <- NULL
  if (requireNamespace("metafor", quietly = TRUE)) {
    fit <- metafor::rma(yi = d$z, vi = d$vi, method = "REML")
    pooled_r  <- tanh(as.numeric(fit$b))                 # back-transform pooled z -> r
    ci_r      <- tanh(c(fit$ci.lb, fit$ci.ub))
    # P(direction): the green-up prior is NEGATIVE (warmer -> EARLIER -> smaller DOY),
    # so "as predicted" means the pooled effect is < 0. Report the probability of the
    # predicted sign from the pooled z and its SE (normal approximation).
    se_z      <- as.numeric(fit$se)
    p_dir     <- stats::pnorm(0, mean = as.numeric(fit$b), sd = se_z)   # P(z < 0) = P(earlier)
    rma_out <- list(
      pooled_r = round(pooled_r, 3), ci_r = round(ci_r, 3),
      p_direction_predicted = round(p_dir, 3),
      I2 = round(fit$I2, 1), tau2 = round(fit$tau2, 4),
      Q = round(fit$QE, 2), Q_p = round(fit$QEp, 4), k = fit$k)
  }

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
                brms::prior(exponential(2), class = "sd")),         # half-flat would not identify tau on ~32 sites
      chains = 4, iter = 4000, warmup = 1000,
      control = list(adapt_delta = 0.99), seed = 1, refresh = 0)
    # convergence gate — never read a number from an unconverged chain
    s <- posterior::summarise_draws(bfit)
    ok <- all(s$rhat < 1.01, na.rm = TRUE) && all(s$ess_bulk > 400, na.rm = TRUE) &&
          all(s$ess_tail > 400, na.rm = TRUE)
    ndiv <- sum(brms::nuts_params(bfit)$Parameter == "divergent__" &
                brms::nuts_params(bfit)$Value > 0)
    draws <- brms::as_draws_df(bfit)
    brms_out <- list(
      converged = ok, divergences = ndiv,
      pooled_r = round(tanh(mean(draws$b_Intercept)), 3),
      cri_r = round(tanh(stats::quantile(draws$b_Intercept, c(0.05, 0.95))), 3),
      p_direction_predicted = round(mean(draws$b_Intercept < 0), 3))  # P(earlier green-up)
  }

  list(from = from, to = to, sites = nrow(d), poolable = TRUE,
       median_r = round(stats::median(d$r), 3),
       sign_match = sprintf("%d/%d sites", sum(d$sign_match), nrow(d)),
       rma = rma_out, brms = brms_out)
}

res <- lapply(GREENUP_LINKS, function(g) meta_one(g[["from"]], g[["to"]]))

cat("\n==== CASCADE COMPANION META-ANALYSIS (green-up rung only) ====\n")
cat("Companion to the binomial sign-test headline, NOT a replacement.\n")
for (r in res) {
  cat(sprintf("\n%s -> %s  (%d sites)\n", r$from, r$to, r$sites))
  if (!isTRUE(r$poolable)) { cat("  ", r$note, "\n"); next }
  cat(sprintf("  sign-match (the headline statistic): %s · median r = %+.2f\n", r$sign_match, r$median_r))
  if (!is.null(r$rma)) cat(sprintf(
    "  metafor::rma  pooled r = %+.3f  [%.3f, %.3f]  P(earlier green-up) = %.3f  I^2 = %.1f%%  (Q p = %.4f, k = %d)\n",
    r$rma$pooled_r, r$rma$ci_r[1], r$rma$ci_r[2], r$rma$p_direction_predicted, r$rma$I2, r$rma$Q_p, r$rma$k))
  else cat("  (install 'metafor' for the frequentist random-effects pool)\n")
  if (!is.null(r$brms)) cat(sprintf(
    "  brms          pooled r = %+.3f  [%.3f, %.3f]  P(earlier) = %.3f  converged = %s  divergences = %d\n",
    r$brms$pooled_r, r$brms$cri_r[1], r$brms$cri_r[2], r$brms$p_direction_predicted, r$brms$converged, r$brms$divergences))
}
cat("\nHonest framing: a high P(direction) here CORROBORATES the binomial headline with\n",
    "an effect size and a heterogeneity test; it does not upgrade the per-site verdicts,\n",
    "and it is run ONLY on the green-up rung where the site count supports it.\n", sep = "")

saveRDS(res, "data/cascade_meta.rds")
cat("\nwrote data/cascade_meta.rds (companion; the About>Methods panel may surface it)\n")

# To run the Bayesian companion too (slower; needs brms + cmdstanr/rstan):
#   options(cascade_meta.run_brms = TRUE); source("scripts/cascade_meta.R")
