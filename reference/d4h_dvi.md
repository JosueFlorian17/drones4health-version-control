# Difference Vegetation Index (DVI)

Calculates the Difference Vegetation Index (DVI) as the simple linear
difference between Near-Infrared and Red reflectance.

## Usage

``` r
d4h_dvi(nir, red)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

## Value

A SpatRaster containing DVI values with background masked to `NA`.

## Details

The Difference Vegetation Index is computed as: \$\$\text{DVI} =
\text{NIR} - \text{Red}\$\$ Sensitive to variations in canopy biomass
and leaf area index (LAI).

## References

Tucker, C. J. (1979). Red and photographic infrared linear combinations
for monitoring vegetation. *Remote Sensing of Environment*, 8(2),
127-150.
