# NEON Explorer Suite revamp program

Status: **ACTIVE — PAUSED BY OWNER BEFORE PASS 5**
Program owner: Driver Response Atlas repository
Audit baseline: 2026-07-18
Scope: Driver Response Atlas plus nine independently deployed companion apps

Progress: Driver baseline, Small Mammal Pass 1, Plant Phenology Pass 2, Plant
Diversity Pass 3, and Vegetation Structure Pass 4 are complete and
production-verified. Vegetation's reset lifecycle and Plotly source-registration
corrections are live on exact PR #8 merge `d566b30` / Connect deployment #59.
Ground Beetle remains the Phase 0 outage. The owner has paused the program before
Pass 5. Vegetation's app-local documentation is published through PR #9 / merge
`3391e70`; append-only receipt PR #10 is published as `da466ea`. Runtime, docs, and
receipt authority remain deliberately separate.

## 1. Outcome

Revamp the NEON Explorer Suite as one recognizable, trustworthy family without
turning it into one fragile monolith. Each app must remain independently useful,
independently deployable, and scientifically honest. The Driver Response Atlas
remains the synthesis layer; companion-app headlines never become Driver evidence
without a pinned data contract, an independent adapter, and a measured join.

The program has five non-negotiable outcomes:

1. **Every public app is actually available.** A green workflow, an HTTP 200, or a
   cover-page prewarm request is not sufficient evidence that a Shiny app started.
2. **Every release is reproducible and auditable.** Source, bundle, manifest,
   runtime, published commit, and public UI must be bound in one release receipt.
3. **Every displayed number has a scientific contract.** Grain, effort,
   opportunity, structural zeros, missingness, censoring, uncertainty, and limits
   travel with the metric.
4. **The suite feels related without becoming repetitive.** Navigation, trust
   signals, accessibility, covers, and suite relationships are consistent; each
   product keeps an organism-, habitat-, and method-specific visual identity.
5. **Driver v2 is learned into existence.** It is rebuilt only after all nine app
   passes produce pinned knowledge packages and the complementary-product gap audit
   is complete.

## 2. Audit baseline and immediate risks

The 2026-07-18 public-cover baseline used dark habitat gradients, constellation
links, code-native mascots, distinct accent palettes, and clear launch controls.
That history is factual but is no longer the target: owner review found the covers
too repetitive and information-heavy. The current direction is the brief artistic
poster system in section 6. Small Mammal and Vegetation now have independently
verified artistic Pages and in-app entry surfaces, with distinct app-native art
carrying the same concise first-impression contract.

The release layer is not at the same quality bar.

| App | Public app on 2026-07-18 | Manifest/runtime-file drift | Executable helper tests | Immediate scientific or product risk |
|---|---|---:|---:|---|
| Small Mammal Tracker | **Startup Error -> restored in Pass 1** | 10 -> 0 files | 0 -> 11 fixtures + JS handler gate | physical-event parity and opportunity denominator repaired; exact current-source Driver join remains held |
| Plant Phenology Explorer | **Startup Error -> restored in Pass 2** | 8 -> 0 files | 1 -> registered science/build/handler/semantic suite | desert green-up opportunity, interval censoring, and visit-cadence comparability are explicit; exact current-source Driver join remains held |
| Plant Diversity | **production verified in Pass 3** | 13 -> 0 files | 1 -> registered science/build/handler/cover/semantic suite | nested grain, opportunity, recurrent panels, Chao2, unknown nativity, reference scope, and `legacy-partial` source limits are release-verified; Driver remains context only |
| Vegetation Structure Explorer | **Pass 4 complete / production verified** | 8 -> 0 files | 1 -> registered source/science/parity/export/runtime/manifest/browser suite | official RELEASE-2026 event/opportunity family is verified; tree-DBH bole and shrub/sapling stem-base cross-section channels remain separate slow standing-structure context, never annual flux; reset and Plotly registration lifecycles are production-verified |
| Ground Beetle Tracker | **Startup Error** | 8 files | 0 | catch-conditioned effort omits zero-carabid bouts; cover copy overstates ecosystem-health meaning |
| Mosquito Pulse | available | 7 files | 0 | expansion, zero-catch effort, day/night support, and seasonal aggregation need fixture coverage |
| Birds | available | 8 files | 1 | annual opportunity/zero-detection support and method/flyover handling need stronger contracts |
| Water Chemistry | available | 3 files | 0 | current QC fixes are ahead of the review documentation; release manifest is stale |
| My Little Inverts | available | 9 files | 0 | water type, sampler, habitat, and density-index support need executable tests and a current expert review |

At baseline, all nine companion manifests disagreed with at least one currently
tracked runtime file. Small Mammal Cover V5 has now closed its drift and independently
validated R 4.5.2 / 91-package / 120-file release family. Plant Phenology Pass 2
then closed its drift with a pinned R 4.5.2 / 92-package / 60-runtime-file release.
Plant Diversity Pass 3 closed its drift with R 4.5.2 / 91 packages / 150 manifest
files and exact runtime, source-limit, export, responsive, and semantic receipts.
Vegetation Pass 4 now has an exact R 4.5.2 / 91-package / 68-runtime-file manifest
and a verified official 42-site RELEASE-2026 family; the other five companions
remain at their baseline state. A future companion deploy can otherwise publish a
different app than the repository appears to describe, or fail at startup.

