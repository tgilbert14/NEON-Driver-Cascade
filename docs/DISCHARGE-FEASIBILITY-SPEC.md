# Continuous Discharge feasibility acquisition specification

Specification state: **GATE F0 CANDIDATE FROZEN FOR REVIEW / NOT YET PASSED OR
PUBLISHED**

Specification date: 2026-08-05 MST

Program disposition: **STAGED EVIDENCE ONLY / CURRENT AUTHORITY STOPS AT F0
CANDIDATE / F1 UNAUTHORIZED / DEFER BUILD / NO DRIVER BYTE CHANGE**

This document freezes the source, schema, QC, clock, key, output, and decision
contract for measuring the exact Continuous Discharge `DP4.00130.001` x My
Little Inverts support intersection. It is written before an authenticated
file-manifest request, before a discharge payload is fetched, and before any
discharge value is inspected. It implements the pass-10 authorization in
[`COMPLEMENTARY-APP-GAP-AUDIT.md`](COMPLEMENTARY-APP-GAP-AUDIT.md); it does not
authorize an application, an annual-flow estimator, an ecological effect, a
prior, a vote, or a generated Driver artifact.

The candidate becomes F0 authority only after its exact head passes review and
CI, is merged to the default branch, is published through Pages, and those exact
identities are recorded in a follow-up receipt. Until that receipt is merged and
Pages-verified, F0 has not passed and F1 is not authorized.

Passing the eventual feasibility gate means only that the candidate has enough
measured common calendar support to **reopen independent review**. It does not
authorize a build and does not establish that the discharge record is complete
enough for an annual hydrologic estimand.

## 1. Scope and no-look boundary

The staged feasibility sequence may answer only these questions:

1. Does the immutable `RELEASE-2026` identity still resolve exactly?
2. Does an authenticated expanded-package file manifest expose the preregistered
   tables and metadata for the exact response-side site roster?
3. Do the downloaded tables satisfy the frozen schema and QC contracts without
   fallback or repair?
4. For every exact Inverts stream `siteID x UTC calendar year`, is a matching
   discharge site-year present, and is at least one table-appropriate finite,
   QC-passing discharge record present?
5. Do at least three unambiguous exact stream sites each have at least six common
   primary years?

The sequence must not:

- build or prototype a Continuous Discharge app;
- implement or call `ann_flow()`, an adapter intended for Driver ingestion, an
  effect function, a pooling function, or another ecological estimator;
- calculate, print, retain, rank, plot, or summarize a discharge magnitude,
  minimum, maximum, mean, median, quantile, anomaly, trend, correlation,
  coefficient, direction, p-value, or effect-like quantity;
- fetch, read, or deserialize any Inverts RDS blob; the committed two-column
  response ledger is the only permitted response-side data input;
- inspect an Inverts density value, composition value, taxon value, or other
  ecological response value;
- add or change a prior, expected class, vote, Driver row, manifest entry, or
  published artifact;
- use a domain-year proxy, coordinates, fuzzy site name, site proximity, or an
  inferred terrestrial-aquatic crosswalk as an eligible join;
- change a table, field, flag rule, clock, site rule, threshold, or sensitivity
  after seeing payload contents; or
- use a sensitivity result to rescue a failed primary gate.

Only schema identities, exact keys and permitted location identity, binary
support states, aggregate support counts, total exclusion-reason receipts,
opaque digests, and a final gate disposition may leave the isolated acquisition
process.

## 2. Immutable authorities

### 2.1 Continuous Discharge release authority

Every stage must assert all of these values. A current product page, a moving
`current` selector, provisional data, or an equivalent-looking package is not an
authority.

| Field | Frozen authority |
|---|---|
| Product | `DP4.00130.001` — Continuous discharge |
| Package | `expanded` |
| Release | `RELEASE-2026` |
| Release UUID | `c28725ff-5aa2-41fa-845e-a7f1c8239d09` |
| Release generation | `2026-01-23T00:07:49Z` |
| Release date | `2026-01-23` |
| Product DOI | `https://doi.org/10.48443/4n6c-gc44` |
| Availability-manifest artifact | `manifest-available-20260123T000738Z.json` |
| Availability-manifest size | `2779477` bytes |
| Availability-manifest MD5 | `33c04c0f24dba030d3082acf704e2c56` |

