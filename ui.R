# ===========================================================================
# NEON Cross-Product Response Atlas — ui.R
# ===========================================================================
ui <- bslib::page_fillable(
  theme = app_theme, title = "NEON Cross-Product Response Atlas", lang = "en",
  tags$head(

    tags$link(rel = "stylesheet", href = asset_url("styles.css")),
    tags$link(rel = "stylesheet", href = asset_url("cascade.css")),
    tags$script(src = asset_url("cascade.js"), defer = NA)
  ),
  useShinyjs(),
  tags$a(class = "skip-link", href = "#mainContent", "Skip to main content"),

  # ---- persistent top bar (v2 flow) --------------------------------------
  # The sidebar is gone: the site picker + response selector now live on a
  # select-panel at the top of the Overview (the landing). The three controls
  # that must stay reachable everywhere — How to read this, the per-site Report
  # export, and the theme toggle — sit in this slim top-right bar.
  tags$header(
    class = "top-bar",
    div(
      class = "top-bar-brand",
      tags$span(class = "tb-mark", `aria-hidden` = "true", "\U0001F517"),
      tags$h1(class = "tb-title", "Response Atlas"),
      tags$span(class = "tb-sub", "NEON · exploratory cross-product associations")
    ),
    div(
      class = "top-bar-actions",
      actionButton("help", tagList(bs_icon("question-circle"), tags$span(class = "tb-action-label", "How to read this")),
        `aria-label` = "How to read the NEON Response Atlas",
        class = "btn-outline-dark btn-sm tb-help"
      ),
      downloadButton("dlReport", tagList(bs_icon("file-earmark-arrow-down"), tags$span(class = "tb-action-label", "Site report (.csv)")),
        `aria-label` = "Download the selected site's report as CSV",
        class = "btn-outline-dark btn-sm tb-report"
      ),
      div(
        class = "tb-theme",
        tags$span(class = "tb-theme-lab", `aria-hidden` = "true", bs_icon("circle-half")),
        input_dark_mode(id = "colorMode", mode = "light")
      )
    )
  ),
  tags$main(
    class = "app-main", id = "mainContent", tabindex = "-1",
    uiOutput("heroStats"),
    div(class = "visually-hidden", role = "status", `aria-live` = "polite", `aria-atomic` = "true",
        textOutput("siteStatus", inline = TRUE)),
    div(
      class = "main-tabs-wrap",
      navset_card_tab(
      id = "tabs",
      nav_panel(
        title = tagList(bs_icon("compass"), " Overview"), value = "overview",
        # ---- relocated site/response controls (was the sidebar) ------------
        # Same input ids the server depends on (site, response). The site picker
        # is the primary control; the Browse-all list below it is the by-name
        # fallback. The hero "change site" link scrolls back up here.
        div(
          id = "sitePanel", class = "select-panel",
          tags$h2(class = "sp-head", bs_icon("sliders"), " Pick a site, and choose a response to explore"),
          div(
            class = "sp-row",
            div(
              class = "sp-field",
              selectInput("site",
                label = tagList(bs_icon("pin-map-fill"), " Site"),
                choices = cascade_site_choices(), selected = DEFAULT_SITE, width = "100%"
              )
            ),
            div(
              class = "sp-field",
              selectInput("response",
                label = tagList(bs_icon("bullseye"), " Driver Lab: explore…"),
                choices = local({
                  keys <- unique(as.character(PRIORS$to))
                  labels <- vapply(keys, sig_label, character(1))
                  context <- vapply(keys, function(key) {
                    rows <- PRIORS[PRIORS$to == key, , drop = FALSE]
                    nrow(rows) > 0 && all(rows$expected_class == "none")
                  }, logical(1))
                  stats::setNames(keys, paste0(labels, ifelse(context, " · context only", " · vote-eligible")))
                }),
                selected = "mammal_cpue", width = "100%"
              )
            )
          ),
          uiOutput("siteBio"),
          uiOutput("signalChips")
        ),
        card(
          card_head(
            "diagram-3-fill", "The idea: align weather and biological responses without pretending they form a tested chain",
            info_pop(
              "The response atlas",
              p("Seven NEON products, normally explored apart, share field sites. This app lines up annual weather, plant timing and composition, and animal detection and catch summaries so their coverage and pairwise associations can be inspected together."),
              p(tags$b("Important:"), " the current measurements do not supply a defensible annual production/seed-resource rung or a mediated-path test. The layered display is therefore a co-display of candidate bottom-up pathways, ", tags$b("not evidence that a trophic cascade occurred"), "."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Each site has only a handful of years. This tool shows the current literature-motivated settings and checks whether the data agree. The settings are locked in this build, but they evolved during inspection of these data, so the screen is exploratory—not preregistered.")
            )
          ),
          uiOutput("overviewInsight"),
          local({
            ord <- neon_sites[order(neon_sites$name), ]
            lay <- SITE_LAYERS[ord$site]
            lay[is.na(lay)] <- 0L
            tags$details(
              class = "picker-list",
              tags$summary(
                class = "picker-list-summary",
                tags$span(
                  class = "pls-label", bs_icon("list-ul"),
                  tagList(" Browse all ", nrow(ord), " sites")
                ),
                tags$span(class = "pls-chevron", bs_icon("chevron-down"))
              ),
              div(
                class = "picker-list-grid",
                lapply(seq_len(nrow(ord)), function(i) {
                  tags$a(
                    class = "picker-list-link", href = "#",
                    `data-cascade-action` = "select-site", `data-site` = ord$site[i],
                    tags$b(ord$site[i]), sprintf(" · %s ", ord$name[i]),
                    tags$span(class = "pll-meta", sprintf("%s · %d layer%s", ord$state[i], lay[i], if (lay[i] == 1) "" else "s"))
                  )
                })
              )
            )
          }),
          div(class = "cascade-strip", uiOutput("cascadeSchematic")),
          div(class = "standing-stock-status", role = "status",
              `aria-live` = "polite", `aria-atomic` = "true",
              uiOutput("standingStock"))
        ),
        card(
          card_head("list-check", "What's measured here", info_pop("Signals", p("The annual signals available at this site, organized by measurement layer."))),
          uiOutput("signalTable"),
          uiOutput("hillProfile")
        ),
        handoff("Compare the layered signals year by year", "ladder")
      ),
      nav_panel(
        title = tagList(bs_icon("bar-chart-steps"), " Layered Timeline"), value = "ladder",
        div(class = "tab-head", div(
          class = "tab-head-text",
          tags$h2(
            "Weather and response signals, year by year",
            info_pop(
              "Reading the timeline",
              p("Each strip is one measurement layer; each line is ", tags$b("standardised"), " (z-scored) within that signal so timing can share one visual scale. Shared x-axis = year; magnitudes are not comparable across products."),
              p("Use the strips to spot candidate timing patterns, then inspect the direct pairwise links and their support. Visual sequencing does not test mediation and must not be read as a climate→plant→animal chain."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Short series: read the shapes, not a single number. Verdicts are gated by how many years overlap.")
            )
          ),
          p("Standardised annual signals co-displayed by measurement layer; direct association cards keep the visual story tied to current build-locked pairs and their support.")
        )),
        uiOutput("pulseBanner"),
        uiOutput("traceYearControl"),
        layout_columns(
          col_widths = c(8, 4),
          card(
            full_screen = TRUE, card_head("bar-chart-steps", "Layered signal timeline"),
            div(
              class = "ladder-note", bs_icon("info-circle"),
              tags$span(HTML("Each line is <b>standardised</b>"), cpop("zscore"), HTML(": <b>0 = that signal's own average year</b>, up = above average, down = below. Compare the <b>timing</b> of the bumps across strips, not their heights, and each link carries a <b>lag</b>"), cpop("lag"), HTML(". Some clicked years won't trace because climate is missing or lagged downstream years are missing at this site; that's expected and is called out in the banner."))
            ),
            spin(plotlyOutput("ladderPlot", height = "560px"))
          ),
          card(
            card_head(
              "link-45deg", "Direct association screens",
              info_pop("Link cards", p("Each card is one literature-motivated driver–response pairing with a stated direction and lag. Colour summarizes that pair only; adjacent cards do not combine into a tested pathway."))
            ),
            uiOutput("linkChips")
          )
        ),
        card(
          card_head(
            "droplet-half", "Seasonal climate: why one annual number isn't enough",
            info_pop(
              "Seasonal split",
              p("At many dryland sites, winter (Oct–Mar) and monsoon (Jul–Sep) precipitation summarize distinct parts of the year that may relate differently to biological observations."),
              p("They can move differently, so one ", tags$b("annual"), " rainfall total can blur temporal contrasts. The panel tests aggregation sensitivity only; it does not establish the proposed ecological pathway or guarantee that the response was measured in the same window.")
            )
          ),
          uiOutput("seasonalPanel"),
          spin(plotlyOutput("seasonalPlot", height = "300px"))
        ),
        handoff("Inspect one response and its candidate drivers", "lab")
      ),
      nav_panel(
        title = tagList(bs_icon("bullseye"), " Driver Lab"), value = "lab",
        div(class = "tab-head", div(
          class = "tab-head-text",
          tags$h2(
            textOutput("labTitle", inline = TRUE),
            info_pop(
              "Driver Lab",
              p("For the response selected on Overview, every current build-locked driver pairing is shown with its literature-motivated ", tags$b("direction"), " and ", tags$b("lag"), ". Only rows explicitly marked vote-eligible enter a tally; the others remain inspectable context."),
              p("At ", tags$b("n < 6 years"), " no verdict is given. Current build-locked lag/direction settings are locked for this build, but the family evolved while these data were inspected; all results remain exploratory. At n≥6 a circular moving-block bootstrap interval sets a per-site direction verdict; the coarse circular-shift p is transparency only. Across-site p-values are shown raw and Holm-adjusted over the current poolable family. Never read these as confirmatory or causal.")
            )
          ),
          p("Which candidate drivers co-vary with this response here, measured against stated directions and lags—not whichever setting happens to look best.")
        )),
        uiOutput("signMatchBanner"),
        layout_columns(
          col_widths = c(7, 5),
          card(
            full_screen = TRUE, card_head("table", "Current build-locked driver pairings vs. the data"),
            uiOutput("driverTable")
          ),
          card(
            full_screen = TRUE, card_head(
              "graph-up", "Selected link: the aligned pairs",
              info_pop(
                "Scatter",
                p("The driver (x) against the response (y) at the current build-locked lag, one point per overlapping year. Few points = wide uncertainty; that's the honest picture."),
                p(class = "caveat", bs_icon("exclamation-triangle"), tags$b(" Permutation p"), " uses an autocorrelation-preserving circular-shift null (response years are rotated, not freely shuffled). Across NEON reports the raw and Holm-adjusted site-vote evidence."),
                p(class = "caveat", bs_icon("exclamation-triangle"), tags$b(" 95% CI"), " is a circular moving-block bootstrap interval (wide at this n; indicative, not a precision claim).")
              )
            ),
            uiOutput("linkScatterHeader"),
            spin(plotlyOutput("linkScatter", height = "330px")),
            uiOutput("linkScatterNote"),
            uiOutput("scatterYearPicker"),
            uiOutput("scatterDetail")
          )
        ),
        tags$details(
          class = "lab-exp",
          tags$summary(
            class = "lab-exp-summary",
            tags$span(
              class = "le-label", bs_icon("sliders"),
              " Lag & season explorer: inspect the current build-locked setting and the full scan"
            ),
            tags$span(class = "le-chevron", bs_icon("chevron-down"))
          ),
          div(
            class = "lab-exp-body",
            p(
              class = "le-intro", bs_icon("info-circle"),
              tags$span(HTML("Re-examine the <b>current build-locked setting</b> by sliding the lag and toggling annual vs seasonal climate. Watch how easily a better-looking r appears when you search, and why an unadjusted p no longer has its one-test interpretation. The gold diamond marks the setting locked for this build; some catalogued rows are context-only, and the family itself evolved alongside these data, so both it and off-setting scans are exploratory."))
            ),
            div(
              class = "le-controls",
              uiOutput("expLinkUI"),
              sliderInput("expLag", "Lag (years)", min = 0, max = 3, value = 0, step = 1, ticks = FALSE),
              uiOutput("expSeasonUI"),
              actionButton("expDesertDemo", tagList(bs_icon("brightness-high"), " Show the desert demo"), class = "btn-sm btn-outline-dark")
            ),
            spin(plotlyOutput("expCurve", height = "260px")),
            div(
              class = "le-explain",
              tags$span(class = "le-explain-lab", "What do these numbers mean?"),
              info_pop(
                "Reading the explorer",
                p(tags$b("r (correlation)"), " the linear co-movement, from -1 (perfect opposite linear movement) through 0 (no linear correlation) to +1 (perfect same-direction linear movement). Nonlinear ecological associations can still exist when r is near zero, and r never means one variable causes the other."),
                p(tags$b("n"), " how many years of overlap the number rests on. Fewer years means shakier, and under 6 we give no verdict at all."),
                p(tags$b("adjusted p"), " under the circular-shift null, the fraction of shifted series whose strongest scanned combination is at least this extreme. It accounts for every lag and season displayed; it is not the probability that the hypothesis is true."),
                p(tags$b("un-adjusted p"), " the same chance for one lag on its own. It looks more impressive than it should once you have scanned several, so we show it small."),
                p(tags$b("block-bootstrap 95% range"), " an instability range from resampling contiguous wrapped blocks on the full calendar grid, with missing years retained. A wide range, or one that crosses 0, means the direction is not clean."),
                p(tags$b("the bar"), " the Sidak per-look reference that would control a 0.05 familywise rate if looks were independent. The exact max-statistic adjusted p above is the preferred safeguard."),
                p(tags$b("current setting vs additional scan"), " the gold lag is the current value locked for this build, not a preregistered setting. Sliding adds another layer of exploration, so the one-setting p cannot describe the scan; the max-statistic adjusted p is the relevant safeguard. Context-only rows remain excluded from inference either way.")
              )
            ),
            spin(uiOutput("expReadout")),
            p(
              class = "le-persistent-caveat", bs_icon("exclamation-triangle"),
              tags$span(HTML("You just looked at up to K lag-by-season combinations. Under an independent-look reference, at least one unadjusted p below 0.05 becomes common as K grows. A value found by sliding does not retain a one-setting interpretation; use the exact max-statistic adjustment and compare the raw and Holm-adjusted site-vote screen on Across NEON. Those safeguards cover the displayed current family, but cannot make its historically data-informed evolution confirmatory."))
            )
          )
        ),
        handoff("Do individual associations recur across NEON?", "suite")
      ),
      nav_panel(
        title = tagList(bs_icon("grid-3x3-gap-fill"), " Across NEON"), value = "suite",
        div(class = "tab-head", div(
          class = "tab-head-text",
          tags$h2(
            "Do the individual association directions recur across NEON?",
            info_pop(
              "The scoreboard",
              p("One site's handful of years can't settle anything. Each vote-eligible temperature–green-up association is summarized over every site with enough support (one raw-level direction vote per site), under an explicit and imperfect site-independence assumption. A companion sensitivity collapses those same votes to one majority per NEON domain, with tied domains abstaining."),
              p("The grid also retains context-only plant and animal pairings, but they never enter a site tally or pooled p-value. ", tags$b("✓ aligned"), " marks a direction with an interval excluding zero; ", tags$b("· <6 years"), " marks insufficient support. Raw and Holm-adjusted values remain exploratory because the family evolved alongside these data.")
            )
          ),
          p("Per-site series are short; the cross-site grid is an exploratory direction summary for separate pairwise associations. It is not a test of a mediated chain. Each cell is one link at one site; activate any site name to open it.")
        )),
        card(
          card_head("clipboard-data", "Multiplicity-adjusted direction summary across the current family",
            downloadButton("dlPooled", tagList(bs_icon("filetype-csv"), " Pooled CSV"),
              class = "btn-outline-dark btn-sm ms-auto")),
          uiOutput("pooledHeadline")
        ),
        card(
          full_screen = TRUE, card_head(
            "grid-3x3-gap", "Site × link sign-match grid",
            info_pop("Reading the grid", p("Rows are sites, visually ordered by a descriptive bio-keyword group; columns are literature-motivated direct pairings. Each cell carries a verdict glyph plus r. Hatched, dashed context-only columns are excluded from all tallies and pooled p-values at every site.")),
            downloadButton("dlSuite", tagList(bs_icon("filetype-csv"), " CSV"), class = "btn-outline-dark btn-sm ms-auto")
          ),
          div(
            class = "sb-sortbar",
            tags$label(class = "sb-sort-lab", `for` = "sbSort", bs_icon("sort-down"), " Sort sites by"),
            selectInput("sbSort", NULL, width = "210px", selectize = FALSE,
              choices = c(
                "Heuristic group + agreement (default)" = "default",
                "Site name (A-Z)"             = "abc",
                "Most links agreeing"         = "agree",
                "Most testable links"         = "coverage",
                "Conditional woody structure" = "ba"
              ), selected = "default")
          ),
          div(class = "sb-scroll", role = "region", tabindex = "0",
              `aria-label` = "Scrollable site by current-pairing scoreboard", uiOutput("scoreboard"))
        )
      ),
      nav_panel(
        title = tagList(bs_icon("search"), " Search"), value = "search",
        div(class = "tab-head", div(
          class = "tab-head-text",
          tags$h2(
            "Search the association atlas",
            info_pop(
              "Searching the atlas",
              p("Two ways to query all ", nrow(SRCH_STR), " sites at once, off the bundled index (instant, no download):"),
              p(tags$b("Find a link"), ": pick one current build-locked driver→response pairing and see every site with data for it, sorted by direction and support."),
              p(tags$b("Direction agreement"), ": rank sites descriptively by how many vote-eligible links point in the literature-motivated direction."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Per-site screens rest on a handful of years and are ", tags$b("underpowered"), ". A site missing from a result usually means too few years, not a real absence. The exploratory cross-site direction summary is reported on ", tags$b("Across NEON"), ".")
            )
          ),
          p("Query every NEON site at once. Pick a link to inspect its direction and coverage, or rank sites by a descriptive count of vote-eligible associations pointing the stated way.")
        )),
        div(
          class = "search-modeswitch",
          radioButtons("searchMode",
            label = tags$span(class = "visually-hidden", "Search mode"), inline = TRUE,
            choices = c("Find a link" = "link", "Direction agreement" = "strength"),
            selected = "link"
          )
        ),

        # (a) FIND A LINK ----------------------------------------------------
        conditionalPanel(
          condition = "input.searchMode == 'link'",
          card(
            card_head("link-45deg", "Find a driver→response pairing across the atlas"),
            div(
              class = "search-controls",
              selectizeInput("searchLink",
                label = tagList(bs_icon("diagram-2"), " Pick a literature-motivated pairing"),
                choices = search_link_choices(),
                selected = if (length(search_link_choices())) "temp|greenup_doy|0" else NULL,
                width = "100%",
                options = list(placeholder = "Type a driver or response (e.g. green-up, monsoon)…")
              ),
              checkboxInput("searchAlignedOnly", "Only vote-eligible rows with a clean aligned direction (n≥6; block-bootstrap interval excludes zero)", value = FALSE)
            ),
            uiOutput("searchLinkSummary"),
            div(class = "table-region", role = "region", tabindex = "0",
                `aria-label` = "Search results for the selected current build-locked pairing",
                DT::DTOutput("searchLinkTable")),
            p(
              class = "qc-cap-note", bs_icon("info-circle"),
              HTML(" Each row is this pairing screened at one site: <b>r</b> is within-site, <b>n</b> is overlapping years, and <b>circular p</b> is a coarse diagnostic that cannot establish per-site significance. Temperature–green-up rows are vote-eligible at every site with enough support; all plant/animal pairings are context-only by measurement/construct contract and never pooled.")
            )
          )
        ),

        # (b) DIRECTION AGREEMENT -------------------------------------------
        conditionalPanel(
          condition = "input.searchMode == 'strength'",
          card(
            card_head("bar-chart-line-fill", "Rank sites by descriptive direction agreement"),
            div(
              class = "search-controls",
              sliderInput("searchMinResolved", tagList(bs_icon("funnel"), " Show sites with at least this many eligible links agreeing"),
                min = 0, max = if (nrow(SRCH_STR)) max(SRCH_STR$expected_testable, na.rm = TRUE) else 6,
                value = 2, step = 1, ticks = FALSE, width = "100%"
              )
            ),
            uiOutput("searchStrengthSummary"),
            div(class = "table-region", role = "region", tabindex = "0",
              `aria-label` = "Sites ranked by descriptive direction agreement",
                DT::DTOutput("searchStrengthTable")),
            p(
              class = "qc-cap-note", bs_icon("info-circle"),
              HTML(" “Agree” = a vote-eligible direct association points in its literature-motivated direction with at least 6 overlapping years. The two eligible temperature–green-up rows apply at every site; context-only rows never count. Agreement does <b>not</b> mean statistically significant. Read this as a descriptive direction tally—not an ecosystem ranking.")
            )
          )
        ),
        p(
          class = "search-foot-caveat", bs_icon("exclamation-triangle"),
          HTML("Every number here is a <b>within-site</b>, short-series screen. It points you to sites worth opening, not settled results. <b>Across NEON</b> shows the one-vote-per-site exact-binomial results with familywise adjustment.")
        ),
        handoff("See the pooled cross-site sensitivity summary", "suite")
      ),
      nav_panel(
        title = tagList(bs_icon("clipboard-check"), " QC"), value = "qc",
        div(class = "tab-head", div(
          class = "tab-head-text",
          tags$h2(
            "Data-quality review for this site",
            info_pop(
              "Verify, not wrong",
              p("The suite data-quality panel: ranked ", tags$b("“verify, not wrong”"), " flags for the selected site, worst-first."),
              p("Every flag is a value to ", tags$b("review"), " before over-reading it, not automatically a bug. The panel shows where the documented coverage, outlier, and interval rules changed what could be analyzed. Activate a flag for the exact rows; export the review as CSV.")
            )
          ),
          p("A site with no flagged rows shows one explicit all-clear message. Pick another site on the Overview to review it.")
        )),
        card(
          card_head("clipboard-check", "Flags worth a second look"),
          uiOutput("qcFlags")
        )
      ),
      nav_panel(
        title = tagList(bs_icon("info-circle"), " About"), value = "about",
        tags$h2(class = "visually-hidden", "About the NEON Response Atlas"),
        uiOutput("aboutPanel")
      )
      )
    )
  ),
  tags$footer(
    class = "ddl-footer",
    div(tags$a(
      class = "custom-cta", href = "mailto:desertdatalabs@gmail.com?subject=NEON%20Response%20Atlas",
      span(class = "hand", "\U0001F44B"), "Questions or feedback? Get in touch with Desert Data Labs."
    )),
    p(
      style = "margin-top:12px", HTML("Built by <strong>Desert Data Labs</strong> · Tucson, AZ · get in touch → "),
      tags$a(href = "mailto:desertdatalabs@gmail.com?subject=NEON%20Response%20Atlas", "desertdatalabs@gmail.com")
    ),
    p(style = "font-size:12px;opacity:.85", "Synthesis of NEON DP1.10072.001 (small mammals), DP1.10003.001 (birds), DP1.10058.001 (plants), DP1.10098.001 (veg structure), DP1.10055.001 (phenology), DP1.10043.001 (mosquitoes), DP1.10022.001 (ground beetles), and NEON/Daymet climate. Not affiliated with NEON, Battelle, or the NSF. An educational data-exploration tool.")
  ),
  div(
    class = "cascade-guide", id = "cascadeGuide", role = "note",
    hidden = NA, inert = NA, `aria-hidden` = "true", `aria-live` = "polite", `aria-atomic` = "true",
    tags$button(class = "cg-close", type = "button", `aria-label` = "Dismiss tip", HTML("&times;")),
    MASCOT_HUDDLE,
    div(
      class = "cg-bubble", tags$b("New here?"),
      HTML(" Start on <b>Overview</b> for the construct warning, then open <b>Driver Lab</b> to inspect a direct association and whether it is vote-eligible or context-only.")
    )
  )
)
