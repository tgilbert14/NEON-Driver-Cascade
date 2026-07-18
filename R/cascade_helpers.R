# ===========================================================================
# NEON Driver Cascade — cascade_helpers.R
# Cross-product direct-association screening on SHORT annual series (n≈3–13/site).
# The discipline (grounded in literature + short-series statistical review):
#   * REGISTER fixed direction/lag contrasts; most rows remain context-only.
#   * n-GATE everything: n<3 can't compare; 3–5 exploratory (no p, no verdict);
#     n>=6 gets a permutation p + bootstrap CI + a gated verdict word.
#   * Never the word "drives"/"causes". Within-site sign matching is descriptive;
#     cross-site raw-level direction screens use site votes under an explicit independence model.
# ===========================================================================
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# Tier-rule version. BUMP this whenever link_stat()'s tier definition changes. The build
# stamps it into the bundle's meta, and the app refuses to boot on a bundle whose tier_rule
# does not match (the 2026-06 stale-tiered-bundle guard: a code change to the null/tier must
# rebuild the bundle, it can never silently ride on a stale precompute). One source of truth.
TIER_RULE_VERSION <- "2026-07-calendar-gap-aware-circular-block-v5"

# Search is a derived view of cascade.rds.  Its schema version and source-bundle
# checksum are checked at app boot so an old index can never silently report a
# different set of priors or statistics than the rest of the app.
CASCADE_BUNDLE_SCHEMA_VERSION <- "2026-07-source-contract-support-v6"
SEARCH_INDEX_SCHEMA_VERSION <- "2026-07-calendar-gap-aware-search-v4"
CASCADE_META_SCHEMA_VERSION <- "2026-07-knha-holm-prediction-v3"

# R on Windows can start in the C locale even when UTF-8 was requested. In that
# state, valid UTF-8 bytes produced by source literals can be serialized with an
# "unknown" encoding mark; a later enc2utf8()/htmltools pass then treats those
# bytes as native text and can turn arrows/dashes into C0 controls. Normalize at
# the artifact boundary and make the mark itself part of the persisted contract.
cascade_normalize_artifact_text <- function(x) {
  normalize_character <- function(value) {
    present <- which(!is.na(value))
    if (!length(present)) return(value)
    valid <- vapply(value[present], validUTF8, logical(1))
    if (any(!valid))
      stop("artifact text contains invalid UTF-8 bytes", call. = FALSE)
    for (i in present) {
      points <- utf8ToInt(value[[i]])
      if (any(points == 0xFFFD))
        stop("artifact text contains a Unicode replacement character", call. = FALSE)
      if (any(points > 127L)) Encoding(value[[i]]) <- "UTF-8"
    }
    value
  }
  if (is.factor(x)) {
    normalized <- normalize_character(levels(x))
    if (!identical(normalized, levels(x))) levels(x) <- normalized
  } else if (is.character(x)) {
    x <- normalize_character(x)
  } else if (is.list(x)) {
    for (i in seq_along(x)) x[[i]] <- cascade_normalize_artifact_text(x[[i]])
  }
  nms <- names(x)
  if (!is.null(nms)) {
    normalized <- normalize_character(nms)
    if (!identical(normalized, nms)) names(x) <- normalized
  }
  dims <- dimnames(x)
  if (!is.null(dims)) {
    normalized <- lapply(dims, normalize_character)
    if (!identical(normalized, dims)) dimnames(x) <- normalized
  }
  custom <- setdiff(names(attributes(x)),
                    c("names", "dimnames", "levels", "class", "row.names", "dim"))
  for (name in custom) {
    current <- attr(x, name)
    normalized <- cascade_normalize_artifact_text(current)
    if (!identical(normalized, current)) attr(x, name) <- normalized
  }
  x
}

cascade_artifact_text_issues <- function(x, path = "artifact") {
  issues <- character(0)
  inspect_character <- function(value, value_path) {
    for (i in seq_along(value)) {
      if (is.na(value[[i]])) next
      item_path <- sprintf("%s[%d]", value_path, i)
      if (!validUTF8(value[[i]])) {
        issues <<- c(issues, sprintf("%s has invalid UTF-8 bytes", item_path))
        next
      }
      points <- utf8ToInt(value[[i]])
      controls <- points[points %in% c(0:31, 127:159)]
      if (length(controls))
        issues <<- c(issues, sprintf("%s contains control code point(s): %s",
                                     item_path, paste(unique(controls), collapse = ",")))
      if (any(points == 0xFFFD))
        issues <<- c(issues, sprintf("%s contains a Unicode replacement character", item_path))
      if (any(points > 127L) && !identical(Encoding(value[[i]]), "UTF-8"))
        issues <<- c(issues, sprintf("%s has unmarked non-ASCII UTF-8", item_path))
      if (any(points > 127L) &&
          !identical(charToRaw(enc2utf8(value[[i]])), charToRaw(value[[i]])))
        issues <<- c(issues, sprintf("%s changes during UTF-8 serialization", item_path))
    }
  }
  walk <- function(value, value_path) {
    nms <- names(value)
    if (!is.null(nms)) inspect_character(nms, paste0(value_path, "$names"))
    dims <- dimnames(value)
    if (!is.null(dims))
      for (i in seq_along(dims))
        inspect_character(dims[[i]], sprintf("%s$dimnames[[%d]]", value_path, i))
    if (is.factor(value)) {
      inspect_character(levels(value), paste0(value_path, "$levels"))
    } else if (is.character(value)) {
      inspect_character(value, value_path)
    } else if (is.list(value)) {
      for (i in seq_along(value)) {
        child <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else as.character(i)
        walk(value[[i]], paste0(value_path, "[[", child, "]]"))
      }
    }
    custom <- setdiff(names(attributes(value)),
                      c("names", "dimnames", "levels", "class", "row.names", "dim"))
    for (name in custom) walk(attr(value, name), paste0(value_path, "$attr[[", name, "]]"))
  }
  walk(x, path)
  unique(issues)
}
cascade_assert_artifact_text <- function(x, label = "artifact") {
  issues <- cascade_artifact_text_issues(x, label)
  if (length(issues))
    stop(sprintf("%s failed its UTF-8 text contract: %s",
                 label, paste(utils::head(issues, 8L), collapse = "; ")), call. = FALSE)
  invisible(TRUE)
}

