# ===========================================================================
# NEON Driver Cascade — global.R
# The capstone of the NEONize family: a cross-product synthesis of what drives
# populations, bottom-up — CLIMATE -> GREEN-UP -> PRODUCERS -> CONSUMERS —
# assembled from the five sibling apps' bundles (mammals, birds, plants, veg,
# phenology). Short annual series, so the design STATES PRIORS and is n-gated.
# ===========================================================================
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(bsicons)
  library(dplyr); library(plotly); library(htmltools)
  library(shinyjs); library(shinycssloaders)
})
source("R/site_metadata.R", local = FALSE)
source("R/cascade_helpers.R", local = FALSE)

CASCADE <- tryCatch(readRDS("data/cascade.rds"), error = function(e) NULL)
ANNUAL  <- if (!is.null(CASCADE)) CASCADE$annual  else data.frame()
SIGNALS <- if (!is.null(CASCADE)) CASCADE$signals else data.frame()
PRIORS  <- if (!is.null(CASCADE)) CASCADE$priors  else data.frame()
# precomputed cross-site scoreboard + pooled headline + per-site biome (the throughline)
SUITE_LINKS <- if (!is.null(CASCADE) && !is.null(CASCADE$suite_links)) CASCADE$suite_links else data.frame()
POOLED      <- if (!is.null(CASCADE) && !is.null(CASCADE$pooled))      CASCADE$pooled      else data.frame()
SITE_META   <- if (!is.null(CASCADE) && !is.null(CASCADE$site_meta))   CASCADE$site_meta   else data.frame()
# signals shown on the main ladder (seasonal climate signals are ladder=FALSE)
LADDER_KEYS <- if ("ladder" %in% names(SIGNALS)) SIGNALS$key[SIGNALS$ladder %in% TRUE] else SIGNALS$key

