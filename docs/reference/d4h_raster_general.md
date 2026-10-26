# Convert Raster Indicator to General Homogeneous Mosaic

Creates a continuous SpatRaster matching the exact spatial footprint of
the input raster where all valid pixels are assigned the overall global
mean value.

## Usage

``` r
d4h_raster_general(raster_in)
```

## Arguments

- raster_in:

  SpatRaster or character. Input raster layer, stack, or path to file.

## Value

A SpatRaster with the mosaic footprint filled with the global mean
value.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  # Load index raster
  ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")

  # Generate homogeneous mosaic filled with global mean value
  r_homo <- d4h_raster_general(raster_in = ndvi_file)
  plot(r_homo)
}
# }
```
