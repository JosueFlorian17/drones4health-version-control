# Interactive Side-by-Side Raster Swipe Viewer

Renders an interactive leaflet slider comparing two raster layers
side-by-side with a single swipe bar over an optional base map.

## Usage

``` r
d4h_mapview_swipe(
  x,
  y,
  grid = NULL,
  basemap = TRUE,
  col_x = "viridis",
  col_y = "magma",
  limits_x = NULL,
  limits_y = NULL,
  max_pixels = 5e+05
)
```

## Arguments

- x:

  SpatRaster or character path. Left layer to compare (e.g., NDVI, RGB,
  Bare Soil Mask, or orthomosaic).

- y:

  SpatRaster or character path. Right layer to compare (e.g., MSAVI2,
  SAVI, NDRE, Slope, Thermal, or DSM).

- grid:

  Optional SpatVector, sf, or character path. Zonal grid boundaries to
  overlay on the map. Default: NULL (no grid).

- basemap:

  Logical or character. If TRUE, includes satellite (Esri.WorldImagery)
  and OpenStreetMap base layers. If FALSE or NULL, disables the
  background map. You can also specify a provider tile name (default:
  TRUE).

- col_x:

  Character or color vector. Color palette for layer x (default:
  "viridis"). Options include "viridis", "magma", "terrain", or custom
  color vectors like `"#2a9d8f"`.

- col_y:

  Character or color vector. Color palette for layer y (default:
  "magma"). Options include "viridis", "magma", "terrain", or custom
  color vectors.

- limits_x:

  Numeric vector c(min, max). Explicit color scale limits for layer x.
  If NULL (default), robust 2%-98% quantiles are used for continuous
  layers.

- limits_y:

  Numeric vector c(min, max). Explicit color scale limits for layer y
  (e.g., c(0, 0.8)). If NULL (default), robust 2%-98% quantiles are used
  for continuous layers.

- max_pixels:

  Integer. Maximum cell count for fast interactive rendering (default:
  500000). Downsample with
  [`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
  if exceeded.

## Value

A leaflet / htmlwidget interactive slider widget.
