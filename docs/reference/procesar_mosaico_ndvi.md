# Process NDVI Mosaic and Zonal Grid

Computes NDVI, summarizes over a spatial grid, and exports outputs.

## Usage

``` r
procesar_mosaico_ndvi(
  nir,
  red,
  tamano_grilla = 20,
  out_tif = NULL,
  out_csv = NULL
)
```

## Arguments

- nir:

  SpatRaster or file path to NIR band.

- red:

  SpatRaster or file path to Red band.

- tamano_grilla:

  Grid cell size in meters (default: 20).

- out_tif:

  Optional output path for GeoTIFF.

- out_csv:

  Optional output path for CSV.

## Value

List containing NDVI SpatRaster and grid SpatVector.
