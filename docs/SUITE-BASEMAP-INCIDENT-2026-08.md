# Suite incident: CARTO stamps "API KEY REQUIRED" on every basemap tile

**Status: DIAGNOSED and DECIDED. The first proposed fix was refuted by evidence (§3). The owner's decision
is to take the free CARTO key and keep the existing basemaps unchanged (§4). BLOCKED on one owner action —
requesting the key at <https://carto.com/basemaps/apikey> — which no agent can do. Nothing applied to the
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

## 4. DECIDED: take the free CARTO key (owner, 2026-08-28)

**Disposition: `ADOPT`.** Keep `CartoDB.Positron` and `CartoDB.DarkMatter` exactly as they are and
authenticate them. This is the only option that changes nothing visually: same tiles, same `maxZoom = 20`,
same retina, zero blank tiles, no marker-palette or CSS re-tuning, no contrast regression, no attribution
regression, and the ground-beetle dark theme keeps working unchanged. Every defect in §3 exists *because*
the other options moved the basemap; this one does not move it.

### 4.1 The one step only the owner can do

**Request the key at <https://carto.com/basemaps/apikey>.** Verbatim from that page: *"Tell us your email,
the domain you will use the basemaps on, and roughly what you are building. We email the key straight back —
there is no approval queue and you do not need a CARTO account."* A JS-less fallback is emailing CARTO
support. Fair use is **5 million tile requests per calendar month**, counted across raster and vector — for
nine low-traffic academic apps that is orders of magnitude of headroom.

Domain to give: the Connect Cloud share domain (`*.share.connect.posit.cloud`). **Not confirmed** whether
that domain is actually enforced as a referer lock or merely recorded — CARTO documents no allowlist
feature and there is no console, since there is no account. Treat it as informational.

**Also verified 2026-08-28 — the key-request form cannot be submitted programmatically.** It is a HubSpot
form (portal `474999`, form `4545f275-9bc1-408f-ba2f-963a53a14803`) and HubSpot's API-submission path
returns `FORM_HAS_RECAPTCHA_ENABLED` — captcha is enforced server-side, so a human must submit it in a
browser. The page's own fallback: email **support-basemaps@carto.com** and "we will issue a key by hand."
Do not re-attempt an API submission.

**Verified 2026-08-28 — a CARTO *platform* API Access Token does NOT work as the basemap key.** The owner
created a Workspace token scoped to the Maps API and it was tested against the raster CDN at confirmed
origin cache misses (`x-cache: MISS`) under five auth forms — `?key=`, `?access_token=`, `?api_key=`,
`?apikey=`, and an `Authorization: Bearer` header. Every response was still the watermarked tile. The
token itself is valid (the platform API recognizes it and echoes `allowed_apis: ["maps"]`); the "maps"
scope is CARTO's Maps API for data layers, not the public basemap CDN. CARTO's key page confirms the
split: platform credentials cover Builder/Workflows and in-platform use — external embedding needs the
form-issued basemap key, a separate credential. **Do not re-test platform tokens; use the form.**
Also learned: the CDN ignores the query string in its cache key (a keyed request can get `x-cache: HIT`
on the unkeyed cached tile), so any smoke test of the real key must be done on an origin-MISS tile —
deep zoom over an obscure spot — or the cached watermarked tile will masquerade as a key failure.

### 4.2 The key is NOT a secret — this is load-bearing

CARTO's key rides in the tile URL, and every tile request is issued **client-side by the browser**. The key
therefore lands in page source and in the network tab on first map paint, whatever you do. CARTO's terms
**§9.c prohibits server-side proxying or caching of tiles**, so routing them through the Shiny server to
hide the key is not allowed either.

So: **treat it as a public, rate-limited identifier, not a credential.** Storing it in
`Sys.getenv("CARTO_BASEMAP_KEY")` buys exactly two things — it keeps the key out of nine public git
histories, and it makes rotation a Connect Cloud setting change rather than nine releases. That is worth
doing. It does not make the key private, and no part of this plan should be written as though it does.

