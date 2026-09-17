# Synthetic Materials Risk Index (IMSR)

Detects non-natural materials (plastics, rubber, tires) that can serve
as vector breeding sites.

## Usage

``` r
d4h_imsr(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001)
```

## Arguments

- red_edge:

  SpatRaster. Red Edge band.

- red:

  SpatRaster. Red band.

- nir:

  SpatRaster. Near-infrared band.

- veg_threshold:

  Numeric. Threshold to differentiate vegetation from synthetics.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster highlighting synthetic materials.
