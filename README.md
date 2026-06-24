# NEON Driver Cascade

The **capstone** of the NEONize family — a cross-product synthesis of *what drives populations*,
bottom-up. Where each sibling app (small mammals, breeding birds, plant diversity, vegetation
structure, plant phenology) dives into one NEON product, this one **lines them up** at shared
field sites into a single trophic cascade:

> **CLIMATE → GREEN-UP (the hinge) → PRODUCERS → CONSUMERS**

> **Where this is headed:** [`docs/CASCADE-ROADMAP.md`](docs/CASCADE-ROADMAP.md) is the living plan
> for growing this into a two-axis (terrestrial + aquatic) cascade — wiring Beetle, Mosquito, Inverts
> and Water Chem in, the repeatable add-a-product framework, and the per-app science feedback loop.

## Why it's careful (and what it refuses to do)

Each NEON site has only ~3–13 years of annual data. At that length a lag-aware correlation scan
finds spurious signals everywhere. So the design is deliberately conservative — grounded in a
literature review of bottom-up driver ecology and short-time-series statistics:

- **States priors, doesn't dredge.** Every driver→response link has an expected **sign + lag**
  taken from the literature *before* looking at the data (Brown & Ernest rain-&-rodents;
  Thibault 2010; Owen 2006; Cole 2015 green-up/NDVI; Both & Visser phenological mismatch;
  dryland ANPP–precipitation). We never report whichever lag happens to fit best.
- **n-gated.** Below **6 overlapping years** no verdict is given — just the aligned series.
  At n≥6 a **permutation null** + **bootstrap CI** gate the verdict.
- **Direction over magnitude.** The headline is a **sign-match tally** — a binomial test of how
  many links point the predicted way — which is honest about multiple comparisons in a way a
  single correlation isn't.
- **Never "drives" or "causes."** A handful of annual points cannot establish causation; these
  are *consistencies with*, not proof of, the mechanism. No SEM/path model, no naive site-pooling.

## Biome-conditional priors (the throughline)
The big lesson of the build: **cascade priors are biome-conditional.** A temperate prior fails in a
desert not because the desert has no cascade, but because you're testing the wrong driver. So each
prior carries the limiting-resource regime where its mechanism is established, and at each site we
test (and tally) the links *expected* for that biome:
- **temperature-limited** (temperate/boreal forest, prairie, tundra): warmer spring → earlier green-up.
- **water-limited** (warm & cold desert, sagebrush): **winter** rain → spring forbs; **summer-monsoon**
  seed crop → next-year granivores. Built from *seasonal* climate (winter Oct–Mar, monsoon Jul–Sep),
  reconstructed from the existing monthly NEON-tower overlays — because one annual rainfall total blends
  two ENSO-anticorrelated seasons that drive different guilds.

## Tabs
- **Overview** — the cascade idea, a schematic of which signals exist, and a one-sentence **verdict**
  (auto-written, biome-anchored) that leads with the answer.
- **Cascade Ladder** (flagship) — standardised (z-scored) annual signals stacked by trophic layer; the
  link chips show whether each *expected* link agrees. Plus a **Seasonal Climate** panel: at desert sites
  it shows how splitting annual rain into winter vs. monsoon recovers the signal the annual total hides.
- **Driver Lab** — pick a response; every literature-predicted driver tested against it, with the
  aligned-pairs scatter (now carrying its **r / n / p / 95% CI on the figure**) and a tier-honest fit line.
- **Across NEON** — the suite scoreboard: each link **pooled across sites** (one vote per site) + a
  site × link grid coloured by verdict, with the grey untestable majority shown, not hidden.
- **About** — the full priors table + the honesty manifesto + citations.

### What it surfaces (real, honest findings)
These are the two results that actually **pool across sites** (one vote per site), the only honest test past the
short-series problem:
- **The suite headline (pooled):** **warmer springs → earlier green-up holds at 23 of 32 temperature-limited
  sites, binomial p = 0.010** — a real result no single short site can show. Led by **SCBI** (r=−0.92, n=6,
  permutation p=0.007). Note the honest tension: the same mechanism on the *mechanistically-correct spring
  window* (temp_spring → green-up) does **not** resolve when pooled (16 of 28 sites, p = 0.286), so the headline
  rests on the better-sampled annual-mean stand-in. The app states that caveat on the headline itself.
- **Producer → consumer links pool to ~null** (richness → rodents 22 of 40 sites, p = 0.318) — and the app
  says so rather than dressing it up.

#### Illustration of the annual-aggregation artifact (single site, not significant)
This is **not** a pooled result — it is one desert site, below the app's n ≥ 6 verdict gate, shown to make the
artifact visible, never as evidence:
- **SRER (the desert that "didn't match"):** the annual cascade looks weak (1–2/3), but that is mostly a
  *method* artifact. Test the **right season** and the summer-monsoon seed crop tracks next-year rodents at
  **r = +0.72** (one desert, n = 7 yrs, **p ≈ 0.06 — suggestive, not established**; annual rain showed +0.20),
  and winter rain → forb richness flips from −0.11 to +0.27. The desert cascade was there all along; the annual
  aggregation was hiding it. The honest, cross-site version of this prior pools at too few sites yet (it sits
  below the pooling floor in the app).

## Run it
R 4.5.x: `shiny::runApp(".", port = 8194)`. Default site **SRER** (Santa Rita — the Sonoran-desert home
turf and the thematic centre; its verdict sentence leads with the monsoon-recovery story). All data
ships in `data/cascade.rds`.

## Data
`data/cascade.rds` = `list(annual, signals, priors, suite_links, pooled, site_meta, meta)`. The annual
per-site signal table — **including the seasonal climate signals** (`precip_winter`, `precip_monsoon`,
`temp_spring`) — is **assembled from the five sibling apps' bundles** + the small-mammal NEON-tower
climate overlays (`scripts/build_cascade.R`) — no re-fetch; plain R reads the existing `.rds`.
`suite_links`/`pooled` are the **precomputed** cross-site scoreboard (every site × prior, biome-aware,
2000-permutation), so the app reads them instead of recomputing on every site switch. Small-mammal catch
rate is a relative annual index (captures per 100 trap-nights), not effort-standardised across sites.
Rebuild + refresh the deploy manifest: `Rscript scripts/build_cascade.R` (it rebuilds the bundle, emits
`data/neon-cascade-codebook.csv`, then runs the lean, hard-gated `scripts/write_manifest.R`). A `.rscignore`
keeps `scripts/`, internal `docs/*.md`, and `README.md` out of the Connect Cloud bundle (the public
`docs/index.html` landing cover still ships).

Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with NEON/Battelle/NSF.