cascade_activate_utf8_ctype <- function() {
  current <- Sys.getlocale("LC_CTYPE")
  if (!is.na(current) && grepl("UTF-?8", current, ignore.case = TRUE)) return(current)
  for (candidate in c(".UTF-8", "C.UTF-8", "en_US.UTF-8")) {
    selected <- suppressWarnings(Sys.setlocale("LC_CTYPE", candidate))
    if (!is.na(selected) && nzchar(selected) &&
        grepl("UTF-?8", selected, ignore.case = TRUE)) return(selected)
  }
  stop("a UTF-8 LC_CTYPE locale is required for lossless text serialization", call. = FALSE)
}

cascade_with_utf8_ctype <- function(fun) {
  stopifnot(is.function(fun))
  original <- Sys.getlocale("LC_CTYPE")
  on.exit(suppressWarnings(Sys.setlocale("LC_CTYPE", original)), add = TRUE)
  cascade_activate_utf8_ctype()
  fun()
}

# The direction/lag family is literature-motivated, but repository history
# shows that it evolved while these same data were being inspected. Stamp that
# status into every bundle so no interface can imply preregistration. This lock
# versions the current exploratory screen; it does not retroactively make the
# historical data a confirmatory holdout.
PRIOR_FAMILY_VERSION <- "2026-07-literature-motivated-exploratory-v2"
PRIOR_FAMILY_STATUS <- paste(
  "exploratory: directions and lags are literature-motivated and locked for this build,",
  "but the family evolved alongside inspection of the analyzed data; not preregistered or confirmatory")

# Both green-up estimators are retrospective full-snapshot standardizations.
# Recurrence, graph connectivity, species references, and additive year effects
# are re-estimated when the source snapshot changes, so a refresh may legitimately
# revise an earlier year's value. Source commits + bundle hash identify the exact fit.
GREENUP_INDEX_VERSION <- "2026-07-retrospective-connected-panel-v1"
GREENUP_INDEX_NOTE <- paste(
  "retrospective full-snapshot standardization: species recurrence, incidence",
  "connectivity, primary species references, and additive species/year effects",
  "are refit over the current source snapshot; future refreshes can revise historical",
  "index values; source commits and the bundle fingerprint preserve exact lineage")

# Trend sensitivity is descriptive lineage, not a second route to a favorable
# p-value. Every eligible raw site vote carries two alternate direction checks:
# linear-year residuals and consecutive-calendar-year changes. Pooled artifacts
# retain only exact k/n counts for those checks (no additional significance test).
TREND_SENSITIVITY_VERSION <- "2026-07-linear-residual-consecutive-change-v1"
TREND_SENSITIVITY_NOTE <- paste(
  "descriptive sensitivity on the same vote-eligible raw sites (n>=6):",
  "detrended correlations use linear-year residuals; change correlations use only",
  "adjacent complete calendar-year differences (at least 3 changes); undefined effects and ties abstain")

# Estimator sensitivity replaces only the green-up response construction. The
# driver, lag, site, raw eligibility rule, and prior direction stay fixed. It is
# descriptive lineage and deliberately carries no additional p-value.
ESTIMATOR_SENSITIVITY_VERSION <- "2026-07-greenup-additive-species-year-v1"
ESTIMATOR_SENSITIVITY_NOTE <- paste(
  "descriptive green-up outcome sensitivity on the same vote-eligible raw sites:",
  "greenup_doy_additive uses the eligible species-year cells and annual gates of",
  "greenup_doy, fit as an unweighted species plus year additive model; undefined",
  "alternate effects and ties abstain; no additional p-value is calculated")

# Spatial-dependence sensitivity collapses the identical raw site-vote
# population to one majority vote per NEON domain. A 50/50 domain abstains. This
# is deliberately descriptive: it diagnoses site pseudoreplication without
# pretending that nine domains support a second well-powered hypothesis test.
SPATIAL_SENSITIVITY_VERSION <- "2026-07-neon-domain-majority-v1"
SPATIAL_SENSITIVITY_NOTE <- paste(
  "descriptive spatial-dependence sensitivity on the same vote-eligible n>=6 non-tie",
  "raw site votes: each NEON domain casts one majority vote; 50/50 domains",
  "abstain and are reported separately; no additional p-value is calculated")

zscore <- function(x) { x <- as.numeric(x); m <- mean(x, na.rm=TRUE); s <- stats::sd(x, na.rm=TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x))); (x - m) / s }

# Stable per-link seed: reproducible builds without reusing the identical
# bootstrap index stream for every site of the same span.
stable_link_seed <- function(...) {
  key <- paste(..., collapse = "|")
  ints <- utf8ToInt(enc2utf8(key))
  if (!length(ints)) return(1L)
  hash <- 0
  for (x in ints) hash <- (hash * 131 + x + 1) %% 2147483646
  as.integer(hash + 1)
}

# Run one deterministic Monte Carlo stream without leaking either RNGkind or
# .Random.seed into the caller. Fixing all three RNG kinds makes a rebuild
# independent of an interactive session's RNG settings; restoring/removing the
# seed exactly makes helper calls referentially transparent to downstream code.
with_preserved_rng <- function(seed, fun) {
  stopifnot(is.function(fun), length(seed) == 1L, is.finite(seed))
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  set.seed(as.integer(seed))
  fun()
}

