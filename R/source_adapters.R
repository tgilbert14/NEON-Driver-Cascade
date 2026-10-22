# Reviewed, build-only adapters for the two sibling products whose applications
# expose reusable helper code. The cascade must treat sibling repositories as
# data inputs: refresh CI may read their committed bundles, but it must never
# source or execute code from them.

GREENUP <- c("Breaking leaf buds", "Initial growth", "Emerging needles",
             "Breaking needle buds")

# Explicit input contracts for sibling artifacts. A missing per-site file can be
# legitimate, but once a file exists its container, tables, and columns are not
# optional: silently treating malformed data as an absent product would publish
# an incomplete synthesis without an error.
CASCADE_PLANT_OCC_REQUIRED <- c(
  "year", "is_species", "scientificName", "percentCover", "plotID",
  "subplotID", "scale", "bout", "nativeStatusCode")
CASCADE_BIRD_OBS_REQUIRED <- c(
  "year", "pointkey", "clusterSize", "detectionMethod", "is_species",
  "scientificName")
CASCADE_MOSQ_OBS_REQUIRED <- c(
  "year", "is_target", "count", "genus", "is_species", "scientificName")
CASCADE_MOSQ_EFFORT_REQUIRED <- c("year")
# The mosquito sibling renamed its weekly effort column in the release merged
# 2026-08-05: `trap_nights` became `effort_days`. Both hold the same unit
# (trapHours / 24), but the new column sums only deployments the source marks
# valid (sampled, usable duration and identity) instead of every row with
# positive trap hours, so a refreshed denominator can be smaller than an
# earlier published one and raise mosq_activity. Read whichever name the bundle
# publishes, preferring the current one exactly as the producing app does;
# neither present stays fatal, and one bundle set must resolve to one basis.
CASCADE_MOSQ_EFFORT_FIELDS <- c("effort_days", "trap_nights")
CASCADE_BEETLE_REQUIRED <- c(
  "collectDate", "plotID", "scientificName", "taxonRank",
  "individualCount", "trapnights")
CASCADE_MAMMAL_REQUIRED <- c(
  "collectDate", "nightuid", "plotID", "trapCoordinate", "trapStatus", "tagID",
  "remarks")
CASCADE_VEG_TREES_REQUIRED <- c(
  "individualID", "plotID", "date", "scientificName", "live", "growthForm",
  "stemDiameter", "basalStemDiameter")
CASCADE_VEG_PLOTS_REQUIRED <- c("plotID", "area_trees", "area_shrub")
CASCADE_MAMMAL_TRAP_EFFORT <- c(
  "1 - trap not set" = 0,
  "2 - trap disturbed/door closed but empty" = 0.5,
  "3 - trap door open or closed w/ spoor left" = 0.5,
  "4 - more than 1 capture in one trap" = 1,
  "5 - capture" = 1,
  "6 - trap set and empty" = 1)
CASCADE_MAMMAL_GRID_COORDINATE_RE <- "^[A-J](?:[1-9]|10)$"
CASCADE_MAMMAL_PLACEHOLDER_COORDINATE_RE <-
  "^(?:[A-J]X|X(?:[1-9]|10)|XX)$"
CASCADE_MAMMAL_REVIEWED_MULTI_TRAP_MARKERS <- c(
  "trap accidentally double set",
  "double trap method (two traps set at each location)")

cascade_mammal_trap_effort <- function(status) {
  token <- tolower(trimws(as.character(status)))
  token[is.na(status)] <- NA_character_
  out <- unname(CASCADE_MAMMAL_TRAP_EFFORT[token])
  unknown <- is.na(out)
  if (any(unknown))
    stop(sprintf("mammal bundle has %d unknown/non-exact trapStatus token(s): %s",
                 sum(unknown),
                 paste(utils::head(sort(unique(token[unknown])), 5L),
                       collapse = ", ")), call. = FALSE)
  as.numeric(out)
}

cascade_mammal_tag_present <- function(tag_id) {
  tag <- as.character(tag_id)
  !is.na(tag_id) & nzchar(trimws(tag))
}

cascade_mammal_multi_trap_marker <- function(remarks) {
  x <- tolower(as.character(remarks))
  vapply(x, function(value) {
    if (is.na(value)) return(0L)
    hit <- which(vapply(CASCADE_MAMMAL_REVIEWED_MULTI_TRAP_MARKERS,
                        grepl, logical(1), x = value, fixed = TRUE))
    if (length(hit) == 1L) as.integer(hit) else 0L
  }, integer(1))
}

cascade_resolve_last_complete_year <- function(override, source_epoch,
                                                min_year = 2013L) {
  if (length(source_epoch) != 1L || !is.finite(source_epoch) || source_epoch < 0)
    stop("source cutoff epoch must be one finite nonnegative value", call. = FALSE)
  source_year <- as.integer(format(
    as.POSIXct(source_epoch, origin = "1970-01-01", tz = "UTC"),
    "%Y", tz = "UTC")) - 1L
  override <- as.character(override)
  if (length(override) != 1L || is.na(override))
    stop("CASCADE_LAST_COMPLETE_YEAR must be one nonmissing value", call. = FALSE)
  if (nzchar(override)) {
    if (!grepl("^[0-9]{4}$", override))
      stop("CASCADE_LAST_COMPLETE_YEAR must be exactly four decimal digits",
           call. = FALSE)
    year <- as.integer(override)
    if (year > source_year)
      stop(sprintf(
        "CASCADE_LAST_COMPLETE_YEAR=%d exceeds the source-derived complete-year ceiling %d",
        year, source_year), call. = FALSE)
    basis <- "explicit CASCADE_LAST_COMPLETE_YEAR"
  } else {
    year <- source_year
    basis <- "UTC year(max source commit epoch) - 1"
  }
  if (!is.finite(year) || year < min_year)
    stop(sprintf("last complete year must be >= %d", as.integer(min_year)),
         call. = FALSE)
  list(year = as.integer(year), basis = basis,
       source_epoch = as.numeric(source_epoch),
       source_year = as.integer(source_year))
}

cascade_data_frame <- function(x, label) {
  if (!is.data.frame(x))
    stop(sprintf("%s must be a data frame", label), call. = FALSE)
  x
}

cascade_bundle_table <- function(bundle, table, product, site) {
  label <- sprintf("%s %s bundle", site, product)
  if (!is.list(bundle) || is.data.frame(bundle))
    stop(sprintf("%s must be a named list", label), call. = FALSE)
  if (is.null(names(bundle)) || !table %in% names(bundle) || is.null(bundle[[table]]))
    stop(sprintf("%s lacks required table '%s'", label, table), call. = FALSE)
  cascade_data_frame(bundle[[table]], sprintf("%s table '%s'", label, table))
}

cascade_require_columns <- function(x, required, label) {
  cascade_data_frame(x, label)
  missing <- setdiff(required, names(x))
  if (length(missing))
    stop(sprintf("%s lacks required field(s): %s", label,
                 paste(missing, collapse = ", ")), call. = FALSE)
  invisible(x)
}

