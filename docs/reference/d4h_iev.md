# Vulnerability Stagnation Indicator (IEV)

Locates areas where surface water is likely to stagnate due to
micro-depressions.

## Usage

``` r
d4h_iev(delta_ndwi, slope_dsm, eps = 0.001)
```

## Arguments

- delta_ndwi:

  SpatRaster. Temporal difference in NDWI or base NDWI.

- slope_dsm:

  SpatRaster. Slope derived from the Digital Surface Model.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster highlighting stagnation risk.
