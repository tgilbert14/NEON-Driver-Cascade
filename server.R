# ===========================================================================
# NEON Driver Cascade — server.R
# ===========================================================================
server <- function(input, output, session) {
  is_dark <- function() identical(input$colorMode, "dark")
  theme_plotly <- function(p) { dark <- is_dark(); ink <- if (dark) "#e8eef2" else "#1f2a30"
    grid <- if (dark) "rgba(220,230,240,0.10)" else "rgba(31,42,48,0.08)"
    p %>% plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
      font=list(color=ink, family="Rubik"),
      hoverlabel=list(bgcolor="rgba(12,35,75,0.96)", bordercolor="#FFD200", font=list(color="#fff", family="Rubik", size=12))) %>%
      plotly::config(displayModeBar=FALSE, responsive=TRUE) }
  note_plot <- function(msg) plotly::plot_ly(type="scatter", mode="markers") %>%
    plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", xaxis=list(visible=FALSE), yaxis=list(visible=FALSE),
      annotations=list(list(text=msg, showarrow=FALSE, font=list(color=if(is_dark())"#9fb0c4" else "#6b7a85", size=14)))) %>%
    plotly::config(displayModeBar=FALSE)

  ann   <- reactive({ req(input$site); site_annual(input$site) })
  links <- reactive({ a <- ann(); req(nrow(a)); site_links(a, PRIORS) })
  smatch <- reactive(signmatch_score(links()))

  output$siteBio <- renderUI({ b <- site_bio(input$site); if (is.null(b)) return(NULL)
    div(class="site-bio", bs_icon("info-circle-fill"), span(b)) })

  output$signalChips <- renderUI({ a <- ann(); req(nrow(a))
    have <- SIGNALS$key[vapply(SIGNALS$key, function(k) sum(is.finite(a[[k]])) >= 2, logical(1))]
    if (!length(have)) return(div(class="sig-chips-empty", "No multi-year signals here yet."))
    div(class="sig-chips", lapply(have, function(k){ L <- SIGNALS$layer[SIGNALS$key==k]
      span(class=paste0("sig-chip sig-", L), sig_label(k)) })) })

  # ---- hero: the sign-match headline ----
  output$heroStats <- renderUI({
    a <- ann(); req(nrow(a)); sm <- smatch(); lp <- layers_present(a, SIGNALS)
    yrs <- range(a$year[rowSums(!is.na(a[, SIGNALS$key, drop=FALSE])) > 0], na.rm=TRUE)
    row <- neon_sites[neon_sites$site==input$site,]
    hero <- function(v,l,icon,tone,ttl=NULL) div(class=paste0("hero-stat hero-",tone), title=ttl,
      div(class="hs-icon", bs_icon(icon)), div(div(class="hs-v", v), div(class="hs-l", l)))
    div(class="hero-band",
      div(class="hero-title", bs_icon("diagram-3-fill"), tags$b(sprintf("%s · %s", input$site, if (nrow(row)) row$name[1] else input$site)),
        tags$span(class="hero-sub", sprintf(" · %s–%s", yrs[1], yrs[2]))),
      div(class="hero-grid",
        hero(sum(lp), "trophic layers", icon="layers", tone="navy", ttl="Climate, green-up, producers, consumers present here"),
        hero(if (sm$n>0) sprintf("%d/%d", sm$k, sm$n) else "—", "links match prior", icon="check2-circle", tone="pine",
             ttl="How many predicted driver->response links point the way ecology expects"),
        hero(if (!is.na(sm$p)) sprintf("%.2f", sm$p) else "—", "sign-match p", icon="dice-5", tone="gold",
             ttl="Binomial test that more links match than chance"),
        hero(nrow(a), "years on record", icon="calendar3", tone="terra")))
  })

  output$overviewInsight <- renderUI({
    sm <- smatch(); a <- ann()
    msg <- if (sm$n == 0) "Not enough overlapping years yet to line up the cascade here — try SRER, HARV, or SCBI."
      else sprintf("Across the predicted links at this site, <b>%s</b>. With only a handful of years per signal, that direction-agreement is a more honest signal than any single correlation.", sm$txt)
    insight_banner("diagram-3", tone = if (!is.na(sm$p) && sm$p < 0.05) "pine" else "navy", HTML(msg))
  })

  # ---- overview cascade schematic ----
  output$cascadeSchematic <- renderUI({
    a <- ann(); req(nrow(a))
    lay <- list(climate="climate", phenology="phenology", producer="producer", consumer="consumer")
    node <- function(L){ lm <- LAYER_META[[L]]
      ks <- SIGNALS$key[SIGNALS$layer==L]
      have <- ks[vapply(ks, function(k) sum(is.finite(a[[k]]))>=2, logical(1))]
      div(class=paste0("casc-node", if (!length(have)) " casc-empty" else ""),
        div(class="casc-node-h", style=sprintf("color:%s", lm$col), bs_icon(lm$icon), " ", lm$title),
        if (length(have)) div(class="casc-sigs", lapply(have, function(k) div(class="casc-sig", sig_label(k))))
        else div(class="casc-sigs", em("no data here"))) }
    arrow <- div(class="casc-arrow", bs_icon("arrow-right"))
    div(class="casc-flow", node("climate"), arrow, node("phenology"), arrow, node("producer"), arrow, node("consumer"))
  })

  output$signalTable <- renderUI({
    a <- ann(); req(nrow(a))
    rows <- lapply(c("climate","phenology","producer","consumer"), function(L){
      ks <- SIGNALS$key[SIGNALS$layer==L]; lm <- LAYER_META[[L]]
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
    LADDER_PAL <- list(
      climate   = c("#2f7fb5","#16386e","#6db3e0","#0a4a8f"),
      phenology = c("#3f9e3a","#7cc46a","#2f7d2f","#9acd6b"),
      producer  = c("#1a7f37","#12612a","#5fae3a","#0c4a20"),
      consumer  = c("#AB0520","#d6336c","#e0607a","#7a0418"))
    dark_hex <- function(hex) if (!is_dark()) hex else {
      rgb <- grDevices::col2rgb(hex)/255; hsv <- grDevices::rgb2hsv(rgb)
      grDevices::hsv(hsv[1], max(0, hsv[2]*0.8), min(1, hsv[3]*1.35)) }   # lift value, ease saturation for navy bg
    plist <- lapply(present, function(L){ dd <- dl[[L]]; lm <- LAYER_META[[L]]
      ramp <- LADDER_PAL[[L]] %||% c("#2f7fb5","#16386e","#6db3e0"); j <- 0L
      p <- plotly::plot_ly()
      for (k in unique(dd$key)) { sub <- dd[dd$key==k,]; sub <- sub[order(sub$year),]; j <- j + 1L
        col <- dark_hex(ramp[(j-1) %% length(ramp) + 1])
        p <- p %>% plotly::add_trace(data=sub, x=~year, y=~z, type="scatter", mode="lines+markers",
          name=sub$label[1], legendgroup=L, line=list(width=2.6, color=col),
          marker=list(size=6, color=col),
          hovertemplate=paste0("<b>",sub$label[1],"</b><br>%{x}: z=%{y:.2f} (",lm$title,")<extra></extra>")) }
      p %>% plotly::layout(yaxis=list(title=list(text=lm$title, font=list(size=11, color=lm$col)),
        zeroline=TRUE, zerolinecolor=if(is_dark())"rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)",
        gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)", tickfont=list(size=9)))
    })
    plotly::subplot(plist, nrows=length(present), shareX=TRUE, titleY=TRUE, margin=0.035) %>%
      theme_plotly() %>%
      plotly::layout(legend=list(orientation="h", y=-0.08, font=list(size=10)),
        xaxis=list(title="year", dtick=1, gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
        margin=list(l=60,r=20,t=20,b=40))
  })

  # ---- link agreement chips (beside the ladder) ----
  output$linkChips <- renderUI({
    lk <- links(); req(nrow(lk))
    div(class="link-chips", lapply(seq_len(nrow(lk)), function(i){ r <- lk[i,]; tm <- TIER_META[[r$tier]]
      arrow <- if (r$prior_sign>0) "↑" else "↓"
      div(class=paste0("link-chip lc-", r$tier),
        div(class="lc-top", span(class="lc-from", sig_label(r$from)), bs_icon("arrow-right"),
          span(class="lc-to", sig_label(r$to)),
          span(class="lc-lag", if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr")),
        div(class="lc-mid",
          span(class="lc-prior", sprintf("expect %s", arrow)),
          if (is.finite(r$r)) span(class="lc-r", sprintf("r=%.2f%s", r$r,
            if (is.finite(r$lo)) sprintf(" [%.2f, %.2f]", r$lo, r$hi) else "")) else span(class="lc-r","—"),
          span(class="lc-n", sprintf("n=%d", r$n))),
        div(class="lc-verdict", style=sprintf("color:%s", tm$col), bs_icon(tm$icon), " ", r$verdict)) }))
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
      else if (tot>0) sprintf("%d of %d predicted drivers point the expected way, but none clears the bar for a verdict at this site's short series.", k, tot)
      else "Too few overlapping years to test any predicted driver here."
    insight_banner("bullseye", tone = if (!is.null(best)) "pine" else "navy", HTML(msg))
  })

  output$driverTable <- renderUI({
    lk <- lab_links(); if (!nrow(lk)) return(p(class="qc-cap-note","No predicted drivers for this response."))
    lk <- lk[order(-lk$n, -abs(ifelse(is.na(lk$r),0,lk$r))), ]
    rows <- lapply(seq_len(nrow(lk)), function(i){ r <- lk[i,]; tm <- TIER_META[[r$tier]]
      arrow <- if (r$prior_sign>0) "↑ +" else "↓ −"
      tags$tr(
        tags$td(tags$b(sig_label(r$from))),
        tags$td(class="dt-prior", sprintf("%s, %s", arrow, if (r$lag>0) sprintf("lag %dy", r$lag) else "same yr")),
        tags$td(class="dt-r", if (is.finite(r$r)) sprintf("%.2f", r$r) else "—"),
        tags$td(class="dt-n", r$n),
        tags$td(span(class="dt-chip", style=sprintf("background:%s", tm$col), tm$lab))) })
    div(
      tags$table(class="inspect-tbl driver-tbl",
        tags$thead(tags$tr(tags$th("Driver"), tags$th("Expected"), tags$th("r"), tags$th("n"), tags$th("Verdict"))),
        tags$tbody(rows)),
      p(class="qc-cap-note", style="margin-top:8px", bs_icon("info-circle"),
        " Expected sign/lag come from the ecology literature (see About), fixed before looking at the data. No verdict is given below 6 overlapping years."))
  })

  # the most-informative link for the scatter = most overlapping years
  sel_link <- reactive({ lk <- lab_links(); lk <- lk[lk$n >= 3, , drop=FALSE]; if (!nrow(lk)) return(NULL)
    lk[which.max(lk$n), ] })

  output$linkScatter <- renderPlotly({
    r <- sel_link(); if (is.null(r)) return(note_plot("No driver has enough overlapping years to plot"))
    m <- lag_pairs(ann(), r$from, r$to, r$lag); if (!nrow(m)) return(note_plot("No overlapping years"))
    p <- plotly::plot_ly(m, x=~x, y=~y, type="scatter", mode="markers+text", text=~year, textposition="top center",
      textfont=list(size=9, color=if(is_dark())"#9fb0c4" else "#6b7a85"),
      marker=list(size=11, color=DDL$sky, line=list(color="#fff", width=1)),
      hovertemplate=paste0(sig_label(r$from),"=%{x}<br>",sig_label(r$to),"=%{y}<extra></extra>"))
    if (r$n >= 6 && is.finite(r$r)) { fit <- stats::lm(y ~ x, data=m); xr <- range(m$x)
      p <- p %>% plotly::add_lines(x=xr, y=predict(fit, newdata=data.frame(x=xr)), inherit=FALSE,
        line=list(color=DDL$gold2, width=2, dash="dot"), showlegend=FALSE, hoverinfo="skip") }
    p %>% theme_plotly() %>% plotly::layout(showlegend=FALSE,
      xaxis=list(title=sprintf("%s (%s)", sig_label(r$from), sig_unit(r$from))),
      yaxis=list(title=sprintf("%s (%s)", sig_label(r$to), sig_unit(r$to))), margin=list(l=55,r=20,t=20,b=45))
  })
  output$linkScatterNote <- renderUI({ r <- sel_link(); if (is.null(r)) return(NULL); tm <- TIER_META[[r$tier]]
    div(class="scatter-note",
      span(sprintf("%s → %s", sig_label(r$from), sig_label(r$to)), style="font-weight:600"),
      if (r$lag>0) span(class="sn-lag", sprintf(" (response %d yr later)", r$lag)),
      div(style=sprintf("color:%s;margin-top:4px", tm$col), bs_icon(tm$icon), " ", r$verdict)) })

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
        p("The capstone of a family of NEON explorers. Each sibling app dives into one product — small mammals, birds, plant diversity, vegetation structure, plant phenology. This one ", tags$b("lines them up"),
          " at shared sites into a single ", tags$b("bottom-up cascade"), ": climate → green-up timing → producers → consumers.")),

      div(class="about-card about-plain", h4(bs_icon("chat-square-text"), " How to read this — in plain English"),
        p("New to this? Start here. Everything below is jargon-free."),
        gloss("The big idea", "Weather sets off a chain reaction through the food web. A wet or warm year first changes the <b>plants</b>, then the <b>animals</b> that eat the plants — like dominoes, from the ground up. This app checks whether each domino actually falls the way ecology says it should."),
        gloss("Green-up", "The moment in spring when plants leaf out and the landscape turns green. We measure it as the <b>day of the year the first leaves appear</b> — a smaller number means an earlier spring."),
        gloss("The “hinge”", "Green-up is the hinge between weather and wildlife: the climate decides <em>when</em> plants wake up, and that sets the table for everything that eats them."),
        gloss("A “lag”", "A delay. A <b>1-year lag</b> means this year's rain shows up in <em>next</em> year's animals — because it takes a season for rain to grow the seeds the animals depend on."),
        gloss("Catch rate (per 100 trap-nights)", "How many small mammals were caught for every 100 trap-nights of effort. It accounts for how hard we trapped, so years compare fairly — but it's a <b>relative index, not a true headcount</b>."),
        gloss("The stacked “ladder”", "Each strip is one rung of the food web, drawn on a <b>standardised</b> scale so they're comparable: <b>0 = that signal's own average year</b>, up = above average, down = below. Watch whether a good year ripples <em>down</em> the rungs — compare the <b>timing</b> of the bumps across strips, not their heights."),
        gloss("Why deserts are the clearest case", "In deserts, water is the one thing everything waits for. When rain comes, the whole food web responds at once and in step — so the chain reaction is easier to see than in wetter places, where many other things also matter.")),

      div(class="about-card about-plain", h4(bs_icon("calculator"), " The statistics, in plain English"),
        gloss("“Could this be luck?” (the permutation test)", "For each link we <b>shuffle the years 2,000 times</b> and re-measure the match each time. If the real match beats almost all the shuffles, it's unlikely to be a coincidence. (We checked: these yearly numbers aren't badly auto-correlated, so the shuffle is a fair test.)"),
        gloss("The uncertainty band (95% CI)", "A range we're fairly sure the true relationship falls in. With only ~6 years it's <b>very wide</b> — that honesty is the point: few years = lots of uncertainty."),
        gloss("“Too few years to judge”", "Below <b>6 overlapping years</b> we show the lined-up data but give <b>no verdict</b> — there simply isn't enough to tell signal from noise."),
        gloss("The three verdicts", "<b>Consistent with prior</b> = matches the expected direction <em>and</em> clears the luck test. <b>Apparent</b> = points the expected way but could be noise. <b>Counter</b> = runs the opposite way."),
        gloss("Sign-match score", "Of the testable links (≥6 years), how many point the direction ecology predicts. Even when no single link is rock-solid, several all pointing the right way is itself meaningful — and we report the odds it's chance."),
        p(class="qc-cap-note", bs_icon("info-circle"), " We never say a driver “causes” anything — a handful of yearly points can't prove cause. These are <em>consistencies with</em> the textbook mechanism, not proof.")),

      div(class="about-card", h4(bs_icon("shield-check"), " Why it's careful (and what it refuses to do)"),
        tags$ul(
          tags$li(HTML("<b>States priors, doesn't dredge.</b> Each link's expected direction and lag come from the literature <em>before</em> looking at the data — we never report whichever lag happens to fit best.")),
          tags$li(HTML("<b>n-gated.</b> Below 6 overlapping years, no verdict — just the aligned series. A permutation null + bootstrap CI gate the rest.")),
          tags$li(HTML("<b>Honest about scope.</b> Several of these mechanisms are clearest <em>across regions</em> or in <em>deserts</em>; testing them within one site, year-to-year, is the hardest case — the notes say so.")),
          tags$li(HTML("<b>Direction over magnitude</b>, and <b>never “drives”/“causes.”</b>")))),

      div(class="about-card", h4(bs_icon("diagram-3"), " The predicted cascade (the priors)"),
        tags$table(class="inspect-tbl",
          tags$thead(tags$tr(tags$th("Driver"), tags$th("Response"), tags$th("Expected"), tags$th("Lag"), tags$th("Confidence"), tags$th("In plain English"))),
          tags$tbody(lapply(seq_len(nrow(pr)), prow))),
        p(class="qc-cap-note", style="margin-top:8px", HTML("Sources: warmer-springs→earlier green-up — <b>Fu et al. 2015</b> (Nat. Comms.), Richardson et al. 2013; rain→desert rodents (lagged, non-linear) — <b>Brown &amp; Ernest 2002</b>, Thibault et al. 2010; rain-timing — Zhang et al. 2021; dryland productivity~precipitation — Sala et al. 1988, Huxman et al. 2004, Knapp et al. 2017; the “green wave” — Merkle et al. 2016. A green-up→bird link is <b>deliberately omitted</b>: the mismatch literature is about timing-synchrony, not “later green-up → more birds.”"))),

      div(class="about-card", h4(bs_icon("database"), " Data & honest limits"),
        p("Per-site annual signals assembled from the five sibling apps' bundles plus NEON/Daymet climate overlays. ",
          tags$b("Small-mammal catch rate"), " is a relative annual index (captures per 100 deployed trap-nights), not effort-standardised across sites — read within-site trends only. ",
          tags$b("Temperature"), " is the year's average, a stand-in for the spring warmth that actually drives green-up. ",
          tags$b("Plant richness"), " (species count) is a rough proxy for plant productivity."),
        p(bs_icon("envelope"), " ", tags$a(href="mailto:desertdatalabs@gmail.com","desertdatalabs@gmail.com"))))
  })
  observeEvent(input$help, showModal(modalDialog(easyClose=TRUE, title=tagList(bs_icon("question-circle"), " How to read the cascade"),
    tags$ul(
      tags$li(HTML("Pick a <b>site</b> — richer sites (more trophic layers) are listed first.")),
      tags$li(HTML("<b>Cascade Ladder</b> — standardised signals stacked by layer; watch a wet year ripple up into green-up, plants, then rodents.")),
      tags$li(HTML("<b>Link chips</b> — each predicted driver→response link, coloured by whether the data agrees and honest about how few years back it.")),
      tags$li(HTML("<b>Driver Lab</b> — pick a response and see every predicted driver tested against it, with a sign-match tally.")),
      tags$li(HTML("Short series: <b>read the shapes</b>, trust the direction-agreement, never read causation."))),
    footer=modalButton("Got it"))))
}
