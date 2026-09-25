# Corrected Transformed Vegetation Index (CTVI)

Calculates CTVI to normalize vegetation index distributions.

## Usage

``` r
d4h_ctvi(ndvi_raster)
```

## Arguments

- ndvi_raster:

  SpatRaster or character. Input NDVI layer or path to file.

## Value

A SpatRaster containing CTVI values with background masked to NA.
