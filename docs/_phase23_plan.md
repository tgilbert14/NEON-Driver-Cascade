> **Historical implementation plan; superseded.** This file records the state observed before the
> current artifact schema, scientific audit, construct correction, and completed UI/backend work.
> Its “confirmed” statements are not claims about the current app. Use the generated artifacts,
> contract tests, README, and in-app About panel for current behavior.

I have everything I need. All load-bearing claims are verified against the then-live code. Confirmed findings: branch=`master` (suite is `main`), manifest checksums stale for 4+ files, ladder uses one global `ci` counter against a flat palette (color-identity bug), bundle is 4-element (no `sites`/`pulses`), priors carry exact lags, scatter draws solid-gold fit line regardless of tier, year-text always-on, About link `href="#"`, stray `%d` file in root.

Here is the consolidated, decision-ready build plan.

---

# Driver Cascade — Phase 2/3 Build Plan (consolidated from Vera, Alyssa, Tim, Vik, NEONize)

All five reviews were ground-truthed against the live repo at `NEON-Driver-Cascade/`. Every claim below is verified, not assumed. Items already on the known backlog (downloads, codebook, QC panel, sibling links, mobile, strip dead JS, Pulse Tracer, scoreboard, completeness map, scorecard, photos) are **sequenced and spec'd** here, not re-litigated.

---

## 1. NEW blockers (not on the known backlog)

These are deploy-or-honesty blockers the backlog did not capture. **Do these first — nothing else ships correctly until they land.**

| # | Blocker | Evidence (verified) | Fix | Eff |
|---|---------|--------|-----|-----|
| **B1** | **Manifest checksums are stale → Connect Cloud serves the OLD pre-fix bundle or fails the deploy.** | `md5 data/cascade.rds` = `6b8663a…` but `manifest.json` pins `967b919…`. Same mismatch on `global.R` (`fb6d8eb` vs `7afd03c`), `R/cascade_helpers.R` (`6749321` vs `f679757`), `scripts/build_cascade.R` (`25972b4` vs `5734f9b`). | `Rscript -e 'rsconnect::writeManifest()'` after every rebuild; `git add manifest.json data/`. Wire into `build_cascade.R` tail. | **S** |
| **B2** | **CI rebuilds data but never regenerates the manifest → every monthly bot deploy re-ships stale checksums forever.** | `.github/workflows/refresh-data.yml` runs `build_cascade.R` then `git add data/cascade.rds` with no `writeManifest()` and no `manifest.json` in the commit. | Add a `writeManifest()` step after rebuild; `git add data/cascade.rds manifest.json`. Add a post-build `Rscript scripts/test_helpers.R` gate so a malformed bundle fails the job instead of deploying. | **S** |
| **B3** | **Deploy branch mismatch → Connect Cloud silently never redeploys.** | `git branch` = `master`; `git ls-remote` shows only `refs/heads/master`; workflow pushes `HEAD:master`; DEPLOY.md says `master`. Suite standard is `main`. | Standardize on `main`: `git branch -m`, update workflow lines + DEPLOY.md, repoint Connect Cloud. (Or document a deliberate exception — but pick one before wiring Connect.) | **S** |
| **B4** | **Ladder hero chart's color encoding is dishonest** — the one global `ci` counter paints each layer's lines from a flat 8-color palette, so climate's 2nd line renders in phenology-green, producers' 1st in consumer-cardinal, and on rich sites (9–10 traces) the palette wraps so `bird_richness == precip blue`. The ladder contradicts every other surface (chips, schematic, axis titles) that teaches climate=blue/phen=green/prod=green/cons=red. | `server.R:93` flat `pal`; `:94` `ci <- 0`; `:97` `ci <<- ci+1` incremented across ALL layers; `:99-100` index `pal[(ci-1)%%length(pal)+1]`. | Per-layer hue **ramp** keyed off `LAYER_META[[L]]$col`; reset the index **inside** the `lapply(present,…)` so it's local per strip; assign `pal_L[(j-1)%%length(pal_L)+1]`. No layer has >4 signals, so no ramp ever wraps — this kills the wrap bug too. (See §4 mobile for legend.) | **M** |
| **B5** | **Driver Lab dropdown dead-end.** `bird_index` is offered as a response but has **zero priors** (green-up→bird was correctly dropped Phase 1), so selecting it lands the user on an empty table from a menu that looked like all the others. | `ui.R:25-28` selectInput offers 4 responses; `server.R:137` flat banner "No predicted drivers". PRIORS table confirms no `*→bird_index` row. | Remove `bird_index` from choices, OR keep it with a **designed** empty-state explaining *why* (trophic-mismatch is about synchrony, not later green-up→more birds) + a button to the ladder where it still shows descriptively. Add a one-line scope note to `plant_richness`/`greenup_doy` (single-driver, thin table). | **S** |