Posit Connect Cloud **does** support this: content settings have a *Variables* section ("Add, update, or
remove your secret environment variables"), values are encrypted at rest, and `Sys.getenv()` reads them at
runtime. They are **not** part of `manifest.json` — the manifest describes files and packages only. Cost to
be honest about: **nine apps × one manual variable each**, and Posit's docs do not say whether an edit takes
effect immediately or needs a republish — **assume a republish until tested**.

### 4.3 The code — one helper, keyed with a keyless fallback

`addProviderTiles()` **cannot** carry the key: the pinned `leaflet.providers` CartoDB template has an `{r}`
retina slot but no `{apikey}` placeholder. It must be a raw `addTiles()` with attribution supplied by hand.

Add to each app's `global.R` (or the top of `app.R` for water-chemistry):

```r
# --- basemap -----------------------------------------------------------------
# CARTO began watermarking UNAUTHENTICATED basemaps.cartocdn.com raster tiles on
# 2026-08-26 (see docs/SUITE-BASEMAP-INCIDENT-2026-08.md in NEON-Driver-Cascade).
# This key is a PUBLIC, rate-limited identifier, not a credential: it rides in the
# tile URL and is visible in the browser. Sys.getenv keeps it out of git and makes
# rotation a Connect Cloud setting rather than a release.
CARTO_KEY <- Sys.getenv("CARTO_BASEMAP_KEY", "")

# CARTO's terms require BOTH credits visible; do not suppress the attribution control.
CARTO_ATTR <- paste(
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  '&copy; <a href="https://carto.com/attributions">CARTO</a>')
ESRI_CANVAS_ATTR <- 'Tiles &copy; Esri &mdash; Esri, HERE, Garmin, &copy; OpenStreetMap contributors'

# variant: "light_all" (= CartoDB.Positron) or "dark_all" (= CartoDB.DarkMatter).
# With a key: the exact tiles the suite has always used. Without one: a keyless Esri
# canvas — never a watermarked tile. The fallback is deliberately NOT used at plot
# scale; see §3.1 (Esri's canvas is blank at z16 for 37% of NEON sites).
add_suite_basemap <- function(map, variant = "light_all", ...) {
  if (nzchar(CARTO_KEY)) {
    leaflet::addTiles(map,
      urlTemplate = sprintf(
        "https://{s}.basemaps.cartocdn.com/%s/{z}/{x}/{y}{r}.png?key=%s", variant, CARTO_KEY),
      attribution = CARTO_ATTR,
      options = leaflet::tileOptions(subdomains = "abcd", maxZoom = 20,
                                     detectRetina = TRUE, ...))
  } else {
    leaflet::addTiles(map,
      urlTemplate = sprintf(
        "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_%s_Gray_Base/MapServer/tile/{z}/{y}/{x}",
        if (identical(variant, "dark_all")) "Dark" else "Light"),
      attribution = ESRI_CANVAS_ATTR,
      options = leaflet::tileOptions(maxNativeZoom = 16, maxZoom = 19, ...))
  }
}
```

Then every call site becomes `add_suite_basemap(map, "light_all")` / `"dark_all"`, and the `input$view`
dropdowns keep their `Esri.*` options routed through `addProviderTiles()` as today, with `"CartoDB.Positron"`
/ `"CartoDB.DarkMatter"` dispatched to the helper.

> **Smoke-test the URL form ONCE before rolling to nine repos.** The `?key=` query-parameter shape is taken
> from CARTO's own docs. It could not be verified here: an *invalid* key returns the **byte-identical
> watermarked tile** as no key at all (same ETag), so there is no negative test — only a real key proves it.
> Fetch one tile with the real key and confirm the watermark is gone before any PR is opened.

### 4.4 Attribution must be restored at the same time

`neon-small-mammal-tracker-app/server.R:2491` and `:2514` set `leafletOptions(attributionControl = FALSE)`.
CARTO's terms require visible CARTO **and** OpenStreetMap credit, so those two lines are **non-compliant
today** and must come out as part of this change — not as a follow-up.

### 4.5 What this decision retires

- The blanket `Esri.WorldGrayCanvas` swap — **REJECTED** (blank at plot scale, §3.1).
- The CSS-invert dark canvas — **REJECTED, superseded** (§3.2; and moot now that Positron/DarkMatter stay).
- The per-map-role split — **retained only as the keyless fallback path** in `add_suite_basemap()`, so a
  missing or revoked key degrades to a clean canvas instead of a defaced one.
- The two questions in the previous revision (UA institutional ArcGIS licence; tileless picker) — **not
  needed for this fix.** Both stay on the register as durability options, since CARTO is retiring raster
  basemaps eventually (§6).

---

## 5. Rollout — what a patch must clear in each repo

**The manifest is the real gate, and it bites at runtime as well as in CI.** Every companion repo ships a
`manifest.json` with per-file checksums, and `ui.R` / `server.R` / `R/*.R` / `global.R` are all on the deploy
surface. So a source edit **requires the manifest to be regenerated in the same commit.**

- **Never hand-edit `manifest.json`.** Small Mammal and Vegetation Structure carry a blessed
  `.github/workflows/regenerate-manifest.yml` — `workflow_dispatch`-only, refuses to run on `main`,
  regenerates twice and requires byte-identical output. Its own header says it exists to end the loop that
  "made the ChatGPT/Codex cover rework fail merges over and over". **Use it.**
- Byte-exact manifest gates, per repo: small-mammal `ci.yml:156`; breeding-birds `:185`; ground-beetle
  `:129`; mosquito `:111`; phenology `:165`; plant-diversity `:165-177` (regenerates twice, requires
  identical sha256, then `verify_bundle.R`); veg-structure `:179-195` (regenerates twice, `verify_manifest.R`,
  then a `git status --porcelain` equivalent).
- **`neon-my-little-inverts` and `neon-waterchemistry-analyte-viewer-app` have NO `ci.yml`** — both still
  ship a `manifest.json`, so their patch needs a **manually regenerated** manifest with nothing to catch a
  stale one. Highest-risk two repos; do them last, with the most care.
- **Driver-Cascade enforces manifest checksums at RUNTIME** (`global.R:106-112`, before any repo code is
  sourced; `DEPLOY.md:74-76`). It has no map so it is unaffected — but if that integrity pattern is ever
  promoted to the siblings, a stale-manifest basemap patch stops being a red check and becomes a
  **production outage**.
- **No test anywhere in the suite asserts a provider string** — a grep across every `scripts/`,
  `test_*`, `check_*`, `verify_*` and smoke file in all nine repos returns zero hits. CI sources the app but
  never fetches a tile, so **CI cannot detect a bad provider or a defaced tile.** That is exactly why this
  shipped unnoticed.
- **Branch targets differ and so do the deploy rules.** Driver-Cascade: Connect watches `master` and a push
  to `master` *is* the deploy. Small Mammal: Connect watches `main` and `DEPLOY.md:9-13` states **"no
  automation may push there directly — a human-reviewed merge is the explicit production decision."**
  So: open a PR per repo; **do not merge them.**

Suggested order, safest first: ground-beetle → mosquito → phenology → breeding-birds → plant-diversity →
veg-structure → small-mammal → little-inverts → water-chemistry. Canary the first one end to end (patch,
manifest, merge, deploy, look at the live map) before touching the rest.

---

## 6. Standing risk

Esri's published retirement schedule: **October 2026** legacy globe services; **March 2028** phase 1 of
legacy basemap retirement (World Imagery/Clarity); **December 2029** phase 2 (World Topographic Map). The
Light Gray Canvas raster basemap is *already labelled deprecated*, and Esri states the legacy raster
basemaps have been in mature support 4+ years with **no content updates since 2021** — which is the direct
cause of the blanking in §3.1.

So: no imminent cliff, but this adopts a **frozen, decaying** service. And several apps move from 2-of-3 to
3-of-3 Esri plus the always-visible picker, so every map surface in those apps then retires on one date.
**Disposition: `ADOPT` the keyed CARTO basemaps (§4); `HOLD` on any blanket Esri swap** — Esri is now only
the keyless fallback in `add_suite_basemap()`, which is why that fallback is capped at `maxNativeZoom = 16`
and is not used to justify plot-scale detail. CARTO states raster basemaps are being retired in favour of
vector, so the key buys time, not permanence: schedule a re-check.

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

- [x] Owner decision recorded: **take the free CARTO key**, keep Positron/DarkMatter unchanged (§4).
- [x] Key mechanics settled: `?key=` query param, raw `addTiles()`, helper + keyless fallback written (§4.3).
- [x] Connect Cloud confirmed to support runtime env vars via a Variables UI; key confirmed NOT secret (§4.2).
- [x] Per-repo manifest gates, branch targets and deploy rules mapped (§5).

Open, in order:

- [x] **Key requested and issued** (2026-08-28, owner via the form; the platform `api_token` route was
      tested first and does NOT work — see §4.1). Key starts `cb1_…`; it lives in the owner's email and in
      Connect Cloud variables, **never in any repo**.
- [x] **Key verified against live tiles**: clean at CDN origin misses for `light_all` AND `dark_all`, and —
      the deployment worry — the previously-cached watermarked picker zooms return CLEAN with the key (the
      CDN caches keyed responses separately). Unkeyed control stays watermarked. `?key=` is the confirmed form.
- [x] **Canary PR open**: Ground-Beetle-Tracker#22 (branch `claude/carto-basemap-key`) — adds
      `add_suite_basemap()` to `global.R`, routes both call sites (`R/map_picker.R:57`,
      `server.R:1633-1634`), dark toggle preserved via `dark_all`. Manifest deliberately untouched in the
      first commit: the pinned CI validator regenerates it and the validated candidate artifact lands in a
      follow-up commit (AGENTS.md forbids hand edits; the repo has no regenerate-manifest.yml dispatch).
      Expect the canary's FIRST run red at the byte-match gate — that is the designed flow.
- [ ] Set `CARTO_BASEMAP_KEY` in Connect Cloud content settings → Variables, for each of the nine apps.
      Assume a republish is needed for it to take effect.
- [ ] Add the `add_suite_basemap()` helper to each app and route its call sites through it (§4.3), removing
      `attributionControl = FALSE` from small-mammal `server.R:2491`/`:2514` in the same change (§4.4).
- [ ] **Regenerate `manifest.json` in the same commit, never by hand** — use `regenerate-manifest.yml` where
      it exists; hand-regenerate for the two repos with no CI (§5).
- [ ] One canary repo end to end — patch, manifest, merge, deploy, *look at the live map* — before the rest.
- [ ] Open a PR per repo; **do not merge them** (Small Mammal `DEPLOY.md:9-13`: a human-reviewed merge is the
      production decision).
- [ ] Add the regression guard: a CI grep asserting no unkeyed `cartocdn` URL, plus a scheduled tile canary
      that decodes a tile and fails on a watermark, a single-colour result, or the Esri placeholder.
- [ ] Record the basemap contract in `docs/neonize-playbook.md` §2g — it currently names **no provider at
      all**, so nothing stops the next app reintroducing an unkeyed CARTO layer.
- [x] **Canary MERGED and confirmed live** — Ground Beetle #22 merged as `e136aeb`; `main` CI, the
      production-verification workflow and Pages all green, no issue opened, and the owner confirmed the
      live map shows Positron/DarkMatter with no watermark. That closed the last unproven link: the
      Connect `CARTO_BASEMAP_KEY` variable really does reach the running app.
- [x] **All eight remaining repos patched, pushed, PRs open** (2026-08-29) — see the rollout table below.
- [ ] Merge the eight PRs (owner decision per repo) and set `CARTO_BASEMAP_KEY` in each app's Connect
      Cloud Variables **before** merging, or the deploy shows the keyless Esri fallback.
- [ ] Visually verify each deployed app after merge. `HTTP 200` is not verification (§8).


### Rollout status (2026-08-29)

The helper landed in every app as `add_suite_basemap()`. It accepts **either** a leaflet provider name or a
CARTO variant, which is why **no `ui.R` Basemap dropdown needed changing anywhere** — the choice vectors and
their defaults are untouched, CARTO entries route to keyed tiles, and every `Esri.*` entry passes straight
through to `addProviderTiles()` exactly as before.

| App | PR | Base | Call sites | Notes |
|---|---|---|---|---|
| Ground Beetle | #22 | `main` | `R/map_picker.R:57`, `server.R:1633` | **MERGED + DEPLOYED**; live map confirmed by owner |
| Plant Diversity | #18 | `master` | `R/map_picker.R:58`, `server.R:1495` | **GREEN, ready**; `www/runtime-receipt.txt` regenerated with the repo's own node script — matched the validator byte-for-byte |
| Small Mammal | #93 | `main` | `server.R:1189`, `:2492`, `:2515` | **GREEN, ready**; also removes `attributionControl = FALSE` (§4.4) |
| Vegetation Structure | #16 | `main` | `R/map_picker.R:88`, `server.R:1375`, `:1398` | **GREEN, ready**; `ui.R` `selected =` made it the default |
| Water Chemistry | #19 | `main` | `app.R:2110` | **GREEN, ready**; passed a real `connect_cold_start` — proves the hand-set manifest MD5 and the `app.R` patch both boot |
| Plant Phenology | #12 | `master` | `server.R:145`, `:177`, `:779` | **GREEN, ready**; "Light" is the default basemap |
| Mosquito Pulse | #12 | `master` | `server.R:537`, `:578`, `:588` | **BLOCKED on owner** — everything passed except the manifest byte gate, and this repo's artifact upload is conditional on an *earlier* failure, so no validated manifest is exported. Needs `Rscript scripts/write_manifest.R` |
| Breeding Birds | #6 | `master` | `server.R:645`, `:711`, `:723` | **BLOCKED on owner** — `write_release_stamp.R` binds `global.R`/`ui.R`/`server.R`; failed at the stamp check before packages installed. Needs manifest **then** stamp |
| My Little Inverts | #10 | `main` | `server.R:940`, `:963` | **BLOCKED on owner** — object form; validator lives in `refresh-data.yml` (not `ci.yml`), failed at "Reject a stale committed identity". Producer artifact byte-compared: 36/36 identical |

**Default branches really are split** — `master` for Mosquito, Birds, Phenology, Plant Diversity;
`main` for Ground Beetle, Vegetation, Small Mammal, Inverts, Water Chem. Checked per repo, never assumed.

**Six of nine are green or merged.** The two-step flow (first run red at the byte gate by design → commit its
validated manifest artifact → second run green) worked for Ground Beetle, Plant Diversity, Small Mammal,
Vegetation Structure and Plant Phenology. In every shuttle the ONLY file that differed was `manifest.json` —
every data file, search index and receipt in the validator's artifact was already byte-identical to the
branch, which is independent evidence the patch moved nothing it shouldn't.

**Three are blocked on the owner, for two distinct reasons — neither faked:**
- *Mosquito Pulse* — a CI-shape gap, not a code problem: its `Upload unvalidated manifest` step is
  `if: failure() && …` and sits BEFORE the byte gate, so when the gate is the only failure nothing has failed
  yet, the upload is skipped, and the validated manifest dies with the runner. Five sibling repos upload
  theirs unconditionally. Worth aligning separately; deliberately not changed in a basemap PR.
- *Breeding Birds* and *My Little Inverts* — their generated authority **binds the app source**
  (`write_release_stamp.R`; `runtime_payload_sha256` in `production-identity.json`), so editing `global.R`
  or `server.R` invalidates it by construction. Regenerating needs R in the pinned validator. Each PR carries
  the validator's own command sequence, lifted verbatim from its workflow.

**Correction worth keeping:** "no `ci.yml`" is NOT the same as "no CI". My Little Inverts and Water Chemistry
both run validators from `refresh-data.yml`. Water Chemistry's even includes a `connect_cold_start` job that
cold-boots the deploy bundle — the strongest single check in the suite, and it passed.

**The seven repos with CI follow the canary's two-step flow:** first run goes red at the byte-match gate by
design, its validated manifest artifact is committed as a second commit, second run goes green.

**The two repos with no `ci.yml` were handled differently, and differently from each other:**
- *My Little Inverts* — `AGENTS.md` forbids hand-editing or casually regenerating `manifest.json`, and its
  `release/production-identity.json` hashes `global.R`/`ui.R`/`server.R` into `runtime_payload_sha256`.
  Nothing was fabricated: the PR is **source-only and explicitly not mergeable** until both are regenerated
  in the clean validator.
- *Water Chemistry* — no such prohibition, and `write_manifest.R` warns a stale checksum can make Connect
  serve yesterday's bytes, which would silently drop the fix. Its manifest is plain per-file MD5s with the
  package block restored verbatim from a reviewed lock, so the single `app.R` checksum was updated in-PR
  after verifying all six committed checksums reproduce exactly.

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

---

## 10. Session 2026-08-31 — the last three PRs, and two new problems

Six of nine were already merged or green. This session cleared the three blocked ones and turned up two
things the rollout had not anticipated: a **corrupted `manifest.json` on the Breeding Birds deploy branch**,
and a **second, quieter basemap failure mode** that the helper as shipped does not survive.

### 10.1 Breeding Birds — `master` was carrying an unresolved merge

Not a basemap problem. Found while checking why the owner's regeneration had not reached the PR.

`master` head `08eb093 "update"` has **nine conflict-marker lines and six superseded checksums committed
into `manifest.json`**, in three blocks inside the `files` map. The file is **not valid JSON**, so every gate
that parses it fails: `verify_manifest.R`, `write_release_stamp.R`, and Connect's own bundle read. CI run #8
on that commit failed, and `master` is the branch Connect Cloud watches.

How it happened: `8128680 "build: regenerate the manifest and release stamp for the basemap change"` has
parent `efda16e` — a months-old line carrying **neither** PR #5's release work **nor** the basemap change. It
regenerated four checksums against the wrong tree. Merging that into `bb18be3` collided on `manifest.json`
and the markers were committed unresolved.

**Nothing else was lost.** `git diff --name-status bb18be3 origin/master` returns exactly one line —
`M manifest.json`. Master's tree is otherwise byte-identical to the last known-good commit, so discarding
the corrupt side restores it completely. The repair rides in PR #6 rather than a separate PR: one merge both
fixes `master` and ships the basemap change. The resolved tree is identical to the PR branch before the merge.

**Lesson for the log:** a generated artifact regenerated on the wrong base is worse than one not regenerated
at all — it looks like progress and it lands on the deploy branch. Check `git merge-base --is-ancestor` before
running any regeneration script.

### 10.2 Regenerating Birds' authority without R — and proving it first

No R runtime here, and Birds' authority is a two-phase, self-referential contract (prestamp manifest →
release stamp → final manifest). It is also **fully deterministic**, so it was reimplemented rather than
hand-computed — and, decisively, **validated by reproducing the known-good `bb18be3` stamp byte-for-byte
before being used**:

| field | reproduced | committed at `bb18be3` |
|---|---|---|
| payload files | 125 | 125 |
| `source_receipt_sha256` | `55f30d25…` | ✅ same |
| `environment_receipt_sha256` | `03f4bc77…` | ✅ same |
| `payload_sha256` | `2ce22cd3…` | ✅ same |
| `release_id` | `sha256:043aa41d…` | ✅ same |

All four match, including the `release_id` derived from the carried-over `manifest_contract_sha256`. The
manifest MD5 model was validated the same way: all 121 committed checksums reproduce from the tree.

Only then was it applied to the PR tree. What moved: `payload_sha256 → d62ebd6d…`, `release_id →
sha256:9492231a…`, and exactly three manifest checksums (`global.R`, `server.R`, `data/release_stamp.json`).
The six non-file contract fields are byte-identical to `bb18be3`, so `manifest_contract_sha256` is unchanged
**by construction** — the stamp's contract digest excludes the `files` map, which is why a source-only edit
cannot move it.

**This is the pattern to reuse**: reproduce a known-good generated artifact exactly, then and only then apply
the same computation to the new tree. It is not hand-editing, because the implementation is checked against
ground truth before it is trusted.

### 10.3 Water Chemistry — a blank map, and the failure mode the helper missed

Reported symptom: the site-picker map draws its Leaflet frame and attribution control but **no basemap tiles**.

