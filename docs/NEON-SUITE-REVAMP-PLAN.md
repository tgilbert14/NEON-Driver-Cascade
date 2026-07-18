# NEON Explorer Suite revamp program

Status: **ACTIVE**
Program owner: Driver Response Atlas repository
Audit baseline: 2026-07-18
Scope: Driver Response Atlas plus nine independently deployed companion apps

Progress: Driver baseline and Small Mammal Pass 1 are complete and published;
Ground Beetle remains the Phase 0 outage; Plant Phenology is the next learning pass
after the central Small Mammal receipt merges green.

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

The public cover system is already cohesive and visually strong: dark habitat
gradients, constellation links, code-native mascots, distinct accent palettes, and
clear launch controls. The revamp should preserve that recognition and improve its
information architecture, provenance, responsiveness, and maintainability.

The release layer is not at the same quality bar.

| App | Public app on 2026-07-18 | Manifest/runtime-file drift | Executable helper tests | Immediate scientific or product risk |
|---|---|---:|---:|---|
| Small Mammal Tracker | **Startup Error -> restored in Pass 1** | 10 -> 0 files | 0 -> 11 fixtures + JS handler gate | physical-event parity and opportunity denominator repaired; exact current-source Driver join remains held |
| Plant Phenology Explorer | available | 8 files | 1 | desert green-up opportunity and visit-cadence comparability must remain explicit |
| Plant Diversity | available | 13 files | 1 | documents and current code disagree about which review findings are resolved |
| Vegetation Structure Explorer | available | 8 files | 1 | shared `stand_site()` contract can drift from Driver; state must not be presented as annual flux |
| Ground Beetle Tracker | **Startup Error** | 8 files | 0 | catch-conditioned effort omits zero-carabid bouts; cover copy overstates ecosystem-health meaning |
| Mosquito Pulse | available | 7 files | 0 | expansion, zero-catch effort, day/night support, and seasonal aggregation need fixture coverage |
| Birds | available | 8 files | 1 | annual opportunity/zero-detection support and method/flyover handling need stronger contracts |
| Water Chemistry | available | 3 files | 0 | current QC fixes are ahead of the review documentation; release manifest is stale |
| My Little Inverts | available | 9 files | 0 | water type, sampler, habitat, and density-index support need executable tests and a current expert review |

At baseline, all nine companion manifests disagreed with at least one currently
tracked runtime file. Small Mammal Pass 1 has now closed its drift and independently
validated R 4.5.2 / 91-package / 117-file release family; the other eight remain at
their baseline state. A future companion deploy can otherwise publish a different
app than the repository appears to describe, or fail at startup.

Additional suite-wide findings (baseline unless a Pass 1 update is stated):

- At baseline, only the Driver repository had `AGENTS.md` and a durable
  `docs/BUILD-TEST-HANDOFF.md`. Small Mammal now has app-local governance, handoff,
  and Driver knowledge-package artifacts; the other eight companions still lack
  them.
- At baseline, four companions had one helper test script and five had none. Small
  Mammal now runs 11 scientific fixtures plus a JavaScript handler-contract gate.
- Most companion workflows use moving action tags and a moving package snapshot,
  combine build/validation/publish in one write-enabled job, and do not reproduce
  the Driver's loaded BLAS/thread receipt.
- Weekly scheduled runs can finish successfully in seconds because a date gate
  skipped the work. That is a skip, not fresh release-health evidence.
- Baseline post-deploy checks were not content-aware. Small Mammal now requires an
  app-specific semantic marker and rejects Posit error pages; the pattern remains to
  be ported to the other eight companions.
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
2. Restore Small Mammal Tracker and Ground Beetle Tracker from clean, verified
   manifests; do not treat an HTTP-only probe as proof.
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
| 2 | Plant Phenology Explorer | produces the suite's strongest supported hinge: temperature to green-up timing |
| 3 | Plant Diversity | separates composition, invasion, richness, cover, and productivity before producer synthesis |
| 4 | Vegetation Structure Explorer | supplies the slow standing-stock floor and the shared `stand_site()` contract |
| 5 | Ground Beetle Tracker | currently unavailable; effort-complete zero-catch support determines whether activity-density can leave context-only status |
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
  palette, icon/mascot, status, and Driver disposition;
- `suite-copy.json`: one canonical short description and role statement per app;
- generated cover relationship nodes and in-app Suite panel;
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
| Plant timing and state | Phenology, Plant Diversity, Vegetation Structure | timing, composition, and slow standing stock are distinct constructs |
| Terrestrial consumers | Small Mammals, Ground Beetles, Mosquitoes, Birds | activity, detection, and community indices with product-specific effort |
| Aquatic condition and consumers | Water Chemistry, My Little Inverts | chemistry is condition/context; invertebrates are method- and water-type-stratified consumers |
| Candidate hinge | HydroPulse or Aquatic Producers | added only if the gap audit supports it |

