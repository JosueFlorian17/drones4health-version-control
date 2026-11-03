# Segment House Roofs and Building Footprints

Identifies, delineates, and vectorizes residential houses, roofs, and
man-made structures from ultra-high resolution RGB orthomosaics using
spectral-geometric OBIA or Segment Anything (SAM).

## Usage

``` r
d4h_segment_buildings(
  rgb_raster,
  ndvi_raster = NULL,
  min_area_m2 = 12,
  max_area_m2 = 600,
  brightness_min = 135,
  ndvi_max = 0.25,
  method = c("spectral", "sam"),
  sam_checkpoint = NULL
)
```

## Arguments

- rgb_raster:

  SpatRaster or character path. Ultra-high resolution 3-band RGB
  orthomosaic.

- ndvi_raster:

  SpatRaster or character path (optional). NDVI layer to exclude green
  vegetation canopies.

- min_area_m2:

  Numeric. Minimum building footprint surface area in square meters
  (default: 12.0).

- max_area_m2:

  Numeric. Maximum building footprint surface area in square meters
  (default: 500.0).

- brightness_min:

  Numeric. Minimum mean RGB brightness threshold `[0, 255]` (default:
  155.0).

- ndvi_max:

  Numeric. Maximum NDVI threshold to exclude tree canopies over roofs
  (default: 0.18).

- method:

  Character. Segmentation method: `"spectral"` (default, fast native R)
  or `"sam"` (Meta Segment Anything Model). When `method = "sam"`,
  delineation is driven by SAM on RGB imagery and filtered by
  `min_area_m2` and `max_area_m2`.

- sam_checkpoint:

  Character path (optional). Model weights path when `method = "sam"`.
  If `NULL` (default), automatically checks the internal package cache
  and downloads Meta's official ViT-B model (~375 MB) on first use.

## Value

An `sf` POLYGON object with columns: `building_id`, `area_m2`,
`centroid_x`, `centroid_y`, and spatial geometry.

## Details

Buildings are extracted using two alternative methodologies:

- **Spectral OBIA (`method = "spectral"`):** Combines high surface
  brightness (corrugated metal/calamina roofs,
  \\\text{RGB}\_{\text{mean}} \ge \theta\_{\text{bright}}\\) and
  red-clay tile chromatic signatures with vegetation exclusion
  constraints (\\\text{NDVI} \< \theta\_{\text{ndvi}}\\):
  \$\$\text{BuildingCandidate} = \begin{cases} 1 & \text{if }
  (\text{Brightness} \ge \theta\_{\text{bright}} \lor \text{RedTile})
  \text{ and } \text{NDVI} \< \theta\_{\text{ndvi}} \\ 0 &
  \text{otherwise} \end{cases}\$\$

- **Deep Learning (`method = "sam"`):** Utilizes Meta's Segment Anything
  Model (SAM) via `reticulate`. Delineates geometric regular roof
  boundaries directly from the 3-band visible RGB orthomosaic. Spectral
  thresholds (`brightness_min`, `ndvi_max`) are bypassed, filtering
  candidates exclusively by `min_area_m2` and `max_area_m2`. Model
  weights are automatically managed in the internal package cache.

Vectorized candidates are filtered by residential building footprints
(\\12\text{ m}^2 \le \text{Area} \le 600\text{ m}^2\\), with centroid
coordinates computed.

## References

Blaschke, T. (2010). Object based image analysis for remote sensing.
*ISPRS Journal of Photogrammetry and Remote Sensing*, 65(1), 2-16.
[doi:10.1016/j.isprsjprs.2009.06.004](https://doi.org/10.1016/j.isprsjprs.2009.06.004)

Kirillov, A., et al. (2023). Segment anything. *arXiv preprint
arXiv:2304.02643*.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  # Define paths to RGB orthomosaic and optional NDVI layer
  rgb_file  <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")
  ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")

  # Extract building footprints with optical brightness thresholds and vegetation masking
  buildings_sf <- d4h_segment_buildings(
    rgb_raster     = rgb_file,
    ndvi_raster    = ndvi_file,
    min_area_m2    = 12.0,
    max_area_m2    = 600.0,
    brightness_min = 135.0,
    ndvi_max       = 0.25,
    method         = "spectral"
  )
  print(buildings_sf)
}
# }
```
