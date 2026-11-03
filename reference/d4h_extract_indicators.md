# Extract Multiple Biophysical and Environmental Indicators

Simultaneously computes, extracts, and summarizes multiple biophysical,
vegetation, water, and terrain indicators across drone orthomosaics,
operational surveillance grids, and physical features. Always provides
both a spatial representation (`$sf`) with polygons and a clean tabular
data frame (`$df`) without geometry, including micro-environmental land
cover composition (`pct_bare_soil`, `pct_houses`, `pct_water`,
`pct_vegetation`, `dominant_class`, `surveillance_priority`).

## Usage

``` r
d4h_extract_indicators(
  raster = NULL,
  bands = c("ndvi", "ndwi"),
  grid = NULL,
  cell_size = NULL,
  area_m2 = NULL,
  n_cells = NULL,
  square = FALSE,
  nir = NULL,
  red = NULL,
  green = NULL,
  blue = NULL,
  red_edge = NULL,
  dem = NULL,
  lst = NULL,
  water = NULL,
  buildings = NULL,
  houses = NULL,
  stat = "mean",
  scale = 1,
  quiet = FALSE,
  orthomosaic = NULL,
  aoi = NULL,
  region = NULL,
  ...
)
```

## Arguments

- raster:

  Optional SpatRaster, character path to orthomosaic, or spatial grid.

- bands:

  Character vector. Indicators to compute and extract (default:
  `c("ndvi", "ndwi")`). Supported codes include:

  - `"ndvi"`: Normalized Difference Vegetation Index
    \\\frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red}}\\

  - `"ndwi"`: Normalized Difference Water Index \\\frac{\text{Green} -
    \text{NIR}}{\text{Green} + \text{NIR}}\\

  - `"gndvi"`: Green Normalized Difference Vegetation Index
    \\\frac{\text{NIR} - \text{Green}}{\text{NIR} + \text{Green}}\\

  - `"savi"`: Soil-Adjusted Vegetation Index

  - `"dvi"`: Difference Vegetation Index \\\text{NIR} - \text{Red}\\

  - `"msavi2"`: Modified Soil-Adjusted Vegetation Index 2

  - `"vari"`: Visible Atmospherically Resistant Index (RGB)

  - `"ndre"`: Normalized Difference Red Edge

  - `"evi"`: Enhanced Vegetation Index

  - `"imsr"`: Micro-Surface Roughness / Debris Exposure Index

  - `"slope"`: Terrain slope in degrees (requires `dem`)

  - `"twi"`: Topographic Wetness Index (requires `dem`)

- grid:

  Optional spatial grid (`sf`, `SpatVector`, or file path). If NULL, an
  operational grid is automatically generated across the flight
  footprint.

- cell_size:

  Numeric (optional). Grid cell size / diameter in meters (default: 50
  if all sizing options are NULL and `grid` is NULL).

- area_m2:

  Numeric (optional). Target cell area in square meters.

- n_cells:

  Numeric / Integer (optional). Desired total number of grid units.

- square:

  Logical. If TRUE, square grid cells; if FALSE, regular hexagonal cells
  (default: FALSE).

- nir:

  SpatRaster or character path. Near-Infrared band.

- red:

  SpatRaster or character path. Red band.

- green:

  SpatRaster or character path. Green band.

- blue:

  SpatRaster or character path. Blue band.

- red_edge:

  SpatRaster or character path. Red Edge band.

- dem:

  SpatRaster or character path. Digital Elevation / Surface Model.

- lst:

  SpatRaster or character path. Land Surface Temperature raster.

- water:

  SpatVector, sf, or SpatRaster (optional). Water body features or
  binary water mask. If NULL and NDWI is computed, water pixels
  (\\\text{NDWI} \> 0\\) are automatically identified.

- buildings:

  SpatVector, sf, or SpatRaster (optional). Building / dwelling
  footprints or binary roof mask.

- houses:

  Deprecated alias for `buildings`.

- stat:

  Character. Summary statistic per grid unit. One of `"mean"` (default),
  `"median"`, `"min"`, `"max"`, `"sd"`.

- scale:

  Named numeric vector or numeric value. Optional multiplier scale
  factor applied to indicator values (default: 1).

- quiet:

  Logical. If TRUE, suppresses console progress messages (default:
  FALSE).

- orthomosaic:

  Alias for `raster`.

- aoi:

  Alias for `raster`.

- region:

  Alias for `raster` or `grid`.

- ...:

  Additional arguments passed to internal functions.

## Value

An object of class `d4h_indicators_summary` and `d4h_grid_summary`
containing:

- `$sf`: Spatial `sf` polygons with geometry, indicator statistics, and
  land cover composition.

- `$df`: Tabular pure `data.frame` without geometry, containing all
  zonal metrics and land cover percentages (`pct_bare_soil`,
  `pct_houses`, `pct_water`, `pct_vegetation`, `dominant_class`,
  `surveillance_priority`).

## Details

Provides a flexible, unified pipeline for automated batch extraction of
biophysical indices. The function operates directly on drone
orthomosaics or multispectral bands without requiring a manual region
input. If an operational grid is not provided via `grid`, an operative
surveillance grid is automatically generated across the valid flight
footprint using `cell_size` (default: 50 m), `area_m2`, or `n_cells`.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  # Define bands
  path_nir <- system.file("extdata", "nir.tif", package = "drones4health")
  path_r   <- system.file("extdata", "red.tif", package = "drones4health")
  path_g   <- system.file("extdata", "green.tif", package = "drones4health")

  # Extract multiple indicators directly without requiring a manual region
  res <- d4h_extract_indicators(
    bands     = c("ndvi", "ndwi"),
    nir       = path_nir,
    red       = path_r,
    green     = path_g,
    cell_size = 50
  )

  # Access both the clean tabular data frame and spatial sf
  head(res$df)
  plot(res$sf)
}
# }
```
