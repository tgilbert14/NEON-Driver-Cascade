# Vegetation plot x event adapter specification (Driver v2 Vegetation adapter)

Specification state: **DRAFT FOR OWNER DISPOSITION / NOT YET THE ADAPTER CONTRACT / NO DRIVER BYTE CHANGE**

Specification date: 2026-10-21

Authors: `cass` (cross-product synthesis, sections 1-8 and 9.1) with the `hk`
statistics sign-off in section 9.2. Written for the owner, who takes the
disposition in section 10.

Recommended disposition: **ADOPT** the adapter and the unchanged conditional
estimand; **HOLD** two named estimand questions (section 9.1). The honest reason
is in section 9.

This document becomes the adapter contract only when the owner records a
disposition in section 10 and the exact merged default-branch commit containing
that record is named as the authority. Before that, no production adapter code,
regenerated family, pin change, workflow change, or manifest change is
authorized. The dry-run prototype that produced the numbers below is
`scripts/dryrun_vegetation_v2_adapter.R`; it is not a build step and is not on
the deploy surface.

Unlike the Phenology registry, this specification is **not effect-blind, because
there is no effect to hide**: `veg_ba_ha` is a per-site context value that enters
no prior, no vote, no site link, no pooled screen, and no sensitivity. The dry run
therefore computed and inspected the candidate values, as the brief asked, so the
owner can see what moves before deciding.

## 0. One-breath summary

The weekly refresh has failed since 2026-08 because the Vegetation Structure
sibling changed its `plots` table from one row per plot to one row per plot and
sampling event, and `cascade_plot_design()` correctly fails closed on the
duplicate `plotID` rows. The fix is not a collapse: each measurement must be
divided by the sampled area of its own event, and events the source holds as
unknown or unsupported must not become denominators. Under that rule, applied to
the current sibling bundle, the Driver's conditional woody-structure value
moves at every one of the 36 sites that keep a value (median absolute change
7.9 percent, maximum 54.4 percent at STEI), four sparse sites lose their value
(CPER, DCFS, NOGP, LAJA, whose every plot-event is `held_opportunity_unknown`
because NEON published no effort fields before 2020), no site flips between
forest and shrubland, WOOD
stays `NA`, and the 46-site roster is unchanged. Nearly all of the movement
comes from the source's support contract (which plots and events count), not
from the area denominators themselves, which differ from the legacy plot table
at only 11 stand plots across 8 sites.

## 1. Scope and boundary

This adapter may change only the vegetation context block of `site_meta`
(`veg_*` fields), the vegetation `data_caveats` strings, the bundle schema
version, the vegetation `product_coverage` row, and the locked WOOD pins in the
handoff. It may not:

- add or remove a site from the 46-site Driver roster (`DRIVER_SITE_SCOPE`);
- touch `annual`, `signals`, `priors`, `suite_links`, `pooled`, `vote_overlap`,
  any climate field, or any effect-producing helper;
- execute, source, or call sibling repository code (it reads committed `.rds`
  bundles only);
- impute an area, treat a held or absent opportunity as zero, or estimate a site
  from an unmatched record plot;
- change the estimand of `veg_ba_ha` (section 4.6) without a separate
  disposition.

The adapter must carry both schemas. The legacy seven-column `plots` table is
still the recorded Driver pin, and a sibling rollback must not break the build:
the adapter detects the schema (section 4.1) and routes to the unchanged legacy
rule or to the v2 rule. It never mixes them inside one site.

## 2. Immutable authorities

