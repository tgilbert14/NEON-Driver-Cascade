# Historical Driver Cascade Expansion Roadmap

> **July 2026 construct correction.** The shipped product is now framed as a cross-product response
> atlas, not a demonstrated trophic cascade. Its current annual data do not contain a defensible
> productivity/seed-resource rung or a mediation test. Any future return to “cascade” inference requires
> coverage-standardized producer resources, valid effort-complete consumer responses, registered direct
> links, and an explicit sequential/mediation design. Older “where we are” language below is roadmap
> history, not a description of current inferential capability.

A preserved design-history document for an earlier proposal to grow the app into a multi-system,
multi-product cascade. Drafted 2026-06-23 (Cass synthesis + Cara/Aquatics/Brooke proposals). It is
not a specification, current-status report, or source of current sample counts or results.

How to read this: Sections 1–2 preserve the obsolete June 2026 baseline; their counts, coverage,
methods, and “wired” status must not be cited as current. Sections 3–8 preserve proposed architecture,
build order, add-a-product ideas, feedback loops, caveats, and owner decisions. For current behavior,
use the root README, in-app About panel, downloadable codebook, and versioned bundle lineage.

---

## 1. Obsolete June 2026 baseline (historical; not current behavior)

`scripts/build_cascade.R` assembles a per-site ANNUAL signal table from the sibling bundles and
draws one bottom-up TERRESTRIAL chain:

    climate (precip, temp, + seasonal aggregates precip_winter / precip_monsoon / temp_spring)
      -> green-up onset (the HINGE)
      -> producers (plant_richness, fruiting_pct; veg basal area = slow ~5-yr STATE floor, not a ladder line)
      -> consumers (mammal_cpue/mnka; bird_index = descriptive, no prior; mosq_activity = monsoon lag-0)

The honesty machinery is the point: every driver to response link carries a STATED sign + lag +
season prior from the literature; priors are biome-conditional (water-limited deserts lead with
monsoon/winter rain, temperate with spring temp); a link pools across sites only if it is the same
index measured the same way with a biome-general prior; per-site n is a false-negative regime so we
pool; permutation null + binomial sign test + space-for-time caveats; "computed everywhere, only the
tally respects expected." The suite's one robust pooled rung is temp -> green-up (23/32, p=0.010).

**Wired today:** env + seasonal climate, phenology green-up, plant richness, fruiting, veg basal-area
state, mammal CPUE/MNKA, bird index, mosquito activity.

**NOT wired (the gaps):** Ground Beetle (a ready terrestrial consumer), My Little Inverts and Water
Chemistry (a whole aquatic axis the cascade does not yet touch).

---

## 2. The opportunity

The cascade is a line today. It should be a TREE: one shared climate/season root feeding two
parallel chains. Adding Beetle sharpens the terrestrial consumer layer; adding Inverts + Water Chem
opens a second, aquatic spine that shares the same climate drivers. The marquee question that
unlocks: **does the same monsoon that booms desert rodents at lag 1 also pulse stream inverts, and at
what lag?** That land-vs-water contrast on one driver is the suite's first cross-system comparison.

---

## 3. The two-axis architecture

