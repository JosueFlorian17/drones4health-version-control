# Segment Water Bodies and Surface Moisture Pools

Detects, delineates, and vectorizes surface water bodies, irrigation
trenches, and micro-pooling zones from multispectral indices (NDWI /
NDVI) or RGB orthomosaics using spectral thresholding or Deep Learning
(SAM).

## Usage

``` r
d4h_segment_water(
  raster_in,
  rgb_raster = NULL,
  threshold = -0.05,
  is_ndwi = FALSE,
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

  Numeric. Spectral threshold for water delineation (default: -0.05 for
  NDVI, 0.0 for NDWI).

- is_ndwi:

  Logical. If TRUE, treats values \\\> \text{threshold}\\ as water; if
  FALSE (default for NDVI), treats values \\\< \text{threshold}\\ as
  water.

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
  reticulate/Python).

- sam_checkpoint:

  Character path (optional). Path to SAM model weights (.pth) when
  `method = "sam"`.

- exclude_buildings:

  `sf` POLYGON object (optional). Residential buildings, roofs, or
  structures to strictly exclude from water bodies to prevent
  metal/calamina roofs from being misclassified as water.

## Value

An `sf` POLYGON object with columns: `water_id`, `area_m2`,
`perimeter_m`, and spatial geometry.

## Details

Water bodies are extracted by isolating negative NDVI or positive NDWI
spectral signatures combined with low optical reflectance:
\$\$\text{WaterMask} = \begin{cases} 1 & \text{if } (\text{NDWI} \>
\theta\_{\text{water}} \text{ or } \text{NDVI} \< \theta\_{\text{veg}})
\text{ and } \text{Brightness} \le \theta\_{\text{dark}} \\ 0 &
\text{otherwise} \end{cases}\$\$ Extracted pixel clusters are converted
to vector polygons (`sf`), with calculated surface area (\\\text{m}^2\\)
and perimeter.
