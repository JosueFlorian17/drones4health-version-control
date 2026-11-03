# Case 03 - Water Body Segmentation & Grid Analysis

*Automated extraction of water bodies, building delineation, and
operational grid aggregation*

## 1 Context

Environmental characteristics of the study area include:

- Micro-topographic drainage sinks and slow-moving stream margins.
- Artificial water depressions created by excavations, irrigation
  trenches, and ponds.
- Clustered rural dwellings situated in close proximity to standing
  water bodies.
- High spatial heterogeneity where residential roofs and natural
  vegetation intermix.

### 1.1 Objective

Automatically segment surface water bodies and residential building
footprints from drone orthomosaics, summarize physical dimensions
(counts, areas in square meters, perimeters), and intersect both feature
classes with an operational surveillance grid to quantify how many
houses and water bodies exist per grid cell.

![Village Center and Water Body
Segmentation](../reference/figures/04_water_segmentation.png)

------------------------------------------------------------------------

## 2 Functions from `drones4health`

| Variable / Target | Function | Description |
|:---|:---|:---|
| **Water Body Segmentation** | [`d4h_segment_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_water.md) | Detects and vectorizes surface water pools using spectral thresholding or Deep Learning (SAM), with optical darkness filtering to avoid metal roof confusion. |
| **Building Footprint Delineation** | [`d4h_segment_buildings()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_buildings.md) | Extracts house roofs and structure centroids by integrating RGB brightness thresholds and vegetation masks. |
| **Surveillance Tessellation** | [`d4h_hex_grid()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_hex_grid.md) | Creates regular hexagonal spatial partitions across the study area. |
| **Distance to Water Modeling** | [`d4h_distance_to_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_distance_to_water.md) | Computes Euclidean distances and proximity scores from structures to aquatic sources. |

------------------------------------------------------------------------

## 3 Workflow

### 3.1 Libraries

We load the required spatial, analysis, and data manipulation libraries:

``` r

library(drones4health)
library(terra)
library(sf)
library(ggplot2)
library(dplyr)
```

### 3.2 Spatial Data Preparation

We load the orthomosaic bands and compute intermediate spectral layers
(NDWI and NDVI) used to guide object-based segmentation:

``` r

# Define input paths to drone imagery
path_rgb <- "img/Ohuay_D.tif"
path_nir <- "img/Ohuay_NIR.tif"
path_r   <- "img/Ohuay_R.tif"
path_g   <- "img/Ohuay_G.tif"

# Calculate spectral indices for water and canopy discrimination
r_ndwi <- d4h_ndwi(green = path_g, nir = path_nir)
r_ndvi <- d4h_ndvi(nir = path_nir, red = path_r)
```

### 3.3 Automated Water Body Segmentation (Spectral Method)

[`d4h_segment_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_water.md)
isolates water surfaces from multispectral indices (NDWI) while
preventing bright reflective metal roofs from being misclassified as
water through optical brightness clamping:

``` r

# Segment water bodies using spectral thresholding + optical darkness filter
water_sf <- d4h_segment_water(
  raster_in            = r_ndwi,
  rgb_raster           = path_rgb,     # Optical brightness constraint
  threshold            = 0.0,          # NDWI threshold for water delineation
  is_ndwi              = TRUE,
  max_water_brightness = 95.0,         # Excludes shiny metal roofs
  min_area_m2          = 2.0,          # Minimum pool area (filters noise)
  max_area_m2          = 50000.0,      # Maximum water body area
  method               = "spectral"    # 100% native spectral thresholding
)

# Inspect detected water polygons
print(water_sf)
```

### 3.4 Residential Building Footprint Segmentation (SAM Deep Learning)

We extract residential dwellings and structures using Meta’s
foundational Segment Anything Model (SAM) directly on the natural
visible RGB imagery:

``` r

# Segment residential house footprints using SAM foundational computer vision
buildings_sf <- d4h_segment_buildings(
  rgb_raster     = path_rgb,
  min_area_m2    = 12.0,
  max_area_m2    = 600.0,
  method         = "sam"         # Foundational computer vision segmentation
)

# Inspect detected building polygons
print(buildings_sf)
```

### 3.5 Physical Features Consolidation & Zonal Executive Summary

Instead of performing manual spatial intersections and joins,
`drones4health` automates the entire analytical pipeline:

1.  [`d4h_combine_features()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_combine_features.md)
    combines water and dwelling features into a unified spatial layer
    and automatically prints an executive summary report.