Additional suite-wide findings (baseline unless a later pass update is stated):

- At baseline, only the Driver repository had `AGENTS.md` and a durable
  `docs/BUILD-TEST-HANDOFF.md`. Small Mammal, Phenology, Plant Diversity, and
  Vegetation now have app-local governance, handoff, and Driver knowledge-package
  artifacts; the other five companions still lack them.
- At baseline, four companions had one helper test script and five had none. Small
  Mammal, Phenology, Plant Diversity, and Vegetation now run product-specific
  science, portability, client-handler, exact-release, and semantic-health gates;
  the other five retain their baseline test debt.
- Most companion workflows use moving action tags and a moving package snapshot,
  combine build/validation/publish in one write-enabled job, and do not reproduce
  the Driver's loaded BLAS/thread receipt.
- Weekly scheduled runs can finish successfully in seconds because a date gate
  skipped the work. That is a skip, not fresh release-health evidence.
- Baseline post-deploy checks were not content-aware. Small Mammal, Phenology,
  Plant Diversity, and Vegetation now require app-specific semantic markers and
  exact release receipts while rejecting Posit error pages; the pattern remains to
  be ported to the other five companions.
- The suite registry and relationship copy are duplicated in each static cover,
  creating ten sources of truth.
- Mosquito Pulse and My Little Inverts reference `og-image.png` without committing
  the file. Water Chemistry declares an Open Graph image but no Twitter image.
- Several expert-review documents mix historical findings with current status.
  Water Chemistry, for example, now implements fixes that its review still presents
  as open. Findings must be linked to fixes and release verification rather than
  overwritten or left ambiguous.
- Ground Beetle's cover calls beetles a gauge of site health. The product supports
  activity-density, composition, and disturbance context, not an impairment or
  ecosystem-health verdict.

## 3. Program order

### Phase 0 — emergency stabilization and release trust

Complete before declaring any scientific app pass finished.

1. Freeze automatic publish-on-push where validation and publication are not
   separated.
2. Keep the production-verified Small Mammal restoration closed and restore Ground
   Beetle Tracker from a clean, verified manifest; do not treat an HTTP-only probe
   as proof.
3. Add a semantic live check that requires an app-specific ready marker and rejects
   Posit startup/error pages even when the response is 200.
4. Verify every manifest's file list and checksums before deployment. Compare
   manifest semantics, not formatting alone.
5. Port the Driver release shape: immutable action SHAs, fixed R, dated repository
   snapshot, loaded numeric-runtime receipt, one-thread guard, read-only validator,
   separately authorized publisher, and two independent reproduction passes for a
   changed numeric bundle.
6. Make schedule gates report `SKIPPED_BY_CALENDAR`, never a misleading green
   refresh receipt.
7. Add `AGENTS.md`, `docs/BUILD-TEST-HANDOFF.md`, and
   `docs/DRIVER-KNOWLEDGE-PACKAGE.md` to each companion as its pass begins.
8. Record rollback target, last-known-good manifest hash, published content ID, and
   public verification in every app-local handoff.

Phase 0 is a platform repair, not permission to change ecological signals in bulk.
Scientific changes still happen one app at a time.

### Phase 1 — one-app learning passes

The pass order is intentionally not alphabetical:

| Pass | App | Why this position |
|---:|---|---|
| 1 | Small Mammal Tracker | **COMPLETE / PRODUCTION VERIFIED**; restored the outage, established the companion release template, and closed physical-event contract parity without changing Driver bytes |
| 2 | Plant Phenology Explorer | **COMPLETE / PRODUCTION VERIFIED**; corrected plant-year opportunity, onset unavailability/censoring, deterministic derived artifacts, and release trust without changing Driver bytes |
| 3 | Plant Diversity | **COMPLETE / PRODUCTION VERIFIED**; separated composition, invasion, richness, and cover from unsupported productivity inference; closed nested-grain/opportunity/panel/source-limit contracts without changing Driver bytes |
| 4 | Vegetation Structure Explorer | **COMPLETE / PRODUCTION VERIFIED**; rebuilt from official RELEASE-2026 with event-atomic opportunity, separate physical channels, exact release promotion, an artistic Living Poster, accessible/export/pin enhancements, a complete reset contract, and a raw registered-event Plotly gate; Driver remains `HOLD / CONTEXT ONLY / NO DRIVER DATA BYTE CHANGE` |
| 5 | Ground Beetle Tracker | **PAUSED BY OWNER before this pass**; currently unavailable, and effort-complete zero-catch support will determine whether activity-density can leave context-only status |
| 6 | Mosquito Pulse | strongest seasonal consumer candidate; requires opportunity-complete trap effort and biome-aware temperature/precipitation framing |
| 7 | Birds | important consumer context, but method, flyover, zero-detection, and annual-support constraints limit Driver use |
| 8 | Water Chemistry | well-powered condition record and best control case for honest statistics; not itself a trophic hinge |
| 9 | My Little Inverts | closes the current aquatic consumer pass and reveals whether a producer or physical-driver product is still missing |

### Phase 2 — complementary-product decision

