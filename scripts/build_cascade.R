# ===========================================================================
# NEON Driver Cascade — build_cascade.R
# Assemble a per-site ANNUAL signal table from the five sibling bundles + the
# small-mammal env overlays. Reads existing .rds only — NO neonUtilities, so
# plain R-4.5.x runs it. Output: data/cascade.rds = list(annual, signals,
# priors, sites, meta). Run from the NEON-Driver-Cascade dir.
# ===========================================================================
suppressPackageStartupMessages({ library(dplyr) })
# helpers for the cross-site precompute (biome-aware site_links + pooling) and the
# biome classification that drives which priors are EXPECTED at each site.
source("R/cascade_helpers.R")   # %||%, site_links(), pooled_links()
source("R/site_metadata.R")     # neon_sites, biome_class(), biome_of(), biome_label()
# Where the sibling repos live. Locally that's the VGS-R folder; in CI the refresh
# workflow clones each sibling into a workspace and sets CASCADE_ROOT to it. The
# dir names below must match the clone target dirs the workflow uses.
ROOT <- Sys.getenv("CASCADE_ROOT", unset = "C:/Users/tsgil/OneDrive/Documents/VGS - R")
APP  <- list(
  mammal = file.path(ROOT, "App-NEON-Small-Mammal-Tracker"),
  plant  = file.path(ROOT, "NEON-Plant-Diversity"),
  veg    = file.path(ROOT, "NEON-Veg-Structure"),
  bird   = file.path(ROOT, "NEON-Breeding-Birds"),
  phe    = file.path(ROOT, "NEON-Plant-Phenology"))
source(file.path(APP$phe, "R/phe_helpers.R"))   # onset(), GREENUP
# veg-structure standing-stock helpers (optional context; never breaks the build)
.have_veg <- tryCatch({ source(file.path(APP$veg, "R/veg_helpers.R")); TRUE }, error = function(e) FALSE)

rd <- function(p) if (file.exists(p)) tryCatch(readRDS(p), error=function(e) NULL) else NULL
sites_in <- function(app) { d <- file.path(APP[[app]], "data/sites"); if (!dir.exists(d)) character(0) else sub("\\.rds$","",list.files(d, "\\.rds$")) }
yr_of <- function(x) suppressWarnings(as.integer(format(as.Date(x), "%Y")))

