# Vulnerability Stagnation Indicator (IEV)

Locates areas where surface water is prone to micro-stagnation and
persistent pooling by synthesizing surface moisture and terrain slope.

## Usage

``` r
d4h_iev(delta_ndwi, slope_dsm, eps = 0.001)
```

## Arguments

- delta_ndwi:

  SpatRaster or character. Temporal difference in NDWI or base NDWI
  layer or path to file.

- slope_dsm:

  SpatRaster or character. Slope layer derived from DSM/DEM or path to
  file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing IEV stagnation risk values with background
masked to `NA`.

## Details

The Entomological Vector Suitability / Stagnation Indicator combines
moisture accumulation with micro-topographical slope inverse:
\$\$\text{IEV} = \text{NDWI} \times \frac{1}{\text{Slope} +
\epsilon}\$\$ High values indicate flat micro-depressions with
significant moisture content suitable for mosquito and snail vector
colonization.

## References

Hardy, A., Makame, M., Cross, D., Majambere, S., & Msellem, M. (2017).
Using low-cost drones to map malaria vector habitats. *Parasites &
Vectors*, 10(1), 29.
[doi:10.1186/s13071-017-1973-3](https://doi.org/10.1186/s13071-017-1973-3)
