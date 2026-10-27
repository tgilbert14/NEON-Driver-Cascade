# ===========================================================================
# DRY RUN ONLY. Not a build step, not an artifact writer, not on the deploy
# surface (scripts/manifest_files.R DEPLOY_APP_FILES), and not one of the six
# LOCAL_BUILD_INPUT_PATHS hashed into cascade_meta. Running it changes no byte
# under data/ and never touches manifest.json.
#
# Small Mammal bundle schema 2 (sibling PR #101): measures the month-adjusted
# mammal_cpue index through the production adapter in R/source_adapters.R.
#   (a) parity: the pinned schema-1 checkout through cascade_mammal_annual()
#       must reproduce every mammal column of the committed data/cascade.rds
#       annual table exactly, over its min_year to last_complete_year range;
#   (b) impact: per site-year pooled CPUE, index, months, trap-nights and gate
#       for the schema-2 checkout, the SRER rows beside the sibling's reference
#       values, and finite mammal_cpue site-years per source.
# It writes one markdown report to <out.md> (docs/ in practice).
#
# Usage (from the repository root):
#   Rscript --vanilla scripts/dryrun_mammal_index.R <out.md> \
#     pinned=<checkout> main=<checkout> pr101=<checkout>
#
# <checkout> is a detached clone of github.com/tgilbert14/neon-small-mammal-
# tracker-app whose data/sites/*.rds are read. Nothing in the sibling checkout
# is sourced or executed; only `git rev-parse HEAD` is read from it.
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
if (length(args) != 4L)
  stop("usage: <out.md> pinned=<path> main=<path> pr101=<path>", call. = FALSE)
OUT <- args[1]
src <- setNames(sub("^[^=]+=", "", args[-1]), sub("=.*$", "", args[-1]))
if (!setequal(names(src), c("pinned", "main", "pr101")))
  stop("sources must be pinned=, main= and pr101=", call. = FALSE)
for (p in src) if (!dir.exists(file.path(p, "data", "sites")))
  stop(sprintf("no data/sites under %s", p), call. = FALSE)
commit_of <- function(p) {
  out <- tryCatch(system2(Sys.which("git"), c("-C", shQuote(p), "rev-parse", "HEAD"),
                          stdout = TRUE, stderr = FALSE), error = function(e) NA_character_)
  if (length(out)) out[1] else NA_character_
}
COMMITS <- vapply(src, commit_of, character(1))

# ---- baseline: the committed artifact (read-only) -------------------------
cascade <- readRDS("data/cascade.rds")
MIN_YEAR <- as.integer(cascade$meta$min_year)
LAST_YEAR <- as.integer(cascade$meta$last_complete_year)
SITES <- sort(unique(cascade$annual$site))
MAMMAL_COLS <- c("mammal_cpue", "mammal_mnka", "mammal_trap_nights", "mammal_captures",
                 "mammal_placeholder_trap_rows", "mammal_multi_capture_trap_events",
                 "mammal_reviewed_double_trap_events")
sp <- cascade$meta$source_products
committed_pin <- if (is.data.frame(sp) && "commit" %in% names(sp))
  sp$commit[sp$product == "mammal"] else NA_character_
cat(sprintf("committed family: %d sites, years %d to %d, mammal pin %s\n",
            length(SITES), MIN_YEAR, LAST_YEAR, committed_pin))

read_bundle <- function(path, site) {
  f <- file.path(path, "data", "sites", paste0(site, ".rds"))
  if (!file.exists(f)) return(NULL)
  readRDS(f)
}
in_window <- function(x) x[x$year >= MIN_YEAR & x$year <= LAST_YEAR, , drop = FALSE]

# Every site through the production adapter for one checkout. Returns the
# resolved shape, the annual rows under that shape, the schema1 (pooled) rows
# and, under schema2, the month-index diagnostics. Climatology uses every
# bundle year, as the builder does; only the reported rows are windowed.
run_source <- function(path) {
  bundles <- setNames(lapply(SITES, function(s) read_bundle(path, s)), SITES)
  shape <- cascade_mammal_resolve_shape(setNames(lapply(SITES, function(s)
    if (is.null(bundles[[s]])) NULL else cascade_mammal_bundle_shape(bundles[[s]], s)), SITES))
  per <- lapply(SITES, function(s) {
    d <- bundles[[s]]; if (is.null(d)) return(NULL)
    pooled <- cascade_mammal_annual(d, s, "schema1")
    out <- if (identical(shape, "schema2")) cascade_mammal_annual(d, s, "schema2") else pooled
    idx <- NULL
    if (identical(shape, "schema2")) {
      dd <- d
      dd$year <- suppressWarnings(as.integer(format(as.Date(dd$collectDate), "%Y")))
      dd <- dd[!is.na(dd$year), , drop = FALSE]
      ev <- cascade_mammal_effort_events(dd, dd$year, s)
      idx <- cascade_mammal_month_index(ev, dd, s)
      idx$site <- s
    }
    list(annual = out, pooled = pooled, idx = idx)
  })
  pick <- function(k) in_window(bind_rows(lapply(per, `[[`, k)))
  list(shape = shape, annual = pick("annual"), pooled = pick("pooled"),
       idx = if (identical(shape, "schema2")) pick("idx") else NULL)
}

