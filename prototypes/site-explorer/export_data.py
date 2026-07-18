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
        "veg_ba_ha": num(sm["veg_ba_ha"]), "veg_type": s(sm["veg_type"]),
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
    },
    "network": network,
    "signals": SIG,
    "sites": sites_out,
}
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)

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