Do not decide from aesthetics or from a product name. Score candidates after pass 9
on the following registered criteria:

- mechanistic hinge closed in the Driver;
- overlap with existing aquatic site/date support;
- explicit effort and structural zeros;
- temporal coverage and lag support;
- method stability and unit integrity;
- ability to distinguish state, driver, producer, and consumer roles;
- independent value as a standalone explorer;
- build and maintenance cost;
- exact adapter/test feasibility; and
- risk of creating a proxy that looks causal.

Current candidates, not commitments:

1. **NEON HydroPulse / Aquatic Drivers** — discharge plus aquatic water
   temperature, with season, flow anomaly, and sampling support. This is the leading
   physical-hinge candidate because it can explain when chemistry and invertebrate
   observations occur in a flow/temperature context.
2. **NEON Aquatic Producers** — periphyton or another defensible primary-producer
   product. This may close the more important trophic gap if method and opportunity
   support are adequate.
3. **Defer a new app** — correct if neither candidate clears the data-contract and
   standalone-value gates.

Fish or other higher aquatic consumers are a later option, not the default answer;
adding another consumer does not close a missing physical-driver or producer rung.

### Phase 3 — Driver v2 reintegration

Synthesize the nine pinned knowledge packages and complementary-product decision.
Only registered `ADOPT` signals enter inferential voting. `CONTEXT` remains visible
but non-voting, `HOLD` stays gated, and `REJECT` reasons remain durable.

## 4. The one-app pass

Each companion pass follows the same sequence.

### A. Freeze and characterize

- Pin the exact source commit and deployed content identity.
- Record the DPID, source tables, bundle schema, row grain, spatial/temporal support,
  opportunity/effort, structural zeros, missingness, censoring, and protocol eras.
- Recompute headline facts from committed bundles; do not copy them from prose.
- Reconcile `DATA-TAKEAWAYS`, expert review, README, codebook, and current code using
  finding IDs and explicit `OPEN` / `FIXED` / `VERIFIED` states.

### B. Make the release fail closed

- Add fixture-level helper tests, schema contracts, bundle-integrity checks,
  semantic manifest comparison, boot-integrity mutation tests, and content-aware
  post-deploy smoke.
- Validate with no live network dependency at app boot.
- Keep source refresh, deterministic transformation, validation, and publication as
  separately observable stages.
- Require the public release receipt before marking the pass complete.

### C. Critically improve the science

- Test the metric against its actual sampling design.
- Expose denominators, uncertainty, support, and exclusions where the number appears.
- Prefer a withheld claim to a polished overclaim.
- Put cross-app parity failures back into the source app; never compensate silently
  in Driver.
- Produce the pinned Driver knowledge package and disposition.

### D. Improve the product and UI

- Test the top three user jobs, not every existing tab.
- Consolidate navigation around `Overview`, `Explore`, `Compare`, `Data & QC`, and
  `Methods`, using in-page modes for app-specific labs and profiles.
- Preserve deep links, last-site restore, map/sidebar synchronization, exports,
  empty states, and keyboard paths.
- Reduce the current eight-to-ten-tab overload on small screens.
- Put a short `What this can tell you` / `What it cannot tell you` contract beside
  the primary signal rather than hiding all limits in About.
- Meet WCAG 2.2 AA: visible focus, keyboard-equivalent interactions, semantic
  headings, color plus shape, adequate contrast, 44px touch targets, reduced motion,
  and screen-reader names for chart actions.
- Budget startup, interaction latency, bundle size, and chart count. Lazy-render
  expensive secondary views after the primary story is ready.

### E. Publish and learn

- Bind green PR head, merge commit, manifest hash, deployed commit/content ID, and
  public verification.
- Test stable desktop and mobile geometry, console/network health, deep links,
  downloads, and one real interaction funnel.
- Update app-local handoff, knowledge package, suite register, and Driver backlog.
- Promote reusable engineering lessons only after they have passed in the app that
  produced them.

## 5. Suite product architecture

### Independent products, shared control plane

Do not create a shared runtime R package that can break all apps at once. Instead,
keep the apps independent and vendor generated, versioned suite artifacts:

- `suite-registry.json`: app ID, public name, role, DPID, repository, cover, app URL,
  palette, field motif/art direction, status, and Driver disposition;
- `suite-copy.json`: one canonical short description and role statement per app;
- a generated single Driver route for each companion poster, the full registry for
  Driver, and the full in-app Suite/About panel;
- `suite-release-status.json`: last verified commit, manifest hash, public-health
  time, and release state;
- a cover/social validator; and
- a suite CI report that reads app receipts but cannot publish companion apps.

Driver owns the canonical registry and generator. Each companion vendors a pinned
generated copy so it remains available if Driver or GitHub is unavailable. CI fails
when a vendored registry drifts from its declared registry version.

### Suite relationship model

Use roles, not decorative causal arrows:

| Suite group | Products | Honest relationship |
|---|---|---|
| Integrator | Driver Response Atlas | compares registered directional evidence and context |
| Plant timing and state | Phenology, Plant Diversity, Vegetation Structure | timing, composition, and slow standing-structure context are distinct constructs |
| Terrestrial consumers | Small Mammals, Ground Beetles, Mosquitoes, Birds | activity, detection, and community indices with product-specific effort |
| Aquatic condition and consumers | Water Chemistry, My Little Inverts | chemistry is condition/context; invertebrates are method- and water-type-stratified consumers |
| Candidate hinge | HydroPulse or Aquatic Producers | added only if the gap audit supports it |