# ---- per-product annual extractors (return data.frame site,year,<signals>) ----
ann_env <- function(site) {                       # climate + coarse NEON phenology %
  e <- rd(file.path(APP$mammal, "data/env", paste0(site, ".rds"))); if (is.null(e)) return(NULL)
  e$year <- yr_of(e$date %||% paste0(e$ym, "-01"))
  # QC: keep only plausible monthly values, and require enough months so a PARTIAL
  # year doesn't masquerade as an annual temp/precip total.
  agg <- e %>% filter(!is.na(.data$year)) %>% group_by(year) %>% summarise(
    temp = { v <- .data$temp_c[is.finite(.data$temp_c) & .data$temp_c > -40 & .data$temp_c < 50]
             if (length(v) >= 8) round(mean(v), 2) else NA_real_ },                 # >=8 valid months
    precip = { p <- .data$precip_mm[is.finite(.data$precip_mm) & .data$precip_mm >= 0 & .data$precip_mm < 2000]
               if (length(p) >= 10) round(sum(p), 1) else NA_real_ },               # annual total needs ~full year
    # fruiting_pct is a monthly STATUS yes-share for the exact "Fruits" phenophase (DP1.10055.001,
    # refresh_env_data.R) — a defensible % of plants in fruit, NOT a binned intensity. We take the
    # year's PEAK, but only over months with >=5 observed individuals so a peak can't rest on 1-2
    # plants. (Arid sites track no "Fruits" phenophase, so this is honestly NA there.)
    fruiting_pct = { ok <- is.finite(.data$fruiting_pct) &
                       (if ("fruiting_pct_n" %in% names(e)) is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5 else TRUE)
                     if (any(ok)) round(max(.data$fruiting_pct[ok]), 1) else NA_real_ },
    .groups="drop")
  # Within-site temp outlier: NA any year whose annual mean is implausibly far from
  # this SITE's own median — catches a corrupted-sensor year (e.g. SCBI 2018, whose
  # summer months read deeply negative) that a fixed window/median can't, since ~40%
  # of its months are bad. Needs >=4 finite years to anchor a robust median.
  tv <- agg$temp[is.finite(agg$temp)]
  if (length(tv) >= 4) { med <- stats::median(tv); thr <- max(6, 3 * stats::mad(tv))
    agg$temp[is.finite(agg$temp) & abs(agg$temp - med) > thr] <- NA_real_ }
  agg %>% mutate(site = site, .before = 1)
}
ann_env_seasonal <- function(site) {              # SEASONAL climate — the desert fix
  # A single annual precip total blends two ecologically independent, often
  # ENSO-anticorrelated rain seasons that drive DIFFERENT guilds: winter (Oct-Mar)
  # rain -> spring forbs; summer monsoon (Jul-Sep) -> the C4 grass seed crop desert
  # granivores track. Reconstruct them (+ a spring-temp window) from the SAME monthly
  # overlay ann_env reads. Verified: at SRER this recovers winter-rain->richness (+0.27)
  # and monsoon(t-1)->rodents (+0.72) that the annual aggregation hides.
  e <- rd(file.path(APP$mammal, "data/env", paste0(site, ".rds"))); if (is.null(e)) return(NULL)
  e$date <- e$date %||% paste0(e$ym, "-01")
  e$year <- yr_of(e$date); e$mo <- suppressWarnings(as.integer(format(as.Date(e$date), "%m")))
  e <- e[is.finite(e$year) & is.finite(e$mo), , drop = FALSE]; if (!nrow(e)) return(NULL)
  e$precip_mm[!(is.finite(e$precip_mm) & e$precip_mm >= 0 & e$precip_mm < 2000)] <- NA
  e$temp_c[!(is.finite(e$temp_c) & e$temp_c > -40 & e$temp_c < 50)] <- NA
  e$wy <- ifelse(e$mo >= 10, e$year + 1L, e$year)   # Oct-Dec credited to the year winter ENDS
  # per-season month-count gates (annual gates can't protect a partial-season sum)
  win <- e %>% filter(.data$mo %in% c(10,11,12,1,2,3)) %>% group_by(year = .data$wy) %>%
    summarise(precip_winter = if (sum(!is.na(.data$precip_mm)) >= 5) round(sum(.data$precip_mm, na.rm = TRUE), 1) else NA_real_, .groups = "drop")
  mon <- e %>% filter(.data$mo %in% c(7,8,9)) %>% group_by(year = .data$year) %>%
    summarise(precip_monsoon = if (sum(!is.na(.data$precip_mm)) == 3) round(sum(.data$precip_mm, na.rm = TRUE), 1) else NA_real_, .groups = "drop")
  spr <- e %>% filter(.data$mo %in% c(3,4,5)) %>% group_by(year = .data$year) %>%
    summarise(temp_spring = if (sum(!is.na(.data$temp_c)) >= 2) round(mean(.data$temp_c, na.rm = TRUE), 2) else NA_real_, .groups = "drop")
  out <- Reduce(function(a, b) full_join(a, b, by = "year"), list(win, mon, spr))
  # same within-site MAD outlier QC the annual temp path uses (catches the SCBI-2018
  # corrupted-sensor year a naive seasonal recompute would let through).
  tv <- out$temp_spring[is.finite(out$temp_spring)]
  if (length(tv) >= 4) { med <- stats::median(tv); thr <- max(6, 3 * stats::mad(tv))
    out$temp_spring[is.finite(out$temp_spring) & abs(out$temp_spring - med) > thr] <- NA_real_ }
  out %>% mutate(site = site, .before = 1)
}
ann_phe <- function(site) {                       # green-up onset DOY (the hinge)
  b <- rd(file.path(APP$phe, "data/sites", paste0(site, ".rds"))); if (is.null(b)) return(NULL)
  o <- onset(b$obs, GREENUP); if (is.null(o) || !nrow(o)) return(NULL)
  o %>% group_by(year) %>% summarise(greenup_doy = round(stats::median(.data$onset_doy)),
      n_ind = dplyr::n_distinct(.data$individualID), .groups="drop") %>%
    filter(.data$n_ind >= 5) %>% transmute(site = site, year, greenup_doy)
}
ann_plant <- function(site) {                     # producer: richness + introduced cover
  b <- rd(file.path(APP$plant, "data/sites", paste0(site, ".rds"))); if (is.null(b) || is.null(b$occ)) return(NULL)
  oc <- b$occ; sp <- oc[oc$is_species %in% TRUE, , drop=FALSE]
  sp %>% group_by(year) %>% summarise(
    plant_richness = dplyr::n_distinct(.data$scientificName),
    plant_intro_pct = { tot <- sum(.data$percentCover, na.rm=TRUE)
      if (tot > 0) round(100 * sum(.data$percentCover[.data$nativeStatusCode %in% c("I","NI")], na.rm=TRUE) / tot, 1) else NA_real_ },
    .groups="drop") %>% mutate(site = site, .before = 1)
}
ann_mammal <- function(site) {                    # consumer: CPUE + minimum known alive
  d <- rd(file.path(APP$mammal, "data/sites", paste0(site, ".rds"))); if (is.null(d)) return(NULL)
  if (!is.data.frame(d)) d <- d[[1]]
  d$year <- yr_of(d$collectDate); d <- d[!is.na(d$year), , drop=FALSE]; if (!nrow(d)) return(NULL)
  # Each row is a TRAP-NIGHT. Effort = DEPLOYED trap-nights (exclude "1 - trap not
  # set"); a capture = trapStatus 5 (capture) or 4 (>1 in one trap). The old code
  # divided by n_distinct(nightuid) = BOUTS, inflating CPUE ~90x into an impossible
  # "35 animals per trap" — this is the captures-per-100-trap-nights index (≈4-16).
  # Effort = trap-nights with the Nelson & Clark (1973) weighting the FLAGSHIP uses
  # (App-NEON-Small-Mammal-Tracker/R/helpers.R:208-216): trapStatus "1 - not set" = 0,
  # "2/3 - disturbed/sprung" = HALF a trap-night, "4/5/6 - capture/set-empty" = 1 full.
  # A capture = a tagged-individual row (tagID present), the flagship's CPUE numerator —
  # so the cascade's consumer rung is the SAME number the consumer app reports, not a
  # divergent grepl-on-status approximation.
  has_status <- "trapStatus" %in% names(d)
  if (has_status) {
    ts1 <- substr(as.character(d$trapStatus), 1, 1); ts1[is.na(ts1)] <- ""
    d$trap_effort <- ifelse(ts1 == "1", 0, ifelse(ts1 %in% c("2","3"), 0.5, 1))
  } else d$trap_effort <- 1
  d$is_cap <- !is.na(d$tagID) & nzchar(as.character(d$tagID))
  d %>% group_by(year) %>% summarise(
    traps    = sum(.data$trap_effort, na.rm = TRUE),                   # Nelson & Clark trap-nights
    captures = sum(.data$is_cap, na.rm = TRUE),
    mammal_mnka = dplyr::n_distinct(.data$tagID[.data$is_cap]),
    .groups="drop") %>%
    mutate(mammal_cpue = ifelse(.data$traps > 0, round(100 * .data$captures / .data$traps, 2), NA_real_),
           site = site) %>% select(site, year, mammal_cpue, mammal_mnka)
}
ann_bird <- function(site) {                      # consumer: detection index + richness
  b <- rd(file.path(APP$bird, "data/sites", paste0(site, ".rds"))); if (is.null(b) || is.null(b$obs)) return(NULL)
  o <- b$obs; if (!"year" %in% names(o)) return(NULL)
  spo <- if ("is_species" %in% names(o)) o[o$is_species %in% TRUE, , drop=FALSE] else o
  o %>% group_by(year) %>% summarise(
    bird_index = { pts <- dplyr::n_distinct(.data$pointkey); if (pts > 0) round(sum(.data$clusterSize, na.rm=TRUE)/pts, 2) else NA_real_ },
    .groups="drop") %>%
    left_join(spo %>% group_by(year) %>% summarise(bird_richness = dplyr::n_distinct(.data$scientificName), .groups="drop"), by="year") %>%
    mutate(site = site) %>% select(site, year, bird_index, bird_richness)
}
ann_veg <- function(site) {                       # producer STANDING STOCK — a slow ~5-yr STATE,
  # NOT an annual link (its remeasurement cadence would manufacture pseudo-resolution). Live basal
  # area m2/ha from the Veg-Structure sibling: directly measured, allometry-free, and computable at
  # DESERTS via basal stem diameter (where richness/temp links fail). Honest cure for the richness
  # productivity proxy — but a stock, not a flux, so it enters as per-site context, not a ladder line.
  if (!isTRUE(.have_veg)) return(NULL)
  b <- rd(file.path(APP$veg, "data/sites", paste0(site, ".rds")))
  if (is.null(b) || is.null(b$trees) || is.null(b$plots)) return(NULL)
  snap <- tryCatch(tree_snapshot(b$trees), error = function(e) NULL); if (is.null(snap) || !nrow(snap)) return(NULL)
  spec <- tryCatch(size_spec(classify_structure(snap)), error = function(e) SIZE_FOREST)
  ss <- tryCatch(stand_site(snap, b$plots, spec), error = function(e) NULL); if (is.null(ss)) return(NULL)
  data.frame(site = site, veg_ba_ha = ss$ba_ha, veg_ba_se = ss$ba_se,
             veg_type = spec$type, veg_n_plots = ss$n_plots, stringsAsFactors = FALSE)
}

