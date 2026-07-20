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
different chat, pass the URL as `url`.

**Cross-linking is relative, not hardcoded** (as of rung 22). `index.html` → `./walk.html?site=CODE`
and `./plot.html`; `walk.html` and `plot.html` → `./index.html`. The published artifact URLs are used
**only** when the page is actually served from `claude.ai` (`ART` + `ON_ARTIFACT` in `index.html`, and
the equivalent host test on `walk.html`'s back-link). This is what lets the prototype work opened
straight from the repo — it previously did not. Update the `ART` map if an artifact URL ever changes.

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
| 21b | **Protocol review (NEON SOP)** — "Survey campaigns" was a misread; relabelled "First tagged", and three shipped claims corrected | DONE | — |
| 22 | **Index explorer, pass 1** — driver cards show the plausible range; the invented year wheel is cut; the three pages finally link up | DONE | — |
| 23 | **Production push, pass 1** — map gated to built sites; The Plot made phone-usable; controls restructured; plot source de-SRER'd | DONE | — |
| 24 | **Standouts** — the Plot-data panel names the real tallest / widest-crown / most-partial-death / lone-saguaro individuals, each a tap-to-fly-there record | DONE | — |
| 25 | **A real second plot — SRER_056** — built end-to-end from real NEON data (own AOP georeference), reachable via a plot switcher; cover denominator now PINNED from real subplotID | DONE | — |
| 26+ | Optional — more plots (recipe proven); more real-LiDAR forests; TOD-linked bark/ground variation | PLANNED | — |

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
stemDistance + stemAzimuth, point coords from the locations API), drawn at real height/crown **for the
104 NEON measured** (the other 75 at a species-typical size, marked with an open ring), live vs
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
as a crisp species-coloured **ring** — a solid disc at NEON's measured crown size, or an open ring at a
species-typical size where NEON did not measure the plant — inside the 40×40 boundary. The 3D plant figures
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

