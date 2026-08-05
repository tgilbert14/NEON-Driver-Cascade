# Driver v2 Phenology adapter specification

Specification state: **SEALED REGISTRY CONTRACT / AUTHORITY IS THE EXACT MERGED DEFAULT-BRANCH COMMIT CONTAINING THIS FILE**

Specification date: 2026-08-04

Ecological disposition: **HOLD / NO DRIVER BYTE CHANGE**

The adapter and primary-model contract become authoritative only when this exact
independently approved document is merged. Before that merge, no implementation or
additional current-source access is authorized. After merge, only Seal 1 is
authorized; current-source support access beyond the disclosed facts in section
8.1 and every effect remain behind their later explicit gates.

This document freezes the source, opportunity, censoring, support, parity, and
execution contract for a possible current-release Plant Phenology adapter. It is
deliberately written before calculating or inspecting any current-release climate
effect estimate. It is effect-blind, not fully source-blind: the pre-existing
`346/45/39` app-support benchmark and the exact source-shape facts enumerated in
section 8.1 informed the contract. Passing this specification would establish an
auditable response and support layer; it would not by itself authorize a
temperature -> green-up vote, a new prior, or a generated Driver artifact.

## 1. Scope and no-look boundary

The complete sealed pre-effect sequence (Seals 1-4) may answer only these
questions, and each question may be answered only at the stage authorized in
section 10:

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
- inspect additional current-source support, censoring, cadence, calendar, or
  model-feasibility distributions before this adapter and primary-model registry
  is merged, or change an estimand, likelihood, analysis unit, eligibility rule,
  threshold, fallback, exposure, season, or lag because of those distributions;
- update `data/cascade.rds`, `data/search_index.rds`,
  `data/cascade_meta.rds`, `data/neon-cascade-codebook.csv`, or `manifest.json`; or
- change the v1 artifact's two historical temperature/green-up rows.

Merging the registry does not itself authorize current-support access. Seal 1 may
use only synthetic fixtures; Seal 2 may use only the exact legacy pin; and current
support counts, key intersections, exclusion counts, invariant checks, and opaque
digests become permitted only inside Seal 3A/3B after every preceding gate passes.
Logs and receipts must omit response values and effect-like quantities. Internal
value comparisons required for legacy parity may return only pass/fail, row
counts, field counts, and bounded numeric deltas—not site names, response values,
correlations, coefficients, p-values, ranks, or directions.

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
| Frozen Driver climate-source origin | `https://github.com/tgilbert14/NEON-Small-Mammal-Tracker-App.git` |
| Frozen Driver climate-source commit | `d2a53282637e4dbd7e5ebef7f64665fa27028531` |
| Frozen Driver climate `data/env` tree | `3825e1f68fd6c99367d3959b64086a849c57538d` |

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

One `obs` row is one source status record for one tagged plant, one phenophase,
and one visit. Source rows can repeat or conflict, so a row is not yet the
Driver-owned visit grain. These exact fields are required:

| Field | Required interpretation |
|---|---|
| `individualID` | nonblank tagged-plant identity |
| `plotID` | nonblank source monitoring location for that visit |
| `scientificName` | recorded taxonomic identity; may be excluded later if unresolved |
| `growthForm` | recorded plant growth form |
| `year` | integer calendar year |
| `date` | valid visit date and the v2 scientific clock authority |
| `dayOfYear` | nullable source-supplied day retained for app/v1 compatibility and discrepancy audit |
| `phenophaseName` | exact recorded phenophase label |
| `status` | exactly `yes`, `no`, or `uncertain` |
| `intensity` | retained source attribute; not an onset or leaf-duration input |
| `is_species` | explicit species-rank eligibility flag |

Every `date` must parse and its calendar year must equal `year`. The v2 adapter
derives `visit_doy` as the integer day of year from that validated date. Every
nonmissing source `dayOfYear` must be numeric, finite, integer-compatible, and
inside 1-366; `NaN`, `Inf`, `-Inf`, nonnumeric tokens, fractional values, and
out-of-range values are hard failures. A source `dayOfYear` may be missing or a
valid finite value may disagree with `visit_doy`; either case is retained as a
counted source discrepancy, not allowed to overwrite the date-derived clock, and
not by itself a release failure.

This creates a deliberate two-clock contract:

- the scientific v2 interval ledger uses only date-derived `visit_doy`; and
- the app/v1 compatibility path uses the committed source `dayOfYear`, including
  its historical missingness, exactly as the published lineage did.

The two clocks must have separate columns, tests, counts, and reason codes. No
fallback can silently mix them within one estimator.

Upstream `missed` records are absent by the release contract. `uncertain` remains
a real recorded state but is never converted to `no`, included in a yes/no
denominator, or used to locate an onset bound.

The v2 visit grain is
`site x individualID x phenophaseName x date`. Preserve all source rows through
validation, then collapse exact duplicate status tokens at that grain. If more
than one distinct status token remains, classify the visit as
`visit_status_conflict`; it contributes neither a yes nor a no bound. Never pick
one token by source or row order. Conflicting nonblank visit plots within this
exact grain are corruption. The compatibility path instead preserves the exact
source-row behavior required for v1 parity. Row order and duplicate order must not
affect either path.

### 3.4 Individual roster and metadata

`inds` must contain one row per `individualID` and these exact fields:

```text
individualID, scientificName, growthForm, plotID, lat, lng,
nativeStatusCode, taxonRank, is_species
```

The roster key must be unique. For an observation identity that resolves to one
roster row, nonmissing scientific identity, growth form, and species-rank values
must agree. Ambiguity or disagreement in those taxonomic fields fails rather than
being settled by row order.

The two plot fields have different source meanings. `obs$plotID` is historical
visit metadata; `inds$plotID` is the release generator's stable first-source
roster value. They may disagree or an individual may have more than one
observation plot through time. Both values must be valid for the file's site, but
the adapter must audit rather than reject those differences and must never
overwrite a visit plot with the roster plot. Plot is not part of the biological
identity; its primary analytic role is frozen separately in section 7 rather than
inferred from whether the two source columns agree.

