# Deploying the NEON Driver Cascade

This app follows the NEON-suite standard: **Posit Connect Cloud, git-backed deploy**
(a push to `master` auto-republishes). See `docs/neonize-playbook.md` §6.

It is a **derived** app — `data/cascade.rds` is assembled from the five sibling apps'
committed `.rds` bundles by `scripts/build_cascade.R` (no direct NEON pull).

## One-time activation (manual)
1. **Connect Cloud app** — create a Connect Cloud app pointed at this repo's `master`
   branch. From then on, every push to `master` redeploys. The committed `manifest.json`
   (appmode `shiny`, bundle-only) describes the runtime.
2. **(Optional) make the repo public** — needed only if you want the GitHub Pages
   showcase (`docs/index.html`) like the siblings. The app + CI work while private.

## Automatic refresh (already wired — idle until step 1)
`.github/workflows/refresh-data.yml` runs the **second Saturday night** of each month
(Arizona, off-peak — one week after the siblings refresh on the first Saturday). It
clones the sibling repos, rebuilds `data/cascade.rds`, and pushes it to `master`
(= the deploy). Run it any time from the **Actions** tab (`workflow_dispatch`).

## Rebuild locally
```r
# from the repo root, with the sibling repos checked out alongside in VGS-R/
Rscript scripts/build_cascade.R          # uses CASCADE_ROOT or the default VGS-R path
Rscript -e 'rsconnect::writeManifest()'  # regenerate manifest.json after dep changes
```

Sibling repo slugs (for the CI clone / local layout): `NEON-Small-Mammal-Tracker-App`,
`NEON-Plant-Diversity`, `NEON-Breeding-Birds`, `NEON-Plant-Phenology-Explorer`,
`NEON-Vegetation-Structure-Explorer`.
