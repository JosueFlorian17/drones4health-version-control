# drones4health: Ultra-High Resolution Drone Metrics for Spatial Health Analysis

Calculate and extract ultra-high resolution remote sensing metrics for
spatial health analysis. This package offers R users a straightforward
way to obtain continuous and zonal micro-environmental statistics and
epidemiological indicators from UAV orthomosaics. Designed to map
localized infection risks within a One Health framework.

## 1. Installation

You can install the development version from GitHub with:

``` r

# install.packages("pak")
pak::pak("JosueFlorian17/drones4health-version-control")
```

``` r

library(drones4health)
```

## 2. Available Micro-Environmental and Epidemiological Metrics

`drones4health` focuses on a curated set of spectral, topographic, and
epidemiological indicators:

``` r

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

Each indicator function accepts either a `SpatRaster` object or a direct
file path string (`.tif`), and supports both continuous calculation
(`d4h_*_general`) and on-the-fly grid aggregation (`cell_size`):

``` r

library(drones4health)
library(terra)

# 1. Calculate base spectral indices
ndwi_continuous <- d4h_ndwi_general(green = "data/green.tif", nir = "data/nir.tif")

# 2. Calculate Topographic Wetness Index (TWI)
twi_continuous  <- d4h_twi_general(dem = "data/dem.tif")

# 3. Calculate Vulnerability Stagnation Indicator (IEV) with 20m hexagonal grid summary
iev_grid <- d4h_iev(
  ndwi = ndwi_continuous, 
  dem = "data/dem.tif", 
  cell_size = 20, 
  square = FALSE
)
```

## 4. Example: Generate Hexagonal Surveillance Grid

Create operational spatial grids for active surveillance across the
survey area:

``` r

# Generate 50m operative surveillance grid
surveillance_grid <- d4h_hex_grid(aoi = ndwi_continuous, cell_size = 50)

# Summarize continuous raster layers over grid
grid_summary <- d4h_summarize_grid(
  raster_in = ndwi_continuous, 
  cell_size = 50, 
  square = FALSE
)
```

## 5. Visualization with ggplot2

``` r

# Plot continuous layer or zonal summary
d4h_plot(ndwi_continuous, title = "Continuous NDWI Extent")
d4h_plot(iev_grid, title = "IEV Stagnation Risk (20m Hexagons)", palette = "magma")
```
