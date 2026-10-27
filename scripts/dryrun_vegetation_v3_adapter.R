# ===========================================================================
# DRY RUN ONLY. Not a build step, not an artifact writer, not on the deploy
# surface (scripts/manifest_files.R DEPLOY_APP_FILES), and not one of the
# LOCAL_BUILD_INPUT_PATHS hashed into cascade_meta. Running it changes no byte
# under data/ and never touches manifest.json.
#
# Measures the Vegetation contract v3 path (rulings V3-1 to V3-6) against the
# committed family. For every site in the committed data/cascade.rds site_meta
# it runs the production ann_veg() and ann_veg_events() definitions, parsed out
# of scripts/build_cascade.R without running the build, over three sibling
# checkouts:
#   pinned  the commit the committed family was built from; every veg_* column
#           must reproduce the committed site_meta exactly (check a).
#   main    a v2 checkout; the same columns must be identical under the
#           adapter at --base (default 32175d1, read with git show) and the
#           working tree (check a2: the v2 path did not move).
#   v3      a v3 checkout; per-site table and deltas against the pinned run.
# It writes one Markdown report of tables to <report.md>.
#
# Usage (from the repository root):
#   Rscript --vanilla scripts/dryrun_vegetation_v3_adapter.R <report.md> \
#     pinned=<checkout> main=<checkout> v3=<checkout> [base=<git ref>]
#
# <checkout> is a detached clone of github.com/tgilbert14/neon-vegetation-
# structure-explorer whose data/sites/*.rds are read. Nothing in the sibling
# checkout is sourced or executed.
# ===========================================================================
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1]), winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) { setwd(root); return(invisible(root)) }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}
ROOT <- setwd_repo_root()
suppressPackageStartupMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4L) stop("usage: <report.md> pinned=<path> main=<path> v3=<path> [base=<ref>]",
                            call. = FALSE)
REPORT <- args[1]
if (grepl("(^|/)data/", REPORT) || grepl("manifest\\.json$", REPORT))
  stop("the dry run never writes under data/ or to manifest.json", call. = FALSE)
kv <- do.call(rbind, lapply(args[-1], function(a) {
  at <- regexpr("=", a, fixed = TRUE)
  if (at < 2L) stop(sprintf("bad argument: %s", a), call. = FALSE)
  data.frame(k = substr(a, 1L, at - 1L), v = substr(a, at + 1L, nchar(a)), stringsAsFactors = FALSE)
}))
opt <- setNames(kv$v, kv$k)
for (k in c("pinned", "main", "v3"))
  if (is.na(opt[k]) || !dir.exists(file.path(opt[[k]], "data", "sites")))
    stop(sprintf("%s=<checkout> with data/sites is required", k), call. = FALSE)
BASE <- if (is.na(opt["base"])) "32175d1" else opt[["base"]]
git_head <- function(path) tryCatch(
  system2("git", c("-C", shQuote(path), "rev-parse", "--short=7", "HEAD"), stdout = TRUE),
  error = function(e) "unknown", warning = function(w) "unknown")

# ---- production definitions, loaded into one environment per code version ----
BUILD_DEFS <- c("veg_legacy_audit", "veg_event_audit", "VEG_AUDIT_NUMERIC_COLS",
                "VEG_AUDIT_CHARACTER_COLS", "ann_veg_events", "ann_veg")
load_code <- function(adapter_lines, build_lines) {
  env <- new.env(parent = globalenv())
  eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = env)
  eval(parse(text = adapter_lines, keep.source = FALSE), envir = env)
  exprs <- parse(text = build_lines, keep.source = FALSE)
  picked <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                     is.name(e[[2]]) && as.character(e[[2]]) %in% BUILD_DEFS, as.list(exprs))
  got <- vapply(picked, function(e) as.character(e[[2]]), character(1))
  if (!setequal(got, BUILD_DEFS) || anyDuplicated(got))
    stop(sprintf("build definitions not found exactly once: %s",
                 paste(setdiff(BUILD_DEFS, got), collapse = ", ")), call. = FALSE)
  for (e in picked) eval(e, envir = env)
  env
}
git_lines <- function(ref, path) {
  out <- system2("git", c("show", sprintf("%s:%s", ref, path)), stdout = TRUE)
  if (!is.null(attr(out, "status"))) stop(sprintf("git show %s:%s failed", ref, path), call. = FALSE)
  out
}
NEW <- load_code(readLines("R/source_adapters.R", warn = FALSE, encoding = "UTF-8"),
                 readLines("scripts/build_cascade.R", warn = FALSE, encoding = "UTF-8"))
