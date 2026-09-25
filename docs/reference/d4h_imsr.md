# Synthetic Materials Risk Index (IMSR)

Detects non-natural materials (plastics, rubber, discarded tires) that
serve as potential vector breeding containers.

## Usage

``` r
d4h_imsr(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001)
```

## Arguments

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- veg_threshold:

  Numeric. Threshold to differentiate vegetation from synthetics
  (default: 0.2).

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing IMSR values in 0, 1 with background masked to
NA.
