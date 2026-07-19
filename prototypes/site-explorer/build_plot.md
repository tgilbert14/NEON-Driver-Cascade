# The Plot — SRER_048 real-data reconstruction (test)

`plot.html` reconstructs one real NEON plot (**SRER_048**, Santa Rita Experimental Range,
Sonoran desert) **plant by plant**: every plant is a real tagged individual placed at its
real mapped position, sized by its real height/crown, coloured live vs standing-dead, and
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

SRER_048 has **179 mapped plants, 9 species** (creosote bush ×93, Christmas cholla ×53, velvet
mesquite ×13, fishhook barrel cactus, Engelmann prickly pear, Graham's pincushion, longleaf
jointfir, …), 104 with measured heights, 28 standing dead.

## Build

`build_plot.py` (kept in the working scratchpad; needs the raw VST CSVs + token, which are **not**
committed) joins the tables, computes positions, maps each `taxonID` → a growth-form model +
common name, and writes the derived **`plot-srer048.json`** (committed). `plot.src.html` is the
scene template; the shipped `plot.html` is `plot.src.html` with Three.js r128, `plot-srer048.json`,
and the desert ground texture inlined.

Growth-form models (low-poly, distinct): creosote (airy multi-stem shrub), cholla (branching
cylinder segments), tree/acacia (trunk + feathery canopy), prickly pear (flat pads), barrel
(ribbed squat cylinder), pincushion (tiny ball), ephedra (green broom), small shrub (low mound).
Standing-dead individuals render grey/bare. Only the derived JSON + `plot.src.html` are committed.

## Planned expansions (see chat brainstorm)

Plant diversity (% cover → ground/understory), phenology (animate leaf-out/flower/senescence
through the year per individual), a link from the travel-map/desert walk into the plot, and more
plots.
