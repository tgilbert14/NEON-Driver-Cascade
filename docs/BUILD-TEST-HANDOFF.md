# Build, test, and handoff record

Last updated: 2026-08-06

This is the durable operating record for the NEON Driver Cascade repository. Read
the whole document before doing work. Keep it factual and current so a new session
can continue safely without relying on chat history.

## Canonical Driver artifact state

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

### Breeding Birds Pass 7 sibling contract (production verified; ingestion held)

The official `DP1.10003.001` `RELEASE-2026` package is complete and public. Run
`30454799557` produced, independently validated, and published the exact 47-site
candidate. Recovery PR #3 preserved candidate tree
`61cd60092c87e2e127e0baeef9ae3a1f0447b8f3` and merged the byte-identical release
as scientific/runtime authority
`97c3e4c25b69068c7d8b3d56bc3da3bc019e5097`.

| Measure | Locked value |
|---|---:|
| bird/Search-site/cross-site-export roster | 47 rows on every surface |
| valid physical counts | 26,365 |
| supported-zero physical counts | 117 |
| supported point-years | 24,509 |
| supported-zero point-years | 79 |
| cross-site analysis window | 2017–2024 inclusive |
| common rarefaction target | 90 valid physical counts |
| temperature source support | 47/47 sites |
| complete realized-month temperature support | 45/47 sites |
| incomplete sites | `BARR`, `TOOL` |
| realized-month support at each incomplete site | 1/2; aggregate `NA`; no imputation |

Source availability and estimand completeness are separate fields. `BARR` and
`TOOL` remain in every bird, Search-site, and export roster and are omitted only
from the finite-temperature view. A supported-zero physical count and a
supported-zero point-year are distinct opportunity states; neither may be
manufactured from missing detections or absent visits. The exact 2017–2024 window,
90-count target, eligibility predicate, and support fields remain aligned across
app, Search, visual marks, codebook, and exports.

The fixed disposition is **`CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE
CHANGE`**. Rarefied community context and birds per count remain descriptive; they
do not authorize causal, abundance, population, density, occupancy, breeding-
status, territory, or forecast claims. Future Driver use requires a pinned
independent adapter, measured eligible joins/support, a registered mechanism, and
old/new parity during suite synthesis.

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
  provenance, receipts, routes, and suite relationships move below the fold. The
  later owner-approved Suite Living Poster V1 contract supersedes this entry's
  “not cloned hero layouts” clause: all companions now share one structural frame
  while their art, palette, copy, crop, and scientific boundary remain app-native.
  Documentary images require clear provenance; generated art must be visibly
  stylized rather than pseudo-documentary.
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

### 2026-07-19 18:16 MST - Small Mammal documentary V4 dual-surface checkpoint (superseded by Cover V5) / root

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
- **Product/public evidence (corrected by the closeouts below):** Connect deployment
  #122 reported exact `bdf56b0` at 2026-07-19 18:00 MST and opened with the concise
  documentary V4 first-run panel: a large real USGS Sherman-trap photograph, “One trap night.
  A whole population story.”, “Follow tagged small mammals across years of return
  visits.”, and “Pick a place”. Desktop, 390 x 844, and 320 x 800 browser checks
  found no root overflow; the app shell stayed on one row at 320. Pages run
  `29710189059` passed on attempt 3 after attempts 1 and 2 failed only on GitHub
  HTTP 503 responses, but it still served documentary V4 and is not artistic
  dual-surface evidence. Brief documentary Pages parity arrived later in PR #85 /
  merge `eb9e1a3`; neither release shipped the owner-selected screenprint. Cover V5
  / PR #86 below is the first valid artistic dual-surface receipt.
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

### 2026-07-19 21:58 MST - Small Mammal documentary Pages correction and Vegetation Pass-4 core handoff / root

