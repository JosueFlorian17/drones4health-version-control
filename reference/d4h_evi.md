# Enhanced Vegetation Index (EVI)

Calculates the Enhanced Vegetation Index (EVI) optimized for
high-biomass canopy regions with improved atmospheric resistance.

## Usage

``` r
d4h_evi(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- blue:

  SpatRaster or character. Blue band or path to file.

- g_factor:

  Numeric. Gain factor \\G\\ (default: 2.5).

- c1:

  Numeric. Aerosol resistance coefficient 1 \\C_1\\ (default: 6.0).

- c2:

  Numeric. Aerosol resistance coefficient 2 \\C_2\\ (default: 7.5).

- l_factor:

  Numeric. Canopy background adjustment \\L\\ (default: 1.0).

## Value

A SpatRaster containing EVI values with background masked to `NA`.

## Details

The Enhanced Vegetation Index is computed as: \$\$\text{EVI} = G \times
\frac{\text{NIR} - \text{Red}}{\text{NIR} + C_1 \cdot \text{Red} - C_2
\cdot \text{Blue} + L}\$\$ where \\G = 2.5\\ is the gain factor, \\C_1 =
6.0\\ and \\C_2 = 7.5\\ are aerosol resistance coefficients, and \\L =
1.0\\ is the canopy background factor.

## References

Huete, A., Didan, K., Miura, T., Rodriguez, E. P., Gao, X., & Ferreira,
L. G. (2002). Overview of the radiometric and biophysical performance of
the MODIS vegetation indices. *Remote Sensing of Environment*, 83(1-2),
195-213.
[doi:10.1016/S0034-4257(02)00096-2](https://doi.org/10.1016/S0034-4257%2802%2900096-2)
