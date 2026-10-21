# Coverage-regression gate: compare a rebuilt candidate data/cascade.rds with
# the committed baseline BEFORE the candidate is staged for publication.
#
# Usage:
#   Rscript --vanilla scripts/check_coverage_regression.R <baseline.rds> <candidate.rds>
#     [--overrides <tsv>] [--summary <markdown path to append>]
#
# Exit status: 0 PASS, 1 REFUSE, 2 usage error or malformed input.
#
# This script deserializes RDS, so it belongs in the read-only build job only,
# never in the write-enabled publisher. It never edits, stages, or publishes.
#
# What is compared (base R only; no package dependencies):
#   Product rules, per product signal (mammal_cpue, plant_richness, bird_index,
#   greenup_doy, mosq_activity, beetle_activity), per climate signal (temp,
#   precip, temp_spring; product "climate"), and for the vegetation context
#   value site_meta$veg_ba_ha (product "veg"):
#     site_years      finite site-years (veg: finite sites) fell by MORE than 10%
#     n_sites         distinct sites with a finite value fell by MORE than 10%
#     max_year        the latest year with a finite value moved backward
#     product_absent  a signal that had any finite value now has none (this rule
#                     replaces the three above for that signal, so one loss is
#                     reported once)
#   Boundary rule: a drop is refused only when (baseline - candidate) * 10 >
#   baseline, in exact integer arithmetic. An exact 10% drop passes; 10.1%
#   refuses. Any rise, and any unchanged count, passes.
#
#   Vegetation parity rules, per site in site_meta (both sides finite unless said):
#     veg_ba_ha    |candidate - baseline| > 15% of |baseline| (either direction)
#     veg_n_plots  candidate < 80% of baseline (5 * candidate < 4 * baseline)
#     veg_type     a non-missing class changes, or goes missing
#     veg_absent   veg_ba_ha goes finite to NA (or the site leaves site_meta);
#                  replaces the other three rules for that site
#   A site going NA to finite is a rise and passes.
#
# Overrides (data/coverage-overrides.tsv, tab separated, header row required):
#   product        mammal, plant, bird, phe, mosq, beetle, climate, veg
#   rule           one of the eight rule names above
#   scope          "*" for the four product rules; a 4-letter site code for the
#                  four veg_* parity rules (those require product "veg")
#   baseline_value, candidate_value
#                  the exact transition being approved, copied from the gate's
#                  "Rule hits" table or override template. An absent value is
#                  written NA (product_absent and veg_absent have candidate NA).
#                  Value types by rule: site_years, n_sites, max_year,
#                  veg_n_plots, product_absent are integers and match exactly;
#                  veg_ba_ha and veg_absent are numbers and match within a
#                  relative tolerance of 1e-6 of the gate's value (rows are
#                  pasted from a printed report with up to 10 significant
#                  digits); veg_type is a string and matches exactly.
#   source_commit  40-hex commit of the product's sibling as recorded in the
#                  CANDIDATE's meta$source_products$commit (veg -> the
#                  vegetation commit; climate -> the mammal commit, because
#                  climate overlays ride in the mammal bundle)
#   reason, approved_by   non-empty
#   approved_on    YYYY-MM-DD, a real calendar date
# A refusal is bypassed only by a row whose product, rule, scope and
# source_commit all equal the refusal and the candidate exactly AND whose
# baseline_value and candidate_value equal the refused transition. A row whose
# source_commit differs from the candidate, or whose key matches but whose
# values differ (for example after an adapter change on the same sibling
# commit), is STALE and bypasses nothing, so an approval is single-use: it
# covers only the transition a reviewer saw. Any malformed row (including an
# empty or unparsable value for a numeric rule), a missing or unknown column,
# or a duplicate row is exit 2.

GATE_SIGNALS <- data.frame(
  product = c("mammal", "plant", "bird", "phe", "mosq", "beetle",
              "climate", "climate", "climate", "veg"),
  signal = c("mammal_cpue", "plant_richness", "bird_index", "greenup_doy",
             "mosq_activity", "beetle_activity", "temp", "precip",
             "temp_spring", "veg_ba_ha"),
  stringsAsFactors = FALSE)
