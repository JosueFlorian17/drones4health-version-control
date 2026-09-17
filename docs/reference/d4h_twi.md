# Topographic Wetness Index (TWI)

Calculates TWI to identify potential water accumulation areas based on
terrain.

## Usage

``` r
d4h_twi(dem_raster, eps = 0.001)
```

## Arguments

- dem_raster:

  SpatRaster. Digital Elevation Model.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster containing TWI values.
