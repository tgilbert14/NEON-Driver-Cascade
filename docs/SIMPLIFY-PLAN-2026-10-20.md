# Plan, 2026-10-20: simplify the Atlas, surface by surface

> Written by the lead on 2026-10-20 from a read of `master` at `4b274e8` and a local run of the app,
> measured in a headless browser at 375 and 1440 px. The method is the one the MSC project used on
> 2026-10-19 (`MSC/docs/plan-2026-10-19-plot-catalog.md`): every visual on a card, one ruling each
> (keep, keep and fix, simplify, move, remove), one rule above all of them: if the owner cannot
> teach a visual in one breath, it goes. Every count below is dated and in the past tense.

**The short version.** The app opened on SCBI in Virginia, not SRER, because SRER has no green-up
record and the default-site rule only picks SRER among sites that do. The first thing a visitor read
was a 103-word paragraph with three kinds of p-value. Seven tabs carried 8,600 words of copy, 3,365
of them on About. Only 2 of the 12 pairings can ever be judged (warmer years, earlier green-up, in
two versions); the other 10 are "context only", yet they fill 12 chips, 12 grid columns, 10 pooled
rows and the Search catalog, so the vote-versus-context distinction had to be learned on every
surface. The app went by four names. The plan cuts to four tabs, one picture per tab, a counts-first
line at the top of each, one plain table of the pairings, the two judged pairings as the headline,
and the caveat on each number as four short lines under the chart instead of paragraphs. No
statistic, data file, workflow or bundle changes.

## 1. What the measurement found

| Tab (as it was) | Words | Controls | Charts | Notes |
|---|---|---|---|---|
| Hero band | 103 | 1 | 0 | The verdict paragraph: raw p, Holm p, "the family evolved", "not confirmatory" |
| Overview | 650 | 2 selects, 46-site list, 8 popovers | 0 | Response selector defaulted to a pairing the app says it cannot judge |
| Layered Timeline | 908 | year select, 12 link chips | 2 | The pulse tracer explains "exact-zero abstentions" before the chart |
| Driver Lab | 615 | 2 selects, lag slider, season radios, demo button | 2 | The lag explorer is a demonstration of p-hacking |
| Across NEON | 1,954 | sort select, 552 grid cells | 0 | The 46 x 12 grid was 835 px wide on a 375 px phone |
| Search | 639 | mode radio, selectize, checkbox, slider | 0 | Both tables repeat what the grid shows |
| QC | 484 | 5 flags | 0 | Fine as it is; it is reference, not a first view |
| About | 3,365 | 2 folds | 0 | 16 headings; REML, Knapp-Hartung, I-squared, exact binomial |

Default site measured: SCBI. Names in use: Response Atlas, NEON Cross-Product Response Atlas, Driver
Cascade, Driver Response Atlas. Em dashes in the reading path: 35 in `ui.R` and `server.R`, 5 on the
cover. The cover said "nine living records"; the bundle consumes seven.

