# ===========================================================================
# NEON Driver Cascade — global.R
# The capstone of the NEONize family: a cross-product synthesis of what drives
# populations, bottom-up — CLIMATE -> GREEN-UP -> PRODUCERS -> CONSUMERS —
# assembled from the five sibling apps' bundles (mammals, birds, plants, veg,
# phenology). Short annual series, so the design STATES PRIORS and is n-gated.
# ===========================================================================
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(dplyr)
  library(plotly)
  library(htmltools)
  library(shinyjs)
  library(shinycssloaders)
  library(DT)
})
source("R/site_metadata.R", local = FALSE)
source("R/cascade_helpers.R", local = FALSE)

CASCADE <- tryCatch(readRDS("data/cascade.rds"), error = function(e) NULL)
# Stale-tiered-bundle guard (2026-06): refuse to boot on a bundle whose tier rule does not match
# the running code, so a change to link_stat()'s tier definition can never silently ride on a
# stale precompute (the incident that showed 7 "consistent" cells the circular-shift null no
# longer produces). Rebuild with: Rscript scripts/build_cascade.R
if (!is.null(CASCADE) && exists("TIER_RULE_VERSION")) {
  .bundle_rule <- CASCADE$meta$tier_rule %||% "<unstamped>"
  if (!identical(.bundle_rule, TIER_RULE_VERSION))
    stop(sprintf("cascade.rds tier rule '%s' != code '%s' — rebuild the bundle: Rscript scripts/build_cascade.R",
                 .bundle_rule, TIER_RULE_VERSION), call. = FALSE)
}
ANNUAL <- if (!is.null(CASCADE)) CASCADE$annual else data.frame()
SIGNALS <- if (!is.null(CASCADE)) CASCADE$signals else data.frame()
PRIORS <- if (!is.null(CASCADE)) CASCADE$priors else data.frame()
# Confidence downgrade (live now, also set at source in build_cascade.R): the
# precip_monsoon -> mammal_cpue seed-crop link is literature-strong but in-app THIN
# (one desert site, n=7, p=0.06). Hold its displayed confidence at "moderate" so the
# app never reads thinner-than-shown. Cited as "strong" in the desert literature; the
# downgrade is about what THIS app's data can carry, not the mechanism.
if (nrow(PRIORS) && all(c("from", "to", "conf") %in% names(PRIORS))) PRIORS$conf[PRIORS$from == "precip_monsoon" & PRIORS$to == "mammal_cpue"] <- "moderate"
# precomputed cross-site scoreboard + pooled headline + per-site biome (the throughline)
SUITE_LINKS <- if (!is.null(CASCADE) && !is.null(CASCADE$suite_links)) CASCADE$suite_links else data.frame()
POOLED <- if (!is.null(CASCADE) && !is.null(CASCADE$pooled)) CASCADE$pooled else data.frame()
SITE_META <- if (!is.null(CASCADE) && !is.null(CASCADE$site_meta)) CASCADE$site_meta else data.frame()
# machine-readable codebook (emitted by build_cascade.R from the SIGNALS keep-vector).
# Fall back to deriving the core columns from SIGNALS so a pre-rebuild bundle still
# yields a downloadable codebook (na_meaning/n_gate just blank until the next build).
CODEBOOK <- if (!is.null(CASCADE) && !is.null(CASCADE$codebook)) {
  CASCADE$codebook
} else if (nrow(SIGNALS)) {
  data.frame(
    key = SIGNALS$key, label = SIGNALS$label, layer = SIGNALS$layer,
    unit = SIGNALS$unit, higher_is = SIGNALS$higher_is, na_meaning = NA_character_,
    n_gate = NA_character_, stringsAsFactors = FALSE
  )
} else {
  data.frame()
}
# signals shown on the main ladder (seasonal climate signals are ladder=FALSE)
LADDER_KEYS <- if ("ladder" %in% names(SIGNALS)) SIGNALS$key[SIGNALS$ladder %in% TRUE] else SIGNALS$key

