# Local-dev convenience only: hop to the repo root if running from elsewhere (e.g.
# RStudio). Skipped in CI (the path won't exist on the Linux runner), where the
# job already runs from the repo root and the relative paths below just work.
.root <- "C:/Users/tsgil/OneDrive/Documents/VGS - R/NEON-Driver-Cascade"
if (dir.exists(.root)) setwd(.root)
suppressPackageStartupMessages({ library(dplyr) })
source("R/cascade_helpers.R")
d <- readRDS("data/cascade.rds"); ANN <- d$annual; PR <- d$priors; SG <- d$signals
ok <- function(l,x) cat(sprintf("%-40s %s\n", l, x))
for (s in c("SRER","HARV","SCBI")) {
  a <- ANN[ANN$site==s,]
  cat("\n=====", s, "=====\n")
  lp <- layers_present(a, SG); ok("layers present", paste(names(lp)[lp], collapse=", "))
  lk <- site_links(a, PR)
  print(as.data.frame(lk[, c("from","to","lag","n","r","lo","hi","p","sign_match","tier")]))
  sm <- signmatch_score(lk); ok("sign-match", sm$txt)
}
cat("\nALL CASCADE HELPERS OK\n")
