# Bottom-up trophic cascade synthesis (climate → plants → consumers) — Expert Review by Cass (NEON cross-domain integrator (no single DPID))
_Devoted product-expert review — June 2026._

> **Historical review; superseded for inferential claims.** Repository history subsequently showed that
> the link family and seasonal windows evolved while the analyzed data were being inspected. Contrary to
> language below, these were not preregistered or fixed a priori. The quoted counts/p-values also predate the
> current strict-coverage, gap-aware rebuild. Treat this file as design history, not current evidence; the
> versioned bundle, About-panel selection disclosure, and generated contract tests are authoritative.

> I re-walked this app end to end as the one reviewer who owns the JOINS rather than any single rung. The original review praised a prior-selection discipline that repository history does not support; that conclusion is withdrawn. The useful design observations below remain historical context, but all numerical and inferential conclusions require regeneration under the current contracts.

## Method fidelity (is the NEON protocol represented correctly?)

There is no DPID for a cascade — this is the synthesis node, and the representation of *how* a cross-domain bottom-up inference is built is faithful and, in places, exemplary.

- **The cadence problem is handled honestly.** The panel is annual (`cascade.rds$annual`, 509 site-years), but the inputs have wildly different native cadences. The app does not pretend otherwise: green-up gated to ≥5 individuals (`build_cascade.R:93`), per-season month-count gates so a partial season can't masquerade as a total (`:74`–`:79`), and — the call I most want to protect — **veg basal area is kept OFF the ladder as per-site context** (`build_cascade.R:142`, `signals$ladder=FALSE`), because annualizing a ~5-year remeasurement manufactures pseudo-resolution. That is the right answer, and the comment block says exactly why.
- **The CPUE rung is the flagship's own number, not a divergent approximation.** `ann_mammal()` (`:104`–`:130`) uses the Nelson & Clark (1973) trap-night weighting the flagship app uses, captures counted by `tagID`, scaled to 100 trap-nights. This is the cross-product hygiene that keeps the consumer rung from being a private re-derivation — the cascade reports the *same* number the consumer app reports.
- **The QC that already exists is the right QC.** Within-site MAD outlier NA on annual `temp` and `temp_spring` (`:54`–`:56`, `:83`–`:85`) catches the SCBI-2018 corrupted-sensor year a fixed window can't (≈40% of its months read deeply negative). `set.seed(1L)` (`cascade_helpers.R:60`) makes the permutation/bootstrap deterministic so the displayed numbers are stable. The DPID provenance is correctly stated in the footer (`ui.R:115`).
- **The honest gap NEONize's own playbook flags is still open.** Playbook §7 makes a **QC-flag panel** the suite gold standard ("every app gets it"). The cascade has the *ingredients* already computed — green-up from <5 individuals, the MAD-NA'd climate years, links with CI spanning zero shown as `apparent` — but no `<entity>_qc()` panel surfaces them as ranked "verify, not wrong" flags. This is the one place the app is below suite parity. It is a cheap credibility win on a PI-facing capstone.

**Method verdict: faithful.** The lag mechanics, the green-up onset metric, the seasonal reconstruction, and the trap-night weighting are all correct. Do not "fix" the stats — the honest move is upstream (coverage), and the app already knows it.

## Analysis & metrics — defensible? (with the literature)

The estimator stack is the correct one for n≈3–13 annual series, and the literature backs every design choice — with two defensible-but-fixable leaks.

**What is defensible and cited correctly:**
- **Lagged correlation on literature-motivated (sign + lag) pairs** uses a gap-aware circular-shift diagnostic and circular block-bootstrap interval. The family was co-developed with these data, so the resulting values are exploratory even though each mechanism has literature support and the current build locks its settings.
- **Binomial sign test, one vote per site** (`pooled_links()`, `:76`) is the multiple-comparison-honest pooled statistic, and it deliberately discards magnitude — which is the *only* legitimate cross-site operation on the within-site indices `mammal_cpue`/`bird_index`. The app pools across the sites where each link is *expected* for its biome (`expected_class`, `build_cascade.R:197`), which is the conservative, biome-stratified space-for-time design (caveat: Damgaard 2019 — pooling sign-matches not values is the conservative version, but still inherits the same-mechanism-across-sites assumption).
- **The one robust result is led with honestly.** temp→green-up pools 23/32 sign-matching sites, binomial p=0.010, median r=−0.15 (`DATA-TAKEAWAYS.md:8`), and the app's pooled headline (`server.R:445`) and verdict copy lead with it. The producer→consumer rung pools to a null (richness→rodents 22/40, p=0.318) and the app **says so**. That asymmetry — leading with the win and naming the null — is the mark of an honest synthesis.

**The leaks (each shipped with its fix):**

