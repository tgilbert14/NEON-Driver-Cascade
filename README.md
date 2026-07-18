# NEON Cross-Product Response Atlas

> **Explore:** [Launch the hosted atlas](https://019ee1cf-a484-44eb-a181-cd495df24b3b.share.connect.posit.cloud/) · [Project home](https://tgilbert14.github.io/NEON-Driver-Cascade/) · [Repository](https://github.com/tgilbert14/NEON-Driver-Cascade)

The **capstone** of the NEONize family — an exploratory cross-product atlas of direct weather–response associations.
The suite has nine product apps. This current baseline consumes seven of them
(small mammals, breeding birds, plant diversity, vegetation structure, plant
phenology, mosquitoes, and ground beetles); water chemistry and aquatic
invertebrates remain future review inputs. The atlas **lines those seven inputs
up** at shared field sites on a common annual calendar.

> **Construct warning:** the current measurements do not supply a defensible annual production/seed-resource rung or
> a mediated-path test. The layered display is a co-display of candidate bottom-up pathways, **not a tested trophic cascade**.

> **Design history and future requirements:** [`docs/CASCADE-ROADMAP.md`](docs/CASCADE-ROADMAP.md) is
> a historical expansion roadmap, not current product documentation. Its older chain proposals are
> retained to show what would have to be remeasured and prospectively registered before any future
> sequential or mediation analysis could be defended.

## Why it's careful (and what it refuses to do)

Each NEON site currently has only 8–13 annual rows, while link-specific usable overlap can fall to 3–11 years. At that length a lag-aware correlation scan
finds spurious signals everywhere. So the design is deliberately conservative — grounded in a
literature review of bottom-up driver ecology and short-time-series statistics:

- **Literature-motivated, build-locked, and explicitly exploratory.** Every scorecard link has a
  literature-motivated **sign + lag**, and the current interface locks those settings while it runs.
  Repository history shows, however, that the family evolved while these same data were being inspected;
  it was not preregistered. The estimates and p-values are therefore exploratory association screens,
  not confirmatory tests. The app shows literature-motivated pairings only where their measurement limits
  can be stated honestly; for example, it posts no green-up→bird-abundance direction because trophic-mismatch
  studies do not supply one for this detection index. The Lag Explorer's max-statistic adjustment limits
  the additional lag/season search in the current interface, but cannot undo that historical selection.
- **n-gated.** Below **6 overlapping years** no verdict is given — just the aligned series.
  At n≥6 a **circular moving-block bootstrap CI** sets the per-site direction verdict; an exact
  calendar-gap-aware circular-shift p is reported for transparency but does not set the tier. Its
  link-specific finite-randomization floor is **1 / (`n_null` + 1)**; the app exports `n_null`, `p_floor`,
  and full calendar span so missing years cannot masquerade as adjacent observations.
- **Direction over magnitude.** The cross-site association summary gives one raw-level vote per testable
  site for each of the two vote-eligible temperature–green-up rows, under an explicit (and imperfect)
  site-independence assumption. Its exact-binomial p is one-sided against 0.5 sign symmetry; the table also
  reports Holm familywise and Benjamini-Hochberg FDR adjustments. A within-site multi-link tally is descriptive
  only because links at one site reuse drivers and responses. A spatial sensitivity collapses the identical
  raw vote population to one majority per NEON domain (50/50 domains abstain), without adding another p-value.
- **Machine-readable selection disclosure.** Every bundle records a versioned prior-family status:
  literature-motivated and locked for that build, but historically co-developed with the analyzed data.
  A future confirmatory analysis would need an immutable registry and genuinely held-out observations.
- **Snapshot-aware phenology.** Both green-up constructions are retrospective full-panel standardizations:
  recurrence/connectivity gates, species centers, and additive year effects are refit when the eligible panel
  changes. A refresh can therefore revise historical index values rather than only append a year. Source and
  bundle hashes make each published snapshot exactly auditable; neither index is a prospectively fixed annual reading.
- **Never "drives," "causes," or "the cascade holds."** A handful of annual points cannot establish
  causation or mediation. No SEM/path model, no naive year-pooling, and no inference from visual arrow order.

## Conditional grouping rule (an explicit sensitivity, not a measured biome class)

Sites retain a deliberately visible descriptive grouping based on a **keyword heuristic over the one-line
site description**: descriptions containing `desert`, `sagebrush`,
or `semi-desert` enter the dryland-keyword group; every other site enters the default other-site group.
The legacy internal keys remain `water-limited` and `temperature-limited`, but they must not be read as
measured aridity, resource limitation, or a validated biome classifier. Dry forests, semiarid grasslands,
Mediterranean sites, and mixed sagebrush–conifer sites can be misgrouped. The bundle stores both the
assignment basis and the exact rule. The current vote-eligible temperature–green-up associations include all
sites rather than conditioning their p-values on this heuristic; non-green-up links are contextual only.

Seasonal climate windows (winter Oct–Mar, monsoon Jul–Sep, spring temperature Mar–May) are reconstructed
from complete monthly overlays because annual aggregation can blend distinct periods. A named window is
still only a proxy: unless a response is calculated over the same dates, the app does not call it a
same-season or mechanistically direct test.

## Tabs
- **Overview** — what is measured, which direct associations are actually vote-eligible, and the construct warning.
- **Layered Timeline** — standardised (z-scored) annual signals co-displayed by measurement layer; direct-link
  cards keep visual patterns separate from tested pairings. At dryland-keyword sites, a **Seasonal Climate**
  panel compares annual, winter, and monsoon associations that an annual total can blur.
- **Driver Lab** — pick a response; every current build-locked literature-motivated pairing is screened, with the
  aligned-pairs scatter (now carrying its **r / n / p / 95% CI on the figure**) and a tier-honest fit line.
- **Across NEON** — the scoreboard: each vote-eligible link **pooled across sites** (one vote per
  testable site) + a site × link grid encoded by glyph and colour, with context-only and under-supported
  rows shown rather than hidden.
- **About** — the full current pairing table + the honesty manifesto + selected references.

### What it surfaces
Exact counts and p-values are generated from the committed bundle and shown in the app rather than copied
into hand-maintained prose. This matters because coverage gates and monthly source refreshes change the
denominators. The pooled table separates vote-eligible rows from pairings that are context-only by design;
the latter are not merely under-supported and cannot become inferential through more years alone. It reports
raw, Holm-adjusted, and FDR-adjusted values plus detrended, consecutive-year-change, and alternate
composition-standardization direction sensitivities. The annual-temperature and March–May-temperature green-up screens are presented together;
neither climate proxy is guaranteed to precede the onset observations.

#### Seasonal aggregation comparison (single-site, non-pooled diagnostic)
The seasonal desert comparison is an illustration, not a pooled result. Its current r/n/p values are read
from the same cached link rows as the plots; they are never hard-coded in prose. Raw plant richness is now
explicitly effort-confounded context (`expected_class='none'`), not a vote: the bundle persists sampled plot
and plot/subplot/scale counts until a defensible coverage-standardized richness series is available.

## Run it

R 4.5.x: `shiny::runApp(".", port = 8194)`. The default site is **SRER** (Santa Rita, a
Sonoran-desert case used to compare annual and seasonal driver summaries).

The required deployable data family is:

- `data/cascade.rds` — annual signals, pairwise screens, pooled direction summaries, site context, and provenance;
- `data/search_index.rds` — a fingerprinted search derivative of that bundle;
- `data/cascade_meta.rds` — the fingerprinted companion meta-analysis; and
- `data/neon-cascade-codebook.csv` — the generated field contract.

App boot verifies the manifest's exact 12-file checksum map before sourcing local code or deserializing
any RDS, then cross-checks the three RDS lineage stamps; inconsistent generations refuse to start.

## Data and measurement limits

`data/cascade.rds` is `list(annual, signals, priors, codebook, suite_links, pooled, site_meta, meta)`.
The annual per-site table—including `precip_winter`, `precip_monsoon`, and `temp_spring`—is assembled
from seven sibling apps’ committed bundles plus the small-mammal app’s NEON-tower climate overlays.
The builder does not refetch NEON data or execute sibling application code.

Annual temperature and precipitation require all **12 distinct months**; winter requires 6/6 months,
monsoon 3/3, and spring temperature 3/3. Every month count is retained. Biological support fields
(individuals, sampled plant units, trap-nights/catches, and observed bird point-count occasions) travel
beside the signals. Bird flyovers are excluded, but annual zero-detection visits can be absent. Beetle
effort contains catch-bearing events only, so that denominator is outcome-conditioned rather than a valid
all-event CPUE denominator. Mosquito effort-only years remain real zero-catch observations.

Phenology excludes left-censored first visits and uses a species-centered, equal-species, DOY-anchored
timing index with explicit contributor, species, exclusion, and onset-interval-width support. The additive
species+year construction is a full-precision sensitivity estimate. Both are retrospective full-panel
standardizations: a refresh can revise earlier values when the eligible species×year panel changes.

`fruiting_pct` is an opportunistic maximum over observed eligible months, not a fixed-season annual
estimate; `fruiting_n_eligible_months` and `fruiting_peak_n_individuals` expose unequal opportunity.
The vegetation context is a mean live basal area per hectare **conditional on plots with qualifying stem
records**. `veg_n_plots`, `veg_area_eligible_plots`, and `veg_record_plots` expose the denominator. The
source cannot distinguish sampled-zero from unsampled plots, so zero-stem and unobserved plots are not
imputed and this value must not be read as universal site-wide standing stock or productivity.

For the two five-site-eligible temperature–green-up rows, the companion uses REML random effects with
Knapp–Hartung inference, reports a 95% prediction interval and heterogeneity before directional p-values,
and applies Holm adjustment over the two-row family. It remains an exploratory sensitivity analysis.

## Reproducible rebuilds

Run only `Rscript scripts/rebuild_all.R`. Set `CASCADE_ROOT` to the directory
containing all seven current input repositories.

Ubuntu 24.04 with R 4.5.2 and the dated Posit snapshot is the canonical
release-byte environment, and CI requires its scientific artifacts to reproduce
exactly. Windows keeps strict schema, class, attribute, key, text, support, and
scientific-decision checks plus only explicitly named bounded full-precision
diagnostics; artifacts are never rounded to manufacture cross-platform identity. Each repository must be at its canonical origin; the archived `data/sites` scope (plus mammal `data/env`) must be clean and all consumed inputs tracked. Unrelated editor metadata outside those inert data roots cannot affect the build. The builder
records the exact commits and input hashes, creates an immutable `git archive` snapshot of each recorded
commit, verifies the extracted inputs against that inventory, and reads only those snapshots. A final live-source
check detects ordinary source changes during the run.

Unless overridden, the analysis cutoff is deterministic: **UTC year of the newest source commit minus one**.
`CASCADE_LAST_COMPLETE_YEAR` is accepted only as an exact four-digit historical year no later than the source-derived ceiling.

The single-writer rebuild lock prevents concurrent publishers. An empty isolated generation is populated from
an in-memory snapshot of the build/deploy code, then runs cascade → search → companion meta-analysis →
raw-source/artifact contracts → manifest write and verification → malformed/mixed-generation rejection tests →
UI/server serialization and initial reactive smoke → final manifest verification. Only then are the five generated
files checksum-verified and promoted; ordinary failures restore the previous byte-exact family, and the live
manifest is verified again before the lock is released. The manifest is promoted last, and app boot checks its
exact 12-file checksum map before sourcing repository code or deserializing RDS, so an interrupted promotion
refuses to serve a mixed generation.

The manifest's exact allowlist is the verified **runtime contract**. A git-backed Connect deployment may still
archive support files from the repository target directory, so the allowlist is not an assertion that scripts,
reviews, `README.md`, or `docs/` are physically absent. The app never sources or reads those support files;
`docs/index.html` remains the separate GitHub Pages landing page.
Built by Desert Data Labs · desertdatalabs@gmail.com. Not affiliated with NEON/Battelle/NSF.
