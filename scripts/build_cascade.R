# ===========================================================================
# NEON Driver Cascade — build_cascade.R
# Assemble a per-site ANNUAL signal table from the five sibling bundles + the
# small-mammal env overlays. Reads existing .rds only — NO neonUtilities, so
# plain R-4.5.x runs it. Output: data/cascade.rds = list(annual, signals,
# priors, sites, meta). Run from the NEON-Driver-Cascade dir.
# ===========================================================================
suppressPackageStartupMessages({ library(dplyr) })
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
    fruiting_pct = if (all(is.na(.data$fruiting_pct))) NA_real_ else round(max(.data$fruiting_pct, na.rm=TRUE),1),
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
  has_status <- "trapStatus" %in% names(d)
  if (has_status) {
    d$is_cap   <- grepl("capture", d$trapStatus, ignore.case = TRUE)
    d$deployed <- !is.na(d$trapStatus) & !grepl("not set", d$trapStatus, ignore.case = TRUE)
  } else { d$is_cap <- TRUE; d$deployed <- TRUE }
  d %>% group_by(year) %>% summarise(
    traps    = sum(.data$deployed),                                    # deployed trap-nights = effort
    captures = sum(.data$is_cap, na.rm = TRUE),
    mammal_mnka = dplyr::n_distinct(.data$tagID[!is.na(.data$tagID) & nzchar(.data$tagID) & .data$is_cap]),
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

# ---- assemble over the union of sites that have mammal or bird data ----
all_sites <- sort(unique(c(sites_in("mammal"), sites_in("bird"))))
cat("assembling", length(all_sites), "sites...\n")
join_all <- function(site) {
  parts <- Filter(Negate(is.null), list(ann_env(site), ann_phe(site), ann_plant(site), ann_mammal(site), ann_bird(site)))
  if (!length(parts)) return(NULL)
  Reduce(function(a,b) full_join(a,b,by=c("site","year")), parts)
}
annual <- bind_rows(lapply(all_sites, join_all))
annual <- annual[!is.na(annual$year) & annual$year >= 2013 & annual$year <= 2025, , drop=FALSE]
annual <- annual %>% arrange(.data$site, .data$year)

# ensure every signal column exists even if no site had it
SIGCOLS <- c("precip","temp","fruiting_pct","greenup_doy","plant_richness","plant_intro_pct","mammal_cpue","mammal_mnka","bird_index","bird_richness")
for (c in SIGCOLS) if (!c %in% names(annual)) annual[[c]] <- NA_real_

# ---- signal metadata: trophic layer + display + direction-of-"more" ----
signals <- tibble::tribble(
  ~key,            ~label,                         ~layer,       ~unit,        ~higher_is,
  "precip",        "Precipitation",                "climate",    "mm/yr",      "wetter",
  "temp",          "Mean temperature",             "climate",    "°C",    "warmer",
  "greenup_doy",   "Green-up onset",               "phenology",  "day-of-year","later",
  "fruiting_pct",  "Peak fruiting",                "producer",   "% plants",   "more fruit",
  "plant_richness","Plant richness",               "producer",   "species",    "more diverse",
  "plant_intro_pct","Introduced plant cover",      "producer",   "% cover",    "more invaded",
  "mammal_cpue",   "Small-mammal catch rate",      "consumer",   "per 100 TN", "more rodents",
  "mammal_mnka",   "Small mammals (indiv.)",       "consumer",   "individuals","more rodents",
  "bird_index",    "Bird detection index",         "consumer",   "birds/point","more birds",
  "bird_richness", "Bird richness",                "consumer",   "species",    "more species")

# ---- literature priors (Sarah's grounded table): expected sign + lag (years) ----
priors <- tibble::tribble(
  ~from,         ~to,            ~sign, ~lag, ~note,
  "precip",      "plant_richness", +1L, 0L,  "ANPP rises with precipitation, strongest in drylands (dryland ANPP~precip review).",
  "precip",      "fruiting_pct",   +1L, 0L,  "Wet years drive flowering/fruiting pulses.",
  "temp",        "greenup_doy",    -1L, 0L,  "Warmer springs advance green-up (earlier DOY) (Cole et al. 2015).",
  "precip",      "mammal_cpue",    +1L, 1L,  "Rain->seed pulse->granivore rodents, lagged & nonlinear (Brown&Ernest; Thibault 2010).",
  "fruiting_pct","mammal_cpue",    +1L, 1L,  "Prior-year seed/fruit production feeds granivores (Owen 2006).",
  "plant_richness","mammal_cpue",  +1L, 1L,  "Producer diversity/productivity -> consumers, lagged.")
# NOTE: no green-up -> bird prior. The trophic-mismatch literature (Both; Visser;
# Mayor 2017; Youngflesh 2021) is about SYNCHRONY between bird breeding and the food
# peak — not "later green-up DOY -> more birds", and the direction reverses by region.
# We can't compute a defensible mismatch from a detection index, so we post no prior
# rather than one the cited literature doesn't support. bird_index still shows on the
# ladder as a descriptive consumer signal.

meta <- list(built = "annual signals from sibling bundles + mammal env overlays",
             n_sites = length(unique(annual$site)))
dir.create("data", showWarnings = FALSE)
saveRDS(list(annual = annual, signals = signals, priors = priors, meta = meta), "data/cascade.rds")

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
cat("\nHARV / SCBI / SRER detail:\n")
print(as.data.frame(annual[annual$site %in% c("HARV","SCBI","SRER"), ]))
