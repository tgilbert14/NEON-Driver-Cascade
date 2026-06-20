# ===========================================================================
# NEON Driver Cascade — cascade_helpers.R
# Cross-trophic, bottom-up driver analysis on SHORT annual series (n≈3–13/site).
# The discipline (grounded in Sarah's lit + short-series stats review):
#   * STATE PRIORS from the literature (sign + lag), don't dredge for a winning lag.
#   * n-GATE everything: n<3 can't compare; 3–5 exploratory (no p, no verdict);
#     n>=6 gets a permutation p + bootstrap CI + a gated verdict word.
#   * Never the word "drives"/"causes". A sign-match tally (binomial test) is the
#     multiple-comparison-honest signal even when no single link is significant.
# ===========================================================================
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

zscore <- function(x) { x <- as.numeric(x); m <- mean(x, na.rm=TRUE); s <- stats::sd(x, na.rm=TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x))); (x - m) / s }

# overlapping (driver[t], response[t+lag]) pairs for one site
lag_pairs <- function(ann_site, from, to, lag = 0L) {
  if (is.null(ann_site) || !all(c(from, to) %in% names(ann_site))) return(data.frame())
  drv <- data.frame(year = ann_site$year,        x = ann_site[[from]])
  rsp <- data.frame(year = ann_site$year - lag,  y = ann_site[[to]])   # response at t+lag keyed to driver year t
  m <- merge(drv, rsp, by = "year")
  m[is.finite(m$x) & is.finite(m$y), , drop = FALSE]
}

# one prior link's statistics, n-gated. prior_sign in {-1,+1}.
link_stat <- function(ann_site, from, to, lag, prior_sign, nperm = 2000) {
  m <- lag_pairs(ann_site, from, to, lag); n <- nrow(m)
  out <- list(from=from, to=to, lag=lag, n=n, r=NA_real_, lo=NA_real_, hi=NA_real_, p=NA_real_,
              prior_sign=prior_sign, sign_match=NA, tier="insufficient",
              verdict=sprintf("only %d overlapping year%s — can't compare", n, if (n==1) "" else "s"))
  if (n < 3) return(out)
  r <- suppressWarnings(stats::cor(m$x, m$y)); if (!is.finite(r)) return(out)
  out$r <- round(r, 2); out$sign_match <- (sign(r) == sign(prior_sign))
  if (n < 6) { out$tier <- "exploratory"
    out$verdict <- sprintf("exploratory only — %d years is too few for a verdict (the eye, not the p-value)", n)
    return(out) }
  # n >= 6: permutation null (shuffle response) + bootstrap CI
  perm <- replicate(nperm, suppressWarnings(stats::cor(m$x, sample(m$y))))
  out$p <- round(mean(abs(perm) >= abs(r) - 1e-9, na.rm = TRUE), 3)
  bs <- replicate(2000, { i <- sample(n, n, replace = TRUE); suppressWarnings(stats::cor(m$x[i], m$y[i])) })
  out$lo <- unname(round(stats::quantile(bs, 0.025, na.rm = TRUE), 2)); out$hi <- unname(round(stats::quantile(bs, 0.975, na.rm = TRUE), 2))
  spans0 <- is.finite(out$lo) && is.finite(out$hi) && out$lo < 0 && out$hi > 0
  out$tier <- if (!is.na(out$p) && out$p < 0.05 && out$sign_match && !spans0) "consistent"
              else if (isTRUE(out$sign_match)) "apparent" else "counter"
  out$verdict <- switch(out$tier,
    consistent = "consistent with the expected direction (clears the permutation null)",
    apparent   = "matches the expected sign, but not distinguishable from noise at this n",
    counter    = "runs counter to the expected direction")
  out
}

# all prior links for a site (data.frame), with stats.
# `biome` = the site's limiting-resource class ("water-limited"/"temperature-limited").
# A prior is `expected` at a site when its expected_class is "all" or matches the biome
# (e.g. temp->green-up is expected in temperature-limited systems, the seasonal-rain
# priors in water-limited ones). Every prior is still COMPUTED where data exists — the
# `expected` flag only governs which links count toward the site's sign-match tally and
# which biome each link pools over. biome=NULL => everything expected (back-compat).
site_links <- function(ann_site, priors, biome = NULL, nperm = 2000) {
  set.seed(1L)   # deterministic permutation/bootstrap so the app shows stable numbers
  ec <- if ("expected_class" %in% names(priors)) priors$expected_class else rep("all", nrow(priors))
  cf <- if ("conf" %in% names(priors)) priors$conf else rep(NA_character_, nrow(priors))
  rows <- lapply(seq_len(nrow(priors)), function(i) {
    s <- link_stat(ann_site, priors$from[i], priors$to[i], priors$lag[i], priors$sign[i], nperm)
    expected <- is.null(biome) || ec[i] == "all" || identical(ec[i], biome)
    data.frame(from=s$from, to=s$to, lag=s$lag, n=s$n, r=s$r, lo=s$lo, hi=s$hi, p=s$p,
               prior_sign=s$prior_sign, sign_match=s$sign_match, tier=s$tier, verdict=s$verdict,
               conf=cf[i], expected_class=ec[i], expected=expected,
               note = priors$note[i], stringsAsFactors = FALSE) })
  do.call(rbind, rows)
}