These identities came from the official
[`RELEASE-2026` API record](https://data.neonscience.org/api/v0/releases/RELEASE-2026)
and the release-filtered
[`DP4.00130.001` product record](https://data.neonscience.org/api/v0/products/DP4.00130.001?release=RELEASE-2026),
observed on 2026-08-05. Temporary signed URLs returned by an API are capabilities,
not authorities, and must never be recorded.

`RELEASE-2026` excludes Continuous Discharge at all sites for 2024-10 through
2025-06 because discharge-related products are released by water year. The
release inventory therefore ends at 2024-09 for this product. File availability
outside that boundary is provisional or belongs to another release and is
forbidden.

### 2.2 Response authority and committed no-look ledger

The response-side authority is the released My Little Inverts science/runtime
merge:

```text
ff23e994e289982c747b91e48c5ff0907c1672d2
```

The exact upstream Git identities and the Driver-owned values-free ledger are:

| Object | Git object | SHA-256 where applicable |
|---|---|---|
| Root tree | `b09c9b54aa5b81290ab6a2dc98072421eae66b03` | — |
| `data` tree | `812be54ac172fe2febaa5a192f90070e87e3fbf0` | — |
| `data/sites` tree | `080534caad4eb76cdaf0b5a56704ed4e890ed16a` | — |
| [`docs/receipts/discharge-inverts-response-site-years.tsv`](receipts/discharge-inverts-response-site-years.tsv) | `c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8` | `79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296` |

The published handoff additionally binds that family to bundle-family SHA-256
`cbc3fa29a0a1b5ca2577310eab71170a9aa0bc587880282412322605587496c9`,
runtime-payload SHA-256
`87900f675a1ef34d4f5c47c6788fbaac08a8549d82c4ef900a1b28726e925278`,
and release ID
`sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5`.

The committed TSV did not pre-exist in the Inverts repository. It freezes the
already-completed pass-10/manual projection from the exact `ff23e994...` commit
and `080534ca...` `data/sites` tree. That earlier one-time derivation necessarily
deserialized the monolithic exact Inverts site bundles because the opportunity
ledger lived inside them. It selected only `siteID`, `collectDate`,
`aquaticSiteType`, and `density_eligible`, and it never indexed, aggregated, or
logged density, count, taxonomy, or other outcome fields. That historical
derivation is provenance, not an authorized F0, F1, or F2 operation.

From F0 forward, the committed TSV is the response-side no-look boundary. F0,
F1, F2, and their CI may verify only the upstream commit/root/`data/sites` tree
metadata and the committed ledger's exact Git-blob and SHA-256 bytes. They must
never fetch, read, or deserialize an Inverts RDS blob. Before the ledger is used,
it must reproduce exactly:

- 210 density-eligible stream `siteID x calendar year` rows;
- 24 exact stream sites; and
- 23 of those sites with at least six density-eligible response years.

This `210 x 24 x 23` assertion is a response-authority integrity rule, not the
discharge-intersection result. The permitted committed response ledger contains
only `siteID` and integer `utc_calendar_year`; inclusion already means
density-eligible stream opportunity under the recorded prior projection. It must
not expose an Inverts density, sample count, area, taxon, composition, event
metric, or other response value.

Any pure response-projector test must also emit a total two-column receipt
`state, n_rows` with all five stable states—even when a count is zero:
`eligible_stream`, `density_eligibility_missing`, `density_ineligible`,
`aquatic_site_type_missing`, and `non_stream_aquatic_site_type`. In F0 those
projector tests use synthetic fixtures only; they do not recreate the authority
ledger from upstream bundles.

### 2.3 Unchanged Driver byte authority

This feasibility sequence has no generated-artifact writer. Before and after
each gate, these five files must retain the exact current hashes:

| Artifact | SHA-256 |
|---|---|
| `data/cascade.rds` | `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe` |
| `data/search_index.rds` | `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e` |
| `data/cascade_meta.rds` | `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de` |
| `data/neon-cascade-codebook.csv` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79` |

Any change is a hard failure and is outside this specification.

## 3. Frozen source schema

### 3.1 Main table split

The expanded release has two main-table regimes. Both are required because the
historical conversion is incomplete.

| Regime | Table | Time field | Discharge field | QC fields |
|---|---|---|---|---|
| Corrected 15-minute | `csd_15_min` | `endDateTime` | `dischargeContinuous` | `dischargeFinalQF`, `dischargeFinalQFSciRvw`, `dischargeCorrectionApplied` |
| Historical uncorrected 1-minute | `csd_continuousDischarge` | `endDate` | `maxpostDischarge` | `dischargeFinalQF`, `dischargeFinalQFSciRvw` |

Beginning with water year 2022 at `2021-10-01`, records were corrected,
converted to 15-minute resolution, and published in `csd_15_min`. BIGC water
year 2021 was also converted. For most sites, earlier records remain uncorrected
at 1-minute resolution in `csd_continuousDischarge`; official NEON guidance is
to use `maxpostDischarge` for those historical periods.

The release contract states that no time period at a site is published in both
main tables. After exact time parsing, any apparent overlap is a hard failure
rather than an invitation to choose one row by order. Because the cutovers below
are exact and nonoverlapping, a cross-table overlap necessarily violates source
chronology and fails first as `source_regime_chronology_mismatch`; the internal
period-overlap assertion is defense in depth, not a separately reachable public
failure under this frozen chronology.

The table chronology is also exact. The ordinary site cutover is
`2021-10-01T00:00:00Z`; BIGC alone uses `2020-10-01T00:00:00Z`. A corrected
`csd_15_min` row must be at or after its site's cutover, and a historical
`csd_continuousDischarge` row must be strictly before it. The invariant is
evaluated before QC or support reduction. Any violation fails the whole family
as `source_regime_chronology_mismatch`; no payload-driven exception or table
fallback is allowed.

### 3.2 Location and time keys

Each source record must retain these nonblank identity fields when the variables
metadata declares them for its table:

```text
siteID, namedLocation
```

The raw uniqueness keys are:

```text
csd_15_min: siteID x namedLocation x endDateTime
csd_continuousDischarge: siteID x namedLocation x endDate
```

Duplicate keys, conflicting duplicate records, an unparseable time, a time
without an explicit documented UTC interpretation, or a site/location identity
that changes after normalization are hard failures. Source order must not settle
a conflict.

`endDateTime` and `endDate` are parsed as UTC instants. The primary `year` is the
four-digit UTC calendar year of the applicable end time. No local-time,
publication-month, download-month, file-name, or water-year fallback may replace
that clock.

TOOK has separately measured lake inflow and outflow locations, so `siteID` alone
is not a safe raw key. TOOK is excluded from the primary gate pending an
independently registered `namedLocation` crosswalk. This exclusion cannot be
reversed because its result would improve support.

### 3.3 TOMB special table

TOMB is published separately in `csd_continuousDischargeUSGS`, approximately
hourly, from USGS data. It has `usgsValueQualCode`, uses a different uncertainty
path, and receives no NEON cleaning or gap-filling. TOMB is excluded from the
primary gate pending its own separately reviewed QC and key contract. The main
table predicate must never be applied to it by field-name analogy. TOMB must be
identified and rejected before main-table schema projection or QC evaluation;
if a TOMB row reaches either main-table projector, the family fails as
`tomb_requires_separate_contract` and emits no support result for that row.

### 3.4 Exact QC predicate

For each main-table record, normalize only the storage representation explicitly
declared by the exact `variables_00130` metadata. No semantic coercion is
allowed. Numeric/integer `0` is not interchangeable with arbitrary strings,
logical values, blanks, or sentinel values unless the variables file explicitly
declares that representation.

A `csd_15_min` record is primary-QC-passing if and only if all of these are true:

1. `dischargeContinuous` is numeric and finite;
2. `dischargeFinalQF` is exactly `0`;
3. `dischargeFinalQFSciRvw` is exactly `0` or missing; and
4. `dischargeCorrectionApplied` is exactly `0` or `1`.

A `csd_continuousDischarge` record is primary-QC-passing if and only if all of
these are true:

1. `maxpostDischarge` is numeric and finite;
2. `dischargeFinalQF` is exactly `0`; and
3. `dischargeFinalQFSciRvw` is exactly `0` or missing.

`dischargeCorrectionApplied = 0` means the record was reviewed and no correction
was required. `1` means it was reviewed and a gap-filling method was applied.
Both are correction-reviewed states. Missing means unreviewed and does not pass.
A reviewed gap that could not be filled is published with
`dischargeContinuous = NA`; the finite-value rule excludes it without treating
all corrected records as bad.

Any undocumented class, duplicate column name, missing required field, unexpected
flag token, nonfinite key, or malformed rectangular table fails the whole source
family. The runner must not rename a near-match field, substitute a component
flag, drop a malformed file, or relax the predicate.

### 3.5 Active, inactive, missing, and zero

NEON documents one record per expected cadence during an active period even when
the pressure transducer produces no usable measurement. Such a record contains
its timestamp, flags, and metadata but no stage or discharge value. When a sensor
is intentionally inactive or removed at a seasonal site, records are not
processed or published.

The frozen interpretation is therefore:

| Source state | Feasibility meaning |
|---|---|
| Row present and primary-QC-passing | passing record present |
| Row present with missing discharge | active opportunity without a usable discharge record |
| Row present with failed or unreviewed QC | active opportunity that does not pass |
| No row | inactive, unpublished, or otherwise absent; never a zero |
| Finite, QC-passing value equal to zero | observed finite zero; passes the binary-presence rule |

No missing, flagged, inactive, or absent state may be converted to zero. No
finite zero may be discarded merely because it is zero. The runner may test only
finiteness and exact equality needed by the QC flags; it must not export or use
the sign or magnitude of the discharge value.

The presence rule is intentionally minimal. It does not claim full-year
coverage, complete active-period coverage, a continuous hydrograph, or a valid
annual-flow metric.

## 4. Primary support and join contract

### 4.1 Discharge site-year state

The final primary ledger is left-anchored to all 210 exact rows in the committed
response ledger. It contains exactly these fields:

```text
siteID
utc_calendar_year
discharge_site_year_present
qc_pass_record_present_in_utc_year
source_regime
```

`discharge_site_year_present` is `TRUE` when a discharge site-year exists for the
exact response key, regardless of whether a record passes QC.
`qc_pass_record_present_in_utc_year` is `TRUE` if and only if at least one record
in either main table satisfies that table's exact primary QC predicate and its
UTC end-time year equals the response year. It is otherwise `FALSE`.

Every response key remains in the ledger, including keys with no matching
discharge site-year and keys whose matching rows all fail the frozen predicate.
The reducer must never implement an inner-join-only receipt. Exclusion receipts
are total: every stable response-projection state and every registered special-
site reason is emitted with its integer count, including zero counts.

Every QC-pass `TRUE` row also receives exactly one source-regime label:

| Label | Meaning |
|---|---|
| `corrected_15_min_only` | passing support only from `csd_15_min` |
| `historical_uncorrected_1_min_only` | passing support only from `csd_continuousDischarge` |
| `mixed_corrected_and_historical` | both regimes have a passing record in that UTC calendar year |

Historical uncorrected records are allowed to satisfy the primary binary, as
directed by the frozen decision, but their regime must remain visible in every
site-year and aggregate receipt. A calendar year spanning the October 2021 table
transition may legitimately be labeled mixed. It must not be represented as an
all-corrected year.

### 4.2 Exact response join

A primary common year exists only when:

```text
exact Inverts siteID
x exact Inverts integer calendar year
x qc_pass_record_present_in_utc_year = TRUE
```

Inclusion in the committed response ledger already proves the density-eligible
stream predicate. The join is literal equality on the four-character `siteID`
and integer `utc_calendar_year` from that exact authority. Before joining,
require nonmissing, unique keys on both values-free panels. A duplicate,
ambiguous site identity, or roster mismatch is a hard family failure with no
partial support receipt. A TOMB row reaching either ordinary main-table
projector is likewise a pre-schema hard failure. TOOK is the registered primary-
gate exclusion, while TOMB and TOOK both retain explicit zero-inclusive rows in
the total special-site exclusion receipt. Neither special-site exclusion may
delete any ordinary response-anchored `FALSE` row.

The authority assertion compares the exact sorted set of all 210
`(siteID, utc_calendar_year)` keys, not counts alone.

Coordinates, NEON domain, hydrologic basin, site-name similarity, nearby gauges,
and shared calendar availability do not repair a missing exact key.

### 4.3 Reopening gate

For each unambiguous exact Inverts stream site, count distinct primary common UTC
calendar years. Define:

```text
site_clears_primary_floor = n_common_primary_years >= 6
```

Gate disposition is:

| Result | Machine token | Human disposition |
|---|---|---|
| At least 3 exact stream sites clear `n >= 6` | `REOPEN_REVIEW` | `REOPEN INDEPENDENT REVIEW` |
| Fewer than 3 exact stream sites clear `n >= 6` | `HOLD` | `HOLD / DO NOT BUILD` |
| Any authority, schema, credential, cleanup, or invariant failure | named failure reason; no scientific token | `FAIL CLOSED / NO SUPPORT RESULT` |

The two machine tokens map only to the human dispositions in this table;
`REOPEN_REVIEW` is not a generic test pass and `HOLD` is not an execution error.
`REOPEN INDEPENDENT REVIEW` is not `BUILD`, `PASS DRIVER INGESTION`, or
`AUTHORIZE EFFECT`. A later decision would still need a separately registered
annual-flow estimand, coverage rule, response adapter, mechanism, prior, pooling
rule, effect-blind validation, and publication plan.

## 5. Non-rescuing sensitivities

Sensitivities are fixed diagnostics and are never alternative primary analyses.

### 5.1 Corrected-only calendar sensitivity

Recompute the binary UTC calendar-year ledger using only primary-QC-passing
`csd_15_min` records. Historical `csd_continuousDischarge` records are excluded.
Report the same values-free common-year counts under the label
`corrected_15_min_only_sensitivity`.

### 5.2 Water-year sensitivity

Define the discharge water year from the UTC end time as October 1 through
September 30, labeled by the ending calendar year. Recompute record-presence and
the exact-key intersection under the explicit label
`utc_water_year_label_sensitivity`.

The response authority remains a calendar-year product. Equality between a
response calendar-year label and a discharge water-year label is only a temporal
sensitivity; it is not a claim that the observation periods are aligned.

Neither sensitivity may:

- replace the primary UTC calendar gate;
- contribute a site or year to the primary floor;
- change `HOLD` into `REOPEN INDEPENDENT REVIEW`;
- be selected because it has more support; or
- authorize an estimator, app, effect, prior, vote, or artifact.

## 6. Values-free output contract

### 6.1 Permitted retained fields

The final feasibility family may retain only:

- release tag, UUID, generation timestamp, DOI, package type, manifest identity,
  and official documentation identifiers;
- opaque request/file identities, file names without capability query strings,
  byte sizes, NEON-provided checksums, and independently calculated SHA-256
  values;
- exact response authority Git objects, ledger Git blob, and hashes;
- exact `siteID`, source `namedLocation`, and integer `utc_calendar_year` keys;
- stream/non-stream and explicit TOMB/TOOK/ambiguity exclusion states;
- the total Inverts projector receipt `state, n_rows` with all five frozen states;
- the complete response-anchored primary ledger fields `siteID`,
  `utc_calendar_year`, `discharge_site_year_present`,
  `qc_pass_record_present_in_utc_year`, and `source_regime`;
- only the source-regime labels `corrected_15_min_only`,
  `historical_uncorrected_1_min_only`, and
  `mixed_corrected_and_historical` for QC-pass support;
- the two named sensitivity binaries and labels;
- values-free schema, duplicate, chronology, QC-state, and exclusion counts;
- common-year counts per exact site, the count of sites clearing `n >= 6`, the
  machine token `REOPEN_REVIEW` or `HOLD`, and its exact frozen
  `human_disposition`; and
- booleans proving that no app, estimator, effect, prior, vote, or Driver artifact
  path was called.

It may emit a one-way digest of a sorted panel, but the digest input schema and
sort order must be recorded. A digest never replaces the reviewable values-free
site-year ledger.

### 6.2 Forbidden retained or logged content

The process must not retain or log:

- a discharge value or its sign, magnitude, distribution, aggregate, anomaly,
  rank, or plot;
- an Inverts density, area, count, composition, taxon, event value, or other
  response metric;
- a discharge-response association or effect-like statistic;
- raw data rows, row samples, head/tail output, serialized table previews, or
  screenshots of payload contents;
- provisional values or another release's files;
- API tokens, authorization headers, cookies, environment dumps, temporary
  signed URLs, URL signatures, or expiring capability parameters; or
- an app bundle, Driver adapter, `ann_flow()` implementation, effect module,
  prior, vote, generated artifact, or manifest edit.

Logs use bounded counts and reason codes only. A failure message may name a
table, field, file identity, expected class, or failed invariant, but must not
print the offending row or value.

## 7. Staged authorization

### Gate F0 — this pre-discharge-payload registry

F0 consists only of this candidate specification, the pure in-memory reducer,
synthetic fixtures, the committed values-free authority ledger, and its exact
byte/metadata verifier. It may use official public documentation, verify the
Inverts commit/root/`data/sites` tree metadata, and verify the TSV's exact Git
blob, SHA-256, schema, order, and `210 x 24 x 23` counts. It may not fetch or
deserialize an upstream Inverts RDS blob. It authorizes no authenticated request
and no discharge data-file fetch.

F0 passes only after the exact candidate is independently reviewed, its exact
head and merged default branch pass CI, Pages publishes that merge, a follow-up
receipt binds those identities, and that receipt is itself merged and Pages-
verified with all five Driver artifact hashes unchanged. A green candidate check
or candidate merge alone does not authorize F1.

### Gate F1 — authenticated manifest-and-schema-metadata acquisition

F1 is separately authorized only after the follow-up exact merge/Pages receipt
proves F0 passed. It may:

1. authenticate to the official NEON API with a narrowly scoped runtime secret;
2. reassert the exact release UUID, generation timestamp, DOI, availability
   manifest name/size/MD5, expanded package, and no-provisional boundary;
3. query file metadata for the exact 24-site response roster and all
   `RELEASE-2026` months available for those sites;
4. record table/metadata file names, sizes, checksums, package labels, site/month
   keys, and a sanitized request receipt;
5. fetch and verify only the exact variables, validation, categorical-code,
   readme, issue/science-review, and other non-observation metadata files named by
   the manifest, then freeze their table/field/class/unit/flag schema receipt; and
6. freeze a sorted exact F2 main-table fetch allowlist and its digest.

F1 must not follow a `csd_15_min`, `csd_continuousDischarge`,
`csd_continuousDischargeUSGS`, or other observation-table URL, and it must not
inspect an ecological payload. The exact schema metadata above are the only file
bytes F1 may fetch. Site-month availability is **inventory only**. It must not be
counted as a passing record, a supported year, or an ecological join. F1 also
must not fetch or deserialize an Inverts RDS blob; its response input remains the
committed two-column TSV.

F1 fails closed if the response roster assertion is not exactly `210 x 24 x 23`,
if TOMB or TOOK enters the primary allowlist, if a required table/metadata family
is absent, if an unexpected site or release appears, or if the official release
identity differs. Its receipt must be independently reviewed before F2.

### Gate F2 — exact payload and values-free reduction

F2 is separately authorized only after an exact F1 receipt passes review. It
must fetch only the immutable allowlist frozen by F1, from `RELEASE-2026`, with
`package=expanded` and provisional data disabled.

F2 executes in this order:

1. Re-fetch and verify only the exact schema metadata named by F1, and require
   its digest and normalized schema receipt to reproduce the independently
   reviewed F1 authority.
2. Reassert the frozen table and field schema, declared storage classes, units,
   timestamps, flag encodings, exact ordinary/BIGC chronology, and table
   relationships. Any mismatch stops F2; the runner may not adapt this
   specification in place.
3. Fetch the exact main-table files from the F1 allowlist and verify every
   source filename, size, NEON digest, and locally calculated SHA-256 before use.
4. Run the isolated values-free reduction. The process may test only table
   structure, keys, UTC times, finiteness, exact QC states, and response-side
   values-free keys.
5. Write only the permitted values-free family, including all 210 response-
   anchored rows and their explicit `FALSE` states, verify its deterministic
   digest, reassert the five unchanged Driver hashes, and delete all raw payload
   and capability material on both success and failure.

No raw payload, authenticated manifest response, or temporary source bundle may
be committed, attached to a pull request, uploaded as a GitHub Actions artifact,
served through Pages, or included in a Connect deployment.

## 8. Credential, network, and cleanup contract

- The API token exists only in the exact F1 or F2 process that requires it. It is
  injected from a secret store at runtime, never passed as a command argument,
  written to disk, echoed, serialized, or inherited by unrelated child
  processes.
- Environment dumps, shell tracing, verbose HTTP authorization output, and
  request debugging that can expose credentials or signed URLs are forbidden.
- Follow redirects only from the official NEON API to the exact host and file
  identity returned by the reviewed F1 manifest. Strip query strings and
  authorization material before any receipt is written.
- F1 and F2 use distinct session-owned temporary directories with restrictive
  permissions. Resolve and validate the exact directory before cleanup; never
  use a broad path, home directory, unresolved variable, or wildcard as a
  deletion target.
- On success, failure, cancellation, or timeout, delete only the exact
  session-owned raw tables, metadata payloads, API responses, signed-URL
  material, cookies, caches, and temporary credentials. Report cleanup as
  booleans and bounded file counts, not paths containing capabilities.
- After cleanup, assert that no raw payload, token, signed URL, request header,
  cache, stage directory, or upload artifact remains. A cleanup failure changes
  the gate result to `FAIL CLOSED / NO SUPPORT RESULT`.
- Network access is disabled during the values-free reduction after all exact
  F2 bytes have been verified. No sibling application code is sourced or run.

## 9. Required invariants, failure reasons, and exclusion reasons

The implementation must expose named, testable failures at least for:

```text
release_identity_mismatch
response_authority_mismatch
response_210_24_23_mismatch
package_not_expanded
provisional_input_present
manifest_allowlist_mismatch
required_table_missing
required_field_missing
unexpected_field_class
unexpected_qc_token
invalid_utc_time
duplicate_source_key
source_regime_chronology_mismatch
site_year_panel_invariant_mismatch
site_identity_ambiguous
tomb_requires_separate_contract
raw_payload_output_attempted
ecological_value_output_attempted
effect_path_attempted
driver_artifact_changed
credential_or_capability_exposed
cleanup_incomplete
```

The registered primary-gate exclusion reasons are:

```text
tomb_requires_separate_contract
took_requires_named_location_crosswalk
```

`tomb_requires_separate_contract` is both a hard family failure when a TOMB row
reaches either ordinary main-table projector and a total-receipt exclusion
reason for the special site. `took_requires_named_location_crosswalk` is an
explicit primary-gate exclusion reason, not a whole-family acquisition failure.
Under the frozen cutovers, cross-table overlap is rejected as
`source_regime_chronology_mismatch` before the defense-in-depth overlap check can
run.

An authority or structural failure yields no partial support result. Scientific
absence is different: a valid source family with too few common primary years
yields `HOLD / DO NOT BUILD`, not a failed acquisition.

## 10. Independent verification requirements

Before any F1 or F2 receipt is accepted, an independent verifier must re-run from
only immutable authorities and permitted values-free outputs. It must prove:

1. exact release, upstream response metadata, and committed ledger identities;
2. exact ledger Git blob/SHA-256, every sorted response site-year key, and the
   `210 x 24 x 23` response counts without fetching or deserializing an upstream
   Inverts RDS blob;
3. exact schema/QC predicate, UTC clock, and ordinary/BIGC source-regime
   chronology implementation;
4. order-invariance under shuffled files and rows;
5. rejection of duplicate keys, chronologically invalid or cross-table-
   overlapping periods as `source_regime_chronology_mismatch`, missing required
   fields, unexpected flag tokens, provisional files, TOMB before QC, and
   ambiguous site joins, plus explicit TOOK exclusion;
6. preservation of finite zero and rejection of absent/NA-as-zero conversion;
7. primary/sensitivity separation and inability of either sensitivity to rescue
   the primary gate;
8. all 210 response keys retained in the primary ledger, including explicit
   `FALSE` states, plus total projection/exclusion receipts with zero counts;
9. absence of ecological values and effect-like quantities from every retained
   output and log;
10. complete credential/capability/raw-payload cleanup; and
11. unchanged hashes for all five canonical Driver files.

Synthetic fixtures must cover corrected pass, corrected gap-filled pass,
unreviewed correction, final-QF failure, science-review failure, finite zero,
missing active-row discharge, absent row, historical uncorrected pass, mixed
calendar year, both ordinary and BIGC cutover boundaries, malformed UTC time,
duplicate key, cross-table overlap preempted by exact chronology, TOMB pre-QC
rejection, TOOK exclusion, total response-projection receipt states,
response-anchored `FALSE`, and both sides of the
`3 sites x 6 years` floor. Synthetic fixtures may not contain or be derived from
real ecological values.

## 11. Gate interpretation and next authority

The current F0 candidate changes no product definition, estimator, application,
source bundle, response metric, prior, vote, or generated Driver byte. Its
Driver impact is `NONE`.

F1 remains unauthorized while this document is a candidate. Only after the
follow-up exact merge/Pages receipt proves F0 passed may Gate F1's authenticated
manifest-and-schema-metadata acquisition begin. F1 cannot fetch observation-
table payload bytes. After an independently reviewed F1 receipt, a separate
authority may permit F2. After F2, either outcome still preserves the no-build
boundary:

- `HOLD / DO NOT BUILD` leaves the complementary product deferred; or
- `REOPEN INDEPENDENT REVIEW` permits only a new decision about whether to design
  a later app or estimator contract.

There is no automatic transition from feasibility to implementation.

## 12. Official primary sources

- [NEON User Guide to Continuous Discharge, Revision G](https://data.neonscience.org/api/v0/documents/NEON_continuousQ_userGuide_vG),
  dated 2026-02-06. Defines active/inactive publication, the two-table split,
  water-year conversion, TOMB, and science-review flagging.
- [NEON ATBD: Stage-discharge rating curves and continuous discharge, Revision B](https://data.neonscience.org/api/v0/documents/NEON.DOC.005403vB),
  dated 2026-03-09. Defines `dischargeContinuous`, correction states,
  gap-filling, NA behavior, indicator flags, TOMB, and historical field mapping.
- [Quick Start Guide for Continuous discharge, v2](https://data.neonscience.org/api/v0/documents/quick-start-guides/NEON.QSG.DP4.00130.001v2),
  PDF creation metadata dated 2026-04-09. Identifies package tables and the
  basic/expanded package boundary.
- [Introduction to the NEON Continuous Discharge Data Product](https://www.neonscience.org/resources/learning-hub/tutorials/continuous-discharge-intro),
  updated 2026-06-30. Demonstrates the official table merge, UTC parsing,
  table-appropriate field mapping, flag aggregation, correction-state meaning,
  and authenticated download requirement.
- [RELEASE-2026](https://www.neonscience.org/release-2026), released 2026-01-23.
  Records the new 15-minute table and the release exclusion after 2024-09.
- [Continuous discharge changing to 15-minute average](https://www.neonscience.org/impact/observatory-blog/continuous-discharge-dp400130001-changing-15-min-average),
  dated 2026-01-23. Records the WY2022 conversion and BIGC WY2021 exception.
- [Updates to Continuous Discharge](https://www.neonscience.org/impact/observatory-blog/updates-continuous-discharge-dp400130001),
  dated 2025-02-04. Directs use of corrected `continuousDischarge` and historical
  or provisional `maxpostDischarge` as appropriate.
- [NEON Products API documentation](https://data.neonscience.org/data-api/endpoints/products/),
  [Releases API documentation](https://data.neonscience.org/data-api/endpoints/releases/),
  and [Data API documentation](https://data.neonscience.org/data-api/endpoints/data/).
  These define release filtering, release immutability, authenticated data-file
  manifests, and expiring download URLs.

Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with
NEON/Battelle/NSF.
