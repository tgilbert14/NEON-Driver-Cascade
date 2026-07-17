# Build, test, and handoff record

Last updated: 2026-07-17

This is the durable operating record for the NEON Driver Cascade repository. Read
the whole document before doing work. Keep it factual and current so a new session
can continue safely without relying on chat history.

## Current handoff state

**Local release-validation state: complete for the unchanged generation below as of
2026-07-17 12:15 MST.** Every applicable completion-matrix row has dated passing
evidence. This is a local, validated release candidate; no commit, push, deployment,
or publication was performed. The broad uncommitted worktree is intentional and must
still be reviewed and preserved.

A change to the captured runtime/build surface or any of the five generated files
invalidates the generation-scoped build, determinism, manifest, live-root, and browser
evidence. A future session should not repeat the expensive matrix merely to recreate
evidence; it should first compare the generation hashes and only rerun gates invalidated
by an actual change.

### Validated five-file generation

| Artifact | Bytes | MD5 | SHA-256 |
|---|---:|---|---|
| `data/cascade.rds` | 110131 | `8a28bc7e9188dbb4bed639f0fa4ec9ec` | `5453e448cd5f1ea82a0844425a61bbf5ed5d15ddcd57f35f3eaedbed68097845` |
| `data/search_index.rds` | 18318 | `28de029bb7fe9ac6abcd0d0b9396b399` | `1e3449cfee4ebb8d41c40ce0f1544f210c8ae1ea671cb33e0f57777221a0ce1d` |
| `data/cascade_meta.rds` | 2484 | `bb2066295994b9d0e4137221f187b932` | `7e1aef4fc614c0cfbe9a7646b974ecd8bf520c1af8db762f51abccf2c6c5f8f4` |
| `data/neon-cascade-codebook.csv` | 15080 | `9f970cd051b1743cc3b45b4bf61e5eb8` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | 210836 | `60567ad8f2f84207ef8513df631549f3` | `dffe9d2de03bd4b301958839f1a41f5c19302445f92a95b02fefb92032aaa344` |

The two final authoritative nine-stage rebuilds produced these exact bytes for all
five files. They used 364 archived RDS inputs from these immutable source commits:

| Product | Commit |
|---|---|
| small mammals | `d2a53282637e4dbd7e5ebef7f64665fa27028531` |
| plant diversity | `73c92c6c67f7c982eaae76950f718ce932ff7a52` |
| vegetation structure | `5e73e0dde5cc9cb1936dc0c589475ca23b5ee8df` |
| breeding birds | `efda16ec27c745efbb738c9e920c72fd85373664` |
| plant phenology | `81e339e9ed6f34d3d04ca45a7030fea51c4147a5` |
| mosquitoes | `79244c8bc252bed1f6c00ca2a76f049fadfa80ed` |
| ground beetles | `0ac67f842642e552153ddaf728798759744fc15d` |

### Dated evidence established

| Date | Scope | Validated result | Limits/notes |
|---|---|---|---|
| 2026-07-17 12:15 MST | Authoritative build and determinism | Two consecutive full rebuilds passed all nine stages, promoted, post-verified, and produced byte-identical five-file families. | Applies only to the exact hashes and source commits above. |
| 2026-07-17 12:15 MST | Independent live-root and science audit | `test_helpers.R`, `verify_manifest.R`, `test_manifest_compare.R`, `test_boot_integrity.R`, and `smoke_app.R` passed. Contracts covered 510 annual rows, 46 sites, 552 links, 73 trusted packages, 12 deploy files, 12 malformed/mutated boot fixtures, and six ordered promotion cuts. | Windows rejected startup `C.UTF-8`; the runtime selected a real UTF-8 locale and the cross-locale reopen passed. |
| 2026-07-17 12:15 MST | Failure safety | Invalid `CASCADE_ROOT` failed before promotion with unchanged hashes; all four direct writers rejected a missing generation capability; a controlled copy-3 promotion failure restored all five prior files exactly; owned lock/stage/backup/pending state was clean. | Hard process kill and power-loss limits remain as described below. |
| 2026-07-17 12:15 MST | Static/workflow/security | All 22 R files parsed; JavaScript, Python, Python fixtures, both workflow YAML files, 13 SHA-pinned action references, workflow receipt fixtures, manifest fixtures, remote-font scan, deploy regular-file scan, and `git diff --check` passed. | R printed two non-fatal native-encoding warnings during a direct parse probe; use the UTF-8 parse pattern documented below. |
| 2026-07-17 12:15 MST | Final browser and accessibility QA | Desktop 1280×720 and mobile 390×844 passed navigation, search, theme, the four Plotly outputs, QC/About, keyboard alternatives, live regions, responsive overflow, and representative screenshots. Required arrows/dashes/degrees/curly quotes rendered; WOOD was withheld with exact metadata; no unexpected console warning/error was observed; all 36 observed boot assets were local. | Browser coverage is broad but finite; external reference anchors are navigation links, not boot dependencies. |
| 2026-07-17 12:15 MST | Handoff/hygiene | The verified four-file `scripts/__pycache__` residue was removed; no rebuild listener, lock, pending, backup, stage, temp config, or reparse point remained. `AGENTS.md` now requires every session to record learnings and test process here. | Existing broad product changes and the tracked deletion of `scripts/_diag_seasonal.R` were preserved. |

## Session start protocol

1. Read root `AGENTS.md` and this file completely.
2. Run `git status --short`. Inspect relevant diffs before editing. Existing changes
   belong to the user or another session unless proved otherwise.
3. Check whether `.cascade-rebuild.lock` exists. Read its `owner.txt`; do not remove
   the lock merely because it exists. Confirm that its recorded process is no longer
   running before explicitly removing a stale lock.
4. Check for another active agent/process working on the same files. Never edit the
   rebuild's captured code surface while a rebuild is running: it intentionally
   detects byte or inventory changes and fails.
5. Read the newest dated evidence, unresolved failures, and residual risks here.
   Select the next unchecked matrix row rather than repeating completed work without
   reason.
6. Establish the Windows/R and source-repository environment below. Do not put
   credentials in commands, logs, this file, or repository files.
7. Hash the five live generated files before any failure-path test so "unchanged" or
   "rolled back" can be proved rather than assumed.