| Role | Immutable authority |
|---|---|
| Driver base of this specification (`master`) | `543fee44e3bbb8ba47ece1cde1a199fdae9b4d50` |
| Vegetation legacy pin recorded in the Driver (`source_products`) | `5e73e0dde5cc9cb1936dc0c589475ca23b5ee8df` |
| Legacy pin `data/sites` tree | `74a0662988507aaca861970ab448306ce03fb2d2` |
| Legacy pin `manifest.json` blob | `09207da4cf0578255788aba49ec886992f755da6` |
| Vegetation commit named in the 2026-09-24 handoff (schema already changed) | `53667a17a50f80c80f6b148e8612f698852ee92d` (merged 2026-08-31) |
| Vegetation `main` at specification time | `dc7684c138e174621580061c91c0ba438c021e0a` (merged 2026-10-20, PR #17 "pipeline/refresh-gate-sweep-2026-10") |
| `data/sites` tree at both `53667a1` and `dc7684c` | `8d6e2377e2251df0491419ed4ff5728d81c851bd` (identical) |
| `manifest.json` blob at both `53667a1` and `dc7684c` | `320f2c1db60834818e2b81bb7c1421dbf0c398ba` (identical) |
| Vegetation data/knowledge authorities in `docs/driver-v2-compatibility.csv` | data `d566b30e...`, knowledge `da466ea2...`, audited default head `d2b7ef08...` (now superseded by `dc7684c`) |
| Vegetation origin (the slug `ci.yml` clones) | `github.com/tgilbert14/neon-vegetation-structure-explorer` |

Because the `data/sites` tree is byte-identical at `53667a1` and `dc7684c`, the
two v2 sources in the dry run are the same bytes, and every difference reported
below is between the legacy pin `5e73e0d` and that one tree. The Vegetation
sibling's default branch moved again while this was being written; any
implementation must name an exact commit, never `main`.

The unchanged Driver baseline hashes at `543fee4` are the no-mutation receipt
for this specification:

| Artifact | SHA-256 |
|---|---|
| `data/cascade.rds` | `dababae42a80724ebb91db856965d3546b53e83324ec539dd1868ffe85fdf478` |
| `data/search_index.rds` | `a7aa0d5e08eee79fa6c8f58ab88be6e40090c640fb03f61257c1640b73aca8af` |
| `data/cascade_meta.rds` | `6ed4fd964dd626f57fa17f1fde3098e7073bd9fc94ebc0cecc4f95f8316cf2ec` |
| `data/neon-cascade-codebook.csv` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | `98bad5c426dc1ac687ec3ccb36e68cfbf51939ff400c2db4b6bf7ae2f31489dd` |

## 3. Old and new schemas side by side

Measured on all 42 bundles at each commit (41 in Driver scope; `PUUM` is
excluded by `DRIVER_SITE_SCOPE`; BARR, KONA, OAES, STER and TOOL have no
Vegetation bundle at any commit). Column sets are identical across the 42 sites
at each commit.

### 3.1 `plots`

| | Legacy `5e73e0d` | Current `53667a1` = `dc7684c` |
|---|---|---|
| Grain | one row per `plotID` | one row per `plotID` x `eventID` (plot-event context) |
| Columns | 7 | 62 |
| Rows in Driver scope | 1,641 (one per plot) | 6,114 plot-events across 1,687 plots |
| `plotID` unique | at every site | at 3 of 41 sites only (DCFS, NOGP, WOOD have one event per plot); duplicate at 38 |
| Events per site | n/a | 1 to 11 |
| Plot sets | | changed at DSNY (23 to 41), JERC (40 to 52), OSBS (51 to 53), WOOD (36 to 50; the 14 record-bearing plots gained a context row); unchanged at the other 37 |

The seven legacy columns are all retained with their names: `plotID`,
`plotType`, `nlcdClass`, `lat`, `lng`, `area_trees`, `area_shrub`. The 55 added
columns, grouped by what they carry:

| Group | Added columns |
|---|---|
| Event identity | `eventID`, `date` (Date), `year`, `eventType`, `event_key` |
| Opportunity source linkage | `opportunity_source_uid`, `opportunity_source_record_count`, `opportunity_key_conflict`, `opportunity_source_uids`, `opportunity_source_missing` |
| Published effort | `samplingImpractical`, `dataCollected` |
| Presence (published and normalized) | `treesPresent`, `shrubsPresent`, `treePresence`, `shrubSaplingPresence`, `targetTaxaPresent`, `woodyTargetTaxaPresent`, `nonWoodyTargetTaxaPresent`, `lianasPresent`, `cactiPresent`, `fernsPresent`, `yuccasPresent`, `palmsPresent`, `ocotillosPresent`, `xerophyllumPresent`, `treeFernsPresent` |
| Measurement audit | `measurement_record_count_all`, `measurement_date_min`, `measurement_date_max`, `measurement_date_distinct_n`, `tree_records`, `shrub_records`, `small_tree_records`, `tree_invalid_metric_records`, `shrub_invalid_metric_records`, `tree_identity_conflict_keys`, `shrub_identity_conflict_keys` |
| Support state (the Driver reads these) | `tree_support`, `tree_support_reason`, `shrub_support`, `shrub_support_reason`, `tree_supported`, `shrub_supported` |
| Published sampled areas | `nestedSubplotAreaShrubSapling`, `nestedSubplotAreaLiana`, `nestedSubplotAreaFerns`, `nestedSubplotAreaOther`, `totalSampledAreaTrees`, `totalSampledAreaShrubSapling`, `totalSampledAreaLiana`, `totalSampledAreaFerns`, `totalSampledAreaOther` |
| Other | `nonwoodyCollectDate`, `dataQF` |

`area_trees` and `area_shrub` are now **per event**. Measured across the 1,687
in-scope plots: `area_trees` takes the values 400 and 800 m2 and differs between
events at 47 plots (16 sites); `area_shrub` takes the values 0, 4, 8, 12, 24, 40,
80, 100, 200, 400 and 800 m2 and differs between events at 387 plots (35 sites).
At least one plot has a between-event area difference at 35 of the 41 in-scope
sites (the 2026-09-24 handoff wrote "45 of 46"; that figure cannot be right with
42 bundles and is corrected here).

Support-state vocabulary, with the count of plot-events in Driver scope:

| State | `tree_support` | `shrub_support` | Meaning (sibling contract) |
|---|---:|---:|---|
| `sampled_with_records` | 921 | 1,400 | supported event with channel records |
| `sampled_absence` | 225 | 2 | supported event, explicit plot-scale absence: an observed zero |
| `held_opportunity_unknown` | 3,956 | 3,961 | `samplingImpractical` or `dataCollected` missing or not `allGrowthForms` |
| `held_metric_invalid` | 397 | 23 | one or more eligible live channel rows lack a valid diameter |
| `held_dendrometer_only` | 254 | 254 | `dataCollected = dendrometerOnly` |
| `held_sampling_impractical` | 227 | 227 | `samplingImpractical` not `OK` |
| `held_identity_conflict` | 51 | 159 | stem locator or opportunity key collision |
| `held_opportunity_source_missing` | 49 | 49 | measurement rows with no published `vst_perplotperyear` row |
| `held_presence_record_conflict` | 34 | 39 | presence and records disagree |

The decisive fact for this adapter: **every plot-event dated 2014 to 2019 is
`held_opportunity_unknown`** (3,807 of them), because NEON did not publish
`samplingImpractical` and `dataCollected` for those years (3,790 of the 3,956
tree-channel unknowns have both fields missing). The first supported event at
any site is in 2020. A plot whose last census was in 2019 or earlier has no
supported event and is held.

### 3.2 `trees`

| | Legacy `5e73e0d` | Current `53667a1` = `dc7684c` |
|---|---|---|
| Columns | 21 | 46 (all 21 legacy columns retained by name) |
| Rows in Driver scope | 520,210 | 521,376: identical at 36 sites; changed at CPER (956 to 1,209), DSNY (2,536 to 2,558), HARV (24,792 to 25,395), MOAB (4,223 to 4,228), OSBS (15,492 to 15,775) |
| Individuals in Driver scope | 145,576 | 145,650: identical except CPER (264 to 270), DSNY (1,575 to 1,595), HARV (6,938 to 6,943), OSBS (8,031 to 8,074) |
| Event key | none (date only) | `eventID` on every row; every `plotID` x `eventID` key present in `plots` at every site (0 unmatched keys) |

Added columns: `source_uid`, `protocol_stem_key`, `protocol_key_group_n`,
`protocol_key_conflict`, `eventID`, `tempStemID`, `ninetyCrownDiameter`,
`basalMeasurementHeight`, `tagStatus`, `dendrometerCondition`, `heightQualifier`,
`dataQF`, `plant_key`, `event_key`, `mapping_source_uid`, `mappingCreatedDate`,
`mappingEventID`, `taxonID`, `recordType`, `identificationQualifier`,
`mappingDataQF`, `mappingMatched`, `taxon_label`, `taxon_resolution`,
`opportunity_source_missing`.

The 2026-09-24 handoff's "`trees` kept every old column and the same rows" holds
for the columns and for 36 sites; the five row changes above are a source
refresh that arrived with the same release, and the reason ledger in section 5
names them separately.

### 3.3 Bundle container

Legacy: `trees`, `plots`, `meta`. Current: `trees`, `plots`,
`opportunity_source`, `meta`, `contract`. The adapter reads `trees` and `plots`
only; `contract` may be checked for the sibling contract id
(`NEON-VST-DP1.10098.001-v2`) as an identity assertion, never as a rule source.

## 4. Adapter rule set

### 4.1 Schema detection and fail-closed checks

1. Read `trees` and `plots` with `cascade_bundle_table()`; both must be data
   frames (unchanged).
2. **Schema routing.** If `plots` lacks `eventID`, the table must satisfy the
   legacy contract exactly (`CASCADE_VEG_PLOTS_REQUIRED`, unique `plotID`) and
   the existing rule runs unchanged. If `plots` has `eventID`, the v2 contract
   applies. A table with `eventID` but without the v2 required fields, or a
   legacy table with duplicate `plotID`, is a hard failure, not a fallback.
3. v2 required fields. `plots`: `plotID`, `eventID`, `date`, `area_trees`,
   `area_shrub`, `tree_support`, `tree_support_reason`, `shrub_support`,
   `shrub_support_reason`, `tree_supported`, `shrub_supported`. `trees`: the
   legacy `CASCADE_VEG_TREES_REQUIRED` plus `eventID`.
4. `plotID` x `eventID` must be unique in `plots`; every `trees` key must exist
   in `plots`. A record plot-event with no context row is
   `unsupported-unmatched-plot-events` for the whole site (the v2 form of the
   legacy no-partial-site law). The current source has 0 such keys at every
   site; the check stays because that is exactly the drift that broke the build.
5. The published logical `tree_supported` must equal
   `tree_support %in% c("sampled_with_records", "sampled_absence")` row for row,
   and likewise for the shrub channel. Disagreement is a hard failure: the
   Driver does not re-derive support from the 62 columns, and it does not let
   the two published encodings drift apart silently.
6. The status vocabulary must be a subset of the nine states in section 3.1. An
   unknown state is a hard failure.

### 4.2 Channels (unchanged thresholds, aligned forms)

| Channel | Growth forms | Measurement | Threshold | Event area | Support fields |
|---|---|---|---:|---|---|
| tree (`forest`) | `single bole tree`, `multi-bole tree` | `stemDiameter` | >= 10 cm | `area_trees` | `tree_support`, `tree_supported` |
| shrub (`shrubland`) | `single shrub`, `small shrub`, `sapling` | `basalStemDiameter` | > 0 cm | `area_shrub` | `shrub_support`, `shrub_supported` |

The legacy form sets include `small tree` in both channels. The sibling's
reviewed contract withholds `small tree` from both (it is a nested DBH class
sampled over a different area). The dry run shows the disjoint sets change no
value at any site on the current source (sensitivity B, section 6.4), so the
adapter adopts the disjoint sets as contract alignment at zero present cost. The
basis strings must say so.

### 4.3 Event selection: one supported event per plot per channel

For each channel independently:

1. A plot-event is **selectable** when its published `*_supported` flag is
   `TRUE` and its channel area is finite and positive.
2. Among a plot's selectable events, choose the latest by `date`, then by
   `eventID` (byte order), descending; a missing `date` sorts last. This is the
   sibling's `vst_latest_supported_events()` ordering, re-implemented in the
   Driver.
3. The selected event's area is the only denominator that plot can have in that
   channel. Nothing is borrowed from another event or another plot.
4. A plot with records but no selectable event is a **held plot** in that
   channel. It is counted, its latest event's state is tallied, and it is
   excluded from every numerator and denominator. It is not zero.

The tree channel and the shrub channel may select different events for the same
plot. That is correct: each channel's support is judged per event.

### 4.4 Stems: each measurement divided by the area of its own event

1. Restrict `trees` to rows whose `plotID` x `eventID` is a selected event in
   the channel. Rows from held events, including later held events, never enter.
2. Within those rows apply the existing stem rule unchanged:
   `cascade_tree_snapshot()` keeps the latest-dated row(s) per
   `plotID` x `individualID` inside the selected event, retains tied rows as
   stems, and fails closed on conflicting `scientificName`.
3. `cascade_live_only()` then `cascade_woody_only(spec)` as today.
4. Per plot: `ba_m2 = sum(pi * (d / 200)^2)`; `ba_ha = ba_m2 / (event area /
   10000)`.
5. The legacy area-eligibility floor is unchanged: a plot enters the stand only
   when its selected event area exceeds 50 m2 (`area_ha > 0.005`). The sibling
   retains 40 m2 nested shrub areas; the Driver keeps its floor so the estimand
   does not move for a second reason. This is named in the basis string.

### 4.5 Classification

Unchanged formula, per-event inputs: for each channel, the summed cross-section
over plots with at least one qualifying stem and an eligible area, divided by
the summed eligible area of those plots. `forest` when the tree value is greater
than or equal to the shrub value or both are zero, otherwise `shrubland`. The
stand is then computed in the selected channel only. The dry run shows no
classification flips among the 36 supported sites.

### 4.6 Estimand: the conditional mean is unchanged; sampled absence is counted

`veg_ba_ha` remains the equal-plot mean of per-plot live basal area per hectare
over plots with at least one qualifying live stem at their latest supported
event, with `veg_ba_se = sd / sqrt(n)` and `NA` when `n = 1`. This is the
published estimand and its caveat stays true.

`sampled_absence` events are now observable (139 selected absence plots in the
selected channel across 12 sites on the current source). The adapter persists them
as `veg_v2_sampled_absence_plots` and does **not** put them into the mean,
because an unconditional site mean is a different estimand (sensitivity C in
section 6.4 moves ONAQ, MOAB and KONZ by roughly 90 percent). Whether the Driver
should publish the unconditional mean instead is a separate disposition
(section 9.1, item H2).

### 4.7 Held and unknown-opportunity events: the rule

- A held event is never a denominator and its stems are never a numerator.
- A plot is held in a channel when it has no selectable event; the latest
  event's state is the recorded reason.
- `held_opportunity_unknown` (effort fields unpublished, almost entirely
  2014-2019) is treated exactly like every other held state. The Driver does
  not infer that an older census was complete because it has records; the
  source says the effort is unknown.
- `held_metric_invalid` is also honored as published (one eligible live stem
  without a valid diameter holds the plot-event). This is stricter than the
  legacy rule, which simply dropped the invalid stem. Sensitivity A quantifies
  the difference; whether to relax it is HOLD item H1.
- A site with no selectable event in either channel is
  `unsupported-no-supported-event`: `veg_ba_ha`, `veg_ba_se`, `veg_type` and the
  class values are `NA`, `veg_n_plots` is 0, and the held-state tally names why.
- A site with selectable events but no qualifying stem in the selected channel
  is `supported-no-qualifying-stem` (`NA` value, counts retained). The current
  source produces none.

### 4.8 Several events in one site-year, and why there is no annual series

The brief asked how multiple events in one site-year reduce to "the annual
`veg_ba_ha`". They do not: `veg_ba_ha` is a per-site latest-census standing
stock (`ann_veg()` says so and it is excluded from every annual link because its
roughly five-year remeasurement cadence would manufacture pseudo-resolution).
The reduction is therefore per plot, not per year: the latest selectable event
per plot per channel (section 4.3), whatever year it falls in. Different plots at
one site may contribute different years; the adapter persists the selected-event
year range (`veg_v2_selected_event_year_min/max`) so the mixture is visible. The
current source selects events from 2020 to 2024; two sites draw on a single
year (DSNY 2022, SOAP 2023), the other 34 on two to five years. No annual `veg_*` field is created, and this
specification does not authorize one.

### 4.9 WOOD and the 14 new contexts

At `5e73e0d` WOOD's 14 record-bearing plots had no row in `plots`; the locked
outcome was `unsupported-unmatched-plots` with 14 unmatched plots and 452
unmatched rows. On the current source those 14 plots have context rows, all
`held_opportunity_source_missing` (no published `vst_perplotperyear` row), and
the other 36 WOOD plots are `held_opportunity_unknown` with no records. Under
section 4.3 WOOD has no selectable event in either channel, so its outcome is
`unsupported-no-supported-event` with `veg_ba_ha = NA`, `veg_record_plots = 14`,
`veg_matched_record_plots = 14`, `veg_unmatched_record_plots = 0`, and
`veg_v2_held_state_counts = held_opportunity_source_missing=14`. The value is
unchanged (`NA`); the reason is now machine-readable in the source's own
vocabulary instead of being inferred from a missing join. The locked WOOD pins in
`docs/BUILD-TEST-HANDOFF.md` must be re-expressed in these terms when the adapter
lands; they are not re-expressed by this specification.

### 4.10 Output fields

The 17 legacy fields keep their names. Semantics that change under v2 are named:

| Field | v2 semantics |
|---|---|
| `veg_record_plots` | plots with at least one `trees` row in any event (unchanged) |
| `veg_matched_record_plots` | record plots with at least one context row (always equal to `veg_record_plots` on a conforming v2 bundle) |
| `veg_unmatched_record_plots`, `veg_unmatched_record_rows` | plots/rows whose `plotID` x `eventID` has no context row; 0 on a conforming bundle, and any positive value makes the site `unsupported-unmatched-plot-events` |
| `veg_n_plots` | stand plots: selected channel, selected event, at least one qualifying stem, area > 50 m2 |
| `veg_area_eligible_plots` | selected-channel plots whose selected event area exceeds 50 m2 |
| `veg_design_status` | `supported`, `supported-no-qualifying-stem`, `unsupported-no-supported-event`, `unsupported-unmatched-plot-events`; the legacy path keeps `supported` and `unsupported-unmatched-plots` |
| `veg_stand_basis`, `veg_class_basis`, `veg_design_basis` | new strings naming the per-event denominator, the published-support gate, the disjoint forms, the 50 m2 floor, and the conditional estimand; they are persisted in `site_meta` and `meta$data_caveats`, so the bytes move |

New fields (all persisted, all audit, none votes): `veg_v2_tree_selected_plots`,
`veg_v2_shrub_selected_plots`, `veg_v2_selected_plots`,
`veg_v2_held_record_plots`, `veg_v2_held_state_counts`,
`veg_v2_sampled_absence_plots`, `veg_v2_sampled_absence_eligible_plots`,
`veg_v2_plots_with_later_held_event`, `veg_v2_selected_event_year_min`,
`veg_v2_selected_event_year_max`, `veg_v2_record_plot_events`,
`veg_v2_unmatched_record_plot_events`. On the legacy path they are typed `NA`.

`CASCADE_BUNDLE_SCHEMA_VERSION` must bump. The codebook (`annual` fields only)
and the search index (no `veg_*` field) are unaffected in content; their bytes
move only through the regenerated family.

## 5. Old-versus-new parity plan on the pinned bundle

### 5.1 What must match bit-for-bit

Running the production adapter against the legacy pin `5e73e0d` (schema route:
legacy) must reproduce the committed `site_meta` for all 46 sites and all 17
`veg_*` fields: integer, character and status fields `identical()`; the doubles
`veg_ba_ha`, `veg_ba_se`, `veg_class_tree_ba_ha`, `veg_class_shrub_ba_ha`
`identical()` on the canonical platform and within absolute `1e-12` on the
Windows oracle. The reason the tolerance exists at all is the repository's
existing cross-platform allowance; the legacy route reuses the production
helpers unchanged, so there is no summation-order change to absorb. The dry run
passed this gate on every field (section 6.1).

The `product_coverage` row (`veg_ba_ha`: 40 of 40), the WOOD lock, and the three
basis strings must also reproduce on the legacy route. A new basis string is
allowed only on the v2 route.

### 5.2 What may move on the current source, and what may not

May move, each with a reason from section 5.3: `veg_ba_ha`, `veg_ba_se`,
`veg_type` (only with `type_flipped`), `veg_n_plots`, `veg_area_eligible_plots`,
`veg_class_*`, `veg_design_status`, the basis strings, the `veg_v2_*` fields,
and the `product_coverage` count.

May not move: the 46-site roster; `veg_record_plots` at a site without
`source_trees_changed`; `veg_unmatched_record_plots` (must be 0 at every site
with a bundle); any field outside the vegetation block; any value at BARR, KONA,
OAES, STER or TOOL (no bundle, all `NA`).

Tolerance for "moved": absolute `1e-9` on `veg_ba_ha`. There is no tolerance
for an unexplained move.

### 5.3 Reason ledger

Every site whose vegetation block differs from the committed baseline must carry
one or more reasons from this closed vocabulary; `UNEXPLAINED` is a hard failure.

```text
no_vegetation_bundle          site has no sibling bundle (all NA, unchanged)
source_trees_changed          trees rows or individuals differ from 5e73e0d
source_plots_changed          the set of plotIDs differs from 5e73e0d
event_area_differs            a stand plot's selected-event area differs from its legacy plot-table area
stems_outside_selected_event  legacy-snapshot stems came from events other than the selected one
held_plots_excluded           record plots held in the selected channel
type_flipped                  forest/shrubland classification changed
site_support_changed          veg_design_status changed
no_change                     all 17 fields reproduce
```

On the current source the dry run assigns reasons to all 46 sites with 0
`UNEXPLAINED` (section 6.2). The ledger is a receipt, not an effect table.

### 5.4 Independent oracle and fixtures

`scripts/test_helpers.R` already carries a test-owned vegetation oracle that
calls no production adapter function. The implementation must add a v2 twin
with the same independence (no `cascade_*` vegetation call, no sibling code)
that recomputes from `bundle$trees` and `bundle$plots`: schema route, selectable
events and the latest-event choice, held plots and their state tally, selected
stems, per-plot areas, class values, type, stand mean and SE, sampled-absence
counts, and the status token, for all 41 in-scope bundles; and synthetic
fixtures for at least:

1. one plot, three events, only the middle one supported: the middle event's
   stems and area are used, the later held event's stems are not;
2. the same plot with a later `sampled_with_records` event: the later one wins;
3. two selectable events on the same date: the larger `eventID` wins;
4. a selectable event with missing `date` sorting after any dated event;
5. tree channel supported and shrub channel held in the same event, and the
   reverse;
6. `tree_supported` disagreeing with `tree_support` membership: hard failure;
7. a `trees` key absent from `plots`: whole-site `unsupported-unmatched-plot-events`;
8. a site whose only events are `held_opportunity_unknown`: `unsupported-no-supported-event`, `NA`, counts retained;
9. `sampled_absence` plots counted and excluded from the mean (and included
   under the H2 option if that option is ever adopted);
10. an area of exactly 50 m2 excluded and 50.0001 m2 included;
11. `small tree` rows excluded from both channels;
12. per-event area division: the same stem set with 400 m2 in one event and
    800 m2 in another yields the expected ratio;
13. a legacy seven-column table routed to the unchanged rule and a legacy table
    with duplicate `plotID` failing closed;
14. row-order shuffles leaving every output identical.

### 5.5 Determinism and runtime

Two clean canonical runs (Ubuntu 24.04, R 4.5.2, dated 2026-07-15 snapshot,
Haswell OpenBLAS, one thread) must produce identical `site_meta` vegetation
blocks, identical reason-ledger digests, and C/UTF-8 structural parity. The dry
run in section 6 ran on Windows with R 4.6.1 and dplyr 1.2.1, which is **not**
the canonical runtime; its numbers size the decision and are reproducible by the
committed script, but canonical values come only from CI.

## 6. Per-site impact estimate (local dry run on the current sibling bundle)

Method: `scripts/dryrun_vegetation_v2_adapter.R` on `legacy=5e73e0d`,
`v2=53667a1`, `v2=dc7684c`; outputs are copied to
`docs/receipts/vegetation-v2-adapter-dryrun-2026-10-21.csv` (46 rows, every
number below with its n). Baseline is the committed `site_meta` at `543fee4`.

### 6.1 Harness validation

The legacy route reproduced all 17 committed fields at all 46 sites (`PASS`,
absolute difference at or below `1e-12` on every double). The two v2 sources
gave identical results at every site, as their identical `data/sites` tree
requires.

### 6.2 Headline

| Measure | Value | n |
|---|---:|---|
| Sites with a bundle | 41 | of 46 |
| Finite `veg_ba_ha`, baseline | 40 | of 41 |
| Finite `veg_ba_ha`, v2 primary | 36 | of 41 |
| Sites whose value moved (absolute change > 1e-9) | 36 | of 36 both-finite |
| Moved up / moved down | 21 / 15 | of 36 |
| Median absolute change | 7.9 % | n = 36 |
| 90th percentile absolute change (R type 7) | 36.8 % | n = 36 |
| Maximum absolute change | 54.4 % (STEI, 17.94 to 8.18) | n = 36 |
| Classification flips | 0 | of 36 |
| Sites newly held (`unsupported-no-supported-event`) | 4: CPER, DCFS, NOGP, LAJA | of 40 |
| WOOD | `NA` to `NA`; status token changes | 1 |
| Stand plots, baseline / v2 | 1,169 / 624 | 40 / 36 sites |
| Held record plots in the selected channel | 641 | of 1,438 record plots at 41 sites |
| Stand plots whose event area differs from the legacy plot-table area | 11 | at 8 sites |
| Selected `sampled_absence` plots (selected channel) | 139 | at 12 sites |
| Supported sites at `n = 1` (SE undefined) | 2: KONZ, MOAB | of 36 |
| `UNEXPLAINED` ledger entries | 0 | of 46 |

Sites moving more than 10 percent (v2 minus baseline, percent of baseline):
STEI -54.4, MOAB +50.1, ONAQ +40.1, SOAP -37.8, BONA -35.8, JORN +34.4,
NIWO +30.1, DEJU -28.5, KONZ +25.0, OSBS -20.4, ABBY +18.1, BART +14.4,
RMNP -13.2, WREF +11.1, SRER +11.0, SERC +10.5, ORNL +10.2 (17 sites).

### 6.3 Per-site table

`ba` is `veg_ba_ha` in m2/ha; `n` is `veg_n_plots`; `held` is held record
plots in the selected channel; `abs` is selected sampled-absence plots; `yrs`
is the selected-event year range. Reasons use the section 5.3 vocabulary
(`S` = `source_trees_changed` or `source_plots_changed`, `A` =
`event_area_differs`, `E` = `stems_outside_selected_event`, `H` =
`held_plots_excluded`, `T` = `site_support_changed`).

| Site | Base ba | Base type | Base n | v2 ba | v2 type | v2 n | Change % | held | abs | yrs | v2 status | Reasons |
|---|---:|---|---:|---:|---|---:|---:|---:|---:|---|---|---|
| ABBY | 26.24 | forest | 31 | 30.98 | forest | 22 | +18.1 | 12 | 0 | 2021-2024 | supported | A E H |
| BARR | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | no bundle | no_vegetation_bundle |
| BART | 41.30 | forest | 41 | 47.25 | forest | 24 | +14.4 | 17 | 0 | 2020-2024 | supported | A E H |
| BLAN | 15.85 | forest | 21 | 16.95 | forest | 19 | +6.9 | 3 | 1 | 2021-2024 | supported | E H |
| BONA | 14.01 | forest | 36 | 9.00 | forest | 17 | -35.8 | 19 | 2 | 2020-2024 | supported | E H |
| CLBJ | 14.12 | forest | 41 | 12.94 | forest | 14 | -8.4 | 30 | 3 | 2020-2024 | supported | E H |
| CPER | 0.41 | shrubland | 13 | NA | NA | 0 | NA | 13 | 0 | NA | unsupported-no-supported-event | S H T |
| DCFS | 0.17 | shrubland | 11 | NA | NA | 0 | NA | 11 | 0 | NA | unsupported-no-supported-event | H T |
| DEJU | 5.59 | forest | 32 | 4.00 | forest | 13 | -28.5 | 25 | 0 | 2020-2024 | supported | E H |
| DELA | 28.00 | forest | 41 | 27.95 | forest | 30 | -0.2 | 11 | 0 | 2021-2024 | supported | E H |
| DSNY | 5.34 | forest | 12 | 5.60 | forest | 6 | +4.9 | 14 | 4 | 2022-2022 | supported | S E H |
| GRSM | 38.05 | forest | 40 | 40.87 | forest | 26 | +7.4 | 14 | 0 | 2021-2024 | supported | E H |
| GUAN | 17.05 | shrubland | 18 | 17.81 | shrubland | 16 | +4.5 | 3 | 0 | 2022-2024 | supported | A E H |
| HARV | 32.94 | forest | 42 | 35.24 | forest | 29 | +7.0 | 13 | 0 | 2020-2024 | supported | S E H |
| HEAL | 2.67 | forest | 14 | 2.52 | forest | 13 | -5.6 | 5 | 33 | 2020-2024 | supported | E H |
| JERC | 11.98 | forest | 29 | 11.18 | forest | 9 | -6.7 | 22 | 0 | 2022-2024 | supported | S E H |
| JORN | 0.37 | shrubland | 50 | 0.49 | shrubland | 23 | +34.4 | 27 | 0 | 2021-2023 | supported | E H |
| KONA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | no bundle | no_vegetation_bundle |
| KONZ | 7.24 | forest | 6 | 9.06 | forest | 1 | +25.0 | 25 | 7 | 2020-2024 | supported | E H |
| LAJA | 3.90 | forest | 4 | NA | NA | 0 | NA | 4 | 0 | NA | unsupported-no-supported-event | E H T |
| LENO | 35.41 | forest | 31 | 36.09 | forest | 20 | +1.9 | 11 | 0 | 2021-2024 | supported | A E H |
| MLBS | 28.07 | forest | 36 | 28.66 | forest | 22 | +2.1 | 14 | 0 | 2022-2024 | supported | E H |
| MOAB | 11.50 | forest | 3 | 17.25 | forest | 1 | +50.1 | 18 | 23 | 2021-2023 | supported | S E H |
| NIWO | 31.14 | forest | 25 | 40.52 | forest | 6 | +30.1 | 22 | 13 | 2022-2024 | supported | E H |
| NOGP | 0.06 | shrubland | 8 | NA | NA | 0 | NA | 8 | 0 | NA | unsupported-no-supported-event | H T |
| OAES | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | no bundle | no_vegetation_bundle |
| ONAQ | 12.92 | forest | 6 | 18.10 | forest | 3 | +40.1 | 6 | 38 | 2022-2024 | supported | E H |
| ORNL | 29.60 | forest | 36 | 32.61 | forest | 13 | +10.2 | 27 | 0 | 2021-2024 | supported | A E H |
| OSBS | 11.69 | forest | 42 | 9.30 | forest | 19 | -20.4 | 23 | 0 | 2023-2024 | supported | S E H |
| RMNP | 25.07 | forest | 29 | 21.77 | forest | 17 | -13.2 | 12 | 0 | 2020-2024 | supported | E H |
| SCBI | 27.73 | forest | 39 | 27.81 | forest | 34 | +0.3 | 5 | 0 | 2020-2024 | supported | E H |
| SERC | 37.25 | forest | 39 | 41.17 | forest | 17 | +10.5 | 22 | 0 | 2022-2024 | supported | E H |
| SJER | 7.46 | forest | 28 | 7.42 | forest | 13 | -0.5 | 20 | 3 | 2022-2024 | supported | A E H |
| SOAP | 23.41 | forest | 36 | 14.56 | forest | 13 | -37.8 | 20 | 0 | 2023-2023 | supported | E H |
| SRER | 5.09 | shrubland | 38 | 5.65 | shrubland | 17 | +11.0 | 21 | 0 | 2021-2024 | supported | A E H |
| STEI | 17.94 | forest | 37 | 8.18 | forest | 5 | -54.4 | 32 | 0 | 2021-2023 | supported | E H |
| STER | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | no bundle | no_vegetation_bundle |
| TALL | 24.45 | forest | 41 | 24.36 | forest | 33 | -0.4 | 8 | 0 | 2020-2024 | supported | A E H |
| TEAK | 50.80 | forest | 38 | 50.00 | forest | 21 | -1.6 | 18 | 1 | 2022-2024 | supported | E H |
| TOOL | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | no bundle | no_vegetation_bundle |
| TREE | 19.69 | forest | 42 | 19.68 | forest | 19 | -0.1 | 23 | 0 | 2020-2024 | supported | E H |
| UKFS | 25.24 | forest | 37 | 25.02 | forest | 29 | -0.9 | 9 | 0 | 2021-2024 | supported | E H |
| UNDE | 27.42 | forest | 31 | 28.25 | forest | 17 | +3.0 | 14 | 0 | 2020-2024 | supported | E H |
| WOOD | NA | NA | 0 | NA | NA | 0 | NA | 14 | 0 | NA | unsupported-no-supported-event | S H T |
| WREF | 56.27 | forest | 39 | 62.50 | forest | 19 | +11.1 | 20 | 0 | 2020-2024 | supported | E H |
| YELL | 16.86 | forest | 26 | 17.04 | forest | 24 | +1.1 | 6 | 11 | 2021-2024 | supported | E H |

Held-state tallies for the held record plots (selected channel) are in the
receipt column `v2_held_state_counts`. Across the 36 supported sites the
largest single held reason is `held_metric_invalid` at 15 sites (for example
BART 12, MLBS 12, ORNL 11, RMNP 11, UNDE 11, HARV 10, NIWO 10),
`held_opportunity_unknown` at 7 (KONZ 25, CLBJ 19, SOAP 18, OSBS 16, MOAB 13,
SERC 12, HEAL 3), `held_sampling_impractical` at 7 (JORN 25, TREE 16, STEI 10,
DEJU 9, UKFS 9, DSNY 8, SJER 7), a tie between those two at JERC (10 each),
`held_dendrometer_only` at 3 (TEAK 15, WREF 8, BONA 7),
`held_identity_conflict` at 2 (SRER 21, GUAN 2) and
`held_presence_record_conflict` at 1 (YELL 3).

### 6.4 Sensitivities (each versus the primary rule, current source)

| Sensitivity | What changes | Sites moved | Largest moves (v2 primary to alternative; n plots) |
|---|---|---:|---|
| A: treat `held_metric_invalid` as supported, drop only the invalid stems (the legacy behaviour) | plot-events with one unmeasurable live stem re-enter | 28 of 36 | STEI 8.18 to 17.49 (+114 %; 5 to 17), DEJU 4.00 to 6.02 (+51 %; 13 to 16), MOAB 17.25 to 11.50 (-33 %; 1 to 3), BONA 9.00 to 11.70 (+30 %; 17 to 25), ONAQ 18.10 to 12.92 (-29 %; 3 to 6), NIWO 40.52 to 34.96 (-14 %; 6 to 16), WREF 62.50 to 54.25 (-13 %; 19 to 29); 21 other sites within 15 % |
| B: disjoint growth forms (`small tree` out of both channels) | form sets | 0 of 36 | none; no classification flips |
| C: `sampled_absence` plots enter the mean as zeros (unconditional site mean) | estimand | 12 of 36 | MOAB 17.25 to 0.72 (-96 %; 1 to 24), ONAQ 18.10 to 1.33 (-93 %; 3 to 41), KONZ 9.06 to 1.13 (-88 %; 1 to 8), HEAL 2.52 to 0.71 (-72 %; 13 to 46), NIWO 40.52 to 12.80 (-68 %; 6 to 19), DSNY 5.60 to 3.36 (-40 %; 6 to 10), YELL 17.04 to 11.69 (-31 %; 24 to 35), CLBJ -18 %, SJER -19 %, BONA -11 %, BLAN -5 %, TEAK -5 % |

Source decomposition: primary v2 on `53667a1` versus on `dc7684c` moves 0
sites (identical tree). Every change in section 6.3 is the rule, applied to the
one current tree; the five `source_trees_changed` sites moved for the same
reasons as the others, not because of their extra rows.

### 6.5 What the numbers say

- The per-event **area** correction, the thing the 2026-09-24 entry named, is
  real but small at the stand level: 11 stand plots at 8 sites use a different
  denominator than the legacy plot table.
- The **support gate** is the thing that moves values: the legacy snapshot
  used every individual's latest measurement regardless of whether its event
  had known effort or area; 641 of 1,438 record plots have no supported event in
  the selected channel, and most of the discarded stems sit in events the
  source now holds. That is the denominator-integrity gate the sibling's
  knowledge package asked the Driver to honour.
- The four sites that lose a value are sparse shrub and grassland sites whose
  last censuses predate 2020 (and LAJA, 4 plots). Their legacy values were
  small (0.06 to 3.90 m2/ha). `NA` with `held_opportunity_unknown=n` is the
  honest state; it is not "no woody stand".
- Two supported sites rest on one plot (KONZ, MOAB) and one on three (ONAQ);
  their SE is undefined or thin, and `veg_n_plots` says so.

## 7. Integration consequences (for the implementation PR, not this one)

- `R/source_adapters.R` gains the v2 route and fields; `scripts/build_cascade.R`
  `ann_veg()` routes by schema; `R/cascade_helpers.R` bumps
  `CASCADE_BUNDLE_SCHEMA_VERSION`; `scripts/test_helpers.R` gains the v2 oracle
  and fixtures; the `veg_*` `data_caveats` strings change. All of these are
  byte-gated inputs, so the canonical family must be regenerated by
  `regenerate-artifacts.yml` and re-registered across the eight hash registries
  and the spec chain, exactly as the 2026-09-24 and 2026-10-20 entries describe.
- `server.R` tests `identical(status, "unsupported-unmatched-plots")` to render
  the withheld banner and otherwise renders nothing when the value is `NA`. With
  the new status tokens the four newly held sites and WOOD would show no
  vegetation line at all until `server.R` learns the tokens, and its About text
  ("the source cannot distinguish sampled-zero from unsampled plots") becomes
  false because `sampled_absence` is now observable. `server.R`, `ui.R`,
  `ci.yml` and `refresh-data.yml` are touched by the open PRs #75, #76 and #77,
  so the adapter PR must be sequenced after them and must not touch them.
- The locked WOOD pins in the handoff are re-expressed per section 4.9.
- `product_coverage` for `veg_ba_ha` moves from 40 of 40 to 36 of 36.
- After the adapter lands, dispatch `regenerate-artifacts.yml` with
  `siblings=current` to find any fourth drift before publication (the
  2026-09-24 next action, unchanged).
- The HOLD alternative is not free: the refresh stays red until either this
  adapter lands or `refresh-data.yml` pins Vegetation at `5e73e0d` per sibling
  while the other six refresh. That workflow change belongs to the owner and to
  PRs #75/#76, not to this specification.

## 8. Hard failures and abstentions

Hard failures (stop, no vegetation block, no family): a bundle that is neither
legacy nor v2 conforming; duplicate `plotID` x `eventID`; `*_supported`
disagreeing with `*_support`; an unknown status token; a selectable event
without positive finite area; a qualifying stem whose plot has no selected
event; conflicting `scientificName` inside a selected event; any
`UNEXPLAINED` reason-ledger entry; legacy-route parity failure on `5e73e0d`.

Declared abstentions (typed `NA` with counts, never zero): a site with no
bundle; `unsupported-no-supported-event`; `supported-no-qualifying-stem`;
`unsupported-unmatched-plot-events`; `veg_ba_se` at `n = 1`.

## 9. Recommended disposition and sign-off

### 9.1 `cass`: ADOPT the adapter, HOLD two estimand questions

**Recommend `ADOPT`** for the adapter as specified in section 4 (per-event
denominators, published-support gate, held-event rule, disjoint forms,
unchanged conditional estimand, WOOD re-expression, full audit fields), and for
regenerating the family from an exact current Vegetation commit under it.

The honest reason: the legacy values were not wrong so much as unprovable. They
divided every individual's latest measurement by whatever area the collapsed
plot table carried, including 3,807 pre-2020 plot-events whose effort NEON never
published and 397 tree plot-events the source now holds as unmeasurable. The v2
values are smaller in n and different in level at every site, but each one is a
ratio whose numerator and denominator come from the same sampled event with a
published support state, and every exclusion is counted in the source's own
vocabulary. For a context-only value with no vote, no prior and no climate link,
a provable denominator is worth more than continuity of level, and the caveat
goes on the number: `veg_n_plots`, the held tally and the year range ride with
it. The 46-site roster is untouched; four sites become honest `NA` context.

`ADOPT` means the owner accepts section 6.3 as the expected post-adoption table
(declared before the canonical rebuild, as the reintegration gate requires) and
accepts that the five canonical artifacts, the eight registries and the spec
chain move.

**Recommend `HOLD`** on two questions that this adapter deliberately does not
decide, each with its numbers in section 6.4:

- **H1: `held_metric_invalid`.** The sibling withholds a plot-event when one
  eligible live stem lacks a valid diameter; the legacy Driver dropped the stem
  and kept the plot. Honouring the source (primary) is the defensible default
  because the Driver should not reinterpret a reviewed hold; relaxing it
  (sensitivity A) would change 28 sites, STEI by +114 percent. Decide separately.
- **H2: the unconditional site mean.** `sampled_absence` plots are now
  observable zeros. Putting them into the mean (sensitivity C) is the better
  estimate of standing stock per sampled hectare, but it is a different
  estimand from the one published and it moves ONAQ, MOAB and KONZ by about 90
  percent. Decide separately; if adopted, rename the field rather than redefine
  `veg_ba_ha` in place.

`CONTEXT` and `REJECT` were considered. `CONTEXT` is already the standing of
`veg_ba_ha` and does not unblock the build. `REJECT` would mean keeping the
Driver on the legacy pin indefinitely, which requires a per-sibling pin in the
refresh workflow and leaves the suite consuming a Vegetation release its own
knowledge package has superseded.

### 9.2 `hk`: statistics sign-off notes

1. **Estimator unchanged, support changed.** `veg_ba_ha` is an equal-plot mean
   of per-plot ratios; `veg_ba_se = sd / sqrt(n)`. No test, no model, no
   multiplicity family, no vote and no prior touches it; `vote_overlap`,
   `pooled` and `signals` are untouched by construction. The adapter changes
   which plots and events are eligible, not the arithmetic. Signed off.
2. **n is persisted and it shrinks** (1,169 to 624 stand plots). KONZ and MOAB
   at `n = 1` have undefined SE; ONAQ at `n = 3` and STEI at `n = 5` are thin.
   No new minimum-n threshold is introduced, because the legacy rule had none
   (MOAB was already at 3) and inventing one now would be a second disposition;
   the UI should show n beside the value, which it already does.
3. **The conditional estimand's caveat stays true** under v2, but the
   `server.R` sentence that the source cannot distinguish sampled zeros from
   unsampled plots is now false and must be re-worded when the adapter lands.
   The unconditional mean (H2) is the better site-level stock estimand; it
   should not be smuggled in by redefining the field.
4. **Classification is robust**: 0 flips among 36 supported sites under the
   primary rule and under all three sensitivities.
5. **Zero is never imputed**; held plots are counted, not zeroed; the four newly
   held sites are `NA` with a reason. Signed off.
6. **Reproducibility caveat.** The dry run ran on Windows R 4.6.1 / dplyr 1.2.1,
   not the canonical Ubuntu R 4.5.2 runtime. The legacy route reproduced the
   committed doubles within `1e-12`, which is the repository's existing
   cross-platform allowance, so the sized impact is trustworthy for a decision;
   canonical post-adoption values come only from CI.
7. **Corrected record.** "Areas differ between events at 45 of 46 sites" is
   restated as measured: 35 of 41 in-scope sites have at least one plot whose
   channel area differs between events, and the stand-level effect of the area
   correction alone is 11 plots at 8 sites. The movement in section 6 is a
   support story, and the specification says so.

### 9.3 What the owner must decide

1. `ADOPT` or `HOLD` the adapter as specified (section 4), with section 6.3 as
   the declared expectation.
2. Accept the four newly held sites and the roster unchanged at 46.
3. H1 and H2 (section 9.1), each `ADOPT` / `HOLD` / `REJECT`.
4. Sequencing: the implementation PR after #75, #76 and #77; the `server.R`
   status tokens and About text in the same or a following PR; then
   `regenerate-artifacts.yml` with `siblings=current`.

## 10. Owner disposition record

```text
Date:
Adapter (section 4):            ADOPT / HOLD / REJECT
Expected table (section 6.3):   ACCEPTED / AMENDED (say how)
H1 held_metric_invalid:         ADOPT primary (honour hold) / ADOPT A (relax) / HOLD
H2 unconditional mean:          ADOPT (new field name: ______) / HOLD / REJECT
Authority commit:
```

Until this record is filled and merged, the Driver's vegetation block, pins,
workflows, artifacts and manifest remain exactly as they are.