> **Parts of this rung-20 block were later reversed/corrected in rungs 21–23 (PR #40) — read those for the
> current behaviour.** Specifically: the About panel now **starts collapsed** (not open); the tag-year filter
> is **"First tagged" cohorts, not "re-surveys"** (the dates are when a tag went on, not a before/after);
> and the cover figure became a **crown-area index over the surveyed strip**, not a whole-plot cover %.

**Standouts (done, rung 24):** the "Plot data & analysis" panel opens with a short **Standouts** list — the real
**tallest** (measured), **widest crown** (measured), **most partial death** (the living plant with the highest
share of standing-dead stems — the "a dead branch is not a dead plant" case), and **the lone saguaro** (flagged
*mapped, not measured*). Each row is a button that closes the panel and calls the existing `selectById` to fly
the map to that individual and open its NEON record. All values are read straight from the records — nothing
invented, heights labelled measured-only.

**A real second plot — SRER_056 (done, rung 25):** the multi-plot architecture is now proven end-to-end with a
genuine second plot. **SRER_056** (Santa Rita, in the same AOP tile as 048) — **147 tagged plants, 6 species,
113 measured** — a distinctly different, mesquite-richer community (creosote ×89, velvet mesquite ×26, Christmas
cholla ×26, prickly pears, one barrel), tag cohorts 2016/2017/2021. Built with scratchpad `build_plot2.py`
(parameterised, current schema) + `geo_plot2.py` (reuses the SRER AOP tiles, re-cropped to 056's centre; georef
validated — mean CHM under mesquites 2.03 m). **Honesty improvement over 048:** 056 carries the real `subplotID`
+ `growthForm` per measured plant (the three fields 048 flagged as a contract gap), so its **cover denominator is
PINNED from the records** — the four 100 m² nested shrub subplots NEON actually sampled (400 m²) — rather than
inferred. `assemble_plot.py` gained `--geo` to bootstrap a new plot's AOP layers and resolves the plot id into a
`__PLOTID__` title placeholder; the page carries a **plot switcher** (top breadcrumb: "also SRER_048/056",
relative in-repo, artifact URL when served). Live artifacts: SRER_048
https://claude.ai/code/artifact/acf46a2b-594f-4da6-ae59-be37dc57195e · **SRER_056**
https://claude.ai/code/artifact/fc6de1aa-76e8-4bf3-bef3-df371876f0fd . Committed: `plot-srer056.json` + the
self-contained `plot-srer056.html`. Rebuild: `python3 assemble_plot.py --plot SRER_056 --out plot-srer056.html`
(reuses 056's geo from the committed page). The 048-only assumptions (title, About heading, plot row, the
"shaded area" survey note) are now all data-driven so nothing on 056 mislabels it as 048.

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
- **"5 of 179 whole plants dead"** conflated assessed with unassessable: 75 plants carry no VST
  apparent-individual record and are live by construction. Now **"5 of 104 assessed"**.

**Also fixed in this rung.** A genuine honesty-rail break: **NIWO** (tundra bucket, `ba` 31.1 m²/ha)
rendered treeless while its caption claimed "built from … measured standing wood" — the tundra branch
never reads `ba`. The claim is now made only when the bucket actually used the measurement, and the
unused figure is disclosed instead of asserted. Plus: **no page had a `<meta name="viewport">`**, so
every responsive rule was dead on real phones (mobile browsers laid out at ~980 px and scaled down);
added, along with the `<meta charset="utf-8">` all three pages were missing. `assemble_plot.py` read
and wrote with the platform's locale encoding and newline translation — on this Windows host that is
cp1252 + CRLF, which would corrupt the UTF-8 text and violate `.gitattributes eol=lf`; now explicit.

## Rung 21b — the protocol review (and the caveat it reversed)

Rung 21 shipped a caveat calling The Plot a "two-bout composite, not a census," reasoning that pooling the
2016 and 2021 survey campaigns violated the sibling's rule against pooling repeated events. **That reasoning
was wrong**, and a review against the published NEON VST protocol (NEON.DOC.000987, the DP1.10098.001 user
guide, and the Cactus SOP NEON.DOC.001715) reversed it. Recorded here because the mistake is more instructive
than the fix.

**The misread.** `vst_mappingandtagging` is a *one-row-per-individual tagging table*: its date is when a
plant's tag went on, not when the plot was visited. Plants are tagged once and re-measured in later bouts.
So grouping 179 individuals by that date can never show the same plant twice — the "zero overlap between two
disjoint cohorts" that looked like a finding is **arithmetically forced by the table's structure**. It is a
diagnostic that the wrong column was joined, not evidence about the vegetation.

**What the two groups actually are.** First-tag cohorts under *different survey scopes*:

| tag date | n | measured | what |
|---|---:|---:|---|
| 2016-10-26 | 83 | 81 | creosote + mesquite — the woody bout |
| 2021-10-13/14 | 21 | 21 | more woody |
| **2021-04-27** | **6** | **0** | Engelmann prickly pear — the spring *Opuntia* campaign |
| **2021-10-18** | **64** | **0** | cholla, barrel, pincushion, saguaro |

Every cactus carries a 2021 tag and **no** structural measurement. That is protocol: NEON's standard woody
protocol does not map cacti at all; Santa Rita (Domain 14) has a written site-specific exception to *map*
large-stature cacti, which postdates the 2016 bout and needs its own spring visit; and cacti are *measured*
under a separate Cactus SOP into a different table. A saguaro is decades old — it did not arrive in 2021.

**Three shipped claims corrected.** "75 plants (the cacti)" → **70 cacti + 5 woody**. The "9 species"
headline → 9 *mapped*, but **2 → 4 among measured** species. And the condition on screen is roughly a **2021
snapshot**, not the tag year: 2016-tagged mesquites carry basal diameter, but SRER only measured mesquite
that way from 2020 onward, so the build joined each plant's latest record.

**The fix in the UI.** The "Survey: 2016+2021" control — which invited exactly the recruitment reading the
protocol forbids — is now **"First tagged"**, and narrowing it raises a note explaining that no plant can
appear in both years and that a plant missing from a year was not absent, just not yet tagged. The cover
figure is additionally marked approximate: its 790 m² divisor is the bounding box of the mapped plants, not
NEON's recorded sampled area, which makes it a lower bound and the percentage an upper bound.

**Still UNKNOWN, deliberately.** Growth, survival, true recruitment and the recorded sampled area all need
`vst_perplotperyear` and `vst_apparentindividual` keyed on `eventID` — neither is committed here. The page
says so rather than guessing.

## Rung 22 — the index explorer, pass 1

A seven-lens audit found the index was not an outline but **a finished shell around an invented
middle**: `FEAT` hand-wrote prose and 12-month rain/green/animal curves for 3 sites, `BIOME` supplied
5 canned templates for the other 43. So the hero and year wheel carried no site-specific information
for 43 of 46 sites — all 26 forest sites shared one sentence — and `select()` printed that sentence
**twice on the same screen**.

**Two honesty breaks, both fixed.**

1. Driver cards drew a **solid** bar of width `|r|` and labelled the p-value **"confidence"**. A solid
   bar reads as a firm result; a non-scientist reads "confidence 0.88" as 88% sure, which is close to
   the opposite. KONZ's first card has r = −0.22 over an interval of **−1.00 to +0.70** and drew as a
   confident bar 22% wide. The bundle carries a plausible range for all **162** links and **133 of them
   straddle zero** — none of which was visible. Replaced with a whisker on a zero-centred −1…+1 axis:
   hatched band lo→hi, dot at r, and a verdict word derived from the interval itself
   ("points one way" / "can't tell which way yet"). `p` moved to the drawer, relabelled
   *"how easily chance alone could produce a pattern this strong — higher means more easily."*
   Correcting a misread number teaches; hiding it does not.
2. The year wheel gave featured sites `"Rhythm sketch for this site."` instead of
   `"(schematic, not measured monthly data)"`. The page boots on SRER, so **the first wheel any
   visitor saw was the one missing its caveat**, and it said "for this site" — implying measured data.
   The bundle is annual; no month on that wheel was measured for any of the 46 sites.

**The wheel is cut, not captioned.** Removing it removes the break; captioning only manages it, and
hanging real units on fabricated rings would make it worse. Gone: the section, its CSS, `drawWheel`,
the player, and every invented month array and `thesis`/`rhythmText` string. **Kept:** the per-biome
colour palettes, which are design tokens, not claims.

**The hero sentence is now derived.** `siteAnswer()` reads the site's own intervals: it names the
strongest link whose range stays one side of zero, or says plainly that none is clean enough to call.
Across the 46 sites that yields 22 with a readable link, 23 honestly reporting nothing clean, and 1
(TEAK) with too little data — "an honest gap, not an empty place."

**The three pages are finally one journey.** `index.html` had **no reference to `plot.html` at all**,
and pinned the walk to a private `claude.ai/code/artifact/…` URL — so opened from the repo, the
prototype's own navigation did not work. Both now resolve **relatively**, falling back to the artifact
URLs only when actually served from that host. The dead `WALKABLE` list was replaced with the real
seven-site LiDAR set, and the walk link now states ground truth: *"this canopy is a real laser scan"*
for those 7, *"drawn from 5.1 m²/ha of measured wood"* for the 33 with a measurement, *"built from
ground cover"* for the 6 without. A second rung links The Plot, active on SRER (the default landing
site) and explicitly disabled elsewhere with "Santa Rita only, so far."