An observation identity absent from `inds` is retained as
`roster_unmatched_taxon_unknown` only when its denormalized
`scientificName`, `growthForm`, and `is_species` are all missing. It remains
in the opportunity ledger but is taxonomically ineligible. An unmatched identity
that asserts any nonmissing taxonomic eligibility, or any duplicate/ambiguous
roster identity, is a hard failure.

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

A source plant-year opportunity is one distinct
`site x year x individualID` with a nonblank source identity and at least one
valid dated observation. Roster resolution, taxonomic rank, target-phase scoring,
and onset detection are not requirements for entering this denominator.

The full ledger assigns a calendar state first. Rows inside the immutable Driver
window `2013 <= year <= 2025` form the monitored Driver-window denominator; rows
outside it remain counted as `outside_driver_window` but cannot enter an annual
response. Multiple visits, phenophases, and duplicate rows do not create more
plant-year opportunities.

The ledger also assigns an independent taxonomy state:

- `eligible_species`: one roster match, explicit `is_species == TRUE`, and a
  nonblank stable scientific identity;
- `taxon_rank_ineligible`: resolved identity not eligible at species rank; or
- `roster_unmatched_taxon_unknown`: the narrow all-taxonomy-missing exception
  in section 3.4.

The existence of a monitored plant-year is opportunity, not evidence that a
green-up phase occurred.

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
`site x individualID x scientificName x growthForm x phenophaseName x year`,
use the normalized, date-clocked v2 visits from section 3.3. Mixed-status visits
remain counted but supply neither yes nor no.

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
- If no unambiguous yes/no visit remains and at least one mixed-status visit
  exists, the record is `status_conflict_only`.
- Otherwise target-phase rows that are all uncertain form `uncertain_only`;
  uncertainty is not absence.
- A monitored plant-year with no target-phase row is `structural_unscored`.

Uncertain and conflict visits remain attached as audit counts even when another
visit supplies an interval. Every monitored plant-year must be represented by one
or more phase rows or by an explicit structural state. No state may disappear
merely because it cannot contribute a scalar timing estimate.

### 4.3 Individual-year green-up record

The adapter produces two explicitly separate individual-year records.

For the scientific v2 interval, represent each informatively observed phase as
`(lower_doy, upper_doy]`: `(-Inf, upper]` for left censoring,
`(lower, Inf)` for right censoring, and the finite interval for a bounded onset.
If any scored target phase for that plant-year is wholly uncertain or
status-conflicted, it remains capable of being the earliest phase but supplies no
bound. The composite is therefore `ambiguous_competing_phase` and unavailable;
the adapter may not silently drop that phase and use a more convenient bounded
one. A target phase with no source row is structural absence from the monitored
phase set, not an unbounded competing interval.

For the earliest onset among the observed target phases:

```text
individual_lower = min(phase lower bounds)
individual_upper = min(phase upper bounds)
```

Here a missing lower bound is `-Inf` and a missing upper bound is `Inf`. Thus
any phase capable of making the earliest onset left-censored preserves that left
censoring, all-right-censored phases remain right-censored, and bounded phases
are combined without selecting one convenient row. A finite interval must satisfy
`individual_lower < individual_upper`; a violation is a hard failure. A record
whose only informative phase bounds are right-censored remains
`right_censored_no_yes` and audit-only; it is not evidence that a seasonal onset
event eventually occurred.

For exact v1 compatibility only, recompute phase values from the original source
rows and source `dayOfYear`: bounded midpoint, or `first_yes` for a
left-censored phase. The minimum compatibility value defines the historical
candidate earliest phase. When compatibility values tie, any tied left-censored
phase makes the whole record left-censored. Reproduce the historical width exactly
as the maximum finite `2 * (first_yes - compat_onset)` across tied rows and
reproduce the stable radix-lexical scientific-name choice used by
`cascade_individual_year_onset()`. Those are namespaced lineage behaviors only;
v2 separately rejects an ambiguous taxonomic identity and never treats the
lexical choice as scientific adjudication.

The compatibility collapse reproduces the published lineage. It does not make a
left-censored upper bound an exact v2 response. The registered v2 model consumes
the independent bounds/censor states directly. Left- and right-censored records
must never be silently inserted into a point-outcome analysis.

### 4.4 Required opportunity partition

Every full-ledger plant-year carries five separate axes:

```text
calendar_state       = inside_driver_window | outside_driver_window
taxonomy_state       = eligible_species | taxon_rank_ineligible |
                       roster_unmatched_taxon_unknown
v2_observation_state = bounded_onset | left_censored_onset |
                       right_censored_no_yes | uncertain_only |
                       status_conflict_only | ambiguous_competing_phase |
                       structural_unscored
v2_eligibility_state = pending | model_row | species_year_excluded |
                       recurrence_excluded | connected_panel_excluded
compat_censor_state  = compat_bounded | compat_left_censored |
                       compat_no_finite_onset
```

For a one-column terminal partition, apply only this declared priority:
`outside_driver_window`, then either taxon-ineligible state, then the seven v2
observation states. The independent axes remain in the ledger, so a taxonomically
ineligible plant's observational history is not erased.

Composition and connected-panel exclusions update only `v2_eligibility_state`; they
never rewrite observational or taxonomy state. Annual emission is a separate
site-year field:

```text
v2_annual_response_state = supported | insufficient_observed_species |
                           insufficient_timing_individuals | no_retained_panel
```

It never rewrites a plant-year's model-row membership. Annual totals must reconcile
from the source denominator through calendar, taxonomy, observation/censoring,
panel eligibility, and the separate emission state. Unknown, unsupported,
conflicted, censored, and zero are never interchangeable.

## 5. Compatibility index and support eligibility

The first adapter implementation must reproduce the existing Driver scalar
construction as an explicitly named compatibility layer. It remains non-voting
through this cycle. It can receive a climate effect only under a future,
separately sealed sensitivity registry.