# Full, contiguous calendar grid for (driver[t], response[t+lag]). Missing
# calendar years remain explicit NAs; they must not be compressed into adjacent
# observations before a time-series randomization or block bootstrap.
lag_grid <- function(ann_site, from, to, lag = 0L) {
  if (is.null(ann_site) || !all(c(from, to) %in% names(ann_site))) return(data.frame())
  collapse_year <- function(year, value, name) {
    year <- suppressWarnings(as.integer(year)); value <- suppressWarnings(as.numeric(value))
    keep <- is.finite(year); year <- year[keep]; value <- value[keep]
    if (!length(year)) return(data.frame(year = integer(0), value = numeric(0)))
    if (anyDuplicated(year))
      warning(sprintf("lag_grid(): duplicate %s years detected; collapsing by year mean.", name), call. = FALSE)
    yrs <- sort(unique(year))
    vals <- vapply(yrs, function(y) {
      v <- value[year == y]
      if (all(!is.finite(v))) NA_real_ else mean(v[is.finite(v)])
    }, numeric(1))
    data.frame(year = yrs, value = vals)
  }
  drv <- collapse_year(ann_site$year, ann_site[[from]], "driver")
  rsp <- collapse_year(ann_site$year - lag, ann_site[[to]], "response")
  if (!nrow(drv) || !nrow(rsp)) return(data.frame())
  # Bound the grid by each signal's finite support envelope, not by the site's
  # union record. Structural years before a product began or after it ended are
  # not time-series gaps and must not be rotated into the null or bootstrap.
  # Genuine missing years *inside* the overlapping envelopes remain explicit.
  drv_support <- drv$year[is.finite(drv$value)]
  rsp_support <- rsp$year[is.finite(rsp$value)]
  if (!length(drv_support) || !length(rsp_support)) return(data.frame())
  lo <- max(min(drv_support), min(rsp_support)); hi <- min(max(drv_support), max(rsp_support))
  if (!is.finite(lo) || !is.finite(hi) || lo > hi) return(data.frame())
  grid <- data.frame(year = seq.int(lo, hi))
  names(drv)[2] <- "x"; names(rsp)[2] <- "y"
  grid <- merge(grid, drv, by = "year", all.x = TRUE, sort = TRUE)
  merge(grid, rsp, by = "year", all.x = TRUE, sort = TRUE)
}

# Observed overlapping pairs for displays and effect estimates.
lag_pairs <- function(ann_site, from, to, lag = 0L) {
  g <- lag_grid(ann_site, from, to, lag)
  if (!nrow(g)) return(g)
  g[is.finite(g$x) & is.finite(g$y), , drop = FALSE]
}

# A direction vote shared by raw, detrended, and change sensitivities. Values
# at floating-point zero are abstentions, matching the exact sign-test tie rule.
direction_match <- function(r, prior_sign) {
  if (length(r) != 1L || !is.finite(r) || abs(r) <= sqrt(.Machine$double.eps)) return(NA)
  sign(r) == sign(prior_sign)
}

# Correlation that rejects numerically constant inputs. This matters after
# detrending: a perfectly linear series has residuals near 1e-15, and base cor()
# can otherwise manufacture a direction from floating-point dust.
stable_cor <- function(x, y) {
  keep <- is.finite(x) & is.finite(y); x <- x[keep]; y <- y[keep]
  if (length(x) < 3L) return(NA_real_)
  varies <- function(z) {
    s <- stats::sd(z); scale <- max(1, max(abs(z)))
    is.finite(s) && s > sqrt(.Machine$double.eps) * scale
  }
  if (!varies(x) || !varies(y)) return(NA_real_)
  r <- suppressWarnings(stats::cor(x, y))
  if (is.finite(r)) r else NA_real_
}

# Trend-robustness diagnostics for an already raw-eligible link. Detrending is
# a two-series linear year adjustment on the identical complete pairs. Change
# sensitivity uses only truly adjacent complete years on the full calendar grid;
# it never compresses a missing year into a one-year difference.
link_trend_sensitivity <- function(g, prior_sign, raw_eligible = TRUE) {
  out <- list(n_detrended = 0L, r_detrended = NA_real_, sign_match_detrended = NA,
              n_change = 0L, r_change = NA_real_, sign_match_change = NA)
  if (!isTRUE(raw_eligible) || is.null(g) || !nrow(g)) return(out)
  m <- g[is.finite(g$x) & is.finite(g$y), , drop = FALSE]
  if (nrow(m) < 6L) return(out)

  out$n_detrended <- as.integer(nrow(m))
  rx <- stats::residuals(stats::lm(x ~ year, data = m))
  ry <- stats::residuals(stats::lm(y ~ year, data = m))
  out$r_detrended <- stable_cor(rx, ry)
  out$sign_match_detrended <- direction_match(out$r_detrended, prior_sign)

  consecutive <- if (nrow(g) >= 2L) {
    g$year[-1L] == g$year[-nrow(g)] + 1L &
      is.finite(g$x[-1L]) & is.finite(g$x[-nrow(g)]) &
      is.finite(g$y[-1L]) & is.finite(g$y[-nrow(g)])
  } else logical(0)
  out$n_change <- as.integer(sum(consecutive))
  if (out$n_change >= 3L) {
    out$r_change <- stable_cor(diff(g$x)[consecutive], diff(g$y)[consecutive])
    out$sign_match_change <- direction_match(out$r_change, prior_sign)
  }
  out
}

# Alternate-outcome effect for the two green-up links. Compute it wherever the
# paired series can be described; downstream pooling still restricts the count
# to the same vote-eligible n>=6 non-tied raw-vote population as the primary result.
link_outcome_sensitivity <- function(ann_site, from, lag, prior_sign,
                                     to_alt = "greenup_doy_additive") {
  out <- list(n_outcome_alt = 0L, r_outcome_alt = NA_real_,
              sign_match_outcome_alt = NA)
  if (is.null(ann_site) || !to_alt %in% names(ann_site)) return(out)
  g <- lag_grid(ann_site, from, to_alt, lag)
  m <- if (nrow(g)) g[is.finite(g$x) & is.finite(g$y), , drop = FALSE] else g
  out$n_outcome_alt <- as.integer(nrow(m))
  if (nrow(m) < 3L) return(out)
  r <- suppressWarnings(stats::cor(m$x, m$y))
  out$r_outcome_alt <- if (is.finite(r)) r else NA_real_
  out$sign_match_outcome_alt <- direction_match(out$r_outcome_alt, prior_sign)
  out
}