# Resolve the mosquito weekly-effort column and remember which basis the whole
# bundle set used, so the published codebook states the effort basis that
# actually produced the numbers rather than a fixed sentence.
.cascade_mosq_effort_state <- new.env(parent = emptyenv())

cascade_mosq_effort_field <- function(x, label) {
  cascade_require_columns(x, CASCADE_MOSQ_EFFORT_REQUIRED, label)
  present <- CASCADE_MOSQ_EFFORT_FIELDS[CASCADE_MOSQ_EFFORT_FIELDS %in% names(x)]
  if (!length(present))
    stop(sprintf("%s lacks required field(s): one of %s", label,
                 paste(CASCADE_MOSQ_EFFORT_FIELDS, collapse = ", ")), call. = FALSE)
  field <- present[1L]
  seen <- .cascade_mosq_effort_state$field
  if (!is.null(seen) && !identical(seen, field))
    stop(sprintf("%s resolves mosquito effort to '%s' after '%s'; one bundle set must use one effort basis",
                 label, field, seen), call. = FALSE)
  .cascade_mosq_effort_state$field <- field
  field
}

cascade_mosq_effort_basis <- function() .cascade_mosq_effort_state$field

cascade_mosq_effort_note <- function() {
  base <- "NA when effort_week is unavailable that year; includes attempted zero-catch deployments."
  if (identical(cascade_mosq_effort_basis(), "effort_days"))
    return(paste(base,
                 "Effort counts only deployments the source bundle marks valid (sampled, usable duration and identity), so this denominator can be smaller than an earlier published one."))
  base
}

# Resolve mammal effort at the physical-trap-event level. A canonical NEON grid
# coordinate (A-J x 1-10) normally identifies one trap. Status 4 explicitly
# emits one row per animal from a single multi-capture trap, so reviewed 4/5
# groups are one trap-night while every distinct tag remains a capture. Two
# pinned exceptions document two physical traps at one coordinate in `remarks`;
# their row weights are summed. AX-JX, X1-X10, and XX are non-unique placeholder
# coordinates, so each source row remains an explicitly uncertain row-level
# effort contribution. Every other duplicate/coordinate pattern fails closed.
cascade_mammal_effort_events <- function(d, year, label = "mammal bundle") {
  cascade_require_columns(d, CASCADE_MAMMAL_REQUIRED, label)
  if (length(year) != nrow(d) || any(!is.finite(year)) ||
      any(year != as.integer(year)))
    stop(sprintf("%s requires one finite integer year per row", label),
         call. = FALSE)
  if (!nrow(d))
    return(data.frame(
      year = integer(), trap_event = character(), trap_effort = numeric(),
      effort_rule = character(), source_row_count = integer(),
      stringsAsFactors = FALSE))

  event_cols <- c("nightuid", "plotID", "trapCoordinate")
  bad_key <- Reduce(`|`, lapply(event_cols, function(k) {
    value <- as.character(d[[k]])
    is.na(d[[k]]) | !nzchar(value)
  }))
  if (any(bad_key))
    stop(sprintf("%s has %d rows without a complete trap-event key",
                 label, sum(bad_key)), call. = FALSE)

  coordinate <- as.character(d$trapCoordinate)
  canonical <- grepl(CASCADE_MAMMAL_GRID_COORDINATE_RE, coordinate, perl = TRUE)
  placeholder <- grepl(CASCADE_MAMMAL_PLACEHOLDER_COORDINATE_RE,
                       coordinate, perl = TRUE)
  unknown_coordinate <- !(canonical | placeholder)
  if (any(unknown_coordinate))
    stop(sprintf("%s has %d unreviewed trapCoordinate token(s): %s",
                 label, sum(unknown_coordinate),
                 paste(utils::head(sort(unique(coordinate[unknown_coordinate])),
                                   5L), collapse = ", ")), call. = FALSE)

  status <- tolower(trimws(as.character(d$trapStatus)))
  effort <- cascade_mammal_trap_effort(status)
  tag <- trimws(as.character(d$tagID))
  tag_present <- cascade_mammal_tag_present(d$tagID)
  marker <- cascade_mammal_multi_trap_marker(d$remarks)
  physical_key <- paste(as.integer(year), d$nightuid, d$plotID, coordinate,
                        sep = "|")

  pack <- function(ix, trap_event, trap_effort, effort_rule) {
    data.frame(
      year = as.integer(year[ix[[1L]]]), trap_event = trap_event,
      trap_effort = as.numeric(trap_effort), effort_rule = effort_rule,
      source_row_count = as.integer(length(ix)), stringsAsFactors = FALSE)
  }
  duplicated_canonical <- canonical &
    (duplicated(physical_key) | duplicated(physical_key, fromLast = TRUE))
  duplicate_rows <- which(duplicated_canonical)
  groups <- split(duplicate_rows, physical_key[duplicate_rows])
  result <- vector("list", 2L + length(groups))
  at <- 0L

  # Placeholder coordinates deliberately do not group: the token cannot prove
  # that two rows came from the same physical trap.
  placeholder_rows <- which(placeholder)
  if (length(placeholder_rows)) {
    at <- at + 1L
    result[[at]] <- data.frame(
      year = as.integer(year[placeholder_rows]),
      trap_event = paste("placeholder-row", placeholder_rows, sep = "|"),
      trap_effort = as.numeric(effort[placeholder_rows]),
      effort_rule = rep("placeholder-row-level", length(placeholder_rows)),
      source_row_count = rep(1L, length(placeholder_rows)),
      stringsAsFactors = FALSE)
  }

  canonical_single_rows <- which(canonical & !duplicated_canonical)
  if (length(canonical_single_rows)) {
    at <- at + 1L
    result[[at]] <- data.frame(
      year = as.integer(year[canonical_single_rows]),
      trap_event = physical_key[canonical_single_rows],
      trap_effort = as.numeric(effort[canonical_single_rows]),
      effort_rule = rep("canonical-single", length(canonical_single_rows)),
      source_row_count = rep(1L, length(canonical_single_rows)),
      stringsAsFactors = FALSE)
  }

  # Only duplicated canonical keys require group-wise scientific resolution;
  # the millions of ordinary singleton events stay vectorized.
  for (ix in groups) {
    at <- at + 1L
    key <- physical_key[ix[[1L]]]
    capture_status <- status[ix] %in% c(
      "4 - more than 1 capture in one trap", "5 - capture")
    has_multi_capture_status <- any(
      status[ix] == "4 - more than 1 capture in one trap")
    reviewed_marker <- length(ix) == 2L && all(marker[ix] > 0L) &&
      length(unique(marker[ix])) == 1L
    same_collect_date <- length(unique(as.character(d$collectDate[ix]))) == 1L
    reviewed_tags <- tag[ix][tag_present[ix]]
    reviewed_tags_unique <- !anyDuplicated(reviewed_tags)
    one_trap_multi_capture <- all(capture_status) &&
      has_multi_capture_status && all(tag_present[ix]) &&
      !anyDuplicated(tag[ix]) && all(marker[ix] == 0L) && same_collect_date

    if (one_trap_multi_capture) {
      result[[at]] <- pack(ix, key, 1,
                           "canonical-multi-capture-one-trap")
    } else if (reviewed_marker && !has_multi_capture_status &&
               reviewed_tags_unique && same_collect_date) {
      result[[at]] <- pack(ix, key, sum(effort[ix]),
                           "reviewed-double-trap-rows")
    } else {
      stop(sprintf(
        "%s has an unreviewed duplicated canonical trap event %s (%d rows; statuses: %s)",
        label, key, length(ix), paste(sort(unique(status[ix])), collapse = " + ")),
        call. = FALSE)
    }
  }

  out <- do.call(rbind, result[seq_len(at)])
  rownames(out) <- NULL
  out
}

