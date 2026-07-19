# NEON Explorer Suite revamp program

Status: **ACTIVE**
Program owner: Driver Response Atlas repository
Audit baseline: 2026-07-18
Scope: Driver Response Atlas plus nine independently deployed companion apps

Progress: Driver baseline, Small Mammal Pass 1, Plant Phenology Pass 2, and Plant
Diversity Pass 3 are complete and production-verified. Ground Beetle remains the
Phase 0 outage. Vegetation Structure is the next scientific pass, but its cover
work waits for owner approval of the new artistic-poster direction.

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
poster system in section 6, pending approval from real cover review.

The release layer is not at the same quality bar.

| App | Public app on 2026-07-18 | Manifest/runtime-file drift | Executable helper tests | Immediate scientific or product risk |
|---|---|---:|---:|---|
| Small Mammal Tracker | **Startup Error -> restored in Pass 1** | 10 -> 0 files | 0 -> 11 fixtures + JS handler gate | physical-event parity and opportunity denominator repaired; exact current-source Driver join remains held |
| Plant Phenology Explorer | **Startup Error -> restored in Pass 2** | 8 -> 0 files | 1 -> registered science/build/handler/semantic suite | desert green-up opportunity, interval censoring, and visit-cadence comparability are explicit; exact current-source Driver join remains held |
| Plant Diversity | **production verified in Pass 3** | 13 -> 0 files | 1 -> registered science/build/handler/cover/semantic suite | nested grain, opportunity, recurrent panels, Chao2, unknown nativity, reference scope, and `legacy-partial` source limits are release-verified; Driver remains context only |
| Vegetation Structure Explorer | available | 8 files | 1 | shared `stand_site()` contract can drift from Driver; state must not be presented as annual flux |
| Ground Beetle Tracker | **Startup Error** | 8 files | 0 | catch-conditioned effort omits zero-carabid bouts; cover copy overstates ecosystem-health meaning |
| Mosquito Pulse | available | 7 files | 0 | expansion, zero-catch effort, day/night support, and seasonal aggregation need fixture coverage |
| Birds | available | 8 files | 1 | annual opportunity/zero-detection support and method/flyover handling need stronger contracts |
| Water Chemistry | available | 3 files | 0 | current QC fixes are ahead of the review documentation; release manifest is stale |
| My Little Inverts | available | 9 files | 0 | water type, sampler, habitat, and density-index support need executable tests and a current expert review |

At baseline, all nine companion manifests disagreed with at least one currently
tracked runtime file. Small Mammal Pass 1 has now closed its drift and independently
validated R 4.5.2 / 91-package / 117-file release family. Plant Phenology Pass 2
then closed its drift with a pinned R 4.5.2 / 92-package / 60-runtime-file release.
Plant Diversity Pass 3 closed its drift with R 4.5.2 / 91 packages / 150 manifest
files and exact runtime, source-limit, export, responsive, and semantic receipts;
the other six companions remain at their baseline state. A future companion deploy can otherwise publish a different
app than the repository appears to describe, or fail at startup.

Additional suite-wide findings (baseline unless a later pass update is stated):

- At baseline, only the Driver repository had `AGENTS.md` and a durable
  `docs/BUILD-TEST-HANDOFF.md`. Small Mammal, Phenology, and Plant Diversity now
  have app-local governance, handoff, and Driver knowledge-package artifacts; the
  other six companions still lack them.
- At baseline, four companions had one helper test script and five had none. Small
  Mammal, Phenology, and Plant Diversity now run product-specific science,
  portability, client-handler, exact-release, and semantic-health gates; the other
  six retain their baseline test debt.
- Most companion workflows use moving action tags and a moving package snapshot,
  combine build/validation/publish in one write-enabled job, and do not reproduce
  the Driver's loaded BLAS/thread receipt.
- Weekly scheduled runs can finish successfully in seconds because a date gate
  skipped the work. That is a skip, not fresh release-health evidence.