> The backlog already covers "strip dead JS." But note the specific land mine Vik/NEONize found inside it: `www/app.js`'s `heroObserver` MutationObserver watches `document.body` with `subtree:true` and fires `runCounters()` on **every DOM mutation** (every plotly render) to find zero `.count-up` elements. That's not just dead — it's an active perf drain on the capstone. Fold it into the strip-JS task as a priority, not a nicety.

---

## 2. PULSE TRACER — buildable spec (the flagship; all 5 reviewers' #1 idea)

**Goal:** tap a wet/warm anomaly year on the climate strip; an anomaly pulse travels DOWN the ladder at each prior's lag, and each next rung lights **GREEN** if it moved as the prior predicts, **RED** if not, **grey** if no data that year.

The architecture is ready: `PRIORS` carries per-link `lag`, `lag_pairs()` already keys `response[t+lag]` to driver year `t`, and `ladder_layer()` already z-scores. **Reuse those z-scores — do not re-implement, or the animation and static ladder will disagree.**

### 2a. Precompute at build time (Vik — makes the animation nearly free)
In `scripts/build_cascade.R`, after saving annual/signals/priors, add a **6th bundle element** `pulses`:

```r
# per (site, driver-year, prior-link): did the destination rung follow the prior?
PULSES <- lapply(sites, function(s) {
  a  <- site_annual(s)
  zl <- do.call(rbind, lapply(layers, function(L) ladder_layer(a, signals, L)))  # SAME z as ladder
  do.call(rbind, lapply(seq_len(nrow(priors)), function(i) {
    pr <- priors[i,]
    zx <- zl$z[zl$key==pr$from]; yx <- zl$year[zl$key==pr$from]
    zy <- zl$z[zl$key==pr$to];   yy <- zl$year[zl$key==pr$to]
    do.call(rbind, lapply(yx, function(t0) {
      di <- which(yx==t0); ri <- which(yy==(t0+pr$lag))
      if (!length(ri)) return(data.frame(link=i, t0=t0, driver_z=zx[di],
        resp_z=NA, lag=pr$lag, verdict="nodata"))
      moved <- sign(zy[ri]) == pr$sign
      data.frame(link=i, t0=t0, driver_z=zx[di], resp_z=zy[ri], lag=pr$lag,
        verdict=if (is.na(zy[ri])) "nodata" else if (moved) "match" else "miss")
    }))
  }))
})
names(PULSES) <- sites
saveRDS(list(annual=annual, signals=signals, priors=priors, meta=meta, pulses=PULSES), "data/cascade.rds")
```