Every cover page as a whole and every About panel should answer: `What is this
app?`, `What role does it play in the suite?`, and `How can it inform Driver?` The
companion poster face answers the first with one invitation and provides exactly one
Driver route; the full suite and scientific relationship story belongs below the
fold, in the in-app Suite/About panel, and in Driver. The third answer may be
`context only`.

## 6. Visual and cover system

### Suite Living Poster V1 — canonical shared frame

Every companion uses the same structural frame on both public Pages and its in-app
first-run surface. This is a shared scaffold, not a cloned artwork. The required
face is:

1. a focusable skip target;
2. a DDL topline/identity with exactly one route to Driver;
3. an app/unofficial eyebrow;
4. one 3–7-word human hook;
5. one 6–12-word plain-language promise;
6. exactly one contextual CTA;
7. one dominant responsive editorial artwork;
8. a visible illustration/photo/data boundary; and
9. a compact scope/honesty/Source/Feedback footer.

No companion poster face carries a metric band, methods block, release receipt,
second marketing bridge, relationship map, or full suite directory. Driver is the
suite ambassador and may carry the complete registry and integration story below
its own poster; companions keep the full registry in their in-app Suite/About panel.
Pages and Connect share the hook, promise, art authority, disclosure, Driver route,
and CTA intent even when their framework geometry differs.

The frame is constant; the visual/content variables are not. Each app owns its
palette, motif, crop, words, focal position, CTA noun, and scientific limitation.
Plant may use nested quadrat/flower motifs; Phenology a bud/seasonal arc; Mammals a
trap or track rendered as art rather than fake field documentation. Driver's motifs
may converge into an integration gesture, but that gesture is visual—not a causal
claim.

Chronology matters: the approved Small Mammal screenprint existed in a concept
board but was not shipped by PR #85. Vegetation established the production frame.
Small Mammal Cover V5 then proved that the same frame transfers to a second app in
PR #86 / merge `c4c46fce`, using “Who moves after dark?”, “Meet the tiny lives
reshaping the landscape.”, “Meet the mammals”, and a dominant trap/mouse editorial
screenprint. Phenology/Plant generated-art releases remain factual baselines and
must be reviewed against this contract before their next cover release.

Validate exact copy/action count, provenance and asset hashes, a separately composed
1200×630 social card, keyboard/focus order, reduced-motion and forced-color modes,
zero overflow at desktop/390/320 and both sides of real framework seams, cache-busted
Pages and Connect identities, CTA-to-picker focus, and console/server logs. Remove
retired runtime media once its provenance remains recoverable.

### Trust, access, and provenance

- Keep imagery local, responsive, accessible, and explicit about whether it is
  documentary, illustrative, generated, or code-native.
- Store source/prompt, dimensions, checksum, alt text, license, and generation date
  for every raster asset. Never let art imply data precision, ecosystem health,
  causal linkage, or field documentation it does not possess.
- Preserve semantic headings, visible focus, keyboard access, 44 px controls,
  contrast, reduced-motion behavior, and a meaningful text alternative.
- Below the fold, retain accurate availability, DPID, source/data and project
  licenses, CAN/CANNOT, methods, provenance, release receipt, repository, and suite
  navigation generated from the canonical registry.

Suggested palette families remain distinct but related:

- Driver: electric blue + teal;
- Mammals: moonlit indigo + warm sand;
- Phenology: spring green + bud coral;
- Plant Diversity: canopy green + wildflower accents;
- Vegetation Structure: cedar + gold-ring highlight;
- Beetles: moss + copper, with health-claim copy removed;
- Mosquitoes: violet + monsoon cyan;
- Birds: dawn gold + sky blue;
- Water Chemistry: deep water blue + analytical cyan;
- Invertebrates: stream teal + riffle amber;
- candidate HydroPulse: glacier blue + floodplain coral.

## 7. Per-app priority briefs

### Small Mammal Tracker — first pass + Cover V5 COMPLETE / production verified

- Cover V5 source head `3e66ddcab6119b4ab0cace85a64616cb19cf766b`
  passed exact-head run `29755133857`; PR #86 merged as
  `c4c46fce3725126231504d8f9610f52e8f929ef8`. Main CI `29755368217`, semantic
  smoke `29755368297`, and Pages `29755366998` passed. Connect deployment #125
  published exact `c4c46fce` under R 4.5.2 with all 91 packages supplied.
  Documentation closeout PR #87 merged as `047204e7`.
- Shipped the reviewed physical-event resolver: exact six status tokens, canonical
  A-J x 1-10 events, strict multi-capture collapse, two documented double-trap
  exceptions, explicit placeholder uncertainty, and fail-closed ambiguity.
- Corrected species CPUE to use all reviewed opportunity; fixed the dormant
  multi-species-tag QC path; surfaced single-night and detection coverage; carried
  p-hat/mean N-hat into Compare and suppressed unsupported raw winners.
