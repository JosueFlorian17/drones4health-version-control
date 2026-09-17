# Clearing Stagnation Index (IEAD)

Detects puddles in recently cleared or deforested areas.

## Usage

``` r
d4h_iead(grad_delta_ndvi, depressions_dsm, red_edge)
```

## Arguments

- grad_delta_ndvi:

  SpatRaster. Gradient of NDVI change.

- depressions_dsm:

  SpatRaster. Topographic depressions from DSM.

- red_edge:

  SpatRaster. Red Edge band.

## Value

A SpatRaster highlighting stagnation in clearings.
