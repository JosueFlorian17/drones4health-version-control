# Unified Cartographic and Interactive Visualization

Unified visualization function for drone rasters, grids, vector
features, and comparative dual-layer analysis. When comparing two layers
(`x` and `y`): if `interactive = TRUE`, renders an interactive
side-by-side swipe slider widget (via Leaflet and Leaflet.extras2); if
`interactive = FALSE` (default), renders a publication-ready static
side-by-side comparative panel (via `ggplot2` and `cowplot`). For a
single layer, `interactive = TRUE` renders an interactive `mapview` web
map, while `interactive = FALSE` produces a static `ggplot2` map.

## Usage

``` r
d4h_plot(
  x,
  y = NULL,
  interactive = FALSE,
  grid = NULL,
  houses = NULL,
  houses_filter_extent = FALSE,
  house_color = "red",
  house_size = 2,
  rgb_bands = NULL,
  palette = "viridis",
  palette_y = "magma",
  limits = NULL,
  limits_y = NULL,
  title = NULL,
  max_pixels = 5e+05
)
```

## Arguments

- x:

  SpatRaster, SpatVector, sf, summary data.frame, or character file path
  to plot (or left layer in comparative mode).

- y:

  Optional SpatRaster or character path. Right layer for comparative
  visualization (e.g. comparing NDVI vs NDWI, or Pre vs Post
  intervention).

- interactive:

  Logical. If `FALSE` (default), outputs a static `ggplot2` plot (or
  side-by-side comparison if `y` is supplied). If `TRUE`, outputs an
  interactive swipe slider (when `y` is provided) or interactive
  `mapview` web map (when single layer).

- grid:

  Optional SpatVector, sf, or character path to overlay grid boundaries.

- houses:

  Optional sf, data.frame, SpatVector, or character path to CSV/Excel
  containing house coordinates. Automatically plotted as points.

- houses_filter_extent:

  Logical. If TRUE, filters houses to only those intersecting the raster
  extent / footprint. If FALSE (default), retains all houses.

- house_color:

  Character. Color for house points (default: "red").

- house_size:

  Numeric. Size for house points (default: 2.0).

- rgb_bands:

  Numeric vector of length 3 (e.g. c(1, 2, 3)). If x is a multi-band
  raster and rgb_bands is specified, renders in true/false RGB.

- palette:

  Character. Color palette name ("viridis", "magma", "terrain",
  "spectral") or custom color vector (default: "viridis"). For dual
  comparison, specifies palette for layer x.

- palette_y:

  Character. Color palette for layer y in dual comparative mode
  (default: "magma").

- limits:

  Numeric vector c(min, max) to fix color scale limits for layer x.

- limits_y:

  Numeric vector c(min, max) to fix color scale limits for layer y.

- title:

  Character. Custom plot title.

- max_pixels:

  Numeric. Maximum number of pixels to render before spatial aggregation
  (default: 500000).

## Value

A `ggplot` object (if `interactive = FALSE`) or a `leaflet` / `mapview`
interactive widget (if `interactive = TRUE`).

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
  ndre_file <- system.file("extdata", "ndre.tif", package = "drones4health")

  # 1. Comparative dual-indicator: interactive slider
  d4h_plot(x = ndvi_file, y = ndre_file, interactive = TRUE)

  # 2. Comparative dual-indicator: static publication panel
  p_dual <- d4h_plot(x = ndvi_file, y = ndre_file, interactive = FALSE)
  print(p_dual)

  # 3. Single indicator: static map
  p_single <- d4h_plot(x = ndvi_file, interactive = FALSE)
  print(p_single)
}
# }
```