- Added 11 pinned scientific fixtures, a six-handler Shiny JavaScript contract,
  exact 46-site/schema/index/checksum gates, offline boot, immutable release review,
  restricted refresh candidates, and semantic outage issue open/close behavior.
- Shipped tidy event/capture and monthly MNKA/CPUE/N-hat/p-hat exports with a
  codebook, exact 46-site/145-species framing, accessibility contracts, all-suite
  About navigation, and a versioned 1200×630 habitat social card.
- Validated the canonical R 4.5.2 / 91-package / 120-file manifest, including the
  distinction between installed URL-package provenance and Connect's absolute-CRAN
  network contract. Final SHA-256 is
  `3fdf334febde34f93f75430bd5ef7daa61cc36f1d6ef7f540578051bee24d3fc`;
  `wk 0.9.5` retains its full HTTPS CRAN tarball reference.
- Driver disposition is `CONTEXT / NO BYTE CHANGE`: contract parity is closed, but
  exact eligible-source site-year join/support remains held for suite synthesis.
- The Living Poster now converges both first impressions around the owner-selected
  hook “Who moves after dark?”, promise “Meet the tiny lives reshaping the
  landscape.”, CTA “Meet the mammals”, and an editorial screenprint whose metal box
  trap is dominant beside a recognizable mouse. A visible boundary says the art is
  illustration, and the honesty note prevents the invitation from becoming a claim
  that capture records measured landscape effects.
- Pages and Connect passed desktop, 390 x 844, 320 x 568/720, and real responsive
  seams with zero root overflow and byte-matched full/compact artwork. The CTA moved
  focus to the 46-site picker; JORN loaded all ten tabs; species and environmental-
  driver bar clicks worked. PR #85 / `eb9e1a3` and Connect #122 / `bdf56b0` are
  documentary Cover V4 history, not evidence for the owner-selected screenprint.

### Plant Phenology Explorer — second pass COMPLETE / production verified

- Corrected the Clock opportunity to one scored plant x phenophase x year x week;
  repeated visits collapse within a week while years remain separate. Executable
  fixtures now cover repeat visits, independent years, uncertain status,
  suppression, interval/left censoring, trend de-pseudoreplication, multi-flush
  leaf-active duration, desert green-up coverage, and within-species support.
- Normalized fully suppressed trend results to honest `NULL` values and preserved
  the required R-list field with `bundle["trend"] <- list(NULL)`. A two-pass,
  all-bundle hash gate proves the migration is idempotent; deterministic indexes
  likewise rebuild twice to exact bytes without wall-clock inputs.
- Shipped the pinned R 4.5.2 / 92-package / 60-runtime-file manifest with absolute
  `wk 0.9.5` CRAN provenance, 46 verified site bundles, exact manifest and index
  checks, five-handler client contract, bundle-only offline source, and separately
  authorized refresh candidates.
- The app now exposes green-up coverage, visit cadence, left censoring, and the
  warm-desert leaf-active alternative. Clock labels/exports use the corrected
  opportunity; unsupported estimates render unavailable rather than empty.
- Across Sites leads with a gated within-species slope and CI, identifies coarse
  cadence, treats the network-wide slope as composition-confounded context, and
  explicitly rejects a causal temperature interpretation.
- Rebuilt the cover around “Read the seasons” with responsive, provenance-tracked
  stylized seasonal art, CAN/CANNOT and suite-role boundaries, a release receipt,
  exact social metadata, and all ten suite destinations. Public desktop, 390, and
  320 browser QA passed with no root overflow.
- Release PR head `cc0151d` passed run `29669603912`; merge, Pages, and Connect Last
  deployed are `29c0ed1`; semantic production run `29670192516` and fresh HARV
  Overview/Clock/Onset/Across-Sites interactions passed.
- Driver disposition: `HOLD / NO DRIVER BYTE CHANGE`. Corrected onset,
  leaf-active, and coverage signals are trusted app-local candidates, but the
  existing temperature-to-green-up family is not re-adopted from a UI result. It
  requires the exact eligible site-year join, support/censoring gates, and a
  registered analysis during suite synthesis.

### Plant Diversity — third pass COMPLETE / production verified

- Registered and verified the 1/10/100/400 m² nested grains, one deterministic
  current bout per plot, one bout per plot-year, recurrent panels, scale-specific
  support, incidence-based finite-sample bias-corrected Chao2 lower bound, relative
  ocular cover, and exclusive Native/Introduced/Unknown handling.
- Kept sampled-empty 1 m² opportunity unavailable rather than invented; scoped the
  one-point NRCS reference honestly; kept short annual/environment screens
  descriptive and non-causal; preserved richness ≠ productivity/health/management.
- Reconciled Data Takeaways, Expert Review, Science Contract, strict export
  dictionary, source receipts, governance, and Driver knowledge package. The exact
  46-plant + 46-environment + 34-reference family remains `legacy-partial`: its
  content hash proves bytes, not upstream build/release/cutoff.
- Final code merge `d6c4862` passed PR run `29695040575`, master run
  `29695179837`, Pages `29695179559`, exact post-republish semantic attempt 2
  `29695179854`, R 4.5.2 / 91 packages / 150 manifest files, deterministic search
  and manifest builds, offline source, exact bundle/receipt equality, and public
  SRER desktop + 390/375/361/360/320 QA.
