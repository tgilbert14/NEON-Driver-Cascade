# The Plot — SRER_048 real-data reconstruction (test)

`plot.html` reconstructs one real NEON plot (**SRER_048**, Santa Rita Experimental Range,
Sonoran desert) **plant by plant**: every plant is a real tagged individual placed at its
real mapped position, coloured live vs standing-dead, and — for the 104 plants NEON actually
measured — drawn at its real height and crown; the other 75 (70 cacti plus 5 unmeasured woody) are
drawn at a species-typical size and marked with an open ring, and
**clickable to read its actual NEON record** (species, individualID, tag year, measured
height/crown, status).

## Data sources (all NEON, via the API with an `X-API-Token`)

- **Vegetation Structure — DP1.10098.001** (the core):
  - `vst_mappingandtagging` → per-plant `individualID`, `taxonID`/`scientificName`, and
    position as `pointID` + `stemDistance` + `stemAzimuth`.
  - `vst_apparentindividual` → per-plant `height`, `maxCrownDiameter`, `plantStatus`, `growthForm`.
- **Locations API** (`/api/v0/locations/SRER_048.basePlot.vst.<pointID>`) → each grid point's
  UTM coordinate. Plant position = point + `stemDistance·[sin(az), cos(az)]`, recentred to the
  surveyed cloud's centre.

SRER_048 has **179 mapped plants across 9 species** — creosote bush ×93, Christmas cholla ×53, velvet
mesquite ×13, fishhook barrel ×7, Engelmann prickly pear ×6, Graham's pincushion ×3, longleaf jointfir ×2,
mariola ×1, saguaro ×1.

**But "9 species" is a *mapping* count, not a measured-community count.** Only **104 plants across 4
species** carry a structural measurement (creosote, mesquite, jointfir, mariola). The other 75 — **70 cacti
and 5 woody** — have a mapped position and nothing else, and 5 of the 104 are whole-plant standing dead.

That split is protocol, not a data gap. NEON's standard woody protocol **does not map cacti at all**; Santa
Rita (Domain 14) carries a written site-specific exception to *map* large-stature cacti, and cacti are
*measured* under a separate Cactus SOP (`NEON.DOC.001715`) whose records do not land in
`vst_apparentindividual`. So every cactus here is a real, really-positioned plant with no height by design.

Two further consequences worth stating before anyone compares years:

- **All five cactus species carry 2021 tag dates and none carry 2016.** The site-specific cactus exception
  postdates the 2016 bout, and the cactus campaign needs its own spring visit. These plants were almost
  certainly standing here in 2016 (a saguaro is decades old) — they were not yet in the survey's scope.
- **Velvet mesquite changed measurement basis mid-record**: measured as a tree at DBH before 2020, as a
  shrub at basal diameter from 2020 onward. 2016-tagged mesquites in this file carry basal diameter, which
  indicates the build joined each plant's **latest** measurement rather than its tagging-era one — so the
  condition shown is closer to a ~2021 snapshot than to the year in the `date` field.

## Build

`build_plot.py` (kept in the working scratchpad; needs the raw VST CSVs + token, which are **not**
committed) joins the tables, computes positions, maps each `taxonID` → a growth-form model +
common name, and writes the derived **`plot-srer048.json`** (committed). `plot.src.html` is the
scene template; the shipped `plot.html` is `plot.src.html` with Three.js r128, `plot-srer048.json`,
and the desert ground texture inlined.

## Rebuilding / handoff (works in a fresh clone)

The everyday loop is just **edit the scene template, then re-inline**:

```bash
# after editing plot.src.html
python3 prototypes/site-explorer/assemble_plot.py    # -> plot.html (self-contained)
```

`assemble_plot.py` is **committed** and depends only on files in this directory: it fills the four
template placeholders (`__THREE__`, `__PLOTDATA__`, `__GROUNDTEX__`, `__GEOLAYERS__`) by **reusing the
heavy embeds verbatim from the existing `plot.html`** (the Three.js runtime, the ground texture, and the
NEON AOP layers) plus the small committed JSON (`plot-srer048.json` + `div-srer.json`). It needs **no raw
NEON data, no image tiles, and no API token**, so any session can iterate on the scene and regenerate the
shipped page. (It reproduces the current `plot.html` byte-for-byte.)

