# Normalized Difference Vegetation Index (NDVI)

Calculates NDVI to quantify photosynthetic activity and vegetation vigor
from SpatRaster objects or file paths.

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
to NA.
