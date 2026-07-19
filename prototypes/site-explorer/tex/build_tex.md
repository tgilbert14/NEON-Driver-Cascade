# Ground / bark textures (Rung 19)

The seven `*.jpg` here are **stylized textures generated with an image model** (nano-banana),
down-res'd to 256px, and **embedded into `walk.html` as inline data-URIs** (no external
requests — CSP-safe like everything else). They map only onto the **smooth surfaces** — the
ground plane (by biome bucket) and the tree trunks (bark) — never the flat-shaded canopy, so
they enhance rather than fight the low-poly look.

- **Ground (by bucket):** `forest`, `grassland`, `dryland`, `tundra`, `other`
- **Bark (by tree shape):** `barkconifer`, `barkdecid`

Only these small derived JPEGs are committed; the multi-MB raw generations are not.

## Regenerate

Generate a square, **top-down, seamless/tileable** image with **flat even shadowless lighting**,
**muted & stylized**, **no objects/shadows**, filling the frame. Prompts used:

- **forest** — temperate forest floor: pine needles, fallen leaves, moss patches, bare soil; muted greens/browns.
- **grassland** — dry tallgrass prairie ground: short dry grass over warm soil; muted tan/olive.
- **dryland** — Sonoran desert ground: fine sandy soil, scattered gravel, cracked earth; muted warm sand.
- **tundra** — arctic tundra: low mossy mat, lichen, small frost-heaved pebbles; muted olive-grey/ochre.
- **other** — mixed meadow: patchy grass over soil with a few small stones; muted natural.
- **barkconifer** — Douglas-fir/pine bark: deep vertical furrows, reddish-brown (vertical tiling).
- **barkdecid** — oak/maple bark: grey-brown ridged (vertical tiling).

Then:

```bash
python3 proc_tex.py <raw.png> tex/<name>.jpg 256   # down-res to a tileable 256px JPEG
python3 embed_tex.py                                # refresh the <script id="texData"> block in walk.html
```

The scene loads `texData` at runtime (`TEX{}`), applies each ground map by bucket in `groundMesh()`
(repeat ≈ 58) and each bark map on the trunks (repeat 2×6). If a texture is absent, that surface
falls back to its flat colour with no other change.
