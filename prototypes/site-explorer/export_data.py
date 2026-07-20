#!/usr/bin/env python3
"""Export the NEON Driver Cascade bundle to a compact JSON the Site Explorer reads.

Prototype tool. Reads ``data/cascade.rds`` (never rebuilds it) and emits
``prototypes/site-explorer/site-data.json`` with per-site real science
(suite_links r/n/p/tier), the pooled network result, and biome metadata for all
46 sites. In a production suite build this would be an R writer alongside
``scripts/build_search_index.R``; here it uses the pure-Python ``rdata`` reader
because the sandbox has no R. Requires: ``pip install rdata``.
"""
import json, math, warnings, os
warnings.filterwarnings("ignore")
import rdata

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BUNDLE = os.path.join(ROOT, "data", "cascade.rds")
OUT = os.path.join(HERE, "site-data.json")
NAMES = os.path.join(HERE, "neon-site-names.json")

# real NEON site names / states / coordinates, fetched once from the NEON API
# (https://data.neonscience.org/api/v0/sites) and committed for offline reproducibility.
try:
    with open(NAMES, encoding="utf-8") as f:
        SITE_NAMES = json.load(f)
except FileNotFoundError:
    SITE_NAMES = {}

def clean_name(nm):
    if not nm:
        return None
    return nm[:-5].rstrip() if nm.endswith(" NEON") else nm

p = rdata.read_rds(BUNDLE)
signals = p["signals"]; site_meta = p["site_meta"]; sl = p["suite_links"]; pooled = p["pooled"]
bmeta = p["meta"]


def scalar(v):
    """Unwrap a length-1 R vector that rdata surfaces as a numpy array."""
    try:
        return v.item() if hasattr(v, "item") and getattr(v, "size", 0) == 1 else v
    except Exception:
        return v


