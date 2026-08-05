# Driver v2 cross-product synthesis

Decision date: 2026-08-04 EDT
Decision state: **PASS 10 COMPLETE / PHENOLOGY SEAL 2 HOLD AT LEGACY SCHEMA GATE / DRIVER V2 SIGNAL CHANGES HELD / NO CANONICAL BYTE CHANGE**

This is the evidence gate between the nine completed companion passes and a future
Driver v2 rebuild. It records what is safe to reuse, what is only context, what is
still unmeasured, and why replacing the seven old Driver pins with current app heads
would not be a safe integration strategy.

## Outcome

- All nine companion releases are production-verified.
- Their reusable sampling, provenance, zero/missing, support, and publication
  contracts are accepted where identified below.
- **No current companion ecological signal is newly vote-eligible.** App-contract
  adoption and ecological-signal adoption are separate decisions.
- The two legacy temperature→green-up screens remain part of the unchanged
  published v1 artifact, and both remain **HOLD for v2 re-authorization**. The
  effect-blind [Phenology Seal-0 registry](PHENOLOGY-V2-ADAPTER-SPEC.md) now
  freezes the independent adapter, response model, support-mask, effect, and
  pooling contracts. Seal 1 now implements only the pure adapter, response-only
  model, and one-way values-free mask under an exact runtime lock; 38 synthetic
  fixture families passed across six fresh isolated Seal-1 processes without
  deserializing either the legacy or current Phenology RDS family. The separate
  unchanged v1 rebuild continues to use its recorded legacy pins only for exact
  canonical reproduction. Legacy parity is not proved; current response support,
  climate support, and all v2 effects remain separate later gates.
- Every complementary-app build is **DEFERRED**. Only pinned feasibility evidence
  acquisition is authorized: discharge first, herbaceous clip harvest second.
- Seal 1 adds isolated Driver-owned implementation, synthetic tests, CI, and a
  runtime-lock receipt only. It does not update a source pin, published schema,
  prior, vote, row, manifest entry, or generated Driver artifact.
- Seal 1 is published as PR #55 exact head
  `35c2ca79a135303c00027dd32d9dd961a07bca2a`, merged authority
  `6cb1e9e8a0fce646ced26ee296cf8ee75d991f4d`. Exact-head run `30977899036`,
  merged-default run `30978285438`, and Pages run `30978284811` all passed;
  the public root returned HTTP 200. Driver impact is `NONE`, all five canonical
  hashes remain unchanged.
- The documentation receipt for that authority is published as PR #56 exact head
  `a26428a66a7e8dcadf9fa26c4f42d870a6ff36be`, merged as
  `c952687399abfef9c155ccaf207b83a79ea698a4`. PR run `30979039907` passed
  rebuild job `92219313582` and Seal-1 job `92219313600`; post-merge run
  `30979297006` passed Seal-1 job `92220080404` and rebuild job `92220080424`.
  Pages run `30979295789` passed build `92220078640`, deploy `92220171068`, and
  status `92220171073`; the public root returned HTTP 200.
- The first Seal-2 candidate acquired only exact legacy commit
  `81e339e9ed6f34d3d04ca45a7030fea51c4147a5` and its `data/sites` tree
  `30abe869b0f78931929c21e544ffc85ec2238e35`. A schema-only scan found 45
  bundles with nonempty `trend` and one typed, non-`NULL` `trend` with the
  required columns but zero rows. The frozen registry correctly raised its
  registered hard failure `empty_required_table`; formal sections 8.3/9.3 parity
  was **NOT ATTEMPTED**. A manual one-bundle nonempty diagnostic adapted
  successfully, but is explicitly not parity evidence.
- The isolated Seal-2 gate records `current_fetched = false`,
  `current_deserialized = false`, `effect_module_sourced = false`, and
  `effect_function_called = false`. Those no-current/no-effect claims apply only
  to that isolated gate; the unchanged canonical rebuild separately uses its
  recorded legacy v1 pins. Adapter, frozen specification, canonical artifacts,
  and Driver disposition remain unchanged. Driver impact is `NONE`, Seal 2 is
  `HOLD`, and Seal 3 remains sealed.