# Which meta$source_products row carries the commit an override is keyed to.
COMMIT_SOURCE <- c(mammal = "mammal", plant = "plant", bird = "bird",
                   phe = "phe", mosq = "mosq", beetle = "beetle",
                   climate = "mammal", veg = "veg")
PRODUCT_RULES <- c("site_years", "n_sites", "max_year", "product_absent")
VEG_RULES <- c("veg_ba_ha", "veg_n_plots", "veg_type", "veg_absent")
OVERRIDE_COLUMNS <- c("product", "rule", "scope", "baseline_value",
                      "candidate_value", "source_commit", "reason",
                      "approved_by", "approved_on")
INTEGER_VALUE_RULES <- c("site_years", "n_sites", "max_year", "veg_n_plots",
                         "product_absent")
NUMERIC_VALUE_RULES <- c("veg_ba_ha", "veg_absent")
STRING_VALUE_RULES <- "veg_type"
VALUE_REL_TOLERANCE <- 1e-6

# Paste-ready rendering: NA, integers in full, other numbers to 10 significant
# digits without scientific notation, strings as is.
fmt_value <- function(x) {
  if (length(x) != 1L || is.na(x)) return("NA")
  if (is.character(x)) return(x)
  if (x == round(x) && abs(x) < 1e15) return(format(x, scientific = FALSE, trim = TRUE))
  format(signif(x, 10), digits = 10, scientific = FALSE, trim = TRUE)
}
# Parse one override value field for a rule; returns list(ok, value).
parse_value <- function(rule, text) {
  if (identical(text, "NA"))
    return(list(ok = TRUE, value = if (rule %in% STRING_VALUE_RULES) NA_character_ else NA_real_))
  if (!nzchar(text)) return(list(ok = FALSE))
  if (rule %in% INTEGER_VALUE_RULES) {
    if (!grepl("^-?[0-9]+$", text)) return(list(ok = FALSE))
    return(list(ok = TRUE, value = as.numeric(text)))
  }
  if (rule %in% NUMERIC_VALUE_RULES) {
    v <- suppressWarnings(as.numeric(text))
    if (!grepl("^-?([0-9]+[.]?[0-9]*|[.][0-9]+)([eE][-+]?[0-9]+)?$", text) || !is.finite(v))
      return(list(ok = FALSE))
    return(list(ok = TRUE, value = v))
  }
  list(ok = TRUE, value = text)
}
value_matches <- function(rule, row_value, gate_value) {
  if (is.na(row_value) || is.na(gate_value)) return(is.na(row_value) && is.na(gate_value))
  if (rule %in% STRING_VALUE_RULES) return(identical(row_value, as.character(gate_value)))
  if (rule %in% NUMERIC_VALUE_RULES)
    return(abs(row_value - gate_value) <= VALUE_REL_TOLERANCE * abs(gate_value))
  row_value == gate_value
}
DROP_TOLERANCE_TENTHS <- 1L  # 10%: refuse when (base - cand) * 10 > base
VEG_BA_TOLERANCE <- 0.15
VEG_PLOTS_FLOOR <- c(num = 4L, den = 5L)  # refuse when cand * 5 < base * 4

gate_input_error <- function(fmt, ...)
  stop(structure(class = c("gate_input_error", "error", "condition"),
                 list(message = sprintf(fmt, ...), call = NULL)))

parse_gate_args <- function(args) {
  usage <- paste("usage: check_coverage_regression.R <baseline.rds> <candidate.rds>",
                 "[--overrides <tsv>] [--summary <markdown path>]")
  positional <- character()
  overrides <- NA_character_
  summary <- NA_character_
  i <- 1L
  while (i <= length(args)) {
    a <- args[[i]]
    if (a %in% c("--overrides", "--summary")) {
      if (i == length(args) || !nzchar(args[[i + 1L]]))
        gate_input_error("%s needs a path. %s", a, usage)
      if (a == "--overrides") overrides <- args[[i + 1L]] else summary <- args[[i + 1L]]
      i <- i + 2L
    } else if (startsWith(a, "--")) {
      gate_input_error("unknown option %s. %s", a, usage)
    } else {
      positional <- c(positional, a)
      i <- i + 1L
    }
  }
  if (length(positional) != 2L) gate_input_error("%s", usage)
  list(baseline = positional[[1]], candidate = positional[[2]],
       overrides = overrides, summary = summary)
}