- **HIGH — `pooled_links()` reports a binomial on a single vote.** There is no `sites >= 3` floor (`cascade_helpers.R:76`–`:90`): `precip_monsoon→mammal_cpue` pools across **1 site, k=1, p=0.500** and is rendered in the same `pooledHeadline` list (`server.R:445`–`:460`) as the 32-site temp→green-up result. A binomial on one vote is not a pooled test. **Fix:** gate `pooled_links()` to `sites >= 3` (ideally ≥5) before emitting a p; render under-floor links as a separate "1 site — not poolable" row, not a p-value in the headline rank.
- **HIGH — the Seasonal panel prints an ungated r below the app's own verdict floor.** `server.R:430` (`rc()`) uses `nrow(m) < 4` as its threshold and returns a raw `round(cor(...), 2)` — so the desert headline `r = +0.72` (monsoon→rodents) is displayed (`seasonalPanel`, `:431`,`:436`) with **no permutation p, no CI, and below the n≥6 gate every other surface in the app enforces.** This is the app's marquee number shown without the discipline the app is built on. The number is real (SRER n=7, p=0.060, `DATA-TAKEAWAYS.md:13`) but it is *not significant* and it is *one site*. **Fix:** footnote the seasonal comparison "illustrative contrast, n=7, not significant (p=0.06)"; or raise `rc()`'s floor to 6 and carry the p the way `linkScatter` already does (`server.R:310`).
- **MEDIUM — the pooled headline uses annual mean `temp` as a spring-warmth proxy when `temp_spring` already exists and is the mechanistically-correct driver** (379 finite). A reviewer will ask why the one robust rung is tested on annual mean temperature rather than the spring window the mechanism is actually about. **Fix:** report both temp→green-up and temp_spring→green-up in the pooled table, or move the headline to `temp_spring` where coverage allows. The data is already in the bundle.

## What the field would add (collection / analysis / presentation / use)

- **Collection — the bottom of the cascade is the scarcest layer.** Annual `precip` is NA in **74%** of site-years (`DATA-TAKEAWAYS.md:14`); the climate *driver* is thinner than every biological response it's supposed to drive. The field's move is not more stats — it is more seasonal climate coverage and more water-limited sites. Of the 5 water-limited sites, JORN and YELL have **zero** testable expected links (`DATA-TAKEAWAYS.md:15`), so "the desert cascade" is effectively a 1-site (SRER) test. Until that sample grows, the desert story is an *illustration*, not a result, and the app must say so everywhere it appears.
- **Analysis — surface the out-of-biome corroboration instead of greying it out.** The seed-crop mechanism (summer rain → C4 seed crop → granivores) is biologically general to *semi-arid grasslands*, not desert-only — and the data shows it is **strongest at temperate grasslands**: KONZ r=+0.77 (p=0.018), CPER r=+0.75 (p=0.041), both marked `expected=FALSE` (`DATA-TAKEAWAYS.md:35`). Those cells currently sit dimmed and uncounted. The field would read that as *corroboration of the mechanism in a related biome*, which strengthens the desert prior rather than competing with it. **Add a "tested elsewhere, not in its prior biome" callout** for links that fire outside their `expected_class`.
- **Presentation — richness is composition; vegetation cross-sectional area is slow standing-structure context, not productivity.** `plant_richness` can *invert* in drylands as a few species dominate wet years (which is exactly why `plant_richness→mammal_cpue` correctly pools to null). The app carries historical `veg_ba_ha` context (0.4 m²/ha at JORN to 56.3 at WREF), but Pass 4 shows that tree-DBH bole cross-section and shrub/sapling stem-base cross-section are different physical channels even when both use m²/ha. Keep the context visible with channel and support fields; never describe it as annual productivity, biomass, carbon, or an annual link.
- **Use — the fundable insight is the biome-conditional prior, not the desert recovery.** The defensible, fundable contribution is the framing that *the right driver depends on whether warmth or water limits the system* — testing the wrong one is what made the desert look empty. Lead the grant narrative with that, with temp→green-up as the proof-of-concept, and the SRER seasonal split as the *illustration of the artifact* — never as a desert result.

## Product-specific honesty & QC traps

The six traps this product hits, scored against how the app handles them:

