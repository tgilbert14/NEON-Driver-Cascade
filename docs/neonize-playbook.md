# The NEONize Playbook

**How to build or remake a trustworthy NEON data-product app.**

"NEONize a product" = take a NEON data product and ship an app that clears the
suite's bar for **flow, UI, statistics, creativity, QC, release trust, and honesty**
while keeping insights native to that product. Small Mammals supplied many early
interaction patterns, but it is a reference implementation, not permanent proof of
correctness and not a template to copy without revalidation.

## Authority and current program state

This file is the reusable pattern catalog. It is not the current release register.

- `docs/NEON-SUITE-LEARNING-LOOP.md` owns pass order, evidence status, and Driver
  decisions.
- `docs/NEON-SUITE-REVAMP-PLAN.md` owns the 2026 suite target, Phase 0 recovery,
  per-app briefs, cover system, and completion gates.
- Each repository's `AGENTS.md` and complete `docs/BUILD-TEST-HANDOFF.md` own the
  commands and evidence for that app.

Historical examples below remain useful, but a named app, workflow, runtime, or
metric is not current evidence unless its app-local handoff and release receipt say
so. Finding documents must distinguish `OPEN`, `FIXED`, and `VERIFIED`; do not infer
status from prose written before later commits.

This doc is the contract. It has three layers:
1. **The quality bar** — the dimensions every NEONized app must hit.
2. **The reusable full stack** — what ports wholesale (design system, data bundling, shared helpers, the pin-card system, report PDF).
3. **The NEONize procedure** — the evidence-producing research → design → build → adversarially-verify → ship loop, run fresh per product.

---

## 1. The quality bar (the six dimensions)

Every NEONized app is judged on the same axes the flagship nails:

| Dimension | What "flagship quality" means |
|---|---|
| **Flow** | A site/entity picker → a fast primary story → progressively disclosed analysis. One global selected-entity state every view reads. No dead ends; every empty state offers the next action. Deep links and restored sessions must not skip honesty context. |
| **UI** | Shared suite structure with product-specific visual tokens: a local/system font stack, accessible cards, responsive task-oriented navigation, consistent methods/QC/download actions, and app-native organism/habitat color. Light and dark modes are optional product choices but every chart must honor the active mode. |
| **Statistics** | Defensible, cited methods (Hill/Chao1/rarefaction/Schnabel/etc.). Every headline number has an `insight_banner()` "answer up front". n-gates before reporting. De-pseudoreplication. The right effort/scale fixed before any comparison. |
| **Creativity** | Playful framing with real science underneath — emoji, rarity tiers, celebratory confetti on standouts, a shareable "trading card", a signature interactive (the Size Lab pin-card scatter). Show-off, not gimmick. |
| **QC** | The app is *useful to the people who collect the data*. Click-to-inspect flag→modal/record patterns. Honest outlier flags that are KEPT not deleted, phrased "verify, not wrong". A downloadable per-entity QC record. |
| **Honesty** | The non-negotiable. Every claim is stated where it lives (on the chart, screenshot-safe). Caveats for what the method can't say. No false precision. "Not detected ≠ absent." Match rates published for joins. Deliberately-omitted analyses stay omitted (e.g. SMI). |

If a feature can't be done honestly on the product's data, it doesn't ship — it gets a caveat or a "why not" note instead.

---

## 2. The reusable full stack (ports wholesale)

A NEONized app is a **lean independent sibling directory** (copy-with-attribution, like the
mammal/beetle apps — NOT a shared package; independent deploys must stay self-contained). Copy
these from the flagship and adapt the data layer:

### 2a. Design system & chrome — vendor a pinned version, then adapt
- `docs/index.html`: lead with one memorable, product-native question or promise,
  then map 2-4 real user questions directly to app routes. Prefer a licensed,
  provenance-tracked documentary image when field realism earns trust; use an
  explicitly stylized illustration when abstraction is the point. Cohesion comes
  from shared navigation, claim boundaries, release receipts, and suite registry —
  not identical hero layouts or paragraphs of generic suite prose.
