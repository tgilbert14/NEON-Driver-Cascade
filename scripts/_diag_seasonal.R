# Diagnostic 2: can we recover the cascade with SEASONAL climate instead of annual?
# Reconstruct winter/monsoon precip + spring temp from the monthly env overlays,
# then re-test the key desert links at SRER and a few comparators.
setwd("C:/Users/tsgil/OneDrive/Documents/VGS - R/NEON-Driver-Cascade")
suppressPackageStartupMessages({ library(dplyr) })
source("R/cascade_helpers.R")
ROOT <- "C:/Users/tsgil/OneDrive/Documents/VGS - R"
ENVDIR <- file.path(ROOT, "App-NEON-Small-Mammal-Tracker", "data/env")

cat("=== env dir exists:", dir.exists(ENVDIR), "===\n")
ef <- list.files(ENVDIR, "\\.rds$"); cat("env sites:", length(ef), "\n")

# inspect one env file structure
e <- readRDS(file.path(ENVDIR, "SRER.rds"))
cat("\n=== SRER env structure ===\n"); cat("cols:", paste(names(e), collapse=", "), "\n")
print(utils::head(as.data.frame(e), 4))

yr_of <- function(x) suppressWarnings(as.integer(format(as.Date(x), "%Y")))
mo_of <- function(x) suppressWarnings(as.integer(format(as.Date(x), "%m")))

seasonal_env <- function(site) {
  f <- file.path(ENVDIR, paste0(site, ".rds")); if (!file.exists(f)) return(NULL)
  e <- readRDS(f)
  if (!"date" %in% names(e)) e$date <- if ("ym" %in% names(e)) paste0(e$ym,"-01") else NA
  e$year <- yr_of(e$date); e$mo <- mo_of(e$date)
  e <- e[is.finite(e$year) & is.finite(e$mo),,drop=FALSE]
  e$temp_c[!(is.finite(e$temp_c) & e$temp_c > -40 & e$temp_c < 50)] <- NA
  e$precip_mm[!(is.finite(e$precip_mm) & e$precip_mm >= 0 & e$precip_mm < 2000)] <- NA
  # winter = Oct(prev)-Mar : assign Oct-Dec to the FOLLOWING growing year
  e$wateryr <- ifelse(e$mo >= 10, e$year + 1, e$year)
  win <- e %>% filter(mo %in% c(10,11,12,1,2,3)) %>% group_by(year=wateryr) %>%
    summarise(precip_winter = if (sum(!is.na(precip_mm))>=4) sum(precip_mm,na.rm=TRUE) else NA_real_, .groups="drop")
  mon <- e %>% filter(mo %in% c(7,8,9)) %>% group_by(year) %>%
    summarise(precip_monsoon = if (sum(!is.na(precip_mm))>=2) sum(precip_mm,na.rm=TRUE) else NA_real_, .groups="drop")
  spr <- e %>% filter(mo %in% c(3,4,5)) %>% group_by(year) %>%
    summarise(temp_spring = if (sum(!is.na(temp_c))>=2) round(mean(temp_c,na.rm=TRUE),2) else NA_real_, .groups="drop")
  Reduce(function(a,b) full_join(a,b,by="year"), list(win,mon,spr)) %>% mutate(site=site)
}

CASCADE <- readRDS("data/cascade.rds"); ANNUAL <- CASCADE$annual
site_annual <- function(s) ANNUAL[ANNUAL$site==s,,drop=FALSE]
corr <- function(a,b){ ok<-is.finite(a)&is.finite(b); if(sum(ok)<4) return(c(n=sum(ok),r=NA)); c(n=sum(ok), r=round(cor(a[ok],b[ok]),2)) }

for (s in c("SRER","JORN","ONAQ","MOAB","SCBI","HARV")) {
  se <- seasonal_env(s); a <- site_annual(s)
  if (is.null(se)) { cat("\n[", s, "] no env\n"); next }
  m <- merge(a, se, by="year", all.x=TRUE)
  cat("\n================= ", s, " seasonal climate =================\n")
  print(as.data.frame(m[,c("year","precip","precip_winter","precip_monsoon","temp","temp_spring","greenup_doy","plant_richness","mammal_cpue")]), row.names=FALSE)
  # rodent response: winter precip(t) -> mammal(t)  and  winter precip(t-1)->mammal(t)
  m <- m[order(m$year),]
  cat("ANNUAL precip -> richness (same yr):    "); print(corr(m$precip, m$plant_richness))
  cat("WINTER precip -> richness (same yr):    "); print(corr(m$precip_winter, m$plant_richness))
  cat("ANNUAL precip(t-1) -> mammal_cpue(t):   "); print(corr(dplyr::lag(m$precip), m$mammal_cpue))
  cat("WINTER precip(t-1) -> mammal_cpue(t):   "); print(corr(dplyr::lag(m$precip_winter), m$mammal_cpue))
  cat("WINTER precip(t)   -> mammal_cpue(t):   "); print(corr(m$precip_winter, m$mammal_cpue))
  cat("ANNUAL temp -> greenup_doy:             "); print(corr(m$temp, m$greenup_doy))
  cat("SPRING temp -> greenup_doy:             "); print(corr(m$temp_spring, m$greenup_doy))
}

# ---- cross-site method-match: temp->greenup and precip->richness sign at every site ----
cat("\n\n=== CROSS-SITE: temp->greenup (prior -) & precip->richness (prior +) ===\n")
sites <- sort(unique(ANNUAL$site))
res <- do.call(rbind, lapply(sites, function(s){
  a <- site_annual(s)
  tg <- corr(a$temp, a$greenup_doy); pr <- corr(a$precip, a$plant_richness)
  data.frame(site=s, tg_n=tg["n"], tg_r=tg["r"], pr_n=pr["n"], pr_r=pr["r"])
}))
res$tg_match <- ifelse(is.na(res$tg_r), NA, res$tg_r < 0)   # prior negative
res$pr_match <- ifelse(is.na(res$pr_r), NA, res$pr_r > 0)   # prior positive
cat("temp->greenup: of sites with n>=4, fraction r<0 (matches prior):",
    round(mean(res$tg_match[res$tg_n>=4], na.rm=TRUE),2), "(n sites=", sum(res$tg_n>=4,na.rm=TRUE), ")\n")
cat("median r:", round(median(res$tg_r[res$tg_n>=4], na.rm=TRUE),2), "\n")
cat("precip->richness: of sites with n>=4, fraction r>0 (matches prior):",
    round(mean(res$pr_match[res$pr_n>=4], na.rm=TRUE),2), "(n sites=", sum(res$pr_n>=4,na.rm=TRUE), ")\n")
cat("median r:", round(median(res$pr_r[res$pr_n>=4], na.rm=TRUE),2), "\n")
print(res[res$tg_n>=4 | res$pr_n>=4,], row.names=FALSE)
