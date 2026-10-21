# Focused fixtures for scripts/check_coverage_regression.R. Every bundle here is
# synthetic and built in memory; no real data is read.
#
# Boundary rule under test: a product drop refuses only when
# (baseline - candidate) * 10 > baseline. On a 1000 site-year baseline, 900
# (an exact 10% drop) passes and 899 (10.1%) refuses. Rises always pass.
#
# Each case runs the gate as a child `Rscript --vanilla` process so the exit
# status (0 pass, 1 refuse, 2 usage or malformed input) is tested exactly.
setwd_repo_root <- function() {
  if (file.exists("global.R")) return(invisible(normalizePath(".", winslash = "/")))
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg)) {
    script <- normalizePath(sub("^--file=", "", arg[1]), winslash = "/", mustWork = TRUE)
    root <- dirname(dirname(script))
    if (file.exists(file.path(root, "global.R"))) {
      setwd(root)
      return(invisible(root))
    }
  }
  stop("cannot locate repository root (global.R)", call. = FALSE)
}
ROOT <- setwd_repo_root()

ok <- function(label, detail = "OK") cat(sprintf("[PASS] %-55s %s\n", label, detail))
fail <- function(label, detail = "")
  stop(sprintf("[FAIL] %s%s", label, if (nzchar(detail)) paste0(": ", detail) else ""), call. = FALSE)
check <- function(value, label, detail = "") {
  if (!isTRUE(value)) fail(label, detail)
  ok(label, detail)
  invisible(TRUE)
}

GATE <- file.path(ROOT, "scripts", "check_coverage_regression.R")
RSCRIPT <- file.path(R.home("bin"), "Rscript")
WORK <- tempfile("coverage-gate-test-")
dir.create(WORK)

SITES <- vapply(0:49, function(i) paste0("S", LETTERS[i %/% 26 + 1L],
                                         LETTERS[(i %/% 2) %% 26 + 1L],
                                         LETTERS[i %% 26 + 1L]), character(1))
stopifnot(!anyDuplicated(SITES), all(grepl("^[A-Z]{4}$", SITES)))
YEARS <- 2006:2025
COMMITS <- c(mammal = strrep("1", 40), plant = strrep("2", 40), veg = strrep("3", 40),
             bird = strrep("4", 40), phe = strrep("5", 40), mosq = strrep("6", 40),
             beetle = strrep("7", 40))

make_bundle <- function() {
  annual <- expand.grid(year = YEARS, site = SITES, stringsAsFactors = FALSE)[, c("site", "year")]
  n <- nrow(annual)
  for (s in c("mammal_cpue", "plant_richness", "bird_index", "greenup_doy",
              "mosq_activity", "beetle_activity", "temp", "precip", "temp_spring"))
    annual[[s]] <- seq_len(n) / 7
  # Mosquito starts at 800 site-years (2006-2009 missing) so a rise is possible.
  annual$mosq_activity[annual$year <= 2009] <- NA_real_
  site_meta <- data.frame(
    site = SITES, veg_ba_ha = 20 + seq_along(SITES), veg_n_plots = 30L,
    veg_type = ifelse(seq_along(SITES) %% 2 == 1, "forest", "shrubland"),
    stringsAsFactors = FALSE)
  site_meta$veg_ba_ha[2] <- NA_real_
  site_meta$veg_n_plots[2] <- NA_integer_
  site_meta$veg_type[2] <- NA_character_
  list(annual = annual, signals = data.frame(), priors = data.frame(),
       codebook = data.frame(), suite_links = data.frame(), pooled = data.frame(),
       site_meta = site_meta,
       meta = list(source_products = data.frame(
         product = names(COMMITS), commit = unname(COMMITS), stringsAsFactors = FALSE)))
}
# Blank the first k finite values of a signal in year order, leaving the max year.
blank_rows <- function(b, signal, k) {
  idx <- which(is.finite(b$annual[[signal]]))
  idx <- idx[order(b$annual$year[idx], b$annual$site[idx])]
  b$annual[[signal]][idx[seq_len(k)]] <- NA_real_
  b
}

