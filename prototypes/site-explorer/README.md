# Site Explorer — "What drives this place?" (Rung 1 prototype)

A **design prototype**, not a published NEON product. It demonstrates the public-facing,
audience-expansion track proposed alongside the pass-10 gap audit
([`docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md)): reframing the
suite from a scientist's question (*"does bottom-up cascade theory hold across NEON?"*) to a citizen's
question (*"what is this place, and what makes it tick?"*).

## The idea (Rung 1 of the concept ladder)

- **Place first, mechanism second.** Pick a site and the whole page repaints in that biome's world
  (atmospheric hero, per-site accent palette, a year-rhythm wheel). The sense of place is the hook.
- **Honesty as curiosity, not fine print.** Each driver is stated in plain language; the science —
  the `r / n / p`, the "no single site can be significant", the "shown as context, not counted in the
  network test" — hides one tap behind *"peel back the science."*
- **Web-first, VR-optional.** One dependency-free HTML page (no build, framework, or network) so it
  runs on any phone or laptop — the accessible foundation the immersive rungs would grow from.

## Wired to the real bundle

The page reads **real per-site direction screens from the committed atlas bundle**
(`data/cascade.rds`) for **all 46 sites**:

- **The "one solid result" banner** is the pooled network test (`temp → green-up`): **15 of 18 sites
  agree, p = 0.004** — the only result that clears significance.
- **Every driver card's numbers** (`r / n / p / tier`) come straight from `suite_links`. Example: at
  **SRER**, summer rain → next-year mice is a real `r = +0.72, n = 7, p = 0.14` — a clean direction
  but not significant, and context-only (not counted in the network test). At **SCBI**, warmer years →
  earlier leaf-out is `r = −0.82` and tagged *part of the one solid result.*
- **Real place identity for all 46 sites.** Site names, states, coordinates, and NEON domain names
  come from the NEON API (`/api/v0/sites`), fetched once and committed as `neon-site-names.json`. So
  a site reads as "Jornada Experimental Range · New Mexico · Desert Southwest domain," not "Site JORN."
- **Three sites are "featured"** (SRER, KONZ, SCBI) with hand-authored theses and rhythm wheels; the
  other 43 load with a biome-appropriate world and their real place data (e.g. WREF shows
  `standing wood 56.3 m²/ha`).

## Year in motion (Rung 2)

The year-wheel plays: a **Play the year** control sweeps a "now" pointer around the twelve months,
the current month's rings light up, and the caption narrates the site's signature moments (the
monsoon breaking, prairie fire, leaf-out). A scrubber gives manual control, hovering a month pauses
and inspects, and each site rests on its own signature month. Autoplay respects
`prefers-reduced-motion` (the button steps one month at a time instead).

**Still illustrative:** the year-wheel is a **schematic** of each biome's typical rhythm (the bundle
holds annual signals, not measured monthly data — the wheel is labeled as such).

## Regenerating the data

```bash
pip install rdata
python3 prototypes/site-explorer/export_data.py     # reads data/cascade.rds + neon-site-names.json -> site-data.json
# then inline site-data.json into index.html's <script id="siteData"> block
```

`export_data.py` only **reads** the committed bundle (it never rebuilds it) and merges the committed
`neon-site-names.json`. In a production suite build this would be an R writer alongside
`scripts/build_search_index.R`; it uses the pure-Python `rdata` reader here only because the sandbox
has no R.

## Run it

Open `index.html` in a browser, or view the hosted Artifact. It is intentionally dependency-free
(the site data is inlined, so there is no fetch).

## Verified

Driven headlessly in Chromium: 0 console errors / 0 page errors; the solid-result banner and every
driver card render real bundle numbers; all 46 sites load with real names/states (featured +
directory search by name/state); the year-in-motion Play/scrub advances the pointer and captions;
driver peel-backs work; dark theme is legible; no horizontal overflow at 390 px.

Built by Desert Data Labs. Not affiliated with NEON / Battelle / NSF.