OLD <- load_code(git_lines(BASE, "R/source_adapters.R"), git_lines(BASE, "scripts/build_cascade.R"))

# ---- committed baseline (read-only) ----
cascade <- readRDS("data/cascade.rds")
committed <- cascade$site_meta[order(cascade$site_meta$site), , drop = FALSE]
SITES <- committed$site
VEG_COLS <- grep("^veg_", names(committed), value = TRUE)

read_bundle <- function(path, site) {
  f <- file.path(path, "data", "sites", paste0(site, ".rds"))
  if (file.exists(f)) readRDS(f) else NULL
}
# The builder's shape resolution and ann_veg loop, with the builder's NA fill
# for sites without a bundle; the extra event audit (flag counts) is collected
# beside it from the same cascade_veg_event_site() call ann_veg_events makes.
run_source <- function(env, path) {
  bundles <- setNames(lapply(SITES, function(s) read_bundle(path, s)), SITES)
  shape <- env$cascade_veg_resolve_shape(setNames(lapply(SITES, function(s)
    if (is.null(bundles[[s]])) NULL else env$cascade_veg_bundle_shape(bundles[[s]], s)), SITES))
  rows <- do.call(rbind, lapply(SITES, function(s) env$ann_veg(s, bundles[[s]], shape)))
  out <- data.frame(site = SITES, stringsAsFactors = FALSE)
  out <- dplyr::left_join(out, rows, by = "site")
  for (col in setdiff(VEG_COLS, names(out)))
    out[[col]] <- if (is.character(committed[[col]])) NA_character_ else NA_real_
  extra <- do.call(rbind, lapply(SITES, function(s) {
    b <- bundles[[s]]
    none <- data.frame(site = s, superseded_rows = NA_integer_, duplicate_rows = NA_integer_,
                       complete_partial_events = NA_integer_, stringsAsFactors = FALSE)
    if (is.null(b) || !shape %in% c("v2", "v3") || !nrow(b$trees)) return(none)
    # The base adapter predates the shape argument (it read v2 only).
    r <- if ("shape" %in% names(formals(env$cascade_veg_event_site)))
      env$cascade_veg_event_site(b$trees, b$plots, s, shape) else
      env$cascade_veg_event_site(b$trees, b$plots, s)
    p <- b$plots
    complete <- if (all(c("tree_channel_complete", "shrub_channel_complete") %in% names(p)))
      sum(p$tree_channel_complete %in% TRUE | p$shrub_channel_complete %in% TRUE) else NA_integer_
    flag <- function(x) if (is.null(x)) NA_integer_ else as.integer(x)
    data.frame(site = s, superseded_rows = flag(r$audit$superseded_rows),
               duplicate_rows = flag(r$audit$duplicate_rows),
               complete_partial_events = as.integer(complete), stringsAsFactors = FALSE)
  }))
  list(shape = shape, meta = out[, c("site", VEG_COLS)], extra = extra,
       n_bundles = sum(!vapply(bundles, is.null, logical(1))))
}
# PASS means identical(). A numeric column that differs only in the last bits
# AND is reproduced bit for bit by the base adapter on the same input is
# reported as PLATFORM: the committed family was summed on the CI runner, and
# the code under test gives the same bits as the code that built it here.
column_parity <- function(a, b, base = NULL) {
  vapply(VEG_COLS, function(col) {
    x <- a[[col]]; y <- b[[col]]
    if (identical(x, y)) return("PASS")
    if (is.numeric(x) && is.numeric(y) && identical(as.numeric(x), as.numeric(y)))
      return("PASS (values identical, storage type differs)")
    bad <- which(!(mapply(identical, as.list(x), as.list(y))))
    if (!is.null(base) && is.numeric(x) && is.numeric(y) && identical(x, base[[col]]) &&
        identical(is.na(x), is.na(y))) {
      rel <- max(abs(x - y) / pmax(abs(y), .Machine$double.xmin), na.rm = TRUE)
      if (rel < 1e-12)
        return(sprintf("PLATFORM (%d site(s), max relative difference %.1e; base adapter gives identical bits)",
                       length(bad), rel))
    }
    sprintf("FAIL (%d site(s): %s)", length(bad), paste(utils::head(a$site[bad], 6L), collapse = ", "))
  }, character(1))
}

