# Normalized Difference Vegetation Index (NDVI)

Calculates NDVI with optional zonal grid summarization (square or
hexagonal).

## Usage

``` r
d4h_ndvi(nir, red, cell_size = NULL, square = TRUE, scale = NULL)
```

## Arguments

- nir:

  Character or SpatRaster. Near-infrared band or path to file.

- red:

  Character or SpatRaster. Red band or path to file.

- cell_size:

  Numeric. Optional cell size in meters. If NULL, returns continuous
  raster (default: NULL).

- square:

  Logical. If TRUE, square grid; if FALSE, hexagonal grid (default:
  TRUE).

- scale:

  Numeric. Divisor to normalize pixel values (default: NULL).

## Value

A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is
numeric).
