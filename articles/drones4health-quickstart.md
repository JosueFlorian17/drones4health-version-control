# Quickstart: UAV Micro-Environmental Pipeline for Spatial Health

## 1. Overview

**`drones4health`** provides automated workflows to turn raw drone
orthomosaics (RGB, Multispectral, Thermal, and DEM) into actionable
micro-environmental epidemiological metrics.

           [UAV Multispectral / DEM Bands]
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
    [Spectral Indices: NDVI/NDWI]  [Micro-Topography: Slope/TWI]
            │                           │
            └─────────────┬─────────────┘
                          ▼
           [Segmentation & Object Detection]
           (Water Bodies & Residential Roofs)
                          │
                          ▼
             [Focal Buffers & Risk Modeling]
             (Euclidean Distance & Grids)
                          │
                          ▼
         [Executive Summaries & Multi-Sheet Excel]

## 2. Installation

Install the package directly from GitHub:

``` r

# install.packages("pak")
pak::pak("JosueFlorian17/drones4health-version-control")
```

Or using `remotes`:

``` r

remotes::install_github("JosueFlorian17/drones4health-version-control")
```

Load libraries:

``` r

library(drones4health)
library(terra)
library(sf)
library(ggplot2)
```

## 3. Basic Workflow: Spectral Indices & Water Detection

``` r

# Define file paths to UAV bands
nir_path <- "data/Ohuay_NIR.tif"
red_path <- "data/Ohuay_R.tif"
dem_path <- "data/Ohuay_D.tif"
rgb_path <- "data/Ohuay_RGB.tif"

# 1. Calculate NDVI and Topographic Wetness Index (TWI)
r_ndvi <- d4h_ndvi(nir = nir_path, red = red_path)
r_twi  <- d4h_twi(dem_raster = dem_path)

# 2. Segment water bodies with optical brightness protection
water_bodies <- d4h_segment_water(
  raster_in            = r_ndvi,
  rgb_raster           = rgb_path,
  max_water_brightness = 90.0,
  threshold            = -0.15,
  min_area_m2          = 15.0
)
```

## 4. Focal Household Buffers & Distance-to-Risk

Evaluate micro-environmental exposure strictly inside a buffer around
community households:

``` r

# Compute focal NDVI inside a 150m buffer (3 grid units of 50m) around houses
res_buffer <- d4h_indicator_buffer(
  indicator   = "NDVI",
  houses      = "nuevas_casas_localizadas.xlsx",
  radius      = 3,
  cell_size   = 50,
  nir         = nir_path,
  red         = red_path,
  palette     = "viridis",
  title       = "Focal Household Buffer (150m) - NDVI"
)

# Distance decay risk modeling to water bodies
risk_houses <- d4h_distance_to_risk(
  buildings    = res_buffer$houses,
  sources      = water_bodies,
  decay_lambda = 100.0
)

# Display distribution of epidemiological exposure
table(risk_houses$risk_level)
```

## 5. Executive Reporting

Extract comprehensive multi-moment descriptive statistics and export to
Excel:

``` r

# Console executive summary
print(d4h_executive_summary(res_buffer$raster, by = "general"))

# Export operational 100m grid diagnostics to Excel
d4h_export_summary(
  raster_in   = res_buffer$raster,
  output_file = "Reporte_Focal_NDVI.xlsx",
  cell_size   = 100
)
```
