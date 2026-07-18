# Site Explorer — "What drives this place?" (Rung 1 prototype)

A **design prototype**, not a published NEON product. It demonstrates the public-facing,
audience-expansion track proposed alongside the pass-10 gap audit
([`docs/COMPLEMENTARY-APP-GAP-AUDIT.md`](../../docs/COMPLEMENTARY-APP-GAP-AUDIT.md)): reframing the
suite from a scientist's question (*"does bottom-up cascade theory hold across NEON?"*) to a citizen's
question (*"what is this place, and what makes it tick?"*).

## The idea (Rung 1 of the concept ladder)

- **Place first, mechanism second.** Pick a site and the whole page repaints in that biome's world
  (atmospheric hero, per-site accent palette, a year-rhythm wheel). The sense of place is the hook.
- **Honesty as curiosity, not fine print.** Each driver is stated in plain language; the science —
  the `r / n / p`, the "we only have 7 years", the "we can't read this here yet" — hides one tap behind
  *"peel back the science."* The suite's honesty machinery becomes the interesting part instead of a
  disclaimer.
- **Web-first, VR-optional.** This is a single self-contained HTML page (no build, no framework, no
  network) so it runs on any phone or laptop — the accessible foundation the immersive rungs (living
  site → walkable 3D → WebXR) grow from.

## What's real vs. illustrative

Three contrasting sites are wired: **SRER** (Sonoran desert), **KONZ** (tallgrass prairie), **SCBI**
(eastern deciduous forest). Direction and strength of every driver are honest to the Driver Response
Atlas' published takeaways (e.g. temperature → green-up as the one robustly pooled rung; the
monsoon → next-year-rodents lead as *suggestive, one site, n = 7*). Exact values are **representative**
and would be read live from the committed `data/cascade.rds` bundle in a real build.

## Run it

Open `index.html` in a browser, or view the hosted Artifact. It is intentionally dependency-free.

## Verified

Driven headlessly in Chromium: 0 console errors / 0 page errors, all three site worlds swap palette +
content, the year-wheel captions and driver peel-backs work, dark theme is legible, and there is no
horizontal overflow at a 390 px mobile width.

Built by Desert Data Labs. Not affiliated with NEON / Battelle / NSF.
