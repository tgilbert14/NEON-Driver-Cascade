# Local-dev convenience only: hop to the repo root if running from elsewhere (e.g.
# RStudio). Skipped in CI (the path won't exist on the Linux runner), where the
# job already runs from the repo root and the relative paths below just work.
.root <- "C:/Users/tsgil/OneDrive/Documents/VGS - R/NEON-Driver-Cascade"
if (dir.exists(.root)) setwd(.root)
suppressPackageStartupMessages({ library(dplyr) })
source("R/cascade_helpers.R")
d <- readRDS("data/cascade.rds"); ANN <- d$annual; PR <- d$priors; SG <- d$signals
ok <- function(l,x) cat(sprintf("%-40s %s\n", l, x))

# Rung presence: every live cascade rung MUST survive the rebuild. The Mosquito
# Pulse rung (NEON-Mosquito-Pulse, DP1.10043.001) is the water-limited consumer
# rung (precip_monsoon -> mosq_activity); fail loudly if a future rebuild drops it
# (e.g. the workflow stops cloning the mosquito sibling) rather than ship a bundle
# silently missing a rung. Mirror the sibling list build_cascade.R assembles.
rungs <- c(mammal = "mammal_cpue", plant = "plant_richness", veg = "plant_richness",
           bird = "bird_index", phenology = "greenup_doy", mosquito = "mosq_activity")
for (r in names(rungs)) {
  col <- rungs[[r]]
  has <- col %in% names(ANN) && any(!is.na(ANN[[col]]))
  ok(sprintf("rung present: %-9s (%s)", r, col), if (has) "OK" else "MISSING")
  if (!has) stop(sprintf("cascade rebuild dropped the %s rung (no non-NA %s) — check the sibling clone/source list", r, col))
}
for (s in c("SRER","HARV","SCBI")) {
  a <- ANN[ANN$site==s,]
  cat("\n=====", s, "=====\n")
  lp <- layers_present(a, SG); ok("layers present", paste(names(lp)[lp], collapse=", "))
  lk <- site_links(a, PR)
  print(as.data.frame(lk[, c("from","to","lag","n","r","lo","hi","p","sign_match","tier")]))
  sm <- signmatch_score(lk); ok("sign-match", sm$txt)
}
cat("\nALL CASCADE HELPERS OK\n")
