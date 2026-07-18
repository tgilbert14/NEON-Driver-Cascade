# Complementary-app gap audit — should the NEON suite add more apps?

Last updated: 2026-07-18. Scope: **planning / decision-support, documentation-only.** No product,
estimator, artifact, or manifest changed in this session.

This document answers the standing question the suite reserves for **learning-loop pass 10**
(`docs/NEON-SUITE-LEARNING-LOOP.md`): *after the nine product apps, is a complementary app
warranted, and if so which one?* It is the ranked decision-support input for that decision — **not an
authorization to build.** The formal `COMPLEMENT` call remains gated on the nine app passes (all
currently `pending`) and the Driver v2 synthesis, exactly as the learning loop requires. Every
candidate below is pinned to a real NEON data-product ID and run through the suite's own
**6-question intake** (`docs/CASCADE-ROADMAP.md` §5) and honesty framework; the top candidates were
then adversarially refuted before earning a recommendation.

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

**Yes, there is real headroom — but the highest-value next move is mostly *not* a brand-new app.**

1. **Finish what is already staged first.** Two of the nine apps (Water Chemistry, My Little Inverts)
   exist but the Driver does not yet consume them, and **most aquatic candidates are gated behind
   them**. Wiring the staged aquatic pair and completing passes 1–9 unblocks more than any new build.
2. **The one genuinely new acquisition worth prioritising is streamflow / discharge**
   (`DP4.00130.001`) — the sole aquatic *hinge* the entire aquatic axis waits on. Acquire/bundle it;
   but ship the **honest** version (a within-stream, sign-only, anomaly-based exploratory
   flow→invertebrate screen), not the marquee land-vs-water monsoon binomial, which is structurally
   unreachable on arrival (the arid-intermittent stratum reduces to ~1 site, SYCA, under the
   `min_sites = 3` floor).
3. **The one genuinely new terrestrial app worth funding is a biome-conditional producer/ANPP rung**
   (litterfall `DP1.10033.001` + herbaceous clip-harvest `DP1.10023.001`) — the *only* candidate that
   directly repairs the July-2026 "atlas, not cascade" construct demotion on the system that actually
   has data, and the only one that joins natively (no 0/34 cross-system gap).
4. **Everything else is strictly sequenced behind those, or defers to HOLD/CONTEXT.** No candidate
   justifies jumping the nine-pass gate.

## What the suite is today (recap)

Ten apps: the **Driver Cross-Product Response Atlas** (the capstone integrator) plus **nine product
apps**. The Driver consumes **seven** today; the aquatic pair is staged but not integrated.

| # | Product app | DPID | System | Driver-consumed |
|---:|---|---|---|:---:|
| 1 | Small Mammal Tracker (flagship) | DP1.10072.001 | terrestrial | yes |
| 2 | Plant Diversity | DP1.10058.001 | terrestrial | yes |
| 3 | Plant Phenology Explorer | DP1.10055.001 | terrestrial | yes |
| 4 | Vegetation Structure Explorer | DP1.10098.001 | terrestrial | yes |
| 5 | Ground Beetle Tracker | DP1.10022.001 | terrestrial | yes |
| 6 | Mosquito Pulse | DP1.10043.001 | terrestrial | yes |
| 7 | Breeding Birds | DP1.10003.001 | terrestrial | yes |
| 8 | Water Chemistry Analyte Viewer | DP1.20093.001 (surface-water chem) | aquatic | **staged** |
| 9 | My Little Inverts (aquatic macroinvertebrates) | DP1.20120.001 | aquatic | **staged** |

## The Driver's standing gaps (what a complement would have to close)

1. **No aquatic hinge / the aquatic axis is unwired.** Streamflow/discharge — the named *primary*
   aquatic driver — is bundled nowhere, so `climate → [streamflow / water temperature]` is empty and
   the whole aquatic spine is dead.
2. **No coverage-standardized producer/productivity rung.** Raw plant richness is composition, not
   productivity (it can invert in drylands) and is held `expected_class = 'none'`; the Driver
   currently has **exactly one** vote-eligible rung (`temp → green-up`) and **no** votable producer or
   consumer rung.