# ---- Search-the-network index (small, bundled, precomputed) ---------------------
# One small .rds loaded ONCE at boot, like site_index in the sibling apps; the Search
# tab filters it in memory (no live fetch, instant). Built by scripts/build_search_index.R
# from the committed cascade bundle. Holds: links (one row per site x prior, with the
# per-site test + biome-expected flag), link_catalog (the autocomplete), site_strength
# (how many expected priors resolve per site), prior_pooled (the honest pooled p).
SEARCH_IDX <- tryCatch(readRDS("data/search_index.rds"), error = function(e) NULL)
SRCH_LINKS <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$links else data.frame()
SRCH_CATALOG <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$link_catalog else data.frame()
SRCH_STR <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$site_strength else data.frame()
SRCH_POOLED <- if (!is.null(SEARCH_IDX)) SEARCH_IDX$prior_pooled else data.frame()
# autocomplete choices: link label -> link_id (richest/most-confident priors first is fine;
# leave alphabetical for findability). Empty-safe.
search_link_choices <- function() {
  if (!nrow(SRCH_CATALOG)) {
    return(character(0))
  }
  stats::setNames(SRCH_CATALOG$link_id, SRCH_CATALOG$link_label)
}
# site short name for the result tables (falls back to the code)
srch_site_name <- function(code) {
  r <- neon_sites[neon_sites$site == code, ]
  if (nrow(r)) r$name[1] else code
}

site_annual <- function(site) ANNUAL[ANNUAL$site == site, , drop = FALSE]
site_bclass <- function(site) if (exists("biome_class")) biome_class(site) else "temperature-limited"
site_blabel <- function(site) if (exists("biome_label")) biome_label(site) else "mixed ecosystem"
is_desert <- function(site) identical(site_bclass(site), "water-limited")
# producer standing stock (live basal area m2/ha) — a slow ~5-yr STATE, per-site context
site_ba <- function(site) {
  r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_ha" %in% names(r) && is.finite(r$veg_ba_ha[1])) r$veg_ba_ha[1] else NA_real_
}
site_ba_se <- function(site) {
  r <- SITE_META[SITE_META$site == site, , drop = FALSE]
  if (nrow(r) && "veg_ba_se" %in% names(r) && is.finite(r$veg_ba_se[1])) r$veg_ba_se[1] else NA_real_
}
# read the precomputed biome-aware links for a site (no live recompute / permutations)
site_links_cached <- function(site) {
  if (nrow(SUITE_LINKS) && "site" %in% names(SUITE_LINKS)) {
    r <- SUITE_LINKS[SUITE_LINKS$site == site, , drop = FALSE]
    if (nrow(r)) {
      return(r)
    }
  }
  site_links(site_annual(site), PRIORS, biome = site_bclass(site)) # fallback
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
  if ("SRER" %in% cand) {
    "SRER"
  } else if ("SCBI" %in% cand) {
    "SCBI"
  } else {
    sc <- vapply(cand, function(s) sum(vapply(SIGNALS$key, function(k) sum(is.finite(site_annual(s)[[k]])), integer(1))), integer(1))
    cand[which.max(sc)]
  }
}

# ---- Desert-night creative system (matches the DDL suite cover) -----------------
# Dark sky + teal/coral/gold. Key NAMES are kept (server.R references DDL$sky etc.),
# only the VALUES are remapped to the desert palette so the charts re-theme with one edit.
DDL <- list(
  navy = "#0e1d40", navy2 = "#16345e", teal = "#2dd4bf", bright = "#5eead4",
  cardinal = "#fb8a7e", coral = "#fb8a7e", gold = "#ffd24a", gold2 = "#e0b43a",
  sky = "#43b8e8", green = "#5fb56a", green2 = "#9bd24a",
  ink = "#eaf2ff", muted = "#9fb0cf", bg = "#070d1f", paper = "#0e1d40", line = "rgba(255,255,255,0.12)"
)
# Light "desert-day" base is the DEFAULT (input_dark_mode mode="light"); the user can
# toggle to the dark desert-night showcase. The navy hero command band stays navy in both.
app_theme <- bs_theme(
  version = 5, bg = "#eef3fb", fg = "#16243a",
  primary = "#149086", secondary = "#e0685a", success = "#3f9a52", info = "#2f8fc4",
  warning = "#d6a31c", danger = "#e0685a",
  base_font = font_google("Rubik"), heading_font = font_google("Rubik"), "border-radius" = "12px"
)

asset_url <- function(path) {
  f <- file.path("www", path)
  v <- if (file.exists(f)) as.integer(as.numeric(file.mtime(f))) else 0L
  sprintf("%s?v=%s", path, v)
}
spin <- function(x, ...) shinycssloaders::withSpinner(x, color = DDL$sky, type = 6)
info_pop <- function(title, ..., placement = "auto") {
  bslib::popover(tags$span(class = "info-dot", bsicons::bs_icon("info-circle")), ..., title = title, placement = placement)
}