# ---- assemble over the union of sites that have mammal or bird data ----
all_sites <- sort(unique(c(sites_in("mammal"), sites_in("bird"))))
cat("assembling", length(all_sites), "sites...\n")
join_all <- function(site) {
  parts <- Filter(Negate(is.null), list(ann_env(site), ann_env_seasonal(site), ann_phe(site), ann_plant(site), ann_mammal(site), ann_bird(site)))
  if (!length(parts)) return(NULL)
  Reduce(function(a,b) full_join(a,b,by=c("site","year")), parts)
}
annual <- bind_rows(lapply(all_sites, join_all))
annual <- annual[!is.na(annual$year) & annual$year >= 2013 & annual$year <= 2025, , drop=FALSE]
annual <- annual %>% arrange(.data$site, .data$year)

# ensure every signal column exists even if no site had it
SIGCOLS <- c("precip","temp","precip_winter","precip_monsoon","temp_spring","fruiting_pct","greenup_doy","plant_richness","plant_intro_pct","mammal_cpue","mammal_mnka","bird_index","bird_richness")
for (c in SIGCOLS) if (!c %in% names(annual)) annual[[c]] <- NA_real_

# ---- signal metadata: trophic layer + display + direction-of-"more" ----
# `ladder` = show on the main stacked ladder. Seasonal climate signals are ladder=FALSE:
# they power the desert priors + the Seasonal Climate panel without crowding the ladder.
signals <- tibble::tribble(
  ~key,            ~label,                         ~layer,       ~unit,        ~higher_is,     ~ladder,
  "precip",        "Precipitation (annual)",       "climate",    "mm/yr",      "wetter",        TRUE,
  "temp",          "Mean temperature",             "climate",    "°C",         "warmer",        TRUE,
  "precip_winter", "Winter rain (Oct–Mar)",        "climate",    "mm",         "wetter winter", FALSE,
  "precip_monsoon","Monsoon rain (Jul–Sep)",       "climate",    "mm",         "wetter monsoon",FALSE,
  "temp_spring",   "Spring temperature",           "climate",    "°C",         "warmer spring", FALSE,
  "greenup_doy",   "Green-up onset",               "phenology",  "day-of-year","later",         TRUE,
  "fruiting_pct",  "Peak fruiting",                "producer",   "% plants",   "more fruit",    TRUE,
  "plant_richness","Plant richness",               "producer",   "species",    "more diverse",  TRUE,
  "plant_intro_pct","Introduced plant cover",      "producer",   "% cover",    "more invaded",  TRUE,
  "mammal_cpue",   "Small-mammal catch rate",      "consumer",   "per 100 TN", "more rodents",  TRUE,
  "mammal_mnka",   "Small mammals (indiv.)",       "consumer",   "individuals","more rodents",  TRUE,
  "bird_index",    "Bird detection index",         "consumer",   "birds/point","more birds",    TRUE,
  "bird_richness", "Bird richness",                "consumer",   "species",    "more species",  TRUE)