3. **No annual production/seed-resource rung and no mediated-path test** — the direct cause of the
   July-2026 demotion from "trophic cascade" to "co-display atlas."
4. **Thin water-limited-site coverage.** 41 temperature-limited vs 5 water-limited sites; JORN and
   YELL have zero testable expected links, so the desert axis is effectively a 1-site (SRER) test that
   gates every desert claim. Climate is also the thinnest layer (annual precip ~74% NA).
5. **No aquatic producer rung** (periphyton — the green-up analog — is unbuilt).
6. **Air temperature stands in for water temperature** on the internal thermal→EPT link.
7. **The desert phenology hinge is thin-to-missing** (green-up scored for only ~0–19% of desert
   plants); it should become biome-conditional (green-up DOY temperate / leaf-active-days desert).

## Ranked candidates

| Tier | Candidate | DPID(s) | Fills gap | Decision | Honest near-term role |
|---|---|---|---|---|---|
| **A1** | Streamflow / discharge | DP4.00130.001 | #1 aquatic hinge | COMPLEMENT (acquire next) | within-stream sign-vote flow→invert; **not** the land-vs-water binomial |
| **A2** | Biome-conditional producer/ANPP rung | DP1.10033.001 + DP1.10023.001 | #2, #3 | COMPLEMENT → ADOPT (grassland rung *iff* ≥3 sites clear n≥6) | the only terrestrial fix for the construct demotion; native join |
| **B1** | Periphyton / seston / phytoplankton | DP1.20166.001 | #5 aquatic producer rung | COMPLEMENT (after discharge) | standing-crop producer series; never "production" |
| **B2** | Surface-water temperature (streams) | DP1.20053.001 | #6 proxy retirement | COMPLEMENT (after discharge/periphyton) | retires air-temp proxy on a *context-only* link |
| **C1** | Ticks (drag-cloth) | DP1.10093.001 | consumer-rung class | COMPLEMENT (conditional; was ADOPT) | best effort denominator, but redundant testable axis |
| **C2** | Fish (electrofishing / netting) | DP1.20107.001 | aquatic top predator | COMPLEMENT (last of the aquatic sequence) | CONTEXT-only 2nd integrator; no climate→fish prior |
| **C3** | Water-quality sonde | DP1.20288.001 | continuous condition tier | CONTEXT | net-new = turbidity + power-control showcase |
| **C4** | Zooplankton | DP1.20219.001 | lake consumer rung | COMPLEMENT / HOLD | fold into a sequenced lake-food-web package |
| **D1** | In-situ meteorology "climate-driver app" | DP1.00002/.00024/.00044/.00098 | (claims driver/join) | **REJECT as a new app** | keep the labeled domain proxy + a dated VPD HOLD prior instead |
| **D2** | Soil moisture + soil temperature | DP1.00094.001 + DP1.00041.001 | (claims desert driver) | **HOLD** | sharpens a driver for a test that does not exist yet |
| **D3** | AOP greenness (NDVI/EVI/LAI/fPAR) | DP3.30026 / .30012 / .30014 | (claims productivity rung) | CONTEXT descriptor; framing **REJECT** | flight cadence caps n below the gate permanently |

### Tier A — acquire next (each restores a whole rung or unwires an axis)

**A1 · Streamflow / continuous discharge — `DP4.00130.001` — COMPLEMENT (acquire).**
The single non-redundant *primary* aquatic driver (water temperature is thermal, periphyton is the
producer rung, fish is the predator rung — none is the hydrologic hinge). It flips the currently-HELD
flow prior ("a monsoon rain is not the resulting hydrograph") into a registered, dated, testable
exploratory link and stands up a stream-stratum flow→invertebrate sub-cascade at the ~24–28 gauged
stream sites that overlap the staged invert/chem panel.
- **Adversarial deflation to respect:** the marquee "first cross-system headline" (monsoon
  land-vs-water lag, SYCA the test bed) is **structurally unreachable on arrival** — the
  arid-intermittent stream stratum reduces to ~1 site, which reads k=1/1, p=0.500 under the hard
  `min_sites = 3` floor and must be split out of any pooled rank. Discharge bundled today unblocks
  nothing that can *vote* today; two of its three unlock gates (a climate proxy for the 0/34 join, and
  the un-consumed inverts app) lie outside discharge's control.
