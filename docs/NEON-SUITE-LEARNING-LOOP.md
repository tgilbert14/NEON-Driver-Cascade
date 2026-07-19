# NEON suite learning loop

This is the durable program record for improving the nine product apps, deciding
whether a complementary app is warranted, and then returning to the Driver Response
Atlas with stronger data, estimators, and ecological understanding. The work is a
sequence of evidence-producing app passes, not nine isolated redesigns.

## Program outcome

Every app pass must produce two things:

1. a better, tested product app (or an evidence-backed no-change/withheld
   decision), published only when authorized and every release gate is green; and
2. a compact knowledge package that states what the Driver can adopt now, what must
   remain contextual or hypothetical, and what missing product would unlock.

This file, in the Driver repository, is the central suite register. Each sibling
keeps its detailed local handoff, but a completed app pass is not closed until its
knowledge package and Driver decision are recorded here.

The Driver is the integration layer. It should not absorb a metric merely because a
sibling displays it. A candidate Driver signal still needs a stable definition,
sampling/effort support, compatible site-year keys, a defensible scale, honest
missing/zero handling, and a pre-stated mechanism or an explicit context-only role.

## Ten-app inventory and sequence

The current Driver is the baseline and final integration target. The nine product
apps visible in the suite cover are:

1. NEON Small Mammal Tracker;
2. NEON Plant Diversity;
3. NEON Plant Phenology Explorer;
4. NEON Vegetation Structure Explorer;
5. NEON Ground Beetle Tracker;
6. NEON Mosquito Pulse;
7. NEON Breeding Birds;
8. NEON Water Chemistry Analyte Viewer; and
9. NEON My Little Inverts.

The default progression moves from the flagship and terrestrial foundation through
fast/slow consumers, then into the aquatic pair. The owner may change the order for
readiness or scientific dependency, but each app remains a separate completed pass.

The 2026-07-18 suite audit changed the working order: Small Mammals remains first as
the companion release reference, but Phenology now precedes Plant Diversity because
green-up timing is the suite's strongest supported hinge and establishes the timing
contract that later producer/consumer passes must respect. The detailed baseline,
per-app briefs, visual system, and completion gates are in
`docs/NEON-SUITE-REVAMP-PLAN.md`.

```text
Driver baseline
  -> Phase 0 release-health stabilization
  -> nine one-at-a-time product passes
  -> cross-product synthesis and gap audit
  -> optional complementary app, only if it unlocks a material Driver advance
  -> Driver v2 integration
  -> full suite cross-link/deployment audit
```

Likely complementary-product candidates already identified by the science roadmap
are discharge/streamflow, aquatic-site water temperature, or periphyton. This is a
decision after the nine app passes, not a commitment now. Build one only when the
evidence register shows that it fills a shared-driver or missing-producer hinge that
cannot be obtained honestly from the existing apps.

## Phase 0 release-health stabilization

The one-app scientific cycle does not excuse a broken or unsafe public release
layer. Before any app is marked complete, repair the suite-wide prerequisites found
in the 2026-07-18 audit:

- Small Mammal Tracker and Ground Beetle Tracker currently render a Posit
  `Startup Error` page and require recovery before redesign work can be published.
- Every companion manifest disagrees with at least one tracked runtime file; exact
  file/checksum and semantic-manifest validation is therefore a release blocker.
- An HTTP 200 or cover prewarm is not app health. Post-deploy smoke must reject
  host error pages and require an app-specific ready marker.
- Moving action tags, moving package snapshots, combined write-enabled
  build/validate/publish jobs, and date-gated six-second "successes" must be replaced
  with the independently validated release shape proven in the Driver baseline.
- Each companion receives an app-local `AGENTS.md`, complete build/test handoff, and
  Driver knowledge-package scaffold as its pass begins.

This is `suite-platform` work. It does not authorize bulk ecological edits or allow
one app's pass to be closed from a cross-suite script alone.

## One-app learning cycle

Run this cycle to completion before beginning the next app.

### 1. Freeze the starting evidence

- Read that repository's `AGENTS.md`, complete build/test handoff, and this suite
  loop (or a synchronized copy).
