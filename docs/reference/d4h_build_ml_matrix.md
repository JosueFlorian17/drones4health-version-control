# Build Machine Learning Ready Matrix from Zonal Statistics

Extracts zonal statistics from raster layers across grid cells to
prepare feature tables.

## Usage

``` r
d4h_build_ml_matrix(hex_data, raster_stack, funs = c("mean", "max"))
```

## Arguments

- hex_data:

  SpatVector or sf. Hexagonal or square surveillance grid.

- raster_stack:

  SpatRaster. Stack of environmental and epidemiological raster layers.

- funs:

  Character vector. Summary functions to compute (e.g., c("mean",
  "max")).

## Value

A data.frame or tibble with grid IDs and extracted features.
