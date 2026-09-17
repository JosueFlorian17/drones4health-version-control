# Cartographic Visualization with ggplot2

Plots continuous raster layers (SpatRaster) or zonal grids (SpatVector /
sf) with ggplot2.

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

  SpatRaster, SpatVector, or sf object to plot.

- grid:

  Optional SpatVector or sf object to overlay grid borders.

- palette:

  Character. Color palette ("viridis", "magma", "terrain" or custom
  colors vector).

- limits:

  Numeric vector c(min, max) to fix the color scale limits.

- title:

  Character. Plot title.

- max_pixels:

  Integer. Maximum number of pixels to sample for fast rendering
  (default: 500000).

## Value

A ggplot object.