# pool each prior link ACROSS sites (one vote per site) — the statistically honest
# answer to per-site n=6 underpower. Pools only sites where the link is EXPECTED and
# testable (n>=6). Binomial sign test vs 0.5. Returns one row per (from,to,lag).
pooled_links <- function(suite_links) {
  sl <- suite_links
  exp <- if ("expected" %in% names(sl)) sl$expected %in% TRUE else rep(TRUE, nrow(sl))
  sl <- sl[exp & sl$n >= 6 & !is.na(sl$sign_match), , drop = FALSE]
  if (!nrow(sl)) return(data.frame())
  key <- paste(sl$from, sl$to, sl$lag, sep = "|")
  out <- do.call(rbind, lapply(split(seq_len(nrow(sl)), key), function(ix) {
    d <- sl[ix, , drop = FALSE]; k <- sum(d$sign_match); tot <- nrow(d)
    bt <- stats::binom.test(k, tot, 0.5, alternative = "greater")
    data.frame(from=d$from[1], to=d$to[1], lag=d$lag[1], expected_class=d$expected_class[1],
               sites=tot, k=k, p=round(bt$p.value, 4), median_r=round(stats::median(d$r, na.rm=TRUE), 2),
               stringsAsFactors = FALSE)
  }))
  out[order(out$p, -out$sites), , drop = FALSE]
}

# sign-match tally across TESTABLE links only (n>=6 — the same n-floor the verdicts
# use; folding in n=3-5 exploratory links would contradict the "no verdict below 6
# years" rule the chips enforce). Binomial vs 0.5.
signmatch_score <- function(links) {
  exp <- if ("expected" %in% names(links)) links$expected %in% TRUE else rep(TRUE, nrow(links))
  ok <- links[exp & links$n >= 6 & !is.na(links$sign_match), , drop = FALSE]
  k <- sum(ok$sign_match); tot <- nrow(ok)
  if (tot == 0) return(list(k=0, n=0, p=NA_real_, txt="no links have enough years (n&ge;6) to test here yet"))
  bt <- stats::binom.test(k, tot, 0.5, alternative = "greater")
  list(k = k, n = tot, p = round(bt$p.value, 3),
       txt = sprintf("%d of %d testable links (n&ge;6) match their predicted direction (binomial p = %.3f%s)",
                     k, tot, bt$p.value, if (bt$p.value < 0.05) ", more than chance" else ""))
}

# which trophic layers have any data at a site
layers_present <- function(ann_site, signals) {
  vapply(c("climate","phenology","producer","consumer"), function(L) {
    ks <- signals$key[signals$layer == L]; any(vapply(ks, function(k) any(is.finite(ann_site[[k]])), logical(1)))
  }, logical(1))
}

# tidy z-scored long frame for the ladder (one layer), only signals with >=2 finite years.
# Seasonal climate signals (ladder=FALSE) are kept off the main ladder to avoid clutter —
# they drive the desert priors and the dedicated Seasonal Climate panel instead.
ladder_layer <- function(ann_site, signals, layer) {
  lad <- if ("ladder" %in% names(signals)) signals$ladder %in% TRUE else rep(TRUE, nrow(signals))
  ks <- signals$key[signals$layer == layer & lad]
  out <- lapply(ks, function(k) {
    # need >=3 finite years: a z-score of exactly 2 points is always {-0.71,+0.71}
    # regardless of the values — a meaningless straight line on the ladder.
    v <- ann_site[[k]]; if (sum(is.finite(v)) < 3) return(NULL)
    data.frame(year = ann_site$year, key = k,
               label = signals$label[signals$key == k],
               raw = v, z = zscore(v), stringsAsFactors = FALSE)
  })
  do.call(rbind, Filter(Negate(is.null), out))
}

LAYER_META <- list(
  climate   = list(title = "CLIMATE",   icon = "cloud-rain",      col = "#2f7fb5"),
  phenology = list(title = "GREEN-UP",  icon = "flower2",         col = "#5fae3a"),
  producer  = list(title = "PRODUCERS", icon = "tree",            col = "#1a7f37"),
  consumer  = list(title = "CONSUMERS", icon = "bug",             col = "#AB0520"))
TIER_META <- list(
  consistent  = list(lab = "Consistent with prior", col = "#1a7f37", icon = "check-circle-fill"),
  apparent    = list(lab = "Apparent only",         col = "#c9a300", icon = "dash-circle-fill"),
  counter     = list(lab = "Counter to prior",      col = "#AB0520", icon = "x-circle-fill"),
  exploratory = list(lab = "Exploratory (n<6)",     col = "#6b7a89", icon = "hourglass-split"),
  insufficient= list(lab = "Too few years",         col = "#9aa6b2", icon = "slash-circle"))