One shared driver spine, two bottom-up chains:

    SHARED ROOT: climate + seasonal aggregates (already in `annual` from one monthly env overlay)

    TERRESTRIAL AXIS (live):  climate -> green-up (hinge) -> producers -> consumers
       consumers are a RESPONSE-TIME spectrum (the axis's most underused asset):
         mammals  = SLOW demographic responder (monsoon -> rodents, LAG 1, the stored seed crop)
         mosquito = FAST water-limited responder (monsoon -> mosquitoes, LAG 0, within-season)
         beetle   = FAST + BROAD responder (LAG 0 in BOTH biomes: spring-temp where temp limits,
                    monsoon where water limits) -- the one consumer that gives the temperature axis
                    a fast responder to pair with its slow one
         bird     = descriptive, no prior

    AQUATIC AXIS (new):  climate -> [streamflow / water temperature] (hinge, NOT yet bundled)
                                 -> water chemistry (CONDITION tier, not a trophic rung)
                                 -> periphyton (future producer)
                                 -> macroinvertebrates (the consumer/integrator)
                                 -> fish (future top predator)

**Structural design (so the two axes coexist without forking the machinery):** keep ONE `priors`
tibble and ONE `signals` tibble. Add two governing columns: a `system` column (terrestrial/aquatic),
and generalize `expected_class` into `stratum_class` (terrestrial: temperature-limited / water-limited;
aquatic: stream / river / lake + flow-regime). The pooling key (`from|to|lag`) and the sign-test are
unchanged. The one new rule: **`pooled_links()` pools WITHIN `system` + `stratum_class`, never across
systems.** A land-vs-water comparison is a deliberate side-by-side of two separately-pooled results on
a shared driver, never a merged tally (merging land + water votes is the cross-system version of the
cross-site magnitude error we never allow).

**What the design unlocks:** (1) the monsoon land-vs-water lag contrast; (2) a fast-vs-slow consumer
contrast at one terrestrial site the moment Beetle lands; (3) two independent consumer integrators
(land + water) corroborating the same climate years; (4) a power control (water chem has n in the
hundreds vs n=6 terrestrial -- the first place the honesty chrome runs where power is NOT the limiter).

---

## 4. Phased build order

### Phase 0 -- Surface the Mosquito rung you already have (half a day, free)
Mosquito is structurally COMPLETE (ann_mosq, two lag-0 priors, ladder signal, scoreboard tooltip) but
INVISIBLE: its water-limited monsoon prior pools under-floor (1-2 sites, like the desert mammal link),
so it never reaches the headline. Do: (a) verify the pooled table carries the two mosq rows and where
they land; (b) check whether the temp_spring -> mosq_activity prior (TEMPERATURE-limited, ~32-site
potential) is actually pooling across temperate sites -- if it pools, it belongs in the headline beside
temp -> green-up as the second temperature-axis rung; (c) refresh DATA-TAKEAWAYS.md from "five products"
to "six." This proves the consumer-add pattern end-to-end on a rung already in the bundle.

### Phase 1 -- Wire Ground Beetle (the easy win, ~1-2 days, zero new data)
46 beetle sites EXACTLY match the 46 mammal sites, so zero site-union expansion. It mirrors `ann_mosq()`.
- **Extractor** `ann_beet(site)`: read `NEON-Ground-Beetle-Tracker/data/sites/<SITE>.rds`,
  `beet_activity = round(100 * carabid individuals / trapnights, 2)` per `year(collectDate)`
  (= `annual_trend(d)$cpn`; trapnights NA-rate is 0%). **Gotcha:** the beetle .rds carry ALTREP deferred
  strings + a classless-numeric `collectDate` that can 139-segfault a cold builder read -- materialize/
  restore Date inside the extractor and wrap reads in the standard retry.
- **Signal:** add to SIGCOLS + the signals tribble: `beet_activity`, layer=consumer, unit="per 100 TN",
  higher_is="more beetles", ladder=TRUE, system=terrestrial.
- **Two priors (verbatim from the app, server.R seasonal_driver_links lags all 0):**
  - `temp_spring -> beet_activity` | +1 | **lag 0** | spring | conf moderate | temperature-limited.
    Basis: spring degree-days pace larval development + adult emergence (Thiele 1977; Lovei & Sunderland
    1996). The carabid mirror of temp -> green-up.
  - `precip_monsoon -> beet_activity` | +1 | **lag 0** | monsoon | conf moderate | water-limited.
    **CRITICAL: lag 0, deliberately UNLIKE monsoon -> mammal_cpue at lag 1.** Beetles are predators/
    omnivores tracking current-season prey, not a stored seed crop maturing into a next-year boom.
- **Honesty rider:** beet_activity is an activity-density INDEX (movement x density), not abundance --
  pool SIGN only. Carry the is_introduced flag so introduced-dominant sites (STEI/UNDE/WOOD =
  *Pterostichus melanarius*, TREE = *Carabus nemoralis*) read as non-native-driven activity.
- **Payoff:** the fast-vs-slow consumer contrast becomes drawable, and the temperature axis gets its
  first fast responder.

### Phase 2 -- Open the aquatic axis, response-side first (Inverts + Water Chem, ~1 week)
The response side is computable today; the climate driver join is the gap. Build the axis as an INTERNAL
aquatic sub-cascade first (WaterChem -> inverts, sharing all 34 aquatic site codes), then bridge to climate.
- **`ann_inv(site)`** from `App-NEON-My-Little-Inverts/data/sites/<SITE>.rds$bouts` ->
  `site,year,inv_density,inv_pct_ept,inv_hill_q1,inv_ept_richness` as a within-year mean over bouts,
  GATED to >=2 bouts/yr (median ~3/yr makes annual aggregation defensible). Carry samplerType + habitatType.
- **`ann_waterchem(site)`** from `App-NEON-WaterChem-AnalyteViewer/data/neon_swc.rds$swc_long` -> per
  site-year means of the UNCENSORED analytes ONLY (specificConductanceField, ANC, waterTemp,
  dissolvedOxygenField -- all 0% BDL), >=4 grabs/yr gate, implausible-extreme flag applied BEFORE the mean.
- **Signals:** add `system=aquatic` rows; add a NEW layer value `condition` for water chem (parallel to the
  trophic ladder, NOT between producer and consumer). The 34 SWC sites == the 34 invert sites.
- **Internal priors (buildable now, 34/34 join, stream-only, stratum_class=stream):**
  - `waterTemp -> inv_pct_ept` | -1 | lag 0 (EPT are cold/clean-water taxa)
  - `dissolvedOxygen -> inv_pct_ept` | +1 | lag 0
  - `specificConductance -> inv_pct_ept` | -1 | lag 0
  These stay SILENT at lakes (lentic ~6% EPT is the ecosystem, not impairment).
- **Climate-fingerprint prior (chem as RESPONSE, well-powered):**
  `precip_winter -> specificConductance` | -1 (dilution, concentration-discharge theory; verified SYCA
  conductance~ANC r=0.86) | lag 0. The aridity corroborator.
- **The join bridge (the honest part):** aquatic site codes have ZERO overlap with the terrestrial climate
  overlays (0/34 confirmed). Do NOT silently key air-precip to aquatic sites. The honest bridge is
  DOMAIN-LEVEL pairing (match each aquatic site to a co-located terrestrial climate overlay in the same NEON
  domain, LABELED a proxy driver, scored as descriptive corroboration). Wire the monsoon cross-system test
  (`precip_monsoon[domain] -> inv_density`, hypothesis lag 0, arid-intermittent-stream conditional, SYCA the
  test bed) as a HELD / HYPOTHESIS link -- framed testable, not demonstrated -- until real discharge arrives.
- **Payoff:** the two-axis app exists; the marquee monsoon land-vs-water comparison is on screen as an
  explicit hypothesis with the data behind both halves.

### Phase 3 -- Future products (as data arrives)
Priority by what unblocks the most:
1. **Streamflow / discharge (DP4.00130.001)** -- the single highest-value acquisition. The PRIMARY aquatic
   driver (the aquatic hinge); converts the monsoon cross-system test from hypothesis to a real lag estimate.
2. **Water temperature (DP1.20053)** -- replaces the air-temp proxy on the thermal -> EPT link.
3. **Periphyton** -- the aquatic PRODUCER rung (the green-up analog; completes climate -> flow -> periphyton
   -> inverts). Arguably more load-bearing than fish: a bottom-up app should complete its producer rung first.
4. **Fish (electrofishing, e.g. DP1.20107)** -- the aquatic top predator; enables land top-consumer vs water
   top-consumer on shared climate years.

---

## 5. The add-a-product framework (so the suite scales)

### The 6-question intake (answer ALL before writing one line of extractor)
1. **Which system + layer?** terrestrial/aquatic; climate / hinge / condition / producer / consumer. A
   condition layer (water chem) is NOT a trophic rung -- it votes descriptively, like birds.
2. **Index or absolute?** An effort-normalized INDEX (CPUE, activity-density, density_m2) pools by SIGN only,
   with the within-site-index caveat. An ABSOLUTE concentration (mg/L) pools on the within-site ANOMALY
   (z/rank), never raw magnitude. A slow STATE (veg basal area) is per-site context, not a ladder line.
3. **What are the priors?** For EACH: stated SIGN + LAG + SEASON + literature citation + the stratum_class
   where the mechanism is established. The legacy terrestrial family was co-developed while its data were
   inspected and must remain labelled exploratory. For every future addition, register and date the choice
   before examining genuinely held-out observations; never promote a best-fitting lag to confirmatory status.
   If the literature carries no defensible directional prior (green-up -> birds is about SYNCHRONY not
   DOY; green-up -> inverts is undefined), POST NO PRIOR and let the signal ride descriptively. Refusing an
   unsupported prior is a feature.
4. **Poolable, within what stratum?** Three conditions, all required: same thing, same way everywhere, prior
   stratum-general within class. Name the stratum_class. Pool WITHIN a stratum only -- never across systems,
   never across water-types where the assemblage control differs.
5. **n-regime?** <3 no compare; 3-5 exploratory no-p; >=6 permutation + CI + verdict. If per-site n is in the
   false-negative floor (the terrestrial norm), per-site verdicts are dishonest and POOLING IS MANDATORY for
   any headline. If n is large (water chem), it becomes a power-control showcase.
6. **What can it claim vs NOT?** Write the CAN/CANNOT list first. Recurring CANNOTs: not abundance (indices),
   not cross-site magnitude, not productivity (richness inverts), not causation, not a condition/impairment
   CALL (no reference condition at NEON aquatic sites), not a lagged driver from snapshot chemistry.

### The 4 wiring steps (mechanical, identical every time)
- **A. Extractor** -- `ann_<product>(site)` mirroring `ann_mosq()`/`ann_inv()`: read the sibling .rds, key on
  year, return site+year+signals; wrap in retry for the Windows R-4.5.2 segfault; materialize any
  ALTREP/classless-Date columns inside the extractor.
- **B. Signal** -- add row(s) to SIGCOLS + the signals tribble (key/label/layer/unit/higher_is/ladder/system);
  add to `join_all()`'s Filter list.
- **C. Prior** -- add the Q3 rows to the priors tibble (from/to/sign/lag/conf/stratum_class/note); the note is
  plain-English AND carries the scope caveat.
- **D. Placement** -- suite_links/pooled recompute automatically; add the mechanism phrase to the scoreboard
  out-of-prior tooltip switch; confirm pooling within the right stratum and under-floor gating; **regenerate
  manifest.json (or Connect serves stale).**

priors-not-dredge, the n-gate, sign-match-over-magnitude, and "computed everywhere, only the tally respects
expected" are PRODUCT-AGNOSTIC -- a new DPID inherits all four for free. The only per-product judgment is the
6-question intake.

---

## 6. The living science feedback loop (propagate each app's advances)

The cascade must absorb each app's science as it matures. When an app changes HOW it computes a signal (a
better estimator, a biome-conditional metric, an honesty fix), that improvement propagates up into
`build_cascade.R`'s extractor and prior. The checklist when an app's science advances:
1. Did the signal's DEFINITION change? -> update the extractor to compute it the new way.
2. Did it become BIOME/STRATUM-CONDITIONAL? -> make the cascade's extraction conditional too, and split the
   prior if the lead driver swaps.
