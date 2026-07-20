# Site Explorer — progress & roadmap (resume anchor)

Durable status for the **public "site explorer" track** so any session (or a fresh chat) can pick up
where we left off. This is the audience-expansion prototype proposed in
[`../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md): reframe the
suite from a scientist's question (*"does bottom-up cascade theory hold?"*) to a citizen's
(*"what is this place, and what makes it tick?"*).

Last updated: 2026-07-20.

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
| 12 | **Wind you can see** — canopy gusts share the wind's ~14s rhythm; trunks stay planted, crowns sway | DONE | #21 |
| 13 | **Drifting clouds** — a procedural fbm cloud layer in the sky shader, sun-lit and dimming into night | DONE | #22 |
| 14 | **SOAP on real AOP LiDAR** — Soaproot Saddle, an open Sierra foothill woodland (seventh real scan) | DONE | #23 |
| 15 | **Audit & polish** — biome-varied cloud cover; idle chirp timer stops when muted; doc accuracy | DONE | #24 |
| 16 | **Visual overhaul (stage 1)** — soft sun shadows, key-dominant warm light, distant horizon hills | DONE | #26 |
| 17 | **Filmic tone mapping** — ACES on the renderer + matching ACES in the sky shader (consistent) | DONE | #27 |
| 18 | **Richer geometry** — scattered rocks + fallen logs, layered distant hills, rounder tree crowns | DONE | #28 |
| 19 | **Generated textures** — per-biome ground + bark from an image model, embedded inline, on ground+trunks | DONE | #29 |
| 20 | **Walkable forests** — real-LiDAR stems thinned from per-cell grid to sparse jittered scatter (sightlines!) | DONE | #30 |
| 21 | **Provenance receipt + scientific corrections** — every page now names its source vintage; six wrong/unsourced numbers fixed | DONE | — |
| 22+ | Optional — more real-LiDAR forests; TOD-linked bark/ground variation; higher-res textures on the reload | PLANNED | — |

> **Rung 4 blocker — RESOLVED.** The owner supplied a NEON API token; the `/api/v0/data/` route was a
> **token gate**, not an IP block (200 with `X-API-Token`). Wind River's canopy is now built from a
> **real NEON AOP Canopy Height Model** (DP3.30015.001, tile `NEON_D16_WREF_DP3_580000_5075000`, 2023 —
> a central 300 m window, 1 m LiDAR downsampled to 3 m cells; real heights to ~68 m). Only the derived
> `lidar-wref.json` grid is committed; the raw multi-MB GeoTIFF is not. To do another site:
> `python3 build_lidar.py <SITE> <CHM.tif>` → re-inline into the site's `<script id="lidar…">`. (The
> token used for this pull should be regenerated on the NEON portal, since it passed through chat.)

Earlier suite PRs (not this track): #5 = the complementary-app gap audit (merged).

## Spin-off track: "The Plot" — a real-data plot reconstruction (`plot.html`)

A new direction (owner's idea): instead of a statistical/procedural impression, reconstruct **one real
NEON plot plant-by-plant**. Test build: **SRER_048** (Santa Rita, Sonoran desert) — **179 real tagged
plants** from Vegetation Structure (DP1.10098.001), each at its **real mapped position** (pointID +
stemDistance + stemAzimuth, point coords from the locations API), sized by real height/crown, live vs
standing-dead, and **click a plant to read its actual NEON record** (species, individualID, tag year,
measured height/crown, status). 9 species, 104 measured heights, 5 whole plants dead of the 104 assessed. See `build_plot.md`. Live
artifact: https://claude.ai/code/artifact/acf46a2b-594f-4da6-ae59-be37dc57195e . Committed: `plot.html`
(self-contained), `plot-srer048.json` + `div-srer.json` (derived), `plot.src.html` (template),
**`assemble_plot.py`** (reproducible re-inliner — commits, needs no raw data/token), `build_plot.md` (recipe).
Rebuild loop: edit `plot.src.html` → `python3 assemble_plot.py` → `plot.html`. The from-scratch data builders
(`build_plot.py`, `div_srer.py`, `geo_plot.py`) stay in scratchpad (they need raw NEON CSVs/tiles + token).

**Botanical models (done):** each of the 9 species now has a research-accurate low-poly model keyed on
the real `taxonID` (built from SEINet/FNA/USDA/ASDM/LBJWC descriptions) — creosote open see-through vase,
Christmas cholla wiry canes with red winter fruit, velvet mesquite wide feathery umbrella over crooked
multi-trunk, Engelmann prickly pear fanning pads, fishhook barrel leaning south with woolly apex + yellow
fruit ring, Graham's pincushion frosted globe + pink halo, longleaf jointfir forked green broom, mariola
silver cushion, saguaro fluted column (juvenile here; arms if tall). CAGI10 identified/named = Saguaro.
Every plant carries a transparent pick-proxy so even thin cacti are clickable; dead woody plants render as
bare skeletons. Rebuild with scratchpad `assemble_plot.py` (reuses Three.js + ground texture from the
existing `plot.html`).

**Sky cam (done):** a top-down orthographic mode (toggle "Sky view" / "Enter the plot") framing the whole
surveyed strip — drag to pan, scroll to zoom, click any plant to read its tag from above. Each plant has a
species-coloured ground disc so the overhead view reads as a NEON crown/survey dot-map. Fixes the "hard to
navigate" first-person complaint.

**Real-world ground layers (done):** a "Ground" toggle cycles stylized → **real NEON AOP aerial photo** →
**colorized LiDAR canopy-height**, both georeferenced and draped over the plot so our tagged plants sit on the
actual desert. Source: NEON AOP **2021-09** SRER (ortho DP3.30010.001 10 cm `2021_SRER_4_515000_3530000_image.tif`;
CHM DP3.30015.001 1 m `NEON_D14_SRER_DP3_515000_3530000_CHM.tif`). Georeference: scene origin (0,0) = surveyed
cloud bbox-centre UTM **E=515527.413, N=3530802.807** (zone 12N); crop a 64 m square, north-up/east-right, drape
on a `PlaneGeometry(64,64)` with `tex.flipY=false`. Validated: plants land on dark shrubs in the photo (mean
brightness 57 under plants vs 115 overall) and the dry wash sits on the east side. Built by scratchpad
`geo_plot.py` (needs raw CSVs + token + downloaded tiles, not committed); both layers embedded as inline
data-URIs (CSP-safe). Google Maps tiles were rejected (not redistributable + CSP blocks live embeds) — NEON
AOP shares our UTM grid and is the correct, openly-licensed source.

**Per-individual variation (done):** each measured woody plant (104 of 179 — creosote, mesquite, jointfir,
mariola) is shaped by its own NEON record: mean **basalStemDiameter** → stem/trunk thickness,
**ninetyCrownDiameter** → **elliptical** crowns, and recorded canopy **shape** → vertical profile.

**Multi-stem correctness (done):** these plants are MULTI-STEM (median 11 stems, up to 45), and `plantStatus`
is **per stem**. Old code picked one stem and mislabelled whole plants — the real counts are **5 fully dead,
80 partially-dead (some stems dead), 19 all-live** (not "28 dead") — of the **104** plants that carry a
VST apparent-individual record. The other 75 (the cacti) have no such record, so their status is not
assessable and they are not in that denominator. `build_plot.py` now aggregates: `stems`
(count), `dead` (dead-stem count), status = dead only if EVERY stem is dead. Creosote renders its real stem
count with the dead fraction as bare grey stems among green live ones; the card reads e.g. "live · 7 of 16
stems standing dead · some damage".

**Plot geometry corrected (done):** the NEON base plot is really **40 × 40 m** (confirmed via the locations API),
not the 20 × 40 plant bounding box. The scene is now anchored to the **true plot centre** UTM
(515517.399, 3530802.996); plants sit in the **eastern half** (that's where VST mapped them — the west half has
shrubs in the aerial but no records). Boundary = a 40 × 40 amber survey-tape rectangle. The AOP crop was
re-anchored to the plot centre (HW 25 → 50 m window) and re-validated (plants still land on the real shrubs).

**Map-first default (done):** the primary view is the top-down **map** — the real NEON aerial with each plant
as a crisp species-coloured **ring** at its real crown size, inside the 40×40 boundary. The 3D plant figures
are **on by default** in the map (seen from above); the **"3D plants"** toggle hides them for a clean
rings-on-aerial view, and **"Enter the plot (3D)"** is the first-person walk. Marker/legend/panel colours share
one bright data-viz palette (`SP[tx].mk`).

**Map interactions (done):** (1) **hover tooltip** on any plant (species · tag · height); (2) click →
**pulsing white selection ring** + the full record card; (3) the bottom **legend chips are filters** — click a
species to show/hide it on the map (chip dims + strikethrough); (4) an **"About"** button toggles a readable
dark backdrop behind the top-left plot notes (default off so the map is clean first). Fast hover/click use a
per-plant proxy pick-list (`PICK`).

**Plant-model toggle (done):** the "3D plants: on/off" button hides the 3D models (keeping the ground rings +
click-inspect) so you can compare our mapped positions against the aerial / canopy layers.

**Cover & species panel (done):** a "Cover & species" side panel shows the plot's **estimated woody canopy
cover (~53.9%)** by species (summed live crown ellipses π(cr÷2)(cr90÷2) ÷ the **790 m² surveyed**
strip, not the full 1600 m² plot — VST mapped only the eastern half, so the unsurveyed west is
excluded from the denominator rather than counted as measured zero cover), plus **SRER site-level ground cover** from plant
diversity (litter 57% / bare soil 26% / rock 8% …) and the understory species (Lehmann lovegrass, black grama,
tanglehead, burroweed, fairy duster). SRER_048 is not itself a diversity plot, so the ground/understory layer
is site-level context (`div-srer.py` → `div-srer.json`, 2024 growing season), clearly labelled.

**LiDAR layer cleanup (done):** the canopy-height drape is now a smoothed sand→green **heatmap** over the real
height range (not per-pixel camo). **Load speed:** capped creosote stems + trimmed tufts cut load-to-interactive
~1.9 s → ~1.2 s (headless).

**Unmapped-area shade + About-first + analysis (done):** four owner-requested touches to "max out this plot":
(1) a **light dark shade** over the plot's **western half** (a `MeshBasicMaterial` plane at y≈0.05, opacity 0.4)
so it's obvious *why* that side has no plants — VST only mapped the east half; the About text calls it out in
bold. (2) The **About panel is readable by default** now (dark backdrop on) with a **"ⓘ Hide info"** toggle, so a
first-time viewer reads the plot's story before clearing it — the button flips to "ⓘ About" to bring it back.
(3) **Colour-by modes** — a "Colour" button cycles the ring colours through **species → height → stems → dead**;
non-species modes swap in a continuous ramp (height: short→tall, stems: few→many, dead: share of stems standing
dead) and reveal a gradient **scale legend** with a plain-language caption. Turns the dot-map into a quick
data-viz of any one variable. (4) A **survey-campaign filter** — a "Survey" button cycles **2016+2021 → 2016 only
→ 2021 only**, hiding plants not tagged in that bout (each plant carries its tag `date`), so you can watch the
plot's mapped population across the two re-surveys. (5) The **"Cover & species" panel now opens with a "this plot
at a glance" analysis block** — tagged plants + species count, per-campaign tallies, density (~plants/100 m²
surveyed), mean/tallest height, total/live/dead **stems mapped**, and whole-plants-dead — all computed live from
the VST records. Verified headless (0 errors; buttons cycle; shade covers the west half; stats compute).

Extra JSON fields (`stems`, `dead`, `bd`, `cr90`, `shape`, `canopy`, `dmg`) come from `build_plot.py` (cacti
have no VST apparent record → species defaults). Positions unchanged, so the AOP georeference is intact.

**Deferred:** phenology (animate the year — owner: "pheno is another area, not tied to these plots; max out this
plot first"), double-click-to-isolate a species, a live/dead filter, link from the desert walk into the plot,
more plots.

## Rung 21 — the provenance receipt (and the numbers it exposed)

The prototype's data was **correct but unfalsifiable**: nothing on any page said *which* vintage of a
versioned, revised NEON product it came from. A review against the sibling Vegetation Structure
Explorer — which has since pinned itself to **RELEASE-2026** (DOI `10.48443/pypa-qf12`) with an exact
raw digest — made the gap concrete. Fixed in two halves.

**The receipt.** `export_data.py` now reads the `source_products` table that
`scripts/build_cascade.R` already writes into the bundle, and stamps it into `site-data.json.meta.provenance`
together with the bundle's SHA-256, schema version, build time and tier rule. The explorer footer renders
it: bundle `47b98e48…` · built 2026-07-03 · and, behind a disclosure, the **exact sibling commit for all
seven source products** (veg is pinned at `5e73e0d`). `plot-srer048.json` and `div-srer.json` gained a
`provenance` object each, and The Plot's panel now has a "Where this data came from" section. Where a
field genuinely cannot be recovered it says **UNKNOWN with the reason** rather than staying silent —
the release tag was never captured because the build queried the live API, and `build_plot.py` is not
committed, so those records are not reproducible from this repo alone. Both facts are now stated on the
page instead of being invisible.

**What the receipt exposed.** Writing down the formula forced four published numbers to be corrected:

- **Canopy cover was normalised to the wrong denominator.** Cover divided by the full 1600 m² plot
  while density, eleven lines earlier, divided by the 790 m² *surveyed* strip — two denominators for
  one plot in one panel. VST mapped only the eastern half, so the whole-plot divisor counts 810 m² of
  never-surveyed ground as measured zero cover. Now **53.9% over the surveyed area**, with the formula
  (live-only, elliptical) written out and the whole-plot figure kept as a labelled aside.
- **"23 all-live" was arithmetically impossible** — 5 + 80 + 23 = 108 against 104 records. It is **19**.
- **Stem median was 10; it is 11.** And the retired **"28 dead"** still survived in two places.
- **"5 of 179 whole plants dead"** conflated assessed with unassessable: the 75 cacti carry no VST
  apparent-individual record and are live by construction. Now **"5 of 104 assessed"**.

**Also fixed in this rung.** A genuine honesty-rail break: **NIWO** (tundra bucket, `ba` 31.1 m²/ha)
rendered treeless while its caption claimed "built from … measured standing wood" — the tundra branch
never reads `ba`. The claim is now made only when the bucket actually used the measurement, and the
unused figure is disclosed instead of asserted. Plus: **no page had a `<meta name="viewport">`**, so
every responsive rule was dead on real phones (mobile browsers laid out at ~980 px and scaled down);
added, along with the `<meta charset="utf-8">` all three pages were missing. `assemble_plot.py` read
and wrote with the platform's locale encoding and newline translation — on this Windows host that is
cp1252 + CRLF, which would corrupt the UTF-8 text and violate `.gitattributes eol=lf`; now explicit.

## Files (all under `prototypes/site-explorer/`, outside the app's build surface)

- `index.html` — the main explorer (self-contained; `site-data.json` + `map-data.json` inlined; ~133 KB).
- `walk.html` — the 3D scene (Three.js r128 inlined; ~1270 KB; deep-linkable via `?site=CODE`, case-insensitive).
- `plot.html` — "The Plot", SRER_048 (self-contained; ~952 KB). Built from `plot.src.html` by `assemble_plot.py`.
- `export_data.py` — reads `data/cascade.rds` + `neon-site-names.json` → `site-data.json` (real science
  **plus the provenance receipt**: bundle SHA-256, build time, schema, and the seven source-product commits).
- `assemble_index.py` — re-inlines `site-data.json` + `map-data.json` into `index.html`. Idempotent;
  replaces only the two tagged block bodies. (This step used to be a manual paste, which is not a build step.)
- `assemble_plot.py` — re-inlines the scene template + committed JSON into `plot.html` (needs no raw data or token).
- `build_map.py` — projects a US-states GeoJSON + site coords → `map-data.json`.
- `build_lidar.py` — a real CHM GeoTIFF (or a synthetic stand-in) → `lidar-<site>.json` height grid.
- `site-data.json` / `map-data.json` / `neon-site-names.json` — generated/fetched data.
- `lidar-{wref,scbi,harv,guan,teak,grsm,soap}.json` — real NEON AOP CHM height grids (derived; raw tiles never committed).
- `tex/*.jpg` + `proc_tex.py` + `embed_tex.py` + `tex/build_tex.md` — generated ground/bark textures (256px,
  embedded inline in walk.html) and their build pipeline + prompts (raw generations not committed).
- `README.md` — what it is, per-rung detail, how to regenerate.

**Nothing here touches the R/Shiny app**: `prototypes/` is outside `manifest.json`'s allowlist and the
rebuild's captured code surface (`R/`, `scripts/`, `www/`, top-level runtime files), so every PR's
`rebuild-contracts` CI passes on the unchanged exact-byte artifacts.

## Key facts / honesty rails (keep these true)

- **Every number names its vintage.** NEON products are versioned and revise prior data, and the sibling
  apps this bundle was built from keep moving. "From the committed bundle" is not provenance. The explorer
  footer carries the bundle SHA-256, build time and all seven source-product commits; The Plot's panel
  carries its product, access bound, release (currently **UNKNOWN**, with the reason) and bout composition.
  A field that cannot be recovered says `UNKNOWN` **and why** — never nothing.
- **The Plot is a two-bout composite, not a census.** Its 179 plants pool the 2016 (88) and 2021 (91)
  survey campaigns into one scene. The sibling's current contract treats the latest supported event per
  plot as current state and does not pool repeated events; the page says so, and the Survey filter lets
  you separate them.
- **Cover is over the surveyed area, and is summed not unioned.** VST mapped only the eastern half of
  SRER_048, so cover divides by 790 m², not the 1600 m² plot — dividing by the plot would count
  never-surveyed ground as measured zero. Crowns overlap, so `100 − cover` is **not** open interspace.
- **A scene may only claim a measurement it actually used.** The tundra branch ignores `veg_ba_ha`, so
  NIWO must not say it was "built from measured standing wood" (it renders from ground cover alone); the
  unused figure is disclosed instead. Same rule for grassland below its `ba > 2` threshold.
- The science is **real** from the committed bundle: the one solid pooled result is `temp → green-up`,
  **15 of 18 sites, p = 0.004**. Single-site values are framed as *direction, never significance*
  (no short series can be significant); context-only measures are labelled "not counted in the network test".
- The **year wheel is a per-biome schematic** (the bundle has annual, not monthly, data) — labelled as such.
- The **3D vegetation is a procedural impression** from measured standing wood — **except the seven forest
  sites WREF, SCBI, HARV, GUAN, TEAK, GRSM, SOAP**, whose canopies are **real NEON AOP LiDAR scans**
  (DP3.30015.001; a site gets a real canopy when a `lidar-<site>.json` grid exists, keyed by site code). TEAK
  (Lower Teakettle, Sierra Nevada) is the tallest — real heights to ~59 m (tile
  `NEON_D17_TEAK_DP3_321000_4097000`, 2024); GRSM (Great Smoky Mountains) is a dense closed-canopy stand to
  ~46 m (tile `NEON_D07_GRSM_DP3_273000_3952000`, 2022); SOAP (Soaproot Saddle) is an open foothill woodland
  (~42% forested, tile `NEON_D17_SOAP_DP3_298000_4100000`, 2024). All 46 sites are walkable. To add another:
  `build_lidar.py <SITE> <CHM.tif>` → inline as `<script id="lidar<SITE>">`.
- **Real-LiDAR forests are walkable** (Rung 20): the CHM gives canopy height per 3 m cell, but placing a trunk
  at every cell made a dense grid-wall you couldn't see through. `buildField` now derives **sparse stems** —
  greedy tallest-first thinning with a minimum spacing (`minSp` cells) + off-grid jitter + height-varied
  thickness — so a forest reads as a walkable interior with sightlines, not a lattice. The **canopy/floor are
  unchanged** (still the full real height model); only the stems are thinned. Far fewer instances, so it also
  renders lighter.
- The **ground/bark textures are AI-generated stylised impressions** (Rung 19), not real ground photography
  of any site — they convey biome *feel* (forest floor, dry prairie, desert sand, tundra moss, bark), not
  measured surface data. Embedded inline (CSP-safe); the flat-shaded canopy stays untextured.
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
- **Drifting clouds are procedural** (Rung 13): a 5-octave value-noise (fbm) layer inside the sky-dome
  fragment shader, drifting on a `time` uniform advanced from the loop (frozen under reduced motion). Broken
  cover, upper-hemisphere only; lit by the **current sun** via a `sunI` uniform (set in `applyTOD`), so clouds
  are bright by day, warm-rimmed near the sun, and fall to dark wisps at night. Cloud **cover varies by biome**
  (Rung 15) via a `cloudAmt` uniform (`CLOUD_AMT` by bucket, set in `build()`): deserts read clearer (~0.34),
  humid forests cloudier (~0.82). It's a **procedural sky, not a
  weather feed** — no real cloud data.
- **Visual overhaul, stage 1** (Rung 16): the render pipeline now has **soft sun shadows** (PCFSoft; the sun
  and its shadow frustum follow the walker; canopy/trunks/shrubs/cactus cast, ground receives; shadows only
  while the sun is above the horizon, so dawn/dusk get long shadows and night none), a **key-dominant warm
  light** (in `applyTOD`, `sun.intensity*1.35` / `hemi.intensity*0.66`, so shadows actually read and forests
  get dappled light), and **distant horizon hills** (a camera-following ridge ring, `RIDGE_AMP` by biome,
  tinted to the horizon colour and dimming into night — a hazy silhouette, `MeshBasicMaterial` with `fog:false`).
  Stage 2 is underway: **filmic tone mapping** (Rung 17) applies **ACES** on the renderer
  (`toneMapping=ACESFilmicToneMapping`, exposure 1.12) *and* the **same ACES curve inside the sky shader**
  (`aces(c*1.12)`) so the custom-shader sky and the tone-mapped standard materials stay consistent (no horizon
  seam) — output stays linear-encoded to avoid the r128 sRGB-workflow footgun. It's a subtle filmic lift,
  strongest at golden hour (warm rim light rolls off nicely). Still to come: richer geometry, then generated
  textures (the owner has a ChatGPT Pro account for the image batch; ~37 Higgsfield credits reload in ~20 days
  — plan a bigger batch then). Everything stays reduced-motion-aware (with a static camera, frames are
  byte-identical under reduced motion).
- **Richer geometry** (Rung 18): scattered **ground detail** — small pebbles everywhere (biome-scaled `rockN`)
  plus **fallen logs** in forest/grassland/mixed — so the floor isn't bare (all rigid + shadow-casting); the
  distant ridge is now **two layered rings** (near = taller/darker at R=300, far = lower/hazier at R=365, via
  vertex colours) for atmospheric depth; and procedural **deciduous crowns are rounder** (icosa detail 1). The
  **generated-texture** stage is done (Rung 19, #29): seven stylized textures from an image model
  (nano-banana via Higgsfield, ~14 credits) — 5 biome grounds + 2 barks — down-res'd to 256px and **embedded
  inline as base64 data-URIs** (CSP-safe, ~163 KB total; walk.html ≈ 1.26 MB). They map only onto the **smooth
  surfaces**: the ground plane by biome bucket (`groundMesh`, repeat ≈ 58) and the tree trunks (bark, repeat
  2×6), keyed by tree shape (conifer vs deciduous). The **flat-shaded canopy stays untextured** so the textures
  enhance rather than fight the low-poly look. Absent texture ⇒ flat-colour fallback, no other change.
  Reproducible: `tex/*.jpg` + `proc_tex.py` + `embed_tex.py` + `tex/build_tex.md` (prompts) are committed;
  raw multi-MB generations are not. It's a **stylized impression**, not real ground photography of any site.
- **Wind is shown, not just heard** (Rung 12): the canopy gusts on the same ~14 s cycle (0.07 Hz) as the audio
  wind LFO — the flexible foliage (crowns, grass, shrubs, tufts) leans downwind and flutters harder during
  gusts, while **trunks, cactus and rocks are rigid** (tagged `userData.rigid`, kept in `world` not the sway
  group) so a gust never distorts their bases. It's a **gentle, procedural gust**, reduced-motion-aware (no
  sway when the OS asks for reduced motion) — an impression of wind, not measured wind speed.
- The **day-to-night lighting is illustrative** (Rung 8): a time-of-day slider (`TOD` keyframes → `applyTOD()`)
  blends the sky-shader colours, arcs the sun's direction/colour/intensity, and dims the hemisphere light and
  fog from dawn → midday → dusk → night. The **midday stop (0.40) uses each site's own daytime palette and the
  original sun defaults, so the default load looks identical to before** (no regression); the other stops blend
  a universal sky over the biome. It's a **mood/lighting illustration, not a modelled solar position** for any
  site's latitude or date.

## How to regenerate / verify

```bash
pip install rdata
python3 prototypes/site-explorer/export_data.py            # -> site-data.json (+ provenance receipt)
python3 prototypes/site-explorer/build_map.py us.json       # -> map-data.json (us.json = a US-states GeoJSON)
python3 prototypes/site-explorer/assemble_index.py          # -> re-inlines both into index.html (idempotent)
```

The re-inline used to be a manual paste. It is a build step now: `assemble_index.py` replaces only the
bodies of the two tagged `<script>` blocks, parses each JSON first (so a malformed file fails loudly
instead of shipping), and is a no-op when the data has not changed.
Verify headlessly with Chromium at `/opt/pw-browsers/chromium-1194/chrome-linux/chrome` via
`playwright-core` (WebGL needs `--enable-unsafe-swiftshader`). Every rung was checked for 0 console/page
errors, correct rendering, and no 390 px mobile overflow before merge.

## Working rhythm (owner's instruction)

Stage-by-stage: build an increment → verify headlessly → commit/push → open draft PR → merge when CI is
green → reset the branch onto the new master → next increment. Branch: `claude/neon-suite-expansion-c0wl9k`.

## Next up (Rung 11+ — further polish)

Done since Rung 6: the **headline driver in-scene** (Rung 6, #15), the **per-biome soundscape** (Rung 7, #16),
the **day-to-night lighting** (Rung 8, #17), **TEAK on real AOP LiDAR** (Rung 9, #18), and the **living
(time-of-day-linked) soundscape** (Rung 10, #19), **GRSM on real AOP LiDAR** (Rung 11, #20), **visible wind** (Rung 12, #21), **drifting clouds**
(Rung 13, #22), **SOAP on real AOP LiDAR** (Rung 14, #23), and an **audit & polish pass** (Rung 15, #24 —
biome-varied cloud cover, the idle chirp timer now stops when muted, doc accuracy). Seven forest sites now
render from **real AOP LiDAR** — WREF, SCBI, HARV, GUAN, TEAK, GRSM, SOAP
(grids committed as `lidar-<site>.json`, inlined as `<script id="lidar<SITE>">`). Remaining nice-to-haves:
**still more forest sites on real LiDAR** — pick another site (e.g. BART, or an Alaskan boreal stand), download its CHM
tile via the NEON API (`X-API-Token`; the token is stashed at scratchpad `.neon_token`), then
`build_lidar.py <SITE> <CHM.tif>` → inline `lidar-<SITE>.json` (recipe above); richer bird/insect voices; or
distant terrain relief on the horizon. No external data is needed for the last two.

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