## Evidence method and vocabulary

`scripts/audit_suite_compatibility.R` reads exact committed RDS blobs from the nine
sibling repositories. It does not check out a moving ref, execute sibling code, or
run the Driver build. Each product is audited in its own R process to bound memory.
It fails closed when a data or knowledge authority is not an ancestor of the
audited default head, or when the pinned knowledge authority lacks the required
Driver package.
The machine-readable decision record is
[`driver-v2-compatibility.csv`](driver-v2-compatibility.csv); the audit reads its
authorities directly so the executable audit and published ledger cannot carry
different pins.

The audit keeps four concepts separate:

- **source site-year** — any year represented in the selected app source family;
- **app-supported site-year** — a year satisfying that app's physical opportunity
  or metric-specific support predicate;
- **direct Driver-calendar match** — exact equality of app `siteID x year` with the
  current Driver terrestrial calendar; and
- **domain-year proxy** — an aquatic site-year whose NEON domain and year occur in
  the Driver. This is a coverage diagnostic only, never an eligible join.

A direct calendar match is not an estimator, mechanism, or vote. Plant Diversity
remains explicitly `UNMEASURED` at the annual support grain because its current
family has no sampled-empty opportunity ledger; counting positive occurrence years
would manufacture a denominator.

## Current Driver baseline

The unchanged artifact at synthesis base
`a7d610ef8fbffe72945c523657995452d5caffdf` contains 510 annual rows, 46
terrestrial sites, 552 site-link rows, and 12 registered priors. It consumes seven
older companion pins; Water Chemistry and Inverts are absent.

Only two rows have an expected class other than `none`, and both belong to the same
phenology hinge:

| Legacy v1 screen | Direction matches | Exact binomial p | Holm / FDR | v2 status |
|---|---:|---:|---:|---|
| annual temperature → green-up DOY | 15 / 18 | 0.003768921 | 0.007537842 | HOLD — Seal-2 parity not attempted (legacy schema gate) |
| March–May temperature → green-up DOY | 8 / 18 | 0.759658813 | 0.759658813 | HOLD — Seal-2 parity not attempted (legacy schema gate) |

These values describe the published v1 snapshot; they are not a claim that the
current Phenology release reproduces the same eligible plants, censoring treatment,
site set, or effect. Annual precipitation is finite in only 108 of 510 rows; its
current missingness is 402/510 (78.82%).

## Measured cross-product compatibility

Counts below describe app support and calendar compatibility, not Driver adoption.
`n>=6` is the number of app-supported sites with at least six supported years.

