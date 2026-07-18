#!/usr/bin/env python3
"""Build map-data.json for the Site Explorer travel map.

Projects a US-states GeoJSON outline + each NEON site's lon/lat into screen
coordinates so the page can draw them with no runtime projection library.
- lower-48 (+ DC) use an Albers equal-area conic projection;
- Alaska and Puerto Rico each get their own equirectangular inset box.

Source outline: a public-domain US-states GeoJSON, e.g.
https://raw.githubusercontent.com/PublicaMundi/MappingAPI/master/data/geojson/us-states.json
Pass its local path as argv[1] (defaults to /tmp/us.json). Prototype tool.
"""
import json, math, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
US = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "/tmp/us.json"))
NAMES = json.load(open(os.path.join(HERE, "neon-site-names.json")))
OUT = os.path.join(HERE, "map-data.json")
EXCLUDE = {"Alaska", "Hawaii", "Puerto Rico"}

def albers(lon, lat):
    lat0, lon0 = math.radians(23), math.radians(-96)
    p1, p2 = math.radians(29.5), math.radians(45.5)
    n = (math.sin(p1) + math.sin(p2)) / 2
    C = math.cos(p1) ** 2 + 2 * n * math.sin(p1)
    rho0 = math.sqrt(C - 2 * n * math.sin(lat0)) / n
    theta = n * (math.radians(lon) - lon0)
    rho = math.sqrt(C - 2 * n * math.sin(math.radians(lat))) / n
    return (rho * math.sin(theta), rho0 - rho * math.cos(theta))

def equirect(mid):
    return lambda lon, lat: (lon * math.cos(math.radians(mid)), lat)

def rings(geom):
    t, c = geom["type"], geom["coordinates"]
    if t == "Polygon":
        return c
    if t == "MultiPolygon":
        return [r for poly in c for r in poly]
    return []

def build(keep, project, W, H, pad=10, step=1):
    polys, sites = [], []
    for f in US["features"]:
        if keep(f["properties"].get("name")):
            for r in rings(f["geometry"]):
                polys.append([project(lon, lat) for lon, lat in r[::step]])
    for code, v in NAMES.items():
        if keep(v["state"]):
            sites.append((code, project(v["lon"], v["lat"])))
    xs = [p[0] for poly in polys for p in poly] + [s[1][0] for s in sites]
    ys = [p[1] for poly in polys for p in poly] + [s[1][1] for s in sites]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    sx, sy = (maxx - minx) or 1, (maxy - miny) or 1
    s = min((W - 2 * pad) / sx, (H - 2 * pad) / sy)
    ox, oy = (W - sx * s) / 2, (H - sy * s) / 2
    def screen(p):
        return ((p[0] - minx) * s + ox, (maxy - p[1]) * s + oy)  # flip y for SVG
    d = "".join("M" + "L".join("%.1f,%.1f" % screen(p) for p in poly) + "Z" for poly in polys)
    so = [{"code": c, "x": round(screen(p)[0], 1), "y": round(screen(p)[1], 1)} for c, p in sites]
    return {"w": W, "h": H, "outline": d, "sites": so}

out = {
    "main": build(lambda n: n and n not in EXCLUDE, albers, 960, 600, step=2),
    "ak": build(lambda n: n == "Alaska", equirect(63), 250, 200, step=3),
    "pr": build(lambda n: n == "Puerto Rico", equirect(18), 210, 96, step=1),
}
json.dump(out, open(OUT, "w"))
print("sites  main=%d ak=%d pr=%d" % (len(out["main"]["sites"]), len(out["ak"]["sites"]), len(out["pr"]["sites"])))
print("outline chars  main=%d ak=%d pr=%d" % (len(out["main"]["outline"]), len(out["ak"]["outline"]), len(out["pr"]["outline"])))
print("map-data.json bytes:", os.path.getsize(OUT))