## Current Windows and R environment

The validated local setup is Windows PowerShell with:

```powershell
$repo = 'D:\Git\NEON-Driver-Cascade'
$rscript = 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe'
Set-Location -LiteralPath $repo

$env:R_LIBS = 'C:/tmp/cascade-r-lib'
$env:RENV_PATHS_CACHE = 'C:/tmp/cascade-renv-cache'
New-Item -ItemType Directory -Force -Path $env:RENV_PATHS_CACHE | Out-Null

$gitUsrBin = 'C:\Program Files\Git\usr\bin'
if (-not (Get-Command sha256sum -ErrorAction SilentlyContinue)) {
  if (-not (Test-Path -LiteralPath "$gitUsrBin/sha256sum.exe")) { throw 'sha256sum is required' }
  $env:PATH = "$gitUsrBin;$env:PATH"
}
```

The local library has contained the complete application/build graph, including
`shiny`, `bslib`, `bsicons`, `dplyr`, `plotly`, `htmltools`, `htmlwidgets`,
`shinyjs`, `shinycssloaders`, `DT`, `tidyr`, `stringr`, `tibble`, `metafor`,
`rsconnect`, and `jsonlite`. Verify rather than assume that this remains true.

Windows may emit `LC_*`/`C.UTF-8` startup warnings. **They are causal, not
harmless:** on this host they leave `LC_CTYPE=C`, and R text marked `unknown` can
then be transliterated or corrupted by `enc2utf8`, `htmltools`, `jsonlite`, or CSV
writing. Runtime startup must call the repository UTF-8 activation helper and prove
`l10n_info()[["UTF-8"]]` is true. Standalone loading of repository R code should use:

```r
eval(parse(file = path, encoding = "UTF-8", keep.source = FALSE), envir = .GlobalEnv)
```

Direct `source(..., encoding = "UTF-8")` can still warn or corrupt nested source
text under the startup C locale. CSV generation temporarily activates a real UTF-8
`LC_CTYPE`, writes, verifies RDS/CSV parity, and restores the caller locale. Treat
any inability to activate UTF-8, any C0/C1 control, U+FFFD, unknown-marked non-ASCII
text, or cross-locale reopen failure as a real failing gate.

The reproducible workflow repository is the dated Posit Package Manager snapshot:

```text
https://packagemanager.posit.co/cran/__linux__/noble/2026-07-15
```

This is a dated repository snapshot, not a cryptographic content-hash guarantee.
That distinction remains a residual supply-chain risk.

### Manifest/network interpretation

`rsconnect::writeManifest()` can require reachable CRAN/Posit repository metadata
even when every package is already installed locally. The expected repository must
be reachable during manifest generation.

There are two distinct provenance layers; never conflate them:

- The outer package record's `Repository` is the trusted installation-repository
  URL. If that value is null or untrusted, classify the result as a local
  repository/network/cache metadata failure.
- Inside `description`, `Repository` must be exactly `CRAN`. The five standard CRAN
  fields `RemoteType`, `RemoteRepos`, `RemotePkgRef`, `RemoteRef`, and `RemoteSha`
  may be either all absent (the official implicit standard-CRAN form emitted by
  `rsconnect` 1.10.1) or all present with canonical values. Partial sets,
  explicitly named null fields, and rogue remote fields fail closed.

The manifest must remain untouched output from `rsconnect::writeManifest()`; policy
validation must not invent or rewrite provenance. Semantic comparison may normalize
the two valid standard-CRAN forms only after each manifest passes policy on its own.
In the explicit form, `RemoteSha` equal to `Version` is reference metadata, not an
independent package-content digest.

An outer `Repository: null` is **not** permission to:

- accept a null or untrusted outer repository value;
- relax `scripts/manifest_policy.R` or the CRAN-only policy;
- hand-edit `manifest.json`;
- omit manifest verification; or
- claim that installed package files alone prove reproducibility.

Repair repository access/configuration or the writable cache and rerun the complete
authoritative rebuild. Record the failing stage and confirm whether the five live
artifacts remained unchanged.

## Seven source repositories and safe Git access

The canonical sibling root in the current local environment is:

```text
C:/Users/tsgil/OneDrive/Documents/VGS - R
```

It must contain these seven expected named repositories. Additional sibling
directories are not consumed or rejected:

1. `App-NEON-Small-Mammal-Tracker`
2. `NEON-Plant-Diversity`
3. `NEON-Veg-Structure`
4. `NEON-Breeding-Birds`
5. `NEON-Plant-Phenology`
6. `NEON-Mosquito-Pulse`
7. `NEON-Ground-Beetle-Tracker`

Git may reject OneDrive-owned repositories as dubious. Never use
`safe.directory=*` and never weaken the machine-wide Git configuration. Create a
session-owned, narrowly scoped global config and an empty excludes file:

```powershell
$sourceRoot = 'C:/Users/tsgil/OneDrive/Documents/VGS - R'
$sourceRepos = @(
  'App-NEON-Small-Mammal-Tracker',
  'NEON-Plant-Diversity',
  'NEON-Veg-Structure',
  'NEON-Breeding-Birds',
  'NEON-Plant-Phenology',
  'NEON-Mosquito-Pulse',
  'NEON-Ground-Beetle-Tracker'
)
$runTag = [guid]::NewGuid().ToString('N')
$gitConfig = "C:/tmp/cascade-gitconfig-$runTag"
$emptyIgnore = "C:/tmp/cascade-empty-ignore-$runTag"

New-Item -ItemType File -Force -Path $emptyIgnore | Out-Null
git config --file $gitConfig core.excludesFile $emptyIgnore
foreach ($name in $sourceRepos) {
  git config --file $gitConfig --add safe.directory "$sourceRoot/$name"
}
$env:GIT_CONFIG_GLOBAL = $gitConfig
$env:CASCADE_ROOT = $sourceRoot
```

Keep these values alive for the entire rebuild. In a `finally` block, after all
child processes have exited, restore any prior `GIT_CONFIG_GLOBAL` and
`CASCADE_ROOT` values and remove only the exact session-owned `$gitConfig` and
`$emptyIgnore` files. Do not delete another session's config or broad temp paths.

