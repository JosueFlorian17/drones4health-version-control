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
  or `"sam"` (Meta Segment Anything Model).

- sam_checkpoint:

  Character path (optional). Model weights path when `method = "sam"`.

## Value

An `sf` POLYGON object with columns: `building_id`, `area_m2`,
`centroid_x`, `centroid_y`, and spatial geometry.

## Details

Buildings are extracted by combining high surface brightness / spectral
contrast in visible RGB bands with non-vegetated constraints
(\\\text{NDVI} \< \theta\_{\text{ndvi}}\\): \$\$\text{BuildingCandidate}
= \begin{cases} 1 & \text{if } \text{RGB}\_{\text{mean}} \ge
\theta\_{\text{bright}} \text{ and } \text{NDVI} \<
\theta\_{\text{ndvi}} \\ 0 & \text{otherwise} \end{cases}\$\$ Vectorized
candidates are filtered by residential building footprints (\\10\text{
m}^2 \le \text{Area} \le 500\text{ m}^2\\).

## References

Blaschke, T. (2010). Object based image analysis for remote sensing.
*ISPRS Journal of Photogrammetry and Remote Sensing*, 65(1), 2-16.
[doi:10.1016/j.isprsjprs.2009.06.004](https://doi.org/10.1016/j.isprsjprs.2009.06.004)

Kirillov, A., et al. (2023). Segment anything. *arXiv preprint
arXiv:2304.02643*.
