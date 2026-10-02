# Corrected Transformed Vegetation Index (CTVI)

Calculates the Corrected Transformed Vegetation Index (CTVI) to
normalize skewed NDVI distributions.

## Usage

``` r
d4h_ctvi(ndvi_raster)
```

## Arguments

- ndvi_raster:

  SpatRaster or character. Input NDVI layer or path to file.

## Value

A SpatRaster containing CTVI values with background masked to `NA`.

## Details

The Corrected Transformed Vegetation Index is given by: \$\$\text{CTVI}
= \frac{\text{NDVI} + 0.5}{\sqrt{\|\text{NDVI} + 0.5\|}}\$\$

## References

Perry, C. R., & Lautenschlager, L. F. (1984). Functional equivalence of
spectral vegetation indices. *Remote Sensing of Environment*, 14(1-3),
169-182.
[doi:10.1016/0034-4257(84)90013-0](https://doi.org/10.1016/0034-4257%2884%2990013-0)
