#!/usr/bin/env python3
"""Re-inline the generated data into the shipped, self-contained index.html.

    site-data.json + map-data.json  --(inline)-->  index.html

index.html ships as one self-contained file: its two data blocks are embedded as

  <script id="siteData" type="application/json"> ... </script>
  <script id="mapData"  type="application/json"> ... </script>

Previously PROGRESS.md documented this step as "then inline site-data.json /
map-data.json into index.html", i.e. a manual paste. A hand paste is not a build
step: it cannot be verified, and a stale block silently desyncs the page from the
data it claims to render. This script makes the step reproducible and idempotent.

  Everyday loop:  python3 export_data.py  ->  python3 assemble_index.py

Only the *contents* of the two tagged blocks are replaced; every other byte of
index.html is preserved exactly, so this is safe to re-run and produces no diff
when the data has not changed.
"""
import os, re, json, sys

D = os.path.dirname(os.path.abspath(__file__))
INDEX = os.path.join(D, "index.html")
BLOCKS = (("siteData", "site-data.json"), ("mapData", "map-data.json"))


def load_compact(path):
    """Parse then re-serialize, so a malformed JSON file fails here, loudly,
    rather than being embedded and breaking the page at runtime."""
    with open(path, encoding="utf-8") as f:
        return json.dumps(json.load(f), ensure_ascii=False, separators=(",", ":"))


def main():
    with open(INDEX, encoding="utf-8") as f:
        html = f.read()
    before = html

    for tag, fname in BLOCKS:
        path = os.path.join(D, fname)
        if not os.path.exists(path):
            sys.exit("missing required data file: %s" % fname)
        payload = load_compact(path)
        pat = re.compile(
            r'(<script id="%s" type="application/json">)(.*?)(</script>)' % re.escape(tag),
            re.DOTALL,
        )
        if not pat.search(html):
            sys.exit('could not find <script id="%s"> block in index.html' % tag)
        html, n = pat.subn(lambda m: m.group(1) + payload + m.group(3), html, count=1)
        if n != 1:
            sys.exit("expected exactly one %s block, replaced %d" % (tag, n))
        print("inlined %-14s -> #%s (%d bytes)" % (fname, tag, len(payload)))

    if html == before:
        print("index.html already current — no change")
        return
    with open(INDEX, "w", encoding="utf-8", newline="") as f:
        f.write(html)
    print("wrote %s (%d bytes)" % (INDEX, len(html)))


if __name__ == "__main__":
    main()
