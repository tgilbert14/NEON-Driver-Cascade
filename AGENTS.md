# Repository operating instructions

These instructions apply to the entire repository. User and platform instructions
take precedence.

This repository is worked by more than one agent — ChatGPT/Codex via this file and Claude
Code via `CLAUDE.md`. The tool-neutral source of truth is `docs/neonize-playbook.md`,
`docs/NEON-SUITE-LEARNING-LOOP.md`, `docs/NEON-SUITE-REVAMP-PLAN.md`, and
`docs/BUILD-TEST-HANDOFF.md`; read those first and keep tool-specific notes to this file.
Close every session with a dated `BUILD-TEST-HANDOFF.md` entry tagged with your tool
(`[Codex]` / `[Claude]`) and a one-line next action. Before coding: plan, question, and
challenge the work, and always surface at least one improvement — see the flagship
`NEON-Small-Mammal-Tracker-App` playbook §9. Branch defaults are split across the suite:
**this repo is `master`** (Connect Cloud watches it); Small Mammal and Vegetation are
`main` — never assume.

## Mandatory entry point

Before inspecting, changing, testing, rebuilding, or reporting on this repository,
read `docs/BUILD-TEST-HANDOFF.md` completely. Treat it as the durable cross-session
record of the current build state, scientific pins, required test matrix, known
failures, residual risks, and next action.

## Suite learning continuity

For any session that changes a product definition, estimator, data contract, QC
rule, shared UI/build pattern, publication pattern, or possible Driver input, also
read `docs/NEON-SUITE-LEARNING-LOOP.md` completely before acting. That file is the
central program register for the nine sibling-app passes, the optional
complementary-product decision, and Driver v2 reintegration.

Every suite-relevant session must classify its result as app-local,
suite-platform, scientific-contract, and/or Driver-impacting, then update the
central evidence register and Driver implication backlog before its final report.
Record an explicit `NONE` when no Driver implication exists; silence is not a
decision. When work moves to a sibling repository, install the equivalent local
instruction there: update its own handoff every session and update this Driver
repository's central register at the end of each completed app pass. Chat history
is never the only copy of a reusable lesson or test process.

## Non-negotiable rules

1. Start and end with `git status --short`. The worktree may intentionally contain
   extensive uncommitted work. Inspect and preserve changes you did not create;
   never reset, discard, overwrite, or "clean up" unrelated work.
2. Before a long rebuild, check for `.cascade-rebuild.lock`, a running rebuild, and
   other active work. Do not edit the captured code surface (`R/`, `scripts/`,
   `www/`, or the top-level runtime/configuration files named in the handoff) while
   `scripts/rebuild_all.R` is running. Coordinate instead.
3. The only supported artifact-generation entry point is:

   ```powershell
   & 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe' --vanilla scripts/rebuild_all.R
   ```

   Do not invoke individual artifact writers to publish live outputs. Do not bypass
   the generation guard, source snapshot, validation stages, manifest-last
   promotion, or rollback path.
4. Do not weaken scientific fail-closed behavior, source provenance checks,
   manifest policy, strict trusted standard-CRAN provenance (including only
   independently validated canonical CRAN/RSPM representations), checksum
   enforcement, workflow
   SHA pins, or runtime boot-integrity checks to make a failing environment pass.
5. Never declare the repository, build, release, deployment, or artifact family
   "done" unless every applicable row in the handoff's completion matrix has dated
   passing evidence. Report skipped, blocked, or not-applicable rows explicitly.
6. Every repository session must update `docs/BUILD-TEST-HANDOFF.md` before its
   final report, including read-only reviews, failed attempts, and sessions that
   make no product change. Use `YYYY-MM-DD HH:mm TZ - scope/owner`; record what was
   learned, the exact reproducible test process and environment, expected versus
   actual results, artifact generation/hashes or explicit non-impact, invalidated
   evidence, failure cleanup, residual risks, and the next concrete action. Promote
   reusable lessons into the canonical sections instead of leaving them only in a
   chronological note. Never record credentials, tokens, environment dumps,
   temporary capability values, data payloads, guesses, or unverified conclusions.
7. Re-read the latest handoff immediately before editing it. With concurrent agents
   or sessions, designate one coordinating editor; every other participant reports
   its evidence to that editor so concurrent entries are merged rather than
   overwritten.
8. Documentation-only work may be reported complete at that narrow scope after its
   documentation checks pass. It does not make the product or release complete.
