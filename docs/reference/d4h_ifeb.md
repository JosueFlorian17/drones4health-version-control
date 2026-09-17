# Fragmentation and Edge Effect Index (IFEB)

Quantifies ecological transitions and borders between vegetation and
urban/cleared soil.

## Usage

``` r
d4h_ifeb(grad_red_edge, red, nir, eps = 0.001)
```

## Arguments

- grad_red_edge:

  SpatRaster. Focal standard deviation of the Red Edge band.

- red:

  SpatRaster. Red band.

- nir:

  SpatRaster. Near-infrared band.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster quantifying edge effects.
