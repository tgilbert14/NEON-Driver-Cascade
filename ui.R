# ===========================================================================
# NEON Response Atlas, ui.R
# Four tabs: This site, One pairing, All sites, About. The output and input
# ids below are the contract the server builds to (docs/SIMPLIFY-PLAN-2026-10-20.md).
# ===========================================================================
ui <- bslib::page_fillable(
  theme = app_theme, title = "NEON Response Atlas", lang = "en",
  tags$head(
    tags$link(rel = "icon", href = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Crect width='16' height='16' rx='3' fill='%230f6a5b'/%3E%3Cpath d='M3 11 6.5 6.5 9 9l4-5' fill='none' stroke='%23fff' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E"),
    tags$link(rel = "stylesheet", href = asset_url("styles.css")),
    tags$link(rel = "stylesheet", href = asset_url("cascade.css")),
    tags$script(src = asset_url("cascade.js"), defer = NA)
  ),
  useShinyjs(),
  tags$a(class = "skip-link", href = "#mainContent", "Skip to main content"),

  # ---- persistent top bar ---------------------------------------------------
  tags$header(
    class = "top-bar",
    div(
      class = "top-bar-brand",
      tags$span(class = "tb-mark", `aria-hidden` = "true", "\U0001F517"),
      tags$h1(class = "tb-title", "NEON Response Atlas")
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
    # The hero: site name, its years, one counts-first line, three tiles.
    uiOutput("heroStats"),
    div(class = "visually-hidden", role = "status", `aria-live` = "polite", `aria-atomic` = "true",
        textOutput("siteStatus", inline = TRUE)),
    div(
      class = "main-tabs-wrap",
      navset_card_tab(
        id = "tabs",

        # ================================================================
        # Tab 1: This site
        # ================================================================
        nav_panel(
          title = tagList(bs_icon("pin-map-fill"), " This site"), value = "site",
          div(
            id = "sitePanel", class = "select-panel",
            div(
              class = "sp-row",
              div(
                class = "sp-field",
                selectInput("site",
                  label = tagList(bs_icon("pin-map-fill"), " Site"),
                  choices = cascade_site_choices(), selected = DEFAULT_SITE, width = "100%"
                )
              )
            ),
            uiOutput("siteBio"),
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
                    tagList(" Browse all ", nrow(ord), " sites by name")
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
            })
          ),
          # The one picture of this tab: the layered timeline.
          card(
            full_screen = TRUE,
            card_head("bar-chart-steps", "Weather and living records, year by year"),
            spin(plotlyOutput("ladderPlot", height = "560px")),
            uiOutput("ladderLines")
          ),
          # The twelve pairings at this site, as one plain table.
          card(
            card_head("link-45deg", "Pairings at this site"),
            uiOutput("pairingsTable")
          ),
          # Winter rain versus monsoon rain. Rendered only at dryland sites.
          uiOutput("seasonalCard"),
          # What is measured here: the signal table and the woody-structure line.
          tags$details(
            class = "picker-list measured-fold",
            tags$summary(
              class = "picker-list-summary",
              tags$span(class = "pls-label", bs_icon("list-check"), " What is measured here"),
              tags$span(class = "pls-chevron", bs_icon("chevron-down"))
            ),
            div(
              class = "measured-body",
              uiOutput("signalTable"),
              div(class = "standing-stock-status", role = "status",
                  `aria-live` = "polite", `aria-atomic` = "true",
                  uiOutput("standingStock"))
            )
          )
        ),

        # ================================================================
        # Tab 2: One pairing
        # ================================================================
        nav_panel(
          title = tagList(bs_icon("bullseye"), " One pairing"), value = "pairing",
          div(class = "select-panel", uiOutput("pairingPicker")),
          card(
            full_screen = TRUE,
            card_head("graph-up", "Driver → response, one dot per year"),
            uiOutput("linkScatterHeader"),
            spin(plotlyOutput("linkScatter", height = "360px")),
            uiOutput("scatterLines"),
            uiOutput("scatterYearPicker"),
            uiOutput("scatterDetail"),
            tags$details(
              class = "picker-list more-numbers",
              tags$summary(
                class = "picker-list-summary",
                tags$span(class = "pls-label", bs_icon("calculator"), " More numbers"),
                tags$span(class = "pls-chevron", bs_icon("chevron-down"))
              ),
              div(class = "measured-body", uiOutput("scatterMore"))
            )
          )
        ),

        # ================================================================
        # Tab 3: All sites
        # ================================================================
        nav_panel(
          title = tagList(bs_icon("grid-3x3-gap-fill"), " All sites"), value = "sites",
          card(
            card_head("clipboard-data", "The judged pairings across NEON",
              downloadButton("dlPooled", tagList(bs_icon("filetype-csv"), " Pooled CSV"),
                class = "btn-outline-dark btn-sm ms-auto")),
            uiOutput("pooledHeadline")
          ),
          card(
            full_screen = TRUE,
            card_head("grid-3x3-gap", "Every site, every pairing",
              downloadButton("dlSuite", tagList(bs_icon("filetype-csv"), " CSV"), class = "btn-outline-dark btn-sm ms-auto")),
            div(
              class = "sb-sortbar",
              tags$label(class = "sb-sort-lab", `for` = "sbSort", bs_icon("sort-down"), " Sort sites by"),
              selectInput("sbSort", NULL, width = "210px", selectize = FALSE,
                choices = c(
                  "Site group, then most fits" = "default",
                  "Site name (A to Z)"         = "abc",
                  "Most fits"                  = "agree"
                ), selected = "default"),
              checkboxInput("showContext", "Show the ten context pairings", value = FALSE)
            ),
            div(class = "sb-scroll", role = "region", tabindex = "0",
                `aria-label` = "Site by pairing table", uiOutput("scoreboard"))
          )
        ),

        # ================================================================
        # Tab 4: About
        # ================================================================
        nav_panel(
          title = tagList(bs_icon("info-circle"), " About"), value = "about",
          tags$h2(class = "visually-hidden", "About the NEON Response Atlas"),
          card(
            card_head("clipboard-check", "Data checks for this site"),
            uiOutput("qcFlags")
          ),
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
      style = "margin-top:12px", HTML("Built by <strong>Desert Data Labs</strong> · Tucson, AZ · "),
      tags$a(href = "mailto:desertdatalabs@gmail.com?subject=NEON%20Response%20Atlas", "desertdatalabs@gmail.com")
    ),
    p(style = "font-size:12px;opacity:.85", "Built from NEON DP1.10072.001 (small mammals), DP1.10003.001 (birds), DP1.10058.001 (plants), DP1.10098.001 (veg structure), DP1.10055.001 (phenology), DP1.10043.001 (mosquitoes), DP1.10022.001 (ground beetles), and NEON/Daymet climate. Not affiliated with NEON, Battelle, or the NSF. An educational data-exploration tool.")
  )
)