# ---- literature priors: expected sign + lag (years). The `note` is PLAIN-ENGLISH
# for non-technical users AND carries the honest scope caveat (the science review:
# several mechanisms are spatial/seasonal but we test them within-site year-to-year,
# the weakest regime; #1 is richness not productivity; #6 is the shakiest). Citations
# live in the About panel. `conf` = how strong the prior is (strong/moderate/weak).
# ---- BIOME-AWARE literature priors. `expected_class` marks the limiting-resource
# regime where the mechanism is established: temp->green-up where TEMPERATURE limits
# phenology (temperate/boreal/prairie/tundra), the seasonal-rain priors where WATER
# does (desert/sagebrush). Every prior is still COMPUTED wherever data exists; the
# class only governs which links count toward a site's sign-match tally and which
# biome each link pools across. Grounded in re-computation on the live data:
#   temp->green-up holds at ~72% of temperature-limited sites (23/32, binom p=0.010);
#   at SRER winter-rain->richness r=+0.27 and monsoon(t-1)->rodents r=+0.72 — the
#   desert cascade the annual aggregation was hiding.
priors <- tibble::tribble(
  ~from,            ~to,              ~sign, ~lag, ~conf,      ~expected_class,       ~note,
  "temp",           "greenup_doy",     -1L, 0L, "strong",   "temperature-limited", "Warmer springs make plants leaf out earlier — the most reliable rung of the whole cascade, and it holds across most temperate and boreal sites. (Annual mean temperature stands in for spring warmth, which works where temperature is what limits green-up — not in warm deserts, where water is the trigger.)",
  "precip",         "plant_richness",  +1L, 0L, "weak",     "temperature-limited", "More rain can mean more plant growth — but species RICHNESS is a poor stand-in for productivity (it can even FALL in wet years as a few species take over), so this link is weak and its direction varies from place to place.",
  "precip",         "mammal_cpue",     +1L, 1L, "moderate", "temperature-limited", "A wet year grows more food, and a year later small-mammal numbers rise — the classic bottom-up lag, clearest where a single rain season feeds the system.",
  "precip_winter",  "plant_richness",  +1L, 0L, "moderate", "water-limited",       "In deserts the COOL-SEASON (Oct–Mar) rain germinates the spring forbs — so winter rain, not the annual total, is what tracks plant diversity that year. (At Santa Rita this recovers the link the annual number hides.)",
  "precip_monsoon", "mammal_cpue",     +1L, 1L, "strong",   "water-limited",       "Desert granivores (kangaroo rats, pocket mice) track the SUMMER-MONSOON (Jul–Sep) seed crop: a big monsoon grows the seeds, and a year later the seed-eaters boom. Testing the monsoon at a 1-year lag — not annual rain — recovers this link (Santa Rita r≈+0.7).",
  "fruiting_pct",   "mammal_cpue",     +1L, 1L, "weak",     "all",                 "A good fruit-and-seed year should feed the seed-eaters into the next year — but our fruiting signal is a coarse peak-intensity index, so read this as suggestive only, not a measured seed crop.",
  "plant_richness", "mammal_cpue",     +1L, 1L, "weak",     "all",                 "More varied plant communities MIGHT support more animals the next year — the least certain link in the cascade: plant variety is only a rough stand-in for food, so even the direction is uncertain, and the data bears that out.")
