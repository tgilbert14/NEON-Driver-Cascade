# Report-only: compare the freshly rebuilt annual table against the committed
# one and print every mosquito site-year whose effort, catch, or activity moved.
# It reads two artifacts and writes a Markdown summary; it never edits, stages,
# or publishes anything, and it never changes the exit status of a build.
#
# Usage: Rscript --vanilla scripts/report_mosq_effort_delta.R <baseline.rds> <rebuilt.rds> [out.md]

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L)
  stop("usage: report_mosq_effort_delta.R <baseline.rds> <rebuilt.rds> [out.md]", call. = FALSE)

read_annual <- function(path, label) {
  if (!file.exists(path)) stop(sprintf("%s artifact not found: %s", label, path), call. = FALSE)
  x <- readRDS(path)
  d <- if (is.data.frame(x)) x else x$annual
  if (!is.data.frame(d)) stop(sprintf("%s artifact has no annual table", label), call. = FALSE)
  d
}

FIELDS <- c("mosq_trap_nights", "mosq_total_catch", "mosq_activity")
base <- read_annual(args[1], "baseline")
new <- read_annual(args[2], "rebuilt")
out_path <- if (length(args) >= 3L) args[3] else ""

keep <- function(d) {
  missing <- setdiff(c("site", "year", FIELDS), names(d))
  if (length(missing))
    stop(sprintf("annual table lacks field(s): %s", paste(missing, collapse = ", ")), call. = FALSE)
  d[, c("site", "year", FIELDS), drop = FALSE]
}

m <- merge(keep(base), keep(new), by = c("site", "year"),
           all = TRUE, suffixes = c("_before", "_after"))

moved <- function(a, b) {
  both_na <- is.na(a) & is.na(b)
  changed <- !both_na & (is.na(a) != is.na(b) |
                           (!is.na(a) & !is.na(b) & abs(a - b) > 1e-12))
  changed
}

any_moved <- Reduce(`|`, lapply(FIELDS, function(f)
  moved(m[[paste0(f, "_before")]], m[[paste0(f, "_after")]])))
delta <- m[any_moved, , drop = FALSE]
delta <- delta[order(delta$site, delta$year), , drop = FALSE]

pct <- function(a, b) ifelse(is.na(a) | is.na(b) | a == 0, NA_real_, 100 * (b - a) / a)

lines <- c("## Mosquito effort-basis delta", "",
           sprintf("Baseline `%s` vs rebuilt `%s`.", args[1], args[2]), "",
           sprintf("- site-years compared: **%d**", nrow(m)),
           sprintf("- site-years with any mosquito field moved: **%d**", nrow(delta)))

if (nrow(delta)) {
  tn_pct <- pct(delta$mosq_trap_nights_before, delta$mosq_trap_nights_after)
  ac_pct <- pct(delta$mosq_activity_before, delta$mosq_activity_after)
  finite_or_na <- function(x) { x <- x[is.finite(x)]; if (!length(x)) NA_real_ else x }
  fmt <- function(x) if (all(is.na(x))) "n/a" else sprintf("%+.2f%%", x)
  tnf <- finite_or_na(tn_pct); acf <- finite_or_na(ac_pct)
  lines <- c(lines,
    sprintf("- trap-nights change: median %s, min %s, max %s",
            fmt(stats::median(tnf)), fmt(min(tnf)), fmt(max(tnf))),
    sprintf("- activity change: median %s, min %s, max %s",
            fmt(stats::median(acf)), fmt(min(acf)), fmt(max(acf))),
    sprintf("- site-years where trap-nights fell: **%d**; rose: **%d**",
            sum(!is.na(tn_pct) & tn_pct < 0), sum(!is.na(tn_pct) & tn_pct > 0)),
    "", "| site | year | trap-nights before | after | activity before | after |",
    "|---|---:|---:|---:|---:|---:|")
  show <- utils::head(delta, 40L)
  num <- function(x) ifelse(is.na(x), "NA", formatC(x, format = "fg", digits = 6))
  lines <- c(lines, sprintf("| %s | %d | %s | %s | %s | %s |",
    show$site, show$year,
    num(show$mosq_trap_nights_before), num(show$mosq_trap_nights_after),
    num(show$mosq_activity_before), num(show$mosq_activity_after)))
  if (nrow(delta) > 40L)
    lines <- c(lines, "", sprintf("_(showing the first 40 of %d moved site-years)_", nrow(delta)))
} else {
  lines <- c(lines, "", "No mosquito site-year changed.")
}

text <- paste(lines, collapse = "\n")
cat(text, "\n", sep = "")
if (nzchar(out_path)) cat(text, "\n", sep = "", file = out_path, append = TRUE)
