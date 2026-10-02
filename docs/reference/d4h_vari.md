# Visible Atmospherically Resistant Index (VARI)

Computes VARI to assess vegetation fraction while minimizing atmospheric
and illumination sensitivity.

## Usage

``` r
d4h_vari(green, red, blue, eps = 0.001)
```

## Arguments

- green:

  SpatRaster or character. Green band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- blue:

  SpatRaster or character. Blue band (or Red Edge / NIR if Blue
  unavailable) or path to file.

- eps:

  Numeric. Small epsilon to prevent zero division (default: 0.001).

## Value

A SpatRaster containing VARI values in `[-1, 1]` with background masked
to NA.