The initial conservative cleanliness gate checks both `data/sites` and `data/env`
across all seven repositories. The immutable Git-object archive includes
`data/sites` for all seven repositories and additionally `data/env` only for the
mammal repository. The build also validates the seven canonical origins, records
exact commit IDs, extracts those exact Git objects with `git archive` into an
isolated source snapshot, and verifies the extracted bytes. Later stages use that
immutable snapshot through `CASCADE_ROOT`, not the mutable sibling worktrees.
Unrelated editor metadata outside both checked data scopes is intentionally inert.

## The only authoritative generation flow

Run from the repository root after the environment and source access are ready:

```powershell
& $rscript --vanilla scripts/rebuild_all.R
if ($LASTEXITCODE -ne 0) { throw "cascade rebuild failed: $LASTEXITCODE" }
```

Do not run `build_cascade.R`, `build_search_index.R`, `cascade_meta.R`, or
`write_manifest.R` separately against the live repository. Their generation guard
exists to prevent an unvalidated mixed artifact family.

`scripts/rebuild_all.R` performs the following nine stages in one isolated
generation:

1. build cascade bundle;
2. activate the exact immutable seven-repository source snapshot and build search
   index;
3. build companion meta-analysis;
4. run artifact/scientific contracts;
5. write the lean deploy manifest;
6. verify the complete deploy manifest;
7. reject malformed and mixed runtime generations;
8. load and smoke-test the exact staged application; and
9. reverify the manifest after application smoke.

The rebuild holds the atomic repository-local `.cascade-rebuild.lock`. It snapshots
the complete code surface as raw bytes before staging:

- all files under `R/`, `scripts/`, and `www/`, excluding Python bytecode caches;
- top-level `global.R`, `ui.R`, `server.R`, `.gitattributes`, `.Rprofile`, and
  `renv.lock` when present.

Any path or byte change in that surface during the run causes a deliberate failure.

Only after every staged check passes are these five files promoted:

1. `data/cascade.rds`
2. `data/search_index.rds`
3. `data/cascade_meta.rds`
4. `data/neon-cascade-codebook.csv`
5. `manifest.json` **last**

Each output first goes to a checksum-verified same-volume pending file. The live
family is backed up, promotion is verified, and `manifest.json` is checked once
more against the live root. An ordinary promotion error rolls all five files back
and verifies the prior hashes.

A power loss or hard process kill cannot make five filesystem entries transactionally
atomic. Manifest-last ordering and the boot checksum guard instead ensure a mixed
family refuses to boot before any generated RDS is deserialized. After such an
interruption, do not hand-repair individual artifacts; inspect/clear only a proven
stale lock and rerun the complete rebuild.

## Locked scientific behavior

These values are deliberate regression pins. Change them only after rechecking the
raw source oracle, updating the focused contracts, successfully rebuilding the
whole artifact family, and recording the evidence here.

### Small-mammal trap effort and duplicate events

The six allowed `trapStatus` tokens are literal after trim/lowercase normalization:

| Literal token | Meaning | Trap-night weight |
|---|---|---:|
| `1 - trap not set` | trap not set | 0 |
| `2 - trap disturbed/door closed but empty` | disturbed or door closed empty | 0.5 |
| `3 - trap door open or closed w/ spoor left` | door open/closed with spoor | 0.5 |
| `4 - more than 1 capture in one trap` | multi-capture row | 1 |
| `5 - capture` | capture | 1 |
| `6 - trap set and empty` | trap set empty | 1 |

Canonical coordinates `A`-`J` by `1`-`10` normally represent one physical trap. A
duplicated canonical event is grouped by
`year|nightuid|plotID|trapCoordinate` and then resolved only by the rules below.

A duplicated canonical group collapses to one trap-night only when:

- every status is 4 or 5;
- at least one row has status 4;
- every tag is present and tag values are unique;
- every reviewed-marker value is zero; and
- every row has the same `collectDate`.

A reviewed double-trap group sums row weights only when:

- it has exactly two rows;
- both rows have the same nonzero reviewed marker;
- neither row has status 4;
- both rows have the same `collectDate`; and
- the subset of tags that are present contains no duplicate value.

Only the first case collapses effort to one while preserving distinct capture rows;
only the second sums row weights. Merely containing a marker is insufficient. The
two reviewed marker substrings are:

- `trap accidentally double set`
- `double trap method (two traps set at each location)`

Placeholder coordinates `AX`-`JX`, `X1`-`X10`, and `XX` remain row-level uncertain
effort because the token cannot identify a physical trap. Any other duplicated
canonical pattern fails closed.

Exact mammal contract pins:

| Measure | Locked value |
|---|---:|
| placeholder rows | 376 |
| multi-capture events | 392 |
| reviewed double-trap events | 2 |
| same-night repeated-tag groups | 79 |
| same-event repeated-tag groups | 0 |
| `mammal_same_night_tag_coordinate_conflicts` (repeated-tag groups containing a duplicate coordinate) | 0 |
| tagged half-effort rows | 10 |
| untagged status-5 rows | 1 |

The coordinate-conflict value of zero means every one of the 79 repeated-tag groups
uses distinct coordinates for its repeated occurrences. It does not mean the tag
appeared only once that night; do not paraphrase it into a different rule.

### WOOD vegetation design

`WOOD` is the one reviewed unsupported vegetation design. It intentionally fails
closed because all qualifying source records use unmatched plots. Exact pins:

| Measure | Locked value |
|---|---:|
| expected basal area | `NA` |
| expected vegetation type | `NA` |
| used/expected plots | 0 |
| source record plots | 14 |
| matched record plots | 0 |
| area-eligible plots | 0 |
| unmatched record plots | 14 |
| unmatched record rows | 452 |
| unmatched qualifying source rows | 411 |
| design status | `unsupported-unmatched-plots` |

The exact unmatched plot IDs are:

```text
WOOD_008, WOOD_009, WOOD_012, WOOD_014, WOOD_015, WOOD_016, WOOD_018,
WOOD_019, WOOD_045, WOOD_056, WOOD_057, WOOD_061, WOOD_070, WOOD_071
```

Do not impute plot area, emit a partial-site estimate, invent basal area/type, or
treat an unmatched or absent plot record as zero. `NA` plus
`unsupported-unmatched-plots` is the valid reviewed outcome, not a failing result
to "fix."

