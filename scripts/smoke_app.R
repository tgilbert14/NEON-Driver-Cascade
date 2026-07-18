# Fail a generation before promotion if the exact staged app cannot boot.
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1L]),
                            winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}

setwd_repo_root()
scan_env <- new.env(parent = baseenv())
sys.source("scripts/manifest_files.R", envir = scan_env)
runtime_font_files <- c(
  scan_env$DEPLOY_APP_FILES[!grepl("\\.rds$", scan_env$DEPLOY_APP_FILES,
                                  ignore.case = TRUE)],
  "manifest.json")
font_rules <- c(
  bslib_google_font = "\\bfont_google\\s*\\(",
  google_fonts_api = "fonts\\s*\\.\\s*googleapis\\s*\\.\\s*com",
  google_fonts_asset = "fonts\\s*\\.\\s*gstatic\\s*\\.\\s*com",
  remote_font_file = "(?:https?:)?\\s*//[^\\s\"'<>)]*\\.(?:woff2?|ttf|otf|eot)(?:[?#][^\\s\"'<>)]*)?",
  remote_css_import = "@import\\s+(?:url\\s*\\(\\s*)?[\"']?\\s*(?:https?:)?\\s*//",
  remote_font_face = "@font-face\\s*\\{[^}]*\\bsrc\\s*:[^}]*url\\s*\\(\\s*[\"']?\\s*(?:https?:)?\\s*//")
font_leaks <- character()
for (path in runtime_font_files) {
  if (!file.exists(path))
    stop(sprintf("runtime font audit file is missing: %s", path), call. = FALSE)
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  hit <- names(font_rules)[vapply(font_rules, function(rule)
    grepl(rule, text, ignore.case = TRUE, perl = TRUE), logical(1))]
  if (length(hit))
    font_leaks <- c(font_leaks, sprintf("%s [%s]", path, paste(hit, collapse = ", ")))
}
if (length(font_leaks))
  stop(sprintf("deployed text has remote-font reference(s): %s",
               paste(font_leaks, collapse = "; ")), call. = FALSE)
