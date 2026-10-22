<!-- playbook-version: 2026-10-22 -->
# The NEONize Playbook

**How to build or remake a trustworthy NEON data-product app.**

"NEONize a product" means: take a NEON data product and ship an R/Shiny app that clears the suite's bar
for **flow, UI, statistics, creativity, QC, release trust and honesty**, with insights native to that
product, not a reskin. The Small Mammal Tracker (NEON-Small-Mammal-Tracker-App, DP1.10072.001) supplied
most of the early interaction patterns. It is a reference implementation, not proof of correctness and not
a template to copy without revalidation (see "Known defects in the reference apps", §5).

## Authority (read first)

- **This file is the one suite playbook, for Claude Code and Codex alike.** Home: NEON-Driver-Cascade
  `docs/neonize-playbook.md` on `master`
  (https://github.com/tgilbert14/NEON-Driver-Cascade/blob/master/docs/neonize-playbook.md). Every other
  app repo carries only a pointer stub at `docs/neonize-playbook.md` (format in §8) plus its own authority
  files. Anything longer in an app repo is a stale fork: report it, do not follow it.
- **Edit here, nowhere else.** Fold every new suite rule, pattern or gotcha into this file in one PR to this
  repo and bump the `playbook-version` line. Never copy suite rules into a stub, an AGENTS.md or a CLAUDE.md.
  App repos link this file unpinned, so an edit here never touches them.
- **What else owns what.** `docs/NEON-SUITE-LEARNING-LOOP.md` owns pass order, evidence status and Atlas
  decisions; `docs/NEON-SUITE-REVAMP-PLAN.md` owns the 2026 suite target, per-app briefs, the cover system and
  completion gates; each repo's `AGENTS.md` and complete `docs/BUILD-TEST-HANDOFF.md` own that app's commands
  and evidence; each app's `docs/SCIENCE-CONTRACT.md` owns its estimands. The fleet's NEONize role
  (TG-Data-Apps `.claude/agents/neonize.md`) owns the roster, the token and refresh-contract summaries, the
  maintainer loop and the handoffs, and points here for everything else.
- **This is a pattern catalog, not a release register.** Dated run IDs, hashes and pass narratives live in
  the learning loop, the specs they belong to and the app handoffs. A named app, workflow, runtime or metric
  below is not current evidence unless its app-local handoff and release receipt say so. Finding documents
  distinguish `OPEN`, `FIXED` and `VERIFIED`; never infer status from prose written before later commits.

It has three layers: **the quality bar** (§1, the dimensions every app must hit), **the reusable full
stack** (§2, what ports), and **the procedure** (§3, the evidence-producing research, design, build,
adversarial-verify and ship loop, run fresh per product). §4 to §7 are the gotchas, the feature inventory,
the deploy lifecycle and the readiness checklist; §8 and §9 are how the agents work together.

---

## 1. The quality bar (the six dimensions)

| Dimension | What it means |
|---|---|
| **Flow** | A site or entity picker, then a fast primary story, then progressively disclosed analysis. One global selected-entity state every view reads. No dead ends; every empty state offers the next action. Deep links and restored sessions must not skip honesty context. |
| **UI** | Shared suite structure with product-specific visual tokens: a local or system font stack, accessible cards, responsive task-oriented navigation, consistent methods, QC and download actions, and app-native organism and habitat color. bslib `page_sidebar`; an `info_pop()` on every card; mobile first. Dark mode is a product choice, but every chart honors the active mode. |
| **Statistics** | Defensible, cited methods (Hill numbers, Chao1 and Chao2, rarefaction, Schnabel and so on). Every headline number has an `insight_banner()` answer up front. n-gates before reporting. No pseudoreplication. The right effort and scale fixed before any comparison. |
| **Creativity** | One product-native signature idea in the art or interaction that makes the app memorable and useful. Delight (motion, play, illustration, a take-away card) when it fits the user job; no mascot, confetti, card or interaction pattern is mandatory. |
| **QC** | The app is useful to the people who collect the data. Click-to-inspect flags that open the exact records. Outlier flags are kept, not deleted, and phrased "verify, not wrong". A downloadable per-entity QC record. |
| **Honesty** | The non-negotiable. Every claim is stated where it lives (on the chart, screenshot-safe). Caveats for what the method cannot say. No false precision. "Not detected" is not "absent"; "review" is not "error"; correlation is not cause; raw richness is not an equal-effort ranking. Match rates published for joins. Deliberately omitted analyses stay omitted. Every series breaks or stratifies at each logged design, method or detection-limit change, the break is drawn on the chart, and no copy claims a normalization absorbs a design change unless a test on the overlap shows it. |

If a feature cannot be done honestly on the product's data, it does not ship; it gets a caveat or a "why
not" note instead.

### Owner-settled house rules (both tools)

- Default demo, startup and picker pre-selection site: **SRER** (then JORN, SJER, MOAB, ONAQ) unless this app documents a reason.
- Copy voice on covers, share cards and in-app copy: plain words a non-expert follows; say what NEON is; no em dashes; no sales pitch (price, access, ease); no hype adjectives; no sincerity labels ("honest", "real data"); never state what the reader can already see.
- No visible "illustration" badge on poster art; the art's status lives in alt text and the image provenance record.

These three bullets are copied verbatim into every app's pointer stub (§8). Enforcement: `post_deploy_smoke`
asserts the landing view loads SRER; TG-Data-Apps `node .claude/scripts/cringe-scan.mjs` runs over `docs/`
and the R UI strings before merge; the suite lint fails on an em dash in cover text, `<title>`, share cards
and UI string literals. A gate that requires an em dash is a bug.

### Other settled owner decisions (never reopen in a PR)

- **The review-branch refresh contract** (settled 2026-10-06): read-only producer and validator jobs, one
  restricted publisher that pushes the app's one fixed review branch, and a person's PR merge into the
  watched branch is the deploy. No workflow pushes a watched branch (the Atlas, the last direct pusher, moved
  to its review branch on 2026-10-22). Never migrate a review-branch workflow back to direct push, and never ask for branch
  protection to come off.
- **A `skip_download` run may publish** its derived-only rebuild to the review branch (2026-10-21).
- **`terra` is pinned at 1.8-50** wherever the leaflet chain is present (§6).
- **`neonUtilities` stays out of `manifest.json`**: deploys are bundle-only, and the fetch package is
  referenced by a computed name so the manifest scanner never pins it.
- **Every skill and flow works from Claude Code and from Codex.**

Open owner decisions are listed in TG-Data-Apps `docs/audits/neonize-doctrine-audit-2026-10-18.md` section 7.
Do not settle one inside a feature PR.

---

## 2. The reusable full stack (what ports)

A NEONized app is a **lean, independent sibling repo**: copy with attribution, never a shared package,
because independent deploys must stay self-contained. Copied code carries a header line
`from <repo>@<sha> <path>`, so the maintainer loop can diff each copy against its source and list fixes not
yet carried. Vendor a pinned version of each pattern, then adapt the data layer.

### 2a. Design system and chrome: vendor a pinned version, then adapt

- `global.R`: semantic tokens (`accent`, `signal`, `warning`, `ink`, `muted`, `surface`, `line`) mapped to an
  app-specific palette (the flagship's DDL list, navy `#0C234B`, navy2 `#16386e`, cardinal `#AB0520`, gold
  `#FFD200`, gold2 `#c9a300`, sky, green, ink, muted, bg, paper, line, is one such palette); `app_theme`
  (bslib bs5 plus a system or committed local font stack, §4a); `asset_url()` (mtime cache-bust); and the
  validated card, banner and loading helpers the product uses (`spin()`, `info_pop()`,
  `insight_banner(icon, ..., tone)`, `glow_badge()`).
- **Page identity:** `title = "<App name>"` and `lang = "en"` on the page function. bslib's `page_sidebar`
  and `page_fillable` take no `window_title` or `fillable` argument; passed anyway, they leak onto `<body>`
  and the tab, bookmarks and screen readers get a UUID. The suite lint checks it (rule L1).
- `ui.R`: `page_sidebar`; a local-only `<head>` library block (vendored, version-pinned sweetalert2,
  canvas-confetti, driver.js and **html-to-image@1.11.11** under `www/vendor/`, then `styles.css` and
  `app.js`; no CDN; feed html-to-image `data:` URLs, not blob URLs; show an error toast when the library is
  missing instead of failing silently); the splash national site picker as a STATIC `leafletOutput`, never
  inside a `renderUI` (the Connect Cloud re-bind race); the loading overlay; the DDL business footer.
- `server.R`: `plotly_theme(p)` (theme-aware hoverlabel, `displayModeBar = FALSE`), the `note_plot()` empty
  state, `ctx_anno()` (but see the annotation gotcha in §4b), the `is_dark()` reactive.
- `www/styles.css` `:root` tokens and dark-theme block; `www/app.js` (count-up engine, confetti, loading
  overlay, the custom-message handlers, each taking exactly one argument, §4b).
- `docs/index.html` and the in-app first-run surface follow Suite Living Poster V1 and the Cover Contract
  (§7). Keep the dominant poster artwork static by default; motion is optional feedback, never the carrier
  of the subject, method or promise.

### 2b. Data bundling: copy the pattern, swap the product

- `scripts/refresh_data.R`: per-site `loadByProduct(..., token = Sys.getenv("NEON_TOKEN"))`, trimmed to a
  `keep` column vector, xz-compressed to `data/sites/<SITE>.rds`. The token comes from the gitignored `.env`,
  declared as a credential in the committed `.env.example` (TG-Data-Apps `docs/envkit-practice.md`);
  `.Renviron` and `.neon_token` are gitignored and are not a layer. The token rule is §6 "The NEON API token";
  the fetch runtime is platform-specific (§4a).
- `read_bundle()` (defensive: NULL on a missing or corrupt file, never crash boot, and the NULL becomes a
  visible failure state), `load_site_bundle()`, `data/site_index.rds` (one row per site for the picker), and
  the manifest discipline in §6: Connect Cloud serves the published snapshot, so rebuilt bundles are not live
  until the manifest round-trips and a reviewed merge publishes them. Reference:
  NEON-Small-Mammal-Tracker-App `docs/data-bundling-pattern.md`.
- **A missing production bundle is a release error.** Never mask it with a live API fallback: that changes
  provenance, latency, schema and reproducibility.
- A committed `data-sample/` demo so the app runs bundle-only with no network (demo on startup).
- **Deterministic bundles.** Sort rows by the product key (`order(..., method = "radix")`) before every
  `saveRDS()`, strip run stamps from hashed content, and no-op on an unchanged content key, so a rebuild of
  the same release is byte-identical and a review branch with real new data stands out from churn. Treat API
  row order as transport noise: normalize by the immutable published row identity before hashing, and call
  the digest what it is (normalized extraction bytes under the pinned serializer). A derived index carries no
  `Sys.Date()` or other wall-clock value; derive its provenance from immutable input (for example the maximum
  observation date), then rebuild twice and require identical hashes.

### 2b-i. "Search the network": a bundled, precomputed search index

Every app with a national footprint gets a **Search** `nav_panel` (value `"search"`, after the cross-site
tab) that queries a SMALL precomputed `data/search_index.rds`, loaded once at boot like `site_index` and
filtered in memory, so it stays instant with no live fetch.

- **Builder** `scripts/build_search_index.R` READS the committed bundles, never NEON, and writes one row per
  searchable unit. For a biotic app that is one row per taxon x site: display name and flair, site name, state
  and domain, the app's **honest within-site measure**, totals and `year_min`/`year_max`. Compute the measure
  through the app's own cleaned-bundle machinery so it matches the rest of the app (Small Mammal: peak
  site-wide MNKA per species from `mnka_series()` on `clean_mam(bundle)`, after `species_level_only()`; 604 rows,
  145 species, 46 sites, 8.2 KB). The Atlas's searchable units are its per-site driver-to-response pair rows.