- Production runtime is `sha256:0765d8951843cf6fea09a295b260bfb53f1eb6708370748905a4a3941c85d2cb`;
  manifest SHA-256 is `12ffe3496ac54a6504a04656236604abc64f4638d1ae92bfe103565c0d15cd51`;
  cover/social receipt remains `sha256:de6718b3b4e3557fdc395911cd98ce55be29db4d2a9b9038f1903814ed00413c`.
- The released stylized plant art remains a verified baseline, not the final suite
  answer. Future cover changes wait for approval of the artistic-poster system and
  must not disturb the production science/release identity silently.
- Driver disposition: `CONTEXT / NO DRIVER BYTE CHANGE`. Current-source ingestion
  requires a complete matching future receipt, sampled-opportunity ledger, and
  measured eligible site-year join; no productivity vote or per-site climate edge.

### Vegetation Structure Explorer — fourth pass COMPLETE / production verified

- Rebuilt the app around NEON `DP1.10098.001` official `RELEASE-2026`, DOI
  `10.48443/pypa-qf12`, with 42 event-keyed site bundles, retained source and
  mapping UIDs, event-atomic opportunity, deterministic indexes/exports, and an
  independently reconstructed release verifier.
- Preserved all published measurement rows. The 49 plot-events / 4,365 rows / 11
  sites without matching opportunity-source rows are explicitly
  `held_opportunity_source_missing`; no area, effort, absence, opportunity date,
  or denominator is manufactured and none enters scaling or derived summaries.
- Registered two disjoint channels: `tree_dbh` tree-DBH bole cross-section and
  `shrub_sapling_basal` shrub/sapling stem-base cross-section. Shared m²/ha units
  do not make their heights, thresholds, sampled areas, or physical meanings
  interchangeable.
  Supported sampled absence is a real zero; held and unsupported states remain NA.
- Exact-head candidate run `29715249829` produced the reviewed 54-payload family;
  promotion commit `800bd5ea64d5aa4f2eab194c1b16dcbee5a0638e` has the candidate
  head as its direct parent and every promoted blob matches the artifact ledger.
  Final PR #4 head `5c7456b` passed CI `29716974286`; merge
  `987c102b84de98f18c11dd98de6c8113ab7f4c8c` passed Pages run `29717224521` and
  Connect deployment #55 serves that exact commit under R 4.5.2 / 91 packages.
- PR #5 introduced the first server-side Plotly state gate. Exact head
  `5baa6a023a9763d03e15d2341985b8d492e36755` passed CI `29718292956`; merge
  `91a7814c9e1275c5a890aed4a9c186485f614e60` passed main CI `29718542229`,
  Pages `29718541621`, and Connect deployment #56. That intermediate release
  removed the originally observed eager path but did not establish the final
  render-registration contract; later exact server-log evidence superseded that
  broader inference.
- PR #6 added accessible loading/focus management, a reduced-motion tour,
  byte-shared active-channel plot-summary CSV/ZIP export, a Size Lab-local eligible
  plant selector, and keyboard-operable named pin groups. Exact-head CI
  `29720142868` passed at `e5a12add8b1227453a904ff14741b92a5a435759`; merge
  `433bbd25acbe48224a75368c9edd6504e55271bd` passed main CI `29720341082` and
  Pages `29720340743`; Connect deployment #57 serves exact `433bbd25` under R
  4.5.2 / 91 packages.
- PR #7 restored the complete 42-choice server-backed site picker on both session
  initialization and reset through one helper. Implementation
  `3835451f6945b25eca4ef31b4d0882b6406c07ae` promoted as exact head
  `8389c9c2d1a723b03f0e1ab88f64732fe454a134`;
  run `29722349642` / artifact `8452911612` passed. PR #7 merged as
  `0709bd021c7c9f142b1f280aa83b2cf3afd49f30`; main CI `29722614074` /
  artifact `8453019545`, Pages `29722613509` / artifact `8452933484` /
  deployment `5517850060`, and Connect #58 all served that exact merge. Live BART
  -> Change site -> search JORN returned one exact choice and loaded correctly.
- Connect #58 nevertheless failed the final server-log gate: fresh loads emitted
  the `plotly_click` / `baBar` not-registered warning although visible behavior and
  the browser console were clean. PR #8 fixed the actual plotly R 4.12 lifecycle:
  keep `event_register("plotly_click")`, trigger from raw
  `session$rootScope()$input[["plotly_click-baBar"]]`, and only then read
  `event_data(..., priority = "event")`. Implementation
  `4ce0cb7b3a7125780a5c7ca60c28a3eae71a88f5` produced the expected
  manifest-only run `29723373295` / artifact `8453312072`; promotion
  `06904fe227119c2b87f80c9dc8334f19f7f79b05` passed exact run
  `29723718100` / artifact `8453460662`. PR #8 merged as
  `d566b30ec8eb52ae984325da402cadfec3f18bc9`; main CI `29724062900` /
  artifact `8453599842` and Pages `29724062095` / artifact `8453482888` /
  deployment `5518123037` passed. Connect #59 serves exact `d566b30` under R
  4.5.2 with all 91 packages after a four-second deployment.