# ---- Sources panel: the literature behind every prior + method (About tab) ----
# Folded by default so it informs without overwhelming. Grouped to the priors/methods.
cascade_sources <- function() {
  ref <- function(...) tags$li(htmltools::HTML(paste0(...)))
  grp <- function(title, ...) htmltools::tagList(tags$h6(title), tags$ol(...))
  div(
    class = "about-card", h4(bsicons::bs_icon("journal-text"), " Sources"),
    tags$p(
      class = "src-lead",
      "Every prior's direction and lag, and every inference method, is set from the published literature before the data is touched. The full reference list:"
    ),
    tags$details(
      class = "src-panel",
      tags$summary(bsicons::bs_icon("book"), " Show the reference list"),
      div(
        class = "src-body",
        grp(
          "Bottom-up trophic-cascade framing",
          ref("Power (1992). Top-down and bottom-up forces in food webs. <i>Ecology</i>."),
          ref("Polis, Sears, Huxel, Strong &amp; Maron (2000). When is a trophic cascade a trophic cascade? <i>TREE</i>."),
          ref("Hunter &amp; Price (1992). Playing chutes and ladders: bottom-up and top-down forces. <i>Ecology</i>.")
        ),
        grp(
          "Dryland rain to productivity to granivore pulse (the seasonal-rain priors)",
          ref("Meserve, Kelt, Milstead &amp; Guti&eacute;rrez (2003). Thirteen years of shifting top-down and bottom-up control. <i>BioScience</i>."),
          ref("Previtali, Lima, Meserve, Kelt &amp; Guti&eacute;rrez (2009). Population dynamics of two sympatric rodents in a variable environment. <i>Ecology</i>."),
          ref("Brown &amp; Ernest (2002). Rain and rodents: complex dynamics of desert consumers. <i>BioScience</i>."),
          ref("Ernest, Brown &amp; Parmenter (2000). Rodents, plants, and precipitation. <i>Oikos</i>."),
          ref("Holmgren et al. (2006). Extreme climatic events shape arid and semiarid ecosystems. <i>Front. Ecol. Environ.</i>"),
          ref("Holmgren, Scheffer, Ezcurra, Guti&eacute;rrez &amp; Mohren (2001). El Ni&ntilde;o effects on terrestrial ecosystems. <i>TREE</i>.")
        ),
        grp(
          "Precipitation to plant production / richness",
          ref("Noy-Meir (1973). Desert ecosystems: environment and producers. <i>Annu. Rev. Ecol. Syst.</i>"),
          ref("Huxman et al. (2004). Convergence across biomes to a common rain-use efficiency. <i>Nature</i>.")
        ),
        grp(
          "Temperature / spring warmth to green-up onset (phenology priors)",
          ref("Richardson et al. (2013). Climate change, phenology, and phenological control of vegetation feedbacks. <i>Agric. For. Meteorol.</i>"),
          ref("Cleland, Chuine, Menzel, Mooney &amp; Schwartz (2007). Shifting plant phenology in response to global change. <i>TREE</i>."),
          ref("Piao et al. (2019). Plant phenology and global climate change. <i>Glob. Change Biol.</i>")
        ),
        grp(
          "Temperature / rain to insect (mosquito) emergence",
          ref("Ciota, Matacchiero, Kilpatrick &amp; Kramer (2014). Effect of temperature on life-history traits of Culex mosquitoes. <i>J. Med. Entomol.</i>"),
          ref("Shaman &amp; Day (2007). Reproductive phase locking of mosquito populations in response to rainfall. <i>PLoS ONE</i>.")
        ),
        grp(
          "Why we post NO green-up to bird prior (cited for the absence)",
          ref("Both, Bouwhuis, Lessells &amp; Visser (2006). Climate change and population declines in a migratory bird. <i>Nature</i>."),
          ref("Visser &amp; Both (2005). Shifts in phenology: the need for a yardstick. <i>Proc. R. Soc. B</i>."),
          ref("Cole, Long, Zelazowski, Szulkin &amp; Sheldon (2015). Predicting bird phenology from satellite green-up. <i>Ecol. Evol.</i> (see also Mayor et al. 2017; Youngflesh et al. 2021).")
        ),
        grp(
          "Inference methods",
          ref("Edgington &amp; Onghena (2007). <i>Randomization Tests</i> (4th ed.). Permutation test for tiny-n correlation."),
          ref("Efron &amp; Tibshirani (1993). <i>An Introduction to the Bootstrap</i>. Bootstrap CI for r."),
          ref("Sokal &amp; Rohlf (1995). <i>Biometry</i> (3rd ed.). Binomial sign test for direction agreement."),
          ref("Pickett (1989). Space-for-time substitution. In <i>Long-Term Studies in Ecology</i>."),
          ref("Damgaard (2019). A critique of the space-for-time substitution practice. <i>TREE</i>.")
        ),
        grp(
          "Continental design (NEON macrosystems)",
          ref("Keller, Schimel, Hargrove &amp; Hoffman (2008). A continental strategy for NEON. <i>Front. Ecol. Environ.</i>"),
          ref("Heffernan et al. (2014). Macrosystems ecology. <i>Front. Ecol. Environ.</i>")
        )
      )
    )
  )
}