### 5.1 Eligible individual-year contributors

The compatibility index starts only from historical compatibility records whose
`compat_censor_state == "compat_bounded"` and that are:

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
This `greenup_doy_additive_compat` is parity/response-sensitivity output only; it
receives no climate effect in this cycle. A rank-deficient design is a hard
failure; missing species-years are disclosed model extrapolations.

### 5.5 Censoring and cadence audits

Compatibility and v2 fields must be namespaced; clock-dependent states may not
share a column. For every source-support year, carry at least:

```text
compat_n_onsets
compat_n_left_censored
compat_n_excluded_umbrella
compat_n_individuals
compat_n_species
compat_reference_doy
compat_interval_median_days
compat_interval_p90_days
compat_interval_max_days
v2_n_monitored
v2_n_target_scored
v2_n_timing_candidates
v2_n_bounded
v2_n_left_censored
v2_n_right_censored
v2_n_uncertain_only
v2_n_status_conflict_only
v2_n_ambiguous_competing_phase
v2_n_structural_unscored
v2_n_taxon_excluded
v2_n_species_year_excluded
v2_n_recurrence_excluded
v2_n_connected_panel_excluded
v2_n_model_individuals
v2_n_model_species
v2_annual_response_state
v2_n_conflicting_visits
v2_n_source_doy_missing
v2_n_source_doy_mismatch
v2_n_roster_unmatched
v2_n_plot_history_mismatch
```

For legacy parity, `compat_n_excluded_umbrella` maps to the published
`greenup_n_taxon_excluded` and must equal
`compat_n_onsets - compat_n_left_censored - compat_n_individuals`. Despite its
historical name, that umbrella includes taxonomy, species-year support,
recurrence, and disconnected-panel exclusions. The new disjoint `v2_*` reason
counts must reconcile independently and must never be summed with that umbrella.

The v2 timing-candidate universe is fixed before taxonomy or composition screens:

```text
v2_n_timing_candidates = v2_n_bounded + v2_n_left_censored
v2_n_timing_candidates = v2_n_taxon_excluded +
                         v2_n_species_year_excluded +
                         v2_n_recurrence_excluded +
                         v2_n_connected_panel_excluded +
                         v2_n_model_individuals
```

Here `v2_n_bounded` and `v2_n_left_censored` count inside-calendar observation
states before taxonomy screening. All terms in the second equation are mutually
exclusive terminal dispositions of those timing candidates; consequently
`v2_n_taxon_excluded` counts only taxonomically ineligible timing candidates, not
every taxonomically ineligible monitored row. In this annual ledger,
`v2_n_model_individuals` means retained one-row-per-individual-year likelihood
rows, including rows from a retained panel year that later fails the
two-species/six-individual emission gate. Observation-only and annual-emission
states are reported separately and never added to this equation.

The p90 interval uses R type-7 quantiles. Interval summaries are finite exactly
when at least one final bounded contributor exists, ordered
`0 <= median <= p90 <= max`, and are timing-resolution audits—not confidence
intervals for the annual index.

Use these exact diagnostic denominators:

- left-censored share =
  `v2_n_left_censored / v2_n_timing_candidates`;
- composition/support exclusion share = the disjoint sum of taxon,
  species-year, recurrence, and connected-panel exclusions divided by
  `v2_n_timing_candidates`.

A zero denominator yields `NA`, never zero. The existing review thresholds remain
diagnostic:

- left-censored share `>= 0.50` is a censor-burden warning;
- composition/support exclusion share `>= 0.50` is an exclusion-burden warning;
- median bounded interval `> 14` days is a typical-cadence warning; and
- maximum bounded interval `> 30` days is an extreme-cadence warning.

Warnings never become zeros. In the registered primary model below, censor,
exclusion, cadence, and the source-clock `thin_greenup` context label are
descriptive and have no additional effect on row inclusion, likelihood weight,
site eligibility, or voting. That consequence may not change after support is
observed.

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

Because this stratum is calculated with the source-DOY compatibility clock and is
conditioned on a finite app-style onset, it is context selection only. It has no
effect on date-clock v2 response fitting, site/contrast eligibility, direction
votes, or pooling. The v2 primary is governed only by its direct opportunity,
censoring, panel, annual-support, and climate-support rules below.

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

## 7. Registered v2 response and temperature-association model

This section is part of Seal 0. It freezes the primary response model, support
rules, two climate contrasts, effect estimator, pooling, multiplicity, and claim
limits before the first additional current-source support receipt. Support may
cause only the declared `PROCEED TO UNSEAL` or
`HOLD / INSUFFICIENT PRE-EFFECT SUPPORT` outcomes; it may not cause a model change.

### 7.1 Primary unit and interval rows

The primary analysis remains within site. One model row is one
`site x individualID x year` v2 interval after the visit, phase, taxonomy, and
calendar rules above. A model row may be:

- bounded; or
- left-censored, represented to `survival::Surv(..., type = "interval2")` with
  missing lower bound and finite upper bound.

A plant-year whose only informative target phases are right-censored/no-yes is an
audit abstention, `eventual_onset_not_established`. Treating it as an ordinary
right-survival event would assume that the recurrent seasonal phenophase
eventually occurs for every plant-year, which these observations do not establish.
A right-censored phase may still widen the conservative earliest-phase envelope
when another target phase in that plant-year has a yes. Uncertain,
status-conflicted, ambiguous-competing-phase, structural, out-of-window, and
taxonomically ineligible records never enter the likelihood.

The primary response is named `greenup_doy_interval_std`. It is a modeled,
composition-standardized latent DOY location, not an observed pooled median, an
abundance measure, whole-community leaf-out, or a causal estimate.

### 7.2 Frozen support panel and warning consequences

Within each site:

1. a species-year cell is eligible with at least three distinct bounded or
   left-censored individual-year rows and at least one bounded anchor;
