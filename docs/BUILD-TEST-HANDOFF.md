# Build, test, and handoff record

Last updated: 2026-07-19

This is the durable operating record for the NEON Driver Cascade repository. Read
the whole document before doing work. Keep it factual and current so a new session
can continue safely without relying on chat history.

## Current handoff state

**Release-validation state on `master`: RELEASED AND PUBLICLY VERIFIED as of
2026-07-18.** The owner approved Ubuntu 24.04 with R 4.5.2, the pinned
2026-07-15 Posit snapshot, OpenBLAS `Haswell`, and one BLAS/OpenMP thread as the
canonical release-byte platform. The exact Ubuntu byte gate remains authoritative.
Windows remains a strict schema/class/attribute/key/text/source/support/decision
oracle with only explicitly named bounded full-precision numeric diagnostics. No
scientific value is rounded and no decision, support, checksum, or provenance gate
is weakened.

The promoted Ubuntu candidate family was copied locally as one unit, with
`manifest.json` copied last. Source and destination SHA-256 values match the table
below; the codebook is unchanged. Local R/Python provenance fixtures, manifest
verification (73 packages/12 files), the complete seven-repository raw-source
oracle, boot-integrity faults (12 malformed/mutated fixtures and six promotion
cuts), app smoke (510 annual rows/12 associations), workflow receipt fixtures,
JavaScript syntax, YAML/pin review, and whitespace checks pass.

GitHub Actions run `29632690022` on head `5effe239` passed the complete nine-stage
build, every raw-source/scientific contract, manifest verification, boot-integrity
fixtures, and app smoke. It then failed the unchanged exact-byte gate because all
three RDS files differed while the CSV codebook matched; semantic-manifest and
whitespace gates correctly skipped. The earlier producer run and this run used the
same runner image, R, OpenBLAS/LAPACK versions, package graph, sources, and writer
code. The remaining unpinned dimension was OpenBLAS host-CPU kernel/thread choice.
GitHub Actions run `29644372306` on head `8ca35a2` then loaded
`OpenBLAS core=Haswell threads=1` under DYNAMIC_ARCH, reproduced all four scientific
artifacts exactly, and passed the semantic-manifest and whitespace gates after the
complete build. The fail-only diagnostic correctly skipped and the run retained zero
artifacts; that temporary upload is now removed.

The diagnostic-free code/workflow head `526dd3bb2b9f6ad7170bd0af54bf25753ed6e3dd`
then passed GitHub Actions run `29644970791` twice on independent fresh runner
attempts (jobs `88081588746` and `88083964830`). Both attempts passed the loaded
Haswell/one-thread guard, all nine build stages, every source/scientific contract,
the unchanged exact-byte gate, semantic manifest comparison, and whitespace. The
second receipt was `OpenBLAS core=Haswell threads=1 config=OpenBLAS 0.3.26
NO_LAPACKE DYNAMIC_ARCH NO_AFFINITY Haswell MAX_THREADS=64`; the run retained zero
artifacts. This completes the required two-run deterministic release proof.

The evidence-only PR head `080673257edcc320c8a811d4bd481eb17279ebfe` passed
run `29646272806` (job `88084946603`) before PR #4 merged into `master` as
`430b0b03642fb9aa42e71de5118b460094d5a20a`. Post-merge master run
`29646451583` (job `88085414025`) passed the same loaded-runtime, nine-stage,
exact-byte, semantic-manifest, and whitespace gates. GitHub Pages reported status
`built` for that exact merge commit, the repository description/homepage now point
to the Response Atlas and its Pages URL, and the live cover, social image,
desktop/mobile layout, console, and all 12 unique public HTTP links passed final
verification.

The cross-platform diagnosis remains part of the audit record: one root family
diff from RDS native-encoding headers plus last-bit OLS/QR, correlation, and
REML/t arithmetic propagates through search/meta fingerprints. On the promoted
family the Windows source oracle reports `greenup_doy_additive` maximum absolute
delta `1.8474111129762605e-13` under its sole `1e-12` diagnostic; the primary
estimator and ten strict fields remain at `1e-15`, and all finite patterns, keys,
support, signs, votes, tiers, sensitivities, and decisions remain exact.

### Canonical Ubuntu release family (two clean pinned-runtime passes)

| Artifact | Bytes | MD5 | SHA-256 |
|---|---:|---|---|
| `data/cascade.rds` | 110113 | `6f67ef73a8ec1b478cf72eef5152dacb` | `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe` |
| `data/search_index.rds` | 18319 | `b11a4be96d406131305de5f1885cdbc5` | `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e` |
| `data/cascade_meta.rds` | 2482 | `84d2ee047fff438e9db3e8d5dce7760f` | `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de` |
| `data/neon-cascade-codebook.csv` | 15080 | `9f970cd051b1743cc3b45b4bf61e5eb8` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | 228559 | `b3d9fb8526e0e23ee90546745a718985` | `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79` |

### Historical validated five-file generation (not current HEAD evidence)

| Artifact | Bytes | MD5 | SHA-256 |
|---|---:|---|---|
| `data/cascade.rds` | 110131 | `8a28bc7e9188dbb4bed639f0fa4ec9ec` | `5453e448cd5f1ea82a0844425a61bbf5ed5d15ddcd57f35f3eaedbed68097845` |
| `data/search_index.rds` | 18318 | `28de029bb7fe9ac6abcd0d0b9396b399` | `1e3449cfee4ebb8d41c40ce0f1544f210c8ae1ea671cb33e0f57777221a0ce1d` |
| `data/cascade_meta.rds` | 2484 | `bb2066295994b9d0e4137221f187b932` | `7e1aef4fc614c0cfbe9a7646b974ecd8bf520c1af8db762f51abccf2c6c5f8f4` |
| `data/neon-cascade-codebook.csv` | 15080 | `9f970cd051b1743cc3b45b4bf61e5eb8` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | 210836 | `7ada31ae9ff396e5e06a9c53c11daeb0` | `b1851e53d1796f4989a2f46b39df02577ae95bc92c9aeca5d67549dbc62c0150` |

The two post-merge authoritative Windows rebuilds at 2026-07-17 13:59 MST
produced these exact bytes for all five files. They are superseded by the
canonical Ubuntu family above and remain audit history only, not current live or
release-byte evidence. The builds used 364 archived RDS inputs from these
immutable source commits:

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
| 2026-07-17 13:59 MST | Post-merge authoritative build and determinism | Two consecutive nine-stage Windows rebuilds passed and produced the historical five-file family above. | Superseded for current HEAD by later writer/policy/search-builder changes; retain as historical evidence only. |
| 2026-07-17 12:15 MST | Earlier authoritative build and determinism | Two consecutive full rebuilds passed all nine stages, promoted, post-verified, and produced byte-identical five-file families. | Its earlier manifest hash is preserved in the 12:15 ledger; this family was superseded by the 13:59 row above. |
| 2026-07-17 12:15 MST | Independent live-root and science audit | `test_helpers.R`, `verify_manifest.R`, `test_manifest_compare.R`, `test_boot_integrity.R`, and `smoke_app.R` passed. Contracts covered 510 annual rows, 46 sites, 552 links, 73 trusted packages, 12 deploy files, 12 malformed/mutated boot fixtures, and six ordered promotion cuts. | Windows rejected startup `C.UTF-8`; the runtime selected a real UTF-8 locale and the cross-locale reopen passed. |
| 2026-07-17 12:15 MST | Failure safety | Invalid `CASCADE_ROOT` failed before promotion with unchanged hashes; all four direct writers rejected a missing generation capability; a controlled copy-3 promotion failure restored all five prior files exactly; owned lock/stage/backup/pending state was clean. | Hard process kill and power-loss limits remain as described below. |
| 2026-07-17 12:15 MST | Static/workflow/security | All 22 R files parsed; JavaScript, Python, Python fixtures, both workflow YAML files, 13 SHA-pinned action references, workflow receipt fixtures, manifest fixtures, remote-font scan, deploy regular-file scan, and `git diff --check` passed. | R printed two non-fatal native-encoding warnings during a direct parse probe; use the UTF-8 parse pattern documented below. |
| 2026-07-17 12:15 MST | Final browser and accessibility QA | Desktop 1280×720 and mobile 390×844 passed navigation, search, theme, the four Plotly outputs, QC/About, keyboard alternatives, live regions, responsive overflow, and representative screenshots. Required arrows/dashes/degrees/curly quotes rendered; WOOD was withheld with exact metadata; no unexpected console warning/error was observed; all 36 observed boot assets were local. | Browser coverage is broad but finite; external reference anchors are navigation links, not boot dependencies. |
| 2026-07-17 12:15 MST | Handoff/hygiene | The verified four-file `scripts/__pycache__` residue was removed; no rebuild listener, lock, pending, backup, stage, temp config, or reparse point remained. `AGENTS.md` now requires every session to record learnings and test process here. | Existing broad product changes and the tracked deletion of `scripts/_diag_seasonal.R` were preserved. |

## Session start protocol

1. Read root `AGENTS.md` and this file completely. For suite-relevant work,
   also read the [NEON suite learning loop](NEON-SUITE-LEARNING-LOOP.md).
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

Endpoint security on this workstation may deny Codex's WindowsApps `pwsh.exe`
launcher with `CreateProcessAsUserW ... Access is denied`. Invoking
`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` explicitly has
worked. Treat this as an orchestration-path issue, not an application or test
failure; ask the owner to intervene only if the explicit system shell is also
blocked.

The reproducible workflow repository is the dated Posit Package Manager snapshot:

```text
https://packagemanager.posit.co/cran/__linux__/noble/2026-07-15
```

This is a dated repository snapshot, not a cryptographic content-hash guarantee.
That distinction remains a residual supply-chain risk.

### Manifest/network interpretation

`rsconnect::writeManifest()` can require reachable CRAN/Posit repository metadata
even when every package is installed locally. The approved dated repository must
be reachable during generation.

Every manifest is independently validated before any semantic normalization:

- the outer package-record `Repository` must be a scalar HTTPS URL on the trusted
  host allowlist;
- `description.Repository` must be scalar `CRAN` or `RSPM`;
- the five core fields `RemoteType`, `RemoteRepos`, `RemotePkgRef`, `RemoteRef`,
  and `RemoteSha` are all absent or all present with exact standard values;
- an `RSPM` description requires all five core fields and exact
  `RemoteRepos=https://packagemanager.posit.co/cran/__linux__/noble/2026-07-15`;
- `RemotePkgPlatform` is optional, but only beside the complete core and only as
  `x86_64-pc-linux-gnu-ubuntu-24.04`; named null, partial, malformed, near-miss,
  wrong-OS, or rogue provenance fields fail closed; and
- package graph, versions, R compatibility, deploy surface, and checksums remain
  exact policy gates.

After both records pass independently, the comparator may normalize the two
trusted standard-CRAN representations. `RemoteSha == Version` remains reference
metadata, not an independent package-content digest.

The sole permitted post-write change is the root manifest locale token. The writer
accepts only the exact rsconnect output tokens `en_US` or `C`, requires one canonical
root line, normalizes it to `en_US`, reparses, and proves every other parsed field
is identical. It never rewrites package provenance. R comparator fixtures and the
independent standard-library Python publisher fixtures enforce the same policy.

An outer `Repository: null` is **not** permission to:

- accept a null or untrusted outer repository value;
- relax `scripts/manifest_policy.R` or the trusted standard-CRAN policy;
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
code/data state. This table now reports current applicability; historical detail
remains in the dated ledger. Run in order after the blockers are corrected. A later
code change invalidates earlier build, determinism, browser, and manifest evidence.