cascade_onset <- function(obs, phenophases = NULL) {
  required <- c("individualID", "scientificName", "growthForm",
                "phenophaseName", "year", "status", "dayOfYear")
  missing <- setdiff(required, names(obs))
  if (length(missing))
    stop(sprintf("phenology observations lack adapter field(s): %s",
                 paste(missing, collapse = ", ")), call. = FALSE)
  d <- obs[obs$status %in% c("yes", "no") & is.finite(obs$dayOfYear), , drop = FALSE]
  if (!is.null(phenophases))
    d <- d[d$phenophaseName %in% phenophases, , drop = FALSE]
  if (!nrow(d)) return(NULL)
  d %>%
    dplyr::group_by(.data$individualID, .data$scientificName, .data$growthForm,
                    .data$phenophaseName, .data$year) %>%
    dplyr::summarise(
      onset_doy = {
        yes <- .data$dayOfYear[.data$status == "yes"]
        no <- .data$dayOfYear[.data$status == "no"]
        if (!length(yes)) NA_real_ else {
          first <- min(yes)
          preceding <- no[no < first]
          if (length(preceding)) (max(preceding) + first) / 2 else first
        }
      },
      left_censored = {
        yes <- .data$dayOfYear[.data$status == "yes"]
        no <- .data$dayOfYear[.data$status == "no"]
        if (!length(yes)) NA else !length(no[no < min(yes)])
      },
      first_yes = if (any(.data$status == "yes"))
        min(.data$dayOfYear[.data$status == "yes"]) else NA_real_,
      .groups = "drop") %>%
    dplyr::filter(is.finite(.data$onset_doy))
}

# Collapse phase-level onset rows to the earliest individual-year record. dplyr
# summaries are sequential: naming the first result onset_doy would mask the raw
# phase vector in every later expression. Keep a noncolliding name until all tied
# censoring, taxonomy, and interval-width calculations have consumed raw rows.
cascade_individual_year_onset <- function(o) {
  required <- c("individualID", "scientificName", "year", "onset_doy",
                "left_censored", "first_yes")
  cascade_require_columns(o, required, "phase-level phenology onsets")
  if (any(!is.finite(o$year) | !is.finite(o$onset_doy)))
    stop("phase-level phenology onsets require finite year and onset_doy",
         call. = FALSE)
  if (!nrow(o))
    return(tibble::tibble(
      individualID = character(), year = integer(), onset_doy = numeric(),
      left_censored = logical(), scientificName = character(),
      onset_interval_days = numeric()))

  o %>%
    dplyr::group_by(.data$individualID, .data$year) %>%
    dplyr::summarise(
      .min_onset_doy = min(.data$onset_doy),
      left_censored = {
        tied <- .data$onset_doy == min(.data$onset_doy)
        any(.data$left_censored[tied] %in% TRUE)
      },
      scientificName = {
        tied <- .data$onset_doy == min(.data$onset_doy)
        sort(unique(as.character(.data$scientificName[tied])),
             method = "radix")[1]
      },
      onset_interval_days = {
        tied <- .data$onset_doy == min(.data$onset_doy)
        widths <- 2 * (.data$first_yes[tied] - .data$onset_doy[tied])
        widths <- widths[is.finite(widths)]
        if (length(widths)) max(widths) else NA_real_
      },
      .groups = "drop") %>%
    dplyr::rename(onset_doy = .min_onset_doy)
}

CASCADE_TREE_FORMS <- c("single bole tree", "multi-bole tree", "small tree")
CASCADE_SHRUB_FORMS <- c("single shrub", "small shrub", "sapling", "small tree")
CASCADE_TREE_DBH_MIN <- 10
CASCADE_SIZE_FOREST <- list(type = "forest", col = "stemDiameter",
  min = CASCADE_TREE_DBH_MIN, area = "area_trees", forms = CASCADE_TREE_FORMS)
CASCADE_SIZE_SHRUB <- list(type = "shrubland", col = "basalStemDiameter",
  min = 0, area = "area_shrub", forms = CASCADE_SHRUB_FORMS)
CASCADE_VEG_CLASSIFICATION_BASIS <- paste(
  "latest plotID+individualID-date rows are treated as stems because stemID is",
  "unavailable (including exact duplicates that cannot be adjudicated); eligible",
  "live/form tree stemDiameter >=10 cm and shrub basalStemDiameter >0 are summed",
  "as stem d^2, then each component is divided by its own qualifying design area")
CASCADE_VEG_STAND_BASIS <- paste(
  "mean basal area per hectare conditional on record-bearing plots with at",
  "least one qualifying live stem and valid selected-design area; latest-date",
  "rows are stems (stemID unavailable; exact duplicates retained), stem d^2 is",
  "summed, and plots with no qualifying record are not imputed as sampled zero")
CASCADE_VEG_DESIGN_BASIS <- paste(
  "per-hectare vegetation structure requires every record-bearing plotID to",
  "map to the bundle's unique plot-area design table; any unmatched record plot",
  "makes the entire site's structure unsupported, so no area is imputed and no",
  "matched subset is estimated")

cascade_size_spec <- function(type) {
  if (identical(type, "shrubland")) CASCADE_SIZE_SHRUB else CASCADE_SIZE_FOREST
}

cascade_live_only <- function(d) {
  if (is.null(d)) return(d)
  cascade_require_columns(d, "live", "vegetation stem table")
  if (!nrow(d)) return(d)
  d[d$live %in% TRUE, , drop = FALSE]
}

cascade_classify_structure <- function(snap, plots) {
  cascade_structure_evidence(snap, plots)$type
}

