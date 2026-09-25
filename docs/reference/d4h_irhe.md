# Spectral Water Retention Index (IRHE)

Highlights persistent, cold surface water bodies with low evaporation
rates.

## Usage

``` r
d4h_irhe(green, nir, lst, eps = 0.001)
```

## Arguments

- green:

  SpatRaster or character. Green band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- lst:

  SpatRaster or character. Land Surface Temperature layer or path to
  file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing water retention potential with background
masked to NA.
