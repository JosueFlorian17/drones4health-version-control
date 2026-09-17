# Continuous Synthetic Materials Risk Index (General Area)

Detects non-natural materials (plastics, rubber, tires) that serve as
potential mosquito breeding containers.

## Usage

``` r
d4h_imsr_general(
  red_edge,
  red,
  nir,
  veg_threshold = 0.2,
  eps = 0.001,
  scale = NULL
)
```

## Arguments

- red_edge:

  Character or SpatRaster. Red Edge band or path to file.

- red:

  Character or SpatRaster. Red band or path to file.

- nir:

  Character or SpatRaster. Near-infrared band or path to file.

- veg_threshold:

  Numeric. Threshold to differentiate vegetation from synthetics
  (default: 0.2).

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

- scale:

  Numeric. Divisor to normalize pixel values (default: NULL).

## Value

A SpatRaster containing continuous IMSR risk values.