cascade_tree_snapshot <- function(trees) {
  if (is.null(trees)) return(trees)
  cascade_require_columns(
    trees, c("plotID", "individualID", "date", "scientificName"),
    "vegetation tree table")
  if (!nrow(trees)) return(trees)
  bad_key <- is.na(trees$plotID) | !nzchar(trimws(as.character(trees$plotID))) |
    is.na(trees$individualID) | !nzchar(trimws(as.character(trees$individualID)))
  if (any(bad_key))
    stop(sprintf("vegetation tree table has %d row(s) without a complete plotID + individualID key",
                 sum(bad_key)), call. = FALSE)
  measurement_date <- tryCatch(as.Date(trees$date), error = function(e)
    rep(as.Date(NA), nrow(trees)))
  if (anyNA(measurement_date))
    stop(sprintf("vegetation tree table has %d row(s) without a valid measurement date",
                 sum(is.na(measurement_date))), call. = FALSE)
  trees$.cascade_measurement_date <- measurement_date
  out <- trees %>%
    dplyr::group_by(.data$plotID, .data$individualID) %>%
    dplyr::filter(.data$.cascade_measurement_date ==
                    max(.data$.cascade_measurement_date)) %>%
    dplyr::ungroup()
  # The source omits stemID: tied rows at an individual's latest date are
  # interpreted as stem rows and retained, including exact-row duplicates that
  # cannot be adjudicated. Stem-level live state, growth form, and diameter may
  # legitimately differ; plot, individual, and date are fixed by the grouping.
  # Scientific identity is the one whole-plant attribute that must remain stable.
  latest_key <- paste(out$plotID, out$individualID, sep = "\r")
  species <- ifelse(is.na(out$scientificName), "<NA>",
                    trimws(as.character(out$scientificName)))
  species_n <- tapply(species, latest_key, function(x) length(unique(x)))
  if (any(species_n != 1L))
    stop(sprintf(
      "vegetation tree table has %d latest plotID + individualID group(s) with conflicting scientificName",
      sum(species_n != 1L)), call. = FALSE)
  out$.cascade_measurement_date <- NULL
  out
}

cascade_woody_only <- function(d, spec = CASCADE_SIZE_FOREST) {
  if (is.null(d)) return(d)
  required_spec <- c("type", "col", "min", "area", "forms")
  if (!is.list(spec) || length(setdiff(required_spec, names(spec))) ||
      length(spec$col) != 1L || length(spec$min) != 1L ||
      !is.finite(spec$min) || !length(spec$forms))
    stop("vegetation size specification is malformed", call. = FALSE)
  cascade_require_columns(d, c("growthForm", spec$col),
                          sprintf("%s vegetation stem table", spec$type))
  if (!nrow(d)) return(d)
  x <- suppressWarnings(as.numeric(d[[spec$col]]))
  d[d$growthForm %in% spec$forms & is.finite(x) & x > 0 & x >= spec$min,
    , drop = FALSE]
}

cascade_plot_design <- function(plots, areas = character(), label = "vegetation plot table") {
  cascade_require_columns(plots, c("plotID", areas), label)
  bad_key <- is.na(plots$plotID) | !nzchar(trimws(as.character(plots$plotID)))
  if (any(bad_key))
    stop(sprintf("%s has %d row(s) without plotID", label, sum(bad_key)),
         call. = FALSE)
  duplicate <- duplicated(as.character(plots$plotID)) |
    duplicated(as.character(plots$plotID), fromLast = TRUE)
  if (any(duplicate))
    stop(sprintf("%s has duplicate/conflicting plotID/area records: %s", label,
                 paste(sort(unique(as.character(plots$plotID[duplicate]))),
                       collapse = ", ")), call. = FALSE)
  plots
}

cascade_vegetation_design_support <- function(snap, plots) {
  cascade_require_columns(snap, "plotID", "vegetation structure snapshot")
  plots <- cascade_plot_design(
    plots, c("area_trees", "area_shrub"), "vegetation structure plot table")
  if (!nrow(snap))
    return(list(snapshot = snap, plots = plots, supported = TRUE,
                n_record_plots = 0L, n_matched_record_plots = 0L,
                n_unmatched_record_plots = 0L, n_unmatched_record_rows = 0L,
                basis = CASCADE_VEG_DESIGN_BASIS))

  record_plot <- as.character(snap$plotID)
  bad_key <- is.na(snap$plotID) | !nzchar(trimws(record_plot))
  if (any(bad_key))
    stop(sprintf("vegetation structure snapshot has %d row(s) without plotID",
                 sum(bad_key)), call. = FALSE)
  matched_row <- !is.na(match(record_plot, as.character(plots$plotID)))
  record_ids <- unique(record_plot)
  matched_id <- !is.na(match(record_ids, as.character(plots$plotID)))
  supported <- all(matched_id)
  list(
    # A partially supported subset is not a defensible site estimand. Preserve
    # counts for audit, but expose zero rows so no downstream helper can silently
    # standardize only the convenient portion of the site.
    snapshot = if (supported) snap else snap[0, , drop = FALSE],
    plots = plots,
    supported = supported,
    n_record_plots = as.integer(length(record_ids)),
    n_matched_record_plots = as.integer(sum(matched_id)),
    n_unmatched_record_plots = as.integer(sum(!matched_id)),
    n_unmatched_record_rows = as.integer(sum(!matched_row)),
    basis = CASCADE_VEG_DESIGN_BASIS)
}

cascade_structure_evidence <- function(snap, plots) {
  cascade_require_columns(
    snap, c("plotID", "individualID", "live", "growthForm",
            "stemDiameter", "basalStemDiameter"),
    "vegetation structure snapshot")
  plots <- cascade_plot_design(
    plots, c("area_trees", "area_shrub"), "vegetation structure plot table")
  if (!nrow(snap))
    return(list(type = "forest", tree_ba_ha = 0, shrub_ba_ha = 0,
                tree_n_plots = 0L, shrub_n_plots = 0L,
                basis = CASCADE_VEG_CLASSIFICATION_BASIS))

  record_ids <- unique(as.character(snap$plotID))
  if (anyNA(match(record_ids, as.character(plots$plotID))))
    stop("vegetation structure snapshot contains plotID absent from plot table",
         call. = FALSE)
  component <- function(spec) {
    stems <- cascade_woody_only(cascade_live_only(snap), spec)
    if (is.null(stems) || !nrow(stems))
      return(list(ba_ha = 0, n_plots = 0L))
    stems$.d <- suppressWarnings(as.numeric(stems[[spec$col]]))
    used <- unique(as.character(stems$plotID))
    area <- suppressWarnings(as.numeric(
      plots[[spec$area]][match(used, as.character(plots$plotID))]))
    if (any(!is.finite(area) | area <= 0))
      stop(sprintf("%s structure classification has qualifying plot(s) without positive finite %s",
                   spec$type, spec$area), call. = FALSE)
    eligible <- area > 50
    if (!any(eligible))
      return(list(ba_ha = 0, n_plots = 0L))
    stems <- stems[as.character(stems$plotID) %in% used[eligible], , drop = FALSE]
    ba <- sum(pi * (stems$.d / 200)^2)
    list(ba_ha = ba / (sum(area[eligible]) / 10000),
         n_plots = as.integer(sum(eligible)))
  }
  tree <- component(CASCADE_SIZE_FOREST)
  shrub <- component(CASCADE_SIZE_SHRUB)
  type <- if (tree$ba_ha == 0 && shrub$ba_ha == 0) "forest" else
    if (tree$ba_ha >= shrub$ba_ha) "forest" else "shrubland"
  list(type = type, tree_ba_ha = as.numeric(tree$ba_ha),
       shrub_ba_ha = as.numeric(shrub$ba_ha),
       tree_n_plots = tree$n_plots, shrub_n_plots = shrub$n_plots,
       basis = CASCADE_VEG_CLASSIFICATION_BASIS)
}

