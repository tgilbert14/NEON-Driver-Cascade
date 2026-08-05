# Driver v2 Phenology adapter specification

Specification state: **DRAFT / ADVERSARIAL REVIEW IN PROGRESS — NOT A REGISTRY AUTHORITY**  
Specification date: 2026-08-04 EDT  
Ecological disposition: **HOLD / NO DRIVER BYTE CHANGE**

Checkpoint note: source-contract review is still resolving the exact roster/plot
semantics and whether the interval-censored response model belongs in this same
seal. Nothing in this draft authorizes implementation or effect inspection.

This document freezes the source, opportunity, censoring, support, parity, and
execution contract for a possible current-release Plant Phenology adapter. It is
deliberately written before calculating or inspecting any current-release climate
effect estimate. Passing this specification would establish an auditable response
and support layer; it would not by itself authorize a temperature -> green-up vote,
a new prior, or a generated Driver artifact.

## 1. Scope and no-look boundary

The first implementation phase may answer only these questions:

1. Can the exact current Phenology release be read through a Driver-owned adapter
   without executing sibling code?
2. Can visit records be partitioned into explicit opportunity and censoring states?
3. Can the legacy scalar green-up construction be reproduced from the legacy pin?
4. Which current-release site-years satisfy the predeclared response-support rules?
5. Can every difference between the legacy and current source families be assigned
   a source, censoring, taxonomy, panel, support, or calendar reason?

The sealed phase must not:

- calculate, deserialize for inspection, print, rank, plot, or summarize a new
  temperature/green-up association;
- source or call `site_links()`, `pooled_links()`, `cascade_meta.R`, the meta-analysis
  writer, or another effect-producing path;
- select a response, site, season, lag, support threshold, censoring rule, or
  alternate outcome because its direction or magnitude looks favorable;
- update `data/cascade.rds`, `data/search_index.rds`,
  `data/cascade_meta.rds`, `data/neon-cascade-codebook.csv`, or `manifest.json`; or
- change the v1 artifact's two historical temperature/green-up rows.

Support counts, key intersections, exclusion counts, invariant checks, and opaque
digests are permitted. Logs and receipts must omit response values and effect-like
quantities. Internal value comparisons required for parity may return only
pass/fail, row counts, field counts, and bounded numeric deltas—not site names,
response values, correlations, coefficients, p-values, ranks, or directions.

## 2. Immutable authorities

The first sealed run must resolve these exact Git objects. A moving branch name or
an equivalent-looking checkout is not an authority.

| Role | Immutable authority |
|---|---|
| Driver Gate-0 synthesis content authority | `34a1789b11d214862f3e7a3f8dc6ceec092f6b4d` |
| Driver Gate-0 merge authority | `a99e0c849998253f47ddd01946f89aedab295418` |
| Driver publication-receipt/default authority at specification start | `928ae23d22bb28b6649bdbec25404e64c4a4dfaa` |
| Unchanged v1 Driver artifact baseline | `a7d610ef8fbffe72945c523657995452d5caffdf` |
| Current Phenology data authority | `7d0f29f7886cfae1c760a9ffc9e056184ec6fc68` |
| Current Phenology data candidate | `3089dc8e527340245735efbc62c95aa2faee5b25` |
| Phenology generator authority named by that candidate | `256989a91d4502feca0b54cea77a24dfe9a02fca` |
| Current Phenology knowledge/default authority | `30be615dc438b60e4fa6454973b3b42589b22234` |
| Legacy Phenology pin recorded in Driver v1 | `81e339e9ed6f34d3d04ca45a7030fea51c4147a5` |

The current data authority and current knowledge/default authority have the same
`data/sites` Git tree:

```text
5a8fd457069d6dcca8dcd0dac9851528509032c6
```

The legacy pin's `data/sites` tree is different:

```text
30abe869b0f78931929c21e544ffc85ec2238e35
```

The current release's `manifest.json` Git blob is
`dcc9433975c2d19b6b128a77c2304fd844c268e9`; its file SHA-256 is:

```text
512737700fdad555264737303439a1816eb189f5ec456e7420aa40dc9165d29b
```

The current data authority must be an ancestor of the knowledge/default authority,
and the exact data tree and manifest must match the objects above. The future
adapter may use the knowledge/default commit as its detached checkout only if it
independently asserts those data-authority objects. Documentation or workflow
descendants do not silently become new data authorities.

