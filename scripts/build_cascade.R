# ===========================================================================
# NEON Driver Cascade — build_cascade.R
# Assemble a per-site ANNUAL signal table from the seven sibling bundles + the
# small-mammal env overlays. Reads existing .rds only — NO neonUtilities, so
# plain R-4.5.x runs it. Output: data/cascade.rds plus the generated codebook.
# Run from the NEON-Driver-Cascade dir.
# ===========================================================================
source("scripts/generation_guard.R", local = TRUE)
suppressPackageStartupMessages({ library(dplyr) })
# Canonical content inventory for every local file executed by this builder.
# generation_guard.R is included now because transactional generation sources it
# before any writer runs; the table is the artifact's executable-code lineage.
LOCAL_BUILD_INPUT_PATHS <- c(
  "scripts/build_cascade.R", "scripts/generation_guard.R",
  "scripts/source_snapshot.R", "R/cascade_helpers.R",
  "R/site_metadata.R", "R/source_adapters.R")
cascade_local_input_inventory <- function(paths) {
  if (any(!file.exists(paths)))
    stop(sprintf("local build input(s) missing: %s",
                 paste(paths[!file.exists(paths)], collapse = ", ")),
         call. = FALSE)
  data.frame(relative_path = paths, md5 = unname(tools::md5sum(paths)),
             stringsAsFactors = FALSE)
}
LOCAL_BUILD_INPUTS <- cascade_local_input_inventory(LOCAL_BUILD_INPUT_PATHS)
assert_local_build_inputs_unchanged <- function() {
  current <- cascade_local_input_inventory(LOCAL_BUILD_INPUT_PATHS)
  if (!identical(LOCAL_BUILD_INPUTS, current))
    stop("local executable build inputs changed during generation; discard and rerun scripts/rebuild_all.R",
         call. = FALSE)
  invisible(TRUE)
}
BUILD_SCRIPT_MD5 <- LOCAL_BUILD_INPUTS$md5[
  match("scripts/build_cascade.R", LOCAL_BUILD_INPUTS$relative_path)]
SOURCE_ADAPTERS_MD5 <- LOCAL_BUILD_INPUTS$md5[
  match("R/source_adapters.R", LOCAL_BUILD_INPUTS$relative_path)]

