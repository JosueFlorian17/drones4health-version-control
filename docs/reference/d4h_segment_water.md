# Segment Water Bodies and Surface Moisture Pools

Detects, delineates, and vectorizes surface water bodies, irrigation
trenches, and micro-pooling zones from multispectral indices (NDWI /
NDVI) or RGB orthomosaics.

## Usage

``` r
d4h_segment_water(
  raster_in,
  threshold = -0.05,
  is_ndwi = FALSE,
  min_area_m2 = 2,
  max_area_m2 = 50000
)
```

## Arguments

- raster_in:

  SpatRaster or character path. Input NDWI, NDVI, or multispectral
  raster layer.

- threshold:

  Numeric. Spectral threshold for water delineation (default: -0.05 for
  NDVI, 0.0 for NDWI).

- is_ndwi:

  Logical. If TRUE, treats values \\\> \text{threshold}\\ as water; if
  FALSE (default for NDVI), treats values \\\< \text{threshold}\\ as
  water.

- min_area_m2:

  Numeric. Minimum water body surface area in square meters to retain
  (default: 2.0). Filters out single-pixel noise.

- max_area_m2:

  Numeric. Maximum water body surface area in square meters to retain
  (default: 50000.0).

## Value

An `sf` POLYGON object with columns: `water_id`, `area_m2`,
`perimeter_m`, and spatial geometry.

## Details

Water bodies are extracted by isolating negative NDVI or positive NDWI
spectral signatures: \$\$\text{WaterMask} = \begin{cases} 1 & \text{if }
\text{NDWI} \> \theta\_{\text{water}} \text{ or } \text{NDVI} \<
\theta\_{\text{veg}} \\ 0 & \text{otherwise} \end{cases}\$\$ Extracted
pixel clusters are converted to vector polygons (`sf`), with calculated
surface area (\\\text{m}^2\\) and perimeter.

## References

McFeeters, S. K. (1996). The use of the Normalized Difference Water
Index (NDWI) in the delineation of open water features. *International
Journal of Remote Sensing*, 17(7), 1425-1432.
[doi:10.1080/01431169608948714](https://doi.org/10.1080/01431169608948714)