read_bundle <- function(path, label) {
  if (!file.exists(path) || dir.exists(path))
    gate_input_error("%s bundle not found: %s", label, path)
  x <- tryCatch(readRDS(path), error = function(e)
    gate_input_error("%s bundle is not a readable RDS (%s): %s", label,
                     conditionMessage(e), path))
  if (!is.list(x) || is.data.frame(x))
    gate_input_error("%s bundle is not a cascade bundle list: %s", label, path)
  if (!is.data.frame(x$annual) || !all(c("site", "year") %in% names(x$annual)))
    gate_input_error("%s bundle has no annual table with site and year", label)
  if (!is.data.frame(x$site_meta) || !("site" %in% names(x$site_meta)))
    gate_input_error("%s bundle has no site_meta table with site", label)
  if (anyNA(x$site_meta$site) || anyDuplicated(x$site_meta$site))
    gate_input_error("%s site_meta has missing or duplicated site codes", label)
  sp <- x$meta$source_products
  if (!is.data.frame(sp) || !all(c("product", "commit") %in% names(sp)) ||
      anyDuplicated(sp$product))
    gate_input_error("%s bundle has no usable meta$source_products", label)
  x
}

signal_coverage <- function(bundle, product, signal) {
  if (product == "veg") {
    sm <- bundle$site_meta
    v <- if (signal %in% names(sm)) suppressWarnings(as.numeric(sm[[signal]])) else
      rep(NA_real_, nrow(sm))
    ok <- is.finite(v)
    n <- sum(ok)
    return(list(site_years = n, n_sites = length(unique(sm$site[ok])),
                max_year = NA_integer_))
  }
  an <- bundle$annual
  v <- if (signal %in% names(an)) suppressWarnings(as.numeric(an[[signal]])) else
    rep(NA_real_, nrow(an))
  ok <- is.finite(v)
  yrs <- suppressWarnings(as.integer(an$year[ok]))
  list(site_years = sum(ok), n_sites = length(unique(an$site[ok])),
       max_year = if (any(ok)) max(yrs, na.rm = TRUE) else NA_integer_)
}

# TRUE when the drop from base to cand exceeds the tolerance (exact integers).
drop_exceeds <- function(base, cand)
  (base - cand) * 10 > base * DROP_TOLERANCE_TENTHS

compare_products <- function(base, cand) {
  rows <- list()
  refusals <- list()
  for (k in seq_len(nrow(GATE_SIGNALS))) {
    p <- GATE_SIGNALS$product[[k]]
    s <- GATE_SIGNALS$signal[[k]]
    b <- signal_coverage(base, p, s)
    c <- signal_coverage(cand, p, s)
    hit <- character()
    if (b$site_years > 0 && c$site_years == 0) {
      hit <- "product_absent"
      refusals[[length(refusals) + 1L]] <- list(
        product = p, rule = "product_absent", scope = "*", signal = s,
        base_val = b$site_years, cand_val = NA_real_)
    } else {
      if (drop_exceeds(b$site_years, c$site_years)) {
        hit <- c(hit, "site_years")
        refusals[[length(refusals) + 1L]] <- list(
          product = p, rule = "site_years", scope = "*", signal = s,
          base_val = b$site_years, cand_val = c$site_years)
      }
      if (drop_exceeds(b$n_sites, c$n_sites)) {
        hit <- c(hit, "n_sites")
        refusals[[length(refusals) + 1L]] <- list(
          product = p, rule = "n_sites", scope = "*", signal = s,
          base_val = b$n_sites, cand_val = c$n_sites)
      }
      if (!is.na(b$max_year) && !is.na(c$max_year) && c$max_year < b$max_year) {
        hit <- c(hit, "max_year")
        refusals[[length(refusals) + 1L]] <- list(
          product = p, rule = "max_year", scope = "*", signal = s,
          base_val = b$max_year, cand_val = c$max_year)
      }
    }
    trend <- if (length(hit)) "refuse" else if (
      c$site_years > b$site_years || c$n_sites > b$n_sites ||
      (!is.na(c$max_year) && (is.na(b$max_year) || c$max_year > b$max_year))) "rise" else if (
      c$site_years == b$site_years && c$n_sites == b$n_sites) "unchanged" else
      "drop within tolerance"
    rows[[k]] <- data.frame(
      product = p, signal = s, base_site_years = b$site_years,
      cand_site_years = c$site_years, base_sites = b$n_sites, cand_sites = c$n_sites,
      base_max_year = b$max_year, cand_max_year = c$max_year,
      rules = paste(hit, collapse = ","), trend = trend, stringsAsFactors = FALSE)
  }
  list(table = do.call(rbind, rows), refusals = refusals)
}

