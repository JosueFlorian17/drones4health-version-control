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
  max_pixels = 5e+05
)
```

## Arguments

- x:

  SpatRaster or character path. Left layer to compare (e.g., NDVI, RGB,
  or orthomosaic).

- y:

  SpatRaster or character path. Right layer to compare (e.g., SAVI,
  Slope, Thermal, or DSM).

- grid:

  Optional SpatVector, sf, or character path. Zonal grid boundaries to
  overlay on the map.

- basemap:

  Logical or character. If TRUE, includes satellite (Esri.WorldImagery)
  and OpenStreetMap base layers. If FALSE or NULL, disables the
  background map. You can also specify a provider tile name (default:
  TRUE).

- col_x:

  Character or color vector. Color palette for layer x (default:
  "viridis"). Options include "viridis", "magma", "terrain", or custom
  color vectors.

- col_y:

  Character or color vector. Color palette for layer y (default:
  "magma"). Options include "viridis", "magma", "terrain", or custom
  color vectors.

- max_pixels:

  Integer. Maximum cell count for fast interactive rendering (default:
  500000). Downsample with
  [`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
  if exceeded.

## Value

A leaflet / htmlwidget interactive slider widget.