**Still to do** (from the audit, in order): the field card rebuilt from data for all 46; the masthead
orienting paragraph; the solid-vs-null result pair with map result-mode; the weather→plants→animals
chain from the 20 unused `signals`. Also unused and worth surfacing: `biome_class` (41
temperature-limited / 5 water-limited), `veg_ba_se`, `veg_design_status`, `lat`/`lon`, and
`network.null` — the matched null result (temp_spring→green-up, 8 of 18, p = 0.76) that proves the
test can fail.

## The goal, and the ladder

The target is **a production-ready product for Santa Rita** that works as the case for building
this across the whole NEON network. Not a prototype — a showcase whose job is to earn the
network-wide build. The ladder:

```
SRER_048 perfected → template → all SRER plots → site-level plan → [decision] → next site → network
```

Plot #2 is **another SRER plot**, so the hard things (camera, scale, species models, ground layers)
stay fixed and only plot geometry and the plant list vary.

**What step 2 actually is, measured from the Vegetation Structure bundle:** SRER has **38 plots with
VST data (~20,000 records)**, 20 distributed and 18 tower. SRER_048 is the richest of all 38 (2,121
records). Sampled areas **vary per plot** — trees 400–800 m², shrub 200–800 m²; SRER_048 is a tower
plot at 800/600 m². Plot geometry is therefore per-plot data, already available for all 38, and must
never be hard-coded. The bundle also carries `area_trees`/`area_shrub`, which is NEON's **recorded**
sampled area — the value that should eventually replace the inferred cover denominator.