The unchanged Driver baseline hashes are an additional no-mutation receipt:

| Artifact | SHA-256 |
|---|---|
| `data/cascade.rds` | `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe` |
| `data/search_index.rds` | `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e` |
| `data/cascade_meta.rds` | `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de` |
| `data/neon-cascade-codebook.csv` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79` |

## 3. Source boundary and schemas

### 3.1 What the adapter may read

The adapter may read only inert committed files from the exact Phenology checkout:

- `data/sites/<site>.rds` for all expected terrestrial sites;
- `data/site_index.rds` only for release-level cross-checks; and
- `manifest.json` only for identity and file/checksum verification.

It must not source `R/phe_helpers.R`, execute a sibling script, call a sibling
function, fetch NEON data, or use a live app response. The per-site bundle's raw
observation table—not its already reduced trend table—is the scientific source for
the Driver-owned reconstruction.

### 3.2 Required bundle container

There must be exactly 46 `data/sites/*.rds` files, with the exact site set declared
by the current Phenology release and the Driver terrestrial roster. Every file must
read as a named list containing at least `obs`, `inds`, `meta`, `ind_summary`, and
`trend`.

`obs` and `inds` must be nonempty rectangular data frames. `trend` must be either
`NULL` or a nonempty rectangular data frame. Package-backed ALTREP columns,
zero-length columns in a nonempty frame, duplicate column names, or a container
whose columns do not all have `nrow()` elements are corruption, not optional data.

### 3.3 Observation grain and required fields

One `obs` row is one recorded status for one tagged plant, one phenophase, and one
visit. These exact fields are required:

| Field | Required interpretation |
|---|---|
| `individualID` | nonblank tagged-plant identity |
| `plotID` | nonblank monitoring location within site |
| `scientificName` | recorded taxonomic identity; may be excluded later if unresolved |
| `growthForm` | recorded plant growth form |
| `year` | integer calendar year |
| `date` | valid visit date |
| `dayOfYear` | finite integer-compatible day 1-366, consistent with `date` and `year` |
| `phenophaseName` | exact recorded phenophase label |
| `status` | exactly `yes`, `no`, or `uncertain` |
| `intensity` | retained source attribute; not an onset or leaf-duration input |
| `is_species` | explicit species-rank eligibility flag |

Upstream `missed` records are absent by the release contract. `uncertain` remains a
real recorded state but is never converted to `no`, included in a yes/no
denominator, or used to locate an onset bound.

Rows may repeat within a visit/opportunity grain. The adapter must preserve source
rows through validation, then collapse them only at the explicitly declared grains
below. Row order and exact duplicate order must not affect any result.

### 3.4 Individual roster and metadata

`inds` must contain one row per `individualID` and these exact fields:

```text
individualID, scientificName, growthForm, plotID, lat, lng,
nativeStatusCode, taxonRank, is_species
```

An observation identity must resolve to exactly one roster row. Site, plot,
scientific identity, growth form, and species-rank disagreements between `obs` and
`inds` must fail rather than be settled by first-row order.

`meta` must be a named list containing `site`, `lat`, `lng`, and `years`. Its site
must equal the file name. The adapter obtains the site code from the verified file
identity and never guesses it from coordinates or free text.

### 3.5 Derived app tables are comparison surfaces only

The optional `trend` table has grain `scientificName x year` and requires
`scientificName`, `year`, `onset`, and `n`, with `n >= 3`. It is used only to
verify the app-supported calendar benchmark.

It is not the Driver response oracle: the app table rounds species-year medians,
does not retain interval bounds, and includes left-censored first-yes values as
points. The app helper also resolves tied earliest phases differently from the
Driver's conservative tied-censor rule. Reading `trend$onset` directly into Driver
would therefore erase the very censoring policy this gate exists to review.

`ind_summary`, `data/site_index.rds`, and the app's release-wide green-up coverage
may be checked for key/count parity, but they do not replace reconstruction from
`obs`.

## 4. Phenology opportunity ledger

The adapter must produce a long, pre-aggregation ledger before calculating any
annual scalar. The ledger is an audit object; it is not a Driver effect table.

### 4.1 Monitored plant-year opportunity

A monitored plant-year is one distinct
`site x year x individualID` with:

- a verified roster identity;
- `is_species == TRUE`;
- at least one source observation with a valid date/day/year; and
- a year inside the immutable Driver window `2013 <= year <= 2025`.

The existence of any monitored plant-year is opportunity, not evidence that a
green-up phase occurred. Multiple visits, phenophases, or rows do not create more
plant-year opportunities.

The exact green-up phase family is frozen as:

```text
Breaking leaf buds
Initial growth
Emerging needles
Breaking needle buds
```

String approximation, case folding, partial matching, or substituting `Leaves` is
forbidden.

### 4.2 Phase-level onset records

For each
`site x individualID x scientificName x growthForm x phenophaseName x year`, use
only finite-day `yes` and `no` rows.

- If there is a `yes`, `first_yes` is the minimum yes day.
- If at least one `no` precedes `first_yes`, the record is `bounded` with
  `lower_doy = max(preceding no)`, `upper_doy = first_yes`,
  `midpoint_doy = (lower_doy + upper_doy) / 2`, and
  `interval_days = upper_doy - lower_doy`.
- If there is a `yes` but no preceding `no`, the record is `left_censored` with
  unknown lower bound and `upper_doy = first_yes`. `first_yes` is an upper bound,
  not a point estimate.
- If there are valid yes/no rows but no `yes`, the record is
  `right_censored_no_yes`. It retains the last observed no as a lower-bound audit;
  it has no finite onset point.
- Target-phase rows that are all uncertain form `uncertain_only`; uncertainty is
  not absence.
- A monitored plant-year with no target-phase row is `structural_unscored`.

Every monitored plant-year must be represented by one or more phase rows or by an
explicit structural state. No state may disappear merely because it cannot
contribute a scalar timing estimate.

### 4.3 Individual-year green-up record

The audit ledger retains every phase-level bound. For exact v1 compatibility only,
phase rows with a `yes` also receive the historical compatibility value: bounded
midpoint, or `first_yes` for a left-censored phase. The minimum compatibility value
defines the candidate earliest phase for that individual-year.

When phase rows tie at that minimum:

- if any tied phase is left-censored, the entire individual-year is
  left-censored;
- the widest finite tied interval is retained for conservative cadence auditing;
  and
- conflicting tied scientific identities are a hard failure; otherwise the
  stable lexical identity is retained solely to make row order irrelevant.

This compatibility collapse exists to reproduce the published lineage. It does
not make a left-censored upper bound an exact v2 response. A later interval-aware
model must consume bounds/censor states directly. Left- and right-censored records
must never be silently inserted into a point-outcome analysis.

### 4.4 Required opportunity partition

At minimum, every monitored plant-year must end in exactly one mutually exclusive
top-level state:

```text
bounded_onset
left_censored_onset
right_censored_no_yes
uncertain_only
structural_unscored
taxon_ineligible
outside_driver_window
```

Composition and connected-panel exclusions are subsequent eligibility states, not
rewrites of the observational state. Annual audit totals must reconcile from the
monitored denominator through observation/censoring state and then through
taxonomy/panel eligibility. Unknown, unsupported, censored, and zero are never
interchangeable.

## 5. Compatibility index and support eligibility

The first adapter implementation must reproduce the existing Driver scalar
construction as an explicitly named compatibility layer. It remains non-voting
until the separate model gate is opened.

### 5.1 Eligible individual-year contributors

The compatibility index starts only from individual-year records that are:

- `bounded_onset`;
- species-rank (`is_species == TRUE`);
- resolved to a nonblank `scientificName`; and
- inside 2013-2025.

Left-censored records are counted and retained in the ledger but excluded from the
compatibility scalar. This is a screen, not interval-censored modeling, and its
possible visit-cadence selection must remain explicit.

### 5.2 Species-year and recurrent-species gates

For each `site x scientificName x year`:

1. collapse to the median bounded individual-year midpoint;
2. count distinct contributing individuals; and
3. retain the species-year only when at least three individuals contribute.

A species is recurrent only when it has at least three eligible species-years at
that site. One-year taxa cannot move a site time series through compositional
turnover.

### 5.3 Connected incidence panel

Build the bipartite incidence graph of recurrent species and eligible years. A
single site index may use only one connected component, so every retained period
has a within-species bridge to the rest of the time series.

Select the component deterministically by:

1. greatest number of retained species;
2. then greatest number of species-year records; and
3. then lexically earliest species name.

Rows outside the selected component remain counted as
`connected_panel_excluded`. The selected component must itself be connected; an
empty or unsupported panel yields unavailable values rather than a build failure.

### 5.4 Equal-species annual index

Within the selected component:

1. calculate each species' across-year median onset as its reference;
2. calculate each species-year deviation from that species reference;
3. take the equal-species median deviation for each year; and
4. add the site's median species reference as a fixed display anchor.

This produces `greenup_doy_compat`, a DOY-anchored composition-adjusted index—not
an observed pooled median onset day.

An annual value is finite only when at least two retained species and at least six
distinct final individuals contribute that year. A site with fewer than six finite
years is not eligible for a later site-level effect screen.

The adapter must also reproduce the existing alternate estimator on the exact same
eligible cells: unweighted
`species_onset ~ scientificName + factor(year)`, evaluated over the full retained
species x retained-year grid and summarized by the equal-species annual median.
This `greenup_doy_additive_compat` is parity/sensitivity output only. A rank-deficient
design is a hard failure; missing species-years are disclosed model extrapolations.

### 5.5 Censoring and cadence audits

For every source-support year, carry at least:

```text
greenup_n_monitored
greenup_n_target_scored
greenup_n_onsets
greenup_n_bounded
greenup_n_left_censored
greenup_n_right_censored
greenup_n_uncertain_only
greenup_n_structural_unscored
greenup_n_taxon_excluded
greenup_n_connected_panel_excluded
greenup_n_individuals
greenup_n_species
greenup_reference_doy
greenup_onset_interval_median_days
greenup_onset_interval_p90_days
greenup_onset_interval_max_days
```

The p90 interval uses R type-7 quantiles. Interval summaries are finite exactly
when at least one final bounded contributor exists, ordered
`0 <= median <= p90 <= max`, and are timing-resolution audits—not confidence
intervals for the annual index.

The existing review thresholds remain diagnostic before model registration:

- left-censored share `>= 0.50` is a censor-burden warning;
- composition/support exclusion share `>= 0.50` is an exclusion-burden warning;
- median bounded interval `> 14` days is a typical-cadence warning; and
- maximum bounded interval `> 30` days is an extreme-cadence warning.

Warnings never become zeros. Whether a warned year can enter an interval-aware
effect model must be frozen in the later model registry before effects are
unsealed; it may not be decided after seeing a result.

## 6. Seven-day leaf-active alternate

### 6.1 Exact current behavior

The current app's leaf-active measure is a positive-presence extent. For each
`site x individualID x scientificName x year`:

1. retain exact `phenophaseName == "Leaves"`, `status == "yes"`, and finite
   `dayOfYear` rows;
2. assign `week = floor((dayOfYear - 1) / 7) + 1`;
3. collapse repeated yes visits to distinct week bins; and
4. set `leaf_active_days_7d = 7 * number of distinct yes-week bins`.

Days 1 and 2 occupy one bin; days 1, 8, and 100 occupy three bins and yield 21
days. Multiple flushes remain additive because separated yes weeks are retained.

The formula does not cap the terminal partial week: day 365/366 can enter week 53,
and the metric can therefore reach 371 nominal days. This is preserved for exact
app parity and must be labeled approximate and quantized. It must not be silently
clipped, rescaled, or described as a measured green-up-to-senescence span.

A plant-year with no `Leaves=yes` row is `NA`, not zero—even when `Leaves=no`
records exist. Unvisited leaf-present weeks receive no credit. `uncertain` does not
add a week. Consequently this measure is positive-conditioned and sensitive to
visit cadence; seven-day standardization does not make it opportunity-complete.

### 6.2 Preselection and role

The alternate is preselected from source support, never from an effect. For each
site, reproduce the app's release-wide green-up coverage:

```text
distinct tagged plants with at least one finite green-up onset in any year
--------------------------------------------------------------------------
                 all tagged plants in the verified site roster
```

Sites with coverage `< 0.50` are the frozen `thin_greenup` stratum. This measured
coverage rule—not the Driver's descriptive keyword biome heuristic—determines where
the seven-day alternate is prepared. A desert label may be carried as context but
cannot add or remove a site.

Within a selected site, a descriptive species-year leaf-active row requires at
least three distinct positive-record individuals. A contextual site-year index may
apply the same recurrent-species, connected-component, two-species, and
six-individual gates as the onset compatibility index, but it must retain its own
cells, support counts, and name.

Leaf-active must never:

- replace green-up within the same response column;
- be chosen because its climate direction is stronger;
- be pooled with onset DOY;
- inherit the onset expected direction; or
- become vote-eligible in this adapter phase.

Its disposition is `CONTEXT / ALTERNATE SUPPORT DIAGNOSTIC`. A future vote would
require a separately registered opportunity/cadence policy, mechanism, model,
direction, multiplicity family, and old/new parity review.

## 7. Exact pre-effect expectations

These are topology and support expectations, not effect targets.

### 7.1 Current release/app support

The immutable current-release audit must reproduce:

| Check | Expected |
|---|---:|
| Per-site bundles | 46 |
| App-supported finite-onset site-years from `trend` | 346 |
| Sites represented by those keys | 45 |
| Sites with at least six app-supported years | 39 |
| Exact matches to current Driver site-year calendar | 346 / 346 |

This benchmark proves app support and calendar compatibility only. It does not
declare the Driver compatibility index eligible, and it does not permit reading
`trend$onset` as the Driver response.

### 7.2 Driver output topology

The sealed support adapter must outer-join to exactly 510 unique Driver
`site x year` rows across exactly 46 sites. It may add no site or year. All 346
app-supported keys must remain auditable, even if later censoring/composition gates
make a scalar index unavailable.

Finite current-release compatibility-index keys must be a reason-coded subset of
the app-supported keys. Their exact count is deliberately `UNMEASURED` before the
first support-only run; it must not be guessed from the legacy artifact or made a
target for threshold tuning. The support receipt records the observed count only
after every rule above is frozen and tested.

### 7.3 Legacy compatibility baseline

Running the compatibility adapter against the legacy Phenology pin must reproduce
the unchanged v1 Phenology surface:

| Check | Expected |
|---|---:|
| Source-support calendar rows (`greenup_n_onsets` finite) | 345 |
| Finite `greenup_doy` compatibility rows | 269 |
| Sites with a finite compatibility row | 40 |
| Sites with at least six finite compatibility years | 31 |
| Sites with at least six paired years for annual temperature screen | 18 |
| Sites with at least six paired years for March-May temperature screen | 18 |

The paired-year counts are support checks only. The sealed run must not calculate
or expose either screen's correlation, sign, pooled count, interval, coefficient,
or p-value.

If a current-release source/support count differs from the current expectations,
or legacy compatibility differs from its exact expectations, the run stops before
any effect path is available. Thresholds must not be relaxed to recover a preferred
count.

## 8. Independent oracle and fixtures

### 8.1 Test-owned raw-observation oracle

Tests must contain an independent, test-owned recomputation from `bundle$obs`.
The oracle must not call the production adapter's onset, collapse, connectivity,
index, or leaf-active functions. It must not source sibling code. Shared constants
are limited to literal field and phenophase contracts whose equality is asserted.

Across all 46 exact current bundles, the oracle must compare:

- opportunity and censor-state keys;
- interval bounds and widths;
- mutually exclusive audit counts;
- taxonomy and support exclusions;
- connected-component membership;
- final contributor/species counts;
- reference anchors and both compatibility indexes; and
- seven-day leaf-active keys and values.

The production and oracle support calendars must be identical. Exact integer,
logical, character, categorical, and key fields must be identical. Numeric fields
other than the additive model must agree with absolute tolerance `1e-15`; the
additive compatibility estimator may use absolute tolerance `1e-12` because the
canonical cross-platform oracle already establishes that bounded allowance. No
artifact may be rounded to force parity.

`trend` is checked separately for the exact 346/45/39 app-support benchmark. It is
never substituted for the raw-observation oracle.

### 8.2 Required adversarial fixtures

At minimum, executable fixtures must cover:

1. repeated visits within one plant/phase/day and arbitrary row order;
2. the same plant and week in different years remaining distinct opportunities;
3. `uncertain` excluded from yes/no and onset bounds;
4. a bounded last-no/first-yes interval and exact midpoint;
5. a first-visit yes retained as left-censored, not exact;
6. all-no target records retained as right-censored/no-yes, not zero;
7. a monitored plant with no green-up phase retained as structural-unscored;
8. tied earliest phases where any tied phase is left-censored;
9. tied bounded phases retaining the widest conservative interval;
10. unresolved taxonomy and species-rank exclusions;
11. exactly two versus three individuals at the species-year support boundary;
12. exactly two species/six contributors at the annual boundary;
13. recurrence at two versus three eligible years;
14. disconnected species-year panels and every deterministic tie-break;
15. abundance/composition shifts resisted by equal-species weighting;
16. rank-deficient versus full-rank additive designs;
17. empty contributor tables producing typed `NA` support fields without warnings;
18. leaf yes on days 1, 2, 8, and 100 producing 21 days;
19. the uncapped day-365/366 week-53 behavior;
20. `Leaves=no`/`uncertain` without yes remaining `NA`, not zero;
21. multi-flush yes weeks remaining additive;
22. green-up coverage immediately below, at, and above 0.50; and
23. malformed containers, duplicate identities, conflicting metadata, invalid
    dates/days, and unsupported status tokens failing closed.

### 8.3 Legacy old/new parity

On the legacy source pin, the new compatibility implementation must have exact
`site x year` key parity with the v1 annual table for:

```text
greenup_doy
greenup_doy_additive
greenup_n_onsets
greenup_n_left_censored
greenup_n_taxon_excluded
greenup_n_individuals
greenup_n_species
greenup_reference_doy
greenup_onset_interval_median_days
greenup_onset_interval_p90_days
greenup_onset_interval_max_days
```

Use the tolerances in section 8.1. Missingness patterns must be identical. The
test must also reproduce the exact legacy support counts in section 7.3 without
calling any effect function.

On current data, compare the compatibility output to the legacy output only through
a reason ledger. Every added, removed, or changed support key must receive one or
more stable reasons from this closed vocabulary:

```text
source_row_added
source_row_removed
source_value_changed
calendar_window
censor_state_changed
taxon_identity_changed
species_year_support
species_recurrence
connected_component
annual_support
cadence_audit_changed
```

An unexplained difference is a hard failure. The ledger reports counts and key
digests during the sealed phase, not site identities, response values, or effects.

### 8.4 Determinism

The adapter and oracle must pass:

- two clean runs with identical canonical support-ledger and reason-ledger SHA-256
  digests;
- randomized input row-order trials with identical canonical output;
- C and UTF-8 locale structural parity;
- canonical Ubuntu 24.04 / R 4.5.2 / dated 2026-07-15 package snapshot /
  OpenBLAS Haswell / one-thread execution; and
- the existing strict cross-platform source oracle, with the additive-only
  tolerance above.

Canonical ordering must be explicit and radix-stable. Wall-clock dates, random
seeds, checkout paths, process IDs, and unordered hash/table iteration must not
enter output.

## 9. Seal, support review, and unseal sequence

The work is divided into separately reviewable stages.

### Seal 0 - specification

Merge this document before running a current-release adapter against any climate
effect path. Record its exact commit as the registry authority.

### Seal 1 - pure adapter and synthetic contracts

Implement only the visit -> opportunity -> support adapter and independent tests.
Effect-producing modules are not sourced. The implementation must default to an
effect-locked mode and abort if an effect-producing symbol or script is invoked.

### Seal 2 - legacy parity

Run the adapter against `81e339e9...` and prove section 7.3 and 8.3. Do not fetch or
inspect current response/effect output to repair a legacy mismatch.

### Seal 3 - current source/support receipt

Run the frozen adapter against the exact current source. The durable receipt may
contain only:

- specification, Driver, data, knowledge, generator, tree, manifest, and runtime
  authorities;
- schema and roster results;
- opportunity/censor/support counts;
- calendar intersections;
- reason-code counts;
- opaque key/output digests;
- test commands and pass/fail results; and
- explicit confirmation that no effect module executed.

It must not contain response values, site rankings, climate pair values, effect
estimates, signs, intervals, coefficients, or p-values.

### Seal 4 - model registry and review

Review the support receipt without effect output. In a separate registered model
document, freeze which climate exposure, season, lag, censor-aware likelihood or
estimand, repeated-measure treatment, site eligibility, cadence/censor warning
policy, direction, pooling rule, multiplicity family, and claim limits will apply.
The annual-temperature and March-May screens remain historical compatibility
families until explicitly re-authorized. The seven-day alternate requires its own
model family and remains context in this cycle.

### Unseal - separate effect run

Only a later, separately reviewed commit may make effect code reachable. Its first
run must use the exact sealed adapter, support receipt, model registry, and source
authorities. Any adapter, threshold, source, reason-code, or model change after
unsealing invalidates every resulting estimate and returns the work to Seal 0/1
under a new version.

No stage authorizes a canonical Driver byte change until exact-head CI, independent
review, an explicit ecological disposition, guarded merge, and post-merge release
verification all pass.

## 10. Proposed later files and integration boundary

This specification proposes, but does not create, these implementation files:

| Proposed file | Purpose |
|---|---|
| `R/phenology_adapter_v2.R` | Pure Driver-owned visit/opportunity/support adapter; no effect functions |
| `scripts/test_phenology_adapter_v2.R` | Independent oracle, adversarial fixtures, legacy parity, determinism |
| `scripts/audit_phenology_v2_support.R` | Effect-locked current-source support and reason receipt |
| `docs/receipts/phenology-v2-support.json` | Machine-readable sealed support receipt without response/effect values |
| `docs/PHENOLOGY-V2-MODEL-REGISTRY.md` | Later climate/response model, direction, eligibility, multiplicity, and claims |

The first adapter PR should add a dedicated CI job that fetches the two immutable
Phenology authorities detached and runs only the files above. It must not edit
`scripts/build_cascade.R`, the signal/prior tables, effect helpers, artifact writers,
generated data, or the deploy manifest.

Only after the unseal decision may a later integration consider changes to
`scripts/build_cascade.R`, `R/source_adapters.R`, the codebook, metadata, workflow
source locks, generated artifacts, and manifest. The supported artifact-generation
entry point remains `scripts/rebuild_all.R`; an adapter test never publishes live
outputs.

## 11. Hard failures and scientific abstentions

### 11.1 Hard failures

The sealed process must stop before effects when any of the following occurs:

- an authority, ancestry, origin, Git object, tree, manifest hash, or canonical
  Driver baseline hash differs;
- the Phenology source-data scope is dirty or changes during a run;
- the bundle roster is not exactly 46 expected sites;
- a required container/field is absent, nonrectangular, zero-length within a
  nonempty frame, duplicated, or of an incompatible type;
- site/file/meta identities disagree, an individual roster key is duplicated or
  unresolved, or observation and roster identity conflict;
- a status token is outside `yes/no/uncertain`, a date/year/day is invalid or
  inconsistent, or a green-up phase is matched approximately;
- interval bounds are nonfinite where required, outside 1-366, reversed, or yield
  a negative width;
- monitored-opportunity and censor/support partitions fail to reconcile exactly;
- output contains duplicate or out-of-calendar `site x year` keys, does not outer-
  join to 510 rows/46 sites, or loses an app-supported key from the audit surface;
- a selected incidence panel is disconnected or its deterministic tie-break is
  unstable;
- the additive design is rank-deficient or produces nonfinite predictions;
- the current 346/45/39 app-support benchmark or a legacy expectation differs;
- raw-oracle, legacy parity, missingness, tolerance, row-order, locale, two-run
  digest, or reason-ledger checks fail;
- a current/legacy difference has no approved reason code;
- a support receipt exposes response/effect values or site identities contrary to
  the seal; or
- any effect-producing function or script executes before unseal.

Do not weaken a schema, support, censoring, parity, provenance, or determinism gate
to make a source pass.

### 11.2 Legitimate abstentions

These conditions are honest unavailable states, not pipeline failures:

- a site or year has no target green-up observation;
- records are uncertain, left-censored, right-censored, structurally unscored, or
  taxonomically ineligible;
- a species-year has fewer than three bounded contributors;
- a species recurs in fewer than three eligible years;
- no connected recurrent panel survives;
- an annual row has fewer than two species or six contributors;
- a site has fewer than six eligible annual response years;
- a climate window is incomplete; or
- too few sites survive the later registered model's support gate.

Such rows remain in the audit ledger with `NA` scalar output and an explicit reason.
If the final support is insufficient, the ecological family remains `HOLD`; the
correct response is not to lower the gate, substitute leaf-active, change seasons,
or inspect another model.

## 12. Decision preserved by this specification

The Plant Phenology application contract is verified, and its current release has
measured Driver-calendar compatibility. Neither fact re-authorizes an ecological
edge. Until the sealed adapter, independent oracle, support receipt, later model
registry, old/new review, and explicit unseal all pass, the decision remains:

```text
HOLD / NO DRIVER BYTE CHANGE / NO CURRENT-RELEASE EFFECT INSPECTION
```
