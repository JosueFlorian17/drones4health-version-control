# Soil Adjusted Vegetation Index (SAVI)

Calculates SAVI to minimize soil brightness influences in sparse canopy
areas.

## Usage

``` r
d4h_savi(nir, red, l_factor = 0.5)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- l_factor:

  Numeric. Soil adjustment factor (default: 0.5).

## Value

A SpatRaster containing SAVI values in -1, 1 with background masked to
NA.
