# Topographic Wetness Index (TWI)

Calculates Topographic Wetness Index to model micro-scale hydrological
accumulation zones.

## Usage

``` r
d4h_twi(dem_raster, eps = 0.001)
```

## Arguments

- dem_raster:

  SpatRaster or character. Input DEM/DSM or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero in flat areas
  (default: 0.001).

## Value

A SpatRaster containing TWI values with background masked to NA.
