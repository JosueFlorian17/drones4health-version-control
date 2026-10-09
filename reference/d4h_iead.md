# Clearing Stagnation Index (IEAD)

Detects surface water pooling and vector vulnerability in recently
cleared, excavated, or deforested micro-zones.

## Usage

``` r
d4h_iead(grad_delta_ndvi, depressions_dsm, red_edge)
```

## Arguments

- grad_delta_ndvi:

  SpatRaster or character. Gradient of NDVI change layer or path to
  file.

- depressions_dsm:

  SpatRaster or character. Topographic depressions layer from DSM or
  path to file.

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

## Value

A SpatRaster highlighting stagnation risk in clearings with background
masked to `NA`.

## Details

The Deforestation Micro-Habitat Exposure Index integrates vegetation
change gradients, elevation depressions, and Red Edge reflectance:
\$\$\text{IEAD} = \nabla(\Delta\text{NDVI}) \times
\text{Depressions}\_{\text{DSM}} \times \text{RedEdge}\$\$

## References

Castro, M. C., Kanamori, S., Kannady, K., Mkude, S., Killeen, G. F., &
Fillinger, U. (2010). The importance of drains for the emergence of
anopheline mosquitoes in urban Dar es Salaam, Tanzania. *BMC Public
Health*, 10, 344.
