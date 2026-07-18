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
CASCADE_MOSQ_EFFORT_REQUIRED <- c("year", "trap_nights")
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
