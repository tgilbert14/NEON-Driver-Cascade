# HK statistical review — NEON Driver Cascade (2026-06)

The HK statistics suite (Desert Data Labs) audited this app, **Cass signed off** on every
inference-touching change, and the edits below were applied. **R could not be executed in
the review environment**, so every change is reviewable-by-reading and needs the rebuild +
visual smoke test in "Verify" before deploy.

## Headline

The app is already statistically careful and most HK "findings" were either **already
implemented** (the circular-shift permutation null `perm_p_circular`, the `pooled_links`
`min_sites=3` floor, `assert_unique_year` + `relationship="one-to-one"` joins, the Lag
Experimenter's best-of-K Šidák) or **already honest** (no fabricated zeros — the `full_join`
leaves not-sampled cells `NA`, never `0`). Cass flagged that the frequentist reviewers had
read a stale copy. The applied changes are the genuinely-open, Cass-approved items.

## Applied changes

### Inference (Cass-approved)
1. **Demote prior #6 `fruiting_pct → mammal_cpue` to display-only.** `build_cascade.R`
   priors table: `expected_class` `"all"` → `"none"`. A coarse peak-intensity proxy the note
   itself calls "suggestive only" should not cast a sign-vote in the pooled tally, and `"all"`
   wrongly pooled it over mesic sites (its mechanism is the water-limited monsoon-seed
   pathway). Now computed + shown (dimmed) in Driver Lab, **excluded from every sign-match and
   the pooled binomial.** *Requires rebuild.* Cass: "small numeric change, strictly-more-honest."
2. **Two-register Overview hero.** `server.R` `verdict_sentence()`: a desert landing page now
   **leads with the one result that survives cross-site pooling** (warmer springs → earlier
   green-up, k/sites + pooled p, read live from `POOLED`), **then** the SRER seasonal-split as
   the app's core insight, hedged ("a single desert, suggestive, not yet established"). Default
   site stays SRER. Cass: "neither buries the other."
3. **Space-for-time caveat on the pooled headline.** `server.R` `pooledHeadline`: added
   Damgaard-2019 wording stating the pool substitutes space for time, assumes one shared
   mechanism across sites, pools sign-agreement (the conservative form) not effect sizes, and
   "remains an assumption, not within-site replication." Cass tightened the wording; the last
   clause is load-bearing.
4. **First-difference companion (shared-trend check), n≥8 only.** `server.R` `linkScatter`
   stat box: when n≥8, shows the year-to-year *change* correlation alongside the level r. Agreeing
   in sign → survives detrending; disagreeing → flags a possible shared trend. **Diagnostic, never
   a verdict input;** suppressed below n=8 (differencing burns a df). Cass: companion only, gated.

### Accessibility / visualization (Tufte)
5. **Scoreboard verdict is no longer colour-only (CVD fix).** `server.R` `scoreboard`: each
   grid cell now carries a tier **glyph** (✓ consistent · ≈ apparent · ✗ counter · · <6yr) so the
   verdict survives red-green colour blindness; the legend keys carry the glyphs too. This was
   the single worst accessibility gap (teal/coral on a dense grid).
6. **Ladder lines show their n.** `server.R` `ladderPlot`: each trace name + hover now reads
   `Signal (n=K)`, so a 3-year z-line and a 12-year one are not read as equally solid.

### Build robustness (Hadley / Joe)
7. **Fail-loud `CASCADE_ROOT`.** `build_cascade.R`: `stop()` if the root dir is missing, instead
   of silently shipping an empty bundle (the CI-killer).
8. **Build-time coverage guard.** `build_cascade.R`: `stopifnot(setequal(suite_links$site,
   annual$site))` so a site missing from the precompute fails the **build**, not the user (it would
   otherwise trigger the live-permutation `site_links_cached` fallback on the reactive path).
9. **Loop-variable rename** `for (c in …)` → `for (col in …)` (×2): removes a latent `base::c`
   shadow.

### New companion (Stan + Cass)
10. **`scripts/cascade_meta.R`** — a random-effects meta-analysis (Fisher-z, `metafor::rma`;
    optional `brms`) of the **green-up rung only** (the ~32-site rung where I²/τ² are estimable).
    Gives a pooled effect size + P(direction) + heterogeneity test as a **companion** to the
    binomial headline. **Explicitly NOT run on `mammal_cpue`/`bird_index`** (too few sites; the
    sign test is the honest read), and `conf` is **not** used as a prior. Output: `data/cascade_meta.rds`
    for an About>Methods panel (wiring it into the UI is a follow-up).

## Verify (R could not run here — do this before deploy)

