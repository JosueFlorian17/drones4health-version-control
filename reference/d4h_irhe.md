# Spectral Water Retention Index (IRHE)

Highlights persistent, cold surface water bodies with low evaporation
rates prone to long-term mosquito colonization.

## Usage

``` r
d4h_irhe(green, nir, lst, eps = 0.001)
```

## Arguments

- green:

  SpatRaster or character. Green band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- lst:

  SpatRaster or character. Land Surface Temperature layer (°C) or path
  to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing water retention potential with background
masked to `NA`.

## Details

The High-Risk Hydric Environment Index is computed as: \$\$\text{IRHE} =
\text{NDWI} \times \frac{1}{\text{LST} + \epsilon}\$\$

## References

McFeeters, S. K. (1996). The use of the Normalized Difference Water
Index (NDWI) in the delineation of open water features. *International
Journal of Remote Sensing*, 17(7), 1425-1432.