| App | Exact data/runtime authority | App-supported site-years | Direct Driver-calendar match | `n>=6` | Signal decision | Reusable contract decision |
|---|---|---:|---:|---:|---|---|
| Small Mammals | `1615ab4e74fd16a2698de8431acb862d6cc4cebf` | 410 at 46 sites | 410 / 410 | 42 | CONTEXT | ADOPT reviewed physical-event effort and detection qualification |
| Plant Phenology | `7d0f29f7886cfae1c760a9ffc9e056184ec6fc68` | 346 at 45 sites | 346 / 346 | 39 | HOLD v2 green-up re-authorization | ADOPT opportunity, censoring, coverage, and unavailable-state rules |
| Plant Diversity | `8fc0824493a52a1a7ca2054852a5d84b264a9c8c` | UNMEASURED | UNMEASURED | UNMEASURED | CONTEXT | ADOPT source receipt, nested grain, recurrent-panel, and unknown-nativity rules |
| Vegetation Structure | `d566b30ec8eb52ae984325da402cadfec3f18bc9` | 156 at 37 sites | 151 / 156 | 0 | CONTEXT | ADOPT event/opportunity and disjoint physical-channel rules |
| Ground Beetles | `a615d6cdf550ea19ea13448bd234004f94de312e` | 388 at 46 sites | 388 / 388 | 43 | CONTEXT | ADOPT field-first opportunity, zero-catch, and taxonomy-reconciliation rules |
| Mosquitoes | `935420e1e1aa79dcc3cf54d03ef150f6f0332b8d` | 203 at 47 sites | 200 / 203 at 46 sites | 7 | CONTEXT | ADOPT outcome-state reconciliation and physical-interval identity |
| Breeding Birds | `97c3e4c25b69068c7d8b3d56bc3da3bc019e5097` | 384 at 47 sites | 381 / 384 at 46 sites | 46 | CONTEXT | ADOPT grain-specific opportunity, supported-zero, and complete-window rules |
| Water Chemistry | `ee95af3e270099980ea5bc98b28b549456b3f0b2` | 387 at 34 sites | 0 / 387 direct site-code matches; 351 / 387 domain-year proxy | 34 | CONTEXT / HOLD ingestion | ADOPT audited-unit, signed-replay, and exact-runtime receipt rules |
| My Little Inverts | `ff23e994e289982c747b91e48c5ff0907c1672d2` | 307 at 34 sites | 0 / 307 direct site-code matches; 307 / 307 domain-year proxy | 33 | CONTEXT / HOLD ingestion | ADOPT field-first status, supported-area, taxonomy-placeholder, and zero/unknown rules |

PUUM explains the three unmatched Mosquito site-years and the three unmatched Bird
site-years: the released companion families include that site while the Driver's
46-site terrestrial roster does not. Water and Inverts have zero exact site-code
matches because their aquatic sites are a different spatial system. Their eligible
Driver integration is therefore **unmeasured, not zero**; the domain proxy does not
repair the key.

## Governance closeout and validation repair

The synthesis ledger pins knowledge authority separately from data authority. Four
package-reconciliation PRs are merged on their watched default branches:

| App | PR-head validation | Merged knowledge/default authority |
|---|---|---|
| Plant Phenology | PR #10 run `30942442471` | `30be615dc438b60e4fa6454973b3b42589b22234` |
| Plant Diversity | PR #16 run `30942526938` | `28fab5b0bb5fa0fb87b7f5bbf4c2aa690cc5b612` |
| Mosquito Pulse | PR #10 run `30941882521` | `ff505c9f64dd3b99bc543f4078eb2e4dddb6a0f1` |
| Water Chemistry | PR #16 run `30940612037` | `9e2946ca5f07f0c81eac790ad10dcef0c9f0f3d9` |

The first Mosquito, Phenology, and Plant Diversity PR checks reached or passed their
scientific contracts and then exposed moving package-resolution defects in
manifest-producing jobs. Those workflows now request the exact committed package
versions (`bslib 0.11.0`, plus `zip 3.0.1` where Phenology requires it) and use new
cache namespaces. The amended exact heads passed their full canonical checks. No
source bundle, estimator, committed manifest, app surface, or Driver artifact was
changed by those release-platform repairs.

## Why a blind repin is rejected

At the exact fields the Driver imports, only Small Mammals remains byte-identical to
the current production family. Plant Diversity matched the older Pass-3 production
at `data/sites`, but its refreshed production now differs there too. Phenology,
Vegetation, Beetles, Mosquitoes, and Birds also differ from the current Driver pins.

That does not mean every biological value changed. It means byte identity cannot
prove parity. A blind commit substitution would:

- hard-fail older Vegetation and Mosquito adapters on newer schemas;
- silently discard opportunity and supported-zero semantics for Beetles or Birds;
- keep provisional 2025 Bird values even though the official Bird release ends in
  2024; and
- present a re-estimated Phenology family as if it were the registered v1 result.

Therefore no source commit is repinned in this phase. Each future integration must
use an independent Driver adapter, exact raw/source oracle, declared pre/post
expectations, and old/new parity evidence.

## Two-axis disposition model