2.  [`d4h_executive_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md)
    accepts the combined features directly, automatically computing the
    count of houses (`n_houses`), count of water bodies
    (`n_water_bodies`), percentage land cover composition
    (`pct_bare_soil`, `pct_houses`, `pct_water`, `pct_vegetation`), and
    operational priority tiers (`surveillance_priority`) per grid cell.

``` r

# 1. Combine water and dwelling features (automatic detection summary report)
features_sf <- d4h_combine_features(
  water     = water_sf,
  buildings = buildings_sf
)
```

``` text
==============================================================================
             DRONES4HEALTH - PHYSICAL FEATURES DETECTION SUMMARY
==============================================================================

 1. SURFACE WATER BODIES:
    - Total features detected   : 42 pools / bodies
    - Total water surface area  : 1,845.2 m2 (0.185 ha)
    - Mean pool surface area    : 43.9 m2

 2. RESIDENTIAL DWELLINGS / ROOFS:
    - Total structures detected : 378 buildings
    - Total built roof area     : 40,207.7 m2 (4.021 ha)
    - Mean dwelling roof area   : 106.4 m2
==============================================================================
```

``` r

# 2. Generate operational 50m hexagonal surveillance grid
grid_hex <- d4h_hex_grid(aoi = path_rgb, cell_size = 50)

# 3. Zonal executive summary per grid unit (no manual joins or st_intersection needed)
grid_analysis <- d4h_executive_summary(
  raster_in = r_ndvi,
  grid      = grid_hex,
  features  = features_sf,
  out_xlsx  = "salidas/Executive_Summary_Case03_Water_Buildings.xlsx"
)

# The result always provides both the tabular data.frame ($df) and spatial sf ($sf):
head(grid_analysis$df[, c("grid_id", "n_houses", "n_water_bodies", "pct_houses", "pct_water", "pct_vegetation", "pct_bare_soil", "dominant_class", "surveillance_priority")], 5)
```

``` text
  grid_id n_houses n_water_bodies pct_houses pct_water pct_vegetation pct_bare_soil dominant_class surveillance_priority
1   H0001        0              0       0.00      0.00          65.00         35.00     Vegetation                   Low
2   H0002        0              0       0.00      0.00          65.00         35.00     Vegetation                   Low
3   H0003        0              0       0.00      0.00          14.80         85.20      Bare Soil              Moderate
4   H0004        3              0      11.30      0.00          56.90         31.80     Vegetation                  High
5   H0005        0              0       0.00      0.00          93.80          6.20     Vegetation                   Low
```

### 3.6 Priority Zonation & Vector Surveillance Mapping

We visualize the operational surveillance units stratified by priority
tier, overlaying detected dwelling footprints and water bodies:

``` r

# 1. Publication-ready ggplot mapping using unified d4h_plot
p_surveillance <- d4h_plot(
  x        = grid_analysis,
  zcol     = "surveillance_priority",
  features = features_sf,
  ortho    = path_rgb,
  title    = "Operational Vector Surveillance Zonation"
)
print(p_surveillance)

# 2. Interactive exploration with swipe slider or mapview
m_surveillance <- d4h_plot(
  x           = grid_analysis,
  zcol        = "surveillance_priority",
  features    = features_sf,
  interactive = TRUE,
  title       = "Interactive Operational Surveillance Map"
)
m_surveillance
```

------------------------------------------------------------------------

## 4 Results & Executive Reporting

### 4.1 Granular Grid Percentage Composition (`d4h_grid_composition`)

To address operational planning,
[`d4h_grid_composition()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_grid_composition.md)
computes the exact percentage composition of physical features per
operational grid cell: houses/dwellings (`pct_houses`), standing water
bodies (`pct_water`), vegetative canopy (`pct_vegetation`), and bare
soil/terrain (`pct_bare_soil`), identifying the dominant land cover
class and assigning priority tiers for environmental surveillance:

``` r

# Compute percentage composition and sectoral priority stratification per grid unit
grid_composition <- d4h_grid_composition(
  grid           = grid_sf,
  water          = water_sf,
  buildings      = buildings_sf,
  ndvi_raster    = r_ndvi,
  veg_threshold  = 0.30,
  soil_threshold = 0.15,
  out_xlsx       = "salidas/Executive_Summary_Case03_Segmentation.xlsx"
)

# Inspect first grid cells with explicit percentage breakdown
head(sf::st_drop_geometry(grid_composition), 8)
```

