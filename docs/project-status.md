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
  `docs/BUILD-TEST-HANDOFF.md`, entry 2026-10-21. Finish lanes (ops, copy, and others) are being
  integrated onto this branch by the lead. Merging it is a deploy.
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

The lead will finish the reasons and owners for each item.

- **`dataCollected = partial` surveys:** held until the Vegetation app records per-channel completeness.
- **Protocol stem locator (`tempStemID`):** not used.
- **"small tree" appearing in both size specs:** deferred.
- **The classifier's occupied-plot denominators:** deferred.
- **An upper diameter screen:** deferred.
- **The zero-fill basal-area estimator:** deferred.
- **Deriving `last_complete_year` from release coverage:** deferred.
- **The temperature sentinel screen:** deferred.
- **The Small Mammal month-adjusted index:** deferred.
- **Vegetation contract v3 support (Vegetation PR #19):** deferred.
- **The first data refresh:** held until the sibling PRs land.
- **A weekly refresh dry run (audit appendix F4):** decided against on 2026-10-22. It would change the
  calendar block every suite repo shares; failures already reach a person through the "Atlas refresh
  failed" issue and the suite watch in TG-Data-Apps #142.