cascade_stand_by_plot <- function(snap, plots, spec = CASCADE_SIZE_FOREST) {
  if (is.null(snap)) return(NULL)
  cascade_require_columns(
    snap, c("plotID", "individualID", "live", "growthForm", spec$col),
    sprintf("%s vegetation snapshot", spec$type))
  plots <- cascade_plot_design(
    plots, spec$area, sprintf("%s vegetation plot table", spec$type))
  if (!nrow(snap)) return(NULL)

  record_ids <- unique(as.character(snap$plotID))
  record_rows <- match(record_ids, as.character(plots$plotID))
  if (anyNA(record_rows))
    stop(sprintf("%s vegetation snapshot contains plotID absent from plot table",
                 spec$type), call. = FALSE)
  record_area <- suppressWarnings(as.numeric(plots[[spec$area]][record_rows]))
  n_area_eligible <- as.integer(sum(is.finite(record_area) & record_area > 50))

  s <- cascade_woody_only(cascade_live_only(snap), spec)
  if (is.null(s) || !nrow(s)) return(NULL)
  bad_stem_plot <- is.na(s$plotID) | !nzchar(trimws(as.character(s$plotID)))
  if (any(bad_stem_plot))
    stop(sprintf("%s vegetation snapshot has %d eligible stem(s) without plotID",
                 spec$type, sum(bad_stem_plot)), call. = FALSE)
  s$.d <- suppressWarnings(as.numeric(s[[spec$col]]))
  s$ba_m2 <- pi * (s$.d / 200)^2
  per <- s %>%
    dplyr::group_by(.data$plotID) %>%
    dplyr::summarise(stems = dplyr::n_distinct(.data$individualID),
                     ba_m2 = sum(.data$ba_m2), sumD2 = sum(.data$.d^2),
                     .groups = "drop")
  pa <- plots[, c("plotID", spec$area), drop = FALSE]
  names(pa)[2] <- "area_use"
  pa$area_use <- suppressWarnings(as.numeric(pa$area_use))
  per <- dplyr::left_join(per, pa, by = "plotID", relationship = "many-to-one")
  bad_area <- !is.finite(per$area_use) | per$area_use <= 0
  if (any(bad_area))
    stop(sprintf("%s vegetation stand has %d qualifying plot(s) without positive finite %s",
                 spec$type, sum(bad_area), spec$area), call. = FALSE)
  per$area_ha <- per$area_use / 10000
  per <- per[per$area_ha > 0.005, , drop = FALSE]
  if (!nrow(per)) return(NULL)
  per$ba_ha <- per$ba_m2 / per$area_ha
  per$density_ha <- per$stems / per$area_ha
  attr(per, "n_record_plots") <- as.integer(length(record_ids))
  attr(per, "n_area_eligible_plots") <- n_area_eligible
  attr(per, "stand_basis") <- CASCADE_VEG_STAND_BASIS
  per
}

cascade_stand_site <- function(snap, plots, spec = CASCADE_SIZE_FOREST) {
  per <- cascade_stand_by_plot(snap, plots, spec)
  if (is.null(per)) return(NULL)
  n <- nrow(per)
  se <- function(x) if (n > 1) stats::sd(x, na.rm = TRUE) / sqrt(n) else NA_real_
  list(ba_ha = mean(per$ba_ha, na.rm = TRUE),
       ba_se = se(per$ba_ha), n_plots = n,
       n_record_plots = attr(per, "n_record_plots"),
       n_area_eligible_plots = attr(per, "n_area_eligible_plots"),
       basis = attr(per, "stand_basis"))
}

# ---------------------------------------------------------------------------
# Vegetation plot-event contract (NEON-VST-DP1.10098.001-v2).
# The Vegetation sibling's v2 bundle keys `plots` by (plotID, eventID) and
# carries eventID on every tree row, with per-event areas and per-channel
# support states. The legacy helpers above stay the exact rule for the legacy
# one-row-per-plot shape. The functions below are the event-aware path ruled
# 2026-10-21 (adapter rulings R1 to R7): per channel, admit plot events by
# their support state, pick the latest admissible event per plot, reduce that
# event's rows to latest-date stems, and divide each stem by that event's own
# channel area. Stems are never carried across events and areas are never
# summed across events. Classification and the stand reuse the unchanged
# cascade_structure_evidence() and cascade_stand_site().
# ---------------------------------------------------------------------------
CASCADE_VEG_V2_CONTRACT_ID <- "NEON-VST-DP1.10098.001-v2"
CASCADE_VEG_V2_CONTRACT_VERSION <- 2L
CASCADE_VEG_LEGACY_CONTRACT <- "legacy-one-row-per-plot"
CASCADE_VEG_SUPPORT_STATES <- c(
  "sampled_with_records", "sampled_absence", "held_sampling_impractical",
  "held_dendrometer_only", "held_missing_area", "held_opportunity_unknown",
  "held_metric_invalid", "held_identity_conflict",
  "held_presence_record_conflict", "held_opportunity_source_missing")
CASCADE_VEG_EVENT_ADMIT_STATES <- c("sampled_with_records", "held_metric_invalid")
CASCADE_VEG_EVENT_ABSENCE_STATE <- "sampled_absence"
CASCADE_VEG_SOURCE_MISSING_STATE <- "held_opportunity_source_missing"
CASCADE_VEG_VINTAGE_REASONS <- c("samplingImpractical is missing",
                                 "dataCollected is missing")
CASCADE_VEG_NO_RECORDS_REASON <-
  "no records and presence does not establish sampled absence"
CASCADE_VEG_PARTIAL_REASON_PATTERN <- "^dataCollected="
CASCADE_VEG_NONLOGISTICAL_HOLD_CODES <- c("extreme weather", "location flooded", "other")
CASCADE_VEG_NONLOGISTICAL_HOLD_BASIS <- paste(
  "count of plots entering veg_ba_ha whose selected survey is older than a later",
  "survey of the same channel that NEON held as sampling impractical for a",
  "non-logistical code (extreme weather, location flooded or other); a screen for",
  "surveys a disturbance may have overtaken, not a count of disturbances: access",
  "holds such as deep snow count too, and NEON codes some fires as other")
CASCADE_VEG_EVENT_MIN_AREA_M2 <- 50
CASCADE_VEG_V2_TREES_REQUIRED <- c(CASCADE_VEG_TREES_REQUIRED, "eventID")
CASCADE_VEG_V2_PLOTS_REQUIRED <- c(
  "plotID", "eventID", "date", "dataCollected", "samplingImpractical",
  "treesPresent", "shrubsPresent", "area_trees", "area_shrub",
  "tree_support", "tree_support_reason", "shrub_support",
  "shrub_support_reason", "tree_records", "shrub_records",
  "tree_identity_conflict_keys", "shrub_identity_conflict_keys")
CASCADE_VEG_EVENT_CHANNELS <- list(
  tree = list(spec = CASCADE_SIZE_FOREST, support = "tree_support",
              reason = "tree_support_reason", area = "area_trees",
              conflict = "tree_identity_conflict_keys",
              records = "tree_records", presence = "treesPresent"),
  shrub = list(spec = CASCADE_SIZE_SHRUB, support = "shrub_support",
               reason = "shrub_support_reason", area = "area_shrub",
               conflict = "shrub_identity_conflict_keys",
               records = "shrub_records", presence = "shrubsPresent"))
