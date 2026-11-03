# Extract and Display Structured Raster Metadata

Inspects one or more drone orthomosaics or raster layers and extracts
comprehensive spatial metadata, including dimensions, data type, spatial
resolution (GSD), georeferencing, bounding box, physical scene
dimensions, and coordinate reference systems.

## Usage

``` r
d4h_raster_metadata(x, quiet = FALSE)

d4h_metadata(x, quiet = FALSE)
```

## Arguments

- x:

  Character file path,
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
  or list of file paths/SpatRasters.

- quiet:

  Logical. If `FALSE` (default), prints a structured executive summary
  block to the console. If `TRUE`, suppresses printing.

## Value

A data frame (tibble) of S3 class
`c("d4h_raster_metadata", "tbl_df", "tbl", "data.frame")` containing
metadata attributes per raster layer or file:

- file:

  Base filename or layer name

- width:

  Number of columns in pixels

- height:

  Number of rows in pixels

- total_pixels:

  Total pixel count (width \* height)

- nbands:

  Number of raster channels/bands

- dtype:

  Storage data type (e.g. uint8, uint16, float32)

- nodata:

  Configured NoData value

- res_x:

  Spatial resolution in X dimension

- res_y:

  Spatial resolution in Y dimension

- gsd_cm:

  Ground Sampling Distance in centimeters (if projected)

- pixel_size_desc:

  Human-readable GSD description string

- crs:

  Coordinate reference system description

- epsg:

  EPSG code as integer

- is_projected:

  Logical indicating whether CRS is projected in meters

- xmin:

  Western boundary coordinate

- xmax:

  Eastern boundary coordinate

- ymin:

  Southern boundary coordinate

- ymax:

  Northern boundary coordinate

- width_m:

  Field horizontal width in meters

- height_m:

  Field vertical height in meters

- area_m2:

  Bounding box total surface area in square meters

- area_ha:

  Bounding box total surface area in hectares

## Details

Drone remote sensing workflows require exact spatial validation before
index computation. `d4h_raster_metadata` (alias `d4h_metadata`) inspects
GeoTIFF files or
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects, translating coordinate extents and pixel resolutions into
human-readable metric dimensions (e.g., cm/pixel GSD, scene area in
hectares, affine transformation coefficients).

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)

  # Inspect metadata for a drone orthomosaic band
  path_r <- system.file("extdata", "ndvi.tif", package = "drones4health")
  meta <- d4h_raster_metadata(path_r)
  head(meta)
}
# }
```