res <- lapply(src, run_source)
for (k in names(res)) cat(sprintf("%s (%s): shape %s\n", k, COMMITS[[k]], res[[k]]$shape))

# ---- (a) parity: pinned schema1 against the committed annual table ---------
committed <- cascade$annual[, c("site", "year", MAMMAL_COLS)]
recomputed <- res$pinned$annual
key_c <- paste(committed$site, committed$year)
key_r <- paste(recomputed$site, recomputed$year)
orphans <- setdiff(key_r, key_c)
aligned <- recomputed[match(key_c, key_r), , drop = FALSE]
parity <- vapply(MAMMAL_COLS, function(col) {
  identical(committed[[col]], aligned[[col]])
}, logical(1))
parity_pass <- identical(res$pinned$shape, "schema1") && !length(orphans) && all(parity)
cat("\n(a) pinned schema1 parity against committed data/cascade.rds annual:\n")
cat(sprintf("  shape schema1: %s; recomputed site-years absent from committed table: %d\n",
            identical(res$pinned$shape, "schema1"), length(orphans)))
for (col in MAMMAL_COLS) cat(sprintf("  %-38s %s\n", col, if (parity[[col]]) "PASS" else "FAIL"))
cat(sprintf("  overall: %s\n", if (parity_pass) "PASS" else "FAIL"))

# ---- (b) schema2 impact -----------------------------------------------------
idx <- res$pr101$idx
pooled101 <- res$pr101$pooled
tab <- merge(pooled101[, c("site", "year", "mammal_cpue", "mammal_trap_nights")],
             idx[, c("site", "year", "index", "n_months", "trap_nights", "ok")],
             by = c("site", "year"), all.x = TRUE)
names(tab)[names(tab) == "mammal_cpue"] <- "pooled_cpue"
tab <- tab[order(tab$site, tab$year), ]

srer_ref <- data.frame(
  year = c(2016L, 2017L, 2018L, 2019L, 2020L, 2021L, 2022L, 2023L, 2024L),
  ref_pooled = c(37.7, 65.9, 31.2, 35.1, NA, 40.5, 66.2, 37.9, 24.0),
  ref_index = c(-3.9, 21.1, -10.6, -4.2, NA, -4.2, 23.8, -3.9, -13.6))
srer <- merge(tab[tab$site == "SRER", ], srer_ref, by = "year", all = TRUE)
srer$diff_index <- round(srer$index, 1) - srer$ref_index
srer$diff_pooled <- round(srer$pooled_cpue, 1) - srer$ref_pooled
cat("\nSRER under schema2 beside the sibling's reference values:\n")
print(srer[, c("year", "pooled_cpue", "ref_pooled", "index", "ref_index", "diff_index",
               "n_months", "trap_nights", "ok")], row.names = FALSE, digits = 4)
max_diff <- max(abs(c(srer$index - srer$ref_index)[srer$ok %in% TRUE]), na.rm = TRUE)

finite_by_site <- function(x) tapply(is.finite(x$mammal_cpue), factor(x$site, levels = SITES), sum)
cov <- data.frame(
  site = SITES,
  pinned_s1 = as.integer(finite_by_site(res$pinned$annual)),
  main_s1 = as.integer(finite_by_site(res$main$annual)),
  pr101_pooled = as.integer(finite_by_site(pooled101)),
  pr101_s2 = as.integer(finite_by_site(res$pr101$annual)))
cov[is.na(cov)] <- 0L
drops <- tab[is.finite(tab$pooled_cpue) & !(tab$ok %in% TRUE), , drop = FALSE]
drop_reason <- ifelse(is.na(drops$n_months), "no trapped plot-month",
  paste0(ifelse(drops$n_months < CASCADE_MAMMAL_INDEX_MIN_MONTHS,
                sprintf("%d mo", drops$n_months), ""),
         ifelse(drops$n_months < CASCADE_MAMMAL_INDEX_MIN_MONTHS &
                  drops$trap_nights < CASCADE_MAMMAL_INDEX_MIN_TRAP_NIGHTS, ", ", ""),
         ifelse(drops$trap_nights < CASCADE_MAMMAL_INDEX_MIN_TRAP_NIGHTS,
                sprintf("%s TN", format(drops$trap_nights, trim = TRUE)), "")))
drop_text <- tapply(sprintf("%d (%s)", drops$year, drop_reason),
                    factor(drops$site, levels = SITES), paste, collapse = "; ")