CASCADE_VEG_EVENT_RULE <- paste(
  "one selected event per plot and channel: the latest admissible event by",
  "its latest measurement date (the plot table's event date when it has no",
  "rows, then eventID); dataCollected=partial events held; the area gate",
  "(>50 m2) applies before selection; no stems carried across events")
CASCADE_VEG_EVENT_ADMITTED_STATES <- paste(
  "sampled_with_records; held_metric_invalid (invalid rows dropped);",
  "sampled_absence (zero stems, blocks fallback); held_opportunity_unknown",
  "only for a pre-2020 field gap or a no-records reason, and only when the",
  "event has rows for the channel or, for a pre-2020 gap, recorded absence")
CASCADE_VEG_EVENT_STAND_BASIS <- paste(
  "mean live basal area per hectare over plots whose selected event has at",
  "least one qualifying live stem; per plot and channel the selected event is",
  "the latest admissible NEON plot event (contract v2), its latest-date rows",
  "per individual are stems, exact duplicate rows retained, each divided by",
  "that event's own channel area (>50 m2); stems are never carried across",
  "events, and plots without a qualifying stem are not imputed as zero")
CASCADE_VEG_EVENT_CLASSIFICATION_BASIS <- paste(
  "forest versus shrubland compares area-normalized live basal area from two",
  "separate event selections: tree stemDiameter >=10 cm from each plot's latest",
  "admissible tree-channel event over that event's area_trees, and shrub",
  "basalStemDiameter >0 from each plot's latest admissible shrub-channel event",
  "over that event's area_shrub; latest-date rows per individual within the",
  "event are stems (exact duplicate rows retained; the protocol stem locator",
  "is not used yet), and events with area <=50 m2 are not admissible")
CASCADE_VEG_EVENT_DESIGN_BASIS <- paste(
  "per channel a plot event is admissible only under the contract v2 support",
  "rules (sampled with records, metric-invalid rows dropped, recorded absence",
  "as zero stems, gated pre-2020 events with channel rows) and only with its",
  "own channel area above 50 m2; partial, sampling-impractical and conflicting events are",
  "held; a plot with no admissible event is a counted exclusion, never imputed",
  "or borrowed, and if every event of a record-bearing plot lacks its",
  "opportunity source the whole site is unsupported")

cascade_veg_blank <- function(x) is.na(x) | !nzchar(trimws(as.character(x)))
cascade_veg_event_key <- function(plot_id, event_id)
  paste(as.character(plot_id), as.character(event_id), sep = "\r")
cascade_veg_token <- function(x)
  gsub("[^a-z]", "", tolower(trimws(ifelse(is.na(x), "", as.character(x)))))
cascade_veg_token_absent <- function(token)
  token %in% c("n", "no", "absent") | grepl("notpresent|absent", token)
cascade_veg_show_keys <- function(key)
  paste(utils::head(sort(unique(sub("\r", " ", key, fixed = TRUE)), method = "radix"), 5L),
        collapse = ", ")

# Resolve the bundle's shape. Anything that is neither the legacy one-row-per-
# plot table nor a well-keyed v2 plot-event table stops with what was seen.
cascade_veg_bundle_shape <- function(bundle, site) {
  label <- sprintf("%s vegetation bundle", site)
  plots <- cascade_bundle_table(bundle, "plots", "vegetation", site)
  trees <- cascade_bundle_table(bundle, "trees", "vegetation", site)
  cascade_require_columns(plots, "plotID", sprintf("%s plot table", label))
  cascade_require_columns(trees, "plotID", sprintf("%s tree table", label))
  contract <- bundle[["contract"]]
  if (is.null(contract)) {
    if ("eventID" %in% names(plots))
      stop(sprintf("%s has no contract element but its plot table carries eventID; the shape is neither legacy nor v2",
                   label), call. = FALSE)
    dup <- duplicated(as.character(plots$plotID))
    if (any(dup))
      stop(sprintf("%s has no contract element and repeats plotID (%s); the shape is neither legacy nor v2",
                   label, cascade_veg_show_keys(plots$plotID[dup])), call. = FALSE)
    return("legacy")
  }
  if (!is.list(contract) || is.data.frame(contract))
    stop(sprintf("%s has a contract element that is not a list", label), call. = FALSE)
  id <- contract[["id"]]
  if (!is.character(id) || length(id) != 1L || is.na(id) ||
      !identical(id, CASCADE_VEG_V2_CONTRACT_ID))
    stop(sprintf("%s carries unknown vegetation contract id '%s' (this adapter reads '%s')",
                 label, paste(format(id), collapse = ","), CASCADE_VEG_V2_CONTRACT_ID),
         call. = FALSE)
  version <- contract[["version"]]
  if (!identical(version, CASCADE_VEG_V2_CONTRACT_VERSION))
    stop(sprintf("%s contract %s has version '%s' (this adapter reads version %d)",
                 label, id, paste(format(version), collapse = ","),
                 CASCADE_VEG_V2_CONTRACT_VERSION), call. = FALSE)
  cascade_require_columns(plots, c("plotID", "eventID"), sprintf("%s plot table", label))
  cascade_require_columns(trees, c("plotID", "eventID"), sprintf("%s tree table", label))
  blank_plot <- cascade_veg_blank(plots$plotID) | cascade_veg_blank(plots$eventID)
  if (any(blank_plot))
    stop(sprintf("%s plot table has %d row(s) with a blank plotID or eventID",
                 label, sum(blank_plot)), call. = FALSE)
  blank_tree <- cascade_veg_blank(trees$plotID) | cascade_veg_blank(trees$eventID)
  if (any(blank_tree))
    stop(sprintf("%s tree table has %d row(s) with a blank plotID or eventID",
                 label, sum(blank_tree)), call. = FALSE)
  plot_key <- cascade_veg_event_key(plots$plotID, plots$eventID)
  dup <- duplicated(plot_key)
  if (any(dup))
    stop(sprintf("%s plot table repeats (plotID, eventID): %s", label,
                 cascade_veg_show_keys(plot_key[dup])), call. = FALSE)
  tree_key <- cascade_veg_event_key(trees$plotID, trees$eventID)
  orphan <- !tree_key %in% plot_key
  if (any(orphan))
    stop(sprintf("%s has %d tree row(s) whose (plotID, eventID) is absent from the plot table: %s",
                 label, sum(orphan), cascade_veg_show_keys(tree_key[orphan])), call. = FALSE)
  "v2"
}

# One shape per bundle set: a mixed set would mix two estimands in one family.
# `shapes` is a named list (site -> shape, NULL when the site has no bundle).
cascade_veg_resolve_shape <- function(shapes) {
  shapes <- shapes[!vapply(shapes, is.null, logical(1))]
  if (!length(shapes)) return(NA_character_)
  flat <- unlist(shapes)
  kinds <- sort(unique(flat), method = "radix")
  if (length(kinds) != 1L)
    stop(sprintf("vegetation bundle set mixes shapes across sites: %s",
                 paste(vapply(kinds, function(k)
                   sprintf("%s=%s", k, paste(names(flat)[flat == k], collapse = ",")),
                   character(1)), collapse = "; ")), call. = FALSE)
  kinds
}

