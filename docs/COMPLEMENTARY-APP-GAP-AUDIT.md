# Complementary-app gap audit — should the NEON suite add more apps?

Last updated: 2026-08-05. Scope: **formal decision support plus a pre-payload F0
candidate frozen for review.** No product, estimator, Driver data artifact, or
manifest changed in this decision.

This document answers the standing question the suite reserves for **learning-loop pass 10**
(`docs/NEON-SUITE-LEARNING-LOOP.md`): *after the nine product apps, is a complementary app
warranted, and if so which one?* It is the ranked decision-support input for that decision — **not an
authorization to build.** The nine app passes are complete; this revision records the resulting
formal `DEFER BUILD / ACQUIRE EVIDENCE` decision for Driver v2. Every candidate below is pinned to a
real NEON data-product ID and run through the suite's own
**6-question intake** (`docs/CASCADE-ROADMAP.md` §5) and honesty framework; the top candidates were
then adversarially refuted before earning a recommendation. Passes 1–9 are now complete and
production-verified, so the former planning gate has been resolved.

## Formal pass-10 decision — 2026-08-04

**DEFER every new complementary-app build. AUTHORIZE evidence acquisition only.** The two leading
ideas remain useful, but neither has an exact pinned candidate bundle or a measured eligible
candidate-to-response intersection. A catalog roster, calendar overlap, direct site-code mismatch,
or domain-year proxy is not an eligible ecological join.

That program decision does not skip the staged authorities. Current authorization
stops at the F0 candidate; F1 is unauthorized until a follow-up receipt proves the
exact reviewed F0 merge and Pages publication.

1. Acquire a pinned Continuous Discharge `DP4.00130.001` source bundle first. Intersect its exact
   QC-cleared `site x year` support with the released Inverts density-eligible stream panel. Reopen
   independent review—not an automatic build—only if at least three recorded-stream sites each have
   at least six common years.
2. Acquire a pinned Herbaceous Clip Harvest `DP1.10023.001` source bundle second. Intersect its exact
   coverage-cleared site-years with the current Driver precipitation grid. Reopen a build or signal
   decision only if at least three temperate-grassland sites each have at least six common years.
3. Keep Litterfall `DP1.10033.001` as prospective descriptive forest context. It neither authorizes
   an app by itself nor supplies a combined clip+litter signal or a seed mediator.

The response-side capacity is promising but insufficient for authorization. Inverts contains 210
density-eligible stream site-years at 24 stream sites; 23 sites have at least six eligible years.
On the terrestrial side, only CLBJ, CPER, KONZ, SJER, and WOOD currently have at least six finite
Driver precipitation years. Candidate-side common support is still unmeasured in both cases.

### Discharge Gate F0 — candidate frozen for review before payload access

The effect-blind [Discharge feasibility specification](DISCHARGE-FEASIBILITY-SPEC.md),
pure reducer, synthetic fixtures, and
[committed response ledger](receipts/discharge-inverts-response-site-years.tsv)
form the F0 candidate. The ledger's exact Git blob is
`c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8` and its SHA-256 is
`79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296`.
It freezes the already-completed pass-10/manual projection from exact Inverts
commit `ff23e994...` and `data/sites` tree `080534ca...`. That earlier projection
necessarily deserialized the monolithic bundles, but selected only the four
opportunity fields and never indexed, aggregated, or logged density, count,
taxonomy, or other outcomes. Repeating that derivation is not authorized in F0,
F1, or F2: the committed two-column ledger is now the no-look boundary, and CI
checks only its bytes plus upstream commit/tree metadata, never an Inverts RDS
blob. It contains 210 site-years at 24 stream sites, 23 with `n >= 6`.
The discharge authority is exact `DP4.00130.001` `RELEASE-2026`, DOI `10.48443/4n6c-gc44`.

