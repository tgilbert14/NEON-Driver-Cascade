#!/usr/bin/env python3
"""Build a walkable canopy-height grid for the 3D scene.

Two sources:
  1. REAL — a NEON AOP Canopy Height Model GeoTIFF (DP3.30015.001, 1 m):
       python3 build_lidar.py WREF path/to/NEON_..._CHM.tif
     Reads the raster with the pure-Python `tifffile` package (no GDAL), crops a
     central walkable window, downsamples to an N×N height grid, and labels it
     with the real source.
  2. SYNTHETIC — no tile available (e.g. this sandbox: NEON's /api/v0/data route
     is 403 without an API token). Generates a plausible canopy-height field with
     real forest STRUCTURE (fractal ridges + clearings) as an honest stand-in:
       python3 build_lidar.py WREF --synthetic

Output: lidar-<site>.json = {site, source, cell_m, n, max_h, note, grid[[...]]}.
Inline that JSON into walk.html's <script id="lidar<SITE>"> block. A real tile
swaps in with no scene changes — only `source`/`note` flip from stand-in to real.
"""
import json, sys, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
N = 100          # grid cells per side
CELL = 3.0       # metres per cell -> 300 m walkable window

def resize(a, n):
    m = a.shape[0]
    xi = np.linspace(0, m - 1, n)
    rows = np.array([np.interp(xi, np.arange(m), a[i]) for i in range(m)])      # (m,n)
    cols = np.array([np.interp(xi, np.arange(m), rows[:, j]) for j in range(n)]).T
    return cols

def synthetic(seed=42, max_h=52.0):
    rng = np.random.default_rng(seed)
    field = np.zeros((N, N)); amp = 1.0; tot = 0.0
    for o in range(6):                      # fractal Brownian motion
        size = 2 ** (o + 1) + 1
        field += resize(rng.random((size, size)), N) * amp
        tot += amp; amp *= 0.55
    field /= tot
    field = np.clip((field - 0.28) / 0.62, 0, 1) ** 0.92      # bare gaps + closed canopy
    h = field * max_h
    # punch a few clearings (meadows / blowdown) so structure reads as real
    yy, xx = np.mgrid[0:N, 0:N]
    for _ in range(4):
        cx, cy, r = rng.integers(10, N - 10, 2).tolist() + [rng.integers(6, 14)]
        h[(xx - cx) ** 2 + (yy - cy) ** 2 < r * r] *= 0.12
    h[h < 1.5] = 0.0                        # open ground
    return h

def from_geotiff(path):
    import tifffile                          # only needed on the real path
    arr = tifffile.imread(path).astype("float64")
    if arr.ndim == 3:
        arr = arr[..., 0]
    arr[(arr < 0) | (arr > 120)] = 0.0       # NEON CHM nodata is often -9999 / 0
    # central N*CELL-metre window (CHM is 1 m/px), then downsample by block-max
    win = int(N * CELL)
    r0 = max(0, arr.shape[0] // 2 - win // 2); c0 = max(0, arr.shape[1] // 2 - win // 2)
    crop = arr[r0:r0 + win, c0:c0 + win]
    fy, fx = crop.shape[0] // N, crop.shape[1] // N
    crop = crop[:fy * N, :fx * N].reshape(N, fy, N, fx)
    return crop.max(axis=(1, 3))             # block-max keeps tree tops

def main():
    site = sys.argv[1] if len(sys.argv) > 1 else "WREF"
    tif = next((a for a in sys.argv[2:] if a.endswith((".tif", ".tiff"))), None)
    if tif and os.path.exists(tif):
        grid = from_geotiff(tif)
        source = "real NEON AOP LiDAR CHM (DP3.30015.001)"
        note = ("Real NEON airborne-LiDAR canopy heights (DP3.30015.001), " + site +
                " — a central 300 m window, downsampled to 3 m cells.")
    else:
        grid = synthetic()
        source = "synthetic-demo"
        note = ("SYNTHETIC canopy-height field — a stand-in for NEON AOP LiDAR "
                "(DP3.30015.001). NEON's data API needs a token this sandbox can't "
                "reach, so this is generated with realistic forest structure (ridges "
                "+ clearings), NOT a real scan. Run build_lidar.py " + site +
                " <CHM.tif> to load the real one.")
    grid = np.round(grid, 1)
    out = {"site": site, "source": source, "cell_m": CELL, "n": N,
           "max_h": float(grid.max()), "note": note,
           "grid": [[float(v) for v in row] for row in grid]}
    path = os.path.join(HERE, "lidar-%s.json" % site.lower())
    json.dump(out, open(path, "w"))
    forested = int((grid > 2).sum())
    print("site=%s source=%s  max=%.1fm mean(forested)=%.1fm forested=%d/%d  ->%s (%d bytes)"
          % (site, source, grid.max(), grid[grid > 2].mean(), forested, N * N,
             os.path.basename(path), os.path.getsize(path)))

if __name__ == "__main__":
    main()
