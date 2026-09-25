# Green Normalized Difference Vegetation Index (GNDVI)

Calculates GNDVI for estimating chlorophyll concentration.

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
to NA.
