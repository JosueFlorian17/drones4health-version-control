# Modified Soil-Adjusted Vegetation Index 2 (MSAVI2)

Computes the Modified Soil-Adjusted Vegetation Index 2 (MSAVI2) for
evaluating vegetation cover in sparse, arid, or degraded landscapes
without requiring an empirical soil adjustment factor.

## Usage

``` r
d4h_msavi2(nir, red)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

## Value

A SpatRaster containing MSAVI2 values in `[-1, 1]` with background
masked to `NA`.

## Details

The Modified Soil-Adjusted Vegetation Index 2 utilizes an inductive
equation based on the soil line: \$\$\text{MSAVI2} = \frac{2 \cdot
\text{NIR} + 1 - \sqrt{(2 \cdot \text{NIR} + 1)^2 - 8 \cdot
(\text{NIR} - \text{Red})}}{2}\$\$ It dynamically adjusts for soil
brightness variations across complex terrain.

## References

Qi, J., Chehbouni, A., Huete, A. R., Kerr, Y. H., & Sorooshian, S.
(1994). A modified soil adjusted vegetation index. *Remote Sensing of
Environment*, 48(2), 119-126.
[doi:10.1016/0034-4257(94)90134-1](https://doi.org/10.1016/0034-4257%2894%2990134-1)