3. Did the honesty framing change (a new caveat, a demotion)? -> carry it into the prior's note + the export.
4. Re-pool and re-check the headline.

**First entry -- the desert phenology hinge (leaf-active days).** Green-up is scored for only ~0-19% of
plants at desert sites, so the cascade's phenology hinge (`greenup_doy`) is thin-to-missing exactly where the
desert cascade matters most. The Phenology app now surfaces **leaf-active days** as the desert-safe read
(auto-flips when green-up coverage < 50%). So the cascade's phenology hinge should become BIOME-CONDITIONAL:
`greenup_doy` at temperate sites, a **leaf-active-derived signal at desert sites** -- repairing the desert
hinge and mirroring the app's honesty. This is the same shape as the cascade's fundable biome-conditional-
priors idea (temp -> green-up is a temperate prior; deserts swap to rain -> green-up). It is the template for
every future "the desert (or the stream, or the lake) needs a different, honestly-better signal" fix.

---

## 7. Honesty constraints (the line, per axis)

- **Defensible to LEAD with:** temp -> green-up pooled (the one robust rung). Stated-prior, sign-only,
  biome-conditional fast-consumer adds (beetle, mosquito). The internal aquatic chem -> invert links on
  uncensored analytes within streams. Water chem as climate's dilution fingerprint (well-powered).