- Replaced the dense cover with the responsive screenprint Living Poster:
  “Tagged. Measured. Still changing.”, “Follow real trees and shrubs through years
  of change.”, and “Pick a place”. Pages and Connect both expose the concise entry
  promise, source/art disclosure, and suite bridge without moving methods onto the
  poster face.
- BART live QA passed both channels, opened the same bar selection from two
  identical clicks, and passed search/compare, keyboard pin motion/resize/close,
  dark mode, and the promised export paths. Its standalone shrub/sapling
  plot-summary CSV exactly matched the ZIP copy. JORN's 50
  tree contexts split into 25 supported sampled-absence zeros and 25
  `held_sampling_impractical` contexts; the UI reported 25 supported plots and zero
  live trees. WOOD remained held-only across all 50 contexts (14 source-missing plus
  36 opportunity-unknown), with 452 shrub/sapling rows / 411 live records and zero
  supported contexts in either physical channel. Final Connect #59 QA also passed
  the exact BART -> reset -> JORN path, JORN supported-zero behavior, WOOD held-only
  behavior, viewport widths 390/375/361/360/320 plus loaded-state 320/390, and zero
  horizontal overflow. Its 33-entry browser slice had no warning, error, suspect
  Plotly/Shiny message, or disconnect. Server logs contained only benign
  plotly/shinyjs package-built-under-R-4.5.3 warnings and zero `baBar`,
  `event_data`, not-registered, undefined-event, or Shiny runtime errors.
- Pass 4 runtime production closeout remains anchored to PR #8 merge
  `d566b30ec8eb52ae984325da402cadfec3f18bc9`. App-local documentation PR #9 head
  `68497de328b2723aa997e7016397bfd266e22337` passed CI `29724891796` with artifact
  `8453930434` (92,307 bytes; SHA-256
  `f92b5a9fc3d7eb1e9dbb70b894bed6882eff9c94d22a5907d3ec0207225684ce`) and merged
  as `3391e702e7be80a3f049c905782661f043be8db8`. Main CI `29725238531` passed with
  artifact `8454053110` (92,307 bytes; SHA-256
  `71ec40bdfe63c2e2987a622c0759ad6c31bf3a749ef6c10a008a82afc1b9ef7f`). The
  runtime manifest and search index remained exactly
  `b497f2e9f4228d772745b220da3f2ba6e9da00b8af4fec61af4272103d2e330c` and
  `c4d145046d9486d7c7cf2c85339200ba1eaad3cf7e0de22bb2e378c7c944fc4b`.
  Pages run `29725237988` passed with artifact `8453952616` (3,902,344 bytes;
  SHA-256
  `d871b82ae790998f03d8228981bcce3921be5724a97b52eabd27d72ee0948265`)
  and deployment `5518345576`. Connect #60 serves exact docs merge `3391e70` under
  R 4.5.2 / 91 packages after four seconds; logs contain only benign
  plotly/shinyjs package-built-under-R-4.5.3 warnings, and public Pages/Connect
  landings are clean.
- Append-only receipt PR #10 head
  `a606f9217f9110a80eff567e34668349b27d3c9f` passed run `29725664115`. Artifact
  `vegetation-structure-derived-a606f9217f9110a80eff567e34668349b27d3c9f-29725664115`
  was ID `8454216674`, 92,307 bytes, with SHA-256
  `8f75c1f43f6e47fd11ae9aa8894861b846e600c1e01821aedca10bcfb8a45946`;
  manifest and search bytes were identical to the documentation release. PR #10
  merged as receipt authority `da466ea2495df3b03cb472bc2c6c65930ca5314a`.
  Main CI `29725954423` passed with artifact
  `vegetation-structure-derived-da466ea2495df3b03cb472bc2c6c65930ca5314a-29725954423`
  (ID `8454339056`, 92,307 bytes; SHA-256
  `2c28c917acee6848bd36ecfaad873d42df1d5a42c26264455362d62d305423ec`),
  and downloaded manifest/search files remained byte-identical. Pages run
  `29725953990` passed with artifact `8454236113` (3,902,883 bytes; SHA-256
  `8e27e003767947d389ec1f87db9357c24cfe2894e7c0208b1b3afa163833f67d`)
  and deployment `5518482150`. Connect #61 serves exact `da466ea` under R 4.5.2 /
  91 packages after four seconds. Server logs contain only the two benign
  plotly/shinyjs package-version warnings and zero `baBar`, `event_data`, or related
  runtime errors. Fresh Connect and Pages landing smoke passed H1, CTA, picker,
  suite bridge, disclosure, zero overflow, and no visible failure.
- The three identities remain separate: authoritative runtime `d566b30`, app-local
  documentation `3391e70`, and append-only receipt `da466ea`. Pass 4, its app-local
  documentation, and receipt publication are complete.
- Driver disposition: `HOLD / CONTEXT ONLY / NO DRIVER DATA BYTE CHANGE`.
  Vegetation supplies channel-qualified slow standing-structure context and design
  evidence, not annual productivity, biomass, carbon, a causal edge, or an annual
  vote. App-local gates 1–7 are satisfied; gate 8, the separately reviewed Driver
  adapter/rebuild, remains closed. Program execution is paused by the owner before
  Ground Beetle Pass 5.

### Ground Beetle Tracker — fifth pass