- **Honest version:** build `ann_flow(site)` returning a per-site-year flow metric **and** its
  within-site anomaly (never cross-site magnitude); register+date `flow → inv_density` as EXPLORATORY,
  `stratum_class = stream`; present only a within-stream sign-vote pooled across gauged streams once
  ≥3 sites carry ≥6 overlapping years; show any land-vs-water comparison strictly as a **side-by-side
  of two independently pooled results**, never a merged binomial; keep the SYCA monsoon link visible
  but `poolable = FALSE` until it independently clears the floor.
- **Required next evidence:** ≥3 gauged (ideally arid-intermittent) stream sites each with ≥6
  overlapping discharge-and-invert site-years — the artifact not yet produced.

**A2 · Biome-conditional annual ANPP / seed rung — Litterfall & fine woody debris `DP1.10033.001`
+ Herbaceous clip-harvest `DP1.10023.001` — COMPLEMENT → ADOPT (grassland rung only).**
The only terrestrial candidate, and the only one that closes **two** gaps behind the construct
demotion at once: it supplies a coverage-standardized producer rung and the missing annual
production/seed-resource signal. Both products are true annual **mass fluxes** (mass/area/yr), not
composition or a slow stock; litterfall isolates a Flowers+Seeds functional-group mass — the single
most direct NEON observation of the stored seed crop the monsoon→rodent lag-1 mechanism invokes. It
**joins natively** on site+year+domain (no 0/34 gap, no proxy driver) — a real inferential advantage
the aquatic complements structurally cannot match. Its grassland `precip → herbaceous-ANPP` prior
(+ / lag 0 / growing season; Sala 1988, Knapp & Smith 2001, Huxman 2004, Del Grosso 2008) is the most
defensible producer prior available to the suite.
- **Adversarial deflation to respect:** the whole distinguishing payoff is a **single, floor-fragile**
  vote-eligible rung. Clip-harvest only began ~2016–2019 and the mammal-panel overlap is 3–11
  site-years; if fewer than 3 grassland sites clear n≥6 simultaneously, the rung is `poolable = FALSE`
  and the app collapses to descriptive producer context.
- **Honest version:** ship clip-harvest **first**, publish the biome/stratum-partitioned measured
  site-year match rate against the 46-site key, register+date the `precip → herbaceous-ANPP` prior and
  evaluate it only on held-out years. **Flip to ADOPT only if ≥3 temperate-grassland sites clear
  n≥6.** Litterfall Flowers+Seeds ships as **descriptive forest context with no registered prior**
  (no stratum-general masting prior; forest-only, ~33 sites — structurally absent at the desert sites
  where the seed mechanism is most load-bearing, which is a *data* gap, not a wiring gap). Pool by
  SIGN within biome/stratum; **never** merge trap-caught litterfall vs clipped-biomass magnitudes.
  **Permanently strike:** "first mediated-path test", the desert seed mediator, any SEM/mediation on a
  handful of annual points, and any chaining of the two products into one signal.

### Tier B — sequenced aquatic rungs (build in bottom-up order, after A1)

**B1 · Periphyton, seston & phytoplankton — `DP1.20166.001` — COMPLEMENT (after discharge).**
The aquatic producer rung (the green-up analog), explicitly recommended *before* fish so the
bottom-up axis completes its producer rung first. The grazer–periphyton link is one of the
best-supported in aquatic ecology (Feminella & Hawkins 1995; Hillebrand 2009); the internal 34/34 join
to the SWC/invert panel is clean.
- **Deflation:** wired to nothing until discharge lands and Water Chem + inverts are consumed —
  building it first is a middle rung with no floor and no ceiling. Per-site n will mostly be 3–5
  (exploratory/no-p); pooling is mandatory across ≥3 stream sites.