# Collapse site-level logical direction votes to one majority vote per NEON
# domain. `domains` counts non-tied domain votes; `domain_ties` preserves how
# many represented domains abstained, so domains + domain_ties is auditable.
domain_majority_counts <- function(d, domain_col = "domain", vote_col = "sign_match") {
  empty <- list(domains = 0L, k_domain = 0L, domain_ties = 0L)
  if (is.null(d) || !nrow(d) ||
      !all(c(domain_col, vote_col) %in% names(d))) return(empty)
  domain <- as.character(d[[domain_col]]); vote <- d[[vote_col]]
  keep <- !is.na(vote) & !is.na(domain) & nzchar(domain)
  if (!any(keep)) return(empty)
  by_domain <- split(as.logical(vote[keep]), domain[keep], drop = TRUE)
  margin <- vapply(by_domain, function(v) sum(v) - sum(!v), integer(1))
  list(domains = as.integer(sum(margin != 0L)),
       k_domain = as.integer(sum(margin > 0L)),
       domain_ties = as.integer(sum(margin == 0L)))
}


# Calendar-gap-aware circular null: shift the full response grid, including its
# NAs, rather than compressing observed pairs. This preserves response order,
# annual spacing, and the missing-year pattern. The valid-null count determines
# the exact finite-randomization floor and is persisted with each link.
perm_circular_result <- function(x, y, nperm = 2000) {
  span <- length(y)
  empty <- list(p = NA_real_, p_floor = NA_real_, n_null = 0L, series_span = span)
  if (length(x) != span || span < 3L) return(empty)
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 3L) return(empty)
  obs <- suppressWarnings(stats::cor(x[ok], y[ok]))
  if (!is.finite(obs)) return(empty)
  shifts <- seq_len(span - 1L)
  pick <- if (length(shifts) <= nperm) shifts else sample(shifts, nperm, replace = FALSE)
  null <- vapply(pick, function(k) {
    yk <- y[((seq_len(span) - 1L + k) %% span) + 1L]
    keep <- is.finite(x) & is.finite(yk)
    if (sum(keep) < 3L) return(NA_real_)
    suppressWarnings(stats::cor(x[keep], yk[keep]))
  }, numeric(1))
  n_null <- sum(is.finite(null))
  if (!n_null) return(empty)
  b <- sum(abs(null) >= abs(obs) - 1e-9, na.rm = TRUE)
  list(p = (b + 1) / (n_null + 1), p_floor = 1 / (n_null + 1),
       n_null = as.integer(n_null), series_span = as.integer(span))
}

perm_p_circular <- function(x, y, nperm = 2000) {
  perm_circular_result(x, y, nperm)$p
}

# A shared, testable definition for every place that says an interval "excludes
# zero". Endpoints touching zero include it; classification always uses the
# unrounded interval and rounds only for display.
ci_excludes_zero <- function(lo, hi) {
  length(lo) == 1L && length(hi) == 1L && is.finite(lo) && is.finite(hi) &&
    (lo > 0 || hi < 0)
}

# Circular moving-block bootstrap for paired annual series. Sampling contiguous
# wrapped blocks keeps short-range temporal dependence that an IID year-pair
# bootstrap destroys. The interval remains an indicative small-n diagnostic,
# but its resampling model now matches the time-series caution used by the null.
circular_block_boot_cor <- function(x, y, reps = 2000L, block_length = NULL) {
  n <- length(x)
  if (n != length(y) || n < 3L) return(rep(NA_real_, reps))
  if (is.null(block_length)) block_length <- max(2L, floor(sqrt(n)))
  block_length <- max(1L, min(as.integer(block_length), n))
  n_blocks <- ceiling(n / block_length)
  replicate(reps, {
    starts <- sample.int(n, n_blocks, replace = TRUE)
    idx <- unlist(lapply(starts, function(s) {
      ((s - 1L + seq_len(block_length) - 1L) %% n) + 1L
    }), use.names = FALSE)[seq_len(n)]
    keep <- is.finite(x[idx]) & is.finite(y[idx])
    if (sum(keep) < 3L) NA_real_ else suppressWarnings(stats::cor(x[idx][keep], y[idx][keep]))
  })
}