site_annual <- function(site) ANNUAL[ANNUAL$site == site, , drop = FALSE]
site_bclass <- function(site) if (exists("biome_class")) biome_class(site) else "temperature-limited"
site_blabel <- function(site) if (exists("biome_label")) biome_label(site) else "mixed ecosystem"
is_desert   <- function(site) identical(site_bclass(site), "water-limited")
# producer standing stock (live basal area m2/ha) — a slow ~5-yr STATE, per-site context
site_ba     <- function(site) { r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_ha" %in% names(r) && is.finite(r$veg_ba_ha[1])) r$veg_ba_ha[1] else NA_real_ }
site_ba_se  <- function(site) { r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_se" %in% names(r) && is.finite(r$veg_ba_se[1])) r$veg_ba_se[1] else NA_real_ }
# read the precomputed biome-aware links for a site (no live recompute / permutations)
site_links_cached <- function(site) {
  if (nrow(SUITE_LINKS) && "site" %in% names(SUITE_LINKS)) {
    r <- SUITE_LINKS[SUITE_LINKS$site == site, , drop = FALSE]
    if (nrow(r)) return(r)
  }
  site_links(site_annual(site), PRIORS, biome = site_bclass(site))   # fallback
}

# layer count per site (for picker richness) + default to the richest
site_layer_count <- function(site) sum(layers_present(site_annual(site), SIGNALS))
ALL_SITES <- sort(unique(ANNUAL$site))
SITE_LAYERS <- vapply(ALL_SITES, site_layer_count, integer(1))
# sites worth exploring = >=3 trophic layers; default to the richest FULL cascade
# (one that actually has the phenology hinge — that's the point of the app)
RICH_SITES <- ALL_SITES[SITE_LAYERS >= 3]
.has_phen <- function(s) unname(layers_present(site_annual(s), SIGNALS)["phenology"])
DEFAULT_SITE <- {
  full <- ALL_SITES[vapply(ALL_SITES, .has_phen, logical(1)) & SITE_LAYERS >= 4]
  cand <- if (length(full)) full else if (length(RICH_SITES)) RICH_SITES else ALL_SITES
  # Default to SRER — the desert is the Desert Data Labs home turf and the thematic
  # centre of the cascade (the precip→productivity→rodent story is the headline). The
  # Overview leads with the strongest available link + honest framing so the weaker
  # SRER stats don't read as a null. (SCBI carries the one significant link; it's one
  # tap away and called out in the copy.)
  if ("SRER" %in% cand) "SRER" else if ("SCBI" %in% cand) "SCBI" else {
    sc <- vapply(cand, function(s) sum(vapply(SIGNALS$key, function(k) sum(is.finite(site_annual(s)[[k]])), integer(1))), integer(1))
    cand[which.max(sc)] } }

# ---- Desert-night creative system (matches the DDL suite cover) -----------------
# Dark sky + teal/coral/gold. Key NAMES are kept (server.R references DDL$sky etc.),
# only the VALUES are remapped to the desert palette so the charts re-theme with one edit.
DDL <- list(
  navy = "#0e1d40", navy2 = "#16345e", teal = "#2dd4bf", bright = "#5eead4",
  cardinal = "#fb8a7e", coral = "#fb8a7e", gold = "#ffd24a", gold2 = "#e0b43a",
  sky = "#43b8e8", green = "#5fb56a", green2 = "#9bd24a",
  ink = "#eaf2ff", muted = "#9fb0cf", bg = "#070d1f", paper = "#0e1d40", line = "rgba(255,255,255,0.12)")
# Light "desert-day" base (shown if the user toggles light). DARK is the default
# (input_dark_mode mode="dark") and the showcase — the desert-night creative system.
app_theme <- bs_theme(version = 5, bg = "#eef3fb", fg = "#16243a",
  primary = "#149086", secondary = "#e0685a", success = "#3f9a52", info = "#2f8fc4",
  warning = "#d6a31c", danger = "#e0685a",
  base_font = font_google("Rubik"), heading_font = font_google("Rubik"), "border-radius" = "12px")

asset_url <- function(path) { f <- file.path("www", path)
  v <- if (file.exists(f)) as.integer(as.numeric(file.mtime(f))) else 0L; sprintf("%s?v=%s", path, v) }
spin <- function(x, ...) shinycssloaders::withSpinner(x, color = DDL$sky, type = 6)
info_pop <- function(title, ..., placement = "auto")
  bslib::popover(tags$span(class = "info-dot", bsicons::bs_icon("info-circle")), ..., title = title, placement = placement)

# ---- concept glossary: a tappable ⓘ that explains a term in plain English ----
# cpop("trophic") drops a small info dot that pops the definition. Sprinkled on the
# concepts a newcomer hits first (the trophic-layer boxes, lag, z-score, biome…).
CONCEPT <- list(
  trophic   = list(t = "Trophic layer", b = "One rung of the food web — who eats whom. This app stacks four, from the ground up: climate → green-up → producers → consumers."),
  climate   = list(t = "Climate — the driver", b = "The bottom of the cascade: precipitation and temperature, the water and warmth that set what's possible for everything above."),
  phenology = list(t = "Green-up — the hinge", b = "The moment in spring plants leaf out, measured as the day-of-year the first leaves appear. Climate decides WHEN the landscape wakes up, which sets the table for everything that eats plants."),
  producer  = list(t = "Producers — the plants", b = "Plants: their richness, cover, and fruiting. They turn water and warmth into food — the base of the food web."),
  consumer  = list(t = "Consumers — the animals", b = "Small mammals and birds that eat the plants and seeds — the top of this bottom-up chain."),
  lag       = list(t = "A lag", b = "A delay. A 1-year lag means this year's driver shows up in NEXT year's response — rain grows a seed crop that feeds the rodents the following year."),
  zscore    = list(t = "Standardised (z-score)", b = "Each signal is rescaled so 0 = its own average year and +1 = one standard deviation above. Signals in different units can then share one axis — so you compare the TIMING of the bumps, not their heights."),
  biome     = list(t = "Biome class", b = "Whether growth here is limited by warmth (temperate/boreal forest, prairie, tundra) or by water (desert, sagebrush). It decides which driver the cascade should follow — temperature→green-up in the cold, rain→everything in the dry."),
  signmatch = list(t = "Sign-match", b = "Does the data point the direction ecology predicts (not how big)? We tally how many links match — an honest signal even when no single short series is statistically significant."),
  expected  = list(t = "“Expected here”", b = "The link whose mechanism is established for THIS biome (warmth→green-up in forests; the monsoon seed crop→rodents in deserts). Only expected links count toward the site's tally; the rest are shown for context."),
  pulse     = list(t = "The pulse trace", b = "Tap a year and its climate anomaly ripples DOWN the rungs at each link's lag. A rung lights green if it moved the way the prior predicts, red if it went the other way. One traced year is an anecdote — the chips and the cross-site scoreboard are the real evidence."),
  standing  = list(t = "Woody standing stock", b = "Live basal area (m²/ha) — the cross-section of all living woody stems per hectare, directly measured from the Veg-Structure product. It's the slow PRODUCER FLOOR the fast annual signals ride on: ~56 in old-growth forest, ~5 in semi-desert, ~0.4 in true desert. Surveyed on a ~5-year cycle, so it's a standing-stock STATE, not a year-to-year link."))
cpop <- function(key, placement = "auto") { c <- CONCEPT[[key]]; if (is.null(c)) return(NULL)
  bslib::popover(tags$span(class = "concept-i", bsicons::bs_icon("info-circle")), tags$p(c$b), title = c$t, placement = placement) }
insight_banner <- function(icon, ..., tone = "navy")
  div(class = paste("chart-insight", paste0("ci-", tone)), bsicons::bs_icon(icon), div(class = "ci-text", ...))
# section-to-section handoff chip (turns parallel tabs into a guided sequence)
handoff <- function(label, tab) div(class = "tab-handoff",
  tags$a(href = "#", class = "handoff-chip",
    onclick = sprintf("Shiny.setInputValue('gotoTab','%s',{priority:'event'});return false;", tab),
    label, " ", bsicons::bs_icon("arrow-right-circle-fill")))
card_head <- function(icon, title, ...)
  bslib::card_header(class = "with-info", bsicons::bs_icon(icon), tags$span(class = "ch-title", " ", title), ...)
fmt_int <- function(x) format(round(as.numeric(x)), big.mark = ",", trim = TRUE)
sig_label <- function(k) { r <- SIGNALS[SIGNALS$key == k, ]; if (nrow(r)) r$label[1] else k }
sig_unit  <- function(k) { r <- SIGNALS[SIGNALS$key == k, ]; if (nrow(r)) r$unit[1] else "" }
# compact label for the dense cross-site scoreboard
sig_abbr  <- function(k) { m <- c(temp="Temp", precip="Rain", precip_winter="Winter rain",
  precip_monsoon="Monsoon", temp_spring="Spring temp", greenup_doy="Green-up", fruiting_pct="Fruiting",
  plant_richness="Richness", plant_intro_pct="Invasion", mammal_cpue="Rodents", mammal_mnka="Rodents",
  bird_index="Birds", bird_richness="Bird rich."); if (k %in% names(m)) unname(m[k]) else k }

# ---- Pulse Tracer: for a tapped climate year t0, where does its ripple land? ----
# Follows the ANNUAL ladder climate signals (precip, temp) down the prior links. Uses
# the SAME ladder_layer() z-scores the static ladder draws (one z implementation, no
# drift). verdict = did the response at t0+lag move the way the prior predicts, GIVEN
# this year's driver anomaly? predicted response sign = sign(prior_sign * driver_z).
pulse_paths <- function(ann_site, t0) {
  if (is.null(t0) || is.na(t0)) return(NULL)
  z <- do.call(rbind, Filter(Negate(is.null), lapply(c("climate","phenology","producer","consumer"),
        function(L) ladder_layer(ann_site, SIGNALS, L))))
  if (is.null(z) || !nrow(z)) return(NULL)
  zv <- function(key, yr){ v <- z$z[z$key == key & z$year == yr]; if (length(v)) v[1] else NA_real_ }
  climate_keys <- intersect(c("precip","temp"), unique(z$key))   # the ladder's climate signals
  rows <- lapply(seq_len(nrow(PRIORS)), function(i){ pr <- PRIORS[i,]
    if (!(pr$from %in% climate_keys)) return(NULL)
    zf <- zv(pr$from, t0); if (!is.finite(zf)) return(NULL)
    zt <- zv(pr$to, t0 + pr$lag); predicted <- sign(pr$sign * zf)
    verdict <- if (!is.finite(zt)) "nodata" else if (sign(zt) == predicted) "match" else "miss"
    data.frame(from = pr$from, to = pr$to, lag = pr$lag, src_z = round(zf, 2),
               dst_year = t0 + pr$lag, dst_z = if (is.finite(zt)) round(zt, 2) else NA_real_,
               verdict = verdict, stringsAsFactors = FALSE) })
  do.call(rbind, Filter(Negate(is.null), rows))
}

# site dropdown choices, richest-cascade first ("SRER — Santa Rita … (4 layers)")
cascade_site_choices <- function() {
  ord <- order(-SITE_LAYERS, ALL_SITES)
  s <- ALL_SITES[ord]; lay <- SITE_LAYERS[ord]
  nm <- vapply(seq_along(s), function(i) {
    row <- neon_sites[neon_sites$site == s[i], ]
    sprintf("%s — %s · %d layer%s", s[i], if (nrow(row)) row$name[1] else s[i], lay[i], if (lay[i]==1) "" else "s")
  }, character(1))
  stats::setNames(s, nm)
}
