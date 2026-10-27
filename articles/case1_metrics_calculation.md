# Case 01 - Orthomosaic Ingestion & Metric Calculation

*Extracting ultra-high resolution vegetation and water metrics from UAV
orthomosaics*

## 1 Objective

Ingest UAV orthomosaic bands (Near-Infrared, Red, and Green) and compute
two foundational environmental metrics: Normalized Difference Vegetation
Index (NDVI) and Normalized Difference Water Index (NDWI).

![Study Area Orthomosaic and Vegetation
Metrics](../reference/figures/02_metric_ndvi.png)

------------------------------------------------------------------------

## 2 Functions from `drones4health`

| Variable / Target | Function | Description |
|:---|:---|:---|
| **Multi-Band Stack Ingestion** | [`d4h_read_stack()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_read_stack.md) | Ingests multi-band raster stacks and verifies that required spectral bands are present, halting with an informative error if any band is missing. |
| **Vegetation Canopy** | [`d4h_ndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndvi.md) | Quantifies photosynthetic vigor and vegetative canopy cover from Near-Infrared and Red bands. |
| **Water Detection** | [`d4h_ndwi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndwi.md) | Delineates open standing water surfaces and moisture accumulation from Green and Near-Infrared bands. |
| **Unified Visualization** | [`d4h_plot()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_plot.md) | Unified visualization: renders static `ggplot2` maps when `interactive = FALSE`, or interactive web maps via `mapview` when `interactive = TRUE`. |

------------------------------------------------------------------------

## 3 Workflow

### 3.1 Libraries

We load the core spatial packages and dependencies required for drone
remote sensing analysis:

``` r

library(drones4health)
library(terra)
library(ggplot2)
```

### 3.2 Spatial Data Preparation & Multi-Band Stack Ingestion

We can ingest individual spectral band files or load a multi-band
GeoTIFF stack using
[`d4h_read_stack()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_read_stack.md),
which automatically validates that all required bands are present:

``` r

# Option A: Ingest individual drone band GeoTIFF files
path_nir <- "img/Ohuay_NIR.tif"
path_r   <- "img/Ohuay_R.tif"
path_g   <- "img/Ohuay_G.tif"

# Option B: Ingest a multi-band stacked raster with automated band validation
# If any required band is missing, d4h_read_stack halts with an informative error
# r_stack <- d4h_read_stack(
#   file_path      = "img/Ohuay_Stack.tif",
#   required_bands = c("NIR", "Red", "Green")
# )
```

### 3.3 Metric Calculation: NDVI & NDWI

We compute the two environmental indices directly from the raster bands:

``` r

# 1. Normalized Difference Vegetation Index (NDVI)
# Formula: (NIR - Red) / (NIR + Red)
r_ndvi <- d4h_ndvi(nir = path_nir, red = path_r)

# 2. Normalized Difference Water Index (NDWI)
# Formula: (Green - NIR) / (Green + NIR)
r_ndwi <- d4h_ndwi(green = path_g, nir = path_nir)
```

### 3.4 Unified Visualization (Static & Interactive)

[`d4h_plot()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_plot.md)
provides a single unified interface: setting `interactive = FALSE`
outputs a publication-ready `ggplot2` figure, while `interactive = TRUE`
renders an interactive `mapview` web map:

``` r

# 1. Static publication-ready cartography via ggplot2 (interactive = FALSE)
p_static <- d4h_plot(
  x           = r_ndvi,
  interactive = FALSE,
  palette     = "viridis",
  title       = "UAV Canopy Density (NDVI)",
  limits      = c(-0.1, 0.9)
)
print(p_static)

# 2. Interactive web map exploration via mapview (interactive = TRUE)
m_interactive <- d4h_plot(
  x           = r_ndvi,
  interactive = TRUE,
  palette     = "viridis",
  title       = "UAV Canopy Density (NDVI)"
)
m_interactive
```

![Interactive Mapview Web Map with Basemap
Background](../reference/figures/01_mapview_basemap.png)

------------------------------------------------------------------------

## 4 Results & Executive Reporting

### 4.1 Multi-Moment Executive Summary

We generate an automated executive summary evaluating spatial moments
(mean, standard deviation, coefficient of variation, median,
interquartile range), Tukey outlier fences, and thematic stratum
distributions for both NDVI and NDWI:

``` r

# Generate multi-moment executive summary with direct multi-sheet Excel export
resumen_caso01 <- d4h_executive_summary(
  raster_in   = c(r_ndvi, r_ndwi),
  by          = "general",
  out_xlsx    = "salidas/Executive_Summary_Case01_Metrics.xlsx",
  sample_size = 1000000,
  digits      = 3
)
print(resumen_caso01)
```

