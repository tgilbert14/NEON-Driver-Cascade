# LESSONS — NEON Driver-Cascade (project-local)

> Project-specific institutional memory for THIS app. Agents boot cold: read this on start (grep for your
> own name, `· <agent> ·`) and append a one-line lesson after a run that taught something durable.
>
> The **canonical, cross-cutting** log lives in `TG-Data-Apps/.claude/agents/LESSONS.md`; the deep NEON
> methodology lives in `docs/neonize-playbook.md` (the flagship `NEON-Small-Mammal-Tracker-App` copy is the
> reference for §6–9). `curator` promotes recurring lessons up. Format + protocol:
> `TG-Data-Apps/.claude/agents/_CONVENTIONS.md`.

## How to write an entry
```
- [YYYY-MM-DD] <agent> · <verdict: confirmed|over-flagged|wrong|gap> · <the durable lesson, one line>
```

## Lessons

<!-- newest at the bottom; append, don't rewrite history. Seeded 2026-07-20 from the cross-agent pass. -->
- [2026-07-20] connor · confirmed · This app's manifest gate is SEMANTIC (`scripts/compare_manifests.R`,
  "reproduce semantically"), not a byte-exact `git diff --exit-code` on `manifest.json`. That sidesteps the
  non-deterministic source-compile `Built`-timestamp flapping that forces the byte-exact merge loop in the
  Small Mammal / Vegetation siblings. **Candidate improvement to promote:** evaluate adopting this semantic
  comparison in the siblings so their gate stops flapping at the root — deeper than the byte-determinism
  recipe + the `Regenerate manifest (manual)` workflow band-aid. The five canonical Driver artifacts stay
  byte-gated as DATA (`git diff --exit-code` on cascade/search/meta/codebook), which is correct.
- [2026-07-20] cass · confirmed · This is a DERIVED app: `data/cascade.rds` is built FROM sibling bundles.
  CI must `git clone --depth 1` each sibling by its REAL slug (not dir name), copy `data/`, run
  `build_cascade.R`, and commit the derived `.rds`. A sibling that hasn't published a fresh bundle breaks or
  staleness-poisons the build — check sibling freshness before a rebuild. Do NOT blindly copy a sibling's
  `Regenerate manifest` workflow here; the derived build is different.
- [2026-07-20] neonize · gap · Branch default here is `master` (Connect Cloud watches it); the other suite
  apps are `main`. Do not rename without FIRST repointing the external Connect watched-branch setting and
  updating `ci.yml:6` + `refresh-data.yml` (lines ~30/234/243/250-251/301-303, incl. `git push origin
  HEAD:master`) + `DEPLOY.md`. Documented per-repo instead, per owner decision.