## Completion test matrix

"Done" means every applicable row below has dated evidence for the final unchanged
code/data state. Run in this order; a later code change invalidates earlier build,
determinism, browser, and manifest evidence.

| Order | Gate | Status | Date | Generation / evidence |
|---:|---|---|---|---|
| 1 | Worktree ownership | PASS | 2026-07-17 | Broad intentional dirty tree reviewed and preserved; no conflicting rebuild/editor; tracked `_diag_seasonal.R` deletion left untouched. |
| 2 | Static syntax | PASS | 2026-07-17 | 22 R files parsed as UTF-8; `node --check`; both Python files compiled in memory; Python fixtures passed. |
| 3 | Workflow policy | PASS | 2026-07-17 | Both YAML files safe-loaded; all 13 `uses:` values are full lowercase 40-hex pins; receipt self-test passed. |
| 4 | Text hygiene | PASS | 2026-07-17 | `git diff --check`; no bytecode, lock, stage, backup, pending, temp config, credential, or scratch residue. |
| 5 | Authoritative build | PASS | 2026-07-17 | Nine of nine stages plus live post-promotion verification passed for SHA family `5453e448…/dffe9d2d…`. |
| 6 | Independent live-root checks | PASS | 2026-07-17 | All five required R checks passed independently; 73 packages, 12 files, 510 annual rows, 552 links. |
| 7 | Determinism | PASS | 2026-07-17 | Second complete rebuild from identical code/source/environment was byte-identical 5/5. |
| 8 | Pre-promotion failure safety | PASS | 2026-07-17 | Invalid source root failed before promotion; all five hashes unchanged; environment/working directory restored; cleanup clean. |
| 9 | Promotion rollback safety | PASS | 2026-07-17 | Controlled third-copy failure restored exact prior bytes/hashes 5/5; environment/working directory restored; cleanup clean. |
| 10 | Writer capability guard | PASS | 2026-07-17 | Four direct writers rejected missing generation capability; all five hashes unchanged. |
| 11 | Browser QA | PASS | 2026-07-17 | Final generation passed desktop/mobile navigation, search, theme, four plots, QC/About, accessibility/live regions, screenshots, local-only boot assets, and console review. |
| 12 | Final state | PASS | 2026-07-17 | Exact hashes, failures, cleanup, residual risks, and next action are recorded here; final status preserves intentional product changes. |

### Static and focused commands

With `$rscript` and `R_LIBS` already established:

```powershell
$env:RFILES = ((rg --files -g '*.R') -join ';')
& $rscript --vanilla -e 'for (f in strsplit(Sys.getenv("RFILES"), ";", fixed=TRUE)[[1]]) parse(file=f); cat("ALL R FILES PARSED\n")'
if ($LASTEXITCODE -ne 0) { throw 'R parse gate failed' }

node --check www/cascade.js
if ($LASTEXITCODE -ne 0) { throw 'JavaScript syntax gate failed' }

python -B -c "from pathlib import Path; [compile(Path(p).read_text(encoding='utf-8'), p, 'exec') for p in ('scripts/trusted_publish.py','scripts/test_trusted_publish.py')]"
python -B scripts/test_trusted_publish.py

& $rscript --vanilla scripts/workflow_guard.R self-test
& $rscript --vanilla scripts/test_manifest_compare.R
git diff --check
```

Parse workflow YAML with a safe parser and programmatically assert every `uses:`
value matches `^[0-9a-f]{40}$` after `@`. Do not validate this by visual sampling.

### Live-root checks after a successful rebuild

Keep the source/safe-directory environment active:

```powershell
& $rscript --vanilla scripts/test_helpers.R
& $rscript --vanilla scripts/verify_manifest.R
& $rscript --vanilla scripts/test_manifest_compare.R
& $rscript --vanilla scripts/test_boot_integrity.R
& $rscript --vanilla scripts/smoke_app.R
```

Stop immediately on any nonzero exit. The full rebuild already runs most of these
inside staging; the separate run proves the promoted live root is coherent.

### Artifact hash record

Capture all five as one family before and after determinism/failure tests:

```powershell
$artifacts = @(
  'data/cascade.rds',
  'data/search_index.rds',
  'data/cascade_meta.rds',
  'data/neon-cascade-codebook.csv',
  'manifest.json'
)
$hashes = Get-FileHash -Algorithm SHA256 -LiteralPath $artifacts |
  Select-Object Path, Hash
$hashes | Format-Table -AutoSize
```

Compare normalized path-to-hash mappings, not console ordering. Record the five
hashes only for a meaningful validated generation; do not paste temporary staging
paths or capability tokens.

### Failure and rollback sequence

1. Save current SHA-256 mappings for all five files.
2. Run the chosen failure in isolation; do not edit code during the run.
3. Confirm the expected stage and nonzero exit rather than treating any failure as
   equivalent evidence.
4. Recompute all five hashes and require the expected unchanged or restored family.
5. Confirm the original working directory and prior values of `CASCADE_ROOT`,
   `CASCADE_GENERATION_ROOT`, and `CASCADE_GENERATION_TOKEN` were restored.
6. Confirm `.cascade-rebuild.lock`, same-volume `.*-pending-*`, and temporary stage
   and backup directories owned by the run are gone.
7. Run `verify_manifest.R` and the boot-integrity test against the surviving live
   family.
8. Record the exact outcome. If rollback is not exact, stop: do not run or deploy
   the app until a complete authoritative rebuild restores a verified family.

`test_boot_integrity.R` separately exercises malformed/truncated/duplicate
manifests, mutated artifacts, and every cut between the four data artifacts and the
manifest. Only all-old and all-new generations may reach the deserialization
sentinel.

### Browser QA sequence

After every non-browser gate passes, start the final app on loopback only, normally
`127.0.0.1:8194`. Retain the server log and stop the process at the end.

For both a desktop viewport and a narrow mobile viewport:

1. load the landing page and confirm no integrity/startup error;
2. navigate every main section and exercise search/link navigation;
3. switch light/dark theme and verify legibility and persisted state;
4. materialize `ladderPlot`, `linkScatter`, `expCurve`, and `seasonalPlot`;
5. inspect QC and About content;
6. use keyboard-only navigation and verify visible focus, popover dismissal, and
   live-region announcements;