cov$dropped_years <- ifelse(is.na(drop_text[cov$site]), "", drop_text[cov$site])
cat("\nfinite mammal_cpue site-years:\n")
print(cov[, 1:5], row.names = FALSE)
cat(sprintf("totals: pinned schema1 %d, main schema1 %d, #101 pooled %d, #101 schema2 %d\n",
            sum(cov$pinned_s1), sum(cov$main_s1), sum(cov$pr101_pooled), sum(cov$pr101_s2)))

# ---- markdown report ----------------------------------------------------------
fmt <- function(x, d = 1) ifelse(is.finite(x), formatC(x, format = "f", digits = d), "NA")
md_table <- function(df) {
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep(" --- ", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}
srer_md <- data.frame(
  year = srer$year, pooled = fmt(srer$pooled_cpue), sibling_pooled = fmt(srer$ref_pooled),
  index = fmt(srer$index), sibling_index = fmt(srer$ref_index),
  diff = fmt(srer$index - srer$ref_index, 2), months = ifelse(is.na(srer$n_months), "NA", srer$n_months),
  trap_nights = fmt(srer$trap_nights, 1), ok = ifelse(is.na(srer$ok), "NA", srer$ok))
cov_md <- cov
lost <- cov$site[cov$pr101_s2 < cov$main_s1]
lines <- c(
  "# Small Mammal schema 2: month-adjusted catch index dry run (2026-10-26)",
  "",
  "Produced by `scripts/dryrun_mammal_index.R`, which reads three Small Mammal checkouts",
  "from the command line through the production adapter in `R/source_adapters.R` and writes",
  "nothing under `data/`. Years are limited to the committed family's range",
  sprintf("(%d to %d); each site's monthly climatology uses every year its bundle carries, as the builder does.",
          MIN_YEAR, LAST_YEAR),
  "",
  "Sources:",
  "",
  sprintf("- pinned: `%s` (the committed Atlas family's mammal pin is `%s`), shape %s",
          COMMITS[["pinned"]], committed_pin, res$pinned$shape),
  sprintf("- main: `%s`, shape %s", COMMITS[["main"]], res$main$shape),
  sprintf("- PR #101 head: `%s`, shape %s", COMMITS[["pr101"]], res$pr101$shape),
  "",
  "Rulings applied (lead, M-1 to M-7): a bundle is schema2 when it carries all of",
  "`gridCompletion`, `samplingImpractical` and `eventID`, schema1 when it carries none; a",
  "partial bundle or a mixed set stops. Under schema2 `mammal_cpue` is the month-adjusted",
  "index: per plot-month (plotID by trap-night year-month) CPUE = 100 x tagged capture rows /",
  "resolved trap-nights over trapped plot-months, minus the site's unweighted mean CPUE for",
  "that calendar month, averaged unweighted within the year; it is published only when the",
  "year has 3 or more sampled calendar months and 300 or more trap-nights. Trap-nights,",
  "captures, MNKA and the audit columns stay pooled per year. Under schema1 every output is",
  "unchanged.",
  "",
  "## (a) Schema1 parity with the committed family",
  "",
  sprintf("Pinned bundles through `cascade_mammal_annual(..., \"schema1\")` against `data/cascade.rds` annual (%d site-year rows; %d recomputed site-years missing from it):",
          nrow(committed), length(orphans)),
  "",
  md_table(data.frame(column = MAMMAL_COLS, result = ifelse(parity, "PASS", "FAIL"))),
  "",
  sprintf("Overall: %s.", if (parity_pass) "PASS" else "FAIL"),
  "",
  "## (b) SRER under schema2 beside the sibling's values",
  "",
  md_table(srer_md),
  "",
  sprintf("Largest absolute index difference over the gated years: %s CPUE units (the sibling values are rounded to 0.1).",
          fmt(max_diff, 2)),
  "",
  "## Coverage: finite `mammal_cpue` site-years",
  "",
  sprintf("Totals: pinned schema1 %d, main schema1 %d, PR #101 pooled (same rows, schema1 rule) %d, PR #101 schema2 %d.",
          sum(cov$pinned_s1), sum(cov$main_s1), sum(cov$pr101_pooled), sum(cov$pr101_s2)),
  sprintf("%d of %d sites lose at least one year against main: %s.", length(lost), length(SITES),
          if (length(lost)) paste(lost, collapse = ", ") else "none"),
  "The coverage gate will see this drop at the first refresh that reads schema2 bundles.",
  "",
  "Per site (dropped years list the PR #101 site-years that have a pooled CPUE but fail the index gate, with the failing condition):",
  "",
  md_table(cov_md),
  "")
writeLines(lines, OUT, useBytes = TRUE)
cat(sprintf("\nreport written: %s\n", OUT))
if (!parity_pass) quit(status = 1L)
