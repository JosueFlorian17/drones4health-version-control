# Spectral Water Retention Index (IRHE)

Highlights stable, cold water bodies with low evaporation rates.

## Usage

``` r
d4h_irhe(green, nir, lst, eps = 0.001)
```

## Arguments

- green:

  SpatRaster. Green band.

- nir:

  SpatRaster. Near-infrared band.

- lst:

  SpatRaster. Land Surface Temperature.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster representing water retention potential.