- Baseline post-deploy checks were not content-aware. Small Mammal, Phenology, and
  Plant Diversity now require app-specific semantic markers and exact release
  receipts while rejecting Posit error pages; the pattern remains to be ported to
  the other six companions.
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
| 2 | Plant Phenology Explorer | **COMPLETE / PRODUCTION VERIFIED**; corrected plant-year opportunity, onset unavailability/censoring, deterministic derived artifacts, and release trust without changing Driver bytes |
| 3 | Plant Diversity | **COMPLETE / PRODUCTION VERIFIED**; separated composition, invasion, richness, cover, and productivity; closed nested-grain/opportunity/panel/source-limit contracts without changing Driver bytes |
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
  palette, field motif/art direction, status, and Driver disposition;
- `suite-copy.json`: one canonical short description and role statement per app;
- generated below-fold cover destinations and in-app Suite panel;
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

Every cover page as a whole and every About panel should answer: `What is this
app?`, `What role does it play in the suite?`, and `How can it inform Driver?` The
poster face does not need to answer all three; those answers can sit below the fold.
The third answer may be `context only`.

## 6. Visual and cover system

### Working direction — pending owner approval

The cover face is an artistic poster for a curious non-scientist, not a compressed
methods page. Above the fold, use only:

1. one dominant app-native object or field motif;
2. one 3–7 word hook;
3. one 6–12 word plain-language promise; and
4. one primary CTA.

Do not place metric bands, methods summaries, CAN/CANNOT detail, provenance blocks,
release receipts, relationship maps, or secondary actions on the poster face. Put
those trust and science surfaces below the fold, where they remain easy to find and
screenshot-safe at the point of interpretation. The final direction is not locked
until the owner approves a real suite cover review.

### Family cohesion without repetition

- Cohesion comes from a subtle suite mark, typography, art language, app-specific
  palette, related field-motif families, the versioned registry, and the in-app
  Suite panel—not identical hero shells, a forced star map, or a mascot on every app.
- Each companion gets one product-native visual idea strong enough to recognize at
  a glance. Plant may use nested quadrat/flower motifs; Phenology a bud/seasonal arc;
  Mammals a trap or track rendered as art rather than fake field documentation.
- Driver is the master poster and suite ambassador: companion field motifs converge
  into one cascade/integration gesture. This is a visual relationship, not a causal
  claim.
- Historical Small Mammal documentary V4 and Phenology/Plant generated-art releases
  remain factual release baselines, but all are subject to the new poster review
  before suite-wide art is standardized.
- Compose and validate a separate 1200×630 social image; never treat a hero crop as
  the social design by default.

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
  About navigation, and a versioned 1200×630 habitat social card.
- Validated the canonical R 4.5.2 / 91-package / 117-file manifest, including the
  distinction between installed URL-package provenance and Connect's absolute-CRAN
  network contract. Final SHA-256 is
  `f6c4a5ff74053b95e22fac7394f1930d2fe2329663737031b1c32f7a1f70bc54`.
- Driver disposition is `CONTEXT / NO BYTE CHANGE`: contract parity is closed, but
  exact eligible-source site-year join/support remains held for suite synthesis.
- Cover V4 replaced the generic generated habitat scene with a provenance-tracked
  USGS public-domain field photograph of a Pacific pocket mouse emerging from a
  Sherman trap. Its question-led routes, concise method/claim boundary, release
  receipt, and complete suite navigation make documentary credibility and user
  intent lead the story rather than decorative product prose.
- Final Pages/browser QA passed desktop, 390 x 844, and 320 x 800 with no page-level
  overflow, local image and social-card assets loaded, stable navigation/touch
  targets, and all suite destinations present. Repository closeout is `b05cecc`;
  the scientific Connect runtime remains the separately verified `1615ab4`.

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
| Responsive | stable desktop, tablet, 390px, and 320px geometry plus both sides of every app-specific breakpoint seam; no persistent overflow, clipped status, or sub-44px control |
| Accessibility | automated scan plus keyboard and screen-reader-name checks; color is not the only channel |
| Publish | green PR head, merge commit, deployed identity, content-aware app-ready marker, console/network health |
| Social/cover | canonical metadata, separately composed 1200×630 card, asset checksum, alt text, every suite link, accurate availability copy |
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
