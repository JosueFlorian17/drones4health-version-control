# Continuous Topographic Wetness Index (General Area)

Calculates continuous TWI from a Digital Elevation Model (DEM) to locate
water accumulation zones.

## Usage

``` r
d4h_twi_general(dem, eps = 0.001)
```

## Arguments

- dem:

  Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or
  path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing continuous TWI values.
