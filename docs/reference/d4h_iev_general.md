# Continuous Vulnerability Stagnation Indicator (General Area)

Identifies micro-stagnation areas with high vector breeding suitability
by combining moisture (NDWI) and terrain slope.

## Usage

``` r
d4h_iev_general(ndwi, dem, eps = 0.001)
```

## Arguments

- ndwi:

  Character or SpatRaster. NDWI layer or path to file.

- dem:

  Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or
  path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing continuous IEV stagnation risk values.
