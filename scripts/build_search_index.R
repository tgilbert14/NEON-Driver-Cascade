# ===========================================================================
# build_search_index.R — precompute the bundled "Search the network" index.
#
# Reads the COMMITTED cascade bundle (data/cascade.rds) — NOT a live fetch — and
# writes a small data/search_index.rds the app loads once at boot (like a
# site_index). The Search tab filters this in memory, so it stays instant.
#
#   Rscript scripts/build_search_index.R
#
# The cascade has NO taxa; the searchable units are the cross-site LINK results
# (one per site x prior) and a per-site cascade-strength summary. This builder is
# a tidy slice of cascade.rds$suite_links + a strength roll-up + the prior list;
# it adds no new science, it just shapes what's already computed for fast lookup.
# ===========================================================================
source("scripts/generation_guard.R", local = TRUE)
suppressPackageStartupMessages(library(dplyr))

# run from the app root whether invoked from repo root or scripts/
if (!file.exists("global.R") && file.exists("../global.R")) setwd("..")
if (!file.exists("global.R")) stop("run from the NEON-Driver-Cascade app root (global.R not found)")
eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)  # SEARCH_INDEX_SCHEMA_VERSION

cascade <- readRDS("data/cascade.rds")
sl    <- cascade$suite_links
pr    <- cascade$priors
pooled<- cascade$pooled
sm    <- cascade$site_meta
ann   <- cascade$annual

if (!identical(cascade$meta$trend_sensitivity_version %||% NA_character_,
               TREND_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$trend_sensitivity_note %||% NA_character_,
               TREND_SENSITIVITY_NOTE) ||
    !identical(cascade$meta$estimator_sensitivity_version %||% NA_character_,
               ESTIMATOR_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$estimator_sensitivity_note %||% NA_character_,
               ESTIMATOR_SENSITIVITY_NOTE) ||
    !identical(cascade$meta$spatial_sensitivity_version %||% NA_character_,
               SPATIAL_SENSITIVITY_VERSION) ||
    !identical(cascade$meta$spatial_sensitivity_note %||% NA_character_,
               SPATIAL_SENSITIVITY_NOTE) ||
    !identical(cascade$meta$greenup_index_version %||% NA_character_,
               GREENUP_INDEX_VERSION) ||
    !identical(cascade$meta$greenup_index_note %||% NA_character_,
               GREENUP_INDEX_NOTE))
  stop("cascade.rds sensitivity lineage is missing or incompatible; rebuild it first",
       call. = FALSE)

stopifnot(nrow(sl) > 0, all(c("from","to","lag","r","p","p_floor","n_null","series_span",
  "prior_sign","sign_match","ci_excludes_zero","tier","expected","n","site","domain","biome",
  "biome_class","verdict","n_detrended","r_detrended","sign_match_detrended",
  "n_change","r_change","sign_match_change","n_outcome_alt","r_outcome_alt",
  "sign_match_outcome_alt") %in% names(sl)))

# site-record bounds retained separately from link-specific paired-year bounds
yr <- ann %>% group_by(site) %>%
  summarise(site_year_min = suppressWarnings(min(year, na.rm = TRUE)),
            site_year_max = suppressWarnings(max(year, na.rm = TRUE)), .groups = "drop") %>%
  mutate(across(c(site_year_min, site_year_max), ~ ifelse(is.finite(.), as.integer(.), NA_integer_)))

# Link-specific paired-year bounds. Site-wide record bounds beside a link can
# imply coverage that the link does not have, so compute these from the same
# lag-aligned complete pairs used for r/n.
pair_years <- do.call(rbind, lapply(seq_len(nrow(sl)), function(i) {
  r <- sl[i, , drop = FALSE]
  a <- ann[ann$site == r$site, , drop = FALSE]
  m <- lag_pairs(a, r$from, r$to, r$lag)
  data.frame(site = r$site, from = r$from, to = r$to, lag = r$lag,
             year_min = if (nrow(m)) min(m$year) else NA_integer_,
             year_max = if (nrow(m)) max(m$year) else NA_integer_,
             stringsAsFactors = FALSE)
}))

# a stable, human-readable label per prior link (the "find a link" autocomplete)
plabel <- function(from, to, lag) {
  abbr <- c(temp="Temperature", precip="Rainfall", precip_winter="Winter rain",
            precip_monsoon="Summer monsoon", temp_spring="Spring temp",
            greenup_doy="Green-up timing index", fruiting_pct="Fruiting",
            plant_richness="Plant richness", plant_intro_pct="Plant invasion",
            mammal_cpue="Small mammals", mammal_mnka="Small mammals",
            bird_index="Birds", bird_richness="Bird richness",
            mosq_activity="Mosquitoes", beetle_activity="Ground beetles")
  f <- ifelse(from %in% names(abbr), abbr[from], from)
  t <- ifelse(to   %in% names(abbr), abbr[to],   to)
  sprintf("%s \u2192 %s%s", unname(f), unname(t),
          ifelse(lag > 0, sprintf(" (lag %dy)", lag), ""))
}

