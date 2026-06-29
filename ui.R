# ===========================================================================
# NEON Driver Cascade — ui.R
# ===========================================================================
ui <- bslib::page_fillable(
  theme = app_theme, title = NULL,
  window_title = "NEON Driver Cascade", fillable = FALSE,
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = NA),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Rubik:wght@400;500;600;700;800&display=swap"),
    tags$link(rel = "stylesheet", href = asset_url("styles.css")),
    tags$link(rel = "stylesheet", href = asset_url("cascade.css")),
    tags$script(src = asset_url("cascade.js"))
  ),
  useShinyjs(),

  # ---- persistent top bar (v2 flow) --------------------------------------
  # The sidebar is gone: the site picker + response selector now live on a
  # select-panel at the top of the Overview (the landing). The three controls
  # that must stay reachable everywhere — How to read this, the per-site Report
  # export, and the theme toggle — sit in this slim top-right bar.
  div(
    class = "top-bar",
    div(
      class = "top-bar-brand",
      tags$span(class = "tb-mark", "\U0001F517"),
      tags$span(class = "tb-title", "Driver Cascade"),
      tags$span(class = "tb-sub", "NEON · cross-product synthesis")
    ),
    div(
      class = "top-bar-actions",
      actionButton("help", tagList(bs_icon("question-circle"), " How to read this"),
        class = "btn-outline-dark btn-sm tb-help"
      ),
      downloadButton("dlReport", tagList(bs_icon("file-earmark-arrow-down"), " Report"),
        class = "btn-outline-dark btn-sm tb-report"
      ),
      div(
        class = "tb-theme",
        tags$span(class = "tb-theme-lab", bs_icon("circle-half")),
        input_dark_mode(id = "colorMode", mode = "light")
      )
    )
  ),
  uiOutput("heroStats"),
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
          div(class = "sp-head", bs_icon("sliders"), " Pick a site, and choose what to explain"),
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
                label = tagList(bs_icon("bullseye"), " Driver Lab: explain…"),
                choices = c(
                  "Small-mammal catch rate" = "mammal_cpue",
                  "Plant richness" = "plant_richness", "Green-up onset" = "greenup_doy"
                ),
                selected = "mammal_cpue", width = "100%"
              )
            )
          ),
          uiOutput("siteBio"),
          uiOutput("signalChips")
        ),
        card(
          card_head(
            "diagram-3-fill", "The idea: populations are driven from the bottom up",
            info_pop(
              "The cascade",
              p("Five NEON products, normally explored apart, share field sites. This app lines them up by year into one ", tags$b("bottom-up cascade"), ":"),
              p(tags$b("climate"), " sets the water and warmth → ", tags$b("green-up timing"), " (the hinge) → ", tags$b("producers"), " (plants) → ", tags$b("consumers"), " (small mammals, birds)."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Each site has only a handful of years. This tool ", tags$b("states what the literature predicts"), " and checks whether the data agrees. It does ", tags$b("not"), " hunt for whichever correlation looks biggest.")
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
                    onclick = sprintf("Shiny.setInputValue('goSite','%s',{priority:'event'});return false;", ord$site[i]),
                    tags$b(ord$site[i]), sprintf(" · %s ", ord$name[i]),
                    tags$span(class = "pll-meta", sprintf("%s · %d layer%s", ord$state[i], lay[i], if (lay[i] == 1) "" else "s"))
                  )
                })
              )
            )
          }),
          div(class = "cascade-strip", uiOutput("cascadeSchematic")),
          uiOutput("standingStock")
        ),
        card(
          card_head("list-check", "What's measured here", info_pop("Signals", p("The annual signals available at this site, by trophic layer."))),
          uiOutput("signalTable"),
          uiOutput("hillProfile")
        ),
        handoff("See the cascade year by year", "ladder")
      ),
      nav_panel(
        title = tagList(bs_icon("bar-chart-steps"), " Cascade Ladder"), value = "ladder",
        div(class = "tab-head", div(
          class = "tab-head-text",
          h4(
            "The cascade, year by year",
            info_pop(
              "Reading the ladder",
              p("Each strip is one trophic layer; each line a signal, ", tags$b("standardised"), " (z-scored) so layers are comparable on one scale. Shared x-axis = year."),
              p("Watch whether pulses ", tags$b("march down the ladder"), ": a wet year, then a green flush, then more plants, then more rodents. The chips on the right show whether each link matches its ", tags$b("literature-predicted direction"), "."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Short series: read the shapes, not a single number. Verdicts are gated by how many years overlap.")
            )
          ),
          p("Standardised annual signals, stacked by trophic layer. The eye does the judging; the chips keep it honest.")
        )),
        uiOutput("pulseBanner"),
        layout_columns(
          col_widths = c(8, 4),
          card(
            full_screen = TRUE, card_head("bar-chart-steps", "Alignment ladder"),
            div(
              class = "ladder-note", bs_icon("info-circle"),
              tags$span(HTML("Each line is <b>standardised</b>"), cpop("zscore"), HTML(": <b>0 = that signal's own average year</b>, up = above average, down = below. Compare the <b>timing</b> of the bumps across strips, not their heights, and each link carries a <b>lag</b>"), cpop("lag"), HTML(". Some clicked years won't trace because climate is missing or lagged downstream years are missing at this site; that's expected and is called out in the banner."))
            ),
            spin(plotlyOutput("ladderPlot", height = "560px"))
          ),
          card(
            card_head(
              "link-45deg", "Do the links match the prior?",
              info_pop("Link chips", p("Each arrow is a predicted driver→response link with its expected sign and lag. The colour says whether the data agrees, and is honest about how few years stand behind it."))
            ),
            uiOutput("linkChips")
          )
        ),
        card(
          card_head(
            "droplet-half", "Seasonal climate: why one annual number isn't enough",
            info_pop(
              "Seasonal split",
              p("In bimodal deserts, rain comes in two ecologically independent seasons: ", tags$b("winter"), " (Oct–Mar, which grows the spring forbs) and the ", tags$b("summer monsoon"), " (Jul–Sep, which grows the grass seeds desert rodents eat)."),
              p("They can even move in opposite directions from year to year, so a single ", tags$b("annual"), " rainfall total blends them into noise. Splitting them back out is what recovers the desert cascade.")
            )
          ),
          uiOutput("seasonalPanel"),
          spin(plotlyOutput("seasonalPlot", height = "300px"))
        ),
        handoff("Why does a rung miss here? Open the Driver Lab", "lab")
      ),
      nav_panel(
        title = tagList(bs_icon("bullseye"), " Driver Lab"), value = "lab",
        div(class = "tab-head", div(
          class = "tab-head-text",
          h4(
            textOutput("labTitle", inline = TRUE),
            info_pop(
              "Driver Lab",
              p("For the response you pick (left), every candidate driver the literature proposes, with its expected ", tags$b("sign"), " and ", tags$b("lag"), ", checked against this site's data."),
              p("At ", tags$b("n < 6 years"), " no verdict is given (the series is too short); links are shown as ", tags$b("exploratory"), ". Expected lag/sign are literature priors on annual site-year summaries (not selected by monthly correlation in this table). At n≥6 the bootstrap interval sets the per-site direction verdict; the permutation p is reported but cannot reach significance at this n (that is the cross-site pooled test's job). Never read these as causation.")
            )
          ),
          p("Which drivers explain this response here, measured against what ecology predicts, not against whichever lag looks best.")
        )),
        uiOutput("signMatchBanner"),
        layout_columns(
          col_widths = c(7, 5),
          card(
            full_screen = TRUE, card_head("table", "Predicted drivers vs. the data"),
            uiOutput("driverTable")
          ),
          card(
            full_screen = TRUE, card_head(
              "graph-up", "Selected link: the aligned pairs",
              info_pop(
                "Scatter",
                p("The driver (x) against the response (y) at the predicted lag, one point per overlapping year. Few points = wide uncertainty; that's the honest picture."),
                p(class = "caveat", bs_icon("exclamation-triangle"), tags$b(" Permutation p"), " uses an autocorrelation-preserving circular-shift null (response years are rotated, not freely shuffled). The honest test is the cross-site pooling on Across NEON."),
                p(class = "caveat", bs_icon("exclamation-triangle"), tags$b(" 95% CI"), " is a bootstrap interval (wide at this n; indicative, not a precision claim).")
              )
            ),
            uiOutput("linkScatterHeader"),
            spin(plotlyOutput("linkScatter", height = "330px")),
            uiOutput("linkScatterNote"),
            uiOutput("scatterDetail")
          )
        ),
        tags$details(
          class = "lab-exp",
          tags$summary(
            class = "lab-exp-summary",
            tags$span(
              class = "le-label", bs_icon("sliders"),
              " Lag & season explorer: see why we lock the prior, not chase the best fit"
            ),
            tags$span(class = "le-chevron", bs_icon("chevron-down"))
          ),
          div(
            class = "lab-exp-body",
            p(
              class = "le-intro", bs_icon("info-circle"),
              tags$span(HTML("Re-examine a <b>stated prior</b> by sliding the lag and toggling annual vs seasonal climate. Watch how easily a better-looking r appears when you search, and why that p is not a real one. The gold diamond is the prior lag, fixed before looking; it is the only honest reading here."))
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
                p(tags$b("r (correlation)"), " how tightly the two move together, from -1 (they move opposite) through 0 (no link) to +1 (in lockstep). It never means one causes the other."),
                p(tags$b("n"), " how many years of overlap the number rests on. Fewer years means shakier, and under 6 we give no verdict at all."),
                p(tags$b("adjusted p"), " the chance a correlation this strong could turn up by luck, after counting every lag and season you tried. Near 1 means easily luck; near 0 means hard to explain by chance. We adjust for the search because trying many combinations finds a winner even in pure noise."),
                p(tags$b("un-adjusted p"), " the same chance for one lag on its own. It looks more impressive than it should once you have scanned several, so we show it small."),
                p(tags$b("bootstrap 95% range"), " the span the true correlation could plausibly sit in, given so few years. A wide range, or one that crosses 0, means we cannot pin it down."),
                p(tags$b("the bar"), " how small the p would have to be to count as real after that many tries. Sliding rarely beats it."),
                p(tags$b("on the prior vs EXPLORED"), " the gold lag is the literature value, fixed before looking, and the one honest reading. Slide off it and you are exploring, not testing, so that p shows struck through.")
              )
            ),
            spin(uiOutput("expReadout")),
            p(
              class = "le-persistent-caveat", bs_icon("exclamation-triangle"),
              tags$span(HTML("You just looked at up to K lag-by-season combinations. With about 6 years, the best-looking one reaches p around 0.05 roughly 1 in 3 by chance. A p you found by sliding is not a p=.03 result. The honest tests are the prior lag (gold) and the cross-site pooling on Across NEON."))
            )
          )
        ),
        handoff("Does this hold across all of NEON?", "suite")
      ),
      nav_panel(
        title = tagList(bs_icon("grid-3x3-gap-fill"), " Across NEON"), value = "suite",
        div(class = "tab-head", div(
          class = "tab-head-text",
          h4(
            "Does the cascade hold across NEON?",
            info_pop(
              "The scoreboard",
              p("One site's handful of years can't settle anything. But each predicted link can be ", tags$b("pooled across the sites where it's expected"), " (one vote per site), which is the statistically honest way past the short-series problem."),
              p("The grid shows every link's verdict at every site. ", tags$b("Green"), " columns marching down a biome block mean the predicted direction holds cleanly at those sites (the per-site verdict is direction, not significance, a short series can't be significant on its own); the ", tags$b("pooled"), " test above the grid is where significance lives. ", tags$b("Grey"), " means too few years to tell, and we show that, rather than hide it.")
            )
          ),
          p("Per-site series are short; pooling across sites gives a stronger test of direction. Each cell is one link's verdict at one site. Click any site to open it.")
        )),
        card(card_head("trophy", "The pooled result: the strongest supported rung"), uiOutput("pooledHeadline")),
        card(
          full_screen = TRUE, card_head(
            "grid-3x3-gap", "Site × link sign-match grid",
            info_pop("Reading the grid", p("Rows are sites grouped by biome; columns are the predicted links. Cell colour = the verdict; faded cells aren't the mechanism expected for that biome.")),
            downloadButton("dlSuite", tagList(bs_icon("filetype-csv"), " CSV"), class = "btn-outline-dark btn-sm ms-auto")
          ),
          div(class = "sb-scroll", uiOutput("scoreboard"))
        )
      ),
      nav_panel(
        title = tagList(bs_icon("search"), " Search"), value = "search",
        div(class = "tab-head", div(
          class = "tab-head-text",
          h4(
            "Search the network",
            info_pop(
              "Searching the cascade",
              p("Two ways to query all ", nrow(SRCH_STR), " sites at once, off the bundled index (instant, no download):"),
              p(tags$b("Find a link"), ": pick one driver→response prior and see every site where it was tested, sorted by how well the data agrees."),
              p(tags$b("Cascade strength"), ": rank sites by how many of their biome-expected links the data agrees with."),
              p(class = "caveat", bs_icon("exclamation-triangle"), " Per-site tests rest on a handful of years and are ", tags$b("underpowered"), ". A site missing from a result usually means too few years, not a real absence. The honest cross-site test is the pooled result on ", tags$b("Across NEON"), ".")
            )
          ),
          p("Query every NEON site in the cascade at once. Pick a single link to see where it holds, or rank sites by how much of their expected cascade the data agrees with.")
        )),
        div(
          class = "search-modeswitch",
          radioButtons("searchMode",
            label = NULL, inline = TRUE,
            choices = c("Find a link" = "link", "Cascade strength" = "strength"),
            selected = "link"
          )
        ),

        # (a) FIND A LINK ----------------------------------------------------
        conditionalPanel(
          condition = "input.searchMode == 'link'",
          card(
            card_head("link-45deg", "Find a driver→response link across the network"),
            div(
              class = "search-controls",
              selectizeInput("searchLink",
                label = tagList(bs_icon("diagram-2"), " Pick a predicted link"),
                choices = search_link_choices(),
                selected = if (length(search_link_choices())) "temp|greenup_doy|0" else NULL,
                width = "100%",
                options = list(placeholder = "Type a driver or response (e.g. green-up, monsoon)…")
              ),
              checkboxInput("searchSignifOnly", "Only sites that clear the expected-link permutation gate (n≥6, p<0.05)", value = FALSE)
            ),
            uiOutput("searchLinkSummary"),
            div(style = "width:100%", DT::DTOutput("searchLinkTable")),
            p(
              class = "qc-cap-note", bs_icon("info-circle"),
              HTML(" Each row is this link tested at one site: <b>r</b> is within-site, <b>n</b> is overlapping years, <b>p</b> is an autocorrelation-preserving circular-shift permutation p. “Expected” marks the biome where the mechanism is predicted; faded sites still ran it as out-of-biome corroboration. A single site's short series can't settle the link; the pooled test on Across NEON can.")
            )
          )
        ),

        # (b) CASCADE STRENGTH ----------------------------------------------
        conditionalPanel(
          condition = "input.searchMode == 'strength'",
          card(
            card_head("bar-chart-line-fill", "Rank sites by cascade strength"),
            div(
              class = "search-controls",
              sliderInput("searchMinResolved", tagList(bs_icon("funnel"), " Show sites with at least this many expected links agreeing"),
                min = 0, max = if (nrow(SRCH_STR)) max(SRCH_STR$expected_testable, na.rm = TRUE) else 6,
                value = 2, step = 1, ticks = FALSE, width = "100%"
              )
            ),
            uiOutput("searchStrengthSummary"),
            div(style = "width:100%", DT::DTOutput("searchStrengthTable")),
            p(
              class = "qc-cap-note", bs_icon("info-circle"),
              HTML(" “Agree” = the data points the literature-predicted direction on a biome-<b>expected</b> link with at least 6 overlapping years. It does NOT require statistical significance, since at this n almost nothing reaches it. Read this as <b>k of K expected links agree</b>, a direction tally, not an absolute ranking of ecosystems. Magnitudes (the within-site indices) are not comparable across sites.")
            )
          )
        ),
        p(
          class = "search-foot-caveat", bs_icon("exclamation-triangle"),
          HTML("Every number here is a <b>within-site</b>, short-series screen. It points you to sites worth opening, not to settled results. The statistically honest, cross-site answer is the pooled binomial on <b>Across NEON</b>.")
        ),
        handoff("See the pooled, cross-site answer", "suite")
      ),
      nav_panel(
        title = tagList(bs_icon("clipboard-check"), " QC"), value = "qc",
        div(class = "tab-head", div(
          class = "tab-head-text",
          h4(
            "Data-quality review for this site",
            info_pop(
              "Verify, not wrong",
              p("The suite gold-standard QC panel: ranked ", tags$b("“verify, not wrong”"), " flags for the selected site, worst-first."),
              p("Every flag is a value to ", tags$b("look at"), " before over-reading it, never a bug. The cascade's QC rules (the ≥5-individual green-up gate, the within-site temperature outlier filter, the CI-spans-zero guard) are correct; this just shows where they bit. Tap a flag for the exact rows; export the whole review as CSV.")
            )
          ),
          p("A clean site shows a single green all-clear. Pick another site on the Overview to review it.")
        )),
        card(
          card_head("clipboard-check", "Flags worth a second look"),
          uiOutput("qcFlags")
        )
      ),
      nav_panel(title = tagList(bs_icon("info-circle"), " About"), value = "about", uiOutput("aboutPanel"))
    )
  ),
  div(
    class = "ddl-footer",
    div(tags$a(
      class = "custom-cta", href = "mailto:desertdatalabs@gmail.com?subject=NEON%20Driver%20Cascade",
      span(class = "hand", "\U0001F44B"), "Questions or feedback? Get in touch with Desert Data Labs."
    )),
    p(
      style = "margin-top:12px", HTML("Built by <strong>Desert Data Labs</strong> · Tucson, AZ · get in touch → "),
      tags$a(href = "mailto:desertdatalabs@gmail.com?subject=NEON%20Driver%20Cascade", "desertdatalabs@gmail.com")
    ),
    p(style = "font-size:12px;opacity:.85", "Synthesis of NEON DP1.10072.001 (small mammals), DP1.10003.001 (birds), DP1.10058.001 (plants), DP1.10098.001 (veg structure), DP1.10055.001 (phenology), DP1.10043.001 (mosquitoes), DP1.10022.001 (ground beetles), and NEON/Daymet climate. Not affiliated with NEON, Battelle, or the NSF. An educational data-exploration tool.")
  ),
  div(
    class = "cascade-guide", id = "cascadeGuide", role = "note",
    tags$button(class = "cg-close", type = "button", `aria-label` = "Dismiss tip", HTML("&times;")),
    MASCOT_HUDDLE,
    div(
      class = "cg-bubble", tags$b("New here?"),
      HTML(" Start on <b>Overview</b> for the verdict, then open the <b>Driver Lab</b> to see what explains it.")
    )
  )
)