2. a species is recurrent with at least three eligible species-years;
3. select the deterministic largest connected species-year component using the
   ranking in section 5.3;
4. include all bounded and left-censored individual-year rows in retained cells;
5. before fitting, mark a retained panel year as `annual_response_supported` only
   when it has at least two observed retained species and at least six distinct
   observed timing individuals;
6. define `response_fit_eligible` as a site with a nonempty connected recurrent
   panel and at least six `annual_response_supported` years;
7. fit all and only `response_fit_eligible` sites, using every bounded and
   left-censored row in their retained cells; and
8. after prediction, emit annual responses only for the pre-fit
   `annual_response_supported` years.

The release-wide app-compatible green-up coverage in section 6.2 is calculated
before any climate join. Its `thin_greenup` label remains fully visible in the
support ledger but has no primary-model or vote consequence. Sites at exactly
`0.50` are not thin. Leaf-active remains context and cannot replace or supplement
the primary onset response.

The censor-burden, exclusion-burden, median-cadence, and maximum-cadence warnings
in section 5.5 are descriptive only. The interval likelihood already carries
censoring and bounded timing resolution; warnings cause no further exclusion or
weighting. Source-day discrepancies affect only compatibility/audit because the
v2 clock is date-derived. Mixed-status visits are excluded at the frozen visit
normalization boundary, not through a later warning rule.

### 7.3 Equal-cell weighting, repeats, and likelihood

Fit one response-only model per `response_fit_eligible` site. Let `N` be the number of retained
model rows, `C` the number of retained species-year cells, and `n_sy` the number of
model rows in a row's species-year cell. Assign:

```text
w_i = N / (C * n_sy)
```

Let `weight_tol = 1e-12 * max(1, N)`. All weights must be positive;
`abs(sum(w_i) - N) <= weight_tol`; `abs(mean(w_i) - 1) <= 1e-12`; and every
species-year cell's weight sum must differ from `N / C` by no more than
`weight_tol`. Thus every retained species-year cell has equal total likelihood
weight; a heavily monitored species-year cannot dominate merely through abundance
of tagged plants.

The sole primary fit is:

```r
survival::survreg(
  survival::Surv(lower_doy, upper_doy, type = "interval2") ~
    scientificName + factor(year),
  data = model_rows,
  dist = "gaussian",
  weights = model_weight,
  robust = TRUE,
  cluster = individualID,
  na.action = stats::na.fail,
  control = survival::survreg.control(
    maxiter = 30L,
    rel.tolerance = 1e-9,
    toler.chol = 1e-10,
    outer.max = 10L
  ),
  model = TRUE,
  x = TRUE,
  y = TRUE
)
```

Use `NA` only for a left-censored lower bound; bounded bounds are finite.
Scientific-name levels are radix-lexical and year levels ascending. Species and
year are fixed effects, stable `individualID` supplies the within-site sandwich
cluster, and sites are fit separately. Plot has no term in this registered primary
model; its historical values remain audit/spatial-context metadata. No frailty,
random effect, imputation, precision weighting, distributional fallback, or
alternate optimizer is allowed.

The implementation PR must add `survival` and `metafor` to the exact canonical
runtime contract, record both installed versions plus the full package inventory,
and merge those pins before any current-source model/support run. R 4.5.2, the
dated 2026-07-15 Posit snapshot, loaded Haswell OpenBLAS, and one thread remain
fixed. The exact `survival` version and controls become immutable response-support
authorities; the exact `metafor` version and full effect-package inventory must be
reverified unchanged before unseal. Runtime drift returns to Seal 0/1.

No unweighted individual-year fit runs in this cycle. It requires the separately
sealed future sensitivity registry described in section 7.6.

### 7.4 Annual standardization and numerical gates

Require full design rank
`n_species + n_years - 1`, no fit warning or nonconvergence, finite coefficients,
a finite positive scale, and a finite robust covariance. Predict Gaussian latent
location with `type = "lp"` over the complete Cartesian grid of every retained
species and every retained panel year. For each year, take the equal-species
median prediction. Apply the observed two-species/six-individual annual gate after
prediction.

Predictions are full precision and are never clipped, rounded, or pulled toward a
compatibility midpoint. Every full-grid species-year prediction and every annual
equal-species median must be finite and inside 1-366, including medians for years
that later remain un-emitted. The prediction vector must be invariant to input
order and factor reference coding and reproduce across two clean canonical runs.
The production fit and an independent numerical oracle must agree within
`1e-8 + 1e-8 * fitted_scale`; tighter adapter-only fields retain the
tolerances in section 9.1.

The response-support process may persist only the annual response count,
missingness mask, convergence/rank results, and an opaque canonical response
digest. It must not print or serialize response values for inspection and must not
load a climate object. That process must exit and its exact receipt/digest must be
sealed before a separate one-way climate-support-mask process can run.

The climate-support-mask process may read the frozen new-v2 response-presence mask
(`site x year` booleans, never new-v2 response values) and only archived
`data/env/*.rds` files from the exact Small Mammal climate origin, commit, and tree
in section 2. It must assert the canonical origin, detached commit, exact
`data/env` tree, 46-file Driver roster, and clean archive before deserializing a
bundle. No Driver response artifact is an allowed climate source.

The mask builder independently reproduces the registered Driver climate support:

1. require `temp_c` and either `date` or `ym`; parse one date and integer month per
   row, restrict to 2013-2025, and hard-fail duplicate `site x year x month` rows;
2. treat a monthly temperature as valid only when finite and strictly between
   -40 and 50 degrees C;
3. calculate `temp` only from exactly 12 valid calendar months and `temp_spring`
   only from exactly three valid March-May months;
4. for each contrast within site and after the calendar restriction, if at least
   four annual means are finite, set
   `threshold = max(6, 3 * stats::mad(finite_means))` and mark a year unavailable
   when its mean differs from `stats::median(finite_means)` by more than that
   threshold; and