**Two-channel data contract:** the woody plants come from the Vegetation Structure table; the cacti
do **not** — they are mapped under a site-specific exception and measured under a separate Cactus
SOP into a different table. SRER_048 has 179 mapped plants but only 114 appear in the woody bundle.
Any future build must pull both channels or explicitly account for the gap.

## Rung 23 — the production push

**The map is now a build registry.** All 46 sites still render — this is a case for a network-wide
build and hiding the other 45 would hide the argument — but only built sites are interactive, driven
by one object:

```js
var BUILT = { SRER: {plot:"SRER_048", plots:1} };
```

The map, picker, directory and `select()` all read it, and `select()` guards on it. **Activating the
next site is one line.** Unbuilt sites are drawn as scenery, not disabled controls: muted, no
`tabindex`, `role="img"`, and an aria-label saying why. A greyed-out button reads as broken software
45 times out of 46; a quiet dot on a network map reads as scope.

**The Plot now works on a phone.** Three independent failures: `pointer-events` sat on the *containers*,
so the control row swallowed drags and taps across most of the viewport while the hint said "drag to
pan"; the tap-vs-drag gate compared accumulated path length, which only grows, so a wobbling thumb
defeated it; and the overhead view could not be zoomed at all, because zoom was wheel-only and the
canvas sets `touch-action:none`. All three fixed, plus the description panel now starts collapsed
under 768 px.

**Seven peer buttons became four controls** — `[▣ Map | ▲ Walk in]`, `[Layers ▾]`, `[ⓘ Plot data]` —
with the legacy buttons kept hidden so every existing handler still works. The **First-tagged filter
moved into the data panel**, directly beneath the paragraph explaining that these are first-tag
cohorts and not re-surveys: it is the one control that invites a reading the data forbids, and its
caveat used to live in a `title` attribute touch users never see.

## The scale-out contract — read this before adding plot #2

Adding a plot should cost **one JSON file + one registry line + any missing species models.**
Anything more is a design failure to fix *before* plot #2, not during it.

**Data contract.** `plot-<PLOTID>.json` matching the SRER_048 shape: `plot, plotDim, ex, ey, n,
cover{...}, note, plants[], legend[], provenance{}`, plus `surveyNote` and `mappedExtent`. Rules:
1. **Optional fields must degrade, never crash.** `realh, stems, bd, cr90, shape, canopy, dmg` are
   absent on all 75 unmeasured plants and the renderer handles it. Absent fields must render as
   *not measured* — never as a ramp value. (This was a live bug: the colour modes were painting
   invented values for 42% of the plot.)
2. **`provenance` is mandatory**, and must carry `officialNeonRelease` even when the value is the
   literal `UNKNOWN`, with a `release_basis` saying why. The rail is *UNKNOWN and why, never nothing*.
3. **A species model per `taxonID`** must exist in `SP{}` or the plant falls back to a generic mound —
   and that fallback must be *labelled*, never silent. A second Sonoran plot reuses most of the 9
   existing models; a different biome needs a whole new family. **This is the real cost of plot #2.**