# one prior link's statistics, n-gated. prior_sign in {-1,+1}.
link_stat <- function(ann_site, from, to, lag, prior_sign, nperm = 2000) {
  g <- lag_grid(ann_site, from, to, lag)
  m <- if (nrow(g)) g[is.finite(g$x) & is.finite(g$y), , drop = FALSE] else g
  n <- nrow(m)
  out <- list(from=from, to=to, lag=lag, n=n, r=NA_real_, lo=NA_real_, hi=NA_real_, p=NA_real_,
              p_floor=NA_real_, n_null=0L, series_span=if (nrow(g)) nrow(g) else 0L,
              n_detrended=0L, r_detrended=NA_real_, sign_match_detrended=NA,
              n_change=0L, r_change=NA_real_, sign_match_change=NA,
              prior_sign=prior_sign, sign_match=NA, ci_excludes_zero=NA, tier="insufficient",
              verdict=sprintf("only %d overlapping year%s, can't compare", n, if (n==1) "" else "s"))
  if (n < 3) return(out)
  r <- suppressWarnings(stats::cor(m$x, m$y))
  if (!is.finite(r)) {
    if (n < 6L) {
      out$tier <- "exploratory"
      out$verdict <- sprintf("exploratory only: %d years is too few for a verdict, and at least one series has no variation", n)
    } else {
      out$tier <- "neutral"
      out$verdict <- "no usable direction: the correlation is undefined because at least one series has no variation"
    }
    return(out)
  }
  # Persist inferential quantities at full precision. Presentation layers round
  # them; the pooled median, meta-analysis, sorting, and exports must not consume
  # display-rounded effects.
  out$r <- r
  # A zero (or floating-point-zero) effect has no direction and must not be
  # counted as a counter-vote in the cross-site direction screen. Exact sign tallies omit
  # ties; they do not silently assign them to the opposite hypothesis.
  out$sign_match <- direction_match(r, prior_sign)
  if (n < 6) { out$tier <- "exploratory"
    out$verdict <- sprintf("exploratory only: %d years is too few for a verdict (the eye, not the p-value)", n)
    return(out) }
  sensitivity <- link_trend_sensitivity(g, prior_sign, raw_eligible = !is.na(out$sign_match))
  for (key in names(sensitivity)) out[[key]] <- sensitivity[[key]]
  # n >= 6: circular moving-block bootstrap CI for the EFFECT, plus a gap-aware
  # circular-shift p that is REPORTED but NOT used to gate the tier. Its finite
  # resolution is 1/(valid null shifts + 1), persisted as p_floor; current short
  # spans make that diagnostic coarse. So the per-site TIER is a DIRECTION verdict (does the sign match,
  # and does the block-bootstrap interval exclude zero), NEVER a significance claim; the cross-site
  # direction screen is reported raw and multiplicity-adjusted by pooled_links(). The tier key "consistent" is kept stable (the CSS
  # and lookups depend on it) but it now means ALIGNED: sign matches AND the interval excludes
  # zero. (Cass ruling, 2026-06; see TIER_RULE_VERSION.)
  perm <- perm_circular_result(g$x, g$y, nperm = nperm)
  out$p <- perm$p; out$p_floor <- perm$p_floor; out$n_null <- perm$n_null
  out$series_span <- perm$series_span
  bs <- circular_block_boot_cor(g$x, g$y, reps = 2000L)
  ci <- if (any(is.finite(bs))) unname(stats::quantile(bs, c(0.025, 0.975), na.rm = TRUE)) else c(NA_real_, NA_real_)
  out$lo <- ci[1]; out$hi <- ci[2]
  # Classify on the unrounded interval.  An endpoint exactly at zero still
  # includes zero; rounding first (and using strict inequalities) could promote
  # a boundary-touching interval to a falsely "clean" direction.
  ci_excl0 <- ci_excludes_zero(ci[1], ci[2])
  out$ci_excludes_zero <- ci_excl0
  out$tier <- if (is.na(out$sign_match)) "neutral"
              else if (isTRUE(out$sign_match) && ci_excl0) "consistent"
              else if (isTRUE(out$sign_match)) "apparent" else "counter"
  out$verdict <- switch(out$tier,
    consistent = "points the stated direction and the block-bootstrap interval excludes zero (a clean per-site direction, NOT a significance claim; cross-site evidence is summarized by the exploratory direction screen)",
    apparent   = "matches the stated direction, but the block-bootstrap interval still crosses zero at this n",
    neutral    = "the estimated correlation is effectively zero, so this site casts no direction vote",
    counter    = "runs counter to the stated direction")
  out
}

# all prior links for a site (data.frame), with stats.
# `biome` is optional grouping context. An "all" prior is vote-eligible everywhere;
# an explicit "none" prior is context-only everywhere; any other expected_class must
# match `biome`. Every prior is still COMPUTED where data exist — `expected` only
# governs direction tallies and pooling. With biome=NULL, legacy non-"none" classes
# remain eligible, but an explicit context-only row can never become a vote.
site_links <- function(ann_site, priors, biome = NULL, nperm = 2000) {
  site_key <- if ("site" %in% names(ann_site)) {
    x <- unique(as.character(ann_site$site[!is.na(ann_site$site)])); if (length(x)) x[1] else "<unknown-site>"
  } else "<unknown-site>"
  ec <- if ("expected_class" %in% names(priors)) priors$expected_class else rep("all", nrow(priors))
  cf <- if ("conf" %in% names(priors)) priors$conf else rep(NA_character_, nrow(priors))
  rows <- lapply(seq_len(nrow(priors)), function(i) {
    seed <- stable_link_seed(site_key, priors$from[i], priors$to[i], priors$lag[i], TIER_RULE_VERSION)
    s <- with_preserved_rng(seed, function()
      link_stat(ann_site, priors$from[i], priors$to[i], priors$lag[i], priors$sign[i], nperm))
    alt <- if (identical(as.character(priors$to[i]), "greenup_doy"))
      link_outcome_sensitivity(ann_site, priors$from[i], priors$lag[i], priors$sign[i])
    else list(n_outcome_alt = 0L, r_outcome_alt = NA_real_, sign_match_outcome_alt = NA)
    expected <- ec[i] != "none" &&
      (is.null(biome) || ec[i] == "all" || identical(ec[i], biome))
    data.frame(from=s$from, to=s$to, lag=s$lag, n=s$n, r=s$r, lo=s$lo, hi=s$hi, p=s$p,
               p_floor=s$p_floor, n_null=s$n_null, series_span=s$series_span,
               n_detrended=s$n_detrended, r_detrended=s$r_detrended,
               sign_match_detrended=s$sign_match_detrended,
               n_change=s$n_change, r_change=s$r_change,
               sign_match_change=s$sign_match_change,
               n_outcome_alt=alt$n_outcome_alt, r_outcome_alt=alt$r_outcome_alt,
               sign_match_outcome_alt=alt$sign_match_outcome_alt,
               prior_sign=s$prior_sign, sign_match=s$sign_match, ci_excludes_zero=s$ci_excludes_zero,
               tier=s$tier, verdict=s$verdict,
               conf=cf[i], expected_class=ec[i], expected=expected,
               note = priors$note[i], stringsAsFactors = FALSE) })
  do.call(rbind, rows)
}

