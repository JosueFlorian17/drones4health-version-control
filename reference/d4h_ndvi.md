# Normalized Difference Vegetation Index (NDVI)

Calculates the Normalized Difference Vegetation Index (NDVI) to quantify
photosynthetic activity, biomass density, and vegetative vigor from UAV
imagery.

## Usage

``` r
d4h_ndvi(nir, red)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

## Value

A SpatRaster containing NDVI values in `[-1, 1]` with background masked
to `NA`.

## Details

The Normalized Difference Vegetation Index is computed according to the
formula: \$\$\text{NDVI} = \frac{\text{NIR} - \text{Red}}{\text{NIR} +
\text{Red}}\$\$ Pixel values are clamped to `[-1, 1]` with background
non-data values masked to `NA`.

## References

Rouse, J. W., Haas, R. H., Schell, J. A., & Deering, D. W. (1974).
Monitoring vegetation systems in the Great Plains with ERTS. *NASA
Special Publication*, 351, 309-317.

Tucker, C. J. (1979). Red and photographic infrared linear combinations
for monitoring vegetation. *Remote Sensing of Environment*, 8(2),
127-150.
[doi:10.1016/0034-4257(79)90013-0](https://doi.org/10.1016/0034-4257%2879%2990013-0)
