# Soil Adjusted Vegetation Index (SAVI)

Calculates SAVI, correcting for soil brightness.

## Usage

``` r
d4h_savi(nir, red, l_factor = 0.5)
```

## Arguments

- nir:

  SpatRaster. Near-infrared band.

- red:

  SpatRaster. Red band.

- l_factor:

  Numeric. Soil brightness correction factor.

## Value

A SpatRaster containing SAVI values.
