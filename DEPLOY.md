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
`.github/workflows/refresh-data.yml` runs the **second Saturday morning** of each month
(about 6 am Arizona, off-peak — one week after the siblings refresh on the first Saturday). It clones the
seven allowlisted origins at detached commits and executes the complete rebuild in a job with no
write token. Exactly four data files plus a SHA-256 receipt pass to a fresh read-only validation job.
Only after that succeeds does a write-enabled publisher verify the receipt without deserializing RDS
payloads, install those four files, and refresh checksums in the already-reviewed manifest package graph.
The publisher never pushes `master`. It commits the four data files plus `manifest.json` as a direct
child of the validated master commit and pushes the fixed review branch `automation/atlas-data-refresh`
(it will not overwrite human review edits already on that branch). A person opens or updates the PR
from that branch, approves its CI runs, and merges it; the merge to `master` is the deploy. Run it any
time from the **Actions** tab (`workflow_dispatch`); the `publish` input defaults to `false`, a dry run
that still runs every gate, so set it to `true` to propose a review branch.

Before staging, the rebuild job runs `scripts/check_coverage_regression.R` against the committed
`data/cascade.rds`. It refuses the candidate when a product loses more than 10% of its finite
site-years or sites, its last year moves back, or it disappears. It also refuses per vegetation site
when basal area moves more than 15%, plots fall below 80% of the committed count, the forest or
shrubland label flips, or a value goes missing. A refusal stops the run before anything is staged,
and the step summary prints each refusal with a paste-ready override row. To accept a reviewed change,
commit that row to `data/coverage-overrides.tsv` by PR with a reason, approver and date, then dispatch
the refresh with `publish` set to `true`. A row names the exact baseline and candidate values and the
candidate's sibling commit, so it approves one transition only and goes stale on any later change.

A scheduled refresh that fails anywhere opens one issue titled "Atlas refresh failed" (the
`notify-failure` job; later failures comment on it) carrying the failed job, step and first error; the
next scheduled run that rebuilds and passes every job closes it. The gate job's step summary also lists
the open `automation/*` review branches in the seven sibling repos ("waiting on N sibling review
branches: ..."), since a sibling's unmerged refresh is not yet in its `master`. A weekly dry run was
considered and decided against: it would change the calendar block every suite repo shares, and
failures already surface through this issue and the suite watch in TG-Data-Apps #142.

After every push to `master`, `.github/workflows/post-deploy.yml` waits for the GitHub Pages cover and
the live Connect Cloud app, drives the app in headless Chromium, and requires the About tab's
"Snapshot and provenance" fold to show the `built_when` of the pushed `data/cascade.rds`. That proves
the data; to prove the code revision it also fetches the `cascade.js`, `cascade.css` and `styles.css`
the app serves and requires each md5 to equal the pushed `www/` file, and it requires the app's and the
cover's `<title>` to contain "NEON Cross-Product Response Atlas" and the app to declare `lang="en"`. All
of these share one retry budget. A failure opens or updates the issue "Production health: Cross-Product Response Atlas smoke failed"; the next
healthy run closes it.

The generated-artifact seals in CI (Seal-2 parity, the Phenology static lock, and the Discharge F1
contract) check the frozen family at `SEAL_FAMILY_SHA` 543fee44 with `git cat-file`, not the working
tree, so a merged refresh does not require re-registering their digests.

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
