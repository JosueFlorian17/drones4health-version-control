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

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)
  library(sf)

  # Reference flight raster and water polygon sources
  ref_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
  water_sf <- st_read(system.file("extdata", "water_bodies.gpkg", package = "drones4health"))

  # Compute continuous distance-to-water risk surface
  r_dist <- d4h_raster_distance(sources = water_sf, raster_ref = ref_file)
  plot(r_dist)
}
# }
```