cat("running pinned ...\n"); pinned <- run_source(NEW, opt[["pinned"]])
cat("running pinned (base) ...\n"); pinned_old <- run_source(OLD, opt[["pinned"]])
cat("running main (base) ...\n"); main_old <- run_source(OLD, opt[["main"]])
cat("running main (working tree) ...\n"); main_new <- run_source(NEW, opt[["main"]])
cat("running v3 ...\n"); v3 <- run_source(NEW, opt[["v3"]])

parity_a <- column_parity(pinned$meta, committed[, c("site", VEG_COLS)], pinned_old$meta)
parity_a_base <- column_parity(pinned$meta, pinned_old$meta)
parity_a2 <- column_parity(main_new$meta, main_old$meta)
cat(sprintf("(a)  %s\n", paste(sprintf("%s %s", VEG_COLS, parity_a), collapse = "\n     ")))
cat(sprintf("(a0) base and working-tree adapters on pinned: %s\n",
            if (all(parity_a_base == "PASS")) "identical on every column" else "DIFFER"))
cat(sprintf("(a2) %s\n", paste(sprintf("%s %s", VEG_COLS, parity_a2), collapse = "\n     ")))

excl_count <- function(s, key) vapply(s, function(x) {
  if (is.na(x) || !nzchar(x)) return(if (is.na(x)) NA_integer_ else 0L)
  parts <- strsplit(strsplit(x, ";", fixed = TRUE)[[1]], "=", fixed = TRUE)
  hit <- Filter(function(p) identical(p[1], key), parts)
  if (length(hit)) as.integer(hit[[1]][2]) else 0L
}, integer(1))
excl_total <- function(s) vapply(s, function(x) {
  if (is.na(x)) return(NA_integer_)
  if (!nzchar(x)) return(0L)
  sum(as.integer(sub("^.*=", "", strsplit(x, ";", fixed = TRUE)[[1]])))
}, integer(1))
site_table <- function(run) {
  m <- run$meta
  data.frame(site = m$site, shape = ifelse(is.finite(m$veg_plot_events) | !is.na(m$veg_source_contract),
                                         run$shape, ""),
             veg_ba_ha = m$veg_ba_ha, veg_n_plots = m$veg_n_plots, veg_type = m$veg_type,
             admitted = m$veg_admitted_events, absence = m$veg_absence_events,
             excluded = excl_total(m$veg_excluded_events),
             sibling_complete = excl_count(m$veg_excluded_events, "excl_partial_hold_sibling_complete"),
             superseded_rows = run$extra$superseded_rows, duplicate_rows = run$extra$duplicate_rows,
             stringsAsFactors = FALSE)
}
fmt <- function(x, digits = 3) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
fmt_int <- function(x) ifelse(is.na(x), "NA", as.character(x))
md_table <- function(df) {
  df[] <- lapply(df, function(x) ifelse(is.na(x), "NA", as.character(x)))
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}
show_site_table <- function(t) {
  t$veg_ba_ha <- fmt(t$veg_ba_ha)
  t$veg_n_plots <- fmt_int(t$veg_n_plots)
  md_table(t)
}
main_t <- site_table(main_new)
v3_t <- site_table(v3)
pin <- pinned$meta
delta <- data.frame(
  site = SITES,
  ba_pinned = pin$veg_ba_ha, ba_v3 = v3$meta$veg_ba_ha,
  ba_abs = v3$meta$veg_ba_ha - pin$veg_ba_ha,
  ba_pct = 100 * (v3$meta$veg_ba_ha - pin$veg_ba_ha) / pin$veg_ba_ha,
  n_pinned = pin$veg_n_plots, n_v3 = v3$meta$veg_n_plots,
  n_abs = v3$meta$veg_n_plots - pin$veg_n_plots,
  n_pct = 100 * (v3$meta$veg_n_plots - pin$veg_n_plots) / pin$veg_n_plots,
  type_pinned = pin$veg_type, type_v3 = v3$meta$veg_type, stringsAsFactors = FALSE)
delta$flag <- ifelse(is.finite(delta$ba_pinned) & !is.finite(delta$ba_v3), "finite to NA",
              ifelse(!is.finite(delta$ba_pinned) & is.finite(delta$ba_v3), "NA to finite",
              ifelse(!is.na(delta$type_pinned) & !is.na(delta$type_v3) &
                       delta$type_pinned != delta$type_v3, "type flip", "")))