- Load once in `global.R` with `read_bundle("data/search_index.rds")`; build grouped selectize labels
  ("... · N sites") with a helper and serve them server-side.
- **Two query modes** on a small radio: (a) **Find a taxon** (or pairing): selectize autocomplete, then a
  sortable DT of every site where it occurs with the measure and years; (b) **a product-specific threshold
  query** (Small Mammal: species recorded at more than N sites; sites with more than X species).
- **Go-to-site reuses the exact map-click path:** the row's button raises
  `Shiny.setInputValue('searchGoSite', code, {priority: 'event'})`; the observer calls
  `nav_select("tabs", "overview")` and the app's one shared loader, so the sidebar syncs and the load is
  identical everywhere.
- **Honesty:** a result count ("12 of 46 sites"), an empty state, and one caption saying the measure is a
  within-site index (and that species counts reflect trapping effort), not an absolute population and not a
  fair cross-site ranking. The measure is a search key, never a leaderboard. Context-only rows stay searchable
  but out of any inference.
- **Manifest:** add the index to the app's deploy-file allowlist and rerun `scripts/write_manifest.R` (DT
  becomes a dependency). Wrap the `DTOutput` in a plain `div(style = "width:100%")` and do not `spin()` it
  (the 0-width trap, §4b).

### 2c. Shared analysis helpers: port the defensible ones

From `R/helpers.R`: `species_level_only()` (drop genus-only records and morphospecies before any richness),
`make_species_pal()` (one color per species across all charts), Hill numbers and `species_accum()`
(rarefaction plus Chao1 with CI), `mode_chr()`, the NA-safe `safe_*()` reducers, the n-gate idioms. The
diversity family ports to almost any taxon product. Read "Known defects" (§5) before copying any helper.

### 2d. The interactive, downloadable plot funnel: one proven signature pattern

The Size Lab (`www/pincards.js` plus the plotly `customdata` pattern in NEON-Small-Mammal-Tracker-App) is a
proven option when the product honestly has positionable entities. It is not a mandatory suite gesture.
Design the product-native signature first; use this "position, inspect, take it with you" funnel only when
its unit and user job fit:

1. **Position** every entity (individual, plot, species or taxon: the product's unit) on one chart, colored
   by a meaningful class, with a filter and an honest, gated overlay (a fit line drawn only where the
   relationship is real, framed as what it is, for example "a QC map, not a body-condition index").
2. **Click to pin a profile card** (draggable and resizable, a leader line anchored to DATA coordinates).
3. **A chip on the card opens the per-entity profile and QC record** (`output$...Card` plus an
   `individual_qc_flags()` analog: ranked "verify, not wrong" flags), scrolled into view on open (§4b).
4. **Download the works:** the chart with pins baked in (html-to-image PNG), the profile or QC card (PNG),
   and the raw per-entity record as analysis-ready CSV (`downloadHandler`).

Keep the funnel in the app's existing plotly stack rather than adding a second renderer; click-for-profile,
QC, downloadable plot and card, and metadata then travel together. When the product lacks honest entity
coordinates or profiles, ship a different signature and keep the same inspectability and export standard.

### 2e. Report PDF: `R/report_pdf.R`

Base `grid`/`grDevices` `cairo_pdf` (no LaTeX, no Chrome), streamed by a `downloadHandler`. Re-theme the
page geometry from the app's tokens and swap the per-product content renderers.

### 2f. What does NOT port (product-specific; design fresh every time)

The **entire data model and its unit of analysis.** For small mammals the unit is the tagged individual and
its mark-recapture career, so the dossier, the Hall of Fame, MNKA detection, age and lifespan, tag-identity
QC, home range and body-measurement outliers port to nothing without individuals. Before building, answer:
**what is this product's unit, and what is its capture-career analog?** For count and cover products there
are no individuals; the unit is the plot, the species or the trap x bout. The app's current
`docs/DATA-TAKEAWAYS.md`, expert review and knowledge package are the reference (for a count product, see
the Ground Beetle app's `docs/SCIENCE-CONTRACT.md`); chat history and named memories are not.

### 2g. The site-picker map contract (popup, sidebar sync, one loader, basemap)

The splash national picker behaves identically across apps; the June 2026 audit found five of seven apps
broke a contract, and the 2026-10-18 audit found the popup options breaking five more.

- **A. Explore/About popup.** Each `addCircleMarkers` dot carries a native leaflet popup built by
  `site_popup_html(row)` and bound with the `popup =` argument (not a server round trip, so it survives a map
  hide and re-show): an **"Explore this site"** button (`onclick` raises the loading overlay client-side, then
  `Shiny.setInputValue('siteExplore', code, {priority: 'event'})`) and an **"About this site"** button
  (`Shiny.setInputValue('siteInfo', code, {priority: 'event'})`, an instant modal, no load). Options
  `maxWidth = 300, minWidth = 230, autoPan = TRUE, keepInView = FALSE, closeOnClick = FALSE`; call
  `closePopup()` before the splash hides, and guard every resize-to-`invalidateSize()` with
  `if (el.clientWidth > 0)`. `keepInView = TRUE` on a hidden map loops Leaflet's auto-pan into a RangeError
  and brings the map back blank at latitude minus 85 (suite lint rule L2).
- **B. Sidebar sync on select (the most common cross-app break).** Picking a site on the map MUST update
  the sidebar dropdowns to what is loaded. The bug: the `observeEvent(input$stateSel)` cascade sets
  `choices` only, never `selected`, and snaps to `sites[[1]]`, so the data loads while the sidebar shows the
  old site. The fix is a **`pendingSite` bridge**: `rv$pendingSite <- NULL` in reactiveValues; the Explore
  handler sets `rv$pendingSite <- code`, then `updateSelectInput(session, "stateSel", selected = state)`; the
  state-cascade observer honors it:
  `sel <- if (!is.null(rv$pendingSite) && rv$pendingSite %in% sites) rv$pendingSite else sites[[1]];`
  `rv$pendingSite <- NULL; updateSelectInput(session, "site", choices = sites, selected = sel)`.
  A single-selectize app is synced only if the click calls `updateSelectizeInput(selected = )`; verify the
  click's behavior, never a code-read.
- **C. One shared `load_site()`** for the sidebar Load button, the map Explore, the browse list and the
  search jump, so behavior is identical everywhere. A server-backed Selectize picker also needs the reset
  contract in §4b.
- **D. Basemap.** Every map draws CARTO Positron or DarkMatter through the suite helper
  `add_suite_basemap()`: a raw `addTiles()` URL carrying `?key=` from `Sys.getenv("CARTO_BASEMAP_KEY")`, both
  credits visible (never `attributionControl = FALSE`), and a keyless Esri canvas fallback when the key is
  unset. The key is a public, rate-limited identifier set in each Connect app's Variables, not a credential.
  Never add an unkeyed `basemaps.cartocdn.com` layer or `addProviderTiles(providers$CartoDB.*)`: CARTO has
  watermarked unauthenticated tiles since 2026-08-26. Tiles are optional decoration, kept apart from core
  data and analysis: with tiles blocked the app still works and every number is right. Record:
  `docs/SUITE-BASEMAP-INCIDENT-2026-08.md` in this repo.
- **E. A non-map fallback.** The sidebar state and site selectors (or a browse list) reach every site
  without the map, by keyboard alone.

PASS TEST: (1) pick a NEW site on the map: the overlay appears, the data loads, and the sidebar state and
site dropdowns read that exact site; (2) open a popup, switch tabs and come back: the map centre is inside
the US, tiles are drawn and the console has no RangeError; (3) Explore from a popup, then Change site: the
same; (4) load `?site=SRER` cold and press Explore on that site: it loads. Reference port: Ground Beetle's
`mapPickerServer()` (`R/map_picker.R`) and `site_popup_html()` (`server.R`), after its keepInView and
deep-link restore fixes land (2026-10-18 audit items 17 and 18). Until then copy the contract, not the file.

---

## 3. The NEONize procedure (run fresh per product)

A repeatable, evidence-producing loop. Durable artifacts and independent verification are required;
parallel review is optional. Each phase is dispatched by the driving session: NEONize names the specialists
and the questions, and in Claude Code it holds no Task tool. Follow the one-app cycle and decision vocabulary
in `docs/NEON-SUITE-LEARNING-LOOP.md`.

**Phase 0: freeze the app and its release.** Read the app-local instructions and the complete handoff;
record source and deployed commits, bundle and manifest hashes, public health, worktree ownership and the
current tests. If the public app is down or the manifest is incoherent, recover release trust before any
redesign ships.

**Phase 1: research the product (gated, required every time).** Produce evidence for five lenses:

- schema and method: exact DPID, tables, joins, units, fields, design, protocol eras and data volume; read
  `issueLog_<DPID>`, the product changeLog, the release notes and any duplication warnings before trusting
  any field;
- domain: cited product-native meaning, mechanisms, caveats and forbidden claims, from the product's rung
  specialist (DP1.10072 mara · DP1.10058 flora · DP1.10003 wren · DP1.10055 iris · DP1.10098 cedar ·
  DP1.10022 cara · DP1.20093 brooke · cross-product cass); fauna or aquatics only where no rung specialist
  exists (Mosquito, Inverts); jornada never grounds a NEON product;
- statistics: the estimand, sampling unit, effort and opportunity, zeros, missingness and censoring,
  uncertainty, pseudoreplication, support gates and export grain;
- architecture: the reuse, adapt, skip and net-new map, plus startup, bundle, manifest and deployment
  dependencies, read from the repository's current data, code, UI, manifest, deployment and public behavior;
- product: the primary user jobs, the signature interaction, accessibility, visual identity, companion
  overlap and candidate Atlas fields, and one grounded improvement worth its complexity.

Use official product and authority sources, and record a source, version, query and license receipt for
every build-time enrichment. A fuzzy or undocumented match can create a review lead; it never silently
changes, demotes or drops an observation.

**Phase 2: design.** Lock the unit of analysis; a CAN / CANNOT / HELD claim list; task-oriented information
architecture; the primary interaction; the data and bundling plan (which demo site, the `keep` vector); the
codebook and QC contract; and the expected Atlas disposition. Register any hypothesis before viewing
held-out results. Confirm a genuine fork with the owner; otherwise proceed.

**Phase 3: build.** Vendor only pinned, relevant patterns from §2. Build the product-specific transform,
helpers, renders, navigation, interaction, styles, tests, codebook, cover, social card, handoff and knowledge
package. Keep boot bundle-only and network-independent. Author the tightly coupled core in one place;
parallelize only genuinely independent pieces.

**Phase 4: adversarially verify.** Review the **git diff** independently for R correctness, science and
statistics, frontend lifecycle and accessibility, field and QC use, deployment and security, and data and
manifest integrity. A rung specialist's sign-off counts only with one data probe per headline metric it
signs: recompute the metric from the committed bundle for SRER plus two contrasting sites, report the
numbers and the base rate of every QC flag, and cite the run (host, R version, date). Triage by severity,
fix supported blockers and high findings, and rerun the complete ordered gate set.

**Phase 5: verify in the running app.** Start in the pinned runtime and exercise the three primary user
funnels with real inputs: empty and error states, deep links, keyboard paths, downloads, dark and light where
applicable, reduced motion, desktop, tablet, and 375 to 390 px mobile. Drive interactions for real: raise the
demo with `Shiny.setInputValue('demoBtn', ..., {priority: 'event'})`, and drive plotly with
`gd.emit('plotly_click', ...)` carrying a full point object including `data: {}`, never a synthetic
`.click()`. Require zero unexplained server, console and network errors and stable geometry, not
screenshot-only proof.

**Phase 6: publish and close.** Update the app-local handoff, the central suite evidence register and the
Atlas implication backlog with exact evidence; add a BUILD-TEST-HANDOFF entry and a LESSONS line; promote
reusable gotchas into this playbook. Then regenerate and verify the manifest, publish only when authorized
and green, and bind the green head, merge commit, deployed identity, manifest hash, landing and social assets
and a content-aware public check in one release receipt.

**Atlas synthesis rule: two decisions and three evidence levels stay separate.** An app may earn `ADOPT`
for a sampling, zero/missing, estimator-support, provenance or publication contract while its ecological
signal remains `CONTEXT`, `HOLD` or `REJECT`; record both axes. Distinguish an app-supported site-year from
an exact Atlas-calendar match and from an eligible Atlas adapter or model row: calendar overlap is
compatibility evidence, not signal authority. For aquatic companions a shared NEON domain-year is only a
labeled coverage proxy; it never repairs a missing site key or authorizes a vote. Keep `UNMEASURED` when the
opportunity ledger, candidate bundle, intersection, adapter or registered model does not exist.

**Stage feasibility acquisition before payload access.** When the question is only whether a new product
can support a future join, freeze the claim and key first, then pass three gates in order. F0: a reviewed
specification, a pure reducer, synthetic fixtures and, where a response roster exists, a committed
values-free authority ledger with a byte and metadata verifier; a frozen F0 branch is a candidate, not a
passed gate, until a receipt binds the reviewed merge and its Pages publication. F1: a pinned availability or
file manifest and only the reviewed non-observation schema metadata, no ecological records. F2: only the
registered payload columns, after the F1 schema is independently reviewed. Name weak support literally
(for example `qc_pass_record_present_in_utc_year`, never "annual coverage"); register exact chronology with a
named failure; publish total opportunity, QC, clock and exclusion diagnostics without response or driver
magnitudes; strip signed URL queries and credentials from every receipt; and treat alternative clocks or
source regimes as non-rescuing sensitivities. Clearing a feasibility floor reopens review; it authorizes no
app, metric, effect, prior, vote or Atlas rebuild. Worked example: `docs/DISCHARGE-FEASIBILITY-SPEC.md`.

---

## 4. The gotcha catalog (carry into every NEONize)

### 4a. Runtime, fonts and layout

- **The fetch runtime is platform-specific.** On the Windows refresh host, R 4.5.2 crashed inside
  `neonUtilities::loadByProduct()` (access violation), so that workflow pulls with R 4.1.1 launched from
  PowerShell, not git-bash; Vegetation's pinned Linux R 4.5.2 fetch passed. Before choosing an R version for
  a pull, run a one-site tokened `loadByProduct()` with the installed R and record host, R and neonUtilities
  versions. Reference neonUtilities by a computed package name so the manifest scanner does not pin it.
- **Fonts and boot assets are network-independent.** `bslib::font_google()` defaults to `local = TRUE`,
  which downloads and compiles the font at app startup on the server; Connect Cloud idles workers after about
  six minutes and wipes the cache on recycle, so a slow Google Fonts response turns a cold start into a black
  screen that a republish only re-primes (it hit five apps at once). Name families as plain CSS with
  `bslib::font_collection("Rubik", "system-ui", ..., "sans-serif")`. A client-side font stylesheet is still
  an external rendering dependency: use a system stack, or commit licensed font files and verify their
  checksums. Audit startup and first render with the network blocked.
- **A 320 px viewport may have only 305 px of usable width.** Desktop test browsers can reserve 15 px for
  the scrollbar, so `body { min-width: 320px }` and edge-to-edge `100vw` carousels create page-level drift.
  Use parent-relative sizing, allow the body below 320 px, and require
  `documentElement.scrollWidth === documentElement.clientWidth` at 390 and 320 CSS px; inspect
  framework-generated gutters, brand and action rows, and top-bar wrapping too.
- **Test framework markup at both sides of every responsive seam.** Shiny `actionButton()` puts its label
  in a text node inside `.action-label`, so a sibling selector cannot hide it: keep the DOM name, zero only
  the inherited font size, restore the icon size, and prove a 44 x 44 target. Plant Diversity's prevention
  matrix is 390/375/361/360/320 px because its status, help and theme grid starts at 360.

### 4b. Shiny, plotly, leaflet and DT lifecycle

- **A plotly re-render kills event handlers.** `Plotly.purge` plus `newPlot` on the same div wipes
  `gd.on()` listeners. Never gate binding on a persistent expando; re-attach `plotly_click` on every render
  (an rAF-debounced MutationObserver scan). This was the Size Lab blocker.
- **Gate server-side plotly reads on the raw registered event.** In plotly R 4.12, `renderPlotly()`
  registers its Shiny event IDs only after preparing the widget, so a reactive `event_data()` can query a
  source before registration. Keep `event_register("plotly_click")` on the widget, trigger the observer from
  the raw `plotly_click-<source>` value in `session$rootScope()$input`, and only then call
  `event_data(..., priority = "event")`. Verify fresh-load and post-reset server logs, not only the console.
- **Pin anchors are DATA coordinates**, recomputed with `gd._fullLayout.xaxis.l2p() + _offset` on
  `plotly_relayout` and a `ResizeObserver`; anchor from the data point, not the click event (touch has no
  `clientX`).
- **`ctx_anno()` and `add_annotations()` accumulate** across re-renders; fold the caption into the
  `layout(annotations = ...)` list so it is replaced wholesale.
- **A named-vector `updateSelectInput()`** spams warnings: wrap choices as `as.list(setNames(...))`, and
  build filter choices from the plotted subset so a choice cannot land on an empty chart.
- **selectize fires `change` through jQuery `.trigger()`**; a native `addEventListener('change')` never sees
  it. Listen on `shiny:inputchanged` or the widget's own event.
- **Server-backed Selectize choices need a reset contract.** Clearing loaded state does not restore remote
  choices. Put initial population in one helper, call it at session start and on every return to the picker,
  and browser-test load site, change site, search a different site, through one exact returned choice.
- **`validate(need())` does not display in some widget outputs** (the stale output persists); return a real
  message chart or empty state.
- **`asset_url()` bakes the cache-bust version at app start**; restart a running preview to pick up edited
  `www/` files.
- **html-to-image over WebGL fails.** Force SVG (`scatter`, not `scattergl` or `toWebGL`) for any chart you
  export; call `Plotly.Plots.resize(gd)` before `toPng` (a hidden tab can be 0-sized); strip live animation
  classes before capture.
- **Register pin-binding listeners BEFORE any auxiliary handler in the IIFE.** A statement near the top of
  `pincards.js` that throws during head-eval aborts the IIFE, and tap-to-pin dies with no captured console
  error. Binding listeners first; auxiliary handlers last and `try`-guarded.
- **Every `Shiny.addCustomMessageHandler` takes exactly one payload argument**, even when unused. A
  zero-argument handler fails Shiny 1.14 registration and the app's JavaScript dies; parse-only checks miss
  it. Inventory every registration in every tracked `.R`, `.js` and `.html` file (the suite handler lint; each
  app's `scripts/check_custom_message_handlers.mjs` until the engine split lands).
- **The `dataSig` pin-clear must ignore the highlight trace.** Selecting an entity appends a highlight trace;
  a trace-count signature then wipes every pin the moment a profile opens from a pin.
- **Scroll into view targets the rendered card node, not the `uiOutput` wrapper.** A bslib `uiOutput` in a
  fill layout is `display: contents` and has no box; poll for the rendered child with `height > 1`.
- **A leaflet map initialized in a hidden tab paints blank on first open.** Two causes, both fixed: dispatch
  a window `resize` on `shown.bs.tab` (`invalidateSize` is a JS map method, not an R function), and make the
  draw a named function called from an eager `observe()` and from a server observer keyed on a `tabShown`
  input that JS sets after the resize tick.
- **A map in a `display: none` block shown by a mode toggle (not a tab) is blank on the FIRST reveal.**
  Under `suspendWhenHidden = TRUE` the widget never binds, and a proxy draw before binding is dropped
  (`Couldn't find map with id`). Fix: `outputOptions(output, "<map_id>", suspendWhenHidden = FALSE)` so it
  binds at init, then on reveal `HTMLWidgets.findAll(".leaflet").forEach(w => w.getMap() &&
  w.getMap().invalidateSize())` after a short delay and re-fire the draw. Guard it with a source grep and a
  headless check that the first reveal has a non-zero box, a canvas taller than 50 px and zero map-id
  errors. This is the opposite of the DT rule below.
- **A `DTOutput` in a full-width card inside a bslib fill container collapses to width 0** and never draws
  (only `&nbsp;`, no error). Drop `spin()` and wrap it in a plain `div` with `width: 100%`. DTs in
  `layout_columns` are fine. Do NOT use `suspendWhenHidden = FALSE` here: the DT would compute at 0 px while
  hidden and not redraw.
- **One fixed output id, not one per entity.** A `render*` registered under a per-row id leaks a binding for
  every entity opened; use one output that reads the selected-entity reactive.
- **A single-species or single-site view still needs a page filter: filter by cohort stratum.** Drive it off
  the roster that carries the strata (sub-area, sex, size or age class), default "All", and wrap each chart in
  a lazy small-n gate (`substitute()` plus `eval.parent()`) so a suppressed stratum never runs the plot body;
  an unknown filter value falls back to the full cohort.
- **Re-theme by token remap plus a CI grep guard.** Keep the CSS variable names and remap their values in
  `:root` and the dark block, fix the few hard-coded literals (gradients, status tints, plotly marker colors,
  the PDF palette, JS dialog colors), then assert in CI that the old hexes are gone and the new tokens present.

### 4c. Data, estimands and release identity

- **A field is not a metric until its denominator, grain, panel, missingness and authority are known.**
  Composition, timing, standing stock, abundance, chemistry and productivity are distinct signals with
  distinct app owners.
- **Never pool repeated visits as independent samples; declare the estimand first.** NEON re-surveys the
  same plots every year; pooling years into richness, rarefaction or Chao treats one quadrat's seven visits as
  seven spatial samples (roughly doubling richness). For a spatial snapshot, compute on **one complete survey
  per unit**: when scales are sampled on different cadences, the snapshot is the newest event that holds every
  scale the metric uses (Plant Diversity since 2019: the 10 and 100 m² subplots are biennial, so a per-plot
  latest year can hold 1 m² rows only). Reserve the multi-year table for the explicit time series. A protocol
  may instead define each physical visit as a repeated **sample-incidence occasion** (Breeding Birds'
  six-minute counts); the app then keeps zero-sample support, uses a fixed analysis window, labels the visits
  as repeated protocol samples, and claims no spatial independence, occupancy or detection correction.
  Rarefaction standardizes sample count only; it does not equalize coverage, detectability, space, timing or
  design.
- **Area-scaled metrics are scoped to the population actually sampled over that area.** NEON nested-samples
  small stems over a smaller area than the headline area variable; scope to the protocol threshold (trees
  >= 10 cm DBH over `totalSampledAreaTrees`) and label it. Quadratic statistics (QMD) are pooled
  (`sqrt(sum(D^2) / sum(n))`), never a mean of per-unit values.
- **Shares need a structural-zero denominator** (all sampled units, not only where present), and a headline
  metric uses **one shared function** in the bundler and the app. Enforce it: `verify_bundle` recomputes each
  index column (search index, site index, expected-vs-observed) from the app's own function for SRER and two
  other sites and fails on any difference, and asserts invariants (Chao2 >= S_obs, N-hat >= MNKA,
  0 <= share <= 1, per-site badges computed from that site's rows).
- **dplyr `summarise()` sees columns it created earlier in the same call.** `richness = mean(richness)` then
  `sd = sd(richness)` takes the sd of the scalar mean (NA), and a modal reassignment makes a later count read
  one value. Compute the spread before the reassignment. Gate: the suite lint (rule L13) flags a `summarise()`
  that assigns a column it later reads, and `verify_bundle` asserts every `*_n_years` and `n_*` count column
  exceeds 1 at some multi-year site.
- **Decode every coded field by exact token from NEON's variables file and user guide, never by
  substring.** One explicit map per field (samplingImpractical: NA and "OK" mean sampled; the documented
  impractical codes mean not sampled; any other value stops the producer with `::error::`). Lower-case and
  trim, then `%in%`; no `grepl()` on categories ("nonenlarged" contains "enlarged"). NA is its own branch:
  `nzchar(NA)` is TRUE; a missing count is unavailable, not zero; a derived column that is NA is re-derived
  from its source. Fixtures carry one row per REAL code copied from a NEON download, including the newest
  code, never an invented value.
- **Register opportunity before the metric.** Occurrence rows cannot invent sampled-empty quadrats; select
  one deterministic bout per plot-year; annual comparisons need recurrent panels; cross-site richness needs
  a common grain. Chao2 is an incidence lower bound, not a generic effort or coverage correction.
- **Build the event ledger before derived structure.** Preserve every source row and event identity before
  choosing a snapshot, tallying stems or scaling by area. A measurement without a matching published
  opportunity row is not a sampled absence: keep it under a dedicated held state and invent no date, effort,
  area or denominator.
- **An aquatic opportunity ledger needs an explicit status partition, not synthetic zeros.** Prefer source
  `uid` and `sampleID` relations; keep field opportunities even when processing or taxonomy is absent; keep
  unstratifiable, nonstandard, processing-unknown, count-unavailable and quantified states mutually exclusive
  and exhaustive. Report density only where area is supported and only as a within-site index; frame EPT as
  composition, never impairment, health or a causal score.
- **Release-safe bytes do not prove an opportunity-safe estimator.** An immutable producer, an independent
  manifest validator, a green Pages deploy and a booting app can all preserve a catch-conditioned transform.
  Build the opportunity ledger from field sampling rows before joining outcomes; taxonomy rows enrich
  opportunities, they never create them (My Little Inverts Pass 9).
- **Source identity and mapping identity are separate invariants.** Preserve the source `uid` and the exact
  mapping or tagging row behind each observation; blank or duplicate UIDs fail; tied mapping candidates fail
  closed.
- **Equal units do not make physical channels interchangeable.** Tree DBH (bole cross-section at breast
  height) and shrub or sapling basal area (stem base) are both m²/ha and still different measurements:
  register channel IDs and channel-specific support, keep separate search and presentation paths, and never
  pool or rank across them.
- **Unknown classifications and narrow references stay visible.** Resolve contradictory nativity to
  Unknown and review; never turn one reference coordinate into plot- or site-wide truth. Short per-site annual
  screens stay descriptive, even after multiple-test handling, and never become Atlas edges.
- **A headline dominated by one record says so.** When the largest single record (an expanded lot, one
  plot, one year) contributes more than 25% of a headline, the number carries a dominance note.
- **Independently reconstruct every derived release family.** The verifier derives support states,
  snapshots, summaries, indexes and exports from preserved rows, never by calling the builder's helpers, and
  carries at least one independent oracle per headline metric (§6). Synthetic positive and corruption
  fixtures prove it can both reproduce and reject.
- **A content hash proves exact bytes, not upstream vintage.** Import dates, mtimes, manifest hashes and
  derived checksums cannot fill an unknown `builtAt`, `neonRelease`, `sourceCutoff`, query receipt or
  raw-source digest; keep explicit `NA` until a complete reviewed source receipt exists.
- **Science, data and runtime authority are separate from governance and production identity.** A later
  governance release can change the production identity (identity-bound docs or Pages bytes changed) while
  the runtime-payload hash stays exact. Record both authorities and the unchanged runtime hash; never move
  the Atlas science pin to the newer publication commit (worked example: My Little Inverts in the learning
  loop).
- **When an app binds its docs into its release identity, the mutable exception is exact.** My Little
  Inverts binds every root `docs/*.md` except the literal `docs/BUILD-TEST-HANDOFF.md`: any other root doc
  change regenerates identity, passes the clean validator and becomes a newly reviewed candidate. Its
  playbook stub is written once and left stable for that reason.
- **A semantic marker proves the app family, not the deployed revision.** Derive a runtime receipt from
  the sorted checksums of the runtime allowlist, emit it with the ready marker, and make the post-deploy
  smoke recompute and require that exact value (Water Chemistry showed a constant marker and HTTP 200
  alongside a stale Connect publication).
- **Release recovery and data refresh are separate authority changes.** Restore a failed deployment
  against one reviewed package graph and prove a clean cold start, exact runtime identity and semantic
  health before dispatching a held refresh; the refreshed candidate still needs its own validation, human
  delta review and promotion receipt.
- **Candidate promotion is an identity proof, not a copy step.** Bind the candidate artifact to one exact
  reviewed PR head and run; require the promotion commit's parent to equal that head, its changed paths to
  equal the artifact ledger and every committed blob to match the artifact checksum.
- **An approved cover concept is not a shipped asset.** Keep the selected concept, production source or
  prompt, derivative hashes, dimensions and byte budgets, social composition, provenance and validators
  together; a concept board is not production evidence.
- **Pages and Connect are one invitation on two surfaces.** Validate cache-busted desktop, 390 and 320
  layouts at the real framework seams, exact copy and action counts, versioned assets, keyboard focus,
  reduced and forced colors, CTA-to-picker focus, the console and worker logs. Remove retired runtime media
  once its provenance is recoverable.
- **Adversarially verify the diff with an independent pass, every time.** It has caught a real regression
  in nearly every session (the plant app's year pooling, the Size Lab's dead-after-re-render scatter). A
  second reviewer, a deliberately separate pass, or the other vendor's agent all count; a named persona is
  not evidence. Record findings and dispositions in the handoff.

---

## 5. The flagship feature inventory (steal the best, per product)

From the **Small Mammal Tracker**: the splash national picker (by site or by species), demo on startup, the
hero stat band (clickable, with a ranked-breakdown modal), the species-first Overview with an auto-written
narrative (`site_insights()`: compute, rank, glue), the Population tab (MNKA and CPUE, detection-corrected
abundance, species accumulation with Chao1, environment-driver overlays with the driver-semantic color
system), the Community Pulse (sex and age, Hill profile, per-plot trends, body size, lifespan, phenology),
the **Hall of Fame** leaderboard, the **Dossier** trading card, the **Size Lab**, the click-to-inspect QC
modals, the report-card PDF and the two-site compare.

From the **Power-4 Girth Index** (see `docs/girth-index-patterns.md` in the Small Mammal, Plant Diversity,
Breeding Birds, Phenology and Vegetation repos): highlight one in a grey cloud, a named-quadrant scatter,
violin plus jitter plus mean "position DNA", a before/after arrow chart, a percentile-band trend, the trading
card, a reusable hover-card builder, a narrative-insight generator, a config-driven entity picker.

For each product, map these to its unit, keep the ones that stay honest, and invent the product-native ones
the research surfaces.

### The Expected-vs-Observed QC module (the EcoPlot recipe)

For any NEON organismal product whose `taxonID` is a registry symbol with an external "what should be
here" authority. First built for Plant Diversity (DP1.10058.001): resolve each site's coordinates to its
NRCS Ecological Site reference plant community (offline, through Soil Data Access), then compare it with what
NEON observed.

- **A build-time location-to-reference join frozen to `.rds`.** `scripts/build_expected_lists.R` (raw SDA
  REST, no soilDB) writes `data/expected/<SITE>.rds`, and `build_plant_authority.R` freezes the USDA PLANTS
  nativity and synonym authority to `data/authority/plants_lookup.rds`; the deployed app makes zero federal
  API calls. Both sources are public domain.
- **Three buckets, completeness never red:** A confirmed (green); C observed but not expected (the review
  lane, split introduced versus native-not-in-reference); B expected but absent (completeness, neutral).
  NEON samples a tiny area, so "expected but absent" is non-detection or a real state transition, never
  missing data or error, and the reference list is never truth the data must match.
- **Gate on land use:** when NLCD or NEON site metadata says cultivated or managed, completeness is NA with
  status "reference community not applicable (cropland)", not a percentage (STER and KONA were scored against
  a rangeland reference).
- **An exact symbol join, not fuzzy.** NEON taxonomy is USDA PLANTS, so `taxonID` equals the SDA
  `plantsym`. Collapse synonyms to the accepted symbol first and drop SDA aggregate codes. Run on
  `species_level_only()` of the full-grain snapshot (§4c), never the year-pooled table.
- **Surface the coarse-ID rate first**: the share resolved only to genus, family or kingdom frames every
  other flag.
- **Publish the match rate and a provenance row** that tells a fetch failure from a genuine empty.
- **Three clickable, downloadable bucket tables and a combined report CSV**, an info dot on every card, plain
  framing on the page, and an EDIT citation link (worked example: SRER, `R041XC318AZ`).

### The suite bars (first assembled from Mosquito Pulse)

These are requirements, not a source to copy. Per-bar reference implementations: bar 2 (effort) is Small
Mammal's exact `trapStatus` decoding and Ground Beetle's zero-catch plot-bouts; bar 4 (QC) is Breeding
Birds' `bird_qc()`; bars 3 and 6 to 10 are Mosquito's shell and helpers. Do not copy Mosquito's `R/` data
layer until its 2026-10-18 audit items 1 and 19 are closed (see "Known defects" below).

1. **Persistent honesty banners**: a synthetic or preview-data banner (red on no data, yellow on any
   synthetic) and a persistent hero caveat ("a within-site activity index, not a population").
2. **An effort denominator and a median**: a seasonal or annual index divides by attempted effort, including
   zero-catch nights and intervals, and uses a skew-robust median across years.
3. **Richness with uncertainty**: Chao2 with CI and sample coverage, incidence rarefaction, a "minimum
   estimate" caveat, and no false precision at low coverage.
4. **Three-tier QC and a clickable inspector**: high, warn and info "verify, not wrong" flags, each opening
   the exact offending rows.
5. **A downloadable codebook and a provenance-complete CSV**: exports carry the columns needed to re-derive
   counts and replay the QC filtering.
6. **Locked data palettes**: category colors are literal R vectors, never CSS tokens, and stay
   theme-independent (with a reserved hue for a disease-vector flag).
7. **Reduced motion and accessibility**: `prefers-reduced-motion` honored on all animation; pin cards and QC
   flags keyboard-operable; decorative SVG `aria-hidden`.
8. **Tab-resize dispatch**: `shown.bs.tab` fires a window `resize` so maps and charts in hidden tabs render
   at size.
9. **Scope chips**: persistent site versus all-N badges so every view's scope is labeled.
10. **Cross-site inference**: Spearman rho with CI and a space-for-time confounding caveat on every
    cross-site gradient.

### The seasonal-driver card (`R/seasonal_env.R` plus `output$seasonalDriver`)

Every app with an environment panel ships the Atlas's seasonal-aggregate driver read as a small `.ec` card
right under the monthly driver ranking. The monthly scan deseasonalizes monthly catch against the monthly
driver, so it averages the monsoon out of the very cycle it subtracts; the seasonal card aggregates each
driver by season (monsoon July to September, winter October to March, spring temperature March to May) into
one value per year and correlates at the prior's stated lag.

- Port `R/seasonal_env.R` from Small Mammal (`seasonal_aggregates`, `seasonal_driver_links`,
  `seasonal_biome`, the permutation and circular-shift nulls, `SEASON_LABELS`), keep
  `.WATER_LIMITED = c("JORN", "MOAB", "ONAQ", "SRER", "YELL")`, and source it in `global.R` after
  `helpers.R`. Until that file carries the n-gate below (2026-10-18 audit, Small Mammal P2), port it with the
  gate applied.
- Build the app's ANNUAL response, `data.frame(year = <int>, value = <num>)`, from the app's own annual
  metric so the card never disagrees with the rest of the app (Small Mammal: captures per 100 trap-nights per
  year; Ground Beetle: `annual_trend(d)$cpn`).
- **The per-product lag is the load-bearing choice.** A slow seed-eater boom (mammals) uses
  `precip_monsoon = 1L`; a fast within-season responder (beetles, mosquitoes) uses lag 0 on every driver. Set
  it from the organism's response time, never by copy.
- The card leads with the biome's lead driver (temperate: `temp_spring`; water-limited: monsoon or winter).
  If a water-limited site has no testable precipitation season (n < 3 after the merge), it falls back to the
  full link list; that means precipitation was not testable there, not that the prior flipped.
- **n-gate: below 6 paired years show r and n as "too few years to call", with no strength word, no lead
  driver and no "recovers the driver" line; p and `p_adj` only at n >= 6; the verdict sentence only when
  `p_adj < 0.10`.** Never deseasonalize the annual aggregate; always carry the small-n caveat and the link to
  the Atlas.

### Known defects in the reference apps (read before copying any helper)

Recorded from the 2026-10-18 suite audit; the app sessions were fixing these on 2026-10-22. NEONize prunes
a row when its fix merges; until then copy the contract text, not the code.

| App | Do not copy until fixed |
|---|---|
| Small Mammal | `flag_repro()` substring matching (about 100% of adult females read as reproductive; P0); untagged-capture placeholder IDs counted as marked animals and deaths kept in M_t in the closed-capture estimator (P1); the leaderboard's `first_stage` reads the modal stage, never the stage at first capture; the QC card crash on an unknown life stage; no `.qc-flag-<level>` classes and no per-flag CSV; `keepInView = TRUE` in `server.R`; `seasonal_env.R` states verdicts at 3 to 5 years |
| Mosquito Pulse | `mos_sampling_occurred()` reads samplingImpractical "OK" as not sampled (44% of effort; P0) and the uncertain-ID flag fires on every row (`nzchar(NA)`), both fixed on the open review-branch PR; contract B and the About button missing; "Save species card" dead (html-to-image never vendored); the Taxon Profile year chart is a raw sum under a per-24-trap-hours caption; the peak-week headline rests on one year; the SRER hero is 39% one expanded lot with no note |
| Ground Beetle | `keepInView = TRUE` in `R/map_picker.R` and `server.R`; the `?site=` restore pre-selects but never loads; trinomials count as separate species; the same `seasonal_env.R` n-gate gap |
| Plant Diversity | the per-plot `latest_snapshot()` picks 1 m²-only years since 2019, so 400 m² richness is computed from 1 m² quadrats (SRER 17.9 against 42.6; P0); `keepInView = TRUE` in `R/map_picker.R` |
| Phenology | every `*_n_years` column is 0 or 1 (the summarise reassignment); `leaf_active` tracks visit effort; "Young leaves" missing from green-up |
| Vegetation | `is_species` reads a reassigned `scientificName` in `scripts/bundle_veg_data.R`; no size-plausibility screen; `keepInView = TRUE` in `R/map_picker.R` |
| Water Chemistry | a zero-argument custom-message handler (`kickMaps`) kills the app's JavaScript; the Fe/Mn 2012 to 2016 unit error passes a plausibility gate whose ceiling the bad rows set |
| Breeding Birds | a blank `clusterSize` read as zero (it is one bird left unrecorded at source) |
| Atlas | a layer test in `scripts/build_cascade.R` that is always TRUE, and no coverage-regression gate before staging: both fixed in open PR #80, so prune this row when it merges (the direct push to `master` already ended on 2026-10-22) |

---

## 6. Deployment and maintenance: the full lifecycle

The suite standard is **Posit Connect Cloud with a git-backed source**. The repository, the Connect
deployment and public semantic health are separate release identities. There are no shinyapps.io secrets,
no `rsconnect/` directory and no `deploy.R` step.

**Deploy model.**
- Connect Cloud watches the repo's watched branch. **A reviewed merge to that branch is the production
  decision**; it makes the revision available, but the deployment is proven only when Connect serves it.
  Inspect **Last deployed**, republish when it lags, then require app-specific semantic health and the
  runtime receipt (§4c). Record the green PR head, the merge, the Connect-deployed commit and the public
  receipt separately.
- **Automation never pushes a watched branch.** The restricted publisher pushes the app's one fixed review
  branch (`automation/<app>-...`, named in the suite registry) and stops; a person's PR merge is the deploy.
- **Branch defaults are split 5/5 and must never be assumed:** `master` = Plant Diversity, Breeding Birds,
  Phenology, Mosquito, the Atlas; `main` = Small Mammal, Vegetation, Ground Beetle, Water Chemistry, Inverts.
  Resolve with `git ls-remote --symref origin HEAD` (in Actions, `${{ github.event.repository.default_branch
  }}`); the branch Connect watches is a dashboard setting git cannot show, so stop and ask when they disagree.
  Standardize new repos on `main`. Branch protection is intended but is NOT set on any suite repo (no
  rulesets; verified 2026-10-21): the review-branch publisher is the only gate today, so verify every push
  target yourself.
- Required in the repo: a lean `manifest.json`, the committed `data/` bundles, an app-specific semantic
  ready marker, and a `docs/index.html` Pages cover whose one primary CTA launches the fixed Connect URL
  directly. No pre-warm ping or pre-warm deployment: an opaque no-CORS `fetch()` proves nothing and adds a
  network dependency at load. Close a publication with one receipt tying the green PR head, the merge commit
  and the exact Pages-deployed commit; keep the repository description and homepage current.
- **PR validation tests the literal review head**, not GitHub's synthetic merge revision: set the source
  identity to `${{ github.event.pull_request.head.sha || github.sha }}`, check out that SHA, assert
  `git rev-parse HEAD` equals it, and bind promotion or merge to the same head.
- **Test the live showcase** at 1280, 390 and 320 CSS px after layout settles: byte-compare the live Pages
  index, poster art and social image with the reviewed checkout; require stable geometry, no persistent
  horizontal overflow, visible keyboard focus, correct canonical, OG and Twitter metadata, the social image's
  natural dimensions, and working app, sibling and license links; fail on console errors, page errors, failed
  requests, same-origin non-success HTTP and stylesheet or poster failures. Then prove the app, not only its
  cover: exact Connect release identity, one live bidirectional Shiny round trip, and registered app-specific
  statistics or roster assertions. Pin the browser harness and its Node floor.
- **Real-bundle lifecycle test.** A healthy shell or marker is necessary, not sufficient: outputs behind a
  picker can evaluate against `NULL` state. In a fresh session, pre-load outputs must suspend as
  `shiny.silent.error`; after loading a committed bundle, the same outputs must render without warning or
  error. Repeat the boundary in production in a fresh browser session.
- Each generated family names one canonical release-byte platform and toolchain (or proves byte identity
  everywhere); other platforms run strict schema, key, text, source and decision checks and only named,
  bounded numeric diagnostics. Never round artifacts to force parity.

**The `manifest.json` is a deploy gate: the terra/GDAL landmine (ask Connor, the Connect Cloud expert).**
A wrong manifest blocks the whole publish (`Failed to publish content`). Connect Cloud **compiles packages
from source** on its jammy image (**system GDAL 3.4.1**); RSPM binaries are not reliably used.
- The killer: `leaflet -> raster -> terra`, and **terra >= 1.8-54** ships `gdal_multidimensional.cpp` calling
  the GDAL 3.8 overload of `GDALMDArray::AsClassicDataset`, unguarded, so terra fails to compile on GDAL 3.4.1.
- The first fix: **pin `terra` to `1.8-50`**, the last release before 1.8-54. It compiles on GDAL 3.4.1 and
  satisfies `raster`'s `terra (>= 1.8-5)`; terra and raster are install-only (the app maps with leaflet), so
  there is no runtime impact.
- The complete fix: CI installs the eight-package geospatial closure (`terra`, `sf`, `s2`, `units`, `wk`,
  `classInt`, `raster`, `sp`) from exact source tarballs under pinned R, and `write_manifest.R` records and
  verifies the installed versions (its `GEO_PINS` gate). Ordinary packages come from one dated Posit
  snapshot. Commit only the validator-produced manifest; never hand-edit `Version`, `RemoteSha`, `Repository`
  or `platform`. An app whose CI regenerates the manifest re-pins terra inside `write_manifest.R`.
- Installed-package provenance and Connect's network contract are separate gates: for an exact direct-URL
  CRAN install keep `RemoteType: url` and the exact `RemotePkgRef`, but require a deployable top-level
  `Source: CRAN` plus an absolute repository URL; strip only reviewed non-semantic build clocks such as
  `Built`. Pin any direct package whose snapshot resolves past the manifest version (for example
  `bslib@0.11.0`) in every producer and validator install list, and roll the dependency-cache version with
  that change. CRAN and RSPM records are equivalent only after each manifest independently passes the
  repository, version, ref, snapshot, dependency, deploy-surface and checksum checks.

**Redeploy discipline (every app change).**
1. **Every change to a file in the manifest's `files` list** (anything in `R/`, `ui.R`, `server.R`,
   `global.R`, `www/`, `data/`) changes its checksum, so the manifest is regenerated in the same PR. A package
   change additionally needs the closure check in step 3.
2. Regenerate from a CLEAN, fully committed tree (`writeManifest()` scans the filesystem):
   `Rscript scripts/write_manifest.R`. With no local pinned R, use the repo's manual
   `.github/workflows/regenerate-manifest.yml` or the validated CI artifact.
3. Verify before commit: it parses; it is lean (`neonUtilities` and `arrow` absent); `terra` is 1.8-50
   wherever the leaflet chain is present; the new package is present; `plotly` implies `data.table`.
4. Commit the validator-produced manifest in the same PR as the code; merge only after the exact candidate
   passes every release gate.
5. After the merge, `post_deploy_smoke` reads the app's runtime receipt and requires it to equal the merged
   HEAD. A failed publish leaves the previous build serving, so "the app still loads" is not proof.

**No local R plus a byte-exact manifest gate is a merge loop: kill it, do not grind it.** A cloud agent
usually cannot run `write_manifest.R` (Connect's toolchain is jammy GDAL 3.4.1 plus the pinned closure).
With a `git diff --exit-code -- manifest.json` gate and `permissions: contents: read`, every runtime edit
fails CI by design; the way through is to download the **validated** `*-manifest-<sha>` artifact (never an
`-UNVALIDATED-` one), commit it byte for byte and rerun the exact head. Each run source-compiles terra and sf
(45 to 100 minutes) and `cancel-in-progress` cancels it on a quick re-push, which is how one cover rework
took about ten PRs and one Living Poster PR burned 13 CI runs. Two ways out:
- **Make the gate byte-deterministic.** In `write_manifest.R`: strip each source-built package's `Built`
  field; canonicalize the geo pins to the deployable lane (`Source` = "CRAN", `Repository` =
  "https://cran.r-project.org"); freeze floating RSPM aliases by targeted text substitution, never a jsonlite
  reserialize (it mangles `writeManifest`'s format and destroys the exact `url::` refs in `RemotePkgRef`); pin
  `platform` and `locale = "C"`. CI can then regenerate twice and require identical bytes, and a read-only
  `verify_manifest.R` twin enforces "committed equals regenerated" without write access. The Atlas's
  semantic comparison (`scripts/compare_manifests.R`) is the alternative that does not flap on build clocks.
- **Kill the manual round trip:** a deliberate `workflow_dispatch` "regenerate and commit manifest" job with
  job-scoped `contents: write` that refuses the watched branch, guards determinism and runs `verify_bundle.R`
  before it commits (reference: Small Mammal's `.github/workflows/regenerate-manifest.yml`), or an agent
  environment with the pinned R and GDAL 3.4.1 image. Never auto-commit on every PR.

### The NEON API token

`NEON_TOKEN` is REQUIRED for data downloads: anonymous `/api/v0/data/...` requests answer 403 since June
2026, while metadata endpoints still answer 200.
- Pin the client that speaks the new auth: R `neonUtilities` >= 4.0.1, Python `neonutilities` >= 2.0.1.
  Pass `token = Sys.getenv("NEON_TOKEN")` to `loadByProduct()` (Python:
  `token = os.environ.get("NEON_TOKEN")`); a direct API call sends the `X-API-Token` header, never the
  `apiToken=` query parameter (it writes the token into URLs, logs and proxy history). Sources, checked
  2026-09-24 and 2026-09-25: NEON's API-token tutorial and Data API docs (downloading data products needs a
  token; exploring metadata does not); an anonymous data GET answered 403 from a cloud container on 2026-09-23
  and 2026-09-24. Clients 4.0.0 (R) and 2.0.0 (Python), June 2026, added the new authentication; 4.0.1 and
  2.0.1 (2026-07-02 by CRAN NEWS and the PyPI upload date; the Python CHANGELOG prints 2025, a year typo) fixed
  the AOP downloads under it; 4.0.2 and 2.0.2 (2026-09-09) leave the floor where it is.
- Every refresh workflow maps `NEON_TOKEN: ${{ secrets.NEON_TOKEN }}` into the probe and fetch steps only,
  not job-level env. The repo declares `NEON_TOKEN` as a credential in its committed `.env.example`; it is
  never echoed.
- Before the fetch, on every path including `skip_download`:
  ```bash
  test -n "$NEON_TOKEN" || { echo '::error::NEON_TOKEN secret is missing: NEON data downloads need an API token'; exit 1; }
  curl -fsS -o /dev/null -H "X-API-Token: $NEON_TOKEN" \
    "https://data.neonscience.org/api/v0/data/<DPID>/SRER/<YYYY-MM>" \
    || { echo '::error::NEON rejected the token on a data endpoint: refresh the NEON_TOKEN secret'; exit 1; }
  ```
  Use a month with data for the product. Never probe `/api/v0/products/...` (200 without a token, so it
  proves nothing).
- A missing or rejected token fails the job with `::error::` and a step-summary line saying the bundle was
  not refreshed. It never passes silently with unchanged row counts, and an access error on a data pull is an
  auth failure until proven otherwise, not a product change.

### Auto-refresh and reviewed release (`.github/workflows/refresh-data.yml`)

- **Schedule:** `cron: "17 13 * * 6"` (Saturday 06:17 America/Phoenix, clear of the UTC-midnight edge). The
  gate job runs one shared calendar block, byte-identical in every repo except `REFRESH_WEEK` (1 for product
  apps, 2 for the Atlas): it steps back to the most recent Phoenix Saturday and checks that Saturday's week of
  the month, so a start up to six days late still refreshes. GitHub never hands the gate its scheduled slot,
  and a gate that reads the job-start wall clock against a cron near Sunday 00:00 UTC skipped July and
  October 2026 green in seven apps. A skip inside the refresh week emits `::warning::`; every decision writes a
  step-summary line. Products on an immutable-release cadence (Breeding Birds, Vegetation) may use a fixed
  day of the month and say so in their workflow header. Test the gate itself with a unit test that feeds it
  late start times. A month in which no run reached the build job is a failure the suite probe reports.
- **Flow:** gate, checkout, pinned R and declared dependencies, the token probe, fetch raw data into an empty
  stage, rebuild bundles and indexes, verify the exact site, schema, index, checksum, manifest and offline
  contracts, the coverage checks below, then publish the immutable candidate to the fixed review branch and
  stop. A separate `notify` job (`issues: write` only, no contents) opens or updates ONE deduped issue
  "<app> refresh ready: <rows> rows, data through <date>" with the compare link when rows or `data_through`
  change, and closes it when the branch merges; a failed scheduled run opens "Refresh failed: <app>". A person
  opens the PR and merges it: a bot `GITHUB_TOKEN` push does not start `push` workflows, and when automation
  later updates an open PR, GitHub holds its `pull_request` runs until a write user selects **Approve
  workflows to run**. Always verify that the green run belongs to the exact `headRefOid` that merges. Never
  give the raw producer write authority, and never delete the last valid bundle before its replacement
  passes. Required download, build, contract, manifest, receipt and publication gates fail closed;
  `continue-on-error` is only for optional diagnostics that cannot change published bytes.
- **`skip_download`:** a `workflow_dispatch` input on every app with a heavy pull. It gates BOTH the fetch
  and the bundle step (the classic bug: fetch gated, bundler not, dying on "No `<SITE>_raw.rds`"); the run
  rebuilds only what derives from committed bundles and may publish that to the review branch. A publisher
  that replaces a waiting full-run candidate logs `::warning::` and a step-summary line; the suite probe
  reports each overwrite.
- **Upstream intake:** the producer reads `issueLog_<DPID>` and the product changeLog on every run, diffs
  them against `docs/upstream-ledger.csv` (entry id, date, disposition handled / quarantined / not
  applicable, owner) and stops with `::error::` on any unledgered entry newer than the last run. Known defects
  are quarantined by identity (site, analyte or field, date window, unit), never by a value threshold, and a
  quarantine lifts itself when NEON says a release corrects them. A release-pinned producer checks for a newer
  RELEASE tag each run (the RELEASE-2027 watch, late January) and raises the refresh-ready signal.
- **Coverage, measured two independent ways:** against the source (per site, the newest month with records
  is within 3 months of NEON's `availableMonths` for the product, read from the anonymous
  `/api/v0/products/<DPID>`), and against the baseline (per site, site-years and rows fall no more than 5%
  below the committed bundle unless a reviewed allowlist names the reason). The oracle never reuses the
  producer's decoding helpers.
- **`verify_bundle.R` carries at least one INDEPENDENT oracle per headline metric:** a fixture built from
  NEON's documented code table for every categorical the producer filters on, with the expected class
  written by the rung specialist, not derived from the producer; ceilings on held or excluded shares; the
  coverage-lag check; and distribution sanity on derived columns (an `n_years` maximum above 1 where years
  exceed 1; a share near 100% in every month fails). The rung specialist signs the oracle.
- **The 60-day rule:** GitHub switches off a public repo's scheduled workflows after 60 days without a
  commit, which the review-branch design makes likely. Each repo keeps a commit inside every 60 days (a
  keepalive job with `actions: write` only, or the maintainer loop's reminder 14 days ahead); recovery is
  `gh workflow enable`.
- **Commit by explicit path** (`git add data/<bundle>.rds`, guarded by `git diff --cached --quiet`), never a
  blanket add that catches a gitignored sibling; zero hard-coded local paths in any CI-run script
  (`grep -rn 'setwd("C:\|/Users/' scripts/` before trusting a refresh).
- **Deploy trigger:** an intentional PR merge to the watched branch. The review boundary is part of data
  provenance.

### Derived apps (the Atlas)

The Atlas (NEON-Driver-Cascade) builds `data/cascade.rds` from the sibling bundles. Never build from moving
shallow-clone heads or copy unverified sibling directories. Allowlist canonical origins
(`scripts/workflow_guard.R` approved sources; add a sibling there, never with an ad-hoc `git clone`), pin
exact sibling commits, build in a no-write producer job, pass only the allowlisted artifact family plus a
SHA-256 receipt to a fresh validator, fail closed when site-year coverage drops against the committed
baseline, and let the restricted publisher push the Atlas's review branch for a person to merge. Inputs:
every product the suite registry marks as an Atlas input (today including Mosquito). Since 2026-10-22 its
publisher pushes the fixed review branch `automation/atlas-data-refresh`, and `publish` defaults to false (a
rebuild that still runs every gate). Its rebuild runs in the second week, after the products settle.

---

## 7. Per-app readiness checklist (audit every app against this)

**Data bundles:** `data/sites/*.rds` present and valid (loadable, non-empty) · `data/site_index.rds` ·
`data-sample/demo.rds` · all git-tracked · `data_through` within 3 months of NEON's `availableMonths` per
site, measured · upstream intake against `docs/upstream-ledger.csv` · `verify_bundle.R` with its named
independent oracle · deterministic bundles.

**Automation:** `refresh-data.yml` on the §6 schedule and gate · producer, validator and restricted
publisher kept separate · publishes a verified candidate to its one fixed review branch and stops; the notify
job opens the refresh-ready issue; a person opens and merges the PR · never pushes production directly · the
token probe on every path · `skip_download` gating fetch and bundle · the candidate-versus-baseline coverage
diff · a commit inside every 60 days · `manifest.json` lean (no `neonUtilities` or `arrow`) with the whole
geospatial closure pinned and truthfully recorded · a GitHub remote · the cover's CTA live · the deployed
revision proven by `post_deploy_smoke`'s runtime receipt · the live Connect URL in TG-Data-Apps
`monitoring/sites.tsv`.

**NEONization:** the cover and landing splash in the house copy voice (§1) · the **in-app suite registry**
(all ten explorers with correct URLs, in About or the footer) and exactly one Atlas route on the cover ·
**page identity** (`title =`, `lang = "en"`, no `window_title`, no `fillable`; `post_deploy_smoke` greps
`<title>` and `<html lang>`) · a **mobile flow at 375 px, driven**: load SRER from the picker, the site name
and hero in view, no element wider than the viewport, popup buttons uncovered, banners on one line, reduced
motion honored · the **QC-flag system** (below) · coded-field maps with real-value fixtures (§4c) · a
metadata and codebook view with the NEON release tag (or PROVISIONAL), the release DOI, the CC BY 4.0
attribution and "data through <date>" on the landing view · **downloads that produce a file**: each control
saved once in headless Chromium and WebKit at 375 and 1440 px, file non-empty, PNG decodes · entity pin cards
· chrome at the version the maintainer loop reports current, each file headed `from <repo>@<sha> <path>` ·
the **site-picker map contract** (§2g) · pointer-driven charts with a keyboard or table alternative ·
**every `Shiny.addCustomMessageHandler` takes exactly one argument** · **gates in `ci.yml` on every PR and in
`refresh-data.yml`**: `verify_bundle.R`, the suite handler lint, the
cover engine, and `post_deploy_smoke` proving REVISION (a runtime receipt equal to the merged SHA) and
BEHAVIOR (a headless pass: zero console errors, `<title>` and `<html lang>` present, the picker answers). An
app missing `ci.yml` is not NEONized. (The suite cover engine and handler lint are being extracted into
`NEON-Small-Mammal-Tracker-App/scripts/suite/`, versioned and pinned by commit SHA and sha256 in each app's
CI with the app's literals in `scripts/suite.config.json`; until then each app's own `check_*.mjs` and
`verify_*.R` stand in.)

**The QC-flag system (every app gets it; first ported to Breeding Birds).** `<entity>_qc()` returns ranked
"verify, not wrong" flags (high, warn, info) with the EXACT offending rows behind each; they surface on the
entity profile INSIDE the export node (so the PNG captures them); each flag is a button (or
`role="button" tabindex="0"` with one delegated Enter and Space handler) that opens an inspector table of the
rows with a per-flag CSV; `<entity>_qc_report()` writes the full QC-report CSV; a clean entity shows a green
reassurance. Thresholds are data-derived and domain-grounded (the rung specialist's), validated on SRER and
two contrasting sites, with base rates recorded in `docs/QC-THRESHOLDS.md`; target about 0 high flags on
clean NEON data, and `verify_bundle` fails a high flag above 5%. A flag or class that fires on 0% or on more
than 90% of eligible rows is guilty until proven innocent, and so is a monthly share that does not vary by
season. CSS: `.qc-flag-<level>`, not `.qc-flag.<level>`; Small Mammal and Plant Diversity still use the older
classes, so Breeding Birds (`bird_qc()` in `R/bird_helpers.R`) is the reference for the convention.

**Opportunity-complete comparative surfaces (Breeding Birds reference).** Distinguish source presence from
complete estimand support: a site may have source rows yet lack a required month, method channel or
comparison year, so keep it in the roster and render the aggregate as `NA` rather than averaging partial
support. Define supported zeros at the estimator's exact grain (a zero count and a zero point-year are
different evidence, never inferred from a missing detection or visit). One versioned comparative contract
owns the window, eligibility predicate, support fields, standardization target and ordered roster, and the
app, Search index, marks, codebook and exports consume it and agree exactly. State in fixtures and UI copy
what the metric cannot support: standardizing effort creates no abundance, population, density, occupancy,
breeding-status, territory, causal or forecast evidence.

**A normative science contract.** Each app ships `docs/SCIENCE-CONTRACT.md` and hard fixtures for: row-order
and bout or event selection invariance; opportunity and structural-zero semantics; panel and effort
handling; exact estimator edge cases; classification conflicts and geographic authority gates; app, PDF and
export parity; strict codebook definitions (units, NA semantics, estimands); and Atlas eligibility and
exclusions. Update the contract and its adversarial tests together whenever scientific meaning changes.

**One suite registry.** The Atlas owns one versioned registry (app ID, name, role, motif and art direction,
palette, DPID, repository, showcase URL, live URL, release state, Atlas disposition), fed by TG-Data-Apps
`.claude/neon/suite.json`. Generate from it the Atlas's suite destinations and the in-app Suite/About panel
in every app (a pinned copy vendored into each); CI checks the declared registry version. Covers carry
exactly one route back to the Atlas, never a directory, constellation or mascot. When a new app ships, update
the registry so every app can reach it.

**Suite Living Poster V1 (the cover frame).** Every companion Pages cover and its in-app first-run echo
share one frame: a focusable skip target; the DDL topline and exactly one Atlas route; an app or unofficial
eyebrow; a 3 to 7 word hook; one plain promise of at most 12 words; one contextual CTA; one dominant
app-specific editorial image in a responsive `picture` (declared natural dimensions, checksums, byte budgets,
an intentional fallback) with meaningful alt text and durable provenance; and a compact scope, honesty,
Source and Feedback footer. No metric band, methods block, release receipt, feature cards, second CTA or
suite directory. Reuse the grammar, not a clone: each app owns its palette, motif, copy, focal crop and
scientific limit. A stylized illustration when abstraction is the point; a licensed, provenance-tracked
documentary image only when field realism earns trust. Validate both surfaces at desktop, 390 and 320 px with
the real framework gutters, and record the exact Pages artifact and Connect commit before calling a cover
shipped.

**The Cover Contract (enforce the frame mechanically).** The suite cover engine (today each app's
`scripts/check_cover.mjs` and `scripts/check_in_app_landing.mjs`, zero-dependency Node CI checks) asserts the
frame instead of trusting it, as a presence and an absence gate: exactly one `<h1>` and `<main>`, the skip
link and the labeled Atlas nav, the single hook, promise and CTA, the full OG and Twitter set with the
1200 x 630 card, no `fetch()`, `http:` or Google Fonts at load, 44 px touch targets, and the
`prefers-reduced-motion`, `prefers-contrast` and `forced-colors` seams; plus asset integrity: each image's
SHA-256 cross-checked against `docs/IMAGE-PROVENANCE.md` (per asset: tool, date, prompt, reference,
dimensions, bytes, SHA-256; AI-generated and third-party attribution kept separate; retired assets
quarantined; "the art carries no scientific value; facts stay selectable HTML"), with self-parsed image
dimensions and byte budgets. Keep a PNG master, full and compact WebP and the 1200 x 630 OG image
byte-identical in `docs/assets` and `www/assets`; no Git LFS; an art, copy or crop change is one coordinated PR
touching the images, both hash pins and the provenance record. Motion, scroll-video ideas, per-app divergence
and the generated-asset pipeline live in NEON-Small-Mammal-Tracker-App `docs/COVER-MOTION-KIT.md`, the
starting kit a cover is built from and then altered per project.

**Definition of done.** An app is finished only when the reviewed code and data are merged, the exact release
bytes are promoted, Connect and Pages are healthy, desktop and mobile public QA passes, exports and receipts
are inspected, the suite learning is recorded centrally, and the last known-good rollback remains
identifiable.

---

## 8. Working across agents (Claude Code and Codex) and the suite loop

The suite is built by Claude Code and Codex, often on the same repo. They share no live memory, so they work
through durable artifacts in the repos:

- **One source of truth, thin front doors.** This file is the suite doctrine. Each app repo carries a thin
  `AGENTS.md` (Codex) and, where present, a thin `CLAUDE.md` (Claude), both pointing at its pointer stub,
  this file and its local authority files (`docs/SCIENCE-CONTRACT.md`, `docs/BUILD-TEST-HANDOFF.md`,
  `DEPLOY.md`). Fleet lessons live in TG-Data-Apps `.claude/agents/LESSONS.md`; a project-local LESSONS file
  is harvested into it, not grown on its own.
- **Codex reads the fleet through a mirror.** The Codex bridges (`~/.codex/agents/*.toml`) resolve role files
  with `dev-teams --path <role>` from a mirror of TG-Data-Apps; every bridge runs `dev-teams --update`
  (fast-forward only) first, and `dev-teams --check` warns when the mirror trails `origin/main`.
- **The handoff log is the async channel.** `docs/BUILD-TEST-HANDOFF.md` is the dated, append-only ledger
  both agents close a session with; tag each entry `[Claude]` or `[Codex]` and end it with a one-line next
  action.
- **Cross-review, do not self-review.** Different model families have different blind spots; when Codex opens
  a PR, have Claude review it, and the reverse.
- **Contracts are the trust layer, within what they encode.** The `check_*.mjs` and `verify_*.R` gates and
  the manifest determinism gate are tool-neutral referees, but CI enforces only the invariants it encodes; a
  structural gate is not a science check. Each `verify_bundle.R` names its independent oracle (§6), or the
  readiness checklist is unmet.
- **The maintainer loop watches the suite between audits.** TG-Data-Apps holds the roster
  (`.claude/neon/suite.json`), the read-only probe (`.claude/scripts/neon-suite-probe.mjs`), the static lint
  (`.claude/scripts/neon-suite-lint.mjs`, which also checks every pointer stub against this file's format)
  and a weekly watch that keeps one issue, "NEON suite: maintainer queue". The monthly steps are in
  `neonize.md` "Maintainer loop".

Rough division by strength, not a rule: Codex for tight visual, UX and prototype iteration; Claude for
cross-repo diagnosis, science-contract and claim review, Atlas synthesis and learning-loop upkeep.

**The pointer stub (every app repo except this one; at most 40 lines; the suite lint checks it).**

```markdown
<!-- neonize-playbook-stub: v1 -->
# NEONize playbook: pointer for <App name>

The NEON suite playbook has one home, read by Claude Code and Codex alike:
https://github.com/tgilbert14/NEON-Driver-Cascade/blob/master/docs/neonize-playbook.md
(side-by-side clone: `../NEON-Driver-Cascade/docs/neonize-playbook.md`). Read it before
suite work. Fold every suite rule, pattern or gotcha into that file, never into this one.
Anything here beyond this pointer and the app facts below is a stale fork: report it.

## This app

- Repo `<slug>` · watched branch `<branch>` · product `<DPID>`
- Rung specialist: `<agent>`
- Refresh: <the fixed review branch, and that a person's merge is the deploy>
- Local authority files: <the files that exist, each with what it decides>

## App-specific rules

- <0 to 6 bullets: only rules a cold agent needs that the local files do not already say>

## Owner-settled house rules (both tools)

- <the three bullets from §1, verbatim>

Cold boot: also grep the fleet's `.claude/agents/LESSONS.md` in TG-Data-Apps (Codex: the
`dev-teams` mirror) for your role name: `grep -E '^- \[[0-9-]*\] [a-z0-9+-]*<role>[ +]'`.
```

### Suite learning and Atlas feedback

`docs/NEON-SUITE-LEARNING-LOOP.md` is the central record of the one-at-a-time app passes and the Atlas v2
synthesis. Each pass:

1. updates the app-local handoff with exact commands, expected and actual results, hashes, failures, cleanup
   and invalidated evidence;
2. emits the app's Atlas knowledge package (`docs/DRIVER-KNOWLEDGE-PACKAGE.md`): unit, support, opportunity
   and effort, zero and missing rules, joins, mechanisms and claim limits;
3. classifies each learning as app-local, suite-platform, scientific-contract and/or Atlas-impacting;
4. updates the central suite register and the Atlas backlog, including explicit `REJECT` and `NONE`
   decisions; and
5. sends any Atlas parity failure or missing audit field back to the owning app instead of hiding it in
   Atlas adapter logic.

Do not rebuild the Atlas repeatedly from half-reviewed sibling states: finish and pin the app knowledge
packages, run the cross-product gap audit, decide whether a complementary product is justified, then
integrate only accepted, immutable inputs in one deliberate pass.

---

## 9. How we work (principles for every session)

These govern every session in either tool and outrank any single feature.

- **Plan, question and challenge before you code.** Before anything non-trivial, restate the goal, surface
  the load-bearing assumptions, name the risks and the blast radius, and ask whether this is the right thing
  to build. Reversible and well scoped: proceed. Risky, outward-facing or ambiguous (a watched-branch change,
  a rename, a contract or schema edit, anything touching production bytes): plan it and confirm first.
- **Promote proven patterns into skills, curator-gated.** When a pattern has been used across two or more
  apps, or survived a real reviewed build, propose it to `curator`, who vets it and, through the
  `skill-creator` skill, turns it into an invokable skill in TG-Data-Apps that both tools can call. (The Cover
  Contract and the manifest-determinism recipe are the first candidates.)
- **Know your tools; suggest new ones.** Take stock of the available skills, subagents, MCP tools and
  workflows before hand-rolling; when a task would be better served by a tool we do not have, say so by name.
- **Always propose an improvement.** Close substantive work by naming at least one concrete improvement you
  noticed, even out of scope, and log the durable ones to LESSONS or the handoff.

---

*Living pattern catalog. Plant Diversity (DP1.10058.001) was the first full NEONize; Breeding Birds,
Phenology, Vegetation Structure and the Atlas supplied many of the examples. This file merged the Small
Mammal copy (last at `d3ec26e`) and the Atlas copy (last at `44acb7a`) on 2026-10-22; both pre-merge texts
are in git history. Current pass status lives in the learning loop and the app handoffs, not in named agents
or chat memory.*
