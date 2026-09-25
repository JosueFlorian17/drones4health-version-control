# Clearing Stagnation Index (IEAD)

Detects surface water pooling in recently cleared or deforested areas.

## Usage

``` r
d4h_iead(grad_delta_ndvi, depressions_dsm, red_edge)
```

## Arguments

- grad_delta_ndvi:

  SpatRaster or character. Gradient of NDVI change layer or path to
  file.

- depressions_dsm:

  SpatRaster or character. Topographic depressions layer from DSM or
  path to file.

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

## Value

A SpatRaster highlighting stagnation risk in clearings with background
masked to NA.