# helpers for the cross-site direct-pair precompute (eligibility-aware site_links + pooling) and the
# bundle/search schema constants; the builder must not carry a second version source.
eval(parse(file = "R/cascade_helpers.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)   # %||%, site_links(), pooled_links()
eval(parse(file = "R/site_metadata.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)     # neon_sites, biome_class(), biome_of(), biome_label()
eval(parse(file = "R/source_adapters.R", encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)   # reviewed local adapters; never execute sibling code
source("scripts/source_snapshot.R") # archive and verify exact recorded Git objects
assert_local_build_inputs_unchanged()
# Where the sibling repos live. Locally that's the VGS-R folder; in CI the refresh
# workflow clones each sibling into a workspace and sets CASCADE_ROOT to it. The
# dir names below must match the clone target dirs the workflow uses.
ROOT <- Sys.getenv("CASCADE_ROOT", unset = "")
if (!nzchar(ROOT))
  stop("CASCADE_ROOT is required. Set it to the directory containing all seven sibling repositories before rebuilding.",
       call. = FALSE)

# The retrospective analysis begins in 2013. Its upper bound is resolved only
# after immutable source provenance is known, so the same sibling commits cannot
# emit different artifacts merely because a calendar year rolled over.
MIN_YEAR <- 2013L
# Fail LOUD if the sibling-repo root is wrong: a silent bad ROOT makes every rd() return
# NULL and ships an EMPTY bundle with no error (the CI-killer). Better to stop here.
if (!dir.exists(ROOT))
  stop(sprintf("CASCADE_ROOT does not exist: '%s'. Set the CASCADE_ROOT env var to the folder that holds the sibling app repos.", ROOT), call. = FALSE)
APP  <- list(
  mammal = file.path(ROOT, "App-NEON-Small-Mammal-Tracker"),
  plant  = file.path(ROOT, "NEON-Plant-Diversity"),
  veg    = file.path(ROOT, "NEON-Veg-Structure"),
  bird   = file.path(ROOT, "NEON-Breeding-Birds"),
  phe    = file.path(ROOT, "NEON-Plant-Phenology"),
  mosq   = file.path(ROOT, "NEON-Mosquito-Pulse"),
  beetle = file.path(ROOT, "NEON-Ground-Beetle-Tracker"))
EXPECTED_ORIGINS <- c(
  mammal = "github.com/tgilbert14/neon-small-mammal-tracker-app",
  plant = "github.com/tgilbert14/neon-plant-diversity",
  veg = "github.com/tgilbert14/neon-vegetation-structure-explorer",
  bird = "github.com/tgilbert14/neon-breeding-birds",
  phe = "github.com/tgilbert14/neon-plant-phenology-explorer",
  mosq = "github.com/tgilbert14/neon-mosquito-pulse",
  beetle = "github.com/tgilbert14/neon-ground-beetle-tracker")

# Every product is required.  A missing sibling used to turn into an all-NA rung
# because rd() returned NULL; that is too dangerous for an auto-deployed synthesis.
missing_repos <- names(APP)[!vapply(APP, dir.exists, logical(1))]
if (length(missing_repos))
  stop(sprintf("required sibling repo(s) missing under CASCADE_ROOT: %s",
               paste(sprintf("%s='%s'", missing_repos, unlist(APP[missing_repos])), collapse = ", ")),
       call. = FALSE)

site_file_count <- function(path) {
  d <- file.path(path, "data", "sites")
  if (!dir.exists(d)) return(0L)
  length(list.files(d, pattern = "\\.rds$", full.names = FALSE))
}
git_system2 <- function(git, args, ...) {
  # R for Windows may rewrite HOME to Documents, while Git for Windows normally
  # resolves its global config/ignore file from USERPROFILE. Pass the real profile
  # explicitly so a source repository has the same clean/dirty status in the
  # shell, an interactive R session, and the transactional rebuild.
  profile <- if (.Platform$OS.type == "windows") Sys.getenv("USERPROFILE", unset = "") else ""
  old_home <- Sys.getenv("HOME", unset = NA_character_)
  on.exit({
    if (is.na(old_home)) Sys.unsetenv("HOME") else Sys.setenv(HOME = old_home)
  }, add = TRUE)
  if (nzchar(profile)) Sys.setenv(HOME = normalizePath(profile, winslash = "/"))
  system2(git, args, ...)
}
canonical_origin <- function(x) {
  x <- trimws(as.character(x)[1])
  x <- sub("^git@([^:]+):", "\\1/", x)
  x <- sub("^ssh://git@", "", x)
  x <- sub("^https?://", "", x)
  x <- sub("[.]git/?$", "", x)
  tolower(sub("/+$", "", x))
}
repo_origin <- function(path) {
  git <- Sys.which("git")
  if (!nzchar(git)) stop("git is required to record sibling-source origin", call. = FALSE)
  out <- tryCatch(
    suppressWarnings(git_system2(
      git, c("-C", shQuote(normalizePath(path, winslash = "/")),
             "config", "--get", "remote.origin.url"),
      stdout = TRUE, stderr = TRUE)),
    error = function(e) character(0))
  status <- attr(out, "status") %||% 0L
  if (!length(out) || status != 0L || !nzchar(trimws(out[1])))
    stop(sprintf("could not read git origin for required sibling repo '%s'", path),
         call. = FALSE)
  canonical_origin(out[1])
}

repo_sha <- function(path) {
  git <- Sys.which("git")
  if (!nzchar(git)) stop("git is required to record sibling-source provenance", call. = FALSE)
  out <- tryCatch(
    suppressWarnings(git_system2(git, c("-C", shQuote(normalizePath(path, winslash = "/")),
                                        "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE)),
    error = function(e) character(0))
  status <- attr(out, "status") %||% 0L
  if (!length(out) || status != 0L || !grepl("^[0-9a-fA-F]{40}$", trimws(out[1])))
    stop(sprintf("could not read git commit for required sibling repo '%s'", path), call. = FALSE)
  tolower(trimws(out[1]))
}
repo_commit_epoch <- function(path) {
  git <- Sys.which("git")
  if (!nzchar(git)) stop("git is required to record sibling-source commit time", call. = FALSE)
  out <- tryCatch(
    suppressWarnings(git_system2(git, c("-C", shQuote(normalizePath(path, winslash = "/")),
                                        "show", "-s", "--format=%ct", "HEAD"),
                                 stdout = TRUE, stderr = TRUE)),
    error = function(e) character(0))
  status <- attr(out, "status") %||% 0L
  value <- suppressWarnings(as.numeric(trimws(out[1] %||% NA_character_)))
  if (!length(out) || status != 0L || !is.finite(value) || value < 0)
    stop(sprintf("could not read git commit time for required sibling repo '%s'", path),
         call. = FALSE)
  value
}
repo_clean <- function(path) {
  git <- Sys.which("git")
  if (!nzchar(git)) stop("git is required to verify sibling-source cleanliness", call. = FALSE)
  # Only committed bytes below these inert data roots can enter the build. Keep
  # that source scope pristine, while unrelated editor metadata elsewhere in a
  # sibling worktree cannot create a false provenance failure.
  err <- tempfile("cascade-git-status-", tmpdir = Sys.getenv(
    "CASCADE_GENERATION_ROOT", unset = tempdir()))
  on.exit(unlink(err, force = TRUE), add = TRUE)
  out <- tryCatch(
    suppressWarnings(git_system2(git, c("-C", shQuote(normalizePath(path, winslash = "/")),
                                        "status", "--porcelain=v1", "--untracked-files=normal",
                                        "--", "data/sites", "data/env"),
                                 stdout = TRUE, stderr = err)),
    error = function(e) structure(character(0), status = 1L))
  status <- attr(out, "status") %||% 0L
  if (status != 0L)
    stop(sprintf("could not inspect git source-data status for required sibling repo '%s'", path), call. = FALSE)
  !any(nzchar(trimws(out)))
}

source_products <- data.frame(
  product = names(APP),
  repo = basename(normalizePath(unlist(APP), winslash = "/")),
  origin = vapply(APP, repo_origin, character(1)),
  commit = vapply(APP, repo_sha, character(1)),
  commit_epoch = vapply(APP, repo_commit_epoch, numeric(1)),
  clean = vapply(APP, repo_clean, logical(1)),
  n_site_files = vapply(APP, site_file_count, integer(1)),
  stringsAsFactors = FALSE)
bad_origin <- source_products$origin != unname(EXPECTED_ORIGINS[source_products$product])
if (any(bad_origin))
  stop(sprintf("required sibling repo origin mismatch: %s",
               paste(sprintf("%s=%s", source_products$product[bad_origin],
                             source_products$origin[bad_origin]), collapse = ", ")),
       call. = FALSE)
if (any(!source_products$clean))
  stop(sprintf("required sibling repo(s) have dirty or untracked archived data inputs: %s; commit/stash them before rebuilding so HEAD provenance is reproducible",
               paste(source_products$product[!source_products$clean], collapse = ", ")), call. = FALSE)
if (any(source_products$n_site_files < 1L))
  stop(sprintf("required product(s) have no data/sites/*.rds bundles: %s",
               paste(source_products$product[source_products$n_site_files < 1L], collapse = ", ")),
       call. = FALSE)

.cutoff_env <- Sys.getenv("CASCADE_LAST_COMPLETE_YEAR", unset = "")
.source_cutoff_epoch <- max(source_products$commit_epoch)
.cutoff_contract <- cascade_resolve_last_complete_year(
  .cutoff_env, .source_cutoff_epoch, min_year = MIN_YEAR)
.source_cutoff_year <- .cutoff_contract$source_year
LAST_COMPLETE_YEAR <- .cutoff_contract$year
LAST_COMPLETE_YEAR_BASIS <- .cutoff_contract$basis

env_dir <- file.path(APP$mammal, "data", "env")
if (!dir.exists(env_dir) || !length(list.files(env_dir, pattern = "\\.rds$")))
  stop("mammal sibling has no data/env/*.rds climate overlays", call. = FALSE)

source_input_inventory <- function(product, path) {
  git <- Sys.which("git")
  files <- list.files(file.path(path, "data", "sites"), pattern = "\\.rds$", full.names = TRUE)
  if (identical(product, "mammal"))
    files <- c(files, list.files(file.path(path, "data", "env"), pattern = "\\.rds$", full.names = TRUE))
  files <- sort(unique(normalizePath(files, winslash = "/", mustWork = TRUE)))
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  relative <- substring(files, nchar(root) + 2L)
  tracked <- tryCatch(
    suppressWarnings(git_system2(git, c("-C", shQuote(root), "ls-files"),
                                 stdout = TRUE, stderr = TRUE)),
    error = function(e) structure(character(0), status = 1L))
  status <- attr(tracked, "status") %||% 0L
  if (status != 0L)
    stop(sprintf("could not enumerate tracked inputs for '%s'", path), call. = FALSE)
  missing <- setdiff(relative, gsub("\\\\", "/", tracked))
  if (length(missing))
    stop(sprintf("required %s source input(s) are ignored or untracked: %s",
                 product, paste(missing, collapse = ", ")), call. = FALSE)
  data.frame(product = product, relative_path = relative,
             md5 = unname(tools::md5sum(files)),
             bytes = as.numeric(file.info(files)$size),
             stringsAsFactors = FALSE)
}
source_inputs <- do.call(rbind, Map(function(product, path)
  source_input_inventory(product, path), names(APP), APP))
if (!nrow(source_inputs) || anyDuplicated(paste(source_inputs$product, source_inputs$relative_path)))
  stop("source input fingerprint inventory is empty or duplicated", call. = FALSE)

# Freeze the recorded Git objects before any product bytes are deserialized. The
# final TOCTOU check below still audits the live repositories, while every reader
# and the later source-backed contract stage consume this same verified snapshot.
LIVE_APP <- APP
source_snapshot <- cascade_materialize_source_snapshot(
  live_app = LIVE_APP, source_products = source_products,
  source_inputs = source_inputs, git_system2 = git_system2)
APP <- as.list(source_snapshot$app)

assert_sources_unchanged <- function() {
  current_products <- data.frame(
    product = names(LIVE_APP),
    repo = basename(normalizePath(unlist(LIVE_APP), winslash = "/")),
    origin = vapply(LIVE_APP, repo_origin, character(1)),
    commit = vapply(LIVE_APP, repo_sha, character(1)),
    commit_epoch = vapply(LIVE_APP, repo_commit_epoch, numeric(1)),
    clean = vapply(LIVE_APP, repo_clean, logical(1)),
    n_site_files = vapply(LIVE_APP, site_file_count, integer(1)),
    stringsAsFactors = FALSE)
  current_inputs <- do.call(rbind, Map(function(product, path)
    source_input_inventory(product, path), names(LIVE_APP), LIVE_APP))
  ordered <- function(x, keys) {
    x <- x[do.call(order, x[keys]), , drop = FALSE]
    rownames(x) <- NULL
    x
  }
  products_before <- ordered(source_products, "product")
  products_after <- ordered(current_products, "product")
  inputs_before <- ordered(source_inputs, c("product", "relative_path"))
  inputs_after <- ordered(current_inputs, c("product", "relative_path"))
  if (!identical(products_before, products_after) || !identical(inputs_before, inputs_after))
    stop("sibling source HEAD, cleanliness, inventory, or bytes changed during the build; discard this generation and rebuild from an immutable snapshot",
         call. = FALSE)
  invisible(TRUE)
}

rd <- function(p) {
  if (!file.exists(p)) return(NULL) # a product may legitimately lack one particular site
  tryCatch(readRDS(p), error = function(e)
    stop(sprintf("failed to read required sibling bundle '%s': %s", p, conditionMessage(e)), call. = FALSE))
}
sites_in <- function(app) { d <- file.path(APP[[app]], "data/sites"); if (!dir.exists(d)) character(0) else sub("\\.rds$","",list.files(d, "\\.rds$")) }
yr_of <- function(x) suppressWarnings(as.integer(format(as.Date(x), "%Y")))
assert_unique_year <- function(df, label) {
  if (is.null(df) || !nrow(df)) return(invisible(df))
  dup <- dplyr::count(df, .data$year, name = "n")
  dup <- dup[dup$n > 1, , drop = FALSE]
  if (nrow(dup)) {
    stop(sprintf("%s has duplicate year rows; fix upstream aggregation before joining.", label), call. = FALSE)
  }
  invisible(df)
}

# ---- per-product annual extractors (return data.frame site,year,<signals>) ----
ann_env <- function(site) {                       # climate + coarse NEON phenology %
  e <- rd(file.path(APP$mammal, "data/env", paste0(site, ".rds"))); if (is.null(e)) return(NULL)
  required <- c("temp_c", "precip_mm", "fruiting_pct", "fruiting_pct_n")
  missing <- setdiff(required, names(e))
  if (length(missing) || !any(c("date", "ym") %in% names(e)))
    stop(sprintf("%s climate overlay lacks required field(s): %s", site,
                 paste(c(missing,
                         if (!any(c("date", "ym") %in% names(e))) "date/ym"),
                       collapse = ", ")), call. = FALSE)
  e$.date <- as.Date(e$date %||% paste0(e$ym, "-01"))
  e$year <- yr_of(e$.date)
  e$month <- suppressWarnings(as.integer(format(e$.date, "%m")))
  e <- e[is.finite(e$year) & is.finite(e$month) &
           e$year >= MIN_YEAR & e$year <= LAST_COMPLETE_YEAR, , drop = FALSE]
  if (!nrow(e)) return(NULL)
  ym <- paste(e$year, e$month, sep = "-")
  if (anyDuplicated(ym))
    stop(sprintf("%s climate overlay has duplicate year-month rows; aggregate upstream before building", site), call. = FALSE)
  # An annual mean/total requires all 12 distinct calendar months.  The previous
  # 8/10-month gates admitted seasonally biased means and unscaled partial sums.
  # Keep the support counts in the bundle so every NA is auditable downstream.
  agg <- e %>% filter(!is.na(.data$year)) %>% group_by(year) %>% summarise(
    temp_n_months = sum(is.finite(.data$temp_c) & .data$temp_c > -40 & .data$temp_c < 50),
    precip_n_months = sum(is.finite(.data$precip_mm) & .data$precip_mm >= 0 & .data$precip_mm < 2000),
    temp = { ok <- is.finite(.data$temp_c) & .data$temp_c > -40 & .data$temp_c < 50
             if (sum(ok) == 12L) mean(.data$temp_c[ok]) else NA_real_ },
    precip = { ok <- is.finite(.data$precip_mm) & .data$precip_mm >= 0 & .data$precip_mm < 2000
               if (sum(ok) == 12L) sum(.data$precip_mm[ok]) else NA_real_ },
    # This is an opportunistic observed-month peak, not a fixed-season annual
    # fruiting estimate. Months enter only with >=5 observed individuals. Persist
    # both opportunity count and conservative support (minimum n among tied peak
    # months); the link remains context-only because opportunity varies by year.
    fruiting_n_eligible_months = sum(is.finite(.data$fruiting_pct) &
      is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5),
    fruiting_peak_n_individuals = {
      ok <- is.finite(.data$fruiting_pct) & is.finite(.data$fruiting_pct_n) &
        .data$fruiting_pct_n >= 5
      if (!any(ok)) NA_real_ else {
        peak <- max(.data$fruiting_pct[ok])
        min(.data$fruiting_pct_n[ok & .data$fruiting_pct == peak])
      }
    },
    # Compute support before naming the summary fruiting_pct: dplyr summaries
    # are sequential, so creating fruiting_pct first would mask the monthly
    # source vector used by the support calculation above.
    fruiting_pct = { ok <- is.finite(.data$fruiting_pct) &
                       is.finite(.data$fruiting_pct_n) & .data$fruiting_pct_n >= 5
                     if (any(ok)) max(.data$fruiting_pct[ok]) else NA_real_ },
    .groups="drop")
  # Within-site temp outlier: NA any year whose annual mean is implausibly far from
  # this SITE's own median — catches a corrupted-sensor year (e.g. SCBI 2018, whose
  # summer months read deeply negative) that a fixed window/median can't, since ~40%
  # of its months are bad. Needs >=4 finite years to anchor a robust median.
  tv <- agg$temp[is.finite(agg$temp)]
  if (length(tv) >= 4) { med <- stats::median(tv); thr <- max(6, 3 * stats::mad(tv))
    agg$temp[is.finite(agg$temp) & abs(agg$temp - med) > thr] <- NA_real_ }
  agg %>% mutate(site = site, .before = 1)
}
ann_env_seasonal <- function(site) {              # registered seasonal climate proxies/context windows
  # Annual precipitation can blur distinct seasonal water inputs, so retain fixed
  # Oct-Mar, Jul-Sep, and Mar-May context windows from the same monthly overlay.
  # Except for spring temperature paired with green-up, these are contextual proxy
  # contrasts, not measured mechanisms. Completeness gates prevent partial windows
  # from being mistaken for comparable seasonal summaries.
  e <- rd(file.path(APP$mammal, "data/env", paste0(site, ".rds"))); if (is.null(e)) return(NULL)
  e$date <- as.Date(e$date %||% paste0(e$ym, "-01"))
  e$year <- yr_of(e$date); e$mo <- suppressWarnings(as.integer(format(e$date, "%m")))
  e <- e[is.finite(e$year) & is.finite(e$mo), , drop = FALSE]; if (!nrow(e)) return(NULL)
  if (anyDuplicated(paste(e$year, e$mo, sep = "-")))
    stop(sprintf("%s seasonal climate overlay has duplicate year-month rows", site), call. = FALSE)
  e$precip_mm[!(is.finite(e$precip_mm) & e$precip_mm >= 0 & e$precip_mm < 2000)] <- NA
  e$temp_c[!(is.finite(e$temp_c) & e$temp_c > -40 & e$temp_c < 50)] <- NA
  e$wy <- ifelse(e$mo >= 10, e$year + 1L, e$year)   # Oct-Dec credited to the year winter ENDS
  # Complete-window gates: missing a shoulder month can bias a seasonal sum/mean
  # just as badly as a missing month biases the annual metric. Persist support.
  win <- e %>% filter(.data$mo %in% c(10,11,12,1,2,3)) %>% group_by(year = .data$wy) %>%
    summarise(precip_winter_n_months = sum(!is.na(.data$precip_mm)),
              precip_winter = if (precip_winter_n_months == 6L) sum(.data$precip_mm) else NA_real_,
              .groups = "drop")
  mon <- e %>% filter(.data$mo %in% c(7,8,9)) %>% group_by(year = .data$year) %>%
    summarise(precip_monsoon_n_months = sum(!is.na(.data$precip_mm)),
              precip_monsoon = if (precip_monsoon_n_months == 3L) sum(.data$precip_mm) else NA_real_,
              .groups = "drop")
  spr <- e %>% filter(.data$mo %in% c(3,4,5)) %>% group_by(year = .data$year) %>%
    summarise(temp_spring_n_months = sum(!is.na(.data$temp_c)),
              temp_spring = if (temp_spring_n_months == 3L) mean(.data$temp_c) else NA_real_,
              .groups = "drop")
  assert_unique_year(win, paste0(site, " winter climate")); assert_unique_year(mon, paste0(site, " monsoon climate")); assert_unique_year(spr, paste0(site, " spring temp"));
  out <- Reduce(function(a, b) full_join(a, b, by = "year", relationship = "one-to-one"), list(win, mon, spr))
  # Crop output years before MAD: shoulder months may come from the preceding
  # calendar year, but future/out-of-window summaries must never set QC thresholds.
  out <- out[is.finite(out$year) & out$year >= MIN_YEAR &
               out$year <= LAST_COMPLETE_YEAR, , drop = FALSE]
  if (!nrow(out)) return(NULL)
  # same within-site MAD outlier QC the annual temp path uses (catches the SCBI-2018
  # corrupted-sensor year a naive seasonal recompute would let through).
  tv <- out$temp_spring[is.finite(out$temp_spring)]
  if (length(tv) >= 4) { med <- stats::median(tv); thr <- max(6, 3 * stats::mad(tv))
    out$temp_spring[is.finite(out$temp_spring) & abs(out$temp_spring - med) > thr] <- NA_real_ }
  out %>% mutate(site = site, .before = 1)
}
ann_phe <- function(site) {                       # composition-adjusted green-up timing
  b <- rd(file.path(APP$phe, "data/sites", paste0(site, ".rds"))); if (is.null(b)) return(NULL)
  required_obs <- c("individualID", "year", "scientificName", "is_species",
                    "growthForm", "phenophaseName", "status", "dayOfYear")
  if (is.null(b$obs) || !all(required_obs %in% names(b$obs)))
    stop(sprintf("%s phenology bundle lacks required columns: %s", site,
                 paste(setdiff(required_obs, names(b$obs %||% data.frame())), collapse = ", ")),
         call. = FALSE)
  o <- cascade_onset(b$obs, GREENUP); if (is.null(o) || !nrow(o)) return(NULL)
  required_onset <- c("individualID", "scientificName", "year", "onset_doy",
                      "left_censored", "first_yes")
  if (!all(required_onset %in% names(o)))
    stop(sprintf("%s onset() output lacks required columns: %s", site,
                 paste(setdiff(required_onset, names(o)), collapse = ", ")), call. = FALSE)

  # onset() returns one row per individual x phenophase x year. The estimand is
  # the EARLIEST green-up phase for an individual-year. If any tied earliest
  # phase is left-censored (the first visit was already 'yes'), the entire
  # individual-year is censored: substituting a later, bounded phase would turn
  # a known upper bound into a falsely exact and systematically late onset.
  individual_year <- o %>%
    filter(is.finite(.data$year), is.finite(.data$onset_doy),
           .data$year >= MIN_YEAR, .data$year <= LAST_COMPLETE_YEAR) %>%
    cascade_individual_year_onset()
  if (!nrow(individual_year)) return(NULL)

  taxon_map <- b$obs %>%
    group_by(.data$individualID, .data$scientificName) %>%
    summarise(is_species = any(.data$is_species %in% TRUE), .groups = "drop")
  individual_year <- individual_year %>%
    left_join(taxon_map, by = c("individualID", "scientificName"),
              relationship = "many-to-one")

  # The raw support calendar travels even when no index can be emitted. Every
  # earliest individual-year is assigned to exactly one of three audit buckets:
  # left-censored, composition/support-excluded, or a final contributor.
  audit <- individual_year %>%
    group_by(.data$year) %>%
    summarise(greenup_n_onsets = dplyr::n(),
              greenup_n_left_censored = sum(.data$left_censored %in% TRUE),
              .groups = "drop")

  uncensored_species <- individual_year %>%
    filter(!(.data$left_censored %in% TRUE), .data$is_species %in% TRUE,
           !is.na(.data$scientificName), nzchar(.data$scientificName))

  # First remove within-species pseudo-replication, then insist that each
  # species-year rests on >=3 uncensored individuals and that a species recurs
  # in >=3 eligible years. This supplies repeated within-species contrasts and
  # prevents one-year taxa from moving a site series through turnover.
  species_year <- uncensored_species %>%
    group_by(.data$scientificName, .data$year) %>%
    summarise(species_onset = stats::median(.data$onset_doy),
              n_individuals = dplyr::n_distinct(.data$individualID),
              .groups = "drop") %>%
    filter(.data$n_individuals >= 3L)
  recurrent_species <- species_year %>%
    group_by(.data$scientificName) %>%
    summarise(n_eligible_years = dplyr::n_distinct(.data$year), .groups = "drop") %>%
    filter(.data$n_eligible_years >= 3L) %>%
    select("scientificName")
  eligible_species_year <- species_year %>%
    semi_join(recurrent_species, by = "scientificName")

  # Recurrence alone can leave two disjoint species-by-year panels (for example,
  # an early-period species set and a wholly different late-period set). Those
  # components have no within-species bridge and cannot identify one coherent
  # site time series. Keep the connected component with the most species; ties
  # go to the most species-year records, then the lexically earliest species.
  # This dependency-light breadth-first expansion avoids adding igraph to builds.
  largest_incidence_component <- function(x) {
    if (is.null(x) || !nrow(x)) return(x)
    remaining <- sort(unique(as.character(x$scientificName)), method = "radix")
    components <- list()
    while (length(remaining)) {
      members <- remaining[1]
      repeat {
        years <- unique(x$year[x$scientificName %in% members])
        expanded <- sort(unique(as.character(
          x$scientificName[x$year %in% years])), method = "radix")
        if (identical(expanded, members)) break
        members <- expanded
      }
      rows <- x[x$scientificName %in% members, , drop = FALSE]
      components[[length(components) + 1L]] <- list(
        rows = rows,
        n_species = length(members),
        n_records = nrow(rows),
        first_species = members[1])
      remaining <- setdiff(remaining, members)
    }
    rank <- data.frame(
      component = seq_along(components),
      n_species = vapply(components, `[[`, integer(1), "n_species"),
      n_records = vapply(components, `[[`, integer(1), "n_records"),
      first_species = vapply(components, `[[`, character(1), "first_species"),
      stringsAsFactors = FALSE)
    winner <- rank$component[order(-rank$n_species, -rank$n_records,
                                   rank$first_species, method = "radix")][1]
    components[[winner]]$rows
  }
  eligible_species_year <- largest_incidence_component(eligible_species_year)
  if (nrow(eligible_species_year) &&
      nrow(largest_incidence_component(eligible_species_year)) !=
        nrow(eligible_species_year))
    stop(sprintf("%s selected phenology species-year panel is disconnected", site),
         call. = FALSE)
  contributors <- uncensored_species %>%
    semi_join(eligible_species_year,
              by = c("scientificName", "year"))
  if (nrow(contributors) &&
      any(!is.finite(contributors$onset_interval_days) |
            contributors$onset_interval_days < 0))
    stop(sprintf("%s final phenology contributors have invalid onset intervals", site),
         call. = FALSE)

  # An empty contributor table is a real, audited state, not a zero-width
  # sample. Avoid asking summary functions to reduce numeric(0): max() would
  # warn and return -Inf, whereas the published contract is NA for all three
  # widths whenever no final contributor survives.
  support <- if (!nrow(contributors)) {
    tibble::tibble(
      year = integer(), greenup_n_individuals = integer(),
      greenup_n_species = integer(),
      greenup_onset_interval_median_days = numeric(),
      greenup_onset_interval_p90_days = numeric(),
      greenup_onset_interval_max_days = numeric())
  } else {
    contributors %>%
      group_by(.data$year) %>%
      summarise(greenup_n_individuals = dplyr::n_distinct(.data$individualID),
                greenup_n_species = dplyr::n_distinct(.data$scientificName),
                greenup_onset_interval_median_days = stats::median(
                  .data$onset_interval_days),
                greenup_onset_interval_p90_days = as.numeric(stats::quantile(
                  .data$onset_interval_days, 0.9, names = FALSE, type = 7)),
                greenup_onset_interval_max_days = max(.data$onset_interval_days),
                .groups = "drop")
  }

  # Center every species on its own across-year median, then give each species
  # one equal vote in the annual median anomaly. The fixed site reference puts
  # the anomaly back on a familiar DOY-like scale for display; it is an anchor,
  # not an observed pooled onset. Changing counts of inherently early/late
  # species therefore cannot by itself move the index.
  indexed <- tibble::tibble(year = integer(), .greenup_anomaly = numeric())
  additive_indexed <- tibble::tibble(year = integer(), .greenup_additive = numeric())
  greenup_reference_doy <- NA_real_
  if (nrow(eligible_species_year)) {
    centered <- eligible_species_year %>%
      group_by(.data$scientificName) %>%
      mutate(species_reference = stats::median(.data$species_onset)) %>%
      ungroup()
    greenup_reference_doy <- centered %>%
      distinct(.data$scientificName, .data$species_reference) %>%
      summarise(reference = stats::median(.data$species_reference)) %>%
      pull("reference")
    indexed <- centered %>%
      group_by(.data$year) %>%
      summarise(.greenup_anomaly = stats::median(
                  .data$species_onset - .data$species_reference),
                .groups = "drop")

    # Estimator-choice sensitivity on the exact same connected species-year
    # cells: an unweighted additive species + year model, standardized by
    # evaluating every retained species in every retained year and taking the
    # equal-species annual median. Values for unobserved species-years are
    # model extrapolations, so this remains a documented alternate rather than
    # silently replacing the transparent median-centered primary index.
    retained_species <- sort(unique(as.character(
      eligible_species_year$scientificName)), method = "radix")
    retained_years <- sort(unique(eligible_species_year$year))
    if (length(retained_species) >= 2L) {
      additive_data <- eligible_species_year
      additive_data$scientificName <- factor(
        as.character(additive_data$scientificName), levels = retained_species)
      additive_fit <- stats::lm(
        species_onset ~ scientificName + factor(year), data = additive_data)
      expected_rank <- length(retained_species) + length(retained_years) - 1L
      if (additive_fit$rank != expected_rank)
        stop(sprintf("%s connected phenology panel produced a rank-deficient additive model",
                     site), call. = FALSE)
      prediction_grid <- expand.grid(
        scientificName = retained_species, year = retained_years,
        KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
      prediction_grid$.prediction <- as.numeric(stats::predict(
        additive_fit, newdata = prediction_grid))
      if (any(!is.finite(prediction_grid$.prediction)))
        stop(sprintf("%s additive phenology standardization produced non-finite predictions",
                     site), call. = FALSE)
      additive_indexed <- prediction_grid %>%
        group_by(.data$year) %>%
        summarise(.greenup_additive = stats::median(.data$.prediction),
                  .groups = "drop")
    }
  }

  out <- audit %>%
    left_join(support, by = "year", relationship = "one-to-one") %>%
    left_join(indexed, by = "year", relationship = "one-to-one") %>%
    left_join(additive_indexed, by = "year", relationship = "one-to-one") %>%
    mutate(
      greenup_n_individuals = dplyr::coalesce(.data$greenup_n_individuals, 0L),
      greenup_n_species = dplyr::coalesce(.data$greenup_n_species, 0L),
      greenup_n_taxon_excluded = .data$greenup_n_onsets -
        .data$greenup_n_left_censored - .data$greenup_n_individuals,
      greenup_reference_doy = greenup_reference_doy,
      greenup_doy = ifelse(
        .data$greenup_n_individuals >= 6L & .data$greenup_n_species >= 2L &
          is.finite(.data$.greenup_anomaly) & is.finite(.data$greenup_reference_doy),
        .data$greenup_reference_doy + .data$.greenup_anomaly, NA_real_),
      greenup_doy_additive = ifelse(
        .data$greenup_n_individuals >= 6L & .data$greenup_n_species >= 2L &
          is.finite(.data$.greenup_additive),
        .data$.greenup_additive, NA_real_),
      site = site, .before = 1) %>%
    select(all_of(c("site", "year", "greenup_doy", "greenup_doy_additive",
                    "greenup_n_onsets", "greenup_n_left_censored",
                    "greenup_n_taxon_excluded", "greenup_n_individuals",
                    "greenup_n_species", "greenup_reference_doy",
                    "greenup_onset_interval_median_days",
                    "greenup_onset_interval_p90_days",
                    "greenup_onset_interval_max_days")))

  if (any(out$greenup_n_taxon_excluded < 0L) ||
      any(out$greenup_n_onsets != out$greenup_n_left_censored +
            out$greenup_n_taxon_excluded + out$greenup_n_individuals))
    stop(sprintf("%s phenology audit buckets do not reconcile", site), call. = FALSE)
  if (!identical(is.finite(out$greenup_doy),
                 is.finite(out$greenup_doy_additive)))
    stop(sprintf("%s primary/additive phenology index year keys differ", site),
         call. = FALSE)
  has_contributors <- out$greenup_n_individuals > 0L
  width_keys <- c("greenup_onset_interval_median_days",
                  "greenup_onset_interval_p90_days",
                  "greenup_onset_interval_max_days")
  if (!all(vapply(out[width_keys], function(x)
        identical(is.finite(x), has_contributors), logical(1))) ||
      any(has_contributors & !(
        out$greenup_onset_interval_median_days <= out$greenup_onset_interval_p90_days &
        out$greenup_onset_interval_p90_days <= out$greenup_onset_interval_max_days)))
    stop(sprintf("%s phenology onset-interval audit fields are inconsistent", site),
         call. = FALSE)
  out
}
ann_plant <- function(site) {                     # producer: richness + introduced cover
  b <- rd(file.path(APP$plant, "data/sites", paste0(site, ".rds")))
  if (is.null(b)) return(NULL)
  oc <- cascade_bundle_table(b, "occ", "plant", site)
  cascade_require_columns(oc, CASCADE_PLANT_OCC_REQUIRED,
                          sprintf("%s plant occurrence table", site))
  if (!nrow(oc)) return(NULL)
  sp <- oc[oc$is_species %in% TRUE, , drop=FALSE]
  if (!nrow(sp)) return(NULL)
  sp %>% group_by(year) %>% summarise(
    plant_richness = dplyr::n_distinct(.data$scientificName),
    # Hill numbers q1/q2 (EFFECTIVE species), weighted by cover share. They are less
    # dominated by rare detections than raw richness, but they are not coverage-standardized
    # and can still vary with sampling effort. They remain descriptive. Manual formulas
    # (no vegan dependency): q1 = exp(Shannon), q2 = inverse-Simpson; NA when <2 species.
    plant_q1 = { ag <- tapply(.data$percentCover, .data$scientificName, sum, na.rm = TRUE)
                 ag <- ag[is.finite(ag) & ag > 0]
                 if (length(ag) < 2) NA_real_ else { p <- ag / sum(ag); exp(-sum(p * log(p))) } },
    plant_q2 = { ag <- tapply(.data$percentCover, .data$scientificName, sum, na.rm = TRUE)
                 ag <- ag[is.finite(ag) & ag > 0]
                 if (length(ag) < 2) NA_real_ else { p <- ag / sum(ag); 1 / sum(p^2) } },
    plant_n_plots = dplyr::n_distinct(.data$plotID),
    plant_n_sampling_units = dplyr::n_distinct(paste(.data$plotID, .data$subplotID, .data$scale, .data$bout, sep = "|")),
    plant_intro_pct = { tot <- sum(.data$percentCover, na.rm=TRUE)
      # NI means ambiguous/unknown in the source bundle, not introduced.
      if (tot > 0) 100 * sum(.data$percentCover[.data$nativeStatusCode == "I"], na.rm=TRUE) / tot else NA_real_ },
    plant_unknown_pct = { tot <- sum(.data$percentCover, na.rm=TRUE)
      unknown <- is.na(.data$nativeStatusCode) | !(.data$nativeStatusCode %in% c("N", "I"))
      if (tot > 0) 100 * sum(.data$percentCover[unknown], na.rm=TRUE) / tot else NA_real_ },
    .groups="drop") %>% mutate(site = site, .before = 1)
}
ann_mammal <- function(site) {                    # consumer: CPUE + minimum known alive
  d <- rd(file.path(APP$mammal, "data/sites", paste0(site, ".rds"))); if (is.null(d)) return(NULL)
  d <- cascade_data_frame(d, sprintf("%s mammal bundle", site))
  cascade_require_columns(d, CASCADE_MAMMAL_REQUIRED,
                          sprintf("%s mammal bundle", site))
  d$year <- yr_of(d$collectDate); d <- d[!is.na(d$year), , drop=FALSE]; if (!nrow(d)) return(NULL)
  # The reviewed adapter distinguishes physical A-J x 1-10 trap coordinates,
  # explicit multi-animal rows from one trap, two source-documented double-trap
  # exceptions, and non-unique AX-JX/X1-X10/XX placeholders. Unknown duplicate
  # patterns fail closed. Nelson-Clark weights remain 0, 0.5, or 1 TN per trap.
  event_effort <- tryCatch(
    cascade_mammal_effort_events(
      d, d$year, sprintf("%s mammal bundle", site)),
    error = function(e) stop(conditionMessage(e), call. = FALSE))
  # Capture is a nonblank tagged handling row, not a status-string inference:
  # the pinned source includes tagged status-2/3 rows and one untagged status-5.
  d$is_cap <- cascade_mammal_tag_present(d$tagID)
  d$.tag_id <- trimws(as.character(d$tagID))
  effort_year <- event_effort %>% group_by(.data$year) %>%
    summarise(
      traps = sum(.data$trap_effort, na.rm = TRUE),
      mammal_placeholder_trap_rows = sum(
        .data$effort_rule == "placeholder-row-level"),
      mammal_multi_capture_trap_events = sum(
        .data$effort_rule == "canonical-multi-capture-one-trap"),
      mammal_reviewed_double_trap_events = sum(
        .data$effort_rule == "reviewed-double-trap-rows"),
      .groups = "drop")
  capture_year <- d %>% group_by(.data$year) %>% summarise(
    captures = sum(.data$is_cap, na.rm = TRUE),
    mammal_mnka = dplyr::n_distinct(.data$.tag_id[.data$is_cap]),
    .groups="drop")
  full_join(effort_year, capture_year, by = "year", relationship = "one-to-one") %>%
    mutate(mammal_cpue = ifelse(.data$traps > 0, 100 * .data$captures / .data$traps, NA_real_),
           site = site,
           mammal_trap_nights = .data$traps,
           mammal_captures = .data$captures) %>%
    select(site, year, mammal_cpue, mammal_mnka, mammal_trap_nights,
           mammal_captures, mammal_placeholder_trap_rows,
           mammal_multi_capture_trap_events,
           mammal_reviewed_double_trap_events)
}
ann_bird <- function(site) {                      # consumer: detection index + richness
  b <- rd(file.path(APP$bird, "data/sites", paste0(site, ".rds")))
  if (is.null(b)) return(NULL)
  o <- cascade_bundle_table(b, "obs", "bird", site)
  cascade_require_columns(o, CASCADE_BIRD_OBS_REQUIRED,
                          sprintf("%s bird observation table", site))
  if (!nrow(o)) return(NULL)
  o$.flyover <- grepl("flyover", tolower(as.character(o$detectionMethod)))
  o$.flyover[is.na(o$.flyover)] <- FALSE
  # The bundled points table carries only lifetime n_visits, not annual effort.
  # pointkey x eventID is therefore the best annual denominator available here,
  # but it includes only occasions with >=1 detection. Persist that lower-bound
  # denominator and its limitation rather than pretending it includes zero-detect visits.
  if ("eventID" %in% names(o))
    o$.observed_visit <- paste(o$pointkey, o$eventID, sep = "|")
  else if ("bout" %in% names(o))
    o$.observed_visit <- paste(o$pointkey, o$year, o$bout, sep = "|")
  else
    stop(sprintf("%s bird bundle lacks eventID/bout needed for visit normalization", site), call. = FALSE)
  spo <- o[o$is_species %in% TRUE & !o$.flyover, , drop = FALSE]
  o %>% group_by(year) %>% summarise(
    bird_observed_point_visits = dplyr::n_distinct(.data$.observed_visit),
    bird_nonflyover_birds = sum(.data$clusterSize[!.data$.flyover], na.rm = TRUE),
    bird_flyover_birds = sum(.data$clusterSize[.data$.flyover], na.rm = TRUE),
    bird_index = if (bird_observed_point_visits > 0)
      bird_nonflyover_birds / bird_observed_point_visits else NA_real_,
    .groups="drop") %>%
    left_join(spo %>% group_by(year) %>% summarise(bird_richness = dplyr::n_distinct(.data$scientificName), .groups="drop"), by="year") %>%
    mutate(bird_richness = ifelse(is.na(.data$bird_richness) & .data$bird_observed_point_visits > 0,
                                  0, .data$bird_richness),
           site = site) %>%
    select(site, year, bird_index, bird_richness, bird_observed_point_visits,
           bird_nonflyover_birds, bird_flyover_birds)
}
ann_mosq <- function(site) {                      # consumer/vector: CO2-trap activity index (per trap-night)
  # A whole-year contextual activity index, NOT a population or a response matched
  # to any seasonal climate window. Per-year activity = whole-trap
  # catch / that year's trap-nights (effort_week), honoring the CPUE/per-trap-night
  # discipline (a 0 is "not trapped," never "extirpated"). Any seasonal pairing
  # remains illustrative until the response is reconstructed in the same window.
  b <- rd(file.path(APP$mosq, "data/sites", paste0(site, ".rds")))
  if (is.null(b)) return(NULL)
  o <- cascade_bundle_table(b, "obs", "mosquito", site)
  ew <- cascade_bundle_table(b, "effort_week", "mosquito", site)
  cascade_require_columns(o, CASCADE_MOSQ_OBS_REQUIRED,
                          sprintf("%s mosquito observation table", site))
  cascade_require_columns(ew, CASCADE_MOSQ_EFFORT_REQUIRED,
                          sprintf("%s mosquito effort table", site))
  tg <- o[o$is_target %in% TRUE, , drop = FALSE]
  eff <- ew %>% group_by(year) %>%
    summarise(tn = sum(.data$trap_nights, na.rm = TRUE), .groups = "drop")
  if (!nrow(tg) && !nrow(eff)) return(NULL)
  catch <- tg %>% group_by(year) %>% summarise(
    total = sum(.data$count, na.rm=TRUE),
    culex = sum(.data$count[.data$genus == "Culex"], na.rm=TRUE),
    mosq_richness = dplyr::n_distinct(.data$scientificName[.data$is_species %in% TRUE]),
    .groups="drop")
  if (!is.null(eff)) assert_unique_year(eff, paste0(site, " mosquito effort")); assert_unique_year(catch, paste0(site, " mosquito catch"));
  # Start from the effort calendar and retain whole years with trapping but zero
  # target catch as real zeros. A catch-first join silently dropped those years.
  out <- full_join(eff, catch, by="year", relationship = "one-to-one")
  out %>% mutate(
    total = ifelse(is.na(.data$total) & is.finite(.data$tn), 0, .data$total),
    culex = ifelse(is.na(.data$culex) & is.finite(.data$tn), 0, .data$culex),
    mosq_richness = ifelse(is.na(.data$mosq_richness) & is.finite(.data$tn), 0, .data$mosq_richness),
    mosq_activity = ifelse(!is.na(.data$tn) & .data$tn > 0, .data$total / .data$tn, NA_real_),
    mosq_culex    = ifelse(.data$total > 0, 100 * .data$culex / .data$total, NA_real_),
    site = site,
    mosq_trap_nights = .data$tn,
    mosq_total_catch = .data$total) %>%
    select(site, year, mosq_activity, mosq_richness, mosq_culex,
           mosq_trap_nights, mosq_total_catch)
}
ann_beetle <- function(site) {                    # consumer: pitfall ACTIVITY-DENSITY (per 100 trap-nights) + richness
  # Ground beetles (Carabidae), NEON DP1.10022.001 (Hoekman et al. 2017, Ecosphere e01744).
  # The sibling bundle is already carabid-only (assemble_beetles filters sampleType=="carabid"
  # and applies the expert ID), so no bycatch guard is needed. Flat tibble: siteID, plotID,
  # collectDate (Date), taxonID, scientificName, taxonRank, individualCount, trapnights.
  # HONESTY (carried on the label "more active beetles"): pitfall catch is ACTIVITY-density,
  # NOT density — it confounds true abundance with locomotor activity (Thiele 1977; Greenslade
  # 1964; Lovei & Sunderland 1996). A within-site relative index, never a cross-site head-count;
  # a 0 is "trapped, none active", NA is "not trapped". EFFORT: trapnights repeats across every
  # species row of the same plot x bout, so it MUST be deduped to one value per (plot, bout)
  # before summing, or a raw sum multiplies effort by the species count and craters the index.
  d <- rd(file.path(APP$beetle, "data/sites", paste0(site, ".rds")))
  if (is.null(d)) return(NULL)
  cascade_data_frame(d, sprintf("%s beetle bundle", site))
  cascade_require_columns(d, CASCADE_BEETLE_REQUIRED,
                          sprintf("%s beetle bundle", site))
  if (!nrow(d)) return(NULL)
  d$year <- yr_of(d$collectDate)
  d$individualCount <- suppressWarnings(as.numeric(d$individualCount))
  d$trapnights      <- suppressWarnings(as.numeric(d$trapnights))
  if (any(!is.finite(d$trapnights) | d$trapnights <= 0))
    stop(sprintf("%s beetle bundle has %d catch rows without positive finite trap effort",
                 site, sum(!is.finite(d$trapnights) | d$trapnights <= 0)), call. = FALSE)
  d <- d[is.finite(d$year) & is.finite(d$individualCount) & d$individualCount > 0 &
           !is.na(d$scientificName) & nzchar(d$scientificName), , drop = FALSE]
  if (!nrow(d)) return(NULL)
  d$is_sp <- !is.na(d$taxonRank) & d$taxonRank %in% c("species", "subspecies", "speciesGroup")
  eff_events <- d %>%
    distinct(.data$year, .data$plotID, .data$collectDate, .data$trapnights)
  conflicts <- eff_events %>%
    count(.data$year, .data$plotID, .data$collectDate, name = "n") %>%
    filter(.data$n > 1L)
  if (nrow(conflicts))
    stop(sprintf("%s beetle bundle has conflicting trap-night effort for %d plot-date events",
                 site, nrow(conflicts)), call. = FALSE)
  eff <- eff_events %>% group_by(.data$year) %>%
    summarise(tn = sum(.data$trapnights, na.rm = TRUE), .groups = "drop")
  catch <- d %>% group_by(.data$year) %>% summarise(
    total = sum(.data$individualCount, na.rm = TRUE),
    beetle_richness = dplyr::n_distinct(.data$scientificName[.data$is_sp]),
    .groups = "drop")
  assert_unique_year(eff, paste0(site, " beetle effort")); assert_unique_year(catch, paste0(site, " beetle catch"));
  out <- left_join(catch, eff, by = "year", relationship = "one-to-one")
  out %>% mutate(   # per 100 trap-nights, same scaling as mammal_cpue (both per-100-TN trap indices)
    beetle_activity = ifelse(!is.na(.data$tn) & .data$tn > 0, 100 * .data$total / .data$tn, NA_real_),
    site = site,
    # Source site bundles contain catch rows, not a complete zero-catch effort
    # table. This denominator is therefore explicitly named as catch-event effort.
    beetle_catch_event_trap_nights = .data$tn,
    beetle_total_catch = .data$total) %>%
    select(site, year, beetle_activity, beetle_richness,
           beetle_catch_event_trap_nights, beetle_total_catch)
}
ann_veg <- function(site) {                       # producer standing stock -- a slow ~5-year state,
  # NOT an annual link (its remeasurement cadence would manufacture pseudo-resolution). Live basal
  # area m2/ha from the Veg-Structure sibling: directly measured, allometry-free, and computable at
  # arid systems via basal stem diameter. It is useful structural context, not a substitute for
  # productivity: a stock, not a flux, so it enters as per-site context, not a ladder line.
  b <- rd(file.path(APP$veg, "data/sites", paste0(site, ".rds")))
  if (is.null(b)) return(NULL)
  trees <- cascade_bundle_table(b, "trees", "vegetation", site)
  plots <- cascade_bundle_table(b, "plots", "vegetation", site)
  cascade_require_columns(trees, CASCADE_VEG_TREES_REQUIRED,
                          sprintf("%s vegetation tree table", site))
  cascade_require_columns(plots, CASCADE_VEG_PLOTS_REQUIRED,
                          sprintf("%s vegetation plot table", site))
  if (!nrow(trees)) return(NULL)
  snap <- cascade_tree_snapshot(trees)
  if (is.null(snap) || !nrow(snap)) return(NULL)
  support <- cascade_vegetation_design_support(snap, plots)
  if (!support$supported) {
    # A source can contain tagged plants but no matching sampled-area design
    # rows. That is an unavailable per-hectare estimand, not zero vegetation and
    # not permission to borrow area from other plots. Keep the site-level NA and
    # the complete support audit so the reason remains machine-readable.
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
    stop(sprintf("%s vegetation support audit disagrees with stand records", site),
         call. = FALSE)
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
# ---- assemble over the union of all seven required product site sets ----
all_sites <- sort(unique(unlist(lapply(names(APP), sites_in), use.names = FALSE)))
cat("assembling", length(all_sites), "sites...\n")
join_all <- function(site) {
  parts <- Filter(Negate(is.null), list(ann_env(site), ann_env_seasonal(site), ann_phe(site), ann_plant(site), ann_mammal(site), ann_bird(site), ann_mosq(site), ann_beetle(site)))
  if (!length(parts)) return(NULL)
  invisible(lapply(seq_along(parts), function(i) assert_unique_year(parts[[i]], paste0(site, " part ", i))));
  Reduce(function(a,b) full_join(a,b,by=c("site","year"), relationship = "one-to-one"), parts)
}
annual <- bind_rows(lapply(all_sites, join_all))
annual <- annual[!is.na(annual$year) & annual$year >= MIN_YEAR &
                   annual$year <= LAST_COMPLETE_YEAR, , drop=FALSE]
annual <- annual %>% arrange(.data$site, .data$year)

# ensure every signal column exists even if no site had it
SIGCOLS <- c("precip","temp","precip_winter","precip_monsoon","temp_spring","fruiting_pct","greenup_doy","plant_richness","plant_q1","plant_q2","plant_intro_pct","mammal_cpue","mammal_mnka","bird_index","bird_richness","mosq_activity","mosq_richness","mosq_culex","beetle_activity","beetle_richness")
for (col in SIGCOLS) if (!col %in% names(annual)) annual[[col]] <- NA_real_
SUPPORT_COLS <- c(
  "temp_n_months", "precip_n_months", "precip_winter_n_months",
  "precip_monsoon_n_months", "temp_spring_n_months",
  "fruiting_n_eligible_months", "fruiting_peak_n_individuals",
  "greenup_n_onsets", "greenup_n_left_censored", "greenup_n_taxon_excluded",
  "greenup_n_individuals", "greenup_n_species", "greenup_reference_doy",
  "greenup_doy_additive",
  "greenup_onset_interval_median_days", "greenup_onset_interval_p90_days",
  "greenup_onset_interval_max_days",
  "plant_n_plots", "plant_n_sampling_units",
  "plant_unknown_pct", "mammal_trap_nights", "mammal_captures",
  "mammal_placeholder_trap_rows", "mammal_multi_capture_trap_events",
  "mammal_reviewed_double_trap_events",
  "bird_observed_point_visits", "bird_nonflyover_birds", "bird_flyover_birds",
  "mosq_trap_nights", "mosq_total_catch",
  "beetle_catch_event_trap_nights", "beetle_total_catch")
for (col in SUPPORT_COLS) if (!col %in% names(annual)) annual[[col]] <- NA_real_

# ---- signal metadata: trophic layer + display + direction-of-"more" ----
# `ladder` = show on the main stacked ladder. Seasonal climate signals are ladder=FALSE:
# they provide registered context proxies (and spring-temperature green-up sensitivity)
# without crowding the main display.
signals <- tibble::tribble(
  ~key,            ~label,                         ~layer,       ~unit,        ~higher_is,     ~ladder,
  "precip",        "Precipitation (annual)",       "climate",    "mm/yr",      "wetter",        TRUE,
  "temp",          "Mean temperature",             "climate",    "°C",         "warmer",        TRUE,
  "precip_winter", "Winter rain (Oct–Mar)",        "climate",    "mm",         "wetter winter", FALSE,
  "precip_monsoon","Monsoon rain (Jul–Sep)",       "climate",    "mm",         "wetter monsoon",FALSE,
  "temp_spring",   "Spring temperature",           "climate",    "°C",         "warmer spring", FALSE,
  "greenup_doy",   "Green-up onset index",         "phenology",  "DOY-anchored index","later", TRUE,
  "fruiting_pct",  "Opportunistic observed-month fruiting peak",                "producer",   "% plants",   "more fruit",    TRUE,
  "plant_richness","Plant richness",               "producer",   "species",    "more diverse",  TRUE,
  "plant_q1",      "Plant diversity (q1)",         "producer",   "eff. species","more diverse",  FALSE,
  "plant_q2",      "Plant diversity (q2)",         "producer",   "eff. species","more diverse",  FALSE,
  "plant_intro_pct","Introduced plant cover",      "producer",   "% cover",    "more invaded",  TRUE,
  "mammal_cpue",   "Small-mammal catch rate",      "consumer",   "per 100 TN", "more rodents",  TRUE,
  "mammal_mnka",   "Small mammals (indiv.)",       "consumer",   "individuals","more rodents",  TRUE,
  "bird_index",    "Bird detection index",         "consumer",   "birds/point","more birds",    TRUE,
  "bird_richness", "Bird richness",                "consumer",   "species",    "more species",  TRUE,
  "mosq_activity", "Mosquito activity",            "consumer",   "per trap-nt","more mosquitoes",TRUE,
  "mosq_richness", "Mosquito richness",            "consumer",   "species",    "more species",  FALSE,
  "mosq_culex",    "Culex share (WNV group)",      "consumer",   "% of catch", "more Culex",    FALSE,
  "beetle_activity","Ground-beetle activity",       "consumer",   "per 100 TN", "more active beetles", TRUE,
  "beetle_richness","Ground-beetle richness",       "consumer",   "species",    "more species",  FALSE)

# ---- Literature-motivated direct association contrasts. `expected_class` is the
# inferential eligibility switch: "all" casts a site vote; "none" remains visible
# as contextual analysis but never enters a site tally, binomial p-value, or meta
# headline. After the 2026-07 construct audit, only the two temperature–green-up
# associations are vote-eligible. The annual panel does not contain a defensible
# productivity/seed-resource rung or a mediation test, mosquito response windows do
# not match their named seasonal drivers, and beetle effort is conditioned on a
# positive catch. Keeping those rows contextual is more honest than drawing a
# synthetic cascade from adjacent arrows. `conf` describes the literature motivation,
# not evidence from this selected dataset. All current estimates come from the bundle.
priors <- tibble::tribble(
  ~from,            ~to,              ~sign, ~lag, ~conf,      ~expected_class,       ~note,
  "temp",           "greenup_doy",     -1L, 0L, "strong",   "all",                 "Warmer conditions are literature-motivated to accompany earlier leaf-out. This row pairs complete annual mean temperature with a left-censor-screened, composition-adjusted green-up timing index. Excluding already-active-at-first-visit records is not interval-censored modeling and can select contributors by visit timing/cadence. Annual temperature is a contemporaneous broad proxy—not an antecedent spring exposure or trigger—so interpret the raw-level direction together with detrended, consecutive-year-change, estimator, and NEON-domain sensitivities.",
  "temp_spring",    "greenup_doy",     -1L, 0L, "strong",   "all",                 "Warmer spring conditions are literature-motivated to accompany earlier leaf-out. This row uses complete March–May mean temperature, but many green-up observations occur before May, so the window can include post-outcome weather. It is a contemporaneous proxy sensitivity, not a direct trigger test; compare raw-level, detrended, and consecutive-year-change directions.",
  "precip",         "plant_richness",  +1L, 0L, "weak",     "none",                "More rain can mean more plant growth, but raw observed richness is dominated by changing sampled plots/scales and is composition, not productivity. Computed and shown as context only: expected_class='none' excludes it from every site tally and pooled inference until richness is coverage-standardized. plant_n_plots and plant_n_sampling_units expose the effort behind each year.",
  "precip",         "mammal_cpue",     +1L, 1L, "moderate", "none",                "Rain–rodent dynamics can be delayed, nonlinear, and guild-specific; the annual catch-per-effort index is not a population count and no annual seed-resource mediator is available here. The +1 one-year pairing is retained as literature-motivated context only, excluded from site tallies and pooled inference.",
  "precip_winter",  "plant_richness",  +1L, 0L, "moderate", "none",                "Cool-season rain can germinate desert spring forbs, but the available raw richness changes strongly with sampled plots/scales. Computed and shown as context only: expected_class='none' excludes this effort-confounded proxy from site tallies and pooled inference until richness is coverage-standardized.",
  "precip_monsoon", "mammal_cpue",     +1L, 1L, "moderate", "none",                "Some dryland granivores track delayed resource pulses after summer rain, but the atlas lacks a measured seed-crop mediator and pools a mixed small-mammal catch index. The monsoon-to-next-year pairing is an illustrative contextual contrast only—not a generic linear desert response and not an inferential vote.",
  "fruiting_pct",   "mammal_cpue",     +1L, 1L, "weak",     "none",                "The annual fruiting signal is the peak monthly share of observed plants marked in fruit, not fruit quantity or a measured seed crop, while mammal CPUE mixes guilds. The one-year pairing is retained as context only and excluded from every site tally and cross-site direction screen.",
  "plant_richness", "mammal_cpue",     +1L, 1L, "none",     "none",                "More varied plant communities might support more animals the next year, but observed richness varies with sampled plots, subplots, and scales and is only a rough food proxy. Computed and shown as context only: expected_class='none' excludes this effort-confounded link from site tallies and pooled inference until richness is coverage-standardized.",
  "precip_monsoon", "mosq_activity",   +1L, 0L, "moderate", "none",                "Rain can create larval habitat, but the response here is a whole-year mosquito catch-per-trap-night index rather than a Jul–Sep matched-window response, and rainfall effects can be delayed and taxon-specific. Shown as context only; it does not cast a same-season or pooled vote.",
  "temp_spring",    "mosq_activity",   +1L, 0L, "moderate", "none",                "Temperature affects mosquito development, survival, longevity, and fecundity in different ways; the response here is whole-year catch rather than a March–May matched-window index. A universally positive linear spring-temperature response is not established, so this row is context only.",
  "temp_spring",    "beetle_activity", +1L, 0L, "moderate", "none",                "Ground-beetle catch mixes abundance and movement across diverse guilds. More importantly, the source bundle includes effort only for catch-bearing events and omits zero-catch deployments, making the denominator outcome-conditioned. This annual association is descriptive context only and cannot cast a vote.",
  "precip_monsoon", "beetle_activity", +1L, 0L, "weak",     "none",                "Ground-beetle moisture responses are guild-specific, and the catch-only source omits zero-catch effort events. Because the denominator is conditioned on a positive outcome—and the annual response is not a Jul–Sep matched window—this association is descriptive context only and cannot cast a vote.")
# NOTE: no green-up -> bird prior. The trophic-mismatch literature (Both; Visser;
# Mayor 2017; Youngflesh 2021) is about SYNCHRONY between bird breeding and the food
# peak — not "later green-up DOY -> more birds", and the direction reverses by region.
# We can't compute a defensible mismatch from a detection index, so we post no prior
# rather than one the cited literature doesn't support. bird_index still shows on the
# ladder as a descriptive consumer signal.
# NOTE: no producer -> beetle prior. Carabids are a guild mix (predators, granivores,
# detritivores); plant productivity feeds some and not others, and dense vegetation can
# LOWER surface activity/catch — so the literature gives no single defensible sign for
# plants -> beetle activity. Routing a richness proxy (already weak: composition, not
# productivity) into an activity-density index would stack two confounds. We post no
# prior rather than one the literature won't sign; beetle_activity still shows on the
# ladder and is testable in Driver Lab. (Cass + Cara, 2026-06.)

# ---- per-site biome classification (the throughline) ----
ALL_SITES <- sort(unique(annual$site))
if (anyDuplicated(neon_sites$site))
  stop("neon_sites has duplicate site codes; domain mapping is not one-to-one", call. = FALSE)
domain_row <- match(ALL_SITES, neon_sites$site)
if (anyNA(domain_row) || anyNA(neon_sites$domain[domain_row]) ||
    any(!nzchar(as.character(neon_sites$domain[domain_row]))))
  stop(sprintf("missing strict NEON-domain mapping for: %s",
               paste(ALL_SITES[is.na(domain_row) |
                 is.na(neon_sites$domain[domain_row]) |
                 !nzchar(as.character(neon_sites$domain[domain_row]))], collapse = ", ")),
       call. = FALSE)
site_meta <- data.frame(
  site        = ALL_SITES,
  domain      = as.character(neon_sites$domain[domain_row]),
  biome       = vapply(ALL_SITES, biome_of, character(1)),
  biome_class = vapply(ALL_SITES, biome_class, character(1)),
  biome_label = vapply(ALL_SITES, biome_label, character(1)),
  biome_class_basis = vapply(ALL_SITES, biome_class_basis, character(1)),
  biome_class_method = BIOME_CLASS_METHOD,
  stringsAsFactors = FALSE)
# producer standing stock (live basal area m2/ha) — per-site context, not an annual signal
veg <- do.call(rbind, lapply(ALL_SITES, ann_veg))
if (!is.null(veg) && nrow(veg)) site_meta <- dplyr::left_join(site_meta, veg, by = "site")
for (col in c("veg_ba_ha", "veg_ba_se", "veg_n_plots", "veg_record_plots",
              "veg_matched_record_plots", "veg_area_eligible_plots",
              "veg_unmatched_record_plots", "veg_unmatched_record_rows",
              "veg_class_tree_ba_ha", "veg_class_shrub_ba_ha",
              "veg_class_tree_plots", "veg_class_shrub_plots"))
  if (!col %in% names(site_meta)) site_meta[[col]] <- NA_real_
for (col in c("veg_type", "veg_stand_basis", "veg_class_basis",
              "veg_design_status", "veg_design_basis"))
  if (!col %in% names(site_meta)) site_meta[[col]] <- NA_character_
cat("\nveg standing stock computed for", sum(is.finite(site_meta$veg_ba_ha)), "of", nrow(site_meta), "sites\n")

# ---- PRECOMPUTE the cross-site scoreboard + pooled exploratory summary.
# Per-site series are short; pooling each link across the sites where it is expected
# gives one site one binomial direction vote. It is an explicit suite-level summary,
# not a confirmatory headline: it depends on the imperfect site-independence assumption
# and the prior family was co-developed while these data were inspected. This
# is also a perf win: the app reads SUITE_LINKS/POOLED from the bundle instead of
# recomputing site_links() across every current-family prior on each site switch.
cat("\nprecomputing cross-site direct-pair rows (vote-eligible vs context-only)...\n")
suite_links <- do.call(rbind, lapply(ALL_SITES, function(s) {
  a  <- annual[annual$site == s, , drop = FALSE]
  bc <- site_meta$biome_class[site_meta$site == s]
  lk <- site_links(a, priors, biome = bc, nperm = 2000)
  lk$site <- s
  lk$domain <- site_meta$domain[site_meta$site == s]
  lk$biome <- site_meta$biome[site_meta$site == s]
  lk$biome_class <- bc
  lk
}))
pooled <- pooled_links(suite_links)
# Carry the pooling-floor flag in the bundle so the server's headline can split the
# multi-site rank from the under-floor (1–2 vote) rows WITHOUT re-deriving the rule
# (a binomial reference on 1–2 site votes is not a useful direction screen). pooled_links() already sets
# this; we re-assert it here so a future change to that helper can't silently drop
# the column the server prefers (it falls back to sites>=3 only if absent).
pooled$poolable <- pooled$sites >= 3
# Build-time guard: EVERY selectable site must be in the precomputed scoreboard, or the
# app's site_links_cached() fallback would run a live 2000-permutation fit on the reactive
# path (a multi-second freeze). The site dropdown is keyed on unique(annual$site); assert
# parity here so a coverage gap fails the BUILD, not the user.
stopifnot("suite_links is missing sites that appear in annual" =
  setequal(unique(suite_links$site), unique(annual$site)))

# Close the provenance time-of-check/time-of-use window before emitting outputs.
assert_sources_unchanged()
assert_local_build_inputs_unchanged()
# ---- machine-readable codebook (emitted ONCE here for every annual signal and
# support/audit column, so numerators, denominators, and coverage gates are not
# undocumented implementation details).
# Columns: key,label,layer,unit,higher_is,na_meaning,n_gate. na_meaning documents WHY
# a cell is NA (the QC gate that produced it); n_gate is the per-signal coverage gate.
na_meaning <- c(
  precip          = "NA unless all 12 distinct calendar months have valid precipitation; partial-year totals are never summed.",
  temp            = "NA unless all 12 distinct calendar months have valid temperature, or when the within-site MAD outlier filter NA'd a corrupted-sensor year.",
  precip_winter   = "NA unless all 6 Oct-Mar months are present.",
  precip_monsoon  = "NA when any of the 3 Jul-Sep months is missing.",
  temp_spring     = "NA unless all 3 Mar-May months are present, or when within-site MAD outlier QC flags an implausible spring-temperature year.",
  greenup_doy     = paste("DOY-anchored composition-adjusted onset index; NA unless >=2 recurrent species contribute, each with >=3 left-censor-screened individuals (therefore >=6 contributors). Exclusion of left-censored records is not interval-censored modeling and can select contributors by visit timing/cadence. It is not an observed pooled-median onset date.", GREENUP_INDEX_NOTE),
  fruiting_pct    = "Opportunistic maximum among observed months with >=5 individuals, not a fixed-season annual estimate. NA when no month qualifies; opportunity varies and is exposed in fruiting_n_eligible_months.",
  plant_richness  = "NA when the plant-diversity bundle has no plot data that year.",
  plant_q1        = "Effective species (exp-Shannon Hill number); NA when fewer than 2 cover-scored species that year.",
  plant_q2        = "Effective species (inverse-Simpson Hill number); NA when fewer than 2 cover-scored species that year.",
  plant_intro_pct = "NA when cover is unscored that year; only nativeStatusCode='I' counts as introduced ('NI' remains unknown).",
  mammal_cpue     = "NA when no reviewed trapping effort is recorded that year. Canonical trap-event duplicates must match the locked multi-capture or exact source-documented double-trap rules; unreviewed ambiguity aborts the build.",
  mammal_mnka     = "Zero when trapping rows exist but no tagged individual is captured; NA when no trapping records exist that year.",
  bird_index      = "NA when no observed point-count occasion that year. Flyovers are excluded. Annual source effort omits zero-detection visits, so this remains a descriptive lower-denominator index and carries no prior.",
  bird_richness   = "NA when no observed point-count detection occasion exists; zero when observed rows contain only excluded flyovers/non-species records.",
  mosq_activity   = "NA when no CO2 trap effort that year.",
  mosq_richness   = "Zero when recorded effort has no target catch; NA when neither effort nor identified mosquito catch is available.",
  mosq_culex      = "NA when the catch is zero or unidentified to the Culex group.",
  beetle_activity = "NA when no catch-bearing pitfall event effort is available that year; source bundles omit zero-catch events, so the denominator is incomplete. Activity-density (per 100 recorded trap-nights), not abundance.",
  beetle_richness = "Species-level carabids only (taxonRank species/subspecies/speciesGroup); genus/family IDs excluded. NA when no identified carabid catch that year.")
n_gate <- c(
  precip = "12 of 12 distinct months", temp = "12 of 12 distinct months", precip_winter = "6 of 6 months",
  precip_monsoon = "3 of 3 months", temp_spring = "3 of 3 months",
  greenup_doy = ">=2 recurrent species/yr and >=3 individuals/species-year (therefore >=6 contributors); species eligible in >=3 years",
  fruiting_pct = "context only; >=5 individuals in each eligible observed month; no fixed annual coverage gate",
  plant_richness = "1+ plot/yr", plant_q1 = ">=2 species/yr", plant_q2 = ">=2 species/yr", plant_intro_pct = "total scored cover > 0",
  mammal_cpue = "effort>0", mammal_mnka = "trapping records present; zero tags allowed", bird_index = "1+ observed point-visit/yr",
  bird_richness = "1+ observed visit/yr", mosq_activity = "effort>0", mosq_richness = "effort>0; zero catch retained",
  mosq_culex = "total catch>0", beetle_activity = "effort>0", beetle_richness = "1+ species/yr")
signal_codebook <- data.frame(
  key       = signals$key,
  label     = signals$label,
  layer     = signals$layer,
  unit      = signals$unit,
  higher_is = signals$higher_is,
  na_meaning = unname(na_meaning[signals$key]),
  n_gate     = unname(n_gate[signals$key]),
  stringsAsFactors = FALSE)
support_codebook <- tibble::tribble(
  ~key, ~label, ~layer, ~unit, ~higher_is, ~na_meaning, ~n_gate,
  "temp_n_months", "Valid annual-temperature months", "climate", "months", "more coverage", "NA when no climate rows exist for the site-year; otherwise counts distinct valid calendar months after range QC.", "0-12; temp requires 12",
  "precip_n_months", "Valid annual-precipitation months", "climate", "months", "more coverage", "NA when no climate rows exist for the site-year; otherwise counts distinct valid calendar months after range QC.", "0-12; precip requires 12",
  "precip_winter_n_months", "Valid winter-rain months", "climate", "months", "more coverage", "NA when no Oct-Mar water-year rows exist; otherwise counts valid months in the six-month window.", "0-6; precip_winter requires 6",
  "precip_monsoon_n_months", "Valid monsoon-rain months", "climate", "months", "more coverage", "NA when no Jul-Sep rows exist; otherwise counts valid months in the three-month window.", "0-3; precip_monsoon requires 3",
  "temp_spring_n_months", "Valid spring-temperature months", "climate", "months", "more coverage", "NA when no Mar-May rows exist; otherwise counts valid months in the three-month window.", "0-3; temp_spring requires 3",
  "fruiting_n_eligible_months", "Eligible observed fruiting months", "producer", "months", "more opportunity", "Zero when monthly rows exist but none has finite fruiting status supported by >=5 individuals; counts observed opportunities, not fixed seasonal coverage.", "0-12 audit; fruiting remains context-only",
  "fruiting_peak_n_individuals", "Individuals behind observed-month fruiting peak", "producer", "individuals", "more support", "NA when no fruiting month qualifies; otherwise the minimum observed-individual count among months tied at the annual observed maximum.", ">=5 by construction; audit only",
  "greenup_n_onsets", "Candidate green-up individual-years", "phenology", "individuals", "more source support", "NA when no finite earliest green-up record exists that year. Includes left-censored first-visit-already-yes records before exclusions.", "audit total; must equal censored + taxon-excluded + contributors",
  "greenup_n_left_censored", "Left-censored green-up records", "phenology", "individuals", "more censoring", "NA when no candidate green-up record exists that year; otherwise counts earliest individual-year records whose first visit was already yes and therefore supplies only an upper bound. Exclusion is a screen, not interval-censored modeling, and may select contributors by visit timing/cadence.", "excluded from greenup_doy; audit censor burden",
  "greenup_n_taxon_excluded", "Composition/support-excluded green-up records", "phenology", "individuals", "more exclusions", "NA when no candidate record exists; otherwise counts uncensored individual-years excluded because taxon identity is unresolved, species-year n<3, species recurs in <3 eligible years, or the species belongs to a disconnected incidence component not selected for the site index.", "excluded from greenup_doy",
  "greenup_n_individuals", "Individuals supporting green-up index", "phenology", "individuals", "more support", "NA when no candidate record exists; zero when candidates exist but none survives censoring/composition gates; otherwise final non-left-censored contributors in the selected connected recurrent-species panel.", ">=2 species x >=3 individuals makes the emitted minimum 6",
  "greenup_n_species", "Species supporting green-up index", "phenology", "species", "more support", "NA when no candidate record exists; zero when none is eligible; otherwise recurrent resolved species contributing to the selected connected panel that year.", ">=2 required for greenup_doy",
  "greenup_reference_doy", "Green-up site reference anchor", "phenology", "day-of-year", "later anchor", "NA when the site has no eligible connected recurrent-species panel; otherwise the fixed equal-species median baseline repeated across site-years. It anchors anomalies for display and is not an observed annual onset.", "audit anchor; no annual gate",
  "greenup_doy_additive", "Green-up additive-model sensitivity", "phenology", "DOY-anchored index", "later", paste("NA on exactly the same site-years as greenup_doy. Alternate unweighted species + year OLS standardization on the same eligible connected cells, evaluated over every retained species x year and summarized by the fixed-species median. Values for missing species-years are additive-model extrapolations; neither this nor the median-centered primary estimator is uniquely true.", GREENUP_INDEX_NOTE), "same >=2-species/current-support gate as greenup_doy; sensitivity only, not a ladder signal",
  "greenup_onset_interval_median_days", "Median contributor onset interval width", "phenology", "days", "wider timing uncertainty", "NA when no final uncensored contributor survives the resolved/recurrent-species and connected-panel screens that year. Otherwise the median last-no to first-yes interval width across final contributors; tied earliest phases use the widest tied interval.", "audit only; values >14 days trigger a QC review flag; finite exactly when greenup_n_individuals > 0",
  "greenup_onset_interval_p90_days", "90th-percentile contributor onset interval width", "phenology", "days", "wider timing uncertainty", "NA when no final contributor survives. Otherwise the type-7 90th percentile of last-no to first-yes interval widths across final contributors; it is a cadence audit, not an annual-index confidence interval.", "audit only; finite exactly when greenup_n_individuals > 0",
  "greenup_onset_interval_max_days", "Maximum contributor onset interval width", "phenology", "days", "wider timing uncertainty", "NA when no final contributor survives. Otherwise the widest last-no to first-yes interval among final contributors; values >30 days trigger a QC review flag.", "audit only; finite exactly when greenup_n_individuals > 0",
  "plant_n_plots", "Sampled plant plots", "producer", "plots", "more effort", "NA when the plant bundle has no species observations that year.", "audit denominator; no inference gate",
  "plant_n_sampling_units", "Sampled plant units", "producer", "plot/subplot/scale/bouts", "more effort", "NA when the plant bundle has no species observations that year; nested scale and bout are part of the key.", "audit denominator; no inference gate",
  "plant_unknown_pct", "Cover with unresolved native status", "producer", "% cover", "more unresolved", "NA when total scored cover is zero; includes NI, UNK, blank, and any code other than N or I.", "total cover > 0",
  "mammal_trap_nights", "Small-mammal trap effort", "consumer", "trap-nights", "more effort", "NA when no trap records exist. A-J x 1-10 coordinates resolve physical events: reviewed status-4/5 multi-capture groups count once, while exactly two source-documented double-trap groups sum row weights. AX-JX, X1-X10, and XX placeholders remain row-level and can overstate effort when several rows came from one unknown trap; every unreviewed canonical duplicate aborts generation.", ">0 required for mammal_cpue",
  "mammal_captures", "Small-mammal captures", "consumer", "tagged capture rows", "more captures", "NA when the mammal bundle has no rows that year; each nonblank tagID is one capture row.", "paired with mammal_trap_nights",
  "mammal_placeholder_trap_rows", "Placeholder-coordinate mammal rows", "consumer", "source rows", "more uncertain effort", "NA when no mammal rows exist that year; otherwise the number of AX-JX, X1-X10, or XX source rows whose physical trap cannot be identified and whose effort therefore remains row-level.", "audit only; each row contributes its locked status weight",
  "mammal_multi_capture_trap_events", "Resolved multi-capture trap events", "consumer", "trap events", "more reviewed collapses", "NA when no mammal rows exist that year; otherwise canonical-coordinate duplicate groups carrying status 4 (optionally 5), all unique tagged animals, collapsed to one trap-night.", "audit only; exact reviewed structural rule",
  "mammal_reviewed_double_trap_events", "Source-documented double-trap events", "consumer", "coordinate-nights", "more documented exceptions", "NA when no mammal rows exist that year; otherwise canonical-coordinate two-row groups whose every remark contains the same one of two locked reviewed multi-trap markers; row effort is summed.", "audit only; exact reviewed remark rule",
  "bird_observed_point_visits", "Observed bird point-count occasions", "consumer", "point-visits", "more observed effort", "NA when the catch-only observation table has no detections that year; zero-detection visits are unavailable.", ">0 required for bird_index",
  "bird_nonflyover_birds", "Non-flyover bird detections", "consumer", "birds", "more detections", "NA when no observation rows exist that year; cluster sizes exclude detectionMethod=flyover.", "numerator of bird_index",
  "bird_flyover_birds", "Excluded flyover detections", "consumer", "birds", "more excluded detections", "NA when no observation rows exist that year; retained for audit but excluded from index and richness.", "audit only",
  "mosq_trap_nights", "Mosquito CO2-trap effort", "consumer", "trap-nights", "more effort", "NA when effort_week is unavailable that year; includes attempted zero-catch deployments.", ">0 required for mosq_activity",
  "mosq_total_catch", "Whole-trap mosquito catch", "consumer", "mosquitoes (estimated)", "more catch", "Zero when positive recorded effort has no target catch; NA when neither effort nor catch is available.", "numerator of mosq_activity",
  "beetle_catch_event_trap_nights", "Ground-beetle catch-event effort", "consumer", "trap-nights", "more recorded effort", "NA when no catch-bearing event with effort exists; source bundles omit zero-catch events.", ">0 required for beetle_activity; incomplete denominator",
  "beetle_total_catch", "Ground-beetle catch", "consumer", "individuals", "more catch", "NA when the catch-only beetle bundle has no positive catch that year.", "numerator of beetle_activity")
codebook <- dplyr::bind_rows(signal_codebook, support_codebook)
dir.create("data", showWarnings = FALSE)
codebook <- cascade_normalize_artifact_text(codebook)
cascade_assert_artifact_text(codebook, "codebook CSV source")
cascade_with_utf8_ctype(function()
  utils::write.csv(codebook, "data/neon-cascade-codebook.csv", row.names = FALSE,
                   fileEncoding = "UTF-8"))
cat("\ncodebook written: data/neon-cascade-codebook.csv (", nrow(codebook), "signals/support fields )\n")

coverage_signals <- c(mammal = "mammal_cpue", plant = "plant_richness",
                      bird = "bird_index", phe = "greenup_doy",
                      mosq = "mosq_activity", beetle = "beetle_activity")
product_coverage <- do.call(rbind, lapply(names(coverage_signals), function(product) {
  key <- coverage_signals[[product]]
  data.frame(product = product, signal = key,
             n_nonmissing = sum(is.finite(annual[[key]])),
             n_sites = length(unique(annual$site[is.finite(annual[[key]])])),
             stringsAsFactors = FALSE)
}))
climate_signals <- c("temp", "precip", "temp_spring")
product_coverage <- rbind(product_coverage, do.call(rbind, lapply(climate_signals, function(key) {
  data.frame(product = "mammal", signal = key,
             n_nonmissing = sum(is.finite(annual[[key]])),
             n_sites = length(unique(annual$site[is.finite(annual[[key]])])),
             stringsAsFactors = FALSE)
})))
eligible_site_count <- function(from, to) {
  paired <- tapply(is.finite(annual[[from]]) & is.finite(annual[[to]]),
                   annual$site, sum)
  sum(paired >= 6L)
}
vote_overlap <- data.frame(from = c("temp", "temp_spring"), to = "greenup_doy",
  n_sites_eligible = c(eligible_site_count("temp", "greenup_doy"),
                       eligible_site_count("temp_spring", "greenup_doy")),
  stringsAsFactors = FALSE)
if (any(vote_overlap$n_sites_eligible < 1L))
  stop(sprintf("vote-eligible climate/green-up overlap is empty for: %s",
               paste(vote_overlap$from[vote_overlap$n_sites_eligible < 1L],
                     collapse = ", ")), call. = FALSE)
product_coverage <- rbind(product_coverage, data.frame(
  product = "veg", signal = "veg_ba_ha",
  n_nonmissing = sum(is.finite(site_meta$veg_ba_ha)),
  n_sites = sum(is.finite(site_meta$veg_ba_ha)), stringsAsFactors = FALSE))

build_toolchain <- data.frame(
  component = c("R", "dplyr", "tibble"),
  version = c(as.character(getRversion()),
              as.character(utils::packageVersion("dplyr")),
              as.character(utils::packageVersion("tibble"))),
  stringsAsFactors = FALSE)

meta <- list(
  schema_version = CASCADE_BUNDLE_SCHEMA_VERSION,
  built = "complete-month annual/seasonal climate signals from seven sibling bundles; explicit exploratory prior family; cross-site precompute",
  n_sites = length(ALL_SITES),
  built_when = format(as.POSIXct(max(source_products$commit_epoch),
                                 origin = "1970-01-01", tz = "UTC"),
                      "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"),
  min_year = MIN_YEAR,
  last_complete_year = LAST_COMPLETE_YEAR,
  last_complete_year_basis = LAST_COMPLETE_YEAR_BASIS,
  last_complete_year_source_epoch = .source_cutoff_epoch,
  build_script_md5 = BUILD_SCRIPT_MD5,
  source_adapters_md5 = SOURCE_ADAPTERS_MD5,
  tier_rule = TIER_RULE_VERSION,
  prior_family_version = PRIOR_FAMILY_VERSION,
  prior_family_status = PRIOR_FAMILY_STATUS,
  greenup_index_version = GREENUP_INDEX_VERSION,
  greenup_index_note = GREENUP_INDEX_NOTE,
  trend_sensitivity_version = TREND_SENSITIVITY_VERSION,
  trend_sensitivity_note = TREND_SENSITIVITY_NOTE,
  estimator_sensitivity_version = ESTIMATOR_SENSITIVITY_VERSION,
  estimator_sensitivity_note = ESTIMATOR_SENSITIVITY_NOTE,
  spatial_sensitivity_version = SPATIAL_SENSITIVITY_VERSION,
  spatial_sensitivity_note = SPATIAL_SENSITIVITY_NOTE,
  source_snapshot_method = source_snapshot$method,
  source_products = source_products,
  source_inputs = source_inputs,
  local_build_inputs = LOCAL_BUILD_INPUTS,
  build_toolchain = build_toolchain,
  product_coverage = product_coverage,
  vote_overlap = vote_overlap,
  data_caveats = c(
    biome_class = BIOME_CLASS_METHOD,
    spatial_sensitivity = SPATIAL_SENSITIVITY_NOTE,
    fruiting_pct = "Opportunistic maximum across observed months with >=5 individuals, not a fixed-season annual estimate. fruiting_n_eligible_months and fruiting_peak_n_individuals expose unequal opportunity/support; context-only and excluded from pooled inference.",
    veg_ba_ha = CASCADE_VEG_STAND_BASIS,
    veg_type = CASCADE_VEG_CLASSIFICATION_BASIS,
    veg_design_support = CASCADE_VEG_DESIGN_BASIS,
    mammal_cpue = "Mammal effort resolves only exact A-J x 1-10 coordinates as physical trap events. Canonical status-4/5 multi-animal groups count one trap-night; two exact source-reviewed remark patterns document double traps and sum their two row weights. AX-JX, X1-X10, and XX are non-unique placeholders retained as row-level effort, which can overstate effort. Every other duplicated canonical event or coordinate token fails closed. Each nonblank tag row remains a capture, including repeated tags at distinct trap events.",
    bird_index = "Annual bird bundles lack a year-specific all-visits effort table. Denominator is observed pointkey x eventID occasions, so zero-detection visits are absent; flyovers are excluded.",
    beetle_activity = "Beetle site bundles contain catch rows only. Trap-night denominator covers unique catch-bearing plot-dates and omits zero-catch events.",
    greenup_doy = paste("Composition-adjusted DOY-anchored onset index: earliest individual-year green-up records that are left-censored are excluded; this screen is not interval-censored modeling and can select contributors by visit timing/cadence. Resolved species need >=3 individuals in >=3 years; the largest connected species-year panel is within-species centered and equal-species weighted; annual output needs >=2 species and therefore >=6 contributors. Annual median/p90/max last-no to first-yes widths expose contributor timing uncertainty. It is not an observed pooled-median onset date.", GREENUP_INDEX_NOTE),
    greenup_doy_additive = paste("Estimator-choice sensitivity using unweighted OLS species_onset ~ scientificName + factor(year) on the same connected eligible species-year cells, standardized over the full retained species x year grid. It shares the primary index's left-censor screen and its visit-timing/cadence selection caveat. Missing species-years are additive extrapolations. Neither the additive nor median-centered standardization is uniquely true; their differences expose sensitivity to the unbalanced observation panel.", GREENUP_INDEX_NOTE),
    plant_richness = "Raw annual richness remains sensitive to sampled plots/scales; plant_n_plots and plant_n_sampling_units are persisted for audit."))
assert_local_build_inputs_unchanged()
cascade_bundle <- cascade_normalize_artifact_text(list(
  annual = annual, signals = signals, priors = priors, codebook = codebook,
  suite_links = suite_links, pooled = pooled, site_meta = site_meta, meta = meta))
cascade_assert_artifact_text(cascade_bundle, "data/cascade.rds")
saveRDS(cascade_bundle, "data/cascade.rds")

# ---- coverage report ----
cat("\nannual rows:", nrow(annual), "| sites:", length(unique(annual$site)), "\n")
covg <- annual %>% group_by(site) %>% summarise(
  yrs = dplyr::n(), greenup = sum(!is.na(greenup_doy)), plant = sum(!is.na(plant_richness)),
  mammal = sum(!is.na(mammal_cpue)), bird = sum(!is.na(bird_index)), precip = sum(!is.na(precip)),
  layers = (any(!is.na(precip)|!is.na(temp))) + (any(!is.na(greenup_doy))) +
           (any(!is.na(plant_richness)|!is.na(fruiting_pct))) + (any(!is.na(mammal_cpue)|!is.na(bird_index))),
  .groups="drop") %>% arrange(desc(layers), desc(greenup+plant))
cat("\nTop atlas sites (by measurement layers present):\n")
print(as.data.frame(head(covg[covg$layers>=3,], 12)))

cat("\n==== POOLED cross-site exploratory direction summary ====\n")
print(pooled, row.names = FALSE)
cat("\nSRER seasonal climate audit columns:\n")
print(as.data.frame(annual[annual$site == "SRER", c("year","precip","precip_winter","precip_monsoon","temp","greenup_doy","plant_richness","mammal_cpue")]), row.names = FALSE)

# Derived artifacts and the deploy manifest are deliberately not built here.
# Run scripts/rebuild_all.R so cascade, search, meta, tests, and manifest advance
# together or are rolled back together on failure.
cat("\nCascade bundle written. Next: Rscript scripts/rebuild_all.R (complete transactional rebuild).\n")