- **Honest version:** explicit benthic-vs-pelagic split; register ONE guild-matched prior only
  (benthic standing crop → scraper/grazer density, +, lag 0, growing season, stream); label it
  **standing-crop, never "production"**; never vote on `inv_density`/`%EPT`; never pool lake pelagic
  against streams; never compare chl-a magnitude across sites.

**B2 · Surface-water temperature (streams) — `DP1.20053.001` — COMPLEMENT (after discharge/periphyton).**
Retires the air-temp→water-temp proxy on the existing internal `waterTemp → inv_pct_ept` stream link —
a genuine, non-fabricated honesty upgrade (the continuous PRT sensor *is* the thermal regime, not
another proxy).
- **Deflation (why it ranks lowest of the aquatic acquisitions):** the link it upgrades is
  `expected_class = 'none'` (context-only after the 2026-07 audit), so improving the *driver* does not
  make it *vote*; it adds neither a rung nor an axis unlock, only a better label. Watch
  double-counting against the SWC grab `waterTemp` already bundled.
- **Honest version:** streams only (`DP1.20054.001` lakes/rivers are CONTEXT and must never vote the
  stream EPT prior); designate the continuous sensor as the single authoritative `waterTemp` signal;
  swap the driver with sign/lag/season BUILD-LOCKED and EXPLORATORY (no re-tuning); score on the
  within-site anomaly only; gate the annual mean behind a sensor coverage/QC screen; keep the link
  context-only until a published match rate shows ≥3 stream sites with ≥6 coverage-cleared years.

### Tier C — genuine but redundant or strictly-downstream (defer; conditional)

**C1 · Ticks (drag-cloth) — `DP1.10093.001` — COMPLEMENT (conditional; revised down from ADOPT).**
The one genuine merit maps to a named gap: the drag-**area** denominator is a valid all-event effort
measure with effort-complete detection — materially better than beetle's outcome-conditioned
catch-only denominator and mosquito's whole-year window (the exact defects that keep both at
`expected_class = 'none'`). So ticks are the most plausible route to a *vote-eligible consumer rung*.
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

**C2 · Fish (electrofishing / netting) — `DP1.20107.001` — COMPLEMENT (last of the aquatic sequence).**
A genuine, non-fabricated trophic level (aquatic top predator) and an independent second aquatic
integrator whose sign-match with inverts would reduce the chance the invert signal is a method
artifact.
- **Deflation:** quadruply contingent — it cannot be built until discharge, water temp, and periphyton
  land; cannot vote (three-pass depletion + net-night is the beetle outcome-conditioned-denominator
  problem → CONTEXT-only); cannot post a prior (climate→fish is mediated/undefined → post no prior);
  and cannot deliver its land-vs-water top-consumer headline (cross-system merge forbidden). The
  roadmap ranks it #4/last of Phase 3.
- **Honest version:** build last; sign-only within-site CPUE trend, stream/lake split and never merged,
  CONTEXT-only until an effort audit proves an all-effort denominator; **never stage the phantom
  `DP1.20108.001`** (per-pass depletion lives inside `DP1.20107.001`).

**C3 · Water-quality multiparameter sonde — `DP1.20288.001` — CONTEXT.**
Earns a slot only as a continuous descriptive **companion** to Water Chemistry.
- **Deflation:** three of its four uncensored channels (specific conductance, DO, water temp) already
  exist in the staged Water Chem condition tier, so on those it adds cadence, not information; its
  advertised "retires the air-temp proxy" is contradicted by the existing grab `waterTemp` and by the
  cheaper single-purpose `DP1.20053`.
- **Honest version:** bundle as a continuous descriptive companion whose only unique contributions are
  **net-new turbidity** (Wood & Armitage 1997 sedimentation→EPT) and the **continuous-cadence
  power-control showcase** (n in the hundreds — the first place the honesty chrome runs where power is
  not the limiter). Coverage/uptime-gated site-year means, autocorrelation-honest, never
  sub-daily-as-independent; chlorophyll stays HELD as uncalibrated RFU (never the periphyton rung); no
  condition/impairment CALL.