5. emit only `site x year x contrast` availability/QC booleans, per-contrast
   response-mask overlap counts, and opaque mask digests.

The builder may hold climate values internally to calculate those frozen masks,
but it must not print or serialize them. It must reject every new-v2 numeric
response input and must not print or serialize paired numeric values, site
rankings, or an effect-like quantity. Exact site/year keys and booleans are allowed
because they are the auditable support mask. No process before unseal may hold
both new-v2 numeric response and climate values.

### 7.5 Exactly two registered climate contrasts

Only these two lag-zero contrasts exist in this v2 family:

| Exposure | Completeness/QC | Expected direction | Role |
|---|---|---:|---|
| `temp` | complete 12/12 calendar-month annual mean; existing range and within-site MAD QC | `-1` | primary broad contemporaneous proxy |
| `temp_spring` | complete 3/3 March-May mean; same range and within-site MAD QC | `-1` | registered historical-window sensitivity |

The climate source is the exact archived Small Mammal `data/env` authority in
section 2, and its window, range, MAD, calendar, and missingness behavior is the
algorithm frozen in section 7.4. There is no lag search, season search, exposure
substitution, or interpolation. Warmer conditions are registered to accompany
lower/earlier modeled DOY. Annual temperature is a broad contemporaneous proxy;
March-May can include weather after some onsets. Neither is called a trigger or
causal exposure.

For each unsealed site/contrast allowed by the exact support-mask rules, use the
unweighted Pearson correlation over the exact complete response/exposure years,
with `n >= 6` and the full calendar gap pattern retained. The raw correlation is
the registered site effect. Reuse
the versioned Driver circular-shift diagnostic, moving-block bootstrap interval,
linear-year detrended sensitivity, and truly adjacent-year change sensitivity at
the specification authority. Those diagnostics can never replace or gate the raw
effect.

### 7.6 Site votes, pooling, multiplicity, and sensitivities

A finite raw effect with absolute value
`<= sqrt(.Machine$double.eps)` is a direction tie and abstains. Every other
eligible site contributes at most one expected-direction vote per contrast.
Pool the direction screen only with at least three non-tied site votes, using the
exact one-sided binomial reference
`stats::binom.test(k_expected, n_non_tied, p = 0.5, alternative = "greater")`.
Apply
`stats::p.adjust(p, method = "holm", n = 2L)` across the fixed two-link family even
when one contrast is unavailable. Emit a display-only BH value using
`stats::p.adjust(p, method = "BH", n = 2L)`. Raw and adjusted direction-screen
p-values are exploratory references with no automatic alpha threshold, ecological
promotion, or canonical-byte consequence.

The companion Fisher-z random-effects summary runs only when at least five finite
site effects are available. It freezes the existing Driver construction:
`z = atanh(pmax(pmin(r, 0.999), -0.999))`, `vi = 1 / (n - 3)`, and
`metafor::rma(yi = z, vi = vi, method = "REML", test = "knha")`. Report the
REML heterogeneity estimate, Knapp-Hartung 95% CI, and 95% prediction interval;
back-transform the pooled estimate and both intervals with `tanh`. Report the
expected-direction one-sided p-value from the fitted Knapp-Hartung t statistic
`t = b / se` and `df = k - 1` (the meta model has one intercept coefficient): use
`stats::pt(t, df)` for expected-negative and
`stats::pt(t, df, lower.tail = FALSE)` for expected-positive directions. It is
descriptive and cannot override the direction screen. Its Holm adjustment also
uses the fixed two-link family and `n = 2L`.
The two v2 contrasts form their own frozen family; they are not silently folded
into or selected from the historical 12-link catalog.

The first unsealed effect run computes no compatibility-index,
additive-compatibility, unweighted-interval, or leaf-active climate effect. Those
responses remain lineage/context outputs only. Any later effect sensitivity needs
a separately sealed registry and multiplicity role before it can run; it cannot be
selected after viewing the primary result.

### 7.7 Failure, feasibility decision, and claim limit

Every `response_fit_eligible` site must be attempted. Any attempted primary site
fit that fails rank, likelihood, warning, convergence, covariance, prediction,
invariance, or determinism checks is a hard family failure—not a selectively
dropped site. No fallback model is tried. Pre-fit response losses from taxonomy,
observation state, species-year support, recurrence, component selection, or fewer
than six `annual_response_supported` years are declared response-support
abstentions.

At Seal 4, a contrast is `PROCEED TO UNSEAL` only when the values-free mask shows
at least three `response_fit_eligible` sites with at least six emitted response
years overlapping that contrast's climate-availability/QC mask. Otherwise it is
`HOLD / INSUFFICIENT PRE-EFFECT SUPPORT`. This gate uses no response value,
climate value, correlation, direction, or tie status. One held contrast does not
promote or demote the other, and `PROCEED TO UNSEAL` authorizes only the separately
reviewed registered effect run.

After unseal, climate completeness/QC, fewer than six exact paired years, a
nonfinite effect, or a direction tie are declared contrast-level abstentions. If
fewer than three non-tied effects remain, the direction screen is
`UNAVAILABLE / INSUFFICIENT NON-TIE VOTES` without a binomial p-value; this is not
a retroactive change to the pre-effect support decision and never authorizes a
fallback.

The maximum claim is a within-site observational association for a connected,
species-rank, monitored target-phase panel, summarized across sites under an
exploratory spatial-independence assumption. It is not causal, not a trigger
model, not whole-community onset, and not a leaf-active result.

Any adapter, clock, visit, interval, panel, weight, model, exposure, threshold,
warning consequence, pooling, multiplicity, or claim change after the first
current-support access invalidates prospective same-release status. The frozen
plan may remain and follow the exact sealed/unsealed outcomes above; otherwise the
current release becomes design/exploratory data and a distinct held-out authority
is required for a confirmatory Driver vote.

## 8. Exact pre-effect expectations

These are topology and support expectations, not effect targets.

### 8.1 Current release/app support

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