Owner rules already settled and applied here: SRER is the default site; no AI-art badge; plain DDL
voice with no em dashes; review-branch deploy only (not this PR's concern; the pipeline is Wave 2).

## 2. The rulings, card by card

Verdicts: **keep**, **keep, fix**, **simplify** (same question, fewer marks or words), **move**,
**remove** (off the visitor surface; code archived under `docs/history/archive/`, never deleted).

### The shell and the first view

| Card | Surface | Ruling | What gets built |
|---|---|---|---|
| A1 | Top bar name and subtitle | keep, fix | One name everywhere: **NEON Response Atlas** (page title, top bar, cover, README, export headers). The subtitle line goes |
| A2 | "How to read this" modal | simplify | Four plain bullets: pick a site, read the timeline, open one pairing, see all sites |
| A3 | Site report CSV, theme toggle | keep | |
| A4 | Hero verdict paragraph (103 words) | remove | Replaced by one counts-first line, computed: "SRER, Santa Rita Experimental Range: 11 years on record (2015 to 2025), 3 of 4 measurement layers, 8 years with complete weather. No green-up record here, so neither judged pairing can be tested at this site." |
| A5 | Four hero tiles | simplify | Three: years on record, measurement layers, years with complete weather. The "eligible associations agree" tile goes; its number lives in the pairings table |
| A6 | "New here?" mascot bubble | remove | Meta copy; the tabs are the guide |
| A7 | Seven tabs | simplify | Four: **This site**, **One pairing**, **All sites**, **About** |
| A8 | Default site | keep, fix | `DEFAULT_SITE` becomes SRER unconditionally (the "has green-up" condition is why it never fired) |

### This site (Overview and Layered Timeline merged)

| Card | Surface | Ruling | What gets built |
|---|---|---|---|
| O1 | Site select and response select | simplify | Site select only, the 46-site browse list folded under it. The response select moves to One pairing |
| O2 | Site bio line | keep | |
| O3 | Signal chips (11 at SRER) | remove | Duplicate of the measured table |
| O4 | "The idea" card: popover, schematic, basal-area line | remove | The schematic is four boxes joined by plus signs. Basal area becomes one row of the measured table |
| O5 | Insight banner | remove | Folded into the headline line (A4) |
| O6 | "What's measured here" table | move | A fold under the timeline, "What is measured here", with the basal-area row and a "Years" column |
| O7 | Hill diversity profile (q0, q1, q2) | remove | Not teachable in one breath; the Plant Diversity app owns it |
| O8 | Handoff links between tabs | remove | |
| T1 | Pulse tracer: banner, year select, click-to-trace, highlight marks | remove | The app itself calls it an anecdote. It is the chart's third encoding |
| T2 | Layered timeline (four strips) | keep, fix | The one picture of this tab. One encoding (one hue per layer, lines scaled to each signal's own average), the legend is the key, the four plain lines under it |
| T3 | Twelve link chips | simplify | One plain table, "Pairings at this site": Driver, Response, Years overlapping, Direction found, Reads as. The two judged rows first, then "shown for context". Plain verdict words (section 3). A row opens that pairing on One pairing |
| T4 | Seasonal rain card (bars plus two comparisons) | simplify | Only at dryland sites. The bars (winter and monsoon by year, one key) and ONE comparison: annual rain versus monsoon rain against next-year small-mammal catch, with n on each number. The plant-richness comparison and the "STRONGER" chip go. At other sites the card is absent, with no paragraph explaining its absence |

### One pairing (Driver Lab)

| Card | Surface | Ruling | What gets built |
|---|---|---|---|
| L1 | Response select, lab title, sign-match banner, rain-coverage note | simplify | One select of the 12 pairings with plain labels ("Monsoon rain, then small-mammal catch the next year · context"). Default: temperature and green-up where it is testable at the site, else the pairing with the most years |
| L2 | Driver table | remove | Moved to T3 |
| L3 | Scatter with on-figure statistics and the trend-line rule | keep, fix | The on-figure box carries r, n and the years. The p-value and the three sensitivity lines leave the figure; they sit in a "More numbers" fold under it. The rule stays: no trend line under six years, grey line unless the direction is clean |
| L4 | Scatter note (permutation null, bootstrap interval) | simplify | The four plain lines |
| L5 | Year picker and tap-a-dot year detail | keep | The tap-for-detail model |
| L6 | Lag and season explorer (fold with select, slider, radios, demo button, curve, glossary, readout, caveat) | remove | Archived. About keeps one sentence: lags and seasons were fixed before the data were looked at, and the app does not let a reader slide them |

### All sites (Across NEON and Search merged)

| Card | Surface | Ruling | What gets built |
|---|---|---|---|
| X1 | Pooled headline card: banner, pooled note, tension note, 2 ranked rows, 10 context rows, 2 popovers | simplify | One headline line: "Warmer years, earlier green-up: the direction fits at 15 of the 18 sites with enough years using annual temperature, and at 8 of 18 using spring temperature." Two rows, each a bar and "fits at k of n sites". A fold, "The statistics", holds raw p, Holm p, median r and the four sensitivity counts. One line says ten other pairings are shown for context and never counted. Pooled CSV stays |
| X2 | Site x pairing grid, 46 x 12 | simplify | Default columns: the two judged pairings and a "pairings with enough years" count, so the table fits a phone. A switch, "Show the ten context pairings", adds the hatched columns. Cell = glyph plus r (one encoding), five-item key. Sort: group, A to Z, most fits. The basal-area sort goes. CSV stays |
| S1 | Search tab: Find a link, Direction agreement | remove | Find a link is a column of the grid; Direction agreement is its "most fits" sort. The two DT tables, slider and mode radio go. The search index file stays in the bundle untouched |

### About (About and QC merged)

| Card | Surface | Ruling | What gets built |
|---|---|---|---|
| Q1 | QC flags, inspector, QC CSV | move | The top of About, "Data checks for this site", unchanged otherwise |
| B1 | What this is | simplify | Two sentences |
| B2 | Construct status and Selection status cards | simplify | One card, "What this can and cannot say", four plain lines |
| B3 | Snapshot and provenance | keep | A fold |
| B4 | Site grouping heuristic | simplify | Two sentences |
| B5 | Plain-English glossary (6 terms) | simplify | Four terms still on screen: green-up index, lag, catch rate, the timeline |
| B6 | Statistics in plain English, the meta-analysis companion, the safeguards list | simplify | One fold, "For statisticians", carrying the existing text without em dashes. The safeguards list goes (it repeats B2) |
| B7 | The pairings table (12 rows) | keep, fix | The "Analysis use" column reads "Counted?" with Yes or No (context). The note column stays |
| B8 | Data and limits, codebook, downloads, sources, attribution | keep | |
| C1 | Cover `docs/index.html` | keep, fix | Kicker "NEON Response Atlas · unofficial"; "nine living records" becomes seven in both places; em dashes out. Nothing else moves |

## 3. Rules every builder codes to

- **The caveat goes on the number, as four short lines, never a paragraph.** Under every chart:
  *Shows* (what the marks are), *Example* (one real value from the selected site, computed),
  *From* (which NEON products and years), *Cannot* (the one thing a reader must not conclude).
- **Plain verdict words, mapped from the bundle's tier field, never from its sentence:**
  consistent = "Fits the expected direction"; apparent = "Fits, but the range includes zero";
  counter = "Runs the other way"; neutral = "No direction"; exploratory = "Too few years to judge";
  insufficient = "Not testable here". The bundle's own verdict sentences are data and stay in the CSVs.
- **Two words replace the jargon in the reading path:** "judged" for vote-eligible and "context"
  for context-only. "Literature-motivated", "build-locked", "construct", "familywise",
  "multiplicity" and "honest" appear only inside the For statisticians fold.
- **No em dashes** in any file this PR touches. The prior notes inside `cascade.rds` carry em
  dashes and cannot change without a rebuild; that is a Wave 2 line, recorded in section 6.
- **Nothing numeric changes.** No edit to `global.R` beyond `DEFAULT_SITE`, none to `R/`,
  `scripts/`, `data/`, or any workflow. The export headers change only where the name appears.
- **Copy voice:** plain words, no hype, no sincerity labels, no sentence that tells the reader what
  they can already see.

## 4. Order, lanes, files and gates

Branch `claude/simplify-2026-10-20` from `master`; one PR to `master`; Tim merges. The lead cuts the
four-tab skeleton in `ui.R` first, then two Opus 5.5 lanes at medium effort build in named regions,
Edit only, the MSC two-lane pattern.

| Lane | Owns | Files |
|---|---|---|
| A | The shell, This site, One pairing | `ui.R` (header, hero, tabs 1 and 2), `server.R` (hero, overview, ladder, chips, lab, explorer removal), `www/cascade.css`, `www/cascade.js` (tracer removal), `global.R` (`DEFAULT_SITE` only) |
| B | All sites, About, the cover and the name | `ui.R` (tabs 3 and 4), `server.R` (pooled, scoreboard, search removal, qc, about, download headers), `docs/index.html`, `README.md` first line, `DEPLOY.md` name lines |

Gates, run locally before the one push: `python3 scripts/trusted_publish.py update-manifest
manifest.json` (the runtime integrity check refuses a changed file whose checksum is stale), then
`Rscript scripts/smoke_app.R` (it pins the arrow glyph, the standing-stock live region and the WOOD
disclosure; those stay), `Rscript scripts/test_boot_integrity.R`, `git diff --check`, and the
browser pass at 375 and 1440 px on SRER, SCBI and WOOD. CI then rebuilds every artifact and requires
the manifest to reproduce; nothing in `data/` moves.

## 5. Decisions flagged for the owner

1. **The name.** This plan uses **NEON Response Atlas** on every surface. The repo stays
   `NEON-Driver-Cascade`.
2. **SRER first, with no judged pairing.** SRER has no green-up record, so the first view says in its
   headline line that neither judged pairing can be tested there, and leads with the timeline and the
   monsoon-rain contrast, the app's clearest teaching case. The alternative is a site where the headline
   pairing can be judged; the owner rule says SRER.
3. **Two teaching tools leave the visitor surface:** the pulse tracer (T1) and the lag and season
   explorer (L6). Both are archived under `docs/history/archive/` and can come back as an About fold.
4. **Context columns off by default** on the All sites grid (X2), with a switch.
5. Not this task: the `publish` default, the coverage-regression gate, the review-branch migration
   (Wave 2, with PR #73 already touching `refresh-data.yml`).

## 6. Follow-ups this plan does not build

- A map site picker (the suite contract); the Atlas has a list only.
- The prior notes in `cascade.rds` carry em dashes; they change at the next rebuild.
- Per-product release labels and "data through" on the first view (audit item, provenance).

## 7. Built (2026-10-20)

Every card above was built as ruled, by two Opus 5.5 lanes at medium effort under the lead, on one
branch, in one PR. Lead changes at integration: the site report CSV's summary line is now the hero's
counts-first line plus the judged-pairing sentence; the QC flag text (which comes from the hashed
helper and cannot change here) is mapped on screen so "Across NEON" reads "All sites" and
"vote-eligible" reads "judged"; the timeline legend sits below the year labels on a phone; the three
hero tiles share one row on a phone; a blank grid cell stays blank on screen and reads "not
testable" to a screen reader; the cover's "How it stays honest" fold became "How the numbers are
checked". Lane choices kept: a year counts as on record only when at least one signal has a value
(SRER shows 10 years, 2016 to 2025, not 11); the About line says the lags and directions were set
before the data were looked at and adjusted during earlier builds, which is what the repository
history shows. Not done, by the rules: README.md and DEPLOY.md keep their em dashes outside the name
lines (they are operating records, not visitor copy); the export CSV headers keep their old wording
beyond the name.

Measured after the build (local run, SRER): This site about 580 words, One pairing about 190,
All sites about 650, About about 2,360 including the data checks (the twelve pairing notes from
the bundle are most of it). The grid is 280 px wide on a 375 px phone with the context columns off.
