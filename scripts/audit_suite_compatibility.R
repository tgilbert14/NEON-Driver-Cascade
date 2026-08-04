#!/usr/bin/env Rscript

# Read-only Driver v2 compatibility audit.
#
# The audit reads exact committed RDS blobs directly from the nine sibling Git
# repositories. It does not check out a moving branch, execute sibling code,
# write a repository artifact, or run the canonical Driver rebuild. Output is CSV on
# stdout; diagnostics go to stderr. Run once per product so one process never
# retains several large release families at the same time:
#   Rscript --vanilla scripts/audit_suite_compatibility.R /path/to/repos mammal

args <- commandArgs(trailingOnly = TRUE)
repos_root <- if (length(args)) args[[1L]] else file.path(getwd(), "..", "..", "repos")
repos_root <- normalizePath(repos_root, winslash = "/", mustWork = TRUE)

authority_path <- "docs/driver-v2-compatibility.csv"
authority <- read.csv(authority_path, stringsAsFactors = FALSE,
                      check.names = FALSE, colClasses = "character",
                      na.strings = "UNMEASURED")
expected_products <- c("mammal", "phenology", "plant_diversity", "vegetation",
                       "ground_beetle", "mosquito", "birds", "water_chemistry",
                       "inverts")
required_authority_columns <- c(
  "product", "system", "data_authority", "knowledge_authority",
  "audited_default_head", "support_basis")
if (!all(required_authority_columns %in% names(authority)) ||
    !setequal(authority$product, expected_products) || anyDuplicated(authority$product))
  stop(sprintf("invalid authority ledger: %s", authority_path), call. = FALSE)
authority <- authority[match(expected_products, authority$product), , drop = FALSE]

pins <- data.frame(
  product = expected_products,
  repo_dir = c("NEON-Small-Mammal-Tracker-App",
               "NEON-Plant-Phenology-Explorer", "NEON-Plant-Diversity",
               "NEON-Vegetation-Structure-Explorer",
               "NEON-Ground-Beetle-Tracker", "NEON-Mosquito-Pulse",
               "NEON-Breeding-Birds",
               "NEON-WaterChemistry-Analyte-Viewer-App",
               "NEON-My-Little-Inverts"),
  data_commit = authority$data_authority,
  knowledge_commit = authority$knowledge_authority,
  audited_default_head = authority$audited_default_head,
  system = authority$system,
  support_basis = authority$support_basis,
  stringsAsFactors = FALSE)

only_product <- if (length(args) >= 2L) args[[2L]] else ""
if (!nzchar(only_product))
  stop("usage: audit_suite_compatibility.R <repos-root> <product>",
       call. = FALSE)
if (nzchar(only_product) && !only_product %in% pins$product)
  stop(sprintf("unknown product '%s'; choose one of: %s", only_product,
               paste(pins$product, collapse = ", ")), call. = FALSE)
audit_rows <- which(pins$product == only_product)

run_git <- function(repo, args, binary = FALSE, binary_n = NULL) {
  git <- Sys.which("git")
  if (!nzchar(git)) stop("git is required", call. = FALSE)
  if (binary) {
    if (length(binary_n) != 1L || !is.finite(binary_n) || binary_n < 0)
      stop("binary Git reads require one finite nonnegative blob size",
           call. = FALSE)
    cmd <- paste(c(shQuote(git), "-C", shQuote(repo), args), collapse = " ")
    con <- pipe(cmd, open = "rb")
    on.exit(close(con), add = TRUE)
    return(readBin(con, what = "raw", n = as.integer(binary_n)))
  }
  out <- suppressWarnings(system2(git, c("-C", repo, args), stdout = TRUE,
                                  stderr = TRUE))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L)
    stop(paste(out, collapse = "\n"), call. = FALSE)
  out
}

assert_commit <- function(repo, commit) {
  out <- run_git(repo, c("cat-file", "-t", paste0(commit, "^{commit}")))
  if (!identical(out[[1L]], "commit"))
    stop(sprintf("%s is not a commit in %s", commit, repo), call. = FALSE)
  invisible(TRUE)
}

assert_ancestor <- function(repo, ancestor, descendant, label) {
  status <- suppressWarnings(system2(
    Sys.which("git"), c("-C", repo, "merge-base", "--is-ancestor",
                        ancestor, descendant),
    stdout = FALSE, stderr = FALSE))
  if (!identical(status, 0L))
    stop(sprintf("%s %s is not an ancestor of audited default %s in %s",
                 label, ancestor, descendant, repo), call. = FALSE)
  invisible(TRUE)
}