``` text
==============================================================================
             DRONES4HEALTH - EXECUTIVE SUMMARY REPORT
==============================================================================

 INDICATOR: NDVI
------------------------------------------------------------------------------
 1. SPATIAL COVERAGE AND RESOLUTION:
    - Pixel Resolution    : 99.21 cm
    - Surveyed Area       : 64.628 ha (646,276 m2)
    - Evaluated Pixels    : 656,624 (36.5% valid footprint coverage)

 2. GLOBAL DESCRIPTIVE STATISTICAL MOMENTS:
    - Arithmetic Mean     : 0.238 (+/- 0.255 SD)
    - Coeff. of Variation : 106.9 %
    - Overall Range [Min,Max]: [-0.954, 0.99] (Span: 1.944)
    - Median (Q50)        : 0.182
    - Interquartile Range : [0.052, 0.399] (IQR: 0.347)
    - Central 90% Span    : [-0.083, 0.716] (P05 - P95)

 3. SPATIAL OUTLIER DIAGNOSTICS (TUKEY IQR):
    - Tukey IQR Fences    : Lower < -0.469 | Upper > 0.92
    - Outliers Detected   : 5,388 pixels (0.82% of valid pixels)
    - Spatial Diagnostics : Homogeneous distribution (extreme values < 1%)

 4. THEMATIC STRATIFICATION & SPATIAL EXTENT:
    - Water / Substrate degradation (< 0.0)     :  14.7 % (  9.53 ha)
    - Bare soil / Sparse canopy [0.0, 0.2)      :  38.2 % ( 24.67 ha)
    - Moderate vegetation / Transition [0.2, 0.5):  29.4 % ( 18.99 ha)
    - Dense vegetation / High vigor [>= 0.5)    :  17.7 % ( 11.44 ha)

..............................................................................

 INDICATOR: NDWI
------------------------------------------------------------------------------
 1. SPATIAL COVERAGE AND RESOLUTION:
    - Pixel Resolution    : 99.21 cm
    - Surveyed Area       : 64.628 ha (646,276 m2)
    - Evaluated Pixels    : 656,624 (36.5% valid footprint coverage)

 2. GLOBAL DESCRIPTIVE STATISTICAL MOMENTS:
    - Arithmetic Mean     : -0.194 (+/- 0.241 SD)
    - Coeff. of Variation : 124.2 %
    - Overall Range [Min,Max]: [-0.985, 0.923] (Span: 1.908)
    - Median (Q50)        : -0.158
    - Interquartile Range : [-0.342, -0.041] (IQR: 0.301)
    - Central 90% Span    : [-0.641, 0.185] (P05 - P95)

 3. SPATIAL OUTLIER DIAGNOSTICS (TUKEY IQR):
    - Tukey IQR Fences    : Lower < -0.794 | Upper > 0.410
    - Outliers Detected   : 4,112 pixels (0.63% of valid pixels)
    - Spatial Diagnostics : Homogeneous distribution (extreme values < 1%)

 4. THEMATIC STRATIFICATION & SPATIAL EXTENT:
    - Water bodies / Saturated soil (> 0.0)     :  18.6 % ( 12.02 ha)
    - Unsaturated terrestrial surface (<= 0.0)  :  81.4 % ( 52.61 ha)

==============================================================================
```

### 4.2 Excel Export Structure & Sheet Previews

The workbook exported to `salidas/Executive_Summary_Case01_Metrics.xlsx`
contains 3 dedicated sheets:

1.  **`Global_Summary`**: Statistical moments, spatial extent, pixel
    counts, and coefficient of variation.
2.  **`Thematic_Strata`**: Percentage and surface area in hectares
    partitioned by biophysical threshold ranges.
3.  **`Outliers_Diagnostics`**: Tukey lower/upper fences, outlier
    counts, and distribution diagnoses.

#### Sheet 1: `Global_Summary` Preview

| Indicator | Resolution | Valid_Pixels | Coverage_Pct | Area_ha | Mean | Std_Dev | CV_Pct | Min | Median_Q50 | Max | IQR | Outliers_Pct | Outlier_Diagnostics |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| **NDVI** | 99.21 cm | 656,624 | 36.5% | 64.628 | 0.238 | 0.255 | 106.9% | -0.954 | 0.182 | 0.990 | 0.347 | 0.82% | Homogeneous (\< 1%) |
| **NDWI** | 99.21 cm | 656,624 | 36.5% | 64.628 | -0.194 | 0.241 | 124.2% | -0.985 | -0.158 | 0.923 | 0.301 | 0.63% | Homogeneous (\< 1%) |

#### Sheet 2: `Thematic_Strata` Preview

| Indicator | Stratum | Percentage (%) | Surface (ha) |
|:---|:---|:---|:---|
| **NDVI** | Water / Substrate degradation (\< 0.0) | 14.7% | 9.53 ha |
| **NDVI** | Bare soil / Sparse canopy \[0.0, 0.2) | 38.2% | 24.67 ha |
| **NDVI** | Moderate vegetation / Transition \[0.2, 0.5) | 29.4% | 18.99 ha |
| **NDVI** | Dense vegetation / High vigor \[\>= 0.5) | 17.7% | 11.44 ha |
| **NDWI** | Water bodies / Saturated soil (\> 0.0) | 18.6% | 12.02 ha |
| **NDWI** | Unsaturated terrestrial surface (\<= 0.0) | 81.4% | 52.61 ha |

#### Sheet 3: `Outliers_Diagnostics` Preview

| Indicator | Lower_Fence | Upper_Fence | Low_Outliers | High_Outliers | Total_Outliers | Outlier_Pct | Diagnosis |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **NDVI** | -0.469 | 0.920 | 2,140 | 3,248 | 5,388 | 0.82% | Homogeneous distribution |
| **NDWI** | -0.794 | 0.410 | 1,820 | 2,292 | 4,112 | 0.63% | Homogeneous distribution |
