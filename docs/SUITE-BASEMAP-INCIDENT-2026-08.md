# Suite incident: CARTO stamps "API KEY REQUIRED" on every basemap tile

**Status: DIAGNOSED — root cause verified, fix decided, not yet applied to the nine apps.**
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

## 3. The decided fix

Owner decision, 2026-08-28:

1. **`CartoDB.Positron` → `Esri.WorldGrayCanvas`** (variant `Canvas/World_Light_Gray_Base`).
   Keyless, verified unwatermarked, and a pale minimal canvas that fills the same visual role
   as Positron. Confirmed to render over Alaska as well as the lower 48.
2. **`CartoDB.DarkMatter` → CSS-invert the grey canvas.** There is **no keyless dark canvas**
   in `leaflet.providers` 3.0.0. Rather than take a key or drop the dark theme, synthesise the
   dark basemap by filtering **only the Leaflet tile pane**, leaving markers, labels, popups and
   the attribution control untouched (they live in separate panes). The exact selector and the
   Shiny-side wiring must be verified before it ships — see the open item in §6.
3. **Leave existing `Esri.*` choices alone.** `Esri.WorldTopoMap` ("Terrain") and
   `Esri.WorldImagery` ("Satellite") are unaffected and stay as they are.
4. **Update the visible labels** in each `selectInput("view", "Basemap", …)` so "Light" still
   maps to a sensible provider string.

### Rejected alternatives, and why

- **Take a CARTO API key** (free tier, 5M tiles/month). Rejected: the key is unavoidably public
  in a client-side tile URL, it needs managing across nine separate Connect Cloud deployments,
  and CARTO is retiring raster basemaps regardless — so it buys a cosmetic reprieve and leaves
  the same cliff in place.
- **`OpenStreetMap.Mapnik`.** Rejected: the OSMF tile usage policy discourages exactly this
  kind of hosted-app embedding, and the style is far busier than a canvas behind circle markers.
  (Noted: a request from this container returned `HTTP 200` with an `x-blocked: Access denied`
  header — OSMF blocks datacentre IPs.)
- **`USGS.USTopo` / `USGS.USImagery`.** Keyless and live, and thematically apt for a US network.
  Rejected as the *canvas* replacement because `USGSTopo` is a full-colour topographic sheet
  with highway shields and dense labels — unusable behind the suite's circle markers. Worth
  keeping in mind as a future "Topo" option.
- **Drop the dark basemap.** Rejected: the ground-beetle app deliberately re-themes its map
  with the rest of the UI, and losing that is a real regression.

---

## 4. Applying it — what a patch must respect

- **Docs-only changes in Driver-Cascade are outside the deploy surface.** `scripts/manifest_files.R`
  allowlists only `global.R`, `ui.R`, `server.R`, `R/cascade_helpers.R`, `R/site_metadata.R`,
  `www/{cascade.css,cascade.js,styles.css}` and the four `data/` artifacts. `docs/` and
  `.claude/` are not in it, so this document does not touch the manifest gate.
- **In the companion repos the patch DOES touch `ui.R` / `server.R` / `R/*.R`**, which are on
  their deploy surfaces. A source-only edit changes no package, so `manifest.json` should not
  need regeneration — **but each repo's CI manifest gate must be checked**, because the sibling
  gates are byte-exact where Driver-Cascade's is semantic.
- **A push to the watched branch is the deploy.** Each companion repo is watched by Posit
  Connect Cloud; merging is what ships. Nine merges = nine deploys.
- Match each repo's local idiom: pipe style (`%>%` vs `|>`), namespacing (`leaflet::` vs bare),
  and its own `CLAUDE.md` / `AGENTS.md` house rules.

---

## 5. Standing risk to record

Both the old and the new basemap are third-party freebies with no contract behind them. CARTO
withdrew its free raster tier with no warning that reached this project; Esri has already
announced the same intent for the legacy endpoints this fix moves onto. **Treat the basemap as
a dependency with an owner and a review date, not as scenery.** Options that would durably
de-risk it — and are explicitly NOT part of this fix:

- Self-host a minimal vector or raster canvas for the ~81 NEON site locations (the suite only
  ever needs a national overview plus site-level zoom, not a world basemap).
- Draw a simple state/coastline outline from a committed GeoJSON — no tile server at all. The
  `prototypes/site-explorer` map already proves this suite can render real geography with no
  tiles and no key.
- Add a suite CI check that fetches one tile from each configured provider and fails on a
  non-image, an unexpected byte-size shift, or a known watermark signature.

---

## 6. Resume checklist — pick this up cold

Work completed on `claude/neon-maps-api-key-eocg8r` in Driver-Cascade:

- [x] Root cause identified and verified by direct tile fetch + image inspection.
- [x] Non-causes eliminated with evidence (package versions, referer, CORS, CSP, app strings).
- [x] Replacement `Esri.WorldGrayCanvas` fetched and visually confirmed clean.
- [x] All nine companion apps enumerated with per-file call sites.
- [x] Owner decision recorded: Esri grey canvas + CSS-inverted tile pane for dark.
- [x] This advisory + `LESSONS.md` + `BUILD-TEST-HANDOFF.md` entries committed.

Open, in order:

- [ ] **Verify the CSS-invert approach concretely** before it ships: confirm the Leaflet 1.x
      pane structure (`.leaflet-tile-pane` vs `.leaflet-overlay-pane` / `.leaflet-marker-pane`),
      settle the exact filter (`invert(1) hue-rotate(180deg)` plus brightness/contrast trim),
      confirm the attribution control is not inverted, and decide how it is toggled from each
      app's existing theme state (a class on the map container vs `htmlwidgets::onRender`).
- [ ] **Confirm `Canvas/World_Light_Gray_Base` max zoom** against
      `https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer?f=json`
      and check it is deep enough for the plot-level maps (Positron went to zoom 20).
- [ ] **Check marker contrast** in each app against the paler grey canvas — several palettes
      were tuned against Positron's near-white.
- [ ] **Apply the patch to the nine companion repos**, one branch + draft PR each, respecting
      each repo's default branch (`master` vs `main`) and CI manifest gate.
- [ ] **Re-check the deployed apps** after each merge; Connect Cloud redeploys on push.
- [ ] Consider the suite CI tile-canary from §5.

### Local working state

The nine companion repos were cloned shallow + blobless + sparse (code present, `data/` and
`assets/` deliberately not checked out) under `/home/user/tgilbert14/<repo>`. That checkout is
**ephemeral** — this container is reclaimed after the session. To rebuild it:

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

### Environment note for the next session

**A headless-browser check of the deployed apps was not possible here.** Chromium is installed
and Playwright is configured, but every navigation fails with `net::ERR_CONNECTION_RESET` —
including `https://example.com` — so the browser has no egress in this container even routed
through the agent proxy. `curl` works fine. A session that *can* drive a browser should
confirm the watermark on a live app and confirm it is gone after the fix; until then the
evidence here is tile-level, which is decisive for the cause but does not substitute for
seeing a fixed app.
