# Normalized Difference Red Edge Index (NDRE)

Calculates the Normalized Difference Red Edge Index (NDRE) using the Red
Edge band to evaluate canopy chlorophyll content and late-stage
vegetative health.

## Usage

``` r
d4h_ndre(nir, red_edge)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

## Value

A SpatRaster containing NDRE values in `[-1, 1]` with background masked
to `NA`.

## Details

The Normalized Difference Red Edge Index is formulated as:
\$\$\text{NDRE} = \frac{\text{NIR} - \text{RedEdge}}{\text{NIR} +
\text{RedEdge}}\$\$ Useful in dense vegetation where standard NDVI
experiences saturation.

## References

Barnes, E. M., Clarke, T. R., Richards, S. E., Colaizzi, P. D., Sloan,
J., Moran, M. S., ... & Pinter, P. J. (2000). Coincident detection of
crop water stress, nitrogen status and canopy density using ground-based
multispectral data. *Proceedings of the 5th International Conference on
Precision Agriculture*, 16, 1-15.
