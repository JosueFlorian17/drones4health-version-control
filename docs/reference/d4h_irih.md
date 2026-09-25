# Human Interface Roughness Index (IRIH)

Measures canopy structural heterogeneity in the forest-household ecotone
interface.

## Usage

``` r
d4h_irih(var_re_nir, red, green, eps = 0.001)
```

## Arguments

- var_re_nir:

  SpatRaster or character. Local variance of RE/NIR ratio or path to
  file.

- red:

  SpatRaster or character. Red band or path to file.

- green:

  SpatRaster or character. Green band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing structural roughness with background masked to
NA.
