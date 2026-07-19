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

## Step inside — first-person 3D (Rung 3)

`walk.html` is a first-person procedural scene: you stand in a NEON site and look around. The
**vegetation is built from the site's real measured standing wood** (`veg_ba_ha`) and biome — from Wind
River's 56 m²/ha old-growth conifer, through the open Sonoran and Chihuahuan deserts, to treeless Arctic
tundra at Toolik. Drag to look, `WASD` (or the **Walk** button) to move; a switcher spans ten
biome-diverse sites, and the hero's **"Step inside this place →"** deep-links here (`walk.html?site=CODE`).

**All 46 sites are walkable** (Rung 5): the six curated ones keep hand-authored scenes; the rest are
generated from each site's `bucket` + `veg_ba_ha` (`walk-sites.json` → `paramsFor()`). Rung 5 also adds
a gradient sky with a soft sun, a gentle canopy sway + walking head-bob (both reduced-motion aware), and
a muted desert-ground tone.

### Day to night (Rung 8)

A **time-of-day slider** in the control row sweeps the scene from **dawn → midday → dusk → night**. It
drives the gradient-sky shader's colours, arcs the sun's direction / colour / intensity across the sky, and
dims the hemisphere light and fog to match — so the trunks catch a warm low sun at dawn and dusk, and the
forest falls to a dim, moonlit blue at night. The slider's track previews the cycle, and the label/icon name
the phase. The **midday stop reuses each site's own daytime palette and the original sun defaults, so the
default view is unchanged** from before; the other stops blend a universal sky over the biome. It's a
**mood/lighting illustration**, not a modelled solar position for any site's latitude or date.

### Soundscape (Rung 7)

An optional **per-biome ambient soundscape**, off by default. Tap **Sound** and a procedural
[Web Audio](https://developer.mozilla.org/docs/Web/API/Web_Audio_API) graph fades in — filtered
pink-noise wind with slow gusts, a faint insect shimmer, and sparse bird chirps — retuning as you travel
between biomes (a closed forest gets birds and a soft canopy wind; the desert gets a brighter, drier wind
with a few insects and no birds; the tundra a low, bare wind). It also **follows the time-of-day slider**
(Rung 10): a **dawn chorus** (birds busiest and loudest near dawn, occasional at midday, silent at night)
and **night crickets** (the insect layer swells toward dusk and night — forest, grassland and desert gain a
night-cricket voice, while the tundra stays silent). It is **synthesized in the browser, not a
field recording** — nothing is streamed or fetched (so it stays within the Artifact CSP, like the inlined
3D engine), and it's an *impression* of the biome's ambience, not the sound of any real site. It starts
only on your tap because browsers require a gesture before audio can play, and it honours the system's
"reduce motion" preference elsewhere in the scene.

It uses [Three.js](https://threejs.org) r128, **inlined** into the page (the Artifact CSP blocks CDNs),
with `InstancedMesh` for trees/shrubs/grass/rock so thousands of plants stay cheap. Five of the six sites
are a **procedural impression** from measured standing wood. Because it inlines a 3D engine, it is a
heavier page and is kept **separate** from the lightweight main explorer, linked rather than merged.

**Five forest sites are rendered from real NEON AOP LiDAR scans** — Wind River (`~68 m` old-growth
conifer), Lower Teakettle (`~59 m` Sierra Nevada conifer), Smithsonian and Harvard (eastern deciduous),
and Guánica (`~16 m` subtropical dry forest).
`build_lidar.py` reads an actual Canopy Height Model GeoTIFF (DP3.30015.001, a central 300 m window of
1 m LiDAR downsampled to 3 m cells) into `lidar-<site>.json`, inlined into `walk.html`; the scene uses a
real scan whenever a `lidar-<site>.json` grid exists (keyed by site code), else the procedural build.
Only the derived grids are committed, not the raw multi-MB tiles. To add another site:
`python3 build_lidar.py <SITE> <CHM.tif>`, then inline as `<script id="lidar<SITE>">` — no scene-code
changes. (The `/api/v0/data/` route needs a NEON API token via `X-API-Token`.)

## Travel map (Rung 2.5)

A **"Travel the network"** map opens the explorer: all 46 sites as dots on a US map (with Alaska and
Puerto Rico insets), coloured by biome. Hover a dot for its name and state; tap one to drop into that
place (and the selected site stays ringed). `build_map.py` projects a public-domain US-states GeoJSON
outline + each site's lon/lat into screen coordinates (Albers for the lower 48; equirectangular insets
for Alaska and Puerto Rico) and writes `map-data.json`, inlined into the page so there is no runtime
projection library and no map tiles. The outline is a low-poly schematic, not a precise basemap.

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
python3 prototypes/site-explorer/build_map.py us.json  # projects a US-states GeoJSON -> map-data.json
# then inline site-data.json and map-data.json into index.html's <script id="siteData"> / <script id="mapData"> blocks
```

`export_data.py` only **reads** the committed bundle (it never rebuilds it) and merges the committed
`neon-site-names.json`. In a production suite build this would be an R writer alongside
`scripts/build_search_index.R`; it uses the pure-Python `rdata` reader here only because the sandbox
has no R.

## Run it

Open `index.html` in a browser, or view the hosted Artifact. It is intentionally dependency-free
(the site data is inlined, so there is no fetch).

## Verified

Driven headlessly in Chromium: 0 console errors / 0 page errors; the travel map renders all 46 dots
(39 lower-48 + 5 Alaska + 2 Puerto Rico) with hover names and click-to-travel + selection highlight;
the solid-result banner and every driver card render real bundle numbers; all 46 sites load with real
names/states (featured + directory search by name/state); the year-in-motion Play/scrub advances the
pointer and captions; driver peel-backs work; dark theme is legible; no horizontal overflow at 390 px.

For the 3D walk: the **Sound** toggle builds its Web Audio graph only on the click (an `AudioContext` and
its ~12 nodes appear after the tap, never before — no autoplay), the button's pressed-state and indicator
flip both ways, and travelling between biomes while sound is on retunes without error; all nine bucket-diverse
sites (forest / grassland / dryland / tundra / mixed) render with 0 console/page errors and no 390 px
overflow. *Audio quality itself can't be verified headlessly (no audio device) — only correct graph creation
and error-free toggling/retuning are checked.* The **time-of-day–linked soundscape** was checked by
instrumenting the Web Audio graph: bird chirps peak at dawn and fall to zero at night, the insect-gain target
rises monotonically from dawn to night, and at night the tundra's insect gain is exactly 0 while grassland and
desert are non-zero — all with 0 errors. The **time-of-day slider** was swept across all six phases
(dawn → night): the label/icon track the phase, midday reproduces the original look, and every bucket renders
cleanly at night — screenshots at dawn/midday/dusk/night confirm the sky, sun, and scene brightness shift as
intended, with 0 console/page errors.

Built by Desert Data Labs. Not affiliated with NEON / Battelle / NSF.
