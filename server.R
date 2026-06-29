# ===========================================================================
# NEON Driver Cascade — server.R
# ===========================================================================
server <- function(input, output, session) {
  is_dark <- function() identical(input$colorMode, "dark")
  theme_plotly <- function(p) { dark <- is_dark(); ink <- if (dark) "#e8eef2" else "#1f2a30"
    grid <- if (dark) "rgba(220,230,240,0.10)" else "rgba(31,42,48,0.08)"
    p %>% plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
      font=list(color=ink, family="Rubik"),
      hoverlabel=list(bgcolor="rgba(11,23,51,0.96)", bordercolor="#2dd4bf", font=list(color="#eaf2ff", family="Rubik", size=12))) %>%
      plotly::config(displayModeBar=FALSE, responsive=TRUE) }
  note_plot <- function(msg) plotly::plot_ly(type="scatter", mode="markers") %>%
    plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", xaxis=list(visible=FALSE), yaxis=list(visible=FALSE),
      annotations=list(list(text=msg, showarrow=FALSE, font=list(color=if(is_dark())"#9fb0c4" else "#6b7a85", size=14)))) %>%
    plotly::config(displayModeBar=FALSE)

  ann    <- reactive({ req(input$site); site_annual(input$site) })
  links  <- reactive({ req(input$site); site_links_cached(input$site) })   # precomputed, biome-aware
  smatch <- reactive(signmatch_score(links()))
  bclass <- reactive(site_bclass(input$site))
  blabel <- reactive(site_blabel(input$site))

  # ---- Pulse Tracer state: the climate year being traced down the ladder ----
  traced <- reactiveVal(NULL)
  observeEvent(input$site, traced(NULL), ignoreInit = TRUE)          # reset on site change
  observeEvent(input$tracedYear, {                                    # set by a ladder dot click (cascade.js onRender)
    y <- suppressWarnings(as.integer(round(as.numeric(input$tracedYear$year))))
    if (is.finite(y)) traced(y)
  })
  observeEvent(input$clearTrace, traced(NULL))

  # ---- clickable scatter dots: the year being inspected in the Driver Lab ----
  scatterYear <- reactiveVal(NULL)
  observeEvent(input$response, scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$site,     scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$scatterYear, {
    y <- suppressWarnings(as.integer(round(as.numeric(input$scatterYear$year))))
    if (is.finite(y)) scatterYear(y)
  })
  observeEvent(input$clearScatter, scatterYear(NULL))

  output$siteBio <- renderUI({ b <- site_bio(input$site); if (is.null(b)) return(NULL)
    div(class="site-bio", bs_icon("info-circle-fill"), span(b)) })

  output$signalChips <- renderUI({ a <- ann(); req(nrow(a))
    have <- LADDER_KEYS[vapply(LADDER_KEYS, function(k) sum(is.finite(a[[k]])) >= 2, logical(1))]
    if (!length(have)) return(div(class="sig-chips-empty", "No multi-year signals here yet."))
    div(class="sig-chips", lapply(have, function(k){ L <- SIGNALS$layer[SIGNALS$key==k]
      span(class=paste0("sig-chip sig-", L), sig_label(k)) })) })

  # ---- hero: ONE auto-written verdict sentence (lead with the answer), biome the anchor ----
  # The sentence is the comprehension fix; the four stat tiles demote to supporting evidence.
  verdict_sentence <- function(site, lk, sm, blab) {
    desert <- identical(site_bclass(site), "water-limited")
    ok <- lk[lk$expected %in% TRUE & lk$n >= 6 & !is.na(lk$sign_match), , drop = FALSE]
    best <- if (nrow(ok)) ok[order(match(ok$tier, c("consistent","apparent","counter","exploratory")),
                                   -abs(ifelse(is.na(ok$r), 0, ok$r))), ][1, ] else NULL
    mon <- lk[lk$from == "precip_monsoon" & lk$to == "mammal_cpue" & is.finite(lk$r), ]
    # Suite-level lead (Cass): on a desert landing page, open with the ONE result that
    # survives cross-site pooling (warmer springs -> earlier green-up), THEN the desert
    # seasonal-split as the app's core insight, hedged. Neither buries the other.
    gp <- POOLED[POOLED$from == "temp" & POOLED$to == "greenup_doy" &
                 (if ("poolable" %in% names(POOLED)) POOLED$poolable %in% TRUE else POOLED$sites >= 3), , drop = FALSE]
    suite_lead <- if (nrow(gp) && is.finite(gp$p[1]))
      sprintf("Across the network, the cascade's most reliable rung holds: <b>warmer springs &rarr; earlier green-up</b> at <b>%d of %d</b> temperature-limited sites (pooled p&nbsp;=&nbsp;%.3f). ",
              gp$k[1], gp$sites[1], gp$p[1]) else ""
    lead <- sprintf("<span class='biome-tag biome-%s'>%s</span> ",
                    if (desert) "water" else "temp", blab)
    body <- if (desert) {
      s <- paste0(suite_lead, "Here, though, green-up is triggered by <b>water, not warmth</b>, so the standard <i>annual</i> cascade only half-fits, and that mismatch <b>is the finding</b>, not a failure.")
      if (nrow(mon) && mon$r[1] > 0)
        s <- paste0(s, sprintf(" Test the <b>right season</b> and the chain reappears: the summer-monsoon seed crop <b>tracks</b> next year's rodents at <b>r&nbsp;=&nbsp;%+.2f</b> (a single desert, suggestive, not yet established), where annual rainfall showed almost nothing (r&nbsp;=&nbsp;+0.20).", mon$r[1]))
      s
    } else if (!is.null(best) && identical(best$tier, "consistent")) {
      sprintf("The cascade points the way ecology predicts: <b>%d of %d</b> testable links align with the expected direction, led by <b>%s&nbsp;→&nbsp;%s</b> (r&nbsp;=&nbsp;%+.2f, interval clean, a clean direction at this site, not a significance claim, the cross-site pooling is the real test).",
              sm$k, sm$n, sig_label(best$from), sig_label(best$to), best$r)
    } else if (!is.na(sm$n) && sm$n > 0) {
      sprintf("Of the links testable here, <b>%d of %d</b> point the direction ecology predicts. A short series, so read it as <i>direction</i>, not proof.", sm$k, sm$n)
    } else {
      "Not enough overlapping years yet to line up the cascade here. The signals are shown below, but no verdict is given."
    }
    HTML(paste0(lead, body))
  }
  output$heroStats <- renderUI({
    a <- ann(); req(nrow(a)); sm <- smatch(); lk <- links(); lp <- layers_present(a, SIGNALS)
    yrs <- range(a$year[rowSums(!is.na(a[, SIGNALS$key, drop=FALSE])) > 0], na.rm=TRUE)
    row <- neon_sites[neon_sites$site==input$site,]
    hero <- function(v,l,icon,tone,ttl=NULL) div(class=paste0("hero-stat hero-",tone), title=ttl,
      div(class="hs-icon", bs_icon(icon)), div(div(class="hs-v", v), div(class="hs-l", l)))
    div(class="hero-band",
      div(class="hero-title", bs_icon("diagram-3-fill"), tags$b(sprintf("%s · %s", input$site, if (nrow(row)) row$name[1] else input$site)),
        tags$span(class="hero-sub", sprintf(" · %s–%s", yrs[1], yrs[2])), cpop("biome"),
        # "change site" affordance: the picker lives on the Overview select-panel now,
        # so this hops to Overview and scrolls the panel into view (works on every width).
        tags$a(class="hero-change", href="#", onclick="cascadeChangeSite();return false;",
          bs_icon("pin-map"), " change site")),
      div(class="hero-verdict", verdict_sentence(input$site, lk, sm, blabel())),
      div(class="hero-grid",
        hero(sum(lp), "trophic layers", icon="layers", tone="navy", ttl="Climate, green-up, producers, consumers present here"),
        hero(if (sm$n>0) sprintf("%d/%d", sm$k, sm$n) else "—", "expected links match", icon="check2-circle", tone="pine",
             ttl="Of the links EXPECTED for this biome, how many point the way ecology predicts"),
        hero(if (!is.na(sm$p)) sprintf("%.2f", sm$p) else "—", "sign-match p", icon="dice-5", tone="gold",
             ttl="Binomial test that more links match than chance"),
        hero(nrow(a), "years on record", icon="calendar3", tone="terra")))
  })

  output$overviewInsight <- renderUI({
    sm <- smatch(); desert <- identical(bclass(), "water-limited")
    # the binomial tally treats each link as an independent trial; links within ONE site
    # share their driver years, so that independence is only approximate — say so.
    tally_caveat <- if (!is.na(sm$n) && sm$n > 1) " (links within a site share driver years, so these are not fully independent trials)" else ""
    msg <- if (sm$n == 0)
        "Not enough overlapping years yet to line up the cascade here. <b>SCBI</b> (a temperate forest) shows it most clearly."
      else if (desert)
        sprintf("This is a <b>water-limited</b> system, so its links are tested by <b>season</b>, not by annual totals: %s%s. The Seasonal Climate panel shows why one annual rainfall number hides the signal.", sm$txt, tally_caveat)
      else
        sprintf("Across the links expected in this temperature-limited system, <b>%s</b>%s. With only a handful of years per signal, that direction-agreement is a more honest signal than any single correlation.", sm$txt, tally_caveat)
    insight_banner("diagram-3", tone = if (!is.na(sm$p) && sm$p < 0.05) "pine" else "navy", HTML(msg))
  })

  # producer standing-stock backdrop — the slow ~5-yr floor the annual signals ride on
  output$standingStock <- renderUI({
    ba <- site_ba(input$site); if (!is.finite(ba)) return(NULL)
    se <- site_ba_se(input$site)
    div(class="standing-stock", bs_icon("tree-fill"),
      HTML(sprintf(" Woody standing stock: <b>%s m²/ha</b>%s live basal area",
        format(round(ba, 1), nsmall = 1), if (is.finite(se)) sprintf(" ±%s", format(round(se, 1), nsmall = 1)) else "")),
      cpop("standing"),
      tags$span(class = "ss-note", "the slow producer floor the annual signals ride on (a real productivity measure where species richness can't be one)."))
  })

  # ---- overview cascade schematic ----
  output$cascadeSchematic <- renderUI({
    a <- ann(); req(nrow(a))
    lay <- list(climate="climate", phenology="phenology", producer="producer", consumer="consumer")
    node <- function(L){ lm <- LAYER_META[[L]]
      ks <- SIGNALS$key[SIGNALS$layer==L & SIGNALS$key %in% LADDER_KEYS]
      have <- ks[vapply(ks, function(k) sum(is.finite(a[[k]]))>=2, logical(1))]
      div(class=paste0("casc-node", if (!length(have)) " casc-empty" else ""),
        div(class="casc-node-h", style=sprintf("color:%s", lm$col), bs_icon(lm$icon), " ", lm$title, cpop(L)),
        if (length(have)) div(class="casc-sigs", lapply(have, function(k) div(class="casc-sig", sig_label(k))))
        else div(class="casc-sigs", em("no data here"))) }
    arrow <- div(class="casc-arrow", bs_icon("arrow-right"))
    div(class="casc-flow", node("climate"), arrow, node("phenology"), arrow, node("producer"), arrow, node("consumer"))
  })

  output$signalTable <- renderUI({
    a <- ann(); req(nrow(a))
    rows <- lapply(c("climate","phenology","producer","consumer"), function(L){
      ks <- SIGNALS$key[SIGNALS$layer==L & SIGNALS$key %in% LADDER_KEYS]; lm <- LAYER_META[[L]]
      lapply(ks, function(k){ v <- a[[k]]; nf <- sum(is.finite(v)); if (nf < 1) return(NULL)
        yrs <- range(a$year[is.finite(v)])
        tags$tr(tags$td(span(class=paste0("sig-dot sig-",L))), tags$td(sig_label(k)),
          tags$td(class="st-unit", sig_unit(k)), tags$td(sprintf("%d yr", nf)),
          tags$td(class="st-yr", sprintf("%s–%s", yrs[1], yrs[2]))) }) })
    rows <- Filter(Negate(is.null), unlist(rows, recursive=FALSE))
    tags$table(class="inspect-tbl sig-tbl",
      tags$thead(tags$tr(tags$th(""), tags$th("Signal"), tags$th("Unit"), tags$th("Coverage"), tags$th("Years"))),
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
    tile <- function(lab, v, sub) div(class = "hill-tile",
      div(class = "hill-v", if (is.finite(v)) format(round(v)) else "—"),
      div(class = "hill-lab", lab), div(class = "hill-sub", sub))
    div(class = "hill-panel",
      div(class = "hill-intro", bs_icon("diagram-2"),
        HTML(" <b>Diversity profile</b> (Hill numbers, median across years): effective species at three weightings. <b>q0</b> counts every species equally (= richness, effort-sensitive); <b>q1</b> weights by commonness (exp-Shannon); <b>q2</b> by dominance (inverse-Simpson). When q1/q2 sit well below q0, a few species dominate, so richness alone overstates diversity.")),
      div(class = "hill-tiles",
        tile("q0", q0, "richness"), tile("q1", q1, "exp-Shannon"), tile("q2", q2, "inv-Simpson")))
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
    LADDER_PAL <- list(    # desert-night per-layer ramps: clim sky · phen lime · prod green · cons coral
      climate   = c("#43b8e8","#2a8fc4","#7fd0f0","#1f6f9e"),
      phenology = c("#9bd24a","#7fb533","#b8e06f","#6a9a2a"),
      producer  = c("#5fb56a","#3f9a52","#86c98e","#2f7d44"),
      consumer  = c("#fb8a7e","#e86a5e","#ffb0a6","#d4584c"))
    dark_hex <- function(hex) if (!is_dark()) hex else {     # col2rgb is 0-255; rgb2hsv's default
      hsv <- grDevices::rgb2hsv(grDevices::col2rgb(hex))      # maxColorValue is 255 — do NOT pre-divide
      grDevices::hsv(hsv[1], max(0, hsv[2]*0.82), min(1, hsv[3]*1.1)) }   # ease saturation, gentle lift for dark bg
    # ---- Pulse Tracer highlights for the traced year (built per signal key) ----
    t0 <- traced(); paths <- if (!is.null(t0)) pulse_paths(a, t0) else NULL
    hl <- list(); add_hl <- function(key, yr, z, color, sym, lab)
      hl[[key]] <<- rbind(hl[[key]], data.frame(year=yr, z=z, color=color, sym=sym, lab=lab, stringsAsFactors=FALSE))
    if (!is.null(paths) && nrow(paths)) {
      vcol <- c(match="#2dd4bf", miss="#fb8a7e", nodata="#9fb0cf")
      for (fk in unique(paths$from)) add_hl(fk, t0, paths$src_z[paths$from==fk][1], "#ffd24a", "circle",
        sprintf("%s · traced year %d (z=%.2f)", sig_label(fk), t0, paths$src_z[paths$from==fk][1]))
      for (i in seq_len(nrow(paths))) { pr <- paths[i,]; if (pr$verdict=="nodata") next
        add_hl(pr$to, pr$dst_year, pr$dst_z, unname(vcol[[pr$verdict]]), if (pr$verdict=="match") "circle" else "x",
          sprintf("%s · %d: %s the prior (z=%.2f)", sig_label(pr$to), pr$dst_year,
                  if (pr$verdict=="match") "as" else "against", pr$dst_z)) }
    }
    plist <- lapply(present, function(L){ dd <- dl[[L]]; lm <- LAYER_META[[L]]
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
          marker=list(size=16, color=h$color, symbol=h$sym, line=list(color="#fff", width=2)),
          name="pulse", legendgroup=L, showlegend=FALSE, hovertext=h$lab, hoverinfo="text") }
      p %>% plotly::layout(yaxis=list(title=list(text=lm$title, font=list(size=11, color=lm$col)),
        zeroline=TRUE, zerolinecolor=if(is_dark())"rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)",
        gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)", tickfont=list(size=9)))
    })
    narrow <- isTRUE((input$vw %||% 1200) < 760)   # on phones the h-legend crushes into the axis
    sp <- plotly::subplot(plist, nrows=length(present), shareX=TRUE, titleY=TRUE, margin=0.035) %>%
      theme_plotly() %>%
      plotly::layout(showlegend = !narrow, legend=list(orientation="h", y=-0.08, font=list(size=10)),
        xaxis=list(title="", dtick=1, gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
        margin = list(l = 60, r = 20, t = 36, b = if (narrow) 24 else 40))
    # capture a dot click -> Shiny input$tracedYear (re-attached on every render; plotly purge wipes handlers)
    htmlwidgets::onRender(sp, "function(el, x){ el.on('plotly_click', function(d){
      if (d && d.points && d.points.length){ var yr = d.points[0].x;
        if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('tracedYear', {year: yr, n: Math.random()}); } }); }")
  })

  output$pulseBanner <- renderUI({
    t0 <- traced()
    if (is.null(t0)) return(div(class="pulse-banner pulse-idle", bs_icon("hand-index-thumb"),
      HTML(" <b>Trace a pulse:</b> tap any year's dot on the ladder. That year lights up, and its ripple lands on the rungs below at each link's lag: a <span class='pulse-key pk-match'>● moved as the prior predicts</span> or <span class='pulse-key pk-miss'>✕ counter</span>."),
      cpop("pulse")))
    paths <- pulse_paths(ann(), t0)
    if (is.null(paths) || !nrow(paths)) return(div(class="pulse-banner pulse-active", bs_icon("activity"),
      HTML(sprintf(" <b>Year %d</b> has no annual climate signal to trace here. ", t0)),
      actionLink("clearTrace", tagList(bs_icon("x-circle"), " clear"), class="pulse-clear")))
    k <- sum(paths$verdict=="match"); tot <- sum(paths$verdict %in% c("match","miss")); nd <- sum(paths$verdict=="nodata")
    div(class="pulse-banner pulse-active", bs_icon("activity"),
      HTML(sprintf(" <b>Tracing %d:</b> %d of %d downstream rung%s moved the way the prior predicts%s. <i>One path is an anecdote; the chips on the right are the evidence.</i> ",
        t0, k, tot, if (tot==1) "" else "s", if (nd>0) sprintf(" (%d had no data that year)", nd) else "")),
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
          title = if (!exp[i]) "Not the mechanism expected in this biome; shown for context, not counted in the verdict" else NULL,
          div(class="lc-top", span(class="lc-from", sig_label(r$from)), bs_icon("arrow-right"),
            span(class="lc-to", sig_label(r$to)),
            span(class="lc-lag", if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr"),
            if (exp[i]) span(class="lc-exp", "expected here")),
          div(class="lc-mid",
            span(class="lc-prior", sprintf("expect %s", arrow)),
            if (is.finite(r$r)) span(class="lc-r", sprintf("r=%.2f%s", r$r,
              if (is.finite(r$lo)) sprintf(" [%.2f, %.2f]", r$lo, r$hi) else "")) else span(class="lc-r","—"),
            span(class="lc-n", sprintf("n=%d", r$n))),
          div(class="lc-verdict", style=sprintf("color:%s", tm$col), bs_icon(tm$icon), " ", r$verdict)) })),
      p(class="qc-cap-note", style="margin-top:8px", bs_icon("info-circle"),
        HTML(" Dimmed links aren't the mechanism <b>expected</b> in this biome (e.g. the temperate temperature→green-up prior at a desert); shown for context, not counted in the verdict.")))
  })

  # ---- Driver Lab ----
  output$labTitle <- renderText(sprintf("What drives %s here?", tolower(sig_label(input$response))))

  lab_links <- reactive({ lk <- links(); lk[lk$to == input$response, , drop=FALSE] })

  output$signMatchBanner <- renderUI({
    lk <- lab_links()
    if (!nrow(lk)) return(insight_banner("info-circle", tone="navy", "No predicted drivers for this response in the cascade."))
    nshow <- lk[lk$n >= 3, , drop=FALSE]
    k <- sum(nshow$sign_match, na.rm=TRUE); tot <- nrow(nshow)
    best <- if (any(lk$tier=="consistent")) lk[lk$tier=="consistent",][1,] else NULL
    msg <- if (!is.null(best)) sprintf("Of the literature's predicted drivers, <b>%s</b> is %s here.", sig_label(best$from), best$verdict)
      else if (tot>0) sprintf("%d of %d predicted drivers point the expected way, but none stands out as a clean direction (interval excludes zero) at this site's short series.", k, tot)
      else "Too few overlapping years to test any predicted driver here."
    # precip-coverage caveat: only when a rain driver is among the predicted links here
    has_precip <- any(grepl("^precip", lk$from))
    tagList(
      insight_banner("bullseye", tone = if (!is.null(best)) "pine" else "navy", HTML(msg)),
      if (has_precip) p(class="precip-coverage-note", bs_icon("info-circle"),
        HTML(" Annual precipitation is available at 19 of 46 NEON sites; rain-driven rungs are testable only where the tower precip record exists.")))
  })

  output$driverTable <- renderUI({
    lk <- lab_links(); if (!nrow(lk)) return(p(class="qc-cap-note","No predicted drivers for this response."))
    lk <- lk[order(-lk$n, -abs(ifelse(is.na(lk$r),0,lk$r))), ]
    expc <- if ("expected" %in% names(lk)) lk$expected %in% TRUE else rep(TRUE, nrow(lk))
    rows <- lapply(seq_len(nrow(lk)), function(i){ r <- lk[i,]; tm <- TIER_META[[r$tier]]
      arrow <- if (r$prior_sign>0) "↑ +" else "↓ −"
      tags$tr(class = if (!expc[i]) "dt-dim" else NULL,
        tags$td(tags$b(sig_label(r$from)),
          if (expc[i]) span(class="dt-exp", title="The mechanism expected in this biome", " ✓") ),
        tags$td(class="dt-prior", sprintf("%s, %s", arrow, if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr")),
        tags$td(class="dt-r", if (is.finite(r$r)) sprintf("%.2f", r$r) else "—"),
        tags$td(class="dt-n", r$n),
        tags$td(span(class="dt-chip", style=sprintf("background:%s", tm$col), tm$lab))) })
    div(
      tags$table(class="inspect-tbl driver-tbl",
        tags$thead(tags$tr(tags$th("Driver"), tags$th("Expected"), tags$th("r"), tags$th("n"), tags$th("Verdict"))),
        tags$tbody(rows)),
      p(class="qc-cap-note", style="margin-top:8px", bs_icon("info-circle"),
        HTML(" Expected sign/lag come from the ecology literature (see About), fixed before looking at the data. No verdict below 6 overlapping years &mdash; and at 6 years only a strong relationship (|r|&nbsp;&gt;&nbsp;0.8) can clear significance, so a &lsquo;counter&rsquo; result on a short series usually means <b>underpowered</b>, not <b>refuted</b>. That is exactly why the cross-site pooling on the Across&nbsp;NEON tab is the honest test.")))
  })

  # the most-informative link for the scatter = most overlapping years
  sel_link <- reactive({ lk <- lab_links(); lk <- lk[lk$n >= 3, , drop=FALSE]; if (!nrow(lk)) return(NULL)
    lk[which.max(lk$n), ] })

  output$linkScatter <- renderPlotly({
    r <- sel_link(); if (is.null(r)) return(note_plot("No driver has enough overlapping years to plot"))
    m <- lag_pairs(ann(), r$from, r$to, r$lag); if (!nrow(m)) return(note_plot("No overlapping years"))
    tm <- TIER_META[[r$tier]]
    md <- if (nrow(m) >= 7) "markers" else "markers+text"   # avoid year-label collision at n>=7
    p <- plotly::plot_ly(m, x=~x, y=~y, type="scatter", mode=md, text=~year, textposition="top center",
      customdata=~year, textfont=list(size=9, color=if(is_dark())"#9fb0c4" else "#6b7a85"),
      marker=list(size=11, color=DDL$sky, line=list(color="#fff", width=1)),
      hovertemplate=paste0("year %{text} · tap for detail<br>",sig_label(r$from),"=%{x}<br>",sig_label(r$to),"=%{y}<extra></extra>"))
    # tier-honest fit line: GOLD only when the link clears the bar; thin GREY "shape only"
    # for apparent/counter; OMITTED below n=6 (a slope on 5 points is theatre, not evidence)
    if (r$n >= 6 && is.finite(r$r)) { fit <- stats::lm(y ~ x, data=m); xr <- range(m$x)
      consistent <- identical(r$tier, "consistent")
      p <- p %>% plotly::add_lines(x=xr, y=predict(fit, newdata=data.frame(x=xr)), inherit=FALSE,
        line=list(color=if (consistent) DDL$gold2 else "#9aa6b2", width=2, dash="dot"), showlegend=FALSE, hoverinfo="skip") }
    # on-figure stats — so a screenshot of the scatter carries its own evidence
    stat_txt <- if (r$n >= 6 && is.finite(r$r))
        sprintf("r = %+.2f   n = %d   p = %.3f%s", r$r, r$n, r$p,
                if (is.finite(r$lo)) sprintf("\n95%% CI [%.2f, %.2f]", r$lo, r$hi) else "")
      else if (is.finite(r$r)) sprintf("r = %+.2f   n = %d\n(exploratory: too few years for a p)", r$r, r$n)
      else sprintf("n = %d, too few overlapping years to fit", r$n)
    # shared-trend check (Cass, n>=8 only): the year-to-year CHANGE correlation. Agreeing in
    # sign with the level r means the link survives detrending; disagreeing flags a possible
    # shared trend. A diagnostic shown alongside, never a verdict input (differencing burns a
    # df, so it is suppressed below n=8 where it would be a coin flip).
    if (r$n >= 8 && is.finite(r$r)) {
      dr <- suppressWarnings(stats::cor(diff(m$x), diff(m$y)))
      if (is.finite(dr)) stat_txt <- paste0(stat_txt, sprintf("\nyear-to-year change: r = %+.2f", round(dr, 2)))
    }
    anns <- list(list(x=0.02, y=0.98, xref="paper", yref="paper", xanchor="left", yanchor="top",
      text=gsub("\n","<br>", stat_txt), showarrow=FALSE, align="left",
      font=list(size=12, color=tm$col, family="Rubik"),
      bgcolor=if(is_dark())"rgba(20,30,45,0.72)" else "rgba(255,255,255,0.82)", bordercolor=tm$col, borderwidth=1, borderpad=4))
    if (!(r$n >= 6 && is.finite(r$r)))
      anns <- c(anns, list(list(x=0.5, y=0.02, xref="paper", yref="paper", xanchor="center", yanchor="bottom",
        text="No trend line below 6 years; read the points, not a slope.", showarrow=FALSE,
        font=list(size=10, color=if(is_dark())"#9fb0c4" else "#6b7a85"))))
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
      div(style=sprintf("color:%s;margin-top:4px", tm$col), bs_icon(tm$icon), " ", r$verdict),
      # stat-honesty labels on the two reported numbers (only meaningful once the link is gated)
      if (r$n >= 6 && is.finite(r$p)) div(class="scatter-statcaveats",
        span(class="ssc-item", bs_icon("info-circle"),
          HTML(" <b>p</b> is a permutation null"), cpop("permp"),
          HTML(sprintf(": with %d years its smallest possible value is 1/%d=%.2f, so a short series can't reach 0.05 here. It does not set the verdict; the honest test is the cross-site pooling on Across NEON.", r$n, r$n, 1/r$n)),
          if (is.finite(r$lo)) tagList(HTML(" <b>95% CI</b> is a bootstrap interval"), cpop("bootci"),
            HTML(": wide at this n, indicative, not a precision claim.")))))
  })

  # ---- tap a scatter dot -> that year's full detail ----
  output$scatterDetail <- renderUI({
    yr <- scatterYear(); r <- sel_link(); if (is.null(yr) || is.null(r)) return(NULL)
    a <- ann(); drow <- a[a$year == yr, , drop = FALSE]; if (!nrow(drow)) return(NULL)
    rrow <- a[a$year == (yr + r$lag), , drop = FALSE]
    f <- function(v) if (length(v) == 0 || !is.finite(v)) "—" else format(round(v, 1), big.mark = ",", trim = TRUE)
    dv <- drow[[r$from]][1]; rv <- if (nrow(rrow)) rrow[[r$to]][1] else NA_real_
    sigs <- LADDER_KEYS[vapply(LADDER_KEYS, function(k) length(drow[[k]]) && is.finite(drow[[k]][1]), logical(1))]
    div(class = "scatter-detail",
      div(class = "sd-head", bs_icon("calendar-event"), tags$b(sprintf(" %d · %s", yr, input$site)),
        actionLink("clearScatter", bs_icon("x-lg"), class = "sd-clear", title = "close")),
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
  # A FOLDED tool that lets a user re-examine a STATED prior by sliding the lag and
  # toggling annual vs seasonal climate. Designed so p-hacking is VISIBLE and self-
  # defeating: every off-prior reading is greyed as "EXPLORED, not a verdict", the
  # adjusted p penalizes the K-combination search AND the annual autocorrelation, and
  # an n<6 hard-gate refuses a p at all. The fixed-prior verdict chips / driverTable
  # are untouched — the experimenter never alters them.
  # ============================================================================
  # the stated priors for the CURRENT response, as "<from> -> <to>" choices
  exp_choices <- reactive({
    lk <- lab_links(); if (!nrow(lk)) return(character(0))
    ids <- sprintf("%s|%s", lk$from, lk$to)
    nms <- sprintf("%s → %s", vapply(lk$from, sig_label, character(1)), vapply(lk$to, sig_label, character(1)))
    stats::setNames(ids, nms)
  })
  output$expLinkUI <- renderUI({
    ch <- exp_choices()
    if (!length(ch)) return(div(class = "le-empty", "No predicted drivers for this response to explore."))
    sl <- sel_link(); def <- if (!is.null(sl)) sprintf("%s|%s", sl$from, sl$to) else unname(ch[1])
    if (!def %in% ch) def <- unname(ch[1])
    selectInput("expLink", "Predicted link", choices = ch, selected = def, width = "100%")
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
         conf = if ("conf" %in% names(r)) r$conf else NA_character_)
  })
  # season radios only when the driver is a climate signal (precip or temp)
  output$expSeasonUI <- renderUI({
    el <- exp_link(); if (is.null(el) || !el$from %in% c("precip","temp")) return(NULL)
    radioButtons("expSeason", "Climate driver",
      c("Annual total" = "annual", "Seasonal (winter / monsoon)" = "seasonal"),
      selected = isolate(input$expSeason) %||% "annual", inline = TRUE)
  })
  # the candidate set the user can scan (this is K): every lag 0:3 x reachable season
  exp_combos <- reactive({
    el <- exp_link(); if (is.null(el)) return(list())
    seasons <- if (el$from %in% c("precip","temp")) c("annual","seasonal") else "annual"
    cm <- list()
    for (se in seasons) for (L in 0:3)
      cm[[length(cm) + 1L]] <- list(col = exp_driver_col(el$from, se, el$to), lag = L)
    cm
  })
  # the SELECTED driver column + its season (annual when the driver isn't climate)
  exp_sel_season <- reactive({
    el <- exp_link(); if (is.null(el)) return("annual")
    if (el$from %in% c("precip","temp")) (input$expSeason %||% "annual") else "annual"
  })
  exp_sel_col <- reactive({ el <- exp_link(); if (is.null(el)) return(NULL)
    exp_driver_col(el$from, exp_sel_season(), el$to) })

  output$expCurve <- renderPlotly({
    el <- exp_link(); if (is.null(el)) return(note_plot("Pick a predicted link to explore"))
    a <- ann(); col <- exp_sel_col(); to <- el$to
    cur <- exp_curve(a, col, to, 0:3); if (is.null(cur) || !nrow(cur)) return(note_plot("No overlapping years to plot"))
    seasonal <- identical(exp_sel_season(), "seasonal")
    # base curve: all-lag r, points with n<3 hollow/greyed
    solid <- cur[is.finite(cur$r) & cur$n >= 3, , drop = FALSE]
    thin  <- cur[is.finite(cur$r) & cur$n <  3, , drop = FALSE]
    p <- plotly::plot_ly()
    p <- p %>% plotly::add_trace(data = cur, x = ~lag, y = ~r, type = "scatter", mode = "lines",
      line = list(color = "#9fb0cf", width = 2, dash = "solid"), name = "r by lag",
      hoverinfo = "skip", showlegend = FALSE, connectgaps = TRUE)
    if (nrow(solid)) p <- p %>% plotly::add_trace(data = solid, x = ~lag, y = ~r, type = "scatter", mode = "markers",
      marker = list(size = 11, color = "#43b8e8", line = list(color = "#fff", width = 1)), name = "tested (n>=3)",
      text = ~sprintf("lag %d: r=%+.2f (n=%d)", lag, r, n), hoverinfo = "text", showlegend = FALSE)
    if (nrow(thin)) p <- p %>% plotly::add_trace(data = thin, x = ~lag, y = ~r, type = "scatter", mode = "markers",
      marker = list(size = 10, color = "rgba(159,176,207,0.35)", line = list(color = "#9fb0cf", width = 1)),
      text = ~sprintf("lag %d: n=%d (too few years)", lag, n), hoverinfo = "text", showlegend = FALSE)
    # SRER-style overlay: when seasonal, draw the faint ANNUAL driver line on the same axes
    if (seasonal) { acur <- exp_curve(a, el$from, to, 0:3)
      if (!is.null(acur) && nrow(acur)) p <- p %>% plotly::add_trace(data = acur, x = ~lag, y = ~r,
        type = "scatter", mode = "lines+markers", line = list(color = "rgba(159,176,207,0.55)", width = 1.6, dash = "dot"),
        marker = list(size = 6, color = "rgba(159,176,207,0.55)"), name = "annual driver (faint)",
        text = ~sprintf("annual, lag %d: r=%s (n=%d)", lag, ifelse(is.finite(r), sprintf("%+.2f", r), "-"), n),
        hoverinfo = "text", showlegend = TRUE) }
    # the LOCKED GOLD DIAMOND at the prior lag (fixed before looking)
    pl <- el$prior_lag; prow <- cur[cur$lag == pl, , drop = FALSE]
    py <- if (nrow(prow) && is.finite(prow$r)) prow$r[1] else 0
    p <- p %>% plotly::add_trace(x = c(pl), y = c(py), type = "scatter", mode = "markers",
      marker = list(size = 18, color = "#ffd24a", symbol = "diamond", line = list(color = "#fff", width = 1.5)),
      name = "prior lag (locked)", hoverinfo = "text",
      text = sprintf("Prior: lag %d %s (fixed before looking)", pl, exp_sel_season()), showlegend = TRUE)
    seas_lab <- sprintf("Prior: lag %d %s (fixed before looking)", pl, exp_sel_season())
    shp <- list(
      list(type = "line", x0 = -0.2, x1 = 3.2, y0 = 0, y1 = 0, xref = "x", yref = "y",
           line = list(color = if (is_dark()) "rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)", width = 1)),
      list(type = "line", x0 = pl, x1 = pl, y0 = -1, y1 = 1, xref = "x", yref = "y",
           line = list(color = "#ffd24a", width = 1.4, dash = "dash")))
    anns <- list(list(x = pl, y = 1, xref = "x", yref = "y", yanchor = "bottom", xanchor = if (pl >= 2) "right" else "left",
      text = seas_lab, showarrow = FALSE, font = list(size = 10, color = "#e0b43a", family = "Rubik")))
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
    # naive single-lag permutation p (the un-adjusted, over-confident number)
    naive <- if (n >= 6 && is.finite(observed_r))
        link_stat(a, col, to, input$expLag %||% el$prior_lag, el$prior_sign)$p else NA_real_
    # best-of-K, autocorrelation-preserving adjusted p for the SELECTED (col, lag)
    adj <- if (n >= 6 && is.finite(observed_r)) exp_adj_p(a, to, combos, observed_r) else NA_real_
    # bootstrap CI on the selected pairing (only meaningful at n>=6)
    ci <- if (n >= 6 && is.finite(observed_r)) {
        set.seed(11L); bs <- replicate(2000, { i <- sample(n, n, replace = TRUE)
          suppressWarnings(stats::cor(m$x[i], m$y[i])) })
        c(lo = unname(round(stats::quantile(bs, 0.025, na.rm = TRUE), 2)),
          hi = unname(round(stats::quantile(bs, 0.975, na.rm = TRUE), 2))) } else c(lo = NA_real_, hi = NA_real_)
    on_prior <- (input$expLag %||% el$prior_lag) == el$prior_lag &&
                (if (el$from %in% c("precip","temp")) season == "annual" else TRUE)
    # Sidak bar: the alpha you'd actually need after viewing K candidates
    sidak <- round(1 - (1 - 0.05)^max(K, 1), 3)
    n_ok <- n >= 6
    # ---- tier badge: teal "on the prior" vs grey "EXPLORED, not a verdict" ----
    badge <- if (on_prior)
        span(class = "le-badge le-onprior", bs_icon("lock-fill"), " you're on the prior")
      else
        span(class = "le-badge le-explored", bs_icon("search"), " EXPLORED: not a verdict")
    # the adjusted-p line: struck-through/greyed + asterisk when OFF the prior, hard-greyed at n<6
    adj_disp <- if (!n_ok)
        span(class = "le-adjp le-ngate", bs_icon("slash-circle"), " n<6: exploratory, no verdict")
      else if (is.na(adj))
        span(class = "le-adjp le-ngate", "p unavailable at this pairing")
      else if (on_prior)
        span(class = "le-adjp le-adjp-live", sprintf("p_adj = %.3f", adj))
      else
        span(class = "le-adjp le-adjp-off", tags$s(sprintf("p_adj = %.3f", adj)), tags$sup("*"))
    rline <- span(class = "le-r",
      if (is.finite(observed_r)) sprintf("r = %+.2f", observed_r) else "r = —",
      span(class = "le-n", sprintf("  n = %d", n)))
    naive_line <- if (n_ok && is.finite(naive))
      div(class = "le-naive", sprintf("un-adjusted, single-lag p = %.3f", naive),
        span(class = "le-naive-note", " (overstates significance when you scan)"))
    ci_line <- if (n_ok && is.finite(ci[["lo"]]))
      div(class = "le-ci", sprintf("bootstrap 95%% CI [%.2f, %.2f]", ci[["lo"]], ci[["hi"]]),
        span(class = "le-naive-note", " (wide at this n; indicative, not a precision claim)"))
    sidak_line <- div(class = "le-sidak", bs_icon("shield-exclamation"),
      sprintf(" to claim significance after viewing K = %d candidates, you'd need p < %.3f", max(K, 1), sidak))
    # the desert-demo caption, only when the demo pairing is loaded
    demo_caption <- if (identical(col, "precip_monsoon") && identical(to, "mammal_cpue") &&
                        season == "seasonal" && (input$expLag %||% 0) == 1)
      div(class = "le-demo-caption", bs_icon("brightness-high"),
        HTML(" The signal is not in a better lag, it is in the right <b>SEASON</b>. Annual rain (faint) stays flat at every lag; only monsoon rain at lag 1 lifts, exactly where the seed-crop mechanism predicts. n=7, p=0.06: a vivid illustration, not an established result."))
    div(class = paste0("le-readout", if (!on_prior) " le-readout-explored" else ""),
      div(class = "le-headline",
        badge,
        span(class = "le-adjp-label",
          sprintf(" p adjusted for searching K = %d candidates (best-of-K, autocorrelation-preserving): ", max(K, 1))),
        adj_disp),
      div(class = "le-stats", rline, naive_line, ci_line),
      sidak_line,
      if (!on_prior && n_ok && !is.na(adj))
        div(class = "le-offnote", tags$sup("*"),
          " a p you reached by sliding off the prior is not a clean result: it is one of many you searched, shown struck through for that reason."),
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
      showNotification("This pairing needs the small-mammal response. Set 'Driver Lab: explain…' to 'Small-mammal catch rate' on the Overview, then try again.",
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
    tagList(
      div(class="qc-section-h", bs_icon("clipboard-check"), " Cascade data-quality review ",
        tags$span(class="qcf-sub", "· verify, not errors"),
        info_pop("Why these are flags, not bugs",
          p("The cascade's QC choices are ", tags$b("correct"), ": the ≥5-individual green-up gate, the within-site MAD temperature filter, the CI-spans-zero guard on “apparent” links."),
          p("This panel surfaces ", tags$b("where those rules bit"), " for the selected site, ranked worst-first, so a reader verifies a thin or missing value before reading too much into it. Tap any flag to list the exact rows behind it."))),
      div(class="qc-flags", lapply(qf, function(f){
        clickable <- !identical(f$level, "clean") && f$n > 0
        div(class = paste0("qc-flag qc-flag-", f$level, if (clickable) " qc-flag-click" else ""),
          role = if (clickable) "button" else NULL, tabindex = if (clickable) "0" else NULL,
          onclick = if (clickable) sprintf("Shiny.setInputValue('qcInspect','%s',{priority:'event'})", f$key) else NULL,
          bs_icon(qc_icon(f$level)),
          div(class="qcf-body",
            div(class="qcf-title", f$title, if (f$n > 0) tags$span(class="qcf-n", f$n)),
            div(class="qcf-detail", f$detail)),
          if (clickable) tags$span(class="qcf-go", bs_icon("chevron-right"))) })),
      if (has_real) div(class="qcf-hint", bs_icon("hand-index-thumb"),
        " tap a flag to list the exact rows behind it"),
      uiOutput("qcInspect"),
      div(class="qc-toolbar",
        downloadButton("dlQcReport", tagList(bs_icon("filetype-csv"), " Download QC report (CSV)"),
          class="btn-outline-dark btn-sm")))
  })

  # clickable inspector: the exact offending rows for the tapped flag
  output$qcInspect <- renderUI({
    key <- input$qcInspect; q <- qc(); req(!is.null(key), key %in% names(q$sets))
    st <- q$sets[[key]]; req(!is.null(st), nrow(st))
    f <- Filter(function(x) identical(x$key, key), q$flags)[[1]]
    cols <- names(st); head_n <- min(nrow(st), 200L); sv <- st[seq_len(head_n), cols, drop=FALSE]
    fmt <- function(v) if (is.numeric(v)) ifelse(is.na(v), "—", format(round(v, 2), trim=TRUE)) else format(v)
    div(class="qc-inspector",
      div(class="qci-head", bs_icon(qc_icon(f$level)),
        tags$b(sprintf(" %s · %d row%s", f$title, f$n, if (f$n==1) "" else "s"))),
      div(class="qc-cap-scroll", tags$table(class="inspect-tbl",
        tags$thead(tags$tr(lapply(cols, tags$th))),
        tags$tbody(lapply(seq_len(nrow(sv)), function(i)
          tags$tr(lapply(cols, function(cc) tags$td(fmt(sv[[cc]][i])))))))),
      if (nrow(st) > head_n) p(class="qc-cap-note", sprintf("Showing first %d of %d.", head_n, nrow(st))))
  })
  output$dlQcReport <- downloadHandler(
    filename = function() sprintf("%s-cascade-qc-report.csv", input$site),
    content = function(file){ rep <- cascade_qc_report(ann(), links(), SIGNALS, input$site)
      if (is.null(rep)) rep <- data.frame(note="No data-quality flags at this site.")
      hdr <- c(sprintf("# NEON Driver Cascade · %s data-quality review (verify, not wrong).", input$site),
               "# Each flag is a value worth a second look, not an error; the cascade's QC rules are correct.", "")
      writeLines(hdr, file)
      suppressWarnings(utils::write.table(rep, file, sep=",", row.names=FALSE, append=TRUE, qmethod="double")) })

  # ---- top-bar Report: the focal site's report card (one self-describing CSV) ----
  # Reuses the existing reactives/helpers: the verdict sentence, the annual signals,
  # the biome-aware link scorecard, and the QC review. Sections are stacked in one
  # file so the export is the site's whole story, not a single table.
  output$dlReport <- downloadHandler(
    filename = function() sprintf("driver-cascade-%s-report-card.csv", input$site),
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
        sprintf("# NEON Driver Cascade - site report card: %s (%s%s)", s, nm,
                if (nzchar(st)) paste0(", ", st) else ""),
        sprintf("# Biome class: %s", site_blabel(s)),
        sprintf("# Years on record: %d", nrow(a)),
        sprintf("# Expected links matching their predicted direction: %s",
                if (!is.na(sm$n) && sm$n > 0) sprintf("%d of %d (sign-match p = %s)",
                  sm$k, sm$n, if (!is.na(sm$p)) format(round(sm$p, 3)) else "NA") else "too few overlapping years"),
        sprintf("# Verdict: %s", verdict),
        "# An educational synthesis tool. r-values are within-site only; never read as causation.",
        ""), con)
      # section 1: annual signals
      writeLines("## Annual signals (one row per year)", con)
      suppressWarnings(utils::write.table(a, con, sep = ",", row.names = FALSE, qmethod = "double"))
      writeLines("", con)
      # section 2: link scorecard
      if (!is.null(lk) && nrow(lk)) {
        writeLines("## Predicted-link scorecard (within-site)", con)
        suppressWarnings(utils::write.table(lk, con, sep = ",", row.names = FALSE, qmethod = "double"))
        writeLines("", con)
      }
      # section 3: QC review (verify, not wrong)
      qcrep <- tryCatch(cascade_qc_report(a, lk, SIGNALS, s), error = function(e) NULL)
      writeLines("## Data-quality review (verify, not wrong - each flag is a value to look at, not a bug)", con)
      if (is.null(qcrep) || !nrow(qcrep))
        writeLines("All clear - no flags at this site.", con)
      else
        suppressWarnings(utils::write.table(qcrep, con, sep = ",", row.names = FALSE, qmethod = "double"))
    })

  # ---- About ----
  output$aboutPanel <- renderUI({
    pr <- PRIORS
    conf_badge <- function(c) { col <- switch(c %||% "", strong="#1a7f37", moderate="#c9a300", weak="#AB0520", "#6b7a89")
      tags$span(class="dt-chip", style=sprintf("background:%s", col), c %||% "—") }
    prow <- function(i){ r <- pr[i,]; arrow <- if (r$sign>0) "↑ more → more" else "↓ more → earlier/less"
      tags$tr(tags$td(sig_label(r$from)), tags$td(sig_label(r$to)), tags$td(arrow),
        tags$td(if (r$lag>0) sprintf("%d yr later", r$lag) else "same yr"),
        tags$td(conf_badge(r$conf)), tags$td(class="pr-note", r$note)) }
    gloss <- function(term, def) div(class="gloss-item", tags$b(term), tags$span(HTML(def)))
    div(class="about-wrap",
      div(class="about-card", h4("\U0001F517 What this is"),
        p("The capstone of a family of NEON explorers. Each sibling app dives into one product: small mammals, birds, plant diversity, vegetation structure, plant phenology. This one ", tags$b("lines them up"),
          " at shared sites into a single ", tags$b("bottom-up cascade"), ": climate → green-up timing → producers → consumers.")),

      div(class="about-card about-plain", h4(bs_icon("chat-square-text"), " How to read this, in plain English"),
        p("New to this? Start here. Everything below is jargon-free."),
        gloss("The big idea", "Weather sets off a chain reaction through the food web. A wet or warm year first changes the <b>plants</b>, then the <b>animals</b> that eat the plants, like dominoes, from the ground up. This app checks whether each domino actually falls the way ecology says it should."),
        gloss("Green-up", "The moment in spring when plants leaf out and the landscape turns green. We measure it as the <b>day of the year the first leaves appear</b>; a smaller number means an earlier spring."),
        gloss("The “hinge”", "Green-up is the hinge between weather and wildlife: the climate decides <em>when</em> plants wake up, and that sets the table for everything that eats them."),
        gloss("A “lag”", "A delay. A <b>1-year lag</b> means this year's rain shows up in <em>next</em> year's animals, because it takes a season for rain to grow the seeds the animals depend on."),
        gloss("Catch rate (per 100 trap-nights)", "How many small mammals were caught for every 100 trap-nights of effort. It accounts for how hard we trapped, so years compare fairly, but it's a <b>relative index, not a true headcount</b>."),
        gloss("The stacked “ladder”", "Each strip is one rung of the food web, drawn on a <b>standardised</b> scale so they're comparable: <b>0 = that signal's own average year</b>, up = above average, down = below. Watch whether a good year ripples <em>down</em> the rungs; compare the <b>timing</b> of the bumps across strips, not their heights."),
        gloss("Why deserts are the clearest case", "In deserts, water is the one thing everything waits for. When rain comes, the whole food web responds at once and in step, so the chain reaction is easier to see than in wetter places, where many other things also matter.")),

      div(class="about-card about-plain", h4(bs_icon("calculator"), " The statistics, in plain English"),
        gloss("“Could this be luck?” (the permutation test)", "For each link we <b>shuffle the years 2,000 times</b> and re-measure the match each time. If the real match beats almost all the shuffles, it's unlikely to be a coincidence. (We checked: these yearly numbers aren't badly auto-correlated, so the shuffle is a fair test.)"),
        gloss("The uncertainty band (95% CI)", "A range we're fairly sure the true relationship falls in. With only ~6 years it's <b>very wide</b>, and that honesty is the point: few years = lots of uncertainty."),
        gloss("“Too few years to judge”", "Below <b>6 overlapping years</b> we show the lined-up data but give <b>no verdict</b>; there simply isn't enough to tell signal from noise."),
        gloss("The three verdicts", "<b>Aligned</b> = points the expected direction <em>and</em> the bootstrap interval excludes zero (a clean per-site direction, not a significance claim). <b>Apparent</b> = points the expected way but the interval still crosses zero. <b>Counter</b> = runs the opposite way. Significance is never a per-site claim here, it lives only in the cross-site pooling."),
        gloss("Sign-match score", "Of the testable links (≥6 years), how many point the direction ecology predicts. Even when no single link is rock-solid, several all pointing the right way is itself meaningful, and we report the odds it's chance."),
        p(class="qc-cap-note", bs_icon("info-circle"), " We never say a driver “causes” anything; a handful of yearly points can't prove cause. These are <em>consistencies with</em> the textbook mechanism, not proof.")),

      local({
        meta <- tryCatch(readRDS("data/cascade_meta.rds"), error = function(e) NULL)
        gp <- if (!is.null(meta)) Filter(function(x) isTRUE(x$poolable), meta) else list()
        div(class = "about-card about-plain", h4(bs_icon("graph-up-arrow"), " Companion test: a meta-analysis of the green-up rung"),
          p(HTML("The headline pooled statistic is the <b>binomial sign test</b> (how many sites agree in direction). As a companion, and ONLY on the well-replicated green-up rung (the ~32-site link where between-site heterogeneity is estimable), we also run a <b>random-effects meta-analysis</b> of the per-site correlations. It adds a pooled effect size and a direct probability of the predicted direction; it <b>corroborates</b> the headline, it does not replace it.")),
          if (length(gp)) tags$ul(class = "meta-list", lapply(gp, function(r) { rma <- r$rma
            tags$li(HTML(sprintf("<b>%s &rarr; %s</b>: sign-match %s%s",
              sig_label(r$from), sig_label(r$to), r$sign_match,
              if (!is.null(rma)) sprintf("; pooled r = %+.2f [%.2f, %.2f], P(earlier green-up) = %.2f, between-site I&sup2; = %.0f%%",
                rma$pooled_r, rma$ci_r[1], rma$ci_r[2], rma$p_direction_predicted, rma$I2)
              else " (install the metafor package and re-run scripts/cascade_meta.R for the pooled estimate)"))) }))
          else p(class = "qc-cap-note", bs_icon("info-circle"),
            HTML(" Run <code>Rscript scripts/cascade_meta.R</code> to generate this companion (it writes data/cascade_meta.rds). It is computed offline, not in the app, because it needs the <code>metafor</code> package; it is run only on the green-up rung, never on the within-site indices.")),
          p(class = "qc-cap-note", "A high probability here corroborates the binomial headline with an effect size; it does not upgrade any per-site verdict, and it is reported only on the rung where the site count supports it."))
      }),

      div(class="about-card", h4(bs_icon("shield-check"), " Why it's careful (and what it refuses to do)"),
        tags$ul(
          tags$li(HTML("<b>States priors, doesn't dredge.</b> Each link's expected direction and lag come from the literature <em>before</em> looking at the data; we never report whichever lag happens to fit best.")),
          tags$li(HTML("<b>n-gated.</b> Below 6 overlapping years, no verdict, just the lined-up series. At n&ge;6 the bootstrap interval sets the per-site DIRECTION verdict; a circular-shift permutation p is reported for transparency but cannot reach significance at this n (its floor is 1/n), that is the cross-site pooled test's job.")),
          tags$li(HTML("<b>Honest about scope.</b> Several of these mechanisms are clearest <em>across regions</em> or in <em>deserts</em>; testing them within one site, year-to-year, is the hardest case, and the notes say so.")),
          tags$li(HTML("<b>Direction over magnitude</b>, and <b>never “drives”/“causes.”</b>")))),

      div(class="about-card", h4(bs_icon("diagram-3"), " The predicted cascade (the priors)"),
        tags$table(class="inspect-tbl",
          tags$thead(tags$tr(tags$th("Driver"), tags$th("Response"), tags$th("Expected"), tags$th("Lag"), tags$th("Confidence"), tags$th("In plain English"))),
          tags$tbody(lapply(seq_len(nrow(pr)), prow))),
        p(class="qc-cap-note", style="margin-top:8px", HTML("Sources: warmer-springs→earlier green-up · <b>Fu et al. 2015</b> (Nat. Comms.), Richardson et al. 2013; rain→desert rodents (lagged, non-linear) · <b>Brown &amp; Ernest 2002</b>, Thibault et al. 2010; rain-timing · Zhang et al. 2021; dryland productivity~precipitation · Sala et al. 1988, Huxman et al. 2004, Knapp et al. 2017; the “green wave” · Merkle et al. 2016. A green-up→bird link is <b>deliberately omitted</b>: the mismatch literature is about timing-synchrony, not “later green-up → more birds.”"))),

      div(class="about-card", h4(bs_icon("database"), " Data & honest limits"),
        p("Per-site annual signals assembled from the five sibling apps' bundles plus the NEON-tower climate overlays. ",
          tags$b("Small-mammal catch rate"), " is a relative annual index (captures per 100 deployed trap-nights), not effort-standardised across sites, so read within-site trends only. ",
          tags$b("Temperature"), " is the year's average, a stand-in for spring warmth that works where temperature limits green-up (temperate/boreal) but not in warm deserts, where water is the trigger. ",
          tags$b("Plant richness"), " (species count) is a COMPOSITION signal, not productivity. In drylands it can even fall in wet years, so its priors are weak and biome-scoped."),
        p(bs_icon("envelope"), " ", tags$a(href="mailto:desertdatalabs@gmail.com","desertdatalabs@gmail.com"))),

      div(class="about-card", h4(bs_icon("table"), " Codebook & data downloads"),
        p("Every signal, its units, how it's derived, and the n-gates, plus analysis-ready CSV exports."),
        uiOutput("codebook")),

      cascade_sources(),

      div(class="about-card", h4(bs_icon("award"), " Data attribution & license"),
        p(class="qc-cap-note",
          "Built with data from the National Ecological Observatory Network (NEON), a U.S. National Science Foundation program operated by Battelle. NEON data are provided under a Creative Commons Attribution 4.0 International (CC BY 4.0) license (",
          tags$a(href="https://creativecommons.org/licenses/by/4.0/", target="_blank", "creativecommons.org/licenses/by/4.0"),
          "). This app aggregates and derives summary metrics from the raw NEON data products; the underlying measurements are unaltered. It is an independent, unofficial tool and is not endorsed by NEON, Battelle, or the NSF."),
        p(class="qc-cap-note", style="margin-top:6px",
          "A multi-product synthesis joining: small mammals (DP1.10072.001), breeding birds (DP1.10003.001), plant diversity (DP1.10058.001), vegetation structure (DP1.10098.001), plant phenology (DP1.10055.001), mosquitoes (DP1.10043.001), and NEON climate overlays (air temperature DP1.00002.001, precipitation DP1.00044.001), each provided under CC BY 4.0.")))
  })
  # ---- SEASONAL CLIMATE reveal (the desert insight made visible) ----
  output$seasonalPlot <- renderPlotly({
    a <- ann(); req(nrow(a))
    if (!is_desert(input$site)) return(note_plot("One main rain season here; the winter/monsoon split is for bimodal desert sites."))
    d <- a[is.finite(a$precip_winter) | is.finite(a$precip_monsoon), c("year","precip_winter","precip_monsoon")]
    if (!nrow(d)) return(note_plot("No seasonal precipitation reconstructed for this site yet."))
    plotly::plot_ly(d, x=~year) %>%
      plotly::add_bars(y=~precip_winter, name="Winter rain (Oct–Mar)", marker=list(color="#43b8e8")) %>%
      plotly::add_bars(y=~precip_monsoon, name="Monsoon rain (Jul–Sep)", marker=list(color="#ffd24a")) %>%
      theme_plotly() %>% plotly::layout(barmode="group", legend=list(orientation="h", y=-0.22),
        yaxis=list(title="precipitation (mm)"), xaxis=list(title="", dtick=1), margin=list(l=55,r=20,t=10,b=40))
  })
  output$seasonalPanel <- renderUI({
    if (!is_desert(input$site)) return(div(class="seasonal-note", bs_icon("info-circle"),
      HTML(" Not a bimodal-desert site. The annual rainfall total already captures its one main rain season, so the cascade is tested on annual climate.")))
    a <- ann()
    # return r WITH its n — so the contrast carries its own sample size (these are
    # single-site, short-series numbers below the app's n>=6 verdict gate; we show
    # them as an illustrative contrast, never a result — the n and the popover say so).
    rc <- function(from,to,lag){ if (!all(c(from,to) %in% names(a))) return(list(r=NA_real_, n=0L))
      m <- lag_pairs(a, from, to, lag); if (nrow(m) < 4) return(list(r=NA_real_, n=nrow(m)))
      list(r=round(stats::cor(m$x, m$y), 2), n=nrow(m)) }
    ann_mam <- rc("precip","mammal_cpue",1);  mon_mam <- rc("precip_monsoon","mammal_cpue",1)
    ann_rich <- rc("precip","plant_richness",0); win_rich <- rc("precip_winter","plant_richness",0)
    rv <- function(x) if (is.na(x$r)) "—" else sprintf("r = %+.2f", x$r)
    rn <- function(x) if (x$n > 0) span(class="sc-n", sprintf(" n=%d", x$n)) else NULL
    # CVD: the contrast between the weak (annual) and strong (seasonal) r must NOT rest on
    # colour alone (the two greens sit near 1.2:1 luminance). Pair the STRONG value with a
    # non-colour cue (up-arrow + a "stronger" chip), and carry the honest stats (n + the
    # p where it's the headline monsoon link) right on the number, never colour-only.
    cmp <- function(lab, a1, lab1, a2, lab2, strong_p = NA_real_) {
      strong_p_lab <- if (!is.na(a2$r) && is.finite(strong_p))
        span(class="sc-p", sprintf(" p=%.2f", strong_p)) else NULL
      strong_cue <- if (!is.na(a2$r))
        span(class="sc-stronger", bs_icon("arrow-up-short"), "stronger") else NULL
      div(class="seasonal-cmp",
        div(class="sc-title", lab),
        div(class="sc-row", span(class="sc-k", lab1), span(class="sc-v sc-weak", rv(a1), rn(a1))),
        div(class="sc-row", span(class="sc-k", lab2),
          span(class="sc-v sc-strong", rv(a2), rn(a2), strong_p_lab, strong_cue)))
    }
    div(
      insight_banner("droplet-half", tone="navy", HTML("A single <b>annual</b> rainfall number blends two independent seasons. Split them, and the desert cascade reappears: the right season carries the signal the annual total buries:"),
        info_pop("Illustrative, not significant", HTML("This is a <b>single-site contrast</b> at the one desert site where the seasonal split is testable, on a short series <b>below the app's n&ge;6 verdict gate</b>. The seasonal r's are larger than the annual ones, but they are <b>not</b> statistically significant (e.g. monsoon&rarr;rodents reaches r=+0.72 at n=7, p=0.06) and they pool across just one site. Read it as a vivid illustration of the annual-aggregation artifact, not an established desert result. The honest, cross-site test is on the Across&nbsp;NEON tab."))),
      div(class="seasonal-cmps",
        # the monsoon->rodents r carries its p (suggestive, p~0.06 at n=7) so the
        # "stronger" cue can never be read as "significant"; richness has no gated p here
        cmp("Rain → next-year rodents", ann_mam, "annual rain", mon_mam, "monsoon seed crop", strong_p = 0.06),
        cmp("Rain → plant richness", ann_rich, "annual rain", win_rich, "winter (forb) rain")),
      p(class="precip-coverage-note", bs_icon("info-circle"),
        HTML(" Annual precipitation is available at 19 of 46 NEON sites; rain-driven rungs are testable only where the tower precip record exists.")))
  })

  # ---- ACROSS NEON: pooled headline + cross-site sign-match scoreboard ----
  output$pooledHeadline <- renderUI({
    pl <- POOLED; if (!nrow(pl)) return(NULL)
    # HARD floor: a binomial on 1–2 votes is not a pooled test (one vote always reads
    # 1/1, p=0.500). Such links must NOT sit in the headline rank beside the 32-site
    # result — split them out and demote them to a p-less "not poolable" footnote row.
    MIN_SITES <- 3L
    poolable <- if ("poolable" %in% names(pl)) pl$poolable %in% TRUE else pl$sites >= MIN_SITES
    rank <- pl[poolable, , drop=FALSE]; under <- pl[!poolable, , drop=FALSE]
    rank <- rank[order(rank$p), , drop=FALSE]
    items <- lapply(seq_len(nrow(rank)), function(i){ r <- rank[i,]
      sig <- is.finite(r$p) && r$p < 0.05
      div(class=paste0("pooled-row", if (sig) " pooled-sig" else ""),
        div(class="pl-link", HTML(sprintf("%s&nbsp;→&nbsp;%s", sig_label(r$from), sig_label(r$to))),
            if (r$lag>0) span(class="pl-lag", sprintf(" lag %dy", r$lag))),
        div(class="pl-bar-wrap", div(class="pl-bar", style=sprintf("width:%.0f%%", 100*r$k/r$sites))),
        div(class="pl-stat", tags$b(sprintf("%d/%d sites", r$k, r$sites)),
            span(class="pl-p", sprintf("p=%.3f", r$p)), span(class="pl-r", sprintf("median r=%+.2f", r$median_r))))
    })
    # under-floor links: shown demoted, no p-value, with a one-click "why?" caveat.
    under_rows <- if (nrow(under)) lapply(seq_len(nrow(under)), function(i){ r <- under[i,]
      div(class="pooled-row pooled-underfloor",
        div(class="pl-link", HTML(sprintf("%s&nbsp;→&nbsp;%s", sig_label(r$from), sig_label(r$to))),
            if (r$lag>0) span(class="pl-lag", sprintf(" lag %dy", r$lag))),
        div(class="pl-stat", span(class="pl-notpool", sprintf("%d site%s · not poolable", r$sites, if (r$sites==1) "" else "s")),
            span(class="pl-r", sprintf("median r=%+.2f", r$median_r))))
    }) else NULL
    # The headline rung is ONE mechanism (warmer springs -> earlier green-up) tested two
    # ways: on the annual-mean temperature stand-in it pools (p=0.010); on the
    # mechanistically-correct spring window it does NOT resolve (p=0.286). State that
    # tension ON the headline rather than letting the stronger row stand alone.
    gp_ann <- pl[pl$from=="temp"        & pl$to=="greenup_doy", , drop=FALSE]
    gp_spr <- pl[pl$from=="temp_spring" & pl$to=="greenup_doy", , drop=FALSE]
    tension <- if (nrow(gp_ann) && nrow(gp_spr) && is.finite(gp_ann$p[1]) && is.finite(gp_spr$p[1]))
      HTML(sprintf(" The same mechanism tested two ways carries a caveat: on <b>annual mean temperature</b> it holds (%d/%d sites, p=%.3f), but on the <b>mechanistic spring window</b> it does not resolve (%d/%d sites, p=%.3f) — read it as a coverage/proxy caveat, not a clean win: the annual mean is the better-sampled stand-in, the spring-only signal is thinner.",
        gp_ann$k[1], gp_ann$sites[1], gp_ann$p[1], gp_spr$k[1], gp_spr$sites[1], gp_spr$p[1]))
      else NULL
    div(insight_banner("trophy", tone="pine",
      HTML("Per-site series are too short for a verdict, but pooled <b>across sites</b> (one vote per site), the cascade's strongest rung is real: <b>warmer springs → earlier green-up</b> holds across most temperature-limited sites. This is the honest, suite-level answer no single site can give.")),
      p(class="qc-cap-note pooled-s4t", style="margin-top:8px", bs_icon("info-circle"),
        HTML(" <b>Pooled across sites, not years.</b> Each link is tested within each site, then we count how many sites agree in direction (one vote per site). This substitutes variation across space for variation through time (Damgaard 2019): it assumes the same mechanism operates the same way at every pooled site. We pool sign-agreement, not effect sizes, the conservative form of that assumption, but it remains an assumption, not within-site replication.")),
      if (!is.null(tension)) p(class="pooled-tension", bs_icon("exclamation-triangle"), tension),
      div(class="pooled-list", items),
      if (!is.null(under_rows)) div(class="pooled-under",
        div(class="pu-head", "Below the pooling floor (<3 sites)",
          info_pop("Not a pooled test", HTML("A pooled binomial needs at least <b>3 site votes</b> to mean anything; on 1–2 votes it is degenerate (a single vote always reads 1/1, p=0.500). These links are expected & testable at too few sites to pool, so we show them <b>without a p-value</b> rather than rank them beside the multi-site results. The desert seasonal priors live here: the cross-site sample isn't there yet."))),
        under_rows))
  })
  output$scoreboard <- renderUI({
    sl <- SUITE_LINKS; if (!nrow(sl)) return(p(class="qc-cap-note","Scoreboard unavailable (rebuild the data bundle)."))
    pr <- PRIORS
    hd <- lapply(seq_len(nrow(pr)), function(j) tags$th(class="sb-col",
      title=sprintf("%s → %s%s", sig_label(pr$from[j]), sig_label(pr$to[j]), if(pr$lag[j]>0) sprintf(" (lag %dy)", pr$lag[j]) else ""),
      HTML(sprintf("%s<br>→ %s", sig_abbr(pr$from[j]), sig_abbr(pr$to[j])))))
    sm <- SITE_META
    sm$em <- vapply(sm$site, function(s){ d <- sl[sl$site==s & sl$expected %in% TRUE & sl$n>=6 & !is.na(sl$sign_match),]; sum(d$sign_match) }, numeric(1))
    sm <- sm[order(sm$biome_class, -sm$em, sm$site), , drop=FALSE]
    rowfor <- function(s, blab){
      cells <- lapply(seq_len(nrow(pr)), function(j){
        d <- sl[sl$site==s & sl$from==pr$from[j] & sl$to==pr$to[j] & sl$lag==pr$lag[j], , drop=FALSE]
        if (!nrow(d)) return(tags$td(class="sb-cell sb-na"))
        tm <- TIER_META[[d$tier[1]]]; exp <- isTRUE(d$expected[1])
        # out-of-prior "hit": a consistent/apparent verdict FIRING OUTSIDE its biome.
        # Already dimmed, but a colour-scanner could still miscount it as an in-prior
        # win — so flag it with a subtle corner marker (the * in the cell) and say WHY
        # in the hover/tap title: out-of-biome corroboration, not an in-prior result.
        outprior_hit <- !exp && d$tier[1] %in% c("consistent","apparent")
        # the STRONGER case: a SIGNIFICANT out-of-biome hit (p<0.05 AND the sign matches
        # the prior). These are genuine corroboration that the mechanism generalizes past
        # its home biome (e.g. the C4-grass seed crop firing on the monsoon->rodents link
        # at KONZ/CPER). We mark them, but we do NOT widen expected_class — no post-hoc
        # class-widening; the cell stays out-of-tally, the mark just names the support.
        outprior_sig <- outprior_hit && is.finite(d$p[1]) && d$p[1] < 0.05 && isTRUE(d$sign_match[1])
        # plain-English mechanism phrase per link, for the "generalizes beyond" tooltip
        mech <- if (pr$from[j]=="precip_monsoon" && pr$to[j]=="mammal_cpue") "the C4-grass seed crop"
                else if (pr$to[j]=="greenup_doy") "warm-spring leaf-out"
                else if (pr$from[j]=="precip_monsoon" && pr$to[j]=="mosq_activity") "monsoon-water breeding"
                else "this driver mechanism"
        ttl <- sprintf("%s · %s → %s: %s (n=%d%s)", s, sig_label(pr$from[j]), sig_label(pr$to[j]), d$verdict[1], d$n[1], if (is.finite(d$r[1])) sprintf(", r=%.2f", d$r[1]) else "")
        if (outprior_sig) ttl <- paste0(ttl, sprintf(". OUT-OF-BIOME SUPPORT: the mechanism (%s) generalizes beyond deserts (p<0.05, sign matches). Corroboration only, not counted in this site's tally; the biome class is unchanged.", mech))
        else if (outprior_hit) ttl <- paste0(ttl, ". OUT OF PRIOR BIOME: corroborates the mechanism in a related biome, but doesn't count toward this site's tally.")
        # CVD: the verdict must not be COLOUR-ONLY (teal/coral fail red-green). Prefix the
        # cell with a tier glyph so shape always travels with the colour (Tufte; Okabe-Ito).
        gly <- switch(d$tier[1], consistent="✓", apparent="≈", counter="✗", exploratory="·", "")
        cell_txt <- if (is.finite(d$r[1])) {
          if (nzchar(gly)) sprintf("%s %+.2f", gly, d$r[1]) else sprintf("%+.2f", d$r[1])
        } else if (nzchar(gly)) gly else "·"
        tags$td(class=paste0("sb-cell sb-clk sb-", d$tier[1], if (!exp) " sb-dim" else "", if (outprior_hit) " sb-outprior" else "", if (outprior_sig) " sb-outprior-sig" else ""),
          title=ttl,
          onclick=sprintf("Shiny.setInputValue('sbCell','%s|%s|%s|%d',{priority:'event'})", s, pr$from[j], pr$to[j], pr$lag[j]),
          cell_txt)
      })
      ba <- site_ba(s)
      tags$tr(tags$td(class="sb-site",
        tags$a(href="#", class="sb-sitelink", onclick=sprintf("Shiny.setInputValue('goSite','%s',{priority:'event'});return false;", s), s),
        tags$div(class="sb-biome", blab,
          if (is.finite(ba)) tags$span(class="sb-ba", title="woody standing stock (live basal area)", sprintf(" · %s m²/ha", format(round(ba,1), nsmall=1))))), cells)
    }
    rows <- lapply(seq_len(nrow(sm)), function(i) rowfor(sm$site[i], sm$biome_label[i]))
    tagList(
      tags$table(class="sb-table",
        tags$thead(tags$tr(tags$th(class="sb-site","Site"), hd)),
        tags$tbody(rows)),
      p(class="qc-cap-note", style="margin-top:10px", bs_icon("info-circle"),
        HTML(" Each cell shows a <b>verdict glyph</b> and the <b>correlation r</b> for that link at that site: <span class='sb-key sb-consistent'>✓ aligned</span> <span class='sb-key sb-apparent'>≈ apparent</span> <span class='sb-key sb-counter'>✗ counter</span> <span class='sb-key sb-exploratory'>· &lt;6&nbsp;yr</span> <span class='sb-key sb-insufficient'>untestable</span>. <b>r</b> runs from −1 to +1: the <b>sign</b> is the direction (does the response move the way the prior predicts) and the <b>size</b> is how tightly the driver and response move together within that site (0 = no link, ±1 = in lockstep). The glyph carries the verdict so it never rests on colour alone. Faded cells aren't the mechanism <b>expected</b> for that biome; a faded cell with a <span class='sb-outprior-key'></span> <b>corner mark</b> still fired there: out-of-biome corroboration that doesn't count toward the tally. <b>Click any cell</b> for its full detail (r, years, interval, and the prior); click a site name to open it. The grey untestable majority is shown, not hidden; that honesty IS the coverage statement.")))
  })

  # ---- DOWNLOADS (the suite's signature export funnel) ----
  output$dlAnnual <- downloadHandler(
    filename = function() sprintf("%s-cascade-annual.csv", input$site),
    content = function(file) {
      a <- ann(); cols <- c("year", intersect(c(LADDER_KEYS, "precip_winter","precip_monsoon","temp_spring","mosq_richness","mosq_culex"), names(a)))
      hdr <- c(sprintf("# NEON Driver Cascade · %s (%s), %s", input$site, site_blabel(input$site), if (nrow(neon_sites[neon_sites$site==input$site,])) neon_sites$name[neon_sites$site==input$site][1] else input$site),
               "# Annual + seasonal signals. mammal_cpue is a within-site relative index (per 100 trap-nights), NOT cross-site standardized.",
               "# precip_winter = Oct-Mar sum (year it ends); precip_monsoon = Jul-Sep sum. See the codebook in the About tab.", "")
      writeLines(hdr, file)
      suppressWarnings(utils::write.table(a[, cols, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })
  output$dlLinks <- downloadHandler(
    filename = function() sprintf("%s-link-scorecard.csv", input$site),
    content = function(file) {
      lk <- links(); keep <- intersect(c("from","to","lag","n","r","lo","hi","p","prior_sign","sign_match","tier","expected","expected_class","conf"), names(lk))
      hdr <- c(sprintf("# NEON Driver Cascade · %s link scorecard. r is within-site only:", input$site),
               "# links built on mammal_cpue/bird_index are WITHIN-SITE relative indices; pooling/comparing across sites by magnitude is invalid (only sign-match pooling is legitimate).", "")
      writeLines(hdr, file)
      suppressWarnings(utils::write.table(lk[, keep, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })
  output$dlSuite <- downloadHandler(
    filename = function() "neon-cascade-scoreboard.csv",
    content = function(file) {
      keep <- intersect(c("site","biome","biome_class","from","to","lag","n","r","lo","hi","p","prior_sign","sign_match","tier","expected","expected_class"), names(SUITE_LINKS))
      hdr <- c("# NEON Driver Cascade · cross-site scoreboard (every site × prior, biome-aware).",
               "# mammal_cpue / bird_index are WITHIN-SITE relative indices: cross-site magnitude comparison is INVALID.",
               "# The only legitimate cross-site operation is the one-vote-per-site sign-match pooling (which discards magnitude).", "")
      writeLines(hdr, file)
      suppressWarnings(utils::write.table(SUITE_LINKS[, keep, drop=FALSE], file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })

  output$dlCodebook <- downloadHandler(
    filename = function() "neon-cascade-codebook.csv",
    content = function(file) {
      cb <- CODEBOOK
      hdr <- c("# NEON Driver Cascade · data codebook (every emitted signal, its unit, NA-semantics, and n-gate).",
               "# Generated from the actual exported keep-vector, so it cannot drift from the columns the app emits.",
               "# na_meaning = the QC gate that produces an NA cell; n_gate = the per-signal coverage gate.",
               "# Source: NEON multi-product synthesis (DP1.10072.001, DP1.10003.001, DP1.10058.001, DP1.10098.001, DP1.10055.001, DP1.10043.001, DP1.00002.001, DP1.00044.001), CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/); aggregated and derived by this app.", "")
      writeLines(hdr, file)
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
        tags$thead(tags$tr(tags$th("key"), tags$th("signal"), tags$th(""), tags$th("layer"), tags$th("unit"), tags$th("“more” ="))),
        tags$tbody(rows)),
      tags$ul(class="codebook-notes",
        tags$li(HTML("<b>precip</b> = annual total mm (needs &ge;10 valid months). <b>temp</b> = annual mean &deg;C (&ge;8 months), with a within-site MAD outlier filter that NAs a corrupted-sensor year.")),
        tags$li(HTML("<b>precip_winter</b> = Oct&ndash;Mar sum keyed to the year it ENDS (&ge;5 of 6 months). <b>precip_monsoon</b> = Jul&ndash;Sep sum (3 of 3). <b>temp_spring</b> = Mar&ndash;May mean. Reconstructed from the monthly NEON-tower overlays.")),
        tags$li(HTML("<b>greenup_doy</b> = median first-&lsquo;yes&rsquo; onset day-of-year over the green-up phenophases, years with &ge;5 individuals.")),
        tags$li(HTML("<b>mammal_cpue</b> = 100 &times; captures / deployed trap-nights (sprung/disturbed traps = &frac12; a trap-night, Nelson &amp; Clark 1973; captures counted by tagID) &mdash; a within-site relative index, NOT cross-site standardized. <b>mammal_mnka</b> = distinct tagged individuals (minimum known alive, Krebs 1966).")),
        tags$li(HTML("<b>plant_richness</b> = species count (a COMPOSITION signal, not productivity). <b>plant_intro_pct</b> = introduced share of cover. <b>fruiting_pct</b> = peak monthly STATUS yes-share for the exact &lsquo;Fruits&rsquo; phenophase (gated to months with &ge;5 individuals; honestly NA at arid sites that track no fruit). <b>bird_index</b> = clusterSize/point &mdash; a descriptive detection index that carries NO prior.")),
        tags$li(HTML("<b>Woody standing stock</b> (per site, not annual) = live basal area m²/ha from Veg-Structure (DP1.10098.001): directly measured, allometry-free, computable even at deserts via basal stem diameter. A slow ~5-yr STATE shown as context, the real productivity measure species richness can't be.")),
        tags$li(HTML("<b>n-gates:</b> &lt;3 yrs &rarr; no comparison; 3&ndash;5 &rarr; exploratory (no p); &ge;6 &rarr; permutation p + bootstrap CI + a verdict. Each prior is tested where its biome mechanism is <b>expected</b>; the cross-site pooled binomial is one vote per site.")),
        tags$li(HTML("<b>NA semantics:</b> a blank/NA cell is never a zero &mdash; it means the signal failed its coverage gate that year (a partial-year climate total dropped, a green-up year below 5 individuals, no trapping effort). The downloadable codebook CSV documents the exact gate behind every column's NAs."))),
      div(class="codebook-dl",
        downloadButton("dlAnnual", tagList(bs_icon("filetype-csv"), " This site's annual data"), class="btn-outline-dark btn-sm"),
        downloadButton("dlLinks",  tagList(bs_icon("filetype-csv"), " This site's link scorecard"), class="btn-outline-dark btn-sm"),
        downloadButton("dlCodebook", tagList(bs_icon("filetype-csv"), " Codebook (every signal, unit, NA-rule)"), class="btn-outline-dark btn-sm"),
        tags$span(class="codebook-dl-note", "(the full cross-site scoreboard CSV is on the Across NEON tab)")))
  })

  # ---- SEARCH THE NETWORK (bundled index, in-memory filter, instant) --------
  # A "Go to this site" link in each row raises the SAME goSite input the browse
  # list and scoreboard use, so the jump loads from the bundle and lands on the
  # Overview — one selection path everywhere.
  go_link <- function(code) sprintf(
    "<a href='#' class='srch-go' onclick=\"Shiny.setInputValue('goSite','%s',{priority:'event'});return false;\">Open &rarr;</a>", code)
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
    if (isTRUE(input$searchSignifOnly)) d <- d[d$is_signif %in% TRUE, , drop = FALSE]
    # significant first, then by p (NA last), then by site
    d[order(!(d$is_signif %in% TRUE), ifelse(is.finite(d$p), d$p, Inf), d$site), , drop = FALSE]
  })

  output$searchLinkSummary <- renderUI({
    if (is.null(input$searchLink) || !nrow(SRCH_CATALOG)) return(NULL)
    cat_row <- SRCH_CATALOG[SRCH_CATALOG$link_id == input$searchLink, , drop = FALSE]
    total <- sum(SRCH_LINKS$link_id == input$searchLink)
    shown <- nrow(search_link_rows())
    pooled_row <- if (nrow(SRCH_POOLED)) SRCH_POOLED[SRCH_POOLED$link_id == input$searchLink, , drop = FALSE] else SRCH_POOLED[0, ]
    pooled_txt <- if (nrow(pooled_row) && isTRUE(pooled_row$poolable[1]) && is.finite(pooled_row$p_pooled[1]))
      sprintf("Pooled across the %d expected sites: p = %.3f (median r = %+.2f). That cross-site test, not any single site, is the honest read.",
              pooled_row$sites[1], pooled_row$p_pooled[1], pooled_row$median_r[1])
      else "Too few expected sites to pool this link yet, so there is no honest cross-site verdict for it."
    conf <- if (nrow(cat_row)) cat_row$conf[1] else NA
    div(class = "search-summary",
      div(class = "ss-count", bs_icon("geo-alt-fill"),
        sprintf(" %d of %d sites", shown, total),
        tags$span(class = "ss-sub", sprintf(" tested for %s", if (nrow(cat_row)) cat_row$link_label[1] else input$searchLink))),
      if (!is.na(conf)) div(class = "ss-conf", sprintf("Prior confidence: %s", conf)),
      div(class = "ss-pooled", bs_icon("people-fill"), " ", pooled_txt))
  })

  output$searchLinkTable <- DT::renderDT({
    d <- search_link_rows()
    if (!nrow(d)) return(DT::datatable(
      data.frame(Site = character(0), `Site name` = character(0), Biome = character(0),
                 n = integer(0), r = numeric(0), p = numeric(0), Verdict = character(0),
                 Years = character(0), Open = character(0), check.names = FALSE),
      escape = FALSE, rownames = FALSE, selection = "none", options = srch_dt_opts))
    yrs <- ifelse(is.na(d$year_min) | is.na(d$year_max), "—", sprintf("%d–%d", d$year_min, d$year_max))
    tbl <- data.frame(
      Site = sprintf("<b>%s</b>%s", d$site, ifelse(d$expected %in% TRUE, "", " <span class='srch-oob' title='out of the biome where this mechanism is expected; shown as corroboration, not counted'>(out of biome)</span>")),
      `Site name` = vapply(d$site, srch_site_name, character(1)),
      Biome = d$biome,
      n = d$n,
      r = ifelse(is.finite(d$r), sprintf("%+.2f", d$r), "—"),
      p = ifelse(is.finite(d$p), sprintf("%.3f", d$p), "—"),
      Verdict = vapply(d$tier, verdict_pill, character(1)),
      Years = yrs,
      Open = vapply(d$site, go_link, character(1)),
      check.names = FALSE, stringsAsFactors = FALSE)
    DT::datatable(tbl, escape = FALSE, rownames = FALSE, selection = "none",
      options = c(srch_dt_opts, list(order = list())),
      class = "srch-dt compact stripe")
  })

  # (b) CASCADE STRENGTH ------------------------------------------------------
  search_strength_rows <- reactive({
    if (!nrow(SRCH_STR)) return(SRCH_STR)
    thr <- if (is.null(input$searchMinResolved)) 0 else input$searchMinResolved
    d <- SRCH_STR[SRCH_STR$n_resolved >= thr, , drop = FALSE]
    d[order(-d$n_resolved, -d$n_signif, d$site), , drop = FALSE]
  })

  output$searchStrengthSummary <- renderUI({
    if (!nrow(SRCH_STR)) return(NULL)
    shown <- nrow(search_strength_rows()); total <- nrow(SRCH_STR)
    div(class = "search-summary",
      div(class = "ss-count", bs_icon("geo-alt-fill"),
        sprintf(" %d of %d sites", shown, total),
        tags$span(class = "ss-sub", " meet the agreement filter")),
      div(class = "ss-pooled", bs_icon("info-circle"),
        " The count is expected links whose DIRECTION agrees, not significance. It ranks where to look, not which ecosystem is 'stronger'."))
  })

  output$searchStrengthTable <- DT::renderDT({
    d <- search_strength_rows()
    if (!nrow(d)) return(DT::datatable(
      data.frame(Site = character(0), Biome = character(0), Agree = character(0),
                 Significant = integer(0), Counter = integer(0), Years = character(0),
                 Open = character(0), check.names = FALSE),
      escape = FALSE, rownames = FALSE, selection = "none", options = srch_dt_opts))
    yrs <- ifelse(is.na(d$year_min) | is.na(d$year_max), "—", sprintf("%d–%d", d$year_min, d$year_max))
    tbl <- data.frame(
      Site = sprintf("<b>%s</b> <span class='srch-sn'>%s</span>", d$site, vapply(d$site, srch_site_name, character(1))),
      Biome = d$biome,
      `Agree (of expected)` = sprintf("<b>%d</b> of %d", d$n_resolved, d$expected_testable),
      Significant = d$n_signif,
      Counter = d$n_counter,
      Years = yrs,
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
  })

  # ---- Across NEON: click a scoreboard cell -> full plain-English detail for that
  # site x link (what r is, the years behind it, the bootstrap interval, the permutation
  # p with its floor, the literature prior, and whether it counts toward the tally). ----
  observeEvent(input$sbCell, {
    parts <- strsplit(input$sbCell %||% "", "|", fixed = TRUE)[[1]]
    if (length(parts) != 4) return()
    s <- parts[1]; from <- parts[2]; to <- parts[3]; lag <- suppressWarnings(as.integer(parts[4]))
    d <- SUITE_LINKS[SUITE_LINKS$site == s & SUITE_LINKS$from == from &
                     SUITE_LINKS$to == to & SUITE_LINKS$lag == lag, , drop = FALSE]
    if (!nrow(d)) return()
    d <- d[1, ]; tm <- TIER_META[[d$tier]] %||% list(col = "#6b7a89", icon = "slash-circle", lab = d$tier)
    arrow <- if (isTRUE(d$prior_sign > 0)) "more driver → more response (↑)" else "more driver → earlier / less response (↓)"
    verdict_plain <- switch(d$tier,
      consistent  = "Aligned: points the predicted direction AND the bootstrap interval excludes zero. A clean per-site direction, not a significance claim.",
      apparent    = "Apparent: points the predicted direction, but the bootstrap interval still crosses zero at this few years.",
      counter     = "Counter: runs the opposite way to what the prior predicts.",
      exploratory = "Exploratory: fewer than 6 overlapping years, so the data is shown but no verdict is given.",
      "Too few overlapping years to compare at this site.")
    r_plain <- if (is.finite(d$r))
      sprintf("<b>r = %+.2f</b> is the correlation between the driver and the response at this site. r runs from −1 (they move opposite) through 0 (no link) to +1 (they move in lockstep): the sign is the direction, the size is how tightly they track. The prior expects <b>%s</b>, and this %s.",
              d$r, arrow, if (isTRUE(d$sign_match)) "matches that direction" else "runs counter to it")
      else "There aren't enough overlapping years here to compute a correlation."
    ci_line <- if (is.finite(d$lo) && is.finite(d$hi))
      sprintf("<b>95%% interval [%.2f, %.2f]</b> (bootstrap): %s. Intervals are honestly wide at this few years.",
              d$lo, d$hi, if (d$lo > 0 || d$hi < 0) "it excludes zero, so the direction is clean" else "it still crosses zero, so the sign isn't yet clean") else NULL
    p_line <- if (isTRUE(d$n >= 6) && is.finite(d$p))
      sprintf("<b>Permutation p = %.3f</b>, shown for transparency, not as a significance test: its smallest possible value at %d years is 1/%d = %.2f, so a single short series cannot reach 0.05. Significance lives only in the cross-site pooled test at the top of this tab.", d$p, d$n, d$n, 1 / d$n) else NULL
    exp_line <- if (isTRUE(d$expected))
      "<b>Expected here.</b> This is the mechanism the literature predicts for this biome, so it counts toward this site's tally."
      else "<b>Not expected in this biome.</b> Shown for context (out-of-biome corroboration); it does <b>not</b> count toward this site's tally."
    showModal(modalDialog(easyClose = TRUE, size = "m",
      title = HTML(sprintf("%s &nbsp;·&nbsp; %s &rarr; %s%s", s, sig_label(from), sig_label(to),
                           if (isTRUE(lag > 0)) sprintf(" (lag %dy)", lag) else "")),
      div(class = "sb-detail",
        p(tags$span(style = sprintf("color:%s;font-weight:700", tm$col), bs_icon(tm$icon %||% "circle"), " ", tm$lab),
          tags$br(), verdict_plain),
        p(HTML(r_plain)),
        p(sprintf("Based on %d overlapping year%s of data.", d$n, if (isTRUE(d$n == 1)) "" else "s")),
        if (!is.null(ci_line)) p(HTML(ci_line)),
        if (!is.null(p_line)) p(HTML(p_line)),
        tags$hr(),
        p(HTML(sprintf("<b>The prior</b> (fixed before looking at the data): expect <b>%s</b>, lag <b>%s</b>, confidence <b>%s</b>.",
          arrow, if (isTRUE(lag > 0)) sprintf("%d year%s later", lag, if (lag == 1) "" else "s") else "same year", d$conf %||% "—"))),
        if (!is.na(d$note) && nzchar(d$note)) p(class = "qc-cap-note", style = "margin-top:6px", d$note),
        p(HTML(exp_line))),
      footer = modalButton("Close")))
  })
  observeEvent(input$gotoTab, updateTabsetPanel(session, "tabs", selected = input$gotoTab))

  observeEvent(input$help, showModal(modalDialog(easyClose=TRUE, title=tagList(bs_icon("question-circle"), " How to read the cascade"),
    tags$ul(
      tags$li(HTML("Pick a <b>site</b>; richer sites (more trophic layers) are listed first.")),
      tags$li(HTML("<b>Cascade Ladder</b>: standardised signals stacked by layer; watch a wet year ripple up into green-up, plants, then rodents.")),
      tags$li(HTML("<b>Link chips</b>: each predicted driver→response link, coloured by whether the data agrees and honest about how few years back it.")),
      tags$li(HTML("<b>Driver Lab</b>: pick a response and see every predicted driver tested against it, with a sign-match tally.")),
      tags$li(HTML("Short series: <b>read the shapes</b>, trust the direction-agreement, never read causation."))),
    footer=modalButton("Got it"))))
}
