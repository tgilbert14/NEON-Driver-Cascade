# ===========================================================================
# DRY RUN ONLY. Not a build step, not an artifact writer, not on the deploy
# surface (scripts/manifest_files.R DEPLOY_APP_FILES), and not one of the six
# LOCAL_BUILD_INPUT_PATHS hashed into cascade_meta. Running it changes no byte
# under data/ and never touches manifest.json.
#
# Prototype of the Vegetation plot x event adapter specified in
# docs/VEGETATION-V2-ADAPTER-SPEC.md. It reads committed sibling bundles from
# detached checkouts, reproduces the CURRENT Driver rule through the production
# helpers in R/source_adapters.R (the "legacy" path, checked against the
# committed data/cascade.rds site_meta), applies the PROPOSED v2 rule and three
# named sensitivities, and writes per-site impact tables plus a reason ledger
# to an output directory.
#
# Usage (from the repository root):
#   Rscript --vanilla scripts/dryrun_vegetation_v2_adapter.R <outdir> \
#     legacy=<tag>=<checkout> v2=<tag>=<checkout> [v2=<tag>=<checkout> ...]
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
eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
eval(parse(file = "R/source_adapters.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3L) stop("usage: <outdir> legacy=<tag>=<path> v2=<tag>=<path> ...", call. = FALSE)
OUT <- args[1]; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
parse_source <- function(a) {
  parts <- strsplit(a, "=", fixed = TRUE)[[1]]
  if (length(parts) < 3L) stop(sprintf("bad source argument: %s", a), call. = FALSE)
  list(mode = parts[1], tag = parts[2], path = paste(parts[-(1:2)], collapse = "="))
}
SOURCES <- lapply(args[-1], parse_source)
for (s in SOURCES) {
  if (!s$mode %in% c("legacy", "v2")) stop(sprintf("mode must be legacy|v2: %s", s$mode), call. = FALSE)
  if (!dir.exists(file.path(s$path, "data", "sites"))) stop(sprintf("no data/sites under %s", s$path), call. = FALSE)
}
legacy_src <- Filter(function(s) s$mode == "legacy", SOURCES)
if (length(legacy_src) != 1L) stop("exactly one legacy=<tag>=<path> source is required", call. = FALSE)
legacy_src <- legacy_src[[1]]

# ---- baseline: the committed artifact (read-only) ------------------------
cascade <- readRDS("data/cascade.rds")
baseline <- cascade$site_meta[, c("site", grep("^veg_", names(cascade$site_meta), value = TRUE))]
SITES <- sort(baseline$site)
LEGACY_COLS <- c("veg_ba_ha", "veg_ba_se", "veg_type", "veg_n_plots", "veg_record_plots",
                 "veg_matched_record_plots", "veg_area_eligible_plots",
                 "veg_unmatched_record_plots", "veg_unmatched_record_rows",
                 "veg_class_tree_ba_ha", "veg_class_shrub_ba_ha",
                 "veg_class_tree_plots", "veg_class_shrub_plots",
                 "veg_stand_basis", "veg_class_basis", "veg_design_status", "veg_design_basis")
cat(sprintf("baseline: %d sites in committed site_meta; veg source pin %s\n", nrow(baseline),
            cascade$meta$source_products$commit[cascade$meta$source_products$product == "veg"]))

read_bundle <- function(path, site) {
  f <- file.path(path, "data", "sites", paste0(site, ".rds"))
  if (!file.exists(f)) return(NULL)
  readRDS(f)
}

# ---- LEGACY path: scripts/build_cascade.R::ann_veg, body copied verbatim ----
# (the only change is that the bundle is passed in instead of read from APP$veg).
ann_veg_legacy <- function(b, site) {
  if (is.null(b)) return(NULL)
  trees <- cascade_bundle_table(b, "trees", "vegetation", site)
  plots <- cascade_bundle_table(b, "plots", "vegetation", site)
  cascade_require_columns(trees, CASCADE_VEG_TREES_REQUIRED, sprintf("%s vegetation tree table", site))
  cascade_require_columns(plots, CASCADE_VEG_PLOTS_REQUIRED, sprintf("%s vegetation plot table", site))
  if (!nrow(trees)) return(NULL)
  snap <- cascade_tree_snapshot(trees)
  if (is.null(snap) || !nrow(snap)) return(NULL)
  support <- cascade_vegetation_design_support(snap, plots)
  if (!support$supported) {
    return(data.frame(
      site = site, veg_ba_ha = NA_real_, veg_ba_se = NA_real_,
      veg_type = NA_character_, veg_n_plots = 0L,
      veg_record_plots = support$n_record_plots,
      veg_matched_record_plots = support$n_matched_record_plots,
      veg_area_eligible_plots = 0L,
      veg_unmatched_record_plots = support$n_unmatched_record_plots,
      veg_unmatched_record_rows = support$n_unmatched_record_rows,
      veg_class_tree_ba_ha = NA_real_, veg_class_shrub_ba_ha = NA_real_,
      veg_class_tree_plots = NA_integer_, veg_class_shrub_plots = NA_integer_,
      veg_stand_basis = CASCADE_VEG_STAND_BASIS,
      veg_class_basis = CASCADE_VEG_CLASSIFICATION_BASIS,
      veg_design_status = "unsupported-unmatched-plots",
      veg_design_basis = support$basis,
      stringsAsFactors = FALSE))
  }
  snap <- support$snapshot
  plots <- support$plots
  structure <- cascade_structure_evidence(snap, plots)
  spec <- cascade_size_spec(structure$type)
  ss <- cascade_stand_site(snap, plots, spec)
  if (is.null(ss)) return(NULL)
  if (!identical(as.integer(ss$n_record_plots), support$n_record_plots))
    stop(sprintf("%s vegetation support audit disagrees with stand records", site), call. = FALSE)
  data.frame(
    site = site, veg_ba_ha = ss$ba_ha, veg_ba_se = ss$ba_se,
    veg_type = spec$type, veg_n_plots = ss$n_plots,
    veg_record_plots = ss$n_record_plots,
    veg_matched_record_plots = support$n_matched_record_plots,
    veg_area_eligible_plots = ss$n_area_eligible_plots,
    veg_unmatched_record_plots = support$n_unmatched_record_plots,
    veg_unmatched_record_rows = support$n_unmatched_record_rows,
    veg_class_tree_ba_ha = structure$tree_ba_ha,
    veg_class_shrub_ba_ha = structure$shrub_ba_ha,
    veg_class_tree_plots = structure$tree_n_plots,
    veg_class_shrub_plots = structure$shrub_n_plots,
    veg_stand_basis = ss$basis, veg_class_basis = structure$basis,
    veg_design_status = "supported", veg_design_basis = support$basis,
    stringsAsFactors = FALSE)
}

# ---- PROPOSED v2 rule --------------------------------------------------------
V2_SUPPORTED_STATUS <- c("sampled_with_records", "sampled_absence")
V2_PLOTS_REQUIRED <- c("plotID", "eventID", "date", "area_trees", "area_shrub",
                       "tree_support", "shrub_support", "tree_supported", "shrub_supported")
V2_TREES_REQUIRED <- c(CASCADE_VEG_TREES_REQUIRED, "eventID")
V2_AREA_ELIGIBLE_M2 <- 50          # unchanged from the legacy rule (area_ha > 0.005)
V2_DISJOINT_TREE_FORMS <- c("single bole tree", "multi-bole tree")
V2_DISJOINT_SHRUB_FORMS <- c("single shrub", "small shrub", "sapling")
v2_channel_spec <- function(type, opts) {
  spec <- cascade_size_spec(type)
  spec$support <- if (type == "forest") "tree_support" else "shrub_support"
  spec$supported <- if (type == "forest") "tree_supported" else "shrub_supported"
  if (isTRUE(opts$disjoint_forms))
    spec$forms <- if (type == "forest") V2_DISJOINT_TREE_FORMS else V2_DISJOINT_SHRUB_FORMS
  spec
}
key2 <- function(d) paste(as.character(d$plotID), as.character(d$eventID), sep = "\r")

# One row per plot: the latest supported event in this channel (date desc, then
# eventID desc; a missing date sorts last). Held events never become denominators.
v2_select_events <- function(plots, spec, opts, label) {
  status <- as.character(plots[[spec$support]])
  flag <- plots[[spec$supported]] %in% TRUE
  if (!identical(flag, status %in% V2_SUPPORTED_STATUS))
    stop(sprintf("%s: published %s disagrees with %s membership", label, spec$supported, spec$support), call. = FALSE)
  ok <- status %in% V2_SUPPORTED_STATUS
  if (isTRUE(opts$metric_invalid_as_supported)) ok <- ok | status %in% "held_metric_invalid"
  area <- suppressWarnings(as.numeric(plots[[spec$area]]))
  ok <- ok & is.finite(area) & area > 0
  dnum <- suppressWarnings(as.numeric(as.Date(plots$date)))
  dnum[!is.finite(dnum)] <- -Inf
  ord <- order(as.character(plots$plotID), -dnum, -xtfrm(as.character(plots$eventID)))
  p <- plots[ord, , drop = FALSE]; okp <- ok[ord]; d <- dnum[ord]
  latest_any <- p[!duplicated(as.character(p$plotID)), , drop = FALSE]          # latest event, any state
  ps <- p[okp, , drop = FALSE]; ds <- d[okp]
  sel <- ps[!duplicated(as.character(ps$plotID)), , drop = FALSE]
  sel_date <- ds[!duplicated(as.character(ps$plotID))]
  # later held event than the selected one (same channel), per selected plot
  later_held <- vapply(seq_len(nrow(sel)), function(i) {
    same <- as.character(p$plotID) == as.character(sel$plotID[i]) & !okp
    any(same & d > sel_date[i])
  }, logical(1))
  list(selected = sel, selected_date = sel_date, latest_any = latest_any,
       later_held = later_held, status_all = status, area_all = area)
}

v2_component <- function(trees, plots, type, opts, label) {
  spec <- v2_channel_spec(type, opts)
  ev <- v2_select_events(plots, spec, opts, label)
  sel <- ev$selected
  record_plots <- unique(as.character(trees$plotID))
  selected_plots <- as.character(sel$plotID)
  held_record <- setdiff(record_plots, selected_plots)
  held_state <- as.character(ev$latest_any[[spec$support]])[match(held_record, as.character(ev$latest_any$plotID))]
  held_tab <- if (length(held_state)) table(held_state) else table(character(0))
  rows <- trees[key2(trees) %in% key2(sel), , drop = FALSE]
  snap <- if (nrow(rows)) cascade_tree_snapshot(rows) else rows
  stems <- if (nrow(snap)) cascade_woody_only(cascade_live_only(snap), spec) else snap
  per <- NULL
  if (!is.null(stems) && nrow(stems)) {
    stems$.d <- suppressWarnings(as.numeric(stems[[spec$col]]))
    per <- stems %>% group_by(plotID = as.character(.data$plotID)) %>%
      summarise(ba_m2 = sum(pi * (.data$.d / 200)^2), stems = n(), .groups = "drop")
    per$area_m2 <- suppressWarnings(as.numeric(sel[[spec$area]]))[match(per$plotID, selected_plots)]
    per$eventID <- as.character(sel$eventID)[match(per$plotID, selected_plots)]
    if (any(!is.finite(per$area_m2) | per$area_m2 <= 0))
      stop(sprintf("%s: qualifying plot without positive finite %s", label, spec$area), call. = FALSE)
    per$eligible <- per$area_m2 > V2_AREA_ELIGIBLE_M2
    per$ba_ha <- per$ba_m2 / (per$area_m2 / 10000)
  }
  # classification evidence: summed BA over used+eligible plots / summed eligible area (legacy formula)
  class_ba_ha <- 0; class_n <- 0L
  if (!is.null(per) && any(per$eligible)) {
    class_ba_ha <- sum(per$ba_m2[per$eligible]) / (sum(per$area_m2[per$eligible]) / 10000)
    class_n <- as.integer(sum(per$eligible))
  }
  absence <- sel[as.character(sel[[spec$support]]) %in% "sampled_absence", , drop = FALSE]
  absence_area <- suppressWarnings(as.numeric(absence[[spec$area]]))
  list(spec = spec, ev = ev, sel = sel, per = per, class_ba_ha = class_ba_ha, class_n = class_n,
       record_plots = record_plots, selected_plots = selected_plots,
       held_record = held_record, held_tab = held_tab,
       absence_plots = as.character(absence$plotID), absence_eligible = sum(is.finite(absence_area) & absence_area > V2_AREA_ELIGIBLE_M2),
       later_held_n = sum(ev$later_held), snap = snap)
}

# legacy-style snapshot on the SAME trees (latest row per individual across all
# events) so we can count stems the legacy rule would have divided by another
# event's area; needs the pinned plots to count area differences.
v2_site <- function(b, site, opts, legacy_plots = NULL) {
  if (is.null(b)) return(NULL)
  trees <- cascade_bundle_table(b, "trees", "vegetation", site)
  plots <- cascade_bundle_table(b, "plots", "vegetation", site)
  cascade_require_columns(trees, V2_TREES_REQUIRED, sprintf("%s v2 vegetation tree table", site))
  cascade_require_columns(plots, V2_PLOTS_REQUIRED, sprintf("%s v2 vegetation plot table", site))
  if (anyDuplicated(key2(plots))) stop(sprintf("%s: duplicate plotID x eventID in plots", site), call. = FALSE)
  if (!nrow(trees)) return(NULL)
  record_keys <- unique(key2(trees))
  unmatched_keys <- setdiff(record_keys, key2(plots))
  record_plots <- unique(as.character(trees$plotID))
  base <- data.frame(site = site, veg_record_plots = length(record_plots),
                     veg_matched_record_plots = length(record_plots) - length(unique(as.character(trees$plotID[key2(trees) %in% unmatched_keys]))),
                     veg_v2_record_plot_events = length(record_keys),
                     veg_v2_unmatched_record_plot_events = length(unmatched_keys),
                     stringsAsFactors = FALSE)
  if (length(unmatched_keys)) {
    base$veg_design_status <- "unsupported-unmatched-plot-events"
    return(base)
  }
  tree <- v2_component(trees, plots, "forest", opts, site)
  shrub <- v2_component(trees, plots, "shrubland", opts, site)
  type <- if (tree$class_ba_ha == 0 && shrub$class_ba_ha == 0) "forest" else
    if (tree$class_ba_ha >= shrub$class_ba_ha) "forest" else "shrubland"
  comp <- if (type == "forest") tree else shrub
  per <- comp$per
  if (!is.null(per)) per <- per[per$eligible, , drop = FALSE]
  n_stand <- if (is.null(per)) 0L else nrow(per)
  vals <- if (is.null(per)) numeric(0) else per$ba_ha
  if (isTRUE(opts$absence_zero)) vals <- c(vals, rep(0, comp$absence_eligible))
  n <- length(vals)
  status <- if (!length(comp$selected_plots)) "unsupported-no-supported-event" else
    if (n == 0L) "supported-no-qualifying-stem" else "supported"
  legacy_outside <- NA_integer_; legacy_total <- NA_integer_; area_differs <- NA_integer_
  if (nrow(comp$snap) >= 0) {
    lsnap <- cascade_woody_only(cascade_live_only(cascade_tree_snapshot(trees)), comp$spec)
    legacy_total <- nrow(lsnap)
    legacy_outside <- sum(!(key2(lsnap) %in% key2(comp$sel)))
  }
  if (!is.null(legacy_plots) && !is.null(per) && nrow(per)) {
    la <- suppressWarnings(as.numeric(legacy_plots[[comp$spec$area]]))[match(per$plotID, as.character(legacy_plots$plotID))]
    area_differs <- sum(is.na(la) | abs(la - per$area_m2) > 1e-9)
  }
  held_str <- if (length(comp$held_tab)) paste(sprintf("%s=%d", names(comp$held_tab), as.integer(comp$held_tab)), collapse = ";") else ""
  sel_years <- suppressWarnings(as.integer(format(as.Date(comp$sel$date), "%Y")))
  cbind(base, data.frame(
    veg_ba_ha = if (n) mean(vals) else NA_real_,
    veg_ba_se = if (n > 1) stats::sd(vals) / sqrt(n) else NA_real_,
    veg_type = if (status == "unsupported-no-supported-event") NA_character_ else type,
    veg_n_plots = n,
    veg_area_eligible_plots = as.integer(sum(suppressWarnings(as.numeric(comp$sel[[comp$spec$area]])) > V2_AREA_ELIGIBLE_M2)),
    veg_unmatched_record_plots = 0L, veg_unmatched_record_rows = 0L,
    veg_class_tree_ba_ha = tree$class_ba_ha, veg_class_shrub_ba_ha = shrub$class_ba_ha,
    veg_class_tree_plots = tree$class_n, veg_class_shrub_plots = shrub$class_n,
    veg_design_status = status,
    veg_v2_tree_selected_plots = length(tree$selected_plots),
    veg_v2_shrub_selected_plots = length(shrub$selected_plots),
    veg_v2_selected_plots = length(comp$selected_plots),
    veg_v2_held_record_plots = length(comp$held_record),
    veg_v2_held_state_counts = held_str,
    veg_v2_sampled_absence_plots = length(comp$absence_plots),
    veg_v2_sampled_absence_eligible_plots = as.integer(comp$absence_eligible),
    veg_v2_stand_plots_with_stems = n_stand,
    veg_v2_plots_with_later_held_event = as.integer(comp$later_held_n),
    veg_v2_selected_event_year_min = if (length(sel_years)) min(sel_years, na.rm = TRUE) else NA_integer_,
    veg_v2_selected_event_year_max = if (length(sel_years)) max(sel_years, na.rm = TRUE) else NA_integer_,
    veg_v2_legacy_snapshot_stems = legacy_total,
    veg_v2_legacy_stems_outside_selected_event = legacy_outside,
    veg_v2_stand_plots_area_differs_from_legacy = area_differs,
    stringsAsFactors = FALSE))
}

# ---- run ---------------------------------------------------------------------
legacy_bundles <- lapply(SITES, function(s) read_bundle(legacy_src$path, s)); names(legacy_bundles) <- SITES
legacy_rows <- bind_rows(lapply(SITES, function(s) ann_veg_legacy(legacy_bundles[[s]], s)))
legacy_full <- left_join(data.frame(site = SITES, stringsAsFactors = FALSE), legacy_rows, by = "site")
write.csv(legacy_full, file.path(OUT, sprintf("legacy_%s.csv", legacy_src$tag)), row.names = FALSE)

# parity of the legacy path against the committed artifact: every column, every site
num_eq <- function(a, b, tol = 1e-12) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
chr_eq <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
parity <- vapply(LEGACY_COLS, function(col) {
  a <- baseline[[col]][match(SITES, baseline$site)]; b <- legacy_full[[col]]
  if (is.numeric(a)) all(num_eq(a, b)) else all(chr_eq(as.character(a), as.character(b)))
}, logical(1))
cat("\n== LEGACY PATH vs committed data/cascade.rds site_meta (46 sites):\n")
print(parity)
cat(sprintf("legacy-path parity: %s\n", if (all(parity)) "PASS (all 17 columns reproduce)" else "FAIL"))

VARIANTS <- list(
  primary = list(metric_invalid_as_supported = FALSE, disjoint_forms = FALSE, absence_zero = FALSE),
  A_metric_invalid_as_supported = list(metric_invalid_as_supported = TRUE, disjoint_forms = FALSE, absence_zero = FALSE),
  B_disjoint_forms = list(metric_invalid_as_supported = FALSE, disjoint_forms = TRUE, absence_zero = FALSE),
  C_absence_zero = list(metric_invalid_as_supported = FALSE, disjoint_forms = FALSE, absence_zero = TRUE))

results <- list()
for (s in Filter(function(x) x$mode == "v2", SOURCES)) {
  bundles <- lapply(SITES, function(site) read_bundle(s$path, site)); names(bundles) <- SITES
  # global held-state tallies across every plot-event of the Driver-scope bundles
  all_plots <- bind_rows(lapply(SITES, function(site) {
    b <- bundles[[site]]; if (is.null(b)) return(NULL)
    data.frame(site = site, tree_support = as.character(b$plots$tree_support),
               shrub_support = as.character(b$plots$shrub_support),
               year = suppressWarnings(as.integer(format(as.Date(b$plots$date), "%Y"))), stringsAsFactors = FALSE)
  }))
  write.csv(as.data.frame(table(tree_support = all_plots$tree_support)), file.path(OUT, sprintf("v2_%s_tree_support_tally.csv", s$tag)), row.names = FALSE)
  write.csv(as.data.frame(table(shrub_support = all_plots$shrub_support)), file.path(OUT, sprintf("v2_%s_shrub_support_tally.csv", s$tag)), row.names = FALSE)
  cat(sprintf("\n== %s: plot-event rows in Driver scope: %d across %d sites\n", s$tag, nrow(all_plots), length(unique(all_plots$site))))
  cat("tree_support tally:\n"); print(table(all_plots$tree_support))
  cat("shrub_support tally:\n"); print(table(all_plots$shrub_support))
  for (vn in names(VARIANTS)) {
    opts <- VARIANTS[[vn]]
    rows <- bind_rows(lapply(SITES, function(site) {
      lp <- legacy_bundles[[site]]$plots
      v2_site(bundles[[site]], site, opts, legacy_plots = lp)
    }))
    full <- left_join(data.frame(site = SITES, stringsAsFactors = FALSE), rows, by = "site")
    write.csv(full, file.path(OUT, sprintf("v2_%s_%s.csv", s$tag, vn)), row.names = FALSE)
    results[[paste(s$tag, vn, sep = "::")]] <- full
  }
}

# ---- impact table: primary v2 on each source vs the committed baseline ----
impact <- function(v2, tag) {
  b <- baseline[match(SITES, baseline$site), ]
  d <- data.frame(site = SITES,
                  baseline_ba_ha = b$veg_ba_ha, baseline_type = b$veg_type, baseline_n_plots = b$veg_n_plots,
                  baseline_status = b$veg_design_status,
                  v2_ba_ha = v2$veg_ba_ha, v2_type = v2$veg_type, v2_n_plots = v2$veg_n_plots,
                  v2_status = v2$veg_design_status,
                  held_record_plots = v2$veg_v2_held_record_plots,
                  held_states = v2$veg_v2_held_state_counts,
                  absence_plots = v2$veg_v2_sampled_absence_plots,
                  later_held = v2$veg_v2_plots_with_later_held_event,
                  legacy_stems_outside_event = v2$veg_v2_legacy_stems_outside_selected_event,
                  legacy_stems_total = v2$veg_v2_legacy_snapshot_stems,
                  stand_plots_area_differs = v2$veg_v2_stand_plots_area_differs_from_legacy,
                  stringsAsFactors = FALSE)
  d$delta_ba_ha <- d$v2_ba_ha - d$baseline_ba_ha
  d$pct_change <- ifelse(is.finite(d$baseline_ba_ha) & d$baseline_ba_ha > 0, 100 * d$delta_ba_ha / d$baseline_ba_ha, NA_real_)
  d$type_flip <- !is.na(d$baseline_type) & !is.na(d$v2_type) & d$baseline_type != d$v2_type
  d$support_change <- !chr_eq(d$baseline_status, d$v2_status)
  d
}
reason_ledger <- function(imp, v2, legacy_tag_rows, cur_rows) {
  reasons <- vapply(seq_len(nrow(imp)), function(i) {
    r <- character(0)
    s <- imp$site[i]
    lb <- legacy_bundles[[s]]
    if (is.null(lb)) return("no_vegetation_bundle")
    lr <- legacy_tag_rows[legacy_tag_rows$site == s, ]; cr <- cur_rows[cur_rows$site == s, ]
    if (!identical(lr$trees_nrow, cr$trees_nrow) || !identical(lr$trees_n_indiv, cr$trees_n_indiv)) r <- c(r, "source_trees_changed")
    if (!identical(lr$plots_n_plotID, cr$plots_n_plotID)) r <- c(r, "source_plots_changed")
    if (isTRUE(imp$stand_plots_area_differs[i] > 0)) r <- c(r, "event_area_differs")
    if (isTRUE(imp$legacy_stems_outside_event[i] > 0)) r <- c(r, "stems_outside_selected_event")
    if (isTRUE(imp$held_record_plots[i] > 0)) r <- c(r, "held_plots_excluded")
    if (isTRUE(imp$type_flip[i])) r <- c(r, "type_flipped")
    if (isTRUE(imp$support_change[i])) r <- c(r, "site_support_changed")
    changed <- !num_eq(imp$baseline_ba_ha[i], imp$v2_ba_ha[i], 1e-9) || isTRUE(imp$type_flip[i]) || isTRUE(imp$support_change[i]) ||
      !num_eq(imp$baseline_n_plots[i], imp$v2_n_plots[i], 0)
    if (!changed) return("no_change")
    if (!length(r)) return("UNEXPLAINED")
    paste(r, collapse = ";")
  }, character(1))
  reasons
}
shape <- function(path, tag) bind_rows(lapply(SITES, function(s) {
  b <- read_bundle(path, s); if (is.null(b)) return(data.frame(site = s, trees_nrow = NA_integer_, trees_n_indiv = NA_integer_, plots_n_plotID = NA_integer_))
  data.frame(site = s, trees_nrow = nrow(b$trees), trees_n_indiv = length(unique(b$trees$individualID)), plots_n_plotID = length(unique(b$plots$plotID)))
}))
legacy_shape <- shape(legacy_src$path, legacy_src$tag)
for (s in Filter(function(x) x$mode == "v2", SOURCES)) {
  v2 <- results[[paste(s$tag, "primary", sep = "::")]]
  imp <- impact(v2, s$tag)
  imp$reasons <- reason_ledger(imp, v2, legacy_shape, shape(s$path, s$tag))
  write.csv(imp, file.path(OUT, sprintf("impact_%s_primary.csv", s$tag)), row.names = FALSE)
  cat(sprintf("\n== IMPACT %s (primary v2 vs committed baseline)\n", s$tag))
  both <- is.finite(imp$baseline_ba_ha) & is.finite(imp$v2_ba_ha)
  cat(sprintf("sites with a bundle: %d; baseline finite: %d; v2 finite: %d; both finite: %d\n",
              sum(!is.na(imp$v2_status) | !is.na(imp$baseline_status)), sum(is.finite(imp$baseline_ba_ha)), sum(is.finite(imp$v2_ba_ha)), sum(both)))
  cat(sprintf("moved (|delta| > 1e-9): %d of %d; type flips: %d; support changes: %d; UNEXPLAINED: %d\n",
              sum(both & abs(imp$delta_ba_ha) > 1e-9), sum(both), sum(imp$type_flip), sum(imp$support_change), sum(imp$reasons == "UNEXPLAINED")))
  q <- stats::quantile(abs(imp$pct_change[both]), c(0.5, 0.9, 1), na.rm = TRUE)
  cat(sprintf("abs %% change among both-finite: median %.2f, p90 %.2f, max %.2f (n=%d)\n", q[1], q[2], q[3], sum(both)))
  options(width = 260)
  print(imp[, c("site", "baseline_ba_ha", "v2_ba_ha", "delta_ba_ha", "pct_change", "baseline_type", "v2_type",
                "baseline_n_plots", "v2_n_plots", "held_record_plots", "absence_plots", "legacy_stems_outside_event", "legacy_stems_total",
                "stand_plots_area_differs", "v2_status", "reasons")], digits = 4, row.names = FALSE)
  cat("\nheld-state counts (latest event of held record plots, selected channel):\n")
  print(imp[nchar(imp$held_states) > 0, c("site", "v2_type", "held_states")], row.names = FALSE)
  # sensitivities vs primary
  for (vn in setdiff(names(VARIANTS), "primary")) {
    alt <- results[[paste(s$tag, vn, sep = "::")]]
    bothv <- is.finite(v2$veg_ba_ha) | is.finite(alt$veg_ba_ha)
    dd <- alt$veg_ba_ha - v2$veg_ba_ha
    flips <- sum(!is.na(v2$veg_type) & !is.na(alt$veg_type) & v2$veg_type != alt$veg_type)
    moved <- sum(is.finite(dd) & abs(dd) > 1e-9)
    cat(sprintf("\n-- sensitivity %s vs primary (%s): sites moved %d, type flips %d, finite primary %d, finite alt %d\n",
                vn, s$tag, moved, flips, sum(is.finite(v2$veg_ba_ha)), sum(is.finite(alt$veg_ba_ha))))
    sens <- data.frame(site = SITES, primary = v2$veg_ba_ha, alt = alt$veg_ba_ha, delta = dd,
                       pct = ifelse(is.finite(v2$veg_ba_ha) & v2$veg_ba_ha > 0, 100 * dd / v2$veg_ba_ha, NA_real_),
                       primary_n = v2$veg_n_plots, alt_n = alt$veg_n_plots, primary_type = v2$veg_type, alt_type = alt$veg_type)
    write.csv(sens, file.path(OUT, sprintf("sensitivity_%s_%s.csv", s$tag, vn)), row.names = FALSE)
    print(sens[is.finite(dd) & abs(dd) > 1e-9 | (!is.na(sens$primary_type) & !is.na(sens$alt_type) & sens$primary_type != sens$alt_type), ], digits = 4, row.names = FALSE)
  }
}
# decomposition between two v2 sources (rule effect vs later source refresh) when both are given
v2tags <- vapply(Filter(function(x) x$mode == "v2", SOURCES), function(x) x$tag, character(1))
if (length(v2tags) >= 2L) {
  a <- results[[paste(v2tags[1], "primary", sep = "::")]]; b <- results[[paste(v2tags[2], "primary", sep = "::")]]
  dd <- b$veg_ba_ha - a$veg_ba_ha
  cat(sprintf("\n== primary v2 on %s vs on %s: sites moved %d (|delta|>1e-9), type flips %d\n", v2tags[2], v2tags[1],
              sum(is.finite(dd) & abs(dd) > 1e-9), sum(!is.na(a$veg_type) & !is.na(b$veg_type) & a$veg_type != b$veg_type)))
  dec <- data.frame(site = SITES, v2_first = a$veg_ba_ha, v2_second = b$veg_ba_ha, delta = dd, first_n = a$veg_n_plots, second_n = b$veg_n_plots)
  write.csv(dec, file.path(OUT, sprintf("decomposition_%s_vs_%s.csv", v2tags[1], v2tags[2])), row.names = FALSE)
  print(dec[is.finite(dd) & abs(dd) > 1e-9, ], digits = 5, row.names = FALSE)
}
cat("\nDRY RUN COMPLETE. Wrote tables under:", OUT, "\n")
