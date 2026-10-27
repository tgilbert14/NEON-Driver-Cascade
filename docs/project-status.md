# Project Status: NEON Cross-Product Response Atlas (NEON-Driver-Cascade)

As of: 2026-10-22 · Version: `master` @ `5316a3f` (PR #78 merge) · Stage: live, frozen exploratory v1
snapshot; the Wave 2 stack waits in PR #80.

> Shape follows the TG-Data-Apps hub's `docs/project-status.md` (Now / Next / Deliberately deferred).
> Cold-boot agents: read this before flagging. The **Deliberately deferred** section is binding: do not
> re-flag an item there unless its stated condition has changed. Session history lives in
> `docs/BUILD-TEST-HANDOFF.md`; this file is the current state only.

## What is live

- **App:** Posit Connect Cloud, git-backed on `master`
  (https://019ee1cf-a484-44eb-a181-cd495df24b3b.share.connect.posit.cloud/). As of 2026-10-22 it still
  serves the pre-#80 code: page title "NEON Response Atlas", and its `www/` assets match `master`'s bytes.
- **Cover:** GitHub Pages from `docs/index.html` (https://tgilbert14.github.io/NEON-Driver-Cascade/),
  title still "NEON Response Atlas · Desert Data Labs".
- **Data:** the committed family (`data/cascade.rds`, `search_index.rds`, `cascade_meta.rds`,
  `neon-cascade-codebook.csv`, plus `manifest.json`), source-state timestamp 2026-07-03 17:52:46 UTC.

## In flight

- **PR #80** (`claude/atlas-veg-event-adapter`, open): lands the Wave 2 stack on `master` (#76, #77,
  #79): the name "NEON Cross-Product Response Atlas", the four-tab app (This site, One pairing, All sites,
  About), and the event-aware Vegetation adapter that supersedes the PR #78 spec. Its rulings are in
  `docs/BUILD-TEST-HANDOFF.md`, entry 2026-10-21. The 2026-10-22 finish work is on the same branch: the
  suite registry, PDF report, pin cards, QC flags, truncated Knapp-Hartung, per-product release labels,
  the refresh failure issue, and the revision-proving post-deploy check. Merging it is a deploy.
- **PR #81** (`claude/atlas-coverage-overrides-first-refresh` -> `master`, open): approves the three
  coverage-gate refusals for the first Atlas refresh, as rows in `data/coverage-overrides.tsv`.

## How a refresh works

1. `.github/workflows/refresh-data.yml` fires every Saturday 13:17 UTC; the suite's shared calendar
   block in the `gate` job lets only the second Saturday of the month proceed (a manual dispatch always
   proceeds). The gate's step summary also lists open `automation/*` review branches in the seven
   sibling repos.
2. `rebuild` (no write token) fetches the seven SOURCE_LOCK origins at their default-branch heads,
   runs `scripts/rebuild_all.R`, then the coverage gate (`scripts/check_coverage_regression.R` against
   the committed baseline, with reviewed overrides keyed to the exact candidate sibling commit). A
   refusal stops the run before anything is staged.
3. Four data files and a SHA-256 receipt pass to `validate-artifacts`, a fresh read-only job that
   reruns the contracts.
4. `publish` verifies the receipt without deserializing RDS, refreshes manifest checksums (the
   package graph and all text outside the files map must stay byte-identical), and pushes the review
   branch `automation/atlas-data-refresh`. It never pushes `master`.
5. A person opens or updates the PR, approves its checks on the exact head, and merges. **The merge is
   the deploy.** `post-deploy.yml` then requires the cover and app titles, `lang="en"`, the About tab's
   `built_when`, and served `www/` asset md5s equal to the pushed files.
6. A failed scheduled run opens or comments on the issue "Atlas refresh failed"; the next scheduled run
   that passes every job closes it.

## Now

- [ ] Land PR #80 (lead integrates the finish lanes; owner merges). The first post-deploy run after it
  is the first live test of the title and asset-revision checks.
- [ ] Decide PR #81, then run the first data refresh once the sibling PRs land (see deferred below).

## Deliberately deferred (DO NOT re-flag: decided, with the reason)

Each item names its owner and the condition that reopens it.

- **`dataCollected = partial` Vegetation surveys:** held (ruling R7). NEON records the woody scope of a
  partial survey only in free text; 50 of 57 are woody-complete, 7 are not. Cost: JERC 29 to 20 plots
  (basal area -1.6%), OSBS 41 to 39. Reopens when the Vegetation app ships a per-channel completeness
  field (cedar), or Tim approves a reviewed allowlist of the 50 JERC and OSBS events.
- **Protocol stem locator (`tempStemID`):** not used. It is blank on 4.3% of rows and moves only BONA
  (0.45%) and DCFS (0.2%); adopting it without cross-day de-duplication would double count BONA_079 and
  GUAN_011 (cedar). Reopens with Vegetation contract v3's multi-bole rules.
- **"small tree" in both size specs:** kept for this adoption so one thing changes at a time; dropping it
  moves NIWO +4.1% and shrub classification evidence by up to 4.3% (hk, cedar). Owner: cass.
- **The classifier's occupied-plot denominators** (MOAB forest from 3 of 42 plots, ONAQ from 6 of 47):
  owner decision with the zero-fill estimator below.
- **An upper diameter screen:** none in either path; BONA includes a 172 cm aspen (about +6% of its
  value). Adopt the Vegetation app's size-plausibility screen when its v3 bundles carry it (cedar).
- **The zero-fill basal-area estimator (appendix F14 step 2):** owner decision for cedar, cass and hk.
  Zero-filling over area-eligible plots would move MOAB 11.50 to 0.82 and ONAQ 12.92 to 1.65 (flipping it
  to shrubland). Cedar must first show sampled-zero plots can be told from unsampled ones.
- **Deriving `last_complete_year` from release coverage (appendix F16):** decided 2026-10-22 to keep 2025
  and label it `provisional_from`. Deriving it would set 2024 and drop 46 display-only rows (2025
  climate, bird_index, fruiting); cass measured no link, tier, vote or pooled change. Revisit when
  RELEASE-2027 publishes and update the release-coverage constants in `R/source_adapters.R`.
- **The temperature sentinel screen (`temp_min <= -80` or `temp_max >= 55`):** owner decision for cass.
  It flags 383 months in 101 site-years, turns 11 annual temp and 5 March to May values NA, changes 15
  link counts and 3 tiers, and moves the March to May vote from 8/18 to 9/18; the temperature to
  green-up headline stays 15/18. cass recommends adopting it in a later family revision.
- **The Small Mammal month-adjusted index:** built 2026-10-26, keyed on the sibling's bundle schema 2
  (PR #101): `mammal_cpue` becomes the month-adjusted index when every site bundle carries
  `gridCompletion`, `samplingImpractical` and `eventID`, and stays pooled CPUE until then. The values
  arrive with the first refresh after that PR merges; the coverage gate will refuse the drop from 410 to
  364 finite site-years (years with under 3 sampled months or 300 trap-nights) until an override row
  approves it (`docs/MAMMAL-INDEX-DRYRUN-2026-10-26.md`).
- **Vegetation contract v3 support:** built 2026-10-26 against PR #19's real v3 bundles; no site moves
  against v2. Still open for cass and hk: whether the Atlas adopts the sibling's channel-complete reading
  of 53 partial events (JERC 25, OSBS 25, YELL 3) and its `duplicate_of_uid` flags (342 stand rows at BONA,
  TEAK and UKFS), both counted and not applied (`docs/VEGETATION-V3-DRYRUN-2026-10-26.md`).
- **The first data refresh:** held until the sibling PRs land, then a dry run, PR #81 re-keyed if any
  sibling commit moved, and a published refresh.
- **SRER's all-NA green-up:** recorded as the honest left-censor outcome; cass and iris to confirm.
- **The hero-card PNG export:** needs an html-to-image library this app does not ship.
- **A keyboard path to timeline pin cards:** timeline points have no picker yet (scatter cards do).
- **A weekly refresh dry run (audit appendix F4):** decided against on 2026-10-22. It would change the
  calendar block every suite repo shares; failures already reach a person through the "Atlas refresh
  failed" issue and the suite watch in TG-Data-Apps #142.