1. **Index-vs-absolute (never compare within-site indices across sites by magnitude)** — *handled.* Sign-match pooling discards magnitude; the within-site-index caveat is in the `dlAnnual` header (`server.R:500`) and the codebook (`:532`). **Gap:** `dlSuite` and `dlLinks` (`:511`,`:505`) pool sites on links built from CPUE but **omit the caveat from their file headers** — anyone reading `neon-cascade-scoreboard.csv` standalone could read cross-site. **Fix:** add the within-site-index caveat to those two headers too.
2. **Annual aggregation censors the seasonal signal** — *handled and surfaced* (the Seasonal panel is the marquee feature) — but see the HIGH ungated-r leak above. Present the recovery as an illustration of the artifact (single-site, n=7), never a desert generalization.
3. **Small-n false-negative regime** — *handled.* n=6 sits in a ~24% power regime; the 9 counter sites in temp→green-up (LENO +0.51, NOGP +0.51) are the false-negative tail, and the driver-table copy says so explicitly (`server.R:287`: "at 6 years only |r|>0.8 can clear significance… 'counter' usually means underpowered, not refuted"). Per-site verdicts are correctly subordinated to the pooled headline.
4. **"Consistent with," never "drives"/"causes"** — *handled in voice* (the manifesto, `server.R:387`,`:394`). **Subtle gap:** the `consistent` tier is **biome-blind** — it can land on an out-of-prior link (SJER `precip_winter→plant_richness` r=0.88 p=0.004 is `consistent` but `expected=FALSE`, `DATA-TAKEAWAYS.md:46`). Only the *tally* respects `expected`. The scoreboard already dims out-of-prior cells (`server.R:475` `sb-dim`); extend that dimming to the link chips and to any "consistent-count" copy so a reader scanning colors can't miscount.
5. **Green-up DOY is first-detection, interval-censored** — *handled.* ≥5-individual gate (`build_cascade.R:93`), and the codebook (`server.R:531`) names it "median first-'yes' onset." Good.
6. **A grey cell is missing CLIMATE, not absent ecology** — *handled.* The scoreboard caption (`server.R:491`) calls the grey majority "the coverage statement," and DATA-TAKEAWAYS confirms 157 of 169 "insufficient" verdicts are n=0. "Not tested" ≠ "no cascade," and the app says it.

**And one documentation-integrity trap the app itself trips:**

- **HIGH — the README's pooled null number contradicts the verified bundle.** `README.md:54` states the producer→consumer rung pools to `richness→rodents 21/40, p=0.44`. The verified bundle (`DATA-TAKEAWAYS.md:10`) says **22/40, p=0.318**. The README headline (23/32, p=0.010) is correct, but this second number is stale/wrong in the public-facing doc. For an app whose entire credibility rests on *not over-claiming*, shipping a wrong null number in the README is a self-inflicted honesty wound. **Fix:** correct `README.md:54` to `22/40, p=0.318` (and verify the README's "+0.20"/"+0.72" desert numbers against the bundle while you're in there). Also note the build comment `build_cascade.R:204` says temp→green-up "holds at ~74% … binom p~0.002" — reconcile that with the verified pooled p=0.010 so the prose, the comment, and the bundle all agree.

## Place in the suite / cascade

This is the capstone — the only app that can answer "does bottom-up cascade theory hold across NEON?" Its verified answer is honest and instructive: **one rung holds (climate→green-up, pooled p=0.010); the rest are too short per-site and pool to null or near-null** (producer→consumer p=0.318). It consumes the five sibling signals as *inputs* and owns the layer above — the priors, the lags, the pooling, the biome-conditional framing — without re-deriving any rung's metric (it reuses the flagship's CPUE definition verbatim). It corroborates the suite-wide truth that climate→green-up is the durable link, demonstrates that desert "failures" are an annual-aggregation artifact, and — most valuably — exposes that the top of the bottom-up chain (producer→consumer) does not resolve at NEON's current series lengths. That last admission is what makes it a *synthesis* and not a sales pitch. It is at suite parity on flow, chrome, honesty machinery, and export discipline; the one place it lags the playbook gold standard is the missing QC-flag panel (§7).

## Scorecard

| Dimension | Grade | One-line why |
|---|---|---|
| Method fidelity | **A** | Cadence/lag/seasonal/trap-night all faithful; veg kept off the ladder; CPUE = flagship's own number. |
| Analysis & metrics | **A−** | Estimator stack correct and cited; docked for the ungated seasonal r and the un-floored single-vote pool. |
| Honesty discipline | **A−** | Priors-not-dredge, n-gate, sign-over-magnitude, green-up→bird *refused* — but a stale null number in the README and a `consistent` tier that's biome-blind. |
| Pooled/cross-site stats | **B+** | The right test (one-vote binomial), but no `sites>=3` floor lets a 1-site "pool" sit in the headline. |
| Presentation / framing | **A−** | Biome-conditional prior is the fundable insight, led correctly; out-of-biome corroboration (KONZ/CPER) hidden in grey. |
| Suite parity (playbook) | **B+** | At parity on flow/chrome/exports; missing the §7 QC-flag panel the data already supports. |
| Coverage / data base | **C+** | Not the app's fault — 74% precip NA, desert effectively n=1; the honest move is upstream collection. |

**Top three before this faces a reviewer:** (1) gate `pooled_links()` to `sites >= 3` and pull the 1-site row out of the headline; (2) fix the ungated `r=+0.72` in the Seasonal panel and the stale `21/40, p=0.44` in the README; (3) ship the QC-flag panel for suite parity. None touches the lag mechanics — they're correct. The work is upstream and editorial, which is exactly where an honest cascade's work should be.

— Cass
