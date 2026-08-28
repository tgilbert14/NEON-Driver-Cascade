# Suite incident: CARTO stamps "API KEY REQUIRED" on every basemap tile

**Status: DIAGNOSED — root cause verified and measured. The FIRST proposed fix was refuted by evidence (§3)
and replaced by a per-role plan (§4). Two owner decisions (§5) now block rollout. Nothing applied to the
nine apps yet.**
**Opened 2026-08-28 · Driver-Cascade branch `claude/neon-maps-api-key-eocg8r` · tagged `[Claude]`.**

This is the suite-wide record for the basemap outage reported on 2026-08-28: the maps in the
NEON explorer apps display a large diagonal watermark reading **"API KEY REQUIRED —
carto.com/basemaps/apikey"** across the basemap. Driver-Cascade is the suite hub, so the
advisory lives here even though **Driver-Cascade itself is NOT affected** (it ships no Leaflet
map — verified: no `leaflet`, `addTiles`, or `addProviderTiles` anywhere in `global.R`, `ui.R`,
`server.R`, or `R/`).

---

## 1. What is actually happening

CARTO now watermarks **unauthenticated** raster tiles served from
`https://{s}.basemaps.cartocdn.com/…`. The watermark is **burned into the tile image
server-side**. The request still returns `HTTP 200` with a valid PNG, so nothing in the app
errors, logs, or falls back — the map simply renders defaced.

### Reproduction (verified live, 2026-08-28)

```sh
curl -s -o carto_light.png "https://a.basemaps.cartocdn.com/light_all/6/13/24.png"   # CartoDB.Positron
curl -s -o carto_dark.png  "https://a.basemaps.cartocdn.com/dark_all/6/13/24.png"    # CartoDB.DarkMatter
```

Both return `HTTP 200`, `image/png`, 256×256 (6465 B and 5884 B respectively). Opening either
image shows a real Colorado basemap overprinted with a grey diagonal
`API KEY REQUIRED / carto.com/basemaps/apikey`. Both the light and dark variants are affected.

### What it is NOT — ruled out with evidence

Each of these was checked and eliminated, so no future session needs to re-walk them:

- **Not an R package regression.** `leaflet.providers` **2.0.0** and **3.0.0** were both
  downloaded from CRAN and their bundled `leaflet-providers.js` compared directly. The
  `CartoDB` and `Esri` URL templates are **byte-identical between the two versions**, and
  neither carries an `{apikey}` placeholder. Eight apps pin `leaflet.providers` 3.0.0 and the
  Water-Chemistry app pins 2.0.0 — **both are equally affected**, which is itself proof the
  package version is not the variable.
- **Not a leaflet-providers API-key check.** The bundled JS only ever throws
  `No such provider (…)` / `No such variant of …`. It has no API-key error path. The
  `<insert your api key here>` placeholders in that file belong to Thunderforest, Jawg,
  Mapbox, MapTiler, TomTom, HERE and OpenWeatherMap — **providers this suite does not use**.
- **Not a referer / origin / CORS block.** The tile was re-fetched with a browser
  `User-Agent`, with `Referer` set to a live `*.share.connect.posit.cloud` app URL, and with
  full `Origin` + `Sec-Fetch-*` headers. **All three return the identical watermarked bytes**
  (`md5` prefix `00f0cd56cfe1` in every case).
- **Not a Posit Connect Cloud problem**, not a CSP problem, not a manifest-pin problem, and
  not something a redeploy can clear. Re-deploying the identical manifest re-fetches the same
  watermarked tiles.
- **Not an app-side string.** `grep` across all nine repos finds **no** occurrence of
  "api key" / "apikey" / "access token" in any app's own R, JS, CSS or HTML.

### Esri is currently clean

Tiles from `https://server.arcgisonline.com/ArcGIS/rest/services/{variant}/MapServer/tile/{z}/{y}/{x}`
were fetched and visually inspected for `World_Topo_Map`, `World_Imagery`, `World_Street_Map`,
`NatGeo_World_Map` and `Canvas/World_Light_Gray_Base` — **all keyless, all unwatermarked**.
That is why the apps whose *main* map defaults to an Esri layer look fine until the user
switches the Basemap select to "Light".