git_path_exists <- function(repo, commit, path) {
  out <- suppressWarnings(system2(
    Sys.which("git"), c("-C", repo, "cat-file", "-e",
                        paste0(commit, ":", path)),
    stdout = FALSE, stderr = FALSE))
  identical(out, 0L)
}

git_paths <- function(repo, commit, prefix, pattern = NULL) {
  out <- run_git(repo, c("ls-tree", "-r", "--name-only", commit, prefix))
  if (!is.null(pattern)) out <- out[grepl(pattern, out, perl = TRUE)]
  sort(out, method = "radix")
}

git_object_id <- function(repo, commit, path) {
  object <- paste0(commit, ":", path)
  if (!git_path_exists(repo, commit, path)) return(NA_character_)
  out <- run_git(repo, c("rev-parse", object))
  if (length(out) != 1L || !grepl("^[0-9a-f]{40}$", out[[1L]]))
    stop(sprintf("invalid object ID for %s", object), call. = FALSE)
  out[[1L]]
}

git_rds <- function(repo, commit, path) {
  if (!git_path_exists(repo, commit, path))
    stop(sprintf("missing Git object %s:%s", commit, path), call. = FALSE)
  object <- paste0(commit, ":", path)
  blob_size <- suppressWarnings(as.numeric(run_git(
    repo, c("cat-file", "-s", object))[[1L]]))
  if (!is.finite(blob_size) || blob_size < 1 || blob_size > .Machine$integer.max)
    stop(sprintf("invalid Git blob size for %s", object), call. = FALSE)
  bytes <- run_git(repo, c("show", object), binary = TRUE,
                   binary_n = blob_size)
  if (length(bytes) != blob_size)
    stop(sprintf("short Git blob read for %s: expected %d, got %d bytes",
                 object, as.integer(blob_size), length(bytes)), call. = FALSE)
  staged <- tempfile("cascade-synthesis-", fileext = ".rds")
  on.exit(unlink(staged, force = TRUE), add = TRUE)
  con <- file(staged, open = "wb")
  writeBin(bytes, con)
  close(con)
  rm(bytes)
  # readRDS streams the blob's native xz/gzip compression. This bounds memory
  # across large exact families better than inflating a second full raw vector.
  readRDS(staged)
}

site_from_path <- function(path) sub("[.]rds$", "", basename(path))
year_of <- function(x) suppressWarnings(as.integer(format(as.Date(x), "%Y")))

keys <- function(site, year) {
  if (!length(year) || !length(site))
    return(data.frame(site = character(), year = integer()))
  if (length(site) == 1L && length(year) > 1L) site <- rep(site, length(year))
  out <- data.frame(site = as.character(site), year = suppressWarnings(as.integer(year)),
                    stringsAsFactors = FALSE)
  out <- out[!is.na(out$site) & nzchar(out$site) & is.finite(out$year), , drop = FALSE]
  unique(out)
}

bind_keys <- function(parts) {
  parts <- Filter(function(x) is.data.frame(x) && nrow(x), parts)
  if (!length(parts)) return(data.frame(site = character(), year = integer()))
  unique(do.call(rbind, parts))
}

site_bundle_paths <- function(repo, commit) {
  git_paths(repo, commit, "data/sites", "^data/sites/[A-Z0-9]{4}[.]rds$")
}

extract_site_family <- function(repo, commit, extractor) {
  paths <- site_bundle_paths(repo, commit)
  if (!length(paths)) stop(sprintf("no site bundles at %s", commit), call. = FALSE)
  source <- vector("list", length(paths))
  supported <- vector("list", length(paths))
  for (i in seq_along(paths)) {
    site <- site_from_path(paths[[i]])
    bundle <- git_rds(repo, commit, paths[[i]])
    value <- extractor(bundle, site)
    source[[i]] <- value$source
    supported[[i]] <- value$supported
    rm(bundle, value)
    if (i %% 4L == 0L) invisible(gc(verbose = FALSE))
  }
  list(source = bind_keys(source),
       supported = if (all(vapply(supported, is.null, logical(1)))) NULL else
         bind_keys(supported))
}

