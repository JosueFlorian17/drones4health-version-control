# End-to-End Drone Mosaic Processing Pipeline

Computes continuous indices (NDVI, NDWI, TWI), creates zonal grids, and
optionally exports results.

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

  Character or SpatRaster. Near-infrared band.

- red:

  Character or SpatRaster. Red band.

- green:

  Character or SpatRaster. Green band (optional).

- dem:

  Character or SpatRaster. DEM/DSM (optional).

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
