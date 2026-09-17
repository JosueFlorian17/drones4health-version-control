# Human Interface Roughness Index (IRIH)

Measures canopy structural heterogeneity in the forest-household
interface.

## Usage

``` r
d4h_irih(var_re_nir, red, green, eps = 0.001)
```

## Arguments

- var_re_nir:

  SpatRaster. Local variance of the RE/NIR ratio.

- red:

  SpatRaster. Red band.

- green:

  SpatRaster. Green band.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster representing structural roughness.
