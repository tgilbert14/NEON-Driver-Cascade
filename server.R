# ===========================================================================
# NEON Cross-Product Response Atlas, server.R
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
  # export = TRUE shows the hover modebar with one PNG button named for the site.
  theme_plotly <- function(p, export = TRUE) { dark <- is_dark(); ink <- if (dark) "#e8eef2" else "#1f2a30"
    grid <- if (dark) "rgba(220,230,240,0.10)" else "rgba(31,42,48,0.08)"
    p <- p %>% plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
      font=list(color=ink, family = APP_FONT_STACK),
      hoverlabel=list(bgcolor="rgba(11,23,51,0.96)", bordercolor="#2dd4bf", font=list(color="#eaf2ff", family = APP_FONT_STACK, size=12)))
    if (export) plotly_export_config(p, sprintf("response-atlas-%s", isolate(input$site) %||% "site"))
    else plotly::config(p, displayModeBar=FALSE, responsive=TRUE) }
  note_plot <- function(msg) plotly::plot_ly(type="scatter", mode="markers") %>%
    plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", xaxis=list(visible=FALSE), yaxis=list(visible=FALSE),
      annotations=list(list(text=msg, showarrow=FALSE,
        font=list(color=if(is_dark())"#9fb0c4" else "#53606d", family=APP_FONT_STACK, size=14)))) %>%
    theme_plotly(export = FALSE)

  ann    <- reactive({ req(input$site); site_annual(input$site) })
  links  <- reactive({ req(input$site); site_links_cached(input$site) })   # precomputed; eligibility is registry-defined
  smatch <- reactive(signmatch_score(links()))
  bclass <- reactive(site_bclass(input$site))
  blabel <- reactive(site_blabel(input$site))
  bgroup <- reactive(if (identical(bclass(), "water-limited")) "dryland-keyword group" else "default other-site group")

  # ---- plain-word helpers shared by the This site and One pairing tabs ----
  # Verdict words come from the bundle's tier field, never from its sentence.
  TIER_WORDS <- c(consistent = "Fits the expected direction",
                  apparent = "Fits, but the range includes zero",
                  counter = "Runs the other way", neutral = "No direction",
                  exploratory = "Too few years to judge", insufficient = "Not testable here")
  tier_words <- function(t) { w <- unname(TIER_WORDS[as.character(t)]); ifelse(is.na(w), "No direction", w) }
  pair_id <- function(from, to, lag) sprintf("%s|%s|%d", from, to, as.integer(lag))
  JUDGED_IDS <- with(PRIORS[PRIORS$expected_class == "all", , drop = FALSE], pair_id(from, to, lag))
  plain_unit <- function(k) switch(sig_unit(k),
    "mm/yr" = "mm", "per 100 TN" = "per 100 trap-nights",
    "per trap-nt" = "per trap-night", "DOY-anchored index" = "(day-of-year index)", sig_unit(k))
  # Short lower-case names for sentences; the table keeps the bundle's labels.
  plain_name <- function(k) switch(k,
    precip = "annual rain", temp = "mean temperature", precip_winter = "winter rain",
    precip_monsoon = "monsoon rain", temp_spring = "March to May temperature",
    greenup_doy = "green-up timing", mammal_cpue = "small-mammal catch",
    fruiting_pct = "fruiting peak",
    tolower(sub(" \\(.*\\)$", "", sig_label(k))))
  cap_first <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))
  fmt_val <- function(v, k) {
    if (length(v) == 0 || !is.finite(v)) return("no value")
    d <- if (abs(v) >= 100) 0 else 1
    u <- plain_unit(k)
    sprintf("%s%s%s", format(round(v, d), big.mark = ",", nsmall = d, trim = TRUE),
            if (identical(u, "°C")) "" else " ", u)
  }
  sig_product <- function(k) {
    if (grepl("^(temp|precip)", k)) return("NEON tower weather")
    if (k %in% c("greenup_doy", "fruiting_pct")) return("NEON plant phenology (DP1.10055.001)")
    if (grepl("^plant_", k)) return("NEON plant diversity (DP1.10058.001)")
    if (grepl("^mammal_", k)) return("NEON small mammals (DP1.10072.001)")
    if (grepl("^bird_", k)) return("NEON breeding birds (DP1.10003.001)")
    if (grepl("^mosq_", k)) return("NEON mosquitoes (DP1.10043.001)")
    if (grepl("^beetle_", k)) return("NEON ground beetles (DP1.10022.001)")
    "NEON"
  }
  pairing_label <- function(from, to, lag, judged) {
    if (lag > 0)
      sprintf("%s, then %s the next year · %s", cap_first(plain_name(from)), plain_name(to), if (judged) "judged" else "context")
    else
      sprintf("%s and %s, same year · %s", cap_first(plain_name(from)), plain_name(to), if (judged) "judged" else "context")
  }
  # Four short lines under a chart: Shows, Example, From, Cannot.
  plain_lines <- function(shows, example, from, cannot) {
    row <- function(lab, txt) div(class = "plain-row", tags$b(class = "plain-lab", lab), span(class = "plain-txt", txt))
    div(class = "plain-lines", row("Shows", shows), row("Example", example),
        row("From", from), row("Cannot", cannot))
  }

  # ---- pin cards: one site-year per card (www/cascade.js draws and anchors them) ----
  # The support behind one signal in one year: the effort or coverage field that
  # gates it, as plain text, or NULL when the bundle carries none.
  support_text <- function(k, row) {
    g <- function(col) if (col %in% names(row) && nrow(row) && is.finite(row[[col]][1])) row[[col]][1] else NA_real_
    v <- NA_real_
    if (k %in% c("temp", "precip", "precip_winter", "precip_monsoon", "temp_spring")) {
      v <- g(paste0(k, "_n_months")); if (is.finite(v)) return(sprintf("%d complete months", as.integer(v)))
    } else if (k %in% c("greenup_doy", "greenup_doy_additive")) {
      v <- g("greenup_n_individuals"); sp <- g("greenup_n_species")
      if (is.finite(v)) return(sprintf("%d plants%s", as.integer(v),
        if (is.finite(sp)) sprintf(", %d species", as.integer(sp)) else ""))
    } else if (k == "fruiting_pct") {
      v <- g("fruiting_n_eligible_months"); if (is.finite(v)) return(sprintf("%d eligible months", as.integer(v)))
    } else if (grepl("^plant_", k)) {
      v <- g("plant_n_plots"); if (is.finite(v)) return(sprintf("%d plots", as.integer(v)))
    } else if (grepl("^mammal_", k)) {
      v <- g("mammal_trap_nights"); if (is.finite(v)) return(sprintf("%s trap-nights", fmt_int(v)))
    } else if (grepl("^bird_", k)) {
      v <- g("bird_observed_point_visits"); if (is.finite(v)) return(sprintf("%s point-count visits", fmt_int(v)))
    } else if (grepl("^mosq_", k)) {
      v <- g("mosq_trap_nights"); if (is.finite(v)) return(sprintf("%s trap-nights", fmt_int(v)))
    } else if (grepl("^beetle_", k)) {
      v <- g("beetle_catch_event_trap_nights")
      if (is.finite(v)) return(sprintf("%s trap-nights, catch-bearing events only", fmt_int(v)))
    }
    NULL
  }
  pin_card_html <- function(title, rows, foot = NULL) {
    paste0("<div class='pin-title'>", htmlEscape(title), "</div><dl class='pin-dl'>",
      paste0(vapply(rows, function(r) sprintf("<dt>%s</dt><dd>%s</dd>", htmlEscape(r[1]), htmlEscape(r[2])),
                    character(1)), collapse = ""),
      "</dl>", if (!is.null(foot)) paste0("<p class='pin-foot'>", htmlEscape(foot), "</p>") else "")
  }

  # ---- clickable scatter dots: the year being inspected on One pairing ----
  scatterYear <- reactiveVal(NULL)
  observeEvent(input$site,     scatterYear(NULL), ignoreInit = TRUE)
  observeEvent(input$pairing,  scatterYear(NULL), ignoreInit = TRUE)
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

  # ---- hero: one counts-first line, computed, then three tiles ----
  site_facts <- reactive({
    a <- ann(); req(nrow(a)); lk <- links(); lp <- layers_present(a, SIGNALS)
    has_any <- rowSums(!is.na(a[, intersect(SIGNALS$key, names(a)), drop = FALSE])) > 0
    yrs <- range(a$year[has_any], na.rm = TRUE)
    row <- neon_sites[neon_sites$site == input$site, ]
    climate_years <- sum(("temp" %in% names(a) & is.finite(a$temp)) |
                         ("precip" %in% names(a) & is.finite(a$precip)))
    jid <- pair_id(lk$from, lk$to, lk$lag)
    judged <- lk[jid %in% JUDGED_IDS, , drop = FALSE]
    testable <- judged[judged$n >= 6 & is.finite(judged$r) & !is.na(judged$sign_match), , drop = FALSE]
    # A year counts as on record when at least one signal has a value that year.
    list(name = if (nrow(row)) row$name[1] else input$site, years = sum(has_any), yrs = yrs,
         layers = sum(lp), n_layers = length(lp), climate_years = climate_years,
         has_greenup = "greenup_doy" %in% names(a) && any(is.finite(a$greenup_doy)),
         n_judged = nrow(judged), testable = testable)
  })
  judged_sentence <- function(f) {
    tt <- f$testable; k <- sum(tt$sign_match %in% TRUE)
    if (!nrow(tt)) {
      if (!f$has_greenup) "No green-up record here, so neither judged pairing can be tested at this site."
      else "Neither judged pairing has six or more years here, so neither can be tested at this site."
    } else if (nrow(tt) == 1) {
      sprintf("One judged pairing has enough years here and it %s.",
              if (isTRUE(tt$sign_match[1])) "fits the expected direction" else "runs the other way")
    } else {
      sprintf("Both judged pairings have enough years here: %d of %d fit the expected direction.", k, nrow(tt))
    }
  }
  counts_line <- function(f, site) {
    sprintf("%s, %s: %d years on record (%s to %s), %d of %d measurement layers, %d years with complete weather.",
            site, f$name, f$years, f$yrs[1], f$yrs[2], f$layers, f$n_layers, f$climate_years)
  }
  output$heroStats <- renderUI({
    f <- site_facts()
    compact <- !is.null(input$tabs) && !identical(input$tabs, "site")
    hero <- function(v,l,icon,tone) div(class=paste0("hero-stat hero-",tone),
      div(class="hs-icon", bs_icon(icon)), div(div(class="hs-v", v), div(class="hs-l", l)))
    div(class=paste("hero-band", if (compact) "hero-band-compact" else ""),
      div(class="hero-title", bs_icon("diagram-3-fill"), tags$b(sprintf("%s · %s", input$site, f$name)),
        tags$span(class="hero-sub", sprintf(" · %s to %s", f$yrs[1], f$yrs[2])),
        # The site picker sits at the top of This site; the link opens that tab and
        # scrolls the picker into view.
        tags$a(class="hero-change", href="#sitePanel", `data-cascade-action`="change-site",
          bs_icon("pin-map"), " change site")),
      # On phones the sentence is clamped to four lines; the toggle shows the rest.
      div(class="hero-verdict hero-line",
        tags$span(class="hv-text", id="heroVerdictText", counts_line(f, input$site), " ", judged_sentence(f)),
        if (!compact) tags$button(type="button", class="hero-more", `aria-expanded`="false",
          `aria-controls`="heroVerdictText", "more")),
      p(class="prereg-caveat hero-prereg", "Exploratory, not preregistered: the pairings were chosen while exploring these data."),
      div(class="hero-grid hero-grid-3",
        hero(f$years, "years on record", icon="calendar3", tone="terra"),
        hero(sprintf("%d of %d", f$layers, f$n_layers), "measurement layers", icon="layers", tone="navy"),
        hero(f$climate_years, "years with complete weather", icon="cloud-sun", tone="gold")))
  })

  # Scope chips: every site-scoped tab head names the site it is showing.
  scope_text <- reactive({ req(input$site); f <- site_facts(); sprintf("%s · %s", input$site, f$name) })
  output$scopeSite <- renderText(scope_text())
  output$scopePairing <- renderText(scope_text())
  output$scopeQc <- renderText(scope_text())

  # URL state: ?site= is read once on load; later site changes replace the query
  # string (no new history entry), so a reload or a shared link keeps the site.
  observeEvent(session$clientData$url_search, {
    q <- shiny::parseQueryString(session$clientData$url_search %||% "")
    want <- toupper(trimws(q$site %||% ""))
    if (nzchar(want) && want %in% ALL_SITES && !identical(want, input$site))
      updateSelectInput(session, "site", selected = want)
  }, once = TRUE)
  observeEvent(input$site, {
    req(input$site %in% ALL_SITES)
    updateQueryString(paste0("?site=", input$site), mode = "replace")
  }, ignoreInit = TRUE)

  # "Data through" line for This site: one line, shown only when the bundle
  # carries per-product release columns.
  output$dataThrough <- renderUI({
    ri <- source_release_info(); if (is.null(ri)) return(NULL)
    rel <- unique(release_label(ri$release))
    months <- sort(unique(ri$data_through))
    span_txt <- if (length(months) == 1L) months else sprintf("%s to %s", months[1], months[length(months)])
    prov <- ri[!is.na(ri$provisional_from) & nzchar(ri$provisional_from), , drop = FALSE]
    p(class = "data-through", bs_icon("calendar-check"),
      sprintf(" Data through %s across the seven products (%s)%s.",
              span_txt, paste(rel, collapse = ", "),
              if (nrow(prov)) sprintf("; %s has provisional data", paste(tolower(prov$label), collapse = ", ")) else ""))
  })

  output$siteStatus <- renderText({
    f <- site_facts()
    sprintf("%s loaded. %d years on record, %d of %d measurement layers, %d years with complete weather. %s",
            input$site, f$years, f$layers, f$n_layers, f$climate_years, judged_sentence(f))
  })

  # Conditional woody-structure context. A legacy source lacks visit effort needed
  # to distinguish sampled-zero from unsampled plots; the plot-event source records
  # absences, but the Atlas keeps the same conditional estimand. Either way this
  # is not a site-wide stock.
  output$standingStock <- renderUI({
    sm <- SITE_META[SITE_META$site == input$site, , drop = FALSE]
    events <- veg_rows_event_contract(sm)
    pop <- cpop(if (events) "standing_events" else "standing")
    status <- if (nrow(sm) && "veg_design_status" %in% names(sm))
      as.character(sm$veg_design_status[1]) else NA_character_
    if (identical(status, "unsupported-unmatched-plots")) {
      unmatched <- if ("veg_unmatched_record_plots" %in% names(sm))
        sm$veg_unmatched_record_plots[1] else NA_integer_
      records <- if ("veg_unmatched_record_rows" %in% names(sm))
        sm$veg_unmatched_record_rows[1] else NA_integer_
      audit <- if (all(is.finite(c(unmatched, records)))) {
        if (events)
          sprintf("The reviewed source has %d vegetation records across %d plots whose surveys all lack a matching NEON sampling record.",
                  records, unmatched)
        else
          sprintf("The reviewed source has %d vegetation records across %d plot IDs with no design-table match.",
                  records, unmatched)
      } else "The reviewed vegetation records have no matching plot-design support."
      return(div(class = "standing-stock standing-stock-unsupported",
        bs_icon("exclamation-triangle-fill"),
        HTML(" Conditional woody structure: <b>estimate withheld</b>"),
        pop,
        tags$span(class = "ss-note", paste(
          audit,
          "No partial subset or area imputation was used; the estimate and classification remain unavailable."))))
    }
    ba <- site_ba(input$site); if (!is.finite(ba)) return(NULL)
    se <- site_ba_se(input$site)
    used <- if (nrow(sm) && "veg_n_plots" %in% names(sm)) sm$veg_n_plots[1] else NA_integer_
    eligible <- if (nrow(sm) && "veg_area_eligible_plots" %in% names(sm)) sm$veg_area_eligible_plots[1] else NA_integer_
    recorded <- if (nrow(sm) && "veg_record_plots" %in% names(sm)) sm$veg_record_plots[1] else NA_integer_
    if (events) {
      year_min <- if ("veg_event_year_min" %in% names(sm)) sm$veg_event_year_min[1] else NA_real_
      year_max <- if ("veg_event_year_max" %in% names(sm)) sm$veg_event_year_max[1] else NA_real_
      surveys <- if (all(is.finite(c(year_min, year_max)))) {
        if (year_min == year_max) sprintf(", surveys %d", as.integer(year_min))
        else sprintf(", surveys %d to %d", as.integer(year_min), as.integer(year_max))
      } else ""
      se_text <- if (is.finite(se)) sprintf(", &plusmn;%s plot-to-plot SE (%s plots%s)",
        format(round(se, 1), nsmall = 1),
        if (is.finite(used)) as.character(used) else "?", surveys) else ""
      coverage <- if (all(is.finite(c(used, eligible, recorded))))
        sprintf("%d plots with a qualifying live stem used; %d plots with a usable survey among %d plots with vegetation records.",
                used, eligible, recorded) else "Plot-support counts are unavailable."
      return(div(class="standing-stock", bs_icon("tree-fill"),
        HTML(sprintf(" Conditional woody structure: <b>%s m&sup2;/ha</b> mean live basal area%s",
          format(round(ba, 1), nsmall = 1), se_text)),
        pop,
        tags$span(class = "ss-note", paste0(coverage,
          " Plots whose selected survey has no qualifying live stem, including NEON-recorded absences, are left out rather than counted as zero; this is structural context, not productivity."))))
    }
    coverage <- if (all(is.finite(c(used, eligible, recorded))))
      sprintf("%d qualifying-stem plots used; %d area-eligible plots among %d plots with vegetation records.",
              used, eligible, recorded) else "Plot-support denominators are unavailable."
    div(class="standing-stock", bs_icon("tree-fill"),
      HTML(sprintf(" Conditional woody structure: <b>%s m&sup2;/ha</b>%s mean live basal area",
        format(round(ba, 1), nsmall = 1),
        if (is.finite(se)) sprintf(" &plusmn;%s", format(round(se, 1), nsmall = 1)) else "")),
      pop,
      tags$span(class = "ss-note", paste0(coverage,
        " Zero-stem and unobserved plots were not imputed; this is structural context, not productivity.")))
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
          tags$td(class="st-yr", sprintf("%s to %s", yrs[1], yrs[2]))) }) })
    rows <- Filter(Negate(is.null), unlist(rows, recursive=FALSE))
    tags$table(class="inspect-tbl sig-tbl",
      tags$caption(class="visually-hidden", "Signals measured at the selected NEON site"),
      tags$thead(tags$tr(tags$th(scope="col", "Layer"), tags$th(scope="col", "Signal"),
        tags$th(scope="col", "Unit"), tags$th(scope="col", "Years"), tags$th(scope="col", "Span"))),
      tags$tbody(rows))
  })

  # ---- flagship: the alignment ladder ----
  output$ladderPlot <- renderPlotly({
    a <- ann(); req(nrow(a))
    layers <- c("climate","phenology","producer","consumer")
    dl <- lapply(layers, function(L) ladder_layer(a, SIGNALS, L))
    names(dl) <- layers; present <- layers[vapply(dl, function(x) !is.null(x) && nrow(x)>0, logical(1))]
    if (!length(present)) return(note_plot("No multi-year signals to align at this site"))
    # Per-LAYER hue ramp (one encoding): every line in a strip shares its layer's
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
      hsv <- grDevices::rgb2hsv(grDevices::col2rgb(hex))      # maxColorValue is 255, do NOT pre-divide
      grDevices::hsv(hsv[1], max(0, hsv[2]*0.82), min(1, hsv[3]*1.1)) }   # ease saturation, gentle lift for dark bg
    plist <- lapply(present, function(L){ dd <- dl[[L]]; lm <- LAYER_META[[L]]
      ramp <- LADDER_PAL[[L]] %||% c("#2f7fb5","#16386e","#6db3e0"); j <- 0L
      p <- plotly::plot_ly()
      for (k in unique(dd$key)) { sub <- dd[dd$key==k,]; sub <- sub[order(sub$year),]; j <- j + 1L
        col <- dark_hex(ramp[(j-1) %% length(ramp) + 1])
        nfin <- sum(is.finite(sub$raw))   # surface coverage: a 3-yr line must not look as solid as a 12-yr one
        sub$pin <- paste(k, sub$year, sep = "|")
        p <- p %>% plotly::add_trace(data=sub, x=~year, y=~z, customdata=~pin, type="scatter", mode="lines+markers",
          name=sprintf("%s (n=%d)", sub$label[1], nfin), legendgroup=L, line=list(width=2.6, color=col),
          marker=list(size=6, color=col),
          hovertemplate=paste0("<b>",sub$label[1],"</b> (n=",nfin,")<br>%{x}: %{y:.2f}, where 0 is its average year (",lm$title,")<extra></extra>")) }
      p %>% plotly::layout(yaxis=list(title=list(text=""),
        zeroline=TRUE, zerolinecolor=if(is_dark())"rgba(220,230,240,0.25)" else "rgba(31,42,48,0.18)",
        gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)", tickfont=list(size=9)))
    })
    narrow <- isTRUE((input$vw %||% 1200) < 760)
    # Layer names sit horizontally above each strip: rotated y-titles were taller
    # than a strip and overlapped their neighbours.
    strip_notes <- lapply(seq_along(present), function(i) {
      L <- present[i]
      col <- if (is_dark()) LAYER_META[[L]]$col else
        switch(L, climate="#176b98", phenology="#4b7314", producer="#287a3b", consumer="#b74338", "#53606d")
      list(text = paste0("<b>", toupper(LAYER_META[[L]]$title), "</b>"), font = list(size = 10.5, color = col),
           xref = "paper", x = 0, xanchor = "left",
           yref = paste0(if (i == 1) "y" else paste0("y", i), " domain"), y = 1, yanchor = "bottom",
           showarrow = FALSE)
    })
    # One pin card per plotted point: the year, the value and its support, and
    # how many of this site's pairings that use the signal include the year.
    zs <- do.call(rbind, dl[present])
    has_val <- function(key, yr) key %in% names(a) && any(a$year == yr) && is.finite(a[[key]][a$year == yr][1])
    cards <- stats::setNames(lapply(seq_len(nrow(zs)), function(i) {
      k <- zs$key[i]; yr <- zs$year[i]; row <- a[a$year == yr, , drop = FALSE]
      uses <- PRIORS[PRIORS$from == k | PRIORS$to == k, , drop = FALSE]
      used <- sum(vapply(seq_len(nrow(uses)), function(j) {
        u <- uses[j, ]
        if (u$from == k) has_val(u$to, yr + u$lag) else has_val(u$from, yr - u$lag)
      }, logical(1)))
      in_pairs <- if (!nrow(uses)) "No pairing uses this signal"
        else sprintf("%d of the %d pairings that use this signal", used, nrow(uses))
      list(x = yr, y = zs$z[i], html = pin_card_html(sprintf("%d · %s", yr, input$site), list(
        c("Signal", zs$label[i]),
        c("Value", fmt_val(zs$raw[i], k)),
        c("Against its average year", if (is.finite(zs$z[i])) sprintf("%+.2f standard deviations", zs$z[i]) else "no value"),
        c("Effort", support_text(k, row) %||% "not recorded"),
        c("Year enters", in_pairs))))
    }), paste(zs$key, zs$year, sep = "|"))
    lp <- plotly::subplot(plist, nrows=length(present), shareX=TRUE, titleY=FALSE, margin=c(0, 0, 0.055, 0.02)) %>%
      theme_plotly() %>%
      plotly::layout(showlegend = TRUE, legend=list(orientation="h", y=if (narrow) -0.14 else -0.1, yanchor="top", font=list(size=if (narrow) 9 else 10)),
        xaxis=list(title="", dtick=1, gridcolor=if(is_dark())"rgba(220,230,240,0.07)" else "rgba(31,42,48,0.06)"),
        annotations = strip_notes,
        margin = list(l = 44, r = 20, t = 30, b = if (narrow) 190 else 80))
    htmlwidgets::onRender(lp, "function(el, x, data){ if (window.cascadePinBind) window.cascadePinBind(el, data, 'ladder'); }",
      data = list(cards = cards, sig = paste(input$site, paste(present, collapse = ","), sep = "|")))
  })

  # ---- the four plain lines under the timeline ----
  output$ladderLines <- renderUI({
    a <- ann(); req(nrow(a)); f <- site_facts()
    clim <- intersect(c("precip", "temp", "precip_monsoon", "precip_winter", "temp_spring"), names(a))
    cons <- intersect(SIGNALS$key[SIGNALS$layer == "consumer" & SIGNALS$key %in% LADDER_KEYS], names(a))
    ex <- NULL
    for (i in order(a$year, decreasing = TRUE)) {
      ck <- clim[vapply(clim, function(k) is.finite(a[[k]][i]), logical(1))]
      rk <- cons[vapply(cons, function(k) is.finite(a[[k]][i]), logical(1))]
      if (length(ck) && length(rk)) { ex <- list(year = a$year[i], ck = ck[1], rk = rk[1], i = i); break }
    }
    example <- if (is.null(ex))
        sprintf("%s has no year with both a weather value and an animal count.", input$site)
      else sprintf("In %d at %s, %s was %s and %s was %s.", ex$year, input$site,
                   plain_name(ex$ck), fmt_val(a[[ex$ck]][ex$i], ex$ck),
                   plain_name(ex$rk), fmt_val(a[[ex$rk]][ex$i], ex$rk))
    keys <- LADDER_KEYS[vapply(LADDER_KEYS, function(k) k %in% names(a) && sum(is.finite(a[[k]])) >= 2, logical(1))]
    prods <- unique(vapply(keys, sig_product, character(1)))
    plain_lines(
      shows = "Each line is one measurement, scaled to its own average year: 0 is that signal's average. Compare when lines rise and fall, not how high they sit.",
      example = example,
      from = sprintf("%s, %s to %s.", paste(prods, collapse = "; "), f$yrs[1], f$yrs[2]),
      cannot = "Show that one line moves another. Heights are not comparable across lines.")
  })

  # ---- Pairings at this site: one plain table; a row opens One pairing ----
  output$pairingsTable <- renderUI({
    lk <- links(); req(nrow(lk))
    ids <- pair_id(lk$from, lk$to, lk$lag)
    judged <- ids %in% JUDGED_IDS
    row_ui <- function(i) { r <- lk[i, ]
      tags$tr(class = "pt-row", role = "button", tabindex = "0",
        `data-shiny-input` = "openPairing", `data-shiny-value` = ids[i],
        `aria-label` = sprintf("Open %s", pairing_label(r$from, r$to, r$lag, judged[i])),
        tags$td(sig_label(r$from)),
        tags$td(sprintf("%s%s", sig_label(r$to), if (r$lag > 0) " (next year)" else "")),
        tags$td(class = "pt-n", r$n),
        tags$td(class = "pt-r", if (is.finite(r$r)) sprintf("r = %+.2f", r$r) else "-"),
        tags$td(class = paste0("pt-reads tier-text tier-", r$tier), tier_words(r$tier)))
    }
    group_ui <- function(lab, idx) if (length(idx)) tagList(
      tags$tr(class = "pt-group", tags$th(scope = "colgroup", colspan = "5", lab)),
      lapply(idx, row_ui))
    ord_j <- which(judged); ord_c <- which(!judged)
    ord_c <- ord_c[order(-lk$n[ord_c])]
    tagList(
      tags$table(class = "inspect-tbl pairings-tbl",
        tags$caption(class = "visually-hidden", "Pairings at this site"),
        tags$thead(tags$tr(tags$th(scope = "col", "Driver"), tags$th(scope = "col", "Response"),
          tags$th(scope = "col", "Years (n)"), tags$th(scope = "col", "Direction found"),
          tags$th(scope = "col", "Reads as"))),
        tags$tbody(group_ui("Judged", ord_j), group_ui("Shown for context", ord_c))),
      p(class = "pt-note", "Judged pairings count toward the cross-site summary; context pairings are shown and never counted."))
  })
  observeEvent(input$openPairing, {
    v <- input$openPairing
    if (!v %in% pairing_choices()) return()
    updateTabsetPanel(session, "tabs", selected = "pairing")
    updateSelectInput(session, "pairing", selected = v)
    focus_after_update(id = "pairing", delay = 220L)
  })

  # ---- One pairing: the picker and the selected link ----
  pairing_choices <- reactive({
    ids <- pair_id(PRIORS$from, PRIORS$to, PRIORS$lag)
    labs <- vapply(seq_len(nrow(PRIORS)), function(i)
      pairing_label(PRIORS$from[i], PRIORS$to[i], PRIORS$lag[i], ids[i] %in% JUDGED_IDS), character(1))
    stats::setNames(ids, labs)
  })
  default_pairing <- reactive({
    lk <- links(); ids <- pair_id(lk$from, lk$to, lk$lag)
    # The judged temperature-to-green-up pairing opens when the site can test it.
    # At SRER, otherwise, the monsoon-rain-to-next-year small-mammal pairing opens
    # when it has six or more years (the SRER teaching case; audit 2026-10-18
    # ruling); failing both, the pairing with the most overlapping years.
    prefs <- c("temp|greenup_doy|0",
               if (identical(input$site, "SRER")) "precip_monsoon|mammal_cpue|1")
    for (pref in prefs) {
      hit <- match(pref, ids)
      if (!is.na(hit) && isTRUE(lk$n[hit] >= 6)) return(pref)
    }
    ids[which.max(lk$n)]
  })
  output$pairingPicker <- renderUI({
    ch <- pairing_choices()
    sel <- isolate(input$pairing)
    if (is.null(sel) || !sel %in% ch) sel <- default_pairing()
    selectInput("pairing", "Pairing", choices = ch, selected = sel, width = "100%")
  })
  # When the site changes, a pairing with no overlapping years falls back to the default.
  observeEvent(input$site, {
    sel <- input$pairing; lk <- links()
    r <- lk[pair_id(lk$from, lk$to, lk$lag) == (sel %||% ""), , drop = FALSE]
    if (!nrow(r) || r$n[1] < 3) updateSelectInput(session, "pairing", selected = default_pairing())
  }, ignoreInit = TRUE)
  sel_link <- reactive({
    lk <- links(); ids <- pair_id(lk$from, lk$to, lk$lag)
    chosen <- input$pairing %||% ""
    if (!chosen %in% pairing_choices()) chosen <- default_pairing()
    r <- lk[match(chosen, ids), , drop = FALSE]
    if (!nrow(r) || is.na(r$from[1])) return(NULL)
    r
  })
  output$linkScatterHeader <- renderUI({
    r <- sel_link(); if (is.null(r)) return(NULL)
    judged <- pair_id(r$from, r$to, r$lag) %in% JUDGED_IDS
    use <- if (judged) "judged" else "context"
    p(class = "scatter-head", HTML(sprintf("<b>%s and %s</b>, %s · <span class=\"sh-use sh-%s\">%s</span>",
      htmlEscape(cap_first(plain_name(r$from))), htmlEscape(plain_name(r$to)),
      if (r$lag > 0) "response the next year" else "same year", use, use)))
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
    # tier-matched fit line: GOLD only when the link clears the bar; thin GREY "shape only"
    # for apparent/counter; OMITTED below n=6 (a slope on 5 points is theatre, not evidence)
    if (r$n >= 6 && is.finite(r$r)) { fit <- stats::lm(y ~ x, data=m); xr <- range(m$x)
      consistent <- identical(r$tier, "consistent")
      p <- p %>% plotly::add_lines(x=xr, y=predict(fit, newdata=data.frame(x=xr)), inherit=FALSE,
        line=list(color=if (consistent) fit_gold else fit_grey, width=2, dash="dot"), showlegend=FALSE, hoverinfo="skip") }
    # On-figure box: r, n and the years only, so a screenshot carries its own support.
    yr_rng <- range(m$year)
    stat_txt <- if (is.finite(r$r))
        sprintf("r = %+.2f   n = %d\n%d to %d", r$r, r$n, yr_rng[1], yr_rng[2])
      else sprintf("n = %d   %d to %d", r$n, yr_rng[1], yr_rng[2])
    tier_plot_col <- if (is_dark()) tm$col else tm$text_col
    # The box sits in the top margin, above the plotted points.
    anns <- list(list(x=0, y=1.02, xref="paper", yref="paper", xanchor="left", yanchor="bottom",
      text=gsub("\n","<br>", stat_txt), showarrow=FALSE, align="left",
      font=list(size=12, color=tier_plot_col, family = APP_FONT_STACK),
      bgcolor=if(is_dark())"rgba(20,30,45,0.72)" else "rgba(255,255,255,0.88)", bordercolor=tier_plot_col, borderwidth=1, borderpad=4))
    if (!(r$n >= 6 && is.finite(r$r)))
      anns <- c(anns, list(list(x=0.5, y=0.02, xref="paper", yref="paper", xanchor="center", yanchor="bottom",
        text="No trend line below 6 years; read the points, not a slope.", showarrow=FALSE,
        font=list(size=10, color=if(is_dark())"#9fb0c4" else "#53606d"))))
    sp <- p %>% theme_plotly() %>% plotly::layout(showlegend=FALSE, annotations=anns,
      xaxis = list(title = list(text = sprintf("Driver: %s", sig_label(r$from)), standoff = 12), automargin = TRUE),
      yaxis = list(title = list(text = sprintf("Response: %s", sig_label(r$to)), standoff = 14), automargin = TRUE), margin = list(l = 80, r = 20, t = 64, b = 50))
    # One pin card per plotted year: both values, the effort behind each, and
    # whether the year is one of the years behind this pairing's r.
    a <- ann(); judged <- pair_id(r$from, r$to, r$lag) %in% JUDGED_IDS
    enters <- if (nrow(m) != r$n) sprintf("Plotted; the stored pairing counts %d years", r$n)
      else if (is.finite(r$r) && r$n >= 6) sprintf("Yes, one of the %d years behind r = %+.2f", r$n, r$r)
      else sprintf("Yes, but %d years is too few to judge a direction", r$n)
    cards <- stats::setNames(lapply(seq_len(nrow(m)), function(i) {
      yr <- m$year[i]
      drow <- a[a$year == yr, , drop = FALSE]; rrow <- a[a$year == yr + r$lag, , drop = FALSE]
      list(x = m$x[i], y = m$y[i], html = pin_card_html(sprintf("%d · %s", yr, input$site), list(
        c("Driver", sprintf("%s, %d: %s", sig_label(r$from), yr, fmt_val(m$x[i], r$from))),
        c("Response", sprintf("%s, %d: %s", sig_label(r$to), yr + r$lag, fmt_val(m$y[i], r$to))),
        c("Driver effort", support_text(r$from, drow) %||% "not recorded"),
        c("Response effort", support_text(r$to, rrow) %||% "not recorded"),
        c("In this pairing", enters),
        c("Pairing", if (judged) "Judged" else "Context, never counted"))))
    }), as.character(m$year))
    htmlwidgets::onRender(sp, "function(el, x, data){ el.on('plotly_click', function(d){
      if (d && d.points && d.points.length){ var yr = d.points[0].customdata;
        if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('scatterYear', {year: yr, n: Math.random()}); } });
      if (window.cascadePinBind) window.cascadePinBind(el, data, 'scatter'); }",
      data = list(cards = cards, sig = paste(input$site, r$from, r$to, r$lag, sep = "|")))
  })
  # ---- the four plain lines under the scatter ----
  output$scatterLines <- renderUI({
    r <- sel_link(); if (is.null(r)) return(NULL)
    m <- lag_pairs(ann(), r$from, r$to, r$lag)
    example <- if (nrow(m)) {
        e <- m[which.max(m$year), ]
        sprintf("In %d at %s, %s was %s; %s %s was %s.", e$year, input$site,
                plain_name(r$from), fmt_val(e$x, r$from),
                if (r$lag > 0) sprintf("in %d,", e$year + r$lag) else "that year,",
                plain_name(r$to), fmt_val(e$y, r$to))
      } else sprintf("%s has no year with both values.", input$site)
    prods <- unique(c(sig_product(r$from), sig_product(r$to)))
    from_txt <- if (nrow(m)) sprintf("%s, %d to %d.", paste(prods, collapse = "; "), min(m$year), max(m$year))
      else sprintf("%s.", paste(prods, collapse = "; "))
    plain_lines(
      shows = "One dot per year with both values: the driver across, the response up.",
      example = example,
      from = from_txt,
      cannot = "Show cause. A slope on a handful of years is not evidence, and below six years no line is drawn.")
  })
  # ---- More numbers (inside the fold): what left the figure ----
  output$scatterMore <- renderUI({
    r <- sel_link(); if (is.null(r)) return(NULL)
    num <- function(v, fmt) if (length(v) && is.finite(v)) sprintf(fmt, v) else "-"
    col <- function(nm) if (nm %in% names(r)) r[[nm]][1] else NA_real_
    item <- function(lab, val) tags$tr(tags$th(scope = "row", lab), tags$td(val))
    p_txt <- if (is.finite(r$p))
        sprintf("%.3f (smallest possible with these years: %s)", r$p, num(col("p_floor"), "%.3f"))
      else "-"
    ci_txt <- if (is.finite(r$lo)) sprintf("%+.2f to %+.2f", r$lo, r$hi) else "-"
    sens <- function(rn, nn, lab) item(lab,
      if (is.finite(col(rn))) sprintf("r = %+.2f (n = %d)", col(rn), as.integer(col(nn))) else "-")
    tags$table(class = "inspect-tbl more-tbl",
      tags$caption(class = "visually-hidden", "More numbers for the selected pairing"),
      tags$tbody(
        item("Permutation p", p_txt),
        item("95% interval for r (block bootstrap)", ci_txt),
        sens("r_detrended", "n_detrended", "After removing a straight-line year trend"),
        sens("r_change", "n_change", "Year-to-year changes"),
        sens("r_outcome_alt", "n_outcome_alt", "Additive green-up index"),
        item("Bundle verdict", as.character(r$verdict))))
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
    f <- function(v) if (length(v) == 0 || !is.finite(v)) "-" else format(round(v, 1), big.mark = ",", trim = TRUE)
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

  # ---- QC-flag panel (§7 gold standard): ranked "verify, not wrong" flags for the
  # selected site, behind its own tab (clean by default, never in the Overview). Each
  # flag is a chip that EXPANDS to the exact offending rows on click. ----
  qc <- reactive({ req(input$site); cascade_qc(ann(), links(), SIGNALS, input$site) })
  qc_icon <- function(level) switch(level, high="exclamation-octagon-fill",
    warn="exclamation-triangle-fill", info="info-circle-fill", "check-circle-fill")

  # The flag text comes from the build-time helper; map its old tab names and
  # jargon to the words on screen without touching the hashed helper file.
  qc_plain <- function(x) {
    x <- gsub("on Across NEON", "on All sites", x, fixed = TRUE)
    x <- gsub("Across NEON", "All sites", x, fixed = TRUE)
    x <- gsub("vote-eligible", "judged", x, fixed = TRUE)
    x <- gsub("context-only", "context", x, fixed = TRUE)
    gsub("\u2014", ", ", x)
  }
  output$qcFlags <- renderUI({
    q <- qc(); qf <- q$flags
    has_real <- length(qf) && !identical(qf[[1]]$level, "clean")
    selected_key <- input$qcInspect %||% ""
    tagList(
      p(class="qc-cap-note qc-intro", "Each flag marks a value worth a second look, not an error. ",
        info_pop("Why these are flags, not bugs",
          p("The atlas uses explicit QC choices: bounded non-left-censored green-up intervals with recurrent-species/composition gates, complete-month climate gates, the within-site MAD temperature filter, and the CI-spans-zero guard on “apparent” rows."),
          p("This panel surfaces ", tags$b("where those rules bit"), " for the selected site, ranked worst-first, so a reader verifies a thin or missing value before reading too much into it."))),
      div(class="qc-flags", lapply(qf, function(f){
        clickable <- !identical(f$level, "clean") && f$n > 0
        div(class = paste0("qc-flag qc-flag-", f$level, if (clickable) " qc-flag-click" else ""),
          role = if (clickable) "button" else NULL, tabindex = if (clickable) "0" else NULL,
          `data-shiny-input` = if (clickable) "qcInspect" else NULL,
          `data-shiny-value` = if (clickable) f$key else NULL,
          `aria-label` = if (clickable) sprintf("%s, %d flagged row%s: inspect", f$title, f$n, if (f$n == 1) "" else "s") else NULL,
          `aria-controls` = if (clickable) "qcInspectRegion" else NULL,
          `aria-expanded` = if (clickable) if (identical(selected_key, f$key)) "true" else "false" else NULL,
          bs_icon(qc_icon(f$level)),
          div(class="qcf-body",
            div(class="qcf-title", f$title, if (f$n > 0) tags$span(class="qcf-n", f$n)),
            div(class="qcf-detail", qc_plain(f$detail))),
          if (clickable) tags$span(class="qcf-go", bs_icon("chevron-right"))) })),
      if (has_real) div(class="qcf-hint", bs_icon("hand-index-thumb"),
        " activate a flag to list the exact rows behind it"),
      uiOutput("qcInspectPanel"),
      div(class="qc-toolbar",
        downloadButton("dlQcReport", tagList(bs_icon("filetype-csv"), " Download QC report (CSV)"), icon = NULL,
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
    fmt <- function(v) if (is.numeric(v)) ifelse(is.na(v), "NA", format(round(v, 2), trim=TRUE)) else format(v)
    div(id = "qcInspectRegion", class="qc-inspector", role = "region",
      tabindex = "-1", `aria-live` = "polite", `aria-atomic` = "true",
      `aria-label` = sprintf("Rows behind the %s quality-control flag", f$title),
      div(class="qci-head", bs_icon(qc_icon(f$level)),
        tags$b(sprintf(" %s · %d row%s", f$title, f$n, if (f$n==1) "" else "s")),
        downloadButton("dlQcFlag", tagList(bs_icon("filetype-csv"), sprintf(" All %d row%s (CSV)", nrow(st), if (nrow(st) == 1) "" else "s")),
          icon = NULL, class = "btn-outline-dark btn-sm qci-dl")),
      div(class="qc-cap-scroll", tags$table(class="inspect-tbl",
        tags$caption(class="visually-hidden", sprintf("Exact rows behind the %s quality-control flag", f$title)),
        tags$thead(tags$tr(lapply(cols, function(col) tags$th(scope="col", col)))),
        tags$tbody(lapply(seq_len(nrow(sv)), function(i)
          tags$tr(lapply(cols, function(cc) tags$td(fmt(sv[[cc]][i])))))))),
      if (nrow(st) > head_n) p(class="qc-cap-note", sprintf("Showing first %d of %d.", head_n, nrow(st))))
  })
  # Per-flag CSV: every row behind the open flag (the inspector shows at most 200).
  output$dlQcFlag <- downloadHandler(
    filename = function() sprintf("%s-response-atlas-qc-%s.csv", input$site,
                                  gsub("[^A-Za-z0-9_-]", "-", input$qcInspect %||% "flag")),
    content = function(file) {
      key <- input$qcInspect; q <- qc()
      req(!is.null(key), key %in% names(q$sets))
      st <- q$sets[[key]]
      f <- Filter(function(x) identical(x$key, key), q$flags)
      title <- if (length(f)) f[[1]]$title else key
      level <- if (length(f)) f[[1]]$level else "unknown"
      hdr <- c(sprintf("# NEON Cross-Product Response Atlas · %s data-quality flag: %s (level %s, %d row%s; verify, not wrong).",
                       input$site, title, level, nrow(st), if (nrow(st) == 1) "" else "s"),
               "# Every row behind this flag. Each is a value worth a second look, not automatically an error.", "")
      writeLines(c(hdr[seq_len(length(hdr) - 1L)], export_provenance(), ""), file)
      suppressWarnings(utils::write.table(st, file, sep=",", row.names=FALSE, append=TRUE, qmethod="double"))
    })
  output$dlQcReport <- downloadHandler(
    filename = function() sprintf("%s-response-atlas-qc.csv", input$site),
    content = function(file){ rep <- cascade_qc_report(ann(), links(), SIGNALS, input$site)
      if (is.null(rep)) rep <- data.frame(note="No data-quality flags at this site.")
      # Same wording cleanup the screen gets (current tab names, no em dashes).
      for (col in intersect(c("flag", "detail"), names(rep))) rep[[col]] <- qc_plain(as.character(rep[[col]]))
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
      f <- site_facts()
      verdict <- paste(counts_line(f, s), judged_sentence(f))
      con <- file(file, open = "w", encoding = "UTF-8")
      on.exit(close(con))
      writeLines(c(
        sprintf("# NEON Cross-Product Response Atlas: site report card for %s (%s%s)", s, nm,
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
      if (!is.null(qcrep)) for (col in intersect(c("flag", "detail"), names(qcrep))) qcrep[[col]] <- qc_plain(as.character(qcrep[[col]]))
      writeLines("## Data-quality review (each flag is a prompt to inspect the source/support, not automatically an error)", con)
      if (is.null(qcrep) || !nrow(qcrep))
        writeLines("All clear: no flags at this site.", con)
      else
        suppressWarnings(utils::write.table(qcrep, con, sep = ",", row.names = FALSE, qmethod = "double"))
    })

  # ---- top-bar Report (.pdf): the same site story on paper ----
  # Base graphics via atlas_report_pdf() in global.R: the hero tally, the signal
  # table, the pairings at this site, the exploratory caveat and the build stamp.
  report_pdf_blocks <- function(s) {
    row <- neon_sites[neon_sites$site == s, ]
    nm <- if (nrow(row)) row$name[1] else s
    st <- if (nrow(row)) row$state[1] else ""
    a <- ann(); lk <- links(); f <- site_facts()
    sig_rows <- do.call(rbind, lapply(c("climate", "phenology", "producer", "consumer"), function(L) {
      ks <- SIGNALS$key[SIGNALS$layer == L & SIGNALS$key %in% LADDER_KEYS]
      do.call(rbind, lapply(ks, function(k) {
        v <- a[[k]]; nf <- sum(is.finite(v)); if (nf < 1) return(NULL)
        yrs <- range(a$year[is.finite(v)])
        data.frame(Layer = LAYER_META[[L]]$title, Signal = sig_label(k), Unit = sig_unit(k),
                   Years = as.character(nf), Span = sprintf("%s to %s", yrs[1], yrs[2]),
                   stringsAsFactors = FALSE)
      }))
    }))
    ids <- pair_id(lk$from, lk$to, lk$lag); judged <- ids %in% JUDGED_IDS
    ord <- c(which(judged), which(!judged)[order(-lk$n[!judged])])
    assoc <- data.frame(
      Driver = vapply(ord, function(i) sig_label(lk$from[i]), character(1)),
      Response = vapply(ord, function(i) sprintf("%s%s", sig_label(lk$to[i]), if (lk$lag[i] > 0) " (next year)" else ""), character(1)),
      `Years (n)` = as.character(lk$n[ord]),
      `Direction found` = ifelse(is.finite(lk$r[ord]), sprintf("r = %+.2f", lk$r[ord]), "-"),
      `Reads as` = tier_words(lk$tier[ord]),
      Counted = ifelse(judged[ord], "Judged", "Context"),
      check.names = FALSE, stringsAsFactors = FALSE)
    m <- CASCADE$meta
    list(
      list(type = "title", text = "NEON Cross-Product Response Atlas: site report"),
      list(type = "p", font = 2, text = sprintf("%s · %s%s", s, nm, if (nzchar(st)) paste0(", ", st) else "")),
      list(type = "p", text = paste(counts_line(f, s), judged_sentence(f))),
      list(type = "note", text = paste(
        "Exploratory, not preregistered: the pairings were chosen while exploring these data. Each row is a within-site association over a few years. It cannot show that weather drives plants",
        "or that plants drive animals, and no row is a tested chain. Below six overlapping years no direction is judged.",
        "Judged pairings count toward the cross-site summary; context pairings are shown and never counted.",
        "Animal indices are relative within one site, not headcounts, and are not comparable across sites.")),
      list(type = "h2", text = "What is measured here"),
      list(type = "table", df = sig_rows, widths = c(1.3, 2.4, 1.3, 0.7, 1.1), empty = "No signals with a value at this site."),
      list(type = "h2", text = "Pairings at this site"),
      list(type = "table", df = assoc, widths = c(1.6, 2.0, 0.8, 1.1, 1.8, 0.9), empty = "No pairings at this site."),
      list(type = "h2", text = "Build and sources"),
      list(type = "p", text = sprintf("Bundle built from source state %s; snapshot ends %s (%s); schema %s; prior family %s (%s).",
                                      m$built_when, m$last_complete_year, m$last_complete_year_basis,
                                      m$schema_version, m$prior_family_version, m$prior_family_status)),
      if (!is.null(ri <- source_release_info())) list(type = "p", text = paste0("Releases: ",
        paste(vapply(seq_len(nrow(ri)), function(i) sprintf("%s %s", tolower(ri$label[i]), release_text(ri[i, ])), character(1)),
              collapse = "; "), ".")),
      list(type = "p", text = paste0("Data: NEON ",
        paste(sprintf("%s (%s)", tolower(SOURCE_PRODUCTS$label), SOURCE_PRODUCTS$dpid), collapse = ", "),
        "; climate from NEON ", paste(sprintf("%s (%s)", tolower(CLIMATE_PRODUCTS$label), CLIMATE_PRODUCTS$dpid), collapse = " and "),
        ". NEON data are provided under CC BY 4.0. This is an independent tool, not endorsed by NEON, Battelle or the NSF.")))
  }
  output$dlReportPdf <- downloadHandler(
    filename = function() sprintf("response-atlas-%s-report-card.pdf", input$site),
    content = function(file) {
      s <- input$site
      atlas_report_pdf(file, report_pdf_blocks(s),
        footer = sprintf("NEON Cross-Product Response Atlas · %s · built %s · exploratory, not causal",
                         s, CASCADE$meta$built_when))
    })

  # ---- About ----
  output$aboutPanel <- renderUI({
    pr <- PRIORS
    conf_badge <- function(c) {
      col <- switch(c %||% "", strong="#1a6b35", moderate="#e0b43a", weak="#9c2931", "#53606d")
      ink <- if (identical(c, "moderate")) "#2e2406" else "#ffffff"
      tags$span(class="dt-chip", style=sprintf("background:%s;color:%s", col, ink), c %||% "n/a")
    }
    eligibility_badge <- function(ec) {
      vote <- identical(as.character(ec), "all")
      tags$span(class="dt-chip", style=sprintf("background:%s;color:#fff", if (vote) "#1a6b35" else "#53606d"),
                if (vote) "Yes" else "No, context")
    }
    about_fold <- function(icon, title, ...) tags$details(class = "picker-list about-fold",
      tags$summary(class = "picker-list-summary",
        tags$span(class = "pls-label", bs_icon(icon), " ", title),
        tags$span(class = "pls-chevron", bs_icon("chevron-down"))),
      div(class = "measured-body", ...))
    prow <- function(i){ r <- pr[i,]; arrow <- if (r$sign>0) "↑ more → more" else "↓ more → earlier/less"
      tags$tr(tags$td(sig_label(r$from)), tags$td(sig_label(r$to)), tags$td(arrow),
        tags$td(if (r$lag>0) sprintf("%d yr later", r$lag) else "same yr"),
        tags$td(conf_badge(r$conf)), tags$td(eligibility_badge(r$expected_class)), tags$td(class="pr-note", r$note)) }
    gloss <- function(term, def) div(class="gloss-item", tags$b(term), tags$span(HTML(def)))
    div(class="about-wrap",
      div(class="about-card", h3("\U0001F517 What this is"),
        p(HTML(paste0("The NEON Cross-Product Response Atlas puts annual weather, plant timing and animal counts from seven NEON products on one calendar, site by site. Each product has its own explorer in the suite: ",
          paste(vapply(list(c("mammal", "small mammals"), c("plant", "plant diversity"), c("veg", "vegetation structure"),
                            c("phe", "plant phenology"), c("bird", "breeding birds"), c("mosq", "mosquitoes")),
                       function(k) as.character(suite_link(k[1], k[2])), character(1)), collapse = ", "),
          " and ", as.character(suite_link("beetle", "ground beetles")), ". This one lines them up.")))),

      div(class="about-card about-plain", h3(bs_icon("exclamation-triangle"), " What this can and cannot say"),
        tags$ul(
          tags$li("It lines up annual weather, plant timing and animal counts from seven NEON products on one calendar."),
          tags$li("It judges two pairings across sites, both temperature and green-up, and shows ten others for context."),
          tags$li("The pairings, lags and seasons were chosen and revised while these data were explored; they are fixed for this build, and the app does not let a reader slide them."),
          tags$li("It cannot show that weather drives plants or that plants drive animals, and no page is a tested chain."))),

      local({
        m <- CASCADE$meta; sp <- m$source_products
        about_fold("fingerprint", "Snapshot and provenance",
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
      div(class="about-card about-plain", h3(bs_icon("signpost-split"), " Site groups"),
        p("The dryland group is a keyword rule on the site's one-line description (desert, sagebrush or semi-desert), not a measured climate class. It can misgroup dry forests, semiarid grasslands and mixed sites.")),

      div(class="about-card about-plain", h3(bs_icon("chat-square-text"), " Plain words for the terms on screen"),
        gloss("Green-up timing index", "A yearly index of when plants leafed out at a site, built from NEON phenology visits. Each species is centred on its own usual timing before species are averaged, so a smaller value means earlier than usual, not a calendar date. A data refresh can revise past values. NEON changed how often plants were observed during the record (fewer visits from March 2020 through 2021 because of COVID-19, one visit a week at gradient sites from August 2024, and core sites only from January 2026), so a change in visit frequency can move the index on its own."),
        gloss("Lag", "A calendar offset. A <b>one-year lag</b> pairs this year's weather with <em>next</em> year's response. The lag states a proposed pathway; the data cannot prove it."),
        gloss("Catch rate (per 100 trap-nights)", "Small mammals caught for every 100 trap-nights of effort, so years with more trapping compare fairly. It is a <b>relative index within one site</b>, not a headcount."),
        gloss("The timeline", "Each strip is one measurement layer, scaled to that signal's own average year: up is above average, down is below. Compare timing, not heights; stacking the strips does not test a chain.")),

      about_fold("calculator", "For statisticians",
      div(class="about-card about-plain", h3(bs_icon("calculator"), " The statistics"),
        gloss("“Could this be luck?” (the circular-shift test)", "For each link we rotate the response over its full calendar grid, retaining missing years. That preserves order, annual spacing, and the gap pattern while breaking the original alignment. The exact finite floor is <b>1/(valid null shifts + 1)</b> and is reported for each link. This coarse p is transparency, not a per-site significance claim."),
        gloss("The uncertainty band (95% CI)", "An indicative range from a circular moving-block bootstrap, which resamples contiguous wrapped year blocks to retain short-range temporal structure. With only ~6 years it is often <b>very wide</b>; it diagnoses instability rather than promising precision."),
        gloss("“Too few years to judge”", "Below <b>6 overlapping years</b> we show the lined-up data but give <b>no verdict</b>; there isn't enough to tell signal from noise."),
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
                "; REML + truncated Knapp&ndash;Hartung pooled r = %+.2f (95%% CI [%.2f, %.2f])",
                "; 95%% prediction interval [%.2f, %.2f]; I&sup2; = %.0f%%",
                "; raw one-sided p = %.3g; Holm p = %.3g (k = %d sites, df = %d)"),
                rma$pooled_r, rma$ci_r[1], rma$ci_r[2], rma$pi_r[1], rma$pi_r[2],
                rma$I2, rma$p_one_sided, rma$p_one_sided_holm, rma$k, rma$df)
              else " (the validated companion contains no effect-size estimate for this row)"))) }))
          else p(class = "qc-cap-note", bs_icon("info-circle"),
            "No association met the companion meta-analysis eligibility contract in this snapshot."),
          p(class = "qc-cap-note", "The prediction interval and heterogeneity lead interpretation; the directional p-values are secondary. The random-effects summary uses Knapp-Hartung inference with the ad hoc truncation, so its interval is never narrower than the standard random-effects interval, and Holm adjustment covers both eligible temperature-green-up rows. The Fisher-z sampling variance still assumes effectively independent paired years and does not model within-site serial dependence. The entire companion remains exploratory, is not a posterior probability, and does not upgrade any per-site verdict."),
          p(class = "qc-cap-note", "March to May temperature is a same-season comparison, not a test of what triggers green-up: at every vote-eligible site the median green-up falls before May 1 (site medians from day 41 to day 119), so part of the window is weather after green-up."))
      })),

      div(class="about-card", h3(bs_icon("diagram-3"), " The twelve pairings"),
        tags$table(class="inspect-tbl",
          tags$caption(class="visually-hidden", "The twelve pairings, their expected direction, lag and whether each is counted"),
          tags$thead(tags$tr(tags$th(scope="col", "Driver"), tags$th(scope="col", "Response"),
          tags$th(scope="col", "Stated direction"), tags$th(scope="col", "Lag"),
            tags$th(scope="col", "Literature basis"), tags$th(scope="col", "Counted?"), tags$th(scope="col", "In plain English"))),
          tags$tbody(lapply(seq_len(nrow(pr)), prow))),
        p(class="qc-cap-note", style="margin-top:8px", HTML("Sources: warmer-springs→earlier green-up · <b>Fu et al. 2015</b> (<i>Nature</i>), Richardson et al. 2013; rain→desert rodents (lagged, non-linear) · <b>Brown &amp; Ernest 2002</b>, Thibault et al. 2010; rain-timing · Zhang et al. 2021; dryland productivity~precipitation · Sala et al. 1988, Huxman et al. 2004, Knapp et al. 2017; the “green wave” · Merkle et al. 2016. A green-up→bird link is <b>deliberately omitted</b>: the mismatch literature is about timing-synchrony, not “later green-up → more birds.”"))),

      div(class="about-card", h3(bs_icon("database"), " Data and limits"),
        p("Per-site annual signals assembled from seven sibling apps' bundles plus the NEON-tower climate overlays. ",
          tags$b("Small-mammal catch rate"), " is a relative annual index (captures per 100 deployed trap-nights), not effort-standardised across sites, so read within-site trends only. ",
          tags$b("Temperature"), " is either a complete annual average or a complete March–May average. Neither is guaranteed to precede the green-up events it is paired with, so both are contemporaneous proxies rather than trigger measurements. ",
          tags$b("Plant richness"), " is composition, not productivity. Beetle effort is observed only for catch-bearing events, so beetle indices are descriptive and cannot cast inferential votes. Other non-green-up links likewise remain contextual until their response windows, effort, and directional basis support stronger use."),
        p(bs_icon("envelope"), " ", tags$a(href="mailto:desertdatalabs@gmail.com","desertdatalabs@gmail.com"))),

      div(class="about-card", h3(bs_icon("table"), " Codebook and downloads"),
        p("Every signal, its units, how it's derived, and the n-gates, plus analysis-ready CSV exports."),
        uiOutput("codebook")),

      cascade_sources(),

      local({
        ri <- source_release_info()
        rel_for <- function(prod) {
          if (is.null(ri)) return(NULL)
          r <- ri[ri$product == prod, , drop = FALSE]
          if (!nrow(r)) return(NULL)
          r <- r[1, ]; dl <- release_doi_link(r)
          tags$span(class = "src-release", HTML(paste0(
            htmlEscape(sprintf(" · data through %s, %s", r$data_through, r$release)),
            if (!is.null(dl)) paste0(", ", as.character(dl)) else "",
            if (!is.na(r$provisional_from) && nzchar(r$provisional_from))
              htmlEscape(sprintf("; provisional from %s", r$provisional_from)) else "")))
        }
        div(class="about-card", h3(bs_icon("database-check"), " Source data products"),
          tags$ul(class = "src-products",
            lapply(seq_len(nrow(SOURCE_PRODUCTS)), function(i) tags$li(
              tags$b(SOURCE_PRODUCTS$label[i]), " ",
              product_link(SOURCE_PRODUCTS$dpid[i]),
              rel_for(SOURCE_PRODUCTS$product[i]))),
            tags$li(tags$b("Climate overlays"), " NEON tower ",
              tolower(CLIMATE_PRODUCTS$label[1]), " ", product_link(CLIMATE_PRODUCTS$dpid[1]), " and ",
              tolower(CLIMATE_PRODUCTS$label[2]), " ", product_link(CLIMATE_PRODUCTS$dpid[2]),
              "(monthly summaries carried in the Small Mammals bundle)")),
          p(class = "qc-cap-note", if (is.null(ri))
            "Each product page lists its releases and their DOIs. This snapshot does not record which release each product came from."
            else "Each product page lists its releases and their DOIs."))
      }),

      div(class="about-card", h3(bs_icon("award"), " Data attribution & license"),
        p(class="qc-cap-note",
          "Built with data from the National Ecological Observatory Network (NEON), a U.S. National Science Foundation program operated by Battelle. NEON data are provided under a Creative Commons Attribution 4.0 International (CC BY 4.0) license (",
          tags$a(href="https://creativecommons.org/licenses/by/4.0/", target="_blank", rel="noopener", "creativecommons.org/licenses/by/4.0"),
          "). This app aggregates and derives summary metrics from the raw NEON data products; the underlying measurements are unaltered. It is an independent, unofficial tool and is not endorsed by NEON, Battelle, or the NSF."),
        p(class="qc-cap-note", style="margin-top:6px",
          "To cite a product: NEON (National Ecological Observatory Network). <Product name> (<DPID>), <release>. https://data.neonscience.org/data-products/<DPID>. Add the date you accessed it and, if you used this app, the bundle stamp ",
          tags$code(CASCADE$meta$built_when), ".")),

      suite_registry_card())
  })
  # ---- SEASONAL CLIMATE reveal (the desert insight made visible) ----
  output$seasonalPlot <- renderPlotly({
    a <- ann(); req(nrow(a))
    if (!is_desert(input$site)) return(note_plot("The winter/monsoon illustration is shown only for sites in the descriptive dryland-keyword group."))
    d <- a[is.finite(a$precip_winter) | is.finite(a$precip_monsoon), c("year","precip_winter","precip_monsoon")]
    if (!nrow(d)) return(note_plot("No seasonal precipitation reconstructed for this site yet."))
    winter_col <- if (is_dark()) "#43b8e8" else "#126c91"
    monsoon_col <- if (is_dark()) "#ffd24a" else "#7a5900"
    # Each season's bars draw only the years that season has a value (no NA rows).
    plotly::plot_ly() %>%
      plotly::add_bars(data=d[is.finite(d$precip_winter), , drop=FALSE], x=~year, y=~precip_winter,
                       name="Winter rain (Oct–Mar)", marker=list(color=winter_col)) %>%
      plotly::add_bars(data=d[is.finite(d$precip_monsoon), , drop=FALSE], x=~year, y=~precip_monsoon,
                       name="Monsoon rain (Jul–Sep)", marker=list(color=monsoon_col)) %>%
      theme_plotly() %>% plotly::layout(barmode="group", legend=list(orientation="h", y=-0.22),
        yaxis=list(title="precipitation (mm)"), xaxis=list(title="", dtick=1), margin=list(l=55,r=20,t=10,b=40))
  })
  # ---- Winter rain and monsoon rain: dryland sites only, no card elsewhere ----
  output$seasonalCard <- renderUI({
    if (!is_desert(input$site)) return(NULL)
    a <- ann(); req(nrow(a))
    rc <- function(from, to, lag) {
      if (!all(c(from, to) %in% names(a))) return(list(r = NA_real_, n = 0L, years = integer(0)))
      m <- lag_pairs(a, from, to, lag)
      r <- if (nrow(m) >= 3) suppressWarnings(stats::cor(m$x, m$y)) else NA_real_
      list(r = if (is.finite(r)) r else NA_real_, n = nrow(m), years = m$year)
    }
    ann_mam <- rc("precip", "mammal_cpue", 1); mon_mam <- rc("precip_monsoon", "mammal_cpue", 1)
    show_r <- function(x) if (is.finite(x$r)) sprintf("r = %+.2f, n = %d", x$r, x$n)
      else sprintf("n = %d, too few years for r", x$n)
    reading <- if (is.finite(ann_mam$r) && is.finite(mon_mam$r)) {
        better <- if (abs(mon_mam$r) > abs(ann_mam$r)) "the monsoon total fits better than the annual total"
          else if (abs(mon_mam$r) < abs(ann_mam$r)) "the annual total fits better than the monsoon total"
          else "the two totals fit about equally"
        nmax <- max(ann_mam$n, mon_mam$n)
        sprintf("At %s %s, but %d years is too few to call it.", input$site, better, nmax)
      } else sprintf("At %s there are too few years with both values to compare the two totals.", input$site)
    yrs_all <- c(ann_mam$years, mon_mam$years)
    seas <- a[is.finite(a$precip_monsoon) | is.finite(a$precip_winter), , drop = FALSE]
    ex <- if (nrow(seas)) seas[which.max(seas$year), ] else NULL
    example <- if (is.null(ex)) sprintf("%s has no seasonal rain on record.", input$site)
      else sprintf("In %d at %s, winter rain was %s and monsoon rain was %s.", ex$year, input$site,
                   fmt_val(ex$precip_winter, "precip_winter"), fmt_val(ex$precip_monsoon, "precip_monsoon"))
    card(
      card_head("droplet-half", "Winter rain and monsoon rain"),
      spin(plotlyOutput("seasonalPlot", height = "300px")),
      div(class = "seasonal-cmps",
        div(class = "seasonal-cmp",
          div(class = "sc-title", "Rain, then small-mammal catch the next year"),
          div(class = "sc-row", span(class = "sc-k", "Annual rain"), span(class = "sc-v", show_r(ann_mam))),
          div(class = "sc-row", span(class = "sc-k", "Monsoon rain"), span(class = "sc-v", show_r(mon_mam))))),
      p(class = "sc-reading", reading),
      plain_lines(
        shows = "Rain in two seasons, one pair of bars per year: winter (October to March) and monsoon (July to September).",
        example = example,
        from = sprintf("NEON tower weather; NEON small mammals (DP1.10072.001)%s.",
                       if (length(yrs_all)) sprintf(", %d to %d", min(yrs_all), max(yrs_all)) else ""),
        cannot = "Show that rain sets the catch. A short record can favour either total by chance."))
  })

  # ---- ALL SITES: the judged pairings across NEON (card X1) ----
  # One headline line computed from POOLED, one bar per judged pairing, the
  # statistics in a fold. Context pairings are never pooled and are not listed here.
  plain_sig <- function(k) switch(k, temp = "annual temperature", temp_spring = "March to May temperature",
    greenup_doy = "green-up timing", tolower(sig_label(k)))
  cap1 <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))
  num_word <- function(n) if (n >= 1 && n <= 12) c("one","two","three","four","five","six","seven",
    "eight","nine","ten","eleven","twelve")[n] else as.character(n)
  lag_words <- function(lag) if (lag == 1) "next yr" else sprintf("%d yr later", lag)
  output$pooledHeadline <- renderUI({
    pl <- POOLED; if (!nrow(pl)) return(NULL)
    judged <- if ("expected_class" %in% names(pl)) pl[pl$expected_class %in% "all", , drop = FALSE] else pl
    poolable <- if ("poolable" %in% names(judged)) judged$poolable %in% TRUE else judged$sites >= 3L
    rank <- judged[poolable, , drop = FALSE]; under <- judged[!poolable, , drop = FALSE]
    prior_sign <- function(r) {
      m <- PRIORS[PRIORS$from == r$from & PRIORS$to == r$to & PRIORS$lag == r$lag, , drop = FALSE]
      if (nrow(m)) m$sign[1] else NA_real_
    }
    direction_words <- function(r) {
      s <- prior_sign(r); down <- isTRUE(s < 0)
      drv <- if (r$from %in% c("temp", "temp_spring")) "Warmer years" else sprintf("More %s", plain_sig(r$from))
      rsp <- if (identical(r$to, "greenup_doy")) (if (down) "earlier green-up" else "later green-up")
             else sprintf("%s %s", if (down) "less" else "more", plain_sig(r$to))
      paste0(drv, ", ", rsp)
    }
    pair_words <- function(r) paste0(cap1(plain_sig(r$from)), " → ", plain_sig(r$to),
      if (r$lag > 0) sprintf(" (%s)", lag_words(r$lag)) else "")
    headline <- if (nrow(rank)) {
      bits <- vapply(seq_len(nrow(rank)), function(i) { r <- rank[i, ]
        if (i == 1) sprintf("at %d of the %d sites with enough years using %s", r$k, r$sites, plain_sig(r$from))
        else sprintf("at %d of %d using %s", r$k, r$sites, plain_sig(r$from)) }, character(1))
      joined <- if (length(bits) == 1) bits else
        paste0(paste(bits[-length(bits)], collapse = ", "), ", and ", bits[length(bits)])
      sprintf("%s: the direction fits %s.", direction_words(rank[1, ]), joined)
    } else "Neither judged pairing has enough sites to pool in this snapshot."
    rows <- lapply(seq_len(nrow(rank)), function(i) { r <- rank[i, ]
      div(class = "pooled-row",
        div(class = "pl-link", pair_words(r)),
        div(class = "pl-bar-wrap", `aria-hidden` = "true",
          div(class = "pl-bar", style = sprintf("width:%.0f%%", 100 * r$k / r$sites))),
        div(class = "pl-stat", tags$b(sprintf("fits at %d of %d sites", r$k, r$sites))))
    })
    under_rows <- if (nrow(under)) div(class = "pooled-under", lapply(seq_len(nrow(under)), function(i) { r <- under[i, ]
      div(class = "pooled-row pooled-underfloor",
        div(class = "pl-link", pair_words(r)),
        div(class = "pl-stat", span(class = "pl-notpool", sprintf("%d site%s, not poolable", r$sites, if (r$sites == 1) "" else "s"))))
    })) else NULL
    n_ctx <- sum(PRIORS$expected_class %in% "none")
    count_of <- function(r, k, n, unit = "sites") {
      if (!all(c(k, n) %in% names(r)) || !is.finite(r[[n]]) || r[[n]] <= 0) return("n/a")
      sprintf("%d of %d %s", as.integer(r[[k]]), as.integer(r[[n]]), unit)
    }
    stat_rows <- lapply(seq_len(nrow(rank)), function(i) { r <- rank[i, ]
      holm <- if ("p_holm" %in% names(r) && is.finite(r$p_holm)) sprintf("%.3f", r$p_holm) else "n/a"
      dom <- count_of(r, "k_domain", "domains", "domains")
      if (dom != "n/a" && "domain_ties" %in% names(r) && is.finite(r$domain_ties) && r$domain_ties > 0)
        dom <- sprintf("%s (+%d tied)", dom, as.integer(r$domain_ties))
      pair <- function(lab, val) tagList(tags$dt(lab), tags$dd(val))
      div(class = "pooled-stats",
        tags$h4(class = "ps-title", pair_words(r)),
        tags$dl(class = "ps-list",
          pair("Raw p", if (is.finite(r$p)) sprintf("%.3f", r$p) else "n/a"),
          pair("Holm p", holm),
          pair("Median r", if (is.finite(r$median_r)) sprintf("%+.2f", r$median_r) else "n/a"),
          pair("Detrended", count_of(r, "k_detrended", "sites_detrended")),
          pair("Consecutive change", count_of(r, "k_change", "sites_change")),
          pair("Additive green-up", count_of(r, "k_outcome_alt", "sites_outcome_alt")),
          pair("NEON-domain majority", dom)))
    })
    tagList(
      p(class = "pooled-headline", tags$b(headline)),
      p(class = "prereg-caveat", "Exploratory, not preregistered: the pairings were chosen while exploring these data."),
      div(class = "pooled-list", rows),
      under_rows,
      p(class = "qc-cap-note", sprintf("%s other pairings are shown for context and never counted; the About tab lists them.",
        cap1(num_word(n_ctx)))),
      tags$details(class = "picker-list",
        tags$summary(class = "picker-list-summary",
          tags$span(class = "pls-label", bs_icon("calculator"), " The statistics"),
          tags$span(class = "pls-chevron", bs_icon("chevron-down"))),
        div(class = "measured-body",
          stat_rows,
          p(class = "qc-cap-note", "The exact binomial is one-sided against a 0.5 sign split and treats sites as independent. The family was chosen and revised while these data were explored, so these are exploratory screens, not preregistered tests."))))
  })
  # ---- ALL SITES: every site, every pairing (card X2) ----
  output$scoreboard <- renderUI({
    sl <- SUITE_LINKS; if (!nrow(sl)) return(p(class="qc-cap-note","The site table is unavailable; the data bundle needs a rebuild."))
    pr <- PRIORS
    judged_j  <- which(pr$expected_class %in% "all")
    context_j <- which(!pr$expected_class %in% "all")
    show_ctx  <- isTRUE(input$showContext)
    col_j <- if (show_ctx) c(judged_j, context_j) else judged_j
    plain_tier <- c(consistent = "Fits the expected direction", apparent = "Fits, but the range includes zero",
      counter = "Runs the other way", neutral = "No direction", exploratory = "Too few years to judge",
      insufficient = "Not testable here")
    col_head <- function(j) {
      lab <- sprintf("%s → %s", sig_abbr(pr$from[j]), tolower(sig_abbr(pr$to[j])))
      if (pr$lag[j] > 0) lab <- sprintf("%s (%s)", lab, lag_words(pr$lag[j]))
      tags$th(class = paste0("sb-col", if (j %in% context_j) " sb-col-ctx" else ""), scope = "col",
        title = sprintf("%s → %s%s", sig_label(pr$from[j]), sig_label(pr$to[j]),
                        if (j %in% context_j) ", context" else ", judged"), lab)
    }
    hd_judged  <- lapply(judged_j, col_head)
    hd_context <- if (show_ctx) lapply(context_j, col_head) else NULL
    sm <- SITE_META
    sm$em <- vapply(sm$site, function(s){ d <- sl[sl$site==s & sl$expected %in% TRUE & sl$n>=6 & !is.na(sl$sign_match),]; sum(d$sign_match) }, numeric(1))
    # testable-link count (the denominator behind em): judged links with n>=6 and a known sign
    sm$ntest <- vapply(sm$site, function(s){ sum(sl$site==s & sl$expected %in% TRUE & sl$n>=6 & !is.na(sl$sign_match)) }, numeric(1))
    # pairings with enough years: every pairing at the site with n >= 6
    sm$nenough <- vapply(sm$site, function(s){ sum(sl$site==s & sl$n>=6, na.rm = TRUE) }, numeric(1))
    sm <- switch(input$sbSort %||% "default",
      abc      = sm[order(sm$site), , drop=FALSE],                       # A to Z
      agree    = sm[order(-sm$em, -sm$ntest, sm$site), , drop=FALSE],     # most fits
      sm[order(sm$biome_class, -sm$em, sm$site), , drop=FALSE])           # default: group, then most fits
    cell_for <- function(s, j){
      d <- sl[sl$site==s & sl$from==pr$from[j] & sl$to==pr$to[j] & sl$lag==pr$lag[j], , drop=FALSE]
      ctx <- j %in% context_j
      if (!nrow(d)) return(tags$td(class=paste0("sb-cell sb-na", if (ctx) " sb-dim" else "")))
      tier <- d$tier[1]
      ttl <- sprintf("%s · %s → %s: %s, %d year%s%s. %s", s, sig_label(pr$from[j]), sig_label(pr$to[j]),
        if (tier %in% names(plain_tier)) plain_tier[[tier]] else tier, d$n[1], if (isTRUE(d$n[1] == 1)) "" else "s",
        if (is.finite(d$r[1])) sprintf(", r = %+.2f", d$r[1]) else "",
        if (ctx) "Context, never counted." else "Judged.")
      # The glyph travels with the colour so the verdict is never colour-only.
      gly <- switch(tier, consistent="✓", apparent="≈",
                    neutral=if (is.finite(d$r[1])) "0" else "",
                    counter="✗", exploratory="·", "")
      cell_txt <- if (is.finite(d$r[1])) {
        if (nzchar(gly)) sprintf("%s %+.2f", gly, d$r[1]) else sprintf("%+.2f", d$r[1])
      } else gly
      tags$td(class=paste0("sb-cell sb-clk sb-", tier, if (ctx) " sb-dim" else ""),
        title=ttl,
        role="button", tabindex="0", `aria-label`=paste(ttl, "Open this pairing."),
        `data-shiny-input`="sbCell",
        `data-shiny-value`=sprintf("%s|%s|%s|%d", s, pr$from[j], pr$to[j], pr$lag[j]),
        cell_txt)
    }
    rowfor <- function(i){
      s <- sm$site[i]
      tags$tr(tags$th(class="sb-site", scope="row",
        tags$a(href="#", class="sb-sitelink", `data-shiny-input`="goSite", `data-shiny-value`=s,
          `aria-label`=sprintf("Open site %s", s), s),
        tags$div(class="sb-biome", sm$biome_label[i])),
        lapply(judged_j, function(j) cell_for(s, j)),
        tags$td(class="sb-cell sb-count", sprintf("%d of %d", as.integer(sm$nenough[i]), nrow(pr))),
        if (show_ctx) lapply(context_j, function(j) cell_for(s, j)))
    }
    rows <- lapply(seq_len(nrow(sm)), rowfor)
    tagList(
      tags$table(class="sb-table",
        tags$caption(class="visually-hidden", "Direction found for each pairing at each NEON site"),
        tags$thead(tags$tr(tags$th(class="sb-site", scope="col", "Site"), hd_judged,
          tags$th(class="sb-col sb-col-count", scope="col", "Pairings with enough years"), hd_context)),
        tags$tbody(rows)),
      p(class="qc-cap-note sb-keyline", style="margin-top:10px",
        HTML("<span class='sb-key sb-consistent'>✓ fits</span> <span class='sb-key sb-apparent'>≈ fits, but the range includes zero</span> <span class='sb-key sb-counter'>✗ runs the other way</span> <span class='sb-key sb-exploratory'>· too few years</span> <span class='sb-key sb-insufficient'>blank: not testable</span>")),
      p(class="qc-cap-note", "Context columns are never counted."))
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
        tags$caption(class="visually-hidden", "NEON Cross-Product Response Atlas signal codebook"),
        tags$thead(tags$tr(tags$th(scope="col", "key"), tags$th(scope="col", "signal"),
          tags$th(scope="col", "Layer color"), tags$th(scope="col", "layer"),
          tags$th(scope="col", "unit"), tags$th(scope="col", "“more” ="))),
        tags$tbody(rows)),
      tags$ul(class="codebook-notes",
        tags$li(HTML("<b>precip</b> = annual total mm and <b>temp</b> = annual mean &deg;C; both require all <b>12 distinct months</b>. The export preserves <code>precip_n_months</code>/<code>temp_n_months</code>; a within-site MAD filter can additionally NA an implausible temperature year.")),
        tags$li(HTML("<b>precip_winter</b> = Oct&ndash;Mar sum keyed to the year it ENDS (6 of 6 months). <b>precip_monsoon</b> = Jul&ndash;Sep sum (3 of 3). <b>temp_spring</b> = Mar&ndash;May mean (3 of 3). Reconstructed from the monthly NEON-tower overlays.")),
        tags$li(HTML("<b>greenup_doy</b> is a legacy key for a full-precision, DOY-anchored composition-adjusted timing index, not a pooled observed date. Left-censored earliest records are excluded; retained species need &ge;3 bounded individual midpoint estimates in &ge;3 years. The connected, species-centered/equal-species annual index needs &ge;2 recurrent species and therefore at least 6 contributors. <b>greenup_doy_additive</b> fits an unweighted species+year model over the same eligible cells as an alternate method; it is a sensitivity field, not a second timeline signal. Both are retrospective full-panel standardizations: a refresh can revise historical values when the eligible species&times;year panel changes. Censoring, exclusions, contributor/species support, reference, interval-width diagnostics, and snapshot hashes are exported.")),
        tags$li(HTML("<b>mammal_cpue</b> = 100 &times; captures / deployed trap-nights (sprung/disturbed traps = &frac12; a trap-night, Nelson &amp; Clark 1973; captures counted by tagID): a within-site relative index, NOT cross-site standardized. <b>mammal_mnka</b> = distinct tagged individuals (minimum known alive, Krebs 1966).")),
        tags$li(HTML("<b>plant_richness</b> = observed species count: an effort-sensitive COMPOSITION signal, not productivity; <code>plant_n_plots</code>/<code>plant_n_sampling_units</code> expose effort and richness-based links are excluded from inferential tallies unless standardized. <b>plant_intro_pct</b> counts only canonical introduced (<code>I</code>) cover; ambiguous <code>NI</code> is unknown, not introduced. <b>fruiting_pct</b> is an opportunistic maximum across observed eligible months (&ge;5 individuals), not a fixed-season annual estimate. <code>fruiting_n_eligible_months</code> and <code>fruiting_peak_n_individuals</code> expose unequal observation opportunity; it remains context-only.")),
        tags$li(HTML("<b>bird_index</b> = detected cluster size per observed point-count visit after excluding flyovers; zero-detection visits may be absent. Mosquito activity has a complete effort calendar but is annual rather than season-window matched. Beetle effort includes catch-bearing events only, so its outcome-conditioned denominator is not a valid CPUE series; all three remain descriptive here.")),
        if (VEG_EVENT_SHAPED)
          tags$li(HTML("<b>Conditional woody structure</b> (per site, not annual) is the mean live basal area m&sup2;/ha over plots whose selected survey has a qualifying live stem. Each plot contributes its latest usable NEON survey, and its stems are divided by that survey's own sampled area. <code>veg_n_plots</code>, <code>veg_area_eligible_plots</code>, and <code>veg_record_plots</code> expose its denominator, and <code>veg_event_year_min</code> to <code>veg_event_year_max</code> give the survey years. The Atlas keeps the conditional estimand: plots whose selected survey has no qualifying live stem, including NEON-recorded absences, are left out rather than counted as zero; this is not a site-wide stock or productivity rate."))
        else
          tags$li(HTML("<b>Conditional woody structure</b> (per site, not annual) is the mean live basal area m&sup2;/ha among plots containing qualifying records. <code>veg_n_plots</code>, <code>veg_area_eligible_plots</code>, and <code>veg_record_plots</code> expose its denominator. Because the source cannot distinguish sampled-zero from unsampled plots, zero-stem and unobserved plots are not imputed; this is not a site-wide stock or productivity rate.")),
        tags$li(HTML("<b>n-gates:</b> &lt;3 yrs &rarr; no comparison; 3&ndash;5 &rarr; exploratory; &ge;6 &rarr; circular-shift p + circular block-bootstrap interval + a direction verdict. Only the two temperature–green-up rows are judged, at every supported site; context rows never pool. Raw-level exact-binomial p-values are shown with Holm adjustment plus detrended, consecutive-change, and outcome-estimator direction sensitivities.")),
        tags$li(HTML("<b>NA semantics:</b> a blank/NA cell is never a zero; it means the signal failed its documented coverage/composition gate that year (for example, an incomplete climate window, too few recurrent green-up species, or no trapping effort). The downloadable codebook CSV documents every rule."))),
      div(class="codebook-dl",
        downloadButton("dlAnnual", tagList(bs_icon("filetype-csv"), " This site's annual data"), icon = NULL, class="btn-outline-dark btn-sm"),
        downloadButton("dlLinks",  tagList(bs_icon("filetype-csv"), " This site's link scorecard"), icon = NULL, class="btn-outline-dark btn-sm"),
        downloadButton("dlCodebook", tagList(bs_icon("filetype-csv"), " Codebook (every signal, unit, NA-rule)"), icon = NULL, class="btn-outline-dark btn-sm"),
        tags$span(class="codebook-dl-note", "(the full cross-site CSV is on the All sites tab)")))
  })

  # A site link (the browse list, the All sites table) selects that site and opens This site.
  observeEvent(input$goSite, {
    req(input$goSite)
    updateSelectInput(session, "site", selected = input$goSite)
    updateTabsetPanel(session, "tabs", selected = "site")
    focus_after_update(tab = "site")
  })

  # ---- All sites: a table cell opens that pairing at that site on One pairing ----
  observeEvent(input$sbCell, {
    parts <- strsplit(input$sbCell %||% "", "|", fixed = TRUE)[[1]]
    if (length(parts) != 4) return()
    s <- parts[1]
    if (!s %in% neon_sites$site) return()
    updateSelectInput(session, "site", selected = s)
    updateTabsetPanel(session, "tabs", selected = "pairing")
    updateSelectInput(session, "pairing", selected = paste(parts[2], parts[3], parts[4], sep = "|"))
    focus_after_update(tab = "pairing")
  })
  observeEvent(input$help, showModal(modalDialog(easyClose = TRUE,
    title = tagList(bs_icon("question-circle"), " How to read this"),
    tags$ul(
      tags$li(tags$b("Pick a site."), " On This site, choose a NEON site from the list or browse them by name."),
      tags$li(tags$b("Read the timeline."), " Each strip is one kind of record, year by year; up means above that record's own average year."),
      tags$li(tags$b("Open one pairing."), " One pairing puts one weather record against one plant or animal record, one dot per year."),
      tags$li(tags$b("See all sites."), " All sites shows how the two temperature and green-up pairings came out at every site.")),
    footer = modalButton("Got it"))))
}
