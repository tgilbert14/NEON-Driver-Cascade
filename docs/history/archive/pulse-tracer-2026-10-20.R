# Pulse tracer (traced year state, keyboard picker, ladder highlights, banner), removed on 2026-10-20.
# Copied verbatim from server.R at 929d03f; plan card T1 in docs/SIMPLIFY-PLAN-2026-10-20.md.

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

  # ---- inside output$ladderPlot ----
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
      ramp <- LADDER_PAL[[L]] %||% c("#2f7fb5","#16386e","#6db3e0"); j <- 0L
        p <- p %>% plotly::add_trace(data=sub, x=~year, y=~z, type="scatter", mode="lines+markers",
          name=sprintf("%s (n=%d)", sub$label[1], nfin), legendgroup=L, line=list(width=2.6, color=if (!is.null(t0)) dimmed else col),
          marker=list(size=6, color=if (!is.null(t0)) dimmed else col),
          hovertemplate=paste0("<b>",sub$label[1],"</b> (n=",nfin,")<br>%{x}: z=%{y:.2f} (",lm$title,")<extra></extra>")) }
      # overlay the pulse highlights for any signal in this strip
      for (k in unique(dd$key)) if (!is.null(hl[[k]])) { h <- hl[[k]]
        p <- p %>% plotly::add_trace(data=h, x=~year, y=~z, type="scatter", mode="markers+text", cliponaxis=FALSE,
    # capture a dot click -> Shiny input$tracedYear (re-attached on every render; plotly purge wipes handlers)
    htmlwidgets::onRender(sp, "function(el, x){ el.on('plotly_click', function(d){
      if (d && d.points && d.points.length){ var yr = d.points[0].x;
        if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('tracedYear', {year: yr, n: Math.random()}); } }); }")


  output$pulseBanner <- renderUI({
    t0 <- traced()
    if (is.null(t0)) return(div(class="pulse-banner pulse-idle", bs_icon("hand-index-thumb"),
      tags$span(class="pb-text", HTML(" <b>Inspect a climate year:</b> select a dot or use the year selector. Vote-eligible direct climate pairings light at their stated lag: <span class='pulse-key pk-match'>● moved in the stated direction</span> or <span class='pulse-key pk-miss'>✕ moved oppositely</span>. Exact-zero driver or response anomalies abstain and are excluded from the denominator. This is an anecdotal trace, not a recursively inferred food-web path."),
      cpop("pulse"))))
    paths <- pulse_paths(ann(), t0, biome = bclass())
    if (is.null(paths) || !nrow(paths)) return(div(class="pulse-banner pulse-active", bs_icon("activity"),
      tags$span(class="pb-text", HTML(sprintf(" <b>Year %d</b> has no annual climate signal to trace here. ", t0))),
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
      tags$span(class="pb-text", HTML(sprintf(" <b>Inspecting %d:</b> %d of %d directly linked response%s moved in the stated direction.%s <i>One year is an anecdote; inspect the full series, uncertainty, support, and pooled sensitivity summary.</i> ",
        t0, k, tot, if (tot==1) "" else "s", audit))),
      actionLink("clearTrace", tagList(bs_icon("x-circle"), " clear"), class="pulse-clear"))
  })