**C4 · Zooplankton — `DP1.20219.001` — COMPLEMENT / HOLD.**
The lake analog of stream macroinvertebrates — a lake secondary-consumer rung the aquatic axis lacks.
- **Deflation:** orphaned on arrival — both its priors (phyto→zoop +, fish→zoop −) require neighboring
  lake rungs that do not exist (no lake phytoplankton producer, no lake fish predator built). 7 lakes
  risks the `min_sites = 3` floor after the n≥6 gate; lakes are EPT-poor and never pool against
  streams.
- **Honest version:** do not build as a standalone acquisition; fold into a single sequenced
  lake-food-web package (phytoplankton → zooplankton → fish) so it is never an isolated orphan. Ship
  strictly as a lentic descriptive context index, `poolable = FALSE`, until ≥3 lakes carry ≥6 years of
  both zooplankton and a co-located lake producer.

### Defer / not a new app (did not survive as a near-term pursuit — reasons preserved)

**D1 · In-situ meteorology "climate-driver app" — `DP1.00002/.00024/.00044/.00098` — REJECT the app framing.**
Rejected *as pitched* (a distinct new app claiming a dual terrestrial+aquatic unlock). The terrestrial
climate root already exists (borrowed Daymet/tower overlay; `temp → green-up` is the existing ADOPT).
The "dual unlock" is factually wrong: it conflates two NEON instrument families — the listed TIS
`DP1.000xx` products vs the aquatic AIS `DP1.200xx` family — and the 0/34 site-code overlap is
confirmed, so the only honest aquatic bridge remains a labeled domain proxy (which the roadmap already
gets for free, no new app). Adding met DPIDs creates zero non-NA site-years, so the desert axis stays
a 1-site test; net new vote-eligible rungs today = zero.
- **What survives without a new app:** (i) register+date a `VPD → moisture-stress` HOLD prior
  (negative, water-limited stratum) and let it ride; (ii) keep the labeled domain-level climate proxy
  for aquatic sites as descriptive corroboration only. **Preserve the reason:** the TIS-vs-AIS
  conflation is the forbidden silent-keying move — do not re-propose it.

**D2 · Soil moisture + soil temperature — `DP1.00094.001` + `DP1.00041.001` — HOLD.**
Attractive as a direct plant-available-water driver at the desert-thin sites, but it **sharpens a
driver for a test that does not exist**: the binding constraints are on the *response* side (no
coverage-standardized desert producer/phenology rung) and on *site count* (the water-limited stratum
is effectively SRER-only, under the floor). It also breaks the load-bearing "borrowed overlays, no
refetch" architecture. It flips to ADOPT only when a single package arrives: a coverage-standardized
desert response rung at ≥3 water-limited sites with ≥6 overlapping soil-sensor site-years **plus** a
pre-registered dated prior. (`DP1.00094.001` is water content + salinity — NEON publishes no
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

1. **Do not open a new app build yet.** Honor the learning-loop gate: complete passes 1–9 and wire the
   already-staged aquatic pair (Water Chem, inverts) into the Driver first. That unblocks more than any
   new build and is the prerequisite for the aquatic candidates.
2. **Rank the pass-10 acquisition list as: A1 discharge → A2 producer/ANPP rung → B1 periphyton → B2
   water temperature → then C-tier.** Discharge and the producer/ANPP rung are the two genuinely new
   builds that pay for themselves; the rest are sequenced or conditional.
3. **When each is built, ship the honest version only** — the flow within-stream sign-vote (not the
   land-vs-water binomial), the grassland ANPP rung gated on ≥3 sites at n≥6, periphyton as
   standing-crop, water temp as a within-site anomaly on a context-only link. Register and date every
   new prior before examining held-out years.
4. **Keep the D-tier ideas on the backlog with their reasons intact** so a future session neither
   re-proposes the TIS-vs-AIS silent-keying join, nor treats AOP greenness magnitude as a productivity
   rung, nor builds a driver (soil moisture) ahead of the response test it would feed.

Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with NEON/Battelle/NSF.
