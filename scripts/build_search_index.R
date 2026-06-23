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
suppressPackageStartupMessages(library(dplyr))

# run from the app root whether invoked from repo root or scripts/
if (!file.exists("global.R") && file.exists("../global.R")) setwd("..")
if (!file.exists("global.R")) stop("run from the NEON-Driver-Cascade app root (global.R not found)")

cascade <- readRDS("data/cascade.rds")
sl    <- cascade$suite_links
pr    <- cascade$priors
pooled<- cascade$pooled
sm    <- cascade$site_meta
ann   <- cascade$annual

stopifnot(nrow(sl) > 0, all(c("from","to","lag","r","p","prior_sign","sign_match",
  "tier","expected","n","site","biome","biome_class","verdict") %in% names(sl)))

# year coverage per site (year_min / year_max) from the annual rows
yr <- ann %>% group_by(site) %>%
  summarise(year_min = suppressWarnings(min(year, na.rm = TRUE)),
            year_max = suppressWarnings(max(year, na.rm = TRUE)), .groups = "drop") %>%
  mutate(across(c(year_min, year_max), ~ ifelse(is.finite(.), as.integer(.), NA_integer_)))

# a stable, human-readable label per prior link (the "find a link" autocomplete)
plabel <- function(from, to, lag) {
  abbr <- c(temp="Temperature", precip="Rainfall", precip_winter="Winter rain",
            precip_monsoon="Summer monsoon", temp_spring="Spring temp",
            greenup_doy="Green-up onset", fruiting_pct="Fruiting",
            plant_richness="Plant richness", plant_intro_pct="Plant invasion",
            mammal_cpue="Small mammals", mammal_mnka="Small mammals",
            bird_index="Birds", bird_richness="Bird richness",
            mosq_activity="Mosquitoes")
  f <- ifelse(from %in% names(abbr), abbr[from], from)
  t <- ifelse(to   %in% names(abbr), abbr[to],   to)
  sprintf("%s → %s%s", unname(f), unname(t),
          ifelse(lag > 0, sprintf(" (lag %dy)", lag), ""))
}

# ---- LINKS table: one row per (site, prior link), the search unit ------------
# Carries the per-site test (r, p, sign, n, tier, verdict) + whether the link is
# the biome-EXPECTED mechanism at that site, so a query can ask "where is this
# link significant?" honestly (and label out-of-biome corroboration).
links <- sl %>%
  mutate(link_id    = sprintf("%s|%s|%d", from, to, lag),
         link_label = plabel(from, to, lag),
         driver     = from, response = to,
         # "significant" = expected mechanism, enough years, sign matches, p<0.05.
         # Honest: per-site tests are underpowered at this n; this is a screen, not
         # a verdict — the pooled (cross-site) test is the real evidence.
         is_signif  = expected %in% TRUE & is.finite(n) & n >= 6 &
                      sign_match %in% TRUE & is.finite(p) & p < 0.05,
         is_testable= is.finite(n) & n >= 6) %>%
  left_join(yr, by = "site") %>%
  select(link_id, link_label, driver, response, lag, site, biome, biome_class,
         expected, n, r, p, prior_sign, sign_match, tier, verdict,
         is_signif, is_testable, year_min, year_max) %>%
  arrange(link_label, desc(is_signif), p, site)

# ---- LINK catalogue (one row per distinct prior) for the autocomplete --------
link_catalog <- links %>%
  distinct(link_id, link_label, driver, response, lag) %>%
  left_join(pr %>% transmute(link_id = sprintf("%s|%s|%d", from, to, lag),
                             conf, expected_class, note), by = "link_id") %>%
  arrange(link_label)

# ---- SITE strength roll-up: how many EXPECTED priors resolve per site --------
# resolved = expected mechanism, n>=6, sign matches the prior (direction agrees).
# Reported with the count of expected-and-testable links as the denominator so the
# bar reads as "k of K expected links agree", never an absolute ranking.
site_strength <- links %>%
  group_by(site, biome, biome_class) %>%
  summarise(
    expected_testable = sum(expected %in% TRUE & is_testable),
    n_resolved        = sum(expected %in% TRUE & is_testable & sign_match %in% TRUE),
    n_signif          = sum(is_signif),
    n_counter         = sum(expected %in% TRUE & is_testable & sign_match %in% FALSE),
    n_layers          = NA_integer_,
    .groups = "drop") %>%
  left_join(yr, by = "site") %>%
  arrange(desc(n_resolved), desc(n_signif), site)

# small denominators per prior (for honest captions on the threshold query)
prior_pooled <- if (!is.null(pooled) && nrow(pooled)) {
  pooled %>% mutate(link_id = sprintf("%s|%s|%d", from, to, lag)) %>%
    select(link_id, sites, k, p_pooled = p, median_r, poolable)
} else data.frame()

index <- list(
  links         = as.data.frame(links),
  link_catalog  = as.data.frame(link_catalog),
  site_strength = as.data.frame(site_strength),
  prior_pooled  = as.data.frame(prior_pooled),
  built         = as.character(Sys.time()),
  n_sites       = length(unique(links$site)),
  n_links       = nrow(link_catalog))

saveRDS(index, "data/search_index.rds")
sz <- file.info("data/search_index.rds")$size
cat(sprintf("search_index.rds written: %d sites, %d distinct links, %d link-rows, %s KB.\n",
            index$n_sites, index$n_links, nrow(index$links), format(round(sz/1024, 1))))
