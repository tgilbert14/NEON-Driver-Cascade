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
- [2026-07-21] cass · confirmed · Botanical model quality (site-explorer `plot.src.html`): two reusable
  patterns proved out on saguaro + Christmas cholla. (1) SWEEP-ONE-TUBE — a single Frenet-framed
  BufferGeometry (`saguaroFlesh`) that ribs+tapers+per-vertex-colours a tube along any curve serves BOTH a
  cactus trunk AND its arms; arms that grow OUT of the trunk (curve base embedded ~0.28×trunkR inside)
  read as connected with NO stuck-on shoulder sphere. (2) BAKE-AND-MERGE — a plant made of dozens of tiny
  meshes (cholla: ~60 cylinders/spines/berries) becomes ≤5 draw calls by baking each part's transform into
  its geometry (`geo.applyMatrix4(compose(pos,quat,scale))`) and concatenating per material; safe & exact
  because these mats use flatShading (normals ignored). 53 dense chollas → 355 total draw calls, <1 s load.
  Gotcha that made cholla read as "scattered sticks": orienting a segment with `rotation.set(cos*tilt,az,
  sin*tilt)` (Euler) does NOT point it along the dir vector used to place its child — use a quaternion
  `setFromUnitVectors(UP, dir)` so tip==child-base. A gated `?dbg` hook (exposes scene/camera/buildPlant +
  a walk-cam setter) lets a headless Playwright harness verify models IN the real plot scene/grade, not
  just a standalone harness — the plot's filmic tone-map shifts colours enough that harness-only tuning lies.
- [2026-07-21] cass · confirmed · Saguaro botanical realism (site-explorer): a swept-tube cactus reads as a
  real Carnegiea when the FLUTES are organic, not machined. In `saguaroFlesh`, drive the rib at a drifted
  angle `thE = th + twist·t + wob·sin(1.7·2π·t+φ) + warp·sin(2·th+φ)` and modulate per-rib DEPTH by a
  seamless hash `ribDepth(round(ribCount·thE/2π) mod ribCount)` — ribs then spiral/wander/converge and vary
  in depth (no dead-straight uniform grooves). Depth needs real amplitude: ribAmp≈0.13 + ribPow≈1.15 (sharp
  valleys) + vertex-colour AO `0.62+0.38·rib^0.8` to throw shadow. Arms read as candelabra (not a bent
  elbow) via a 5-pt CatmullRom: embedded base → shoulder reaching out with only a SLIGHT sag → elbow at
  branch height just turning up → smooth sweep → tip drawn back toward the trunk (parallel). Keep the
  shoulder sag small (dip≈armR·0.15–0.45) or the arm droops and re-enters the trunk (self-intersection
  hole). Spread arm azimuths (`azBase + i·2π/n`) and stagger heights (0.40–0.76·colH) so many-arm plants
  don't tangle. Base variety must sit ABOVE grade: `swell·exp(-t·4.5)` (not exp(-t·10), which buries it).
  Two agent critic rounds (view renders → rank fixes) converged this; the reference-photo tells (curved
  arms, wandering shadow-lines, pinched/swollen bases, cristate crest) all map to explicit params.