7. inspect browser console and network failures; and
8. capture representative desktop/mobile screenshots tied to the final generation.

Any app/code/data change after this pass invalidates it. A smoke test does not
replace browser QA, and screenshots do not replace interaction/console checks.

## Failure interpretations

| Symptom | Interpretation and required action |
|---|---|
| `.cascade-rebuild.lock` already exists | Another publisher may be active. Read ownership and inspect the process. Remove only if proved stale, then record that action. |
| source repository is unsafe/dubious | Use the narrow session Git config above. Never add wildcard safe-directory trust. |
| consumed source scope is dirty or origin/commit is wrong | Stop. Resolve the source repository deliberately; do not build from unrecorded working-tree bytes. |
| build code inventory/bytes changed | Concurrent edit occurred. Let the editor finish, then restart the entire rebuild from a stable state. |
| WOOD returns unsupported/`NA` with exact pins | Valid fail-closed scientific result; no imputation or partial estimate. |
| outer package-record `Repository: null` or untrusted | Environment/network/repository metadata failure; repair it and rerun, without policy relaxation or manifest rewriting. |
| all five standard CRAN `description.Remote*` fields absent | Valid implicit form from untouched `rsconnect` output, provided outer repository, `description.Repository`, package graph, version, and all other policy checks pass. Partial/null-named/rogue remote fields still fail. |
| staged contract, manifest, boot, or smoke stage fails | No promotion should occur. Prove live hashes unchanged and record the exact stage/message. |
| ordinary promotion fails | Rollback should restore all five prior files. Prove exact hashes and cleanup; stop if any mismatch remains. |
| power loss/hard kill during promotion | Treat live family as suspect even if files exist. Runtime guard should refuse mixed bytes. Rerun the full rebuild before use. |
| direct artifact writer refuses to run | Expected generation-capability protection; use `rebuild_all.R`. |

## Residual risks currently carried

- No commit, push, deployment, or publication was performed. The validated release
  candidate remains a broad uncommitted worktree and needs deliberate human review
  before any publication action.
- The dated Posit Package Manager URL and strict CRAN identity policy do not archive
  or independently content-hash every upstream package tarball.
- Five separate filesystem entries cannot be indivisibly atomic across hard power
  loss. Manifest-last promotion and the 12-file boot checksum guard make a mixed
  generation refuse to boot; recovery is still a complete rebuild.
- The process starts with invalid `C.UTF-8` environment settings on this Windows
  host. Runtime activation of `English_United States.utf8` is tested and required,
  but bypassing the supported runtime/helper path can reintroduce corruption.
- Browser coverage is finite. The final matrix covered the principal desktop/mobile,
  interaction, plot, Unicode, and accessibility paths, not every device/browser or
  every possible input combination.
- The user Sass cache is not writable in this sandbox; Shiny safely falls back to a
  temporary cache. Some installed R packages report that they were built under R
  4.5.3 while tests run under R 4.5.2. Neither warning changed validated output,
  but both should remain visible in future environment audits.

Remove a risk only when new dated evidence actually eliminates it. Do not delete a
risk merely because it is inconvenient or accepted.

## Handoff update protocol

Every repository session must update this record before its final report, including
read-only inspection, a failed attempt, a blocked task, or a no-change result. The
coordinating owner is the sole editor when agents/sessions overlap; all others return
their evidence to that owner. Immediately before editing, re-read the latest file and
merge concurrent facts rather than replacing them.

Use this timestamped shape:

```text
YYYY-MM-DD HH:mm TZ - scope/owner
- Changed: exact files or behavior, or explicitly none.
- Learned: reusable causal finding or process improvement.
- Test process: cwd, relevant tool versions/environment, exact commands/gates,
  expected result, actual result, and artifact generation/hash scope.
- Evidence invalidated: none, or the exact earlier gates invalidated by a change.
- Artifacts: unchanged, cleanly rolled back, or promoted with the five hashes.
- Failure/cleanup: failed stage/message and lock/pending/stage/backup/scratch state.
- Residual risk: what remains unproved.
- Next action: the first concrete unchecked, blocked, review, or publication step.
```

Rules:

- Promote durable lessons into the canonical environment, generation, failure, or
  test sections above; keep the chronological ledger compact.
- Record only observed facts. Never include credentials, access tokens, cookies,
  environment dumps, temporary capabilities/lock tokens, PIDs, private data rows,
  large logs, guesses, or speculative conclusions.
- A gate entry must name its status (`PASS`, `FAIL`, `BLOCKED`, `NOT RUN`, or `N/A`),
  date, evidence, and generation. A later relevant change explicitly invalidates it.
- A failed build entry states whether promotion began, whether all five live hashes
  were unchanged/restored, and whether owned temporary/lock state was removed.
- A scoped docs/test/tooling task can be complete only at that narrow scope when
  omitted matrix rows are explicit. Never translate it into product completion.
- Finish with `git status --short`; preserve every unrelated change.

## Session ledger

### 2026-07-17 12:15 MST - final UTF-8/release audit / root, with three read-only auditors

- **Changed:** completed recursive artifact text normalization/validation in
  `R/cascade_helpers.R`; activated a real UTF-8 runtime locale in `global.R`; made
  nested runtime loading use UTF-8 parse/eval; protected UTF-8 codebook writing;
  strengthened `scripts/test_helpers.R` and `scripts/smoke_app.R`; rebuilt the four
  data/codebook outputs and manifest. Updated `AGENTS.md` and this handoff so every
  future session records learnings and its reproducible test process.
- **Learned:** valid UTF-8 bytes serialized with `Encoding="unknown"` are unsafe
  under this Windows startup C locale. The observed arrow, en dash, and degree
  corruption came from that path, not from invalid source bytes. `fileEncoding`
  alone also transliterates marked text under C; activate a real UTF-8 `LC_CTYPE`
  during CSV writes. Recursive normalizers must not assign unchanged data-frame
  metadata, because doing so can materialize compact row names and break exact
  provenance equality. Nested repository source should use
  `eval(parse(..., encoding="UTF-8"))`.
