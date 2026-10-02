# Visible Atmospherically Resistant Index (VARI)

Computes the Visible Atmospherically Resistant Index (VARI) to estimate
vegetation fraction from visible RGB channels with minimal sensitivity
to atmospheric aerosols and illumination differences.

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
to `NA`.

## Details

The Visible Atmospherically Resistant Index is formulated as:
\$\$\text{VARI} = \frac{\text{Green} - \text{Red}}{\text{Green} +
\text{Red} - \text{Blue} + \epsilon}\$\$ where \\\epsilon\\ is a small
numerical stabilization constant.

## References

Gitelson, A. A., Kaufman, Y. J., Stark, R., & Rundquist, D. (2002).
Novel algorithms for remote estimation of vegetation fraction. *Remote
Sensing of Environment*, 80(1), 76-87.
[doi:10.1016/S0034-4257(01)00289-9](https://doi.org/10.1016/S0034-4257%2801%2900289-9)