| Order | Gate | Status | Date | Generation / evidence |
|---:|---|---|---|---|
| 1 | Worktree ownership | PASS | 2026-07-18 | Clean synchronized `master`; PR release branch deleted remotely; no rebuild process, conflicting editor, or unrelated worktree change remains. |
| 2 | Static syntax | PASS | 2026-07-17 | 22 R files parsed as UTF-8; `node --check`; both Python files compiled in memory; Python fixtures passed. |
| 3 | Workflow policy | PASS | 2026-07-18 | Both YAML files safe-loaded; all 13 final `uses:` values are full lowercase 40-hex pins; receipt self-test passed; the temporary diagnostic upload is removed. |
| 4 | Text hygiene | PASS | 2026-07-18 | Release and closeout documentation pass `git diff --check` plus strict UTF-8/LF/no-BOM checks; no repository bytecode, lock, stage, backup, pending, temp config, or credential residue. |
| 5 | Authoritative build | PASS | 2026-07-18 | Diagnostic-free head `526dd3b` passed twice in run `29644970791`; final PR head `0806732` passed run `29646272806`; merged master `430b0b0` passed run `29646451583`, including all nine stages, exact scientific bytes, semantic manifest, and whitespace. |
| 6 | Independent live-root checks | PASS | 2026-07-17 | Promoted family passed the complete seven-source oracle, manifest verification/comparison, Python publisher fixtures, boot integrity, app smoke, and workflow receipt fixtures. |
| 7 | Determinism | PASS | 2026-07-18 | Two independent fresh attempts of run `29644970791` on unchanged head `526dd3b` loaded the pinned Haswell/one-thread runtime and reproduced exact artifact bytes plus manifest semantics. |
| 8 | Pre-promotion failure safety | PASS | 2026-07-17 | Historical controller test passed; current Windows stage-5 failure also began no promotion and left all five hashes unchanged. |
| 9 | Promotion rollback safety | PASS | 2026-07-17 | Historical controller test restored exact prior bytes/hashes 5/5; promotion controller code has not changed. |
| 10 | Writer capability guard | PASS | 2026-07-17 | All four direct writers rejected missing generation capability; SHA-256 for all five live release files remained unchanged. |
| 11 | Browser QA | PASS | 2026-07-18 | Historical interactive app QA remains valid; deployed Pages cover passed at desktop 1265x720 and mobile 390x844 with stable zero overflow, correct canonical/OG/Twitter data, 1734x907 social asset, no console warning/error, and 12/12 unique public HTTP links returning 200. |
| 12 | Final state | PASS | 2026-07-18 | PR #4 merged as `430b0b0`; master CI and Pages build passed; repository description/homepage and the public cover/share card are live and verified. |

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
| all five core `description.Remote*` fields absent | Valid only for independently trusted `description.Repository=CRAN`; `RSPM` requires the complete exact core and pinned snapshot. Partial/null-named/rogue fields always fail. |
| staged contract, manifest, boot, or smoke stage fails | No promotion should occur. Prove live hashes unchanged and record the exact stage/message. |
| ordinary promotion fails | Rollback should restore all five prior files. Prove exact hashes and cleanup; stop if any mismatch remains. |
| power loss/hard kill during promotion | Treat live family as suspect even if files exist. Runtime guard should refuse mixed bytes. Rerun the full rebuild before use. |
| direct artifact writer refuses to run | Expected generation-capability protection; use `rebuild_all.R`. |
| post-rebuild generated-file diff | Current release fails exact reproducibility even if staged science/boot checks pass. Do not weaken the gate or promote ad hoc; compare candidate semantics/serialization only through an explicitly approved diagnostic transfer, fix the cause, then rerun. |
| `partial standard CRAN provenance: DT` | A core provenance field is missing or malformed. Keep the five-field all-or-none rule; `RemotePkgPlatform` alone is optional only beside a complete valid core. Repair generation/environment metadata and rerun. |

## Residual risks currently carried

- The retained isolated diagnostic bundle under `C:\tmp` is non-authoritative and
  outside the repository. It is no longer needed for scientific evidence and may be
  removed after release without touching the canonical repository family.
- The dated Posit Package Manager URL and strict provenance validation do not
  archive or independently content-hash every upstream package tarball.
- Five separate filesystem entries cannot be indivisibly atomic across hard power
  loss. Manifest-last promotion and the 12-file boot checksum guard make a mixed
  generation refuse to boot; recovery is still a complete rebuild.
- The process starts with invalid `C.UTF-8` environment settings on this Windows
  host. Runtime activation of `English_United States.utf8` is tested and required,
  but bypassing the supported runtime/helper path can reintroduce corruption.
- Browser coverage is finite. Historical app QA covered the principal desktop/mobile,
  interaction, plot, Unicode, and accessibility paths; the public Pages cover and
  share card now also have deployed desktop/mobile, console, asset, and link evidence.
  Future browser/host changes still require a fresh stable-state check.
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
- For suite-relevant work, update
  `docs/NEON-SUITE-LEARNING-LOOP.md` in the same session, including the evidence
  register and Driver implication backlog. The app-local handoff remains the
  detailed evidence source; chat history is not durable evidence.
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

### 2026-07-17 16:28 MST - suite learning continuity and release-state reconciliation / root, with two read-only audits

- **Changed:** added `docs/NEON-SUITE-LEARNING-LOOP.md` as the central ten-app
  evidence/Driver-feedback register; required suite continuity in `AGENTS.md`; and
  updated `docs/neonize-playbook.md` so each app pass emits durable local and central
  evidence, integrates Driver only after nine pinned app passes, and uses
  network-independent font/boot assets. Corrected this handoff's stale release claim
  and exposed, without resolving, the current manifest-policy contradiction.
- **Learned:** useful suite memory needs both an exact app-local test receipt and a
  compact cross-product decision package. Driver should receive definitions,
  support, effort/zero rules, joins, mechanisms, and claim limits—not UI headlines.
  Driver parity failures must flow back to the owning app. The WindowsApps
  PowerShell launcher can be blocked by endpoint security while the explicit system
  PowerShell path works. Locale rewriting, RSPM/platform provenance, and the older
  canonical manifest contract cannot safely be cloned across the suite until they
  are reconciled together.
- **Test process:** documentation-only scope in
  `D:\Git\NEON-Driver-Cascade`; started from branch `3700c34` with only the new
  suite loop untracked. Read the complete handoff and playbook, reviewed branch
  history/current five-file hashes, and used independent read-only science/process
  and handoff-reconciliation audits. Ran `git diff --check`; strict UTF-8 decode,
  BOM/control/trailing-whitespace/fence checks on all four edited documents;
  missing-heading-spacing and stale-policy scans; required-text/link/lock checks;
  and exact SHA-256 verification of all five live artifacts. Expected result PASS;
  actual result PASS. The changed-file scope is exactly these four documents, no R
  process or rebuild lock remains, and no product/artifact bytes changed.
- **Evidence invalidated:** none by these documentation-only changes. Earlier
  generation evidence was already invalidated by writer/policy/search-builder
  commits through `3700c34`; this edit makes that state explicit.
- **Artifacts:** no generation or promotion ran. The live family remains cascade
  `5453e448…`, search `1e3449cf…`, meta `7e1aef4f…`, codebook
  `a79cc754…`, manifest `b1851e53…`.
- **Failure/cleanup:** the latest Linux exact-byte gate remains failed for
  search/meta; the local exact-snapshot run remains failed closed at stage 5 for DT
  provenance. No current R rebuild process or owned lock/stage/backup/pending
  residue remains. No temporary failed-run artifact upload was added or performed.
- **Residual risk:** PR #4 remains red; manifest semantics and cross-platform
  artifact bytes remain unresolved; merge, metadata,
  Pages publication, and public verification remain not run. Temporary diagnostic
  transfer of failed-run Linux artifacts still requires explicit owner approval.
- **Next action:** validate and commit/push these documentation changes to PR #4,
  then—with explicit owner approval—retrieve the unmodified Linux artifacts for
  semantic/serialization diagnosis without changing the existing gates.

### 2026-07-17 16:44 MST - post-push CI evidence reconciliation / root

- **Changed:** updated only this handoff's current-state and completion-matrix text
  after the documentation push produced newer CI evidence. No application, build,
  workflow, test, manifest-policy, or generated artifact file changed.
- **Learned:** explicit search collation did not solve reproducibility, and the
  differing set is not stable across the last two runs. At head `e906497`, all
  three RDS files differed and only the CSV codebook matched. That makes
  search-ordering alone insufficient and does not prove either serialization or a
  semantic difference. Candidate inspection is required before proposing a fix.
