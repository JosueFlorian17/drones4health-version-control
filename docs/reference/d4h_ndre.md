# Normalized Difference Red Edge Index (NDRE)

Calculates NDRE to assess canopy chlorophyll content and plant health
using the Red Edge band.

## Usage

``` r
d4h_ndre(nir, red_edge)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

## Value

A SpatRaster containing NDRE values in -1, 1 with background masked to
NA.