- **Changed/classification:** corrected the Small Mammal artistic-Pages identity;
  vendored the Vegetation official-source, science, promotion, Living Poster, and
  core production evidence into the central register, revamp plan, playbook, Data
  Takeaways, and Expert Review; and recorded the explicit pause before Pass 5.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting`. The exact Vegetation disposition is **HOLD / CONTEXT ONLY /
  NO DRIVER DATA BYTE CHANGE**. This tranche changes documentation only: no Driver
  app code, source lock, estimator, generated artifact, manifest, or public surface
  changes.
- **Small Mammal correction (superseded by Cover V5 below):** the prior 2026-07-19
  handoff incorrectly cited Pages run `29710189059` as artistic dual-surface proof.
  That run remains a valid documentary-V4 receipt. PR #85 / merge
  `eb9e1a3e9e91096a1c1a82ebf116bf85d33405e3`, PR CI `29711968094`, main CI
  `29712103176`, Pages build `29712102838`, and production semantic run
  `29712103164` established concise documentary Pages parity with Connect #122 on
  `bdf56b0`: both surfaces carried the same real USGS photograph and old copy. They
  were not the owner-selected artistic poster; PR #86 / `c4c46fce` below replaces
  them as current cover authority.
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

### 2026-07-20 09:15 MST - Small Mammal Cover V5 correction and shared-frame handoff / root

- **Changed/classification:** corrected the central handoff, suite register, revamp
  plan, and playbook so PR #85 / `eb9e1a3` and Connect #122 / `bdf56b0` remain
  documentary Cover V4 history rather than false artistic proof. Vendored the real
  Cover V5 release and made Suite Living Poster V1 the canonical shared frame.
  Classification is `suite-platform`; ecological Driver implication is explicitly
  **NONE / CONTEXT ONLY / NO DRIVER BYTE CHANGE**. No Driver runtime surface changed.
- **Sibling identity/evidence:** Small Mammal head `3e66ddca` passed exact-head R
  4.5.2 run `29755133857`. PR #86 merged as `c4c46fce3725126231504d8f9610f52e8f929ef8`;
  main CI `29755368217`, semantic smoke `29755368297`, and Pages `29755366998`
  passed. Its canonical manifest is 91 packages / 120 files, SHA-256
  `3fdf334febde34f93f75430bd5ef7daa61cc36f1d6ef7f540578051bee24d3fc`.
  Connect #125 published exact `c4c46fce`, supplied all packages, and resolved
  `wk 0.9.5` through the complete HTTPS CRAN tarball URL. App-local closeout PR #87
  passed run `29758319410` and merged as `047204e7fcca253ab24ee416654dc59e4ccca266`.
  Its docs-only main CI `29758617689`, semantic health `29758618145`, and Pages
  deployment `29758615636` also passed.
- **Product/public evidence:** Pages and Connect now use “Who moves after dark?”,
  “Meet the tiny lives reshaping the landscape.”, “Meet the mammals”, and the same
  owner-selected editorial screenprint with a dominant metal box trap and
  recognizable mouse. Both expose exactly one Driver route and a visible
  illustration/data boundary. Desktop/390/320 and responsive-seam checks found
  byte-matched art and zero root overflow. The CTA focused the 46-site picker; JORN
  loaded all ten tabs; species-composition and environmental-driver bar clicks worked.
- **Reusable frame contract:** every companion Pages and in-app first-run surface
  shares DDL identity, exactly one Driver route, an app/unofficial eyebrow, a
  3–7-word hook, a 6–12-word promise, one contextual CTA, one dominant responsive
  editorial artwork, a visible art/data boundary, and a compact
  scope/honesty/Source/Feedback footer. Metric bands, methods, receipts, second
  marketing bridges, and the full suite directory stay off the companion face.
  Driver carries the full registry; each app owns its art, palette, crop, words,
  CTA noun, and scientific limitation.
- **Science/Driver non-impact:** Cover V5 changed cover UI, CSS, art, and manifest
  inventory only. The physical-event resolver, opportunity/detection contracts,
  46/604/604 indexes, 145-species inventory, bundles, estimators, exports, source
  pins, Driver adapters, and all five canonical Driver artifacts are unchanged.
  Small Mammal remains `CONTEXT`; no inferential vote is added.
- **Test process/result:** from clean `origin/master` with no rebuild lock, read the
  complete handoff, suite loop, revamp plan, and playbook; audited the app-local V5
  release; and changed only four Markdown authorities. `git diff --check`, strict
  UTF-8/LF/no-BOM/control/fence checks, the 13-row register-shape gate, stale-current-
  receipt scan, exact five-file Driver rehash, and no-lock check all passed. Driver
  R/build/browser gates are N/A because no runtime input or output changed.
- **Evidence invalidated:** only current claims that PR #85 / Connect #122 were the
  artistic proof and that companions should avoid one shared frame. Their documentary
  receipts remain factual history. No Driver release/science evidence is invalidated.
- **Artifacts/failure/cleanup:** no generation, promotion, lock, stage, backup,
  pending artifact, credential, or temporary project data was created. Two benign
  Small Mammal Plotly initialization warnings remain documented; both click paths
  were verified live.
- **Residual risk/next action:** browser coverage is finite and this docs-only branch
  still requires static validation, review, green CI, and merge. Then keep the owner
  pause before Ground Beetle Pass 5; resume from this entry without repeating V5.

### 2026-07-19 23:11 MST - site-explorer provenance receipt and scientific corrections / root

- **Changed/classification:** work is confined to `prototypes/site-explorer/**`. Added
  `assemble_index.py`; modified `export_data.py`, `assemble_plot.py`, `index.html`,
  `walk.html`, `plot.src.html`, `plot.html`, `site-data.json`, `plot-srer048.json`,
  `div-srer.json`, `PROGRESS.md`, `README.md`, `build_plot.md`. Classification is
  `app-local` plus `suite-platform` (the provenance-receipt pattern is reusable).
  Ecological Driver implication is explicitly **NONE**. No Driver app code, estimator,
  scientific pin, source lock, workflow, generated artifact, or manifest changed.
  `prototypes/` is outside `manifest.json`'s allowlist and outside the rebuild's
  captured code surface, so no rebuild was required or run.
- **Artifacts/non-impact:** no generation or promotion ran. All five canonical files
  were rehashed at the end of this session and are UNCHANGED: cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, manifest
  `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Learned (promoted to the prototype's honesty rails):** a derived figure needs its
  *denominator* recorded, not only its formula. The prototype reported plot canopy
  cover over the full 1600 m2 base plot while reporting density over the 790 m2
  actually surveyed - two denominators for one plot in one panel. Vegetation Structure
  mapped only the eastern half of SRER_048, so the whole-plot divisor silently counts
  810 m2 of never-surveyed ground as measured zero cover. Second reusable lesson: a
  build script that omits explicit `encoding=` and `newline=` is not portable. On this
  Windows host Python defaults to cp1252 and translates LF to CRLF, so `export_data.py`
  emitted 4380 CRLF into a file `.gitattributes` pins to `eol=lf`, and `assemble_plot.py`
  would have decoded UTF-8 page text as cp1252. This is the same cross-platform byte-drift
  class the release gate exists to catch, reaching a prototype that CI does not cover.
- **Scientific corrections (recomputed independently from `plot-srer048.json` before any
  edit):** all-live plants 23 -> **19** (5 + 80 + 23 = 108 exceeded the 104 records that
  carry stem data); stem median 10 -> **11**; the retired "28 dead" removed from two
  further places; whole-plant mortality "5 of 179" -> **"5 of 104 assessed"** (75 cacti
  carry no `vst_apparentindividual` record and are live by construction); canopy cover
  26.6% over 1600 m2 -> **53.9% over the 790 m2 surveyed strip**, with the previously
  unstated formula now written out (summed **live-only** elliptical crowns
  `pi*(cr/2)*(cr90/2)`, summed not unioned, so `100 - cover` is not open interspace).
  An honesty-rail break was also closed: NIWO (tundra bucket, `veg_ba_ha` 31.1) rendered
  treeless while its caption claimed the scene was "built from measured standing wood";
  the tundra branch never reads `ba`. The claim is now made only when the bucket used the
  measurement, and the unused figure is disclosed rather than asserted.
- **Provenance added:** `export_data.py` now reads the bundle's existing `source_products`
  table and stamps `site-data.json.meta.provenance` with the bundle SHA-256, schema
  version, build time, tier rule, prior-family status and the exact commit for all seven
  source products; the explorer footer renders it behind a disclosure. `plot-srer048.json`
  and `div-srer.json` gained `provenance` objects, surfaced on The Plot. Fields that
  cannot be recovered are recorded as `UNKNOWN` **with the reason** (the Plot was built
  from a live API query, so no release tag or DOI was captured, and `build_plot.py` is
  uncommitted, so those records are not reproducible from this repository alone). The
  Plot is now labelled a **two-bout composite** (2016 n=88, 2021 n=91), not a census.
- **Test process/environment:** cwd `D:\Git\NEON-Driver-Cascade`; Windows PowerShell/Git
  Bash; Python 3.10 with `rdata` 0.11.2 installed for the read-only bundle reader
  (`pip install rdata`, as README documents); Node 24 for `node --check`; the in-app
  browser for render checks. Gates run and results: independent recomputation of every
  corrected statistic directly from `plot-srer048.json` (expected: confirm or refute the
  claimed values; actual: all six confirmed before editing); `node --check` on the
  authored script block of `index.html` and `walk.html` (PASS); all 14 committed JSON
  files parsed (PASS); CRLF/UTF-8 sweep over every text file in the directory (PASS after
  the `export_data.py` fix); `export_data.py` run twice with identical SHA-256
  (`ada2943c...`) and `assemble_plot.py` run twice with identical SHA-256
  (`241608ef...`), establishing determinism for both; `assemble_index.py` re-run reported
  "already current", establishing idempotency; `site-data.json` diffed field-by-field
  against its pre-change copy (expected: only the two new veg keys added and no science
  value moved; actual: exactly that, plus one latent bug fixed - WOOD's `veg_type` had
  been the literal string `"<NA>"` and is now `null`, with `veg_design_status`
  `unsupported-unmatched-plots` now carried through, matching this document's locked WOOD
  pins); browser render of all three pages with zero console errors, 46 sites, and no
  horizontal overflow at 320 px.
- **Evidence invalidated:** none of the Driver's build, determinism, manifest, boot,
  browser, or release evidence. The completion matrix is untouched because no row's
  subject changed. Superseded are the prototype's own stale claims listed above.
- **Failure/cleanup:** one real defect was found by attempting to verify rather than
  assuming - none of the three prototype pages carried `<meta name="viewport">` or
  `<meta charset>`. Without the viewport tag mobile browsers lay out at ~980 px and scale
  down, so every responsive rule in all three pages was dead on a real phone; this was
  invisible until a 320 px viewport reported `clientWidth` 980. Both tags were added and
  the 320 px re-check passed. No lock, stage, backup, pending file, credential, or
  scratch residue remains; the `.neon_token` present in the sibling checkout was never
  read, used, or recorded.
- **Residual risk:** the Plot's NEON release vintage is unrecoverable and is now labelled
  `UNKNOWN` rather than silently absent - it cannot be resolved without rebuilding from a
  pinned release. The walk's `veg_ba_ha` is computed by the Driver's own adapter from the
  sibling's tables at pinned commit `5e73e0d`; whether the sibling's RELEASE-2026 family
  would move any site is **UNKNOWN and must not be asserted either way**, because
  determining it would require a Driver rebuild that the sibling's own disposition
  (`HOLD / CONTEXT ONLY / NO DRIVER BYTE CHANGE`) forbids. Browser coverage remains
  finite and the in-app preview strips query strings, so the `?site=` deep-link
  normalization was verified by code inspection and by exercising the switcher, not by a
  real deep-link load.
- **Next action:** owner review of this prototype tranche. NOTE (added at merge time):
  the register row-4 correction described here was SUPERSEDED before merge. A
  concurrent `root` session (PR #39, master merge `5370be1`) vendored the full
  Vegetation Pass-4 receipt and rewrote row 4 to `PASS 4 COMPLETE / PRODUCTION
  VERIFIED` with app-local evidence I did not have. On merge I kept their row and
  their backlog entry verbatim and added only my prototype backlog row; my earlier
  observation-only row 4 was correctly discarded. See the merge-resolution entry below.

### 2026-07-20 08:16 MST - site-explorer protocol review; a prior-entry caveat reversed / root

- **Changed/classification:** confined to `prototypes/site-explorer/**` (`plot-srer048.json`,
  `plot.src.html`, `plot.html`, `build_plot.md`, `PROGRESS.md`). Classification `app-local`
  plus `scientific-contract` (it corrects published claims about a NEON product).
  Ecological Driver implication explicitly **NONE**. No Driver app code, estimator,
  scientific pin, source lock, workflow, generated artifact, or manifest changed.
- **Evidence invalidated - THIS ENTRY REVERSES A CLAIM MADE IN THE PRECEDING ENTRY.** The
  2026-07-19 23:11 MST entry recorded that The Plot had been labelled "a two-bout composite,
  not a census", reasoning that pooling the 2016 and 2021 survey campaigns conflicted with
  the sibling's rule against pooling repeated events. **That reasoning was wrong and the
  label has been withdrawn.** The remaining corrections in that entry (cover denominator,
  19 all-live, median 11, 5-of-104, NIWO, viewport/charset, encoding) all stand.
- **Learned - the causal error:** `vst_mappingandtagging` is a ONE-ROW-PER-INDIVIDUAL tagging
  table. Its date is when a plant's tag went on, not when the plot was surveyed. Individuals
  are tagged once and re-measured in later bouts. Therefore grouping the 179 plants by that
  date CANNOT produce a plant appearing twice: the "two disjoint cohorts with zero shared
  individualIDs" that was read as a finding is arithmetically forced by the table's
  structure. The generalisable rule: before drawing an inference from a grouping, establish
  whether the grouping key can even vary within the entity being grouped. A zero-overlap
  result on a one-row-per-entity key is a diagnostic that the wrong table was joined, not a
  result. Verified by two independent specialist reviews against primary sources
  (NEON.DOC.000987 VST protocol, the DP1.10098.001 user guide, and the Cactus SOP
  NEON.DOC.001715), which converged.
- **Scientific corrections made (each re-verified locally against the committed file before
  editing):** (1) the two date groups are FIRST-TAG COHORTS, not re-surveys - the UI control
  "Survey: 2016+2021" is now "First tagged", and narrowing it raises a note stating that no
  plant can appear in both years and that absence from a year is not absence from the plot;
  (2) "75 plants (the cacti) have no VST record" was wrong - it is **70 cacti plus 5 woody**
  (3 mesquite, 2 creosote); (3) the "9 species" headline is a MAPPING count - among measured
  plants the species count is **2 -> 4**, because NEON's standard woody protocol does not map
  cacti at all, Santa Rita (Domain 14) carries a site-specific exception to map large-stature
  cacti that postdates the 2016 bout, and cacti are measured under a separate Cactus SOP into
  a different table; (4) the condition rendered is approximately a **2021 snapshot**, not the
  tag year - 2016-tagged velvet mesquite carry basal diameter, but SRER measured mesquite at
  basal diameter only from 2020 onward (as a tree at DBH before), which indicates the builder
  joined each plant's latest measurement; (5) the 790 m2 cover divisor is the bounding box of
  the mapped plants, not NEON's recorded sampled area, so it is a lower bound and the
  percentage an UPPER bound - now labelled approximate. The page additionally records that
  saplings are never mapped, so this is a map of tagged individuals rather than of every
  plant present.
- **Claims now explicitly forbidden on this surface** (recorded in `plot-srer048.json`
  `provenance.cannot_show` and in the prototype's honesty rails): recruitment or ingrowth;
  mortality between visits; turnover; rising species richness; and any statement that a
  2016-tagged plant is gone. NEON records death as `standing dead` / `lost, presumed dead`,
  never as an absent row.
- **Test process/environment:** cwd `D:\Git\NEON-Driver-Cascade`; Python 3.10; Node 24; the
  in-app browser. Every specialist claim was independently re-derived from the committed
  `plot-srer048.json` before any edit was made (expected: confirm or refute; actual: all four
  load-bearing claims confirmed - the seven-date decomposition, the 70+5 split, the 2->4
  measured-species count, and basal diameter present on 2016-tagged mesquite). Then
  `node --check` on the rebuilt plot app block (PASS); `assemble_plot.py` rebuild (PASS,
  956,933 bytes); browser check that the control cycles all/2016/2021, that the explanatory
  note shows only when narrowed, that the corrected 70+5 text renders, and that the approximate
  cover caveat and revised provenance render (all PASS, zero console errors).
- **Artifacts/non-impact:** no generation or promotion ran. The five canonical files are
  unchanged: cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`,
  search `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, manifest
  `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Failure/cleanup:** the failure was analytical, not operational - a wrong inference reached
  a commit and is corrected here rather than being silently overwritten. No lock, stage,
  backup, pending file, or credential residue; no sibling repository or working tree was
  modified.
- **Residual risk:** growth, survival, true recruitment, and the NEON-recorded sampled area
  remain **UNKNOWN** and are labelled as such on the page. Settling them requires
  `vst_perplotperyear` (recorded sampled area, which growth forms were surveyed per bout) and
  `vst_apparentindividual` keyed on `eventID` (each plant's full measurement career); neither
  is committed here, and the builder that could fetch them is scratchpad-only. The inference
  that the SRER cactus-mapping exception postdates the 2016 bout is well supported by
  convergent evidence (no cactus carries a 2016 tag; NEON's API shows no spring sampling month
  at SRER before 2019) but was not confirmed against the specific superseded protocol revision,
  and is worded as an inference on the page.
- **Next action:** owner review. If this surface is ever rebuilt from raw NEON data, pull
  `vst_perplotperyear` and eventID-keyed `vst_apparentindividual` first and replace the
  inferred cover denominator with the recorded sampled area.

### 2026-07-20 - concurrent-session merge resolution (site-explorer x Vegetation Pass 4) / root

- **Changed/classification:** documentation-only merge resolution. Merged `origin/master`
  `5370be1` (PR #39, "Document Small Mammal and Vegetation Pass 4 handoff", by a
  concurrent `root` session) into branch `claude/site-explorer-provenance`. Classification
  `suite-platform`; ecological Driver implication explicitly **NONE**. No Driver app code,
  estimator, source lock, workflow, generated artifact, or manifest changed by the merge.
- **Conflicts and how they were resolved (AGENTS.md rule 7 - merge, never overwrite):**
  two files conflicted, both because the sessions wrote to the same records concurrently.
  * `docs/NEON-SUITE-LEARNING-LOOP.md` row 4 (Vegetation Structure). **Theirs kept in
    full, mine discarded.** My row said `PASS APPARENTLY COMPLETE IN THE SIBLING - NOT
    YET VENDORED HERE`, written from a read-only observation of the sibling's GitHub
    `main`. Theirs says `PASS 4 COMPLETE / PRODUCTION VERIFIED` and carries the app-local
    receipt (candidate head `a8ccb56`, run `29715249829`, promotion `800bd5e` with an
    exact-parent/54-payload ledger proof, core merge `987c102`). Their evidence class is
    strictly stronger than mine; my row was an outside observation and was correctly
    superseded.
  * `docs/NEON-SUITE-LEARNING-LOOP.md` Driver-implication backlog. **Theirs kept
    verbatim**, including their channel-qualified Vegetation row and their closing
    paragraph recording that Pass 4 is complete and that program execution is
    intentionally paused by the owner before Pass 5. I re-inserted only my one unique
    row (the Site Explorer prototype provenance-receipt pattern, decision `NONE`), which
    has no counterpart in their tranche.
  * `docs/BUILD-TEST-HANDOFF.md` ledger. **All four of their entries kept unmodified**,
    including their revision of the 2026-07-19 18:16 MST Small Mammal entry, which
    supersedes the version I had merged from. My two site-explorer entries were appended
    after theirs rather than interleaved: two of their entries carry a date but no clock
    time, so strict chronological interleaving would have required guessing their
    position. Heading timestamps preserve the true order.
- **Evidence invalidated:** the "Next action" of my 2026-07-19 23:11 MST entry, which
  stated that register row 4 was corrected in that tranche. It was not; theirs
  superseded it. That line is annotated in place rather than deleted.
- **Test process/result:** `git merge origin/master`; both conflicts resolved by script
  so the "keep theirs" halves were byte-preserved rather than retyped; then verified no
  conflict markers remain in `docs/*.md` (PASS), that row 4 is theirs (PASS), that both
  the Vegetation and Site Explorer backlog rows are present exactly once each (PASS),
  that their Pass-4 closing paragraph survived (PASS), that both backlog rows carry the
  table's 7 pipes (PASS), and `git diff --check` (PASS).
- **Artifacts/non-impact:** no generation ran; the five canonical files are untouched by
  the merge and remain cascade `47b98e48...`, search `a11a072d...`, meta `00120c52...`,
  codebook `a79cc754...`, manifest `92b46277...`.
- **Residual risk:** ledger entries from the two sessions are append-ordered rather than
  strictly clock-ordered. If more sessions run concurrently, designate one coordinating
  editor as rule 7 requires, rather than relying on merge resolution after the fact.
- **Next action:** owner review of PR #40.

### 2026-07-20 - site-explorer index pass 1 and second concurrent merge / root

- **Changed/classification:** `prototypes/site-explorer/{index.html,walk.html,plot.html,PROGRESS.md}`
  plus a second merge of `origin/master`. Classification `app-local` and
  `scientific-contract` (it corrects how uncertainty is displayed to the public).
  Ecological Driver implication explicitly **NONE**. No Driver app code, estimator,
  source lock, workflow, generated artifact, or manifest changed. The five canonical
  files are unchanged: cascade `47b98e48...`, search `a11a072d...`, meta
  `00120c52...`, codebook `a79cc754...`, manifest `92b46277...`.
- **Two display defects corrected on the index page.** (1) Driver cards drew a SOLID
  bar of width `|r|` and labelled the p-value "confidence". A solid bar reads as a
  firm result, and a lay reader takes "confidence 0.88" to mean 88% confident, which
  is close to the inverse. The bundle carries a plausible interval for all 162 links
  and 133 of them straddle zero, none of which was visible. Replaced with a
  zero-centred interval whisker whose verdict word is derived from the interval
  itself; `p` moved into the drawer relabelled "how easily chance alone could produce
  a pattern this strong - higher means more easily". (2) The year wheel gave the three
  featured sites "Rhythm sketch for this site." in place of "(schematic, not measured
  monthly data)", and the page boots on SRER, so the default view was the one missing
  its caveat while implying site-specific measurement. The bundle is annual and no
  month on that wheel was measured at any site, so the wheel and its hand-authored
  inputs were removed rather than re-captioned.
- **Learned:** a caveat that is correct in the general branch and dropped in the
  special-cased branch is worse than no caveat, because the special case is usually
  the default view. Also: hand-authored per-biome templates presented beside real
  per-site data are indistinguishable to a reader; 43 of 46 sites were showing the
  same generated sentence twice on one screen without any indication it was generic.
  The replacement rule that generalises: derive the sentence from the site's own
  numbers, and let "nothing here is clean enough to call" be a legitimate result.
- **Test process/result:** JS syntax checked on index.html and walk.html
  (`node --check` on the extracted app block); plot.html rebuilt; grep confirmed zero
  dangling references to `WALK_URL`, `WALKABLE`, `drawWheel`, `player`, `polar` or
  `WHEEL`. The interval whisker was verified headlessly by lifting `pos()`/`whisker()`
  out of the page and running them over all 162 drivers in `site-data.json`: 0
  geometry failures, 133/162 straddling zero, and 0 mismatches between the derived
  verdict word and the interval. `siteAnswer()` was exercised over all 46 sites (22
  with a readable link, 23 reporting nothing clean, 1 with insufficient data) with no
  empty or malformed output. Link resolution was tested for both the repo case and the
  artifact-host case. Expected and actual matched throughout.
- **Also fixed:** the prototype's own navigation did not work when opened from the
  repository. `index.html` had no reference to `plot.html` at all and pinned the walk
  link to a private artifact URL; both now resolve relatively and fall back to the
  artifact URLs only when served from that host. `walk.html`'s back-link had the same
  defect and the same fix. The dead `WALKABLE` list was replaced with the real
  seven-site LiDAR set, verified against the committed `lidar-*.json` grids.
- **Merge resolution (second concurrent collision, AGENTS.md rule 7):** merged
  `origin/master` `646764a` (PR #41, "Record the Small Mammal V5 suite contract"). One
  conflict, in this file's ledger; `NEON-SUITE-LEARNING-LOOP.md` auto-merged and my
  prototype backlog row survived intact. Resolved as before: their entry kept verbatim
  and my entries appended after, never interleaved or overwritten.
- **Residual risk:** this is the third concurrent-session collision on these two
  documents in one day. Rule 7 asks for a designated coordinating editor when sessions
  overlap; resolving after the fact has worked so far only because the tranches touched
  different records. The remaining index work (field card, masthead, solid-versus-null
  pair, the weather/plants/animals chain from the 20 unused `signals`) is recorded in
  `prototypes/site-explorer/PROGRESS.md` rung 22.
- **Next action:** owner review of PR #40.

### 2026-07-26 07:06 MST - Pass-5 closeout and Pass-6 register handoff / Codex

- **Changed/classification:** reconciled the central suite register, revamp plan,
  and playbook with the published Plant Phenology and Plant Diversity Living Poster
  refreshes and the complete Ground Beetle Pass-5 release. Classification is
  `suite-platform`, `scientific-contract`, and `Driver-impacting`; the ecological
  Driver implication is **HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE**. The
  static-poster default is now durable suite guidance. No Driver app code, source
  lock, estimator, workflow, generated artifact, manifest, or public surface changed.
- **Exact sibling evidence:** Phenology PR #5 head `c1bf55d` passed
  `29963446292` and merged as `50106f20`; main validation `29964265558`, Pages
  `29964264658`, and production health `29964265433` passed. Plant Diversity PR
  #11 head `3b9137e` passed `29963358476` and merged as `dfb44231`; main
  validation `29963570916`, Pages `29963570413`, and production health
  `29963570919` passed. Both live Pages and Connect poster surfaces passed the
  previously completed desktop/390/320 review.
- **Ground Beetle result:** opportunity-complete PR #14 head `c3dec8d` merged as
  `4e628f88`; final static-poster PR #15 head `a7950294` merged as release authority
  `89caa435`. Exact-head CI `30023971987` passed 46 bundles / 100,163 rows /
  33,012 opportunity anchors / 67,151 catch rows, the effort/zero-catch/taxonomy/
  detection/QC contracts, and the 91-package/112-file manifest. Pages
  `30023970965` and content-aware production health `30023973253` passed on the
  same merge. Manifest SHA-256 is
  `b3da3599f7601fabd697d592897f2238af02315c286ef829d1ab0715815a9266`.
- **Learned:** a release register must distinguish historical baseline failure from
  current production authority. Opportunity-complete app metrics can become
  scientifically trusted without automatically becoming Driver votes; ingestion
  still requires a pinned independent adapter, measured eligible joins/support,
  a registered mechanism, and old/new parity at suite synthesis. The main poster
  artwork is static by default from Pass 5 onward.
- **Test process/result:** started from clean synchronized `origin/master`
  `7405bb039f4305ec1c8b51736e729a0f55fb978a`; read the complete repository
  instructions, handoff, learning loop, revamp plan, and playbook; refreshed the
  Driver remote; independently queried the merged sibling PR and workflow receipts;
  inspected the Ground Beetle exact validator and production-smoke logs; and
  reproduced its manifest SHA-256/package/file counts from `origin/main`. Expected
  result was to replace only stale current-state documentation with exact released
  evidence; actual matched. Driver R/build/browser gates are N/A because its runtime
  surface and artifact family did not change.
- **Evidence invalidated:** the central current-state claims that the two plant
  covers were unpublished and that Ground Beetle was release-unsafe,
  catch-conditioned, and still in foundation work. Their dated baseline records
  remain factual history. No Driver release, determinism, science, manifest, boot,
  browser, or publication evidence is invalidated.
- **Artifacts/failure/cleanup:** no generation or promotion ran. Canonical Driver
  SHA-256 values remain cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`,
  search `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`,
  meta `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`,
  codebook `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`,
  and manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild lock, stage, backup, pending artifact, or temporary project data was
  created.
- **Residual risk/next action:** browser coverage is finite and the documentation
  release still requires review, green CI, merge, and master verification. After
  that closeout, begin Mosquito Pulse Pass 6 with the full app-local evidence loop;
  do not alter Driver bytes during the companion pass.

### 2026-07-26 10:54 MST - Mosquito Pass-6 production closeout and Pass-7 handoff / Codex

- **Changed/classification:** reconciled the central suite register, revamp plan,
  playbook, and this handoff with the completed Mosquito Pulse Pass 6. Classification
  is `suite-platform`, `scientific-contract`, and `Driver-impacting`. The ecological
  decision is **CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE**. The
  outcome-state reconciliation and real-bundle server lifecycle test are adopted as
  suite engineering/science-contract patterns, not as a Mosquito inferential vote.
  This Driver tranche changes documentation only; no Driver code, source lock,
  estimator, workflow, generated artifact, manifest, or public surface changed.
- **Source/release evidence:** official `DP1.10043.001` `RELEASE-2026` producer and
  validator completed in run `30207972162`. The promoted family contains 47 site
  bundles and 223,048 combined effort/catch rows: 55,114 valid opportunities,
  25,076 supported zeros, 103,887 catch rows, and 82,875 held rows. Data artifact
  SHA-256 is
  `2679408c4af5387811f2b3ac12642ea22b962fd996c855eb9216e0545838f3ed`;
  source-receipt SHA-256 is
  `00bba55dcfa4fdba2f9f9400e53cbff319d3a9281eacd6fb32e7b533aaa4f826`.
  The final exact R 4.5.2 / 91-package / 112-runtime-file manifest SHA-256 is
  `acef14509ce44347d53a99b252cd92814797df1698b5a4365c9e0ac0724cc4ce`.
- **Scientific contract:** effort is keyed by source `uid` or a complete physical
  event composite; `trapHours / 24` is continuous. Supported zero requires a valid
  opportunity and `targetTaxaPresent = N`; positive, zero, unusable, unknown, and
  ineligible states stay distinct. Invalid or conflicting expansion is held.
  Total-versus-species and all-zero states fail closed. The exposed metric is
  whole-trap-scaled target catch per 24 trap-hours: a within-site activity index,
  never population, biting rate, infection prevalence, pathogen presence, disease
  risk, or a causal effect. PUUM is included; its climate overlay remains held.
- **Runtime/public identity:** PR #3 exact head `c1c0783` passed CI `30211462476`
  and merged as `1522048`; main CI `30212048494`, Pages `30212048059`, and
  production smoke `30212048468` passed. PR #4 exact head `c909ef2` passed CI
  `30212805885` and merged as `68aef41`; main CI `30212882395`, Pages
  `30212882153`, and smoke `30212882466` passed. Accessibility PR #5 exact head
  `24e0eb7` passed CI `30213142660` and merged as authoritative runtime
  `935420e1e1aa79dcc3cf54d03ef150f6f0332b8d`; main CI `30213225754`, Pages
  `30213225369`, and smoke `30213225753` passed. App-local documentation PR #6
  head `2179e80` passed `30213386500` and merged as receipt authority
  `91b4c713ebbdc717128de584273b995ec49dd622` without changing runtime.
- **Product/browser evidence:** Pages and Connect use one static violet/cyan
  nocturnal-wetland screenprint with a plausible CO2 trap and mosquito. Static
  Pages passed desktop/768/390/320 without root overflow, cover animation, remote
  font/CDN, missing alt text, or duplicate Driver/CTA routes. The first production
  Connect audit found `heroStats` and `siteInsights` evaluating before a site bundle
  existed despite a healthy shell and semantic marker. Runtime PR #4 made them
  suspend before load and added a permanent fresh-session `shiny::testServer`
  regression that loads real bundled SRER. Fresh production sessions then had zero
  Shiny errors before and after SRER. Final 390 QA measured all 19 audited poster,
  navigation, expansion, and popover controls at least 44×44 px.
- **Refresh failure and resolution:** the restricted producer and validator passed,
  and the review branch published safely, but the initial workflow's final PR-open
  operation was denied by the default GitHub Actions token. That failure did not
  invalidate produced bytes or validator evidence. The publisher now reports the
  review branch as a notice and exits successfully when token policy forbids PR
  creation; it does not gain broader authority or bypass stale-base, exact-diff,
  manifest, or validation gates. Integrated no-download refresh run `30211449455`
  passed all jobs.
- **Driver decision:** do not ingest Mosquito now. At suite synthesis, an independent
  Driver adapter must pin runtime `935420e` and receipt `91b4c71`, preserve outcome
  and effort states, measure the eligible site-season/year join and support,
  pre-register a seasonal/thermal mechanism, keep PUUM climate overlay held, and
  prove old/new parity before any ecological adoption decision.
- **Validation/non-impact:** started from clean synchronized `origin/master`
  `7070f18fae2e3582f9f0dd7a0af8786f79db0803` with no rebuild lock; read the
  complete repository instructions, handoff, suite loop, revamp plan, and playbook;
  and changed only the four Markdown authorities. Documentation UTF-8/LF/no-BOM,
  control-character, fence/table-shape, stale-current-state, and `git diff --check`
  gates passed. Driver R/build/browser gates are N/A because no Driver runtime input
  or output changed. Canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No generation, promotion, lock, stage, backup, pending artifact, credential, or
  temporary Driver project data was created.
- **Evidence invalidated:** only the central current-state claims that Mosquito had
  seven manifest mismatches, no executable tests, a missing social image, and
  startup-only evidence. That 2026-07-18 baseline remains factual history. No
  Driver release, determinism, science, manifest, boot, browser, or publication
  evidence is invalidated.
- **Residual risk/next action:** browser coverage is finite; Mosquito's PUUM climate
  overlay and Driver ingestion remain deliberately held. Merge this docs-only
  Driver tranche after green CI, verify master/Pages, then begin Breeding Birds
  Pass 7. Do not rebuild Driver v2 until all nine app packages and the suite
  synthesis gate are complete.

### 2026-07-26 13:38 MST - Mosquito compact-cover correction and Pass-7 continuity / Codex

- **Changed/classification:** reconciled the suite register, revamp plan, reusable
  playbook, and this handoff after user review found that Mosquito's Pages face was
  more verbose than the approved Small Mammal/Vegetation Living Poster flow.
  Classification is `suite-platform`; the explicit ecological decision is
  **NONE / NO DRIVER BYTE CHANGE**. This Driver tranche changes documentation only.
- **Correction:** Mosquito Pages removed the second method lead, three numbered
  science cards, and the two-part CAN/CANNOT panel. The public face now moves from
  one static poster directly to a compact footer with one collapsed honesty
  disclosure. The load-bearing supported-zero versus unavailable boundary and the
  activity/population/pathogen/causal limits remain present there. At ≤700 px the
  artwork leads, while the CTA remains in the first viewport.
- **Exact sibling authority:** compact-cover PR #7 head
  `db732ebaa1173f92e5a36511401060b4224cdde7` passed exact-head run
  `30218822559` and merged as Pages authority
  `ec0f2ba4df71040d1760c23338da39233b92db96`. Merged-master validation
  `30218905672`, Pages `30218905198`, and semantic smoke `30218905626` passed.
  App-local receipt PR #8 head `8998dd4cd6246f3cb1e17f9ebb5a4aa7e1c34be6`
  passed `30219204557` and merged as
  `6450f0197ac3ee535c0059b80a5e041b5dfe0b9a`; receipt-main validation
  `30219314063`, Pages `30219313524`, and smoke `30219314027` passed.
- **Identity boundary:** authoritative Connect/science runtime remains
  `935420e1e1aa79dcc3cf54d03ef150f6f0332b8d`; its science/runtime receipt remains
  `91b4c713ebbdc717128de584273b995ec49dd622`. Compact Pages authority is
  `ec0f2ba`; compact-cover receipt authority is `6450f01`. No art byte, `ui.R`,
  release source, opportunity state, estimator, bundle, manifest, Connect runtime,
  Driver adapter, or ecological disposition changed.
- **Fresh production evidence:** cache-busted Pages passed visual and DOM QA at
  1440×900, 390×844, and 320×800. Each width had no horizontal overflow, one H1,
  one CTA, one Driver route, zero H2/method/card blocks, a 52 px CTA, and a 44 px
  collapsed honesty control. At 390 and 320 the full artwork loaded first and the
  footer began exactly at 844 and 800 CSS px; at desktop the footer began at 900.
  The WebP completed at its intrinsic 1200×800 dimensions with local PNG fallback,
  and browser warning/error logs were empty.
- **Reusable prevention:** cover validators must combine required-presence and
  prohibited-absence checks. Require one poster/CTA/Driver route/disclosure and
  reject metric, methods, truth, boundary, second-bridge, and suite-directory
  layers. From Birds onward, browser QA must also prove artwork-first narrow order
  and first-viewport CTA visibility where geometry permits.
- **Validation/non-impact:** started from clean synchronized `origin/master`
  `2508104deca59265478f31b1664fdf2dff45a534` with no rebuild lock; the complete
  handoff, suite loop, revamp plan, playbook, and repository instructions were read.
  Documentation UTF-8/LF/no-BOM, control-character, fence/table-shape, identity,
  exact changed-file scope, and `git diff --check` gates passed. Driver R/build and
  browser gates are N/A because no Driver runtime input or public surface changed.
  Canonical Driver SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** only the earlier claim that Mosquito Pages already met
  the concise Living Poster first-impression contract. Its dated visual acceptance
  remains historical evidence for the static artwork and responsive mechanics.
  All science, release, manifest, bundle, Connect, and Driver evidence remains
  valid.
- **Residual risk/next action:** browser coverage is finite and this docs-only
  Driver reconciliation still requires review, green CI, merge, and master/Pages
  verification. Then begin Breeding Birds Pass 7; do not rebuild Driver v2 before
  all nine app packages and the suite-synthesis gate are complete.

### 2026-08-03 10:20 EDT - Breeding Birds Pass 7 production closeout / Codex

- **Changed/classification:** reconciled the app-local production package into this
  handoff, the suite evidence register, revamp plan, and reusable playbook.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting` documentation. The ecological disposition is **`CONTEXT /
  HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE`**; no Driver adapter, build,
  runtime, source lock, estimator, data, manifest, or public surface changed.
- **Official release evidence:** Breeding Birds Run 14 `30454799557` ran on exact
  reviewed head `2da56ee499c10064b47b468bd23330fba6b35892`. Producer job
  `90585528840`, independent validator `90662811450`, and restricted publisher
  `90672878106` succeeded. Candidate `e3ec1cd35cc75891ac6eebd87da307d8266f8ca5`
  binds release ID
  `sha256:28cf09453f25d5d8fc509d414c7549fbefec45f6f89dc611946360944976a3ac`,
  manifest SHA-256
  `14f7425c3134ee217af4ab4331a5805c72dbc23e56724207c190877df5a767d2`,
  121 runtime files, 91 pinned packages, and the complete 47-site opportunity and
  context family.
- **Merge and production identity:** recovery PR #3 exact head
  `ffd0f05d13a716118d1efc63a0abbbfaca7f054a` passed exact-head CI
  `30817207865` / job `91697774641` and merged as
  `97c3e4c25b69068c7d8b3d56bc3da3bc019e5097`. Candidate, recovery head, and
  merge share exact tree `61cd60092c87e2e127e0baeef9ae3a1f0447b8f3`.
  Master CI `30818593951` / `91702470321`, Pages `30818592101`, and production
  smoke `30818593688` / `91702467072` passed. Smoke proved Pages marker
  `breeding-birds-poster-v1` and Connect marker
  `breeding-birds-release-2026-v1` served the same release ID without startup-
  failure text.
- **App-local documentation authority:** closeout PR #4 exact head
  `812df303f74a85880d9bafe2f49db55b07923c26` passed CI `30820481561` / job
  `91708865944` and merged as
  `07c852c2ed56357b39fb0315ecca1f12ebff962b`. The resulting master CI
  `30821230065` / `91711360010`, Pages deployment `30821227931` (build
  `91711362808`, deploy `91711428197`, report `91711428122`), and production
  smoke `30821231664` / `91711364275` all succeeded. This docs-only authority did
  not replace scientific/runtime authority `97c3e4c`.
- **Contract adopted as context:** the app retains 47 sites, 26,365 valid physical
  counts with 117 supported zeros, 24,509 supported point-years with 79 supported
  zeros, exact 2017–2024 comparison support, rarefaction target 90, and separate
  47/47 temperature-source versus 45/47 complete-realized-month support. `BARR`
  and `TOOL` retain `NA`; no partial average, imputation, or unrelated-row loss is
  allowed. Birds per count is a detection index, and rarefaction standardizes
  effort rather than creating abundance, occupancy, or causality.
- **Reusable prevention:** pull-request validators must evaluate the literal review
  head, not GitHub's synthetic merge revision. Set the source SHA to
  `github.event.pull_request.head.sha || github.sha`, checkout that SHA, assert
  `git rev-parse HEAD` equality, and bind any promotion/merge to the same head.
  A green merge-ref build cannot prove the bytes the reviewer actually approved.
- **Validation/non-impact:** work began from clean current Driver `master`
  `d80be866d681336e04c5ac397ed3d9332f986596`. Documentation scope and receipt
  checks pass; Driver runtime/build/browser gates are not applicable because no
  Driver byte changed. Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated:** central Birds `PASS PENDING`, eight-manifest-mismatch,
  one-helper-test, startup-only, and next-pass statements are superseded as current
  state. They remain dated baseline history. No Driver release, science, manifest,
  determinism, or publication evidence is invalidated.
- **Next action:** publish this docs-only Driver reconciliation through exact-head
  review and post-merge checks, then begin Water Chemistry Pass 8. Driver v2 remains
  gated on all nine packages and suite synthesis.

### 2026-08-03 15:41 EDT - verified sibling releases and Water recovery checkpoint / Codex

- **Changed/classification:** reconciled only verified sibling-release evidence into
  this handoff, the central suite register, revamp plan, and reusable playbook.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting` documentation. Ecological disposition remains **`CONTEXT /
  HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE`** for Water and every already-held
  sibling signal; no Driver adapter, build, runtime, source lock, estimator, data,
  manifest, or public surface changed.
- **Verified companion continuity:** Plant Diversity Living Poster authority
  `dfb44231` remains supported by main validation `29963570916`, Pages
  `29963570413`, and production health `29963570919`. Ground Beetle artistic
  release `89caa435` remains supported by CI `30023971987`, Pages `30023970965`,
  and semantic smoke `30023973253`. Mosquito runtime `935420e`, science/runtime
  receipt `91b4c71`, compact Pages authority `ec0f2ba`, and cover receipt
  `6450f01` retain their recorded green receipts. Breeding Birds runtime
  `97c3e4c` and docs authority `07c852c` retain their exact validation, Pages, and
  production-smoke receipts. This session changed no authority or ecological
  disposition for those four apps.
- **Phenology current authority:** current-data PR #9 exact head
  `3089dc8e527340245735efbc62c95aa2faee5b25` merged as
  `7d0f29f7886cfae1c760a9ffc9e056184ec6fc68`, retaining the approved Living
  Poster. Merged-main validation `30842200764`, Pages `30842196863`, and exact
  production health `30842199076` all completed successfully on that merge. The
  earlier Poster authority `50106f20` remains historical cover provenance rather
  than the current release head.
- **Water recovery review and merge:** recovery PR #12 exact head
  `04130a34cd2e4b315d181d954339b2beefe7afb7` passed run `30844732454`, including
  candidate build, independent validation, and clean Ubuntu 22.04 / R 4.5.2
  Connect cold start. It merged as
  `d5101f2187b30b1492b2119607875f6305c35d19`. The recovery preserved the merged
  scientific/data bytes, restored a reviewed 103-package Connect graph, restricted
  the manifest to the exact six required runtime files, and added readiness
  metadata bound to all six checksums.
- **Water production identity:** Pages deployment `30846455599` and production
  smoke `30846458474` succeeded on exact merge `d5101f2`. The smoke independently
  derived the six-file receipt, received HTTP 200 plus the expected semantic body
  from Connect and Pages on its first attempt, and rejected Posit Startup Error
  text. The released runtime reports 48 quarantined collapsed unit-mismatch groups
  representing 99 source rows, 11,679 registered missing-label fills without
  numeric conversion, 198 plausibility exclusions, and zero PRPO high-variance
  exclusions.
- **Held refresh boundary:** full refresh run `30846587801` remains pending
  candidate review. It is not a production receipt and supplies no accepted data-
  through date, metric delta, artifact, or new release authority. Water Pass 8
  remains open until its independently validated candidate and final knowledge
  package are reviewed. No automatic merge, Driver ingestion, or suite-synthesis
  promotion is authorized by the recovery.
- **Reusable prevention:** a constant ready marker identifies an app family but
  cannot prove the deployed revision. Emit an exact runtime receipt derived from
  the sorted explicit allowlist checksums and make post-deploy smoke recompute and
  match it while rejecting host error pages. Keep package/runtime recovery separate
  from data refresh so a restored deployment cannot implicitly bless new data.
- **Validation/non-impact:** work began from clean synchronized Driver
  `origin/master` `13edc725fcb361e0a22da674a261a45967226698` with no rebuild lock.
  Documentation UTF-8/LF/no-BOM, control-character, fence/table-shape, exact changed-
  file scope, stale-current-state, and `git diff --check` gates pass. Driver
  R/build/browser gates are not applicable because no Driver runtime input or
  public surface changed. Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** current-state claims that Phenology authority stops at
  `50106f20`, Birds retains eight mismatches and one helper test, and Water remains
  a three-mismatch/no-test/startup-only baseline are superseded. The dated
  2026-07-18 baseline remains historical. No prior app science or release receipt
  is invalidated, and Water full-refresh evidence is deliberately not inferred.
- **Next action:** review run `30846587801` and its exact Water candidate if and
  only if producer, independent validator, and publisher succeed. Close Pass 8 only
  after human delta review, promotion, merged production verification, and the
  complete app-local knowledge package. Driver v2 remains gated on all nine passes
  and suite synthesis.

### 2026-08-03 16:02 EDT - Inverts partial release audit correction / Codex

- **Changed/classification:** independently reviewed the four uncommitted Driver
  documentation changes against current My Little Inverts main and production,
  then corrected the central register, revamp plan, handoff, and reusable playbook.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting` documentation. Disposition is **`CONTEXT / HOLD DRIVER
  INGESTION / NO DRIVER BYTE CHANGE`**; no Driver or sibling runtime, data,
  manifest, estimator, deployment, or public byte changed.
- **Exact Inverts authority:** refresh/data merge
  `fd509ae6821aae556a51ac05820e7f4f5dafbad5` retains the 34-site family reporting
  830 bouts, 6,430 samples, 9,392 search rows, and source stamp `2026-06-22`.
  Documentation PR #5 literal head
  `31ff4cbe181be87f6c351affd28c903ab0ef62e1` passed producer and independent
  validator run `30829357856`, then merged as current main
  `114f91db92bb2d47e032af5d70d564f719b8ec2f`.
- **Release/manifest evidence:** current manifest SHA-256 is
  `a6b5056f4c786f8cbbccc8613cdbed80eebbb1d76ac4894df867247be8914c98`,
  binding R 4.5.2, 91 packages, and 48 runtime files. Run `30829357856` evaluated
  the literal review head, rebuilt derived release data in its clean validator,
  and passed the exact candidate verifier. This supersedes the current-state claim
  of nine manifest mismatches and no executable release validation; it does not
  validate the ecological estimand.
- **Pages and production evidence:** Pages run `30833410378` passed build, deploy,
  and status on exact `114f91d`. The live 47,895-byte page is byte-identical to
  current `docs/index.html`, both SHA-256
  `11b4deac721d62a638f382475a0c7e2b7acac3b5e5bd40eca218756612147f45`.
  Connect returned HTTP 200 and a real Shiny surface with Shiny, Plotly, Leaflet,
  and Selectize dependencies rather than a Startup Error page, but the repository
  has no post-deploy exact marker/receipt; availability cannot bind the worker to
  `114f91d`. Declared Open Graph/Twitter `og-image.png` returned HTTP 404.
- **Scientific hold:** `scripts/build_inv_data.R` constructs `tax` from taxonomy
  rows, creates `obs` with `tax %>% inner_join(fld, by = "sampleID")`, and derives
  `samp`, `bout_ids`, and `bouts` from `obs`. A field sampling opportunity with no
  taxonomy outcome therefore cannot enter the released sample/bout family as a
  sampled zero. No independent opportunity/zero ledger currently reconciles
  positive, sampled-empty, unusable, and missing-effort states. The 830/6,430
  counts, density index, richness, composition, and EPT summaries are released
  surfaces, not Pass-9-safe opportunity-complete science evidence.
- **Required Pass-9 closeout:** build the field-opportunity ledger before outcomes;
  add adversarial zero, expansion, benthic-area, sampler, habitat, water-type,
  taxonomy, rarefaction, and EPT fixtures; add an exact Connect runtime receipt;
  repair the social asset; complete browser/accessibility and expert review; and
  publish the final app-local knowledge package. Until then infer no absence,
  density trend, impairment/health grade, causal link, or Driver vote.
- **Water continuity:** run `30846587801` remained `in_progress` on exact recovery
  merge `d5101f2` at 16:02 EDT. Its candidate remains pending review and supplies
  no accepted data authority; the Water wording and Driver hold remain unchanged.
- **Reusable prevention:** release safety and scientific opportunity safety are
  separate gates. An immutable producer, independent manifest validator, green
  Pages deployment, and booting app can faithfully preserve a catch-conditioned
  transform. Require the sampling-opportunity ledger before outcome joins and
  record partial release health without promoting the product pass.
- **Validation/non-impact:** work remains based on clean synchronized Driver
  `origin/master` `13edc725fcb361e0a22da674a261a45967226698` with no rebuild lock.
  Documentation UTF-8/LF/no-BOM, control-character, fence/table-shape, exact changed-
  file scope, stale-current-state, and `git diff --check` gates pass. Driver
  R/build/browser gates remain not applicable. Canonical SHA-256 values remain
  cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`,
  search `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`,
  meta `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`,
  codebook `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`,
  and manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** only the new uncommitted current-state claim that
  Inverts retained its untouched nine-mismatch/no-test/startup-only baseline is
  superseded. Its dated 2026-07-18 baseline and current scientific/product gaps
  remain factual. No Water, Inverts, Driver, or other sibling release/science
  receipt is invalidated.
- **Next action:** keep Water refresh `30846587801` held for exact candidate review.
  After Pass 8 closes, execute the full Inverts Pass 9 from the opportunity ledger;
  do not treat the repaired release plumbing as a completed scientific pass.

### 2026-08-04 EDT - Water Chemistry Pass 8 production closeout / Codex

- **Changed/classification:** reconciled the final Water refreshed release into
  this handoff, the suite evidence register, and the revamp plan while preserving
  the earlier recovery and pending-review entries as dated history. Classification
  is `suite-platform`, `scientific-contract`, and `Driver-impacting`
  documentation. The ecological disposition remains **`CONTEXT / HOLD DRIVER
  INGESTION / NO DRIVER BYTE CHANGE`**; no Driver adapter, build, runtime, source
  lock, estimator, data, manifest, or public-surface byte changed.
- **Authoritative source and candidate:** full-fetch workflow `30872232876` ran at
  exact source `e2ea753a25257492e4a9e82970c8275d898a2788`. Its signed replay
  contains 238,488 lab rows, 8,599 field rows, and the canonical 34-site
  coordinate roster. Producer, replay, independent validator, exact six-file cold
  boot, manifest, and restricted publisher passed. Candidate
  `27512485a2252e994be501eca3e8440e7659d2c1` is the direct child of that source.
- **Reviewed release:** reviewer-authenticated PR #15 bound the exact candidate to
  full run `30872232876`; exact-head check `30876917859` passed before the PR
  merged as `ee95af3e270099980ea5bc98b28b549456b3f0b2`. The released bundle SHA-256
  is `50f6e57981cae7cee2f1d5cb68f9beff306ed7d8e59ce461503c62b26963f78c`
  and contains 200,953 observations, 34 analytes, and 34 sites through 2026-07-15.
- **Scientific receipt:** unit policy
  `explicit-targets-audited-exclusions-value-invariant-v4` rewrites 14,422 exact
  registered missing labels, excludes 75 audited source rows, and changes zero
  numeric values. The clean independent replay reconstructed the same candidate
  and reported runtime exclusions `0/0`. Source, bundle, index, codebook, manifest,
  and receipt checks remained fail closed.
- **Production identity:** Pages run `30878152320` and production-health run
  `30878153073` passed on exact merge `ee95af3`. Public Pages returned HTTP 200 and
  was byte-identical to the committed surface. Connect content
  `019ebf59-b2ff-a20a-cb35-6d227ca6261a` publication #67 served the exact merge
  without Startup Error text.
- **Driver decision:** Pass 8 is complete, but release quality does not create an
  ecological vote. Aquatic chemistry remains descriptive condition/aridity
  context. Driver join/support is **UNMEASURED, not zero**; any future use requires
  a separately reviewed pinned adapter, measured eligible site-time support, a
  registered role and claim limits, old/new parity, and suite-synthesis review.
- **Validation/non-impact:** the Driver worktree remains based on
  `13edc725fcb361e0a22da674a261a45967226698` with no rebuild lock. The intended
  scope is exactly the four Markdown authorities. Documentation UTF-8/LF/no-BOM,
  control-character, fence/table-shape, stale-current-state, canonical-hash, and
  `git diff --check` gates pass. Driver runtime/build/browser gates are not
  applicable because no Driver input or public surface changed. Canonical SHA-256
  values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** current-state claims that Water stopped at recovery
  merge `d5101f2`, full refresh remained pending, or Pass 8 remained open are
  superseded. The dated recovery/pending-review entries remain factual history;
  no prior Water, Driver, or sibling science/release receipt is invalidated.
- **Next action:** complete My Little Inverts Pass 9 and its app-local publication
  receipts, then reconcile that exact package here before the cross-product
  synthesis and complementary-product decision. Do not ingest either aquatic app
  into Driver without the independent adapter and measured-support gate.

### 2026-08-04 EDT - My Little Inverts Pass 9 production closeout / Codex

- **Changed/classification:** reconciled the completed Inverts scientific release,
  exact candidate review, merge, Pages, Connect, and live-production receipt into
  this handoff, the suite evidence register, revamp plan, and reusable playbook.
  Classification is `suite-platform`, `scientific-contract`, and
  `Driver-impacting` documentation. Final disposition is **`CONTEXT / HOLD DRIVER
  INGESTION / NO DRIVER BYTE CHANGE`**; no Driver adapter, build, runtime, source
  lock, estimator, data, manifest, or public-surface byte changed.
- **Authoritative source:** official `DP1.20120.001` `RELEASE-2026`, DOI
  `10.48443/hp56-s582`, full-fetch run `30885526988` ran at publication source
  `a685e01c61938fcbd49325d7cf365aa272fae58a`. Source artifact `8883372756`
  contains raw RDS SHA-256
  `13345d39682bcc27ec45fca490cd63888b18c98735e6575737a79c6c109b67d0`;
  source receipt SHA-256 is
  `0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28`,
  and maximum source publication date is `2025-12-09`. The raw family contains
  7,201 field rows, 6,446 per-sample rows, and 320,240 taxonomy rows; three `.DNA`
  field rows remain quarantined.
- **Scientific receipt:** the release begins from all 7,198 remaining field
  opportunities across 34 sites before taxonomy outcomes. It reconciles 830
  events, 1,679 exact event strata, 6,477 primary opportunities, 6,213 count
  eligible, 6,213 density eligible, 181,922 collapsed taxonomy rows, and 85,874
  taxon-stratum search rows. Its exhaustive display-status partition is 719
  unstratifiable, 2 nonstandard collection, 34 processing unknown, 230 count
  unavailable, and 6,213 quantified community. Source `uid`/`sampleID`, practical
  opportunities lacking processing, taxonomy placeholders, method, habitat, water
  type, area, and support remain explicit. Unknown is not zero; density is a
  supported-area within-site/index quantity; EPT is composition, not health,
  impairment, a causal claim, or a Driver vote.
- **Reviewed candidate and release identity:** validated candidate
  `b7dffb6c1e149c52d094c4347483435df07856f6` is the direct child of source
  `a685e01c61938fcbd49325d7cf365aa272fae58a`. Its 43-file publication allowlist
  matches validated artifact `8883990535` byte for byte; artifact ZIP SHA-256 is
  `ec37be5bd0f3fe56cb9dde50e56f80193af024b7aa5a233bc5749db29f55b22d`.
  Identity SHA-256 is
  `f0be51e0da7cc41176abdda57c52e202019579c1df3890e6ab7df18f8a1a1f46`,
  manifest SHA-256 is
  `26b94b5e8ddc5e22618ad47faf1b388802dfa76354fd38f0a33a5c4c1a0eb8d2`,
  and release ID is
  `sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5`.
  Exact R 4.5.2 / 91-package proof uses dated Posit forms with no moving alias or
  `cran.rstudio.com` reference.
- **Human review and publication:** exact-head PR workflow `30888675725` passed on
  candidate `b7dffb6c`; reviewer-authenticated PR #6 merged as
  `ff23e994e289982c747b91e48c5ff0907c1672d2`. Pages run `30890184235` passed on
  that merge. Connect publication #17
  (`019fcbca-a610-e368-7562-54b93e2056d0`) served the same release. Production run
  `30890185880` / smoke job `91930207585` passed exact Pages and Connect HTTP
  identity plus a live bidirectional Shiny session. Signed-in QA loaded the local
  Living Poster, Leaflet, all 34 sites, SYCA's five hero statistics, and Help with
  no horizontal overflow or browser error.
- **Executable evidence:** the authoritative workflow passed source, science,
  producer, release-verifier, and loaded-app contracts; the recorded suite totals
  are 143, 109, 43, 58, and 110 checks. Source/release identity, manifest,
  opportunity/status, area/density, taxonomy/EPT, cover, responsive, accessibility,
  and production contracts are closed. Earlier safe-failure runs remain preserved
  as nonauthoritative diagnostic history and published no candidate byte.
- **Driver decision:** release quality and opportunity-complete science still do
  not create an ecological vote. Driver join/support is **UNMEASURED, not zero**.
  Keep every Driver artifact unchanged. Any future use requires a separately
  reviewed pinned adapter, measured eligible site-time support, a registered
  role/mechanism and claim limits, plus old/new parity during suite synthesis.
- **Validation/non-impact:** the Driver worktree remains based on
  `13edc725fcb361e0a22da674a261a45967226698` with no rebuild lock. Intended scope
  is exactly the four Markdown authorities. Documentation UTF-8/LF/no-BOM,
  control-character, fence/table-shape, stale-current-state, canonical-hash, and
  `git diff --check` gates pass. Driver runtime/build/browser gates are not
  applicable because no Driver input or public surface changed. Canonical SHA-256
  values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** current-state claims that Inverts stops at `114f91d`,
  retains a taxonomy-first 830-bout / 6,430-sample / 9,392-search-row family, lacks
  the social asset, or has no exact production receipt are superseded. The dated
  2026-07-18 baseline and 2026-08-03 partial-audit entry remain factual history;
  none of their historical hashes, failures, or observations was rewritten.
- **Next action:** run the cross-product synthesis and record the formal
  complementary-product build/defer decision. Do not automatically ingest Inverts,
  Water, or any other companion into Driver; only accepted immutable inputs may
  enter a deliberate Driver v2 adapter/rebuild.

### 2026-08-04 06:26 EDT - My Little Inverts governance/tooling publication closeout / [Codex]

- **Changed/classification:** reconciled the separately published Inverts
  governance/tooling candidate and current production receipt into this handoff,
  the suite evidence register, revamp plan, and reusable playbook. Classification
  is `suite-platform`, `scientific-contract`, and `Driver-impacting`
  documentation. Scope is exactly these four Driver Markdown authorities; no
  Driver or Inverts runtime, estimator, data, manifest, generated artifact, or
  public-surface byte was edited here.
- **Authority/receipt model:** `ff23e994e289982c747b91e48c5ff0907c1672d2`
  remains the Inverts science/data/runtime authority. The later governance stream
  began at `1b059cb04e32c02c171d21a9d47b22cf6c060db2`; direct-child candidate
  `ecbb23cd313632727e78896ab4473b600b456b34` passed PR #7 exact-head check
  `30894827652` and merged as governance/tooling and production-identity authority
  `6972817382491cc9312ae4588b75bc67ed422987`. Final BUILD-only merge
  `53991b6f460a97a4abfcee9f62e94cd77c167f89` is the current deployed-revision
  receipt; because it changes only the identity-excluded handoff, it replaces
  neither authority nor the Driver-facing science/runtime pin.
- **Identity/domain receipt:** the cycle-free production identity uses the
  Pages-payload domain v2 and binds every root `docs/*.md` file
  except the literal mutable `docs/BUILD-TEST-HANDOFF.md`; closure status belongs
  in that excluded handoff and the central Driver register. Any other root-doc
  change requires regenerated identity, a clean validator, and a newly reviewed
  exact candidate. Governance manifest SHA-256 is
  `7dceb40616052bb22e05a1ba68b56c47896ede68d08394b67c502bc81cd1ec8d`,
  production ID is
  `sha256:e1d3f1be5620706c71a53783e87b4570c6985fe8d9ed5554ece0b51954aa7aa8`,
  and Pages payload SHA-256 is
  `43b16e7b44d160055c8fa59039d2c922e802342042b1db1238e65c0249a44fff`.
  Runtime payload SHA-256 remains byte-identical at
  `87900f675a1ef34d4f5c47c6788fbaac08a8549d82c4ef900a1b28726e925278`.
- **Published governance receipt:** Pages run `30896544721` passed on exact merge
  `6972817`. Connect publication #18
  (`019fcc1b-5672-3278-21c6-9ead85568da2`) served the same governance production
  identity. Production run `30896548595` / job `91950703053` passed
  exact Pages and Connect identity plus a live bidirectional Shiny round trip.
  The reviewed candidate/source diff proves the science, data, runtime, poster,
  index, and social-image bytes were unchanged.
- **Executable production QA:** live Pages index, poster/art, and social assets
  matched the reviewed checkout byte for byte. Stable 1280-, 390-, and 320-pixel
  layouts had no persistent horizontal overflow and exposed visible keyboard
  focus. Console, page, request, same-origin HTTP, stylesheet, and poster-image
  failures were fail-closed. The live SYCA path reported 193 field opportunities,
  121 count-eligible, 121 density-eligible, 245 mixed-rank taxa, and 17 events.
  Playwright 1.55.1 ran on Node >=18; `npm audit` reported zero vulnerabilities.
- **Final BUILD-only receipt:** PR #8 exact head
  `6c01244c7eeb756c7305a6dfaa3f1c67adac3833` passed exact-head run
  `30898431839`; its publisher skipped with zero steps before exact-head merge
  `53991b6f460a97a4abfcee9f62e94cd77c167f89`. Pages run `30900109522`, Connect
  publication #19 (`019fcc48-823f-0cc5-f8dc-4ef8c302f3cb`), and production run
  `30900110643` / job `91962182435` passed on that merge. Connect published in
  five seconds without a Startup Error, signed-in QA confirmed the exact
  `sha256:e1d3f1be…` identity and 193/121/121/245/17 SYCA view, and the production
  smoke proved exact Pages bytes at 1280/390/320 plus a live bidirectional Shiny
  session. This append-only closeout moved neither runtime/science authority nor
  any identity-bound byte.
- **Driver decision:** disposition remains **`CONTEXT / HOLD DRIVER INGESTION /
  NO DRIVER BYTE CHANGE`**. Governance quality and exact production verification
  do not create an ecological vote. Driver join/support is **UNMEASURED, not
  zero**; future use still requires a separately reviewed pinned adapter, measured
  eligible site-time support, registered role/mechanism and claim limits, and
  old/new parity during suite synthesis.
- **Validation/non-impact:** the Driver worktree remains based on
  `29052fc077859ab6ff746ecdfac918b75fcc43a5` with no rebuild lock. Documentation
  UTF-8/LF/no-BOM, control-character, fence/table-shape, stale-current-state,
  placeholder-absence, canonical-hash, changed-path, and `git diff --check` gates
  pass. Driver runtime/build/browser gates are not applicable because no Driver
  input or public surface changed. Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No rebuild, generation, promotion, lock, stage, backup, or temporary Driver data
  was created.
- **Evidence invalidated:** current-state claims that the Inverts governance
  package or BUILD-only closeout was staged/pending, that `ff23e994` owned the
  governance identity, or that `6972817` was still the current deployed repository
  commit are superseded. The historical `ff23e994` science/data/runtime authority,
  `6972817` governance/tooling and identity authority, manifests, production IDs,
  Pages/Connect/live-Shiny receipts, and all earlier factual history remain valid.
- **Next action:** begin cross-product synthesis and record the formal
  complementary-product build/defer decision; do not ingest Inverts automatically.

### 2026-08-04 06:36 EDT - Driver dependency-resolution contract repair / [Codex]

- **Changed/classification:** repaired the release infrastructure exposed by the
  first PR #51 validation attempt. Changed only `.github/workflows/ci.yml`, both
  dependency-install sites in `.github/workflows/refresh-data.yml`, this append-only
  handoff, and the already-in-scope reusable playbook. Classification is
  `suite-platform` / release infrastructure; ecological Driver implication is
  explicitly **NONE**. No Driver source, input, estimator, manifest, generated
  artifact, or public-surface byte changed.
- **Failure/root cause:** PR #51 exact head
  `f3497e17b894f907b8139555e9ed0d72a6e10e0c` failed run `30900961084` / job
  `91964895890` at `Validate committed snapshot and extract immutable source lock`
  with `runtime package version drift: bslib=0.12.0 (manifest 0.11.0)`. Checkout,
  dependency installation, deterministic OpenBLAS verification, static checks,
  workflow/helper contracts, and the full cascade contract fixture set had passed;
  sibling fetch, rebuild, exact-artifact reproduction, semantic-manifest comparison,
  and final diff checks were skipped. The workflow requested unversioned `bslib`
  while the immutable manifest requires `0.11.0`, allowing the pinned Posit snapshot
  to resolve the newer library.
- **Repair:** pinned `bslib@0.11.0` beside the existing exact Plotly pin in all
  three CI/refresh dependency lists and rolled the shared cache contract from
  `cascade-ppm-2026-07-15-v1` to `cascade-ppm-2026-07-15-v2`. The manifest drift
  guard remains strict. Independent review found no P0-P2 concern: the failed
  validator reported no other package mismatch, the exact version satisfies the
  committed Shiny/rmarkdown constraints, and all producer/validator install sites
  use the same pin and fresh cache namespace.
- **Local validation/non-impact:** both edited workflows parse as YAML; exact
  pin/cache cardinality is three; no unpinned workflow `bslib` or old cache key
  remains; the manifest target is exactly `0.11.0`; workflow-receipt guard and
  manifest-comparator fixtures pass; and `git diff --check` passes. The local
  system Python is 3.9.6, so `scripts/test_trusted_publish.py` stops at its existing
  `Path.write_text(..., newline=...)` test-harness requirement; the unchanged test
  passed on the preceding GitHub runner before the package-version gate. A fresh
  exact-head GitHub run remains authoritative for dependency installation and every
  downstream rebuild/reproducibility gate. Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated/residual risk:** the prior four-Markdown-path statement
  remains true for the completed Inverts reconciliation commit, but no longer
  describes the complete PR after this release-infrastructure repair. No Inverts
  authority, production receipt, ecological disposition, or Driver artifact
  evidence is invalidated. The repair is not complete until a new literal PR head
  passes every previously skipped gate.
- **Next action:** commit and push the focused repair, require a fully green
  exact-head PR #51 run, then exact-head merge and verify `master`, Pages, and the
  signed-in Connect publication before beginning cross-product synthesis.

### 2026-08-04 06:45 EDT - Driver dependency repair exact-head validation / [Codex]

- **Changed/classification:** appended the immutable validation receipt for the
  focused dependency-resolution repair. This entry is `suite-platform` release
  evidence only; ecological Driver implication remains explicitly **NONE**. No
  workflow, source, input, estimator, manifest, artifact, or public-surface byte
  changed after the reviewed repair head.
- **Exact-head receipt:** PR #51 head
  `e10a667671fefef431829096abe67fffc3dde927` passed run `30901537212` / job
  `91966748824`. The job checked out that immutable SHA, installed the fresh pinned
  dependency set, verified Haswell OpenBLAS with one thread, validated the committed
  snapshot and 73-package / 12-file manifest, and extracted all seven source locks.
  It fetched the seven recorded sibling commits detached, rebuilt all nine stages,
  ended `ALL CASCADE CONTRACT TESTS PASSED`, verified runtime-integrity fault
  fixtures, booted the exact staged app with 510 annual rows and 12 registered
  associations, and reverified the manifest after boot and promotion.
- **Reproduction/non-impact:** the four committed scientific artifacts reproduced
  with an empty exact-byte diff; manifest semantics reproduced for 73 packages and
  12 deploy checksums; and final whitespace rejection passed. The canonical five
  hashes recorded above remain unchanged. This closes the dependency-repair risk
  and validates all downstream gates skipped by failed run `30900961084`.
- **Residual risk/next action:** this handoff-only receipt requires one final
  literal-head PR run. After it passes, exact-head merge PR #51 and verify the
  resulting `master` CI, Pages publication, signed-in Connect deployed revision,
  and live Driver surface before beginning cross-product synthesis.

### 2026-08-04 15:48 EDT - Driver v2 cross-product synthesis Gate 0 / [Codex]

- **Changed/classification:** completed Pass 10 cross-product synthesis from the
  nine production companion packages and added an executable, immutable
  compatibility audit plus a machine-readable decision ledger. Updated the suite
  register, learning loop, revamp plan, complementary-product audit, README,
  reusable playbook/lesson, and CI/refresh contract lists. Classification is
  `scientific-contract`, `suite-platform`, and Driver-governance documentation.
  No Driver source pin, adapter, estimator, schema, prior, vote, manifest entry,
  generated artifact, or public-surface byte changed.
- **Formal decision:** Gate 0 is **`PASS 10 COMPLETE / DRIVER V2 SIGNAL CHANGES
  HELD / NO CANONICAL BYTE CHANGE`**. Reusable app contracts are accepted
  independently of ecological signals; every new signal remains non-voting. The
  two published v1 temperature-to-green-up screens remain unchanged historical
  artifacts and are held for v2 re-authorization through a separately specified
  current-Phenology adapter, censoring policy, registered model, and old/new
  parity. A blind seven-repository repin is rejected.
- **Measured compatibility:** exact app-supported/direct-calendar site-years are
  Mammal `410/410`, Phenology `346/346`, Vegetation `151/156`, Beetles `388/388`,
  Mosquito `200/203`, and Birds `381/384`. Plant Diversity annual support remains
  `UNMEASURED` because the frozen family lacks an opportunity denominator. Water
  is `0/387` by exact terrestrial site key and `351/387` by descriptive domain-year
  proxy; Inverts is `0/307` exact and `307/307` proxy. Proxy compatibility is not
  an eligible integration key and cannot repair either zero exact join.
- **Complementary-product decision:** **`DEFER BUILD / ACQUIRE EVIDENCE ONLY`**.
  Acquire pinned Continuous Discharge first and reopen only at at least three
  recorded-stream sites with at least six common QC-cleared discharge x Inverts
  years. Acquire Herbaceous Clip Harvest second and reopen only at at least three
  temperate-grassland sites with at least six common coverage-cleared clip x
  Driver-precipitation years. Litterfall remains separate descriptive forest
  context. No complementary app, adapter, prior, or vote is authorized here.
- **Companion governance receipts:** Mosquito PR #10 repair head
  `273fabda1494c35d26a4b74b062d72d65833aa68` passed `30941882521` and merged as
  `ff505c9f64dd3b99bc543f4078eb2e4dddb6a0f1`; Water PR #16 head
  `6c662ad1d8adc964946b19072040eb7108f15348` passed `30940612037` and merged as
  `9e2946ca5f07f0c81eac790ad10dcef0c9f0f3d9`; Phenology PR #10 repair head
  `1fc8e7d60a7009b6f1ec15edc2ee95ce05aa662f` passed `30942442471` and merged as
  `30be615dc438b60e4fa6454973b3b42589b22234`; Plant Diversity PR #16 repair head
  `af89a1556e3d7268cbe1fc6514ccac517e029b99` passed `30942526938` and merged as
  `28fab5b0bb5fa0fb87b7f5bbf4c2aa690cc5b612`. Their first manifest-producing
  checks exposed moving `bslib` resolution, plus `zip` in Phenology; exact
  `bslib@0.11.0` / `zip@3.0.1` pins and fresh cache namespaces closed those
  release-platform failures without changing data or science bytes.
- **Publication receipts:** the four governance merges have green Pages/production
  pairs: Mosquito `30943576642` / `30943578793`, Water `30942884939` /
  `30942886333`, Phenology `30943932550` / `30943933630`, and Plant Diversity
  `30944079772` / `30944081214`. At this snapshot the supplemental merged-default
  full validators `30943578486`, `30943934425`, and `30944081691` were still
  running; no completion is asserted for them in this entry. Their amended PR
  heads had already passed the same full canonical validators.
- **Executable audit:** for each ledger product, ran
  `Rscript --vanilla scripts/audit_suite_compatibility.R ../../repos <product>` in
  its own process. All nine passed exact-commit reads, data/knowledge ancestry,
  required knowledge-package presence, measured-count reproduction, and current
  default data-tree identity. Water explicitly compares `data/neon_swc.rds`; every
  compared Git object must exist, preventing `NA == NA` from becoming a false
  identity receipt. The audit never checks out a sibling ref or runs sibling code.
- **Local validation:** `Rscript --vanilla scripts/test_suite_synthesis.R` passed
  ledger schema, all nine authorities, legacy pins, measured counts, the no-vote
  gate, and the unchanged 510-row/46-site/552-link/12-prior Driver baseline. Both
  new R scripts parse, both edited workflows parse as YAML, `git diff --check`
  passes, and independent adversarial re-review returned **MERGE-READY** with no
  remaining scientific or governance blocker. `scripts/test_helpers.R` is not a
  valid local gate because this Mac runtime lacks `dplyr`; `verify_manifest.R`
  correctly refused local R 4.5.3 against the committed R 4.5.2 platform. Canonical
  Ubuntu 24.04 / R 4.5.2 / dated Posit 2026-07-15 / Haswell / one-thread CI remains
  the authoritative full helper, rebuild, semantic-manifest, and exact-byte proof.
- **Artifact/non-impact receipt:** no `.cascade-rebuild.lock` existed and no local
  Driver rebuild, generation, promotion, backup, or staging operation was run.
  SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Next action:** publish this synthesis through exact-head canonical CI, merge it
  only after the unchanged bytes reproduce, and verify `master`, Pages, and
  production. Then specify the independent current-Phenology v2 adapter and acquire
  pinned discharge feasibility evidence; do not inspect new effects or build a
  complementary app before its recorded reopening gate is met.

### 2026-08-04 20:16 EDT - Driver v2 synthesis publication closeout / [Codex]

- **Changed/classification:** appended the immutable PR, default-branch, Pages,
  and signed-in Connect receipt for the completed Gate 0 synthesis. This entry is
  `suite-platform` publication evidence only; ecological Driver implication is
  explicitly **NONE**. No workflow, source pin, adapter, estimator, schema, prior,
  vote, manifest, generated artifact, or public-surface byte changed after the
  reviewed synthesis head.
- **Exact-head validation and merge:** PR #52 exact head
  `34a1789b11d214862f3e7a3f8dc6ceec092f6b4d` passed canonical run
  `30945187045` / job `92113293064`. The job installed the pinned runtime, verified
  Haswell OpenBLAS with one thread, ran the new synthesis ledger gate and the full
  helper/manifest contract set, fetched all seven recorded siblings detached,
  rebuilt all nine Driver stages, booted the staged app, and reproduced every
  committed scientific artifact exactly. The clean, non-draft exact head merged
  as `a99e0c849998253f47ddd01946f89aedab295418`.
- **Default-branch and companion validators:** merge-head CI `30945683263` / job
  `92114951480` passed the same complete rebuild contract on `a99e0c8`; Pages run
  `30945682541` passed build, deploy, and report on that exact merge. Supplemental
  merged-default validators previously pending in the Gate 0 entry also completed
  successfully: Mosquito `30943578486` on `ff505c9f64dd3b99bc543f4078eb2e4dddb6a0f1`,
  Phenology `30943934425` on `30be615dc438b60e4fa6454973b3b42589b22234`,
  and Plant Diversity `30944081691` on
  `28fab5b0bb5fa0fb87b7f5bbf4c2aa690cc5b612`. No failed step or rerun was hidden.
- **Signed-in Connect receipt:** GitHub-connected publication #111
  (`019fce5a-cb89-1eef-718e-7e6d91c84d40`) published successfully from exact
  source commit `a99e0c849998253f47ddd01946f89aedab295418` at 15:58 EDT in five
  seconds, using Shiny with R 4.5.2. Signed-in history identified that commit and
  the public share URL loaded the Response Atlas with 46 sites and the unchanged
  510-row/12-prior artifact. A real public Shiny session switched from Overview to
  QC and returned the site-specific panel; browser console warning/error logs were
  empty. Connect logs contained only the previously accepted benign
  plotly/shinyjs package-built-under-R-4.5.3 warnings and a successful listener/
  worker connection, with no Startup Error.
- **Live Pages receipt:** the public project page served the expected Response
  Atlas title, launch link, nine companion explorers, 46-site disclosure, four
  measurement layers, construct warning, and attribution. It linked to the same
  public Connect content and produced no browser warning/error log.
- **Reproduction/non-impact:** canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  The formal decision remains **`PASS 10 COMPLETE / DRIVER V2 SIGNAL CHANGES
  HELD / NO CANONICAL BYTE CHANGE`**.
- **Next action:** merge this append-only receipt, then publish the no-look
  Phenology v2 adapter specification before implementing support-only code. In
  parallel, preserve the Continuous Discharge `RELEASE-2026` acquisition plan as
  feasibility evidence only; neither track may inspect effects, add a vote, or
  change Driver artifacts before its recorded gate is independently cleared.

### 2026-08-04 20:43 EDT - Phenology v2 specification review checkpoint / [Codex]

- **Safe branch/base:** resumed on `agent/phenology-v2-adapter-spec`, based on the
  exact Driver receipt merge `928ae23d22bb28b6649bdbec25404e64c4a4dfaa`.
  The post-merge `master` CI run `30963302148` and Pages run `30963301347` both
  completed successfully at that exact head.
- **Draft scope:** created only `docs/PHENOLOGY-V2-ADAPTER-SPEC.md`. It is explicitly
  marked `DRAFT / ADVERSARIAL REVIEW IN PROGRESS — NOT A REGISTRY AUTHORITY`.
  No adapter, effect path, source pin, workflow, manifest, generated artifact,
  canonical Driver byte, deployment, merge, or ecological vote changed.
- **No-look status:** no current-release climate/green-up association, coefficient,
  direction, correlation, rank, interval, or p-value was calculated or inspected.
  Read-only checks were limited to immutable source shape and identity semantics.
- **Open review findings:** the exact current Phenology data tree
  `5a8fd457069d6dcca8dcd0dac9851528509032c6` contains a taxonomically unknown
  observation identity absent from `inds`, plus historical observation `plotID`
  values that can differ from the roster's first-source plot. The draft's initial
  fail-closed wording would reject its own pinned authority and must be replaced
  by an explicit, audited taxonomy-exclusion and visit-plot policy. The review is
  also deciding whether to freeze the primary interval-censored response model in
  this same no-look seal rather than after current support is observed.
- **Next action:** finish the independent scientific review, correct those two
  contracts with `apply_patch`, validate the docs-only diff, and publish a separate
  exact-head no-look PR only when the document can truthfully be marked sealed.
  Do not implement the adapter or expose an effect before that PR merges.

### 2026-08-04 23:15 EDT - Phenology v2 Seal-0 registry ready for publication / [Codex]

- **Changed/classification:** completed the effect-blind Phenology v2 Seal-0
  registry in `docs/PHENOLOGY-V2-ADAPTER-SPEC.md` and aligned the README, Driver v2
  synthesis, and central suite register/backlog. Classification is
  `scientific-contract` and Driver-governance documentation. No adapter, source
  pin, workflow, manifest, generated artifact, public runtime byte, deployment,
  ecological vote, or canonical Driver byte changed.
- **Sealed contract:** the registry fixes separate source-DOY compatibility and
  validated-date v2 clocks; exact duplicate/mixed-status visit handling; the
  narrow taxonomy-null roster exception; historical observation/roster plot
  audit semantics; orthogonal opportunity/censor/support states; exact v1 tie
  parity; conservative earliest-phase interval algebra; context-only leaf-active
  and `thin_greenup`; and a primary Gaussian interval-censored `survreg` response
  with equal species-year cell weights, individual clustering, deterministic
  connected panels, exact fit/prediction gates, and no fallback.
- **Pre-effect/effect boundary:** current v2 compatibility and model support remain
  `UNMEASURED`. Seal 1 is synthetic implementation only; Seal 2 is legacy parity;
  Seal 3A is response-only current support; Seal 3B is a separate values-free
  climate-support mask; Seal 4 may issue only the registered support decision; and
  a later reviewed commit is required to unseal effects. The first effect run is
  limited to the two frozen lag-zero temperature contrasts, with exact
  direction-screen, Holm/BH, REML/Knapp-Hartung, runtime, sensitivity, and claim
  rules. No current v2 response value or effect was calculated, deserialized for
  inspection, printed, ranked, plotted, or summarized in this work.
- **Immutable authorities:** current Phenology data
  `7d0f29f7886cfae1c760a9ffc9e056184ec6fc68`, knowledge/default
  `30be615dc438b60e4fa6454973b3b42589b22234`, generator
  `256989a91d4502feca0b54cea77a24dfe9a02fca`, data tree
  `5a8fd457069d6dcca8dcd0dac9851528509032c6`, manifest SHA-256
  `512737700fdad555264737303439a1816eb189f5ec456e7420aa40dc9165d29b`,
  and legacy pin `81e339e9ed6f34d3d04ca45a7030fea51c4147a5` are frozen. The isolated
  climate-mask source is the canonical Small Mammal origin at commit
  `d2a53282637e4dbd7e5ebef7f64665fa27028531`, exact `data/env` tree
  `3825e1f68fd6c99367d3959b64086a849c57538d`, and 46 archived files; no Driver
  response artifact is an allowed climate source.
- **Independent review:** separate read-only reviewers returned **MODEL-READY**,
  **MERGE-READY**, and **DOCS-READY** after all authority, model, denominator,
  roster/plot, two-clock, support-mask, seal-order, pooling, multiplicity,
  runtime, fixture, hard-failure/abstention, link, and stale-status blockers were
  corrected. Reviewers made no edits and accessed no effects.
- **Validation/non-impact:** `Rscript --vanilla scripts/test_suite_synthesis.R`
  passed; `git diff --check` passed; all four changed-document link targets
  resolve; no `.cascade-rebuild.lock` exists; and the Small Mammal origin/commit/
  tree/46-file assertions resolve locally. A synthetic, non-source `survreg` trial
  had already passed the registered formula, rank, weight, and finite-prediction
  gates; its local package version is not adopted as canonical. No rebuild,
  generation, promotion, stage, backup, or temporary Driver data was created.
  Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Evidence invalidated/residual risk:** the 20:43 draft/checkpoint state and its
  two open source-contract questions are superseded by this reviewed registry.
  No Gate-0, publication, source-shape, app-support, legacy, or canonical-byte
  evidence is invalidated. This narrow documentation scope is not an adapter,
  support receipt, effect result, Driver release, or product completion. The
  registry authority is not immutable until the exact reviewed head passes
  canonical CI and merges to `master`.
- **Next action:** commit and push the exact reviewed docs-only head, open a
  guarded PR to `master`, require exact-head canonical CI, merge only that head,
  and verify default-branch CI/Pages/publication. Then start Seal 1 from the exact
  merge with no current-source support or effect access.

### 2026-08-04 20:38 MST - Phenology Seal-0 publication receipt and literal-head CI correction / [Codex]

- **Publication/classification:** Phenology Seal-0 PR #54 published head
  `381f26e083fe6f9a5ceb08579bc4a60d7260a275` and merged to `master` as
  `61568339de3585db59e0ed73fed2d4b203a29bef`. This is a
  `scientific-contract` publication receipt plus a `suite-platform` CI correction;
  Driver artifact/ecological impact remains **NONE**. No current v2 response,
  support distribution, climate value, association, effect, vote, source pin,
  generated artifact, manifest byte, or public application byte was changed or
  inspected.
- **Exact published-commit evidence:** default-branch push run `30972228069` / job
  `92198882319` checked out exact merge commit `61568339...`, verified the pinned
  Ubuntu 24.04 / R 4.5.2 / 2026-07-15 snapshot / Haswell / one-thread runtime,
  fetched all seven recorded sibling commits detached, completed the full guarded
  nine-stage rebuild and contract suite, and reproduced every committed scientific
  artifact and semantic manifest successfully. Pages run `30972227489` also
  completed successfully on that exact merge. The registry is therefore immutable
  at `61568339...`, and Seal 1 starts from that commit.
- **Corrected PR-CI evidence:** retrospective log inspection found that PR run
  `30971888672` / job `92197832889` used GitHub's synthetic PR merge revision
  `0785cf7b1174db04de4dbffbc50c4803ad35725e`, not literal submitted head
  `381f26e...`, because `.github/workflows/ci.yml` checked out
  `${{ github.sha }}` on `pull_request`. Its green result is valid merge-simulation
  evidence but is not exact-head evidence; any earlier description of that PR run
  as literal-head validation is superseded by this correction. The subsequent
  exact published-commit run above supplies the canonical scientific proof, so no
  rollback or artifact regeneration is required.
- **Workflow repair staged for Seal 1:** branch `agent/phenology-v2-seal1` was
  created directly from exact `61568339...`. CI now derives `SOURCE_SHA` from
  `${{ github.event.pull_request.head.sha || github.sha }}`, checks out that
  revision, and immediately asserts `git rev-parse HEAD == SOURCE_SHA`. The first
  Seal-1 PR run must prove from its logs that this guard executes the literal head
  before the PR can merge.
- **Non-impact receipt:** no `.cascade-rebuild.lock` exists and no local rebuild,
  generation, promotion, backup, or staging operation ran. All five canonical
  Driver hashes remain those recorded in the preceding entry.
- **Next action:** checkpoint the literal-head workflow repair, then implement the
  three isolated Seal-1 modules and independent synthetic tests on this branch.
  Do not deserialize current or legacy Phenology bundles, create Seal-3 receipts,
  source effect code, or expose any new response/climate/effect value.

### 2026-08-04 21:54 MST - Phenology v2 Seal-1 implementation candidate / [Codex]

- **Safe base and code authority:** branch `agent/phenology-v2-seal1` starts from
  exact merged Seal-0 authority
  `61568339de3585db59e0ed73fed2d4b203a29bef`. Literal-head checkout repair was
  checkpointed as `2cc02149fc8f96e1b7463e48ef4217bf6608dd85`; the complete
  reviewed Seal-1 implementation is commit
  `ff643116678e8115d8817268913c6c4408838bf1`. Publication remains pending the
  first PR run that proves both jobs executed this branch's literal head.
- **Changed/classification:** added `R/phenology_adapter_v2.R`,
  `R/phenology_response_model_v2.R`,
  `R/phenology_climate_support_mask_v2.R`,
  `scripts/test_phenology_adapter_v2.R`, the exact runtime receipt at
  `docs/receipts/phenology-v2-seal1-runtime.json`, and an isolated Seal-1 CI job.
  This is `scientific-contract` implementation plus `suite-platform` validation.
  It changes no source pin, published data schema, prior, vote, manifest entry,
  generated Driver artifact, app runtime, or public-surface byte.
- **Pure adapter:** the synthetic-only Driver-owned adapter implements the frozen
  source/date two-clock contract, exact duplicate and mixed-status visit rules,
  conservative earliest-phase censor envelope, roster/taxonomy/plot audits,
  recurrent connected panels, compatibility and v2 annual support, context-only
  leaf-active support, exact 510-row/46-site calendar topology, and a direct
  adapter-to-response schema. Climate/effect-like bundle, column, calendar, and
  audit payloads fail closed.
- **Response and mask isolation:** the sole response model is the registered
  Gaussian interval-censored `survreg` with equal species-year cell weights,
  stable individual clustering, exact controls, full-rank and covariance gates,
  two-fit determinism, full species-by-year latent predictions, and equal-species
  annual medians. The response-presence projection is values-free and enforces the
  six-year eligibility gate. The separate climate builder accepts only that
  boolean mask and allowlisted monthly climate input, applies exact completeness,
  range, and equality-retaining within-site MAD rules, and emits only keyed
  booleans, counts, and opaque digest material. Neither module can call an effect.
- **Runtime authority:** canonical execution is Ubuntu 24.04 / R 4.5.2 / Posit
  2026-07-15 / Haswell OpenBLAS / one thread. The receipt pins
  `survival 3.8-9` archive SHA-256
  `741f925dca22ef8f0aa67f798df19148ad56be3b09e8c8eea09e351ac5f99282`,
  `metafor 5.0-1` archive SHA-256
  `953f1a43794a9d660225cad666849f1100263e5cad486fb8becc1ad32f81e73f`,
  and the complete 20-package hard-dependency inventory digest
  `f94392ce27024f6c7828ade4c3ff025f618d08e90ef68210fa3fed68f7c7d01a`.
  CI re-downloads and hashes both source archives, reconstructs dependency
  closure, and checks the loaded OS/R/BLAS/thread identity before testing.
- **Synthetic verification:** 38 fixture families pass across two clean
  `static-lock`, two clean `adapter-response`, and two clean `climate-mask`
  processes. Stdout and stderr reproduce byte-for-byte. The response processes
  also emit only opaque SHA-256 receipt
  `188dca20ce8e3373e88233025336fcede6008941cb005a88952226d7cd1ae239`
  locally over canonical model rows, every full-grid species-year latent
  prediction, annual responses, and diagnostics; both production prediction
  vectors are exactly identical and every value agrees with the independent
  numerical oracle within the registered tolerance. The fit object and response
  values are never printed.
- **Adversarial coverage:** fixtures cover exact interval algebra, all registered
  status/state vocabularies, same-visit conflicts, source/date disagreement,
  left/right censoring, roster exceptions and failures, recurrent/panel/support
  boundaries, factor coding, warnings/nonconvergence/covariance/range failure,
  response/mask eligibility contradictions, leaf-active and coverage boundaries,
  monthly completeness/range/MAD equality, order and locale invariance, malformed
  schemas, whitespace identities, ALTREP/dimensioned columns, payload smuggling,
  effect-function aliasing, and generated-artifact nonmutation. Independent
  architecture and runtime reviews found no remaining P0/P1/P2 contract defect.
- **No-look receipt:** no current or legacy Phenology RDS was checked out,
  deserialized, summarized, modeled, or repaired during Seal 1. CI verifies only
  immutable Git commit/tree/manifest identities without checking out Phenology
  data. No new response support, response value, climate pair, association,
  coefficient, sign, rank, interval, p-value, effect, or vote was accessed or
  exposed. Current v2 compatibility/model support remains `UNMEASURED` and every
  effect path remains sealed.
- **Local validation/non-impact:** the full six-process orchestrator,
  `scripts/test_suite_synthesis.R`, parsing of all four new R/test files, workflow
  YAML parsing, runtime-receipt JSON parsing, inventory-digest reconstruction, and
  `git diff --check` passed. No `.cascade-rebuild.lock` exists; no local rebuild,
  generation, promotion, backup, staging, or Phenology-data operation ran.
  Canonical SHA-256 values remain cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Next action:** commit the aligned registers/handoff, push the exact branch,
  open a guarded PR, require literal-head Seal-1 plus full canonical rebuild CI,
  merge only that head, and verify exact merged-default CI and Pages. After a
  publication receipt, begin only Seal 2 against legacy pin `81e339e9...`; do not
  inspect current response/effect output to repair parity or begin Seal 3 early.

### 2026-08-04 22:02 MST - Seal-1 PR #55 first-run CI parser repair / [Codex]

- **Exact failed evidence:** draft PR #55 ran exact literal head
  `593140eed242c93ebcb0dec0af53b775693b48a5` in workflow run
  `30976845525`. Job `phenology-v2-seal1-synthetic` / `92212514600` reached
  the locked Ubuntu 24.04 / R 4.5.2 / Haswell / one-thread runtime and then
  failed in `Verify the complete sealed runtime lock` with
  `ValueError: not enough values to unpack (expected 4, got 1)`. The synthetic
  adapter/model/mask suite did not run, so this failed job is not Seal-1 evidence.
  The concurrent canonical rebuild job was still running when the failure was
  diagnosed; no result is claimed for it here.
- **Root cause and narrow repair:** the embedded R inventory emitter lives inside
  a Python raw string, but its tab, unit-separator, newline, and CR/LF escapes were
  double-escaped. R therefore printed literal escape text rather than four
  delimiter-separated fields. The workflow-only repair uses the intended single
  R escapes `\t`, `\037`, `\n`, `\r`; it changes no runtime authority,
  inventory value/digest, dependency rule, adapter/model/mask code, fixture,
  source identity, artifact, or ecological disposition.
- **Local regression:** an exact-framing probe executed the repaired embedded R
  emitter through Python and parsed 4/4 installed-package rows into four fields,
  with three dependency subfields per row. Workflow YAML parsing and
  `git diff --check` pass. Canonical CI must still prove the complete 20-package
  inventory and all Seal-1 contracts on the amended literal head.
- **Next action:** commit and push the workflow-only repair, update PR #55 to its
  new exact head, and require fresh literal-head success from both jobs. Do not
  rerun the failed job against the superseded head or merge partial evidence.

### 2026-08-04 22:09 MST - Seal-1 PR #55 hard-closure correction / [Codex]

- **Exact failed evidence:** amended literal head
  `490ff71d9919f40c80761a03b4e8f3d6f88b993b` ran as
  `30977182631`. The repaired framing passed and job
  `phenology-v2-seal1-synthetic` / `92213534519` then failed closed with
  `runtime lock omits hard dependencies: ['compiler']`. The job again stopped
  before the synthetic contract suite, so it is not Seal-1 evidence. Its
  concurrent canonical rebuild result is not reused after the head changes.
- **Root cause:** the receipt's 20-row inventory omitted R base package
  `compiler`. Exact installed DESCRIPTION traversal exposes the chain
  `metafor -> pbapply -> parallel -> compiler`; local R independently confirms
  `parallel` imports `tools, compiler`. Because the registered inventory includes
  implicit base packages and all `Depends`/`Imports`/`LinkingTo` closure, omission
  is a receipt defect rather than an allowable installer-only exclusion.
- **Narrow authority correction:** add radix-ordered row
  `compiler<TAB>4.5.2<TAB>base<TAB>r-4.5.2-base` between `base` and `digest`.
  The corrected 21-row canonical inventory SHA-256 is
  `b2263019cdcd50af0230c0fb69b1422ef064e55b2ecbe521bde6548cb9846f0f`.
  This supersedes the earlier 20-row / `f94392ce...` inventory claim. The direct
  `survival`/`metafor` versions and archive hashes, OS/R/snapshot/BLAS/thread
  authority, scientific implementation, tests, no-look boundary, and all Driver
  artifact hashes remain unchanged.
- **Next action:** independently verify the corrected row/digest, commit and push
  the receipt plus CI expectation and this append-only correction, and require a
  third fresh literal-head run. Merge no partial or superseded evidence.

### 2026-08-04 22:17 MST - Seal-1 PR #55 cross-platform MAD-fixture repair / [Codex]

- **Exact failed evidence:** corrected-closure head
  `2999ccbaacce69fdd8d555ea8fa257308bf032ad` ran as
  `30977613684`. Job `phenology-v2-seal1-synthetic` / `92214882028`
  passed the complete 21-package runtime lock, immutable Phenology identity-only
  gate, all adapter/response fixtures, and two clean Ubuntu response processes.
  Their opaque full-grid numerical receipt was
  `496d1465d7da21be60f9ba0b929ca34b6b7e3fd52ae5eaf0b4e44469e3857a73`
  and reproduced byte-for-byte inside that canonical job. The job then failed
  only `equality-retained MAD boundary is invariant to monthly row order` in
  fixture 37; its concurrent rebuild result is not reused after the head changes.
- **Root cause:** one fixture asked a deliberately ill-conditioned decimal monthly
  vector to do two jobs: expose order-sensitive summation and land exactly on the
  six-degree inclusive MAD boundary. Canonical month ordering worked, but the
  constructed annual mean rounded just above six on Ubuntu while landing on six
  locally. That is a platform-sensitive synthetic-fixture assumption, not a
  production algorithm or threshold failure.
- **Test-only correction:** retain the ill-conditioned vector solely to require
  identical ordered/reversed support, counts, and digest material, without
  asserting its platform-specific MAD classification. Add a separate exact
  six-year boundary fixture with five years of monthly zero and 2023 monthly six.
  Both values are exactly representable; for both registered contrasts the median
  and MAD are zero, threshold and deviation are exactly six, and the frozen `<=`
  rule must retain the year. Ordered/reversed support, counts, and digests must
  also match.
- **Independent/local verification:** fixture review found no contract issue and
  confirmed that the split preserves both the floating-order stress test and the
  exact inclusive-boundary test. Climate-only and full six-clean-process runs pass
  locally with unchanged opaque local response receipt `188dca20...`; all five
  generated artifact hashes remain unchanged. No production module, runtime pin,
  source authority, response/effect boundary, or Driver ecological decision
  changed.
- **Next action:** commit and push only the corrected fixture plus this failure
  receipt, update PR #55 to the fourth exact head, and require both jobs to rerun
  from scratch. Merge no result attached to a superseded head.

### 2026-08-04 22:35 MST - Phenology v2 Seal-1 publication receipt / [Codex]

- **Exact reviewed authority:** PR #55 exact head
  `35c2ca79a135303c00027dd32d9dd961a07bca2a` passed literal-head workflow run
  `30977899036`: `phenology-v2-seal1-synthetic` job `92215796752` and
  `rebuild-contracts` job `92215796821` both succeeded. GitHub's exact-head merge
  guard then merged only that head as master authority
  `6cb1e9e8a0fce646ced26ee296cf8ee75d991f4d` at 2026-08-04 22:29 MST.
- **Merged-default validation:** push run `30978285438` checked out and asserted
  literal merge SHA `6cb1e9e8...`. Seal-1 job `92217038888` passed the complete
  21-package runtime lock, immutable identity-only gate, and all 38 fixture
  families twice across six isolated clean processes. Rebuild job `92217038849`
  fetched the seven recorded sibling commits detached, reproduced every canonical
  artifact exactly, reproduced the deploy manifest semantically, and passed the
  whitespace gate.
- **Runtime and numerical receipts:** the canonical lock remains Ubuntu 24.04 / R
  4.5.2 / Posit Package Manager 2026-07-15 / Haswell OpenBLAS / one thread, with
  21-row hard-closure digest
  `b2263019cdcd50af0230c0fb69b1422ef064e55b2ecbe521bde6548cb9846f0f`.
  Canonical Ubuntu response processes reproduced opaque full-grid receipt
  `496d1465d7da21be60f9ba0b929ca34b6b7e3fd52ae5eaf0b4e44469e3857a73`
  byte-for-byte within each Seal-1 job. That isolated path printed or promoted no
  fit, prediction, response value, or effect.
- **Pages/publication:** Pages run `30978284811` built and deployed exact merge
  `6cb1e9e8...`; build job `92217038921`, status job `92217111182`, and deploy job
  `92217111221` succeeded. The public root
  `https://tgilbert14.github.io/NEON-Driver-Cascade/` returned HTTP 200 after
  deployment. Seal 1 changed no public app/runtime byte, so no Connect deployment
  was required or attempted.
- **No-look/effect-lock receipt:** the isolated Seal-1 synthetic jobs and this
  documentation-only receipt checked out, deserialized, summarized, modeled, or
  inspected neither current nor legacy Phenology RDS. No current v2
  response/support/effect value was accessed and no v2 effect code ran; current v2
  compatibility/model support remains `UNMEASURED`; all v2 effect paths remain
  sealed. The separate canonical `rebuild-contracts` jobs necessarily exercised
  the unchanged published v1 builder against its recorded legacy pins; that is
  exact artifact-reproduction evidence only, not Seal-1 data access or a new v2
  effect. This scoped receipt supersedes any unscoped reading of earlier
  shorthand no-look claims.
- **Driver impact:** `NONE`. No source pin, prior, vote, eligible row, manifest
  entry, generated artifact, or ecological disposition changed. Canonical SHA-256
  remains cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`,
  search `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`,
  meta `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`,
  codebook `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`,
  and manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Next action:** publish this documentation-only receipt, then branch Seal 2
  from its exact merge. Seal 2 may access only exact legacy pin `81e339e9...` for
  registered sections 8.3/9.3 parity. Current response/effect output and every
  effect execution remain forbidden until their separately reviewed later gates.

### 2026-08-04 23:34 MST - Phenology v2 Seal-2 legacy schema HOLD candidate / [Codex]

- **Published receipt base:** receipt PR #56 exact head
  `a26428a66a7e8dcadf9fa26c4f42d870a6ff36be` merged as
  `c952687399abfef9c155ccaf207b83a79ea698a4`. PR run `30979039907` passed
  rebuild job `92219313582` and Seal-1 job `92219313600`; post-merge run
  `30979297006` passed Seal-1 job `92220080404` and rebuild job `92220080424`.
  Pages run `30979295789` passed build `92220078640`, deploy `92220171068`, and
  status `92220171073`; the public root returned HTTP 200.
- **Seal-2 boundary exercised:** the candidate acquired only exact legacy commit
  `81e339e9ed6f34d3d04ca45a7030fea51c4147a5` and its `data/sites` tree
  `30abe869b0f78931929c21e544ffc85ec2238e35`. It schema-scanned all 46 legacy
  bundles before any registered parity comparison. Forty-five bundles had a
  nonempty `trend`; one bundle had a typed, non-`NULL` `trend` with every required
  column and zero rows.
- **Registered stop:** the frozen validator correctly raised its registered hard
  failure `empty_required_table`. Formal sections 8.3/9.3 parity was **NOT
  ATTEMPTED**. A manual diagnostic adapted one nonempty legacy bundle
  successfully, but that single-bundle result proves no full-set count, key,
  tolerance, or digest parity and is explicitly not parity evidence.
- **Isolation receipt:** `current_fetched = false`, `current_deserialized = false`,
  `effect_module_sourced = false`, and `effect_function_called = false`. These
  no-current/no-effect claims apply to the isolated Seal-2 gate only. The existing
  canonical rebuild separately uses its recorded legacy v1 pins, so it is exact
  v1 artifact-reproduction evidence rather than a no-look gate.
- **Implementation/classification:** scientific-contract + suite-platform CI;
  Driver impact decision `NONE / HOLD`; no app-local change. The new two-VM gate
  fetches the literal legacy SHA in an empty object database, exports only the
  verified 46-file site tree plus a values-free receipt, destroys the object
  database, and runs the restricted parity surface without network access. The
  parity job waits for legacy acquisition, the unchanged canonical rebuild, and
  the unchanged Seal-1 suite. The HOLD path stops before adapter sourcing,
  baseline deserialization, oracle/model work, or any effect path.
- **Local and independent validation:** R parse, runner `--static`, runner
  `--synthetic`, the exact 46-bundle legacy gate, and the unchanged full Seal-1
  38-fixture/six-process suite passed. The real gate emitted exactly one ordered
  HOLD JSON object and zero stderr bytes. The synthesis-ledger and manifest-
  comparator fixtures, JavaScript syntax, YAML parse, all seven new shell blocks,
  all four workflow Python blocks, immutable action-pin review, canonical hashes,
  and `git diff --check` passed. Independent review improved the boundary so
  reordered and duplicate-key JSON are rejected; expected HOLD and the latent
  PASS schema remain accepted. Local `verify_manifest.R` correctly refused the
  host R 4.5.3 versus sealed R 4.5.2 mismatch, and the host Python 3.9.6 cannot
  execute the existing Python-3.10+ trusted-publish fixture; exact Ubuntu 24.04 /
  R 4.5.2 CI remains required before merge.
- **Cleanup/residual risk:** the acquisition object database and archive were
  destroyed immediately; the extracted temporary legacy payload and validation
  outputs were deleted after the final HOLD check and are not recoverable from
  this workspace. The one typed-empty source bundle prevents registered parity;
  CI viability of the hosted network namespace and exact sealed runtime remains
  to be demonstrated on the candidate head.
- **Contract and Driver impact:** `HOLD / NONE`. The adapter, frozen
  `docs/PHENOLOGY-V2-ADAPTER-SPEC.md`, canonical artifacts, and every Driver
  ecological disposition remain unchanged. Canonical SHA-256 remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  Seal 3 remains sealed.
- **Publication identity:** this is the local HOLD candidate record; no PR, run,
  or merge identity is claimed for it.
- **Next action:** publish this HOLD gate. If the typed-empty legacy schema needs
  an amendment, introduce it only as a new, separately reviewed registry stage;
  never silently normalize or rewrite the frozen contract. Current response
  support and every effect path remain forbidden until their later explicit gates.

### 2026-08-05 04:15 MST - Phenology v2 Seal-2 HOLD publication receipt / [Codex]

- **Publication/classification:** scientific-contract + suite-platform CI;
  Driver impact `NONE / HOLD`; no app-local change. PR #57 exact reviewed head
  `acd08543bf0566b4dc87763dbe10efc2495f3dc2` merged only after its required
  checks as `a10c8ff75a88fed1043162325e19325901167020`.
- **Exact-head evidence:** PR run `30982533042` passed canonical rebuild job
  `92229861895`, exact legacy acquisition job `92229862026`, unchanged Seal-1 job
  `92229862050`, and isolated Seal-2 job `92230756400`. The Seal-2 log emitted
  `HOLD`, `bundles=46`, `affected=1`, `code=empty_required_table`, and
  `parity_attempted=false`; `current_fetched`, `current_deserialized`,
  `effect_module_sourced`, and `effect_function_called` were all false. The
  registered 21-package runtime digest remained
  `b2263019cdcd50af0230c0fb69b1422ef064e55b2ecbe521bde6548cb9846f0f`.
- **Merged-default evidence:** run `30982973823` passed acquisition job
  `92231270151`, canonical rebuild `92231270214`, Seal-1 `92231270259`, and the
  networkless Seal-2 HOLD job `92232268414` on literal merge `a10c8ff...`. The
  merged HOLD receipt repeated exactly: 46 checked, one affected,
  `empty_required_table`, parity not attempted, and all four current/effect flags
  false. Rebuild reproduction and all five canonical hashes remained unchanged.
- **Pages/publication:** Pages run `30982972991` passed build `92231270574`, status
  `92231369592`, and deploy `92231370607` on the same merge. The public Driver root
  returned HTTP 200 after deployment. Seal 2 changed no Driver app/runtime byte,
  so no Connect deployment was required or attempted.
- **Scoped conclusion:** Seal 2 is published as `HOLD`; it did not prove sections
  8.3/9.3 parity. The isolated gate fetched or deserialized no current Phenology
  family and sourced or called no effect path. The separate canonical rebuild
  continued to use recorded legacy v1 pins solely for exact v1 reproduction.
  Current compatibility/model support remains `UNMEASURED`; Seal 3 and every v2
  effect remain sealed.
- **Next action:** do not normalize the typed-empty table or edit the frozen
  registry in place. Either introduce a new, separately reviewed legacy-only
  schema-amendment registry stage, or leave Phenology held and proceed to the
  already authorized discharge feasibility evidence task. No new Driver vote or
  canonical byte is authorized.

### 2026-08-05 09:12 MST - Continuous Discharge Gate F0 no-look candidate / [Codex]

- **Prerequisite receipt closure:** Phenology Seal-2 receipt PR #58 exact head
  `251e989b4f2e280a1f9672ef1c3fb792e66ce027` passed run `31016236215` and
  merged as exact master `609894461fde057fd9d32e3f7d6abadb50bc546a`.
  Merged-default run `31016815527` and Pages run `31016812195` passed, and the
  public root returned HTTP 200. That closes the preceding publication receipt;
  current Phenology response/effects and Seal 3 remain sealed.
- **Classification and authority boundary:** scientific-contract + suite-platform
  candidate; Driver impact `NONE`; no app-local change. F0 freezes only a
  pre-payload specification, pure in-memory reducer, synthetic fixtures, exact
  values-free response-key ledger, and metadata-only authority verifier. It
  authorizes no authenticated discharge request, F1 inventory, payload fetch,
  estimator, app, effect, prior, vote, rebuild, or generated Driver byte. F1
  remains unauthorized until a follow-up receipt binds the exact reviewed F0
  merge and Pages publication and is itself merged and Pages-verified.
- **Frozen release identity:** Continuous Discharge `DP4.00130.001`,
  `RELEASE-2026`, expanded UUID
  `c28725ff-5aa2-41fa-845e-a7f1c8239d09`, generation
  `2026-01-23T00:07:49Z`, DOI `https://doi.org/10.48443/4n6c-gc44`, and
  availability manifest `manifest-available-20260123T000738Z.json` / `2779477`
  bytes / MD5 `33c04c0f24dba030d3082acf704e2c56`. F1 may eventually inspect only the
  authenticated availability/file manifest and independently reviewed
  non-observation schema-metadata allowlist; observation-table URLs remain
  sealed until a later, separately reviewed F2 authority.
- **Exact response authority and honest provenance:** the committed two-column
  ledger `docs/receipts/discharge-inverts-response-site-years.tsv` is SHA-256
  `79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296` and Git
  blob `c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8`. It freezes exactly 210 sorted
  `(siteID, utc_calendar_year)` keys at 24 exact stream sites, 23 with at least
  six response years, from Inverts authority
  `ff23e994e289982c747b91e48c5ff0907c1672d2`, root tree
  `b09c9b54aa5b81290ab6a2dc98072421eae66b03`, `data` tree
  `812be54ac172fe2febaa5a192f90070e87e3fbf0`, and `data/sites` tree
  `080534caad4eb76cdaf0b5a56704ed4e890ed16a`. The earlier one-time manual
  projection necessarily deserialized monolithic Inverts bundles but did not
  index, aggregate, or log ecological outcome fields. That derivation is frozen
  provenance, not an authorized method: F0/F1/F2 may not fetch or deserialize an
  upstream Inverts RDS blob.
- **Scientific contract:** the primary quantity is only
  `qc_pass_record_present_in_utc_year`, left-anchored to every eligible response
  key and retaining explicit `FALSE`. Finite zero qualifies; missing, nonfinite,
  absent, or flagged values do not. The corrected 15-minute and historical
  uncorrected 1-minute tables have exact field/QC predicates, UTC calendar clock,
  ordinary `2021-10-01T00:00:00Z` and BIGC-only
  `2020-10-01T00:00:00Z` cutovers, and chronology-first failure. TOMB fails before
  ordinary schema/QC projection; TOOK remains excluded pending a named-location
  crosswalk. Total five-state Inverts projection and zero-inclusive TOMB/TOOK
  exclusion receipts are retained. Corrected-only and water-year results are
  non-rescuing sensitivities. Machine `REOPEN_REVIEW` / `HOLD` map exactly to
  `REOPEN INDEPENDENT REVIEW` / `HOLD / DO NOT BUILD`; clearing `3 sites x 6
  years` reopens review only and never a build.
- **No-look CI:** two new sparse jobs assert literal `SOURCE_SHA`, remove checkout
  credentials/remotes, inventory every path/mode/SHA before and after, and run in
  a verified empty Linux network namespace with a session-owned `0700` temporary
  directory. The synthetic job checks only the two R scripts. The authority job
  fetches the exact Inverts commit/tree graph with `--filter=blob:none`, asserts
  zero local blob objects before and after, removes its remote, sets
  `GIT_NO_LAZY_FETCH=1`, and reads only the committed TSV. Both jobs destroy only
  their exact owned temporary paths on success or failure and publish no
  artifacts.
- **Adversarial review and invalidated drafts:** independent CI/security,
  science, and documentation/register reviews are clean. Review caught and fixed
  an initial counts-only authority check that could accept the wrong years, TOMB
  schema validation that ran before the special-site short circuit, missing
  executable human-disposition mapping, and stale overlap/exclusion/F1 wording.
  The final fixtures mutate one exact year, exercise a TOMB-only special shape,
  assert chronology-first overlap, exact exclusion tokens, total zero-count
  states, response-anchored `FALSE`, and both sides of the review floor. An
  earlier draft whole-bundle RDS verifier is invalidated and absent; repeating
  that derivation is forbidden.
- **Local verification and environment limits:** `Rscript --vanilla
  scripts/test_discharge_feasibility_contract.R`,
  `scripts/test_suite_synthesis.R`, `scripts/test_manifest_compare.R`, and parse
  checks for all three F0 scripts passed. A locally constructed metadata-only
  repository contained commits/trees and zero blobs; with its remote removed and
  `GIT_NO_LAZY_FETCH=1`, `scripts/test_discharge_inverts_authority.R` passed the
  exact commit/tree/ledger/key assertions before the exact temporary directory
  was destroyed. Bundled Python 3.12.13 passed `scripts/test_trusted_publish.py`;
  JavaScript syntax, workflow YAML (`6` jobs), all `30` workflow shell blocks,
  local Markdown links, ledger counts/hash/blob, and `git diff --check` passed.
  Host `test_boot_integrity.R` could not exercise its intended fixture because
  this local R library lacks `shiny`; the literal Ubuntu 24.04 / R 4.5.2
  canonical rebuild remains required CI evidence rather than being weakened or
  represented as a local pass.
- **Cleanup and non-impact:** no discharge API request, credential, capability
  URL, manifest response, observation payload, discharge value, or upstream RDS
  blob was fetched, logged, retained, or committed in this session. No local
  rebuild, generation, promotion, backup, or staging ran; no rebuild lock exists.
  The metadata-only test directory was deleted after its zero-blob receipt.
  Canonical SHA-256 remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Publication status/residual risk:** this is a reviewed local candidate; no F0
  PR, CI run, merge, or Pages identity is claimed yet. Hosted-network namespace,
  GitHub partial-clone behavior, exact canonical rebuild reproduction, and Pages
  publication must still pass on the literal candidate head. Discharge support
  remains `UNMEASURED`.
- **Next action:** commit and push this exact F0 candidate, open a guarded PR,
  require every literal-head job to pass, merge only that reviewed head, then
  verify merged-default CI, Pages, and HTTP 200. Publish a separate follow-up
  receipt binding those exact identities before authorizing any F1 inventory.

### 2026-08-05 09:35 MST - Continuous Discharge F0 implementation publication / append-only receipt candidate / [Codex]

- **Classification and current authority:** documentation-only publication
  receipt candidate for the scientific-contract + suite-platform F0
  implementation; Driver impact `NONE`; no app-local change. The implementation
  is published, but F0 is **not yet passed** and F1 remains unauthorized until
  this append-only receipt itself passes review, merges, passes merged-default
  CI, and publishes through Pages with a public HTTP 200 check.
- **Exact reviewed implementation:** PR #59 exact head
  `0a8b71ccb3c5f47c13a1f7f59d73dd2a297e6d5e` passed exact-head run
  `31024370208`. All six jobs succeeded: authority `92368904355`, Seal 1
  `92368904384`, discharge synthetic `92368904417`, Phenology acquisition
  `92368904433`, canonical rebuild `92368904457`, and Seal 2 HOLD
  `92370103528`.
- **Exact merge and default-branch evidence:** only the reviewed head merged as
  `28f00ecef8091a41af58db3f82ef9519ce940ceb`. Merged-master run
  `31024947729` repeated all six successful jobs: rebuild `92370870240`,
  authority `92370870294`, Seal 1 `92370870359`, acquisition `92370870396`,
  discharge synthetic `92370870524`, and Seal 2 HOLD `92372099261`.
- **Pages and public evidence:** Pages run `31024946671` passed build
  `92370871661`, status `92370999666`, and deploy `92370999669` on exact merge
  `28f00ece...`. The public Driver root returned HTTP 200 after deployment.
- **Connect decision:** no Connect deployment was required. The base-to-merge
  comparison was byte-identical for `global.R`, `ui.R`, `server.R`, every
  tracked file under `R/` and `www/`, all 12 manifest-listed runtime files, the
  four generated data artifacts, and the manifest. The F0 files live outside
  the deployed Driver runtime payload.
- **Scientific and acquisition boundary:** no discharge credential, capability
  URL, manifest response, observation table URL, payload, value, token, or
  upstream Inverts RDS blob was accessed, logged, retained, or committed.
  Discharge support remains `UNMEASURED`; publication of implementation code
  supplies no ecological result, effect, prior, vote, app, or Driver signal.
  The frozen `docs/DISCHARGE-FEASIBILITY-SPEC.md`, reducer, CI, tests, and exact
  values-free response ledger are unchanged by this receipt candidate.
- **Non-impact receipt:** canonical SHA-256 remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Receipt status and next action:** this entry records implementation
  publication only; the current documentation commit has no PR, run, merge, or
  Pages identity yet. Commit and push this exact append-only receipt, require its
  literal-head CI, merge only that reviewed head, then verify merged-default CI,
  Pages, and public HTTP 200. Only that published receipt may mark F0 passed and
  authorize a separate F1 metadata-inventory branch. F2, observation payloads,
  all metrics/effects, a new app, and every Driver byte change remain forbidden.

### 2026-08-05 10:05 MST - Continuous Discharge F0 receipt published / F1 metadata inventory authorized / [Codex]

- **Classification and authority transition:** scientific-contract +
  suite-platform documentation receipt; Driver impact `NONE`; no app-local
  change. F0 is now **passed**, and its append-only publication receipt is
  published. Current
  authority stops at F1's authenticated, values-free file inventory and the
  explicitly reviewed non-observation schema-metadata allowlist. F2,
  observation-table bytes, support conclusions, metrics, effects, priors, votes,
  apps, rebuilds, and every Driver byte change remain unauthorized. Discharge
  support remains `UNMEASURED`.
- **Exact receipt head:** PR #60 exact head
  `8954c1f8934356c1c1c41706c35cc42680a8b027` passed all six jobs in exact-head
  run `31026452964`: authority `92376064326`, canonical rebuild `92376064382`,
  Seal 1 `92376064421`, Phenology acquisition `92376064426`, discharge
  synthetic `92376064466`, and Seal 2 parity HOLD `92377263455`.
- **Exact merge and default-branch evidence:** only that reviewed head merged as
  `b75996a85809ed0cd8ba89121e0de18e22063cc7`; its parents are exact prior
  `master` `28f00ecef8091a41af58db3f82ef9519ce940ceb` and exact reviewed head
  `8954c1f...`, and its tree is the reviewed-head tree
  `8e7b774da4fc8486fb3c41e790317c61d5af9379`. Merged-master run
  `31027151110` independently passed rebuild `92378424553`, Phenology
  acquisition `92378424569`, discharge synthetic `92378424583`, authority
  `92378424588`, Seal 1 `92378424748`, and Seal 2 parity HOLD `92379479040`.
- **Pages and public evidence:** Pages run `31027144433` passed build
  `92378404954`, status `92378564211`, and deploy `92378564233` on exact merge
  `b75996a...`. The public root returned HTTP 200, and its served
  `docs/index.html` bytes matched the exact merge at SHA-256
  `0187780bc9986530b6ed0d49daf82f52986b9f61a88993f3e52cbe7736b0918b`.
- **Frozen contract and response authority:** the preregistered specification is
  still exact Git blob `643dbaa3489bb8100de691b2de0ead124f842502` / SHA-256
  `831baf97f6558a7d0bccacb401880929ffccd7a6ebf210b8ee70d536db298ac7`.
  The response ledger remains exact Git blob
  `c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8` / SHA-256
  `79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296`,
  with exactly 210 keys at 24 sites and 23 sites having at least six response
  years. The frozen specification's earlier candidate wording is preserved as
  preregistration history; mutable registers carry the current authority.
- **F1-only acquisition boundary:** F1 may authenticate at runtime for exact
  `DP4.00130.001` / `expanded` / `RELEASE-2026`, inventory sanitized site-month
  file identities, and fetch only explicitly registered non-observation
  metadata. It must never follow an observation-table URL, expose or retain a
  token or signed capability, publish a raw manifest response, infer record
  support from availability, or inspect an Inverts RDS blob. Any F1 receipt must
  be independently verified and published before separate F2 authorization.
- **Secret and implementation state:** the Driver repository currently has no
  configured `NEON_TOKEN` repository secret. No API request was attempted and no
  credential was copied from another repository. This F1 branch may therefore
  implement and adversarially test the F1 contract offline only; a protected,
  manually dispatched acquisition remains blocked on a Driver-owned runtime
  secret and a separately reviewed exact implementation merge.
- **Connect and non-impact receipt:** no Connect deployment was required because
  no app/runtime, generated artifact, or manifest byte changed. Canonical
  SHA-256 remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Next action:** publish offline F1 producer, independent verifier, synthetic
  adversarial tests, and manual protected workflow as a separately reviewed PR.
  After exact-head and merged-master verification, provision the Driver-owned
  environment secret, dispatch only from the protected exact `master`, delete
  all raw material, and publish only route-free sanitized receipts to a draft
  review PR. F2 remains sealed until that exact receipt independently passes.

### 2026-08-05 11:07 MST - Continuous Discharge F1 offline implementation candidate / no authenticated acquisition / [Codex]

- **Classification and gate boundary:** scientific-contract + suite-platform F1
  implementation candidate; Driver impact `NONE`; no app-local or runtime
  change. Exact F0 authority remains receipt merge
  `b75996a85809ed0cd8ba89121e0de18e22063cc7` / tree
  `8e7b774da4fc8486fb3c41e790317c61d5af9379`. F1 is authorized only for the
  reviewed manifest and non-observation metadata inventory. No authenticated
  F1 acquisition has run; F2, observation bytes, support/effect calculations,
  adapters, priors, votes, apps, and Driver-byte changes remain unauthorized.
  Discharge support remains `UNMEASURED`.
- **Public release-window recheck:** an unauthenticated, release-filtered read of
  the official `DP4.00130.001` product record established that the exact frozen
  24-site roster is present and its `RELEASE-2026` availability spans
  `2016-08` through `2024-09`. Only that safe aggregate was printed; no raw
  response, token, signed route, file manifest, or data byte was retained. The
  authenticated `/data/query` endpoint was not called.
- **Offline implementation:** added a pure producer contract, one isolated
  network acquisition process, an independent stdlib-only verifier, an
  adversarial fixture family, a dedicated empty-network CI job, and a protected
  manual workflow. Exact positional basenames are classified before a URL field
  may be read; observation routes are never retained or followed. Sanitized
  inventories freeze domain/site/month/package and package/file generation
  identities, normalized table-field declarations, validation rules, referenced
  categorical flag codes, and an exact F2 identity-only allowlist. The raw phase
  returns only route-free immutable objects before cleanup and receipt writing.
- **Publication and credential controls:** the manual workflow is designed for
  an exact `master` SHA in environment `discharge-f1`; that environment must be
  configured with reviewer and literal-master protection before dispatch. It
  injects `NEON_TOKEN` into one `python3 -I -S` process, destroys raw state
  before an independent empty-network verifier and second checkout, and may
  push only one direct-child review commit containing exactly four sanitized
  receipt files. CI binds any such family to that direct-child producer and its
  current blobs; it neither uploads artifacts nor creates/merges a PR
  automatically.
- **Adversarial and static validation:** the complete producer/acquisition/
  independent-verifier suite passes on host Python 3.9.6 and bundled Python
  3.12.13, including metadata masquerades with zero download calls, conflicting
  domain/site/month identities, malformed and impossible UTC generations,
  response-window drift, pre-window/provisional packages, flag-schema mutation,
  route/secret canaries, raw-scope cleanup, `0600` staging, and `0644`
  publication. Both workflow YAML files parse; every F1 Bash block and the
  isolated Python wrapper syntax-check; `git diff --check` passes.
- **Non-impact receipt:** no local Driver rebuild, generation, promotion,
  Connect deployment, authenticated query, availability-manifest download,
  observation fetch, or upstream Inverts RDS access occurred. Canonical SHA-256
  remains cascade
  `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`, search
  `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`, meta
  `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`, codebook
  `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`, and
  manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
- **Publication status and next action:** this is a local offline candidate; no
  implementation PR, CI run, merge, Pages identity, environment protection, or
  Driver-owned `NEON_TOKEN` is claimed yet. Commit and publish the exact branch,
  require literal-head and merged-master CI plus Pages, then configure the
  protected master-only environment and its environment-scoped secret before a
  manual F1 dispatch. Any generated receipt still requires its own exact-head,
  independent review, merge, and Pages receipt before F2 can be considered.

### 2026-08-05 12:04 MST - Continuous Discharge F1 implementation published / protected environment configured / token pending / [Codex]

- **Published implementation:** PR #61 exact head
  `bacb1ea4def8dc70b4a1304fc75f4c9dc406bbd2` passed all seven jobs in run
  `31034934400` and merged as
  `c8ebe39f2ff6a45a523a64666caf5e15ce93b278`. Merged-master cascade run
  `31035535292` and Pages run `31035532263` passed. The F1 offline producer,
  exact-basename no-look classifier, all-row schema normalization, independent
  stdlib verifier, adversarial fixtures, empty-network CI, exact-four publisher,
  and direct-child provenance gate are therefore published.
- **GitHub-only repair:** separate workflow-registration run `31035532958`
  rejected `runner.temp` in job-level `env` before any job started. No token,
  API request, raw response, manifest, metadata, or observation byte was touched.
  Focused repair PR #62 exact head
  `ce85c7c8bdaae490f99a38621dcafeb25ff05c1a` moved the four runner-owned paths
  into a bounded early `GITHUB_ENV` initializer, passed all seven jobs in run
  `31035951191`, and merged as
  `f16ab3ec06659c82a50c32276d0538365e20ef02`.
- **Final publication evidence:** exact final merged-master run `31036991024`
  passed all seven cascade/Discharge/Phenology jobs. Pages run `31036988796`
  passed build, report, and deploy. The public root returned HTTP success and
  matched `f16ab3ec...:docs/index.html` at SHA-256
  `0187780bc9986530b6ed0d49daf82f52986b9f61a88993f3e52cbe7736b0918b`.
- **Protected environment state:** environment `discharge-f1` exists and requires
  reviewer `tgilbert14`; administrator bypass is disabled; deployment is limited
  to the literal `master` branch. Repository Actions defaults remain read-only.
  Within the F1 workflow, only its reviewed publish job requests
  `contents: write` for a unique review branch; the separate allowlisted refresh
  publisher retains its existing scoped write permission. The repository and
  environment contain no secrets, so there is no same-name fallback
  `NEON_TOKEN`.
- **Current boundary and next action:** no authenticated F1 acquisition has run,
  no Driver/app/runtime/generated byte changed, no Connect deployment was needed,
  discharge support remains `UNMEASURED`, and F2 remains unauthorized. Add a
  Driver-owned `NEON_TOKEN` only as an environment secret in `discharge-f1`, then
  dispatch the manual workflow from the exact current `master` with the frozen
  F1 confirmation. Review and merge only its route-free exact-four receipt
  branch; do not authorize F2 from availability alone.

### 2026-08-06 08:17 MST - cover-label policy and companion-publication reconciliation / Codex

- **Classification and policy:** documentation/governance plus companion UI
  publication; Driver impact `NONE`. Exact policy source
  `3889a16dc8cbd5d772650b347988ba293435a640`, direct child of
  `f0fcfc4c9582d4e12448c1be4d6145c3fb1d43c7`, changes only the suite learning
  loop, revamp plan, and playbook. It retires ornamental cover-visible art
  disclaimers, not meaningful alt text, durable provenance, accessibility, or
  scientific claim limits.
- **Publication state:** Small Mammal PR #92 `c1b667b6` -> `fa982438`
  (head/main/Pages/production `31067930858` / `31068784690` / `31068784339` /
  `31068784703`); Vegetation PR #15 `343e072a` -> `fa083293`
  (`31068003862` / `31069040690` / `31069039945`; the central signed-in suite
  receipt binds Connect content `019ee110-8fd3-abae-aee3-02ea8e4274c8` to exact
  `fa083293` under R 4.5.2 / 91 packages, followed by live science/responsive QA);
  Phenology PR #11
  `36e6725e` -> `c704a377` (`31066206050` / `31066622018` / `31066621547` /
  `31066622073`); Plant Diversity PR #17 `f8038f66` -> `7fa45bbe`
  (`31066213366` / `31066454741` / `31066453987` / `31066454742`); Mosquito PR
  #11 `105a7dba` -> `fdb9aa1a` (`31067295881` / `31069571068` /
  `31069570315` / `31069571090`; the central signed-in suite receipt binds
  Connect content `019ef0b1-0099-c999-1edc-4d47826044cc` to exact `fdb9aa1a`
  under R 4.5.2 / 91 packages, followed by live science/responsive QA); Inverts
  PR #9 `21bc350b` ->
  `98c44ec4` (exact-head `31069906944`, Pages `31070821235`, production
  `31070821791`, production identity
  `sha256:eb247cf7ad9f534c3696623604b60277181e1471ae660e9982786a167dd540ca`).
  Breeding Birds PR #5 `a7b954a5` -> `bb18be35` passed exact-head/default
  validation `31108947955` / `31110952060`, recovery Pages `31113290899`, and
  exact production smoke `31110952345` attempt 2. All listed terminal release
  runs are success; the superseded Birds infrastructure failures are classified
  separately below.
- **Final nine-app public QA:** a fresh Playwright 1.55.1 / headless-Chrome sweep
  completed at 2026-08-06 08:06 MST against every registered companion's public
  production surfaces. All 27 Pages cases (1440 x 900, 390 x 844, and 320 x 720
  for each app) and all nine Connect desktop cases (1440 x 900) rendered without
  a host or Shiny output error, broken image, root overflow, visible retired
  disclaimer, or visible `figcaption`; every cover retained a visible control at
  least 44 CSS pixels high. All eight artistic covers retained meaningful image
  alternatives, and Water remained the confirmed no-art/no-op cover.
- **Ground lifecycle/docs closeout:** cover PR #19 `746f909a` -> `1be09b7b`
  passed `31068718372` / `31069632109` / `31069631437` / `31069632097`.
  Lifecycle PR #20 source `76459ec4` produced reviewed artifact `8955558168`
  (digest
  `sha256:65cf82b845ca1a47507d952ed7d1b69b0330ee3f8de59eaf6fcdaaf8da3fcfe4`)
  in run `31070700866`; that source run deliberately ended red at the expected
  pre-promotion generated-byte mismatch gate. Promoted head `832991e2` and merge
  `a5d3e0ef` then passed exact-head `31071059592`, main `31071173398`, Pages
  `31071172870`, and production `31071173390`. Docs PR #21 `fcd01c85` -> current default/deployed
  `0594cfa489333a824e2fb1f3dd78196c5c1fce57`; exact-head `31071704436` /
  artifact `8955904506`, main `31071862375`, Pages `31071861854`, production
  `31071862357`, and Connect #76 /
  `019fd55e-6e87-e75f-6232-8905aad702fc` passed. Science/data authority remains
  `a615d6c`; cover, lifecycle runtime, and docs/default authority remain distinct.
- **Water inspected no-op:** Water already had no visible cover-art disclaimer.
  PR #17 head `1c1031cf` -> merge `7feb49ee` pins only the manifest-producing
  `bslib@0.10.0` closure; exact workflow `31067098412`, Pages `31068098866`, and
  production `31068099200` passed. Science/data/runtime authority stays
  `ee95af3`, governance stays `9e2946ca`, and no cover/app/runtime/data/science/
  Driver byte changed.
- **Breeding Birds terminal release:** scientific/runtime authority stays
  `97c3e4c` and prior docs/default authority stays `07c852c`; the exact cover and
  current default publication chain begins at source
  `44e7cf928b32e75e4089ea5dc6497ae4e402867b`. Authenticated refresh
  `31067221525` produced validated artifact `8960794005` (digest
  `sha256:c46ece7f868c489c4c9f9ee00f8dbfbcc12be4fbabcf080173150dd21ff7e4fa`)
  and direct-child candidate/PR #5 head
  `a7b954a5de4ac20494f9270a355ee8d268a596dc`. Exact-head CI `31108947955`
  passed; the exact candidate merged as current default
  `bb18be3526fd91ac90239bab393c86b83ad3ec78`; default CI `31110952060`
  passed all scientific, manifest, deterministic-byte, offline-source, and
  real-bundle Shiny gates. Release identity is
  `sha256:043aa41d80a5b714b76e0d9bdc035fa636dc87a17200321695b9d9db706502cc`.
  Connect #47 / history `019fd779-48d4-3ca1-31f5-e016c02ef2c1` published exact
  `bb18be35` under R 4.5.2 / 91 packages via request
  `2c597a29-cd83-4f7d-8f41-51fc496e6f3a`. Pages recovery run `31113290899`
  then published the same exact release, and production run `31110952345`
  attempt 2 verified exact Pages/Connect parity.
- **Birds Pages incident boundary:** initial Pages run `31110949642` attempts 1
  and 2 each built and accepted an exact artifact, then the GitHub Pages backend
  remained `deployment_in_progress` for 600 seconds and timed out. Production
  run `31110952345` attempt 1 therefore failed only its exact Pages-release poll;
  Connect was already exact and healthy. A fresh Pages build request from
  unchanged exact `bb18be35` created `31113290899`, whose deploy job
  `92656395730` succeeded after 7m24s; production attempt 2 passed immediately.
  No repository, app, science, data, manifest, or release byte was changed to
  recover the infrastructure publication.
- **Authority separation:** Small science/data stays `c4c46fce`; Vegetation
  `d566b30`; Phenology `7d0f29f`; Plant Diversity source-data `a060ee6` and
  science/runtime `8fc0824`; Mosquito `935420e`; Inverts `ff23e994`. The new
  merges above own cover/default/publication state only to the exact scope proved
  by their app-local receipts.
- **Workspace warning:** the ten publish-intended worktrees were clean at the
  bounded suite sweep, but they are handoff snapshots rather than current-default
  authority after merge. Fourteen historical parallel worktrees still contain
  retired badge markup or copy and are not publication sources. Do not branch,
  publish, or infer deployment from those stale trees; fetch the exact remote
  default into a fresh worktree before future changes. No live pre-PR exception
  remains.
- **Driver non-impact and publication boundary:** canonical SHA-256 remains
  cascade `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe`,
  search `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e`,
  meta `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de`,
  codebook `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3`,
  and manifest `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79`.
  No scientific Driver rebuild is required. Publish this exact documentation/
  default head through review, and require Driver CI, Pages, Connect, and public
  verification for the governance receipt.

### 2026-08-06 17:05 MST - Driver context publication receipt / [Codex]

- **Governance scope:** PR #64 (`44acb7a8088515023a6b4873c712206dffa69c79`) merged
  normally as `1eb361f8eb5ba87f3f332a91b31fb7f36c35c63c`. The change is limited to
  the four Driver Markdown handoff/context files listed above; canonical cascade,
  search, meta, codebook, and manifest SHA-256 values remain unchanged.
- **Exact post-merge CI:** `31116430000` attempt 3 completed successfully at
  `2026-08-07T00:00:06Z`; the recovered Seal-1 job was `92725619087` and its
  dependent Seal-2 parity job was `92725879418`. Every scientific, rebuild,
  offline, and parity job passed. Attempts 1 and 2 are retained as infrastructure
  evidence only: hosted-runner action-download service failures during the GitHub
  Actions outage, with no project-step failure.
- **Exact post-merge Pages:** `31116427918` attempt 3 completed successfully at
  `2026-08-06T23:57:17Z`; deploy job `92725623059` published the exact merged
  default head. The earlier attempts failed only during hosted action-download
  setup while GitHub Actions/Pages were degraded; the build and report jobs were
  green.
- **Connect publication:** Driver Connect deployment #123 remains exact at
  content `019ee1cf-a484-44eb-a181-cd495df24b3b`, history
  `019fd7b5-aa8e-ad8e-1811-420dc7259d01`, commit
  `1eb361f8eb5ba87f3f332a91b31fb7f36c35c63c`, and publish request
  `77a5f775-ff95-4a85-9b90-4f36a1e3937b` (R 4.5.2 / 73 packages).
- **Public verification:** the live Driver Pages root returned the updated
  Response Atlas context with no host/Shiny error, root overflow, retired cover
  disclaimer, or visible `figcaption`; Connect remained exact and healthy.
- **Closeout:** all nine registered companion Pages/Connect surfaces have passed
  the final responsive/accessibility sweep. This receipt closes the suite-wide
  cover-disclaimer removal and publication pass; no app science, data, runtime,
  or Driver canonical artifact bytes were changed.

### 2026-08-07 09:41 MST - Driver cover redesign (living-poster hub) / [Claude]

- **Scope:** cover-only. `docs/index.html` rewritten in the suite's living-poster
  language; four new art assets added under `docs/assets/` (`cascade-living-poster.png`
  1672x941, `.webp` 1672w + 840w, `cascade-og.png` 1200x630) and the retired
  `response-atlas-social.png` removed (og/twitter meta now point at `cascade-og.png`).
  `docs/` is in `.rscignore` and outside the manifest allowlist, so the Connect
  deploy bundle and the five canonical Driver artifacts are untouched.
- **Driver implication: NONE.** Canonical SHA-256 verified unchanged this session:
  cascade `47b98e48...`, search `a11a072d...`, meta `00120c52...` (matches the
  2026-08-06 receipt). No rebuild run, no science/data/runtime byte changed.
- **What changed and why:** the 2026-08-06 suite pass left the hub as the only
  cover still in the old constellation style while all nine companions moved to
  the split-hero living-poster language and route here via "Whole suite: Driver
  Cascade". The new cover conforms to the extracted suite token spec (system
  Iowan/Palatino serif two-line question headline with one teal accent line,
  poster-grid with art bleed + gradient weld, feTurbulence film grain, single
  52px pill CTA, cream `#f3e8cb` honesty footer, zero JavaScript) while keeping
  the hub's unique jobs: a 3x3 explorer grid wearing each companion's accent hex
  with its cover question, the four canonical layer hues, the 9/46/open/4 stats,
  and every governed caveat (short chain caveat stays in the hero lead; the full
  mediation/causation sentence moved to the layers band; "How it stays honest"
  body preserved verbatim in the footer disclosure). Kicker now says
  "Driver Cascade · NEON Response Atlas" so arrivals from companion headers can
  confirm they landed at the hub.
- **Art provenance:** hero art generated via Higgsfield (Recraft V4.1 explorations,
  then nano-banana image-referenced variants of the owner-picked Sonoran monsoon
  scene, bytedance 2k upscale), graded to the suite palette; decorative
  illustration only — depicts no data. Owner picked the base scene mid-session;
  a palette-muting regrade was generated and REJECTED in favor of the owner's pick.
- **Test process + evidence:** local Playwright (bundled Chromium) shots at
  1440x900 / 1920x1080 / 800x1000 / 390x844 / 320x720: no horizontal overflow at
  any width (scrollWidth == innerWidth), h1 exactly two lines everywhere, art-first
  stacking below 960px. Five-agent adversarial review (suite-kinship, a11y/QA,
  honesty-preservation, links, code) ran against the draft; both blockers and all
  "important" findings fixed (two-line headline, compact lead, 3x3 grid, two-column
  layers band, 700-960px grid overflow, art overhang occlusion, svh->vh fallbacks,
  footer CTA contrast #a04a38 = 4.9:1, causation clause restored, GitHub link
  relabeled). Consciously rejected: recoloring the four canonical layer hues
  (must stay in sync with the deployed app) and rewriting companions' quoted
  cover questions (provenance wins). All 14 outbound links returned 200 at check
  time. A11y bar: 44px controls, skip link, aria-label'd h1 over the span/em
  split, reduced-motion/contrast/forced-colors blocks, meaningful alt text, no
  figcaption, no cover-art disclaimer.
- **Residual risk:** `assets/cascade-og.png` 404s on live Pages until this branch
  merges to `master` (assets ship in the same commit as the HTML, so the deploy is
  atomic). The suite-jump naming fix is one-sided: companion headers still label
  the hub "Driver Cascade"; the hub kicker now carries both names.
- **Next action:** review + merge PR from `claude/cascade-driver-cover-design-norhf2`
  to `master`, then re-curl the live og:image URL and re-run the responsive QA
  sweep against the deployed Pages root.

### 2026-08-07 11:55 MST - Driver cover: card skins + wording pass / [Claude]

- **Scope:** cover-only follow-up on the same branch/PR (#66). (1) The nine
  explorer cards now wear their own apps' published cover art as dimmed
  "skins" (new `docs/assets/covers/*.webp`, eight 640x360 thumbs ~290KB total,
  recompressed from the siblings' live Pages assets; lazy-loaded, `alt=""`,
  per-card `--pos` focal points, hover/focus brighten+zoom; Water Chemistry has
  no cover art by design, so it carries a CSS droplet pattern in its accent).
  (2) A cringe/AI-wording editorial pass: warm-start note and hero lead
  de-jargoned ("co-displayed" removed), meta/og/twitter descriptions now lead
  with the cover question instead of methods-abstract triads, layers h2 reads
  "Weather and living records", and the seamed causation sentence was split
  back into the two original governed sentences (both verbatim; no caveat
  weakened). Water card tagline is now "What's in the water?" (hub-authored;
  its cover has no question to quote).
- **Review evidence:** copy pass and card-skin critique ran as two independent
  agents. Adopted: per-card `--dim` hook (Plant Diversity .62 — fixes a real
  WCAG AA fail measured ~4.0:1 over its cream art, worst on :focus-visible),
  hover brighten capped at .88, text-shadow on card name/ask, Phenology/Mammals
  focal retunes. Verified post-fix: no horizontal overflow at 320/390/800/1440/
  1920, h1 two lines everywhere, all eight lazy skins load on real scroll at
  390px (a blank card in one fullPage capture was a Playwright lazy-decode
  race, not a page bug).
- **Driver implication: NONE** (no data/runtime/manifest byte changed).
- **Next action:** merge PR #66, then re-check live Pages root, og:image, and
  the nine card skins over the deployed assets.

### 2026-08-07 13:55 MST - hub Water card + suite register addendum / [Claude]

- **Scope:** cover/docs-only follow-up on a fresh `claude/cascade-driver-cover-design-norhf2`
  restarted from merged master `bb56bd35`. The hub's Water Chemistry card now
  wears the real art from the new Water living-poster cover (sibling repo PR #18,
  built this session with the same token spec and art pipeline); the CSS droplet
  placeholder is removed and `docs/assets/covers/water-chemistry.webp` added.
  The card's "What's in the water?" tagline is now the companion cover's actual
  headline — provenance aligned.
- **Learning loop:** dated 2026-08-07 hub + Water cover addendum added to
  `docs/NEON-SUITE-LEARNING-LOOP.md` (register supersession for the two surfaces,
  thumb-refresh coupling, ten-of-ten living-poster closure, naming-drift note);
  coupling lesson appended to `.claude/agents/LESSONS.md`.
- **Driver implication: NONE** (no data/runtime/manifest byte changed).
- **Next action:** after Water PR #18 merges, pin its merge SHA in the register
  addendum on this branch, merge this PR to master, and verify both live Pages.