# ---- the suite huddle: a tiny cluster of sibling mascots (the cascade has no single
# creature, so it gets a "tiny suite" — a consumer, a flier, and a producer — used once
# as a first-visit onboarding nudge in the corner). Flat, no-gradient, reused-safe SVGs. ----
MASCOT_HUDDLE <- htmltools::HTML('<span class="cg-mascots" aria-hidden="true"><svg class="mascot mascot-bird" viewBox="0 0 120 120"><g fill="#f0b94a"><path d="M54,30 L57,16 L62,30 Z"/><path d="M62,30 L65,14 L70,30 Z"/></g><ellipse cx="60" cy="66" rx="32" ry="33" fill="#ffce5a"/><ellipse cx="60" cy="76" rx="19" ry="21" fill="#fff3d6"/><g class="mascot-ear-l"><path d="M30,58 Q14,66 22,86 Q34,80 40,64 Z" fill="#e0714a"/></g><g class="mascot-ear-r"><path d="M90,58 Q106,66 98,86 Q86,80 80,64 Z" fill="#e0714a"/></g><path d="M54,68 L66,68 L60,80 Z" fill="#f0993a"/><g class="mascot-eyes"><circle cx="50" cy="60" r="6.5" fill="#2a160a"/><circle cx="70" cy="60" r="6.5" fill="#2a160a"/><circle cx="48" cy="57.5" r="2.4" fill="#fff"/><circle cx="68" cy="57.5" r="2.4" fill="#fff"/></g></svg><svg class="mascot mascot-mouse" viewBox="0 0 120 120"><g class="mascot-ear-l"><circle cx="42" cy="34" r="14" fill="#5aa0d8"/><circle cx="43" cy="36" r="8" fill="#ffd24a"/></g><g class="mascot-ear-r"><circle cx="78" cy="34" r="14" fill="#5aa0d8"/><circle cx="77" cy="36" r="8" fill="#ffd24a"/></g><path d="M88,82 Q110,94 113,72" fill="none" stroke="#5a93c8" stroke-width="4" stroke-linecap="round"/><ellipse cx="60" cy="66" rx="32" ry="33" fill="#5aa0d8"/><ellipse cx="60" cy="76" rx="20" ry="22" fill="#eaf2ff"/><path d="M55,70 Q60,68 65,70 Q62,77 60,77 Q58,77 55,70 Z" fill="#fb8a7e"/><g class="mascot-eyes"><circle cx="50" cy="60" r="6.5" fill="#0a1a2e"/><circle cx="70" cy="60" r="6.5" fill="#0a1a2e"/><circle cx="48" cy="57.5" r="2.4" fill="#fff"/><circle cx="68" cy="57.5" r="2.4" fill="#fff"/></g></svg><svg class="mascot mascot-sprout" viewBox="0 0 120 120"><path d="M60,60 L60,30" stroke="#4aa050" stroke-width="4" stroke-linecap="round"/><g class="mascot-ear-l"><path d="M60,36 C40,24 24,30 22,46 C40,52 56,46 60,36 Z" fill="#5fd16a"/></g><g class="mascot-ear-r"><path d="M60,36 C80,24 96,30 98,46 C80,52 64,46 60,36 Z" fill="#5fd16a"/></g><ellipse cx="60" cy="76" rx="28" ry="26" fill="#d8cf9e"/><g class="mascot-eyes"><circle cx="51" cy="72" r="6" fill="#3a2a12"/><circle cx="69" cy="72" r="6" fill="#3a2a12"/><circle cx="49" cy="69.5" r="2.2" fill="#fff"/><circle cx="67" cy="69.5" r="2.2" fill="#fff"/></g></svg></span>')