> **Caveat that belongs on the number:** Esri has publicly announced that these legacy ArcGIS
> Online basemap tile services are deprecated and being sunset in favour of the newer ArcGIS
> basemap layer service (which is keyed). Moving to Esri is a **fix with a shelf life**, not a
> permanent answer. See §5.

---

## 2. Blast radius — all nine companion apps, on first load

Every companion app puts a `CartoDB.Positron` layer on its **landing / site-picker map**, which
renders with **zero user interaction**. So the watermark is the first thing a visitor sees in
all nine apps, regardless of what the main explore map defaults to.

| App | Repo | CARTO call sites (file:line) | Watermark visible without interaction |
|---|---|---|---|
| Small Mammal | `neon-small-mammal-tracker-app` | `server.R:1189` (pickerMap), `server.R:2515` (DarkMatter fallback), `ui.R:622-623` (choices) | **Yes** — picker map |
| Plant Diversity | `neon-plant-diversity` | `R/map_picker.R:58`, `ui.R:458` (choices) | **Yes** — picker map |
| Vegetation Structure | `neon-vegetation-structure-explorer` | `R/map_picker.R:88`, `server.R:1375`, `server.R:1398`, `ui.R:259-260` (`selected =`) | **Yes** — picker *and* main map default |
| Breeding Birds | `neon-breeding-birds` | `server.R:711`, `server.R:723`, `ui.R:298` (choices) | **Yes** — `nationalPicker` |
| Plant Phenology | `neon-plant-phenology-explorer` | `server.R:145`, `server.R:177`, `server.R:779`, `ui.R:215` (choices) | **Yes** — `nationalMap` *and* main map default |
| Mosquito Pulse | `neon-mosquito-pulse` | `server.R:578`, `server.R:588`, `ui.R:229` (choices) | **Yes** — `nationalPicker` |
| Ground Beetle | `neon-ground-beetle-tracker` | `R/map_picker.R:57`, `server.R:1633` (theme-aware Positron/DarkMatter) | **Yes** — picker *and* main map, both themes |
| My Little Inverts | `neon-my-little-inverts` | `server.R:940`, `server.R:963` (`providers$CartoDB.Positron`) | **Yes** — `nationalPicker` |
| Water Chemistry | `neon-waterchemistry-analyte-viewer-app` | `app.R:2110` | **Yes** — the only map |
| **Driver-Cascade** | `NEON-Driver-Cascade` | **none** | **No — unaffected** |

Line numbers are from each repo's default-branch HEAD as cloned on 2026-08-28. **Re-verify them
before patching** — they are a navigation aid, not a contract.

> ⚠️ **Branch defaults are SPLIT across the suite.** Driver-Cascade is `master`; Small Mammal
> and Vegetation are `main`. Never assume — check each repo before branching or pushing.

---

## 3. The first proposed fix — and why the evidence overturned it

The initial plan was: swap every `CartoDB.Positron` for `Esri.WorldGrayCanvas`, and synthesise a dark
canvas with a CSS filter. **A measured audit refuted that plan on four independent grounds.** Both of the
decisive findings were then re-verified by hand, and both hold. The record is kept here rather than
quietly rewritten, because the *reason* the first answer was wrong is the useful part.

### 3.1 `Esri.WorldGrayCanvas` goes BLANK at plot scale — measured

`Esri.WorldGrayCanvas` is the variant `Canvas/World_Light_Gray_Base`. Esri's legacy raster canvas has had
**no content update since 2021**, and at NEON's rural sites it simply runs out of data:

| Tile (SCBI, 38.893 N 78.140 W) | Distinct RGB values in the 256×256 tile |
|---|---|
| `World_Light_Gray_Base` z13 | **224** — hairline roads, no labels, near-white |
| `World_Light_Gray_Base` z16 | **1** — a single flat `RGB(239,239,239)`. Literally blank |
| `World_Topo_Map` z13 | **3,912** — roads, contours, named streets |
| `World_Topo_Map` z16 | **717** — full detail |