# ---- LINKS table: one row per (site, prior link), the search unit ------------
# Carries the per-site diagnostics (r, circular p, sign, n, tier, verdict) plus
# whether the link is vote-eligible. Context-only expected_class="none" rows stay
# searchable but never enter direction tallies or pooling. Per-site rows are never
# labeled significant; network inference lives in the pooled table.
links <- sl %>%
  mutate(link_id    = sprintf("%s|%s|%d", from, to, lag),
         link_label = plabel(from, to, lag),
         driver     = from, response = to,
         # "aligned" is deliberately NOT called significant: it follows the stated
         # direction, is n-gated, and its block-bootstrap interval excludes
         # zero (the bundle's `consistent` tier). Network-level inference is
         # reported separately in the cross-site pooled direction table.
         is_aligned = expected %in% TRUE & is.finite(n) & n >= 6 & tier == "consistent",
         is_testable = is.finite(n) & n >= 6 & is.finite(r)) %>%
  left_join(pair_years, by = c("site", "from", "to", "lag")) %>%
  left_join(yr, by = "site") %>%
  select(link_id, link_label, driver, response, lag, site, domain, biome, biome_class,
         expected, n, r, p, p_floor, n_null, series_span, prior_sign, sign_match,
         n_detrended, r_detrended, sign_match_detrended,
         n_change, r_change, sign_match_change,
         n_outcome_alt, r_outcome_alt, sign_match_outcome_alt,
         ci_excludes_zero, tier, verdict, is_aligned, is_testable,
         year_min, year_max, site_year_min, site_year_max) %>%
  arrange(link_label, desc(expected), match(tier, c("consistent", "apparent", "neutral", "counter", "exploratory", "insufficient")),
          desc(abs(r)), site)

# ---- LINK catalogue (one row per distinct prior) for the autocomplete --------
link_catalog <- links %>%
  distinct(link_id, link_label, driver, response, lag) %>%
  left_join(pr %>% transmute(link_id = sprintf("%s|%s|%d", from, to, lag),
                             conf, expected_class, note), by = "link_id") %>%
  arrange(link_label)

# ---- SITE strength roll-up: how many VOTE-ELIGIBLE priors resolve per site ---
# resolved = vote-eligible, n>=6, sign matches the prior (direction agrees).
# Reported with the vote-eligible/testable denominator so context-only rows cannot
# inflate the bar or silently become inferential evidence.
site_strength <- links %>%
  group_by(site, domain, biome, biome_class) %>%
  summarise(
    # Exact direction tests omit zero-effect ties, so the displayed denominator
    # matches signmatch_score()/pooled_links() rather than counting a neutral row.
    expected_testable = sum(expected %in% TRUE & is_testable & !is.na(sign_match)),
    n_resolved        = sum(expected %in% TRUE & is_testable & sign_match %in% TRUE),
    n_aligned         = sum(is_aligned),
    n_counter         = sum(expected %in% TRUE & is_testable & sign_match %in% FALSE),
    n_layers          = NA_integer_,
    .groups = "drop") %>%
  left_join(yr, by = "site") %>%
  arrange(desc(n_resolved), desc(n_aligned), site)

# small denominators per prior (for honest captions on the threshold query)
prior_pooled <- if (!is.null(pooled) && nrow(pooled)) {
  pooled %>% mutate(link_id = sprintf("%s|%s|%d", from, to, lag)) %>%
    transmute(link_id, sites, k, p_raw = p,
              p_holm = if ("p_holm" %in% names(pooled)) p_holm else NA_real_,
              p_fdr = if ("p_fdr" %in% names(pooled)) p_fdr else NA_real_,
              median_r, poolable,
              sites_detrended, k_detrended, sites_change, k_change,
              sites_outcome_alt, k_outcome_alt,
              domains, k_domain, domain_ties)
} else data.frame()

index <- list(
  links         = as.data.frame(links),
  link_catalog  = as.data.frame(link_catalog),
  site_strength = as.data.frame(site_strength),
  prior_pooled  = as.data.frame(prior_pooled),
  schema_version = SEARCH_INDEX_SCHEMA_VERSION,
  source_bundle_md5 = unname(tools::md5sum("data/cascade.rds")),
  source_bundle_rows = nrow(sl),
  source_bundle_priors = nrow(pr),
  trend_sensitivity_version = cascade$meta$trend_sensitivity_version,
  trend_sensitivity_note = cascade$meta$trend_sensitivity_note,
  estimator_sensitivity_version = cascade$meta$estimator_sensitivity_version,
  estimator_sensitivity_note = cascade$meta$estimator_sensitivity_note,
  spatial_sensitivity_version = cascade$meta$spatial_sensitivity_version,
  spatial_sensitivity_note = cascade$meta$spatial_sensitivity_note,
  greenup_index_version = cascade$meta$greenup_index_version,
  greenup_index_note = cascade$meta$greenup_index_note,
  built         = cascade$meta$built_when,
  n_sites       = length(unique(links$site)),
  n_links       = nrow(link_catalog))

index <- cascade_normalize_artifact_text(index)
cascade_assert_artifact_text(index, "data/search_index.rds")
saveRDS(index, "data/search_index.rds")
sz <- file.info("data/search_index.rds")$size
cat(sprintf("search_index.rds written: %d sites, %d distinct links, %d link-rows, %s KB.\n",
            index$n_sites, index$n_links, nrow(index$links), format(round(sz/1024, 1))))