# ---- concept glossary: a tappable ⓘ that explains a term in plain English ----
# cpop("trophic") drops a small info dot that pops the definition. Sprinkled on the
# concepts a newcomer hits first (the trophic-layer boxes, lag, z-score, biome…).
CONCEPT <- list(
  trophic   = list(t = "Trophic layer", b = "One rung of the food web: who eats whom. This app stacks four, from the ground up: climate → green-up → producers → consumers."),
  climate   = list(t = "Climate: the driver", b = "The bottom of the cascade: precipitation and temperature, the water and warmth that set what's possible for everything above."),
  phenology = list(t = "Green-up: the hinge", b = "The moment in spring plants leaf out, measured as the day-of-year the first leaves appear. Climate decides WHEN the landscape wakes up, which sets the table for everything that eats plants."),
  producer  = list(t = "Producers: the plants", b = "Plants: their richness, cover, and fruiting. They turn water and warmth into food, the base of the food web."),
  consumer  = list(t = "Consumers: the animals", b = "Small mammals and birds that eat the plants and seeds, the top of this bottom-up chain."),
  lag       = list(t = "A lag", b = "A delay. A 1-year lag means this year's driver shows up in NEXT year's response: rain grows a seed crop that feeds the rodents the following year. In this app, lag is evaluated on annual site-year summaries; month-level seasonality is represented by separate winter/monsoon and spring-temperature signals."),
  zscore    = list(t = "Standardised (z-score)", b = "Each signal is rescaled so 0 = its own average year and +1 = one standard deviation above. Signals in different units can then share one axis, so you compare the TIMING of the bumps, not their heights."),
  biome     = list(t = "Biome class", b = "Whether growth here is limited by warmth (temperate/boreal forest, prairie, tundra) or by water (desert, sagebrush). It decides which driver the cascade should follow: temperature→green-up in the cold, rain→everything in the dry."),
  signmatch = list(t = "Sign-match", b = "Does the data point the direction ecology predicts (not how big)? We tally how many links match, an honest signal even when no single short series is statistically significant."),
  expected  = list(t = "“Expected here”", b = "The link whose mechanism is established for THIS biome (warmth→green-up in forests; the monsoon seed crop→rodents in deserts). Only expected links count toward the site's tally; the rest are shown for context."),
  pulse     = list(t = "The pulse trace", b = "Tap a year and its climate anomaly ripples DOWN the rungs at each link's lag. A rung lights green if it moved the way the prior predicts, red if it went the other way. One traced year is an anecdote; the chips and the cross-site scoreboard are the real evidence."),
  standing  = list(t = "Woody standing stock", b = "Live basal area (m²/ha), the cross-section of all living woody stems per hectare, directly measured from the Veg-Structure product. It's the slow PRODUCER FLOOR the fast annual signals ride on: ~56 in old-growth forest, ~5 in semi-desert, ~0.4 in true desert. Surveyed on a ~5-year cycle, so it's a standing-stock STATE, not a year-to-year link."),
  permp     = list(t = "The permutation p", b = "A circular-shift null: response years are rotated so the year-to-year autocorrelation is preserved. <b>It has a floor:</b> with N years the smallest possible p is 1/N, so a series this short (N&le;11 here) cannot reach p&lt;0.05 no matter how strong the link, a single short series simply can't be significant on its own. So this p is shown for transparency, not as a per-site significance test, and it does NOT set the verdict. The real significance test is the cross-site pooling on Across NEON."),
  bootci    = list(t = "The bootstrap interval", b = "Bootstrap interval (wide at this n; indicative, not a precision claim). It resamples the few overlapping years to show how unstable the relationship is, not to pin down a precise value.")
)
cpop <- function(key, placement = "auto") {
  c <- CONCEPT[[key]]
  if (is.null(c)) {
    return(NULL)
  }
  bslib::popover(tags$span(class = "concept-i", bsicons::bs_icon("info-circle")), tags$p(c$b), title = c$t, placement = placement)
}
insight_banner <- function(icon, ..., tone = "navy") {
  div(class = paste("chart-insight", paste0("ci-", tone)), bsicons::bs_icon(icon), div(class = "ci-text", ...))
}
# section-to-section handoff chip (turns parallel tabs into a guided sequence)
handoff <- function(label, tab) {
  div(
    class = "tab-handoff",
    tags$a(
      href = "#", class = "handoff-chip",
      onclick = sprintf("Shiny.setInputValue('gotoTab','%s',{priority:'event'});return false;", tab),
      label, " ", bsicons::bs_icon("arrow-right-circle-fill")
    )
  )
}
card_head <- function(icon, title, ...) {
  bslib::card_header(class = "with-info", bsicons::bs_icon(icon), tags$span(class = "ch-title", " ", title), ...)
}
fmt_int <- function(x) format(round(as.numeric(x)), big.mark = ",", trim = TRUE)
sig_label <- function(k) {
  r <- SIGNALS[SIGNALS$key == k, ]
  if (nrow(r)) r$label[1] else k
}
sig_unit <- function(k) {
  r <- SIGNALS[SIGNALS$key == k, ]
  if (nrow(r)) r$unit[1] else ""
}
# compact label for the dense cross-site scoreboard
sig_abbr <- function(k) {
  m <- c(
    temp = "Temp", precip = "Rain", precip_winter = "Winter rain",
    precip_monsoon = "Monsoon", temp_spring = "Spring temp", greenup_doy = "Green-up", fruiting_pct = "Fruiting",
    plant_richness = "Richness", plant_intro_pct = "Invasion", mammal_cpue = "Rodents", mammal_mnka = "Rodents",
    bird_index = "Birds", bird_richness = "Bird rich."
  )
  if (k %in% names(m)) unname(m[k]) else k
}