def bundle_sha256():
    import hashlib
    h = hashlib.sha256()
    with open(BUNDLE, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def source_products():
    """The exact sibling commits this bundle was generated from.

    ``scripts/build_cascade.R`` records one row per source product; CI re-reads the
    same table to fetch each sibling detached at that commit. Surfacing it here is
    what lets a reader of the Site Explorer say *which* vintage of each sibling app
    produced the numbers on screen.
    """
    sp = bmeta.get("source_products")
    if sp is None:
        return []
    rows = []
    for _, r in sp.iterrows():
        rows.append({
            "product": s(r["product"]), "repo": s(r["repo"]), "origin": s(r["origin"]),
            "commit": s(r["commit"]), "clean": bool(r["clean"]),
            "n_site_files": num(r["n_site_files"]),
        })
    rows.sort(key=lambda x: x["product"] or "")
    return rows

def s(x):
    if x is None: return None
    try:
        if isinstance(x, float) and math.isnan(x): return None
    except Exception:
        pass
    return str(x)

def num(x):
    try:
        f = float(x)
        return None if math.isnan(f) else f
    except Exception:
        return None

# --- signal label lookup ---
SIG = {}
for _, r in signals.iterrows():
    SIG[s(r["key"])] = {"label": s(r["label"]), "higher_is": s(r["higher_is"]),
                        "unit": s(r["unit"]), "layer": s(r["layer"])}

# --- plain-language claim per (from,to) driver pair ---
CLAIM = {
    ("temp", "greenup_doy"): "Warmer years, earlier leaf-out",
    ("temp_spring", "greenup_doy"): "Warm springs and the timing of leaf-out",
    ("precip", "plant_richness"): "Rain and how many plant kinds show up",
    ("precip", "mammal_cpue"): "This year's rain and next year's small mammals",
    ("precip_winter", "plant_richness"): "Winter rain and spring plant variety",
    ("precip_monsoon", "mammal_cpue"): "Summer rain and next year's small mammals",
    ("fruiting_pct", "mammal_cpue"): "A good fruiting year and next year's mammals",
    ("plant_richness", "mammal_cpue"): "Plant variety and next year's mammals",
    ("precip_monsoon", "mosq_activity"): "Summer rain and mosquitoes",
    ("temp_spring", "mosq_activity"): "Spring warmth and mosquitoes",
    ("temp_spring", "beetle_activity"): "Spring warmth and ground beetles",
    ("precip_monsoon", "beetle_activity"): "Summer rain and ground beetles",
}

def biome_bucket(label):
    l = (label or "").lower()
    if "forest" in l: return "forest"
    if "grass" in l or "prairie" in l: return "grassland"
    if "desert" in l or "shrub" in l or "sage" in l: return "dryland"
    if "tundra" in l or "alpine" in l: return "tundra"
    return "other"

# --- the pooled network headline (the one solid rung + the null it beats) ---
def pooled_row(frm, to):
    m = pooled[(pooled["from"] == frm) & (pooled["to"] == to)]
    if not len(m): return None
    r = m.iloc[0]
    return {"from": frm, "to": to, "sites": num(r["sites"]), "k": num(r["k"]),
            "p": num(r["p"]), "median_r": num(r["median_r"]), "poolable": bool(r["poolable"])}

network = {"solid": pooled_row("temp", "greenup_doy"),
           "null": pooled_row("temp_spring", "greenup_doy")}

# --- classify a per-site link into an honest strength chip ---
def classify(row):
    frm, to = s(row["from"]), s(row["to"])
    tier = s(row["tier"]); sign_match = bool(row["sign_match"]); expected = bool(row["expected"])
    context = (s(row["expected_class"]) == "none")
    is_pooled_rung = (frm == "temp" and to == "greenup_doy")
    if tier == "counter":
        chip = ["cool", "runs the other way here"]
    elif tier == "consistent":
        if is_pooled_rung and expected:
            chip = ["ok", "part of the one solid result"]
        else:
            chip = ["warn", "a clean direction here"]
    elif tier == "apparent":
        chip = ["warn", "a hint, not proof"]
    else:
        chip = ["cool", "too few years to say"]
    return chip, context, is_pooled_rung

FEATURED = {"SRER", "KONZ", "SCBI"}
sites_out = []
for _, sm in site_meta.iterrows():
    code = s(sm["site"])
    label = s(sm["biome_label"])
    links = sl[(sl["site"] == code)]
    drivers = []
    for _, row in links.iterrows():
        n = num(row["n"])
        if n is None or n < 6:
            continue  # only tested links (>=6 overlapping years) reach the public read
        key = (s(row["from"]), s(row["to"]))
        claim = CLAIM.get(key)
        if not claim:
            continue
        r = num(row["r"])
        chip, context, is_rung = classify(row)
        drivers.append({
            "claim": claim, "from": key[0], "to": key[1], "lag": num(row["lag"]),
            "r": r, "n": int(n), "p": num(row["p"]), "tier": s(row["tier"]),
            "lo": num(row["lo"]), "hi": num(row["hi"]),
            "expected": bool(row["expected"]), "context": context, "pooled_rung": is_rung,
            "chip": chip, "strength": max(15, min(100, round(abs(r or 0) * 100))),
        })
    # order: pooled rung first, then clean directions, then hints, by |r|
    trank = {"consistent": 0, "apparent": 1, "counter": 2, "": 3, None: 3}
    drivers.sort(key=lambda d: (0 if d["pooled_rung"] and d["expected"] else 1,
                                trank.get(d["tier"], 3), -abs(d["r"] or 0)))
    nm = SITE_NAMES.get(code, {})
    sites_out.append({
        "site": code, "domain": s(sm["domain"]),
        "name": clean_name(nm.get("name")), "state": nm.get("state"),
        "lat": nm.get("lat"), "lon": nm.get("lon"), "domain_name": nm.get("domainName"),
        "biome_label": label, "biome_class": s(sm["biome_class"]),
        "bucket": biome_bucket(label),
        # veg_ba_se and veg_design_status travel with veg_ba_ha so the walk can say how
        # certain the standing-wood figure is, and whether the site's design is supported
        # at all. veg_type is the DBH-vs-basal-diameter paradigm tag: tree and shrub
        # basal areas are a difference in kind, not degree, and must never be pooled.
        "veg_ba_ha": num(sm["veg_ba_ha"]), "veg_type": s(sm["veg_type"]),
        "veg_ba_se": num(sm["veg_ba_se"]), "veg_design_status": s(sm["veg_design_status"]),
        "n_testable": len(drivers), "featured": code in FEATURED,
        "drivers": drivers[:5],
    })

sites_out.sort(key=lambda x: (not x["featured"], -x["n_testable"], x["site"]))

out = {
    "meta": {
        "note": "Real per-site direction screens from the committed NEON Driver Response Atlas "
                "bundle (data/cascade.rds). Single-site values are exploratory: no short series is "
                "significant on its own; only the pooled network result carries significance.",
        "generated_by": "prototypes/site-explorer/export_data.py",
        # --- provenance receipt -------------------------------------------------
        # Which exact bytes, built when, from which exact sibling commits. Without
        # this a reader cannot tell one vintage of a revised NEON product from
        # another, and nothing on screen is falsifiable against its source.
        "provenance": {
            "bundle": "data/cascade.rds",
            "bundle_sha256": bundle_sha256(),
            "schema_version": scalar(bmeta.get("schema_version")),
            "built_when": scalar(bmeta.get("built_when")),
            "n_sites": num(scalar(bmeta.get("n_sites"))),
            "min_year": num(scalar(bmeta.get("min_year"))),
            "last_complete_year": num(scalar(bmeta.get("last_complete_year"))),
            "tier_rule": scalar(bmeta.get("tier_rule")),
            "prior_family_version": scalar(bmeta.get("prior_family_version")),
            "prior_family_status": scalar(bmeta.get("prior_family_status")),
            "source_snapshot_method": scalar(bmeta.get("source_snapshot_method")),
            "source_products": source_products(),
            "vintage_note": "These are the sibling-app commits frozen into this bundle. Sibling "
                            "repositories continue to evolve; a newer sibling release does not "
                            "change these bytes and is not reflected here. The Driver bundle is "
                            "byte-frozen and is not rebuilt by this prototype.",
        },
    },
    "network": network,
    "signals": SIG,
    "sites": sites_out,
}
# newline="" suppresses Windows' "\n" -> "\r\n" translation. .gitattributes pins this
# file to eol=lf, and without this the same script emits different bytes on Windows and
# Linux — the exact class of cross-platform drift the Driver's release gate exists to catch.
with open(OUT, "w", encoding="utf-8", newline="") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
    f.write("\n")

# --- console summary ---
print("sites:", len(sites_out), "| featured:", sum(1 for x in sites_out if x["featured"]))
sr = network["solid"]
print("network solid rung temp->greenup:  k=%d/%d  p=%.4f  median_r=%.3f"
      % (sr["k"], sr["sites"], sr["p"], sr["median_r"]))
for code in ("SRER", "KONZ", "SCBI"):
    site = next(x for x in sites_out if x["site"] == code)
    print("\n%s (%s) — %d tested drivers" % (code, site["biome_label"], site["n_testable"]))
    for d in site["drivers"]:
        print("   %-46s r=%+.2f n=%d p=%.2f  %-11s %s%s"
              % (d["claim"], d["r"], d["n"], d["p"], d["tier"],
                 d["chip"][1], "  [context]" if d["context"] else ""))
print("\nwrote", OUT)