veg_frame <- function(bundle) {
  sm <- bundle$site_meta
  col <- function(name, fn) if (name %in% names(sm)) fn(sm[[name]]) else
    fn(rep(NA, nrow(sm)))
  data.frame(site = as.character(sm$site),
             ba = col("veg_ba_ha", function(x) suppressWarnings(as.numeric(x))),
             plots = col("veg_n_plots", function(x) suppressWarnings(as.numeric(x))),
             type = col("veg_type", function(x) {
               x <- as.character(x)
               x[!is.na(x) & !nzchar(x)] <- NA_character_
               x
             }), stringsAsFactors = FALSE)
}

compare_veg <- function(base, cand) {
  b <- veg_frame(base)
  c <- veg_frame(cand)
  m <- merge(b, c, by = "site", all = TRUE, suffixes = c("_b", "_c"), sort = TRUE)
  refusals <- list()
  m$rules <- ""
  add <- function(i, rule, field_b, field_c) {
    refusals[[length(refusals) + 1L]] <<- list(
      product = "veg", rule = rule, scope = m$site[[i]], signal = rule,
      base_val = field_b, cand_val = field_c)
    m$rules[[i]] <<- paste(c(if (nzchar(m$rules[[i]])) m$rules[[i]], rule), collapse = ",")
  }
  for (i in seq_len(nrow(m))) {
    if (is.finite(m$ba_b[[i]]) && !is.finite(m$ba_c[[i]])) {
      add(i, "veg_absent", m$ba_b[[i]], m$ba_c[[i]])
      next
    }
    if (is.finite(m$ba_b[[i]]) && is.finite(m$ba_c[[i]]) &&
        abs(m$ba_c[[i]] - m$ba_b[[i]]) > VEG_BA_TOLERANCE * abs(m$ba_b[[i]]))
      add(i, "veg_ba_ha", m$ba_b[[i]], m$ba_c[[i]])
    if (is.finite(m$plots_b[[i]]) &&
        (!is.finite(m$plots_c[[i]]) ||
         m$plots_c[[i]] * VEG_PLOTS_FLOOR[["den"]] < m$plots_b[[i]] * VEG_PLOTS_FLOOR[["num"]]))
      add(i, "veg_n_plots", m$plots_b[[i]], m$plots_c[[i]])
    if (!is.na(m$type_b[[i]]) && !identical(m$type_b[[i]], m$type_c[[i]]))
      add(i, "veg_type", m$type_b[[i]], m$type_c[[i]])
  }
  same_num <- function(x, y) (is.na(x) & is.na(y)) |
    (!is.na(x) & !is.na(y) & abs(x - y) <= 1e-9 * pmax(1, abs(x)))
  same_chr <- function(x, y) (is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & x == y)
  moved <- !(same_num(m$ba_b, m$ba_c) & same_num(m$plots_b, m$plots_c) &
               same_chr(m$type_b, m$type_c))
  list(table = m[moved, , drop = FALSE], refusals = refusals)
}