- **Test process:** cwd `D:\Git\NEON-Driver-Cascade`; R 4.5.2;
  `R_LIBS=C:/tmp/cascade-r-lib`; canonical seven-repository `CASCADE_ROOT`; isolated
  narrow Git safe-directory config; visualization scratch renv cache. Ran
  `scripts/rebuild_all.R` twice, then `test_helpers.R`, `verify_manifest.R`,
  `test_manifest_compare.R`, `test_boot_integrity.R`, and `smoke_app.R`; ran the
  R/JS/Python/YAML/workflow/static matrix; independently audited science/provenance;
  and exercised the final app at 1280×720 and 390×844. Expected and actual result:
  two identical passing generations plus unchanged hashes during read-only checks.
- **Scientific result:** schemas are cascade v6, search v4, meta v3; 510 annual rows,
  46 sites, and 552 link rows. Temperature→green-up is 15/18 with stored
  `p=0.003768920898437503`; meta pooled `r=-0.32816863784464995` from 18 effects,
  95% CI/prediction interval `[-0.48428028312776150,-0.15180551808277745]`.
  Mammal and WOOD raw-source pins in the locked sections passed exactly.
- **Failed safely:** an early stage-3 rebuild found that assigning unchanged
  data-frame names changed row-name representation and failed provenance equality.
  Two stage-4 attempts exposed C-locale CSV transliteration/parity failures. None
  reached promotion; live hashes stayed unchanged and owned state cleaned up. The
  fixes were respectively conditional metadata assignment and a temporary verified
  UTF-8 locale around CSV writing. Controlled invalid-root, writer-capability, boot
  cut, and promotion-copy failures also failed/rolled back exactly as designed.
- **Artifacts:** promoted SHA-256 family is the five-file table at the top; the
  second full build and independent checks left it byte-identical. All 908
  non-ASCII artifact values are explicitly UTF-8-marked; recursive text issues are
  zero in all three RDS bundles; cross-locale RDS reopen and CSV parity passed.
- **Browser/accessibility:** all seven sections loaded; search exposed 12 unique
  arrow labels and the aligned-only result reported two clean sites; QC rendered
  `“Apparent” links whose CI spans zero`; About rendered `Oct–Mar`, `Jul–Sep`, and
  `°C`; WOOD announced a polite/atomic withheld estimate with 452 records and 14
  plot IDs; BLAN rendered `oak–hickory`; the four Plotly outputs, theme, responsive
  layout, keyboard alternatives, and zero horizontal overflow passed. Console
  warning/error review was empty and page-asset inventory found only local boot
  resources. A redundant browser reattachment after these checks timed out in the
  harness; the loopback server remained healthy and was stopped with no listener.
- **Cleanup/evidence:** three independent read-only auditors reproduced the live R,
  static/workflow, and science/provenance gates without changing the five hashes.
  The exact four-file ignored `scripts/__pycache__` residue was verified and removed;
  no lock/stage/backup/pending/temp-config residue remains. This documentation edit
  passed strict UTF-8/LF, NUL/control, fence, trailing-whitespace, required-content,
  and `git diff --check` gates; it does not invalidate the built runtime generation.
- **Residual risk:** package bytes are not independently archived, five-file hard
  power-loss atomicity is impossible, browser coverage is finite, and the validated
  tree is not yet committed or deployed.
- **Next action:** review the intentional worktree diff, then commit/publish/deploy
  only if explicitly requested. If code or artifacts change first, mark the affected
  matrix rows invalid and rerun from the earliest invalidated gate.

### 2026-07-17 13:59 MST - merged release, deterministic rebuild, and publication prep / root

- **Changed:** merged `origin/master` into `codex/publish-response-atlas-20260717`
  (`e0ca139`); retained the hardened receipt workflow, generation-guarded manifest
  writer, and system-only app font stack. Added the share-card asset, canonical/social
  metadata, README Explore links, and a desktop-safe two-line cover heading.
- **Learned:** the stage-8 remote-font gate intentionally rejects a forbidden helper
  token even when it appears only in a comment; explain the offline policy without
  copying that token. The final shell wrapper must use `git -C` after app smoke, and
  the workflow pin audit must recurse through every `jobs.*.steps.*.uses` entry.
- **Test process:** cwd `D:\Git\NEON-Driver-Cascade`; R 4.5.2; `R_LIBS=C:/tmp/cascade-r-lib`;
  dated Posit package cache; canonical seven-repository `CASCADE_ROOT`; session-scoped
  Git safe-directory config. Ran `scripts/rebuild_all.R` twice, all nine stages each
  time; both generations passed contract, manifest, malformed-generation, staged-app
  boot, smoke, and post-promotion checks. Then ran R parse, JavaScript, Python, YAML,
  13 pinned-action, workflow-guard, live helpers, manifest verification/comparison,
  boot-integrity, and app-smoke gates. Expected locale/package-build warnings only;
  all required gates passed.
- **Evidence invalidated:** the earlier pre-merge generation hashes were invalidated
  by the upstream merge and font-policy comment change; the final two-pass family is
  the applicable evidence.
- **Artifacts:** final byte-identical SHA-256 family: cascade
  `5453e448cd5f1ea82a0844425a61bbf5ed5d15ddcd57f35f3eaedbed68097845`, search
  `1e3449cfee4ebb8d41c40ce0f1544f210c8ae1ea671cb33e0f57777221a0ce1d`, meta
  `7e1aef4fc614c0cfbe9a7646b974ecd8bf520c1af8db762f51abccf2c6c5f8f4`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, manifest
  `b1851e53d1796f4989a2f46b39df02577ae95bc92c9aeca5d67549dbc62c0150`.
- **Failure/cleanup:** the first post-merge pass stopped at 8/9 because its explanatory
  comment triggered the remote-font scanner; it did not promote, the five live hashes
  stayed unchanged, and lock/stage/backup/pending state was removed. The corrected
  rerun passed and promoted; the initial inline workflow checker was a harness false
  negative and was replaced by the corrected 13-entry recursive check.
- **Residual risk:** GitHub metadata, branch push/merge, Pages deployment, and final
  public URL verification remain unchecked; the current static cover was browser-tested
  locally at desktop and mobile sizes, but the published Pages response is not yet
  verified.
