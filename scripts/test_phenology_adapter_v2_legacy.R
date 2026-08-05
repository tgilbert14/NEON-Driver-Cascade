#!/usr/bin/env Rscript

# Seal 2: effect-blind parity of the frozen Phenology compatibility adapter
# against the exact legacy source tree and the unchanged Driver v1 surface.
#
# The default entry point is intentionally machine-only: success emits one JSON
# object and nothing else.  Development-only --static and --synthetic modes do
# not deserialize either a legacy bundle or a Driver artifact.

SEAL2_SCHEMA <- "phenology-v2-seal2-legacy-parity/v1"
SEAL2_LEGACY_COMMIT <- "81e339e9ed6f34d3d04ca45a7030fea51c4147a5"
SEAL2_LEGACY_TREE <- "30abe869b0f78931929c21e544ffc85ec2238e35"
SEAL2_BUNDLE_COUNT <- 46L
SEAL2_DRIVER_YEARS <- 2013:2025
SEAL2_TARGET_PHASES <- c(
  "Breaking leaf buds", "Initial growth", "Emerging needles",
  "Breaking needle buds"
)

SEAL2_FIELD_MAP <- c(
  greenup_doy = "greenup_doy_compat",
  greenup_doy_additive = "greenup_doy_additive_compat",
  greenup_n_onsets = "compat_n_onsets",
  greenup_n_left_censored = "compat_n_left_censored",
  greenup_n_taxon_excluded = "compat_n_excluded_umbrella",
  greenup_n_individuals = "compat_n_individuals",
  greenup_n_species = "compat_n_species",
  greenup_reference_doy = "compat_reference_doy",
  greenup_onset_interval_median_days = "compat_interval_median_days",
  greenup_onset_interval_p90_days = "compat_interval_p90_days",
  greenup_onset_interval_max_days = "compat_interval_max_days"
)
SEAL2_INTEGER_FIELDS <- c(
  "greenup_n_onsets", "greenup_n_left_censored",
  "greenup_n_taxon_excluded", "greenup_n_individuals",
  "greenup_n_species"
)
SEAL2_ADDITIVE_FIELD <- "greenup_doy_additive"
SEAL2_STRICT_TOLERANCE <- 1e-15
SEAL2_ADDITIVE_TOLERANCE <- 1e-12
SEAL2_EXPECTED <- c(
  source_support_rows = 345L,
  finite_compatibility_rows = 269L,
  finite_compatibility_sites = 40L,
  finite_sites_ge_6 = 31L,
  annual_temperature_sites_ge_6 = 18L,
  spring_temperature_sites_ge_6 = 18L,
  fields_compared = 11L
)
SEAL2_ARTIFACTS <- c(
  "data/cascade.rds", "data/search_index.rds", "data/cascade_meta.rds",
  "data/neon-cascade-codebook.csv", "manifest.json"
)

seal2_condition <- function(code) {
  structure(
    list(message = sprintf("Phenology Seal-2 failure [%s]", code),
         call = NULL, seal2_code = code),
    class = c("seal2_error", "error", "condition")
  )
}

seal2_abort <- function(code) stop(seal2_condition(code))

seal2_assert <- function(value, code) {
  if (length(value) != 1L || is.na(value) || !isTRUE(value)) seal2_abort(code)
  invisible(TRUE)
}

seal2_script_path <- function() {
  hit <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  seal2_assert(length(hit) == 1L, "script_path")
  normalizePath(sub("^--file=", "", hit), winslash = "/", mustWork = TRUE)
}

seal2_repo_root <- function() {
  here <- dirname(seal2_script_path())
  candidate <- normalizePath(file.path(here, ".."), winslash = "/", mustWork = TRUE)
  seal2_assert(file.exists(file.path(candidate, "R", "phenology_adapter_v2.R")),
               "repository_root")
  candidate
}

seal2_with_repo <- function(code) {
  previous <- getwd()
  on.exit(setwd(previous), add = TRUE)
  setwd(seal2_repo_root())
  force(code)
}

seal2_nonblank <- function(x) {
  value <- as.character(x)
  !is.na(value) & nzchar(trimws(value))
}

oracle_key_part <- function(x) {
  value <- enc2utf8(as.character(x))
  missing <- is.na(x) | is.na(value)
  out <- character(length(value))
  out[missing] <- "-1:"
  if (any(!missing)) {
    bytes <- nchar(value[!missing], type = "bytes", allowNA = FALSE)
    out[!missing] <- paste0(bytes, ":", value[!missing])
  }
  out
}

oracle_key <- function(...) {
  columns <- list(...)
  seal2_assert(length(columns) > 0L, "oracle_key_arity")
  lengths <- lengths(columns)
  seal2_assert(length(unique(lengths)) == 1L, "oracle_key_length")
  do.call(paste, c(lapply(columns, oracle_key_part), sep = "\034"))
}

oracle_groups <- function(key) {
  if (!length(key)) return(list())
  levels <- sort(unique(key), method = "radix", na.last = TRUE)
  lapply(levels, function(level) which(key == level))
}

oracle_order <- function(...) {
  columns <- lapply(list(...), function(x) {
    if (is.character(x) || is.factor(x)) enc2utf8(as.character(x)) else x
  })
  do.call(order, c(columns, list(na.last = TRUE, method = "radix")))
}

oracle_median <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  seal2_assert(length(x) > 0L, "oracle_empty_median")
  x <- sort(x, method = "radix")
  n <- length(x)
  if (n %% 2L) x[(n + 1L) %/% 2L] else (x[n %/% 2L] + x[n %/% 2L + 1L]) / 2
}

oracle_quantile_type7 <- function(x, probability) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  seal2_assert(length(x) > 0L, "oracle_empty_quantile")
  seal2_assert(length(probability) == 1L && is.finite(probability) &&
                 probability >= 0 && probability <= 1,
               "oracle_quantile_probability")
  x <- sort(x, method = "radix")
  if (length(x) == 1L) return(x)
  index <- 1 + (length(x) - 1) * probability
  lower <- floor(index)
  upper <- ceiling(index)
  if (lower == upper) return(x[lower])
  x[lower] + (index - lower) * (x[upper] - x[lower])
}

oracle_empty_annual <- function() {
  data.frame(
    site = character(), year = integer(),
    greenup_doy = numeric(), greenup_doy_additive = numeric(),
    greenup_n_onsets = integer(), greenup_n_left_censored = integer(),
    greenup_n_taxon_excluded = integer(), greenup_n_individuals = integer(),
    greenup_n_species = integer(), greenup_reference_doy = numeric(),
    greenup_onset_interval_median_days = numeric(),
    greenup_onset_interval_p90_days = numeric(),
    greenup_onset_interval_max_days = numeric(),
    stringsAsFactors = FALSE
  )
}