read_overrides <- function(path) {
  empty <- as.data.frame(stats::setNames(
    replicate(length(OVERRIDE_COLUMNS), character(), simplify = FALSE),
    OVERRIDE_COLUMNS), stringsAsFactors = FALSE)
  if (is.na(path)) return(empty)
  if (!file.exists(path) || dir.exists(path))
    gate_input_error("overrides file not found: %s", path)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- sub("\r$", "", lines)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) gate_input_error("overrides file has no header row: %s", path)
  split <- strsplit(lines, "\t", fixed = TRUE)
  header <- split[[1]]
  if (!identical(header, OVERRIDE_COLUMNS))
    gate_input_error("overrides header must be exactly: %s (got: %s)",
                     paste(OVERRIDE_COLUMNS, collapse = " "), paste(header, collapse = " "))
  body <- split[-1]
  if (!length(body)) return(empty)
  widths <- lengths(body)
  if (any(widths != length(OVERRIDE_COLUMNS)))
    gate_input_error("overrides row(s) %s do not have %d tab-separated fields",
                     paste(which(widths != length(OVERRIDE_COLUMNS)) + 1L, collapse = ", "),
                     length(OVERRIDE_COLUMNS))
  ov <- as.data.frame(do.call(rbind, body), stringsAsFactors = FALSE)
  names(ov) <- OVERRIDE_COLUMNS
  ov[] <- lapply(ov, trimws)
  for (i in seq_len(nrow(ov))) {
    r <- ov[i, ]
    where <- sprintf("overrides row %d", i + 1L)
    if (!(r$product %in% names(COMMIT_SOURCE)))
      gate_input_error("%s: unknown product '%s'", where, r$product)
    if (!(r$rule %in% c(PRODUCT_RULES, VEG_RULES)))
      gate_input_error("%s: unknown rule '%s'", where, r$rule)
    if (r$rule %in% VEG_RULES) {
      if (r$product != "veg")
        gate_input_error("%s: rule %s needs product veg", where, r$rule)
      if (!grepl("^[A-Z]{4}$", r$scope))
        gate_input_error("%s: rule %s needs a 4-letter site scope, got '%s'",
                         where, r$rule, r$scope)
    } else if (r$scope != "*") {
      gate_input_error("%s: product rule %s needs scope '*', got '%s'",
                       where, r$rule, r$scope)
    }
    if (!grepl("^[0-9a-f]{40}$", r$source_commit))
      gate_input_error("%s: source_commit must be 40 lowercase hex, got '%s'",
                       where, r$source_commit)
    d <- if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", r$approved_on))
      as.Date(r$approved_on, format = "%Y-%m-%d") else as.Date(NA)
    if (is.na(d) || format(d, "%Y-%m-%d") != r$approved_on)
      gate_input_error("%s: approved_on must be a real YYYY-MM-DD date, got '%s'",
                       where, r$approved_on)
    if (!nzchar(r$reason) || !nzchar(r$approved_by))
      gate_input_error("%s: reason and approved_by must be non-empty", where)
    for (field in c("baseline_value", "candidate_value"))
      if (!parse_value(r$rule, r[[field]])$ok)
        gate_input_error("%s: %s '%s' is not a valid %s value for rule %s (write NA for absent)",
                         where, field, r[[field]],
                         if (r$rule %in% INTEGER_VALUE_RULES) "integer" else
                           if (r$rule %in% NUMERIC_VALUE_RULES) "numeric" else "string",
                         r$rule)
  }
  key <- paste(ov$product, ov$rule, ov$scope, ov$baseline_value, ov$candidate_value,
               ov$source_commit, sep = "|")
  if (anyDuplicated(key))
    gate_input_error("overrides file repeats a row (same key, values and source_commit)")
  ov
}

candidate_commit <- function(cand, product) {
  sp <- cand$meta$source_products
  hit <- sp$commit[sp$product == COMMIT_SOURCE[[product]]]
  if (length(hit) != 1L || is.na(hit)) NA_character_ else as.character(hit)
}

md_escape <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)
md_table <- function(header, rows) {
  if (!length(rows)) return(character())
  c(paste0("| ", paste(header, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(header)), collapse = "|"), "|"),
    vapply(rows, function(r) paste0("| ", paste(md_escape(r), collapse = " | "), " |"),
           character(1)))
}

