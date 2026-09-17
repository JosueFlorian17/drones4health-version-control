# drones4health: Ultra-High Resolution Drone Metrics for Spatial Health Analysis

<!-- badges: start -->
<!-- badges: end -->

Calculate and extract ultra-high resolution remote sensing metrics for spatial health analysis. This package offers R users a straightforward way to obtain continuous and zonal micro-environmental statistics and epidemiological indicators from UAV orthomosaics. Designed to map localized infection risks within a One Health framework.

## 1. Installation

You can install the development version from GitHub with:

```r
# install.packages("pak")
pak::pak("JosueFlorian17/drones4health-version-control")
```

```r
library(drones4health)
```

## 2. Available Micro-Environmental and Epidemiological Metrics

`drones4health` focuses on a curated set of spectral, topographic, and epidemiological indicators:

```r
d4h_list_metrics()
#> # A tibble: 5 × 4
#>   category        metric            resolution_cm application                              
#>   <chr>           <chr>                     <dbl> <chr>                                    
#> 1 Spectral        NDVI                          5 Vegetation vigor & biomass               
#> 2 Spectral        NDWI                          5 Surface water & moisture detection       
#> 3 Topographic     TWI                          10 Topographic micro-hydrology & pooling    
#> 4 Epidemiological IEV (Stagnation)             10 Vector / snail breeding micro-depressions
#> 5 Epidemiological IMSR (Synthetics)             5 Artificial container & waste risk sites  
```

## 3. Example: Calculate Epidemiological Indices from UAV Imagery

All indicator functions accept either `terra::SpatRaster` objects or direct file paths (`character`), automatically handle CRS/extent alignment, and mask background NoData to `NA`:

```r
library(drones4health)
library(terra)

# 1. Calculate base spectral indices
ndwi_layer <- d4h_ndwi(green = "data/green.tif", nir = "data/nir.tif")

# 2. Derive topographic indicators
twi_layer   <- d4h_twi(dem_raster = "data/dem.tif")
slope_layer <- d4h_slope(dem_raster = "data/dem.tif")

# 3. Calculate Vulnerability Stagnation Indicator (IEV)
iev_risk <- d4h_iev(delta_ndwi = ndwi_layer, slope_dsm = slope_layer)
```

## 4. Example: Generate Hexagonal Surveillance Grid

Create operational spatial grids and extract zonal summaries across the survey area:

```r
# Generate 50m operative surveillance grid
surveillance_grid <- d4h_hex_grid(aoi = iev_risk, cell_size = 50)

# Summarize continuous raster layers over grid
grid_summary <- d4h_summarize_grid(
  raster_in = iev_risk, 
  cell_size = 50, 
  square = FALSE
)
```

## 5. Visualization with ggplot2

```r
# Plot continuous raster or zonal grid with automatic aggregation and transparent background
d4h_plot(iev_risk, title = "Continuous IEV Stagnation Risk", palette = "magma")
d4h_plot(grid_summary, title = "IEV Stagnation Risk (50m Hexagons)")
```
