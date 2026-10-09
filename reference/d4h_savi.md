# Soil-Adjusted Vegetation Index (SAVI)

Calculates the Soil-Adjusted Vegetation Index (SAVI) to minimize soil
brightness background effects in sparse or arid vegetation canopies.

## Usage

``` r
d4h_savi(nir, red, l_factor = 0.5)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- l_factor:

  Numeric. Soil adjustment factor \\L\\ (default: 0.5).

## Value

A SpatRaster containing SAVI values in `[-1, 1]` with background masked
to `NA`.

## Details

The Soil-Adjusted Vegetation Index is defined as: \$\$\text{SAVI} =
\frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red} + L} \times (1 +
L)\$\$ where \\L\\ is a canopy background adjustment factor typically
set to \\L = 0.5\\ for intermediate vegetation densities.

## References

Huete, A. R. (1988). A soil-adjusted vegetation index (SAVI). *Remote
Sensing of Environment*, 25(3), 295-309.
[doi:10.1016/0034-4257(88)90106-X](https://doi.org/10.1016/0034-4257%2888%2990106-X)