show_delta <- function(d) {
  for (k in c("ba_pinned", "ba_v3", "ba_abs")) d[[k]] <- fmt(d[[k]])
  for (k in c("ba_pct", "n_pct")) d[[k]] <- fmt(d[[k]], 1)
  for (k in c("n_pinned", "n_v3", "n_abs")) d[[k]] <- fmt_int(d[[k]])
  md_table(d)
}
v3_vs_main <- data.frame(site = SITES, ba_main = main_new$meta$veg_ba_ha, ba_v3 = v3$meta$veg_ba_ha,
                         ba_pct = 100 * (v3$meta$veg_ba_ha - main_new$meta$veg_ba_ha) /
                           main_new$meta$veg_ba_ha,
                         n_main = main_new$meta$veg_n_plots, n_v3 = v3$meta$veg_n_plots,
                         type_main = main_new$meta$veg_type, type_v3 = v3$meta$veg_type,
                         stringsAsFactors = FALSE)
moved <- v3_vs_main[!mapply(identical, v3_vs_main$ba_main, v3_vs_main$ba_v3) |
                      !mapply(identical, v3_vs_main$n_main, v3_vs_main$n_v3) |
                      !mapply(identical, v3_vs_main$type_main, v3_vs_main$type_v3), , drop = FALSE]
moved$ba_main <- fmt(moved$ba_main); moved$ba_v3 <- fmt(moved$ba_v3)
moved$ba_pct <- fmt(moved$ba_pct, 1)

totals <- function(t, run) c(
  admitted = sum(t$admitted, na.rm = TRUE), absence = sum(t$absence, na.rm = TRUE),
  excluded = sum(t$excluded, na.rm = TRUE),
  sibling_complete_stand_channel = sum(t$sibling_complete, na.rm = TRUE),
  partial_events_marked_complete_either_channel = sum(run$extra$complete_partial_events, na.rm = TRUE),
  superseded_rows = sum(t$superseded_rows, na.rm = TRUE),
  duplicate_rows = sum(t$duplicate_rows, na.rm = TRUE))
tot <- rbind(main = totals(main_t, main_new), v3 = totals(v3_t, v3))

lines <- c(
  "<!-- generated by scripts/dryrun_vegetation_v3_adapter.R; tables below are machine output -->",
  "",
  "## Machine output",
  "",
  sprintf("Sources: pinned %s (%s, %d bundles), main %s (%s, %d bundles), v3 %s (%s, %d bundles); base adapter %s.",
          git_head(opt[["pinned"]]), pinned$shape, pinned$n_bundles,
          git_head(opt[["main"]]), main_new$shape, main_new$n_bundles,
          git_head(opt[["v3"]]), v3$shape, v3$n_bundles, BASE),
  "",
  "### (a) pinned checkout against the committed site_meta",
  "",
  md_table(data.frame(column = VEG_COLS, result = unname(parity_a), stringsAsFactors = FALSE)),
  "",
  sprintf("Base adapter %s and the working tree on the pinned checkout: %s.", BASE,
          if (all(parity_a_base == "PASS")) "identical on every veg_* column" else "DIFFER"),
  "",
  "### (a2) v2 path before and after the change, on the main checkout",
  "",
  md_table(data.frame(column = VEG_COLS, result = unname(parity_a2), stringsAsFactors = FALSE)),
  "",
  "### (b) main checkout (contract v2), per site",
  "",
  show_site_table(main_t),
  "",
  "### (c) v3 checkout (contract v3), per site",
  "",
  show_site_table(v3_t),
  "",
  "### v3 against pinned",
  "",
  show_delta(delta),
  "",
  "### v3 against main (sites whose veg_ba_ha, veg_n_plots or veg_type moved)",
  "",
  if (nrow(moved)) md_table(moved) else "No site moved.",
  "",
  "### Suite totals (sum over sites)",
  "",
  md_table(data.frame(source = rownames(tot), tot, check.names = FALSE, stringsAsFactors = FALSE)))
writeLines(lines, REPORT, useBytes = TRUE)
cat(sprintf("wrote %s\n", REPORT))
if (any(startsWith(parity_a, "FAIL")) || any(!startsWith(parity_a2, "PASS")) ||
    any(parity_a_base != "PASS")) quit(status = 1L)