# NOTE: no green-up -> bird prior. The trophic-mismatch literature (Both; Visser;
# Mayor 2017; Youngflesh 2021) is about SYNCHRONY between bird breeding and the food
# peak — not "later green-up DOY -> more birds", and the direction reverses by region.
# We can't compute a defensible mismatch from a detection index, so we post no prior
# rather than one the cited literature doesn't support. bird_index still shows on the
# ladder as a descriptive consumer signal.

# ---- per-site biome classification (the throughline) ----
ALL_SITES <- sort(unique(annual$site))
site_meta <- data.frame(
  site        = ALL_SITES,
  biome       = vapply(ALL_SITES, biome_of, character(1)),
  biome_class = vapply(ALL_SITES, biome_class, character(1)),
  biome_label = vapply(ALL_SITES, biome_label, character(1)),
  stringsAsFactors = FALSE)
# producer standing stock (live basal area m2/ha) — per-site context, not an annual signal
veg <- do.call(rbind, lapply(ALL_SITES, ann_veg))
if (!is.null(veg) && nrow(veg)) site_meta <- dplyr::left_join(site_meta, veg, by = "site")
for (c in c("veg_ba_ha","veg_ba_se","veg_type","veg_n_plots"))
  if (!c %in% names(site_meta)) site_meta[[c]] <- if (grepl("type", c)) NA_character_ else NA_real_