- Record timestamp/time zone, owner, objective, branch, commit, relevant tool
  versions, generated-data lineage and hashes, deployment target, live URL, and
  current test state.
- Inventory the starting worktree, existing user changes, and active publishers
  before editing; record the final ownership/status at close.
- State the product's sampling unit, observational unit, response opportunity, and
  effort denominator before judging charts or estimators.

### 2. Audit science and data from raw records upward

- Confirm the exact DPID/tables, sampling design, spatial support, revisit structure,
  censoring, structural zeros, missingness, and protocol changes.
- Recompute headline metrics with an independent raw-source oracle.
- Identify pseudoreplication, unequal opportunity, denominator, nested-area,
  detection, and snapshot-versus-trend traps.
- Write a `CAN / CANNOT / HELD` claim list before promoting new conclusions.
- Prefer a reviewed `NA` or context-only result over an unsupported estimate.

### 3. Improve the product app

- Preserve product-native units and scientific identity; reuse suite chrome and
  interaction patterns only where they remain honest.
- Make QC inspectable: flag -> exact rows -> export, phrased as "verify, not wrong."
- Keep startup bundle-only and network-independent; update the cover, social card,
  sibling registry, and direct GitHub Pages URL when publishing.
- Record any reusable UI, accessibility, packaging, browser, CI, or deployment
  pattern in `docs/neonize-playbook.md` rather than leaving it in chat history.

### 4. Verify adversarially

- Run static syntax, unit/contract, raw-oracle, build, determinism, manifest,
  runtime-boot, and desktop/mobile browser gates in the repository's required order.
- Test real user events, empty states, keyboard paths, exports, local-only boot
  assets, console/network failures, and published URLs.
- Include at least one fresh diff review focused separately on science/statistics,
  R correctness, frontend lifecycle/accessibility, and deployment/security.
- Record failed attempts and cleanup with the same care as passing evidence.
- Record exact commands, environment, expected result, actual result, and
  `PASS`/`FAIL`/`BLOCKED`/`N/A`; a screenshot or remembered outcome is not a gate.
- After publication, bind the green PR head, merge commit, and deployed Pages
  commit in one receipt. Verify stable desktop/mobile geometry after reload or
  remeasurement, canonical/social metadata, natural social-image dimensions,
  console/network health, and every public link; persistent overflow blocks release.

### 5. Produce the Driver knowledge package

Every app pass ends with the following fields. `Unknown` is valid; omission is not.

| Field | Required content |
|---|---|
| Product identity | app/repository, DPID, immutable source commit, bundle/schema version |
| Unit and support | entity, sampling unit, spatial grain, temporal grain, revisit structure |
| Opportunity/effort | denominator, structural-zero rule, missingness, censoring, support gates |
| Trusted signals | definition, unit, direction meaning, uncertainty, exact eligible keys |
| Driver joins | compatible site/year/domain keys, match rate, proxy status, rejected joins |
| Mechanisms | candidate driver -> response, sign, lag, season, stratum, citations/status |
| Honesty limits | CAN / CANNOT / HELD statements and failure-closed outcomes |
| Reusable engineering | code/UI/QC/build/deploy pattern plus tests that proved it |
| Learning class | app-local, suite-platform, scientific-contract, and/or Driver-impacting |
| Driver decision | `ADOPT`, `HOLD`, `CONTEXT`, `COMPLEMENT`, or `REJECT`, with evidence |
| Next dependency | first missing data, method, or validation that would change the decision |

Use these decision meanings consistently:

- `NONE`: a reusable app/release lesson with no ecological Driver change.
- `ADOPT`: the Driver can implement the exact signal/mechanism now.
- `HOLD`: scientifically plausible but awaiting registered analysis, stronger support,
  or held-out observations.
- `CONTEXT`: useful descriptive state but not eligible to vote in Driver inference.
- `COMPLEMENT`: exposes a missing product/hinge worth evaluating after the nine apps.
- `REJECT`: incompatible scale, opportunity, join, or construct; preserve the reason.

### 6. Close the session durably

- Update the app-local handoff with exact commands, environment, expected/actual
  results, artifacts/hashes, invalidated evidence, failures, cleanup, residual risks,
  and next action.