Only the **from-scratch data builders** stay in scratchpad (they pull bulk raw NEON downloads that are not
committed) — recipes are in this doc:
- `build_plot.py` → `plot-srer048.json` (raw VST `vst_mapping`/`vst_apparent` CSVs + an `X-API-Token`).
- `div_srer.py` → `div-srer.json` (the SRER plant-diversity CSV + token).
- `geo_plot.py` → the georeferenced AOP crops that feed `__GEOLAYERS__` (raw ortho/CHM GeoTIFF tiles + token).

Verify headlessly with Chromium + swiftshader (WebGL) and confirm **0 console/page errors** before shipping
(the same rhythm the rest of the site-explorer uses).

Plant models are **botanically accurate per species**, keyed on the real NEON `taxonID` and
built from sourced descriptions (SEINet / Flora of North America / USDA PLANTS / ASDM / Lady
Bird Johnson WC) so each reads as that actual plant:

- **LATR2 Creosote bush** — open see-through vase of thin jointed grey stems (swollen dark
  nodes) with sparse dark-olive resinous tufts at the tips.
- **CYLE8 Christmas cholla** — thin wiry canes with near-perpendicular terminal branchlets and
  bright-red persistent winter fruit.
- **PRVE Velvet mesquite** — crooked multi-trunk under a broad, feathery, wider-than-tall
  pale-green umbrella (trunk kept visible).
- **OPEN3 Engelmann prickly pear** — trunkless mound of flat obovate pads fanning up-and-out in
  varied planes.
- **FEWI Fishhook barrel** — ribbed keg leaning south ("compass barrel"), woolly tan apex,
  crown ring of yellow fruit, a few reddish hooked central spines.
- **MAGR9 Graham's pincushion** — ankle-high frosted green globe with a pink flower halo.
- **EPTR Longleaf jointfir** — airy broom of thin erect green rods, three-forked.
- **PAIN2 Mariola** — low dense silvery-grey cushion.
- **CAGI10 Saguaro** — tall fluted green column (juveniles armless; upcurving arms on mature
  giants). SRER_048's individual is a 0.5 m juvenile post.

Each plant also carries a transparent pick-proxy so even the thinnest cactus is reliably
clickable. Standing-dead woody plants render as bare grey skeletons; only soft-tissue plants
sway. Only the derived JSON + `plot.src.html` are committed (the shipped `plot.html` is
regenerated by inlining Three.js + the JSON + the desert ground texture + the AOP layers).

## Views

- **Walk** — first-person (drag to look, W A S D, click to inspect).
- **Sky view** — top-down orthographic map (drag to pan, scroll to zoom); each plant has a
  species-coloured ground disc so it reads as a NEON crown/survey dot-map.
- **Ground toggle** — cycles the ground between the stylized desert texture, a **real NEON AOP
  aerial photo**, and a **colorized LiDAR canopy-height** layer, both georeferenced under the plot.

## Real-world ground layers (NEON AOP, georeferenced)

`geo_plot.py` (scratchpad) drapes real NEON Airborne Observation Platform imagery over the plot:

