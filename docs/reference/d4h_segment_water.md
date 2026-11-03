# Segment Water Bodies and Surface Moisture Pools

Detects, delineates, and vectorizes surface water bodies, irrigation
trenches, and micro-pooling zones from multispectral indices (NDWI /
NDVI) or RGB orthomosaics using spectral thresholding or Deep Learning
(SAM).

## Usage

``` r
d4h_segment_water(
  raster_in = NULL,
  rgb_raster = NULL,
  threshold = NULL,
  is_ndwi = NULL,
  max_water_brightness = 95,
  min_area_m2 = 2,
  max_area_m2 = 50000,
  method = c("spectral", "sam"),
  sam_checkpoint = NULL,
  exclude_buildings = NULL
)
```

## Arguments

- raster_in:

  SpatRaster or character path. Input NDWI, NDVI, or multispectral
  raster layer.

- rgb_raster:

  SpatRaster or character path (optional). RGB orthomosaic to enforce
  optical darkness constraint (water absorbs visible light, while shiny
  metal/calamina roofs reflect high brightness).

- threshold:

  Numeric (optional). Spectral threshold for water delineation. If
  `NULL` (default), automatically set to `0.0` when `is_ndwi = TRUE` or
  `-0.05` when `is_ndwi = FALSE`.

- is_ndwi:

  Logical (optional). If `TRUE`, treats values \\\> \text{threshold}\\
  as water. If `FALSE`, treats values \\\< \text{threshold}\\ as water
  (NDVI convention). If `NULL` (default), automatically detected from
  the layer names or filename of `raster_in`.

- max_water_brightness:

  Numeric. Maximum allowable mean RGB brightness \\\[0, 255\]\\ for
  water (default: 95.0). Prevents metal roofs and concrete from being
  classified as water.

- min_area_m2:

  Numeric. Minimum water body surface area in square meters to retain
  (default: 2.0). Filters out single-pixel noise.

- max_area_m2:

  Numeric. Maximum water body surface area in square meters to retain
  (default: 50000.0).

- method:

  Character. Segmentation algorithm: `"spectral"` (default, 100% native
  R Object-Based GeoAI) or `"sam"` (Meta Segment Anything Model via
  reticulate/Python). When `method = "sam"`, delineation is driven by
  SAM on RGB imagery and filtered by `min_area_m2`, `max_area_m2`, and
  `exclude_buildings`.

- sam_checkpoint:

  Character path (optional). Path to SAM model weights (.pth) when
  `method = "sam"`. If `NULL` (default), automatically checks the
  internal package cache and downloads Meta's official ViT-B model (~375
  MB) on first use.

- exclude_buildings:

  `sf` POLYGON object (optional). Residential buildings, roofs, or
  structures to strictly exclude from water bodies to prevent
  metal/calamina roofs from being misclassified as water.

## Value

An `sf` POLYGON object with columns: `water_id`, `area_m2`,
`perimeter_m`, and spatial geometry.

## Details

Water bodies are extracted using two alternative methodologies:

- **Spectral Thresholding (`method = "spectral"`):** Combines negative
  NDVI or positive NDWI signatures with an optical darkness constraint:
  \$\$\text{WaterMask} = \begin{cases} 1 & \text{if } (\text{NDWI} \>
  \theta\_{\text{water}} \text{ or } \text{NDVI} \<
  \theta\_{\text{veg}}) \text{ and } \text{Brightness} \le
  \theta\_{\text{dark}} \\ 0 & \text{otherwise} \end{cases}\$\$
  **Automatic Detection:** When `is_ndwi = NULL` (default), the function
  inspects the layer name or filepath. If an NDWI/water index is
  detected, it applies \\\text{threshold} = 0.0\\ (\\\> 0\\); if an
  NDVI/vegetation index is detected, it applies \\\text{threshold} =
  -0.05\\ (\\\< -0.05\\). Users can explicitly override
  `is_ndwi = TRUE/FALSE` and `threshold`.

- **Deep Learning (`method = "sam"`):** Utilizes Meta's Segment Anything
  Model (SAM) via `reticulate`. Operates on natural visible RGB imagery
  (`rgb_raster`) to delineate precise morphological water boundaries.
  Spectral parameters (`threshold`, `is_ndwi`, `max_water_brightness`)
  are bypassed in favor of visual feature extraction, filtering
  candidates exclusively by `min_area_m2`, `max_area_m2`, and
  `exclude_buildings`. Model weights (`sam_checkpoint`) are
  automatically resolved and cached locally on first use.

Extracted pixel clusters are converted to vector polygons (`sf`), with
calculated surface area (\\\text{m}^2\\) and perimeter.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)
  library(sf)

  # Define paths to NDWI, RGB orthomosaic, and building exclusion layers
  ndwi_file  <- system.file("extdata", "ndwi.tif", package = "drones4health")
  rgb_file   <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")
  houses_sf  <- st_read(system.file("extdata", "buildings.gpkg", package = "drones4health"))

  # Segment surface water bodies with brightness filtering and building exclusion
  # (is_ndwi and threshold are auto-detected from ndwi_file)
  water_sf <- d4h_segment_water(
    raster_in            = ndwi_file,
    rgb_raster           = rgb_file,
    max_water_brightness = 95.0,
    min_area_m2          = 2.0,
    max_area_m2          = 50000.0,
    method               = "spectral",
    exclude_buildings    = houses_sf
  )
  print(water_sf)
}
# }
```
