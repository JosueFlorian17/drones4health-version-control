# Normalize Digital Numbers to Surface Reflectance

Scales raw 16-bit or 8-bit digital numbers to a 0-1 reflectance range
and masks zeros to NA.

## Usage

``` r
d4h_normalize_reflectance(raster_layer, scale_factor = 65535)
```

## Arguments

- raster_layer:

  SpatRaster or character. Input band or path to file.

- scale_factor:

  Numeric. Divisor to scale the raster (default: 65535).

## Value

A SpatRaster clamped between 0 and 1 with zeros masked as NA.
