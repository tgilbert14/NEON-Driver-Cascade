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
- [2026-07-20] connor · confirmed · This app's manifest gate is SEMANTIC: `compare_manifests.R` projects
  each manifest to files→checksum + package `{source, name, version}` + `locale`/`platform` and IGNORES
  `Built`, the CRAN/RSPM repo label, and descriptive noise — so it is immune to source-compile timestamp
  churn by design (verified by reading `manifest_reproducibility_projection`). The byte-exact siblings
  neutralize the SAME churn a different way: the §6 byte-determinism recipe (strip `Built`, pin `locale`, so
  `git diff` is stable) + the `Regenerate manifest (manual)` workflow for the no-local-R case. **Both work
  — the siblings already stopped flapping**, so adopting this semantic projection there is a ROBUSTNESS
  upgrade (tolerates future non-semantic churn without needing a perfectly-deterministic writer), NOT an
  urgent fix; converge when convenient. The five canonical Driver DATA artifacts stay byte-gated
  (`git diff --exit-code`), which is correct.
- [2026-07-20] cass · confirmed · This is a DERIVED app: `data/cascade.rds` is built FROM sibling bundles.
  CI must `git clone --depth 1` each sibling by its REAL slug (not dir name), copy `data/`, run
  `build_cascade.R`, and commit the derived `.rds`. A sibling that hasn't published a fresh bundle breaks or
  staleness-poisons the build — check sibling freshness before a rebuild. Do NOT blindly copy a sibling's
  `Regenerate manifest` workflow here; the derived build is different.
- [2026-07-20] neonize · gap · Branch default here is `master` (Connect Cloud watches it); the other suite
  apps are `main`. Do not rename without FIRST repointing the external Connect watched-branch setting and
  updating `ci.yml:6` + `refresh-data.yml` (lines ~30/234/243/250-251/301-303, incl. `git push origin
  HEAD:master`) + `DEPLOY.md`. Documented per-repo instead, per owner decision.