4. **A georeferenced AOP crop, or an explicit `null`.** The page now lands overhead either way.

**Already made data-driven (do not regress these).** Each was a latent honesty bug that would have
shipped a false sentence at plot #2:

| Was hard-coded | Now |
|---|---|
| survey-extent prose ("the eastern half") | `DATA.surveyNote` |
| unsurveyed shading inferred as always-west | `DATA.mappedExtent.xmin`, inference only as fallback |
| tag-year filter `["2016","2021"]` | derived from `plants[].date` |
| at-a-glance year tallies | derived per year |
| colour ramp domains 0.3–2.8 m, 1–20 stems | computed from the loaded plot *(this also fixed a real bug — stems actually reach 45, so multi-stem plants were saturating)* |
| cover caveat naming 790 m² and "western half" | assembled from `cover.surveyedArea` + `cover.denominatorBasis` |
| boot mode conditional on an aerial existing | always lands overhead |

**Freeze now.** One template file keyed by query string (`plot.html?plot=SRER_048`) — never a second
copy of the source; the control layout above; the `BUILT` registry as the single source of what
exists; and a plot-picker slot in the breadcrumb from day one, even while it renders as one item.

**Templating — where it actually stands.** `assemble_plot.py` now takes `--plot <ID>` (and `--out`),
so the build is no longer hard-wired to SRER_048: it resolves `plot-<id>.json`, refuses a mismatch
between the requested id and the file's own `plot` field, and fails cleanly if the data does not
exist. The page reads `?plot=<ID>` and **validates** it — if you ask for a plot that has not been
built, it says so rather than silently showing SRER_048, which would be the page lying about what
it is displaying.

What is *not* solved, deliberately: the page inlines **one** plot so it stays self-contained and
needs no network. Inlining all 38 SRER plots would add roughly 2 MB; generating 38 separate pages
would be roughly 37 MB, since each carries its own copy of Three.js. Neither is acceptable. **The
production answer is a shell page that fetches `plot-<ID>.json` on demand** (~54 KB each) — that is
a hosting decision, not a code one, and self-containment was a constraint of artifact hosting rather
than of the design. Take that decision before plot #2, not during it.

**Still to do before plot #2:** replace the inferred cover denominator with NEON's recorded
`area_shrub` (600 m² for SRER_048 — the value exists in the Vegetation Structure bundle); and a
keyboard path to the 179 records, since the payload is still reachable only by pointer.

## Lesson: syntax checking is not a boot check

Three separate runtime-ordering bugs shipped in one day, each of which left `plot.html` frozen on
"Reconstructing the plot…" — because the loading overlay is only hidden on the **last** line of the
script, so *any* exception anywhere leaves it up forever.

All three were `var X` declared **after** the top-level code that read it. `var` hoists as
`undefined`, so the read throws a `TypeError` rather than a `ReferenceError`, and — crucially —
`node --check` passes every time, because the **syntax is valid**. The bugs were:

| Symbol | Declared | First used | Introduced by |
|---|---|---|---|
| `SITENAME` | line 802 | line 774 | the breadcrumb |
| `TAGYEARS` | line 843 | line 436 | de-SRER'ing the tag-year filter |
| `SY` / `syi` | line 846 | line 531 | moving the filter into the data panel |

The pattern behind all three: `buildCover()` is an IIFE that runs **immediately**, near the top, but
kept acquiring references to things declared further down as the file grew.

`check_boot.js` exists because of this. It executes each page's authored script against a stub DOM
and a Proxy-based THREE, and fails loudly with the offending line. It found two of these three; only
the first was caught by hand. It cannot prove a page *looks* right — nothing renders — but it proves
the script runs to completion, and that is exactly the failure mode that had been shipping.

## The cover figure was wrong three ways — what replaced it