BASE <- file.path(WORK, "baseline.rds")
saveRDS(make_bundle(), BASE)
counter <- 0L
save_candidate <- function(b) {
  counter <<- counter + 1L
  path <- file.path(WORK, sprintf("candidate-%02d.rds", counter))
  saveRDS(b, path)
  path
}
write_overrides <- function(rows, header = c("product", "rule", "scope", "source_commit",
                                             "reason", "approved_by", "approved_on")) {
  counter <<- counter + 1L
  path <- file.path(WORK, sprintf("overrides-%02d.tsv", counter))
  writeLines(c(paste(header, collapse = "\t"),
               vapply(rows, paste, character(1), collapse = "\t")), path)
  path
}
run_gate <- function(...) {
  out <- suppressWarnings(system2(RSCRIPT, c("--vanilla", shQuote(GATE),
                                             vapply(c(...), shQuote, character(1))),
                                  stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  list(status = if (is.null(status)) 0L else as.integer(status), out = out)
}
has <- function(res, pattern) any(grepl(pattern, res$out, fixed = TRUE))
final_line <- function(res) {
  hits <- grep("^COVERAGE GATE: ", res$out, value = TRUE)
  if (length(hits)) hits[[length(hits)]] else ""
}

# ---- identical and rises -------------------------------------------------------
r <- run_gate(BASE, BASE)
check(r$status == 0L && final_line(r) == "COVERAGE GATE: PASS",
      "identical candidate passes", final_line(r))

b <- make_bundle(); b$annual$mosq_activity <- b$annual$temp
r <- run_gate(BASE, save_candidate(b))
check(r$status == 0L && has(r, "| mosq | mosq_activity | 800 -> 1000 |") && has(r, "| rise |"),
      "a 25% mosquito rise passes", final_line(r))

# ---- drops and the 10% boundary -------------------------------------------------
r <- run_gate(BASE, save_candidate(blank_rows(make_bundle(), "mosq_activity", 96L)))
check(r$status == 1L && has(r, "800 -> 704") && has(r, "REFUSE: site_years") &&
        final_line(r) == "COVERAGE GATE: REFUSE (1 rule(s))",
      "a 12% mosquito drop refuses", final_line(r))

r <- run_gate(BASE, save_candidate(blank_rows(make_bundle(), "bird_index", 100L)))
check(r$status == 0L && has(r, "1000 -> 900") && has(r, "drop within tolerance"),
      "an exact 10% drop passes", final_line(r))

r <- run_gate(BASE, save_candidate(blank_rows(make_bundle(), "bird_index", 101L)))
check(r$status == 1L && has(r, "1000 -> 899") && has(r, "REFUSE: site_years"),
      "a 10.1% drop refuses", final_line(r))

b <- make_bundle(); b$annual$plant_richness[b$annual$site %in% SITES[1:6]] <- NA_real_
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "50 -> 44") && has(r, "REFUSE: site_years, n_sites"),
      "a 12% site drop refuses on n_sites", final_line(r))

b <- make_bundle(); b$annual$bird_index[b$annual$year == 2025] <- NA_real_
BIRD_BACK <- save_candidate(b)
r <- run_gate(BASE, BIRD_BACK)
check(r$status == 1L && has(r, "2025 -> 2024") && has(r, "REFUSE: max_year") &&
        final_line(r) == "COVERAGE GATE: REFUSE (1 rule(s))",
      "bird max year 2025 -> 2024 refuses", final_line(r))

b <- make_bundle(); b$annual$beetle_activity <- NA_real_
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "REFUSE: product_absent") && has(r, "1000 -> 0"),
      "product present -> absent refuses", final_line(r))

b <- make_bundle(); b$annual$temp_spring <- NULL
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "| climate | temp_spring | 1000 -> 0 |"),
      "a dropped climate column refuses as absent", final_line(r))

# ---- vegetation parity ------------------------------------------------------------
b <- make_bundle(); b$site_meta$veg_ba_ha[1] <- 21 * 0.84
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, sprintf("| %s |", SITES[1])) && has(r, "REFUSE: veg_ba_ha"),
      "veg_ba_ha drop over 15% refuses", final_line(r))

b <- make_bundle(); b$site_meta$veg_ba_ha[1] <- 21 * 0.86
r <- run_gate(BASE, save_candidate(b))
check(r$status == 0L && has(r, "within tolerance"),
      "veg_ba_ha move under 15% passes and is listed", final_line(r))

b <- make_bundle(); b$site_meta$veg_type[3] <- "shrubland"
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "forest -> shrubland") && has(r, "REFUSE: veg_type"),
      "veg_type flip refuses", final_line(r))

b <- make_bundle(); b$site_meta$veg_n_plots[4] <- 23L
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "REFUSE: veg_n_plots"),
      "veg_n_plots below 80% refuses", final_line(r))

b <- make_bundle(); b$site_meta$veg_n_plots[4] <- 24L
r <- run_gate(BASE, save_candidate(b))
check(r$status == 0L, "veg_n_plots at exactly 80% passes", final_line(r))

b <- make_bundle(); b$site_meta$veg_ba_ha[5] <- NA_real_
r <- run_gate(BASE, save_candidate(b))
check(r$status == 1L && has(r, "REFUSE: veg_absent") &&
        final_line(r) == "COVERAGE GATE: REFUSE (1 rule(s))",
      "veg site finite -> NA refuses once (veg_absent)", final_line(r))

b <- make_bundle()
b$site_meta$veg_ba_ha[2] <- 30; b$site_meta$veg_n_plots[2] <- 12L
b$site_meta$veg_type[2] <- "forest"
r <- run_gate(BASE, save_candidate(b))
check(r$status == 0L && has(r, "rise (NA -> finite)") && has(r, "| veg | veg_ba_ha | 49 -> 50 |"),
      "veg site NA -> finite passes as a rise", final_line(r))

