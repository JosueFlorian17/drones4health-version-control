# Continuous Normalized Difference Water Index (General Area)

Computes continuous NDWI for the entire survey extent to identify
surface water and moisture.

## Usage

``` r
d4h_ndwi_general(green, nir, scale = NULL)
```

## Arguments

- green:

  Character or SpatRaster. Green band or path to file.

- nir:

  Character or SpatRaster. Near-infrared band or path to file.

- scale:

  Numeric. Divisor to normalize pixel values (default: auto-detected or
  65535).

## Value

A SpatRaster containing continuous NDWI values bounded in -1, 1.
