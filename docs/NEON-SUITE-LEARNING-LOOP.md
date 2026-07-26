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

Owner direction on 2026-07-22 resumed the program after Pass 4 and inserted one
cover-alignment checkpoint before Pass 5. Plant Diversity PR #11 merged as
`dfb44231e67fff49f229a835eb9fcdc2bfcefe0d`; Plant Phenology PR #5 merged as
`50106f205a38ab5abf1e807f1c54e44a9b5d8885`. Their pinned validation, Pages, and
semantic-production workflows passed, and both public surfaces now use the
approved Suite Living Poster V1 frame without changing their scientific contracts
or Driver dispositions. Ground Beetle Pass 5 subsequently completed the full
release/science cycle and its static artistic Living Poster on exact production
merge `89caa4359019d95fe99dd9d916163ec269b6572e`. Mosquito Pulse Pass 6 then
published an opportunity-complete 47-site release, a static nocturnal-wetland
Living Poster, and production-verified reactive-output and accessibility gates on
authoritative runtime `935420e1e1aa79dcc3cf54d03ef150f6f0332b8d`. Pass 7,
Breeding Birds, is next.

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

- The three baseline Startup Error states are closed. Small Mammal Pass 1 restored
  its release and Cover V5 is production-verified through PR #86 / merge
  `c4c46fce` and Connect #125. Ground Beetle Pass 5 replaced its catch-conditioned
  family with 46 validated opportunity-complete bundles, repaired the custom
  handlers and semantic-ready contract, and passed exact CI, Pages, and production
  smoke on merge `89caa4359019d95fe99dd9d916163ec269b6572e`.
