# Lag and season explorer, removed from the One pairing tab (Driver Lab) on 2026-10-20.
# Copied verbatim from server.R at 929d03f; plan card L6 in docs/SIMPLIFY-PLAN-2026-10-20.md.

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