for (path in c("global.R", "ui.R", "server.R",
               "R/cascade_helpers.R", "R/site_metadata.R")) {
  parse(path, keep.source = FALSE)
}
eval(parse(file = "global.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "ui.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "server.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
if (!grepl("UTF-?8", Sys.getlocale("LC_CTYPE"), ignore.case = TRUE))
  stop("the app did not activate a UTF-8 runtime locale", call. = FALSE)

if (!exists("ui", inherits = FALSE) || is.null(ui))
  stop("ui.R did not construct the application UI", call. = FALSE)
if (!exists("server", inherits = FALSE) || !is.function(server))
  stop("server.R did not construct a server function", call. = FALSE)

app <- shiny::shinyApp(ui = ui, server = server)
if (!inherits(app, "shiny.appobj"))
  stop("the staged UI and server did not construct a Shiny application", call. = FALSE)

rendered <- htmltools::renderTags(ui)
rendered_points <- utf8ToInt(rendered$html)
forbidden_controls <- c(0:8, 11:12, 14:31, 127:159)
if (any(rendered_points %in% forbidden_controls))
  stop("rendered UI contains a forbidden control code point", call. = FALSE)
if (!grepl("\u2192", rendered$html, fixed = TRUE))
  stop("rendered Search choices lost their UTF-8 driver-to-response arrow", call. = FALSE)
if (!is.list(rendered) || !is.character(rendered$html) ||
    length(rendered$html) != 1L || !nzchar(rendered$html))
  stop("the staged UI could not be serialized", call. = FALSE)
apparent_titles <- unlist(lapply(ALL_SITES, function(site) {
  audit <- cascade_qc(site_annual(site), site_links_cached(site), SIGNALS, site)
  vapply(audit$flags, function(flag)
    if (identical(flag$key, "apparent_ci0")) flag$title else NA_character_, character(1))
}), use.names = FALSE)
apparent_titles <- apparent_titles[!is.na(apparent_titles)]
if (!length(apparent_titles) ||
    !all(apparent_titles == "\u201cApparent\u201d links whose CI spans zero"))
  stop("the apparent-link QC title was lost or corrupted", call. = FALSE)
runtime_text_probe <- list(
  search = SRCH_CATALOG$link_label,
  seasonal = SIGNALS$label,
  units = SIGNALS$unit,
  bio = site_bio("BLAN"),
  site_choices = names(sites_in_state("VA")),
  qc = apparent_titles)
cascade_assert_artifact_text(runtime_text_probe, "rendered runtime text probe")
escaped_probe <- as.character(htmltools::htmlEscape(
  paste(unlist(runtime_text_probe, use.names = FALSE), collapse = " | ")))
escaped_points <- utf8ToInt(escaped_probe)
required_glyphs <- c("\u2192", "Oct\u2013Mar", "Jul\u2013Sep", "\u00b0C", "\u00b7",
                     "\u201cApparent\u201d")
if (any(escaped_points %in% forbidden_controls) ||
    !all(vapply(required_glyphs, grepl, logical(1), x = escaped_probe, fixed = TRUE)))
  stop("htmltools corrupted a required UTF-8 runtime glyph", call. = FALSE)
remote_dependency <- vapply(rendered$dependencies, function(dep) {
  src <- unlist(dep$src, recursive = TRUE, use.names = FALSE)
  any(grepl("^\\s*(?:https?:)?//", src, ignore.case = TRUE, perl = TRUE))
}, logical(1))
if (any(remote_dependency))
  stop(sprintf("the staged UI has remote boot dependencies: %s",
               paste(vapply(rendered$dependencies[remote_dependency], `[[`, character(1), "name"),
                     collapse = ", ")), call. = FALSE)
remote_boot_tag <- "<(?:link|script|img|source|video|audio|iframe)\\b[^>]*(?:src|href)\\s*=\\s*['\"]\\s*(?:https?:)?//"
if (grepl(remote_boot_tag, rendered$html, ignore.case = TRUE, perl = TRUE))
  stop("the serialized UI embeds a remote boot resource", call. = FALSE)
for (token in c('class="standing-stock-status"', 'role="status"',
                'aria-live="polite"', 'aria-atomic="true"'))
  if (!grepl(token, rendered$html, fixed = TRUE))
    stop(sprintf("standing-stock live region omitted %s", token), call. = FALSE)

wood_meta <- SITE_META[SITE_META[["site"]] == "WOOD", , drop = FALSE]
if (nrow(wood_meta) != 1L ||
    !identical(as.character(wood_meta[["veg_design_status"]][1]),
               "unsupported-unmatched-plots") ||
    !is.na(wood_meta[["veg_ba_ha"]][1]) ||
    as.integer(wood_meta[["veg_unmatched_record_rows"]][1]) != 452L ||
    as.integer(wood_meta[["veg_unmatched_record_plots"]][1]) != 14L)
  stop("WOOD unsupported vegetation metadata drifted from its reviewed source audit",
       call. = FALSE)

# testServer() does not hydrate input defaults from the UI. Supply the actual
# landing-state values, flush, and materialize representative outputs so req()
# cannot let a broken initial session pass this smoke test vacuously.
shiny::testServer(server, {
  session$setInputs(
    site = DEFAULT_SITE,
    response = "mammal_cpue",
    tabs = "overview",
    colorMode = "light",
    sbSort = "default",
    searchMode = "link",
    searchLink = "temp|greenup_doy|0",
    searchAlignedOnly = FALSE,
    searchMinResolved = 0L,
    expLag = 0L,
    vw = 1200L
  )
  session$flushReact()
  representative <- c(
    "heroStats", "siteBio", "signalChips", "overviewInsight",
    "cascadeSchematic", "signalTable", "driverTable", "linkScatterHeader",
    "linkScatterNote", "pooledHeadline", "scoreboard", "qcFlags",
    "aboutPanel", "ladderPlot", "linkScatter", "expCurve", "seasonalPlot")
  runtime_warnings <- character()
  materialized <- withCallingHandlers(
    stats::setNames(lapply(representative, function(id) output[[id]]),
                    representative),
    warning = function(w) {
      runtime_warnings <<- c(runtime_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  if (length(runtime_warnings))
    stop(sprintf("initial app outputs emitted warning(s): %s",
                 paste(unique(runtime_warnings), collapse = "; ")), call. = FALSE)
  empty <- names(materialized)[vapply(materialized, function(value) {
    is.null(value) || (is.character(value) && !any(nzchar(value)))
  }, logical(1))]
  if (length(empty))
    stop(sprintf("initial app smoke produced empty output(s): %s",
                 paste(empty, collapse = ", ")), call. = FALSE)

  empty_note <- plotly::plotly_build(note_plot("Empty-state font smoke"))
  note_annotations <- empty_note$x$layout$annotations
  note_family <- if (length(note_annotations) && is.list(note_annotations[[1L]]$font))
    note_annotations[[1L]]$font$family else NULL
  if (!identical(note_family, APP_FONT_STACK))
    stop("Plotly empty-state annotation does not use APP_FONT_STACK", call. = FALSE)

  session$setInputs(site = "WOOD")
  session$flushReact()
  wood <- output[["standingStock"]]
  wood_html <- if (is.list(wood) && is.character(wood$html))
    paste(wood$html, collapse = "\n") else ""
  if (!grepl("standing-stock-unsupported", wood_html, fixed = TRUE))
    stop("WOOD standingStock did not render the unsupported state", call. = FALSE)
  wood_text <- tolower(gsub("\\s+", " ", gsub("<[^>]+>", " ", wood_html)))
  wood_required <- c(
    "estimate withheld",
    "452 vegetation records across 14 plot ids",
    "no partial subset or area imputation was used",
    "estimate and classification remain unavailable")
  wood_missing <- wood_required[!vapply(wood_required, function(text)
    grepl(text, wood_text, fixed = TRUE), logical(1))]
  if (length(wood_missing))
    stop(sprintf("WOOD standingStock omitted required disclosure(s): %s",
                 paste(wood_missing, collapse = ", ")), call. = FALSE)
})


cat(sprintf("APP BOOT SMOKE PASSED: %d annual rows, %d registered associations.\n",
            nrow(ANNUAL), nrow(PRIORS)))