oracle_bind <- function(rows, template) {
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(template)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

oracle_validate_observations <- function(obs) {
  seal2_assert(is.data.frame(obs), "oracle_observation_container")
  seal2_assert(!is.null(names(obs)) && !anyNA(names(obs)) &&
                 !any(!nzchar(names(obs))) && !anyDuplicated(names(obs)),
               "oracle_observation_names")
  required <- c(
    "individualID", "scientificName", "growthForm", "phenophaseName",
    "year", "dayOfYear", "status", "is_species"
  )
  seal2_assert(all(required %in% names(obs)), "oracle_observation_schema")
  seal2_assert(is.numeric(obs$year) && is.numeric(obs$dayOfYear),
               "oracle_observation_numeric_schema")
  seal2_assert(is.logical(obs$is_species), "oracle_observation_rank_schema")
  seal2_assert(all(seal2_nonblank(obs$individualID)), "oracle_observation_identity")
  invisible(TRUE)
}

oracle_phase_records <- function(obs, site) {
  keep <- obs$phenophaseName %in% SEAL2_TARGET_PHASES &
    obs$status %in% c("yes", "no") & is.finite(obs$dayOfYear) &
    is.finite(obs$year)
  d <- obs[keep, , drop = FALSE]
  template <- data.frame(
    site = character(), individualID = character(), scientificName = character(),
    growthForm = character(), phenophaseName = character(), year = integer(),
    onset = numeric(), left_censored = logical(), first_yes = numeric(),
    stringsAsFactors = FALSE
  )
  if (!nrow(d)) return(template)
  key <- oracle_key(
    d$individualID, d$scientificName, d$growthForm,
    d$phenophaseName, as.integer(d$year)
  )
  rows <- lapply(oracle_groups(key), function(ix) {
    x <- d[ix, , drop = FALSE]
    yes <- as.numeric(x$dayOfYear[x$status == "yes"])
    if (!length(yes)) return(NULL)
    no <- as.numeric(x$dayOfYear[x$status == "no"])
    first_yes <- min(yes)
    preceding <- no[no < first_yes]
    left <- !length(preceding)
    onset <- if (left) first_yes else (max(preceding) + first_yes) / 2
    data.frame(
      site = site, individualID = as.character(x$individualID[1L]),
      scientificName = as.character(x$scientificName[1L]),
      growthForm = as.character(x$growthForm[1L]),
      phenophaseName = as.character(x$phenophaseName[1L]),
      year = as.integer(x$year[1L]), onset = as.numeric(onset),
      left_censored = left, first_yes = as.numeric(first_yes),
      stringsAsFactors = FALSE
    )
  })
  out <- oracle_bind(rows, template)
  if (nrow(out)) {
    out <- out[oracle_order(
      out$site, out$year, out$individualID, out$phenophaseName,
      out$scientificName
    ), , drop = FALSE]
    rownames(out) <- NULL
  }
  out
}

oracle_individual_years <- function(phases, obs) {
  template <- data.frame(
    site = character(), individualID = character(), year = integer(),
    scientificName = character(), onset = numeric(),
    left_censored = logical(), interval_days = numeric(),
    is_species = logical(), stringsAsFactors = FALSE
  )
  if (!nrow(phases)) return(template)
  key <- oracle_key(phases$site, phases$individualID, phases$year)
  rows <- lapply(oracle_groups(key), function(ix) {
    d <- phases[ix, , drop = FALSE]
    onset <- min(d$onset)
    tied <- which(d$onset == onset)
    taxa <- sort(unique(enc2utf8(as.character(d$scientificName[tied]))),
                 method = "radix", na.last = TRUE)
    taxa <- taxa[!is.na(taxa) & nzchar(taxa)]
    widths <- 2 * (d$first_yes[tied] - d$onset[tied])
    widths <- widths[is.finite(widths)]
    data.frame(
      site = as.character(d$site[1L]),
      individualID = as.character(d$individualID[1L]),
      year = as.integer(d$year[1L]),
      scientificName = if (length(taxa)) taxa[1L] else NA_character_,
      onset = as.numeric(onset),
      left_censored = any(d$left_censored[tied] %in% TRUE),
      interval_days = if (length(widths)) max(widths) else NA_real_,
      is_species = NA,
      stringsAsFactors = FALSE
    )
  })
  out <- oracle_bind(rows, template)

  tax_key <- oracle_key(obs$individualID, obs$scientificName)
  tax_rows <- lapply(oracle_groups(tax_key), function(ix) {
    data.frame(
      individualID = as.character(obs$individualID[ix[1L]]),
      scientificName = as.character(obs$scientificName[ix[1L]]),
      is_species = any(obs$is_species[ix] %in% TRUE),
      stringsAsFactors = FALSE
    )
  })
  taxon <- do.call(rbind, tax_rows)
  match_index <- match(
    oracle_key(out$individualID, out$scientificName),
    oracle_key(taxon$individualID, taxon$scientificName)
  )
  out$is_species <- ifelse(is.na(match_index), NA, taxon$is_species[match_index])
  out$is_species <- as.logical(out$is_species)
  out <- out[
    is.finite(out$year) & out$year %in% SEAL2_DRIVER_YEARS,
    , drop = FALSE
  ]
  out <- out[oracle_order(out$site, out$year, out$individualID), , drop = FALSE]
  rownames(out) <- NULL
  out
}

oracle_select_component <- function(cells) {
  if (!nrow(cells)) return(logical())
  species <- sort(unique(enc2utf8(as.character(cells$scientificName))),
                  method = "radix")
  years <- sort(unique(as.integer(cells$year)), method = "radix")
  species_nodes <- paste0("S", oracle_key_part(species))
  year_nodes <- paste0("Y", oracle_key_part(years))
  nodes <- c(species_nodes, year_nodes)
  parent <- seq_along(nodes)
  names(parent) <- nodes

  find_root <- function(index) {
    while (parent[index] != index) index <- parent[index]
    index
  }
  unite <- function(left, right) {
    left_root <- find_root(unname(parent[[left]]))
    right_root <- find_root(unname(parent[[right]]))
    if (left_root != right_root) parent[right_root] <<- left_root
    invisible(NULL)
  }
  for (i in seq_len(nrow(cells))) {
    unite(
      paste0("S", oracle_key_part(cells$scientificName[i])),
      paste0("Y", oracle_key_part(as.integer(cells$year[i])))
    )
  }
  roots <- vapply(seq_along(parent), find_root, integer(1L))
  node_root <- setNames(roots, names(parent))
  cell_root <- unname(node_root[paste0(
    "S", oracle_key_part(cells$scientificName)
  )])
  groups <- oracle_groups(cell_root)
  score <- lapply(seq_along(groups), function(i) {
    ix <- groups[[i]]
    taxa <- sort(unique(enc2utf8(as.character(cells$scientificName[ix]))),
                 method = "radix")
    data.frame(
      group = i, n_species = length(taxa), n_records = length(ix),
      first_species = taxa[1L], stringsAsFactors = FALSE
    )
  })
  score <- do.call(rbind, score)
  winner <- score$group[oracle_order(
    -score$n_species, -score$n_records, score$first_species
  )[1L]]
  selected <- logical(nrow(cells))
  selected[groups[[winner]]] <- TRUE
  selected
}

oracle_additive_predictions <- function(cells) {
  if (!nrow(cells)) return(data.frame(year = integer(), prediction = numeric()))
  cells <- cells[oracle_order(cells$scientificName, cells$year), , drop = FALSE]
  species <- sort(unique(enc2utf8(as.character(cells$scientificName))),
                  method = "radix")
  years <- sort(unique(as.integer(cells$year)), method = "radix")
  design <- matrix(1, nrow = nrow(cells), ncol = 1L)
  if (length(species) > 1L) {
    design <- cbind(design, vapply(species[-1L], function(level) {
      as.numeric(as.character(cells$scientificName) == level)
    }, numeric(nrow(cells))))
  }
  if (length(years) > 1L) {
    design <- cbind(design, vapply(years[-1L], function(level) {
      as.numeric(as.integer(cells$year) == level)
    }, numeric(nrow(cells))))
  }
  expected_rank <- length(species) + length(years) - 1L
  fit_qr <- qr(design)
  seal2_assert(fit_qr$rank == expected_rank && ncol(design) == expected_rank,
               "oracle_additive_rank")
  coefficients <- qr.coef(fit_qr, as.numeric(cells$species_onset))
  seal2_assert(length(coefficients) == expected_rank &&
                 all(is.finite(coefficients)), "oracle_additive_coefficients")

  rows <- lapply(years, function(year) {
    grid <- matrix(1, nrow = length(species), ncol = 1L)
    if (length(species) > 1L) {
      grid <- cbind(grid, vapply(species[-1L], function(level) {
        as.numeric(species == level)
      }, numeric(length(species))))
    }
    if (length(years) > 1L) {
      grid <- cbind(grid, vapply(years[-1L], function(level) {
        rep(as.numeric(year == level), length(species))
      }, numeric(length(species))))
    }
    values <- as.numeric(grid %*% coefficients)
    data.frame(year = as.integer(year), prediction = oracle_median(values),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

oracle_legacy_annual <- function(obs, site) {
  oracle_validate_observations(obs)
  seal2_assert(length(site) == 1L && seal2_nonblank(site), "oracle_site")
  phases <- oracle_phase_records(obs, as.character(site))
  individual <- oracle_individual_years(phases, obs)
  if (!nrow(individual)) return(oracle_empty_annual())

  support_years <- sort(unique(individual$year), method = "radix")
  bounded <- individual[
    !(individual$left_censored %in% TRUE) & individual$is_species %in% TRUE &
      seal2_nonblank(individual$scientificName),
    , drop = FALSE
  ]

  cell_template <- data.frame(
    scientificName = character(), year = integer(), species_onset = numeric(),
    n_individuals = integer(), stringsAsFactors = FALSE
  )
  if (nrow(bounded)) {
    cell_key <- oracle_key(bounded$scientificName, bounded$year)
    cell_rows <- lapply(oracle_groups(cell_key), function(ix) {
      d <- bounded[ix, , drop = FALSE]
      data.frame(
        scientificName = as.character(d$scientificName[1L]),
        year = as.integer(d$year[1L]),
        species_onset = oracle_median(d$onset),
        n_individuals = as.integer(length(unique(d$individualID))),
        stringsAsFactors = FALSE
      )
    })
    cells <- oracle_bind(cell_rows, cell_template)
  } else cells <- cell_template
  cells <- cells[cells$n_individuals >= 3L, , drop = FALSE]
  if (nrow(cells)) {
    species_levels <- sort(unique(cells$scientificName), method = "radix")
    recurrence <- vapply(species_levels, function(species) {
      length(unique(cells$year[cells$scientificName == species]))
    }, integer(1L))
    recurrent_species <- species_levels[recurrence >= 3L]
    cells <- cells[cells$scientificName %in% recurrent_species, , drop = FALSE]
  }
  if (nrow(cells)) {
    cells <- cells[oracle_order(cells$scientificName, cells$year), , drop = FALSE]
    cells <- cells[oracle_select_component(cells), , drop = FALSE]
  }

  selected_keys <- if (nrow(cells))
    oracle_key(cells$scientificName, cells$year) else character()
  contributors <- bounded[
    oracle_key(bounded$scientificName, bounded$year) %in% selected_keys,
    , drop = FALSE
  ]
  if (nrow(contributors)) {
    seal2_assert(all(is.finite(contributors$interval_days) &
                       contributors$interval_days >= 0),
                 "oracle_contributor_interval")
  }

  references <- numeric()
  anchor <- NA_real_
  if (nrow(cells)) {
    species_levels <- sort(unique(cells$scientificName), method = "radix")
    references <- vapply(species_levels, function(species) {
      oracle_median(cells$species_onset[cells$scientificName == species])
    }, numeric(1L))
    names(references) <- species_levels
    anchor <- oracle_median(references)
  }
  additive <- oracle_additive_predictions(cells)

  rows <- lapply(support_years, function(year) {
    candidates <- individual[individual$year == year, , drop = FALSE]
    final <- contributors[contributors$year == year, , drop = FALSE]
    n_onsets <- nrow(candidates)
    n_left <- sum(candidates$left_censored %in% TRUE)
    n_individuals <- nrow(final)
    n_species <- length(unique(final$scientificName))
    n_excluded <- n_onsets - n_left - n_individuals
    seal2_assert(n_excluded >= 0L, "oracle_reconciliation")
    widths <- final$interval_days[is.finite(final$interval_days)]

    primary <- NA_real_
    if (n_individuals >= 6L && n_species >= 2L && is.finite(anchor)) {
      year_cells <- cells[cells$year == year, , drop = FALSE]
      deviations <- year_cells$species_onset - references[year_cells$scientificName]
      if (length(deviations) && all(is.finite(deviations)))
        primary <- anchor + oracle_median(deviations)
    }
    additive_value <- NA_real_
    if (is.finite(primary)) {
      hit <- additive$year == year
      seal2_assert(sum(hit) == 1L, "oracle_additive_year")
      additive_value <- additive$prediction[hit]
    }
    data.frame(
      site = as.character(site), year = as.integer(year),
      greenup_doy = as.numeric(primary),
      greenup_doy_additive = as.numeric(additive_value),
      greenup_n_onsets = as.integer(n_onsets),
      greenup_n_left_censored = as.integer(n_left),
      greenup_n_taxon_excluded = as.integer(n_excluded),
      greenup_n_individuals = as.integer(n_individuals),
      greenup_n_species = as.integer(n_species),
      greenup_reference_doy = as.numeric(anchor),
      greenup_onset_interval_median_days = if (length(widths))
        oracle_median(widths) else NA_real_,
      greenup_onset_interval_p90_days = if (length(widths))
        oracle_quantile_type7(widths, 0.9) else NA_real_,
      greenup_onset_interval_max_days = if (length(widths))
        max(widths) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  out <- oracle_bind(rows, oracle_empty_annual())
  out <- out[oracle_order(out$site, out$year), , drop = FALSE]
  rownames(out) <- NULL
  out
}

seal2_canonical_table <- function(x) {
  required <- c("site", "year", names(SEAL2_FIELD_MAP))
  seal2_assert(is.data.frame(x) && all(required %in% names(x)),
               "canonical_table_schema")
  seal2_assert(is.character(x$site), "canonical_site_type")
  seal2_assert(is.integer(x$year), "canonical_year_type")
  out <- data.frame(
    site = enc2utf8(x$site),
    year = x$year,
    stringsAsFactors = FALSE
  )
  for (field in names(SEAL2_FIELD_MAP)) {
    if (field %in% SEAL2_INTEGER_FIELDS) {
      seal2_assert(is.integer(x[[field]]), "canonical_integer_type")
      out[[field]] <- x[[field]]
    } else {
      seal2_assert(is.double(x[[field]]), "canonical_numeric_type")
      out[[field]] <- as.numeric(x[[field]])
    }
  }
  seal2_assert(!anyDuplicated(oracle_key(out$site, out$year)),
               "canonical_duplicate_key")
  out <- out[oracle_order(out$site, out$year), , drop = FALSE]
  rownames(out) <- NULL
  out
}

seal2_map_adapter <- function(result) {
  seal2_assert(is.list(result) && is.data.frame(result$compatibility_annual),
               "adapter_result_surface")
  source <- result$compatibility_annual
  required <- c("site", "year", unname(SEAL2_FIELD_MAP))
  seal2_assert(all(required %in% names(source)), "adapter_compatibility_schema")
  source <- source[!is.na(source[[SEAL2_FIELD_MAP[["greenup_n_onsets"]]]]),
                   required, drop = FALSE]
  seal2_assert(is.character(source$site), "adapter_site_type")
  seal2_assert(is.integer(source$year), "adapter_year_type")
  mapped <- data.frame(
    site = enc2utf8(source$site),
    year = source$year, stringsAsFactors = FALSE
  )
  for (field in names(SEAL2_FIELD_MAP)) {
    value <- source[[SEAL2_FIELD_MAP[[field]]]]
    if (field %in% SEAL2_INTEGER_FIELDS) {
      seal2_assert(is.integer(value), "adapter_integer_type")
      mapped[[field]] <- value
    } else {
      seal2_assert(is.double(value), "adapter_numeric_type")
      mapped[[field]] <- as.numeric(value)
    }
  }
  seal2_canonical_table(mapped)
}

seal2_comparison <- function(observed, expected) {
  result <- list(
    ok = TRUE, key_mismatches = 0L, missingness_mismatches = 0L,
    exact_mismatches = 0L, tolerance_mismatches = 0L,
    max_abs_delta = 0, max_abs_additive_delta = 0
  )
  if (!is.data.frame(observed) || !is.data.frame(expected)) {
    result$ok <- FALSE
    result$key_mismatches <- 1L
    return(result)
  }
  required <- c("site", "year", names(SEAL2_FIELD_MAP))
  if (!all(required %in% names(observed)) || !all(required %in% names(expected))) {
    result$ok <- FALSE
    result$key_mismatches <- 1L
    return(result)
  }
  if (!is.character(observed$site) || !is.character(expected$site) ||
      !is.integer(observed$year) || !is.integer(expected$year)) {
    result$ok <- FALSE
    result$key_mismatches <- 1L
    return(result)
  }
  left_key <- oracle_key(observed$site, observed$year)
  right_key <- oracle_key(expected$site, expected$year)
  if (anyDuplicated(left_key) || anyDuplicated(right_key)) {
    result$ok <- FALSE
    result$key_mismatches <- as.integer(anyDuplicated(left_key) > 0L) +
      as.integer(anyDuplicated(right_key) > 0L)
    return(result)
  }
  left_order <- oracle_order(observed$site, observed$year)
  right_order <- oracle_order(expected$site, expected$year)
  observed <- observed[left_order, , drop = FALSE]
  expected <- expected[right_order, , drop = FALSE]
  left_key <- left_key[left_order]
  right_key <- right_key[right_order]
  if (!identical(left_key, right_key)) {
    result$ok <- FALSE
    result$key_mismatches <- as.integer(
      length(setdiff(left_key, right_key)) + length(setdiff(right_key, left_key))
    )
    return(result)
  }

  for (field in names(SEAL2_FIELD_MAP)) {
    left <- observed[[field]]
    right <- expected[[field]]
    nan_count <- sum(is.nan(left)) + sum(is.nan(right))
    if (nan_count) {
      result$missingness_mismatches <- result$missingness_mismatches +
        as.integer(nan_count)
      next
    }
    left_missing <- is.na(left)
    right_missing <- is.na(right)
    missing_count <- sum(xor(left_missing, right_missing))
    if (missing_count) {
      result$missingness_mismatches <- result$missingness_mismatches +
        as.integer(missing_count)
      next
    }
    present <- !left_missing & !right_missing
    if (!any(present)) next
    if (field %in% SEAL2_INTEGER_FIELDS) {
      if (!is.integer(left) || !is.integer(right)) {
        result$exact_mismatches <- result$exact_mismatches + 1L
      } else {
        result$exact_mismatches <- result$exact_mismatches +
          as.integer(sum(left[present] != right[present]))
      }
      next
    }
    if (!is.double(left) || !is.double(right)) {
      result$exact_mismatches <- result$exact_mismatches + 1L
      next
    }
    invalid_nonfinite <- present & (!is.finite(left) | !is.finite(right))
    if (any(invalid_nonfinite)) {
      result$exact_mismatches <- result$exact_mismatches +
        as.integer(sum(invalid_nonfinite))
      next
    }
    finite_disagreement <- xor(is.finite(left[present]), is.finite(right[present]))
    if (any(finite_disagreement)) {
      result$missingness_mismatches <- result$missingness_mismatches +
        as.integer(sum(finite_disagreement))
      next
    }
    finite <- present & is.finite(left) & is.finite(right)
    if (!any(finite)) next
    delta <- abs(left[finite] - right[finite])
    tolerance <- if (field == SEAL2_ADDITIVE_FIELD)
      SEAL2_ADDITIVE_TOLERANCE else SEAL2_STRICT_TOLERANCE
    if (field == SEAL2_ADDITIVE_FIELD) {
      result$max_abs_additive_delta <- max(
        result$max_abs_additive_delta, delta
      )
    } else {
      result$max_abs_delta <- max(result$max_abs_delta, delta)
    }
    result$tolerance_mismatches <- result$tolerance_mismatches +
      as.integer(sum(delta > tolerance))
  }
  result$ok <- identical(
    result$key_mismatches + result$missingness_mismatches +
      result$exact_mismatches + result$tolerance_mismatches,
    0L
  )
  result
}

seal2_assert_comparison <- function(comparison, code) {
  seal2_assert(is.list(comparison) && isTRUE(comparison$ok), code)
  invisible(comparison)
}

seal2_identical_table <- function(left, right) {
  identical(
    serialize(seal2_canonical_table(left), NULL, version = 3L),
    serialize(seal2_canonical_table(right), NULL, version = 3L)
  )
}

seal2_synthetic_observations <- function() {
  species <- c("Alpha alba", "Beta beta")
  years <- 2018:2020
  rows <- list()
  counter <- 0L
  for (species_index in seq_along(species)) {
    for (year_index in seq_along(years)) {
      center <- if (species_index == 1L) c(100, 110, 90)[year_index]
      else c(200, 210, 190)[year_index]
      for (individual_index in 1:3) {
        counter <- counter + 1L
        width <- if (year_index == 1L)
          c(2, 4, 6, 8, 10, 40)[(species_index - 1L) * 3L + individual_index]
        else 4
        identifier <- sprintf("S%d-I%d", species_index, individual_index)
        rows[[counter]] <- data.frame(
          individualID = rep(identifier, 2L),
          scientificName = rep(species[species_index], 2L),
          growthForm = rep("tree", 2L),
          phenophaseName = rep("Breaking leaf buds", 2L),
          year = rep(as.integer(years[year_index]), 2L),
          dayOfYear = c(center - width / 2, center + width / 2),
          status = c("no", "yes"), is_species = rep(TRUE, 2L),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

seal2_run_synthetic <- function() {
  obs <- seal2_synthetic_observations()
  direct <- oracle_legacy_annual(obs, "TEST")
  reversed <- oracle_legacy_annual(obs[nrow(obs):1L, , drop = FALSE], "TEST")
  set.seed(1701L)
  shuffled_one <- oracle_legacy_annual(
    obs[sample.int(nrow(obs)), , drop = FALSE], "TEST"
  )
  set.seed(2909L)
  shuffled_two <- oracle_legacy_annual(
    obs[sample.int(nrow(obs)), , drop = FALSE], "TEST"
  )
  seal2_assert(seal2_identical_table(direct, reversed) &&
                 seal2_identical_table(direct, shuffled_one) &&
                 seal2_identical_table(direct, shuffled_two),
               "synthetic_row_order")
  seal2_assert(nrow(direct) == 3L &&
                 identical(direct$greenup_n_onsets, rep(6L, 3L)) &&
                 identical(direct$greenup_n_individuals, rep(6L, 3L)) &&
                 identical(direct$greenup_n_species, rep(2L, 3L)) &&
                 isTRUE(all.equal(direct$greenup_doy, c(150, 160, 140),
                                  tolerance = 0)) &&
                 isTRUE(all.equal(
                   direct$greenup_onset_interval_p90_days[1L], 25,
                   tolerance = 0
                 )), "synthetic_oracle_values")

  censor_taxon <- data.frame(
    individualID = c("CENS", "CENS", "CENS", "NONT", "NONT", "NOYES"),
    scientificName = c(
      rep("Alpha alba", 3L), rep("Unresolved taxon", 2L), "Alpha alba"
    ),
    growthForm = rep("tree", 6L),
    phenophaseName = c(
      "Breaking leaf buds", "Initial growth", "Initial growth",
      "Breaking leaf buds", "Breaking leaf buds", "Breaking leaf buds"
    ),
    year = c(2018L, 2018L, 2018L, 2019L, 2019L, 2020L),
    dayOfYear = c(100, 90, 110, 100, 104, 100),
    status = c("yes", "no", "yes", "no", "yes", "no"),
    is_species = c(TRUE, TRUE, TRUE, FALSE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  censor_result <- oracle_legacy_annual(censor_taxon, "TEST")
  seal2_assert(
    nrow(censor_result) == 2L &&
      identical(censor_result$greenup_n_onsets, c(1L, 1L)) &&
      identical(censor_result$greenup_n_left_censored, c(1L, 0L)) &&
      identical(censor_result$greenup_n_taxon_excluded, c(0L, 1L)) &&
      identical(censor_result$greenup_n_individuals, c(0L, 0L)) &&
      all(is.na(censor_result$greenup_doy)) &&
      all(is.na(censor_result$greenup_onset_interval_max_days)),
    "synthetic_censor_taxon_oracle"
  )

  baseline <- direct
  seal2_assert(seal2_comparison(direct, baseline)$ok,
               "synthetic_comparator_identity")
  within_strict <- baseline
  within_strict$greenup_doy[1L] <- within_strict$greenup_doy[1L] + 5e-16
  seal2_assert(seal2_comparison(within_strict, baseline)$ok,
               "synthetic_strict_tolerance_inside")
  outside_strict <- baseline
  outside_strict$greenup_doy[1L] <- outside_strict$greenup_doy[1L] + 2e-12
  seal2_assert(!seal2_comparison(outside_strict, baseline)$ok,
               "synthetic_strict_tolerance_tripwire")
  within_additive <- baseline
  within_additive$greenup_doy_additive[1L] <-
    within_additive$greenup_doy_additive[1L] + 5e-13
  seal2_assert(seal2_comparison(within_additive, baseline)$ok,
               "synthetic_additive_tolerance_inside")
  outside_additive <- baseline
  outside_additive$greenup_doy_additive[1L] <-
    outside_additive$greenup_doy_additive[1L] + 2e-12
  seal2_assert(!seal2_comparison(outside_additive, baseline)$ok,
               "synthetic_additive_tolerance_tripwire")
  missingness <- baseline
  missingness$greenup_reference_doy[1L] <- NA_real_
  seal2_assert(!seal2_comparison(missingness, baseline)$ok,
               "synthetic_missingness_tripwire")
  integer_value <- baseline
  integer_value$greenup_n_species[1L] <- integer_value$greenup_n_species[1L] + 1L
  seal2_assert(!seal2_comparison(integer_value, baseline)$ok,
               "synthetic_integer_tripwire")
  integer_type <- baseline
  integer_type$greenup_n_species <- as.numeric(integer_type$greenup_n_species)
  seal2_assert(!seal2_comparison(integer_type, baseline)$ok,
               "synthetic_integer_type_tripwire")
  fractional_count <- baseline
  fractional_count$greenup_n_species <-
    as.numeric(fractional_count$greenup_n_species) + 0.9
  seal2_assert(!seal2_comparison(fractional_count, baseline)$ok,
               "synthetic_fractional_count_tripwire")
  infinite_value <- baseline
  infinite_value$greenup_doy[1L] <- Inf
  seal2_assert(!seal2_comparison(infinite_value, baseline)$ok,
               "synthetic_infinite_value_tripwire")
  nan_value <- baseline
  nan_value$greenup_doy[1L] <- NaN
  seal2_assert(!seal2_comparison(nan_value, baseline)$ok,
               "synthetic_nan_value_tripwire")
  keys <- baseline
  keys$year[1L] <- keys$year[1L] - 1L
  seal2_assert(!seal2_comparison(keys, baseline)$ok,
               "synthetic_key_tripwire")
  key_type <- baseline
  key_type$year <- as.numeric(key_type$year)
  seal2_assert(!seal2_comparison(key_type, baseline)$ok,
               "synthetic_key_type_tripwire")

  previous <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", previous)), add = TRUE)
  c_locale <- suppressWarnings(Sys.setlocale("LC_COLLATE", "C"))
  c_result <- oracle_legacy_annual(obs, "TEST")
  utf8_locale <- ""
  for (candidate in c("C.UTF-8", "en_US.UTF-8", "en_US.utf8")) {
    attempted <- suppressWarnings(Sys.setlocale("LC_COLLATE", candidate))
    if (nzchar(attempted) && !identical(attempted, c_locale)) {
      utf8_locale <- attempted
      break
    }
  }
  seal2_assert(nzchar(c_locale) && nzchar(utf8_locale),
               "synthetic_locale_availability")
  utf8_result <- oracle_legacy_annual(obs, "TEST")
  seal2_assert(seal2_identical_table(c_result, utf8_result),
               "synthetic_locale_determinism")
  invisible(TRUE)
}

seal2_ast_calls <- function(expression) {
  unique(all.names(expression, functions = TRUE, unique = FALSE))
}

seal2_run_static <- function() {
  seal2_with_repo({
    adapter_path <- "R/phenology_adapter_v2.R"
    runner_path <- "scripts/test_phenology_adapter_v2_legacy.R"
    adapter_expression <- parse(adapter_path, keep.source = FALSE)
    runner_expression <- parse(runner_path, keep.source = FALSE)
    adapter_calls <- seal2_ast_calls(adapter_expression)
    runner_calls <- seal2_ast_calls(runner_expression)
    forbidden_effect_calls <- c(
      "cor", "stats::cor", "cor.test", "stats::cor.test", "rma",
      "metafor::rma", "metafor::rma.uni", "site_links", "pooled_links"
    )
    seal2_assert(!any(adapter_calls %in% forbidden_effect_calls) &&
                   !any(runner_calls %in% forbidden_effect_calls),
                 "static_effect_call")
    forbidden_acquisition_calls <- c(
      "download.file", "url", "curl::curl", "httr::GET", "git2r::clone"
    )
    seal2_assert(!any(adapter_calls %in% forbidden_acquisition_calls) &&
                   !any(runner_calls %in% forbidden_acquisition_calls),
                 "static_acquisition_call")
    text <- readLines(runner_path, warn = FALSE, encoding = "UTF-8")
    adapter_text <- readLines(adapter_path, warn = FALSE, encoding = "UTF-8")
    seal2_assert("sys.source" %in% runner_calls &&
                   !any(grepl(
                     "(^|[^[:alnum:]_.:])source[[:space:]]*\\(",
                     text, perl = TRUE
                   )), "static_source_boundary")
    forbidden_current_root <- paste0("PHENOLOGY_V2_", "CURRENT_ROOT")
    seal2_assert(!any(grepl(forbidden_current_root, text, fixed = TRUE)) &&
                   !any(grepl(forbidden_current_root, adapter_text, fixed = TRUE)),
                 "static_current_root_symbol")
    seal2_assert(sum(grepl(
      'base::sys.source\\("R/phenology_adapter_v2\\.R"', text
    )) == 1L, "static_adapter_source_literal")
    invisible(TRUE)
  })
}

seal2_source_adapter <- function() {
  seal2_assert(!("metafor" %in% loadedNamespaces()), "effect_namespace_loaded")
  environment <- new.env(parent = globalenv())
  tripwire <- function(symbol) {
    force(symbol)
    function(...) seal2_abort(paste0("forbidden_symbol_", symbol))
  }
  for (symbol in c(
    "source", "sys.source", "site_links", "pooled_links", "binom.test",
    "p.adjust", "cor", "cor.test", "rma", "readRDS", "download.file",
    "url", "system", "system2", "pipe", "socketConnection",
    "phenology_v2_build_climate_support_mask", "temp", "temp_spring",
    "climate"
  )) assign(symbol, tripwire(symbol), envir = environment)
  base::sys.source("R/phenology_adapter_v2.R", envir = environment)
  required <- c(
    "PHENOLOGY_V2_TARGET_PHASES", "PHENOLOGY_V2_SEAL1_MODE",
    "phenology_v2_adapt_bundle"
  )
  seal2_assert(all(vapply(required, exists, logical(1L), envir = environment,
                          inherits = FALSE)), "adapter_api")
  seal2_assert(identical(
    get("PHENOLOGY_V2_TARGET_PHASES", envir = environment, inherits = FALSE),
    SEAL2_TARGET_PHASES
  ), "adapter_phase_literal")
  mode <- get("PHENOLOGY_V2_SEAL1_MODE", envir = environment, inherits = FALSE)
  seal2_assert(identical(mode, "seal1-synthetic-response"), "adapter_seal1_mode")
  lockEnvironment(environment, bindings = TRUE)
  seal2_assert(!("metafor" %in% loadedNamespaces()), "effect_namespace_loaded")
  environment
}

seal2_call_adapter <- function(environment, bundle, site) {
  adapter <- get("phenology_v2_adapt_bundle", envir = environment, inherits = FALSE)
  warnings <- 0L
  result <- tryCatch(
    withCallingHandlers(
      adapter(bundle, site, effect_locked = TRUE),
      warning = function(condition) {
        warnings <<- warnings + 1L
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) {
      code <- condition$code
      if (length(code) == 1L && !is.na(code) &&
          code %in% c("empty_required_table")) {
        seal2_abort(paste0("adapter_", code))
      }
      seal2_abort("adapter_execution")
    }
  )
  seal2_assert(warnings == 0L, "adapter_warning")
  seal2_assert(!("metafor" %in% loadedNamespaces()), "effect_namespace_loaded")
  result
}

seal2_artifact_state <- function() {
  seal2_assert(all(file.exists(SEAL2_ARTIFACTS)), "artifact_presence")
  value <- unname(tools::md5sum(SEAL2_ARTIFACTS))
  names(value) <- SEAL2_ARTIFACTS
  seal2_assert(all(grepl("^[0-9a-f]{32}$", value)), "artifact_digest")
  value
}

seal2_legacy_authority <- function() {
  commit <- Sys.getenv("PHENOLOGY_V2_LEGACY_COMMIT", unset = "")
  tree <- Sys.getenv("PHENOLOGY_V2_LEGACY_TREE", unset = "")
  root <- Sys.getenv("PHENOLOGY_V2_LEGACY_ROOT", unset = "")
  seal2_assert(identical(commit, SEAL2_LEGACY_COMMIT), "legacy_commit_authority")
  seal2_assert(identical(tree, SEAL2_LEGACY_TREE), "legacy_tree_authority")
  seal2_assert(length(root) == 1L && nzchar(root) && dir.exists(root),
               "legacy_root_authority")
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  current_root <- normalizePath(seal2_repo_root(), winslash = "/", mustWork = TRUE)
  seal2_assert(!identical(root, current_root) &&
                 !startsWith(root, paste0(current_root, "/data/sites")),
               "legacy_root_isolation")
  files <- list.files(root, pattern = "^[A-Za-z0-9]{4}\\.rds$", full.names = TRUE)
  files <- sort(normalizePath(files, winslash = "/", mustWork = TRUE),
                method = "radix")
  seal2_assert(length(files) == SEAL2_BUNDLE_COUNT, "legacy_bundle_count")
  all_files <- list.files(root, all.files = TRUE, no.. = TRUE, recursive = TRUE,
                         full.names = TRUE, include.dirs = FALSE)
  all_files <- normalizePath(all_files, winslash = "/", mustWork = TRUE)
  seal2_assert(length(all_files) == SEAL2_BUNDLE_COUNT &&
                 setequal(files, all_files), "legacy_root_shape")
  list(root = root, files = files)
}

seal2_load_baseline <- function() {
  object <- tryCatch(
    readRDS("data/cascade.rds"),
    error = function(condition) seal2_abort("baseline_read")
  )
  seal2_assert(is.list(object) && is.data.frame(object$annual),
               "baseline_container")
  annual <- object$annual
  rm(object)
  required <- c(
    "site", "year", names(SEAL2_FIELD_MAP), "temp", "temp_spring"
  )
  seal2_assert(nrow(annual) == 510L && ncol(annual) == 54L &&
                 all(required %in% names(annual)), "baseline_structure")
  seal2_assert(!anyDuplicated(oracle_key(annual$site, annual$year)),
               "baseline_duplicate_key")
  support_mask <- !is.na(annual$greenup_n_onsets)
  presence <- data.frame(
    site = enc2utf8(as.character(annual$site)),
    year = as.integer(annual$year),
    response_present = is.finite(annual$greenup_doy),
    annual_temperature_present = is.finite(annual$temp),
    spring_temperature_present = is.finite(annual$temp_spring),
    stringsAsFactors = FALSE
  )
  support <- annual[support_mask, c("site", "year", names(SEAL2_FIELD_MAP)),
                    drop = FALSE]
  rm(annual)
  gc(verbose = FALSE)
  list(table = seal2_canonical_table(support), presence = presence)
}

seal2_site_count <- function(site, present, minimum = 1L) {
  levels <- sort(unique(enc2utf8(as.character(site))), method = "radix")
  totals <- vapply(levels, function(value) {
    sum(present[as.character(site) == value] %in% TRUE)
  }, integer(1L))
  as.integer(sum(totals >= minimum))
}

seal2_baseline_counts <- function(baseline) {
  table <- baseline$table
  presence <- baseline$presence
  result <- c(
    source_support_rows = as.integer(nrow(table)),
    finite_compatibility_rows = as.integer(sum(is.finite(table$greenup_doy))),
    finite_compatibility_sites = seal2_site_count(
      table$site, is.finite(table$greenup_doy), 1L
    ),
    finite_sites_ge_6 = seal2_site_count(
      table$site, is.finite(table$greenup_doy), 6L
    ),
    annual_temperature_sites_ge_6 = seal2_site_count(
      presence$site,
      presence$response_present & presence$annual_temperature_present,
      6L
    ),
    spring_temperature_sites_ge_6 = seal2_site_count(
      presence$site,
      presence$response_present & presence$spring_temperature_present,
      6L
    ),
    fields_compared = as.integer(length(SEAL2_FIELD_MAP))
  )
  storage.mode(result) <- "integer"
  seal2_assert(identical(result, SEAL2_EXPECTED), "legacy_registered_counts")
  result
}

seal2_read_bundle <- function(path) {
  tryCatch(readRDS(path), error = function(condition) seal2_abort("legacy_bundle_read"))
}

seal2_preflight_legacy <- function(files) {
  required_members <- c("obs", "inds", "meta", "ind_summary", "trend")
  trend_fields <- c("scientificName", "year", "onset", "n")
  affected <- 0L
  for (path in files) {
    bundle <- seal2_read_bundle(path)
    seal2_assert(is.list(bundle) && !is.data.frame(bundle) &&
                   !is.null(names(bundle)) && !anyNA(names(bundle)) &&
                   !any(!nzchar(names(bundle))) && !anyDuplicated(names(bundle)) &&
                   all(required_members %in% names(bundle)),
                 "legacy_preflight_container")
    seal2_assert(is.data.frame(bundle$obs) && is.data.frame(bundle$inds) &&
                   is.list(bundle$meta) && is.data.frame(bundle$ind_summary),
                 "legacy_preflight_tables")
    if (!is.null(bundle$trend)) {
      seal2_assert(is.data.frame(bundle$trend) &&
                     all(trend_fields %in% names(bundle$trend)),
                   "legacy_preflight_trend_schema")
      typed_empty <- nrow(bundle$trend) == 0L &&
        is.character(bundle$trend$scientificName) &&
        is.numeric(bundle$trend$year) && !is.logical(bundle$trend$year) &&
        is.numeric(bundle$trend$onset) && !is.logical(bundle$trend$onset) &&
        is.numeric(bundle$trend$n) && !is.logical(bundle$trend$n)
      affected <- affected + as.integer(typed_empty)
    }
    rm(bundle)
  }
  list(
    hard_failure_code = if (affected) "empty_required_table" else NA_character_,
    affected_bundles = as.integer(affected),
    bundles_checked = as.integer(length(files))
  )
}

seal2_shuffle_bundle <- function(bundle, seed) {
  seal2_assert(is.list(bundle) && is.data.frame(bundle$obs), "legacy_bundle_surface")
  set.seed(seed)
  order <- if (nrow(bundle$obs)) sample.int(nrow(bundle$obs)) else integer()
  bundle$obs <- bundle$obs[order, , drop = FALSE]
  bundle
}

seal2_set_locale <- function(value) {
  observed <- suppressWarnings(Sys.setlocale("LC_COLLATE", value))
  seal2_assert(nzchar(observed), "locale_unavailable")
  observed
}

seal2_utf8_locale <- function(c_locale) {
  for (candidate in c("C.UTF-8", "en_US.UTF-8", "en_US.utf8")) {
    observed <- suppressWarnings(Sys.setlocale("LC_COLLATE", candidate))
    if (nzchar(observed) && !identical(observed, c_locale)) return(observed)
  }
  seal2_abort("locale_unavailable")
}

seal2_collect_legacy <- function(files, environment) {
  original_new <- vector("list", length(files))
  original_oracle <- vector("list", length(files))
  shuffled_new <- vector("list", length(files))
  shuffled_oracle <- vector("list", length(files))
  locale_new <- vector("list", length(files))
  locale_oracle <- vector("list", length(files))
  previous_locale <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", previous_locale)), add = TRUE)
  c_locale <- seal2_set_locale("C")
  utf8_locale <- seal2_utf8_locale(c_locale)

  for (index in seq_along(files)) {
    bundle <- seal2_read_bundle(files[index])
    seal2_assert(is.list(bundle) && is.data.frame(bundle$obs),
                 "legacy_bundle_surface")
    site <- sub("\\.rds$", "", basename(files[index]))

    seal2_set_locale("C")
    original_new[[index]] <- seal2_map_adapter(
      seal2_call_adapter(environment, bundle, site)
    )
    original_oracle[[index]] <- oracle_legacy_annual(bundle$obs, site)

    shuffled <- seal2_shuffle_bundle(bundle, 1701L + index)
    shuffled_new[[index]] <- seal2_map_adapter(
      seal2_call_adapter(environment, shuffled, site)
    )
    shuffled_oracle[[index]] <- oracle_legacy_annual(shuffled$obs, site)
    rm(shuffled)

    seal2_set_locale(utf8_locale)
    locale_new[[index]] <- seal2_map_adapter(
      seal2_call_adapter(environment, bundle, site)
    )
    locale_oracle[[index]] <- oracle_legacy_annual(bundle$obs, site)
    rm(bundle)
  }
  seal2_set_locale(previous_locale)

  bind <- function(rows) seal2_canonical_table(do.call(rbind, rows))
  list(
    original_new = bind(original_new),
    original_oracle = bind(original_oracle),
    shuffled_new = bind(shuffled_new),
    shuffled_oracle = bind(shuffled_oracle),
    locale_new = bind(locale_new),
    locale_oracle = bind(locale_oracle)
  )
}

seal2_receipt_digest <- function(baseline, collected) {
  seal2_assert(requireNamespace("digest", quietly = TRUE), "digest_dependency")
  material <- serialize(list(
    baseline = baseline$table,
    presence = baseline$presence,
    adapter = collected$original_new,
    oracle = collected$original_oracle
  ), NULL, version = 3L)
  value <- digest::digest(material, algo = "sha256", serialize = FALSE)
  seal2_assert(length(value) == 1L && grepl("^[0-9a-f]{64}$", value),
               "parity_digest")
  value
}

seal2_merge_delta <- function(comparisons, field) {
  values <- vapply(comparisons, function(value) as.numeric(value[[field]]), numeric(1L))
  seal2_assert(all(is.finite(values) & values >= 0), "comparison_delta")
  max(values)
}

seal2_run_worker_core <- function() {
  seal2_with_repo({
    before <- seal2_artifact_state()
    authority <- seal2_legacy_authority()
    environment <- seal2_source_adapter()
    baseline <- seal2_load_baseline()
    counts <- seal2_baseline_counts(baseline)
    collected <- seal2_collect_legacy(authority$files, environment)

    comparisons <- list(
      adapter_oracle = seal2_comparison(
        collected$original_new, collected$original_oracle
      ),
      adapter_baseline = seal2_comparison(
        collected$original_new, baseline$table
      ),
      oracle_baseline = seal2_comparison(
        collected$original_oracle, baseline$table
      )
    )
    for (name in names(comparisons))
      seal2_assert_comparison(comparisons[[name]], "legacy_parity")

    seal2_assert(
      seal2_identical_table(collected$original_new, collected$shuffled_new) &&
        seal2_identical_table(
          collected$original_oracle, collected$shuffled_oracle
        ), "legacy_row_order_determinism"
    )
    seal2_assert(
      seal2_identical_table(collected$original_new, collected$locale_new) &&
        seal2_identical_table(
          collected$original_oracle, collected$locale_oracle
        ), "legacy_locale_determinism"
    )

    observed_counts <- c(
      source_support_rows = as.integer(nrow(collected$original_new)),
      finite_compatibility_rows = as.integer(sum(
        is.finite(collected$original_new$greenup_doy)
      )),
      finite_compatibility_sites = seal2_site_count(
        collected$original_new$site,
        is.finite(collected$original_new$greenup_doy), 1L
      ),
      finite_sites_ge_6 = seal2_site_count(
        collected$original_new$site,
        is.finite(collected$original_new$greenup_doy), 6L
      ),
      annual_temperature_sites_ge_6 = counts[[
        "annual_temperature_sites_ge_6"
      ]],
      spring_temperature_sites_ge_6 = counts[[
        "spring_temperature_sites_ge_6"
      ]],
      fields_compared = as.integer(length(SEAL2_FIELD_MAP))
    )
    storage.mode(observed_counts) <- "integer"
    seal2_assert(identical(observed_counts, SEAL2_EXPECTED),
                 "legacy_registered_counts")
    after <- seal2_artifact_state()
    seal2_assert(identical(before, after), "artifact_nonmutation")

    list(
      schema = SEAL2_SCHEMA, status = "PASS",
      source_support_rows = unname(observed_counts[["source_support_rows"]]),
      finite_compatibility_rows = unname(observed_counts[[
        "finite_compatibility_rows"
      ]]),
      finite_compatibility_sites = unname(observed_counts[[
        "finite_compatibility_sites"
      ]]),
      finite_sites_ge_6 = unname(observed_counts[["finite_sites_ge_6"]]),
      annual_temperature_sites_ge_6 = unname(observed_counts[[
        "annual_temperature_sites_ge_6"
      ]]),
      spring_temperature_sites_ge_6 = unname(observed_counts[[
        "spring_temperature_sites_ge_6"
      ]]),
      fields_compared = unname(observed_counts[["fields_compared"]]),
      max_abs_delta = seal2_merge_delta(comparisons, "max_abs_delta"),
      max_abs_additive_delta = seal2_merge_delta(
        comparisons, "max_abs_additive_delta"
      ),
      parity_sha256 = seal2_receipt_digest(baseline, collected)
    )
  })
}

seal2_error_code <- function(condition) {
  code <- condition$seal2_code
  if (length(code) != 1L || is.na(code) ||
      !grepl("^[a-z0-9_]+$", code)) "unexpected_failure" else code
}

seal2_write_worker_result <- function(result, path) {
  seal2_assert(length(path) == 1L && nzchar(path), "worker_result_path")
  saveRDS(result, path, version = 3L)
  suppressWarnings(Sys.chmod(path, mode = "0600"))
  invisible(TRUE)
}

seal2_run_worker <- function() {
  path <- Sys.getenv("PHENOLOGY_V2_RESULT_FILE", unset = "")
  status <- 0L
  result <- tryCatch(
    seal2_run_worker_core(),
    error = function(condition) {
      status <<- 1L
      list(schema = SEAL2_SCHEMA, status = "FAIL",
           code = seal2_error_code(condition))
    }
  )
  tryCatch(
    seal2_write_worker_result(result, path),
    error = function(condition) {
      status <<- 1L
    }
  )
  quit(save = "no", status = status, runLast = FALSE)
}

seal2_read_raw <- function(path) {
  info <- file.info(path)
  if (is.na(info$size) || info$size == 0) return(raw())
  readBin(path, what = "raw", n = as.integer(info$size))
}

seal2_run_clean_worker <- function() {
  result_path <- tempfile("phenology-v2-seal2-result-")
  stdout_path <- tempfile("phenology-v2-seal2-stdout-")
  stderr_path <- tempfile("phenology-v2-seal2-stderr-")
  on.exit(unlink(c(result_path, stdout_path, stderr_path), force = TRUE), add = TRUE)
  executable <- file.path(R.home("bin"), "Rscript")
  status <- suppressWarnings(system2(
    executable,
    args = c("--vanilla", shQuote(seal2_script_path()), "--worker"),
    stdout = stdout_path, stderr = stderr_path,
    env = c(
      paste0("PHENOLOGY_V2_RESULT_FILE=", result_path),
      "OPENBLAS_NUM_THREADS=1", "OMP_NUM_THREADS=1", "MKL_NUM_THREADS=1",
      "VECLIB_MAXIMUM_THREADS=1", "RCPP_PARALLEL_NUM_THREADS=1"
    )
  ))
  seal2_assert(length(seal2_read_raw(stdout_path)) == 0L &&
                 length(seal2_read_raw(stderr_path)) == 0L,
               "worker_output_boundary")
  seal2_assert(file.exists(result_path), "worker_result_missing")
  result <- tryCatch(
    readRDS(result_path), error = function(condition) seal2_abort("worker_result_read")
  )
  seal2_assert(is.list(result) && identical(result$schema, SEAL2_SCHEMA) &&
                 result$status %in% c("PASS", "FAIL"), "worker_result_schema")
  list(exit_status = as.integer(status), result = result)
}

seal2_validate_receipt <- function(receipt) {
  expected_names <- c(
    "schema", "status", "source_support_rows", "finite_compatibility_rows",
    "finite_compatibility_sites", "finite_sites_ge_6",
    "annual_temperature_sites_ge_6", "spring_temperature_sites_ge_6",
    "fields_compared", "max_abs_delta", "max_abs_additive_delta",
    "parity_sha256"
  )
  seal2_assert(identical(names(receipt), expected_names) &&
                 identical(receipt$schema, SEAL2_SCHEMA) &&
                 identical(receipt$status, "PASS"), "receipt_schema")
  integer_names <- names(SEAL2_EXPECTED)
  observed <- vapply(integer_names, function(name) {
    value <- receipt[[name]]
    seal2_assert(length(value) == 1L && is.integer(value) && !is.na(value),
                 "receipt_integer")
    value
  }, integer(1L))
  seal2_assert(identical(observed, SEAL2_EXPECTED), "receipt_counts")
  seal2_assert(length(receipt$max_abs_delta) == 1L &&
                 is.finite(receipt$max_abs_delta) && receipt$max_abs_delta >= 0 &&
                 receipt$max_abs_delta <= SEAL2_STRICT_TOLERANCE,
               "receipt_strict_delta")
  seal2_assert(length(receipt$max_abs_additive_delta) == 1L &&
                 is.finite(receipt$max_abs_additive_delta) &&
                 receipt$max_abs_additive_delta >= 0 &&
                 receipt$max_abs_additive_delta <= SEAL2_ADDITIVE_TOLERANCE,
               "receipt_additive_delta")
  seal2_assert(length(receipt$parity_sha256) == 1L &&
                 grepl("^[0-9a-f]{64}$", receipt$parity_sha256),
               "receipt_digest")
  invisible(TRUE)
}

seal2_hold_receipt <- function(preflight) {
  receipt <- list(
    schema = SEAL2_SCHEMA,
    status = "HOLD",
    hard_failure_code = "empty_required_table",
    affected_bundles = as.integer(preflight$affected_bundles),
    bundles_checked = as.integer(preflight$bundles_checked),
    parity_attempted = FALSE,
    current_fetched = FALSE,
    current_deserialized = FALSE,
    effect_module_sourced = FALSE,
    effect_function_called = FALSE
  )
  seal2_validate_hold_receipt(receipt)
  receipt
}

seal2_validate_hold_receipt <- function(receipt) {
  expected_names <- c(
    "schema", "status", "hard_failure_code", "affected_bundles",
    "bundles_checked", "parity_attempted", "current_fetched",
    "current_deserialized", "effect_module_sourced",
    "effect_function_called"
  )
  seal2_assert(identical(names(receipt), expected_names) &&
                 identical(receipt$schema, SEAL2_SCHEMA) &&
                 identical(receipt$status, "HOLD") &&
                 identical(receipt$hard_failure_code, "empty_required_table") &&
                 identical(receipt$affected_bundles, 1L) &&
                 identical(receipt$bundles_checked, SEAL2_BUNDLE_COUNT) &&
                 identical(receipt$parity_attempted, FALSE) &&
                 identical(receipt$current_fetched, FALSE) &&
                 identical(receipt$current_deserialized, FALSE) &&
                 identical(receipt$effect_module_sourced, FALSE) &&
                 identical(receipt$effect_function_called, FALSE),
               "hold_receipt")
  invisible(TRUE)
}

seal2_json_number <- function(value) {
  seal2_assert(length(value) == 1L && is.finite(value) && value >= 0,
               "json_number")
  if (value == 0) "0" else formatC(value, digits = 17L, format = "g")
}

seal2_receipt_json <- function(receipt) {
  seal2_validate_receipt(receipt)
  sprintf(
    paste0(
      '{"schema":"%s","status":"%s",',
      '"source_support_rows":%d,"finite_compatibility_rows":%d,',
      '"finite_compatibility_sites":%d,"finite_sites_ge_6":%d,',
      '"annual_temperature_sites_ge_6":%d,',
      '"spring_temperature_sites_ge_6":%d,"fields_compared":%d,',
      '"max_abs_delta":%s,"max_abs_additive_delta":%s,',
      '"parity_sha256":"%s"}'
    ),
    receipt$schema, receipt$status, receipt$source_support_rows,
    receipt$finite_compatibility_rows, receipt$finite_compatibility_sites,
    receipt$finite_sites_ge_6, receipt$annual_temperature_sites_ge_6,
    receipt$spring_temperature_sites_ge_6, receipt$fields_compared,
    seal2_json_number(receipt$max_abs_delta),
    seal2_json_number(receipt$max_abs_additive_delta), receipt$parity_sha256
  )
}

seal2_hold_json <- function(receipt) {
  seal2_validate_hold_receipt(receipt)
  sprintf(
    paste0(
      '{"schema":"%s","status":"HOLD",',
      '"hard_failure_code":"empty_required_table",',
      '"affected_bundles":%d,"bundles_checked":%d,',
      '"parity_attempted":false,"current_fetched":false,',
      '"current_deserialized":false,',
      '"effect_module_sourced":false,"effect_function_called":false}'
    ),
    receipt$schema, receipt$affected_bundles, receipt$bundles_checked
  )
}

seal2_run_orchestrator <- function() {
  seal2_with_repo({
    before <- seal2_artifact_state()
    seal2_run_static()
    authority <- seal2_legacy_authority()
    preflight <- seal2_preflight_legacy(authority$files)
    if (preflight$affected_bundles > 0L) {
      receipt <- seal2_hold_receipt(preflight)
      after <- seal2_artifact_state()
      seal2_assert(identical(before, after), "artifact_nonmutation")
      cat(seal2_hold_json(receipt), "\n", sep = "")
      return(invisible(TRUE))
    }
    seal2_run_synthetic()
    first <- seal2_run_clean_worker()
    second <- seal2_run_clean_worker()
    if (identical(first$result$status, "FAIL") ||
        identical(second$result$status, "FAIL")) {
      seal2_assert(identical(first$result, second$result),
                   "worker_failure_nondeterminism")
      seal2_abort(first$result$code)
    }
    seal2_assert(first$exit_status == 0L && second$exit_status == 0L,
                 "worker_exit_status")
    seal2_validate_receipt(first$result)
    seal2_validate_receipt(second$result)
    seal2_assert(identical(first$result, second$result),
                 "two_process_determinism")
    after <- seal2_artifact_state()
    seal2_assert(identical(before, after), "artifact_nonmutation")
    cat(seal2_receipt_json(first$result), "\n", sep = "")
    invisible(TRUE)
  })
}

seal2_main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  mode <- if (!length(arguments)) "--orchestrator" else arguments[1L]
  seal2_assert(length(arguments) <= 1L &&
                 mode %in% c("--orchestrator", "--worker", "--static", "--synthetic"),
               "entrypoint")
  if (identical(mode, "--worker")) seal2_run_worker()
  if (identical(mode, "--static")) return(seal2_run_static())
  if (identical(mode, "--synthetic")) return(seal2_run_synthetic())
  seal2_run_orchestrator()
}

if (identical(environment(), globalenv())) {
  tryCatch(
    seal2_main(),
    error = function(condition) {
      cat(sprintf("Phenology Seal-2 failure [%s]\n", seal2_error_code(condition)),
          file = stderr())
      quit(save = "no", status = 1L, runLast = FALSE)
    }
  )
}
