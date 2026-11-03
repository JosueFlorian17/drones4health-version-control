# Summarize Raster Indicator by Spatial Grid or General Footprint (Deprecated)

This function is deprecated in favor of
[`d4h_executive_summary`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md)
with `grid = ...` or `by = "grid"`. Generates a square or hexagonal
spatial grid and extracts zonal summary statistics of raster indicators
per grid cell.

## Usage

``` r
d4h_summarize_grid(
  raster_in,
  cell_size = 20,
  square = TRUE,
  discard_na = TRUE,
  general = FALSE,
  exact_boundary = TRUE
)

d4h_summarize_general(raster_in, exact_boundary = TRUE)
```

## Arguments

- raster_in:

  SpatRaster or character. Input raster layer, stack, or path to file.

- cell_size:

  Numeric. Grid cell size / diameter in meters (default: 20). Ignored
  when `general = TRUE`.

- square:

  Logical. If TRUE, creates square cells; if FALSE, hexagonal cells
  (default: TRUE). Ignored when `general = TRUE`.

- discard_na:

  Logical. If TRUE, removes grid cells outside the valid raster data
  area (default: TRUE). Ignored when `general = TRUE`.

- general:

  Logical. If TRUE, computes the overall mean value of raster layers
  across the entire area of interest as a single spatial vector polygon
  (SpatVector) with `grid_id = "GENERAL"` (default: FALSE).

- exact_boundary:

  Logical. When `general = TRUE`, if TRUE, traces the exact outer
  boundary of valid non-NA flight data; if FALSE, uses the bounding box
  extent (default: TRUE).

## Value

A SpatVector or sf containing the grid cells (or single general
footprint polygon) with extracted values.
