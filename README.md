# NEON Driver Cascade

The **capstone** of the NEONize family — a cross-product synthesis of *what drives populations*,
bottom-up. Where each sibling app (small mammals, breeding birds, plant diversity, vegetation
structure, plant phenology) dives into one NEON product, this one **lines them up** at shared
field sites into a single trophic cascade:

> **CLIMATE → GREEN-UP (the hinge) → PRODUCERS → CONSUMERS**

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

## Tabs
- **Overview** — the cascade idea + a schematic of which signals exist at the site.
- **Cascade Ladder** (flagship) — standardised (z-scored) annual signals stacked by trophic layer
  on a shared year axis; watch a wet year ripple up into green-up, plants, then rodents. Side
  panel: each predicted link, coloured by whether the data agrees and honest about its few years.
- **Driver Lab** — pick a response; see every literature-predicted driver tested against it, with
  the aligned-pairs scatter and the sign-match tally.
- **About** — the full priors table + the honesty manifesto + citations.

### What it surfaces (real, honest findings)
- **SCBI**: warmer springs → earlier green-up — r=−0.60, n=7, clears the permutation null
  (*consistent with prior*); 3/3 cascade links point the predicted way.
- **SRER / HARV**: messier (1/5, 1/3 sign-matches) — and the app *says so* (high binomial p =
  not more than chance). Honesty over a tidy story.

## Run it
R 4.5.x: `shiny::runApp(".", port = 8194)`. Default site **SRER** (the desert
precip→productivity→rodent showcase). All data ships in `data/cascade.rds`.

## Data
`data/cascade.rds` = `list(annual, signals, priors, meta)`. The annual per-site signal table is
**assembled from the five sibling apps' bundles** + the small-mammal NEON/Daymet climate overlays
(`scripts/build_cascade.R`) — no re-fetch; plain R reads the existing `.rds`. Small-mammal catch
rate is a relative annual index (captures per 100 plot-nights), not effort-standardised across sites.

Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with NEON/Battelle/NSF.
