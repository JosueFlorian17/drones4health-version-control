# Normalized Difference Water Index (NDWI)

Calculates NDWI to detect open surface water bodies and moisture
accumulation.

## Usage

``` r
d4h_ndwi(green, nir)
```

## Arguments

- green:

  SpatRaster or character. Green band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

## Value

A SpatRaster containing NDWI values in `[-1, 1]` with background masked
to NA.