# ---- overrides ------------------------------------------------------------------------
row <- function(product = "bird", rule = "max_year", scope = "*",
                commit = COMMITS[["bird"]], date = "2026-10-21")
  c(product, rule, scope, commit, "provisional 2025 bird year withdrawn upstream",
    "Tim", date)

r <- run_gate(BASE, BIRD_BACK, "--overrides", write_overrides(list(row())))
check(r$status == 0L && has(r, "max_year (overridden)") && has(r, "| applied |") &&
        final_line(r) == "COVERAGE GATE: PASS",
      "matching override bypasses exactly its rule", final_line(r))

b <- make_bundle(); b$annual$bird_index[b$annual$year == 2025] <- NA_real_
b <- blank_rows(b, "mosq_activity", 96L)
r <- run_gate(BASE, save_candidate(b), "--overrides", write_overrides(list(row())))
check(r$status == 1L && has(r, "max_year (overridden)") && has(r, "| mosq |") &&
        final_line(r) == "COVERAGE GATE: REFUSE (1 rule(s))",
      "override leaves other products' refusals standing", final_line(r))

r <- run_gate(BASE, BIRD_BACK, "--overrides",
              write_overrides(list(row(commit = strrep("a", 40)))))
check(r$status == 1L && has(r, "STALE") && final_line(r) == "COVERAGE GATE: REFUSE (1 rule(s))",
      "override for a different source_commit is stale", final_line(r))

r <- run_gate(BASE, BIRD_BACK, "--overrides",
              write_overrides(list(row(commit = COMMITS[["mosq"]]))))
check(r$status == 1L && has(r, "STALE"),
      "override keyed to another product's commit is stale", final_line(r))

r <- run_gate(BASE, BASE, "--overrides", write_overrides(list(row())))
check(r$status == 0L && has(r, "unused (no matching refusal)"),
      "an unmatched current override is reported unused", final_line(r))

b <- make_bundle(); b$site_meta$veg_type[3] <- "shrubland"
r <- run_gate(BASE, save_candidate(b), "--overrides", write_overrides(list(
  row("veg", "veg_type", SITES[3], COMMITS[["veg"]]))))
check(r$status == 0L && has(r, "veg_type (overridden)"),
      "veg override keyed to its site bypasses the flip", final_line(r))

r <- run_gate(BASE, BASE, "--overrides", file.path(ROOT, "data", "coverage-overrides.tsv"))
check(r$status == 0L && has(r, "No override rows."),
      "committed overrides file is header-only and valid", final_line(r))

# ---- malformed input -> exit 2 ---------------------------------------------------------
malformed <- list(
  "missing column" = write_overrides(list(row()[-7]),
                                     header = c("product", "rule", "scope", "source_commit",
                                                "reason", "approved_by")),
  "short commit" = write_overrides(list(row(commit = "abc123"))),
  "uppercase commit" = write_overrides(list(row(commit = toupper(strrep("ab", 20))))),
  "impossible date" = write_overrides(list(row(date = "2026-02-30"))),
  "unformatted date" = write_overrides(list(row(date = "10/21/2026"))),
  "unknown rule" = write_overrides(list(row(rule = "everything"))),
  "unknown product" = write_overrides(list(row(product = "fish"))),
  "veg rule with wildcard" = write_overrides(list(row("veg", "veg_type", "*", COMMITS[["veg"]]))),
  "product rule with site scope" = write_overrides(list(row(scope = SITES[1]))),
  "duplicate key" = write_overrides(list(row(), row())))
for (label in names(malformed)) {
  r <- run_gate(BASE, BIRD_BACK, "--overrides", malformed[[label]])
  check(r$status == 2L && has(r, "INPUT ERROR"), sprintf("malformed overrides (%s) exit 2", label))
}
r <- run_gate(BASE)
check(r$status == 2L, "missing candidate argument exits 2")
r <- run_gate(BASE, file.path(WORK, "absent.rds"))
check(r$status == 2L, "unreadable candidate exits 2")
r <- run_gate(BASE, BASE, "--bogus", "x")
check(r$status == 2L, "unknown option exits 2")
notbundle <- file.path(WORK, "notbundle.rds"); saveRDS(data.frame(x = 1), notbundle)
r <- run_gate(BASE, notbundle)
check(r$status == 2L, "a non-bundle RDS exits 2")

# ---- summary is appended, never truncated --------------------------------------------------
summary_path <- file.path(WORK, "summary.md")
writeLines("prior step output", summary_path)
r1 <- run_gate(BASE, BASE, "--summary", summary_path)
r2 <- run_gate(BASE, BIRD_BACK, "--summary", summary_path)
s <- readLines(summary_path)
s_final <- grep("^COVERAGE GATE: ", s, value = TRUE)
check(r1$status == 0L && r2$status == 1L && s[[1]] == "prior step output" &&
        identical(s_final, c("COVERAGE GATE: PASS", "COVERAGE GATE: REFUSE (1 rule(s))")),
      "summary file is appended with PASS then REFUSE")

unlink(WORK, recursive = TRUE)
cat("\nAll coverage-regression gate tests passed.\n")