- Restore the public app and repair its release path.
- Build effort from all trapping opportunities, including zero-carabid bouts. Until
  that denominator is complete, label catch-per-effort as outcome-conditioned and
  keep it non-voting.
- Make bundles portable under cold Linux reads; force materialized character data,
  restore Date classes, save a supported serialization version, and test cold load.
- Keep species-rank gates, introduced-dominant flags, and permutation-null framing.
- Remove the cover's site-health claim.
- Require enough environmental support before any candidate driver can enter model
  selection.
- Driver disposition: `CONTEXT`, with possible reconsideration after an
  effort-complete rebuild.

### Mosquito Pulse — sixth pass

- Test zero-catch deployments keyed independently of nullable `sampleID`.
- Test continuous subsample expansion, trap-hour conversion, missing/zero effort,
  day/night support, compromised samples, and uncertain IDs.
- Keep activity per trap-night as a within-site activity index, not population,
  biting rate, or disease risk.
- Prefer within-season monsoon/thermal pulse analyses to underpowered site-year
  verdicts; model thermal ceilings rather than monotone warmth.
- Add a current expert review and static release codebook.
- Driver disposition: `HOLD` for a registered pooled seasonal consumer signal;
  otherwise `CONTEXT`.

### Birds — seventh pass

- Preserve rarefaction, Chao2 uncertainty/suppression, flyover quarantine, method
  channels, and 999-distance handling.
- Audit annual zero-detection opportunity so absent detections are distinguishable
  from absent visits.
- Keep point x year as the sampling unit; treat raw richness and detection counts as
  effort/method sensitive.
- Test method mixtures and observer-distance support in exports and visual marks.
- Driver disposition: `CONTEXT` unless a registered, effort-complete pooled signal
  clears support.

### Water Chemistry — eighth pass

- Treat the current code, not the older review prose, as the candidate implementation;
  verify canonical units, the site-aware plausibility gate, censored-share greying,
  BH q, effective-n logic, codebook, and legacy provenance with fixtures.
- Verify that mislabeled historical unit strings are corrected without applying a
  false 1000x numeric conversion.
- Preserve below-detection values and flags in raw exports while keeping
  heavy-censor results exploratory.
- Consider charge balance only after canonical units pass and only as QC.
- Consolidate nine top-level tabs into task-oriented modes.
- Driver disposition: `CONTEXT` as aquatic condition/aridity corroboration, not a
  lag-aware trophic link.

### My Little Inverts — ninth pass

- Add an expert review and executable tests for sample expansion, benthic area,
  density, rarefaction/small-n suppression, coarse taxonomy, and EPT classification.
- Stratify comparisons by water type, sampler, and habitat; make support visible on
  every cross-site view.
- Keep density as a within-site standardized index and EPT as composition, not an
  impairment/health grade.
- Confirm codebook-to-export parity and source provenance.
- Driver disposition: `CONTEXT`; use the pass to decide whether physical drivers or
  aquatic producers are the more load-bearing missing product.

## 8. Verification matrix

No app pass is complete without evidence in all applicable rows.

| Layer | Required gate |
|---|---|
| Source | pinned product, exact tables, schema, site set, release vintage, and raw-source fingerprint |
| Transform | fixture tests for grain, effort, zeros, missing/censoring, joins, units, and protocol eras |
| Bundle | exact schema/count contracts, cold-load portability, codebook parity, deterministic hashes where feasible |
| Manifest | exact file checksum audit, package/provenance policy, semantic compare, no runtime-irrelevant files |
| Boot | clean offline start plus malformed/missing/mutated fixture failures |
| UI | primary funnel, deep link, map/sidebar sync, empty state, keyboard path, download, dark/light, reduced motion |
| Responsive | stable desktop, tablet, 390px, and 320px geometry plus both sides of every app-specific breakpoint seam; no persistent overflow, clipped status, or sub-44px control |
| Accessibility | automated scan plus keyboard and screen-reader-name checks; color is not the only channel |
| Publish | green PR head, merge commit, deployed identity, content-aware app-ready marker, console/network health |
| Social/cover | canonical metadata, separately composed 1200×630 card, asset checksum, alt text, one Driver route on a companion poster, full registry in Driver/in-app Suite/About, accurate availability copy |
| Driver | pinned knowledge package, measured joins, disposition, and explicit implication or `NONE` |

The current execution environment has no local R runtime, so this audit does not
claim any R test passed. Static repository, manifest, public browser, and workflow
evidence are valid; runtime validation must execute in the pinned GitHub/Connect
environment until a matching local R toolchain is provisioned.

## 9. Definition of done

The revamp program is complete only when:

- all ten current public apps pass content-aware health checks;
- every companion has a pinned, coherent, independently verified release receipt;
- every app has current governance, handoff, codebook, data takeaways, expert review,
  and Driver knowledge package;
- all historical findings have durable status and verification links;
- the canonical suite registry generates all covers and in-app relationship panels;
- every app's primary user funnel passes desktop/mobile/accessibility verification;
- all nine knowledge packages are pinned;
- the new-app decision is recorded with the scored gap audit;
- Driver v2 includes only accepted signals and independently tested adapters; and
- the final published suite is verified as a family without sacrificing independent
  deployment or honest scientific limits.