This is deterministic and tiny (the full links+smatch precompute is 259 KB per Vik's measurement). **Update the bundle-shape comment** (`build_cascade.R:5`) and DEPLOY.md — both currently must read 6 elements; the live save is 4 today (`list(annual, signals, priors, meta)` confirmed at `:144`).

### 2b. Plotly frame build (Vera's spec, concretized)
Keep the 4-strip `subplot`. Add an animation **frame** dimension via `plotly::animation_opts(frame=900, transition=300, redraw=TRUE)`, accumulate-style reveal:

- **frame 0** — only the chosen climate anomaly marker glows at year `t0` (size bump 6→14→8 over 2 sub-frames).
- **frame 1** — draw the thread from `(climate, t0)` to `(phenology, t0+lag)`.
- **frame 2** — thread to producers at `t0+lag2`.
- **frame 3** — thread to consumers at `t0+lag3` (the rain→rodent lag=1).

### 2c. The per-hop thread (the hard part — Vera's solution)
Cross-subplot lines in paper coords are brittle. Instead use **`add_annotations` with per-subplot `axref`/`ayref`** set to each strip's axis (`x`/`y` for strip 1, `x2`/`y2` for strip 2, …). Each frame's `layout.annotations` adds **one more arrow** from `(driver year t, its z)` to `(response year t+lag, its z)`. The arrow's rightward x-shift of `lag` years **is** the honest geometric encoding of the time offset — no separate legend needed for lag.

### 2d. Verdict coloring (the differentiator)
Per hop, color the **destination rung's marker AND the arrowhead** from the precomputed `verdict`:
- `match` → green `#1a7f37` (dark-mode `#5fcf86`)
- `miss` → red `#AB0520` (dark-mode `#ff7a8a`)
- `nodata` → **dashed grey arrow**, never a fabricated green.

Annotate each lit hop with the real values: `precip +1.8 SD → green-up −1.2 SD, as predicted`.

### 2e. Honesty guards (non-negotiable — this is what keeps it from being a lie)
- Only animate hops where the destination year has **finite** data (the `nodata` branch above).
- Persistent banner: *"One year's ripple is an anecdote, not a test — the verdict tally on the ladder is the evidence; this shows you ONE path through it."*
- **Reduced-motion / no-JS / screenshot fallback:** render **frame-3 (all hops resolved) as the static first paint**. `prefers-reduced-motion` → snap to final, no sweep (pattern already in `app.js:18`).

### 2f. Controls & client/server split
- `plotly_click` on a climate marker sets `t0`; an "animate" play button uses plotly's built-in `animation_button`.
- Because frames are precomputed (§2a), the sweep is **pure client-side plotly relayout/restyle — zero server round-trips**, so it runs instantly even on a just-woken Connect worker.

---

## 3. Build order

### PHASE 2 — clear the readiness bar (ship-blockers + standard shell)

Do B1–B5 (§1) first. Then, in order of impact-per-effort:

| # | Item | What | Eff | Impact |
|---|------|------|-----|--------|
| P2-1 | **Precompute `site_links()` into the bundle** (Vik's #1 perf win) | `site_links()` = ~460 ms/site, runs on **every** site switch, no `bindCache` anywhere, but it's deterministic (`set.seed(1L)`). All 46 sites precompute in 11.8 s → 259 KB. Add `LINKS`/`SMATCH` to bundle; `links() <- reactive(CASCADE$links[[input$site]])`. Pairs naturally with the §2a pulses precompute (one rebuild). | **M** | **High** — half a second of dead air → a readRDS lookup on every interaction; makes Pulse Tracer affordable. |
| P2-2 | **Strip dead JS** | Replace `www/app.js` (~211 lines, 100% small-mammal: `smtTour`, `smtSaveCard`→`#smtCardNode`, `rodentConfetti`, `loadOverlay`, `kickMaps`, `animateCount`→nonexistent `.count-up`, the body-wide `heroObserver`) with a ~25-line `cascade.js` keeping **only** the popover-dismiss block (`app.js:158-175`) + a real ladder-resize-on-`shown.bs.tab`. Filenames also mislabel saves `neon-mammal-*.png`. | **S** | **High** — kills ~10 KB dead weight + the per-render MutationObserver on every visit. |
| P2-3 | **Trim `styles.css`** | 69 KB (1060 lines) mammal sheet shipped whole; ~14 cascade-relevant selectors vs `cascade.css`'s 40. Fold the live ~5 KB into `cascade.css`, delete `styles.css` from the link list. | **M** | Med — ~64 KB off first paint; removes the "edit the wrong file" trap. |
| P2-4 | **Downloads** (zero exist today — confirmed) | 3 `downloadHandler`s, self-describing filenames: (a) `{site}-cascade-annual.csv` (per-site annual table + methods header); (b) `{site}-link-scorecard.csv` (every prior: from/to/lag/n/r/CI/p/tier/verdict); (c) `{site}-cascade-ladder.png` via plotly `toImage`. All pull from the precomputed object → free at click time. | **M** | **High** — the suite's signature export funnel; absent on the data-richest app. |
| P2-5 | **In-app sibling + hub links** | About-tab `tags$a(href="#","small mammals")` (`server.R:199`) is a dead anchor; only outbound link is desertdatalabs.com. Add a suite registry (name/emoji/tagline/DPID/Connect URL — canonical URLs already in `docs/index.html:155-202`), render as About grid + sidebar `deck-foot` "Back to the suite hub", and deep-link each schematic layer to its product's app. Also fix `docs/index.html:234` `DRIVERS_URL` placeholder so the hub goes live + warms the app. | **M** | **High** — a capstone that doesn't link to what it synthesizes undersells itself; the doors-not-dead-ends rule. |
| P2-6 | **Scatter in-figure annotation + honest fit line** (Vera's highest honesty-per-line) | (a) Add a plotly `annotations` block top-left: `r=−0.92 · n=6 · p=0.012 · 95% CI [−0.99,−0.34]` from `r$r/r$n/r$p/r$lo/r$hi`; `n<6` → `n=5 · exploratory (no p)`; color by `TIER_META[[r$tier]]$col`. (b) Fit line (`server.R:177-179`) is solid gold `DDL$gold2` regardless of tier — color it gold **only** for `tier=='consistent'`; for `apparent`/`counter` draw thin grey `#9aa6b2` + note "fit shown for shape only — not distinguishable from noise." (c) Year labels always-on (`mode='markers+text'`, `server.R:173`) collide at n≥7 → move year to hovertemplate, drop always-on text (or label endpoints only). (d) When no fit drawn, add explicit line "No trend line below 6 years — read the points, not a slope." | **M** | **High** — a screenshot of the scatter currently carries no statistics; makes it travel. |
| P2-7 | **QC-flag panel** (cascade-level — the most compelling QC in the suite) | `cascade_qc(site)` returning ranked "verify, not wrong" flags: HIGH = signal on ladder with <3 finite years; WARN = climate year NA'd by the within-site MAD temp-outlier filter (`build_cascade.R:42-44` silently drops e.g. SCBI 2018 — surface the offending year); WARN = link with CI spanning 0 at n≥6 shown as "apparent"; INFO = green-up from <5 individuals (`ann_phe:52`); INFO = mammal CPUE years with thin deployed-trap-night denominators. Each flag clickable → offending rows + per-flag CSV. **Emit `.qc-flag-<level>` classes** (suite standard), migrate `styles.css` off the deprecated `.qc-flag.high` compound convention. | **L** | **High** — turns "trust me" into "check me" for the PI audience. |
| P2-8 | **Codebook / methods tab** | Render `SIGNALS` (key/label/layer/unit/higher_is) as a codebook + derivation notes (CPUE = 100×captures/deployed-trap-nights — surface the Phase-1 denominator fix as a transparency win; green-up = median onset DOY where n_ind≥5; bird_index = clusterSize/point; intro% denominator) + the n-gating thresholds + the QC gates (≥8-month temp, ≥10-month precip, MAD outlier NA, n_ind≥5). | **M** | Med-High — cheapest credibility win; feeds the download methods-header. |
| P2-9 | **Mobile** | See §4 — the flagship cannot render readable text on a phone today. | **M** | **High** |
| P2-10 | **Empty-state plots theming** (Vera) | `note_plot()` (`server.R:12-15`) skips `theme_plotly()` → no Rubik font, no `responsive=TRUE` (only data plots get it). Route through `theme_plotly()`, raise message font to 15, add a glyph so empty reads as intentional. | **S** | Med |
| P2-11 | **Cleanups** | Delete stray `%d` file (270 B, confirmed in root) + `.gitignore` it; delete unused `fmt_int` (`global.R:60`); correct bundle-shape comments to match the real save; guard `DEFAULT_SITE` block with `if ('SCBI' %in% ALL_SITES)` to skip the wasted load-time vapply; add a one-time "data bundle failed to load" UI banner for the silent-empty rds-missing path; add `RColorBrewer`+`jsonlite` to CI deps (`build_cascade.R` sources a sibling that references them). | **S** | Med |
| P2-12 | **First-run comprehension** (Alyssa) | Overview leads with the priors-not-dredge caveat + amber warning before any line moves. Lead instead with the schematic + the one headline that works (`overviewInsight` already computes `sm$txt`); demote the methodology caveat to a dismissible amber `ctx_note` below it. Also fix `linkChips` to say *why* a link is insufficient in plain language ("plant + mammal years don't overlap here yet" beats "0 overlapping years"). Fix `overviewInsight` fallback hardcoding "try SRER, HARV, or SCBI" — SRER (1/3) and HARV (1/4) are messy; suggest SCBI (the one consistent link). | **M** | Med-High — deflating first impression on a capstone. |

### PHASE 3 — best-app moves (what earns "best in the suite")

| # | Item | What | Eff | Impact |
|---|------|------|-----|--------|
| P3-1 | **Pulse Tracer** | Build per §2. THE flagship. | **L** | **Highest** |
| P3-2 | **Suite-wide sign-match scoreboard** | Promote `signmatch_score` from per-site to a cross-site, **precomputable** leaderboard. Two views: (a) small-multiples grid (rows=sites, cols=6 prior links, cell=tier color) sorted by binomial p — instantly shows temp→greenup lights green across sites while producer→consumer is mostly grey; (b) the meta-question pooled **across** sites per link (only 96/276 site-links clear n≥6, so cross-site pooling is the statistically honest way to beat the short-series problem). Each row = a door that loads that site. Live numbers: SCBI 3/4 (p=0.31), HARV 1/4 (p=0.94), SRER 1/3 (p=0.88). | **L** | **Highest** — the only view in the whole suite that answers "does bottom-up cascade theory hold in NEON?" Genuinely novel, fundable, screenshot-worthy. Honest because it shows the grey untestable majority. |
| P3-3 | **Cascade-completeness map** | Static `plotly` scattergeo (~46 points — keeps the package list lean; no leaflet dep) sized/colored by **testable-link count** (Alyssa verified this diverges sharply from layers-present), doubling as the site picker (click → `input$site`) and as an honest coverage statement. If leaflet is used instead, it MUST be a static `leafletOutput`, never inside `renderUI` (Connect Cloud htmlwidget re-bind race). | **M** | High — replaces the bare dropdown; makes data gaps a feature. |
| P3-4 | **Downloadable site scorecard (PNG/PDF)** | One page: ladder thumbnail + link chips w/ verdicts+CIs + sign-match tally + QC summary + codebook footer + priors-vs-data table + "consistency not causation" caveat. **Server-side `cairo_pdf` `downloadHandler`** (per playbook §2d) — NOT the dead client html-to-image path in `app.js` which depends on CDN globals this app never loads. | **M** | High — the grad-student-pastes-into-lab-meeting artifact. |
| P3-5 | **Cover/landing splash** | One-screen animated cascade explainer + the completeness map, leading into SCBI. Every sibling opens on a splash; the capstone has none. | **M** | Med-High |
| P3-6 | **Export the link registry with selection status** | Export from/to/sign/lag/citation plus family version and the explicit fact that the current registry evolved during inspection of these data. A future confirmatory registry must be dated and frozen before genuinely held-out observations are analyzed. | **S** | Med |

---

## 4. Mobile fixes (all four UX/perf reviewers flagged; currently the flagship is unreadable on a phone)

**Root cause:** `plotlyOutput` height hardcoded `'560px'` (`ui.R:60`); **no viewport-width signal sent to the server** (grepped — no `Shiny.setInputValue` of `innerWidth`). On 375px, 4 stacked subplots get ~120px each, `tickfont` stays size 9, and the h-legend (`y=-0.08`) wraps and collides with the "year" axis title. `responsive=TRUE` rescales WIDTH but cannot fix baked SVG text or the legend crush. This is the exact "phone text is a canvas problem" trap from the playbook.

1. **Send `innerWidth` to the server** on connect + resize (the `setInputValue` trick the suite already uses). Bundle this with the `bindCache`/precompute device-width key so the cache never serves desktop SVGs to phones.
2. **Under ~700px:** taller per-layer height (~150px/layer, let the user scroll) instead of cramming 4 strips into phone height; bump `tickfont` to ~11.
3. **Turn the h-legend OFF on narrow screens** — rely on the colored per-strip y-axis titles that already exist (`LAYER_META` carries title+color). On desktop, given the B4 per-layer-ramp fix, **end-of-line direct labels** are the premium choice and remove legend-crowding entirely (each strip has only 1–4 lines).
4. **Optionally facet to one-layer-at-a-time** with a layer toggle on phones.
5. **CSS:** `cascade.css` has exactly one `@media` rule (line 44, schematic arrow). Add `@media(max-width:800px)` to stack the ladder above the chips full-width and reflow the link-chips/driver-table. Verify the `.casc-arrow` rotate-90 actually triggers — flex nodes wrap at `min-width:150px`, which can happen well before 800px, leaving sideways arrows mid-stack.
6. **Sidebar self-clean:** auto-close the off-canvas drawer on nav-tab tap <768px; echo the Driver Lab response in the hero band (currently only in `labTitle` textOutput); move the theme toggle to `deck-foot` (it's a preference, not a task) so the two real controls don't compete with it.

---

## 5. THE ONE move

**Build the Pulse Tracer (§2) — but only after the precompute (P2-1 + §2a) lands, because precompute is what makes it free.**

Every reviewer named it #1 independently. The ladder today is four parallel line charts where the user is *told* to "watch pulses march down" but nothing helps them see it. The Pulse Tracer turns the app's entire thesis into a 3-second tap-gesture: tap a climate anomaly → watch it ripple down the rungs at each prior's lag → each rung lights green (followed the prior) or red (didn't). It is touch-native, it visualizes the lag structure that's currently invisible, and it is **honest by construction** — it only animates rungs where a prior exists and data permits, it shows the misses in red, and it carries the "one path is an anecdote, the tally is the evidence" guard. With frames precomputed into the bundle it's pure client-side relayout — zero server cost, instant even on a cold worker. It is the single feature that earns this app the title of best in the suite, and the suite-wide sign-match scoreboard (P3-2) is the natural second beat once it lands.

**Verified file references:** `NEON-Driver-Cascade/server.R` (ladder `:87-111`, color bug `:93-100`, scatter/fit `:170-183`, dead About link `:199`), `scripts/build_cascade.R` (priors `:126-133`, bundle save `:144`), `R/cascade_helpers.R` (`lag_pairs:17`, `link_stat:26`, `site_links:53` w/ `set.seed(1L):54`, `ladder_layer:84`, `signmatch_score:66`), `.github/workflows/refresh-data.yml`, `manifest.json` (stale checksums), `ui.R` (ladder height `:60`, Driver Lab choices `:25-28`), `www/app.js` + `www/styles.css` (dead), `docs/index.html:234` (placeholder URL), stray `%d` in repo root.