extractors <- list(
  mammal = function(x, site) {
    stopifnot(is.data.frame(x), all(c("collectDate", "trapStatus") %in% names(x)))
    yr <- year_of(x$collectDate)
    weights <- c(
      "1 - trap not set" = 0,
      "2 - trap disturbed/door closed but empty" = 0.5,
      "3 - trap door open or closed w/ spoor left" = 0.5,
      "4 - more than 1 capture in one trap" = 1,
      "5 - capture" = 1,
      "6 - trap set and empty" = 1)
    token <- tolower(trimws(as.character(x$trapStatus)))
    effort <- unname(weights[token])
    if (anyNA(effort)) stop(sprintf("%s has an unknown mammal effort token", site),
                            call. = FALSE)
    list(source = keys(site, yr), supported = keys(site, yr[effort > 0]))
  },
  phenology = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$obs),
              is.null(x$trend) || is.data.frame(x$trend))
    if (is.null(x$trend) || !nrow(x$trend))
      return(list(source = keys(site, x$obs$year),
                  supported = data.frame(site = character(), year = integer())))
    stopifnot(all(c("year", "onset") %in% names(x$trend)))
    list(source = keys(site, x$obs$year),
         supported = keys(site, x$trend$year[is.finite(x$trend$onset)]))
  },
  plant_diversity = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$occ), "year" %in% names(x$occ))
    list(source = keys(site, x$occ$year), supported = NULL)
  },
  vegetation = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$plots),
              all(c("year", "tree_supported", "shrub_supported") %in% names(x$plots)))
    ok <- x$plots$tree_supported %in% TRUE | x$plots$shrub_supported %in% TRUE
    list(source = keys(site, x$plots$year),
         supported = keys(site, x$plots$year[ok]))
  },
  ground_beetle = function(x, site) {
    stopifnot(is.data.frame(x),
              all(c("collectDate", "sampled_opportunity", "trapnights") %in% names(x)))
    yr <- year_of(x$collectDate)
    ok <- x$sampled_opportunity %in% TRUE & is.finite(x$trapnights) & x$trapnights > 0
    list(source = keys(site, yr), supported = keys(site, yr[ok]))
  },
  mosquito = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$effort),
              all(c("year", "valid_effort", "effort_days") %in% names(x$effort)))
    ok <- x$effort$valid_effort %in% TRUE & is.finite(x$effort$effort_days) &
      x$effort$effort_days > 0
    list(source = keys(site, x$effort$year),
         supported = keys(site, x$effort$year[ok]))
  },
  birds = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$visits),
              all(c("year", "valid_count") %in% names(x$visits)))
    list(source = keys(site, x$visits$year),
         supported = keys(site, x$visits$year[x$visits$valid_count %in% TRUE]))
  },
  inverts = function(x, site) {
    stopifnot(is.list(x), is.data.frame(x$opportunities),
              all(c("collectDate", "density_eligible") %in% names(x$opportunities)))
    yr <- year_of(x$opportunities$collectDate)
    list(source = keys(site, yr),
         supported = keys(site, yr[x$opportunities$density_eligible %in% TRUE]))
  })

required_rows <- unique(c(audit_rows,
                          if (any(pins$product[audit_rows] %in%
                                  c("water_chemistry", "inverts")))
                            which(pins$product == "water_chemistry") else integer()))
for (i in required_rows) {
  repo <- file.path(repos_root, pins$repo_dir[[i]])
  if (!dir.exists(repo)) stop(sprintf("missing sibling repository: %s", repo),
                              call. = FALSE)
  assert_commit(repo, pins$data_commit[[i]])
  assert_commit(repo, pins$knowledge_commit[[i]])
  assert_commit(repo, pins$audited_default_head[[i]])
  assert_ancestor(repo, pins$data_commit[[i]], pins$audited_default_head[[i]],
                  "data authority")
  assert_ancestor(repo, pins$knowledge_commit[[i]], pins$audited_default_head[[i]],
                  "knowledge authority")
}

driver <- readRDS("data/cascade.rds")
stopifnot(is.list(driver), is.data.frame(driver$annual),
          is.data.frame(driver$site_meta), is.list(driver$meta),
          is.data.frame(driver$meta$source_products))
driver_keys <- keys(driver$annual$site, driver$annual$year)
driver_domains <- unique(merge(
  driver_keys, driver$site_meta[, c("site", "domain"), drop = FALSE],
  by = "site", all.x = TRUE))
driver_domain_year <- unique(driver_domains[, c("domain", "year"), drop = FALSE])