# Event date: the latest measurement date of the event's rows, falling back to
# the plot table's event date when the event has no rows.
cascade_veg_event_dates <- function(plots, trees, label) {
  tree_date <- tryCatch(as.Date(trees$date), error = function(e)
    rep(as.Date(NA), nrow(trees)))
  if (anyNA(tree_date))
    stop(sprintf("%s tree table has %d row(s) without a valid measurement date",
                 label, sum(is.na(tree_date))), call. = FALSE)
  plot_date <- tryCatch(as.Date(plots$date), error = function(e)
    rep(as.Date(NA), nrow(plots)))
  out <- rep(NA_real_, nrow(plots))
  if (nrow(trees)) {
    latest <- tapply(as.numeric(tree_date),
                     cascade_veg_event_key(trees$plotID, trees$eventID), max)
    out <- as.numeric(unname(latest[cascade_veg_event_key(plots$plotID, plots$eventID)]))
  }
  fallback <- is.na(out)
  out[fallback] <- as.numeric(plot_date[fallback])
  as.Date(out, origin = "1970-01-01")
}

# Rows of each plot event attributable to a channel: a row whose growth form is
# in the channel's forms, or a status-only row (growthForm NA) whose individual
# appears in that channel's forms anywhere at the same plot.
cascade_veg_channel_row_counts <- function(plots, trees, spec) {
  plot_key <- cascade_veg_event_key(plots$plotID, plots$eventID)
  if (!nrow(trees)) return(integer(length(plot_key)))
  plant <- paste(as.character(trees$plotID), as.character(trees$individualID), sep = "\r")
  in_forms <- trees$growthForm %in% spec$forms
  known <- unique(plant[in_forms])
  attributable <- in_forms | (is.na(trees$growthForm) & plant %in% known)
  counts <- table(cascade_veg_event_key(trees$plotID, trees$eventID)[attributable])
  out <- as.integer(counts[plot_key])
  out[is.na(out)] <- 0L
  out
}

# Per-channel disposition of every plot event (ruling R1): "admit", "absence"
# (selectable, zero stems, blocks fallback) or an "excl_" reason.
cascade_veg_event_disposition <- function(plots, trees, channel, site) {
  ch <- CASCADE_VEG_EVENT_CHANNELS[[channel]]
  if (is.null(ch)) stop(sprintf("unknown vegetation channel '%s'", channel), call. = FALSE)
  label <- sprintf("%s vegetation %s channel", site, channel)
  state <- as.character(plots[[ch$support]])
  unknown_state <- is.na(state) | !state %in% CASCADE_VEG_SUPPORT_STATES
  if (any(unknown_state))
    stop(sprintf("%s has support state(s) outside the contract: %s", label,
                 paste(sort(unique(ifelse(is.na(state[unknown_state]), "<NA>",
                                          state[unknown_state]))), collapse = ", ")),
         call. = FALSE)
  reason <- as.character(plots[[ch$reason]])
  records <- suppressWarnings(as.integer(plots[[ch$records]]))
  conflict <- suppressWarnings(as.integer(plots[[ch$conflict]]))
  if (anyNA(records) || anyNA(conflict))
    stop(sprintf("%s has plot events without %s or %s counts", label, ch$records,
                 ch$conflict), call. = FALSE)
  collected <- cascade_veg_token(plots$dataCollected)
  trees_absent <- cascade_veg_token_absent(cascade_veg_token(plots$treesPresent))
  presence_absent <- if (identical(channel, "tree")) trees_absent else
    cascade_veg_token_absent(cascade_veg_token(plots$shrubsPresent)) & trees_absent
  own_absent <- cascade_veg_token_absent(cascade_veg_token(plots[[ch$presence]]))
  channel_rows <- cascade_veg_channel_row_counts(plots, trees, ch$spec)
  area <- suppressWarnings(as.numeric(plots[[ch$area]]))

  out <- paste0("excl_", state)
  out[state %in% CASCADE_VEG_EVENT_ADMIT_STATES] <- "admit"
  out[state == CASCADE_VEG_EVENT_ABSENCE_STATE] <- "absence"
  held_unknown <- state == "held_opportunity_unknown"
  vintage <- held_unknown & reason %in% CASCADE_VEG_VINTAGE_REASONS
  partial <- held_unknown & !is.na(reason) &
    grepl(CASCADE_VEG_PARTIAL_REASON_PATTERN, reason)
  no_records <- held_unknown & reason %in% CASCADE_VEG_NO_RECORDS_REASON
  unrecognised <- held_unknown & !(vintage | partial | no_records)
  if (any(unrecognised))
    stop(sprintf("%s has held_opportunity_unknown with unrecognised reason(s): %s",
                 label, paste(sort(unique(ifelse(is.na(reason[unrecognised]), "<NA>",
                                                 reason[unrecognised]))), collapse = ", ")),
         call. = FALSE)
  vintage_outcome <- ifelse(!collected %in% c("", "allgrowthforms"), "excl_vintage_partial",
    ifelse(conflict > 0L, "excl_vintage_identity_conflict",
    ifelse(records > 0L & own_absent, "excl_vintage_presence_conflict",
    ifelse(channel_rows > 0L, "admit",
    ifelse(presence_absent, "absence", "excl_vintage_no_channel_rows")))))
  out[vintage] <- vintage_outcome[vintage]
  out[no_records] <- ifelse(channel_rows[no_records] > 0L, "admit",
                            "excl_no_records_unknown_presence")
  out[partial] <- "excl_partial_hold"
  selectable <- out %in% c("admit", "absence")
  out[selectable & !(is.finite(area) & area > CASCADE_VEG_EVENT_MIN_AREA_M2)] <-
    "excl_area_missing_or_le50"
  out
}

# Per-channel selection (rulings R2, R3): the latest admissible event per plot,
# its within-event stem snapshot, and a one-row-per-plotID design table built
# from the selected events' own areas.
cascade_veg_event_selection <- function(plots, trees, channel, site,
                                        event_date = NULL) {
  label <- sprintf("%s vegetation %s channel", site, channel)
  disposition <- cascade_veg_event_disposition(plots, trees, channel, site)
  if (is.null(event_date)) event_date <- cascade_veg_event_dates(plots, trees, label)
  candidate <- which(disposition %in% c("admit", "absence"))
  if (anyNA(event_date[candidate]))
    stop(sprintf("%s has %d admissible plot event(s) without any date", label,
                 sum(is.na(event_date[candidate]))), call. = FALSE)
  plot_id <- as.character(plots$plotID)
  event_id <- as.character(plots$eventID)
  ordered <- candidate[order(plot_id[candidate], as.numeric(event_date[candidate]),
                             event_id[candidate], method = "radix")]
  chosen <- ordered[!duplicated(plot_id[ordered], fromLast = TRUE)]
  chosen <- chosen[order(plot_id[chosen], method = "radix")]
  last_any <- tapply(as.numeric(event_date), plot_id, function(x)
    if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE))
  selected <- data.frame(
    plotID = plot_id[chosen], eventID = event_id[chosen],
    event_date = event_date[chosen], disposition = disposition[chosen],
    support = as.character(plots[[CASCADE_VEG_EVENT_CHANNELS[[channel]]$support]][chosen]),
    stringsAsFactors = FALSE)
  selected$later_held <- as.numeric(selected$event_date) <
    unname(last_any[selected$plotID])
  selected_key <- cascade_veg_event_key(selected$plotID, selected$eventID)
  rows <- trees[cascade_veg_event_key(trees$plotID, trees$eventID) %in% selected_key, ,
                drop = FALSE]
  design <- data.frame(
    plotID = selected$plotID,
    area_trees = suppressWarnings(as.numeric(plots$area_trees[chosen])),
    area_shrub = suppressWarnings(as.numeric(plots$area_shrub[chosen])),
    stringsAsFactors = FALSE)
  list(channel = channel, disposition = disposition, selected = selected,
       snapshot = cascade_tree_snapshot(rows), design = design)
}