Ruled out by measurement, not inference:

| Hypothesis | Test | Result |
|---|---|---|
| Stale deploy | `ddl-runtime-receipt` meta in the served HTML vs the joined MD5 of the six `WATER_RUNTIME_FILES` | **Exact match** — the live app runs the merged code |
| Bad call site | Helper + call site vs Ground Beetle's (which works) | Byte-identical |
| Dead tile servers | `curl` all three endpoints | All `200`: CARTO `light_all` keyed (`image/png`), both Esri canvases (`image/jpeg`) |

That leaves the **key's value in Connect Cloud**, and one value explains it exactly:

> A **missing** key is loud — CARTO serves the "API KEY REQUIRED" watermark, which is this whole incident.
> A key carrying a **trailing newline or a stray space** is silent. `sprintf()` interpolates it into the tile
> URL, every tile request is malformed, and the basemap goes blank behind an otherwise-working map.

That is exactly what a paste out of the CARTO signup mail leaves in Connect Cloud's Variables field, and it is
**not observable from outside the container** — tile URLs travel over the Shiny websocket.

**The fix (Water Chemistry PR #20):** stop trusting the value.

```r
key <- trimws(Sys.getenv("CARTO_BASEMAP_KEY", ""))
if (grepl("^[A-Za-z0-9_-]+$", key)) {
```

Trim it, so a padded paste still authenticates. Validate its shape, so a mangled value takes the Esri
fallback — a real basemap instead of nothing. A correct key is unaffected by both. The fallback branch now
also `message()`s why it fired, so the next occurrence is one line in the Connect log instead of a blank
rectangle.

**⚠️ Not verified end-to-end.** The reasoning is airtight on everything *except* the actual stored value of
`CARTO_BASEMAP_KEY` for that content item, which only the Connect Cloud settings page shows. If the map is
still blank after PR #20 deploys, the next datum to get is the tile host in the browser Network tab
(`cartocdn` keyed / `arcgisonline` / neither).

### 10.4 OUTSTANDING — the hardening is in ONE repo, not nine

**The other eight apps carry the unhardened helper.** They work today, so this session deliberately did not
churn eight byte-exact manifests to fix one app. But every one of them is one whitespace-padded paste away
from the same silent blank map, and the owner set the variable by hand in nine places.

**Next session: land §10.3's three-line change in the remaining eight repos in one pass.** Each needs its own
manifest regeneration, so treat it as a rollout, not a patch — the same shuttle flow this incident already
documents. The `message()` line makes it self-diagnosing thereafter.

### 10.5 Final rollout state

| App | PR | Base | State at end of session |
|---|---|---|---|
| Ground Beetle | #22 | `main` | **MERGED + DEPLOYED**, live map confirmed by owner |
| Water Chemistry | #19 | `main` | **MERGED + DEPLOYED**; receipt-verified live. Blank map → **PR #20** (§10.3) |
| Plant Diversity | #18 | `master` | Green, ready |
| Small Mammal | #93 | `main` | Green, ready |
| Vegetation Structure | #16 | `main` | Green, ready |
| Plant Phenology | #12 | `master` | Green, ready |
| Mosquito Pulse | #12 | `master` | **UNBLOCKED** — CI now exports the validated manifest; artifact shuttled (§10.6) |
| My Little Inverts | #10 | `main` | **UNBLOCKED** — dispatched validator succeeded, all 3 authority files shuttled (§10.6) |
| Breeding Birds | #6 | `master` | **UNBLOCKED** — authority regenerated (§10.2) **and** repairs `master` (§10.1) |

### 10.6 How the last two shuttles were done

*Mosquito* — the CI-shape gap is fixed: an unconditional `upload-artifact` step now sits before the byte
gate, matching Ground Beetle's verbatim (same pinned action SHA). The run then exported
`mosquito-manifest-43c8892d…`, and its 112 file checksums all match the tree, including the two the basemap
change moves. Everything else differing from the committed manifest is a package `Built` timestamp — **73 of
them** — recording when the validator compiled each source package. That is precisely the non-determinism
this repo's byte-exact gate flaps on, and the reason the bytes must be *taken* from the validator rather than
reconstructed. **This is the case for promoting `compare_manifests.R` to the byte-exact siblings.**

*Inverts* — the dispatched `refresh-data.yml` run (`skip_download`) succeeded in all four jobs against the PR
head, and its publish job wrote the validated tree to `automation/invert-data-refresh`. Before shuttling, the
whole branch was byte-compared: it differed from the PR branch in **exactly** `manifest.json`,
`release/production-identity.json` and `docs/release.json`. After the shuttle the PR tree is byte-identical to
the validated branch. `runtime_payload_sha256` moved because it hashes `global.R`/`ui.R`/`server.R`.