# Summarize each registered contrast ACROSS sites (one vote per site). Only rows
# marked vote-eligible enter this exploratory cross-site direction family, and only when
# estimable at n>=6. Reports an exploratory exact-binomial reference against 0.5.
# Returns one row per (from,to,lag); this is a direction screen, not a network test.
# `min_sites` is a HARD floor: a binomial reference on 1–2 votes is not useful (a single
# vote always reads k=1/1, p=0.500), so links below the floor get `poolable=FALSE` and
# NO p — they must not sit in the headline rank beside a 32-site result.
pooled_links <- function(suite_links, min_sites = 3L) {
  catalog_cols <- intersect(c("from", "to", "lag", "expected_class"), names(suite_links))
  catalog <- unique(suite_links[, catalog_cols, drop = FALSE])
  sl_all <- suite_links
  exp <- if ("expected" %in% names(sl_all)) sl_all$expected %in% TRUE else rep(TRUE, nrow(sl_all))
  # A zero effect is still an effect-size datum, but it is an exact-sign-test
  # tie. Keep it in d_effect/median while omitting it only from d_vote k/n.
  sl_effect <- sl_all[exp & sl_all$n >= 6 & is.finite(sl_all$r), , drop = FALSE]
  out <- do.call(rbind, lapply(seq_len(nrow(catalog)), function(i) {
    pr <- catalog[i, , drop = FALSE]
    keep <- sl_effect$from == pr$from & sl_effect$to == pr$to & sl_effect$lag == pr$lag
    if ("expected_class" %in% names(pr) && "expected_class" %in% names(sl_effect))
      keep <- keep & sl_effect$expected_class == pr$expected_class
    d_effect <- sl_effect[keep, , drop = FALSE]
    d_vote <- d_effect[!is.na(d_effect$sign_match), , drop = FALSE]
    k <- sum(d_vote$sign_match); tot <- nrow(d_vote)
    sensitivity_count <- function(column) {
      if (!column %in% names(d_vote)) return(c(sites = 0L, k = 0L))
      v <- d_vote[[column]]; ok <- !is.na(v)
      c(sites = as.integer(sum(ok)), k = as.integer(sum(v[ok])))
    }
    det <- sensitivity_count("sign_match_detrended")
    chg <- sensitivity_count("sign_match_change")
    outcome <- sensitivity_count("sign_match_outcome_alt")
    spatial <- domain_majority_counts(d_vote)
    poolable <- tot >= min_sites
    p <- if (poolable) stats::binom.test(k, tot, 0.5, alternative = "greater")$p.value else NA_real_
    data.frame(from=pr$from, to=pr$to, lag=pr$lag,
               expected_class=if ("expected_class" %in% names(pr)) pr$expected_class else NA_character_,
               sites=tot, k=k, p=p, poolable=poolable,
               sites_detrended=unname(det["sites"]), k_detrended=unname(det["k"]),
               sites_change=unname(chg["sites"]), k_change=unname(chg["k"]),
               sites_outcome_alt=unname(outcome["sites"]),
               k_outcome_alt=unname(outcome["k"]),
               domains=spatial$domains, k_domain=spatial$k_domain,
               domain_ties=spatial$domain_ties,
               median_r=if (nrow(d_effect)) stats::median(d_effect$r) else NA_real_,
               stringsAsFactors = FALSE)
  }))
  # The network exposes the current literature-motivated family together, so
  # report raw exact-binomial p-values plus familywise/FDR adjustments across
  # poolable rows. These remain exploratory because the family was refined while
  # the analyzed data were being inspected (see PRIOR_FAMILY_STATUS).
  finite <- is.finite(out$p)
  out$p_holm <- out$p_fdr <- NA_real_
  out$p_holm[finite] <- stats::p.adjust(out$p[finite], method = "holm")
  out$p_fdr[finite] <- stats::p.adjust(out$p[finite], method = "BH")
  # poolable rows first (ranked by Holm p, raw p, coverage); unsupported priors stay visible.
  out[order(!out$poolable, out$p_holm, out$p, -out$sites), , drop = FALSE]
}

# Descriptive sign-match tally across TESTABLE links only (n>=6 — the same
# n-floor the verdicts use). Links within one site reuse drivers and responses,
# so they are not independent Bernoulli trials; a within-site binomial p would
# be false precision. pooled_links() carries the exploratory cross-site direction
# reference, where one site contributes one vote; spatial independence is an assumption.
signmatch_score <- function(links) {
  exp <- if ("expected" %in% names(links)) links$expected %in% TRUE else rep(TRUE, nrow(links))
  ok <- links[exp & links$n >= 6 & !is.na(links$sign_match), , drop = FALSE]
  k <- sum(ok$sign_match); tot <- nrow(ok)
  if (tot == 0) return(list(k=0, n=0, p=NA_real_, txt="no links have enough years (n&ge;6) to test here yet"))
  list(k = k, n = tot, p = NA_real_,
       txt = sprintf("%d of %d eligible links (n&ge;6) match their stated direction (descriptive tally; links within a site are not independent)",
                     k, tot))
}

# ---- Lag Experimenter helpers ----
# Registered seasonal-proxy/context setting (fixed choices, not a free search knob).
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
  if (is.null(ann_site) || !nrow(ann_site) || !to %in% names(ann_site)) return(NA_real_)
  yrs <- suppressWarnings(as.integer(ann_site$year))
  response <- suppressWarnings(as.numeric(ann_site[[to]]))
  support <- yrs[is.finite(yrs) & is.finite(response)]
  if (!length(support)) return(NA_real_)
  # Bound the null by the response's finite support envelope. Site-wide years
  # belonging only to another product are structural padding, not response gaps;
  # genuine missing years inside the response envelope remain explicit.
  a_grid <- merge(data.frame(year = seq.int(min(support), max(support))), ann_site,
                  by = "year", all.x = TRUE, sort = TRUE)
  y <- a_grid[[to]]; ny <- length(y)
  if (ny < 4 || !is.finite(observed_r)) return(NA_real_)
  scan_max <- function(a) {
    rs <- vapply(combos, function(cb) {
      m <- lag_pairs(a, cb$col, to, cb$lag)
      if (nrow(m) >= 3) { r <- suppressWarnings(stats::cor(m$x, m$y)); if (is.finite(r)) abs(r) else NA_real_ } else NA_real_
    }, numeric(1))
    if (all(is.na(rs))) NA_real_ else max(rs, na.rm = TRUE)
  }
  # There are only ny-1 distinct non-trivial circular shifts. Enumerate them
  # exactly instead of sampling the same handful 2,000 times, and use the same
  # add-one correction as perm_p_circular(). This makes the explorer honest
  # about its finite p-value floor too.
  shifts <- seq_len(ny - 1L)
  perm_max <- vapply(shifts, function(k) {
    a2 <- a_grid; a2[[to]] <- y[((seq_len(ny) - 1L + k) %% ny) + 1L]
    scan_max(a2)
  }, numeric(1))
  if (!any(is.finite(perm_max))) return(NA_real_)
  b <- sum(perm_max >= abs(observed_r) - 1e-9, na.rm = TRUE)
  (b + 1) / (sum(is.finite(perm_max)) + 1)
}

