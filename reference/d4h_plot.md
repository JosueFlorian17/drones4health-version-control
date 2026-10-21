# Cartographic Visualization with ggplot2

Plots continuous raster layers or zonal grids using aggregation and
geom_raster.

## Usage

``` r
d4h_plot(
  x,
  grid = NULL,
  houses = NULL,
  houses_filter_extent = FALSE,
  house_color = "red",
  house_size = 2,
  rgb_bands = NULL,
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

- houses:

  Optional sf, data.frame, SpatVector, or character path to CSV
  containing house coordinates. Automatically plotted as red points (or
  customizable color/size).

- houses_filter_extent:

  Logical. If TRUE, filters houses to only those intersecting the raster
  extent / footprint. If FALSE (default), shows all houses including
  surrounding ones.

- house_color:

  Character. Color for house points (default: "red").

- house_size:

  Numeric. Size for house points (default: 2.0).

- rgb_bands:

  Numeric vector of length 3 (e.g. c(1, 2, 3)). If x is a multi-band
  raster and rgb_bands is specified, renders in true/false RGB.

- palette:

  Character. Color palette name ("viridis", "magma", "terrain") or
  custom color vector (default: "viridis").

## Value

A ggplot object.