- Update the suite register below and the Driver implication backlog.
- Promote reusable lessons to canonical instructions/playbooks, not only a dated log.
- Return Driver parity failures, incompatible keys/calendars, and missing audit
  fields to the owning app as explicit work rather than compensating silently.
- End with a clean ownership/status check and preserve unrelated work.

## Suite evidence register

This table is the program index. Detailed evidence stays in each app's repository.
Do not mark an app complete from memory or screenshots alone.

| Pass | App | Status | Source/build evidence | Knowledge package | Driver disposition | Published verification |
|---:|---|---|---|---|---|---|
| 0 | Driver Response Atlas baseline | COMPLETE AND PUBLISHED | exact bytes + semantic manifest passed twice in run `29644970791`, final PR run `29646272806`, and master run `29646451583`; merge `430b0b0`; see `BUILD-TEST-HANDOFF.md` | baseline + canonical Ubuntu/Haswell/one-thread and publication contracts captured | integration target; Driver v2 waits for passes 1-9 | Pages root/social card, desktop/mobile, console, metadata, and 12/12 public links verified 2026-07-18 |
| 0A | Suite release-health preflight | IN PROGRESS — 1/2 OUTAGES RESTORED | 2026-07-18 baseline found drift in all nine companion manifests, moving release inputs, and five apps with no executable tests. Small Mammal then fully validated the first pinned read-only CI, restricted refresh-candidate, semantic-health, and exact-manifest template; Ground Beetle remains the open outage | revamp plan + first complete app-local governance, handoff, and knowledge package | `NONE` (suite-platform); reuse the validated release shape in later passes, but keep product science app-specific | Small Mammal production restored and verified; Beetle still fails semantic startup; other seven companions have startup-only evidence |
| 1 | Small Mammal Tracker | PASS 1 COMPLETE / PRODUCTION VERIFIED | app closeout `main` `b05cecc`; deployed runtime `1615ab4`; R 4.5.2, 91 packages, 117 files, Haswell/one thread, six-handler JS contract, 11 scientific fixtures, 46/46 site bundles, 46/604/604 indexes, 145 species, offline source, exact checksums, and semantic production health passed; manifest SHA-256 `f6c4a5ff74053b95e22fac7394f1930d2fe2329663737031b1c32f7a1f70bc54` | pinned package complete; exact physical-event effort, opportunity, detection, exports, limitations, release identities, documentary-cover provenance, question-led information architecture, and reusable learning recorded | `CONTEXT`; physical-event contract parity is closed, but exact current-source Driver join remains held; no Driver artifact byte change | Connect Last deployed `1615ab4`; fresh JORN flow and semantic marker passed; Pages V4 merge `dd72d51` plus final closeout `b05cecc` passed desktop, 390 x 844, and 320 x 800 with no overflow, local USGS imagery, complete suite links, and valid social metadata |
| 2 | Plant Phenology Explorer | PASS 2 COMPLETE / PRODUCTION VERIFIED | release head `cc0151d` passed run `29669603912`; merge/Pages/Connect `29c0ed1`; R 4.5.2, 92 packages, 60 runtime files, Haswell/one thread, five-handler JS contract, expanded scientific fixtures, 46/46 bundles, two-pass null-container normalization, two-build deterministic indexes, offline source, and exact manifest/data equality passed; manifest SHA-256 `cc5e2a464b2c96772c6e2b441b55a4eabb603f36311c08d4342e4ed0f59a5325` | exact plant-year-week opportunity, onset interval/left censoring, desert coverage/leaf-active alternative, within-species cross-site guardrails, release identities, cover provenance, and reusable learning recorded | `HOLD / NO DRIVER BYTE CHANGE`; app-local onset/leaf-active/coverage are trusted candidates, but existing temperature -> green-up adoption must be re-evaluated through an exact registered join | Connect Last deployed `29c0ed1`; semantic run `29670192516`, fresh HARV Overview/Clock/Onset/Across-Sites flow, and Pages desktop/390/320 with all ten suite links and no root overflow passed |
| 3 | Plant Diversity | PASS PENDING | live start passed; 13 manifest file mismatches; one helper test | — | provisional `CONTEXT` for richness/invasion | startup only, not a release receipt |
| 4 | Vegetation Structure Explorer | PASS PENDING | live start passed; 8 manifest file mismatches; one helper test | — | provisional `CONTEXT` slow state floor | startup only, not a release receipt |
| 5 | Ground Beetle Tracker | P0 OUTAGE / PASS PENDING | live startup error; 8 manifest file mismatches; no executable tests | — | catch-conditioned effort remains `CONTEXT` | failed semantic startup check 2026-07-18 |
| 6 | Mosquito Pulse | PASS PENDING | live start passed; 7 manifest file mismatches; no executable tests | — | provisional `HOLD` seasonal / otherwise `CONTEXT` | startup only, not a release receipt |
| 7 | Breeding Birds | PASS PENDING | live start passed; 8 manifest file mismatches; one helper test | — | provisional `CONTEXT` | startup only, not a release receipt |
| 8 | Water Chemistry Analyte Viewer | PASS PENDING | live start passed; 3 manifest file mismatches; no executable tests; current code ahead of review prose | — | provisional `CONTEXT` aquatic condition | startup only, not a release receipt |
| 9 | My Little Inverts | PASS PENDING | live start passed; 9 manifest file mismatches; no executable tests; no expert review | — | provisional `CONTEXT` | startup only, not a release receipt |
| 10 | Optional complementary product | decision-support audit COMPLETE; formal decision still after pass 9 | catalog swept against the live NEON Data Product Catalog 2026-07-18 (DPIDs verified; phantom/renamed products flagged) | [`docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](COMPLEMENTARY-APP-GAP-AUDIT.md) — 11 candidates ranked through the 6-question intake + adversarial refutation; 29 dropped with reasons | ranked backlog recorded (see rows below); no build authorized — gate remains passes 1–9 | — |
| 11 | Driver v2 reintegration | blocked on synthesis | — | nine packages + gap decision | integrate accepted set | — |

## Driver implication backlog

Add one row for every materially supported or rejected cross-product idea. Never
delete rejected ideas; their reasons prevent future sessions from repeating unsafe
work.

| Source app | Candidate signal/link | Decision | Evidence/support | Required Driver change | Blocker/next test |
|---|---|---|---|---|---|
| Driver baseline | temperature -> green-up | ADOPT (existing exploratory family) | 18 eligible sites; full details in Driver handoff | preserve exact lineage and sensitivities | re-evaluate after phenology pass |
| Driver baseline | plant richness as productivity | REJECT | composition is not productivity | keep context-only wording | evaluate periphyton/producer gap after aquatic passes |
| Driver baseline | beetle activity as CPUE | CONTEXT | denominator is catch-event-conditioned | no inferential vote | revisit after beetle effort audit |
| Driver baseline | aquatic climate bridge | COMPLEMENT | no direct terrestrial/aquatic site-code overlap | require explicit proxy or true aquatic driver | water chemistry + inverts passes, then gap audit |
| Driver release platform | canonical Ubuntu bytes + strict Windows oracle + independently validated CRAN/RSPM manifest normalization | NONE (suite-platform; validated) | family hashes, dual policy fixtures, raw-source oracle, boot/smoke evidence, and two clean exact-byte/semantic-manifest passes in Driver handoff | no scientific Driver change | reuse this release/test split in each app pass; never round artifacts or normalize unvalidated provenance |
| Driver release platform | fixed BLAS core and one-thread numeric runtime | NONE (suite-platform; validated) | unpinned run drifted; run `29644970791` attempts 1 and 2 loaded Haswell/one thread and reproduced exact bytes plus semantic manifest on unchanged head `526dd3b` | keep loaded core/thread assertions in CI and refresh, with no scientific rounding | reuse the exact loaded-runtime guard and two-run proof in each sibling app that publishes numeric artifacts |
| Driver release platform | PR/merge/Pages identity plus stable public browser receipt | NONE (suite-platform; validated) | final PR and master CI green; Pages built merge `430b0b0`; desktop/mobile, metadata, 1734x907 social asset, empty console, and 12/12 public links passed | no scientific Driver change | reuse the three-identity publication receipt; remeasure after viewport transitions and reject persistent overflow |
| Complementary-app gap audit | streamflow / discharge `DP4.00130.001` as the aquatic hinge | COMPLEMENT (acquire next; top-ranked) | sole non-redundant primary aquatic driver; ~24–28 gauged-stream overlap with staged inverts | build `ann_flow()`; register+date `flow→inv_density` EXPLORATORY, `stratum_class=stream`; within-site anomaly only | needs ≥3 gauged streams × ≥6 overlapping discharge-and-invert site-years; marquee land-vs-water monsoon is SYCA≈1-site, `poolable=FALSE` under `min_sites=3` |
| Complementary-app gap audit | biome-conditional producer/ANPP rung — litterfall `DP1.10033.001` + clip-harvest `DP1.10023.001` | COMPLEMENT → ADOPT (grassland rung iff ≥3 sites clear n≥6) | only terrestrial candidate; true annual mass flux; native site+year+domain join; best-supported producer prior (Sala/Knapp/Huxman) | add producer rung + `precip→herbaceous-ANPP` grassland prior; litterfall Flowers+Seeds = descriptive context, no prior | clip-harvest 2016–2019 start → 3–11 site-year overlap is floor-fragile; strike mediated-path/SEM + desert seed mediator (forest-only data gap) |
| Complementary-app gap audit | periphyton `DP1.20166.001` aquatic producer rung | COMPLEMENT (after discharge) | green-up analog; clean internal 34/34 join; grazer–periphyton link well-supported | `ann_periphyton()` benthic/pelagic split; one guild-matched standing-crop prior | build only after discharge + Water Chem/inverts consumed; standing-crop never "production"; mostly n=3–5 → pool ≥3 streams |
| Complementary-app gap audit | surface-water temperature `DP1.20053.001` (streams) | COMPLEMENT (after discharge/periphyton) | retires air-temp→water-temp proxy on the internal `waterTemp→inv_pct_ept` link | swap driver, sign/lag/season build-locked EXPLORATORY; within-site anomaly | smallest payoff — the upgraded link is `expected_class='none'` (context-only), so better driver ≠ a vote; avoid double-count with SWC grab `waterTemp` |
| Complementary-app gap audit | ticks (drag-cloth) `DP1.10093.001` consumer rung | COMPLEMENT (conditional; revised down from ADOPT) | valid all-event drag-**area** denominator (better than beetle catch-only / mosquito whole-year) → plausible route to a votable consumer rung | area-standardized questing-window index; registered temperature prior | temperature axis duplicates beetle `temp_spring`; moisture axis unwireable without a 2nd (VPD) acquisition; 46/46 join asserted, not measured |
| Complementary-app gap audit | fish `DP1.20107.001` aquatic top predator | COMPLEMENT (last of aquatic sequence) | genuine top-predator level; 2nd aquatic integrator corroborating inverts | sign-only within-site CPUE, stream/lake split, CONTEXT-only | quadruply contingent (needs discharge+watertemp+periphyton); no climate→fish prior; land-vs-water headline forbidden; never stage phantom `DP1.20108.001` |
| Complementary-app gap audit | water-quality sonde `DP1.20288.001` | CONTEXT (descriptive companion) | net-new turbidity + continuous-cadence power-control showcase | continuous descriptive condition companion, autocorrelation-honest | 3/4 uncensored channels redundant with staged Water Chem; drop "retires air-temp proxy" framing; chlorophyll HELD, never the periphyton rung |
| Complementary-app gap audit | zooplankton `DP1.20219.001` lake consumer | COMPLEMENT / HOLD | lake analog of stream macroinverts | fold into a sequenced lake-food-web package (phyto→zoop→fish) | orphaned until a lake producer + lake predator exist; 7 lakes risks `min_sites=3` floor; EPT-poor lakes never pool against streams |
| Complementary-app gap audit | in-situ meteorology "climate-driver app" `DP1.000xx` | REJECT the app framing (keep 2 non-app moves) | terrestrial climate root already borrowed; adds 0 non-NA site-years | none as an app: register a `VPD→moisture-stress` HOLD prior; keep the labeled domain climate proxy | preserve reason — TIS (`DP1.000xx`) vs AIS (`DP1.200xx`) is 0/34; never silently key air-precip to aquatic sites |
| Complementary-app gap audit | soil moisture + soil temp `DP1.00094.001` + `DP1.00041.001` | HOLD | direct plant-available water at desert-thin sites | descriptive within-site anomaly co-display; dated soil-temp prior on green-up | sharpens a driver for a test that does not exist (no coverage-standardized desert response rung; water-limited stratum ≈ SRER-only); breaks "no-refetch" architecture |
| Complementary-app gap audit | AOP greenness NDVI/EVI/LAI/fPAR `DP3.30026/.30012/.30014` | CONTEXT descriptor; productivity-rung framing REJECT | only sensor-standardized cross-site greenness proxy | at most a within-site anomaly QC cross-check beside `veg_ba_ha` | ~3–4-yr flight cadence caps per-site n below the n≥6 gate permanently; cross-site NDVI magnitude = the rejected richness-as-productivity construct |
| Small Mammal Tracker | physical-event trap effort, opportunity-complete species CPUE, and detection-qualified consumer context | CONTEXT / NO BYTE CHANGE | runtime `1615ab4` passed the exact six-status, canonical-coordinate, multi-capture, double-trap, placeholder, and fail-closed fixtures in pinned R; species denominators use all reviewed opportunity; Compare carries p-hat/mean N-hat and suppresses unsupported raw winners; 49% of 8,200 bouts are single-night/index-only | keep current Driver bytes and independent resolver; preserve the app package as descriptive consumer context, not an inferential vote | during suite synthesis, pin an eligible current source and measure exact site-year join/support before considering ingestion; retain monsoon precipitation -> next-year CPUE only as a registered contextual candidate |
| Plant Phenology Explorer | plant-year green-up onset, leaf-active duration, and green-up coverage/support | HOLD / NO BYTE CHANGE | run `29669603912` passed corrected plant x phenophase x year x week opportunity, interval/left censoring, all-suppressed `NULL` trends, multi-flush leaf-active duration, warm-desert coverage, within-species support, deterministic artifacts, exact manifest, and offline source; public HARV flow exposed cadence, coverage, roster, CI, and non-causal limits | keep current Driver bytes and independent adapter; preserve app-local signals as candidates, not a UI-derived Driver vote; retain coverage as support rather than timing | pin the exact eligible site-year source and measure match/missingness/censoring; register temperature/onset model and desert alternative before re-evaluating the existing exploratory family; demote to `CONTEXT` if the inferential gate does not clear |

## Driver v2 reintegration gate

After the nine app passes, synthesize before coding. Driver v2 begins only when:

- all nine knowledge packages exist and their source commits are pinned;
- shared terms have one canonical definition and incompatible constructs stay split;
- site-year/domain joins and match rates are measured, with every proxy labeled;
- signal opportunity, effort, zero/missing, censoring, and support gates are explicit;
- directional priors are registered with sign, lag, season, stratum, citation, and
  exploratory/held status before examining any genuinely held-out result;
- complementary-product candidates are ranked by how many important Driver gaps
  they close, and the build/defer decision is recorded;
- every accepted Driver change has an independent adapter/raw-source oracle rather
  than executing sibling app code or copying a UI headline;
- each semantic change bumps affected bundle/search/meta schemas and updates the
  codebook, coverage, source lineage, search index, and exports;
- expected pre/post row/site counts, scientific pins, votes, sensitivities, meta
  results, headlines, and caveats are declared before rebuilding;
- no sibling input is consumed from a moving branch or half-reviewed app state;
  Driver integration uses only pinned, green source commits;
- each generated family names one canonical release-byte platform/toolchain,
  including any dispatched BLAS core and thread contract, or proves exact
  cross-platform bytes; other-platform diagnosis separates RDS
  headers/serialization, strict schema/key/text equality, hexadecimal numeric
  deltas, and embedded upstream-fingerprint propagation before counting drift;
- Windows/Linux portability is rechecked for locale ordering, justified numeric
  tolerances, line endings, manifest provenance, and immutable workflow pins; and
- the full artifact, manifest, boot-integrity, browser, publication, and rollback
  matrix is rerun for the final unchanged integration.

The desired result is not a larger app at any cost. It is a better-grounded map of
ecological drivers whose links say exactly what the NEON data can and cannot support.
