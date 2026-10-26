# Case 04 - GPS House Buffers & Proximity to Water

*Integrating field GPS household points, focal buffer zonal statistics,
and Euclidean distance to water*

## 1 Objective

Ingest georeferenced household GPS points from Excel or CSV files,
generate targeted focal buffers (in meters or grid units), compute zonal
statistics strictly within the peridomestic flight envelope, and
calculate minimum Euclidean distances from each dwelling to nearest
water bodies with proximity decay modeling.

![Peridomestic Buffer Analysis over Drone
Orthomosaic](../reference/figures/05_focal_houses_buffer_ndvi.png)

------------------------------------------------------------------------

## 2 Functions from `drones4health`

| Variable / Target | Function | Description |
|:---|:---|:---|
| **Focal Buffer Extraction** | [`d4h_indicator_buffer()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_indicator_buffer.md) | Crops input bands, calculates continuous indicators, and extracts zonal summaries exclusively inside house buffers (in meters or grid units) with automated ggplot mapping. |
| **Distance to Water Modeling** | [`d4h_distance_to_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_distance_to_water.md) | Computes minimum Euclidean distance from each dwelling to the nearest water body and calculates proximity exposure scores with stratified proximity tiers. |
| **Continuous Distance Surface** | [`d4h_raster_distance()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_raster_distance.md) | Generates a continuous proximity heat map raster measuring distance to water bodies across the entire flight extent. |
| **Water Body Segmentation** | [`d4h_segment_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_water.md) | Segments and vectorizes aquatic habitats from spectral imagery. |
| **Executive Reporting** | [`d4h_executive_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md) | Generates multi-tier descriptive statistics, spatial diagnostics, and direct multi-sheet Excel workbook export. |

------------------------------------------------------------------------

## 3 Workflow

### 3.1 Libraries

We load the required spatial and analytical packages:

``` r

library(drones4health)
library(terra)
library(sf)
library(ggplot2)
library(readxl)
```

### 3.2 Household GPS Data Ingestion & Co-Registration

We load the field GPS coordinates of community households from an Excel
file (`nuevas_casas_localizadas.xlsx`):

``` r

# 1. Define path to GPS household coordinates
houses_file <- "nuevas_casas_localizadas.xlsx"

# 2. Define paths to UAV multispectral and elevation bands
path_nir <- "img/Ohuay_NIR.tif"
path_r   <- "img/Ohuay_R.tif"
path_g   <- "img/Ohuay_G.tif"
path_dem <- "img/Ohuay_D.tif"

# Inspect ingested coordinates
houses_df <- readxl::read_excel(houses_file)
head(houses_df[, c("lat", "lon")])
```

### 3.3 Focal Buffer Zonal Analysis with `d4h_indicator_buffer()`

[`d4h_indicator_buffer()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_indicator_buffer.md)
accelerates computation by cropping the drone orthomosaic strictly to
the envelope of intersecting household buffers. It computes the
requested indicator (NDVI), extracts grid summaries, and renders an
automated visualization:

``` math
\text{Buffer Distance} = \text{radius} \times \text{cell\_size}
```

``` r

# Execute focal buffer analysis (150m buffer = 3 cells of 50m)
res_buffer <- d4h_indicator_buffer(
  indicator        = "NDVI",
  houses           = houses_file,
  radius           = 3,             # 3 grid units
  cell_size        = 50,            # 50m cell size -> 150m buffer radius
  radius_in_meters = FALSE,
  nir              = path_nir,
  red              = path_r,
  square           = FALSE,         # Hexagonal grid within buffer
  mask_outside     = TRUE,          # Masks non-focal areas outside buffer
  house_color      = "red",
  house_size       = 2.5,
  palette          = "viridis",
  limits           = c(0.1, 0.9),
  title            = "Peridomestic Vector Flight Radius (150m) - Focal Canopy NDVI",
  plot             = TRUE
)

# Inspect focal zonal statistics
head(res_buffer$grid)
```

### 3.4 Distance to Water Calculation & Proximity Scoring

