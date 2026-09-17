# Process Multivariate Mosaic (NDVI and SAVI)

Computes both NDVI and SAVI, stacks them, and extracts zonal stats.

## Usage

``` r
procesar_mosaico_multivariado(
  nir,
  red,
  tamano_grilla = 50,
  square = FALSE,
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

  Grid cell size in meters (default: 50).

- square:

  Logical. TRUE for square cells, FALSE for hexagons.

- out_tif:

  Optional output path for stacked GeoTIFF.

- out_csv:

  Optional output path for CSV.

## Value

List containing SpatRaster stack and grid SpatVector.
