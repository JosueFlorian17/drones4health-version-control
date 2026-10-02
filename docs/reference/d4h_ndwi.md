# Normalized Difference Water Index (NDWI)

Calculates the Normalized Difference Water Index (NDWI) to identify open
surface water bodies, irrigation canals, and localized moisture pooling.

## Usage

``` r
d4h_ndwi(green, nir)
```

## Arguments

- green:

  SpatRaster or character. Green band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

## Value

A SpatRaster containing NDWI values in `[-1, 1]` with background masked
to `NA`.

## Details

The Normalized Difference Water Index is calculated as: \$\$\text{NDWI}
= \frac{\text{Green} - \text{NIR}}{\text{Green} + \text{NIR}}\$\$
Positive values (\\\text{NDWI} \> 0\\) typically demarcate water
surfaces, while negative values represent terrestrial vegetation and dry
bare soil.

## References

McFeeters, S. K. (1996). The use of the Normalized Difference Water
Index (NDWI) in the delineation of open water features. *International
Journal of Remote Sensing*, 17(7), 1425-1432.
[doi:10.1080/01431169608948714](https://doi.org/10.1080/01431169608948714)
