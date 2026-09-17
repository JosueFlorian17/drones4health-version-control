# drones4health: Ultra-High Resolution Drone Metrics for Spatial Health Analysis <img src="man/figures/logo.png" align="right" width="120" />

<!-- badges: start -->
<!-- badges: end -->

Calculate and extract ultra-high resolution remote sensing metrics for spatial health analysis 🚁. This package offers R users a quick and straightforward way to obtain micro-environmental statistics and epidemiological indicators (e.g., bare soil, stagnation, synthetic materials) from UAV orthomosaics. Designed to map localized infection risks, such as *Fasciola hepatica* and vector-borne diseases, within a One Health framework.

## 1. Installation

You can install the development version from GitHub with:

```r
# install.packages("pak")
pak::pak("JosueFlorian17/drones4health-version-control")
```

```r
library(drones4health)
# Initialize Terra out-of-core processing automatically
```

## 2. List of available micro-environmental metrics

`drones4health` implements standardized spectral indices alongside novel epidemiological indicators optimized for drone imagery.

```r
d4h_list_metrics()
#> # A tibble: 12 × 4
#>    category          metric            resolution_cm  application
#>    <chr>             <chr>             <dbl>          <chr>
#>  1 Topographic       Slope             10             Runoff prediction
#>  2 Topographic       TWI               10             Micro-hydrology
#>  3 Spectral          NDVI              5              Vegetation vigor
#>  4 Spectral          NDWI              5              Surface water
#>  5 Spectral          LST (°C)          30             Thermal mapping
#>  6 Epidemiological   Bare Soil Mask    5              Zoonotic/fecalism risk
#>  7 Epidemiological   IMSR (Synthetics) 5              Aedes breeding sites
#>  8 Epidemiological   IEV (Stagnation)  10             Snail/mosquito habitat
#>  ...
```

## 3. Example: Calculate Epidemiological Indices from UAV Imagery

This example demonstrates how to calculate the Vulnerability Stagnation Indicator (IEV) and map *Fasciola hepatica* environmental suitability using multi-spectral and thermal drone surveys.

```r
library(drones4health)
library(terra)

# Load drone bands (Red, NIR, Green, DEM)
dsm_raster <- rast("data/huayllapata_dsm.tif")
green_band <- rast("data/huayllapata_green.tif")
nir_band   <- rast("data/huayllapata_nir.tif")

# Calculate base indices
ndwi_layer <- d4h_ndwi(green_band, nir_band)
slope_layer <- d4h_slope(dsm_raster)

# Calculate Vulnerability Stagnation Indicator (IEV)
iev_risk <- d4h_iev(delta_ndwi = ndwi_layer, slope_dsm = slope_layer)
```

```r
# Spatial visualization
library(ggplot2)
library(tidyterra)

ggplot() +
  geom_spatraster(data = iev_risk) +
  scale_fill_viridis_c(name = "Stagnation Risk\n(IEV)", option = "magma") +
  theme_minimal(base_size = 15) +
  labs(title = "Fine-scale F. hepatica Risk Zones - Huayllapata")
```

## 4. Example: Generate Hexagonal Grid and ML-Ready Matrix

Integrate drone-derived indices into localized covariates to feed spatial Machine Learning models (Random Forest, XGBoost).

```r
# Generate 50m operative grid for active surveillance
surveillance_grid <- d4h_hex_grid(aoi = iev_risk, cell_size = 50)

# Extract zonal statistics for Machine Learning Matrix
ml_matrix <- d4h_build_ml_matrix(
  hex_data = surveillance_grid, 
  raster_stack = c(ndwi_layer, slope_layer, iev_risk),
  funs = c("mean", "max")
)
```