# The Water release supplies the exact aquatic site-to-domain map shared by the
# 34-site Water/Inverts panel. Domain-year is a labeled proxy diagnostic only;
# it is never a direct site join.
water_bundle <- NULL
aquatic_domains <- NULL
if (any(pins$product[audit_rows] %in% c("water_chemistry", "inverts"))) {
  water_row <- which(pins$product == "water_chemistry")
  water_repo <- file.path(repos_root, pins$repo_dir[[water_row]])
  water_bundle <- git_rds(water_repo, pins$data_commit[[water_row]],
                          "data/neon_swc.rds")
  stopifnot(is.list(water_bundle), is.data.frame(water_bundle$swc_long),
            is.data.frame(water_bundle$sites_meta),
            all(c("site", "domain") %in% names(water_bundle$sites_meta)))
  aquatic_domains <- unique(
    water_bundle$sites_meta[, c("site", "domain"), drop = FALSE])
}

families <- list()
for (i in audit_rows) {
  product <- pins$product[[i]]
  message(sprintf("Auditing %s at %s", product,
                  substr(pins$data_commit[[i]], 1L, 8L)))
  repo <- file.path(repos_root, pins$repo_dir[[i]])
  commit <- pins$data_commit[[i]]
  if (identical(product, "water_chemistry")) {
    yr <- year_of(water_bundle$swc_long$collectDate)
    families[[product]] <- list(
      source = keys(water_bundle$swc_long$site, yr),
      supported = keys(water_bundle$swc_long$site, yr))
  } else if (identical(product, "plant_diversity")) {
    # The frozen Plant family has an exact 46-site index but no sampled-empty
    # opportunity ledger or trustworthy annual eligibility table. Reading
    # occurrence rows would measure observation-conditioned presence, not the
    # support required by its knowledge package, so keep site-year explicitly
    # UNMEASURED instead of manufacturing a denominator.
    site_index <- git_rds(repo, commit, "data/site_index.rds")
    stopifnot(is.data.frame(site_index), "site" %in% names(site_index))
    families[[product]] <- list(
      source = NULL, supported = NULL,
      source_sites = sort(unique(as.character(site_index$site)), method = "radix"))
  } else {
    families[[product]] <- extract_site_family(repo, commit, extractors[[product]])
  }
}

rate <- function(numerator, denominator) {
  if (is.na(numerator) || is.na(denominator) || denominator == 0L) return(NA_real_)
  round(numerator / denominator, 6)
}

n_sites_ge <- function(x, floor = 6L) {
  if (is.null(x)) return(NA_integer_)
  if (!nrow(x)) return(0L)
  n <- table(x$site)
  as.integer(sum(n >= floor))
}