- **Over-reach (label, never lead with):** the desert monsoon -> rodents r=+0.72 is APPARENT (p=0.060) and
  pools across ONE site -- it illustrates the annual-aggregation artifact, it does NOT establish a desert
  result. Any chem -> invert link on a CENSORED analyte (Br 56% BDL, Mn, Fe, F, Ortho-P, NH4, NO2) is
  hypothesis-generating, NEVER a vote (a non-detect is not zero; Helsel/NADA). The monsoon cross-system lag is
  a HYPOTHESIS until discharge is bundled.
- **Pool WITHIN system + stratum, never across.** Terrestrial: temperature-limited vs water-limited. Aquatic:
  stream / river / lake (lakes are genuinely EPT-poor -- never pool a lake EPT response against streams).
  Indices pool by sign; absolute concentrations pool on the within-site anomaly. The cross-system comparison is
  a SIDE-BY-SIDE of two independently-pooled results, never a merged binomial.
- **Space-for-time** (Damgaard 2019): pooling sign-matches (not values) is the conservative version but still
  assumes a shared mechanism. Aquatic confirms there is NO geographic gradient to pool on (EPT vs latitude
  rho=-0.01) -- the structure is water-type, so pool by water-type, not geography.
- **Label every proxy:** air temp is a PROXY for water temp (cool forested streams only); domain-paired climate
  is a PROXY driver; the flow prior is HELD until discharge is bundled (a monsoon rain is not the resulting
  hydrograph). Inherit the aquatic app's disclaimer: CONDITION TRENDS, never a CONDITION CALL.

