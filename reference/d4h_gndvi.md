# Green Normalized Difference Vegetation Index (GNDVI)

Calculates the Green Normalized Difference Vegetation Index (GNDVI) for
assessing chlorophyll concentration and photosynthetic activity.

## Usage

``` r
d4h_gndvi(nir, green)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- green:

  SpatRaster or character. Green band or path to file.

## Value

A SpatRaster containing GNDVI values in `[-1, 1]` with background masked
to `NA`.

## Details

The Green Normalized Difference Vegetation Index is defined as:
\$\$\text{GNDVI} = \frac{\text{NIR} - \text{Green}}{\text{NIR} +
\text{Green}}\$\$

## References

Gitelson, A. A., Merzlyak, M. N., & Lichtenthaler, H. K. (1996).
Detection of red edge position and chlorophyll content by reflectance
spectra. *Journal of Plant Physiology*, 148(3-4), 494-508.
[doi:10.1016/S0176-1617(96)80285-9](https://doi.org/10.1016/S0176-1617%2896%2980285-9)