The published "~53.9% canopy cover" was wrong in a way that outranked the denominator debate, and the
fault was mine: **13.1% of the numerator was invented.** All 75 plants without a structural record
carry a *per-species constant* crown diameter — every one of the 53 Christmas cholla is exactly
0.7 m, every unmeasured mesquite exactly 3.2 m — distinguishable only by a missing `cr90`. The cover
sum gated on `status === "live"` rather than on whether a crown was actually measured, so those
defaults were summed as though they were data. This is the *same* bug recorded as fixed for the
colour ramps; it was never fixed in the headline number.

| | |
|---|---|
| measured woody crowns | **370.0 m²** (99 plants) |
| placeholder woody | 28.1 m² (5 plants) |
| placeholder cacti | 27.8 m² (70 plants) |
| **invented share of the published figure** | **13.1%** |

Two further errors, both confirmed against the protocol:

- **The denominator was a guess when it did not need to be.** 790 m² was the bounding box of the mapped
  plants. The real figure is **800 m² by design**: protocol Table 10 samples two of the four 20 × 20 m
  subplots of a 40 × 40 m base plot. The "unsurveyed western half" was the sampling design all along.
- **The caveat pointed the wrong way.** It said the divisor was a lower bound and the percentage an
  upper bound. That holds only for the tree channel; for a nested-subplot channel the sampled area can
  be *smaller* than the bounding box, so the published number could equally have been an under-estimate.

Now reported as a **crown area index in m²/m²**, never a percentage, with cacti held out as a count.

**Still unresolved, and stated on the page:** the 800 m² assumes the measured woody plants were searched
across the full selected subplots. If they came from nested subplots the denominator is smaller and the
index higher. Settling it needs `subplotID` per record — which the committed file does not carry.

**Contract gap that must close before plot #2:** no plant record carries `growthForm`, `subplotID` or
`eventID`. `growthForm` assigns the measurement channel and therefore which sampled area applies;
`subplotID`/`eventID` pins the denominator. Without them the same ambiguity propagates to 37 more plots.
NEON records these areas per `plotID` × `eventID`, they can be NULL when a growth form is not scheduled,
and at SRER *Prosopis velutina* changed channel in 2020 — so the channel must be read per record, never
per species. Recorded in the file as `contractGaps`.

## No-guessing audit — what remained, and what still needs raw NEON data

A full sweep for values or visuals not backed by real per-plant data. Three remained; two are now
closed, one cannot be without re-pulling raw NEON tables.

**Closed — 75 plants were drawn at species-typical sizes with no visual marker.** The 3D/map view sized
every plant from `p.h`/`p.cr`, but for 75 of 179 those are per-species *defaults*, not measurements
(`realh !== true`). They were disclosed on click ("~X m typical") and greyed in the colour modes, but
the default view drew them at full fidelity as if real. They now render as an **open ring** (measured
plants keep a solid disc), the About card introduces the distinction, and the at-a-glance panel states
"104 measured · 75 species-typical". Docs that claimed "sized by its real height/crown" for all plants
(build_plot.md, PROGRESS.md ×2) are corrected to scope it to the 104 measured.

**Closed — the "eastern half was not surveyed" framing was wrong and partly circular.** The eastern half
is the *sampling design* — NEON samples two of the four 20×20 m subplots of a 40×40 m base plot (protocol
Table 10), and `area_trees = 800 m²` confirms it — not a survey that skipped the west. And "eastern" was
inferred from where the plants sit, so it is stated as "where the two sampled subplots are", not asserted
as an independently verified selection. Reframed in `surveyNote`, `mappedExtent`, and build_plot.md.

**Open — needs raw NEON data I do not have.** The 800 m² denominator assumes the woody plants were
searched across the full selected subplots rather than nested subplots; if nested, the denominator is
smaller and the index higher. Settling it needs `subplotID` per record. More broadly, no plant record
carries `growthForm`, `subplotID` or `eventID` (the `contractGaps`), which assign the measurement channel
and pin the denominator. Closing these requires re-running `build_plot.py` — which needs the raw VST CSVs
and a NEON API token, neither committed. **This is stated as unresolved on the page rather than guessed.**
Until the raw pull is redone, the index carries its on-screen "unresolved" caveat and must not be
presented as settled.