Every package now carries two independent decisions:

1. **Contract/process disposition** — whether the suite should reuse an effort,
   missingness, zero, estimator-support, provenance, or publication rule.
2. **Ecological-signal disposition** — whether a specific metric and mechanism may
   enter Driver voting.

This resolves the apparent Mosquito contradiction: outcome-state reconciliation is
`ADOPT`, while whole-trap-scaled activity remains `CONTEXT / HOLD DRIVER INGESTION`.
The same rule applies elsewhere; a production-proven app is not automatically a
production-proven Driver edge.

## Complementary-product decision

The formal decision is **DEFER BUILD / ACQUIRE EVIDENCE**.

- **First:** acquire a pinned Continuous Discharge `DP4.00130.001` bundle and
  publish the exact QC-cleared discharge×Inverts site-year intersection. Reopen a
  build only at at least three recorded-stream sites with at least six common years.
- **Second:** acquire a pinned Herbaceous Clip Harvest `DP1.10023.001` bundle and
  publish the exact coverage-cleared clip×Driver-precipitation intersection. Reopen
  only at at least three temperate-grassland sites with at least six common years.
- **Litterfall `DP1.10033.001`:** retain as prospective descriptive forest context.
  Do not fuse it with clip harvest or call it a seed mediator.

The detailed ranked backlog and rejected alternatives remain in
[`COMPLEMENTARY-APP-GAP-AUDIT.md`](COMPLEMENTARY-APP-GAP-AUDIT.md).

## Authorized next work

1. Preserve this synthesis as the v2 decision baseline.
2. Seal 1 and its publication receipt are complete: the frozen
   [Phenology registry](PHENOLOGY-V2-ADAPTER-SPEC.md) has a pure two-clock
   adapter, response-only interval model, one-way values-free climate-support-mask
   builder, adversarial synthetic fixtures, and exact runtime pin. Its isolated
   Seal-1 path accessed no current or legacy Phenology response family and
   produced no v2 effect; the separate unchanged v1 rebuild used its recorded
   legacy pins only for exact canonical reproduction. PR #55
   exact head `35c2ca7` merged as `6cb1e9e8`; exact-head, merged-default, and
   Pages publication gates passed in runs `30977899036`, `30978285438`, and
   `30978284811` respectively. Receipt PR #56 exact head `a26428a...` merged as
   `c952687...`; its PR, post-merge, and Pages gates passed, and the public root
   returned HTTP 200.
3. Seal 2 is `HOLD` before parity. Its isolated legacy-only gate scanned all 46
   bundles from exact legacy commit `81e339e9...` / tree `30abe869...`: 45 had a
   nonempty `trend`, while one had a typed non-`NULL` required-column `trend` with
   zero rows. The frozen registry raised `empty_required_table`, so formal
   sections 8.3/9.3 parity was **NOT ATTEMPTED**. The successful manual adaptation
   of one nonempty bundle is diagnostic only and is not parity evidence.
4. Publish this HOLD gate. Any legacy-only schema amendment must be a new,
   separately reviewed registry stage; never silently normalize the frozen
   contract. Current response support remains forbidden and Seal 3, including all
   effect execution, remains sealed.
5. Acquire discharge feasibility evidence without building an app, adding a prior,
   or changing Driver artifacts.
6. Revisit other companion adapters only when a named Driver question requires the
   metric. Do not ingest all available app outputs merely to make the atlas larger.

## No-build receipt

At this decision point the canonical hashes remain:

| Artifact | SHA-256 |
|---|---|
| `data/cascade.rds` | `47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe` |
| `data/search_index.rds` | `a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e` |
| `data/cascade_meta.rds` | `00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de` |
| `data/neon-cascade-codebook.csv` | `a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3` |
| `manifest.json` | `92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79` |

Canonical Ubuntu 24.04 / R 4.5.2 / dated 2026-07-15 snapshot / Haswell /
one-thread CI must still rebuild and prove those bytes unchanged before merge.