result <- vector("list", length(audit_rows))
driver_pins <- driver$meta$source_products
for (out_i in seq_along(audit_rows)) {
  i <- audit_rows[[out_i]]
  product <- pins$product[[i]]
  family <- families[[product]]
  source <- family$source
  supported <- family$supported
  source_join <- if (is.null(source)) NULL else
    merge(source, driver_keys, by = c("site", "year"))
  supported_join <- if (is.null(supported)) NULL else
    merge(supported, driver_keys, by = c("site", "year"))
  domain_join <- NULL
  if (identical(pins$system[[i]], "aquatic") && !is.null(supported)) {
    with_domain <- merge(supported, aquatic_domains, by = "site", all.x = TRUE)
    if (anyNA(with_domain$domain))
      stop(sprintf("%s has supported sites absent from the exact aquatic domain map",
                   product), call. = FALSE)
    domain_join <- merge(with_domain, driver_domain_year, by = c("domain", "year"))
  }
  driver_name_map <- c(mammal = "mammal", phenology = "phe",
                       plant_diversity = "plant", vegetation = "veg",
                       ground_beetle = "beetle", mosquito = "mosq",
                       birds = "bird")
  driver_name <- if (product %in% names(driver_name_map))
    unname(driver_name_map[[product]]) else NULL
  pin_hit <- if (is.null(driver_name)) integer() else
    which(driver_pins$product == driver_name)
  current_pin <- if (length(pin_hit) == 1L) driver_pins$commit[[pin_hit]] else NA_character_
  consumed_paths <- switch(
    product,
    mammal = c("data/sites", "data/env"),
    water_chemistry = "data/neon_swc.rds",
    "data/sites")
  consumed_tree_matches <- NA
  production_tree_matches <- NA
  if (!is.na(current_pin)) {
    old_objects <- vapply(consumed_paths, function(path)
      git_object_id(file.path(repos_root, pins$repo_dir[[i]]), current_pin, path),
      character(1))
    new_objects <- vapply(consumed_paths, function(path)
      git_object_id(file.path(repos_root, pins$repo_dir[[i]]),
                    pins$data_commit[[i]], path), character(1))
    if (anyNA(old_objects) || anyNA(new_objects))
      stop(sprintf("%s Driver-pin comparison has a missing consumed object at %s",
                   product, paste(consumed_paths, collapse = ", ")), call. = FALSE)
    consumed_tree_matches <- identical(old_objects, new_objects)
  }
  data_objects <- vapply(consumed_paths, function(path)
    git_object_id(file.path(repos_root, pins$repo_dir[[i]]),
                  pins$data_commit[[i]], path), character(1))
  head_objects <- vapply(consumed_paths, function(path)
    git_object_id(file.path(repos_root, pins$repo_dir[[i]]),
                  pins$audited_default_head[[i]], path), character(1))
  if (anyNA(data_objects) || anyNA(head_objects))
    stop(sprintf("%s production comparison has a missing consumed object at %s",
                 product, paste(consumed_paths, collapse = ", ")), call. = FALSE)
  production_tree_matches <- identical(data_objects, head_objects)
  if (!production_tree_matches)
    stop(sprintf("%s audited default no longer matches the pinned data authority at %s",
                 product, paste(consumed_paths, collapse = ", ")), call. = FALSE)
  knowledge_path <- "docs/DRIVER-KNOWLEDGE-PACKAGE.md"
  knowledge_present <- git_path_exists(
    file.path(repos_root, pins$repo_dir[[i]]), pins$knowledge_commit[[i]],
    knowledge_path)
  if (!knowledge_present)
    stop(sprintf("%s knowledge authority lacks %s", product, knowledge_path),
         call. = FALSE)
  result[[out_i]] <- data.frame(
    product = product,
    system = pins$system[[i]],
    data_commit = pins$data_commit[[i]],
    knowledge_commit = pins$knowledge_commit[[i]],
    audited_default_head = pins$audited_default_head[[i]],
    knowledge_package_present = knowledge_present,
    current_driver_pin = current_pin,
    current_pin_matches_data_commit = !is.na(current_pin) &&
      identical(current_pin, pins$data_commit[[i]]),
    consumed_data_tree_matches_current_pin = consumed_tree_matches,
    data_tree_matches_audited_default_head = production_tree_matches,
    support_basis = pins$support_basis[[i]],
    source_sites = if (is.null(source)) length(family$source_sites) else
      length(unique(source$site)),
    source_site_years = if (is.null(source)) NA_integer_ else nrow(source),
    app_supported_sites = if (is.null(supported)) NA_integer_ else
      length(unique(supported$site)),
    app_supported_site_years = if (is.null(supported)) NA_integer_ else nrow(supported),
    app_supported_sites_n_ge_6_years = n_sites_ge(supported),
    direct_source_join_sites = if (is.null(source_join)) NA_integer_ else
      length(unique(source_join$site)),
    direct_source_join_site_years = if (is.null(source_join)) NA_integer_ else
      nrow(source_join),
    direct_source_join_rate = if (is.null(source_join)) NA_real_ else
      rate(nrow(source_join), nrow(source)),
    direct_supported_join_sites = if (is.null(supported_join)) NA_integer_ else
      length(unique(supported_join$site)),
    direct_supported_join_site_years = if (is.null(supported_join)) NA_integer_ else
      nrow(supported_join),
    direct_supported_join_rate = if (is.null(supported_join)) NA_real_ else
      rate(nrow(supported_join), nrow(supported)),
    direct_supported_sites_n_ge_6_years = n_sites_ge(supported_join),
    domain_proxy_supported_site_years = if (is.null(domain_join)) NA_integer_ else
      nrow(unique(domain_join[, c("site", "year"), drop = FALSE])),
    domain_proxy_supported_rate = if (is.null(domain_join)) NA_real_ else
      rate(nrow(unique(domain_join[, c("site", "year"), drop = FALSE])),
           nrow(supported)),
    stringsAsFactors = FALSE)
}

out <- do.call(rbind, result)
write.csv(out, stdout(), row.names = FALSE, na = "UNMEASURED", quote = TRUE)