```r
# 1. Rebuild the bundle (changes #1 / #7-9 only take effect after this):
Rscript scripts/build_cascade.R
#    Expect: the pooled headline unchanged for green-up; the fruiting→rodents link
#    GONE from any site's tally and from `pooled`; the stopifnot passes.

# 2. Smoke-test the app:
R -e 'shiny::runApp(".", port = 8194)'
#    - SRER Overview hero LEADS with "warmer springs → earlier green-up at N of M sites"
#      then the desert story.
#    - Across NEON: the scoreboard cells show a glyph (✓/≈/✗) + r; the space-for-time
#      caption is under the pooled headline.
#    - Cascade Ladder legend reads "Signal (n=K)".
#    - Driver Lab scatter on a long series (n≥8) shows a "year-to-year change: r=…" line.
#    - VISUAL CHECK: confirm the scoreboard cells are not cramped by the glyph; if they
#      are, shrink the cell font or move the glyph to a CSS ::before — it is the one
#      change whose look I could not see.

# 3. The companion meta-analysis (optional, needs metafor):
Rscript scripts/cascade_meta.R
```

### Round 2 (also applied — Hutch + Stan)
11. **Hill diversity profile (q0/q1/q2).** `build_cascade.R` `ann_plant` now computes `plant_q1`
    (exp-Shannon) and `plant_q2` (inverse-Simpson) effective-species Hill numbers from cover shares
    (manual formulas, **no vegan dependency**, manifest stays lean); added to `signals` (descriptive,
    ladder=FALSE, no prior so no tally change), the codebook, and a new **Diversity profile** panel
    (`output$hillProfile` → the Overview "What's measured here" card, reusing the orphaned `.hill-tile`
    CSS). Surfaces the q0-vs-q1/q2 gap that says "a few species dominate, so richness overstates
    diversity." *Requires rebuild.* (Hutch.)
12. **Meta-analysis wired into About → Methods.** `aboutPanel` now reads `data/cascade_meta.rds` and
    shows the green-up companion (pooled r, P(direction), I²) when present, with a graceful "run
    `scripts/cascade_meta.R`" note when absent. Companion framing, never the headline (Stan + Cass + Few).

### Round 3 — the "no consistent cells" investigation (Cass ruling 2026-06)
A user noticed the Across-NEON grid had **zero ✓ "consistent" cells** (and JORN no sign-match p). Investigated in R:
- **JORN is correct** — it has 12 years but **zero testable (n≥6) expected links** (sparse tower precip; its one n=5 link is exploratory). Not a bug; Cass had flagged JORN/YELL as untestable.
- **The "consistent" tier was a real problem.** The deployed bundle had 7 "consistent" cells that were **artifacts of an older i.i.d.-shuffle null**, never rebuilt after the code switched to the circular-shift null. Under the honest circular-shift null, the smallest possible p is **1/n**, so at n≤11 **no single site can reach p<0.05** — "consistent" (gated on p<0.05) was mathematically unreachable, which clashed with the whole app's copy ("clears the permutation null", "green columns mean the mechanism holds").

**Cass's ruling, implemented:** keep the honest circular-shift null and its 1/n floor; do **not** re-gate significance onto the shaky bootstrap CI. Instead, demote the per-site tiers to honest **direction** verdicts. The "consistent" key now means **ALIGNED**: `sign_match AND bootstrap-CI-excludes-zero` (p reported for transparency, **never gates the tier**). All significance language now points at the pooled binomial. The SCBI "p=0.007" claim (an i.i.d.-null artifact) is replaced by its CI [−0.99, −0.28]. Added a **stale-bundle guard**: a `TIER_RULE_VERSION` stamped into the bundle that the app **boot-checks** (refuses to start on a mismatched/stale tiered bundle).
- Verified after rebuild: **14 aligned cells** (honest, CI-based), SCBI is `aligned` via its CI, the **pooled headline is unchanged** (23/32, p=0.010), the boot-guard passes, and all renders execute at SRER/SCBI/JORN.

> **This whole review WAS verified in R 4.5.2** (found at `C:\Program Files\R\R-4.5.2`): all files parse, the build runs clean (`stopifnot`s pass), Hill q1/q2 compute (430/509), the meta companion yields P(earlier green-up)=0.975 I²=0%, and every render executes via `testServer`. The "Verify" commands below remain the recommended pre-deploy smoke test for the live visual look.

## Deferred (recommended, not yet applied)
- **`n_eff`/lag-1 ACF as display metadata** on the verdict chip (Cass: show, never feed into the p).
  Low value; skipped to avoid chip clutter (Few).
- The Bayesian `brms` companion is gated behind `options(cascade_meta.run_brms=TRUE)` — run it
  once converged numbers are confirmed (Rhat/ESS/divergences) before surfacing any P(direction).
- A `precip_winter → plant_q1` prior (test diversity against q1 not raw richness) — would change the
  tally, so it needs Cass sign-off before adding; `plant_q1` ships descriptive-only for now.

Reviewed by the HK suite (Hadley, Tukey, Fisher, Stan, Hutch, Tobler, Tufte, Joe, Few) with
domain sign-off from Cass.