run_gate <- function(args) {
  opt <- parse_gate_args(args)
  base <- read_bundle(opt$baseline, "baseline")
  cand <- read_bundle(opt$candidate, "candidate")
  ov <- read_overrides(opt$overrides)

  prod <- compare_products(base, cand)
  veg <- compare_veg(base, cand)
  refusals <- c(prod$refusals, veg$refusals)

  cand_commit <- vapply(names(COMMIT_SOURCE), function(p) candidate_commit(cand, p),
                        character(1))
  ov$status <- if (nrow(ov)) {
    cc <- unname(cand_commit[ov$product])
    ifelse(!is.na(cc) & ov$source_commit == cc, "unused", "stale")
  } else character()
  ov$detail <- rep("", nrow(ov))
  bypassed <- logical(length(refusals))
  for (i in seq_len(nrow(ov))) {
    if (ov$status[i] == "stale") next
    same_key <- which(vapply(refusals, function(r)
      r$product == ov$product[i] && r$rule == ov$rule[i] && r$scope == ov$scope[i],
      logical(1)))
    if (!length(same_key)) next
    bv <- parse_value(ov$rule[i], ov$baseline_value[i])$value
    cv <- parse_value(ov$rule[i], ov$candidate_value[i])$value
    hit <- same_key[vapply(refusals[same_key], function(r)
      value_matches(ov$rule[i], bv, r$base_val) && value_matches(ov$rule[i], cv, r$cand_val),
      logical(1))]
    if (length(hit)) {
      bypassed[hit] <- TRUE
      ov$status[i] <- "applied"
    } else {
      ov$status[i] <- "stale_values"
      ov$detail[i] <- paste(vapply(refusals[same_key], function(r)
        sprintf("row %s -> %s, gate %s -> %s", ov$baseline_value[i], ov$candidate_value[i],
                fmt_value(r$base_val), fmt_value(r$cand_val)), character(1)),
        collapse = "; ")
    }
  }
  open <- refusals[!bypassed]

  # ---- Markdown report ----
  out <- c("## Coverage-regression gate", "",
           sprintf("Baseline `%s` against candidate `%s`.",
                   basename(opt$baseline), basename(opt$candidate)),
           "Drops of more than 10% in finite site-years or sites, a backward max year, or a lost product refuse; rises pass.", "")
  fmt_year <- function(y) if (is.na(y)) "n/a" else as.character(y)
  verdict_for <- function(product, rules, trend) {
    if (!nzchar(rules)) return(trend)
    parts <- strsplit(rules, ",", fixed = TRUE)[[1]]
    labs <- vapply(parts, function(rule) {
      done <- any(vapply(seq_along(refusals), function(j)
        bypassed[[j]] && refusals[[j]]$product == product && refusals[[j]]$rule == rule,
        logical(1)))
      if (done) paste0(rule, " (overridden)") else rule
    }, character(1))
    if (all(grepl("overridden", labs))) paste("PASS by override:", paste(labs, collapse = ", "))
    else paste("REFUSE:", paste(labs, collapse = ", "))
  }
  t <- prod$table
  out <- c(out, "### Product coverage", "",
           md_table(c("product", "signal", "site-years (base -> cand)",
                      "sites (base -> cand)", "max year (base -> cand)", "verdict"),
                    lapply(seq_len(nrow(t)), function(i) c(
                      t$product[i], t$signal[i],
                      sprintf("%d -> %d", t$base_site_years[i], t$cand_site_years[i]),
                      sprintf("%d -> %d", t$base_sites[i], t$cand_sites[i]),
                      sprintf("%s -> %s", fmt_year(t$base_max_year[i]), fmt_year(t$cand_max_year[i])),
                      verdict_for(t$product[i], t$rules[i], t$trend[i])))), "")
  out <- c(out, "### Vegetation parity (sites that moved)", "")
  vt <- veg$table
  if (!nrow(vt)) {
    out <- c(out, "No site's veg_ba_ha, veg_n_plots, or veg_type moved.", "")
  } else {
    f <- function(x) if (is.na(x)) "NA" else if (is.numeric(x)) format(round(x, 3)) else x
    out <- c(out, md_table(
      c("site", "veg_ba_ha (base -> cand)", "veg_n_plots", "veg_type", "verdict"),
      lapply(seq_len(nrow(vt)), function(i) {
        rules <- vt$rules[i]
        v <- if (!nzchar(rules)) {
          if (!is.finite(vt$ba_b[i]) && is.finite(vt$ba_c[i])) "rise (NA -> finite)" else "within tolerance"
        } else {
          parts <- strsplit(rules, ",", fixed = TRUE)[[1]]
          labs <- vapply(parts, function(rule) {
            done <- any(vapply(seq_along(refusals), function(j)
              bypassed[[j]] && refusals[[j]]$rule == rule && refusals[[j]]$scope == vt$site[i],
              logical(1)))
            if (done) paste0(rule, " (overridden)") else rule
          }, character(1))
          if (all(grepl("overridden", labs))) paste("PASS by override:", paste(labs, collapse = ", "))
          else paste("REFUSE:", paste(labs, collapse = ", "))
        }
        c(vt$site[i], sprintf("%s -> %s", f(vt$ba_b[i]), f(vt$ba_c[i])),
          sprintf("%s -> %s", f(vt$plots_b[i]), f(vt$plots_c[i])),
          sprintf("%s -> %s", f(vt$type_b[i]), f(vt$type_c[i])), v)
      })), "")
  }
  if (length(refusals)) {
    out <- c(out, "### Rule hits", "", md_table(
      c("product", "scope", "signal", "rule", "baseline", "candidate", "status"),
      lapply(seq_along(refusals), function(j) {
        r <- refusals[[j]]
        c(r$product, r$scope, r$signal, r$rule, fmt_value(r$base_val), fmt_value(r$cand_val),
          if (bypassed[[j]]) "overridden" else "REFUSE")
      })), "")
  }
  if (length(open)) {
    out <- c(out, "### Override template (only if a reviewer approves this exact transition)", "",
             "```", paste(OVERRIDE_COLUMNS, collapse = "\t"),
             vapply(open, function(r) paste(
               r$product, r$rule, r$scope, fmt_value(r$base_val), fmt_value(r$cand_val),
               cand_commit[[r$product]], "<reason>", "<approved_by>", "<YYYY-MM-DD>",
               sep = "\t"), character(1)), "```", "")
  }
  out <- c(out, "### Overrides", "")
  if (!nrow(ov)) {
    out <- c(out, "No override rows.", "")
  } else {
    out <- c(out, md_table(
      c("product", "rule", "scope", "baseline -> candidate", "source_commit",
        "candidate commit", "status", "approved_by", "approved_on", "reason"),
      lapply(seq_len(nrow(ov)), function(i) c(
        ov$product[i], ov$rule[i], ov$scope[i],
        sprintf("%s -> %s", ov$baseline_value[i], ov$candidate_value[i]),
        substr(ov$source_commit[i], 1, 12),
        substr(cand_commit[[ov$product[i]]], 1, 12),
        switch(ov$status[i], applied = "applied",
               stale = "STALE (commit differs from candidate; bypasses nothing)",
               stale_values = sprintf("STALE (values differ: %s; bypasses nothing)", ov$detail[i]),
               unused = "unused (no matching refusal)"),
        ov$approved_by[i], ov$approved_on[i], ov$reason[i]))), "")
  }
  sp_b <- base$meta$source_products
  sp_c <- cand$meta$source_products
  out <- c(out, "### Source commits", "", md_table(
    c("product", "baseline", "candidate"),
    lapply(sp_c$product, function(p) c(
      p, substr(c(sp_b$commit[sp_b$product == p], "none")[1], 1, 12),
      substr(sp_c$commit[sp_c$product == p], 1, 12)))), "")
  final <- if (length(open)) sprintf("COVERAGE GATE: REFUSE (%d rule(s))", length(open)) else
    "COVERAGE GATE: PASS"
  out <- c(out, final, "")
  writeLines(out)
  if (!is.na(opt$summary)) {
    con <- file(opt$summary, open = "a", encoding = "UTF-8")
    on.exit(close(con), add = TRUE)
    writeLines(out, con)
  }
  if (length(open)) 1L else 0L
}

status <- tryCatch(
  run_gate(commandArgs(trailingOnly = TRUE)),
  gate_input_error = function(e) {
    message("COVERAGE GATE: INPUT ERROR: ", conditionMessage(e))
    2L
  },
  error = function(e) {
    message("COVERAGE GATE: INPUT ERROR (unexpected): ", conditionMessage(e))
    2L
  })
quit(save = "no", status = status)