cat("\nveg standing stock computed for", sum(is.finite(site_meta$veg_ba_ha)), "of", nrow(site_meta), "sites\n")

# ---- PRECOMPUTE the cross-site scoreboard + pooled result (the honest headline).
# Per-site n=6 is underpowered; pooling each link across the sites where it is EXPECTED
# (one vote per site, binomial sign test) is the defensible suite-level statistic. This
# is also a perf win: the app reads SUITE_LINKS/POOLED from the bundle instead of
# recomputing site_links() (2000 permutations x 7 priors) on every site switch.
cat("\nprecomputing cross-site links (biome-aware)...\n")
suite_links <- do.call(rbind, lapply(ALL_SITES, function(s) {
  a  <- annual[annual$site == s, , drop = FALSE]
  bc <- site_meta$biome_class[site_meta$site == s]
  lk <- site_links(a, priors, biome = bc, nperm = 2000)
  lk$site <- s; lk$biome <- site_meta$biome[site_meta$site == s]; lk$biome_class <- bc
  lk
}))
pooled <- pooled_links(suite_links)
# Carry the pooling-floor flag in the bundle so the server's headline can split the
# multi-site rank from the under-floor (1–2 vote) rows WITHOUT re-deriving the rule
# (a binomial on 1–2 site votes is not a pooled test). pooled_links() already sets
# this; we re-assert it here so a future change to that helper can't silently drop
# the column the server prefers (it falls back to sites>=3 only if absent).
pooled$poolable <- pooled$sites >= 3

meta <- list(built = "annual + seasonal climate signals from sibling bundles + mammal env overlays; biome-aware priors; cross-site precompute",
             n_sites = length(ALL_SITES), built_when = format(Sys.Date()))
dir.create("data", showWarnings = FALSE)
saveRDS(list(annual = annual, signals = signals, priors = priors,
             suite_links = suite_links, pooled = pooled, site_meta = site_meta, meta = meta),
        "data/cascade.rds")

# ---- coverage report ----
cat("\nannual rows:", nrow(annual), "| sites:", length(unique(annual$site)), "\n")
covg <- annual %>% group_by(site) %>% summarise(
  yrs = dplyr::n(), greenup = sum(!is.na(greenup_doy)), plant = sum(!is.na(plant_richness)),
  mammal = sum(!is.na(mammal_cpue)), bird = sum(!is.na(bird_index)), precip = sum(!is.na(precip)),
  layers = (any(!is.na(precip)|!is.na(temp))) + (any(!is.na(greenup_doy))) +
           (any(!is.na(plant_richness)|!is.na(fruiting_pct))) + (any(!is.na(mammal_cpue)|!is.na(bird_index))),
  .groups="drop") %>% arrange(desc(layers), desc(greenup+plant))
cat("\nTop cascade sites (by trophic layers present):\n")
print(as.data.frame(head(covg[covg$layers>=3,], 12)))

cat("\n==== POOLED cross-site result (the honest headline) ====\n")
print(pooled, row.names = FALSE)
cat("\nSRER seasonal columns (the desert fix):\n")
print(as.data.frame(annual[annual$site == "SRER", c("year","precip","precip_winter","precip_monsoon","temp","greenup_doy","plant_richness","mammal_cpue")]), row.names = FALSE)

# ---- refresh the deploy manifest so Connect Cloud serves THIS bundle ----
# A rebuilt-but-unmanifested .rds silently serves stale data (the checksum is pinned).
if (requireNamespace("rsconnect", quietly = TRUE)) {
  try({ rsconnect::writeManifest(); cat("\nmanifest.json regenerated\n") }, silent = TRUE)
} else cat("\n[note] rsconnect not installed — run rsconnect::writeManifest() before deploy\n")
