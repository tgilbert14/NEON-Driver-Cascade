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
              verdict=sprintf("only %d overlapping year%s, can't compare", n, if (n==1) "" else "s"))
  if (n < 3) return(out)
  r <- suppressWarnings(stats::cor(m$x, m$y)); if (!is.finite(r)) return(out)
  out$r <- round(r, 2); out$sign_match <- (sign(r) == sign(prior_sign))
  if (n < 6) { out$tier <- "exploratory"
    out$verdict <- sprintf("exploratory only: %d years is too few for a verdict (the eye, not the p-value)", n)
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
# `min_sites` is a HARD floor: a binomial on 1–2 votes is not a pooled test (a single
# vote always reads k=1/1, p=0.500), so links below the floor get `poolable=FALSE` and
# NO p — they must not sit in the headline rank beside a 32-site result.
pooled_links <- function(suite_links, min_sites = 3L) {
  sl <- suite_links
  exp <- if ("expected" %in% names(sl)) sl$expected %in% TRUE else rep(TRUE, nrow(sl))
  sl <- sl[exp & sl$n >= 6 & !is.na(sl$sign_match), , drop = FALSE]
  if (!nrow(sl)) return(data.frame())
  key <- paste(sl$from, sl$to, sl$lag, sep = "|")
  out <- do.call(rbind, lapply(split(seq_len(nrow(sl)), key), function(ix) {
    d <- sl[ix, , drop = FALSE]; k <- sum(d$sign_match); tot <- nrow(d)
    poolable <- tot >= min_sites
    p <- if (poolable) round(stats::binom.test(k, tot, 0.5, alternative = "greater")$p.value, 4) else NA_real_
    data.frame(from=d$from[1], to=d$to[1], lag=d$lag[1], expected_class=d$expected_class[1],
               sites=tot, k=k, p=p, poolable=poolable,
               median_r=round(stats::median(d$r, na.rm=TRUE), 2),
               stringsAsFactors = FALSE)
  }))
  # poolable rows first (ranked by p, then coverage); under-floor rows demoted to the tail
  out[order(!out$poolable, out$p, -out$sites), , drop = FALSE]
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

# ---- Lag Experimenter helpers ----
# mechanism-driven seasonal driver swap (a stated prior, not a free knob)
exp_driver_col <- function(from, season, to = NULL) {
  if (season != "seasonal") return(from)
  if (from == "precip") {
    if (!is.null(to) && to %in% c("mammal_cpue","mammal_mnka","bird_index","fruiting_pct")) return("precip_monsoon")
    return("precip_winter")
  }
  if (from == "temp") return("temp_spring")
  from
}
# r at each candidate lag for the curve (plain cor; n per point)
exp_curve <- function(ann_site, from, to, lags = 0:3) {
  do.call(rbind, lapply(lags, function(L) {
    m <- lag_pairs(ann_site, from, to, L); n <- nrow(m)
    r <- if (n >= 3) suppressWarnings(stats::cor(m$x, m$y)) else NA_real_
    data.frame(lag = L, r = if (is.finite(r)) round(r, 2) else NA_real_, n = n)
  }))
}
# best-of-K, autocorrelation-preserving adjusted p for the SELECTED (driver_col, lag).
# Null = circular-shift the response series (preserves serial structure), RE-SCAN every
# candidate (col,lag) combo, take max|r|; p_adj = P(null best |r| >= observed). Penalizes
# both the lag/season search AND the annual autocorrelation that makes a free-shuffle p
# anti-conservative. combos = list(list(col=, lag=), ...).
exp_adj_p <- function(ann_site, to, combos, observed_r, nperm = 2000) {
  y <- ann_site[[to]]; ny <- length(y)
  if (ny < 4 || !is.finite(observed_r)) return(NA_real_)
  scan_max <- function(a) {
    rs <- vapply(combos, function(cb) {
      m <- lag_pairs(a, cb$col, to, cb$lag)
      if (nrow(m) >= 3) { r <- suppressWarnings(stats::cor(m$x, m$y)); if (is.finite(r)) abs(r) else NA_real_ } else NA_real_
    }, numeric(1))
    if (all(is.na(rs))) NA_real_ else max(rs, na.rm = TRUE)
  }
  set.seed(7L)
  perm_max <- replicate(nperm, {
    k <- sample.int(ny - 1L, 1L)
    a2 <- ann_site; a2[[to]] <- y[((seq_len(ny) - 1L + k) %% ny) + 1L]
    scan_max(a2)
  })
  round(mean(perm_max >= abs(observed_r) - 1e-9, na.rm = TRUE), 3)
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

# Desert-night cascade layer hues (match the suite cover): clim sky, phen lime,
# prod green, cons coral.
LAYER_META <- list(
  climate   = list(title = "CLIMATE",   icon = "cloud-rain",      col = "#43b8e8"),
  phenology = list(title = "GREEN-UP",  icon = "flower2",         col = "#9bd24a"),
  producer  = list(title = "PRODUCERS", icon = "tree",            col = "#5fb56a"),
  consumer  = list(title = "CONSUMERS", icon = "bug",             col = "#fb8a7e"))
# Verdict tiers, harmonised to the teal/coral/gold system (semantics preserved):
# consistent = teal (the brand win), apparent = gold, counter = coral, the rest dim.
TIER_META <- list(
  consistent  = list(lab = "Consistent with prior", col = "#2dd4bf", icon = "check-circle-fill"),
  apparent    = list(lab = "Apparent only",         col = "#e0b43a", icon = "dash-circle-fill"),
  counter     = list(lab = "Counter to prior",      col = "#fb8a7e", icon = "x-circle-fill"),
  exploratory = list(lab = "Exploratory (n<6)",     col = "#9fb0cf", icon = "hourglass-split"),
  insufficient= list(lab = "Too few years",         col = "#6b7a89", icon = "slash-circle"))

# ===========================================================================
# QC-flag panel (the suite gold standard, §7) — ranked "VERIFY, not wrong"
# data-quality flags for ONE site's cascade slice. Returns list(flags, sets):
#   flags = ranked list (high > warn > info) each with key/level/title/n/detail,
#   sets  = the EXACT offending rows behind each flag (key -> data.frame), so the
#           UI can expand a chip to the records that earned it.
# Every flag is a thing to LOOK AT, never a thing that's "broken" — the cascade's
# QC choices (the >=5-individual green-up gate, the within-site MAD temp NA, the
# CI-spans-zero "apparent" guard) are CORRECT; this panel surfaces where they bit.
# Computed entirely from the bundle (annual rows + cached links) — no recompute.
cascade_qc <- function(ann_site, links_site, signals = NULL, site = NULL) {
  flags <- list(); sets <- list()
  add <- function(key, level, title, detail, set = NULL) {
    n <- if (is.null(set)) 0L else nrow(set)
    flags[[length(flags) + 1L]] <<- list(key = key, level = level, title = title,
                                         detail = detail, n = n)
    if (!is.null(set) && nrow(set)) sets[[key]] <<- set
  }
  a <- if (is.null(ann_site)) data.frame() else ann_site
  lk <- if (is.null(links_site)) data.frame() else links_site

  # (1) WARN — climate years MAD-flagged / NA'd. The within-site MAD outlier filter
  # NAs an implausible annual temp (corrupted-sensor years); we can't see WHICH years
  # it caught from the bundle, but we CAN flag the years where the cascade has biology
  # present but its climate driver is missing — the gaps that thin every link's n.
  if (nrow(a) && "temp" %in% names(a)) {
    bio_keys <- intersect(c("greenup_doy","plant_richness","mammal_cpue","bird_index"), names(a))
    has_bio  <- if (length(bio_keys)) rowSums(!is.na(a[, bio_keys, drop = FALSE])) > 0 else rep(FALSE, nrow(a))
    gap <- a[has_bio & is.na(a$temp), , drop = FALSE]
    if (nrow(gap)) {
      show <- intersect(c("year","temp","precip","greenup_doy","plant_richness","mammal_cpue","bird_index"), names(gap))
      add("climate_na", "warn", "Climate missing where biology is present",
          paste0("Annual temperature is NA in ", nrow(gap), " year",
                 if (nrow(gap) == 1) "" else "s",
                 " that DO have a biological signal, either too few valid months, or a year the within-site MAD outlier filter dropped as a corrupted-sensor read. The biology is real; the driver for those years isn't, so they can't enter a link. Verify the tower record before reading the gap as 'no climate effect'."),
          gap[, show, drop = FALSE])
    }
  }

  # (2) INFO — green-up onsets resting on a thin individual base. The builder already
  # gates green-up to years with >=5 tagged individuals, so nothing UNDER the floor
  # ships; the honest flag is a SPARSE phenology record (few green-up years total),
  # where each onset leans on a small panel and a single mis-scored plant moves it.
  if (nrow(a) && "greenup_doy" %in% names(a)) {
    gu <- a[is.finite(a$greenup_doy), , drop = FALSE]
    if (nrow(gu) && nrow(gu) < 6) {
      show <- intersect(c("year","greenup_doy"), names(gu))
      add("greenup_thin", "info", "Green-up rests on a short phenology record",
          paste0("Only ", nrow(gu), " year", if (nrow(gu) == 1) "" else "s",
                 " of green-up here (each already gated to >=5 individuals, so none rests on fewer). A short onset record is more swayed by a single late- or early-scored plant, so read the timing, not a precise day-of-year. Tap to see the years."),
          gu[, show, drop = FALSE])
    }
  }

  # (3) HIGH — "apparent" links whose bootstrap CI spans zero. These point the way the
  # prior predicts but the 95% interval crosses 0, so the sign isn't yet distinguishable
  # from noise — the most over-readable cell in the app. Surface them so a reader doesn't
  # promote an "apparent" to a result.
  if (nrow(lk) && all(c("tier","lo","hi") %in% names(lk))) {
    ap <- lk[lk$tier %in% "apparent" & is.finite(lk$lo) & is.finite(lk$hi) & lk$lo < 0 & lk$hi > 0, , drop = FALSE]
    if (nrow(ap)) {
      lab <- function(k) if (!is.null(signals) && k %in% signals$key) signals$label[signals$key == k][1] else k
      ap$link <- vapply(seq_len(nrow(ap)), function(i) sprintf("%s -> %s", lab(ap$from[i]), lab(ap$to[i])), character(1))
      show <- intersect(c("link","lag","n","r","lo","hi","p"), names(ap))
      add("apparent_ci0", "high", "“Apparent” links whose CI spans zero",
          paste0(nrow(ap), " link", if (nrow(ap) == 1) "" else "s",
                 " point the predicted direction but the 95% bootstrap interval still crosses 0; the sign is not yet distinguishable from noise at this site's n. Read as suggestive only; the honest test is the cross-site pooling on the Across NEON tab. Tap to see each link's r and interval."),
          ap[, show, drop = FALSE])
    }
  }

  # rank high > warn > info (the gold-standard order); clean path = a green reassurance
  if (!length(flags)) {
    return(list(flags = list(list(key = "clean", level = "clean",
      title = "No data-quality flags at this site",
      detail = "Climate coverage, green-up support, and every link's interval all read clean here, with nothing flagged to verify.", n = 0L)),
      sets = list()))
  }
  ord <- order(match(vapply(flags, `[[`, character(1), "level"), c("high","warn","info","clean")))
  list(flags = flags[ord], sets = sets)
}

# flat one-row-per-flag QC report for CSV export (the <entity>_qc_report() analog)
cascade_qc_report <- function(ann_site, links_site, signals = NULL, site = NULL) {
  q <- cascade_qc(ann_site, links_site, signals, site)
  do.call(rbind, lapply(q$flags, function(f) data.frame(
    site = site %||% NA_character_, level = f$level, flag = f$title,
    n_rows = f$n, detail = f$detail, stringsAsFactors = FALSE)))
}