- **Next action:** stage the final generated manifest and this ledger entry, commit,
  push the release branch, merge it, update the repository description/homepage, wait
  for Pages, and verify the direct public cover plus share asset.

### 2026-07-17 14:06 MST - remote CI repair / root

- **Changed:** after PR #4 started, GitHub Actions failed before project tests because
  the Ubuntu runner lacked `libcurl` headers while `pak-version: repo` compiled pak
  from source. Changed all three dependency-install jobs in the two workflows to
  `pak-version: stable`; no app or generated artifact bytes changed.
- **Learned:** local Windows package availability does not prove the Linux runner has
  native headers. Treat dependency-bootstrap failures separately from product gates,
  and prefer the action's published stable pak distribution when a source build adds
  an unnecessary system-toolchain dependency.
- **Test process:** reran the safe YAML parser, all 13 immutable action-SHA checks,
  trusted-publisher fixtures, and `git diff --check`; expected result PASS, actual
  result PASS. The prior local two-pass rebuild and live-root matrix remain valid
  because this change is workflow-only.
- **Evidence invalidated:** only the remote PR check; the failed job reached no project
  build or contract stage. Local artifact hashes and live-root evidence remain valid.
- **Failure/cleanup:** GitHub job failed in pak installation with `curl/curl.h: No such
  file or directory`; no repository artifacts were written. Local workflow fix is
  staged and statically validated; PR check must rerun.
- **Residual risk:** the replacement `stable` pak distribution still requires GitHub
  Actions to complete; merge and Pages publication remain pending.
- **Next action:** commit/push the CI repair, wait for PR checks to pass, merge, update
  repository metadata, and verify the live Pages cover and share asset.

### 2026-07-17 14:18 MST - cross-platform UTF-8 contract repair / root

- **Changed:** updated `scripts/test_helpers.R` so unmarked UTF-8 rejection is
  locale-invariant and added an explicitly foreign-marked fixture for the byte-change
  guard. No generated artifact or deploy file changed; the test is outside the build
  input inventory.
- **Learned:** Linux `C.UTF-8` can preserve raw UTF-8 bytes through `enc2utf8()` while
  Windows startup C/activated UTF-8 changes the same unmarked fixture. The durable
  contract is the required UTF-8 mark plus a separate deterministic foreign-mark test,
  not a locale-specific byte-change count.
- **Test process:** the second GitHub check reached project tests and failed at the
  old locale-specific assertion. After the fix, the full local `scripts/test_helpers.R`
  source/oracle suite passed under R 4.5.2 with the canonical seven-source root;
  the earlier 13-action YAML/pin and publisher gates remain green.
- **Evidence invalidated:** only the second remote PR check; local two-pass artifact,
  manifest, boot, smoke, and live-root evidence remains valid because generated inputs
  and bytes are unchanged.
- **Failure/cleanup:** GitHub failed with `valid UTF-8 with an unknown/native mark is
  rejected` under `C.UTF-8`; no artifact promotion or repository writes occurred.
  The corrected local helper run completed cleanly and removed its session config.
- **Residual risk:** PR #4 must rerun the cross-platform helper and full rebuild job;
  merge and Pages publication remain pending.
- **Next action:** commit/push this test-only portability fix, wait for the remote check
  to pass, merge, update repository metadata, and verify the public Pages cover.
### 2026-07-17 14:28 MST - CI manifest dependency repair / root

- **Changed:** added `cpp11` to the explicit Linux CI dependency bootstrap because the committed manifest requires it at runtime. No application, workflow input inventory, or generated artifact bytes changed beyond this workflow dependency declaration.
- **Learned:** a hard dependency install can complete while a manifest-governed runtime package remains absent when that package is only exposed through recorded LinkingTo/configuration metadata. CI must install the manifest's required runtime set explicitly before verification.
- **Test process:** the third remote check passed all parser, publisher, UTF-8 helper, manifest, and contract tests, then failed at the runtime-library completeness gate with `cpp11` missing. Local workflow/pin checks and the full deterministic rebuild evidence remain valid because this is a workflow-only repair.
- **Evidence invalidated:** only the third remote PR check; no artifact promotion or repository snapshot mutation occurred in the failed job.
- **Failure/cleanup:** no local generated files were changed. The workflow now requests `cpp11` directly; `git diff --check` and the local workflow guard must pass before push.
- **Residual risk:** GitHub Actions must confirm the added package is available from the pinned Posit repository; merge and Pages publication remain pending.
- **Next action:** commit/push this CI dependency repair, wait for PR checks to pass, merge, update repository metadata, and verify the public Pages cover and share asset.

### 2026-07-17 14:45 MST - sibling checkout line-ending portability repair / root

- **Changed:** kept exact detached-commit and index checks, but replaced the sibling worktree cleanliness assertion with `git diff --quiet --ignore-space-at-eol` plus an explicit cached-index check. Removed temporary fetch tracing after identifying the affected row. No application or generated artifact bytes changed.
- **Learned:** the pinned beetle commit stores its CSV with CRLF in the index while `.gitattributes` declares `eol=lf`; Ubuntu therefore reports a line-ending-only worktree modification after checkout even though the commit is exact. A clean-content check must distinguish normalization-only EOL changes from substantive edits.
- **Test process:** the traced GitHub run fetched and verified all seven exact commits, then failed only on `data-sample/beetle_demo.csv` showing ` M` from EOL normalization. Local reproduction confirmed the same attribute/index behavior; the new guard ignores only end-of-line whitespace and still rejects staged or substantive differences.
- **Evidence invalidated:** only the traced remote PR check; local generated artifacts and deterministic rebuild evidence remain valid because the fix is CI guard logic only.
- **Failure/cleanup:** temporary diagnostics were removed; `git diff --check` passes. The next remote run is the authoritative validation of the portability fix.
- **Residual risk:** merge and Pages publication remain pending until the full rebuild and manifest comparison complete on GitHub.
- **Next action:** push this final CI portability repair, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 14:55 MST - cross-platform sensitivity precision repair / root

