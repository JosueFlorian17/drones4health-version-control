# Summarize Raster Indicator by Spatial Grid

Generates a square or hexagonal grid and computes the mean value of
raster layers per cell, discarding unpopulated areas.

## Usage

``` r
d4h_summarize_grid(raster_in, cell_size = 20, square = TRUE, discard_na = TRUE)
```

## Arguments

- raster_in:

  SpatRaster. Input raster layer or multi-layer raster stack.

- cell_size:

  Numeric. Grid cell size in meters (default: 20).

- square:

  Logical. If TRUE, creates square cells; if FALSE, hexagonal cells
  (default: TRUE).

- discard_na:

  Logical. If TRUE, removes grid cells outside the valid raster data
  area (default: TRUE).

## Value

A SpatVector containing the grid cells with extracted mean values.
