#!/usr/bin/env Rscript

ledger_path <- "docs/driver-v2-compatibility.csv"
if (!file.exists(ledger_path))
  stop(sprintf("missing Driver v2 compatibility ledger: %s", ledger_path),
       call. = FALSE)

expected_columns <- c(
  "product", "system", "data_authority", "knowledge_authority",
  "audited_default_head", "current_driver_pin", "pin_state", "support_basis",
  "app_supported_sites", "app_supported_site_years",
  "app_supported_sites_n_ge_6_years", "direct_driver_calendar_sites",
  "direct_driver_calendar_site_years", "direct_driver_calendar_rate",
  "domain_proxy_site_years", "contract_disposition", "ecological_disposition",
  "vote_eligible", "next_action")

ledger <- read.csv(
  ledger_path, stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = "character", na.strings = "UNMEASURED")
stopifnot(identical(names(ledger), expected_columns))

expected_products <- c(
  "mammal", "phenology", "plant_diversity", "vegetation", "ground_beetle",
  "mosquito", "birds", "water_chemistry", "inverts")
stopifnot(nrow(ledger) == length(expected_products),
          !anyDuplicated(ledger$product),
          setequal(ledger$product, expected_products))

is_sha <- function(x) !is.na(x) & grepl("^[0-9a-f]{40}$", x)
stopifnot(all(is_sha(ledger$data_authority)),
          all(is_sha(ledger$knowledge_authority)),
          all(is_sha(ledger$audited_default_head)))
ingested <- !ledger$current_driver_pin %in% "NOT_INGESTED"
stopifnot(all(is_sha(ledger$current_driver_pin[ingested])),
          all(ledger$current_driver_pin[!ingested] == "NOT_INGESTED"))

expected_pin_states <- c(byte_current = 1L, byte_stale = 6L, not_ingested = 2L)
observed_pin_states <- table(factor(ledger$pin_state,
                                   levels = names(expected_pin_states)))
stopifnot(identical(as.integer(observed_pin_states),
                    unname(expected_pin_states)),
          all(ledger$vote_eligible == "FALSE"))

driver <- readRDS("data/cascade.rds")
stopifnot(is.list(driver), is.data.frame(driver$annual),
          is.data.frame(driver$site_meta), is.data.frame(driver$suite_links),
          is.data.frame(driver$priors), is.data.frame(driver$pooled),
          nrow(driver$annual) == 510L, nrow(driver$site_meta) == 46L,
          nrow(driver$suite_links) == 552L, nrow(driver$priors) == 12L)

driver_name <- c(
  mammal = "mammal", phenology = "phe", plant_diversity = "plant",
  vegetation = "veg", ground_beetle = "beetle", mosquito = "mosq",
  birds = "bird")
source_products <- driver$meta$source_products
stopifnot(is.data.frame(source_products),
          all(c("product", "commit") %in% names(source_products)))
for (product in names(driver_name)) {
  row <- ledger[ledger$product == product, , drop = FALSE]
  pin <- source_products$commit[source_products$product == driver_name[[product]]]
  stopifnot(nrow(row) == 1L, length(pin) == 1L,
            identical(row$current_driver_pin[[1L]], pin[[1L]]))
}
stopifnot(all(ledger$current_driver_pin[
  ledger$product %in% c("water_chemistry", "inverts")] == "NOT_INGESTED"))

numeric_value <- function(product, column) {
  value <- ledger[ledger$product == product, column, drop = TRUE]
  if (length(value) != 1L || is.na(value)) return(NA_real_)
  suppressWarnings(as.numeric(value))
}
expect_number <- function(product, column, expected, tolerance = 0) {
  actual <- numeric_value(product, column)
  stopifnot(is.finite(actual), abs(actual - expected) <= tolerance)
}

expect_number("mammal", "app_supported_site_years", 410)
expect_number("mammal", "direct_driver_calendar_site_years", 410)
stopifnot(ledger$pin_state[ledger$product == "mammal"] == "byte_current")

expect_number("phenology", "app_supported_site_years", 346)
expect_number("phenology", "direct_driver_calendar_site_years", 346)
expect_number("phenology", "app_supported_sites_n_ge_6_years", 39)

plant <- ledger[ledger$product == "plant_diversity", , drop = FALSE]
plant_measure_columns <- c(
  "app_supported_sites", "app_supported_site_years",
  "app_supported_sites_n_ge_6_years", "direct_driver_calendar_sites",
  "direct_driver_calendar_site_years", "direct_driver_calendar_rate",
  "domain_proxy_site_years")
stopifnot(all(is.na(plant[1L, plant_measure_columns])))

expect_number("vegetation", "app_supported_site_years", 156)
expect_number("vegetation", "direct_driver_calendar_site_years", 151)
expect_number("vegetation", "app_supported_sites_n_ge_6_years", 0)
expect_number("ground_beetle", "direct_driver_calendar_site_years", 388)
expect_number("mosquito", "direct_driver_calendar_site_years", 200)
expect_number("birds", "direct_driver_calendar_site_years", 381)

expect_number("water_chemistry", "direct_driver_calendar_site_years", 0)
expect_number("water_chemistry", "domain_proxy_site_years", 351)
expect_number("inverts", "direct_driver_calendar_site_years", 0)
expect_number("inverts", "domain_proxy_site_years", 307)

expected_priors <- driver$priors[driver$priors$expected_class != "none",
                                c("from", "to"), drop = FALSE]
stopifnot(nrow(expected_priors) == 2L,
          identical(expected_priors$from, c("temp", "temp_spring")),
          all(expected_priors$to == "greenup_doy"))
pooled <- driver$pooled[driver$pooled$from %in% c("temp", "temp_spring") &
                          driver$pooled$to == "greenup_doy", , drop = FALSE]
pooled <- pooled[match(c("temp", "temp_spring"), pooled$from), , drop = FALSE]
stopifnot(nrow(pooled) == 2L,
          identical(pooled$sites, c(18L, 18L)),
          identical(pooled$k, c(15L, 8L)),
          isTRUE(all.equal(pooled$p,
                           c(0.003768921, 0.759658813), tolerance = 1e-9)),
          isTRUE(all.equal(pooled$p_holm,
                           c(0.007537842, 0.759658813), tolerance = 1e-9)),
          isTRUE(all.equal(pooled$p_fdr,
                           c(0.007537842, 0.759658813), tolerance = 1e-9)),
          isTRUE(all.equal(pooled$median_r,
                           c(-0.35203872, 0.02657096), tolerance = 1e-8)))

cat("OK: Driver v2 synthesis ledger, legacy pins, measured support, and no-vote gate passed.\n")