Every cover and About panel should answer: `What is this app?`, `What role does it
play in the suite?`, and `How can it inform Driver?` The third answer may be
`context only`.

## 6. Visual and cover system

### Preserve

- constellation/connected-suite metaphor;
- friendly code-native organism mascots;
- dark habitat atmosphere and app-specific accent colors;
- plain-language hero copy and two clear launch paths; and
- reduced-motion support.

### Revamp

Each cover uses one versioned shell with app-specific tokens and content:

1. suite eyebrow plus app role chip;
2. short outcome-led title and one-sentence honest promise;
3. primary `Open the app` and secondary `See methods & data` actions;
4. three verified facts stamped with data vintage;
5. a concise can/cannot claim pair;
6. a simplified, accessible suite relationship map;
7. availability language that does not claim an app is healthy before a semantic
   check; and
8. repository, DPID, data license, project license, and release receipt links.

Use imagery when it improves recognition or context:

- keep charts, maps, icons, and relationship diagrams code-native;
- use a coherent low-poly or cut-paper habitat illustration as an optional hero
  layer, generated specifically for the product rather than using generic stock;
- create a validated 1200x630 social card for every app from the same design tokens;
- include the organism or habitat, app title, role, and Desert Data Labs mark, but no
  tiny chart labels or unsupported headline numbers;
- store the prompt/source, dimensions, checksum, alt text, and generation date with
  every raster asset; and
- never let decorative imagery imply data precision, ecosystem health, or causal
  linkage.

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

### Small Mammal Tracker — first pass COMPLETE / production verified

- Restored Connect production at runtime merge `1615ab4` and closed the original
  startup outage with a semantic ready-marker check, explicit Last-deployed receipt,
  fresh JORN interaction, and no first-party console warning/error.
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
  About navigation, and a versioned 1200x630 habitat social card.
- Validated the canonical R 4.5.2 / 91-package / 117-file manifest, including the
  distinction between installed URL-package provenance and Connect's absolute-CRAN
  network contract. Final SHA-256 is
  `f6c4a5ff74053b95e22fac7394f1930d2fe2329663737031b1c32f7a1f70bc54`.
- Driver disposition is `CONTEXT / NO BYTE CHANGE`: contract parity is closed, but
  exact eligible-source site-year join/support remains held for suite synthesis.
- Residual: mobile visual QA is still unclaimed; static responsive, reduced-motion,
  focus, and touch-target gates passed. Phenology is the next app only after this
  central Driver receipt merges green.

### Plant Phenology Explorer — second pass

- Protect interval-censored onset and CI-or-silence behavior.
- Verify the current desert default and coverage badge with executable fixtures.
- Use green-up only where opportunity is adequate; default to leaf-active or a
  registered first-leaf metric in warm-desert strata.
- Relabel the clock denominator if it is observation-weighted rather than a unique
  plant share.
- Surface visit cadence and guard cross-site comparisons with coarse observation
  intervals.
- Lead cross-site interpretation with within-species evidence and uncertainty;
  keep the across-network slope as a species-mix-confounded echo.
- Evaluate GDD and PhenoCam linkage as registered future analyses, not automatic
  replacements.
- Driver disposition: `ADOPT` for the validated temperature-to-green-up family;
  register desert alternatives separately.

### Plant Diversity — third pass

- Reconcile expert-review text with current p-gating, codebook, provenance, and
  reference-flora code.
- Keep nested grain, latest-snapshot discipline, Chao2 support, unknown nativity,
  and cover-as-relative-index language.
- Make codebooks derive from actual exported frames and fail on undocumented
  columns.
- Lead with species-area, composition, and invasion pressure; never equate richness
  with productivity or ecosystem health.
- Keep per-site environment screens exploratory and pooled/registered if promoted.
- Driver disposition: richness/invasion `CONTEXT`; no productivity vote.

### Vegetation Structure Explorer — fourth pass

- Protect the forest DBH versus shrub basal-diameter paradigm and structural-NA
  semantics.
- Add cross-repository contract IDs and fixtures for `stand_site()`; require a
  Driver rebuild when the contract version changes.
- Keep basal area as a slow site-level state with plot-level uncertainty, never an
  annual climate response.
- Verify no-stand/single-census sites and distributed-versus-tower design paths.
- Consider recruitment and basal-area increment as app-local additions only after
  the state estimator remains stable.
- Driver disposition: `CONTEXT` slow producer floor; no annual vote.

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
| Responsive | stable desktop, tablet, and 390px mobile geometry with no persistent overflow or clipped controls |
| Accessibility | automated scan plus keyboard and screen-reader-name checks; color is not the only channel |
| Publish | green PR head, merge commit, deployed identity, content-aware app-ready marker, console/network health |
| Social/cover | canonical metadata, 1200x630 card, asset checksum, alt text, every suite link, accurate availability copy |
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
