# Continuous Euclidean Distance Raster from Risk Sources

Computes a continuous Euclidean distance surface raster (heat map)
measuring proximity to water bodies, breeding sites, or waste clusters
across the entire flight extent.

## Usage

``` r
d4h_raster_distance(sources, raster_ref)
```

## Arguments

- sources:

  `sf` or `SpatVector` spatial object containing risk source
  polygons/points.

- raster_ref:

  SpatRaster or character path. Reference raster layer defining spatial
  grid dimensions and CRS.

## Value

A SpatRaster where each pixel represents the Euclidean distance in
meters to the nearest risk source.