The primary cell is deliberately narrow:
`qc_pass_record_present_in_utc_year` means that an exact Inverts stream site and UTC calendar year
contains at least one unique, finite, table-appropriate released discharge record that passes the
frozen final/science-review and correction-status predicates. It means **record presence only**,
not annual coverage, annualization readiness, flow permanence, or a usable `ann_flow()` metric.
Historical released 1-minute rows may qualify but remain labeled
`historical_uncorrected_1_min_only`; corrected 15-minute rows remain separate.
Ordinary sites cut over at `2021-10-01T00:00:00Z`, BIGC alone at
`2020-10-01T00:00:00Z`; any corrected-before or historical-at/after chronology
fails as `source_regime_chronology_mismatch`. Water-year and corrected-only
summaries are non-rescuing sensitivities. TOMB is rejected before main-table QC,
and TOOK is outside the primary gate until its inflow/outflow `namedLocation`
ambiguity has an exact crosswalk.

The final primary receipt is left-anchored to all 210 response keys and retains
`siteID`, `utc_calendar_year`, `discharge_site_year_present`,
`qc_pass_record_present_in_utc_year`, and `source_regime`, including every
explicit `FALSE`. `namedLocation` is permitted only as source identity. Total
projection/exclusion receipts include zero-count states. Machine token
`REOPEN_REVIEW` maps to human disposition `REOPEN INDEPENDENT REVIEW`; `HOLD`
maps to `HOLD / DO NOT BUILD`.

The same reopening floor remains: at least three unambiguous exact stream sites
with at least six common primary years. Clearing it reopens **review**, not a
build. F0 is not yet passed or published, so F1 remains unauthorized until the
follow-up exact merge/Pages receipt. Once separately authorized, F1 may inspect
only the authenticated values-free availability/file manifest and the reviewed
non-observation schema-metadata allowlist; Gate F2 alone may inspect the
registered payload columns. No stage may compute a
discharge summary, response magnitude, association, effect, prior, vote, or
Driver artifact.

## How this was produced

- **Grounded against the live NEON catalog.** Candidates were drawn from a full sweep of the NEON
  Data Product Catalog (aquatics, terrestrial fauna/disease, producers/biogeochemistry,
  atmosphere/flux, and AOP remote sensing), not from memory. DPIDs were verified against the catalog;
  the corrections that surfaced are recorded in the appendix (e.g. `DP1.20108.001` is a phantom;
  `DP1.00044.001` is now primary precipitation; NEON publishes no root-ingrowth product and does not
  band birds).