# ---- Pulse Tracer: for a tapped climate year t0, where does its ripple land? ----
# Follows the ANNUAL ladder climate signals (precip, temp) down the prior links. Uses
# the SAME ladder_layer() z-scores the static ladder draws (one z implementation, no
# drift). verdict = did the response at t0+lag move the way the prior predicts, GIVEN
# this year's driver anomaly? predicted response sign = sign(prior_sign * driver_z).
pulse_paths <- function(ann_site, t0, biome = NULL) {
  if (is.null(t0) || is.na(t0)) {
    return(NULL)
  }
  z <- do.call(rbind, Filter(Negate(is.null), lapply(
    c("climate", "phenology", "producer", "consumer"),
    function(L) ladder_layer(ann_site, SIGNALS, L)
  )))
  if (is.null(z) || !nrow(z)) {
    return(NULL)
  }
  zv <- function(key, yr) {
    v <- z$z[z$key == key & z$year == yr]
    if (length(v)) v[1] else NA_real_
  }
  climate_keys <- intersect(c("precip", "temp"), unique(z$key)) # the ladder's climate signals
  rows <- lapply(seq_len(nrow(PRIORS)), function(i) {
    pr <- PRIORS[i, ]
    if (!is.null(biome) && "expected_class" %in% names(PRIORS)) {
      ec <- PRIORS$expected_class[i]
      if (!is.na(ec) && !(ec %in% c("all", biome))) {
        return(NULL)
      }
    }
    if (!(pr$from %in% climate_keys)) {
      return(NULL)
    }
    zf <- zv(pr$from, t0)
    if (!is.finite(zf)) {
      return(NULL)
    }
    zt <- zv(pr$to, t0 + pr$lag)
    predicted <- sign(pr$sign * zf)
    verdict <- if (!is.finite(zt)) "nodata" else if (sign(zt) == predicted) "match" else "miss"
    data.frame(
      from = pr$from, to = pr$to, lag = pr$lag, src_z = round(zf, 2),
      dst_year = t0 + pr$lag, dst_z = if (is.finite(zt)) round(zt, 2) else NA_real_,
      verdict = verdict, stringsAsFactors = FALSE
    )
  })
  do.call(rbind, Filter(Negate(is.null), rows))
}

# site dropdown choices, richest-cascade first ("SRER — Santa Rita … (4 layers)")
cascade_site_choices <- function() {
  ord <- order(-SITE_LAYERS, ALL_SITES)
  s <- ALL_SITES[ord]
  lay <- SITE_LAYERS[ord]
  nm <- vapply(seq_along(s), function(i) {
    row <- neon_sites[neon_sites$site == s[i], ]
    sprintf("%s · %s · %d layer%s", s[i], if (nrow(row)) row$name[1] else s[i], lay[i], if (lay[i] == 1) "" else "s")
  }, character(1))
  stats::setNames(s, nm)
}
