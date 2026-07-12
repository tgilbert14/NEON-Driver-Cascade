# ===========================================================================
# write_manifest.R — (re)generate manifest.json for Posit Connect Cloud (LEAN).
#
# RUN THIS after ANY change to runtime dependencies or the committed data set,
# then COMMIT manifest.json — Connect Cloud reads the committed manifest, so a
# stale manifest restores the OLD package set or serves yesterday's data.
#
#   Rscript scripts/write_manifest.R
#
# appFiles is scoped EXPLICITLY to global/ui/server + R/ + www/ + data/*.rds +
# data-sample, so internal scripts/docs/README never leak into the bundle. After
# writing, this script PARSES manifest.json and stop()s with a non-zero exit if
# neonUtilities / arrow / data.table appears as a package key — a leaked manifest
# (the heavy fetch/IO stack the app must never deploy) must not commit silently.
# neonUtilities is referenced only via a computed name + requireNamespace in the
# refresh path, so rsconnect's static scan does not pin it here.
# ===========================================================================
setwd_root <- function() {
  # run from the app root whether invoked from repo root or scripts/
  if (file.exists("global.R")) return(invisible())
  if (file.exists("../global.R")) { setwd(".."); return(invisible()) }
  stop("run from the NEON-Driver-Cascade app root (global.R not found)")
}
setwd_root()

if (!requireNamespace("rsconnect", quietly = TRUE)) stop("install.packages('rsconnect') first")

data_files <- list.files("data", pattern = "\\.(rds|csv)$", recursive = TRUE, full.names = TRUE)
sample_files <- if (dir.exists("data-sample")) list.files("data-sample", full.names = TRUE) else character(0)

rsconnect::writeManifest(
  appDir = ".",                        # global.R + ui.R + server.R -> a Shiny app
  appFiles = c(
    "global.R", "ui.R", "server.R",
    list.files("R",   full.names = TRUE),
    list.files("www", full.names = TRUE),
    data_files,
    sample_files
  )
)

m <- jsonlite::fromJSON("manifest.json")
pkgs <- names(m$packages)
cat(sprintf("manifest.json written: %d packages, %d files.\n", length(pkgs), length(m$files)))

# HARD GATE: neonUtilities + arrow are the heavy FETCH/IO stack the app must never
# deploy (the app runs off committed bundles, never a live pull) — their presence is
# always a leak, fail the build.
fatal <- c("neonUtilities", "arrow")
leaked <- fatal[tolower(fatal) %in% tolower(pkgs)]
if (length(leaked)) {
  stop(sprintf("HEAVY PACKAGE LEAKED INTO manifest.json: %s — the deploy must stay lean (bundle-only, no live fetch/IO stack). Fix the dependency scan in global.R before committing.",
               paste(leaked, collapse = ", ")))
}

# data.table is ALSO forbidden as a DIRECT dependency, but plotly legitimately Imports
# it at runtime — so we only fail if data.table is present WITHOUT plotly carrying it
# (i.e. it would be a genuine direct leak, not plotly's transitive runtime need).
if ("data.table" %in% tolower(pkgs) || "data.table" %in% pkgs) {
  pkg_imports_dt <- function(p) {
    d <- m$packages[[p]]$description
    grepl("data.table", paste(c(d$Depends, d$Imports), collapse = ","), fixed = TRUE)
  }
  carriers <- pkgs[vapply(pkgs, pkg_imports_dt, logical(1))]
  carriers <- setdiff(carriers, "data.table")
  if (!length(setdiff(carriers, character(0))) || !any(tolower(carriers) == "plotly")) {
    stop("data.table is in the manifest but NOT as a plotly transitive dependency — it looks like a direct leak. Remove the direct data.table use before committing.")
  }
  cat(sprintf("Note: data.table present as a transitive runtime dependency of %s (legitimate; plotly requires it).\n",
              paste(carriers, collapse = ", ")))
}
cat("OK: manifest is lean (no neonUtilities / arrow; data.table only via plotly).\n")

# HARD GATE (completeness): every package global.R LOADS at boot must be pinned in the
# manifest. writeManifest() only pins packages it finds INSTALLED, so if a runtime dep is
# missing from this environment it is silently DROPPED and the deploy dies at boot with
# "there is no package called '<x>'". A monthly rebuild did exactly this (dropped plotly/
# DT/bsicons/shinyjs/shinycssloaders, 73 -> 46 pkgs). Derive the required set straight from
# global.R's library() calls so it stays in lock-step with the code, and fail loudly here.
gl <- readLines("global.R", warn = FALSE)
loaded <- unique(regmatches(gl, regexpr("(?<=library\\()[A-Za-z0-9._]+", gl, perl = TRUE)))
missing_runtime <- setdiff(loaded, pkgs)
if (length(missing_runtime)) {
  stop(sprintf(paste0("RUNTIME PACKAGE(S) MISSING FROM manifest.json: %s. global.R loads them ",
                      "but writeManifest() did not pin them (not installed in this environment?). ",
                      "Add them to the refresh workflow's 'packages:' list, then re-run. ",
                      "Deploying this manifest would die at boot."),
               paste(missing_runtime, collapse = ", ")))
}
cat(sprintf("OK: all %d runtime packages loaded by global.R are pinned in the manifest.\n",
            length(loaded)))
