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

DDL <- list(
  navy = "#0C234B", navy2 = "#16386e", cardinal = "#AB0520", gold = "#FFD200",
  gold2 = "#c9a300", sky = "#2f7fb5", green = "#1a7f37", green2 = "#12612a",
  ink = "#1c2733", muted = "#6b7a89", bg = "#eef2f8", paper = "#ffffff", line = "#dbe2ec")
app_theme <- bs_theme(version = 5, bg = "#ffffff", fg = DDL$ink,
  primary = DDL$navy, secondary = DDL$cardinal, success = DDL$green, info = DDL$sky,
  warning = DDL$gold, danger = DDL$cardinal,
  base_font = font_google("Rubik"), heading_font = font_google("Rubik"), "border-radius" = "10px")

asset_url <- function(path) { f <- file.path("www", path)
  v <- if (file.exists(f)) as.integer(as.numeric(file.mtime(f))) else 0L; sprintf("%s?v=%s", path, v) }
spin <- function(x, ...) shinycssloaders::withSpinner(x, color = DDL$sky, type = 6)
info_pop <- function(title, ..., placement = "auto")
  bslib::popover(tags$span(class = "info-dot", bsicons::bs_icon("info-circle")), ..., title = title, placement = placement)
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