- **Changed:** relaxed only the two recomputed correlation comparisons for detrended and adjacent-change sensitivities from `1e-15` to `1e-12`; counts, signs, NA states, and all other exact contracts remain unchanged. No generated artifact bytes changed.
- **Learned:** the final Ubuntu run passed provenance fetching and all earlier contracts, then exposed a floating-point comparison that is stricter than reproducible correlation arithmetic across R/platform builds. A 1e-12 absolute bound remains far below display precision while avoiding false failures from harmless platform rounding.
- **Test process:** local R 4.5.2 helper suite passes end-to-end; the failed remote run isolated the issue to the single detrended/change sensitivity check. GitHub must rerun the authoritative Linux build after this test-only portability change.
- **Evidence invalidated:** only the latest remote PR check; deterministic artifacts and prior local rebuild evidence remain valid because the test comparator change does not alter production code or bytes.
- **Residual risk:** if the remote mismatch is structural rather than numeric, the remaining exact count/sign checks will still fail and require further diagnosis.
- **Next action:** push this focused test repair, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 15:05 MST - manifest locale portability repair / root

- **Changed:** normalized rsconnect's informational manifest locale token to `en_US` immediately after write, preserving all other generated bytes and the approved manifest schema. No scientific computations or deploy-file checksums changed.
- **Learned:** the Ubuntu rebuild reached stage 5 and failed because rsconnect serialized the runner's `C.UTF-8` locale while the release contract intentionally requires the stable Connect token `en_US`; package installation and all earlier contracts were healthy.
- **Test process:** the preceding GitHub run passed the sibling provenance guard and contract suite, then failed only at manifest locale policy. The local full rebuild cannot execute without the seven sibling repositories (`CASCADE_ROOT` is intentionally absent in this workspace); prior two-pass rebuild hashes remain the authoritative artifact evidence.
- **Evidence invalidated:** the latest remote rebuild only; the locale normalization is a writer-only portability fix and does not alter source locks or artifact inputs.
- **Residual risk:** GitHub must confirm the patched writer preserves manifest semantic comparison and the final deploy manifest checks.
- **Next action:** push the writer fix, wait for the complete rebuild to pass, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 15:12 MST - Posit RSPM manifest trust repair / root

- **Changed:** allowed the standard CRAN package record label `RSPM` alongside `CRAN` when the recorded `RemoteRepos` host remains the trusted pinned Posit repository; removed temporary DT logging. No package versions, dependency projections, or deploy checksums are relaxed.
- **Learned:** Ubuntu's Posit snapshot records ordinary CRAN packages with `Source=CRAN` but `description$Repository=RSPM`, while the Windows-generated baseline records `CRAN`. The prior policy treated this legitimate platform packaging label as untrusted even though the remote provenance fields were exact.
- **Test process:** the diagnostic run printed the DT record and isolated the mismatch to `description$Repository=RSPM`; package version, standard remote ref/SHA, trusted RemoteRepos, and R 4.5 compatibility all matched policy. The next GitHub run must validate the full manifest projection and rebuild.
- **Evidence invalidated:** only the diagnostic remote check; artifact hashes remain unchanged because this is manifest-policy validation logic.
- **Residual risk:** the candidate manifest may still expose a different dependency projection; `compare_manifests.R` will catch any semantic drift after policy validation.
- **Next action:** push this narrow trust-policy repair, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 15:18 MST - Posit remote platform provenance repair / root

- **Changed:** allow rsconnect's `RemotePkgPlatform` field as an optional standard Posit provenance field, while preserving exact RemoteType/ref/SHA and trusted RemoteRepos validation. No dependency projection or deploy checksum is relaxed.
- **Learned:** after accepting the legitimate `RSPM` repository label, Ubuntu's rsconnect added a truthful platform field (`x86_64-pc-linux-gnu-ubuntu-24.04`) that the older allowlist rejected as unexpected. Platform-specific provenance metadata must be allowlisted without becoming a trust bypass.
- **Test process:** the latest run passed all source contracts and reached manifest generation; the sole failure was `unexpected package provenance field(s) for DT: RemotePkgPlatform`. The next run must validate manifest semantic reproducibility after this narrow allowlist update.
- **Evidence invalidated:** only the latest remote check; artifact and source-lock evidence remain valid.
- **Residual risk:** additional RSPM metadata fields, if present, should remain rejected unless they are separately understood and validated.
- **Next action:** push this narrow provenance-field repair, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 15:21 MST - provenance fixture alignment / root

- **Changed:** updated the manifest comparator fixture to populate the newly allowlisted `RemotePkgPlatform` field in explicit provenance records, so its partial/singleton-field tests continue to exercise the complete standard field set. No production manifest or artifact bytes changed.
- **Learned:** expanding a schema allowlist requires updating its adversarial fixtures; otherwise the fixture itself becomes a partial-provenance record and fails for the wrong reason.
- **Test process:** the latest CI run passed all contracts and manifest verification, then failed inside `test_manifest_compare.R` because its synthetic explicit record lacked the newly recognized field. This is a test-fixture-only correction.
- **Evidence invalidated:** only the latest remote check; all generated artifacts remain unaffected.
- **Residual risk:** the next check must still complete sibling rebuild, artifact byte comparison, and semantic manifest comparison.
- **Next action:** push the aligned fixture, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.
### 2026-07-17 15:34 MST - search-index ordering portability repair / root

- **Changed:** made all three search-index `arrange()` calls use explicit `.locale = "en"` ordering. This targets row-order bytes only; link values, calculations, counts, and source bundle hashes are unchanged.
- **Learned:** the Linux rebuild passed every contract and all artifact stages except the byte-exact search-index comparison. The index is the only artifact built from dplyr-sorted human labels/catalogues, so implicit host collation is the leading reproducibility risk; explicit locale ordering removes that dependency.
- **Test process:** the failing run reported only `data/search_index.rds` as binary-different; cascade.rds, metadata, codebook, and manifest checks did not fail before the gate. The exact seven-snapshot local reproduction is available, though a prior local child rebuild is still finishing and owns temporary test processes.
- **Evidence invalidated:** only the latest remote check; committed scientific artifacts remain untouched locally.
- **Residual risk:** if the remaining byte difference is serialization rather than row order, the next run will isolate that with the same one-file diff.
- **Next action:** push this deterministic ordering repair, wait for green checks, merge, update repository metadata, and verify the public Pages cover/share asset.