# which measurement layers have any data at a site
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

# Visual measurement-layer hues: weather sky, phenology lime, plants green,
# animals coral. The order is a co-display, not an inferred pathway.
LAYER_META <- list(
  climate   = list(title = "WEATHER",          icon = "cloud-rain", col = "#43b8e8"),
  phenology = list(title = "GREEN-UP TIMING",  icon = "flower2",    col = "#9bd24a"),
  producer  = list(title = "PLANT OBSERVATIONS", icon = "tree",      col = "#5fb56a"),
  consumer  = list(title = "ANIMAL OBSERVATIONS", icon = "bug",      col = "#fb8a7e"))
# Verdict tiers are DIRECTION verdicts, NOT significance claims. The "consistent"
# key is kept for CSS/lookup stability but now means ALIGNED:
# sign matches AND the block-bootstrap interval excludes zero. teal/gold/coral preserved.
TIER_META <- list(
  consistent  = list(lab = "Aligned (clean direction)", col = "#2dd4bf", text_col = "#0b6f68", ink = "#063b35", icon = "check-circle-fill"),
  apparent    = list(lab = "Apparent only",             col = "#e0b43a", text_col = "#755900", ink = "#2e2406", icon = "dash-circle-fill"),
  neutral     = list(lab = "No usable direction",        col = "#7b8798", text_col = "#4f5d70", ink = "#ffffff", icon = "dash-circle"),
  counter     = list(lab = "Counter to prior",          col = "#fb8a7e", text_col = "#a6332b", ink = "#3a0e08", icon = "x-circle-fill"),
  exploratory = list(lab = "Exploratory (n<6)",         col = "#4a5d78", text_col = "#4a5d78", ink = "#ffffff", icon = "hourglass-split"),
  insufficient= list(lab = "Too few years",             col = "#6b7a89", text_col = "#53606d", ink = "#ffffff", icon = "slash-circle"))

