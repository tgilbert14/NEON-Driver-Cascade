# Exact deploy surface. Keep this allowlist small: the hosted app reads committed
# artifacts and must never receive refresh scripts, reviews, or incidental data.
DEPLOY_APP_FILES <- c(
  "global.R",
  "ui.R",
  "server.R",
  "R/cascade_helpers.R",
  "R/site_metadata.R",
  "www/cascade.css",
  "www/cascade.js",
  "www/styles.css",
  "data/cascade.rds",
  "data/search_index.rds",
  "data/cascade_meta.rds",
  "data/neon-cascade-codebook.csv")

if (anyDuplicated(DEPLOY_APP_FILES))
  stop("DEPLOY_APP_FILES contains duplicates", call. = FALSE)