The audit ran the same measurement across the coordinates of **all 46 NEON terrestrial sites**: at z16,
**17 of 46 (37%) return a single-colour blank tile** — including SCBI, TREE, UNDE, ORNL, CPER, CLBJ, SRER,
WOOD, DCFS, UKFS, OAES, NIWO, KONZ, BONA, DEJU, HEAL, TOOL. At z15, 9 of 46. Above z16 every request
returns an identical 2,521-byte "Map data not yet available" placeholder. Every other candidate tested —
`Esri.WorldTopoMap`, `Esri.WorldImagery`, `USGS.USTopo`, `USGS.USImageryTopo`, `OpenStreetMap.Mapnik`, and
`CartoDB.Positron` itself — was **0/46 blank**.

**Consequence:** on the plot-scale maps, whose entire purpose is 20 m vegetation plots and 10 m trap grids,
the "fix" would trade a defaced-but-legible basemap for markers floating on a featureless grey field. In
Vegetation Structure that blank field lands under the app's "held is not zero" empty-state message — a
science-communication regression, not a cosmetic one.

**The proposed `maxNativeZoom = 16` mitigation does not mitigate.** SCBI z15 and z16 are byte-identical;
the option upscales an already-blank tile and *hides* the defect from a visual check. It is a zoom-control
fix only — it stops Leaflet hard-stopping the zoom slider at 16, nothing more.

### 3.2 There IS a keyless dark canvas — the CSS-invert plan is unnecessary

The earlier claim in this document that "there is no keyless dark canvas" was **wrong**, and the error was
in the question, not the search: the check asked whether *leaflet-providers* exposes a dark canvas, never
whether *the provider* serves one. It does.

```
https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}
https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}
```

Verified live: z4 returns a 5,456-byte JPEG, **283 distinct colours, dominant `RGB(63,63,65)`** — a real,
dark, unwatermarked canvas carrying country and ocean labels. It is keyless and needs no referer. It is
absent from `leaflet.providers`, so it needs a raw `addTiles()` rather than `addProviderTiles()`.

**This supersedes the CSS-invert decision.** A real dark basemap beats a synthesised one, costs the same
raw `addTiles()` call, and avoids filtering artefacts entirely. The CSS-invert route is recorded as
**REJECTED — superseded**, not as an open task.

### 3.3 The swap makes marker contrast WORSE, not better

Measured grounds: Positron land `#fafaf8`, Esri Base land `#efefef`. Every marker palette in the suite is
*darker* than both, so a darker ground **reduces** contrast. Computed ratios, Positron → Esri:

| Marker | Positron | Esri Base |
|---|---|---|
| birds tundra `#7fc7ec` | 1.78 | 1.62 |
| birds NA `#9aa6b2` | 2.37 | 2.16 |
| phenology NA `#c4c0b2` | 1.74 | 1.58 |
| veg `grey_na` `#cfd6dd` | 1.40 | 1.28 |
| plant-diversity comp-low `#E7E0CC` | 1.26 | 1.15 |

Uniformly ~8–10% worse. Three of the per-app audits asserted contrast would *improve*; they had the sign
backwards. Worse, the white 1–1.5 px marker ring every picker uses scores **1.10:1** against `#efefef` —
with the base's linework gone, markers float with neither ground contrast nor surrounding structure.

### 3.4 The swap is an attribution REGRESSION

`leaflet.providers` 3.0.0 hardcodes the Esri canvas attribution as `Tiles © Esri — Esri, DeLorme, NAVTEQ`.
The service's own live metadata disagrees:

```sh
curl -s "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer?f=pjson"
# copyrightText: "Esri, HERE, Garmin, © OpenStreetMap contributors, and the GIS user community"
```

So the bundled string credits two entities that are no longer licensors (DeLorme was absorbed by Garmin,
NAVTEQ by HERE) and **omits the required OpenStreetMap credit** — separately an ODbL produced-work
attribution failure. The `CartoDB` entry in the same file emits `© OpenStreetMap contributors © CARTO`,
which is *correct today*. The naive swap therefore trades a compliant credit line for a non-compliant one.
In a repo whose house rule is "the caveat goes ON the number", shipping an affirmative misstatement of
provenance to fix a cosmetic watermark is the wrong trade.

