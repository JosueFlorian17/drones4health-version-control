# Summarize Raster Indicator for the General Mosaic Footprint

Computes the overall mean value of raster layers across the entire area
of interest (AOI) as a single spatial vector polygon (SpatVector),
formatted identically to zonal grid summaries for consistent map
plotting.

## Usage

``` r
d4h_summarize_general(raster_in, exact_boundary = TRUE)
```

## Arguments

- raster_in:

  SpatRaster or character. Input raster layer, stack, or path to file.

- exact_boundary:

  Logical. If TRUE, traces the exact outer boundary of valid non-NA
  flight data; if FALSE, uses the bounding box extent (default: TRUE).

## Value

A SpatVector with a single polygon containing the overall mean value(s).
