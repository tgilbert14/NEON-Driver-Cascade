# Site Explorer — progress & roadmap (resume anchor)

Durable status for the **public "site explorer" track** so any session (or a fresh chat) can pick up
where we left off. This is the audience-expansion prototype proposed in
[`../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md): reframe the
suite from a scientist's question (*"does bottom-up cascade theory hold?"*) to a citizen's
(*"what is this place, and what makes it tick?"*).

Last updated: 2026-07-18.

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
| 4 | **Real AOP LiDAR canopy** — swap procedural canopy for actual CHM (DP3.30015.001) heights | IN PROGRESS | — |
| 5+ | Polish — ambient sound, sky gradient/sun, smoother desert tone, more of the 46 walkable | PLANNED | — |

Earlier suite PRs (not this track): #5 = the complementary-app gap audit (merged).

## Files (all under `prototypes/site-explorer/`, outside the app's build surface)

- `index.html` — the main explorer (self-contained; `site-data.json` + `map-data.json` inlined).
- `walk.html` — the 3D scene (Three.js r128 inlined; ~620 KB; deep-linkable via `?site=CODE`).
- `export_data.py` — reads `data/cascade.rds` + `neon-site-names.json` → `site-data.json` (real science).
- `build_map.py` — projects a US-states GeoJSON + site coords → `map-data.json`.
- `site-data.json` / `map-data.json` / `neon-site-names.json` — generated/fetched data.
- `README.md` — what it is, per-rung detail, how to regenerate.

**Nothing here touches the R/Shiny app**: `prototypes/` is outside `manifest.json`'s allowlist and the
rebuild's captured code surface (`R/`, `scripts/`, `www/`, top-level runtime files), so every PR's
`rebuild-contracts` CI passes on the unchanged exact-byte artifacts.

## Key facts / honesty rails (keep these true)

- The science is **real** from the committed bundle: the one solid pooled result is `temp → green-up`,
  **15 of 18 sites, p = 0.004**. Single-site values are framed as *direction, never significance*
  (no short series can be significant); context-only measures are labelled "not counted in the network test".
- The **year wheel is a per-biome schematic** (the bundle has annual, not monthly, data) — labelled as such.
- The **3D vegetation is a procedural impression** from measured standing wood, **not** a LiDAR scan
  (Rung 4 makes one site real). Six sites are walkable: WREF, SCBI, KONZ, SRER, JORN, TOOL.
- No R in the sandbox → `export_data.py` reads the RDS with the pure-Python `rdata` package
  (`pip install rdata`). A production build would use an R writer beside `scripts/build_search_index.R`.

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

## Next up (Rung 4 — real AOP LiDAR)

Goal: at one forest site (candidate: **WREF** or **SCBI**), replace procedural trees with canopy placed
from the **real Canopy Height Model** (DP3.30015.001, 1 m GeoTIFF). Plan: query the NEON API for a CHM
tile (`/api/v0/data/DP3.30015.001/<site>/<yearMonth>`), read the GeoTIFF raster (pure-Python `tifffile`),
downsample to a compact height grid, inline it, and place instanced canopy by real height. Label it
"Real AOP LiDAR canopy heights, <site> <year>." CHM is available for WREF, SCBI, HARV, TALL, SRER
(≈7–9 flight-years each).

Built by Desert Data Labs. Not affiliated with NEON / Battelle / NSF.