- **Filtered by the suite's own rules.** A candidate that violates the honesty framework
  (n-gate, sign-only pooling of indices, within-system+stratum pooling, `min_sites = 3` floor, no
  censored-analyte votes, no cross-site magnitude, priors-not-dredge, "condition trend not condition
  call", proxy labeling) is not shortlisted, or is shortlisted only with the forbidden headline
  struck.
- **Adversarially verified.** Each shortlisted candidate was attacked on five axes — redundancy, join
  keys, honesty-forbidden headline, real integration payoff, and data availability — and kept only
  with the over-claims removed. The "honest version" lines below are what survived that attack.

> **Note on priority numbers.** The two evaluation stages used inconsistent 1-vs-5 priority scales, so
> the ranking here is derived from the *substance* of the refutations, not the raw integers. Tiers
> below are ordered best-first within a consistent P1 = highest scale.

## Bottom line

**There is real headroom, but no new app clears the build gate today.**

1. **The existing nine-app passes are complete.** Water Chemistry and My Little Inverts are released
   and production-verified, but neither is Driver-integrated. Their exact aquatic site codes have no
   direct match to the Driver's terrestrial site roster; that is a structural system split, not a
   zero-valued ecological result.
2. **Discharge is the first feasibility acquisition**, not an authorized app. It is the most useful
   prospective aquatic hinge, but a pinned discharge bundle and exact discharge×Inverts support
   table do not yet exist.
3. **Clip harvest is the second feasibility acquisition**, not an authorized ANPP rung. The current
   Driver has only five grassland sites with at least six finite precipitation years, and the exact
   candidate-side intersection is unknown. Litterfall stays separate descriptive forest context.
4. **Everything else remains sequenced, contextual, held, or rejected.** For Discharge, a measured
   common-support artifact may reopen only independent review, never a build; any later build needs
   separate authority. Product names and catalog site counts never reopen either gate.

## What the suite is today (recap)

Ten apps: the **Driver Cross-Product Response Atlas** (the capstone integrator) plus **nine product
apps**. The Driver consumes **seven older pinned families** today; the aquatic pair is released and
production-verified but not integrated.

| # | Product app | DPID | System | Driver-consumed |
|---:|---|---|---|:---:|
| 1 | Small Mammal Tracker (flagship) | DP1.10072.001 | terrestrial | yes |
| 2 | Plant Diversity | DP1.10058.001 | terrestrial | yes |
| 3 | Plant Phenology Explorer | DP1.10055.001 | terrestrial | yes |
| 4 | Vegetation Structure Explorer | DP1.10098.001 | terrestrial | yes |
| 5 | Ground Beetle Tracker | DP1.10022.001 | terrestrial | yes |
| 6 | Mosquito Pulse | DP1.10043.001 | terrestrial | yes |
| 7 | Breeding Birds | DP1.10003.001 | terrestrial | yes |
| 8 | Water Chemistry Analyte Viewer | DP1.20093.001 (surface-water chem) | aquatic | **no — released** |
| 9 | My Little Inverts (aquatic macroinvertebrates) | DP1.20120.001 | aquatic | **no — released** |

## The Driver's standing gaps (what a complement would have to close)

1. **No aquatic hinge / the aquatic axis is unwired.** Streamflow/discharge — the named *primary*
   aquatic driver — is bundled nowhere, so `climate → [streamflow / water temperature]` is empty and
   the whole aquatic spine is dead.
2. **No coverage-standardized producer/productivity rung.** Raw plant richness is composition, not
   productivity (it can invert in drylands) and is held `expected_class = 'none'`; the Driver
   currently has one biological vote-eligible family represented by two registered screens
   (`annual temperature → green-up` and `spring temperature → green-up`) and **no** votable producer
   or consumer rung. Those legacy screens remain published v1 evidence, not automatic v2 adoption.
3. **No annual production/seed-resource rung and no mediated-path test** — the direct cause of the
   July-2026 demotion from "trophic cascade" to "co-display atlas."
4. **Thin water-limited-site coverage.** 41 temperature-limited vs 5 water-limited sites; JORN and
   YELL have zero testable expected links, so the desert axis is effectively a 1-site (SRER) test that
   gates every desert claim. Climate is also the thinnest layer: annual precipitation is missing in
   402 of 510 current Driver site-years (78.82%).
5. **No aquatic producer rung** (periphyton — the green-up analog — is unbuilt).
6. **Air temperature stands in for water temperature** on the internal thermal→EPT link.
7. **The desert phenology hinge is thin-to-missing** (green-up scored for only ~0–19% of desert
   plants); it should become biome-conditional (green-up DOY temperate / leaf-active-days desert).

## Ranked candidates

| Tier | Candidate | DPID(s) | Fills gap | Decision | Honest near-term role |
|---|---|---|---|---|---|
| **A1** | Streamflow / discharge | DP4.00130.001 | #1 aquatic hinge | **DEFER BUILD / ACQUIRE EVIDENCE** | measure the pinned discharge×Inverts join before any app or vote |
| **A2** | Herbaceous clip harvest; litterfall separate | DP1.10023.001; DP1.10033.001 | #2, #3 | **DEFER BUILD / ACQUIRE CLIP EVIDENCE** | measure clip×precipitation support; keep litterfall descriptive |
| **B1** | Periphyton / seston / phytoplankton | DP1.20166.001 | #5 aquatic producer rung | **HOLD / CONDITIONAL BACKLOG** | standing-crop concept only; no build or measured candidate join |
| **B2** | Surface-water temperature (streams) | DP1.20053.001 | #6 proxy retirement | **HOLD / CONDITIONAL BACKLOG** | possible future proxy correction on a context-only link |
| **C1** | Ticks (drag-cloth) | DP1.10093.001 | consumer-rung class | **HOLD / LOW PRIORITY** | useful effort design, but redundant testable axis |
| **C2** | Fish (electrofishing / netting) | DP1.20107.001 | aquatic top predator | **HOLD / DOWNSTREAM BACKLOG** | no build, eligible denominator, or climate→fish prior |
| **C3** | Water-quality sonde | DP1.20288.001 | continuous condition tier | **CONTEXT / NO BUILD** | prospective turbidity/cadence context only |
| **C4** | Zooplankton | DP1.20219.001 | lake consumer rung | **HOLD / NO BUILD** | orphaned until a separately justified lake package exists |
| **D1** | In-situ meteorology "climate-driver app" | DP1.00002/.00024/.00044/.00098 | (claims driver/join) | **REJECT as a new app** | keep the labeled domain proxy + a dated VPD HOLD prior instead |
| **D2** | Soil moisture + soil temperature | DP1.00094.001 + DP1.00041.001 | (claims desert driver) | **HOLD** | sharpens a driver for a test that does not exist yet |
| **D3** | AOP greenness (NDVI/EVI/LAI/fPAR) | DP3.30026 / .30012 / .30014 | (claims productivity rung) | CONTEXT descriptor; framing **REJECT** | flight cadence caps n below the gate permanently |

### Tier A — feasibility acquisition order (no build authorized)

**A1 · Streamflow / continuous discharge — `DP4.00130.001` — DEFER BUILD / ACQUIRE EVIDENCE.**
The single non-redundant *primary* aquatic driver (water temperature is thermal, periphyton is the
producer rung, fish is the predator rung — none is the hydrologic hinge). It flips the currently-HELD
flow prior ("a monsoon rain is not the resulting hydrograph") into a candidate registered, dated,
testable exploratory link. The released Inverts response side has 24 recorded-stream sites, but no
pinned discharge bundle has been intersected with them; a 24–28-site discharge overlap was an
unmeasured planning estimate and is withdrawn.
- **Adversarial deflation to respect:** the marquee "first cross-system headline" (monsoon
  land-vs-water lag, SYCA the test bed) is **structurally unreachable on arrival** — the
  arid-intermittent stream stratum reduces to ~1 site, which reads k=1/1, p=0.500 under the hard
  `min_sites = 3` floor and must be split out of any pooled rank. Discharge bundled today unblocks
  nothing that can *vote* today; the remaining gates—a true aquatic integration key, a registered
  bridge, and an independently eligible Inverts response—lie outside discharge alone. A domain or
  climate proxy cannot repair the missing site-key join.
- **Conditional honest design, not current authorization:** if the measured acquisition clears the
  reopening floor and a later decision authorizes implementation, a future `ann_flow(site)` would
  return a per-site-year flow metric **and** its within-site anomaly (never cross-site magnitude);
  only then register+date `flow → inv_density` as EXPLORATORY, `stratum_class = stream`; present only
  a within-stream sign-vote pooled across gauged streams once
  ≥3 sites carry ≥6 overlapping years; show any land-vs-water comparison strictly as a **side-by-side
  of two independently pooled results**, never a merged binomial; keep the SYCA monsoon link visible
  but `poolable = FALSE` until it independently clears the floor.
- **Required next evidence:** ≥3 gauged (ideally arid-intermittent) stream sites each with ≥6
  overlapping discharge-and-invert site-years — the artifact not yet produced.

**A2 · Herbaceous clip harvest `DP1.10023.001`; litterfall `DP1.10033.001` kept separate — DEFER
BUILD / ACQUIRE CLIP EVIDENCE.**
Clip harvest is the leading terrestrial feasibility candidate because it may support a registered
grassland precipitation→herbaceous-production screen. That is a hypothesis to test against exact
coverage, not a pre-authorized Driver rung. No pinned clip bundle or candidate-side support table is
available locally, so native key compatibility does not establish an eligible join. Litterfall is a
different forest measurement and remains descriptive context; the suite does not combine the two
products into one ANPP or seed signal.
- **Adversarial deflation to respect:** the whole distinguishing payoff is a **single, floor-fragile**
  vote-eligible rung. The earlier 3–11-year overlap was a catalog/roadmap estimate, not a measured
  common-support artifact. Only five current Driver grassland sites clear six finite precipitation
  years; if fewer than three also clear the clip-harvest coverage gate, the candidate is not
  poolable and remains descriptive producer context.
- **Conditional honest design, not current authorization:** acquisition publishes the
  biome/stratum-partitioned measured site-year match rate against the 46-site key. Only a later
  reopening decision may authorize an adapter or a registered `precip → herbaceous-ANPP` prior for
  held-out evaluation, and only if ≥3 temperate-grassland sites clear n≥6. Litterfall
  Flowers+Seeds remains prospective **descriptive forest context with no registered prior**
  (no stratum-general masting prior; forest-only, ~33 sites — structurally absent at the desert sites
  where the seed mechanism is most load-bearing, which is a *data* gap, not a wiring gap). Pool by
  SIGN within biome/stratum; **never** merge trap-caught litterfall vs clipped-biomass magnitudes.
  **Permanently strike:** "first mediated-path test", the desert seed mediator, any SEM/mediation on a
  handful of annual points, and any chaining of the two products into one signal.

### Tier B — conditional aquatic backlog (no build authorized)

**B1 · Periphyton, seston & phytoplankton — `DP1.20166.001` — HOLD / CONDITIONAL BACKLOG.**
The aquatic producer rung (the green-up analog), explicitly recommended *before* fish so the
bottom-up axis completes its producer rung first. The grazer–periphyton link is one of the
best-supported in aquatic ecology (Feminella & Hawkins 1995; Hillebrand 2009), but no pinned candidate
bundle or audited candidate×Water/Inverts intersection exists. The earlier "clean 34/34 join" was a
panel assumption, not measured evidence, and is withdrawn.
- **Deflation:** it is wired to nothing, and even a future discharge gate would not automatically
  authorize this separate product. Per-site support, method strata, and exact joins remain
  `UNMEASURED`.
- **Conditional honest design:** if separate acquisition and reopening gates someday pass, keep an
  explicit benthic-vs-pelagic split and consider only ONE pre-registered guild-matched prior
  (benthic standing crop → scraper/grazer density, +, lag 0, growing season, stream); label it
  **standing-crop, never "production"**; never vote on `inv_density`/`%EPT`; never pool lake pelagic
  against streams; never compare chl-a magnitude across sites.

**B2 · Surface-water temperature (streams) — `DP1.20053.001` — HOLD / CONDITIONAL BACKLOG.**
Retires the air-temp→water-temp proxy on the existing internal `waterTemp → inv_pct_ept` stream link —
a genuine, non-fabricated honesty upgrade (the continuous PRT sensor *is* the thermal regime, not
another proxy).
- **Deflation (why it ranks lowest of the aquatic acquisitions):** the link it upgrades is
  `expected_class = 'none'` (context-only after the 2026-07 audit), so improving the *driver* does not
  make it *vote*; it adds neither a rung nor an axis unlock, only a better label. Watch
  double-counting against the SWC grab `waterTemp` already bundled.
- **Conditional honest design:** if separately acquired and authorized, use streams only
  (`DP1.20054.001` lakes/rivers are CONTEXT and must never vote the
  stream EPT prior); designate the continuous sensor as the single authoritative `waterTemp` signal;
  swap the driver with sign/lag/season BUILD-LOCKED and EXPLORATORY (no re-tuning); score on the
  within-site anomaly only; gate the annual mean behind a sensor coverage/QC screen; keep the link
  context-only until a published match rate shows ≥3 stream sites with ≥6 coverage-cleared years.

### Tier C — genuine but redundant or strictly downstream (no build authorized)

**C1 · Ticks (drag-cloth) — `DP1.10093.001` — HOLD / LOW PRIORITY.**
The drag-**area** denominator is a useful all-event effort measure. It no longer fills a unique
opportunity gap: the released Beetle and Mosquito families now both begin from independent physical
opportunity ledgers and preserve supported zeros. Ticks therefore remain a possible distinct
consumer product, not an automatic route to a vote-eligible rung.
- **Deflation:** its one testable axis (temperature) duplicates beetle's `temp_spring` in the same
  temperate stratum; its distinguishing axis (moisture / saturation-deficit) is **unwireable** —
  SIGCOLS carries no humidity/VPD, and precip is a dishonest proxy for questing moisture — so being
  more than a duplicate temperature responder requires a **second** new acquisition. The "clean 46/46
  join" is asserted, not measured (no tick sibling bundle exists yet). Off-target for all three real
  bottlenecks (empty aquatic axis, producer rung, desert stratum).
- **Honest version:** a conditional future acquisition, **not** "buildable now / 46/46 / vote-eligible".
  Before any build, pull real drag records and publish the measured site+year+domain match rate and
  the count of sites with ≥6 overlapping questing-window years; register+date a temperature prior;
  define an area-standardized index computed over the **same questing window** as the driver exposure,
  with an explicit structural-zero/life-stage rule. Decide whether to fund a VPD driver — without it,
  post no moisture prior and accept a redundant temperature responder.

**C2 · Fish (electrofishing / netting) — `DP1.20107.001` — HOLD / DOWNSTREAM BACKLOG.**
A genuine, non-fabricated trophic level (aquatic top predator) and an independent second aquatic
integrator whose sign-match with inverts would reduce the chance the invert signal is a method
artifact.
- **Deflation:** quadruply contingent — it cannot be built until discharge, water temp, and periphyton
  land; cannot vote (three-pass depletion + net-night is the beetle outcome-conditioned-denominator
  problem → CONTEXT-only); cannot post a prior (climate→fish is mediated/undefined → post no prior);
  and cannot deliver its land-vs-water top-consumer headline (cross-system merge forbidden). The
  roadmap ranks it #4/last of Phase 3.
- **Conditional honest design:** if a later decision ever reopens this downstream item, keep a
  sign-only within-site CPUE trend, stream/lake split and never merge them;
  CONTEXT-only until an effort audit proves an all-effort denominator; **never stage the phantom
  `DP1.20108.001`** (per-pass depletion lives inside `DP1.20107.001`).

**C3 · Water-quality multiparameter sonde — `DP1.20288.001` — CONTEXT / NO BUILD.**
Would earn a slot only as a continuous descriptive **companion** to Water Chemistry.
- **Deflation:** three of its four uncensored channels (specific conductance, DO, water temp) already
exist in the released Water Chemistry condition tier, so on those it adds cadence, not information; its
  advertised "retires the air-temp proxy" is contradicted by the existing grab `waterTemp` and by the
  cheaper single-purpose `DP1.20053`.
- **Conditional honest design:** if independently justified later, bundle only as a continuous
  descriptive companion whose unique contributions are
  **net-new turbidity** (Wood & Armitage 1997 sedimentation→EPT) and the **continuous-cadence
  power-control showcase** (n in the hundreds — the first place the honesty chrome runs where power is
  not the limiter). Coverage/uptime-gated site-year means, autocorrelation-honest, never
  sub-daily-as-independent; chlorophyll stays HELD as uncalibrated RFU (never the periphyton rung); no
  condition/impairment CALL.

**C4 · Zooplankton — `DP1.20219.001` — HOLD / NO BUILD.**
The lake analog of stream macroinvertebrates — a lake secondary-consumer rung the aquatic axis lacks.
- **Deflation:** orphaned on arrival — both its priors (phyto→zoop +, fish→zoop −) require neighboring
  lake rungs that do not exist (no lake phytoplankton producer, no lake fish predator built). 7 lakes
  risks the `min_sites = 3` floor after the n≥6 gate; lakes are EPT-poor and never pool against
  streams.
- **Conditional honest design:** no build is authorized. If a separately justified lake-food-web
  package is ever reopened, keep phytoplankton → zooplankton → fish together so this is not an
  isolated orphan, and retain zooplankton as a lentic descriptive context index with
  `poolable = FALSE` until ≥3 lakes carry ≥6 years of both zooplankton and a co-located lake producer.

### Defer / not a new app (did not survive as a near-term pursuit — reasons preserved)

**D1 · In-situ meteorology "climate-driver app" — `DP1.00002/.00024/.00044/.00098` — REJECT the app framing.**
Rejected *as pitched* (a distinct new app claiming a dual terrestrial+aquatic unlock). The terrestrial
climate root already exists (borrowed Daymet/tower overlay); the published v1 `temp → green-up`
screen is HOLD for v2 re-authorization, not an existing v2 ADOPT.
The "dual unlock" is factually wrong: it conflates two NEON instrument families — the listed TIS
`DP1.000xx` products vs the aquatic AIS `DP1.200xx` family — and the 0/34 site-code overlap is
confirmed, so the only honest aquatic bridge remains a labeled domain proxy (which the roadmap already
gets for free, no new app). Adding met DPIDs creates zero non-NA site-years, so the desert axis stays
a 1-site test; net new vote-eligible rungs today = zero.
- **What survives without a new app:** (i) retain a possible `VPD → moisture-stress` hypothesis in
  the backlog without registering or activating a prior in this phase; (ii) keep the labeled
  domain-level climate proxy for aquatic sites as descriptive corroboration only. **Preserve the reason:** the TIS-vs-AIS
  conflation is the forbidden silent-keying move — do not re-propose it.

**D2 · Soil moisture + soil temperature — `DP1.00094.001` + `DP1.00041.001` — HOLD.**
Attractive as a direct plant-available-water driver at the desert-thin sites, but it **sharpens a
driver for a test that does not exist**: the binding constraints are on the *response* side (no
coverage-standardized desert producer/phenology rung) and on *site count* (the water-limited stratum
is effectively SRER-only, under the floor). It also breaks the load-bearing "borrowed overlays, no
refetch" architecture. Reconsider acquisition only if a coverage-standardized desert response rung
first exists at ≥3 water-limited sites with ≥6 overlapping soil-sensor site-years; that evidence
would reopen review rather than guarantee ADOPT. (`DP1.00094.001` is water content + salinity — NEON publishes no
soil-water-potential product; `DP1.00095.001` is Soil CO2.)

**D3 · AOP greenness (NDVI / EVI / LAI / fPAR) — `DP3.30026 / .30012 / .30014` — CONTEXT descriptor; productivity-rung framing REJECT.**
The siteCode overlap is real (its only genuine strength), but the **year grain fails**: a ~3–4-year
flight cadence populates only ~1-in-3/1-in-4 site-years — below the n≥6 gate, permanently, no matter
how long you wait — and annualizing the snapshot manufactures pseudo-resolution (the exact error the
suite avoids by keeping veg basal area off the ladder). Its one distinctive claim ("one radiometric
scale across 47 sites") is the **forbidden cross-site-magnitude** operation, and NDVI's
PFT-dependence + saturation make that magnitude an invalid cross-biome productivity value — the
rejected richness-as-productivity construct in remote-sensing clothing. Usable only if fused with a
dense satellite series (MODIS/Landsat) to reach n≥6 — a different, larger acquisition — and even then
only as a within-site anomaly proxy beside `veg_ba_ha`, never a vote.

## Appendix — considered and dropped (reasons preserved per the learning loop)

The catalog sweep evaluated and dropped 29 further products. Never delete these reasons; they prevent
future sessions from re-hunting dead ends.

- **Eddy-covariance flux bundle `DP4.00200.001` (GPP/NEE).** A rich productivity *driver*, but
  terrestrial-tower-only (no aquatic bridge) and the heaviest processing burden of any met product
  (HDF5). Deferred, not rejected.
- **Lake thermal (`DP1.20264.001`, `DP1.20055.001`), Secchi/depth profiles (`DP1.20252.001`,
  `DP1.20254.001`), dissolved gases (`DP1.20097.001`), SUNA nitrate (`DP1.20033.001`).** Lake-only or
  condition/metabolism variables; redundant with the chosen stream/34-site condition tier.
- **Aquatic macrophyte/algae (`DP1.20066.001`, `DP1.20072.001`), periphyton chemistry
  (`DP1.20163.001`).** Secondary/patchy producer channels; `DP1.20166.001` biomass is the primary
  green-up analog.
- **Riparian cover/structure (`DP1.20191.001`, `DP1.20275.001`), sediment (`DP1.20194.001`,
  `DP1.20197.001`), stream/lake morphology (`DP4.00131.001`, `DP4.00132.001`).** Slow physical-template
  STATE floors on multi-year cadences that break the annual site-year join. `DP1.20197.001` also
  returned an empty siteCodes array in the 2026-07-18 snapshot.
- **Discharge enabling inputs (`DP4.00133.001`, `DP1.20048.001`, `DP1.20193.001`, `DP1.20267.001`,
  `DP1.20016.001`).** Provenance/inputs to the continuous product `DP4.00130.001`, not standalone
  rungs.
- **Disease-as-condition layers:** tick pathogen `DP1.10092.001`, mosquito pathogen `DP1.10041.001`,
  rodent pathogen `DP1.10064.001` (truncated 2014–2019, discontinued 2020), `DP1.10064.002`
  (tick-borne; 2020+ start is series-length-blocked — the most conceptually valuable disease layer,
  held on length). Zero-inflated prevalence on tiny denominators that never clears n≥6.
- **Herpetofauna pitfall bycatch** (no standalone DPID; incidental to `DP1.10022.001`) — no
  standardized detection design, no effort-complete abundance index.
- **DNA barcode products (`DP1.10038.001`, `DP1.10020.001`, `DP1.10076.001`)** — taxonomy/QA support,
  no votable annual signal.
- **Terrestrial producer STATE/quality/belowground:** foliar traits `DP1.10026.001` (quality, not
  flux), field LAI `DP1.10017.001`, coarse downed wood `DP1.10014.001`/`DP1.10010.001` (necromass
  stock), root biomass `DP1.10067.001`/`DP1.10066.001`, soil physical/chemical
  `DP1.10086.001`/`DP1.00096.001`, soil microbe biomass `DP1.10104.001`, soil microbe *community*
  `DP1.10081.001`/.002 (composition-is-not-productivity — repeats the plant-richness REJECT).
- **Secondary met:** triple-aspirated air temp `DP1.00003.001` (redundant with single-aspirated
  `DP1.00002.001`, which also reaches aquatic sites), net radiation `DP1.00023.001` (overlaps PAR),
  2D wind `DP1.00001.001`, barometric pressure `DP1.00004.001`, understory phenology images
  `DP1.00042.001` (images-only; GCC lives in the PhenoCam Network, not this product).
- **AOP:** directional reflectance `DP3.30006.001` (raw cube, not a scalar), orthophoto
  `DP3.30010.001` (visual context), canopy nitrogen `DP3.30018.002` (provisional, sparse), CHM
  `DP3.30015.001` (slow structural state, overlaps Veg Structure).

### DPID corrections captured by the live-catalog check

- `DP1.20108.001` (fish "per-pass") is a **phantom** — the API returns 400 "Product code not found";
  per-pass depletion is inside `DP1.20107.001`. Do not stage it.
- `DP1.00044.001` is the **primary** (weighing-gauge) precipitation product, split out of
  `DP1.00006.001` on 2024-12-23; `DP1.00006.001` is now secondary/throughfall.
- `DP1.00094.001` is soil water content **+ salinity**, not water potential; NEON publishes no
  soil-water-potential product. `DP1.00095.001` is Soil CO2.
- NEON has **no root-ingrowth product** (a mislabeled `DP1.10068.001` does not correspond to one), and
  **does not band or test birds** — only `DP1.10003.001` point counts exist (already wired).

## Recommendation to the owner

1. **Do not open a new app build.** Passes 1–9 are complete; the remaining blocker is measured
   candidate support, not companion release readiness.
2. **Acquire feasibility evidence in this order:** discharge → herbaceous clip harvest → only then
   reconsider periphyton or water temperature. For Discharge, acquisition follows the frozen staged
   sequence: publish F0 and its receipt, inventory only the reviewed F1 non-observation metadata,
   then separately authorize any F2 pinned payload/support artifact. It never means a UI, adapter,
   prior, or vote.
3. **Reopen independent review only at the registered floors:** discharge×Inverts at at least three
   stream sites with at least six common eligible years, or clip×Driver precipitation at at least
   three temperate-grassland sites with at least six common coverage-cleared years. Crossing a floor
   does not authorize a build; any later build requires separate authority. Litterfall stays
   descriptive forest context and is never silently fused with clip harvest.
4. **Keep the D-tier ideas on the backlog with their reasons intact** so a future session neither
   re-proposes the TIS-vs-AIS silent-keying join, nor treats AOP greenness magnitude as a productivity
   rung, nor builds a driver (soil moisture) ahead of the response test it would feed.

Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with NEON/Battelle/NSF.