- `global.R`: semantic tokens (`accent`, `signal`, `warning`, `ink`, `muted`,
  `surface`, `line`) mapped to an app-specific palette; `app_theme` (bslib bs5 + a
  system/local font stack); `asset_url()` (mtime cache-bust); and the validated
  card/banner/loading helpers appropriate to the product.
- `ui.R`: `page_sidebar`, a local-only `<head>` library block (committed/pinned sweetalert2, canvas-confetti, driver.js, **html-to-image@1.11.11**, styles.css, app.js), the splash/national-site-picker (STATIC `leafletOutput`, never inside a `renderUI` — the Connect Cloud re-bind race), the loading overlay, the DDL business footer.
- `server.R`: `plotly_theme(p)` (theme-aware, the navy+gold hoverlabel, `displayModeBar=FALSE`), `note_plot()` empty-state, `ctx_anno()` (BUT see gotcha #5), the `is_dark()` reactive.
- `www/styles.css` `:root` tokens + dark-theme block; `www/app.js` (count-up engine, confetti, loading overlay, the custom-message handlers).

### 2b. Data bundling — copy the pattern, swap the product
- `scripts/refresh_data.R`: per-site `loadByProduct` → trim to a `keep` column vector → xz-compress → `data/sites/<SITE>.rds`. Build with **R-4.1.1** (neonUtilities; R-4.5.2 crashes on `loadByProduct`). Token in gitignored `.neon_token` (env `NEON_TOKEN`).
- `read_bundle()` (defensive — NULL on missing/corrupt, never crash boot), `load_site_bundle()`, `data/site_index.rds` (one row/site for the picker), the manifest→republish discipline (Connect Cloud serves the *published* snapshot — rebuilt bundles aren't live until `writeManifest()` + commit + republish). See `docs/data-bundling-pattern.md`.
- A committed `data-sample/` demo so the app runs bundle-only with no network (demo-on-startup).

### 2c. Shared analysis helpers — port the defensible ones
From `R/helpers.R`: `species_level_only()` (drop genus-only/morphospecies before any richness), `make_species_pal()` (one color per species across all charts), Hill numbers / `species_accum()` (rarefaction + Chao1 w/ CI), `mode_chr()`, `safe_*()` NA-safe reducers, the n-gate idioms. The diversity family ports to almost any taxon product.

### 2d. The interactive-downloadable-plot funnel — the signature every app gets
The Size Lab (`www/pincards.js` + the plotly `customdata` pattern in Small Mammals) is
the template for **the one interactive every NEONize app should ship**: a "position entities in a
2-D space → pick one → inspect → take it with you" funnel. The full funnel, in order:

1. **Position** every entity (individual / plot / species / taxon — the product's unit) on one chart,
   coloured by a meaningful class, with **a filter (species/site/etc.) and an honest, gated overlay**
   (a fit line drawn *only* where the relationship is real; framed as what it IS, e.g. "a QC map, not
   a body-condition index").
2. **Click → pin a profile card** (draggable/resizable, gold leader line anchored to DATA coords).
3. **Chip on the card → a per-entity profile / QC record** (`output$…Card` + `individual_qc_flags()`
   analog: ranked, *"verify not wrong"* data-quality flags). **Scroll it into view** on open (custom
   message → scroll the rendered card node, §4).
4. **Download the works:** the chart with pins baked in (html-to-image PNG), the profile/QC card
   (PNG), and the raw per-entity record as **analysis-ready CSV metadata** (`downloadHandler`).

**It is plotly, not ggiraph** (the apps are already plotly; no second rendering stack). This funnel —
click-for-profile, QC checks, downloadable plot + card + metadata — is a **default deliverable**, not a
one-off; map it to each product's unit. Carry the hard-won gotchas (§4).

### 2e. Report PDF — `R/report_pdf.R`
Base `grid`/`grDevices` `cairo_pdf` (no LaTeX/Chrome), streamed by a `downloadHandler`. Re-theme
the page geometry from `DDL`; swap the per-product content renderers.

### 2f. What does NOT port (product-specific — design fresh every time)
The **entire data model and its "unit of analysis."** For small mammals the unit is the
*tagged individual* and its mark-recapture career — so the dossier, Hall of Fame, MNKA detection,
age/lifespan, tag-identity QC, home-range/trap-grid, body-measurement outliers are all
mark-recapture-specific and port to **nothing** without individuals. Before building, answer:
**what is this product's unit, and what is its capture career analog?** (For count/cover products
there are no individuals — the unit is the plot, the species, or the trap x bout.
The app's current `DATA-TAKEAWAYS`, expert review, and knowledge package are the
reference; chat or named memories are not.)

---

## 3. The NEONize procedure (run fresh per product)

A repeatable, evidence-producing loop. Parallel review is optional; durable
artifacts and independent verification are required. Follow the one-app cycle and
decision vocabulary in `docs/NEON-SUITE-LEARNING-LOOP.md`.

**Phase 0 — Freeze the app and its release.** Read the app-local instructions and
complete handoff; record source/deployed commits, bundle/manifest hashes, public
health, worktree ownership, and current tests. If the public app is down or the
manifest is incoherent, recover release trust before redesign publication.

**Phase 1 — Research the product (gated and required).** Produce evidence for five
lenses, whether one person or several reviewers do the work:

- schema/method: exact DPID, tables, fields, design, protocol eras, and data volume;
- domain: cited product-native meaning, mechanisms, caveats, and forbidden claims;
- statistics: estimand, sampling unit, effort/opportunity, zeros, missing/censoring,
  uncertainty, pseudoreplication, support gates, and export grain;
- architecture: reuse/adapt/skip/net-new map plus startup, bundle, manifest, and
  deployment dependencies; and
- product: primary user jobs, signature interaction, accessibility, visual identity,
  and one grounded improvement worth the complexity.

**Phase 2 — Design.** Lock the unit of analysis; CAN/CANNOT/HELD claim list;
task-oriented information architecture; primary interaction; data/bundling plan;
codebook and QC contract; and expected Driver disposition. Register any hypothesis
before viewing held-out results.

**Phase 3 — Build.** Vendor only pinned, relevant patterns from section 2. Build the
product-specific transform, helpers, renders, navigation, interaction, styles,
tests, codebook, cover, social card, handoff, and knowledge package. Keep app boot
bundle-only and network-independent.

**Phase 4 — Adversarially verify.** Review the **git diff** independently for R
correctness, science/statistics, frontend lifecycle/accessibility, field/QC use,
deployment/security, and data/manifest integrity. Triage by severity, fix supported
blockers and high findings, and rerun the complete ordered gate set.

**Phase 5 — Verify in the running app.** Start in the pinned runtime; exercise the
three primary user funnels with real inputs, including empty/error states, deep
links, keyboard paths, downloads, dark/light where applicable, reduced motion,
desktop, tablet, and 390px mobile. Require zero unexplained server/console/network
errors and stable geometry rather than screenshot-only proof.

**Phase 6 — Publish and close.** Update the app-local handoff, the central suite evidence
register, and the Driver implication backlog with exact evidence. Promote reusable
gotchas into this playbook. Then regenerate/verify the manifest, publish only when
authorized and green, and bind the green head, merge commit, deployed identity,
manifest hash, landing/social assets, and content-aware public app check in one
release receipt.

---

## 4. The gotcha catalog (carry into every NEONize)

- **R version:** R-4.5.2 runs the app but **crashes on `neonUtilities::loadByProduct`** (access violation). Pull/bundle data with **R-4.1.1**. Launch R via **PowerShell**, not git-bash (git-bash segfaults R here). Reference neonUtilities by a *computed* package name so the rsconnect scanner doesn't pin it into the manifest (the deploy is bundle-only + lean).
- **Fonts and boot assets must be network-independent.** Runtime theme font helpers that fetch or compile remote fonts are a cold-start failure mode, and a client-side font stylesheet is still an external rendering dependency. Use a system stack, or commit licensed font files and verify their checksums. The Driver's proven default is `system-ui`/platform sans with local serif fallbacks. Audit startup and first render with network blocked; a manual republish that only warms a cache is not a fix.
- **A 320px viewport may have only 305px of usable layout width.** Desktop test
  browsers can reserve 15px for the vertical scrollbar, so `body { min-width:
  320px }` and edge-to-edge `100vw` carousels create page-level horizontal drift
  even when the screenshot looks plausible. Use parent-relative sizing for local
  scrollers, allow the body below 320px, and require
  `documentElement.scrollWidth === documentElement.clientWidth` at both 390 and
  320 CSS pixels. A carousel's own larger `scrollWidth` is valid only while the
  root stays fixed.
- **In an R list, `$field <- NULL` deletes the field.** If a bundle schema requires
  a named field whose honest unavailable value is `NULL`, preserve it with
  `bundle["field"] <- list(NULL)`. Normalize filtered zero-row derived frames to
  that representation, verify the required name and container type, execute every
  migration twice, and require identical all-bundle hashes on the second pass.
- **plotly re-render kills event handlers:** a Shiny+plotly re-render runs `Plotly.purge`+`newPlot` on the SAME div, silently wiping `gd.on()` listeners. **Never** gate binding on a persistent expando — re-attach `plotly_click` on every render (rAF-debounced MutationObserver scan). This was the Size Lab blocker.
- **plotly pin anchors must be DATA coords**, recomputed via `gd._fullLayout.xaxis.l2p()+_offset` on `plotly_relayout` + a `ResizeObserver` — frozen pixels drift on resize/fullscreen/rotate. Anchor from the data point, not the click event (touch has no `clientX`).
- **`ctx_anno()`/`add_annotations` accumulates** across reactive re-renders (the binding doesn't clear it) — fold the caption into the `layout(annotations=...)` list instead, so it's replaced wholesale. (Invisible when copies overlap, but real.)
- **Named-vector `updateSelectInput`** spams console warnings — wrap choices as `as.list(setNames(...))`. Build filter choices from the *plotted* subset so a choice can't land on an empty chart.
- **selectize fires `change` via jQuery `.trigger()`** — a native `addEventListener('change')` never sees it. Listen on `shiny:inputchanged` (jQuery) or the widget's own event.
- **`validate(need())` doesn't display in some widget outputs** (stale output persists) — return a real message-chart/empty-state instead.
- **`asset_url()` bakes the cache-bust version at app start** (ui is an object, built once) — a running server serves the old `?v=` after you edit a `www/` file; **restart** to pick up JS/CSS changes in preview.
- **html-to-image over WebGL fails** — force SVG (`scatter`, not `scattergl`/`toWebGL`) for any chart you want to export; `Plotly.Plots.resize(gd)` before `toPng` (a tab that rendered hidden can be 0-sized); strip live animation classes before capture.
- **Register pin-binding listeners BEFORE any aux handler in the IIFE.** A `Shiny.addCustomMessageHandler(...)` (or any statement) placed near the top of `pincards.js`, before the `DOMContentLoaded`/`shown.bs.tab` bind listeners, can throw during head-eval and abort the IIFE so binding never registers — tap-to-pin silently dead, with **no captured console error** (the throw predates the preview's console hook). Put the binding listeners first; put aux handlers last and `try`-guarded. (Caught verifying the Size Lab scroll fix — it had killed the whole pin layer.)
- **The `dataSig` pin-clear must ignore the highlight/"tracking" trace.** Selecting an entity appends a gold highlight trace (N→N+1); a trace-count-based signature flips and wipes every pin the instant the user opens a profile from a pin (the happy path). Filter the highlight trace out of the signature.
- **Scroll-into-view: target the rendered card node, NOT the uiOutput wrapper.** A bslib `uiOutput` in a fill layout is `display:contents` — it has **no box**, so `scrollIntoView` on `#…Output` is a silent no-op. Scroll the actual rendered child (`#…CardNode` / the empty-state node), polling until it exists AND has `height > 1` (the card re-renders async after the select). (The Size Lab scroll bug: a fixed-delay scroll to the wrapper did nothing.)
- **Never pool repeated visits as independent samples.** NEON re-surveys the same plots/quadrats yearly. Pooling years into a richness / rarefaction / Chao estimate treats one quadrat's 7 visits as 7 spatial samples — it inflates richness ~2× and the incidence-unit count several-fold, and conflates spatial with temporal turnover. Compute snapshot metrics on **one survey per unit** (a `latest_snapshot()`); reserve the multi-year table for the explicit time-series. (Caught by the plant-app review.)
- **Area-scaled metrics (density, per-ha, cover share) must be scoped to the population actually sampled over that area.** NEON nested-samples small stems / fine scales over a SMALLER area than the headline area variable — dividing everything by the big area biases the small classes low (a flat curve that's a sampling artifact, not biology). Scope to the protocol threshold (e.g. trees ≥10 cm DBH over `totalSampledAreaTrees`) and label it. Quadratic/RMS stats (QMD) must be POOLED (`sqrt(ΣD²/Σn)`), never a mean of per-unit RMS values (Jensen). (Veg-app review blocker.)
- **One fixed output id, not one-per-entity.** A `renderPlotly`/`renderUI` registered under a per-row id (`output[[paste0("spark_", id)]]`) accumulates a new binding for every entity the user opens (a slow leak). Use a single fixed output that reads the selected-entity reactive.
- **Cover/percentage SHARES need a structural-zero denominator** (divide by all sampled units, not only where-present) — present-only means inflate patchy categories and distort the share. And a headline metric must use **one shared function** in the bundler and the app, or the picker and the hero will show different numbers for the same thing.
- **dplyr `summarise()` sees earlier newly-created columns** — `richness = mean(richness)` then `sd = sd(richness)` makes sd operate on the scalar mean (→ NA). Compute the spread before the reassignment.
- **Adversarially verify the diff with an independent pass** every time. A second
  reviewer, a deliberately separate review pass, or both can provide independence;
  named personas are not evidence. Record the findings and disposition in the
  handoff.

---

## 5. The flagship feature inventory (steal the best, per product)

From the **Small Mammal Tracker**: the splash national picker (by-site / by-species), demo-on-startup,
the hero stat band (clickable → ranked-breakdown modal), the species-first Overview with an
auto-written narrative (`site_insights()` compute→rank→glue), the Population tab (MNKA+CPUE,
detection-corrected abundance, species accumulation+Chao1, env-driver correlation overlays with the
driver-semantic color system), the Community Pulse (sex/age, Hill profile, per-plot trends,
body-size profile, lifespan, phenology), the **Hall of Fame** leaderboard (rarity tiers, re-sortable),
the **Dossier** trading card (+ downloadable PNG), the **Size Lab** (pin-card scatter + QC card),
the click-to-inspect QC modals, the report-card PDF, the two-site compare.

From the **Girth Index**: highlight-one-in-a-grey-cloud, named-quadrant scatter, violin+jitter+mean
"position DNA", before/after arrow chart, percentile-band trend, the holographic trading card, the
reusable hover-card builder, the narrative-insight generator, the config-driven entity picker.

For each new product, map these to the product's unit and KEEP the ones that stay honest;
invent the product-native ones the research surfaces.

---

## 6. Deployment & maintenance — the full lifecycle (dev → deploy → self-update)

The suite standard is **Posit Connect Cloud with a Git-backed source**. Repository,
Connect deployment, and public semantic health are separate release identities.

**Deploy model (Connect Cloud, git-backed):**
- The app lives on Connect Cloud, pointed at a GitHub repo and branch. A merge makes a
  source revision available, but does not prove that Connect rebuilt or serves it.
  Treat the merge as publication intent; inspect **Last deployed**, explicitly
  republish when it lags, then require app-specific semantic health. Record the green
  PR head, merge, Connect-deployed commit, and public receipt separately. There are no
  shinyapps.io secrets, no `rsconnect/` directory, and no `deploy.R` step in this path.
- Required in-repo: a lean **`manifest.json`** (`rsconnect::writeManifest()`; bundle-only, keep
  `neonUtilities` OUT via the computed-package-name trick), the committed `data/` bundles, and a
  `docs/index.html` GitHub Pages showcase whose `APP_URL` points at the live Connect Cloud app.
- Close publication with one receipt tying together the green PR head, merge commit, and exact
  Pages-deployed commit; also update and verify the repository description and homepage.
- Test the live showcase at desktop and 390x844 mobile after layout stabilizes or a reload:
  require zero persistent horizontal overflow, correct canonical/OG/Twitter metadata, the social
  image's natural dimensions, an empty unexpected console/network failure set, and successful
  responses for every app/sibling/license link. An immediate viewport-transition frame is not
  release evidence; remeasure it, but treat persistent overflow as a blocker.
- Every generated family must name one canonical release-byte platform/toolchain or prove exact
  byte identity everywhere. Keep that platform's exact-byte gate; use other platforms for strict
  schema/key/text/source/decision checks and only explicitly named bounded numeric diagnostics.
  Never round artifacts to force parity.
- Treat installed-package provenance and the deployment platform's network contract
  as separate gates. For an exact direct-URL CRAN install, retain `RemoteType: url`
  and the exact `RemotePkgRef`, but require deployable top-level `Source: CRAN` plus
  an absolute repository URL when Connect needs to resolve current/archive paths.
  Strip only explicitly reviewed non-semantic source-build clocks such as
  `description.Built`; retain versions, origins, refs, compatibility, and checksums.
  A real Connect dependency-install receipt is required before the pattern becomes
  reusable.
- Treat ordinary CRAN and Posit/RSPM records as semantically equivalent only after each complete
  manifest independently passes trusted-repository, version/ref/SHA, pinned-snapshot,
  optional-platform, dependency, deploy-surface, and checksum validation.
- Inventory every Shiny custom-message registration and require each handler to take
  exactly one payload argument, even when the payload is unused. Parse-only checks do
  not catch the Shiny 1.14 registration failure caused by zero-argument handlers.
- Branch naming is split across the suite (`main` vs `master`) — each workflow must push to the
  branch its own Connect Cloud app watches. Standardize new repos on `main`.

**Auto-refresh + self-deploy (`.github/workflows/refresh-data.yml`) — copy the trust shape,
then choose the app's documented cadence:**
- Product apps normally refresh on the first Saturday; derived/master apps run later (the Driver
  uses the second Saturday) so upstream publication can settle. Keep `workflow_dispatch` for
  controlled reruns, but do not pretend every app has the same dependency schedule.
- Required download, build, contract, manifest, receipt, and publication gates fail closed.
  `continue-on-error` is reserved for genuinely optional diagnostics that cannot affect published
  bytes or the release decision.
- Give write permission only to a restricted publisher after a read-only producer
  and validator have passed. A review-PR flow or a restricted automatic publisher
  can both be valid; neither is trusted without stale-base, manifest, exact-diff,
  and release-receipt checks.

**Derived/master apps (e.g. Driver Cascade):** never build from moving shallow-clone heads or copy
unverified sibling directories. Allowlist canonical origins, capture exact commits, verify the
consumed scopes, materialize immutable Git-object snapshots, and build in a no-write producer job.
Pass only the allowlisted artifact family plus a SHA-256 receipt to a fresh validator. Give write
permission only to a restricted publisher that rechecks the receipt, stale-base condition, manifest
policy, exact file allowlist, and final diff before pushing the watched branch. Include every actual
input product (including mosquitoes for the current Driver), and keep the source lock durable.

## 7. Per-app readiness checklist (audit every app against this)

Data bundles: `data/sites/*.rds` present + valid (loadable, non-empty) · `data/site_index.rds`
(picker) · `data-sample/demo.rds` (instant demo) · all git-tracked · refreshed within the cadence.
Automation: `.github/workflows/refresh-data.yml` on the product's documented schedule · separates
producer/validator/publisher authority · records calendar-gated work as skipped, not refreshed ·
`manifest.json` coherent · GitHub **remote** exists · `docs/index.html`
`APP_URL` is live. NEONization: cover/landing splash · **in-app sibling links** + `docs` cross-promo
grid covering the WHOLE suite · mobile-responsive CSS (`@media`, prefers-reduced-motion) · **QC-flag
system** (§ below) · metadata/codebook view · comprehensive downloads (CSV + card PNG + report PDF) ·
entity pin-cards · current shared chrome (styles.css + app.js + pincards.js).

**The QC-flag system (gold standard — every app gets it; first ported to birds):** `<entity>_qc()` →
ranked *"verify, not wrong"* flags (high/warn/info) + the EXACT offending rows behind each; surfaced
on the entity profile INSIDE the export node (PNG captures it); each flag **clickable → inspector
table** of offending rows + per-flag CSV; a full **QC-report CSV** (`<entity>_qc_report()`); clean
path shows a green reassurance. Tune thresholds **data-derived + domain-grounded** (ask the domain
agent) and validate on contrasting sites so it never cries wolf (target ~0 high on clean NEON data).
CSS class convention: standardize on `.qc-flag-<level>` (not `.qc-flag.<level>`).
The current bird implementation is one concrete reference; each app still requires
domain-grounded thresholds and fixture evidence.

**Search the network (the bundled-index search tab — every app with a national footprint gets it):**
a "Search" nav_panel that queries a SMALL precomputed `data/search_index.rds` (one row per searchable
unit), loaded ONCE at boot like `site_index` and filtered in memory, so it stays instant with NO live
fetch. Builder `scripts/build_search_index.R` READS the committed bundles (never fetches) and writes the
index; add the index to the app's explicit deploy-file allowlist so `write_manifest.R` bundles it (rerun the manifest:
DT becomes a dependency). Two query modes via a radio/segmented control: **(a) Find-a-taxon/link** —
a `selectizeInput` autocomplete of every unit in the index → a `DT` of every site where it occurs with
the app's honest per-site MEASURE + years; **(b) a product-specific threshold query** → a `DT` of the
matching sites, sortable. Each row carries a **"Open →"** link that raises the SAME `goSite`/`siteExplore`
input the browse list uses, so the jump loads from the bundle and lands on the Overview (one selection
path everywhere). Show a **result count** ("12 of 46 sites"), an **empty state**, and a **one-line honest
caption** (the measure is a within-site index / space-for-time screen, not an absolute ranking; for short
per-site series, keep the pooling caveat and point to the cross-site test). DT gotcha: wrap `DTOutput`
in a plain `div(style="width:100%")` and do NOT `spin()` it (the bslib fill-container 0-width trap).
*First built on the Driver Cascade / Response Atlas* (DP-derived, no taxa): the searchable units are the
per-site direct-pair rows (`cascade.rds$suite_links`) — “find every site with data for a registered
driver→response pairing” + “rank sites by descriptive direction agreement among vote-eligible rows.”
Per-site rows are never called significant; context-only rows remain searchable but excluded from inference,
and the Across NEON panel carries the exploratory cross-site summary and its sensitivities.

**Sibling links + cover page:** Driver owns one versioned suite registry (app ID,
name, role, mascot, palette, DPID, repository, showcase URL, live URL, release
state, and Driver disposition). Generate the cover relationship nodes and in-app
Suite panel from that registry, then vendor a pinned copy in every independent app.
CI verifies the declared registry version so a new app or URL cannot drift across
ten hand-edited copies.

## 8. Suite learning and Driver feedback

`docs/NEON-SUITE-LEARNING-LOOP.md` is the central source of truth for the planned
nine one-at-a-time app passes and the later Driver v2 synthesis. Each pass must:

1. update the app-local build/test handoff with exact commands, expected/actual
   results, hashes, failures, cleanup, and invalidated evidence;
2. emit the required Driver knowledge package, including unit, support,
   opportunity/effort, zero/missing rules, joins, mechanisms, and claim limits;
3. classify each learning as app-local, suite-platform, scientific-contract,
   and/or Driver-impacting;
4. update the central suite register and Driver backlog, including explicit
   `REJECT` and `NONE` decisions; and
5. back-propagate any Driver parity failure or missing audit field to the owning
   app instead of hiding it in Driver adapter logic.

Do not repeatedly rebuild Driver from half-reviewed sibling states. Finish and pin
the nine app knowledge packages first, run the cross-product gap audit, decide
whether a complementary product is justified, and then integrate only accepted,
immutable inputs in one deliberate Driver v2 pass. Durable repository records—not
chat-only memory—are what allow later sessions to build on earlier work.

---

*Living pattern catalog. Plant Diversity, Birds, Phenology, Vegetation Structure,
and Driver supplied many of the examples. Current pass status and verification live
in the suite learning loop and app-local handoffs, not in named agents or chat-only
memory.*
