# End-to-End Drone Mosaic Processing Pipeline

Computes continuous indices (NDVI, NDWI, TWI, IEV), creates zonal grids,
and optionally exports results.

## Usage

``` r
d4h_process_mosaic(
  nir,
  red,
  green = NULL,
  dem = NULL,
  cell_size = 50,
  square = FALSE,
  out_tif = NULL,
  out_csv = NULL
)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- green:

  SpatRaster or character. Green band or path to file (optional).

- dem:

  SpatRaster or character. DEM/DSM or path to file (optional).

- cell_size:

  Numeric. Grid cell size in meters (default: 50).

- square:

  Logical. If TRUE, square grid; if FALSE, hexagonal grid (default:
  FALSE).

- out_tif:

  Character. Path to output multi-band GeoTIFF file (optional).

- out_csv:

  Character. Path to output CSV file with grid zonal statistics
  (optional).

## Value

A list containing the SpatRaster stack of indicators and the SpatVector
grid summary.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  # Define paths to multispectral drone bands
  nir_path   <- system.file("extdata", "nir.tif", package = "drones4health")
  red_path   <- system.file("extdata", "red.tif", package = "drones4health")
  green_path <- system.file("extdata", "green.tif", package = "drones4health")
  dem_path   <- system.file("extdata", "dem.tif", package = "drones4health")

  # Execute full automated processing pipeline with output exports
  results <- d4h_process_mosaic(
    nir       = nir_path,
    red       = red_path,
    green     = green_path,
    dem       = dem_path,
    cell_size = 50,
    square    = FALSE,
    out_tif   = tempfile(fileext = ".tif"),
    out_csv   = tempfile(fileext = ".csv")
  )
  # Inspect stacked indicators and hexagonal summary grid
  print(results$indicators)
  head(results$grid)
}
# }
```
