# Deploying the NEON Cross-Product Response Atlas

This app follows the NEON-suite standard: **Posit Connect Cloud, git-backed deploy**
(a push to `master` auto-republishes). See `docs/neonize-playbook.md` §6.

It is a **derived** app — its deployable artifact family is assembled from **seven** sibling
apps' committed `.rds` bundles (no direct NEON pull). The only supported rebuild entry point is
`scripts/rebuild_all.R`. A repo-local single-writer lock rejects concurrent rebuilds. It snapshots the build/deploy code into an isolated generation, builds the
response, search, and companion-meta artifacts, runs raw-source and artifact contracts, writes and
verifies the manifest, proves malformed and mixed generations are rejected, boot-loads the staged app,
reverifies the manifest, then performs a checksum-verified, rollback-protected
promotion. Direct artifact writers refuse to run outside that generation context.

## One-time activation (manual)
1. **Connect Cloud app** — create a Connect Cloud app pointed at this repo's `master`
   branch. From then on, every push to `master` redeploys. The committed `manifest.json`
   (appmode `shiny`, bundle-only) describes the runtime.
2. **(Optional) make the repo public** — needed only if you want the GitHub Pages
   showcase (`docs/index.html`) like the siblings. The app + CI work while private.

## Automatic refresh (already wired — idle until step 1)
`.github/workflows/refresh-data.yml` runs the **second Saturday night** of each month
(Arizona, off-peak — one week after the siblings refresh on the first Saturday). It clones the
seven allowlisted origins at detached commits and executes the complete rebuild in a job with no
write token. Exactly four data files plus a SHA-256 receipt pass to a fresh read-only validation job.
Only after that succeeds does a write-enabled publisher verify the receipt without deserializing RDS
payloads, install those four files, refresh checksums in the already-reviewed manifest package graph,
and push the four data files plus `manifest.json` to `master` (= the deploy). Run it any time from the
**Actions** tab (`workflow_dispatch`).

Workflow Actions are pinned to full commit SHAs. Ubuntu 24.04, R 4.5.2, and the
dated 2026-07-15 Posit Package Manager snapshot are the canonical release-byte
environment; the Linux CI gate still requires exact artifact bytes. Windows is a
strict portability/oracle environment for schemas, classes, attributes, keys,
text, support, scientific decisions, and explicitly named bounded last-bit
diagnostics, not a second artifact-byte authority. No release value is rounded.

A manifest may represent a standard CRAN install as `CRAN` or `RSPM` only after
the complete record independently passes trusted-repository, exact
package/version/ref/SHA, pinned-snapshot, optional-platform, dependency-graph,
deploy-surface, and checksum policies. Semantic normalization never substitutes
for those validations.

## Rebuild locally
```powershell
# From the repo root. CASCADE_ROOT is mandatory and must contain the directories below.
$env:CASCADE_ROOT = 'D:/path/to/sibling-workspace'
Rscript scripts/rebuild_all.R
```

Sibling repo slug → required directory name:

| Repository | Directory under `CASCADE_ROOT` |
|---|---|
| `NEON-Small-Mammal-Tracker-App` | `App-NEON-Small-Mammal-Tracker` |
| `NEON-Plant-Diversity` | `NEON-Plant-Diversity` |
| `NEON-Breeding-Birds` | `NEON-Breeding-Birds` |
| `NEON-Plant-Phenology-Explorer` | `NEON-Plant-Phenology` |
| `NEON-Vegetation-Structure-Explorer` | `NEON-Veg-Structure` |
| `NEON-Mosquito-Pulse` | `NEON-Mosquito-Pulse` |
| `NEON-Ground-Beetle-Tracker` | `NEON-Ground-Beetle-Tracker` |

Do not run the build/search/meta scripts separately for a deploy: a failed partial run can leave
artifacts from different source snapshots, and the writers now reject that invocation. The rebuild
requires seven repositories at their canonical origins with clean archived data scopes, records their commits and every tracked
input hash, and builds only from immutable `git archive` snapshots of those recorded commits after
verifying the extracted bytes against the inventory. It verifies schemas and scientific invariants,
refuses promotion if its own code or ordinary live-source state changes while it runs, and verifies
`manifest.json` again against the live root after promotion. The default cutoff is deterministic—UTC
year of the newest source commit minus one; an override must be an exact four-digit historical year no later than that source-derived ceiling.

Ordinary R errors restore and checksum-check the prior five-file family before releasing the lock. A
process kill or power loss during the brief multi-file promotion cannot make five paths filesystem-atomic,
so `manifest.json` is promoted last. Before sourcing repository code or deserializing any RDS, app boot
requires the manifest's exact 12-file surface and verifies every checksum. Any interrupted or mixed
generation therefore refuses to start; rerun `scripts/rebuild_all.R` to recover it.

For the documented git-backed Connect path, the committed manifest is available in the runtime app
directory. The platform may also archive support files from the repository target directory. The 12-file
manifest map is the verified runtime contract, not a claim that scripts or documentation are physically
absent from the checkout; the app does not source or read those support files.
