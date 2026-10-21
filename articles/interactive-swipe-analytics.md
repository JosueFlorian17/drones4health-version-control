# Interactive Swipe & Visual Analytics

## 1. Interactive Dual-Layer Comparison

In precision spatial epidemiology, field researchers and epidemiologists
often need to contrast a physical landscape feature (such as an RGB
orthomosaic or digital surface model) against a derived risk metric
(such as NDVI, MSAVI2, or TWI) to validate classification boundaries in
real time.

`drones4health` provides
[`d4h_mapview_swipe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_mapview_swipe.md),
powered by Leaflet and Mapview swipe mechanics, enabling side-by-side or
split-screen exploration in interactive R Markdown and web dashboards.

## 2. Dynamic Contrast Stretching

Sensor values can occasionally exhibit extreme outliers (e.g., highly
reflective metal roofs or deep shaded water).
[`d4h_mapview_swipe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_mapview_swipe.md)
integrates quantile-based contrast stretching:

``` r

library(drones4health)
library(terra)

# Load raster layers
r_dem   <- rast("data/Ohuay_D.tif")
r_ndvi  <- rast("data/Ohuay_NDVI.tif")

# Side-by-side interactive swipe comparison
d4h_mapview_swipe(
  x               = r_dem,
  y               = r_ndvi,
  quantile_cutoff = c(0.02, 0.98),
  col.regions     = "viridis"
)
```

## 3. Highlighting Micro-Ecosystem Transitions

The interactive swipe allows users to slide between layers to confirm: -
The exact delineation of bare soil footprints versus dense vegetation. -
Micro-drainage channels visible in high-resolution elevation models
versus water stagnation indices. - Roof material transitions (galvanized
zinc versus palm thatch) and their proximity to standing water.
