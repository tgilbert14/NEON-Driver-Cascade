# NEON Driver-Cascade — working context for Claude

> Read this first. It orients an agent that boots cold in this repo. Depth lives in the docs it points at.
> This is a **Desert Data Labs (DDL)** project; the DDL business context + the full agent suite live in the
> `TG-Data-Apps` repo (and in user scope, so every agent is available here too).
>
> **Worked by more than one agent (Claude Code + ChatGPT/Codex).** The tool-neutral source of truth is
> `docs/neonize-playbook.md`, `docs/NEON-SUITE-LEARNING-LOOP.md`, `docs/NEON-SUITE-REVAMP-PLAN.md`,
> `docs/BUILD-TEST-HANDOFF.md`, and `AGENTS.md` — read those first; `CLAUDE.md` / `AGENTS.md` only add
> tool-specific notes on top. Close every session with a dated `BUILD-TEST-HANDOFF.md` entry tagged with
> your tool (`[Claude]` / `[Codex]`) and a one-line next action, so the other agent can pick up cold.
>
> **Before you code: plan, question, and challenge the work** — and always name at least one improvement
> you spot. The how-we-work principles are the flagship `NEON-Small-Mammal-Tracker-App` playbook §9.

## What this is

The **NEON Cross-Product Response Atlas** — an exploratory cross-product weather→response atlas across the
DDL **NEON explorer suite**, and the suite's **ambassador** (every companion cover routes here). It is a
**DERIVED app**: its `data/cascade.rds` is built FROM the sibling apps' bundles, not from a raw NEON pull.

## The stack + how it deploys (load-bearing facts)

- **Default branch: `master`** (watched by Posit Connect Cloud — a push/merge to `master` is the deploy).
  ⚠️ Branch defaults are SPLIT across the suite: **this repo is `master`**; Small Mammal + Vegetation are
  **`main`**. Never assume — target this repo's `master`. Documented, **not renamed**, per owner decision:
  a rename would first require repointing the external Connect Cloud watched-branch setting and updating
  `ci.yml` + `refresh-data.yml` (which does `git push origin HEAD:master`).
- **Derived build.** CI `git clone --depth 1`s the sibling repos by real slug, copies their `data/`, runs
  `scripts/build_cascade.R`, and commits the derived `.rds` + `manifest.json`. A push to `master` deploys.
- **The terra/GDAL landmine.** Same as the suite: pin **terra 1.8-50** + the geospatial closure; the
  manifest records the actual installed versions; never hand-edit Version/RemoteSha.
- **The manifest gate here is SEMANTIC, not byte-exact — the better pattern.** CI uses
  `scripts/compare_manifests.R` to require the deploy manifest to reproduce *semantically* (same package
  identity / versions / checksums) rather than a `git diff --exit-code` on raw bytes, so it does NOT flap on
  non-deterministic source-compile `Built` timestamps the way the byte-exact sibling gates do. The five
  canonical Driver artifacts (cascade / search / meta / codebook / manifest) are still byte-gated as DATA.
  This semantic-comparison approach is a candidate to promote to the byte-exact siblings — see LESSONS.

## Which agents own what here

- **`cass`** — the cross-product Driver-Cascade synthesis (the domain owner here). **`neonize`** — suite
  methodology. **`connor`** — Connect deploy + manifest correctness. **`hk`** and its stats team — the
  statistics. Call them by name; they're installed in user scope.

## The learning loop

- **`.claude/agents/LESSONS.md`** — project-local, one-line lessons; read on cold boot, append after a
  durable run. Canonical cross-cutting log: `TG-Data-Apps`; `curator` promotes recurring lessons up (and
  turns proven patterns into skills — playbook §9).
- **`docs/neonize-playbook.md`** + **`docs/NEON-SUITE-LEARNING-LOOP.md`** + **`docs/NEON-SUITE-REVAMP-PLAN.md`**
  — the suite methodology and cross-product register live here; this repo is the suite hub.

## Working notes

- **Prototypes under `prototypes/` are OUTSIDE the build surface** (not in `manifest.json`'s allowlist), so
  changes there don't touch the deploy — but keep them honest (real data, provenance, no invented numbers).
- **Honesty discipline:** the caveat goes ON the number; Driver artifacts change only when the evidence and
  an explicit disposition (`ADOPT` / `HOLD` / `CONTEXT` / `COMPLEMENT` / `REJECT` / `NONE`) authorize it.