- At the 2026-07-18 baseline, every companion manifest disagreed with at least one
  tracked runtime file. Unresolved drift remains a release blocker for each later
  pass until exact file/checksum and semantic-manifest validation closes it.
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
- Use **Suite Living Poster V1** on both Pages and the in-app first-run surface:
  the same structural frame, but app-native art and content. The companion face has
  DDL identity, exactly one Driver route, an app/unofficial eyebrow, a 3–7-word
  hook, a 6–12-word plain promise, one contextual CTA, one dominant responsive
  editorial artwork, a visible art/data boundary, and a compact
  scope/honesty/Source/Feedback footer. It has no metric band, method block, second
  marketing bridge, release receipt, or full suite directory. Driver owns the full
  registry; each app still owns its palette, motif, crop, words, and scientific
  limitation.
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
| 0A | Suite release-health preflight | IN PROGRESS — 3/3 STARTUPS RESTORED; PASSES 1–6 RELEASE-SAFE | 2026-07-18 baseline found drift in all nine companion manifests, moving release inputs, five apps with no executable tests, and Startup Error states in Small Mammal, Phenology, and Ground Beetle. Pass-specific releases now give Small Mammal, Phenology, Plant Diversity, Vegetation, Ground Beetle, and Mosquito pinned validation, restricted refresh candidates, semantic health, exact manifests, and app-local governance. Mosquito runtime `935420e` passed its 47-bundle opportunity/index/manifest contracts, real-bundle server render, and exact production smoke | revamp plan + six published app-local packages; Vegetation docs authority `3391e70` / receipt `da466ea`; Ground Beetle release merge `89caa435`; Mosquito receipt merge `91b4c71` | `NONE` (suite-platform); reuse the validated release shape in later passes, but keep product science app-specific | All three baseline startup errors are closed; passes 1–6 have content-aware production receipts; Birds, Water Chemistry, and Inverts retain startup-only baseline evidence until their passes |
| 1 | Small Mammal Tracker | PASS 1 + COVER V5 COMPLETE / PRODUCTION VERIFIED | Cover V5 source head `3e66ddca`, PR #86, merge `c4c46fce3725126231504d8f9610f52e8f929ef8`; R 4.5.2, 91 packages, 120 manifest files, Haswell/one thread, six-handler JS contract, 11 scientific fixtures, 46/46 site bundles, 46/604/604 indexes, 145 species, offline source, exact checksums, and semantic production health passed; manifest SHA-256 `3fdf334febde34f93f75430bd5ef7daa61cc36f1d6ef7f540578051bee24d3fc`; docs closeout PR #87 merged as `047204e7` and passed post-merge main/semantic/Pages runs `29758617689` / `29758618145` / `29758615636` | pinned package complete; exact physical-event effort, opportunity, detection, exports, limitations, release identities, editorial-screenprint provenance/hashes, shared-frame contract, question-led information architecture, dual-surface Living Poster, and reusable learning recorded | `CONTEXT / NO DRIVER BYTE CHANGE`; physical-event contract parity is closed, but exact current-source Driver join remains held; Cover V5 is suite-platform only and changed no scientific artifact | exact-head CI `29755133857`, main CI `29755368217`, semantic smoke `29755368297`, and Pages `29755366998` passed; Connect #125 published exact `c4c46fce`, resolved `wk 0.9.5` through a full HTTPS CRAN URL, loaded JORN, focused the CTA on the 46-site picker, and preserved species/environmental-driver chart clicks; live desktop/390/320 and responsive seams passed with byte-matched art and zero overflow |
| 2 | Plant Phenology Explorer | PASS 2 + LIVING POSTER REFRESH COMPLETE / PRODUCTION VERIFIED | release head `cc0151d` passed run `29669603912`; core merge/Pages/Connect `29c0ed1`; R 4.5.2, 92 packages, 60 runtime files, Haswell/one thread, five-handler JS contract, expanded scientific fixtures, 46/46 bundles, two-pass null-container normalization, two-build deterministic indexes, offline source, and exact manifest/data equality passed; manifest SHA-256 `cc5e2a464b2c96772c6e2b441b55a4eabb603f36311c08d4342e4ed0f59a5325`; Living Poster PR #5 head `c1bf55d` passed run `29963446292` and merged as `50106f20` | exact plant-year-week opportunity, onset interval/left censoring, desert coverage/leaf-active alternative, within-species cross-site guardrails, release identities, cover provenance, and reusable learning recorded | `HOLD / NO DRIVER BYTE CHANGE`; app-local onset/leaf-active/coverage are trusted candidates, but existing temperature -> green-up adoption must be re-evaluated through an exact registered join | core semantic run `29670192516` and fresh HARV flow passed; poster merge `50106f20` passed main validation `29964265558`, Pages `29964264658`, and production health `29964265433`; live Pages and Connect desktop/390/320 poster checks passed |
| 3 | Plant Diversity | PASS 3 + LIVING POSTER REFRESH COMPLETE / PRODUCTION VERIFIED | core code merge `d6c4862`; PR-head run `29695040575` and master run `29695179837` passed R 4.5.2 / 91 packages / 150 manifest files, Haswell/one thread, registered science and portability fixtures, 46 plant + 46 environment bundles, 34 references, two-build deterministic search/manifest, exact bundle/manifest equality, offline source, and six-handler/mobile contracts; runtime `sha256:0765d895...`; manifest SHA-256 `12ffe349...`; Living Poster PR #11 head `3b9137e` passed run `29963358476` and merged as `dfb44231` | exact nested-grain/current-state/recurrent-panel, Chao2 lower-bound, cover/nativity/reference/source-limit, export, release, responsive, artistic-poster, and reusable-learning package recorded; governance-only closeout PR #10 merged as `8948930` | `CONTEXT / NO DRIVER BYTE CHANGE`; common-grain richness, native/introduced/unknown cover, cross-scale occurrence, reference completeness, and support remain descriptive frozen-family context; richness is not productivity | core production receipt remains exact; poster merge `dfb44231` passed main validation `29963570916`, Pages `29963570413`, and production health `29963570919`; live Pages and Connect desktop/390/320 poster checks passed |
| 4 | Vegetation Structure Explorer | PASS 4 COMPLETE / PRODUCTION VERIFIED | official `DP1.10098.001` `RELEASE-2026`, DOI `10.48443/pypa-qf12`; candidate head `a8ccb56` run `29715249829`; promotion `800bd5e` exact-parent/54-payload ledger proof; core merge `987c102`; intermediate Plotly gate `91a7814`; runtime enhancement `433bbd25`; reset-picker PR #7 head `8389c9c` passed exact run `29722349642` and merged as `0709bd0`; definitive Plotly PR #8 head `06904fe` passed exact run `29723718100` and merged as authoritative runtime `d566b30`; exact R 4.5.2 / 91-package / 68-runtime-file manifest; 42 site bundles; source/science/DQA/parity/export/offline/browser gates passed | exact event/stem/source/mapping identity; opportunity/support states; disjoint tree-DBH and shrub/sapling stem-base cross-section channels; deterministic network/export/release family; 49 events / 4,365 rows / 11 sites held without invented opportunity fields; accessible loading/tour/pins, byte-shared plot export, artistic Living Poster, Selectize reset lifecycle, raw Plotly-event registration gate, and reusable learning published through docs PR #9 / merge `3391e70`; append-only receipt PR #10 head `a606f92` passed run `29725664115` and merged as receipt authority `da466ea` | `HOLD / CONTEXT ONLY / NO DRIVER DATA BYTE CHANGE`; channel-qualified cross-sectional area is slow standing-structure context, never annual productivity, biomass, carbon, or an annual vote | runtime main CI `29724062900`, Pages `29724062095`, and Connect #59 verified exact `d566b30`; docs PR #9 merge `3391e70` passed CI/Pages/Connect #60; receipt merge `da466ea` passed main `29725954423`, Pages `29725953990`, and Connect #61 with byte-identical runtime manifest/search and clean landings/logs |
| 5 | Ground Beetle Tracker | PASS 5 COMPLETE / PRODUCTION VERIFIED | opportunity-complete data PR #14 head `c3dec8d` merged as `4e628f88`; final static-poster PR #15 head `a7950294` merged as `89caa435`; exact R 4.5.2 / 91-package / 112-runtime-file manifest SHA-256 `b3da3599f7601fabd697d592897f2238af02315c286ef829d1ab0715815a9266`; 46 bundles / 100,163 rows / 33,012 opportunity anchors / 67,151 catch rows; effort, zero-catch, taxonomy, detection, QC, cold-bundle, index, handler, cover, and manifest contracts passed | opportunity-complete field-effort grain; individualID expert reconciliation with count conservation; sampled-zero versus invalid/missing effort; detection-frequency and activity-density boundaries; static moss/copper screenprint provenance; release and production identities recorded | `CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE`; the app metric is now opportunity-complete, but it remains a within-site activity-density index and gains no inferential Driver vote without a separately reviewed pinned adapter, measured join/support, and synthesis decision | exact final merge passed CI `30023971987`, Pages `30023970965`, and content-aware Connect/Pages smoke `30023973253`; live Pages desktop/390/320 and Connect first-run/representative site flow passed with no first-party error and identical static art |
| 6 | Mosquito Pulse | PASS 6 COMPLETE / PRODUCTION VERIFIED | official `DP1.10043.001` `RELEASE-2026`; producer/validator run `30207972162`; 47 site bundles / 223,048 combined effort-catch rows / 55,114 valid opportunities / 25,076 supported zeros / 103,887 catch rows / 82,875 held rows; data SHA-256 `2679408c4af5387811f2b3ac12642ea22b962fd996c855eb9216e0545838f3ed`; exact R 4.5.2 / 91-package / 112-file manifest SHA-256 `acef14509ce44347d53a99b252cd92814797df1698b5a4365c9e0ac0724cc4ce`; final runtime `935420e` and receipt `91b4c71` | exact effort identity; continuous `trapHours / 24`; supported-zero, positive, unusable, unknown, and ineligible states; target-taxon and whole-trap expansion gates; activity/population/pathogen/causal claim limits; static poster provenance; runtime lifecycle regression and release receipts recorded | `CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE`; whole-trap-scaled target catch per 24 trap-hours is a within-site activity index, not a population, biting, pathogen, or disease-risk estimate | runtime PRs #3–#5 passed exact-head/main CI, Pages, and semantic production smoke; final merge `935420e` passed CI `30213225754`, Pages `30213225369`, and production smoke `30213225753`; fresh 390/mobile and desktop Pages/Connect QA had zero overflow or Shiny errors and all 19 audited controls at least 44×44 px; docs receipt PR #6 merged as `91b4c71` |
| 7 | Breeding Birds | PASS PENDING | live start passed; 8 manifest file mismatches; one helper test | — | provisional `CONTEXT` | startup only, not a release receipt |
| 8 | Water Chemistry Analyte Viewer | PASS PENDING | live start passed; 3 manifest file mismatches; no executable tests; current code ahead of review prose | — | provisional `CONTEXT` aquatic condition | startup only, not a release receipt |
| 9 | My Little Inverts | PASS PENDING | live start passed; 9 manifest file mismatches; no executable tests; no expert review | — | provisional `CONTEXT` | startup only, not a release receipt |
| 10 | Optional complementary product | decision-support audit COMPLETE; formal decision still after pass 9 | catalog swept against the live NEON Data Product Catalog 2026-07-18 (DPIDs verified; phantom/renamed products flagged) | [`docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](COMPLEMENTARY-APP-GAP-AUDIT.md) — 11 candidates ranked through the 6-question intake + adversarial refutation; 29 dropped with reasons | ranked backlog recorded (see rows below); no build authorized — gate remains passes 1–9 | — |
| 11 | Driver v2 reintegration | blocked on synthesis | — | nine packages + gap decision | integrate accepted set | — |

Pass-4 boundary evidence is deliberately explicit. JORN exports 50 tree contexts:
25 supported `sampled_absence` zeros plus 25 `held_sampling_impractical` contexts;
the UI shows 25 supported plots and no live trees. WOOD is held-only across all 50
contexts (14 source-missing plus 36 opportunity-unknown), with 452 shrub/sapling
rows / 411 live records and zero supported contexts in either physical channel.
These are tests of support-state integrity, not ecological rankings. PR #7 restored
the complete server-backed picker choice family at initialization and reset; live
Connect #58 proved the BART -> Change site -> exact JORN search path, but its server
logs exposed a remaining `baBar` registration warning that clean visible behavior
and a clean browser console had missed. PR #8 then bound the observer to the raw
registered `plotly_click-baBar` input before reading `event_data()`. Connect #59
proved two identical BART clicks, the reset path, the JORN and WOOD boundaries, the
full responsive matrix, a clean 33-entry browser slice, and server logs with only
benign package-built-under-R-4.5.3 warnings.

App-local documentation PR #9 remains documentation authority `3391e70`.
Append-only receipt PR #10 head `a606f92` passed run `29725664115`, merged as
`da466ea`, and passed main `29725954423`, Pages `29725953990`, and Connect #61.
Manifest/search bytes remained identical; fresh Pages/Connect landing smoke and
worker logs were clean apart from two benign package-version warnings. Receipt
publication does not replace authoritative runtime merge `d566b30`.

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
| Small Mammal Tracker | physical-event trap effort, opportunity-complete species CPUE, and detection-qualified consumer context | CONTEXT / NO DRIVER BYTE CHANGE | production Cover V5 merge `c4c46fce` retains the exact six-status, canonical-coordinate, multi-capture, double-trap, placeholder, and fail-closed contracts in pinned R; species denominators use all reviewed opportunity; Compare carries p-hat/mean N-hat and suppresses unsupported raw winners; 49% of 8,200 bouts are single-night/index-only; the shared-frame editorial Living Poster is suite-platform only and changes no ecological evidence | keep current Driver bytes and independent resolver; preserve the app package as descriptive consumer context, not an inferential vote | during suite synthesis, pin an eligible current source and measure exact site-year join/support before considering ingestion; retain monsoon precipitation -> next-year CPUE only as a registered contextual candidate |
| Plant Phenology Explorer | plant-year green-up onset, leaf-active duration, and green-up coverage/support | HOLD / NO BYTE CHANGE | run `29669603912` passed corrected plant x phenophase x year x week opportunity, interval/left censoring, all-suppressed `NULL` trends, multi-flush leaf-active duration, warm-desert coverage, within-species support, deterministic artifacts, exact manifest, and offline source; public HARV flow exposed cadence, coverage, roster, CI, and non-causal limits | keep current Driver bytes and independent adapter; preserve app-local signals as candidates, not a UI-derived Driver vote; retain coverage as support rather than timing | pin the exact eligible site-year source and measure match/missingness/censoring; register temperature/onset model and desert alternative before re-evaluating the existing exploratory family; demote to `CONTEXT` if the inferential gate does not clear |
| Plant Diversity | common-grain 400 m² richness, native/introduced/unknown relative cover, cross-scale occurrence, reference completeness, and explicit support | CONTEXT / NO DRIVER BYTE CHANGE | exact frozen `legacy-partial` 46-site family and release `d6c4862` passed registered current-state/recurrent-panel/grain/nativity/reference contracts plus exact runtime/manifest/public verification; original upstream build, NEON release, cutoff, query receipt, raw digest, and sampled-empty 1 m² opportunity ledger remain unavailable | no Driver artifact change; preserve composition ≠ phenology ≠ slow standing-structure context and richness ≠ productivity; keep the source app and contract linked as descriptive context only | require one complete matching future receipt across all 46 bundles plus `site_index.rds`, an explicit sampled-opportunity ledger, recurrent/common-grain support, and a measured eligible Driver site-year join before reconsidering current-source ingestion |
| Vegetation Structure Explorer | channel-qualified tree-DBH bole cross-section and shrub/sapling stem-base cross-section with exact opportunity/support | HOLD / CONTEXT ONLY / NO DRIVER DATA BYTE CHANGE | official 42-site RELEASE-2026 family preserves source `uid`, `mapping_source_uid`, event-atomic measurements, published opportunity, supported sampled-absence zeros, event-specific positive areas, physical-channel support, and plot-level uncertainty; 49 measurement-only events / 4,365 rows / 11 sites remain explicit held context and contribute no invented absence, effort, area, or denominator; JORN proves supported-zero/held separation and WOOD remains held-only; app-local gates 1–7 and production verification are satisfied | keep all Driver data bytes unchanged; retain only the method/design lesson and source-app link; retire productivity-as-floor language in favor of channel-qualified slow standing-structure context and never create an annual or causal vote | gate 8 remains: at suite synthesis, reconsider a field only through a separately reviewed Driver adapter/rebuild that pins the exact promoted source, preserves channel/support fields, measures eligible joins, and reproduces old/new parity; keep the existing strict `WOOD` hold until then |
| Ground Beetle Tracker | expert-reconciled Carabidae activity-density, composition, introduced-species context, trend, and exploratory environmental scan | CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE | release `89caa435` emits 33,012 independent sampled opportunity anchors across 46 bundles, including zero-Carabidae bouts; fixtures cover duplicate/conflicting/missing effort, all-zero sites, individualID expert override, count conservation, coarse-ID exclusion, and cold-load/index/manifest parity; exact CI/Pages/semantic production receipts passed | keep Driver artifacts unchanged; preserve the opportunity/event resolver lesson and companion context, but do not create an inferential vote from the app result | at suite synthesis, pin the exact released source, implement an independent Driver adapter, measure eligible site-month/year join and support, pre-register any seasonal mechanism, and require old/new parity before reconsidering ingestion |
| Mosquito Pulse | whole-trap-scaled target catch per 24 trap-hours with explicit opportunity and outcome states | CONTEXT / HOLD DRIVER INGESTION / NO DRIVER BYTE CHANGE | official RELEASE-2026 family on runtime `935420e` reconciles 55,114 valid opportunities, including 25,076 supported zeros, independently of nullable `sampleID`; effort keys prefer `uid` and otherwise require a complete physical-event composite; invalid/conflicting expansion and unknown/ineligible opportunity remain held; total-versus-species, all-zero, pathogen, and claim-limit fixtures pass | keep all Driver artifacts unchanged; adopt the outcome-state reconciliation and real-bundle server-render patterns as suite engineering/science contracts, but create no ecological vote or UI-derived adapter | at suite synthesis, pin `935420e` and receipt `91b4c71`, implement an independent adapter, measure eligible site-season/year join and support, pre-register a seasonal/thermal mechanism, preserve PUUM climate overlay as held, and require old/new parity before considering ingestion |
| Site Explorer prototype (`prototypes/site-explorer/`) | provenance receipt on a derived public surface: stamp the bundle SHA-256, build time, schema and all seven source-product commits into the exported data and render them | NONE (app-local + suite-platform; no ecological change) | The bundle already carried `meta$source_products` with per-product commit SHAs and CI already re-read it; the prototype simply never asked, so every public number said "the committed bundle" without saying which one. Writing the receipt also exposed six wrong or unsourced figures, including a cover statistic normalized to a 1600 m² plot when only 790 m² was surveyed. Driver artifacts rehashed unchanged; see the 2026-07-19 23:11 MST handoff entry | No Driver change. Reusable rule promoted: a derived figure must record its **denominator**, not only its formula; and any surface that publishes a number from a versioned, revised NEON product must name that product's vintage or say `UNKNOWN` with the reason | Reuse the receipt pattern on any sibling surface that renders derived numbers. The prototype's own Plot release tag is unrecoverable (built from a live API query) and is now labelled `UNKNOWN` rather than left silent |

Passes 1–6 are complete and production-verified. Phenology Living Poster merge
`50106f20` and Plant Diversity Living Poster merge `dfb44231` are published with
green validation, Pages, and semantic production checks. Ground Beetle release
authority is `89caa435`: its opportunity-complete science family and static poster
passed exact CI, Pages, Connect/Pages semantic smoke, and responsive live QA. Its
ecological disposition remains contextual and Driver bytes remain unchanged.
Mosquito runtime `935420e` and receipt `91b4c71` likewise close Pass 6 with an
opportunity-complete science family, static poster, real-bundle server lifecycle
gate, and responsive production receipt. Its ecological disposition remains
contextual, PUUM climate overlay remains held, and Driver bytes remain unchanged.
Breeding Birds Pass 7 is the next one-app cycle.

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