## Files (all under `prototypes/site-explorer/`, outside the app's build surface)

- `index.html` — the main explorer (self-contained; `site-data.json` + `map-data.json` inlined; ~133 KB).
- `walk.html` — the 3D scene (Three.js r128 inlined; ~1270 KB; deep-linkable via `?site=CODE`, case-insensitive).
- `plot.html` — "The Plot", SRER_048 (self-contained; ~952 KB). Built from `plot.src.html` by `assemble_plot.py`.
- `export_data.py` — reads `data/cascade.rds` + `neon-site-names.json` → `site-data.json` (real science
  **plus the provenance receipt**: bundle SHA-256, build time, schema, and the seven source-product commits).
- `assemble_index.py` — re-inlines `site-data.json` + `map-data.json` into `index.html`. Idempotent;
  replaces only the two tagged block bodies. (This step used to be a manual paste, which is not a build step.)
- `assemble_plot.py` — re-inlines the scene template + committed JSON into `plot.html` (needs no raw data or token).
- `check_boot.js` — **runs each page's script for real** against a stub DOM and reports the first
  exception. `node --check` only validates syntax; this proves the script reaches its end, which is
  the difference between a working page and one frozen on its loading overlay. Run it before every
  commit: `node check_boot.js index.html walk.html plot.html`.
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
- **The Plot's dates are first-tag dates, and the two groups are NOT re-surveys.**
  `vst_mappingandtagging` holds one row per individual — the date its tag went on. A plant is tagged once
  and re-measured in later bouts, so grouping by that date *cannot* show the same plant twice: the zero
  overlap between the 2016 (88) and 2021 (91) groups is forced by the table's structure and is **not**
  evidence of recruitment, mortality or turnover. The control is labelled **"First tagged"**, and narrowing
  it raises an explanatory note. Never call these "survey campaigns" or "re-surveys."
- **The Plot may not claim recruitment, mortality, turnover, or rising richness.** NEON records death as
  `standing dead` / `lost, presumed dead`, never as an absent row, so a plant missing from a group is not a
  plant that died. And the species difference between the groups is survey *scope*: NEON's standard woody
  protocol does not map cacti at all, Santa Rita has a site-specific exception that postdates the 2016
  bout, and cacti are measured under a separate Cactus SOP into a different table. Among *measured* plants
  the species count goes 2 → 4, not 2 → 9.
- **Condition shown is roughly a 2021 snapshot, not the tag year.** 2016-tagged velvet mesquite carry basal
  diameter, but SRER measured mesquite at basal diameter only from 2020 onward (as a tree at DBH before) —
  so the build joined each plant's *latest* measurement. The tag year says when a plant entered the record;
  it does not date the measurements drawn on screen.
- **There is no cover percentage, and there must not be one.** The page reports a **woody crown area
  index — 0.46 m² of crown per m² of ground** (370 m² of measured crown over the 800 m² NEON searched,
  99 plants). Three independent reasons a percentage would be wrong: crowns **overlap**, so a sum is not a
  union; each crown is measured from its **two maximum diameters at right angles**, so the ellipse
  circumscribes an open desert crown; and the measurement "may include live and dead material". The
  denominator is **800 m² by design** — a 40 × 40 m base plot is sampled in two of its four 20 × 20 m
  subplots, randomly selected, and at SRER_048 those are the eastern pair. That is *why* the plants fill
  half the plot; it was never a survey gap. **Cacti are excluded** — NEON measures them under a separate
  Cactus SOP against a different sampled area, and at Santa Rita only large-stature individuals are
  mapped, so they are a mapped subset, not a census. They are reported as a count and species list.
- **This is a map of tagged individuals, not of every plant in the plot.** Saplings are never mapped, and
  a plant with no stem ≥ 1 cm basal diameter is outside this protocol entirely.
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
node prototypes/site-explorer/check_boot.js      prototypes/site-explorer/{index,walk,plot}.html        # -> must print BOOT OK for all three
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
