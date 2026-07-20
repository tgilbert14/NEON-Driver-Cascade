#!/usr/bin/env python3
"""Assemble the shipped, self-contained plot.html from the scene template.

    plot.src.html  --(inline)-->  plot.html

The template carries four placeholders; this script fills them in:

  __THREE__       the Three.js r128 runtime
  __PLOTDATA__    the derived plot record (plot-srer048.json + div-srer.json)
  __GROUNDTEX__   the stylized desert ground texture (a data: URI)
  __GEOLAYERS__   the georeferenced NEON AOP layers (aerial photo + canopy height)

The three *heavy* embeds (Three.js, the ground texture, and the AOP layers) are
**reused verbatim from the existing committed plot.html** — exactly as they were
first inlined — so this script depends only on files that live in this directory
and is fully reproducible in a fresh clone. It needs no raw NEON data, no image
tiles, and no API token.

  Everyday edit loop:  edit plot.src.html  ->  python3 assemble_plot.py

To *regenerate* the derived data or the AOP layers from raw NEON downloads (rarely
needed), use the scratchpad recipes documented in build_plot.md:
  - build_plot.py -> plot-srer048.json   (needs the raw VST CSVs + an API token)
  - div_srer.py   -> div-srer.json       (needs the plant-diversity CSV + token)
  - geo_plot.py   -> the AOP crops        (needs the raw ortho/CHM GeoTIFF tiles)
Those three stay in scratchpad because they need bulk raw data that is not committed.
"""
import os, json

D = os.path.dirname(os.path.abspath(__file__))

# Encoding and line endings are explicit on purpose. Python's default text mode uses
# the locale encoding (cp1252 on this Windows host) and translates "\n" to "\r\n" on
# write. Either would corrupt this build: the pages carry UTF-8 (em dashes, degree
# signs, times signs) and .gitattributes pins these files to `eol=lf`. Reading as
# cp1252 mangles the text; writing without newline="" rewrites every line ending and
# makes the output differ byte-for-byte between Windows and Linux.
def read_text(path):
    with open(path, encoding="utf-8", newline="") as f:
        return f.read()


def write_text(path, text):
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


old = read_text(os.path.join(D, "plot.html"))
src = read_text(os.path.join(D, "plot.src.html"))

# --- editable content (small, committed JSON) -------------------------------
data_obj = json.loads(read_text(os.path.join(D, "plot-srer048.json")))
try:
    data_obj["siteDiv"] = json.loads(read_text(os.path.join(D, "div-srer.json")))  # SRER site-level ground/herb cover
except Exception as e:
    print("  (no div-srer.json:", e, ")")
# ensure_ascii=False keeps the UTF-8 text as UTF-8 (matching the page's charset)
# rather than expanding it into \uXXXX escapes; sort_keys makes the embed stable
# so re-running with unchanged inputs is a no-op diff.
data = json.dumps(data_obj, ensure_ascii=False, sort_keys=True)

# --- heavy embeds: reuse verbatim from the existing plot.html ---------------
def script_body(html, opener):
    """Return the text between `opener` (a full <script...> tag) and its </script>."""
    i = html.index(opener) + len(opener)
    j = html.index("</script>", i)
    return html[i:j]

# THREE: the first bare <script>...</script> after the sky-view backlink anchor
anchor = "&larr; back to the map</a>"
tj_open = old.index("<script>", old.index(anchor)) + len("<script>")
three = old[tj_open:old.index("</script>", tj_open)]

gtex = script_body(old, '<script id="groundTex" type="application/json">')
geo = script_body(old, '<script id="geoLayers" type="application/json">')

# sanity: the extracts must look like what we expect before we write anything
assert len(three) > 100000, "three.js extract looks wrong (%d bytes)" % len(three)
assert gtex.startswith('"data:image') or gtex.startswith("data:image"), "groundtex extract looks wrong: %r" % gtex[:40]
assert '"ortho"' in geo and '"chm"' in geo, "geoLayers extract looks wrong: %r" % geo[:60]

out = (src.replace("__THREE__", three)
          .replace("__PLOTDATA__", data)
          .replace("__GROUNDTEX__", gtex)
          .replace("__GEOLAYERS__", geo))

# sanity: the exact placeholder TAGS from the template must be gone.
# (three.js itself contains the token "__THREE__" internally, so check the tags, not bare tokens.)
for ph in ("<script>__THREE__</script>", ">__PLOTDATA__<", ">__GROUNDTEX__<", ">__GEOLAYERS__<"):
    assert ph not in out, "placeholder tag %s not replaced" % ph

write_text(os.path.join(D, "plot.html"), out)
print("wrote plot.html: %d bytes (three=%d, data=%d, gtex=%d, geo=%d)" % (
    len(out), len(three), len(data), len(gtex), len(geo)))
