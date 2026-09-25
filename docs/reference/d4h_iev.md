# Vulnerability Stagnation Indicator (IEV)

Locates areas where surface water is prone to micro-stagnation by
combining surface moisture and micro-topography.

## Usage

``` r
d4h_iev(delta_ndwi, slope_dsm, eps = 0.001)
```

## Arguments

- delta_ndwi:

  SpatRaster or character. Temporal difference in NDWI or base NDWI
  layer or path to file.

- slope_dsm:

  SpatRaster or character. Slope layer derived from DSM or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing IEV stagnation risk values with background
masked to NA.
