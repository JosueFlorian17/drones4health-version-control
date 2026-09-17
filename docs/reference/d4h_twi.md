# Topographic Wetness Index (TWI)

Calculates Topographic Wetness Index with optional zonal grid
summarization.

## Usage

``` r
d4h_twi(dem, cell_size = NULL, square = TRUE, eps = 0.001)
```

## Arguments

- dem:

  Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or
  path to file.

- cell_size:

  Numeric. Optional cell size in meters. If NULL, returns continuous
  raster (default: NULL).

- square:

  Logical. If TRUE, square grid; if FALSE, hexagonal grid (default:
  TRUE).

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is
numeric).
