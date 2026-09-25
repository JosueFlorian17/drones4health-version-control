# Bare Soil Mask

Generates a binary mask of bare or exposed soil based on an NDVI
threshold.

## Usage

``` r
d4h_bare_soil(ndvi_raster, threshold = 0.15)
```

## Arguments

- ndvi_raster:

  SpatRaster or character. Input NDVI layer or path to file.

- threshold:

  Numeric. Value below which pixels are classified as bare soil
  (default: 0.15).

## Value

A binary SpatRaster (1 = bare soil, 0 = vegetation/water) with
background masked to NA.