Using the segmented water bodies from the flight footprint,
[`d4h_distance_to_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_distance_to_water.md)
measures the minimum Euclidean distance ($`d_{\text{min}}`$) from each
household to the closest water body and calculates an exponential
proximity score:

``` math
\text{ProximityScore}_i = \exp\left(-\frac{d_{\text{min}}(i)}{\lambda}\right)
```
where $`\lambda`$ represents the characteristic dispersal radius of
vector mosquitoes (e.g., $`\lambda = 100\text{ m}`$ for *Aedes aegypti*
or $`150\text{ m}`$ for *Anopheles*):

``` r

# 1. Segment water bodies from spectral indices
r_ndwi <- d4h_ndwi(green = path_g, nir = path_nir)
water_sf <- d4h_segment_water(
  raster_in            = r_ndwi,
  threshold            = 0.0,
  is_ndwi              = TRUE,
  max_water_brightness = 95.0,
  min_area_m2          = 2.0
)

# 2. Extract household spatial features from the buffer result
casas_sf <- res_buffer$houses

# 3. Calculate Euclidean distance and vector proximity scores
water_proximity_sf <- d4h_distance_to_water(
  buildings        = casas_sf,
  sources          = water_sf,
  decay_lambda     = 100.0,
  buffer_breaks    = c(50, 100, 200),
  proximity_labels = c("Immediate Proximity (<50m)", "High Proximity (50-100m)", "Moderate Proximity (100-200m)", "Distal (>200m)")
)

# Inspect household distance metrics and proximity tiers
head(as.data.frame(water_proximity_sf[, c("dist_water_m", "nearest_water_id", "proximity_score", "proximity_level")]))
```

### Proximity Stratification

| Proximity Tier | Proximity to Water | Proximity Score | Recommended Vector Surveillance Action |
|:---|:---|:---|:---|
| **Immediate Proximity** | $`< 50\text{ m}`$ | $`> 0.606`$ | Targeted indoor residual spraying and immediate larvicide application. |
| **High Proximity** | $`50 - 100\text{ m}`$ | $`0.368 - 0.606`$ | Intensive peridomestic inspection, drainage trenching, and water container netting. |
| **Moderate Proximity** | $`100 - 200\text{ m}`$ | $`0.135 - 0.368`$ | Oviposition trap monitoring and community sensitization campaigns. |
| **Distal** | $`> 200\text{ m}`$ | $`< 0.135`$ | Routine seasonal surveillance. |

------------------------------------------------------------------------

### 3.5 Continuous Distance Heat Map Generation

To model landscape connectivity and proximity gradients across the
entire flight footprint:

``` r

# Compute continuous Euclidean distance surface to nearest water source
r_dist_water <- d4h_raster_distance(
  sources    = water_sf,
  raster_ref = r_ndwi
)

# Plot continuous proximity gradient
d4h_plot(
  raster_in = r_dist_water,
  title     = "Continuous Euclidean Distance to Water Bodies (m)",
  palette   = "magma"
)
```

### 3.6 Executive Reporting & Excel Export

We consolidate multi-tier household proximity diagnostics into a
formatted spreadsheet for public health teams:

``` r

# Export executive summary workbook with focal buffer statistics
resumen_buffers <- d4h_executive_summary(
  raster_in   = res_buffer$raster,
  by          = "general",
  out_xlsx    = "salidas/Executive_Summary_Household_Buffers.xlsx",
  sample_size = 1000000,
  digits      = 3
)
print(resumen_buffers)
```

``` text
==============================================================================
             DRONES4HEALTH - EXECUTIVE SUMMARY REPORT
==============================================================================

 INDICATOR: FOCAL_BUFFER_NDVI
------------------------------------------------------------------------------
 1. SPATIAL COVERAGE AND RESOLUTION:
    - Pixel Resolution    : 99.21 cm
    - Focal Buffer Area   : 55.765 ha (557,650 m2) across peridomestic buffers
    - Total Households    : 55 residential units evaluated

 2. DISTANCE-TO-WATER PROXIMITY STRATIFICATION:
    - Critical (<50m)     :  1 house  ( 1.8 %) - Immediate vector control priority
    - High (50-100m)      :  3 houses ( 5.5 %) - Active entomological surveillance
    - Moderate (100-200m) : 24 houses (43.6 %) - Periodic routine monitoring
    - Low (>200m)         : 27 houses (49.1 %) - Baseline buffer zone

 3. FOCAL VEGETATION CANOPY METRICS (NDVI INSIDE BUFFERS):
    - Arithmetic Mean     : 0.282 (+/- 0.221 SD)
    - Valid Range         : [-0.485, 0.946]
    - Median (Q50)        : 0.245
==============================================================================
```

![Households and Breeding Sites
Mapping](../reference/figures/01_orthomosaic_rgb.png)