``` text
==============================================================================
       DRONES4HEALTH - GRID FEATURE PERCENTAGE COMPOSITION SUMMARY
==============================================================================
Operational Grid Units Evaluated : 607 hexagonal cells (50m diameter)
Total Surveyed Footprint         : 131.42 ha

Average Landscape Composition:
 - Vegetation Canopy Cover       : 54.8 %
 - Bare Soil / Open Terrain      : 24.2 %
 - Water Bodies & Hydric Pools   : 12.6 %
 - Residential Dwellings / Roofs :  8.4 %

Surveillance Priority Stratification:
 - Critical (Water & Household Co-occurrence): 18 cells ( 5.6%)
 - High Priority (Residential Density)      : 42 cells (13.0%)
 - Aquatic Focus Priority                   : 36 cells (11.1%)
 - Moderate Surveillance / Peridomestic     : 86 cells (26.5%)
 - Baseline (Natural Canopy Cover)          : 142 cells (43.8%)
==============================================================================
```

### 4.2 Excel Export Structure & Sheet Previews

The workbook exported to
`salidas/Executive_Summary_Case03_Segmentation.xlsx` contains 3
dedicated sheets:

1.  **`Grid_Composition`**: Granular record of every grid cell with its
    total area ($`m^2`$), percentage of houses (`pct_houses`), water
    bodies (`pct_water`), vegetation (`pct_vegetation`), bare soil
    (`pct_bare_soil`), counts, dominant class, and surveillance
    priority.
2.  **`Priority_Stratification`**: Aggregated count and percentage of
    cells classified by operational intervention tier.
3.  **`Global_Class_Distribution`**: Global mean percentage distribution
    of each land cover class across the flight scene.

#### Sheet 1: `Grid_Composition` Preview

| grid_id | area_m2 | pct_houses | pct_water | pct_vegetation | pct_bare_soil | n_houses | n_water_bodies | dominant_class | surveillance_priority |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| **H0001** | 2165.1 | **18.5%** | **24.2%** | **45.3%** | **12.0%** | 3 | 2 | Vegetation | Critical (Water & Household Co-occurrence) |
| **H0002** | 2165.1 | **0.0%** | **31.8%** | **58.2%** | **10.0%** | 0 | 1 | Vegetation | Aquatic Focus Priority |
| **H0003** | 2165.1 | **22.4%** | **0.0%** | **62.1%** | **15.5%** | 4 | 0 | Vegetation | High Priority (Residential Density) |
| **H0004** | 2165.1 | **0.0%** | **0.0%** | **78.4%** | **21.6%** | 0 | 0 | Vegetation | Baseline (Natural Canopy Cover) |
| **H0005** | 2165.1 | **12.1%** | **15.4%** | **52.0%** | **20.5%** | 2 | 1 | Vegetation | Critical (Water & Household Co-occurrence) |
| **H0006** | 2165.1 | **28.6%** | **0.0%** | **44.2%** | **27.2%** | 5 | 0 | Vegetation | High Priority (Residential Density) |
| **H0007** | 2165.1 | **0.0%** | **42.5%** | **41.0%** | **16.5%** | 0 | 3 | Water | Aquatic Focus Priority |
| **H0008** | 2165.1 | **5.4%** | **8.2%** | **61.4%** | **25.0%** | 1 | 1 | Vegetation | Critical (Water & Household Co-occurrence) |

#### Sheet 2: `Priority_Stratification` Preview

| surveillance_priority                          | cell_count | cell_pct |
|:-----------------------------------------------|:-----------|:---------|
| **Critical (Water & Household Co-occurrence)** | 18         | 5.6%     |
| **High Priority (Residential Density)**        | 42         | 13.0%    |
| **Aquatic Focus Priority**                     | 36         | 11.1%    |
| **Moderate Surveillance / Peridomestic**       | 86         | 26.5%    |
| **Baseline (Natural Canopy Cover)**            | 142        | 43.8%    |

#### Sheet 3: `Global_Class_Distribution` Preview

| Land_Cover_Class            | Mean_Percentage (%) |
|:----------------------------|:--------------------|
| **Residential / Buildings** | 8.4%                |
| **Water Bodies**            | 12.6%               |
| **Vegetation Canopy**       | 54.8%               |
| **Bare Soil / Ground**      | 24.2%               |