The same stale-string defect already affects the Esri options this plan leaves alone (`World_Topo_Map`'s
live text also names HERE, Garmin and OpenStreetMap; `World_Imagery`'s names Vantor and Earthstar).

**Separately non-compliant today:** `neon-small-mammal-tracker-app/server.R:2491` and `:2514` set
`leafletOptions(attributionControl = FALSE)`, suppressing tile attribution entirely. That violates CARTO's
terms now and would violate Esri's after the swap.

### 3.5 Dark mode cannot be deferred

`neon-ground-beetle-tracker/server.R:1633` reads `tiles <- if (is_dark()) "CartoDB.DarkMatter" else
"CartoDB.Positron"` **inside** `renderLeaflet`, so flipping the theme toggle actively re-renders the map
with DarkMatter. Patching only the light branch leaves every dark-mode visitor a full-bleed 540 px
watermark. This must land in the same wave, not "separately".

---

## 4. The corrected plan — split by map ROLE

The single biggest correction: **there is no one right basemap here, because these apps have two kinds of
map with opposite requirements.**

### 4a. National site-picker maps (z2–5) → `Esri.WorldGrayCanvas`, keyless

At picker zoom the grey canvas is fine — 0/46 blank, and it carries country and ocean labels (verified by
eye at z4). It is a "pick a dot" navigation control, not a detail map. **Caveat to carry:** it shows
country outlines and a state-boundary hairline but *not* state or city names, where Positron did. If that
reads too bare, pair it with the keyless label layer
`Canvas/World_Light_Gray_Reference` (verified live, transparent PNG, 5,346 B at z4) via a raw `addTiles()`
— at the cost of doubling this suite's exposure to the sunsetting Esri service.

Apply to: small-mammal `server.R:1189`; plant-diversity `R/map_picker.R:58`; veg-structure
`R/map_picker.R:88`; breeding-birds `server.R:711` and `:723`; mosquito `server.R:578` and `:588`;
phenology `server.R:145` and `:177`; little-inverts `server.R:940` and `:963`; water-chemistry `app.R:2110`;
ground-beetle `R/map_picker.R:57`.

### 4b. Per-site / plot-scale maps → NOT the grey canvas

Do **not** put `Esri.WorldGrayCanvas` on any per-site map or in any Basemap dropdown. Either drop the
"Light" choice or point it at a provider with content at z13–16 (`Esri.WorldTopoMap`, `USGS.USTopo` and
`OpenStreetMap.Mapnik` all measured 0/46 blank).

Two apps currently **default** their plot map to Light and must change: `neon-vegetation-structure-explorer/ui.R:259`
(`selected = "CartoDB.Positron"`) and `neon-plant-phenology-explorer/ui.R:215` (Light is first, therefore
selected). Small Mammal, Birds and Plant Diversity already default to Satellite/Terrain.

### 4c. Dark → `Canvas/World_Dark_Gray_Base` via raw `addTiles()`

Not a CSS filter. See §3.2.

### 4d. Attribution must be set explicitly

Because the bundled provider strings are stale and drop the OSM credit (§3.4), any call that adopts an
Esri layer should pass an explicit `attribution` matching the service's live `copyrightText`, and
`attributionControl = FALSE` must come out of small-mammal `server.R:2491`/`:2514`.

### 4e. A string sweep is not sufficient

`neon-my-little-inverts/server.R:940` and `:963` use the **object form**
`leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron)` — no quoted provider name. A
`grep '"CartoDB'` leaves that app fully watermarked. Use:

```sh
grep -rn --include='*.R' -E 'CartoDB[."$]|cartocdn' .
```

The complete CARTO surface is **22 lines across 9 repos**. `R/map_picker.R` is a *forked shared module*
present in three repos (ground-beetle:57, plant-diversity:58, veg-structure:88) and must move in lockstep.

---

## 5. Two questions that should have been asked first

Both could dissolve most of the work above. Neither has been put to the owner:

1. **Is there a University of Arizona institutional ArcGIS Online licence?** (`tsgilbert@arizona.edu` —
   near-universal at US R1s.) That yields a keyed, supported, non-sunsetting Esri basemap at no cost and
   removes the "keyless or bust" constraint this entire plan is built on.
2. **Why a tile basemap for the picker at all?** It needs a national outline and ~46 dots. `prototypes/site-explorer`
   already proves this suite can render real geography with no tiles and no key; `docs/_phase23_plan.md`
   P3-3 specifies a plotly `scattergeo` for exactly this map; and the Water Chemistry repo's
   `assets/wc_sitemap.png` shows **the suite already shipped a tileless scattergeo picker once.** It is the
   only option with no vendor, no key, no watermark and no sunset.

A third option, deliberately re-opened: **the free CARTO key** (no account, emailed on request, ~5M
tiles/month fair use) restores the exact current design — Positron *and* DarkMatter, retina, maxZoom 20,
zero blank tiles, no palette or CSS re-tuning. Its real costs are that the key is visible client-side
(inherent to browser tile fetching, and it is free and rotatable) and that CARTO requires visible
attribution — which small-mammal suppresses today regardless. It was filed as a last resort; on the
measured evidence it deserved to be a leading option.

---

## 6. Standing risk

Esri's published retirement schedule: **October 2026** legacy globe services; **March 2028** phase 1 of
legacy basemap retirement (World Imagery/Clarity); **December 2029** phase 2 (World Topographic Map). The
Light Gray Canvas raster basemap is *already labelled deprecated*, and Esri states the legacy raster
basemaps have been in mature support 4+ years with **no content updates since 2021** — which is the direct
cause of the blanking in §3.1.

So: no imminent cliff, but this adopts a **frozen, decaying** service. And several apps move from 2-of-3 to
3-of-3 Esri plus the always-visible picker, so every map surface in those apps then retires on one date.
That concentration is the genuine durability defect. **Disposition: `HOLD` on any blanket Esri swap;
`ADOPT` scoped to the national pickers only**, with a scheduled re-check.

Durable options, none part of this fix: self-host a minimal canvas for ~46 points; draw states/coastlines
from a committed GeoJSON; or go tileless per §5.2.

---

## 7. Gate asymmetry across the nine repos — checked

Not uniform, and it matters for rollout order:

- **`neon-my-little-inverts` and `neon-waterchemistry-analyte-viewer-app` have NO `ci.yml`** — only
  `post-deploy.yml` and `refresh-data.yml`. The two repos with the two non-standard idioms (object-form
  provider access; native `|>` pipe and a `leaflet.providers` 2.0.0 pin) are the two with **zero pre-merge
  parse or manifest gate**. Inverts still ships a 55-file `manifest.json` containing `ui.R` and `server.R`
  that nothing regenerates or verifies on a PR.
- **`neon-vegetation-structure-explorer` has no `post-deploy.yml`** — no smoke verification after deploy.
- small-mammal and veg-structure carry a separate `regenerate-manifest.yml` path.
- **No repo asserts any provider string anywhere.** Nothing today would catch a revert, or a new map added
  with the old default. That is why this shipped unnoticed.

Verified safe on both pins: `Esri.WorldGrayCanvas` is present in `leaflet.providers` 3.0.0
(`R/providers_data.R:94`, variant `Canvas/World_Light_Gray_Base`, `maxZoom = 16L`) **and** 2.0.0
(`:38`, `:244`), so the water-chemistry app's older pin is safe. Note `leaflet` 2.2.3
(`R/plugin-providers.R:44-50`) runs `check = TRUE` and **hard-errors** on an unknown provider name — a typo
is a loud runtime failure at first render, not a silent blank.

---

## 8. What must NOT be repeated

- Do not answer "what is the canvas max zoom?" from `MapServer?f=json`. It declares **LODs to level 23**,
  while `leaflet.providers` hardcodes `maxZoom = 16L` and real tiles above ~16 are the 2,521-byte
  placeholder. The prescribed method returns the wrong answer.
- Do not treat `HTTP 200` as evidence a tile is good. That assumption is exactly what let the CARTO
  watermark ship unnoticed, and it equally hides a blank Esri tile. **Decode the image and count distinct
  colours**; a single-colour tile is blank, and the "Map data not yet available" placeholder has md5
  `f27d9de7f80c13501f470595e327aa6d`.

---

## 9. Resume checklist — pick this up cold

Done:

- [x] Root cause verified by direct tile fetch + image inspection; non-causes eliminated with evidence.
- [x] All nine apps audited; 22 CARTO call sites inventoried with verified file:line.
- [x] First plan (blanket `Esri.WorldGrayCanvas` + CSS-invert dark) **refuted on four grounds**, measured.
- [x] `Canvas/World_Dark_Gray_Base` confirmed keyless and real — CSS-invert superseded.
- [x] Blank-at-plot-scale quantified (37% of NEON sites at z16); attribution regression identified.
- [x] Gate asymmetry across the nine repos mapped.

Open, in order — **first two are owner decisions and block the rest**:

- [ ] **Answer §5.1** — is there a UA institutional ArcGIS licence?
- [ ] **Answer §5.2 / the CARTO key** — tileless picker, free CARTO key, or keyless Esri split by role?
- [ ] Apply §4 per-role patch to the nine repos, one branch + draft PR each, respecting each repo's default
      branch (Driver-Cascade `master`; Small Mammal and Vegetation `main`) and its gate config from §7.
      Land ground-beetle's dark branch in the same wave (§3.5).
- [ ] Fix attribution (§3.4) — explicit strings; remove `attributionControl = FALSE`.
- [ ] Re-tune marker strokes and the palest fills against the new ground (§3.3); note `www/styles.css` is
      manifest-tracked in several repos, so bundle it into the same commit.
- [ ] Add the regression guard: a CI grep asserting zero matches for `CartoDB[."$]|cartocdn`, plus a
      scheduled tile canary that decodes tiles and fails on a single-colour or placeholder result.
- [ ] Record the basemap contract in `docs/neonize-playbook.md` §2g — it currently names **no provider at
      all**, so nothing stops the next app reintroducing CARTO.
- [ ] Visually verify each deployed app after merge. `HTTP 200` is not verification (§8).

### Per-app call-site inventory

Line numbers verified against each repo's default-branch HEAD on 2026-08-28. Re-verify before patching.

**Small Mammal** — `neon-small-mammal-tracker-app`
- `server.R:1189` — CartoDB.Positron · ALWAYS — CONFIRMED, and the confirmation is stronger than the original audit stated. This 
- `server.R:2492` — dynamic · The Plot map tab (output$map, server.R:2511; leafletOutput("map") at ui.R:631, inside the 
- `server.R:2515` — CartoDB.DarkMatter · Conditional empty state only — CONFIRMED not on the default path, but the ORIGINAL AUDIT S
- `ui.R:619` — Basemap choices vector

**Plant Diversity** — `neon-plant-diversity`
- `R/map_picker.R:58` — CartoDB.Positron · ALWAYS — the national site-picker map inside div(id="splash") (ui.R:106), placed by mapPic
- `ui.R:458` — CartoDB.Positron · ONLY IF THE USER PICKS IT — third option in the "Basemap" selectInput on the Map tab (ui.R
- `server.R:1495` — dynamic · The per-site plot map on the Map tab, shown after a site loads. The tile layer is always v
- `ui.R:456` — Basemap choices vector

**Vegetation Structure** — `neon-vegetation-structure-explorer`
- `R/map_picker.R:88` — CartoDB.Positron · ALWAYS ON LOAD, zero interaction — CONFIRMED. This is the national site-picker map on the 
- `server.R:1398` — CartoDB.Positron · CORRECTED — NOT on the cold-load path. This is the default basemap of the main Map tab, bu
- `server.R:1375` — CartoDB.Positron · Conditional, and — corrected — also gated behind a site load plus a Map-tab click. This is
- `ui.R:259` — Basemap choices vector

**Breeding Birds** — `neon-breeding-birds`
- `server.R:723` — CartoDB.Positron · ALWAYS ON LOAD, VERIFIED. output$nationalPicker (server.R:709) renders into leafletOutput(
- `server.R:711` — CartoDB.Positron · CORRECTED — NOT "always on load". The original audit's visibility string opens with "alway
- `server.R:645` — dynamic · Opt-in and post-load, VERIFIED TWICE OVER. (a) output$map (server.R:629) begins `obs <- rv
- `ui.R:298` — Basemap choices vector

**Plant Phenology** — `neon-plant-phenology-explorer`
- `server.R:177` — CartoDB.Positron · ALWAYS ON LOAD — highest-impact site in the app. VERIFIED: this is output$nationalMap (ren
- `server.R:145` — CartoDB.Positron · Empty-state fallback of that same always-on landing map. VERIFIED: server.R:144 filters si
- `server.R:779` — CartoDB.Positron · DEFAULT BASEMAP of the main explore map (output$map, renderLeaflet opens at server.R:743; 
- `ui.R:215` — Basemap choices vector

**Mosquito Pulse** — `neon-mosquito-pulse`
- `server.R:588` — CartoDB.Positron · ALWAYS on load — VERIFIED. This is the national site-picker map rendered into leafletOutpu
- `server.R:578` — CartoDB.Positron · Fallback branch of the same always-on picker map — VERIFIED at server.R:574-582. Reached o
- `server.R:537` — Dynamic · Main per-site trap-grid map, rendered at ui.R:230 inside the Map nav_panel (ui.R:222). Rea
- `ui.R:229` — Basemap choices vector

**Ground Beetle** — `neon-ground-beetle-tracker`
- `R/map_picker.R:57` — CartoDB.Positron · always on load — this is the landing/site-picker map, the app's front door. VERIFIED: ui.R
- `server.R:1630` — CartoDB.Positron · the DEFAULT basemap of the Biogeography tab map (output$map opens at server.R:1628; ui.R:4

**My Little Inverts** — `neon-my-little-inverts`
- `server.R:963` — CartoDB.Positron · VERIFIED, with one correction to the original audit. This is the real landing/site-picker 
- `server.R:940` — CartoDB.Positron · VERIFIED. Degraded-state fallback inside the SAME output$nationalPicker renderLeaflet (ser

**Water Chemistry** — `neon-waterchemistry-analyte-viewer-app`
- `app.R:2110` — CartoDB.Positron · ALWAYS — CONFIRMED by re-reading the UI tree, not just the section comment. This is the on
- `app.R:2014` — CartoDB.Positron · NEVER user-visible — source comment only. Byte-verified verbatim at line 2014 (2-space ind

### Local working state

The nine companion repos were cloned shallow + blobless + sparse (code present, `data/` and `assets/` not
checked out) under `/home/user/tgilbert14/<repo>`. That checkout is **ephemeral**. To rebuild it:

```sh
for r in neon-small-mammal-tracker-app neon-plant-diversity \
         neon-vegetation-structure-explorer neon-breeding-birds \
         neon-plant-phenology-explorer neon-mosquito-pulse \
         neon-ground-beetle-tracker neon-my-little-inverts \
         neon-waterchemistry-analyte-viewer-app; do
  git clone --depth 1 --filter=blob:none --no-checkout \
    "https://github.com/tgilbert14/$r" "/home/user/tgilbert14/$r"
  git -C "/home/user/tgilbert14/$r" sparse-checkout set --no-cone \
    '/*' '!/data/**' '!/data-sample/**' '!/assets/**' '!/docs/assets/**'
  git -C "/home/user/tgilbert14/$r" checkout HEAD
done
```

### Environment note

**A headless-browser check of the deployed apps was not possible here.** Chromium is installed and
Playwright configured, but every navigation fails `net::ERR_CONNECTION_RESET` — including
`https://example.com` — so the browser has no egress in this container, proxied or not. `curl` works. All
evidence in this document is tile-level and source-level: decisive for the cause and for the measured
blanking, but **nobody has yet seen a fixed app**.