These additional exact source-shape facts were measured from the immutable current
data tree before this registry was sealed and are therefore disclosed inputs, not
post-registry discoveries:

| Source-shape check | Exact current authority |
|---|---:|
| Raw observation rows | 5,735,598 |
| Roster individuals | 9,537 |
| Observation rows with valid date but missing source `dayOfYear` | 14,990 |
| Finite source `dayOfYear` values disagreeing with the valid date | 2,199 |
| Green-up duplicate visit grains | 6,599 |
| Green-up mixed-status visit grains | 226 |
| Green-up duplicate visits carrying multiple source DOYs | 90 |
| Roster-unmatched observation rows / identities / plant-years | 6 / 1 / 1 |
| Historical observation/roster plot disagreements | 10,477 rows / 74 individuals / 4 sites / 5 directed plot pairs |
| Target-scored plant-years / with exactly one target phase | 33,938 / 33,938 |

All 5,735,598 dates parse, all recorded years agree with their dates, all source
statuses are `yes/no/uncertain`, and all current rows are inside 2013-2025. These
facts justify the explicit two-clock, visit-conflict, and roster/plot contracts;
they do not expose annual response values or climate effects.

### 8.2 Driver output topology

The sealed support adapter must outer-join to exactly 510 unique Driver
`site x year` rows across exactly 46 sites. It may add no site or year. All 346
app-supported keys must remain auditable, even if later censoring/composition gates
make a scalar index unavailable.

Finite current-release compatibility-index keys must be a reason-coded subset of
the app-supported keys. The date-clock v2 model calendar is separate and may
recover or lose keys through declared clock, visit-conflict, censoring, panel, or
support rules. Exact compatibility and v2 model-support counts are deliberately
`UNMEASURED` before the first support-only run; neither may be guessed from the
legacy artifact or made a target for threshold tuning. The response-support
receipt records both only after every adapter and primary-model support rule above
is frozen, tested, merged, and named by exact commit.

### 8.3 Legacy compatibility baseline

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

## 9. Independent oracle and fixtures

### 9.1 Test-owned raw-observation oracle

Tests must contain an independent, test-owned recomputation from `bundle$obs`.
The oracle must not call the production adapter's onset, collapse, connectivity,
index, or leaf-active functions. It must not source sibling code. Shared constants
are limited to literal field and phenophase contracts whose equality is asserted.

Across all 46 exact current bundles, the oracle must compare:

- source-clock and date-clock values, discrepancy flags, and normalized visit keys;
- duplicate-visit and mixed-status conflict states;
- opportunity, taxonomy, v2 observation, compatibility-censor, and eligibility keys;
- interval bounds and widths;
- mutually exclusive audit counts;
- taxonomy and support exclusions;
- connected-component membership;
- final contributor/species counts, model cells, and normalized weights;
- reference anchors and both compatibility indexes;
- primary response-model design/rank, annual missingness mask, predictions, and
  opaque digest; and
- seven-day leaf-active keys and values.

The production and oracle support calendars must be identical. Exact integer,
logical, character, categorical, and key fields must be identical. Numeric adapter
fields other than the additive model must agree with absolute tolerance `1e-15`;
the additive compatibility estimator may use absolute tolerance `1e-12` because
the canonical cross-platform oracle already establishes that bounded allowance.
The interval-model prediction uses only the registered tolerance in section 7.4.
No artifact may be rounded to force parity.

`trend` is checked separately for the exact 346/45/39 app-support benchmark. It is
never substituted for the raw-observation oracle.

A separate test-owned climate-mask oracle runs only after the response receipt is
sealed. It receives the response-presence mask but no response values, independently
recomputes each registered climate completeness/range/MAD boolean, and compares
only booleans, counts, and opaque digests. Its process and the response-model
process must not share numeric response and climate objects.

### 9.2 Required adversarial fixtures

At minimum, executable fixtures must cover:

1. same-status duplicates within one plant/phase/date collapsing once;
2. mixed `no+yes`, `uncertain+yes`, and `no+uncertain` visits becoming
   `visit_status_conflict` regardless of row order;
3. multiple source DOYs within one valid-date visit leaving one date-derived v2
   visit clock;
4. valid date plus missing source DOY: v2 retained, compatibility omitted;
5. valid date plus disagreeing finite source DOY: v2 date-clocked and compatibility
   source-clocked with no fallback between them;
6. the same plant and week in different years remaining distinct opportunities;
7. `uncertain` excluded from yes/no and onset bounds;
8. a bounded last-no/first-yes interval and exact compatibility midpoint;
9. a first-visit yes retained as left-censored, not exact;
10. all-no target records retained as right-censored/no-yes and excluded from the
    primary likelihood, not set to zero;
11. a monitored plant with no green-up phase retained as structural-unscored;
12. an informative phase plus an uncertain/conflict-only competing target phase
    becoming `ambiguous_competing_phase` rather than silently dropping the latter;
13. earliest-phase envelope algebra for bounded, left-, and right-censored mixes;
14. exact v1 tied behavior: any tied left censor, radix-lexical compatibility
    taxon, and maximum `2 * (first_yes - compat_onset)` width;
15. a v2 taxonomic identity conflict failing independently of v1 lexical parity;
16. the narrow all-taxonomy-null unmatched roster identity retained and excluded;
17. an unmatched roster identity asserting taxonomy failing closed;
18. historical observation/first-roster plot disagreement accepted and audited;
19. conflicting plots within one exact visit failing closed;
20. species-rank exclusions;
21. exactly two versus three timing individuals and the required bounded anchor at
    the species-year boundary;
22. exactly two observed species/six individuals at the annual boundary;
23. recurrence at two versus three eligible years;
24. disconnected species-year panels and every deterministic tie-break;
25. abundance/composition shifts resisted by equal-cell likelihood weights and
    equal-species standardization;
26. exact weight positivity, mean-one, sum-`N`, per-cell total, and registered
    tolerance invariants;
27. repeated individuals clustered within site, with plot absent from the primary
    design;