# ===========================================================================
# QC-flag panel (the suite gold standard, §7) — ranked "VERIFY, not wrong"
# data-quality flags for ONE site's cascade slice. Returns list(flags, sets):
#   flags = ranked list (high > warn > info) each with key/level/title/n/detail,
#   sets  = the EXACT offending rows behind each flag (key -> data.frame), so the
#           UI can expand a chip to the records that earned it.
# Every flag is a thing to LOOK AT, never a thing that's "broken" — the cascade's
# QC choices (the connected recurrent-species green-up gate, the within-site MAD temp NA, the
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
    bio_keys <- intersect(c("greenup_doy", "plant_richness", "mammal_cpue", "bird_index",
                            "mosq_activity", "beetle_activity"), names(a))
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

  # (2) Phenology audit — the annual index needs >=2 resolved recurrent species,
  # each species-year needs >=3 uncensored individuals, each species must recur in
  # >=3 eligible years, and the retained incidence panel must be connected. The
  # annual contributor gate is therefore >=6. Left-censored records are screened
  # out, not interval-censored-modelled.
  if (nrow(a) && "greenup_doy" %in% names(a)) {
    gu <- a[is.finite(a$greenup_doy), , drop = FALSE]
    if (!nrow(gu)) {
      add("greenup_absent", "info", "No usable green-up years",
          "No annual green-up index passes the current left-censor screen, resolved/recurrent-species support, and connected-panel rules at this site. That is missing usable evidence, not a clean phenology record.")
    } else if (nrow(gu) < 6) {
      show <- intersect(c("year","greenup_doy","greenup_n_individuals",
                          "greenup_n_species"), names(gu))
      add("greenup_thin", "info", "Green-up rests on a short phenology record",
          paste0("Only ", nrow(gu), " year", if (nrow(gu) == 1) "" else "s",
                 " of green-up here. Every emitted year has >=2 recurrent resolved species and >=3 non-left-censored individuals per species-year (minimum 6 contributors) in the selected connected panel. With few years, a species-year shift can still move the index; read it as an index, not a precise observed onset day. Tap to see the years."),
          gu[, show, drop = FALSE])
    }

    if (all(c("greenup_n_onsets", "greenup_n_left_censored") %in% names(a))) {
      candidate <- a[is.finite(a$greenup_n_onsets) & a$greenup_n_onsets > 0, , drop = FALSE]
      if (nrow(candidate)) {
        candidate$censor_share <- candidate$greenup_n_left_censored /
          candidate$greenup_n_onsets
        censored <- candidate[is.finite(candidate$greenup_n_left_censored) &
                                candidate$greenup_n_left_censored > 0, , drop = FALSE]
        if (nrow(censored)) {
          level <- if (any(censored$censor_share >= 0.5, na.rm = TRUE)) "warn" else "info"
          show <- intersect(c("year", "greenup_n_onsets", "greenup_n_left_censored",
                              "censor_share"), names(censored))
          add("greenup_censor_burden", level,
              "Left-censored green-up candidates were excluded",
              paste0(sum(censored$greenup_n_left_censored), " candidate individual-year",
                     if (sum(censored$greenup_n_left_censored) == 1) " was" else "s were",
                     " already active at the first visit across ", nrow(censored), " year",
                     if (nrow(censored) == 1) "" else "s",
                     ". Exclusion is not an interval-censored model and can select which plants/years contribute based on visit timing and cadence. Inspect the annual shares before treating the retained index as cadence-neutral."),
              censored[, show, drop = FALSE])
        }
      }
    }

    if (all(c("greenup_n_onsets", "greenup_n_taxon_excluded") %in% names(a))) {
      candidate <- a[is.finite(a$greenup_n_onsets) & a$greenup_n_onsets > 0, , drop = FALSE]
      if (nrow(candidate)) {
        candidate$composition_exclusion_share <- candidate$greenup_n_taxon_excluded /
          candidate$greenup_n_onsets
        excluded <- candidate[is.finite(candidate$greenup_n_taxon_excluded) &
                                candidate$greenup_n_taxon_excluded > 0, , drop = FALSE]
        if (nrow(excluded)) {
          level <- if (any(excluded$composition_exclusion_share >= 0.5, na.rm = TRUE)) "warn" else "info"
          show <- intersect(c("year", "greenup_n_onsets", "greenup_n_taxon_excluded",
                              "greenup_n_individuals", "greenup_n_species",
                              "composition_exclusion_share"), names(excluded))
          add("greenup_composition_exclusions", level,
              "Green-up candidates were removed by composition/support rules",
              paste0(sum(excluded$greenup_n_taxon_excluded), " uncensored candidate individual-year",
                     if (sum(excluded$greenup_n_taxon_excluded) == 1) " was" else "s were",
                     " excluded across ", nrow(excluded), " year",
                     if (nrow(excluded) == 1) "" else "s",
                     " because identity, species-year n, recurrence, or connected-panel requirements were not met. This stabilizes composition but changes the contributing population; inspect the exclusions rather than reading them as random missingness."),
              excluded[, show, drop = FALSE])
        }
      }
    }

    width_cols <- c("greenup_onset_interval_median_days",
                    "greenup_onset_interval_p90_days",
                    "greenup_onset_interval_max_days")
    if (all(width_cols %in% names(a))) {
      typical_wide <- a[is.finite(a$greenup_onset_interval_median_days) &
                          a$greenup_onset_interval_median_days > 14, , drop = FALSE]
      if (nrow(typical_wide)) {
        show <- intersect(c("year", "greenup_doy", "greenup_n_individuals", width_cols),
                          names(typical_wide))
        add("greenup_wide_typical_intervals", "warn",
            "Typical contributor onset intervals exceed 14 days",
            paste0(nrow(typical_wide), " year", if (nrow(typical_wide) == 1) " has" else "s have",
                   " a median last-no to first-yes interval wider than 14 days among final contributors. The annual timing index uses interval midpoints, so a broad typical interval indicates visit-cadence uncertainty even when no single contributor is exceptionally wide."),
            typical_wide[, show, drop = FALSE])
      }
      wide <- a[is.finite(a$greenup_onset_interval_max_days) &
                  a$greenup_onset_interval_max_days > 30, , drop = FALSE]
      if (nrow(wide)) {
        show <- intersect(c("year", "greenup_doy", "greenup_n_individuals", width_cols),
                          names(wide))
        add("greenup_wide_intervals", "warn",
            "Some contributing onset intervals exceed 30 days",
            paste0(nrow(wide), " year", if (nrow(wide) == 1) " has" else "s have",
                   " at least one final contributor whose last-no to first-yes interval exceeds 30 days. The index uses interval midpoints; these annual median/p90/max widths expose cadence uncertainty and are not confidence intervals for the annual index."),
            wide[, show, drop = FALSE])
      }
    }
  }

  # A lack of interval-bearing links is an absence of usable evidence, not a
  # reason to display the all-clear path.
  if (nrow(lk) && all(c("n", "lo", "hi") %in% names(lk))) {
    interval_rows <- lk[lk$n >= 6 & is.finite(lk$lo) & is.finite(lk$hi), , drop = FALSE]
    if (!nrow(interval_rows))
      add("interval_absent", "info", "No link has a usable uncertainty interval",
          "No link at this site currently has both enough overlapping years and a finite block-bootstrap interval. Direction evidence is absent here; it did not pass every check.")
  }

  # (3) HIGH — "apparent" links whose bootstrap CI spans zero. These point the way the
  # prior predicts but the 95% interval crosses 0, so the sign isn't yet distinguishable
  # from noise — the most over-readable cell in the app. Surface them so a reader doesn't
  # promote an "apparent" to a result.
  if (nrow(lk) && all(c("tier","lo","hi") %in% names(lk))) {
    ap <- lk[lk$tier %in% "apparent" & is.finite(lk$lo) & is.finite(lk$hi) & lk$lo <= 0 & lk$hi >= 0, , drop = FALSE]
    if (nrow(ap)) {
      lab <- function(k) if (!is.null(signals) && k %in% signals$key) signals$label[signals$key == k][1] else k
      ap$link <- vapply(seq_len(nrow(ap)), function(i) sprintf("%s -> %s", lab(ap$from[i]), lab(ap$to[i])), character(1))
      show <- intersect(c("link","lag","n","r","lo","hi","p"), names(ap))
      add("apparent_ci0", "high", "“Apparent” links whose CI spans zero",
          paste0(nrow(ap), " link", if (nrow(ap) == 1) "" else "s",
                 " point in the stated direction but the 95% circular block-bootstrap interval still crosses 0; the sign is not yet clean at this site's n. For vote-eligible rows, compare the raw, adjusted, trend, and outcome-estimator cross-site summaries on Across NEON. Tap to inspect each pairing."),
          ap[, show, drop = FALSE])
    }
  }

  # rank high > warn > info (the gold-standard order); clean path = a green reassurance
  if (!length(flags)) {
    return(list(flags = list(list(key = "clean", level = "clean",
      title = "No data-quality flags at this site",
      detail = "No implemented QC rule fired for the available records. This does not guarantee that every product or link has usable support; inspect the coverage and codebook alongside this panel.", n = 0L)),
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
