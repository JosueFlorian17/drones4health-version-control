# Cartographic Visualization with ggplot2

Plots continuous raster layers or zonal grids using aggregation and
geom_raster.

## Usage

``` r
d4h_plot(
  x,
  grid = NULL,
  palette = "viridis",
  limits = NULL,
  title = NULL,
  max_pixels = 5e+05
)
```

## Arguments

- x:

  SpatRaster, SpatVector, sf, or character path to plot.

- grid:

  Optional SpatVector, sf, or character path to overlay grid boundaries.

- palette:

  Character. Color palette name ("viridis", "magma", "terrain") or
  custom color vector (default: "viridis").

- limits:

  Numeric vector c(min, max) to fix the color scale limits (default:
  NULL).

- title:

  Character. Plot title (default: NULL).

- max_pixels:

  Integer. Maximum number of pixels to display before regular
  aggregation (default: 500000).

## Value

A ggplot object.