28. rank-deficient versus full-rank compatibility and interval designs;
29. fit-warning, nonconvergence, covariance, out-of-range prediction, reference-
    coding, and row-order failures;
30. empty contributor tables producing typed `NA` support fields without warnings;
31. leaf yes on days 1, 2, 8, and 100 producing 21 days;
32. the uncapped day-365/366 week-53 behavior;
33. `Leaves=no`/`uncertain` without yes remaining `NA`, not zero;
34. multi-flush yes weeks remaining additive;
35. green-up coverage immediately below, at, and above 0.50 changing only the
    leaf-active context stratum and never primary response/vote eligibility;
36. five versus six `annual_response_supported` years at the exact
    `response_fit_eligible` boundary, with all eligible fits attempted;
37. one-way climate-support masks at five versus six overlapping years and two
    versus three eligible sites, with no response/climate numeric co-residence;
    and
38. malformed containers, duplicate roster identities, conflicting metadata,
    invalid date/year, every invalid nonmissing source DOY class, and unsupported
    status tokens failing closed.

### 9.3 Legacy old/new parity

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

Use the tolerances in section 9.1. Missingness patterns must be identical. The
test must also reproduce the exact legacy support counts in section 8.3 without
calling any effect function.

On current data, compare the compatibility output to the legacy output only through
a reason ledger. Every added, removed, or changed support key must receive one or
more stable reasons from this closed vocabulary:

```text
source_row_added
source_row_removed
source_value_changed
source_day_missing
source_day_disagrees_with_date
visit_status_conflict
roster_identity_unresolved
historical_plot_disagreement
calendar_window
compat_censor_state_changed
v2_observation_state_changed
taxon_identity_changed
species_year_support
species_recurrence
connected_component
annual_support
cadence_audit_changed
thin_greenup
model_support
```

An unexplained difference is a hard failure. The ledger reports counts and key
digests during the sealed phase, not site identities, response values, or effects.

### 9.4 Determinism

The adapter and oracle must pass:

- two clean runs with identical canonical support-ledger, reason-ledger,
  response-presence, and climate-support-mask SHA-256 digests;
- randomized input row-order trials with identical canonical output;
- C and UTF-8 locale structural parity;
- canonical Ubuntu 24.04 / R 4.5.2 / dated 2026-07-15 package snapshot /
  OpenBLAS Haswell / one-thread execution; and
- the existing strict cross-platform source oracle, with the additive-only
  tolerance above.

Canonical ordering must be explicit and radix-stable. Wall-clock dates, random
seeds, checkout paths, process IDs, and unordered hash/table iteration must not
enter output.

## 10. Seal, support review, and unseal sequence

The work is divided into separately reviewable stages.

### Seal 0 - specification

Merge this document, including the adapter contract and section 7 primary-model
registry, before any additional current-source support/model run or climate effect
path. Record its exact commit as the registry authority.

### Seal 1 - pure adapter and synthetic contracts

Implement only the visit -> opportunity -> support adapter, the response-only
interval model, the one-way values-free climate-support-mask builder, and
independent tests. Pin the exact installed `survival` and `metafor` versions, full
package inventory, and runtime authority in the implementation commit before any
current-source model/support run. Effect-producing modules are not sourced. The
adapter/response process must default to an effect-locked mode and abort if an
effect-producing symbol, script, or climate object is invoked. The mask builder is
a separate process and is tested synthetically to reject new-v2 numeric response
values and effect functions.

### Seal 2 - legacy parity

Run the adapter against `81e339e9...` and prove sections 8.3 and 9.3. Do not fetch or
inspect current response/effect output to repair a legacy mismatch.

### Seal 3A - current response-support receipt

Run the frozen adapter and response-only model against the exact current source.
The first durable receipt may contain only:

- specification, Driver, data, knowledge, generator, tree, manifest, and runtime
  authorities;
- schema and roster results;
- opportunity/censor/support/model-eligibility counts;
- exact `site x year` response-presence booleans and calendar intersections;
- reason-code counts;
- opaque key/weight/response-output digests;
- test commands and pass/fail results; and
- explicit confirmation that no effect module executed.

It must not contain response values, site rankings, climate pair values, effect
estimates, signs, intervals, coefficients, or p-values.

The response process then exits. Its receipt and response-presence digest become
immutable inputs to the next stage.

### Seal 3B - values-free climate-support-mask receipt

In a fresh process, run only the registered climate-support-mask builder. It may
read only the exact archived Small Mammal `data/env` authority from section 2 and
the sealed response-presence mask; it must reject every new-v2 numeric response
input. The second durable receipt may contain only authorities, per-contrast
availability/QC counts, response-mask overlap counts, exact keyed support
booleans, opaque mask digests, test commands, and pass/fail results. It must omit
all new-v2 response values, climate values, paired numeric values, effects, signs,
intervals, coefficients, ranks, and p-values.

### Seal 4 - preregistered support decision

Review both support receipts without effect output and apply only section 7.7:
issue `PROCEED TO UNSEAL` for a contrast with at least three
`response_fit_eligible` sites having at least six response-mask/climate-mask
overlap years; otherwise issue `HOLD / INSUFFICIENT PRE-EFFECT SUPPORT`. No
response definition, model, exposure, eligibility rule, warning consequence,
threshold, fallback, pooling rule, multiplicity family, sensitivity role, or claim
may change. Insufficient support does not authorize another model.

### Unseal - separate effect run

Only a later, separately reviewed commit may make effect code reachable. Its first
run must use the exact sealed adapter, response model, response receipt,
climate-support-mask receipt, registry, and source authorities. Any adapter, clock,
threshold, source, reason-code, response-model, or effect-model change after the
first current-support access invalidates prospective same-release status under
section 7.7; changing the plan requires a distinct held-out authority for a
confirmatory vote.

No stage authorizes a canonical Driver byte change until exact-head CI, independent
review, an explicit ecological disposition, guarded merge, and post-merge release
verification all pass.