- **Ortho** DP3.30010.001 (10 cm true-colour) and **CHM** DP3.30015.001 (1 m canopy height), the
  **2021-09** SRER flight (contemporaneous with the plot's 2021 re-survey), tile `515000_3530000`.
- **Georeference:** the scene origin (0,0) is the surveyed cloud's bbox-centre UTM
  **E=515527.413, N=3530802.807** (zone 12N) — exactly how `build_plot.py` recentres the plants
  (`easting = originE + scene_x`, `northing = originN + plant_y`). A 64 m square is cropped
  north-up/east-right. In the scene, plants are placed at `(x, 0, −y)` so **scene north = −Z**; the
  drape (`PlaneGeometry(64,64)`, `tex.flipY=true`) matches, so the top-down **Sky view** is a true
  **north-up / east-right** map (with an on-screen compass). Plants + drape flip together, so their
  mutual alignment is preserved.
- **Validation:** the CHM was sampled (3×3 max) at each plant's UTM position — mean canopy height
  under the mesquites is **1.70 m** (matching their real ~2 m stature), and the correct origin beats
  a deliberate +40 m shift. On the photo, plant positions land on dark shrubs (mean brightness 57
  under plants vs 115 over the whole crop) and the dry wash sits on the east side — confirming the
  transform. (1 m CHM barely resolves sparse desert shrub, so the height correlation is modest; the
  photo overlay is the strong check.) The shipped page carries a viewer-facing NEON attribution +
  an "approximate, not surveyed" caveat when a real-world layer is on.
- Both layers are down-sized (ortho 512 px JPEG, CHM 256 px PNG) and embedded as inline data-URIs,
  so `plot.html` stays fully self-contained (CSP-safe). Google Maps/Earth tiles are **not** usable
  (not redistributable + the artifact CSP blocks live embeds); NEON AOP shares our UTM grid and is
  openly licensed, so it is the correct source.

Alignment is approximate, not surveyed: NEON stem mapping is ~sub-metre, and the 2021 flight
postdates the 2016 tags for many plants (some grew or died), so treat the overlay as "our plot on
its real ground", not a pixel-perfect per-plant registration.

## Per-individual variation

Beyond the accurate per-*species* base models, each **measured** individual (104 of 179 — the woody
plants; cacti have no VST apparent record) is shaped by its own record, pulled into the JSON by
`build_plot.py`:

These plants are **multi-stem**: an individual has one crown/height row plus many per-stem rows, each with a
`basalStemDiameter` and its own `plantStatus`. `build_plot.py` aggregates across the stems:

- **`stems`** — real stem count (median 11, up to 45).
- **`dead`** — how many of those stems are standing dead. A plant is only `status: "dead"` when **every** stem
  is dead (SRER_048: 5 fully dead, 80 partially-dead, 19 all-live — *not* the 28 a per-stem read implied).
  Those 104 are the plants carrying a VST apparent-individual record. The other **75 are 70 cacti + 5 woody**
  (3 mesquite, 2 creosote) — not "75 cacti" as an earlier version of this doc said. So whole-plant
  mortality is reported as "5 of 104 assessed", never "of 179".
- **`bd`** — mean `basalStemDiameter` (cm) → stem/trunk thickness.
- **`cr90`** — `ninetyCrownDiameter` (m) → the crown is drawn **elliptical** (`maxCrownDiameter` × `cr90`).
- **`shape`** — recorded canopy shape → foliage vertical profile. **`canopy`** = `canopyPosition`,
  **`dmg`** = any live stem is insect/physically damaged.

Creosote renders its real stem count with the dead fraction as bare grey stems among green live ones; the card
reads e.g. "16 stems · mean ⌀ 2.8 cm … live · 7 of 16 stems standing dead · some damage". Positions are
untouched, so the AOP georeference stays valid. The surveyed extent is marked in-scene by an amber boundary.

## Plot geometry

The SRER base plot is **40 × 40 m** (confirmed via `locations/SRER_048.basePlot.vst`), centred at UTM
(515517.4, 3530803.0). The scene is anchored to that plot centre, so plant coordinates are `E−CX, N−CY`
(no cloud recentring). The woody plants were mapped in the plot's **eastern half**; the AOP crop is a 50 m
window (`HW=25`) centred on the plot.

## Ground cover & species (the "Cover & species" panel)

- **This plot (from our VST crowns): a woody crown area INDEX, not a cover percentage.** The panel reports

  ```
  crown area index = Σ π · (cr / 2) · (cr90 / 2)   over the 99 live woody plants NEON MEASURED
                     ──────────────────────────────
                            800 m²                  (the two 20 × 20 m subplots NEON sampled)
                   = 370 m² / 800 m² = 0.46 m² of crown per m² of ground
  ```

  This replaced an earlier "~53.9% canopy cover" that was wrong three ways (all recorded in
  `PROGRESS.md`):

  1. **13% of the numerator was invented.** The 75 plants with no crown measurement carry a
     *per-species constant* (`cr90` absent), and the old sum gated on `status == "live"` rather than on
     whether a crown was measured, so those defaults were summed as data. The index gates on `cr90`
     being present.
  2. **The denominator is 800 m² by design, not a 790 m² bounding box.** A 40 × 40 m base plot is
     sampled in two of its four 20 × 20 m subplots, randomly selected (protocol Table 10). The mapped
     plants fall in the eastern half because that is where the two sampled subplots are — it is the
     sampling design, **not** ground that was skipped. `area_trees = 800 m²` in the Vegetation
     Structure bundle confirms it.
  3. **It is not a cover percentage.** Crowns overlap (a sum is not a union), and each crown is
     measured from its two *maximum* diameters at right angles, so the ellipse circumscribes an open
     desert crown. It is reported as an index in m²/m², never a percentage of ground.

  **Cacti are excluded entirely** — NEON measures them under a separate Cactus SOP against a different
  sampled area, and Santa Rita maps only large-stature individuals, so they are a mapped subset, not a
  census. They are reported as a count and species list. **Unresolved and stated on the page:** the
  800 m² assumes the woody plants were searched across the full selected subplots; if they came from
  nested subplots the denominator is smaller and the index higher. Settling it needs `subplotID` per
  record, which the committed file does not carry.
- **SRER ground layer (site diversity):** SRER_048 is a VST plot and is **never** a plant-diversity plot, so
  `div-srer.py` aggregates SRER **site-level** plant diversity (DP1.10058.001, 2024 growing season) into
  `div-srer.json` — ground categories (litter ~57%, bare soil ~26%, rock, biocrust) and top understory species
  (Lehmann lovegrass, black grama, tanglehead, burroweed, fairy duster). Clearly labelled as site-level context
  for the interspaces, not this exact plot. `assemble_plot.py` inlines it as `DATA.siteDiv`.

A **"Plants: on/off"** toggle hides the 3D models (keeping the ground dots + click-inspect) to compare the
mapped positions against the aerial / canopy layers.

## Analysis & map controls

- **Colour-by** — the "Colour" button cycles the ground-ring colour through **species → height → stems → dead**.
  Non-species modes swap in a continuous ramp (short→tall, few→many stems, share of stems standing dead) and show
  a gradient scale legend, turning the crown dot-map into a quick single-variable data-viz.
- **Survey filter** — the "Survey" button cycles **2016+2021 → 2016 only → 2021 only**, hiding plants not tagged
  in that bout (each plant carries its tag `date`). **These are first-tag cohorts, not re-surveys.**
  `vst_mappingandtagging` holds one row per individual — the date its tag went on — so a plant is tagged
  once and re-measured in later bouts. Grouping by that date therefore *cannot* show the same plant twice;
  zero overlap between 2016 and 2021 is forced by the table's structure and is **not** evidence of
  recruitment, mortality or turnover. The UI control is labelled "First tagged" for that reason, and shows
  an explanatory note whenever it is narrowed.
- **Legend chips are filters** — click any species chip to show/hide it; the chip dims + strikes through.
- **Unmapped-area shade** — a light dark plane over the plot's western half makes it obvious that NEON
  sampled two of the four 20×20 m subplots (here, the eastern pair), rather than the west looking like
  missing data. It is the sampling design, not a survey that skipped that half.
- **This plot at a glance** — the "Cover & species" panel opens with a live analysis block (tagged plants +
  species, per-campaign tallies, density per 100 m² surveyed, mean/tallest height, total/live/dead stems, whole
  plants dead), all computed from the VST records in the browser.
- **About-first** — the top-left plot notes are readable by default (dark backdrop on); a "ⓘ Hide info" button
  clears it so the map reads clean, and flips to "ⓘ About" to bring it back.

## Planned expansions (see chat brainstorm)

Phenology (animate leaf-out/flower/senescence through the year per individual), a link from the
travel-map/desert walk into the plot, and more plots.
