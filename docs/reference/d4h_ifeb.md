# Fragmentation and Edge Effect Index (IFEB)

Quantifies ecological transitions and borders between canopy and
urban/cleared soil.

## Usage

``` r
d4h_ifeb(grad_red_edge, red, nir, eps = 0.001)
```

## Arguments

- grad_red_edge:

  SpatRaster or character. Focal standard deviation of Red Edge or path
  to file.

- red:

  SpatRaster or character. Red band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster quantifying edge effects with background masked to NA.