## 11. Proposed later files and integration boundary

This specification proposes, but does not create, these implementation files:

| Proposed file | Purpose |
|---|---|
| `R/phenology_adapter_v2.R` | Pure Driver-owned visit/opportunity/support adapter; no effect functions |
| `R/phenology_response_model_v2.R` | Registered response-only interval model; cannot load climate |
| `R/phenology_climate_support_mask_v2.R` | Separate one-way climate availability/QC mask builder; rejects new-v2 response values |
| `scripts/test_phenology_adapter_v2.R` | Independent oracle, adversarial fixtures, legacy parity, determinism |
| `scripts/audit_phenology_v2_support.R` | Effect-locked current response-support and reason receipt |
| `scripts/audit_phenology_v2_climate_mask.R` | Separate values-free climate-support-mask receipt |
| `docs/receipts/phenology-v2-response-support.json` | Sealed response-support receipt without response/effect values |
| `docs/receipts/phenology-v2-climate-support.json` | Sealed mask/overlap receipt without response, climate, or effect values |

The first adapter PR should add a dedicated CI job that fetches the two immutable
Phenology authorities detached, pins the registered runtime, and runs only the
files above. It must not edit
`scripts/build_cascade.R`, the signal/prior tables, effect helpers, artifact writers,
generated data, or the deploy manifest.

Only after the unseal decision may a later integration consider changes to
`scripts/build_cascade.R`, `R/source_adapters.R`, the codebook, metadata, workflow
source locks, generated artifacts, and manifest. The supported artifact-generation
entry point remains `scripts/rebuild_all.R`; an adapter test never publishes live
outputs.

## 12. Hard failures and scientific abstentions

### 12.1 Hard failures

The sealed process must stop before effects when any of the following occurs:

- an authority, ancestry, origin, Git object, tree, manifest hash, or canonical
  Driver baseline hash differs;
- the Phenology source-data scope is dirty or changes during a run;
- the bundle roster is not exactly 46 expected sites;
- a required container/field is absent, nonrectangular, zero-length within a
  nonempty frame, duplicated, or of an incompatible type;
- site/file/meta identities disagree; a roster key is duplicated or ambiguous; an
  unmatched observation asserts taxonomy; matched taxonomic identity conflicts;
  or one exact visit has conflicting nonblank plots;
- a status token is outside `yes/no/uncertain`, a date is invalid, date/year
  disagree, a nonmissing source DOY is nonnumeric, nonfinite, noninteger, or
  outside 1-366, or a green-up phase is matched approximately. Missing source DOY
  and valid finite source-DOY/date disagreement are required audit states, not
  failures;
- finite interval bounds are outside 1-366, a required bound is missing, a bounded
  interval is not strictly increasing, or earliest-phase algebra is impossible;
- monitored-opportunity and censor/support partitions fail to reconcile exactly;
- output contains duplicate or out-of-calendar `site x year` keys, does not outer-
  join to 510 rows/46 sites, or loses an app-supported key from the audit surface;
- a selected incidence panel is disconnected or its deterministic tie-break is
  unstable;
- model weights are nonpositive or fail their cell-total/mean/sum invariants;
- the compatibility additive design or an attempted `response_fit_eligible`
  primary fit fails rank, warning, convergence, scale, covariance,
  prediction-range, reference-
  coding, row-order, numerical-oracle, or determinism gates;
- the canonical R/`survival`/`metafor`/effect-package-inventory/BLAS/thread/runtime
  authority drifts;
- the current 346/45/39 app-support benchmark, an enumerated source-shape fact in
  section 8.1, or a legacy expectation differs;
- raw-oracle, legacy parity, missingness, tolerance, row-order, locale, two-run
  digest, or reason-ledger checks fail;
- a current/legacy difference has no approved reason code;
- a support receipt exposes response/climate/paired numeric values or effect-like
  quantities; the response process loads climate; the mask process accepts
  new-v2 numeric response values; or a pre-unseal process holds both new-v2
  numeric response and climate objects; or
- any effect-producing function/script executes before unseal.

Do not weaken a schema, support, censoring, parity, provenance, or determinism gate
to make a source pass.

### 12.2 Legitimate abstentions

These conditions are honest unavailable states, not pipeline failures:

- a site or year has no target green-up observation;
- a record is uncertain, status-conflicted, ambiguous across competing phases,
  structurally unscored, out of window, or taxonomically ineligible;
- a left-censored record is unavailable to compatibility but remains eligible for
  the primary v2 model under section 7;
- an all-right-censored/no-yes plant-year remains audit-only because eventual
  onset is not established;
- a species-year has fewer than three timing contributors or no bounded anchor;
- a species recurs in fewer than three eligible years;
- no connected recurrent panel survives;
- an annual row has fewer than two observed species or six timing individuals;
- a site has fewer than six `annual_response_supported` years and is not
  `response_fit_eligible`;
- a contrast has fewer than six response/climate-mask overlap years at a site;
- a climate window is incomplete or fails its frozen range/MAD QC;
- an unsealed site effect is nonfinite or a direction tie;
- a contrast has fewer than three pre-effect support-eligible sites and remains
  `HOLD`, or fewer than three non-tied unsealed site votes and has an unavailable
  direction screen; or
- the descriptive meta-analysis has fewer than five sites.

Such rows remain in the audit ledger with `NA` scalar output and an explicit reason.
If the final support is insufficient, the ecological family remains `HOLD`; the
correct response is not to lower the gate, substitute leaf-active, change seasons,
or inspect another model.

## 13. Decision preserved by this specification

The Plant Phenology application contract is verified, and its current release has
measured Driver-calendar compatibility. Neither fact re-authorizes an ecological
edge. Until this adapter/model registry, independent oracle, response-support and
climate-mask receipts, preregistered support decision, old/new review, and
explicit unseal all pass, the decision remains:

```text
HOLD / NO DRIVER BYTE CHANGE / NO CURRENT-RELEASE EFFECT INSPECTION
```