cascade_veg_count_string <- function(x) {
  if (!length(x)) return("")
  counts <- table(x)
  keys <- sort(names(counts), method = "radix")
  paste(sprintf("%s=%d", keys, as.integer(counts[keys])), collapse = ";")
}

# Site-level event-aware result (rulings R1 to R4) for one v2 bundle: the stand,
# the classification evidence, and the audit counts ann_veg persists.
cascade_veg_event_site <- function(trees, plots, site) {
  label <- sprintf("%s vegetation bundle", site)
  cascade_require_columns(trees, CASCADE_VEG_V2_TREES_REQUIRED,
                          sprintf("%s tree table", label))
  cascade_require_columns(plots, CASCADE_VEG_V2_PLOTS_REQUIRED,
                          sprintf("%s plot table", label))
  plots <- as.data.frame(plots, stringsAsFactors = FALSE)
  trees <- as.data.frame(trees, stringsAsFactors = FALSE)
  plot_id <- as.character(plots$plotID)
  record_ids <- sort(unique(as.character(trees$plotID)), method = "radix")
  # Ruling R3: a record-bearing plot whose every event lacks its opportunity
  # source has no design support, so the whole site is unsupported (no subset).
  source_missing <- plots$tree_support %in% CASCADE_VEG_SOURCE_MISSING_STATE |
    plots$shrub_support %in% CASCADE_VEG_SOURCE_MISSING_STATE
  all_missing <- tapply(source_missing, plot_id, all)
  unmatched_ids <- record_ids[unname(all_missing[record_ids]) %in% TRUE]
  event_date <- cascade_veg_event_dates(plots, trees, label)
  impractical <- tolower(trimws(as.character(plots$samplingImpractical)))
  audit_for <- function(sel, contributing = character()) {
    s <- sel$selected
    at <- s$event_date[match(contributing, s$plotID)]
    years <- as.integer(format(at, "%Y"))
    stand_support <- as.character(plots[[CASCADE_VEG_EVENT_CHANNELS[[sel$channel]]$support]])
    nonlogistical_hold <- stand_support == "held_sampling_impractical" &
      impractical %in% CASCADE_VEG_NONLOGISTICAL_HOLD_CODES & !is.na(event_date)
    later_nonlogistical <- vapply(seq_along(contributing), function(i)
      any(plot_id == contributing[i] & nonlogistical_hold &
            as.numeric(event_date) > as.numeric(at[i])), logical(1))
    list(
      plot_events = length(sel$disposition),
      admitted_events = sum(sel$disposition == "admit"),
      absence_events = sum(sel$disposition == "absence"),
      excluded_events = cascade_veg_count_string(
        sel$disposition[!sel$disposition %in% c("admit", "absence")]),
      selected_plots = nrow(s),
      selected_absence_plots = sum(s$disposition == "absence"),
      selected_vintage_plots = sum(s$support == "held_opportunity_unknown"),
      later_held_plots = sum(s$later_held %in% TRUE),
      no_admissible_event_plots = length(setdiff(record_ids, s$plotID)),
      area_eligible_plots = sum(record_ids %in% s$plotID),
      event_year_min = if (length(years)) as.numeric(min(years)) else NA_real_,
      event_year_median = if (length(years)) as.numeric(stats::median(years)) else NA_real_,
      event_year_max = if (length(years)) as.numeric(max(years)) else NA_real_,
      later_nonlogistical_hold_plots = sum(later_nonlogistical))
  }
  base <- list(record_plots = length(record_ids),
               matched_record_plots = length(record_ids) - length(unmatched_ids),
               unmatched_record_plots = length(unmatched_ids),
               unmatched_record_rows = sum(as.character(trees$plotID) %in% unmatched_ids))
  if (length(unmatched_ids)) {
    # No type is resolved for an unsupported site; the event audit is reported
    # on the tree channel, the classification default when no evidence exists,
    # and nothing is selected because no estimate is formed.
    empty <- data.frame(plotID = character(), eventID = character(),
                        event_date = as.Date(character()), disposition = character(),
                        support = character(), later_held = logical(),
                        stringsAsFactors = FALSE)
    audit <- audit_for(list(
      channel = "tree", selected = empty,
      disposition = cascade_veg_event_disposition(plots, trees, "tree", site)))
    return(c(list(supported = FALSE, type = NA_character_, channel = NA_character_,
                  stand = NULL, structure = NULL), base, list(audit = audit)))
  }
  selection <- list(
    tree = cascade_veg_event_selection(plots, trees, "tree", site, event_date),
    shrub = cascade_veg_event_selection(plots, trees, "shrub", site, event_date))
  # Ruling R4: each component comes from its own channel's selection through
  # the unchanged classifier; the legacy comparison then decides the type.
  tree_evidence <- cascade_structure_evidence(selection$tree$snapshot,
                                              selection$tree$design)
  shrub_evidence <- cascade_structure_evidence(selection$shrub$snapshot,
                                               selection$shrub$design)
  tree_ba <- as.numeric(tree_evidence$tree_ba_ha)
  shrub_ba <- as.numeric(shrub_evidence$shrub_ba_ha)
  type <- if (tree_ba == 0 && shrub_ba == 0) "forest" else
    if (tree_ba >= shrub_ba) "forest" else "shrubland"
  channel <- if (identical(type, "forest")) "tree" else "shrub"
  spec <- cascade_size_spec(type)
  chosen <- selection[[channel]]
  per_plot <- cascade_stand_by_plot(chosen$snapshot, chosen$design, spec)
  stand <- cascade_stand_site(chosen$snapshot, chosen$design, spec)
  contributing <- if (is.null(per_plot)) character() else as.character(per_plot$plotID)
  c(list(supported = TRUE, type = type, channel = channel, stand = stand,
         structure = list(tree_ba_ha = tree_ba, shrub_ba_ha = shrub_ba,
                          tree_n_plots = as.integer(tree_evidence$tree_n_plots),
                          shrub_n_plots = as.integer(shrub_evidence$shrub_n_plots))),
    base, list(audit = audit_for(chosen, contributing)))
}
