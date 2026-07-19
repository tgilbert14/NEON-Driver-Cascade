# Site Explorer — progress & roadmap (resume anchor)

Durable status for the **public "site explorer" track** so any session (or a fresh chat) can pick up
where we left off. This is the audience-expansion prototype proposed in
[`../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md): reframe the
suite from a scientist's question (*"does bottom-up cascade theory hold?"*) to a citizen's
(*"what is this place, and what makes it tick?"*).

Last updated: 2026-07-19.

## Live artifacts (private to the owner unless shared)

- **Main explorer:** https://claude.ai/code/artifact/ae959cc7-7728-4445-a4e1-bc5e79671755
- **Step inside (3D walk):** https://claude.ai/code/artifact/93dc3028-3d44-4e50-88dd-5ce9b9985918

To update either: republish the **same file path** via the Artifact tool (keeps the URL). From a
different chat, pass the URL as `url`. The two pages cross-link by hardcoded artifact URL
(`WALK_URL` in `index.html`; the back-link in `walk.html`) — update those if a URL ever changes.

## The concept ladder (what's built)

| Rung | What | Status | PR |
|---|---|---|---|
| 1 | "What drives this place?" — pick a site, place-first hero + year wheel + peel-back science | DONE | #6 |
| 1b | Wired to the **real** `data/cascade.rds` bundle — all 46 sites, honest per-site r/n/p | DONE | #7 |
| 2 | Year in motion (play/scrub the wheel) + real NEON site **names/states/coords** (NEON API) | DONE | #8 |
| 2.5 | **Travel map** — 46 sites as biome-coloured dots on a US map (+ AK/PR insets), click to travel | DONE | #9 |
| 3 | **Step inside** — first-person 3D, vegetation from real `veg_ba_ha` (Three.js inlined) | DONE | #10 |
| 4 | **Height-field canopy** renderer + `build_lidar.py` pipeline; WREF canopy from a grid | DONE (synthetic) | #11 |
| 5 | **Polish** — gradient sky + sun, canopy sway + head-bob, muted desert, **all 46 walkable** | DONE | #12 |
| 4-real | **Real AOP LiDAR** — WREF, SCBI, HARV & GUAN canopies from actual NEON CHM scans | DONE | #13 |
| 6 | **Science in-scene** — each site's honest headline driver shown in the 3D overlay | DONE | #15 |
| 7 | **Soundscape** — per-biome procedural Web Audio ambience (wind/insects/birds), opt-in, retunes per site | DONE | #16 |
| 8 | **Day-to-night lighting** — a time-of-day slider drives sky/sun/hemi/fog (dawn → midday → dusk → night) | DONE | #17 |
| 9 | **TEAK on real AOP LiDAR** — Lower Teakettle (Sierra Nevada), the tallest real canopy in the set (~59 m) | DONE | #18 |
| 10 | **Living soundscape** — the day-cycle drives the audio too: dawn chorus, quiet midday, night crickets | DONE | #19 |
| 11 | **GRSM on real AOP LiDAR** — Great Smoky Mountains, a dense southern-Appalachian canopy (sixth real scan) | DONE | #20 |
| 12+ | Optional — still more sites on real LiDAR; richer bird/insect voices; weather (wind gusts you can see) | PLANNED | — |

> **Rung 4 blocker — RESOLVED.** The owner supplied a NEON API token; the `/api/v0/data/` route was a
> **token gate**, not an IP block (200 with `X-API-Token`). Wind River's canopy is now built from a
> **real NEON AOP Canopy Height Model** (DP3.30015.001, tile `NEON_D16_WREF_DP3_580000_5075000`, 2023 —
> a central 300 m window, 1 m LiDAR downsampled to 3 m cells; real heights to ~68 m). Only the derived
> `lidar-wref.json` grid is committed; the raw multi-MB GeoTIFF is not. To do another site:
> `python3 build_lidar.py <SITE> <CHM.tif>` → re-inline into the site's `<script id="lidar…">`. (The
> token used for this pull should be regenerated on the NEON portal, since it passed through chat.)

Earlier suite PRs (not this track): #5 = the complementary-app gap audit (merged).

## Files (all under `prototypes/site-explorer/`, outside the app's build surface)

- `index.html` — the main explorer (self-contained; `site-data.json` + `map-data.json` inlined).
- `walk.html` — the 3D scene (Three.js r128 inlined; ~964 KB; deep-linkable via `?site=CODE`).
- `export_data.py` — reads `data/cascade.rds` + `neon-site-names.json` → `site-data.json` (real science).
- `build_map.py` — projects a US-states GeoJSON + site coords → `map-data.json`.
- `build_lidar.py` — a real CHM GeoTIFF (or a synthetic stand-in) → `lidar-<site>.json` height grid.
- `site-data.json` / `map-data.json` / `neon-site-names.json` — generated/fetched data.
- `lidar-{wref,scbi,harv,guan,teak,grsm}.json` — real NEON AOP CHM height grids (derived; raw tiles never committed).
- `README.md` — what it is, per-rung detail, how to regenerate.

**Nothing here touches the R/Shiny app**: `prototypes/` is outside `manifest.json`'s allowlist and the
rebuild's captured code surface (`R/`, `scripts/`, `www/`, top-level runtime files), so every PR's
`rebuild-contracts` CI passes on the unchanged exact-byte artifacts.

## Key facts / honesty rails (keep these true)

- The science is **real** from the committed bundle: the one solid pooled result is `temp → green-up`,
  **15 of 18 sites, p = 0.004**. Single-site values are framed as *direction, never significance*
  (no short series can be significant); context-only measures are labelled "not counted in the network test".
- The **year wheel is a per-biome schematic** (the bundle has annual, not monthly, data) — labelled as such.
- The **3D vegetation is a procedural impression** from measured standing wood — **except the six forest
  sites WREF, SCBI, HARV, GUAN, TEAK, GRSM**, whose canopies are **real NEON AOP LiDAR scans** (DP3.30015.001;
  a site gets a real canopy when a `lidar-<site>.json` grid exists, keyed by site code). TEAK (Lower Teakettle,
  Sierra Nevada) is the tallest — real heights to ~59 m (tile `NEON_D17_TEAK_DP3_321000_4097000`, 2024); GRSM
  (Great Smoky Mountains) is a dense closed-canopy stand to ~46 m (tile `NEON_D07_GRSM_DP3_273000_3952000`,
  2022). All 46 sites are walkable. To add another: `build_lidar.py <SITE> <CHM.tif>` → inline as
  `<script id="lidar<SITE>">`.
- No R in the sandbox → `export_data.py` reads the RDS with the pure-Python `rdata` package
  (`pip install rdata`). A production build would use an R writer beside `scripts/build_search_index.R`.
- The **soundscape is synthesized, not recorded** (Rung 7): a procedural Web Audio graph — filtered pink-noise
  wind with slow LFO gusts, an AM insect shimmer, and sparse bird chirps — so nothing is streamed or fetched
  (CSP-safe, no audio files). It's **off by default** and starts only on the user's tap (browsers require a
  gesture to start audio). Each biome retunes the graph (`BIOME_SND`): forest = birds + soft wind, dryland =
  bright wind + faint insects + no birds, tundra = low bare wind, etc. It's an **impression of the biome's
  ambience, not a field recording** of any site.
- The soundscape is **wired to time of day** (Rung 10): the same `todVal` that drives the lighting also shapes
  the audio — a **dawn chorus** (birds most frequent/loud near dawn, occasional midday, off at night) and
  **night crickets** (insect layer swells toward dusk/night; `NIGHT_INS` gives forest/grassland/dryland a
  night-cricket capacity, **tundra stays silent**). `setBiomeSound()` re-times the chirp scheduler on every
  change so the chorus follows the slider promptly. Still synthesized, still an impression — no recordings.
- The **day-to-night lighting is illustrative** (Rung 8): a time-of-day slider (`TOD` keyframes → `applyTOD()`)
  blends the sky-shader colours, arcs the sun's direction/colour/intensity, and dims the hemisphere light and
  fog from dawn → midday → dusk → night. The **midday stop (0.40) uses each site's own daytime palette and the
  original sun defaults, so the default load looks identical to before** (no regression); the other stops blend
  a universal sky over the biome. It's a **mood/lighting illustration, not a modelled solar position** for any
  site's latitude or date.

## How to regenerate / verify

```bash
pip install rdata
python3 prototypes/site-explorer/export_data.py            # -> site-data.json
python3 prototypes/site-explorer/build_map.py us.json       # -> map-data.json (us.json = a US-states GeoJSON)
# then inline site-data.json / map-data.json into index.html's <script id="siteData"> / <script id="mapData">
```
Verify headlessly with Chromium at `/opt/pw-browsers/chromium-1194/chrome-linux/chrome` via
`playwright-core` (WebGL needs `--enable-unsafe-swiftshader`). Every rung was checked for 0 console/page
errors, correct rendering, and no 390 px mobile overflow before merge.

## Working rhythm (owner's instruction)

Stage-by-stage: build an increment → verify headlessly → commit/push → open draft PR → merge when CI is
green → reset the branch onto the new master → next increment. Branch: `claude/neon-suite-expansion-c0wl9k`.

## Next up (Rung 11+ — further polish)

Done since Rung 6: the **headline driver in-scene** (Rung 6, #15), the **per-biome soundscape** (Rung 7, #16),
the **day-to-night lighting** (Rung 8, #17), **TEAK on real AOP LiDAR** (Rung 9, #18), and the **living
(time-of-day-linked) soundscape** (Rung 10, #19), and **GRSM on real AOP LiDAR** (Rung 11, #20). Six forest
sites now render from **real AOP LiDAR** — WREF, SCBI, HARV, GUAN, TEAK, GRSM (grids committed as
`lidar-<site>.json`, inlined as `<script id="lidar<SITE>">`). Remaining nice-to-haves: **still more forest
sites on real LiDAR** — pick another tall-canopy site (e.g. BART, SOAP), download its CHM tile via the NEON
API (`X-API-Token`; the token is stashed at scratchpad `.neon_token`), then `build_lidar.py <SITE> <CHM.tif>`
→ inline `lidar-<SITE>.json` (recipe above); richer bird/insect voices; or visible weather (wind gusts that
move the canopy). No external data is needed for the last two.

**Reusable recipe for a new real-LiDAR site** (proven for TEAK): `TOKEN=$(cat scratchpad/.neon_token)`;
GET `/api/v0/locations/<SITE>` for the tower UTM easting/northing → floor each to the 1 km grid for the tile's
SW corner; GET `/api/v0/products/DP3.30015.001` for the site's `availableMonths`; GET
`/api/v0/data/DP3.30015.001/<SITE>/<YYYY-MM>?package=basic` and pick the `*_CHM.tif` whose name contains
`<easting>_<northing>`; `curl` its signed `url`; `rdenv/bin/python3 build_lidar.py <SITE> <tile.tif>`; inline
the resulting `lidar-<site>.json` after the last `lidar…` `<script>`; add the code to the switcher list. The
raw `.tif` stays in scratchpad — **never commit it**, only the derived grid.

Rung 5 (done): all 46 sites are now walkable — the six curated ones keep hand-authored scenes; the rest
are generated from `bucket` + `veg_ba_ha` in `walk-sites.json` via `paramsFor()`. Deep-link any with
`walk.html?site=CODE`; the explorer's hero "Step inside" now appears for every site.

Built by Desert Data Labs. Not affiliated with NEON / Battelle / NSF.
