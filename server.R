# ===========================================================================
# NEON Cross-Product Response Atlas — server.R
# ===========================================================================
server <- function(input, output, session) {
  focus_after_update <- function(id = NULL, tab = NULL, delay = 160L) {
    payload <- list(delay = as.integer(delay))
    if (!is.null(id)) payload$id <- id
    if (!is.null(tab)) payload$tab <- tab
    session$sendCustomMessage("cascade-focus", payload)
  }
  export_provenance <- function() {
    sp <- CASCADE$meta$source_products
    source_short <- if (is.data.frame(sp) && nrow(sp))
      paste(sprintf("%s:%s", sp$product, substr(sp$commit, 1L, 12L)), collapse = "; ")
    else "unavailable"
    c(
      sprintf("# Snapshot cutoff: %s (%s)", CASCADE$meta$last_complete_year,
              CASCADE$meta$last_complete_year_basis),
      sprintf("# Bundle built from source state: %s; schema=%s; prior family=%s (%s)",
              CASCADE$meta$built_when, CASCADE$meta$schema_version,
              CASCADE$meta$prior_family_version, CASCADE$meta$prior_family_status),
      sprintf("# Source snapshot method: %s; source inputs=%d; build fingerprint=%s",
              CASCADE$meta$source_snapshot_method %||% "recorded commits and verified input hashes",
              if (is.data.frame(CASCADE$meta$source_inputs)) nrow(CASCADE$meta$source_inputs) else 0L,
              CASCADE$meta$build_script_md5 %||% "unavailable"),
      sprintf("# Source commits: %s", source_short))
  }
  is_dark <- function() identical(input$colorMode, "dark")
  theme_plotly <- function(p) { dark <- is_dark(); ink <- if (dark) "#e8eef2" else "#1f2a30"
    grid <- if (dark) "rgba(220,230,240,0.10)" else "rgba(31,42,48,0.08)"
    p %>% plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
      font=list(color=ink, family = APP_FONT_STACK),
      hoverlabel=list(bgcolor="rgba(11,23,51,0.96)", bordercolor="#2dd4bf", font=list(color="#eaf2ff", family = APP_FONT_STACK, size=12))) %>%
      plotly::config(displayModeBar=FALSE, responsive=TRUE) }
  note_plot <- function(msg) plotly::plot_ly(type="scatter", mode="markers") %>%
    plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", xaxis=list(visible=FALSE), yaxis=list(visible=FALSE),
      annotations=list(list(text=msg, showarrow=FALSE,
        font=list(color=if(is_dark())"#9fb0c4" else "#53606d", family=APP_FONT_STACK, size=14)))) %>%
    theme_plotly()

  ann    <- reactive({ req(input$site); site_annual(input$site) })
  links  <- reactive({ req(input$site); site_links_cached(input$site) })   # precomputed; eligibility is registry-defined
  smatch <- reactive(signmatch_score(links()))
  bclass <- reactive(site_bclass(input$site))
  blabel <- reactive(site_blabel(input$site))
  bgroup <- reactive(if (identical(bclass(), "water-limited")) "dryland-keyword group" else "default other-site group")

  # ---- Pulse Tracer state: the climate year being traced down the ladder ----
  traced <- reactiveVal(NULL)
  observeEvent(input$site, traced(NULL), ignoreInit = TRUE)          # reset on site change
  observeEvent(input$tracedYear, {                                    # set by a ladder dot click (cascade.js onRender)
    y <- suppressWarnings(as.integer(round(as.numeric(input$tracedYear$year))))
    if (is.finite(y)) {
      traced(y)
      updateSelectInput(session, "traceYearPick", selected = as.character(y))
    }
  })
  observeEvent(input$traceYearPick, {
    y <- suppressWarnings(as.integer(input$traceYearPick))
    traced(if (is.finite(y)) y else NULL)
  }, ignoreInit = TRUE)
  observeEvent(input$clearTrace, {
    traced(NULL)
    updateSelectInput(session, "traceYearPick", selected = "")
    focus_after_update(id = "traceYearPick")
  })

  output$traceYearControl <- renderUI({
    a <- ann(); req(nrow(a))
    keys <- intersect(LADDER_KEYS, names(a))
    has_signal <- if (length(keys)) rowSums(is.finite(as.matrix(a[, keys, drop = FALSE]))) > 0 else rep(FALSE, nrow(a))
    yrs <- sort(unique(a$year[has_signal]))
    if (!length(yrs)) return(NULL)
    div(class = "trace-year-control",
      selectInput("traceYearPick", "Keyboard alternative: choose a year to trace",
        choices = c("Choose a year…" = "", stats::setNames(as.character(yrs), yrs)),
        selected = if (is.null(traced())) "" else as.character(traced()),
        selectize = FALSE, width = "100%"))
  })

  # ---- clickable scatter dots: the year being inspected in the Driver Lab ----
  scatterYear <- reactiveVal(NULL)
  observeEvent(input$response, scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$site,     scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$labLink,  scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$scatterYear, {
    y <- suppressWarnings(as.integer(round(as.numeric(input$scatterYear$year))))
    if (is.finite(y)) {
      scatterYear(y)
      focus_after_update(id = "scatterDetailPanel", delay = 220L)
    }
  })
  observeEvent(input$scatterYearPick, {
    y <- suppressWarnings(as.integer(input$scatterYearPick))
    scatterYear(if (is.finite(y)) y else NULL)
    if (is.finite(y)) focus_after_update(id = "scatterDetailPanel", delay = 220L)
  })
  observeEvent(input$clearScatter, {
    scatterYear(NULL)
    focus_after_update(id = "scatterYearPick")
  })

  output$siteBio <- renderUI({ b <- site_bio(input$site); if (is.null(b)) return(NULL)
    div(class="site-bio", bs_icon("info-circle-fill"), span(b)) })

  output$signalChips <- renderUI({ a <- ann(); req(nrow(a))
    have <- LADDER_KEYS[vapply(LADDER_KEYS, function(k) sum(is.finite(a[[k]])) >= 2, logical(1))]
    if (!length(have)) return(div(class="sig-chips-empty", "No multi-year signals here yet."))
    div(class="sig-chips", lapply(have, function(k){ L <- SIGNALS$layer[SIGNALS$key==k]
      span(class=paste0("sig-chip sig-", L), sig_label(k)) })) })

  # ---- hero: ONE auto-written association summary (lead with the answer) ----
  # The sentence is the comprehension fix; the four stat tiles demote to supporting evidence.
  verdict_sentence <- function(site, lk, sm, blab) {
    desert <- identical(site_bclass(site), "water-limited")
    ok <- lk[lk$expected %in% TRUE & lk$n >= 6 & !is.na(lk$sign_match), , drop = FALSE]
    best <- if (nrow(ok)) ok[order(match(ok$tier, c("consistent","apparent","counter","exploratory")),
                                   -abs(ifelse(is.na(ok$r), 0, ok$r))), ][1, ] else NULL
    mon <- lk[lk$from == "precip_monsoon" & lk$to == "mammal_cpue" & is.finite(lk$r), ]
    # Suite-level context: summarize the best-supported row in the complete
    # current literature-motivated family, selected by the displayed Holm value rather than by a
    # hard-coded favourite. This is an ordered summary, not an extra hypothesis.
    gp <- POOLED[(if ("poolable" %in% names(POOLED)) POOLED$poolable %in% TRUE else POOLED$sites >= 3) &
                   is.finite(POOLED$p), , drop = FALSE]
    if (nrow(gp)) {
      ord_p <- if ("p_holm" %in% names(gp)) ifelse(is.finite(gp$p_holm), gp$p_holm, Inf) else rep(Inf, nrow(gp))
      gp <- gp[order(ord_p, gp$p, -gp$sites, gp$from, gp$to), , drop = FALSE][1, , drop = FALSE]
    }
    suite_lead <- if (nrow(gp) && is.finite(gp$p[1])) {
      adj <- if ("p_holm" %in% names(gp) && is.finite(gp$p_holm[1])) gp$p_holm[1] else NA_real_
      prior_row <- PRIORS[PRIORS$from == gp$from[1] & PRIORS$to == gp$to[1] & PRIORS$lag == gp$lag[1], , drop = FALSE]
      direction <- if (nrow(prior_row) && isTRUE(prior_row$sign[1] < 0)) "earlier / less" else "more"
            sprintf("Exploratory cross-site context: the lowest Holm-adjusted direct-association row in the current literature-motivated family is <b>%s &rarr; %s %s</b>, with %d/%d site votes (raw p&nbsp;=&nbsp;%.3f%s)%s. The family evolved alongside inspection of these data, so this is not confirmatory. ",
              sig_label(gp$from[1]), direction, sig_label(gp$to[1]), gp$k[1], gp$sites[1], gp$p[1],
              if (is.finite(adj)) sprintf("; Holm p&nbsp;=&nbsp;%.3f", adj) else "",
              if (is.finite(adj) && adj >= .05) ", but it does not clear the familywise 0.05 threshold" else "")
    } else ""
    lead <- sprintf("<span class='biome-tag biome-%s'>descriptive site group: %s</span> ",
                    if (desert) "water" else "temp", blab)
    group_note <- if (desert) {
      s <- " This site enters the <b>dryland-keyword group</b> under a documented bio-text heuristic—not a measured water-limitation classification. The seasonal panel is an aggregation-sensitivity illustration, not a pooled pathway result."
      ann_mon <- lk[lk$from == "precip" & lk$to == "mammal_cpue" & is.finite(lk$r), ]
      if (nrow(mon) && mon$n[1] >= 3 && mon$r[1] > 0) {
        ptxt <- if (is.finite(mon$p[1])) sprintf(", circular-shift p&nbsp;=&nbsp;%.3f", mon$p[1]) else ""
        atxt <- if (nrow(ann_mon)) sprintf("; annual-rain r&nbsp;=&nbsp;%+.2f", ann_mon$r[1]) else ""
        s <- paste0(s, sprintf(" At <b>this site</b>, the contextual monsoon-to-next-year-rodent pairing is <b>r&nbsp;=&nbsp;%+.2f</b> (n&nbsp;=&nbsp;%d%s%s): an illustrative seasonal contrast, not an inferential vote or a desert-wide result.",
                               mon$r[1], mon$n[1], ptxt, atxt))
      }
      s
    } else ""
    body <- if (!is.null(best) && identical(best$tier, "consistent")) {
      sprintf("%sAt this site, <b>%d of %d</b> testable, vote-eligible direct associations point in their stated direction; <b>%s&nbsp;→&nbsp;%s</b> has r&nbsp;=&nbsp;%+.2f and an interval excluding zero. That is a clean per-site direction—not significance, causation, mediation, or evidence of a trophic chain.%s",
              suite_lead,
              sm$k, sm$n, sig_label(best$from), sig_label(best$to), best$r, group_note)
    } else if (!is.na(sm$n) && sm$n > 0) {
      sprintf("%sOf the vote-eligible direct associations testable here, <b>%d of %d</b> point in their stated direction. These short raw-level series are exploratory; compare the trend sensitivities before interpreting them.%s", suite_lead, sm$k, sm$n, group_note)
    } else {
      paste0(suite_lead, "Not enough overlapping years support a vote-eligible direct association here. The measurements are co-displayed below without a site verdict.", group_note)
    }
    HTML(paste0(lead, body))
  }
  output$heroStats <- renderUI({
    a <- ann(); req(nrow(a)); sm <- smatch(); lk <- links(); lp <- layers_present(a, SIGNALS)
    yrs <- range(a$year[rowSums(!is.na(a[, SIGNALS$key, drop=FALSE])) > 0], na.rm=TRUE)
    row <- neon_sites[neon_sites$site==input$site,]
    compact <- !is.null(input$tabs) && !identical(input$tabs, "overview")
    climate_years <- sum(("temp" %in% names(a) & is.finite(a$temp)) |
                         ("precip" %in% names(a) & is.finite(a$precip)))
    hero <- function(v,l,icon,tone,ttl=NULL) div(class=paste0("hero-stat hero-",tone), title=ttl,
      div(class="hs-icon", bs_icon(icon)), div(div(class="hs-v", v), div(class="hs-l", l)))
    div(class=paste("hero-band", if (compact) "hero-band-compact" else ""),
      div(class="hero-title", bs_icon("diagram-3-fill"), tags$b(sprintf("%s · %s", input$site, if (nrow(row)) row$name[1] else input$site)),
        tags$span(class="hero-sub", sprintf(" · %s–%s", yrs[1], yrs[2])), cpop("biome"),
        # "change site" affordance: the picker lives on the Overview select-panel now,
        # so this hops to Overview and scrolls the panel into view (works on every width).
        tags$a(class="hero-change", href="#sitePanel", `data-cascade-action`="change-site",
          bs_icon("pin-map"), " change site")),
      div(class="hero-verdict", verdict_sentence(input$site, lk, sm, blabel())),
      div(class="hero-grid",
        hero(sum(lp), "measurement layers", icon="layers", tone="navy", ttl="Weather, green-up timing, plant, and animal measurements present here"),
        hero(if (sm$n>0) sprintf("%d/%d", sm$k, sm$n) else "—", "eligible associations agree", icon="check2-circle", tone="pine",
             ttl="Of vote-eligible direct associations, how many point in the stated direction; descriptive only"),
        hero(climate_years, "years with ≥1 complete annual climate signal", icon="cloud-sun", tone="gold",
             ttl="Years with a complete annual temperature or precipitation signal"),
        hero(nrow(a), "years on record", icon="calendar3", tone="terra")))
  })

  output$siteStatus <- renderText({
    a <- ann(); sm <- smatch(); lp <- layers_present(a, SIGNALS)
    sprintf("%s loaded: %d measurement layers; descriptive group %s; %s vote-eligible associations point in the stated direction.", input$site, sum(lp), bgroup(),
            if (sm$n > 0) sprintf("%d of %d", sm$k, sm$n) else "no testable")
  })

  output$overviewInsight <- renderUI({
    sm <- smatch()
    msg <- if (sm$n == 0)
        "Not enough overlapping years support a vote-eligible direct association here. The measurements remain available for inspection; <b>Across NEON</b> shows which associations have enough site votes to summarize."
      else
        sprintf("Across the vote-eligible direct associations, <b>%s</b>. This is a descriptive site tally, not a test of a linked weather→plant→animal pathway.", sm$txt)
    insight_banner("diagram-3", tone = "navy", HTML(msg))
  })

  # Conditional woody-structure context. The source lacks visit effort needed to
  # distinguish sampled-zero from unsampled plots, so this is not a site-wide stock.
  output$standingStock <- renderUI({
    sm <- SITE_META[SITE_META$site == input$site, , drop = FALSE]
    status <- if (nrow(sm) && "veg_design_status" %in% names(sm))
      as.character(sm$veg_design_status[1]) else NA_character_
    if (identical(status, "unsupported-unmatched-plots")) {
      unmatched <- if ("veg_unmatched_record_plots" %in% names(sm))
        sm$veg_unmatched_record_plots[1] else NA_integer_
      records <- if ("veg_unmatched_record_rows" %in% names(sm))
        sm$veg_unmatched_record_rows[1] else NA_integer_
      audit <- if (all(is.finite(c(unmatched, records))))
        sprintf("The reviewed source has %d vegetation records across %d plot IDs with no design-table match.",
                records, unmatched)
      else "The reviewed vegetation records have no matching plot-design support."
      return(div(class = "standing-stock standing-stock-unsupported",
        bs_icon("exclamation-triangle-fill"),
        HTML(" Conditional woody structure: <b>estimate withheld</b>"),
        cpop("standing"),
        tags$span(class = "ss-note", paste(
          audit,
          "No partial subset or area imputation was used; the estimate and classification remain unavailable."))))
    }
    ba <- site_ba(input$site); if (!is.finite(ba)) return(NULL)
    se <- site_ba_se(input$site)
    used <- if (nrow(sm) && "veg_n_plots" %in% names(sm)) sm$veg_n_plots[1] else NA_integer_
    eligible <- if (nrow(sm) && "veg_area_eligible_plots" %in% names(sm)) sm$veg_area_eligible_plots[1] else NA_integer_
    recorded <- if (nrow(sm) && "veg_record_plots" %in% names(sm)) sm$veg_record_plots[1] else NA_integer_
    coverage <- if (all(is.finite(c(used, eligible, recorded))))
      sprintf("%d qualifying-stem plots used; %d area-eligible plots among %d plots with vegetation records.",
              used, eligible, recorded) else "Plot-support denominators are unavailable."
    div(class="standing-stock", bs_icon("tree-fill"),
      HTML(sprintf(" Conditional woody structure: <b>%s m&sup2;/ha</b>%s mean live basal area",
        format(round(ba, 1), nsmall = 1),
        if (is.finite(se)) sprintf(" &plusmn;%s", format(round(se, 1), nsmall = 1)) else "")),
      cpop("standing"),
      tags$span(class = "ss-note", paste0(coverage,
        " Zero-stem and unobserved plots were not imputed; this is structural context, not productivity.")))
  })
  # ---- overview measurement-layer schematic ----
  output$cascadeSchematic <- renderUI({
    a <- ann(); req(nrow(a))
    lay <- list(climate="climate", phenology="phenology", producer="producer", consumer="consumer")
    node <- function(L){ lm <- LAYER_META[[L]]
      ks <- SIGNALS$key[SIGNALS$layer==L & SIGNALS$key %in% LADDER_KEYS]
      have <- ks[vapply(ks, function(k) sum(is.finite(a[[k]]))>=2, logical(1))]
        div(class=paste0("casc-node", if (!length(have)) " casc-empty" else ""),
        div(class=paste("casc-node-h layer-text", paste0("layer-", L)), bs_icon(lm$icon), " ", lm$title, cpop(L)),
        if (length(have)) div(class="casc-sigs", lapply(have, function(k) div(class="casc-sig", sig_label(k))))
        else div(class="casc-sigs", em("no data here"))) }
    sep <- div(class="casc-arrow casc-separator", `aria-hidden`="true", bs_icon("plus-lg"))
    div(class="casc-flow", node("climate"), sep, node("phenology"), sep, node("producer"), sep, node("consumer"))
  })

  output$signalTable <- renderUI({
    a <- ann(); req(nrow(a))
    rows <- lapply(c("climate","phenology","producer","consumer"), function(L){
      ks <- SIGNALS$key[SIGNALS$layer==L & SIGNALS$key %in% LADDER_KEYS]; lm <- LAYER_META[[L]]
      lapply(ks, function(k){ v <- a[[k]]; nf <- sum(is.finite(v)); if (nf < 1) return(NULL)
        yrs <- range(a$year[is.finite(v)])
        tags$tr(tags$td(
            span(class=paste0("sig-dot sig-", L), `aria-hidden`="true"),
            span(class="sig-layer-name", lm$title)),
          tags$td(sig_label(k)),
          tags$td(class="st-unit", sig_unit(k)), tags$td(sprintf("%d yr", nf)),
          tags$td(class="st-yr", sprintf("%s–%s", yrs[1], yrs[2]))) }) })
    rows <- Filter(Negate(is.null), unlist(rows, recursive=FALSE))
    tags$table(class="inspect-tbl sig-tbl",
      tags$caption(class="visually-hidden", "Signal coverage at the selected NEON site"),
      tags$thead(tags$tr(tags$th(scope="col", "Layer"), tags$th(scope="col", "Signal"),
        tags$th(scope="col", "Unit"), tags$th(scope="col", "Coverage"), tags$th(scope="col", "Years"))),
      tags$tbody(rows))
  })

  # ---- Hill diversity profile (q0/q1/q2): the producer-diversity profile a raw richness
  # count can't be — effective species at three weightings, median across this site's years.
  # Descriptive (no prior, not on the ladder); surfaces the q0 vs q1/q2 gap that signals a
  # few-species-dominate community where richness alone would overstate diversity (Hill 1973).
  output$hillProfile <- renderUI({
    a <- ann(); req(nrow(a))
    if (!all(c("plant_q1","plant_q2") %in% names(a))) return(NULL)
    med <- function(v) { v <- v[is.finite(v)]; if (length(v)) stats::median(v) else NA_real_ }
    q0 <- med(a$plant_richness); q1 <- med(a$plant_q1); q2 <- med(a$plant_q2)
    if (!is.finite(q1) && !is.finite(q2)) return(NULL)
    tile <- function(lab, v, sub, hue) div(class = "hill-tile", style = sprintf("--hc: %s;", hue),
      div(class = "hill-v", if (is.finite(v)) format(round(v)) else "—"),
      div(class = "hill-lab", lab), div(class = "hill-sub", sub))
    div(class = "hill-panel",
      div(class = "hill-intro", bs_icon("diagram-2"),
        HTML(" <b>Diversity profile</b> (Hill numbers, median across years): effective species at three weightings. <b>q0</b> counts every species equally (= richness, effort-sensitive); <b>q1</b> weights by commonness (exp-Shannon); <b>q2</b> by dominance (inverse-Simpson). When q1/q2 sit well below q0, a few species dominate, so richness alone overstates diversity.")),
      div(class = "hill-tiles",
        tile("q0", q0, "richness", "var(--sky)"), tile("q1", q1, "exp-Shannon", "var(--pine)"), tile("q2", q2, "inv-Simpson", "var(--terra)")))
  })

  # ---- flagship: the alignment ladder ----
  output$ladderPlot <- renderPlotly({
    a <- ann(); req(nrow(a))
    layers <- c("climate","phenology","producer","consumer")
    dl <- lapply(layers, function(L) ladder_layer(a, SIGNALS, L))
    names(dl) <- layers; present <- layers[vapply(dl, function(x) !is.null(x) && nrow(x)>0, logical(1))]
    if (!length(present)) return(note_plot("No multi-year signals to align at this site"))
    # Per-LAYER hue ramp (honest encoding): every line in a strip shares its layer's
    # colour family (climate=blue, green-up=lime, producers=forest, consumers=cardinal),
    # the SHADE distinguishes signals within the strip. Index resets per strip, so no
    # global counter ever bleeds one layer's hue into another or wraps into a clash.
    LADDER_PAL <- if (is_dark()) list(
      climate   = c("#43b8e8","#2a8fc4","#7fd0f0","#5eb5dc"),
      phenology = c("#9bd24a","#7fb533","#b8e06f","#86bd45"),
      producer  = c("#5fb56a","#86c98e","#4ea85f","#75bd7e"),
      consumer  = c("#fb8a7e","#e86a5e","#ffb0a6","#df7065"))
    else list( # darker light-theme strokes clear the 3:1 graphical-object threshold
      climate   = c("#176b98","#255d86","#0f718d","#355b78"),
      phenology = c("#527d17","#456b13","#5d761c","#386419"),
      producer  = c("#287a3b","#356f3e","#176d35","#486b38"),
      consumer  = c("#b74338","#a64237","#9e4c42","#8f3e36"))
    dark_hex <- function(hex) if (!is_dark()) hex else {     # col2rgb is 0-255; rgb2hsv's default
      hsv <- grDevices::rgb2hsv(grDevices::col2rgb(hex))      # maxColorValue is 255 — do NOT pre-divide
      grDevices::hsv(hsv[1], max(0, hsv[2]*0.82), min(1, hsv[3]*1.1)) }   # ease saturation, gentle lift for dark bg
    # ---- Pulse Tracer highlights for the traced year (built per signal key) ----
    t0 <- traced(); paths <- if (!is.null(t0)) pulse_paths(a, t0, biome = bclass()) else NULL
    hl <- list(); add_hl <- function(key, yr, z, color, sym, lab)
      hl[[key]] <<- rbind(hl[[key]], data.frame(year=yr, z=z, color=color, sym=sym, lab=lab, stringsAsFactors=FALSE))
    pulse_driver_col <- if (is_dark()) "#ffd24a" else "#7a5900"
    pulse_outline <- "#07131f"
    if (!is.null(paths) && nrow(paths)) {
      vcol <- if (is_dark()) c(match="#2dd4bf", miss="#fb8a7e")
              else c(match="#0b6f68", miss="#a6332b")
      for (fk in unique(paths$from)) add_hl(fk, t0, paths$src_z[paths$from==fk][1], pulse_driver_col, "circle",
        sprintf("%s · traced year %d (z=%.2f)", sig_label(fk), t0, paths$src_z[paths$from==fk][1]))
      for (i in seq_len(nrow(paths))) { pr <- paths[i,]
        if (pr$verdict %in% c("nodata", "neutral")) next
        add_hl(pr$to, pr$dst_year, pr$dst_z, unname(vcol[[pr$verdict]]), if (pr$verdict=="match") "circle" else "x",
          sprintf("%s · %d: %s the stated direction (z=%.2f)", sig_label(pr$to), pr$dst_year,
                  if (pr$verdict=="match") "aligned with" else "counter to", pr$dst_z)) }
    }
    plist <- lapply(present, function(L){ dd <- dl[[L]]; lm <- LAYER_META[[L]]
      layer_title_col <- if (is_dark()) lm$col else
        switch(L, climate="#176b98", phenology="#4b7314",
               producer="#287a3b", consumer="#b74338", "#53606d")
      ramp <- LADDER_PAL[[L]] %||% c("#2f7fb5","#16386e","#6db3e0"); j <- 0L
      p <- plotly::plot_ly()
      for (k in unique(dd$key)) { sub <- dd[dd$key==k,]; sub <- sub[order(sub$year),]; j <- j + 1L
        col <- dark_hex(ramp[(j-1) %% length(ramp) + 1])
        dimmed <- if (!is.null(t0)) "rgba(150,160,175,0.55)" else col   # fade base lines while tracing
        nfin <- sum(is.finite(sub$raw))   # surface coverage: a 3-yr z-line must not look as solid as a 12-yr one
        p <- p %>% plotly::add_trace(data=sub, x=~year, y=~z, type="scatter", mode="lines+markers",
          name=sprintf("%s (n=%d)", sub$label[1], nfin), legendgroup=L, line=list(width=2.6, color=if (!is.null(t0)) dimmed else col),
          marker=list(size=6, color=if (!is.null(t0)) dimmed else col),
          hovertemplate=paste0("<b>",sub$label[1],"</b> (n=",nfin,")<br>%{x}: z=%{y:.2f} (",lm$title,")<extra></extra>")) }
      # overlay the pulse highlights for any signal in this strip
      for (k in unique(dd$key)) if (!is.null(hl[[k]])) { h <- hl[[k]]
        p <- p %>% plotly::add_trace(data=h, x=~year, y=~z, type="scatter", mode="markers+text", cliponaxis=FALSE,
          text=~lab, textposition="top center", textfont=list(size=9, color=if(is_dark())"#e8eef2" else "#1f2a30"),
          marker=list(size=16, color=h$color, symbol=h$sym, line=list(color=pulse_outline, width=2)),
          name="pulse", legendgroup=L, showlegend=FALSE, hovertext=h$lab, hoverinfo="text") }
      p %>% plotly::layout(yaxis=list(title=list(text=lm$title, font=list(size=11, color=layer_title_col)),
        zeroline=TRUE, zerolinecolor=if(is_dark())"rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)",
        gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)", tickfont=list(size=9)))
    })
    narrow <- isTRUE((input$vw %||% 1200) < 760)
    sp <- plotly::subplot(plist, nrows=length(present), shareX=TRUE, titleY=TRUE, margin=0.035) %>%
      theme_plotly() %>%
      plotly::layout(showlegend = TRUE, legend=list(orientation="h", y=-0.08, font=list(size=if (narrow) 9 else 10)),
        xaxis=list(title="", dtick=1, gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
        margin = list(l = 60, r = 20, t = 36, b = if (narrow) 110 else 40))
    # capture a dot click -> Shiny input$tracedYear (re-attached on every render; plotly purge wipes handlers)
    htmlwidgets::onRender(sp, "function(el, x){ el.on('plotly_click', function(d){
      if (d && d.points && d.points.length){ var yr = d.points[0].x;
        if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('tracedYear', {year: yr, n: Math.random()}); } }); }")
  })

  output$pulseBanner <- renderUI({
    t0 <- traced()
    if (is.null(t0)) return(div(class="pulse-banner pulse-idle", bs_icon("hand-index-thumb"),
      HTML(" <b>Inspect a climate year:</b> select a dot or use the year selector. Vote-eligible direct climate pairings light at their stated lag: <span class='pulse-key pk-match'>● moved in the stated direction</span> or <span class='pulse-key pk-miss'>✕ moved oppositely</span>. Exact-zero driver or response anomalies abstain and are excluded from the denominator. This is an anecdotal trace, not a recursively inferred food-web path."),
      cpop("pulse")))
    paths <- pulse_paths(ann(), t0, biome = bclass())
    if (is.null(paths) || !nrow(paths)) return(div(class="pulse-banner pulse-active", bs_icon("activity"),
      HTML(sprintf(" <b>Year %d</b> has no annual climate signal to trace here. ", t0)),
      actionLink("clearTrace", tagList(bs_icon("x-circle"), " clear"), class="pulse-clear")))
    k <- sum(paths$verdict == "match")
    tot <- sum(paths$verdict %in% c("match", "miss"))
    nd <- sum(paths$verdict == "nodata")
    abstain <- sum(paths$verdict == "neutral")
    audit <- paste0(
      if (nd > 0) sprintf(" %d had no data that year.", nd) else "",
      if (abstain > 0) sprintf(" %d exact-zero state%s abstained and %s excluded from the denominator.",
                               abstain, if (abstain == 1) "" else "s",
                               if (abstain == 1) "was" else "were") else "")
    div(class="pulse-banner pulse-active", bs_icon("activity"),
      HTML(sprintf(" <b>Inspecting %d:</b> %d of %d directly linked response%s moved in the stated direction.%s <i>One year is an anecdote; inspect the full series, uncertainty, support, and pooled sensitivity summary.</i> ",
        t0, k, tot, if (tot==1) "" else "s", audit)),
      actionLink("clearTrace", tagList(bs_icon("x-circle"), " clear"), class="pulse-clear"))
  })

  # ---- link agreement chips (beside the ladder) ----
  output$linkChips <- renderUI({
    lk <- links(); req(nrow(lk))
    exp <- if ("expected" %in% names(lk)) lk$expected %in% TRUE else rep(TRUE, nrow(lk))
    lk <- lk[order(!exp, match(lk$tier, names(TIER_META))), , drop=FALSE]
    exp <- if ("expected" %in% names(lk)) lk$expected %in% TRUE else rep(TRUE, nrow(lk))
    tagList(
      div(class="link-chips", lapply(seq_len(nrow(lk)), function(i){ r <- lk[i,]; tm <- TIER_META[[r$tier]]
        arrow <- if (r$prior_sign>0) "↑" else "↓"
        div(class=paste0("link-chip lc-", r$tier, if (!exp[i]) " lc-dim" else ""),
          title = if (!exp[i]) "Context only by measurement/construct contract at every site; excluded from all tallies and pooled p-values" else "Vote-eligible at every site with enough support",
          div(class="lc-top", span(class="lc-from", sig_label(r$from)), bs_icon("arrow-right"),
            span(class="lc-to", sig_label(r$to)),
            span(class="lc-lag", if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr"),
            span(class="lc-exp", if (exp[i]) "vote-eligible" else "context only")),
          div(class="lc-mid",
            span(class="lc-prior", sprintf("expect %s", arrow)),
            if (is.finite(r$r)) span(class="lc-r", sprintf("r=%.2f%s", r$r,
              if (is.finite(r$lo)) sprintf(" [%.2f, %.2f]", r$lo, r$hi) else "")) else span(class="lc-r","—"),
            span(class="lc-n", sprintf("n=%d", r$n))),
          div(class=paste("lc-verdict tier-text", paste0("tier-", r$tier)),
            bs_icon(tm$icon), " ", r$verdict)) })),
      p(class="qc-cap-note", style="margin-top:8px", bs_icon("info-circle"),
        HTML(" Hatched, dashed links are <b>context-only at every site</b> because their response window, effort, proxy, or directional basis does not meet the voting contract. Only the temperature–green-up rows are vote-eligible, at every site with enough support.")))
  })

  # ---- Driver Lab ----
  output$labTitle <- renderText(sprintf("What is associated with %s here?", tolower(sig_label(input$response))))

  lab_links <- reactive({ lk <- links(); lk[lk$to == input$response, , drop=FALSE] })

  output$signMatchBanner <- renderUI({
    lk <- lab_links()
    if (!nrow(lk)) return(insight_banner("info-circle", tone="navy", "No literature-motivated driver pairing is catalogued for this response."))
    eligible <- if ("expected" %in% names(lk)) lk$expected %in% TRUE else rep(TRUE, nrow(lk))
    nshow <- lk[eligible & lk$n >= 6 & !is.na(lk$sign_match), , drop=FALSE]
    k <- sum(nshow$sign_match, na.rm=TRUE); tot <- nrow(nshow)
    best <- if (any(eligible & lk$tier=="consistent")) lk[eligible & lk$tier=="consistent",][1,] else NULL
    msg <- if (!any(eligible))
        sprintf("All displayed pairings for <b>%s</b> are <b>context only</b> because their response window, effort, proxy, or directional basis does not support a site vote.", sig_label(input$response))
      else if (!is.null(best)) sprintf("Among vote-eligible direct associations, <b>%s</b> is %s here.", sig_label(best$from), best$verdict)
      else if (tot>0) sprintf("%d of %d vote-eligible direct associations point in the stated direction, but none has an interval excluding zero at this site's short series.", k, tot)
      else "Too few overlapping years to evaluate a vote-eligible direct association here."
    # precip-coverage caveat: only when a rain driver is among the registered pairings here
    has_precip <- any(grepl("^precip", lk$from))
    tagList(
      insight_banner("bullseye", tone = if (!is.null(best)) "pine" else "navy", HTML(msg)),
      if (has_precip) p(class="precip-coverage-note", bs_icon("info-circle"),
        HTML(sprintf(" Complete annual precipitation is available at %d of %d NEON sites; annual-rain pairings are estimable only where all 12 months are present.", N_PRECIP_SITES, length(ALL_SITES)))))
  })

  output$driverTable <- renderUI({
    lk <- lab_links(); if (!nrow(lk)) return(p(class="qc-cap-note","No literature-motivated driver pairing is catalogued for this response."))
    lk <- lk[order(-lk$n, -abs(ifelse(is.na(lk$r),0,lk$r))), ]
    expc <- if ("expected" %in% names(lk)) lk$expected %in% TRUE else rep(TRUE, nrow(lk))
    rows <- lapply(seq_len(nrow(lk)), function(i){ r <- lk[i,]; tm <- TIER_META[[r$tier]]
      arrow <- if (r$prior_sign>0) "↑ +" else "↓ −"
      tags$tr(class = if (!expc[i]) "dt-dim" else NULL,
        tags$td(tags$b(sig_label(r$from)),
          span(class="dt-exp", title=if (expc[i]) "Eligible for the exploratory site-vote summary" else "Context only; excluded from site tallies and pooled inference",
               if (expc[i]) " vote" else " context") ),
        tags$td(class="dt-prior", sprintf("%s, %s", arrow, if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr")),
        tags$td(class="dt-r", if (is.finite(r$r)) sprintf("%.2f", r$r) else "—"),
        tags$td(class="dt-n", r$n),
        tags$td(span(class=paste("dt-chip", paste0("tier-", r$tier)),
          style=sprintf("background:%s;color:%s", tm$col, tm$ink), tm$lab))) })
    div(
      tags$table(class="inspect-tbl driver-tbl",
        tags$caption(class="visually-hidden", "Literature-motivated driver pairings for the selected response"),
        tags$thead(tags$tr(tags$th(scope="col", "Driver / use"), tags$th(scope="col", "Stated direction + lag"),
          tags$th(scope="col", "r"), tags$th(scope="col", "n"), tags$th(scope="col", "Verdict"))),
        tags$tbody(rows)),
      p(class="qc-cap-note", style="margin-top:8px", bs_icon("info-circle"),
        HTML(" Direction and lag settings are literature-motivated and locked for this build, but the family evolved alongside inspection of these data. Rows marked <b>context</b> never enter a site tally or pooled p-value. No verdict below 6 overlapping years. A &lsquo;counter&rsquo; direction can reflect low power, an imperfect proxy, confounding, a shared trend, or a genuinely opposite association; it is not automatically either refutation or noise.")))
  })

  # Explicit pairing selector for the scatter. The former implicit "largest n"
  # choice made other registered drivers effectively unreachable in Driver Lab.
  sel_link <- reactive({
    lk <- lab_links(); lk <- lk[lk$n >= 3, , drop=FALSE]; if (!nrow(lk)) return(NULL)
    ids <- sprintf("%s|%s|%d", lk$from, lk$to, lk$lag)
    chosen <- input$labLink %||% ""
    if (!chosen %in% ids) return(lk[which.max(lk$n), , drop=FALSE])
    lk[match(chosen, ids), , drop=FALSE]
  })
  output$linkScatterHeader <- renderUI({
    lk <- lab_links(); lk <- lk[lk$n >= 3, , drop=FALSE]
    if (!nrow(lk)) return(p(class="qc-cap-note", "No current build-locked pairing has three overlapping years here."))
    ids <- sprintf("%s|%s|%d", lk$from, lk$to, lk$lag)
    use <- ifelse(lk$expected %in% TRUE, "vote-eligible", "context only")
    labels <- sprintf("%s → %s · %s · n=%d", vapply(lk$from, sig_label, character(1)),
                      vapply(lk$to, sig_label, character(1)), use, lk$n)
    selected <- input$labLink %||% ""
    if (!selected %in% ids) selected <- ids[which.max(lk$n)]
    div(class="scatter-link-picker",
      selectInput("labLink", "Pairing shown in the scatter", choices=stats::setNames(ids, labels),
                  selected=selected, width="100%"))
  })

  output$linkScatter <- renderPlotly({
    r <- sel_link(); if (is.null(r)) return(note_plot("No driver has enough overlapping years to plot"))
    m <- lag_pairs(ann(), r$from, r$to, r$lag); if (!nrow(m)) return(note_plot("No overlapping years"))
    tm <- TIER_META[[r$tier]]
    md <- if (nrow(m) >= 7) "markers" else "markers+text"   # avoid year-label collision at n>=7
    point_col <- if (is_dark()) "#43b8e8" else "#126c91"
    point_outline <- if (is_dark()) "#07131f" else "#ffffff"
    fit_gold <- if (is_dark()) DDL$gold2 else "#755500"
    fit_grey <- if (is_dark()) "#9aa6b2" else "#596777"
    p <- plotly::plot_ly(m, x=~x, y=~y, type="scatter", mode=md,
      customdata=~year,
      marker=list(size=11, color=point_col, line=list(color=point_outline, width=1.5)),
      hovertemplate=paste0("year %{customdata} · select for detail<br>",sig_label(r$from),"=%{x}<br>",sig_label(r$to),"=%{y}<extra></extra>"))
    if (identical(md, "markers+text"))
      p <- p %>% plotly::style(text=m$year, textposition="top center",
        textfont=list(size=9, color=if(is_dark())"#9fb0c4" else "#53606d", family=APP_FONT_STACK))
    # tier-honest fit line: GOLD only when the link clears the bar; thin GREY "shape only"
    # for apparent/counter; OMITTED below n=6 (a slope on 5 points is theatre, not evidence)
    if (r$n >= 6 && is.finite(r$r)) { fit <- stats::lm(y ~ x, data=m); xr <- range(m$x)
      consistent <- identical(r$tier, "consistent")
      p <- p %>% plotly::add_lines(x=xr, y=predict(fit, newdata=data.frame(x=xr)), inherit=FALSE,
        line=list(color=if (consistent) fit_gold else fit_grey, width=2, dash="dot"), showlegend=FALSE, hoverinfo="skip") }
    # on-figure stats — so a screenshot of the scatter carries its own evidence
    stat_txt <- if (r$n >= 6 && is.finite(r$r))
        sprintf("r = %+.2f   n = %d   p = %.3f%s", r$r, r$n, r$p,
                if (is.finite(r$lo)) sprintf("\n95%% CI [%.2f, %.2f]", r$lo, r$hi) else "")
      else if (is.finite(r$r)) sprintf("r = %+.2f   n = %d\n(exploratory: too few years for a p)", r$r, r$n)
      else sprintf("n = %d, too few overlapping years to fit", r$n)
    # Precomputed descriptive sensitivities use the exact same contract as the
    # downloadable suite. They never change the raw-level verdict or add p-values.
    if (r$n >= 6 && "r_detrended" %in% names(r) && is.finite(r$r_detrended))
      stat_txt <- paste0(stat_txt, sprintf("\nlinear-year residuals: r = %+.2f (n = %d)",
                                           r$r_detrended, r$n_detrended))
    if (r$n >= 6 && "r_change" %in% names(r) && is.finite(r$r_change))
      stat_txt <- paste0(stat_txt, sprintf("\nconsecutive-year change: r = %+.2f (nΔ = %d)",
                                           r$r_change, r$n_change))
    if (r$n >= 6 && "r_outcome_alt" %in% names(r) && is.finite(r$r_outcome_alt))
      stat_txt <- paste0(stat_txt, sprintf("\nadditive green-up index: r = %+.2f (n = %d)",
                                           r$r_outcome_alt, r$n_outcome_alt))
    tier_plot_col <- if (is_dark()) tm$col else tm$text_col
    anns <- list(list(x=0.02, y=0.98, xref="paper", yref="paper", xanchor="left", yanchor="top",
      text=gsub("\n","<br>", stat_txt), showarrow=FALSE, align="left",
      font=list(size=12, color=tier_plot_col, family = APP_FONT_STACK),
      bgcolor=if(is_dark())"rgba(20,30,45,0.72)" else "rgba(255,255,255,0.88)", bordercolor=tier_plot_col, borderwidth=1, borderpad=4))
    if (!(r$n >= 6 && is.finite(r$r)))
      anns <- c(anns, list(list(x=0.5, y=0.02, xref="paper", yref="paper", xanchor="center", yanchor="bottom",
        text="No trend line below 6 years; read the points, not a slope.", showarrow=FALSE,
        font=list(size=10, color=if(is_dark())"#9fb0c4" else "#53606d"))))
    sp <- p %>% theme_plotly() %>% plotly::layout(showlegend=FALSE, annotations=anns,
      xaxis = list(title = list(text = sprintf("Driver: %s", sig_label(r$from)), standoff = 12), automargin = TRUE),
      yaxis = list(title = list(text = sprintf("Response: %s", sig_label(r$to)), standoff = 14), automargin = TRUE), margin = list(l = 80, r = 20, t = 30, b = 50))
    htmlwidgets::onRender(sp, "function(el, x){ el.on('plotly_click', function(d){
      if (d && d.points && d.points.length){ var yr = d.points[0].customdata;
        if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('scatterYear', {year: yr, n: Math.random()}); } }); }")
  })
  output$linkScatterNote <- renderUI({ r <- sel_link(); if (is.null(r)) return(NULL); tm <- TIER_META[[r$tier]]
    div(class="scatter-note",
      span(sprintf("%s → %s", sig_label(r$from), sig_label(r$to)), style="font-weight:600"),
      if (r$lag>0) span(class="sn-lag", sprintf(" (response %d yr later)", r$lag)),
      div(class=paste("scatter-tier tier-text", paste0("tier-", r$tier)), bs_icon(tm$icon), " ", r$verdict),
      # stat-honesty labels on the two reported numbers (only meaningful once the link is gated)
      if (r$n >= 6 && is.finite(r$p)) div(class="scatter-statcaveats",
        span(class="ssc-item", bs_icon("info-circle"),
          HTML(" <b>p</b> is a permutation null"), cpop("permp"),
          HTML(sprintf(": %d paired years across a %d-year calendar span yield %d valid null shifts and a finite floor of %.3f. It does not set the verdict; Across NEON reports raw and Holm-adjusted site-vote evidence.",
            r$n, r$series_span, r$n_null, r$p_floor)),
          if (is.finite(r$lo)) tagList(HTML(" <b>95% CI</b> is a circular block-bootstrap interval"), cpop("bootci"),
            HTML(": wide at this n, indicative, not a precision claim.")))))
  })
  output$scatterYearPicker <- renderUI({
    r <- sel_link(); if (is.null(r)) return(NULL)
    m <- lag_pairs(ann(), r$from, r$to, r$lag)
    yrs <- sort(unique(suppressWarnings(as.integer(m$year[is.finite(m$year)]))))
    if (!length(yrs)) return(NULL)
    selected <- scatterYear()
    div(class = "scatter-year-control",
      selectInput("scatterYearPick", "Keyboard alternative: inspect a plotted driver year",
        choices = c("Choose a year…" = "", stats::setNames(as.character(yrs), yrs)),
        selected = if (is.null(selected) || !selected %in% yrs) "" else as.character(selected),
        selectize = FALSE, width = "100%"))
  })

  # ---- tap a scatter dot -> that year's full detail ----
  output$scatterDetail <- renderUI({
    yr <- scatterYear(); r <- sel_link(); if (is.null(yr) || is.null(r)) return(NULL)
    a <- ann(); drow <- a[a$year == yr, , drop = FALSE]; if (!nrow(drow)) return(NULL)
    rrow <- a[a$year == (yr + r$lag), , drop = FALSE]
    f <- function(v) if (length(v) == 0 || !is.finite(v)) "—" else format(round(v, 1), big.mark = ",", trim = TRUE)
    dv <- drow[[r$from]][1]; rv <- if (nrow(rrow)) rrow[[r$to]][1] else NA_real_
    sigs <- LADDER_KEYS[vapply(LADDER_KEYS, function(k) length(drow[[k]]) && is.finite(drow[[k]][1]), logical(1))]
    div(id = "scatterDetailPanel", class = "scatter-detail", role = "region",
      tabindex = "-1", `aria-live` = "polite", `aria-atomic` = "true",
      `aria-label` = sprintf("Details for driver year %d at %s", yr, input$site),
      div(class = "sd-head", bs_icon("calendar-event"), tags$b(sprintf(" %d · %s", yr, input$site)),
        actionLink("clearScatter", bs_icon("x-lg"), class = "sd-clear",
                   title = "Close year detail", `aria-label` = "Close year detail")),
      div(class = "sd-pair",
        span(class = "sd-driver", sprintf("%s = %s %s", sig_label(r$from), f(dv), sig_unit(r$from))),
        bs_icon("arrow-right"),
        span(class = "sd-resp", sprintf("%s = %s %s%s", sig_label(r$to), f(rv), sig_unit(r$to),
          if (r$lag > 0) sprintf("  ·  %d", yr + r$lag) else ""))),
      div(class = "sd-sigs", lapply(sigs, function(k)
        span(class = "sd-chip", tags$b(sig_label(k)), sprintf(" %s", f(drow[[k]][1]))))))
  })

  # ============================================================================
  # ---- LAG & SEASON EXPLORER (the Lag Experimenter) --------------------------
  # A FOLDED tool that lets a user re-examine a registered pairing by sliding the lag
  # and toggling annual vs seasonal climate. The max-statistic p accounts for the
  # K-combination search while the interface keeps off-setting results explicitly
  # exploratory; an n<6 hard gate refuses a p. The fixed scorecard / driverTable
  # are untouched — the experimenter never alters them.
  # ============================================================================
  # the registered pairings for the CURRENT response, as "<from> -> <to>" choices
  exp_choices <- reactive({
    lk <- lab_links(); if (!nrow(lk)) return(character(0))
    ids <- sprintf("%s|%s", lk$from, lk$to)
    use <- if ("expected" %in% names(lk)) ifelse(lk$expected %in% TRUE, "vote-eligible", "context only") else "registered"
    nms <- sprintf("%s → %s · %s", vapply(lk$from, sig_label, character(1)),
                   vapply(lk$to, sig_label, character(1)), use)
    stats::setNames(ids, nms)
  })
  output$expLinkUI <- renderUI({
    ch <- exp_choices()
    if (!length(ch)) return(div(class = "le-empty", "No current build-locked driver pairings for this response to explore."))
    sl <- sel_link(); def <- if (!is.null(sl)) sprintf("%s|%s", sl$from, sl$to) else unname(ch[1])
    if (!def %in% ch) def <- unname(ch[1])
    selectInput("expLink", "Current build-locked pairing", choices = ch, selected = def, width = "100%")
  })
  # resolve from/to/prior_lag/prior_sign for the selected link (default = sel_link())
  exp_link <- reactive({
    lk <- lab_links(); if (!nrow(lk)) return(NULL)
    id <- input$expLink
    parts <- if (!is.null(id) && nzchar(id)) strsplit(id, "|", fixed = TRUE)[[1]] else NULL
    r <- if (!is.null(parts) && length(parts) == 2)
           lk[lk$from == parts[1] & lk$to == parts[2], , drop = FALSE] else lk[0, , drop = FALSE]
    if (!nrow(r)) { sl <- sel_link(); if (!is.null(sl)) r <- sl else r <- lk[1, , drop = FALSE] }
    r <- r[1, , drop = FALSE]
    list(from = r$from, to = r$to, prior_lag = r$lag, prior_sign = r$prior_sign,
         expected = if ("expected" %in% names(r)) isTRUE(r$expected) else TRUE,
         conf = if ("conf" %in% names(r)) r$conf else NA_character_)
  })
  climate_family <- function(from) {
    if (from %in% c("precip", "precip_winter", "precip_monsoon")) return("precip")
    if (from %in% c("temp", "temp_spring")) return("temp")
    NULL
  }
  prior_season <- function(from) if (from %in% c("precip_winter", "precip_monsoon", "temp_spring")) "seasonal" else "annual"
  seasonal_col <- function(el) {
    if (el$from %in% c("precip_winter", "precip_monsoon", "temp_spring")) return(el$from)
    exp_driver_col(climate_family(el$from), "seasonal", el$to)
  }
  # Season radios cover both annual priors and priors already expressed on a
  # seasonal column. That keeps the monsoon demo honest: it can compare the
  # actual monsoon prior against annual rain instead of getting stuck on annual.
  output$expSeasonUI <- renderUI({
    el <- exp_link(); if (is.null(el) || is.null(climate_family(el$from))) return(NULL)
    radioButtons("expSeason", "Climate driver",
      c("Annual aggregate" = "annual", "Named seasonal climate window" = "seasonal"),
      selected = prior_season(el$from), inline = TRUE)
  })
  observeEvent(input$expLink, {
    el <- exp_link()
    if (!is.null(el) && !is.null(climate_family(el$from)))
      updateRadioButtons(session, "expSeason", selected = prior_season(el$from))
  }, ignoreInit = TRUE)
  # the candidate set the user can scan (this is K): every lag 0:3 x reachable season
  exp_combos <- reactive({
    el <- exp_link(); if (is.null(el)) return(list())
    seasons <- if (!is.null(climate_family(el$from))) c("annual","seasonal") else "annual"
    cm <- list()
    for (se in seasons) for (L in 0:3) {
      col <- if (se == "annual") climate_family(el$from) %||% el$from else seasonal_col(el)
      cm[[length(cm) + 1L]] <- list(col = col, lag = L)
    }
    cm
  })
  # the SELECTED driver column + its season (annual when the driver isn't climate)
  exp_sel_season <- reactive({
    el <- exp_link(); if (is.null(el)) return("annual")
    if (!is.null(climate_family(el$from))) (input$expSeason %||% prior_season(el$from)) else "annual"
  })
  exp_sel_col <- reactive({ el <- exp_link(); if (is.null(el)) return(NULL)
    if (exp_sel_season() == "annual") climate_family(el$from) %||% el$from else seasonal_col(el) })

  output$expCurve <- renderPlotly({
    el <- exp_link(); if (is.null(el)) return(note_plot("Pick a current build-locked pairing to explore"))
    a <- ann(); col <- exp_sel_col(); to <- el$to
    cur <- exp_curve(a, col, to, 0:3); if (is.null(cur) || !nrow(cur)) return(note_plot("No overlapping years to plot"))
    seasonal <- identical(exp_sel_season(), "seasonal")
    curve_line_col <- if (is_dark()) "#9fb0cf" else "#596777"
    curve_point_col <- if (is_dark()) "#43b8e8" else "#126c91"
    comparison_col <- if (is_dark()) "rgba(159,176,207,0.78)" else "rgba(69,82,96,0.82)"
    registered_col <- if (is_dark()) "#ffd24a" else "#7a5900"
    registered_text_col <- if (is_dark()) "#e0b43a" else "#694c00"
    marker_outline <- "#07131f"
    # Only n>=3 correlations exist; unsupported lags remain explicit gaps.
    solid <- cur[is.finite(cur$r) & cur$n >= 3, , drop = FALSE]
    p <- plotly::plot_ly()
    p <- p %>% plotly::add_trace(data = cur, x = ~lag, y = ~r, type = "scatter", mode = "lines",
      line = list(color = curve_line_col, width = 2, dash = "solid"), name = "r by lag",
      hoverinfo = "skip", showlegend = FALSE, connectgaps = FALSE)
    if (nrow(solid)) p <- p %>% plotly::add_trace(data = solid, x = ~lag, y = ~r, type = "scatter", mode = "markers",
      marker = list(size = 11, color = curve_point_col, line = list(color = marker_outline, width = 1)), name = "estimable (n>=3)",
      text = ~sprintf("lag %d: r=%+.2f (n=%d)", lag, r, n), hoverinfo = "text", showlegend = FALSE)
    # SRER-style overlay: when seasonal, draw the ANNUAL comparison on the same axes.
    if (seasonal) { acur <- exp_curve(a, climate_family(el$from), to, 0:3)
      if (!is.null(acur) && nrow(acur)) p <- p %>% plotly::add_trace(data = acur, x = ~lag, y = ~r,
        type = "scatter", mode = "lines+markers", line = list(color = comparison_col, width = 1.6, dash = "dot"),
        marker = list(size = 6, color = comparison_col), name = "annual driver (comparison)",
        text = ~sprintf("annual, lag %d: r=%s (n=%d)", lag, ifelse(is.finite(r), sprintf("%+.2f", r), "-"), n),
        hoverinfo = "text", showlegend = TRUE) }
    # Mark the registered lag only when the selected driver window is also the
    # registered one. Off-window scans must not relabel the selected curve as current.
    pl <- el$prior_lag
    registered_driver_selected <- identical(col, el$from)
    shp <- list(list(
      type = "line", x0 = -0.2, x1 = 3.2, y0 = 0, y1 = 0, xref = "x", yref = "y",
      line = list(color = if (is_dark()) "rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)", width = 1)))
    anns <- list()
    if (registered_driver_selected) {
      prow <- cur[cur$lag == pl, , drop = FALSE]
      py <- if (nrow(prow) && is.finite(prow$r)) prow$r[1] else 0
      p <- p %>% plotly::add_trace(x = c(pl), y = c(py), type = "scatter", mode = "markers",
        marker = list(size = 18, color = registered_col, symbol = "diamond", line = list(color = marker_outline, width = 1.5)),
        name = "current-family setting", hoverinfo = "text",
        text = sprintf("Current literature-motivated setting: lag %d %s (locked for this build; exploratory)", pl, prior_season(el$from)), showlegend = TRUE)
      shp <- c(shp, list(list(type = "line", x0 = pl, x1 = pl, y0 = -1, y1 = 1, xref = "x", yref = "y",
        line = list(color = registered_col, width = 1.4, dash = "dash"))))
      anns <- list(list(x = pl, y = 1, xref = "x", yref = "y", yanchor = "bottom", xanchor = if (pl >= 2) "right" else "left",
        text = sprintf("Current family: lag %d %s", pl, prior_season(el$from)), showarrow = FALSE,
        font = list(size = 10, color = registered_text_col, family = APP_FONT_STACK)))
    }
    p %>% theme_plotly() %>% plotly::layout(showlegend = TRUE,
      legend = list(orientation = "h", y = -0.22, font = list(size = 10)),
      shapes = shp, annotations = anns,
      xaxis = list(title = "lag (years)", dtick = 1, range = c(-0.3, 3.3),
        gridcolor = if (is_dark()) "rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
      yaxis = list(title = "correlation r", range = c(-1, 1), zeroline = FALSE,
        gridcolor = if (is_dark()) "rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
      margin = list(l = 55, r = 20, t = 24, b = 40))
  })

  output$expReadout <- renderUI({
    el <- exp_link(); if (is.null(el)) return(NULL)
    a <- ann(); to <- el$to; col <- exp_sel_col(); season <- exp_sel_season()
    combos <- exp_combos(); K <- length(combos)
    m <- lag_pairs(a, col, to, input$expLag %||% el$prior_lag); n <- nrow(m)
    observed_r <- if (n >= 3) suppressWarnings(stats::cor(m$x, m$y)) else NA_real_
    observed_r <- if (is.finite(observed_r)) observed_r else NA_real_
    # Exact single-setting circular-shift p. Avoid link_stat() here: its 2,000-draw
    # bootstrap is unrelated to this value and would make a slider interaction slow.
    selected_lag <- input$expLag %||% el$prior_lag
    selected_grid <- if (n >= 6 && is.finite(observed_r)) lag_grid(a, col, to, selected_lag) else NULL
    naive <- if (!is.null(selected_grid))
        perm_circular_result(selected_grid$x, selected_grid$y)$p else NA_real_
    # best-of-K, autocorrelation-preserving adjusted p for the SELECTED (col, lag)
    adj <- if (n >= 6 && is.finite(observed_r)) exp_adj_p(a, to, combos, observed_r) else NA_real_
    # Circular moving-block bootstrap CI on the selected full calendar grid
    # (n>=6 observed pairs). Keeping missing calendar years explicit avoids
    # turning separated observations into artificial neighbours.
    ci <- if (n >= 6 && is.finite(observed_r)) {
        g <- selected_grid
        seed <- stable_link_seed(input$site, col, to, selected_lag, "lag-explorer")
        bs <- with_preserved_rng(seed, function() circular_block_boot_cor(g$x, g$y, reps = 2000L))
        c(lo = unname(round(stats::quantile(bs, 0.025, na.rm = TRUE), 2)),
          hi = unname(round(stats::quantile(bs, 0.975, na.rm = TRUE), 2))) } else c(lo = NA_real_, hi = NA_real_)
    on_prior <- (input$expLag %||% el$prior_lag) == el$prior_lag && identical(col, el$from)
    # Sidak per-comparison cutoff controlling family-wise alpha at 0.05 after K
    # independent looks. (The exact max-statistic adjusted p above is preferred.)
    sidak <- 1 - (1 - 0.05)^(1 / max(K, 1))
    n_ok <- n >= 6
    # ---- setting badge: teal on the registered row vs grey off-setting scan ----
    badge <- if (on_prior)
        span(class = "le-badge le-onprior", bs_icon("lock-fill"),
             if (isTRUE(el$expected)) " build-locked vote setting" else " build-locked context setting")
      else
        span(class = "le-badge le-explored", bs_icon("search"), " EXPLORED: not a verdict")
    # The max-statistic p remains the valid familywise safeguard after selecting
    # among the displayed K combinations. Historical family construction still
    # makes it exploratory, and context-only pairings remain excluded from votes.
    adj_disp <- if (!n_ok)
        span(class = "le-adjp le-ngate", bs_icon("slash-circle"), " n<6: exploratory, no verdict")
      else if (is.na(adj))
        span(class = "le-adjp le-ngate", "p unavailable at this pairing")
      else
        span(class = "le-adjp le-adjp-live", sprintf("p_adj = %.3f", adj))
    rline <- span(class = "le-r",
      if (is.finite(observed_r)) sprintf("r = %+.2f", observed_r) else "r = —",
      span(class = "le-n", sprintf("  n = %d", n)))
    naive_line <- if (n_ok && is.finite(naive))
      div(class = "le-naive", sprintf("unadjusted single-lag p = %.3f", naive),
        span(class = "le-naive-note", " (ignores the other combinations scanned)"))
    ci_line <- if (n_ok && is.finite(ci[["lo"]]))
      div(class = "le-ci", sprintf("block-bootstrap 95%% CI [%.2f, %.2f]", ci[["lo"]], ci[["hi"]]),
        span(class = "le-naive-note", " (wide at this n; indicative, not a precision claim)"))
    sidak_line <- div(class = "le-sidak", bs_icon("shield-exclamation"),
      sprintf(" Sidak reference after K = %d looks: per-look p < %.4f (the max-statistic adjusted p above is the actual safeguard)", max(K, 1), sidak))
    # the desert-demo caption, only when the demo pairing is loaded
    demo_caption <- if (identical(col, "precip_monsoon") && identical(to, "mammal_cpue") &&
                        season == "seasonal" && (input$expLag %||% 0) == 1)
      div(class = "le-demo-caption", bs_icon("brightness-high"),
        HTML(sprintf(" This is the current build-locked <b>seasonal contextual setting</b>, excluded from site votes and pooling. The faint curve is annual rain for comparison. At this site and lag: n=%d%s. The max-statistic p accounts for the displayed lag/season scan, but the broader family was historically data-informed; read the contrast as an illustration, not an established result.",
                     n, if (is.finite(naive)) sprintf(", circular-shift p=%.3f", naive) else "")))
    div(class = paste0("le-readout", if (!on_prior) " le-readout-explored" else ""),
      div(class = "le-headline",
        badge,
        span(class = "le-adjp-label",
          sprintf(" p adjusted for searching K = %d candidates (best-of-K, autocorrelation-preserving): ", max(K, 1))),
        adj_disp),
      div(class = "le-stats", rline, naive_line, ci_line),
      sidak_line,
      if (n_ok && !is.na(adj))
        div(class = "le-offnote",
          if (on_prior && isTRUE(el$expected))
            " The adjusted p protects against selecting among the displayed K settings; it remains exploratory because this association family was historically refined while these data were inspected."
          else if (on_prior)
            " This current build-locked setting is context-only and excluded from all votes and pooled p-values. The adjusted p controls the displayed scan but does not make the pairing inferential."
          else
            " This off-setting result is one of the K displayed combinations; the max-statistic adjustment accounts for that scan. It remains exploratory and does not alter the locked scorecard verdict."),
      demo_caption)
  })

  # the desert demo: jump to precip_monsoon -> mammal_cpue, seasonal, lag 1 (if present)
  observeEvent(input$expDesertDemo, {
    ch <- exp_choices(); target <- "precip_monsoon|mammal_cpue"
    if (target %in% ch) {
      updateSelectInput(session, "expLink", selected = target)
      updateRadioButtons(session, "expSeason", selected = "seasonal")
      updateSliderInput(session, "expLag", value = 1)
    } else {
      showNotification("This pairing needs the small-mammal response. Set 'Driver Lab: explore…' to 'Small-mammal catch rate' on the Overview, then try again.",
        type = "message", duration = 6)
    }
  })

  # ---- QC-flag panel (§7 gold standard): ranked "verify, not wrong" flags for the
  # selected site, behind its own tab (clean by default, never in the Overview). Each
  # flag is a chip that EXPANDS to the exact offending rows on click. ----
  qc <- reactive({ req(input$site); cascade_qc(ann(), links(), SIGNALS, input$site) })
  qc_icon <- function(level) switch(level, high="exclamation-octagon-fill",
    warn="exclamation-triangle-fill", info="info-circle-fill", "check-circle-fill")

  output$qcFlags <- renderUI({
    q <- qc(); qf <- q$flags
    has_real <- length(qf) && !identical(qf[[1]]$level, "clean")
    selected_key <- input$qcInspect %||% ""
    tagList(
      div(class="qc-section-h", bs_icon("clipboard-check"), " Response-atlas data-quality review ",
        tags$span(class="qcf-sub", "· verify, not errors"),
        info_pop("Why these are flags, not bugs",
          p("The atlas uses explicit QC choices: bounded non-left-censored green-up intervals with recurrent-species/composition gates, complete-month climate gates, the within-site MAD temperature filter, and the CI-spans-zero guard on “apparent” rows."),
          p("This panel surfaces ", tags$b("where those rules bit"), " for the selected site, ranked worst-first, so a reader verifies a thin or missing value before reading too much into it. Activate any flag to list the exact rows behind it."))),
      div(class="qc-flags", lapply(qf, function(f){
        clickable <- !identical(f$level, "clean") && f$n > 0
        div(class = paste0("qc-flag qc-flag-", f$level, if (clickable) " qc-flag-click" else ""),
          role = if (clickable) "button" else NULL, tabindex = if (clickable) "0" else NULL,
          `data-shiny-input` = if (clickable) "qcInspect" else NULL,
          `data-shiny-value` = if (clickable) f$key else NULL,
          `aria-label` = if (clickable) sprintf("Inspect %s: %d flagged row%s", f$title, f$n, if (f$n == 1) "" else "s") else NULL,
          `aria-controls` = if (clickable) "qcInspectRegion" else NULL,
          `aria-expanded` = if (clickable) if (identical(selected_key, f$key)) "true" else "false" else NULL,
          bs_icon(qc_icon(f$level)),
          div(class="qcf-body",
            div(class="qcf-title", f$title, if (f$n > 0) tags$span(class="qcf-n", f$n)),
            div(class="qcf-detail", f$detail)),
          if (clickable) tags$span(class="qcf-go", bs_icon("chevron-right"))) })),
      if (has_real) div(class="qcf-hint", bs_icon("hand-index-thumb"),
        " activate a flag to list the exact rows behind it"),
      uiOutput("qcInspectPanel"),
      div(class="qc-toolbar",
        downloadButton("dlQcReport", tagList(bs_icon("filetype-csv"), " Download QC report (CSV)"),
          class="btn-outline-dark btn-sm")))
  })

  # clickable inspector: the exact offending rows for the activated flag
  observeEvent(input$qcInspect, {
    focus_after_update(id = "qcInspectRegion", delay = 220L)
  }, ignoreInit = TRUE)
  output$qcInspectPanel <- renderUI({
    key <- input$qcInspect; q <- qc(); req(!is.null(key), key %in% names(q$sets))
    st <- q$sets[[key]]; req(!is.null(st), nrow(st))
    f <- Filter(function(x) identical(x$key, key), q$flags)[[1]]
    cols <- names(st); head_n <- min(nrow(st), 200L); sv <- st[seq_len(head_n), cols, drop=FALSE]
    fmt <- function(v) if (is.numeric(v)) ifelse(is.na(v), "—", format(round(v, 2), trim=TRUE)) else format(v)
    div(id = "qcInspectRegion", class="qc-inspector", role = "region",
      tabindex = "-1", `aria-live` = "polite", `aria-atomic` = "true",
      `aria-label` = sprintf("Rows behind the %s quality-control flag", f$title),
      div(class="qci-head", bs_icon(qc_icon(f$level)),
        tags$b(sprintf(" %s · %d row%s", f$title, f$n, if (f$n==1) "" else "s"))),
      div(class="qc-cap-scroll", tags$table(class="inspect-tbl",
        tags$caption(class="visually-hidden", sprintf("Exact rows behind the %s quality-control flag", f$title)),
        tags$thead(tags$tr(lapply(cols, function(col) tags$th(scope="col", col)))),
        tags$tbody(lapply(seq_len(nrow(sv)), function(i)
          tags$tr(lapply(cols, function(cc) tags$td(fmt(sv[[cc]][i])))))))),
      if (nrow(st) > head_n) p(class="qc-cap-note", sprintf("Showing first %d of %d.", head_n, nrow(st))))
  })
  output$dlQcReport <- downloadHandler(
    filename = function() sprintf("%s-response-atlas-qc.csv", input$site),
    content = function(file){ rep <- cascade_qc_report(ann(), links(), SIGNALS, input$site)
      if (is.null(rep)) rep <- data.frame(note="No data-quality flags at this site.")
      hdr <- c(sprintf("# NEON Cross-Product Response Atlas · %s data-quality review (verify, not wrong).", input$site),
               "# Each flag is a value worth a second look, not automatically an error; review the documented QC rule and source record.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(rep, file, sep=",", row.names=FALSE, append=TRUE, qmethod="double")) })

  # ---- top-bar Report: the focal site's report card (one self-describing CSV) ----
  # Reuses the existing reactives/helpers: the verdict sentence, the annual signals,
  # the registry-defined link scorecard, and the QC review. Sections are stacked in one
  # file so the export is the site's whole story, not a single table.
  output$dlReport <- downloadHandler(
    filename = function() sprintf("response-atlas-%s-report-card.csv", input$site),
    content = function(file){
      s <- input$site
      row <- neon_sites[neon_sites$site == s, ]
      nm  <- if (nrow(row)) row$name[1] else s
      st  <- if (nrow(row)) row$state[1] else ""
      sm  <- smatch(); lk <- links(); a <- ann()
      verdict <- tryCatch(verdict_sentence(s, lk, sm, blabel()), error = function(e) "")
      # strip any HTML tags the verdict helper may carry, so the CSV stays plain text
      verdict <- gsub("<[^>]+>", "", as.character(verdict))
      con <- file(file, open = "w", encoding = "UTF-8")
      on.exit(close(con))
      writeLines(c(
        sprintf("# NEON Cross-Product Response Atlas - site report card: %s (%s%s)", s, nm,
                if (nzchar(st)) paste0(", ", st) else ""),
        sprintf("# Heuristic site group: %s", site_blabel(s)),
        sprintf("# NEON domain: %s", if (nrow(row)) row$domain[1] else "unknown"),
        sprintf("# Years on record: %d", nrow(a)),
        sprintf("# Vote-eligible associations matching their stated direction: %s",
                if (!is.na(sm$n) && sm$n > 0) sprintf("%d of %d (descriptive within-site tally; links are not independent)",
                  sm$k, sm$n) else "too few overlapping years"),
        sprintf("# Verdict: %s", verdict),
        "# An educational synthesis tool. r-values are within-site only; never read as causation.",
        ""), con)
      writeLines(c(export_provenance(), ""), con)
      # section 1: conditional site context and its denominators
      site_context <- SITE_META[SITE_META$site == s, , drop = FALSE]
      if (nrow(site_context)) {
        writeLines("## Site context (vegetation values are conditional on qualifying-record plots)", con)
        suppressWarnings(utils::write.table(site_context, con, sep = ",", row.names = FALSE, qmethod = "double"))
        writeLines("", con)
      }
      # section 2: annual signals
      writeLines("## Annual signals (one row per year)", con)
      suppressWarnings(utils::write.table(a, con, sep = ",", row.names = FALSE, qmethod = "double"))
      writeLines("", con)
      # section 3: link scorecard
      if (!is.null(lk) && nrow(lk)) {
        writeLines("## Direct-pair scorecard (within-site)", con)
        suppressWarnings(utils::write.table(lk, con, sep = ",", row.names = FALSE, qmethod = "double"))
        writeLines("", con)
      }
      # section 4: QC review (flags are prompts for review, not automatic errors)
      qcrep <- tryCatch(cascade_qc_report(a, lk, SIGNALS, s), error = function(e) NULL)
      writeLines("## Data-quality review (each flag is a prompt to inspect the source/support, not automatically an error)", con)
      if (is.null(qcrep) || !nrow(qcrep))
        writeLines("All clear - no flags at this site.", con)
      else
        suppressWarnings(utils::write.table(qcrep, con, sep = ",", row.names = FALSE, qmethod = "double"))
    })

  # ---- About ----
  output$aboutPanel <- renderUI({
    pr <- PRIORS
    conf_badge <- function(c) {
      col <- switch(c %||% "", strong="#1a6b35", moderate="#e0b43a", weak="#9c2931", "#53606d")
      ink <- if (identical(c, "moderate")) "#2e2406" else "#ffffff"
      tags$span(class="dt-chip", style=sprintf("background:%s;color:%s", col, ink), c %||% "—")
    }
    eligibility_badge <- function(ec) {
      vote <- identical(as.character(ec), "all")
      tags$span(class="dt-chip", style=sprintf("background:%s;color:#fff", if (vote) "#1a6b35" else "#53606d"),
                if (vote) "vote-eligible" else "context only")
    }
    prow <- function(i){ r <- pr[i,]; arrow <- if (r$sign>0) "↑ more → more" else "↓ more → earlier/less"
      tags$tr(tags$td(sig_label(r$from)), tags$td(sig_label(r$to)), tags$td(arrow),
        tags$td(if (r$lag>0) sprintf("%d yr later", r$lag) else "same yr"),
        tags$td(conf_badge(r$conf)), tags$td(eligibility_badge(r$expected_class)), tags$td(class="pr-note", r$note)) }
    gloss <- function(term, def) div(class="gloss-item", tags$b(term), tags$span(HTML(def)))
    div(class="about-wrap",
      div(class="about-card", h3("\U0001F517 What this is"),
        p("The capstone of a family of NEON explorers. Each sibling app dives into one product: small mammals, birds, plant diversity, vegetation structure, plant phenology, mosquitoes, or ground beetles. This one ", tags$b("lines them up"),
          " at shared sites as a ", tags$b("cross-product response atlas"), ": annual weather, plant timing and composition, and animal detection and catch summaries shown on one calendar.")),

      div(class="about-card about-plain", h3(bs_icon("exclamation-triangle"), " Construct status: this does not test a trophic cascade"),
        p(HTML("The current data do <b>not</b> provide a defensible annual productivity or seed-resource signal connecting green-up to consumers, and the analysis does not fit a sequential or mediation model. Most non-phenology pairings are therefore contextual displays, not inferential votes.")),
        p(class="qc-cap-note", "The layered timeline is a co-display of candidate bottom-up pathways. Arrows and visual ordering cannot supply missing producer→consumer rungs, so no page should be read as evidence that a mediated climate→plant→animal chain occurred.")),

      div(class="about-card about-plain", h3(bs_icon("exclamation-diamond"), " Selection status: exploratory, not preregistered"),
        p(HTML(sprintf("The current direction-and-lag family is <b>literature-motivated and locked for this build</b> (<code>%s</code>). Repository history shows that links and seasonal windows evolved while these same data were being inspected. The family therefore was <b>not fixed in advance</b>: correlations, intervals, raw p-values, Holm adjustments, and the companion meta-analysis are all exploratory screens, not confirmatory evidence.", PRIOR_FAMILY_VERSION))),
        p(class="qc-cap-note", "The locked interface prevents additional silent tuning today, and the max-statistic adjustment accounts for the displayed lag/season scan. Neither safeguard can undo historical post-selection. A confirmatory analysis would require a dated immutable registry and genuinely held-out observations.")),

      local({
        m <- CASCADE$meta; sp <- m$source_products
        div(class="about-card about-plain", h3(bs_icon("fingerprint"), " Snapshot and provenance"),
          p(HTML(sprintf("The displayed snapshot ends at <b>%s</b> (<code>%s</code>). Its deterministic source-state timestamp is <code>%s</code>.",
            m$last_complete_year, m$last_complete_year_basis, m$built_when))),
          p(HTML(sprintf("Bundle schema <code>%s</code>; prior family <code>%s</code> (<b>%s</b>); source snapshot <code>%s</code>.",
            m$schema_version, m$prior_family_version, m$prior_family_status,
            m$source_snapshot_method %||% "recorded commits + verified input hashes"))),
          if (is.data.frame(sp) && nrow(sp)) tags$details(
            tags$summary(sprintf("Seven source commits · %d tracked RDS inputs", nrow(m$source_inputs))),
            tags$ul(lapply(seq_len(nrow(sp)), function(i)
              tags$li(tags$code(sp$product[i]), ": ", tags$code(sp$commit[i]), " · ", sp$origin[i]))),
            p(class="qc-cap-note", "The full relative-path input hashes and local build-code fingerprints are stored in the downloadable bundle metadata and repeated in export headers."))
          else p(class="qc-cap-note", "Source provenance is unavailable; this should have failed the runtime contract."))
      }),
      div(class="about-card about-plain", h3(bs_icon("signpost-split"), " Site grouping is a keyword heuristic"),
        p(HTML("The internal <code>water-limited</code>/<code>temperature-limited</code> labels are <b>not measured climate or resource-limitation classes</b>. A one-line site bio containing <code>desert</code>, <code>sagebrush</code>, or <code>semi-desert</code> enters the dryland-keyword group; every other site defaults to the other group.")),
        p(class="qc-cap-note", "Dry forests, semiarid grasslands, Mediterranean systems, and mixed sagebrush–conifer sites can be misgrouped. The current vote-eligible green-up associations include all sites rather than conditioning their p-values on this rule; the grouping remains visible for descriptive context, and its exact basis and method are stored in the bundle.")),

      div(class="about-card about-plain", h3(bs_icon("chat-square-text"), " How to read this, in plain English"),
        p("New to this? Start here. Start with the plain-language definitions; technical terms are defined where they appear."),
        gloss("The big idea", "Weather, plant timing and composition, and animal observations can be aligned on the same calendar. This app evaluates selected <b>direct pairwise associations</b>; it does not estimate a sequential weather→plant→animal pathway."),
        gloss("Green-up timing index", "A DOY-anchored, composition-adjusted index built from bounded, non-left-censored onset-interval midpoint estimates. Each repeatedly observed species is centered on its own across-year timing before species are weighted equally. A smaller value means earlier relative green-up, but it is not a literal pooled median date. Excluding first-visit-already-yes records avoids treating upper bounds as dates; it is <b>not</b> an interval-censored model and can select on monitoring start and visit cadence. Interval-width diagnostics remain visible in the export and QC panel. This is a retrospective full-panel standardization: recurrence, connectivity, species centers, and additive year effects are refit at refresh, so newly eligible observations can revise historical index values. Snapshot hashes preserve the exact published version."),
        gloss("A “lag”", "A calendar offset. A <b>1-year lag</b> pairs this year's driver with <em>next</em> year's response. The offset encodes a proposed pathway; this observational screen does not prove that pathway."),
        gloss("Catch rate (per 100 trap-nights)", "How many small mammals were caught for every 100 trap-nights of effort. It accounts for how hard we trapped, so years compare fairly, but it's a <b>relative index, not a true headcount</b>."),
        gloss("The layered timeline", "Each strip is one measurement layer, drawn on a <b>standardised</b> within-signal scale: <b>0 = that signal's own average year</b>, up = above average, down = below. Compare timing, not heights. Stacking is a visual co-display, not a mediation test."),
        gloss("Why deserts expose aggregation problems", "Desert ecology depends strongly on <b>when</b> rain falls. Winter rain and the summer monsoon support different pathways, so combining them into one annual total can hide or reverse a relationship. The current desert sample is thin; this is a measurement lesson, not a desert-wide result.")),

      div(class="about-card about-plain", h3(bs_icon("calculator"), " The statistics, in plain English"),
        gloss("“Could this be luck?” (the circular-shift test)", "For each link we rotate the response over its full calendar grid, retaining missing years. That preserves order, annual spacing, and the gap pattern while breaking the original alignment. The exact finite floor is <b>1/(valid null shifts + 1)</b> and is reported for each link. This coarse p is transparency, not a per-site significance claim."),
        gloss("The uncertainty band (95% CI)", "An indicative range from a circular moving-block bootstrap, which resamples contiguous wrapped year blocks to retain short-range temporal structure. With only ~6 years it is often <b>very wide</b>; it diagnoses instability rather than promising precision."),
        gloss("“Too few years to judge”", "Below <b>6 overlapping years</b> we show the lined-up data but give <b>no verdict</b>; there simply isn't enough to tell signal from noise."),
        gloss("The direction verdicts", "<b>Aligned</b> = points in the stated direction <em>and</em> the block-bootstrap interval excludes zero (a clean per-site direction, not significance). <b>Apparent</b> = same direction but the interval crosses zero. <b>No usable direction</b> = an effectively zero or undefined correlation; neither casts a vote. <b>Counter</b> = opposite direction. Across-site exact-binomial p-values are one-sided against 0.5 sign symmetry and shown raw plus Holm-adjusted for vote-eligible rows."),
        gloss("Sign-match score", "Of the vote-eligible links with at least 6 years, how many point in the stated literature-motivated direction. Within one site this is a <b>descriptive tally only</b>, because links share years and variables. The cross-site sign screen gives one site vote to one current literature-motivated link at a time; its p-values remain exploratory because the family was not preregistered."),
        p(class="qc-cap-note", bs_icon("info-circle"), " We never say a driver “causes” anything; a handful of yearly points cannot prove cause. These are exploratory direct-association screens, not proof of a mechanism or a trophic chain.")),

      local({
        meta <- CASCADE_META
        gp <- if (!is.null(meta)) Filter(function(x) isTRUE(x$poolable), meta) else list()
        div(class = "about-card about-plain", h3(bs_icon("graph-up-arrow"), " Companion screen: meta-analysis of temperature–green-up associations"),
          p(HTML("The cross-site table uses an exact <b>binomial sign calculation</b> (how many sites agree in direction), with Holm adjustment across its current poolable family. For temperature&ndash;green-up rows meeting the five-site minimum, a <b>random-effects meta-analysis</b> summarizes per-site correlations. It is an exploratory effect-size sensitivity analysis, not evidence of a broader cascade and not a way to make the historically selected family confirmatory.")),
          if (length(gp)) tags$ul(class = "meta-list", lapply(gp, function(r) { rma <- r$rma
            ts <- r$trend_sensitivity; es <- r$estimator_sensitivity; ss <- r$spatial_sensitivity
            sensitivity <- if (!is.null(ts) && !is.null(es) && !is.null(ss)) sprintf(
              "; direction sensitivity: residuals %d/%d, consecutive changes %d/%d, additive green-up index %d/%d, NEON-domain majorities %d/%d%s",
              ts$detrended$k, ts$detrended$sites, ts$change$k, ts$change$sites,
              es$outcome_alt$k, es$outcome_alt$sites, ss$k_domain, ss$domains,
              if (ss$domain_ties > 0) sprintf(" (+%d tied)", ss$domain_ties) else "") else ""
            tags$li(HTML(sprintf("<b>%s &rarr; %s</b>: raw-level direction %s%s%s",
              sig_label(r$from), sig_label(r$to), r$sign_match, sensitivity,
              if (!is.null(rma)) sprintf(paste0(
                "; REML + Knapp&ndash;Hartung pooled r = %+.2f (95%% CI [%.2f, %.2f])",
                "; 95%% prediction interval [%.2f, %.2f]; I&sup2; = %.0f%%",
                "; raw one-sided p = %.3g; Holm p = %.3g (k = %d sites, df = %d)"),
                rma$pooled_r, rma$ci_r[1], rma$ci_r[2], rma$pi_r[1], rma$pi_r[2],
                rma$I2, rma$p_one_sided, rma$p_one_sided_holm, rma$k, rma$df)
              else " (the validated companion contains no effect-size estimate for this row)"))) }))
          else p(class = "qc-cap-note", bs_icon("info-circle"),
            "No association met the companion meta-analysis eligibility contract in this snapshot."),
          p(class = "qc-cap-note", "The prediction interval and heterogeneity lead interpretation; the directional p-values are secondary. Knapp-Hartung inference reflects the small site sample, and Holm adjustment covers both eligible temperature-green-up rows. The Fisher-z sampling variance still assumes effectively independent paired years and does not model within-site serial dependence. The entire companion remains exploratory, is not a posterior probability, and does not upgrade any per-site verdict."))
      }),

      div(class="about-card", h3(bs_icon("shield-check"), " What the safeguards do—and do not do"),
        tags$ul(
          tags$li(HTML("<b>Limits additional tuning in this build.</b> The current literature-motivated scorecard setting is locked in the interface. The Lag Explorer shows every scanned alternative and uses a max-statistic adjustment. The family itself nevertheless evolved during data inspection, so neither route is confirmatory.")),
          tags$li(HTML("<b>n-gated.</b> Below 6 overlapping years, no verdict. At n&ge;6 the circular block-bootstrap interval sets a per-site DIRECTION verdict; the circular-shift p is transparency only. Across-site exact-binomial p-values are shown both raw and Holm-adjusted.")),
          tags$li(HTML("<b>Honest about scope.</b> Several of these mechanisms are clearest <em>across regions</em> or in <em>deserts</em>; testing them within one site, year-to-year, is the hardest case, and the notes say so.")),
          tags$li(HTML("<b>Direction over magnitude</b>, and <b>never “drives”/“causes.”</b>")))),

      div(class="about-card", h3(bs_icon("diagram-3"), " The current literature-motivated association family"),
        tags$table(class="inspect-tbl",
          tags$caption(class="visually-hidden", "Current exploratory literature-motivated direct associations"),
          tags$thead(tags$tr(tags$th(scope="col", "Driver"), tags$th(scope="col", "Response"),
          tags$th(scope="col", "Stated direction"), tags$th(scope="col", "Lag"),
            tags$th(scope="col", "Literature basis"), tags$th(scope="col", "Analysis use"), tags$th(scope="col", "In plain English"))),
          tags$tbody(lapply(seq_len(nrow(pr)), prow))),
        p(class="qc-cap-note", style="margin-top:8px", HTML("Sources: warmer-springs→earlier green-up · <b>Fu et al. 2015</b> (<i>Nature</i>), Richardson et al. 2013; rain→desert rodents (lagged, non-linear) · <b>Brown &amp; Ernest 2002</b>, Thibault et al. 2010; rain-timing · Zhang et al. 2021; dryland productivity~precipitation · Sala et al. 1988, Huxman et al. 2004, Knapp et al. 2017; the “green wave” · Merkle et al. 2016. A green-up→bird link is <b>deliberately omitted</b>: the mismatch literature is about timing-synchrony, not “later green-up → more birds.”"))),

      div(class="about-card", h3(bs_icon("database"), " Data & honest limits"),
        p("Per-site annual signals assembled from seven sibling apps' bundles plus the NEON-tower climate overlays. ",
          tags$b("Small-mammal catch rate"), " is a relative annual index (captures per 100 deployed trap-nights), not effort-standardised across sites, so read within-site trends only. ",
          tags$b("Temperature"), " is either a complete annual average or a complete March–May average. Neither is guaranteed to precede the green-up events it is paired with, so both are contemporaneous proxies rather than trigger measurements. ",
          tags$b("Plant richness"), " is composition, not productivity. Beetle effort is observed only for catch-bearing events, so beetle indices are descriptive and cannot cast inferential votes. Other non-green-up links likewise remain contextual until their response windows, effort, and directional basis support stronger use."),
        p(bs_icon("envelope"), " ", tags$a(href="mailto:desertdatalabs@gmail.com","desertdatalabs@gmail.com"))),

      div(class="about-card", h3(bs_icon("table"), " Codebook & data downloads"),
        p("Every signal, its units, how it's derived, and the n-gates, plus analysis-ready CSV exports."),
        uiOutput("codebook")),

      cascade_sources(),

      div(class="about-card", h3(bs_icon("award"), " Data attribution & license"),
        p(class="qc-cap-note",
          "Built with data from the National Ecological Observatory Network (NEON), a U.S. National Science Foundation program operated by Battelle. NEON data are provided under a Creative Commons Attribution 4.0 International (CC BY 4.0) license (",
          tags$a(href="https://creativecommons.org/licenses/by/4.0/", target="_blank", rel="noopener", "creativecommons.org/licenses/by/4.0"),
          "). This app aggregates and derives summary metrics from the raw NEON data products; the underlying measurements are unaltered. It is an independent, unofficial tool and is not endorsed by NEON, Battelle, or the NSF."),
        p(class="qc-cap-note", style="margin-top:6px",
          "A multi-product synthesis joining: small mammals (DP1.10072.001), breeding birds (DP1.10003.001), plant diversity (DP1.10058.001), vegetation structure (DP1.10098.001), plant phenology (DP1.10055.001), mosquitoes (DP1.10043.001), ground beetles (DP1.10022.001), and NEON climate overlays (air temperature DP1.00002.001, precipitation DP1.00044.001), each provided under CC BY 4.0.")))
  })
  # ---- SEASONAL CLIMATE reveal (the desert insight made visible) ----
  output$seasonalPlot <- renderPlotly({
    a <- ann(); req(nrow(a))
    if (!is_desert(input$site)) return(note_plot("The winter/monsoon illustration is shown only for sites in the descriptive dryland-keyword group."))
    d <- a[is.finite(a$precip_winter) | is.finite(a$precip_monsoon), c("year","precip_winter","precip_monsoon")]
    if (!nrow(d)) return(note_plot("No seasonal precipitation reconstructed for this site yet."))
    winter_col <- if (is_dark()) "#43b8e8" else "#126c91"
    monsoon_col <- if (is_dark()) "#ffd24a" else "#7a5900"
    plotly::plot_ly(d, x=~year) %>%
      plotly::add_bars(y=~precip_winter, name="Winter rain (Oct–Mar)", marker=list(color=winter_col)) %>%
      plotly::add_bars(y=~precip_monsoon, name="Monsoon rain (Jul–Sep)", marker=list(color=monsoon_col)) %>%
      theme_plotly() %>% plotly::layout(barmode="group", legend=list(orientation="h", y=-0.22),
        yaxis=list(title="precipitation (mm)"), xaxis=list(title="", dtick=1), margin=list(l=55,r=20,t=10,b=40))
  })
  output$seasonalPanel <- renderUI({
    if (!is_desert(input$site)) return(div(class="seasonal-note", bs_icon("info-circle"),
      HTML(" This site is not classified in the descriptive dryland-keyword group, so the winter/monsoon illustration is hidden. That heuristic does not establish how many ecologically relevant rain seasons the site has, and no pathway test is implied.")))
    a <- ann()
    # Return r, n, and the same circular-shift p used everywhere else. Numbers
    # are computed for the selected site—never copied from SRER into other sites.
    rc <- function(from,to,lag){
      if (!all(c(from,to) %in% names(a))) return(list(r=NA_real_, n=0L, p=NA_real_))
      g <- lag_grid(a, from, to, lag)
      m <- if (nrow(g)) g[is.finite(g$x) & is.finite(g$y), , drop=FALSE] else g
      if (nrow(m) < 3) return(list(r=NA_real_, n=nrow(m), p=NA_real_))
      r <- suppressWarnings(stats::cor(m$x, m$y))
      prm <- if (nrow(m) >= 6 && is.finite(r)) perm_circular_result(g$x, g$y) else list(p=NA_real_)
      list(r=if (is.finite(r)) round(r, 2) else NA_real_, n=nrow(m),
           p=prm$p)
    }
    ann_mam <- rc("precip","mammal_cpue",1);  mon_mam <- rc("precip_monsoon","mammal_cpue",1)
    ann_rich <- rc("precip","plant_richness",0); win_rich <- rc("precip_winter","plant_richness",0)
    rv <- function(x) if (is.na(x$r)) "—" else sprintf("r = %+.2f", x$r)
    rn <- function(x) if (x$n > 0) span(class="sc-n", sprintf(" n=%d", x$n)) else NULL
    # CVD: the contrast between the weak (annual) and strong (seasonal) r must NOT rest on
    # colour alone (the two greens sit near 1.2:1 luminance). Pair the STRONG value with a
    # non-colour cue (up-arrow + a "stronger" chip), and carry the honest stats (n + the
    # p where it's the headline monsoon link) right on the number, never colour-only.
    cmp <- function(lab, a1, lab1, a2, lab2) {
      p_lab <- if (!is.na(a2$r) && is.finite(a2$p))
        span(class="sc-p", sprintf(" p=%.3f", a2$p)) else NULL
      is_stronger <- is.finite(a1$r) && is.finite(a2$r) && abs(a2$r) > abs(a1$r)
      strong_cue <- if (is_stronger)
        span(class="sc-stronger", bs_icon("arrow-up-short"), "stronger") else NULL
      div(class="seasonal-cmp",
        div(class="sc-title", lab),
        div(class="sc-row", span(class="sc-k", lab1), span(class="sc-v sc-weak", rv(a1), rn(a1))),
        div(class="sc-row", span(class="sc-k", lab2),
          span(class="sc-v sc-strong", rv(a2), rn(a2), p_lab, strong_cue)))
    }
    mon_detail <- if (is.finite(mon_mam$r)) sprintf(
      "At %s, monsoon rain → next-year rodents is r=%+.2f at n=%d%s.", input$site,
      mon_mam$r, mon_mam$n, if (is.finite(mon_mam$p)) sprintf(", circular-shift p=%.3f", mon_mam$p) else "")
      else sprintf("At %s, the monsoon-to-rodent pairing has too few overlapping years to estimate.", input$site)
    div(
      insight_banner("droplet-half", tone="navy", HTML("A single <b>annual</b> rainfall number can blend ecologically distinct seasons. The selected site's winter and monsoon contrasts show whether season choice changes the apparent relationship:"),
        info_pop("Illustrative single-site contrast", HTML(paste0(mon_detail, " Read these as short-series illustrations of aggregation sensitivity, not a desert-wide result. The exploratory cross-site direction summary is on the Across&nbsp;NEON tab.")))),
      div(class="seasonal-cmps",
        cmp("Rain → next-year rodents", ann_mam, "annual rain", mon_mam, "monsoon rain"),
        cmp("Rain → plant richness", ann_rich, "annual rain", win_rich, "winter (forb) rain")),
      p(class="precip-coverage-note", bs_icon("info-circle"),
        HTML(sprintf(" Complete annual precipitation is available at %d of %d NEON sites; annual-rain pairings are estimable only where all 12 months are present.", N_PRECIP_SITES, length(ALL_SITES)))))
  })

  # ---- ACROSS NEON: pooled headline + cross-site sign-match scoreboard ----
  output$pooledHeadline <- renderUI({
    pl <- POOLED; if (!nrow(pl)) return(NULL)
    # HARD floor: a binomial on 1–2 votes is not a pooled test (one vote always reads
    # 1/1, p=0.500). Such links must NOT sit in the headline rank beside broadly
    # supported rows—split them out and demote them to a p-less footnote row.
    MIN_SITES <- 3L
    is_context <- if ("expected_class" %in% names(pl)) pl$expected_class == "none" else rep(FALSE, nrow(pl))
    context <- pl[is_context, , drop=FALSE]
    eligible <- pl[!is_context, , drop=FALSE]
    poolable <- if ("poolable" %in% names(eligible)) eligible$poolable %in% TRUE else eligible$sites >= MIN_SITES
    rank <- eligible[poolable, , drop=FALSE]; under <- eligible[!poolable, , drop=FALSE]
    if (!"p_holm" %in% names(rank)) rank$p_holm <- NA_real_
    if (!"p_fdr" %in% names(rank)) rank$p_fdr <- NA_real_
    rank <- rank[order(ifelse(is.finite(rank$p_holm), rank$p_holm, Inf), rank$p), , drop=FALSE]
    n_family <- sum(is.finite(rank$p))
    items <- lapply(seq_len(nrow(rank)), function(i){ r <- rank[i,]
      sig <- is.finite(r$p_holm) && r$p_holm < 0.05
      div(class=paste0("pooled-row", if (sig) " pooled-sig" else ""),
        div(class="pl-link", HTML(sprintf("%s&nbsp;→&nbsp;%s", sig_label(r$from), sig_label(r$to))),
            if (r$lag>0) span(class="pl-lag", sprintf(" lag %dy", r$lag))),
        div(class="pl-bar-wrap", div(class="pl-bar", style=sprintf("width:%.0f%%", 100*r$k/r$sites))),
        div(class="pl-stat", tags$b(sprintf("%d/%d sites", r$k, r$sites)),
            span(class="pl-p", sprintf("raw p=%.3f", r$p)),
            if (is.finite(r$p_holm)) span(class="pl-padj", sprintf("Holm p=%.3f", r$p_holm)),
            span(class="pl-r", sprintf("median r=%+.2f", r$median_r)),
            if ("sites_detrended" %in% names(r) && is.finite(r$sites_detrended) && r$sites_detrended > 0)
              span(class="pl-sens", sprintf("detrended direction %d/%d", r$k_detrended, r$sites_detrended)),
            if ("sites_change" %in% names(r) && is.finite(r$sites_change) && r$sites_change > 0)
              span(class="pl-sens", sprintf("consecutive-change direction %d/%d", r$k_change, r$sites_change)),
            if ("sites_outcome_alt" %in% names(r) && is.finite(r$sites_outcome_alt) && r$sites_outcome_alt > 0)
              span(class="pl-sens", sprintf("additive green-up direction %d/%d", r$k_outcome_alt, r$sites_outcome_alt)),
            if ("domains" %in% names(r) && is.finite(r$domains) && r$domains > 0)
              span(class="pl-sens", sprintf("NEON-domain majority %d/%d%s", r$k_domain, r$domains,
                if (is.finite(r$domain_ties) && r$domain_ties > 0) sprintf(" (+%d tied)", r$domain_ties) else ""))))
    })
    # under-floor links: shown demoted, no p-value, with a one-click "why?" caveat.
    under_rows <- if (nrow(under)) lapply(seq_len(nrow(under)), function(i){ r <- under[i,]
      div(class="pooled-row pooled-underfloor",
        div(class="pl-link", HTML(sprintf("%s&nbsp;→&nbsp;%s", sig_label(r$from), sig_label(r$to))),
            if (r$lag>0) span(class="pl-lag", sprintf(" lag %dy", r$lag))),
        div(class="pl-stat", span(class="pl-notpool", sprintf("%d site%s · not poolable", r$sites, if (r$sites==1) "" else "s")),
            if (is.finite(r$median_r)) span(class="pl-r", sprintf("median r=%+.2f", r$median_r))))
    }) else NULL
    context_rows <- if (nrow(context)) lapply(seq_len(nrow(context)), function(i){ r <- context[i,]
      div(class="pooled-row pooled-underfloor",
        div(class="pl-link", HTML(sprintf("%s&nbsp;→&nbsp;%s", sig_label(r$from), sig_label(r$to))),
            if (r$lag>0) span(class="pl-lag", sprintf(" lag %dy", r$lag))),
        div(class="pl-stat", span(class="pl-notpool", "context only by design · excluded from pooling")))
    }) else NULL
    # The eligible association is screened with annual and spring-only temperature.
    # Report raw and multiplicity-adjusted values; never promote the minimum row
    # from a displayed family as though it were the only hypothesis.
    gp_ann <- pl[pl$from=="temp"        & pl$to=="greenup_doy", , drop=FALSE]
    gp_spr <- pl[pl$from=="temp_spring" & pl$to=="greenup_doy", , drop=FALSE]
    tension <- if (nrow(gp_ann) && nrow(gp_spr) && is.finite(gp_ann$p[1]) && is.finite(gp_spr$p[1]))
      HTML(sprintf(" The same literature-motivated association tested with two climate proxies carries a caveat: <b>annual mean temperature</b> gives %d/%d agreeing sites (raw p=%.3f%s), while the <b>March&ndash;May temperature window</b> gives %d/%d (raw p=%.3f%s). Neither is guaranteed to precede an individual green-up event; treat the contrast as a coverage/proxy sensitivity, not a clean mechanistic test.",
        gp_ann$k[1], gp_ann$sites[1], gp_ann$p[1],
        if ("p_holm" %in% names(gp_ann) && is.finite(gp_ann$p_holm[1])) sprintf(", Holm p=%.3f", gp_ann$p_holm[1]) else "",
        gp_spr$k[1], gp_spr$sites[1], gp_spr$p[1],
        if ("p_holm" %in% names(gp_spr) && is.finite(gp_spr$p_holm[1])) sprintf(", Holm p=%.3f", gp_spr$p_holm[1]) else ""))
      else NULL
    any_familywise <- any(is.finite(rank$p_holm) & rank$p_holm < .05)
    headline <- if (any_familywise)
      sprintf("Across %d vote-eligible direct associations, Holm-adjusted direction rows below 0.05 are highlighted. Because this family evolved alongside inspection of these data, those values remain exploratory; compare the residual, consecutive-change, alternate-green-up, and NEON-domain-majority direction counts before interpretation.", n_family)
    else sprintf("Across %d vote-eligible direct associations, no Holm-adjusted direction row is below 0.05. The family was not preregistered, and trend, outcome-construction, or spatial-clustering sensitivities can differ, so this is an exploratory association screen.", n_family)
    div(insight_banner("clipboard-data", tone="pine",
      HTML(headline)),
      p(class="qc-cap-note pooled-s4t", style="margin-top:8px", bs_icon("info-circle"),
        HTML(sprintf(" <b>Pooled across sites, not years.</b> Each vote-eligible temperature–green-up pairing is screened at every site with enough support, then raw-level direction votes are counted. The exact-binomial p is <b>one-sided against 0.5 sign symmetry</b>; Holm-adjusted values cover the %d eligible rows. Residual, consecutive-change, alternate-outcome, and NEON-domain-majority counts are descriptive sensitivities, not extra p-values. The raw calculation treats sites as independent even though sites in one domain can share climate and history; the domain count collapses the same raw votes to one majority per NEON domain, with 50/50 domains abstaining. Context-only plant/animal rows never enter the family.", n_family))),
      if (!is.null(tension)) p(class="pooled-tension", bs_icon("exclamation-triangle"), tension),
      div(class="pooled-list", items),
      if (!is.null(under_rows)) div(class="pooled-under",
        div(class="pu-head", "Below the pooling floor (<3 sites)",
          info_pop("Not a pooled test", HTML("This app sets a conservative reporting floor of <b>3 site votes</b>; one or two votes are too fragile to rank beside multi-site patterns (and 1/1 has p=0.500). These links remain visible <b>without a p-value</b>. The floor is a presentation safeguard, not a claim that three sites suddenly provide strong evidence."))),
        under_rows),
      if (!is.null(context_rows)) div(class="pooled-under pooled-context",
        div(class="pu-head", "Context-only pairings (excluded from inference)",
          info_pop("Why these are not pooled", HTML("These rows remain inspectable at every site, but their effort denominator, temporal window, proxy, or directional basis does not satisfy the current inferential contract. More site-years alone would <b>not</b> make them poolable; the measurement must first be redesigned."))),
        context_rows))
  })
  output$scoreboard <- renderUI({
    sl <- SUITE_LINKS; if (!nrow(sl)) return(p(class="qc-cap-note","Scoreboard unavailable (rebuild the data bundle)."))
    pr <- PRIORS
    hd <- lapply(seq_len(nrow(pr)), function(j) tags$th(class="sb-col", scope="col",
      title=sprintf("%s → %s%s", sig_label(pr$from[j]), sig_label(pr$to[j]), if(pr$lag[j]>0) sprintf(" (lag %dy)", pr$lag[j]) else ""),
      HTML(sprintf("%s<br>→ %s", sig_abbr(pr$from[j]), sig_abbr(pr$to[j])))))
    sm <- SITE_META
    sm$em <- vapply(sm$site, function(s){ d <- sl[sl$site==s & sl$expected %in% TRUE & sl$n>=6 & !is.na(sl$sign_match),]; sum(d$sign_match) }, numeric(1))
    # testable-link count (the denominator behind em): expected links with n>=6 and a known sign
    sm$ntest <- vapply(sm$site, function(s){ sum(sl$site==s & sl$expected %in% TRUE & sl$n>=6 & !is.na(sl$sign_match)) }, numeric(1))
    sm$ba_sort <- if ("veg_ba_ha" %in% names(sm)) ifelse(is.finite(sm$veg_ba_ha), sm$veg_ba_ha, -Inf) else rep(-Inf, nrow(sm))
    sm <- switch(input$sbSort %||% "default",
      abc      = sm[order(sm$site), , drop=FALSE],                       # A-Z lookup
      agree    = sm[order(-sm$em, -sm$ntest, sm$site), , drop=FALSE],     # descriptive direction agreement
      coverage = sm[order(-sm$ntest, -sm$em, sm$site), , drop=FALSE],     # richest-data sites first
      ba       = sm[order(-sm$ba_sort, sm$site), , drop=FALSE],           # conditional sampled-plot woody BA; context only
      sm[order(sm$biome_class, -sm$em, sm$site), , drop=FALSE])           # default: biome, then agreement
    rowfor <- function(s, blab){
      cells <- lapply(seq_len(nrow(pr)), function(j){
        d <- sl[sl$site==s & sl$from==pr$from[j] & sl$to==pr$to[j] & sl$lag==pr$lag[j], , drop=FALSE]
        if (!nrow(d)) return(tags$td(class="sb-cell sb-na"))
        tm <- TIER_META[[d$tier[1]]]; exp <- isTRUE(d$expected[1])
        ttl <- sprintf("%s · %s → %s: %s (n=%d%s)", s, sig_label(pr$from[j]), sig_label(pr$to[j]), d$verdict[1], d$n[1], if (is.finite(d$r[1])) sprintf(", r=%.2f", d$r[1]) else "")
        if (!exp) ttl <- paste0(ttl, ". CONTEXT ONLY at every site by measurement/construct contract; excluded from site tallies and pooled inference regardless of direction.")
        else ttl <- paste0(ttl, ". Vote-eligible at every site with enough support.")
        # CVD: the verdict must not be COLOUR-ONLY (teal/coral fail red-green). Prefix the
        # cell with a tier glyph so shape always travels with the colour (Tufte; Okabe-Ito).
        gly <- switch(d$tier[1], consistent="✓", apparent="≈",
                      neutral=if (is.finite(d$r[1])) "0" else "—",
                      counter="✗", exploratory="·", "")
        cell_txt <- if (is.finite(d$r[1])) {
          if (nzchar(gly)) sprintf("%s %+.2f", gly, d$r[1]) else sprintf("%+.2f", d$r[1])
        } else if (nzchar(gly)) gly else "·"
        tags$td(class=paste0("sb-cell sb-clk sb-", d$tier[1], if (!exp) " sb-dim" else ""),
          title=ttl,
          role="button", tabindex="0", `aria-label`=ttl,
          `data-shiny-input`="sbCell",
          `data-shiny-value`=sprintf("%s|%s|%s|%d", s, pr$from[j], pr$to[j], pr$lag[j]),
          cell_txt)
      })
      ba <- site_ba(s)
      tags$tr(tags$th(class="sb-site", scope="row",
        tags$a(href="#", class="sb-sitelink", `data-shiny-input`="goSite", `data-shiny-value`=s,
          `aria-label`=sprintf("Open site %s", s), s),
        tags$div(class="sb-biome", blab,
          if (is.finite(ba)) tags$span(class="sb-ba", title="conditional mean live basal area among qualifying-record plots", sprintf(" · %s m²/ha", format(round(ba,1), nsmall=1))))), cells)
    }
    rows <- lapply(seq_len(nrow(sm)), function(i) rowfor(sm$site[i], sm$biome_label[i]))
    tagList(
      tags$table(class="sb-table",
        tags$caption(class="visually-hidden", "Driver-to-response direction verdicts by NEON site"),
        tags$thead(tags$tr(tags$th(class="sb-site", scope="col", "Site"), hd)),
        tags$tbody(rows)),
      p(class="qc-cap-note", style="margin-top:10px", bs_icon("info-circle"),
        HTML(" Each cell shows a <b>verdict glyph</b> and the <b>correlation r</b> for that direct pairing at that site: <span class='sb-key sb-consistent'>✓ aligned</span> <span class='sb-key sb-apparent'>≈ apparent</span> <span class='sb-key sb-neutral'>0/— no usable direction</span> <span class='sb-key sb-counter'>✗ counter</span> <span class='sb-key sb-exploratory'>· &lt;6&nbsp;yr</span> <span class='sb-key sb-insufficient'>untestable</span>. <b>r</b> runs from −1 to +1; nonlinear associations can still exist near zero. Exact-zero ties and undefined constant-series correlations cast no direction vote. Hatched, dashed cells are context-only by contract at every site and never count; the two temperature–green-up columns are vote-eligible everywhere with enough support. <b>Activate any cell</b> for detail; activate a site name to open it.")))
  })

  # ---- DOWNLOADS (the suite's signature export funnel) ----
  output$dlAnnual <- downloadHandler(
    filename = function() sprintf("%s-response-atlas-annual.csv", input$site),
    content = function(file) {
      a <- ann()
      # Export every documented signal and support/audit denominator. The
      # codebook is the source of truth, so a future builder field cannot be
      # silently omitted by a stale hand-maintained keep-vector here.
      cols <- c("year", CODEBOOK$key[CODEBOOK$key %in% names(a)])
      hdr <- c(sprintf("# NEON Cross-Product Response Atlas · %s (%s), %s", input$site, site_blabel(input$site), if (nrow(neon_sites[neon_sites$site==input$site,])) neon_sites$name[neon_sites$site==input$site][1] else input$site),
               "# Annual + seasonal signals. mammal_cpue is a within-site relative index (per 100 trap-nights), NOT cross-site standardized.",
               "# All documented coverage counts, effort denominators, and excluded-catch audit fields are included. precip_winter = Oct-Mar sum (year it ends); precip_monsoon = Jul-Sep sum.",
               "# See the downloadable codebook in the About tab for units, NA semantics, and gates.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(a[, cols, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })
  output$dlLinks <- downloadHandler(
    filename = function() sprintf("%s-response-atlas-link-scorecard.csv", input$site),
    content = function(file) {
      lk <- links(); keep <- intersect(c("from","to","lag","n","r","lo","hi","p","p_floor","n_null","series_span",
        "r_detrended","n_detrended","sign_match_detrended","r_change","n_change","sign_match_change",
        "r_outcome_alt","n_outcome_alt","sign_match_outcome_alt",
        "prior_sign","sign_match","ci_excludes_zero","tier","verdict","expected","expected_class","conf","note"), names(lk))
      hdr <- c(sprintf("# NEON Cross-Product Response Atlas · %s direct-pair scorecard. r is within-site only:", input$site),
               "# expected=TRUE means vote-eligible at every supported site; expected_class=none means context-only at every site and excluded from pooling.",
               "# r_detrended, r_change, and r_outcome_alt are descriptive trend/outcome-construction sensitivities; animal indices are not comparable in magnitude across sites.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(lk[, keep, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })
  output$dlSuite <- downloadHandler(
    filename = function() "neon-response-atlas-scoreboard.csv",
    content = function(file) {
      keep <- intersect(c("site","domain","biome","biome_class","from","to","lag","n","r","lo","hi","p","p_floor",
        "n_null","series_span","r_detrended","n_detrended","sign_match_detrended","r_change","n_change","sign_match_change",
        "r_outcome_alt","n_outcome_alt","sign_match_outcome_alt",
        "prior_sign","sign_match","ci_excludes_zero","tier","verdict","expected","expected_class","conf","note"), names(SUITE_LINKS))
      hdr <- c("# NEON Cross-Product Response Atlas · cross-site scoreboard (every site × current build-locked direct pairing).",
               "# expected=TRUE only for vote-eligible temperature–green-up rows; expected_class=none rows are context-only everywhere.",
               "# Raw-level, detrended, consecutive-change, and alternate-green-up directions plus NEON domain membership are included; animal index magnitudes are not comparable across sites.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(SUITE_LINKS[, keep, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })

  output$dlPooled <- downloadHandler(
    filename = function() "neon-response-atlas-pooled-direction-tests.csv",
    content = function(file) {
      keep <- intersect(c("from", "to", "lag", "expected_class", "sites", "k", "median_r",
                          "sites_detrended", "k_detrended", "sites_change", "k_change",
                          "sites_outcome_alt", "k_outcome_alt",
                          "domains", "k_domain", "domain_ties",
                          "p", "p_holm", "p_fdr", "poolable"), names(POOLED))
      hdr <- c(
        "# NEON Cross-Product Response Atlas · one-raw-level-vote-per-site exact-binomial direction screens.",
        "# p = raw one-sided exact-binomial p; p_holm = familywise adjustment; p_fdr = Benjamini-Hochberg adjustment across poolable current associations.",
        "# Residual, consecutive-change, alternate-green-up, and NEON-domain-majority counts are descriptive sensitivities, not additional p-values; tied domains abstain.",
        "# expected_class=none rows are context-only by design and excluded from pooling; they are not merely below the site-count floor.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(POOLED[, keep, drop=FALSE], file, sep=",", row.names=FALSE,
                                          append=TRUE, qmethod="double"))
    })

  output$dlCodebook <- downloadHandler(
    filename = function() "neon-response-atlas-codebook.csv",
    content = function(file) {
      cb <- CODEBOOK
      hdr <- c("# NEON Cross-Product Response Atlas · data codebook (every emitted signal, its unit, NA-semantics, and n-gate).",
               "# Generated from the actual exported keep-vector, so it cannot drift from the columns the app emits.",
               "# na_meaning = the QC gate that produces an NA cell; n_gate = the per-signal coverage gate.",
               "# Source: NEON multi-product synthesis (DP1.10072.001, DP1.10003.001, DP1.10058.001, DP1.10098.001, DP1.10055.001, DP1.10043.001, DP1.10022.001, DP1.00002.001, DP1.00044.001), CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/); aggregated and derived by this app.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(cb, file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })

  # ---- CODEBOOK (the cheapest credibility win) ----
  output$codebook <- renderUI({
    rows <- lapply(seq_len(nrow(SIGNALS)), function(i){ s <- SIGNALS[i,]
      tags$tr(tags$td(tags$code(s$key)), tags$td(s$label),
        tags$td(span(class=paste0("sig-dot sig-", s$layer))), tags$td(s$layer),
        tags$td(class="st-unit", s$unit), tags$td(s$higher_is)) })
    tagList(
      tags$table(class="inspect-tbl",
        tags$caption(class="visually-hidden", "Response Atlas signal codebook"),
        tags$thead(tags$tr(tags$th(scope="col", "key"), tags$th(scope="col", "signal"),
          tags$th(scope="col", "Layer color"), tags$th(scope="col", "layer"),
          tags$th(scope="col", "unit"), tags$th(scope="col", "“more” ="))),
        tags$tbody(rows)),
      tags$ul(class="codebook-notes",
        tags$li(HTML("<b>precip</b> = annual total mm and <b>temp</b> = annual mean &deg;C; both require all <b>12 distinct months</b>. The export preserves <code>precip_n_months</code>/<code>temp_n_months</code>; a within-site MAD filter can additionally NA an implausible temperature year.")),
        tags$li(HTML("<b>precip_winter</b> = Oct&ndash;Mar sum keyed to the year it ENDS (6 of 6 months). <b>precip_monsoon</b> = Jul&ndash;Sep sum (3 of 3). <b>temp_spring</b> = Mar&ndash;May mean (3 of 3). Reconstructed from the monthly NEON-tower overlays.")),
        tags$li(HTML("<b>greenup_doy</b> is a legacy key for a full-precision, DOY-anchored composition-adjusted timing index—not a pooled observed date. Left-censored earliest records are excluded; retained species need &ge;3 bounded individual midpoint estimates in &ge;3 years. The connected, species-centered/equal-species annual index needs &ge;2 recurrent species and therefore at least 6 contributors. <b>greenup_doy_additive</b> fits an unweighted species+year model over the same eligible cells as an alternate construction; it is a sensitivity field, not a second timeline signal. Both are retrospective full-panel standardizations: a refresh can revise historical values when the eligible species&times;year panel changes. Censoring, exclusions, contributor/species support, reference, interval-width diagnostics, and snapshot hashes are exported.")),
        tags$li(HTML("<b>mammal_cpue</b> = 100 &times; captures / deployed trap-nights (sprung/disturbed traps = &frac12; a trap-night, Nelson &amp; Clark 1973; captures counted by tagID) &mdash; a within-site relative index, NOT cross-site standardized. <b>mammal_mnka</b> = distinct tagged individuals (minimum known alive, Krebs 1966).")),
        tags$li(HTML("<b>plant_richness</b> = observed species count: an effort-sensitive COMPOSITION signal, not productivity; <code>plant_n_plots</code>/<code>plant_n_sampling_units</code> expose effort and richness-based links are excluded from inferential tallies unless standardized. <b>plant_intro_pct</b> counts only canonical introduced (<code>I</code>) cover; ambiguous <code>NI</code> is unknown, not introduced. <b>fruiting_pct</b> is an opportunistic maximum across observed eligible months (&ge;5 individuals), not a fixed-season annual estimate. <code>fruiting_n_eligible_months</code> and <code>fruiting_peak_n_individuals</code> expose unequal observation opportunity; it remains context-only.")),
        tags$li(HTML("<b>bird_index</b> = detected cluster size per observed point-count visit after excluding flyovers; zero-detection visits may be absent. Mosquito activity has a complete effort calendar but is annual rather than season-window matched. Beetle effort includes catch-bearing events only, so its outcome-conditioned denominator is not a valid CPUE series; all three remain descriptive here.")),
        tags$li(HTML("<b>Conditional woody structure</b> (per site, not annual) is the mean live basal area m&sup2;/ha among plots containing qualifying records. <code>veg_n_plots</code>, <code>veg_area_eligible_plots</code>, and <code>veg_record_plots</code> expose its denominator. Because the source cannot distinguish sampled-zero from unsampled plots, zero-stem and unobserved plots are not imputed; this is not a site-wide stock or productivity rate.")),
        tags$li(HTML("<b>n-gates:</b> &lt;3 yrs &rarr; no comparison; 3&ndash;5 &rarr; exploratory; &ge;6 &rarr; circular-shift p + circular block-bootstrap interval + a direction verdict. Only the two temperature–green-up rows are vote-eligible, at every supported site; context-only rows never pool. Raw-level exact-binomial p-values are shown with Holm adjustment plus detrended, consecutive-change, and outcome-estimator direction sensitivities.")),
        tags$li(HTML("<b>NA semantics:</b> a blank/NA cell is never a zero &mdash; it means the signal failed its documented coverage/composition gate that year (for example, an incomplete climate window, too few recurrent green-up species, or no trapping effort). The downloadable codebook CSV documents every rule."))),
      div(class="codebook-dl",
        downloadButton("dlAnnual", tagList(bs_icon("filetype-csv"), " This site's annual data"), class="btn-outline-dark btn-sm"),
        downloadButton("dlLinks",  tagList(bs_icon("filetype-csv"), " This site's link scorecard"), class="btn-outline-dark btn-sm"),
        downloadButton("dlCodebook", tagList(bs_icon("filetype-csv"), " Codebook (every signal, unit, NA-rule)"), class="btn-outline-dark btn-sm"),
        tags$span(class="codebook-dl-note", "(the full cross-site scoreboard CSV is on the Across NEON tab)")))
  })

  # ---- SEARCH THE ATLAS (bundled index, in-memory filter, instant) ----------
  # A "Go to this site" link in each row raises the SAME goSite input the browse
  # list and scoreboard use, so the jump loads from the bundle and lands on the
  # Overview — one selection path everywhere.
  go_link <- function(code) sprintf(
    "<a href='#' class='srch-go' data-shiny-input='goSite' data-shiny-value='%s' aria-label='Open site %s'>Open &rarr;</a>",
    htmltools::htmlEscape(code), htmltools::htmlEscape(code))
  verdict_pill <- function(tier) {
    tm <- TIER_META[[tier]]; if (is.null(tm)) return(htmltools::htmlEscape(tier))
    sprintf("<span class='srch-pill srch-%s'>%s</span>", tier, htmltools::htmlEscape(tm$lab))
  }
  srch_dt_opts <- list(dom = "tp", pageLength = 12, autoWidth = FALSE, scrollX = TRUE,
    language = list(emptyTable = "No sites match — try widening the filter."),
    columnDefs = list(list(className = "dt-center", targets = "_all")))

  # (a) FIND A LINK -----------------------------------------------------------
  search_link_rows <- reactive({
    if (!nrow(SRCH_LINKS) || is.null(input$searchLink)) return(SRCH_LINKS[0, , drop = FALSE])
    d <- SRCH_LINKS[SRCH_LINKS$link_id == input$searchLink, , drop = FALSE]
    if (isTRUE(input$searchAlignedOnly)) d <- d[d$is_aligned %in% TRUE, , drop = FALSE]
    # Vote-eligible rows first, then clean aligned directions, effect size, and site.
    d[order(!(d$expected %in% TRUE), !(d$is_aligned %in% TRUE),
            -abs(ifelse(is.finite(d$r), d$r, 0)), d$site), , drop = FALSE]
  })

  output$searchLinkSummary <- renderUI({
    if (is.null(input$searchLink) || !nrow(SRCH_CATALOG)) return(NULL)
    cat_row <- SRCH_CATALOG[SRCH_CATALOG$link_id == input$searchLink, , drop = FALSE]
    all_rows <- SRCH_LINKS[SRCH_LINKS$link_id == input$searchLink, , drop = FALSE]
    total <- nrow(all_rows)
    testable <- sum(all_rows$is_testable %in% TRUE)
    aligned <- sum(all_rows$is_aligned %in% TRUE)
    shown <- nrow(search_link_rows())
    pooled_row <- if (nrow(SRCH_POOLED)) SRCH_POOLED[SRCH_POOLED$link_id == input$searchLink, , drop = FALSE] else SRCH_POOLED[0, ]
    context_only <- nrow(cat_row) && identical(as.character(cat_row$expected_class[1]), "none")
    pooled_txt <- if (context_only)
      "Context only by measurement/construct contract at every site; excluded from site tallies and pooled inference. More years alone would not change that status."
    else if (nrow(pooled_row) && isTRUE(pooled_row$poolable[1]) && is.finite(pooled_row$p_raw[1]))
      sprintf("Vote-eligible at every supported site: %d raw-level votes, raw p = %.3f%s (median r = %+.2f); NEON-domain majority %d/%d%s. The Holm value covers the eligible family; inspect all sensitivities on Across NEON.",
              pooled_row$sites[1], pooled_row$p_raw[1],
              if (is.finite(pooled_row$p_holm[1])) sprintf("; Holm p = %.3f", pooled_row$p_holm[1]) else "",
              pooled_row$median_r[1], pooled_row$k_domain[1], pooled_row$domains[1],
              if (pooled_row$domain_ties[1] > 0) sprintf(" (+%d tied)", pooled_row$domain_ties[1]) else "")
      else "Vote-eligible, but too few supported site votes to pool this association yet."
    conf <- if (nrow(cat_row)) cat_row$conf[1] else NA
    div(class = "search-summary",
      div(class = "ss-count", bs_icon("geo-alt-fill"),
        if (isTRUE(input$searchAlignedOnly))
          sprintf(" %d clean aligned site%s", shown, if (shown == 1) "" else "s")
        else sprintf(" %d of %d sites have at least 6 paired years", testable, total),
        tags$span(class = "ss-sub", sprintf(" for %s · %d clean aligned direction%s overall",
          if (nrow(cat_row)) cat_row$link_label[1] else input$searchLink,
          aligned, if (aligned == 1) "" else "s"))),
      if (!is.na(conf)) div(class = "ss-conf", sprintf("Literature basis: %s", conf)),
      div(class = "ss-pooled", bs_icon("people-fill"), " ", pooled_txt))
  })

  output$searchLinkTable <- DT::renderDT({
    d <- search_link_rows()
    if (!nrow(d)) return(DT::datatable(
       data.frame(Site = character(0), `Site name` = character(0), `Descriptive group` = character(0),
                  n = integer(0), r = numeric(0), `Circular p (coarse)` = numeric(0), Verdict = character(0),
                  `Paired years` = character(0), Open = character(0), check.names = FALSE),
      escape = FALSE, rownames = FALSE, selection = "none", options = srch_dt_opts))
    yrs <- ifelse(is.na(d$year_min) | is.na(d$year_max), "—", sprintf("%d–%d", d$year_min, d$year_max))
    tbl <- data.frame(
      Site = sprintf("<b>%s</b>%s", d$site, ifelse(d$expected %in% TRUE, " <span class='srch-oob' title='vote-eligible at every site with enough support'>(vote)</span>", " <span class='srch-oob' title='context only by measurement/construct contract at every site; never counted or pooled'>(context)</span>")),
      `Site name` = vapply(d$site, srch_site_name, character(1)),
      `Descriptive group` = d$biome,
      n = d$n,
      r = ifelse(is.finite(d$r), sprintf("%+.2f", d$r), "—"),
      `Circular p (coarse)` = ifelse(is.finite(d$p), sprintf("%.3f", d$p), "—"),
      Verdict = vapply(d$tier, verdict_pill, character(1)),
      `Paired years` = yrs,
      Open = vapply(d$site, go_link, character(1)),
      check.names = FALSE, stringsAsFactors = FALSE)
    DT::datatable(tbl, escape = FALSE, rownames = FALSE, selection = "none",
      options = c(srch_dt_opts, list(order = list())),
      class = "srch-dt compact stripe")
  })

  # (b) DESCRIPTIVE DIRECTION AGREEMENT --------------------------------------
  search_strength_rows <- reactive({
    if (!nrow(SRCH_STR)) return(SRCH_STR)
    thr <- if (is.null(input$searchMinResolved)) 0 else input$searchMinResolved
    d <- SRCH_STR[SRCH_STR$n_resolved >= thr, , drop = FALSE]
    d[order(-d$n_resolved, -d$n_aligned, d$site), , drop = FALSE]
  })

  output$searchStrengthSummary <- renderUI({
    if (!nrow(SRCH_STR)) return(NULL)
    shown <- nrow(search_strength_rows()); total <- nrow(SRCH_STR)
    div(class = "search-summary",
      div(class = "ss-count", bs_icon("geo-alt-fill"),
        sprintf(" %d of %d sites", shown, total),
        tags$span(class = "ss-sub", " meet the agreement filter")),
      div(class = "ss-pooled", bs_icon("info-circle"),
        " The count is eligible links whose direction agrees, not significance. It ranks where to look, not which ecosystem is 'stronger'."))
  })

  output$searchStrengthTable <- DT::renderDT({
    d <- search_strength_rows()
    if (!nrow(d)) return(DT::datatable(
      data.frame(Site = character(0), `Descriptive group` = character(0), Agree = character(0),
                 `Aligned (CI excludes 0)` = integer(0), Counter = integer(0), `Site record` = character(0),
                 Open = character(0), check.names = FALSE),
      escape = FALSE, rownames = FALSE, selection = "none", options = srch_dt_opts))
    yrs <- ifelse(is.na(d$site_year_min) | is.na(d$site_year_max), "—",
                  sprintf("%d–%d", d$site_year_min, d$site_year_max))
    tbl <- data.frame(
      Site = sprintf("<b>%s</b> <span class='srch-sn'>%s</span>", d$site, vapply(d$site, srch_site_name, character(1))),
      `Descriptive group` = d$biome,
      `Agree (of eligible)` = sprintf("<b>%d</b> of %d", d$n_resolved, d$expected_testable),
      `Aligned (CI excludes 0)` = d$n_aligned,
      Counter = d$n_counter,
      `Site record` = yrs,
      Open = vapply(d$site, go_link, character(1)),
      check.names = FALSE, stringsAsFactors = FALSE)
    DT::datatable(tbl, escape = FALSE, rownames = FALSE, selection = "none",
      options = c(srch_dt_opts, list(order = list())),
      class = "srch-dt compact stripe")
  })

  observeEvent(input$goSite, {
    req(input$goSite)
    updateSelectInput(session, "site", selected = input$goSite)
    updateTabsetPanel(session, "tabs", selected = "overview")
    focus_after_update(tab = "overview")
  })

  # ---- Across NEON: click a scoreboard cell -> full plain-English detail for that
  # site x link (what r is, the years behind it, the block-bootstrap interval, the permutation
  # p with its floor, the literature prior, and whether it counts toward the tally). ----
  observeEvent(input$sbCell, {
    parts <- strsplit(input$sbCell %||% "", "|", fixed = TRUE)[[1]]
    if (length(parts) != 4) return()
    s <- parts[1]; from <- parts[2]; to <- parts[3]; lag <- suppressWarnings(as.integer(parts[4]))
    d <- SUITE_LINKS[SUITE_LINKS$site == s & SUITE_LINKS$from == from &
                     SUITE_LINKS$to == to & SUITE_LINKS$lag == lag, , drop = FALSE]
    if (!nrow(d)) return()
    d <- d[1, ]; tm <- TIER_META[[d$tier]] %||%
      list(col = "#6b7a89", text_col = "#53606d", ink = "#ffffff", icon = "slash-circle", lab = d$tier)
    arrow <- if (isTRUE(d$prior_sign > 0)) "more driver → more response (↑)" else "more driver → earlier / less response (↓)"
    verdict_plain <- switch(d$tier,
      consistent  = "Aligned: points in the literature-motivated direction AND the circular block-bootstrap interval excludes zero. A clean per-site direction, not a significance claim.",
      apparent    = "Apparent: points in the literature-motivated direction, but the circular block-bootstrap interval still crosses zero at this few years.",
      neutral     = "No usable direction: the correlation is effectively zero (a tie) or undefined because one series has no variation, so this row casts no direction vote.",
      counter     = "Counter: runs opposite to the literature-motivated direction.",
      exploratory = "Exploratory: fewer than 6 overlapping years, so the data is shown but no verdict is given.",
      "Too few overlapping years to compare at this site.")
    direction_read <- if (is.na(d$sign_match)) "has no direction and is omitted as a tie from direction tallies"
                      else if (isTRUE(d$sign_match)) "matches that direction" else "runs counter to it"
    r_plain <- if (is.finite(d$r))
      sprintf("<b>r = %+.2f</b> is the linear correlation between the driver and the response at this site. r runs from −1 (perfect opposite linear movement) through 0 (no linear correlation) to +1 (perfect same-direction linear movement); nonlinear associations can still exist near zero. The current setting expects <b>%s</b>, and this %s.",
              d$r, arrow, direction_read)
      else if (d$n >= 3) "A correlation is unavailable because at least one series has no variation across the overlapping years."
      else "There aren't enough overlapping years here to compute a correlation."
    ci_line <- if (is.finite(d$lo) && is.finite(d$hi))
      sprintf("<b>95%% interval [%.2f, %.2f]</b> (circular block bootstrap): %s. Intervals are wide at this few years.",
              d$lo, d$hi, if (isTRUE(d$ci_excludes_zero)) "its unrounded endpoints exclude zero, so the direction is clean" else "it includes zero, so the sign isn't yet clean") else NULL
    p_line <- if (isTRUE(d$n >= 6) && is.finite(d$p))
      sprintf("<b>Permutation p = %.3f</b>, shown as a coarse diagnostic, not a per-site significance test. The gap-aware null retained a %d-year calendar span; %d valid shifts give a minimum attainable p of %.3f. Across NEON reports the raw-level site-vote screen plus trend, outcome-construction, and domain sensitivities for eligible rows.",
              d$p, d$series_span, d$n_null, d$p_floor) else NULL
    sensitivity_bits <- character(0)
    if ("r_detrended" %in% names(d) && is.finite(d$r_detrended))
      sensitivity_bits <- c(sensitivity_bits, sprintf("linear-year residual r = %+.2f (n=%d)", d$r_detrended, d$n_detrended))
    if ("r_change" %in% names(d) && is.finite(d$r_change))
      sensitivity_bits <- c(sensitivity_bits, sprintf("consecutive-change r = %+.2f (nΔ=%d)", d$r_change, d$n_change))
    if ("r_outcome_alt" %in% names(d) && is.finite(d$r_outcome_alt))
      sensitivity_bits <- c(sensitivity_bits, sprintf("additive-green-up r = %+.2f (n=%d)", d$r_outcome_alt, d$n_outcome_alt))
    sensitivity_line <- if (length(sensitivity_bits)) paste0(
      "<b>Descriptive sensitivities:</b> ", paste(sensitivity_bits, collapse = "; "),
      ". They do not change this raw-level verdict or add p-values.") else NULL
    exp_line <- if (!isTRUE(d$expected))
      "<b>Context only at every site.</b> Its response window, effort, proxy, or directional basis does not meet the inferential contract, so it never enters a site tally or pooled p-value."
      else if (d$n < 6)
        "<b>Vote-eligible at every site, but not yet testable here.</b> Too few overlapping years means it does not enter this site's direction tally."
      else if (is.na(d$sign_match) && is.finite(d$r))
        "<b>Vote-eligible, but tied.</b> Exact direction calculations omit zero-effect ties, so this row casts no tally vote."
      else if (is.na(d$sign_match))
        "<b>Vote-eligible, but direction is undefined.</b> With no variation in at least one series, this row casts no tally vote."
      else
        "<b>Vote-eligible and testable here.</b> This row casts one raw-level match-or-counter vote in the site's descriptive direction tally; pooled trend sensitivities are reported separately."
    showModal(modalDialog(easyClose = TRUE, size = "m",
      title = HTML(sprintf("%s &nbsp;·&nbsp; %s &rarr; %s%s", s, sig_label(from), sig_label(to),
                           if (isTRUE(lag > 0)) sprintf(" (lag %dy)", lag) else "")),
      div(class = "sb-detail",
        p(tags$span(class=paste("tier-text", paste0("tier-", d$tier)), bs_icon(tm$icon %||% "circle"), " ", tm$lab),
          tags$br(), verdict_plain),
        p(HTML(r_plain)),
        p(sprintf("Based on %d overlapping year%s of data.", d$n, if (isTRUE(d$n == 1)) "" else "s")),
        if (!is.null(ci_line)) p(HTML(ci_line)),
        if (!is.null(p_line)) p(HTML(p_line)),
        if (!is.null(sensitivity_line)) p(HTML(sensitivity_line)),
        tags$hr(),
        p(HTML(sprintf("<b>Current literature-motivated setting</b> (locked for this build, but historically selected alongside these data): expect <b>%s</b>, lag <b>%s</b>, literature-basis grade <b>%s</b>.",
          arrow, if (isTRUE(lag > 0)) sprintf("%d year%s later", lag, if (lag == 1) "" else "s") else "same year", d$conf %||% "—"))),
        if (!is.na(d$note) && nzchar(d$note)) p(class = "qc-cap-note", style = "margin-top:6px", d$note),
        p(HTML(exp_line))),
      footer = modalButton("Close")))
  })
  observeEvent(input$gotoTab, {
    updateTabsetPanel(session, "tabs", selected = input$gotoTab)
    focus_after_update(tab = input$gotoTab)
  })

  observeEvent(input$help, showModal(modalDialog(easyClose=TRUE, title=tagList(bs_icon("question-circle"), " How to read the response atlas"),
    tags$ul(
      tags$li(HTML("Pick a <b>site</b>; sites with more available measurement layers are listed first.")),
      tags$li(HTML("<b>Layered Timeline</b>: standardized signals co-displayed by layer; inspect a year to compare direct pairings at their stated lags. The visual order is not a tested chain.")),
      tags$li(HTML("<b>Link cards</b>: each literature-motivated direct pairing, marked vote-eligible or context-only and honest about how few years support it.")),
      tags$li(HTML("<b>Driver Lab</b>: pick a response and inspect every current build-locked pairing; only eligible rows enter a direction tally.")),
      tags$li(HTML("Short series: <b>read the shapes</b>, inspect direction agreement with its uncertainty and support, and never read causation."))),
    footer=modalButton("Got it"))))
}