---

## 8. Open questions for the owner

1. **Aquatic-terrestrial climate join.** 0/34 site-code overlap. Use domain-level pairing now (labeled a
   proxy driver) for an interim headline, or wait for true aquatic-site climate overlays? *Recommend:* do the
   domain proxy now, explicitly labeled; swap to real aquatic climate when available.
2. **Flow/discharge source.** The PRIMARY aquatic driver is not bundled anywhere. Is DP4.00130.001 the
   acquisition target, and who owns bundling it into a sibling the cascade can read? Highest-value data ask.
   Also pick the water-temperature source (DP1.20053) to retire the air-temp proxy.
3. **Future fish rung?** *Recommend periphyton before fish* -- complete the aquatic PRODUCER rung (the green-up
   analog) before adding a second predator level.
4. **One ladder or split systems in the UI?** *Recommend:* two side-by-side ladders sharing the climate x-axis
   for the domain-paired sites where both axes have data (the comparison's whole point); a system selector
   elsewhere (most sites are single-system given 0/34 overlap).
5. **Mosquito surfacing + the water-limited coverage floor.** Promote temp_spring -> mosq_activity to the
   headline if it pools across temperate sites. And the standing bottleneck: the water-limited stratum is a
   1-2-site test almost everywhere (JORN + YELL have zero testable expected links) -- is acquiring more
   water-limited site or seasonal-climate coverage a data priority? It gates every desert-axis claim.
6. **Water chem framing -- condition tier vs driver.** *Recommend:* lead with chem-as-fingerprint (the
   well-powered, defensible direction) and treat chem-as-driver-of-inverts as the secondary, stream-only,
   uncensored-analyte-only set. Never draw water chem as a producer/trophic rung.
