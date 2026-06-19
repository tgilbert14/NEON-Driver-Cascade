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
    pal <- c("#2f7fb5","#5fae3a","#1a7f37","#AB0520","#c9a300","#9c6644","#16386e","#d6336c")
    ci <- 0
    plist <- lapply(present, function(L){ dd <- dl[[L]]; lm <- LAYER_META[[L]]
      p <- plotly::plot_ly()
      for (k in unique(dd$key)) { sub <- dd[dd$key==k,]; sub <- sub[order(sub$year),]; ci <<- ci+1
        p <- p %>% plotly::add_trace(data=sub, x=~year, y=~z, type="scatter", mode="lines+markers",
          name=sub$label[1], legendgroup=L, line=list(width=2.6, color=pal[(ci-1)%%length(pal)+1]),
          marker=list(size=6, color=pal[(ci-1)%%length(pal)+1]),
          hovertemplate=paste0("<b>",sub$label[1],"</b><br>%{x}: z=%{y:.2f}<extra></extra>")) }
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
    prow <- function(i){ r <- pr[i,]; arrow <- if (r$sign>0) "↑ positive" else "↓ negative"
      tags$tr(tags$td(sig_label(r$from)), tags$td(sig_label(r$to)), tags$td(arrow),
        tags$td(if (r$lag>0) sprintf("%d yr", r$lag) else "same yr"), tags$td(class="pr-note", r$note)) }
    div(class="about-wrap",
      div(class="about-card", h4("\U0001F517 What this is"),
        p("The capstone of a family of NEON explorers. Each sibling app dives into one product — ",
          tags$a(href="#","small mammals"), ", birds, plant diversity, vegetation structure, plant phenology. This one ", tags$b("lines them up"),
          " at shared sites into a single ", tags$b("bottom-up cascade"), ": climate → green-up timing → producers → consumers.")),
      div(class="about-card", h4(bs_icon("shield-check"), " Why it's careful (and what it refuses to do)"),
        tags$ul(
          tags$li(HTML("<b>States priors, doesn't dredge.</b> Each link's expected direction and lag come from the literature <em>before</em> looking at the data. We never report whichever lag happens to fit best.")),
          tags$li(HTML("<b>n-gated.</b> Each site has only 3–13 years. Below 6 overlapping years, no verdict is given — just the aligned series. A permutation null + bootstrap CI gate the rest.")),
          tags$li(HTML("<b>Direction over magnitude.</b> The headline is a <b>sign-match tally</b> (a binomial test of how many links point the predicted way) — honest about multiple comparisons in a way a single correlation isn't.")),
          tags$li(HTML("<b>Never 'drives' or 'causes.'</b> A handful of annual points cannot establish causation; these are <em>consistencies with</em>, not proof of, the mechanism.")))),
      div(class="about-card", h4(bs_icon("diagram-3"), " The predicted cascade (the priors)"),
        tags$table(class="inspect-tbl",
          tags$thead(tags$tr(tags$th("Driver"), tags$th("Response"), tags$th("Expected"), tags$th("Lag"), tags$th("Why"))),
          tags$tbody(lapply(seq_len(nrow(pr)), prow))),
        p(class="qc-cap-note", style="margin-top:8px", "Sources: Brown & Ernest (rain & rodents); Thibault et al. 2010; Owen 2006; Cole et al. 2015; Both et al. & Visser (phenological mismatch); dryland ANPP–precipitation reviews.")),
      div(class="about-card", h4(bs_icon("database"), " Data"),
        p("Per-site annual signals assembled from the five sibling apps' bundles plus NEON/Daymet climate overlays. Small-mammal catch rate is a relative annual index (captures per 100 plot-nights), not effort-standardised across sites."),
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