- **Test process:** followed the installed GitHub CI-fix workflow: verified existing
  `gh` authentication, then ran its `inspect_pr_checks.py --repo . --pr 4 --json`
  inspector against GitHub Actions run
  [29621153262](https://github.com/tgilbert14/NEON-Driver-Cascade/actions/runs/29621153262),
  job `rebuild-contracts`, head `e906497924d9dc2d02beb160870f78179dadea0f`.
  Expected result was a precise failed-step/log receipt; actual result confirmed all
  nine build stages and every source/science/manifest/boot/smoke contract passed,
  then exact Git diff failed for `cascade.rds`, `search_index.rds`, and
  `cascade_meta.rds`; the codebook did not differ. The later semantic-manifest
  gate was not reached. After this entry, strict UTF-8/control/final-LF,
  trailing-whitespace, ledger-spacing, required-evidence, exact five-hash,
  rebuild-lock, and `git diff --check` gates all passed.
- **Evidence invalidated:** the prior top-level statement that the latest run differed
  only for search/meta and matched cascade. The dated 16:28 entry remains an accurate
  record of evidence available before run 29621153262 completed.
- **Artifacts:** the CI candidate was promoted only inside its ephemeral workspace,
  then runner cleanup removed it. No candidate was uploaded, retained, downloaded,
  committed, or promoted locally. The five local live hashes remain unchanged.
- **Failure/cleanup:** GitHub failed only at the exact committed-artifact comparison
  after a complete validated build. Runner post-job cleanup completed. Locally,
  there is no rebuild lock or R process and no generated file changed.
- **Residual risk:** without the candidate RDS files, semantic versus serialization
  differences cannot be separated. The distinct manifest-policy conflict also
  remains unresolved, and PR #4 cannot be merged.
- **Next action:** obtain explicit owner approval for a temporary, SHA-pinned
  failed-run artifact upload, inspect the three RDS candidates against the committed
  family, remove the diagnostic step, and propose a focused fix without weakening
  any existing gate.

### 2026-07-17 18:31 MST - approved Linux artifact diagnosis and policy stop / root, with two read-only audits

- **Changed:** temporarily added the owner-approved SHA-pinned failed-run upload in
  `c3863b5`, retrieved exactly three RDS files plus `manifest.json`, then restored
  the original workflow in `4676233`. The final branch workflow is unchanged from
  its pre-diagnostic form. No generated artifact remains changed, staged, committed,
  or live. This handoff and the central suite loop alone record the new evidence.
- **Learned:** the three RDS diffs are one causal chain. Ubuntu changes the RDS
  native-encoding header and last bits from platform-sensitive OLS/QR, correlation,
  and `metafor` arithmetic; search and meta then embed the changed cascade MD5.
  Counting derived fingerprint carriers as independent drift exaggerates the failure.
  A suite app must declare a canonical release-byte platform or prove cross-platform
  bytes, while other-platform tests separately protect schema, keys, text, support,
  signs, decisions, and bounded full-precision deltas. The Linux package graph is
  version/dependency-equivalent but its truthful `RSPM`/platform provenance conflicts
  with the older written `CRAN`-only/untouched-manifest contract.
- **Test process:** GitHub run `29622897425` passed all nine build stages, source
  locks, artifact/science contracts, manifest checks, malformed-generation tests,
  and app smoke before the exact-byte gate failed; its diagnostic upload succeeded.
  Run `29623201989` at cleanup head `4676233` reproduced that sequence without the
  upload. Locally under R 4.5.2, complete SHA-256/MD5/size capture, `infoRDS`,
  decompressed-payload comparison, strict recursive identity, same-process v2/v3
  serialization, known-key sequence audits, character-byte/encoding-mark checks,
  hexadecimal numeric deltas, and MD5-sentinel diagnosis isolated the exact fields
  and counts in the current-state block. The Linux manifest passed current policy,
  all 12 mapped checksums, all 73 exact runtime package versions, and manifest
  fixtures. Candidate boot integrity passed 12 malformed/mutated fixtures and six
  promotion cuts; app smoke passed with 510 annual rows and 12 associations. The
  Windows raw-source suite passed through every preceding oracle, then failed only
  when exact Windows recomputation reached the Ubuntu additive green-up values.
- **Evidence invalidated:** the prior statement that the cause was unknown, that no
  Linux candidate had been retained for inspection, and that owner approval was not
  recorded. No historical scientific conclusion or local Windows hash receipt is
  invalidated; they remain platform-specific evidence.
- **Artifacts:** isolated Ubuntu SHA-256 values are cascade `47b98e48…`, search
  `a11a072d…`, meta `00120c52…`, unchanged codebook `a79cc754…`, and manifest
  `92b46277…`. The worktree was restored to cascade `5453e448…`, search
  `1e3449cf…`, meta `7e1aef4f…`, codebook `a79cc754…`, and manifest `b1851e53…`.
- **Failure/cleanup:** the temporary upload was removed and pushed; the artifact
  expires after one day. The experimental live-root copy was restored from immutable
  `HEAD` and all four restored SHA-256 values were asserted. Session-scoped Git
  configuration was removed. No rebuild lock or R process remains. Bitdefender
  blocked the normal patch helper, so exact assertion-guarded UTF-8/LF replacements
  were used only after the helper failed.
- **Residual risk:** PR #4 remains red and unmerged. Accepting Ubuntu bytes requires
  an explicit release-platform decision and an atomic resolution of the manifest
  contract (`CRAN`/trusted `RSPM`, optional platform metadata, locale normalization,
  comparator fixtures, and cross-platform matrix meaning). Metadata, Pages, and
  public cover verification remain pending.
- **Next action:** obtain the owner's explicit policy choice. Recommended: designate
  Ubuntu 24.04/R 4.5.2 plus the pinned Posit snapshot as the release-byte platform;
  keep the exact Ubuntu byte gate; keep Windows structural/raw-source/decision tests
  with diagnostic numeric deltas; formally validate and semantically normalize the
  two trusted standard-CRAN provenance representations; then promote the already
  validated Linux family, rerun unchanged CI, and merge only when green.

### 2026-07-17 22:24 MST - canonical Ubuntu release implementation / root

- **Changed:** adopted Ubuntu 24.04/R 4.5.2 with the pinned 2026-07-15
  Posit snapshot as the release-byte authority; promoted the validated three-RDS
  family plus its manifest as one hash-checked unit with manifest last; split the
  five core provenance fields from optional exact `RemotePkgPlatform`; required
  pinned explicit RSPM provenance; normalized CRAN/RSPM only after independent
  validation; hardened locale normalization to one allowlisted root field; mirrored
  policy and adversarial fixtures in the independent Python publisher; limited the
  Windows raw-source diagnostic to `greenup_doy_additive <= 1e-12`; and aligned
  monthly refresh dependencies/cleanliness with CI. Updated README, DEPLOY, suite
  learning, and the reusable playbook, including removal of moving-head,
  `continue-on-error`, and implicit manifest-glob guidance.
- **Learned:** the release contract must separate canonical byte reproducibility
  from strict cross-platform scientific portability. Manifest labels are never
  normalized as a shortcut: canonical RSPM requires the exact dated repository and
  optional platform tuple, and the R and Python trust boundaries must move together.
  This is a reusable suite-platform pattern with Driver implication `NONE`.
- **Test process:** under pinned R 4.5.2 and `R_LIBS=C:/tmp/cascade-r-lib`,
  `verify_manifest.R` passed 73 packages/12 files; R comparator and Python publisher
  adversarial fixtures passed; the complete seven-repository `test_helpers.R` oracle
  passed 510 annual rows/46 sites/552 links and all raw-product overlays. The formerly
  failing phenology check passed 345 site-years with ten strict fields at `1e-15`
  and additive maximum delta `1.847e-13 <= 1e-12`. Boot integrity passed 12 malformed/
  mutated fixtures and six promotion cuts; app smoke passed 510 rows/12 associations;
  receipt fixtures, both workflow YAML/pin reviews, JavaScript syntax, R/Python
  parse checks, and `git diff --check` passed. All four direct writers rejected a
  missing generation capability with all five live SHA-256 values unchanged.
  Three independent read-only reviews found no release-blocking implementation,
  workflow, publisher, or Pages defect.
- **Artifacts:** current canonical SHA-256 values are cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, unchanged
  codebook `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Expected versus actual:** expected the approved Ubuntu family to preserve every
  schema, source, support, key, text, sign, sensitivity, and decision contract while
  passing bounded Windows diagnosis; actual matched. No rounding or scientific gate
  relaxation occurred.
- **Evidence invalidated:** the canonical sections that called the platform/provenance
  choice unresolved, the Linux family unaccepted, and the Windows family current are
  superseded. Historical dated diagnostic and Windows-build records remain factual.
- **Failure/cleanup:** Bitdefender repeatedly blocked the normal patch helper and one
  read-only launcher approval stalled for roughly two hours; exact one-occurrence
  UTF-8/LF/no-BOM replacements were used only after helper failure. Session-owned Git
  config/ignore files were removed; no rebuild lock, R process, stage, backup, pending
  file, bytecode, or credential residue remains.
- **Residual risk:** the remote PR still points to old red head `33653cf`. Fresh
  canonical Ubuntu CI must pass the unchanged exact-byte and semantic-manifest gates
  before merge. Master CI, repository metadata, Pages deployment, and final public
  desktop/mobile console/network/share-card QA remain pending.
- **Next action:** commit and push this complete family, require fresh PR CI green,
  merge PR #4, synchronize `master`, patch repository description/homepage, wait for
  master CI and Pages, then verify the public cover and social asset.

### 2026-07-17 22:39 MST - exact rsconnect locale-token correction / root

- **Changed:** narrowed the manifest source-locale allowlist to exact rsconnect
  output tokens `en_US` and `C`; updated positive/negative/nested locale fixtures
  and canonical handoff wording. Artifact and manifest bytes are unchanged.
- **Learned:** rsconnect 1.10.1 `detectLocale()` splits non-Windows `LC_CTYPE` at
  the dot, so runner environment `C.UTF-8` is serialized as root token `C`. The
  earlier ledger named the environment locale rather than the emitted JSON token.
- **Test process:** GitHub run `29632368165` passed setup, dependency install,
  committed-snapshot validation, source lock, all seven detached fetches, build
  stages 1-4, and the complete raw-source/scientific contract suite; it failed
  closed only at stage 5 with `generated manifest source locale is missing or
  unapproved`. Inspected the installed rsconnect namespace to prove the exact
  derivation, then reran pinned-R parsing, the complete R locale/provenance
  adversarial matrix, and `git diff --check`; all passed.
- **Expected versus actual:** expected strict normalization to expose any unmodeled
  source token; actual did. The correction admits only the exact deterministic
  token that rsconnect derives from the pinned runner locale.
- **Evidence invalidated:** only the three-token source allowlist and the statement
  that rsconnect serialized the full `C.UTF-8` string. All scientific, artifact,
  provenance, package, checksum, boot, and local validation evidence remains valid.
- **Failure/cleanup:** CI failed before manifest completion or promotion. No local
  generation ran; no lock, stage, backup, pending file, or artifact hash changed.
- **Residual risk/next action:** push the exact-token correction and require a fresh
  unchanged Ubuntu run to pass stages 5-9 plus both final byte/manifest gates.

### 2026-07-17 23:07 MST - hosted-runner numeric determinism diagnosis / root, with two read-only audits

- **Changed:** kept the exact artifact gate unchanged; pinned `OPENBLAS_CORETYPE=Haswell`,
  `OPENBLAS_NUM_THREADS=1`, and `OMP_NUM_THREADS=1` in both CI and refresh; added a
  fail-closed standard-library `ctypes` check of the loaded OpenBLAS core and actual
  thread count to CI plus both refresh R jobs; and temporarily restored the SHA-pinned
  one-day fail-only upload of three RDS candidates plus manifest after an exact-byte
  failure. No scientific code, comparator tolerance, generated artifact, or manifest
  policy changed.
- **Learned:** canonical OS, R, snapshot, package versions, source commits, and writer
  code are not a complete byte platform when a DYNAMIC_ARCH BLAS selects kernels
  from the physical hosted-runner CPU. The prior and current runs matched all those
  declared inputs yet emitted different RDS bytes. Generation audit found no
  wall-clock/temp metadata, nonzero gzip MTIME, RNG/order drift, or repeat-save
  instability. Host-specific OpenBLAS kernel/thread selection is therefore the one
  remaining focused causal hypothesis; it is not recorded as proved until fresh
  runner evidence passes.
- **Test process:** inspected failed GitHub run `29632690022` and compared it with
  candidate-producing run `29622897425`; both used runner image
  `ubuntu-24.04/20260714.240.1`, R 4.5.2, OpenBLAS 0.3.26/LAPACK 3.12.0, the same
  package cache and seven source commits, and unchanged RDS-generating code. Upstream
  OpenBLAS documentation confirmed `OPENBLAS_CORETYPE` kernel selection and one-thread
  controls. Locally, both workflow files safe-loaded, all 14 temporary `uses:` entries
  were full 40-hex pins, `git diff --check` passed, and the workflow receipt guard
  passed after adding the documented Git `sha256sum` directory to `PATH`. Expected
  remote result is either exact match or a retained pinned-runtime candidate; actual
  remote result is not yet available.
- **Evidence invalidated:** the claim that one promoted hosted-Ubuntu candidate family
  alone proved reproducibility for the whole canonical platform. Its science,
  provenance, boot, smoke, and Windows-oracle evidence remains valid.
- **Artifacts:** no local generation or promotion ran. The five live SHA-256 values
  remain cascade `47b98e48...`, search `a11a072d...`, meta `00120c52...`, codebook
  `a79cc754...`, and manifest `92b46277...`.
- **Failure/cleanup:** run `29632690022` failed only at exact artifact bytes after
  complete validation and did not retain candidates. Semantic-manifest and whitespace
  steps skipped by fail-fast. Locally no rebuild lock, stage, backup, pending file,
  or artifact changed. Bitdefender blocked the patch helper; exact one-occurrence
  UTF-8/LF/no-BOM replacements were used through the explicit system PowerShell.
- **Residual risk:** `Haswell` is an upstream-documented override and is expected on
  hosted x64 runners, but compatibility and byte stability are unproved here. The
  temporary diagnostic must not survive release.
- **Next action:** commit/push the focused experiment. If bytes differ, download and
  compare the retained candidate family, promote only a fully validated pinned-runtime
  family, remove the upload, and require two independent exact-byte plus semantic-
  manifest passes before merge, metadata, Pages, and public QA.

### 2026-07-18 05:36 MST - first pinned-runtime exact pass and diagnostic removal / root

- **Changed:** removed the temporary fail-only candidate upload and its step ID after
  the first pinned-runtime run passed, returning CI to 13 immutable action uses. Kept
  the loaded OpenBLAS core/thread assertions in CI and both refresh R jobs. No science,
  tolerance, generated artifact, manifest policy, or release hash changed.
- **Learned:** the fixed numeric runtime reproduced the already-promoted family
  exactly, while the immediately preceding unpinned runner did not. This converts
  host-specific OpenBLAS dispatch/threading from the leading hypothesis into the
  supported missing platform dimension. The runtime receipt, not environment text
  alone, is the reusable fail-closed gate.
- **Test process:** GitHub run `29644372306`, job `88080017215`, on exact head
  `8ca35a22d28544fbd5686efd7588695b80465e88` reported
  `OpenBLAS core=Haswell threads=1 config=OpenBLAS 0.3.26 NO_LAPACKE DYNAMIC_ARCH
  NO_AFFINITY Haswell MAX_THREADS=64`. It passed setup, dependencies, source lock,
  seven detached fetches, the complete nine-stage rebuild, all raw-source/scientific
  contracts, exact committed artifact bytes, semantic manifest, and whitespace.
  The diagnostic step skipped; GitHub reported zero run artifacts.
- **Expected versus actual:** expected either an exact match or a retained candidate;
  actual was an exact match, so no candidate transfer or promotion was needed.
- **Evidence invalidated:** the prior statement that Haswell/one-thread had not yet
  passed. Historical evidence about the unpinned failure remains factual.
- **Artifacts:** unchanged at cascade `47b98e48...`, search `a11a072d...`, meta
  `00120c52...`, codebook `a79cc754...`, and manifest `92b46277...`.
- **Failure/cleanup:** no run artifact exists to expire or delete. The diagnostic
  workflow block is removed locally. No rebuild lock, stage, backup, pending file,
  or generated artifact changed.
- **Residual risk:** one successful pinned run is not the final unchanged release
  head and is not enough to prove repeatability across fresh runners.
- **Next action:** commit/push the diagnostic-free workflow and updated durable
  evidence, require that final head to pass all gates, rerun that same final head on
  a second independent runner, then merge only if both are green.

### 2026-07-18 06:25 MST - two clean pinned-runtime passes complete / root

- **Changed/classification:** documentation only. Recorded the completed deterministic
  proof in the handoff and suite register. Classification is `suite-platform`;
  Driver implication is explicitly `NONE`. No product definition, estimator, data
  contract, QC rule, science, workflow, generated artifact, or manifest changed.
- **Learned:** reproducible RDS bytes require the effective numeric runtime to be
  part of the release platform. Pinning the BLAS core and thread count and then
  verifying the loaded library state fail-closed is sufficient here: two fresh
  runners reproduced the same canonical family without rounding or relaxed gates.
- **Test process/environment:** GitHub Actions run `29644970791` on exact PR head
  `526dd3bb2b9f6ad7170bd0af54bf25753ed6e3dd` passed attempt 1/job `88081588746`
  and attempt 2/job `88083964830`. Both used Ubuntu 24.04, R 4.5.2, the pinned
  2026-07-15 Posit snapshot, OpenBLAS 0.3.26 with loaded Haswell core and one
  thread, all seven detached pinned sources, and the supported nine-stage rebuild.
  Both passed source locks, every raw-source/scientific contract, manifest
  verification (73 packages/12 files), runtime integrity (12 malformed/mutated
  fixtures and six promotion cuts), app smoke (510 rows/12 associations), exact
  committed scientific bytes, semantic manifest comparison, and whitespace. The
  second exact runtime receipt was `OpenBLAS core=Haswell threads=1 config=OpenBLAS
  0.3.26 NO_LAPACKE DYNAMIC_ARCH NO_AFFINITY Haswell MAX_THREADS=64`.
- **Expected versus actual:** expected two independent diagnostic-free runs on the
  unchanged code/workflow head to reproduce exact bytes and manifest semantics;
  both did. GitHub reports zero retained artifacts.
- **Evidence invalidated:** the prior `pass 1` and `double-run pending` status is
  superseded. The historical unpinned failure and first pinned experiment remain
  factual diagnostic evidence.
- **Artifacts/non-impact:** unchanged at cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Failure/cleanup:** neither clean attempt failed or retained a diagnostic artifact;
  no rebuild lock, stage, backup, pending file, or generated artifact changed.
- **Residual risk:** the evidence-only final PR head still needs one green CI run;
  merge, repository metadata, Pages deployment, and public desktop/mobile
  cover/share-card plus console/network QA remain pending.
- **Next action:** commit and push this evidence-only update, require its full CI to
  pass, merge PR #4, update repository metadata, then verify the deployed Pages
  root and social image in desktop/mobile browser sessions.

### 2026-07-18 06:43 MST - merged release and public baseline closeout / root

- **Changed/classification:** merged fully green PR #4 into `master` as
  `430b0b03642fb9aa42e71de5118b460094d5a20a`, deleted the remote release branch,
  updated the GitHub description and homepage, and verified the deployed Pages
  cover/share card. This closeout changes only documentation. Classification is
  `suite-platform`; ecological Driver implication is explicitly `NONE`.
- **Learned:** publication has three identities that must agree: the green PR head,
  the merge commit, and the Pages-deployed commit. Record and verify all three.
  Responsive automation must also distinguish the immediate viewport-transition
  frame from steady state: reload or remeasure, require stable geometry, and block
  release on persistent overflow rather than accepting either a transient pass or
  a transient failure. Reuse this deployment/browser receipt for all nine apps.
- **Test process/environment:** final PR head
  `080673257edcc320c8a811d4bd481eb17279ebfe` passed GitHub Actions run
  `29646272806`, job `88084946603`; post-merge master
  `430b0b03642fb9aa42e71de5118b460094d5a20a` passed run `29646451583`, job
  `88085414025`. Each loaded OpenBLAS 0.3.26 Haswell with one thread and passed
  all seven detached source fetches, the nine-stage build, source/scientific
  contracts, 73-package/12-file manifest verification, 12 malformed/mutated boot
  fixtures, six promotion cuts, 510-row/12-association app smoke, exact committed
  scientific bytes, semantic manifest comparison, and whitespace. Pages API
  reported `built` for `430b0b0`; deployment workflow `29646450942` targeted that
  same commit.
- **Public browser/network result:** the live root
  `https://tgilbert14.github.io/NEON-Driver-Cascade/` rendered the expected title,
  accessible hierarchy, launch/GitHub controls, nine-sibling suite registry,
  canonical URL, Open Graph fields, and Twitter large-image fields. Desktop
  1265x720 and mobile 390x844 stable-state layouts had no horizontal overflow and
  no console warning/error. The social image loaded at 1734x907 and matched local
  SHA-256 `8bef6bd8462b9606c7de1c718ca6c1778f7ce84fc57f72c2c9ed741135a6fee1`.
  The hosted app, repository, nine sibling pages, and CC license were 12/12 HTTP
  200 responses.
- **Expected versus actual:** expected the final evidence head, merge commit,
  master build, Pages commit, metadata, public cover, social asset, and all links
  to agree; actual matched.
- **Evidence invalidated:** all prior `merge/metadata/Pages/public QA pending`
  statements are superseded. Historical failed-run diagnostics remain factual.
- **Artifacts/non-impact:** no generation ran in this closeout. The canonical
  SHA-256 family remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Failure/cleanup:** Bitdefender continued to deny the sandboxed WindowsApps
  launcher and image helper; the already-approved explicit system PowerShell path
  completed all repository/GitHub work. The browser backend did not support a
  `networkidle` wait, so the supported `load` state was used. The first immediate
  mobile viewport sample reported transitional 608-pixel scroll width; repeated
  root/body geometry plus a full mobile reload produced stable 375/375 width,
  correct screenshots, and zero overflow. No repository artifact, lock, stage,
  backup, pending file, credential, or diagnostic run artifact changed.
- **Residual risk:** upstream package tarballs remain unarchived, five-file hard
  power-loss atomicity is impossible, browser coverage remains finite, and the
  isolated `C:\tmp` diagnostic bundle is optional non-authoritative cleanup.
- **Next action:** publish this documentation-only closeout and require its
  no-product-impact CI/Pages update to pass, then begin suite pass 1 (Small Mammal
  Tracker) using the recorded one-app learning cycle. Do not reintegrate Driver v2
  until all nine pinned knowledge packages and the complementary-product decision
  are complete.

### 2026-07-18 - complementary-app gap audit (planning / documentation-only) / root

- **Changed:** added `docs/COMPLEMENTARY-APP-GAP-AUDIT.md` (the ranked pass-10
  decision-support audit); updated `docs/NEON-SUITE-LEARNING-LOOP.md` pass-10
  register row and appended 11 Driver-implication backlog rows. No code, artifact,
  data bundle, manifest, scientific pin, or workflow changed.
- **Learned:** the "add more apps?" question already has a suite gate (learning-loop
  pass 10) and pre-named candidates (discharge/water-temp/periphyton/fish). A live
  NEON Data Product Catalog sweep confirms the roadmap's four and adds a terrestrial
  producer/ANPP candidate (litterfall `DP1.10033.001` + clip-harvest
  `DP1.10023.001`) as the only non-aquatic complement that repairs the "atlas not
  cascade" construct demotion on a system with data. Adversarial refutation deflated
  several over-claims: discharge's marquee land-vs-water headline is unreachable on
  arrival (SYCA≈1-site under `min_sites=3`); ticks are a conditional double-acquisition,
  not "buildable now/46-46"; a met "climate-driver app", soil-moisture, and AOP
  greenness do not survive as near-term builds (REJECT-framing/HOLD/CONTEXT). DPID
  corrections captured: `DP1.20108.001` is a phantom (fish per-pass lives in
  `DP1.20107.001`); `DP1.00044.001` is now primary precip; no NEON root-ingrowth
  product; NEON does not band birds.
- **Test process:** cwd `/home/user/NEON-Driver-Cascade`; branch
  `claude/neon-suite-expansion-c0wl9k`. Research via a background workflow (29
  subagents, 0 errors) fanning out the live neonscience.org catalog by domain +
  repo-constraint synthesis, then per-candidate 6-question intake and adversarial
  refutation. No build/test gate was run because no product or artifact changed;
  documentation edits target `git diff --check` / UTF-8 / LF cleanliness only.
- **Evidence invalidated:** none. All release/build/determinism/browser/manifest
  gates from the 2026-07-18 closeout remain valid; this is additive documentation.
- **Artifacts:** unchanged. Canonical SHA-256 family (cascade
  `47b98e48…f3fe`, search `a11a072d…4f0e`, meta `00120c52…d14e`, codebook
  `a79cc754…8ca3`, manifest `92b46277…441e`) is untouched; docs are not in the
  runtime manifest allowlist and the app never sources them, so no rebuild is
  required.
- **Failure/cleanup:** none; no lock, stage, backup, pending, or credential residue.
- **Residual risk:** the audit is a decision input, not a decision — the formal
  `COMPLEMENT` build/defer call still requires the nine app passes and Driver v2
  synthesis. Candidate join/overlap counts (gauged-stream×invert, grassland
  clip×mammal, tick 46/46) are asserted from the roadmap and catalog and must be
  measured before any build.
- **Next action:** owner review of the ranked backlog; begin suite pass 1 (Small
  Mammal Tracker). Re-run the 6-question intake with measured match rates when any
  Tier-A candidate is actually scheduled.

### 2026-07-18 07:24 MST - suite deep audit and executable revamp program / root

- **Changed/classification:** added `docs/NEON-SUITE-REVAMP-PLAN.md`, updated the
  suite register with the observed companion baseline and a Phase 0 release-health
  gate, reordered Phenology before Plant Diversity for Driver leverage, and
  modernized the playbook's authority, evidence loop, release permissions, registry,
  and non-memory wording. Classification is `suite-platform`; ecological Driver
  implication is explicitly `NONE`. No Driver app code, scientific definition,
  source lock, workflow, generated artifact, or manifest changed.
- **Starting state:** clean Driver `master` at
  `b62b52998fb2`; all nine companion default branches cloned at their published
  heads. Ground Beetle showed only a known checkout line-ending normalization in
  `data-sample/beetle_demo.csv` (`git diff --ignore-space-at-eol --quiet` passed);
  no companion content was edited.
- **Repository/static audit:** all nine companions have `manifest.json`, a Pages
  cover, and a bundled search index, but none has `AGENTS.md` or
  `docs/BUILD-TEST-HANDOFF.md`. Birds, Plant Diversity, Phenology, and Vegetation
  Structure each have one helper test; Mammals, Beetles, Mosquitoes, Water
  Chemistry, and Inverts have none. Current tracked runtime files disagree with
  manifest MD5 entries in Birds 8, Beetles 8, Mosquitoes 7, Inverts 9, Plant
  Diversity 13, Phenology 8, Mammals 10, Vegetation Structure 8, and Water
  Chemistry 3. Driver remained coherent at 12/12 files.
- **Public browser result:** all ten GitHub Pages covers rendered their cohesive
  constellation/mascot design without persistent desktop horizontal overflow.
  Direct app startup succeeded for Driver, Plant Diversity, Phenology, Vegetation
  Structure, Mosquitoes, Birds, Water Chemistry, and Inverts. Small Mammal Tracker
  and Ground Beetle Tracker each rendered the Posit `Startup Error` page after
  reload. Therefore the earlier 12/12 HTTP result is still factual for URLs but is
  invalid as evidence that every hosted app is semantically healthy.
- **Science/data review:** the new companion process is fundamentally sound: one
  app at a time, pinned knowledge packages, gap audit, optional complementary app,
  then Driver v2. The audit added the missing emergency release gate. It also found
  a source/Driver parity failure: Mammal's current row-level effort shortcut does
  not implement Driver's reviewed physical trap-event resolver. Beetle effort
  remains catch-event-conditioned because zero-carabid opportunities are absent.
  Existing review documents are not current-status records; Water Chemistry code
  already implements several findings its review still describes as open.
- **Cover/social review:** preserve the current visual identity rather than replace
  it. Generate covers/in-app relationship panels from one versioned suite registry;
  use product-specific habitat imagery only as an attributed/provenance-stamped
  enhancement. Mosquitoes and Inverts reference an uncommitted `og-image.png`,
  Water Chemistry lacks a Twitter image declaration, and Beetle's site-health copy
  exceeds the product's supported claim.
- **Test process/environment:** read the complete Driver handoff, suite loop,
  playbook, roadmap, all companion inventories, current review/takeaway evidence,
  workflows, manifest maps, and relevant helper/transform code; inspected public
  covers and live startup state in the in-app browser; compared every tracked
  companion manifest file checksum to current bytes; ran `git diff --check` after
  the documentation edits. No local R runtime is installed (`Rscript` unavailable),
  so no R unit, boot, bundle, or manifest-generation test is claimed.
- **Expected versus actual:** expected a mostly finished visual suite with
  app-specific scientific cleanup; actual visual cohesion is strong, but release
  trust is materially behind Driver and two public apps are down. The one-app
  learning loop remains the right architecture after inserting Phase 0 and moving
  the strongest ecological hinge earlier.
- **Evidence invalidated:** "public link returned HTTP 200" is no longer sufficient
  public-app verification; a scheduled workflow that exits successfully after its
  date gate is not fresh refresh evidence; expert-review prose alone does not state
  current fix status; the Small Mammal app cannot currently be treated as the
  unquestioned suite quality oracle.
- **Artifacts/non-impact:** canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Failure/cleanup:** `jq` is not installed; the checksum audit was rerun read-only
  with the bundled Node runtime. No rebuild, deploy, public write, workflow dispatch,
  manifest rewrite, lock, stage, backup, pending file, or generated data occurred.
- **Residual risk:** the companion audit is static/browser-level until each app runs
  in a pinned R toolchain. The two startup errors have no public diagnostic log, and
  a stale manifest is a release blocker but not proven to be the sole outage cause.
  Companion workflows remain capable of unsafe publication until Phase 0 lands.
- **Next action:** begin Small Mammal pass 1. Install the app-local governance and
  handoff, capture the last-known-good release identity, add content-aware health and
  manifest/boot gates, port/test the reviewed effort resolver, rebuild only in the
  pinned runtime, restore the public app, and then close its knowledge package before
  starting Phenology.

### 2026-07-18 07:50 MST - Small Mammal pass-1 implementation checkpoint / root

- **Changed/classification:** updated only the Driver suite evidence register and
  implication backlog with the detailed Small Mammal working-tree checkpoint.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting`; the current Driver artifact implication is **NONE / HOLD
  CURRENT BYTES**. No Driver estimator, app code, source lock, workflow, generated
  artifact, or manifest changed.
- **Sibling starting state:** Small Mammal `main` began clean at
  `39dca56c69ef11188333effefd4b2d5bc28948ee` and remains based on that commit with
  uncommitted current-session changes. Its public Connect URL still showed Posit
  `Startup Error`; the committed manifest retained ten known runtime mismatches.
- **Sibling implementation evidence:** installed app-local governance, handoff,
  and Driver knowledge-package scaffolds; ported the Driver-reviewed exact physical
  trap-event resolver; added adversarial pure-helper fixtures; corrected
  outcome-conditioned species effort; made export/codebook grain and fields
  explicit; added exact 46-site/load/schema/index/checksum/package-provenance gates;
  froze CI/refresh R 4.5.2, jammy snapshot `2026-07-15`, Haswell/one thread, and
  immutable official action commits; changed refresh to stage/validate an immutable
  candidate and publish only a review branch/PR; added an app-specific ready marker
  and semantic main-push health workflow.
- **Static test process/result (PASS):** system Ruby 2.6 `YAML.safe_load` parsed all
  three Small Mammal workflows; `bash -n scripts/post_deploy_smoke.sh` passed;
  `git diff --check` passed. The initial unsupported `YAML.load_file(..., aliases:)`
  invocation failed and was replaced by the compatible parser call. No R test is
  included in this PASS.
- **Runtime/publication result (BLOCKED):** the local environment has no R,
  Docker, or Podman. GitHub CLI 2.96.0 is installed, but `gh auth status` reported
  the saved active `tgilbert14` token invalid. Per the publication contract, no
  branch, commit, push, draft PR, Actions run, manifest candidate, merge, refresh,
  or deployment was created. Required recovery is `gh auth login -h github.com`.
- **Expected versus actual:** expected a safe non-watched draft PR to supply the
  missing pinned R evidence; actual static work completed but authentication
  stopped publication before any external write. The public outage therefore
  remains unresolved and the app pass remains open.
- **Artifacts/non-impact:** no Driver generation ran. Canonical SHA-256 values remain
  cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated:** the suite register's Small Mammal `PASS PENDING` and
  `no executable tests` descriptions are superseded by `PASS IN PROGRESS` and
  authored-but-unexecuted fixtures. The baseline outage, committed-manifest drift,
  and lack of green runtime evidence remain factual.
- **Failure/cleanup/ownership:** auth was checked before branch creation or staging;
  nothing needed rollback. Driver documentation changes and Small Mammal code/docs
  changes are owned by this `root` session, uncommitted, and unpublished. No lock,
  stage, backup, pending artifact, production data, or public state changed.
- **Residual risk:** Small Mammal R syntax, fixtures, 46-site raw parity, manifest
  package availability, offline boot, UI funnels/accessibility/mobile behavior,
  Connect build, and semantic health are all unverified. Its current outage cause
  remains unisolated. Suite visual/retheme work intentionally waits behind release
  recovery so design changes do not obscure the diagnostic boundary.
- **Next action:** reauthenticate GitHub CLI, publish only the Small Mammal tranche
  as a draft PR, inspect the pinned CI/manifest evidence, fix failures without
  merging, restore and semantically verify production, complete the UI/cover pass,
  then close its knowledge package before beginning Phenology.

### 2026-07-18 15:36 MST - Small Mammal pass-1 production receipt vendored / root

- **Changed/classification:** superseded the earlier Small Mammal working-tree
  checkpoint with its complete app-local production receipt in the suite register,
  implication backlog, revamp plan, and canonical playbook. Classification is
  `suite-platform`, `scientific-contract`, and `Driver-impacting`; Driver implication
  remains **NONE / HOLD CURRENT BYTES** and learning disposition is **CONTEXT**. This
  documentation tranche does not run generation or change Driver app/data artifacts.
- **Sibling release identity:** Small Mammal documentation closed on `main`
  `957e56cc3af15d62387bfefbd37ee31623ae682b`; the exact Connect runtime remains
  `1615ab4e74fd16a2698de8431acb862d6cc4cebf` because the later merge changed only
  documentation. PR #77 head run `29663525911` passed, then final `main` validation
  `29663599017`, semantic production run `29663599007`, and Pages run `29663598641`
  all completed successfully.
- **Pinned runtime evidence:** exact-head run `29663236510` (job `88129323716`),
  final runtime-main validation `29663335706` (job `88129588478`), semantic run
  `29663335708` (job `88129588525`), and Pages run `29663335341` passed. The
  canonical deployable manifest is R 4.5.2, 91 packages, 117 files, SHA-256
  `f6c4a5ff74053b95e22fac7394f1930d2fe2329663737031b1c32f7a1f70bc54`.
- **Science/data result:** the source app now implements the exact reviewed physical
  trap-event contract: six status tokens, canonical A-J x 1-10 coordinates,
  multi-capture collapse, two exact double-trap markers, explicit placeholder
  uncertainty, and fail-closed ambiguity. Species CPUE uses all reviewed opportunity;
  the dormant `id_uncertain` path is fixed; Compare carries p-hat/mean N-hat and
  suppresses unsupported raw winners; tidy event/capture and monthly
  MNKA/CPUE/N-hat/p-hat exports plus codebook shipped. All 11 scientific fixtures,
  46/46 site bundles, 46/604/604 indexes, and 145-species contract passed. Coverage
  remains material: 49% of 8,200 bouts are single-night/index-only.
- **Product/public result:** Connect Last deployed reported `1615ab4` at 15:23 MST.
  A fresh public session served `ddl-app-ready=small-mammal-tracker-v1`, restored the
  JORN flow (6,093 captures, 2,252 individuals, 21 species, 31,584 reviewed
  trap-nights), exposed no Startup Error and no first-party console warning/error.
  Pages served the reviewed 1200x630 habitat social card, launch/repository controls,
  all nine companion links, and exact 46-site/145-species framing.
- **Reusable learning promoted:** validate installed-package provenance separately
  from Connect's absolute repository/network contract; remove only reviewed
  non-semantic build clocks; treat merge, Connect Last deployed, and public semantic
  health as separate identities; require one-argument Shiny custom-message handlers;
  keep refresh publication behind immutable reviewed candidates; carry effort,
  opportunity, detection, support, units, and NA conventions into UI and exports.
  Small-mammal status weights, trap-coordinate rules, MNKA windows, and closed-capture
  gates remain product-specific and must not be copied as generic suite science.
- **Driver decision/non-impact:** physical-event contract parity is closed, so no
  parity patch is needed in the current Driver. Exact current-source `siteID` x year
  join/support remains **UNKNOWN / HELD**; monsoon precipitation -> next-year CPUE is
  context only, not an inferential vote. No source pin, estimator, source lock,
  generated file, manifest, or Driver artifact byte changed. The separate idea branch
  remained untouched.
- **Artifacts/non-impact:** canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated:** the earlier auth block, unexecuted fixtures, ten-file
  drift, outage, candidate-manifest, republish-pending, and first-party handler-error
  states are superseded. Historical failures remain factual diagnostics.
- **Failure/residual risk:** the production dependency failure on `wk 0.9.5` proved
  that a locally truthful `Repository: CRAN` value was not a usable Connect URL; the
  corrected top-level absolute CRAN lane passed real production resolution. Five
  upstream bootstrap-datepicker language deprecations remain non-blocking. Mobile
  visual QA is unclaimed, although static responsive, focus, reduced-motion, and
  touch-target gates passed.
- **Next action:** publish this documentation-only Driver tranche through review,
  require final branch and `master` checks to pass with the artifact hashes unchanged,
  and only then begin Plant Phenology pass 2. Do not rebuild Driver v2 before all nine
  pinned packages and the complementary-product decision are complete.

### 2026-07-19 10:06 MST - Phenology pass-2 and Plant Diversity pass-3 continuity closeout / root

- **Changed/classification:** reconciled the central suite ledger with the completed
  Phenology and Plant Diversity passes; promoted their science, source, responsive,
  release, and production lessons into the learning loop, revamp plan, and playbook;
  and replaced the superseded cover prescription with an owner-reviewable artistic
  poster brief. Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting`. Both sibling decisions are **HOLD/CONTEXT / NO DRIVER BYTE
  CHANGE**. This tranche changes Driver documentation only; it does not run Driver
  generation or edit Driver app, source, derived-data, manifest, or release bytes.
- **Phenology continuity receipt:** Pass 2 release head `cc0151d` passed workflow
  `29669603912`; merge/Pages/Connect commit `29c0ed1` passed the 46-bundle, 60-file
  runtime, R 4.5.2 / 92-package, Haswell/one-thread, exact-manifest, deterministic-index,
  offline-source, client-handler, science-fixture, and public semantic contracts.
  Manifest SHA-256 is
  `cc5e2a464b2c96772c6e2b441b55a4eabb603f36311c08d4342e4ed0f59a5325`;
  semantic production run `29670192516` and fresh HARV desktop/390/320 flows passed.
  Green-up onset, leaf-active duration, and coverage remain **HOLD / NO DRIVER BYTE
  CHANGE** until an exact eligible site-year join, censoring/support audit, registered
  temperature/onset model, and warm-desert alternative are reviewed. This compact
  receipt closes the chronological gap left by the prior Small Mammal handoff; it
  does not rewrite that historical entry.
- **Plant release identity:** the exact production code merge is
  `d6c48625f8268873bcd42d86285becaadbd57b4c`. Exact PR-head validation
  `29695040575` (job `88214223755`) passed on promoted artifact head
  `d51291bf570963c475595ab1cb9a9d41eba1bd59`; master validation `29695179837`
  (job `88214587699`), Pages `29695179559` (deploy job `88214620774`), and exact
  post-republish semantic attempt 2 in `29695179854` (job `88216101765`) passed.
  Governance-only closeout PR #10 head
  `52b0b6e61025af0e995b731e99bb1bc43f72bc5d` passed `29695932625` (job
  `88216579937`) and merged as `894893029582077c2677eece6351e2e4ffbcadf3`;
  docs-only master validation `29696162868` (job `88217192873`), semantic health
  `29696162847` (job `88217192767`), and Pages `29696162583` (deploy job
  `88217232845`) then passed. That later documentation merge does not replace the
  deployed app identity.
- **Plant exact receipts:** Connect request
  `00bdcf5f-babc-4a33-8307-144a221517f6` reports Last deployed `d6c4862` on Connect
  2026.06.1 with R 4.5.2 / 91 packages. Runtime token is
  `sha256:0765d8951843cf6fea09a295b260bfb53f1eb6708370748905a4a3941c85d2cb`
  and runtime-receipt file SHA-256 is
  `8c60432c053d45f033fe84d15d0a9a20db5c9f88040c35051af72cb816795768`.
  Manifest SHA-256 is
  `12ffe3496ac54a6504a04656236604abc64f4638d1ae92bfe103565c0d15cd51`;
  search-index SHA-256 is
  `889764559d21f4de9b0f71f1f7e9140f63f73015352063cf3b4ff720acdefd1b`.
  Cover token is
  `sha256:de6718b3b4e3557fdc395911cd98ce55be29db4d2a9b9038f1903814ed00413c`
  and cover-receipt file SHA-256 is
  `c52ff4e6198aae3174af2174699caaea95c9f39cddd5d76c16063da34ed2061d`.
  The validated family contains 46 plant bundles, 46 environment bundles, 34
  reference files, and 150 manifest files. Canonical master artifact `8444800158`
  has digest
  `sha256:a23b2f6ce8df2172626d83d683473bc2da53861f0d2f36580bcfeab6869f386a`.
- **Plant science/data result:** registered gates now require sampled opportunity
  before metrics, one deterministic bout per plot-year, recurrent panels for annual
  comparisons, a common 400 m² grain for cross-site richness, explicit support,
  Chao2 as an incidence lower bound rather than a generic effort correction,
  visible Unknown nativity, and spatially scoped references. The source family is
  exact and frozen but remains `legacy-partial`: original `builtAt`, NEON release,
  source cutoff, query receipt, raw digest, and sampled-empty 1 m² opportunity are
  unavailable. Repository dates, mtimes, manifests, and content hashes do not repair
  that missing upstream provenance. Short annual screens remain descriptive context.
- **Plant product/public result:** a fresh SRER flow showed 203 species, 33 plots,
  and 22.2% introduced relative cover; on-screen context, CSV export, and PDF report
  paths passed. Public desktop plus 390/375/361/360/320 px checks showed the full
  `SRER ready` state, a 44 × 44 Help target, no root overflow, disconnect, or output
  error, and the exact cover/social receipt. The production URL is
  `https://019ee109-30ae-006e-cb3b-143afeac57e3.share.connect.posit.cloud/`.
- **Failure caught and closed:** the first post-PR #8 production check found the
  Help control 94 px tall at 360/320 because Shiny `actionButton()` leaves its label
  as a text node inside `.action-label`; the sibling selector used by the first fix
  could not hide it. PR #9 zeroed inherited visual font size while preserving the
  accessible DOM label and restoring the icon. Candidate run `29694888946` (job
  `88213835069`) then failed only the intentional exact-byte gate, uploaded artifact
  `8444715871` with digest
  `sha256:be763c5432e20950bbfa2e72f61ea53da27deb3cae93047f92708693d3cb9855`,
  and was promoted exactly before the green validation and production QA above.
- **Reusable learning promoted:** define the observational opportunity before the
  estimator; preserve unit, denominator, support, censoring, unknown classification,
  spatial scope, and upstream-receipt limits from UI through exports; treat a hash as
  exact-byte evidence rather than source-vintage evidence; and test framework markup
  at both sides of every responsive seam. The Plant prevention matrix is
  390/375/361/360/320 because its status/help/theme grid changes at 360 px.
- **Cover-direction decision:** the prior identical dark-shell/constellation/mascot
  prescription and dense eight-part above-fold formula are superseded pending owner
  approval. The working face is a creative, intentionally art-directed poster for a
  non-scientist: one dominant app-native object or moment, one 3–7 word human hook,
  one 6–12 word plain-language promise, and one CTA. Methods, metrics, CAN/CANNOT,
  provenance, receipts, routes, and suite relationships move below the fold. Suite
  cohesion comes from the mark, typography, art language, motif family, registry,
  and in-app Suite panel, not cloned hero layouts. Documentary images require clear
  provenance; generated art must be visibly stylized rather than pseudo-documentary.
  A separate validated 1200 × 630 social composition remains required.
- **Driver decision/non-impact:** Plant common-grain richness,
  native/introduced/unknown cover, cross-scale occurrence, reference completeness,
  and support are **CONTEXT / NO DRIVER BYTE CHANGE**. Composition is not phenology
  or slow standing-structure context, and richness is not productivity. Reconsider
  ingestion only
  after one complete matching future receipt across all 46 bundles plus
  `site_index.rds`, an explicit sampled-opportunity ledger, recurrent/common-grain
  support, and a measured eligible Driver site-year join. Phenology remains held as
  stated above. No Driver v2 inference or build is authorized by either pass.
- **Artifacts/non-impact:** canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated:** the central ledger's Plant `PASS PENDING`, 13-mismatch,
  single-test, and startup-only state is superseded by the exact release above. The
  earlier conclusion to preserve the suite's constellation/mascot/dense cover shell
  is superseded by owner review and the pending artistic-poster brief. Historical
  release failures remain factual. No Driver build or release evidence is invalidated.
- **Validation/cleanup:** Driver documentation received Markdown/static consistency
  review and exact artifact rehashing; Driver R/build tests are N/A because no app,
  R, source, generated, or manifest input changed. No rebuild process or
  `.cascade-rebuild.lock` exists, and no backup, pending artifact, or temporary data
  was created. The first local UTF-8/fence loop used scalar syntax that zsh treated
  as one filename; it made no change and the array-form rerun passed. Plant
  code/release and governance merges are cleanly separated so the public app remains
  pinned to `d6c4862` while documentation closes on `8948930`. Independent final
  review caught and corrected the stale `1/2` outage count and Phenology baseline
  row; the accurate current state is two of three discovered outages restored, with
  Ground Beetle still open.
- **Residual risk/next action:** Plant's exact bytes still cannot answer the missing
  upstream vintage or sampled-empty opportunity questions; its released generated
  cover is only a baseline subject to the new suite poster review. Merge this
  Driver documentation tranche with all five Driver hashes unchanged. Then pause
  before Vegetation Structure cover implementation until the owner approves the
  artistic direction; once approved, run the full one-app learning loop and do not
  begin another app until Vegetation is production-verified and its lessons are
  vendored back here.

### 2026-07-19 18:16 MST - Small Mammal in-app Living Poster / documentary Pages checkpoint (artistic Pages parity superseded) / root

- **Changed/classification:** updated only this handoff, the suite learning loop,
  revamp plan, and reusable playbook. The central Pass 1 row and priority brief now
  replace stale pre-poster release evidence rather than duplicating it.
  Classification is `suite-platform` and `Driver-impacting`; the exact decision is
  **NONE for the Living Poster pattern / CONTEXT ONLY for the existing mammal
  signal / NO DRIVER BYTE CHANGE**. No Driver app, estimator, source lock, workflow,
  generated artifact, data file, or manifest changed.
- **Sibling release identity:** Small Mammal runtime merge
  `bdf56b0482ac76364e7055107361d58d8728d782` is the exact deployed application;
  documentation-only closeout merge
  `8d650b787075bb548d17f8380060597f5a8ff7f9` is the later repository identity. The
  production manifest records R 4.5.2, 91 packages, 118 files, and SHA-256
  `90c1366fcd51c507cb786a45a60dd59607a6980f97fc2e4d2e21b29af326d28e`.
- **Product/public evidence (corrected by the closeout below):** Connect deployment
  #122 reported exact `bdf56b0` at 2026-07-19 18:00 MST and opened with the artistic
  in-app Living Poster: a large real USGS Sherman-trap photograph, “One trap night.
  A whole population story.”, “Follow tagged small mammals across years of return
  visits.”, and “Pick a place”. Desktop, 390 x 844, and 320 x 800 browser checks
  found no root overflow; the app shell stayed on one row at 320. Pages run
  `29710189059` passed on attempt 3 after attempts 1 and 2 failed only on GitHub
  HTTP 503 responses, but it still served documentary V4 and is not artistic
  dual-surface evidence. Final artistic Pages parity arrived later in PR #85 / merge
  `eb9e1a3`; the exact four-run receipt is recorded in the correction below.
- **Learned:** a public showcase and its launched app are one first-impression
  contract even though their implementations differ. Updating only Pages can leave
  the in-app pre-selection state looking like the retired cover, so each release
  must verify hook, promise, CTA, dominant art, and claim boundary on both surfaces.
  A nominal 320-pixel viewport yielded only 305 usable layout pixels; inspect the
  framework-generated gutters, brand/actions, and top-bar wrap in addition to the
  poster component itself.
- **Test process/result:** started clean from `origin/master`
  `c6d7c74a644375d3bef210b42d7c754d4ca43825` on branch
  `agent/driver-small-mammal-poster-handoff`; confirmed no rebuild lock. Ran
  `git diff --check`; strict Node UTF-8/LF/no-BOM/control/trailing-whitespace/code-
  fence checks on all four changed Markdown files; table-shape checks on the suite
  register; stale-current-receipt scans; changed-file scope review; and SHA-256
  rehashing of the five Driver release files. Independently resolved both sibling
  commit objects and parsed the `bdf56b0` manifest as 91 packages/118 files while
  reproducing its exact SHA-256. Expected and actual result: PASS. Driver
  R/build/browser gates are N/A because the Driver runtime and publication surfaces
  did not change.
- **Evidence invalidated:** only the central current-state references to Small
  Mammal runtime `1615ab4`, 117 files, manifest `f6c4a5ff...`, closeout `b05cecc`,
  and a Pages-only documentary V4 endpoint are superseded. Their dated historical
  receipts remain factual. No Driver release, determinism, science, manifest, boot,
  browser, or publication evidence is invalidated.
- **Artifacts/non-impact:** no generation or promotion ran. Canonical Driver
  SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Failure/cleanup:** the two Pages HTTP 503 failures were external publication
  attempts and recovered without source changes on attempt 3. This Driver docs-only
  handoff had no failed local gate, created no lock/stage/backup/pending/temp data,
  and changed no credential or external state.
- **Residual risk/next action:** browser coverage remains finite, and this local
  documentation tranche still requires coordinating-owner review, commit, remote
  checks, and merge. After that docs-only closeout, continue Vegetation Structure
  through its complete app-local release and vendor its new evidence here before
  starting another app.

### 2026-07-19 21:58 MST - Small Mammal Pages correction and Vegetation Pass-4 core handoff / root

- **Changed/classification:** corrected the Small Mammal artistic-Pages identity;
  vendored the Vegetation official-source, science, promotion, Living Poster, and
  core production evidence into the central register, revamp plan, playbook, Data
  Takeaways, and Expert Review; and recorded the explicit pause before Pass 5.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting`. The exact Vegetation disposition is **HOLD / CONTEXT ONLY /
  NO DRIVER DATA BYTE CHANGE**. This tranche changes documentation only: no Driver
  app code, source lock, estimator, generated artifact, manifest, or public surface
  changes.
- **Small Mammal correction:** the prior 2026-07-19 handoff incorrectly cited Pages
  run `29710189059` as artistic dual-surface proof. That run remains a valid
  documentary-V4 release receipt but did not publish the final artistic Pages
  cover. The accurate Pages receipt is PR #85, merge
  `eb9e1a3e9e91096a1c1a82ebf116bf85d33405e3`, PR CI `29711968094`, main CI
  `29712103176`, Pages build `29712102838`, and production semantic run
  `29712103164`. Connect deployment #122 on `bdf56b0` remains the exact in-app
  artistic-poster receipt. Both independent surfaces carry the same hook, promise,
  CTA, and real USGS Sherman-trap photograph; the corrected identities avoid
  pretending that one commit or run published both implementations.
- **Vegetation source/science receipt:** Pass 4 targets NEON
  `DP1.10098.001`, official `RELEASE-2026`, provisional data excluded, DOI
  `10.48443/pypa-qf12`, across 42 sites. Raw family SHA-256 is
  `e8d78dd776fa4188c3f237548b7d2ab185eb5c03bc7b220991d03753ebca3e29`;
  bundle family SHA-256 is
  `3e62514de12b0d7b11cbe8aa53dde76d9f05f65c0174418a3df64e1261a88ffb`.
  The event-first family preserves source `uid`, exact `mapping_source_uid`, every
  measurement row, every published opportunity row, supported sampled-absence
  zeros, channel-specific area/support, and plot uncertainty. Forty-nine
  measurement-only plot-events / 4,365 rows / 11 sites are retained as
  `held_opportunity_source_missing`; the app invents no opportunity ID, date,
  effort, presence, absence, design, coordinates, area, or denominator and excludes
  those events from scaling and derived summaries.
- **Physical-channel boundary:** `tree_dbh` is bole cross-section at breast height;
  `shrub_sapling_basal` is shrub/sapling stem-base cross-section. Both can use
  m²/ha, but their
  measurement height, threshold, sampled area, and physical meaning remain
  disjoint. The exact 42-site x two-channel index carries the selected channel into
  the app; no cross-channel rank, pooled magnitude, forest/shrub classification, or
  annualization is authorized.
- **Candidate/promotion identity:** exact reviewed candidate head
  `a8ccb56e95f643ba9343ca13d176782ebc050017` passed run `29715249829` and emitted
  candidate artifact
  `vegetation-release-candidate-a8ccb56e95f643ba9343ca13d176782ebc050017-29715249829`
  (artifact ID `8450700945`, 28,378,366 bytes) plus raw artifact ID `8450530222`
  (29,782,052 bytes). Independent inspection verified 55 files / 54 payloads, 42
  sites, 68 runtime files, 91 packages, R 4.5.2, exact source-gap counts, and exact
  geo-package URL pins. Promotion commit
  `800bd5ea64d5aa4f2eab194c1b16dcbee5a0638e` has the candidate head as its direct
  parent, changes exactly the 54 ledger payload paths, and every committed blob
  independently matches its artifact checksum.
- **Core release/publication identity:** final PR #4 head
  `5c7456b16abae2569d037bb3b731a9e5065b0906` passed exact-head CI
  `29716974286`; diagnostic artifact
  `vegetation-structure-derived-5c7456b16abae2569d037bb3b731a9e5065b0906-29716974286`
  is artifact ID `8450993821` (92,307 bytes). PR #4 merged as
  `987c102b84de98f18c11dd98de6c8113ab7f4c8c`; Pages run `29717224521` passed and
  Connect deployment #55 successfully fetched and serves that exact merge under R
  4.5.2 with all 91 packages provided, including `wk 0.9.5`. This closes the earlier
  malformed dependency-URL failure mode for the core release.
- **Product/public result:** Pages and Connect now lead with the responsive
  screenprint Living Poster “Tagged. Measured. Still changing.”, promise “Follow
  real trees and shrubs through years of change.”, and CTA “Pick a place”. The
  source/art disclosure and suite bridge remain below the brief poster face. Public
  Pages desktop geometry, canonical metadata, disclosure, Driver link, and no root
  overflow passed; Connect opened the same entry promise and the 42-place gateway.
- **Open correction / no premature closeout:** Connect deployment #55 logs exposed
  one non-scientific landing-state warning: the hidden `baBar` Plotly source was
  queried before registration. A gated event listener correction is in PR #5. Its
  merge commit, main CI, final Connect deployment, clean post-landing logs, bar-click
  interaction, and full mobile receipt remain intentionally pending. Therefore this
  entry says **core merged / production closeout pending** rather than converting a
  known warning into an inferred PASS.
- **Driver decision/non-impact:** current Driver bytes remain unchanged. The
  released app contributes channel-qualified slow standing-structure context and a
  stricter observation/opportunity contract; it does not contribute annual
  productivity, biomass, carbon, a causal edge, or a vote. The existing strict
  `WOOD` hold remains. Any future field requires a separately reviewed adapter and
  Driver rebuild from the exact promoted source with channel/support fields,
  measured eligible joins, and old/new parity.
- **Reusable learning:** use one brief hook/promise/CTA across independently tested
  entry surfaces; serve checksum- and dimension-declared responsive art; build an
  event ledger before summaries; retain source and mapping UIDs; treat missing
  opportunity source as held rather than zero; keep equal-unit physical channels
  disjoint; independently reconstruct derived outputs; and promote only an artifact
  bound to an exact reviewed head, direct-parent commit, path ledger, and checksum
  proof.
- **Validation/non-impact:** documentation scope, UTF-8/LF/control-character,
  Markdown fence, table-shape, stale-receipt, and `git diff --check` gates passed.
  The first stale-state assertion omitted the app name and therefore matched other
  apps' legitimate `PASS PENDING` rows; it changed no file, and the app-scoped
  Vegetation rerun passed.
  Rehashing confirmed canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  Driver R/build/browser gates are N/A because no runtime input or output changed.
- **Next action:** after coordinating-owner review, add the exact PR #5/main/final
  Connect receipts, close the Vegetation app-local production record, merge this
  docs-only Driver tranche, and pause. Do not begin Ground Beetle or any other app
  until the owner deliberately resumes the program.

### 2026-07-19 - Vegetation Pass-4 runtime release and reset-picker hold / root

- **Changed/classification:** vendored the exact Vegetation warning fix, runtime
  enhancement, science-boundary checks, export checks, and the newly discovered
  reset-path defect into the central learning record. Classification is
  `suite-platform`, `scientific-contract`, and `Driver-impacting`. The decision
  remains **HOLD / CONTEXT ONLY / NO DRIVER DATA BYTE CHANGE**. This Driver tranche
  changes documentation only; no Driver code, source lock, estimator, generated
  artifact, data file, manifest, or publication surface changed.
- **Plotly warning correction:** the gated server listener fix passed exact-head CI
  `29718292956` at head `5baa6a023a9763d03e15d2341985b8d492e36755`
  after expected manifest-only run `29717387935`. Its diagnostic artifact was ID
  `8451426404` (92,308 bytes). PR #5 merged as
  `91a7814c9e1275c5a890aed4a9c186485f614e60`; main CI `29718542229`
  produced artifact ID `8451506471` (92,308 bytes), Pages run `29718541621`
  passed, and Connect deployment #56 served exact `91a7814` under R 4.5.2 with all
  91 packages. Fresh landing and repeated bar-click checks were clean.
- **Runtime release identity:** PR #6 added an accessible loading focus boundary,
  idempotent start/completion handling, focus restoration, reduced-motion tour,
  byte-shared active-channel plot-summary CSV/ZIP export, a Size Lab-local eligible
  plant selector, and keyboard-operable named pin groups. Implementation commit
  `7c1ced5c68e2ab32bb698f2f1a913f22a46541f9` was followed by exact manifest
  promotion `e5a12add8b1227453a904ff14741b92a5a435759`; the archived candidate
  inspector is pinned by SHA-256
  `819eca6d2f9a9b0663b8ad075796b0c558c5af07f740d3f5aa780826257416c5`.
  Expected manifest-only run `29719846128` uploaded artifact ID `8452015013`; the
  promoted manifest SHA-256 is
  `c9356c29aaa1f6bf869442ceb44eca81c5128c86c9352a1256fbae8c374fac6b`.
  Exact-head run `29720142868` passed with artifact ID `8452100740` (92,307
  bytes; archive SHA-256
  `6eb1b916e029c7c61d8e25b83a2b09c9cbfff3aa2962bcf5e50e2b0dfb4083cc`).
  PR #6 merged as `433bbd25acbe48224a75368c9edd6504e55271bd`.
- **Merged/public identity:** main CI `29720341082` passed and emitted artifact ID
  `8452189687` (92,307 bytes; SHA-256
  `c4c84cf70f069fab6d086738e35b6c95c117244a0b9833fcfb5e78b717aa7d49`).
  Pages run `29720340743` passed with artifact ID `8452121645` and deployment
  `5517445662`. Connect deployment #57 successfully published exact `433bbd25`
  under R 4.5.2 with all 91 packages.
- **Science-boundary QA:** BART loaded both physical channels and preserved their
  separate summaries. The standalone BART shrub/sapling plot-summary CSV was
  byte-identical to `plot_summary_latest.csv` in the eight-file site ZIP (both
  SHA-256
  `fddca062b6e9a69ed72dd7f00b27725adc45d773755878fb39f3ec8614259a7e`);
  PDF, full/flag-specific QC, plant CSV, plant/QC cards, and pinned-chart PNG paths
  also produced valid files. JORN's 50 exported tree contexts split into 25
  supported `sampled_absence` zeros and 25 `held_sampling_impractical` contexts;
  the UI reported 25 supported plots, zero live trees/species/stems/area, and no
  enabled plant or champion action. WOOD remains held-only: all 50 contexts are
  held (14 source-missing plus 36 opportunity-unknown), its 452 shrub/sapling rows
  include 411 live records, and neither physical channel has a supported context.
  These cases prove that supported zero, held, and missing are not interchangeable.
- **Open runtime defect / no premature closeout:** post-release QA found that after
  a loaded site, **Change site** returned to the Living Poster but did not repopulate
  the server-backed Selectize choices. A fresh session worked, so this is a reset
  lifecycle defect rather than missing site data. The reusable fix must refresh the
  picker on both initialization and reset and carry a browser regression gate.
  At this checkpoint the reset-picker PR/head, exact-head CI/artifact, merge, main
  CI, Pages, Connect deployment, and clean-log/mobile matrix remained open; the
  2026-07-20 closeout below supplies those exact identities. PR #6 / deployment #57
  remains exact evidence for the capabilities above, but it is not final Pass-4
  production-closeout proof.
- **Interim learning, superseded below:** loaded application and inferred
  output/source state appeared sufficient to gate `plotly::event_data()`, but the
  later #58 server logs disproved that assumption and the final entry records the
  raw-event contract. Stateful server-backed pickers need explicit initialization
  and reset contracts; making their container visible is not enough. Export QA
  should compare the same promised table byte-for-byte across standalone and archive
  paths.
- **Driver decision/non-impact:** Vegetation remains channel-qualified slow
  standing-structure context: tree-DBH bole cross-section and shrub/sapling
  stem-base cross-section stay disjoint, supported zero remains distinct from held,
  and no annual productivity, biomass, carbon, causal edge, or vote is added. Gate
  1–7 app-local source/science/release requirements are satisfied; gate 8—the
  separately reviewed Driver adapter/rebuild with exact source, support, measured
  joins, and old/new parity—remains closed.
- **Artifacts/non-impact:** canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  Driver runtime/build/browser gates remain N/A because no runtime input or output
  changed.
- **Checkpoint next action:** land and production-verify the reset-picker fix, add
  exact final-runtime evidence, then finish the separate app-local and central
  documentation closeouts. The 2026-07-20 entry below closes the runtime action,
  records the later app-local docs publication, and separates its append-only
  receipt candidate. Pause before Ground Beetle or any other companion app.

### 2026-07-20 - Vegetation Pass-4 production closeout / root

- **Changed/classification:** superseded the pending runtime state above with the
  exact reset, Plotly-registration, publication, responsive, science-boundary, and
  clean-log receipts for Vegetation Pass 4. Classification is `suite-platform`,
  `scientific-contract`, and `Driver-impacting`. Pass 4 is **COMPLETE / PRODUCTION
  VERIFIED**; its Driver disposition remains **HOLD / CONTEXT ONLY / NO DRIVER DATA
  BYTE CHANGE**. This central tranche changes documentation only. Vegetation's
  app-local documentation is published through PR #9 / merge `3391e70`, and its
  append-only receipt is published through PR #10 / merge `da466ea`. Runtime,
  documentation, and receipt authority remain separate; neither documentation
  identity is inferred from or substituted for the authoritative runtime release.
- **PR #7 reset lifecycle:** implementation
  `3835451f6945b25eca4ef31b4d0882b6406c07ae` moved both initial and reset population
  of the complete 42-site server-backed Selectize family through one helper.
  Promotion `8389c9c2d1a723b03f0e1ab88f64732fe454a134` passed exact-head run
  `29722349642`; artifact `8452911612` was 92,307 bytes with SHA-256
  `dde4ae1bac76051758abdd2f70a8d620c562949a907d6e2ed1b631992457af8d`.
  PR #7 merged as `0709bd021c7c9f142b1f280aa83b2cf3afd49f30`; main run
  `29722614074` emitted artifact `8453019545` (92,307 bytes; SHA-256
  `337816a4e4171b9e629119186979c6bd962d30b5daa33aff8fb601af122300a0`).
  Pages run `29722613509` emitted artifact `8452933484` (3,889,240 bytes;
  SHA-256
  `8de384a248795a09547d248e6353f83f2303f4c04291d5531f38ffe7a2ba92f7`)
  and deployment `5517850060`. Connect deployment #58 served exact `0709bd0` and
  live BART -> Change site -> search JORN returned one exact result and loaded it.
- **Failure caught after PR #7:** Connect #58 was visibly functional and its browser
  console was clean, but fresh worker server logs at 23:48:50, 23:53:51, and
  23:54:27 MST emitted the plotly warning that `plotly_click` for source `baBar` was
  not registered. This failed production closeout and invalidated the inference that
  application/output state checks proved source registration. The source family,
  picker repair, science checks, and artifact bytes remained valid; the clean-log
  claim did not.
- **PR #8 registered-event lifecycle:** plotly R 4.12 registers declared Shiny event
  IDs only after `renderPlotly()` prepares the widget. Implementation
  `4ce0cb7b3a7125780a5c7ca60c28a3eae71a88f5` therefore retained explicit
  `event_register("plotly_click")`, triggered the observer from raw
  `session$rootScope()$input[["plotly_click-baBar"]]`, and only then called
  `event_data(..., priority = "event")`. Site state or zero data cannot trigger the
  read, while event priority preserves repeated identical clicks. Expected
  manifest-only run `29723373295` emitted artifact `8453312072` (92,307 bytes;
  SHA-256
  `986bd3f29a16cd945dedb97f2dc2e26ab750e215a4283c164b066417778d0f72`).
  Manifest promotion `06904fe227119c2b87f80c9dc8334f19f7f79b05` passed exact-head run
  `29723718100`; artifact `8453460662` was 92,307 bytes with SHA-256
  `a37b64aa7bff81a4f963142ee9e19bb2737a5758697d29c222d92e4356229871`.
- **Authoritative runtime merged/public identity:** PR #8 merged as
  `d566b30ec8eb52ae984325da402cadfec3f18bc9`. Main run `29724062900`
  passed and emitted artifact `8453599842` (92,307 bytes; SHA-256
  `cf0fb363314e40004036652bd8968f8849196e51f9f626492c49e6bc08104f5f`).
  Pages run `29724062095` passed and emitted artifact `8453482888` (3,889,230
  bytes; SHA-256
  `24dda716e7d739d288cbacac2e958ffb587b86cc999ddb0b4e0072f0ac23cba1`)
  through deployment `5518123037`. Connect deployment #59 fetched and serves exact
  `d566b30` under R 4.5.2 with all 91 packages; deployment completed in four
  seconds.
- **App-local documentation publication identity:** PR #9 exact head
  `68497de328b2723aa997e7016397bfd266e22337` passed CI `29724891796`; artifact
  `8453930434` was 92,307 bytes with SHA-256
  `f92b5a9fc3d7eb1e9dbb70b894bed6882eff9c94d22a5907d3ec0207225684ce`.
  PR #9 merged as `3391e702e7be80a3f049c905782661f043be8db8`. Main CI
  `29725238531` passed and emitted artifact `8454053110` (92,307 bytes; SHA-256
  `71ec40bdfe63c2e2987a622c0759ad6c31bf3a749ef6c10a008a82afc1b9ef7f`).
  Manifest SHA-256 remained
  `b497f2e9f4228d772745b220da3f2ba6e9da00b8af4fec61af4272103d2e330c`, and
  search-index SHA-256 remained
  `c4d145046d9486d7c7cf2c85339200ba1eaad3cf7e0de22bb2e378c7c944fc4b`.
  Pages run `29725237988` passed with artifact `8453952616` (3,902,344 bytes;
  SHA-256
  `d871b82ae790998f03d8228981bcce3921be5724a97b52eabd27d72ee0948265`)
  and deployment `5518345576`. Connect deployment #60 fetched and serves exact docs
  merge `3391e70` under R 4.5.2 with all 91 packages after four seconds. Its server
  logs contain only benign plotly/shinyjs package-built-under-R-4.5.3 warnings, and
  fresh public Pages and Connect landings are clean. These governance/publication
  changes leave the PR #8 runtime family unchanged.
- **Append-only receipt publication identity:** PR #10 exact head
  `a606f9217f9110a80eff567e34668349b27d3c9f` passed run `29725664115`. Artifact
  `vegetation-structure-derived-a606f9217f9110a80eff567e34668349b27d3c9f-29725664115`
  was ID `8454216674`, 92,307 bytes, with SHA-256
  `8f75c1f43f6e47fd11ae9aa8894861b846e600c1e01821aedca10bcfb8a45946`.
  Its manifest and search index were byte-identical to the documentation release.
  PR #10 merged as `da466ea2495df3b03cb472bc2c6c65930ca5314a`. Main CI
  `29725954423` passed and emitted artifact
  `vegetation-structure-derived-da466ea2495df3b03cb472bc2c6c65930ca5314a-29725954423`
  (ID `8454339056`, 92,307 bytes; SHA-256
  `2c28c917acee6848bd36ecfaad873d42df1d5a42c26264455362d62d305423ec`).
  Independently downloaded manifest and search-index files remained byte-identical.
  Pages run `29725953990` passed with artifact `8454236113` (3,902,883 bytes;
  SHA-256
  `8e27e003767947d389ec1f87db9357c24cfe2894e7c0208b1b3afa163833f67d`)
  and deployment `5518482150`. Connect deployment #61 fetched and serves exact
  receipt merge `da466ea` under R 4.5.2 with all 91 packages after four seconds.
  Server logs contain only two benign plotly/shinyjs package-built-under-R-4.5.3
  warnings and zero `baBar`, `event_data`, not-registered, undefined-event, or
  Shiny runtime errors. Fresh Connect and Pages landing smoke passed the H1, CTA,
  picker, suite bridge, disclosure, zero root overflow, and no visible failure.
  This append-only receipt does not replace authoritative runtime merge `d566b30`
  or app-local documentation merge `3391e70`.
- **Final production/browser result:** a fresh #59 session loaded BART and opened
  the same `baBar` selection twice from two identical clicks. Change site then
  returned the complete picker, one exact JORN match loaded, JORN retained its
  supported-zero boundary, and WOOD remained held rather than zero. Landing widths
  390/375/361/360/320 and loaded widths 320/390 all had zero root horizontal
  overflow, visible/in-bounds primary controls, and no Shiny error or disconnect.
  The exact #59 worker's 33-entry browser slice had zero warning/error, zero suspect
  `baBar`/`event_data`/undefined/Shiny entries, and zero disconnect. After those
  actions, #59 server logs contained only benign plotly/shinyjs
  package-built-under-R-4.5.3 warnings and zero `baBar`, `event_data`,
  not-registered, undefined-event, or Shiny runtime errors.
- **Science boundary/non-impact:** the final interaction release does not change the
  official 42-site RELEASE-2026 event/stem family. BART continues to expose the two
  physical channels separately; JORN preserves supported sampled-absence zeros;
  WOOD remains held-only; and tree-DBH bole cross-section stays disjoint from
  shrub/sapling stem-base cross-section. The app adds no annual productivity,
  biomass, carbon, causal edge, or inferential vote. App-local gates 1–7 and runtime
  production verification are complete; gate 8 remains the separately reviewed
  Driver adapter/rebuild with exact source, channel/support fields, measured joins,
  and old/new parity.
- **Reusable learning:** server-backed picker state has an initialization-and-reset
  lifecycle, not merely a visibility state. For server-side Plotly reads, an
  inferred loaded/output condition is weaker than the raw registered event that can
  exist only after widget preparation. Every public release needs browser-console
  and worker-server-log review after fresh load, repeated identical interaction,
  reset, and re-render; visible success alone cannot close the gate.
- **Artifacts/non-impact:** canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  Driver runtime/build/browser gates are N/A because no Driver runtime input,
  output, workflow, or public surface changed.
- **Validation/cleanup:** documentation scope, UTF-8/LF/no-BOM/control-character,
  Markdown fence/table shape, stale-current-state, `git diff --check`, historical
  Small Mammal receipt, and five-file Driver hash guards passed. No Driver build,
  generation, manifest rewrite, lock, stage, backup, pending artifact, credential,
  or temporary project data was created.
- **Residual risk/next action:** app-local runtime, documentation, and receipt
  publication are complete; browser coverage remains finite. Merge this Driver
  documentation-only tranche without altering the three authoritative identities
  above. The owner has paused program execution before Ground Beetle Pass 5; do not
  begin another companion app until the owner deliberately resumes it.
