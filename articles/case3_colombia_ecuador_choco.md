# Case Study 3: Wet Pacific - Colombia

## 1. Epidemiological Context: The Hyper-Humid Chocó & Pacific Basins

The Pacific coastal plains of **Colombia** form one of the wettest
biogeographic corridors in the world.

Epidemiological challenges include: - High precipitation
($`>4,000\text{ mm/year}`$) leading to chronic soil waterlogging. -
Simultaneous circulation of arboviruses (Dengue, Chikungunya) and
malaria (*Anopheles albimanus* and *An. darlingi*). - Complex river
corridors with palafitic houses erected along tidal or fluvial
floodplains.

## 2. Targeted Indicator Suite

| Indicator | Implementation | Significance |
|:---|:---|:---|
| **IEV** | [`d4h_iev()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_iev.md) | Vectorial Stagnation Index: detects areas where flat topography ($`\text{slope} \approx 0`$) coincides with persistent surface moisture. |
| **VARI / EVI** | [`d4h_vari()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_vari.md), [`d4h_evi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_evi.md) | Captures vegetation vigor from standard RGB sensors in high cloud-cover conditions where infrared may saturate. |
| **TWI** | [`d4h_twi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_twi.md) | Identifies natural hydrologic flow paths and subterranean water accumulation in lowlands. |
| **IRHE** | [`d4h_irhe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irhe.md) | Stagnant Turbid Moisture Index: differentiates clean flowing river channels from eutrophic, brackish puddles favored by vector larvae. |

## 3. Workflow

### 3.1 Libraries & Elevation Models

We load raster and vector processing tools to model hydrologic drainage
gradients from digital surface models (DSM/DEM):

``` r

library(drones4health)
library(terra)
library(sf)
library(ggplot2)

# File paths to UAV elevation and multispectral data
path_dem <- "data/choco_pacific/Ohuay_D.tif"    # DEM / DSM
path_nir <- "data/choco_pacific/Ohuay_NIR.tif"  # NIR band
path_r   <- "data/choco_pacific/Ohuay_R.tif"    # Red band
path_g   <- "data/choco_pacific/Ohuay_G.tif"    # Green band
path_rgb <- "data/choco_pacific/Ohuay_D.tif"    # Orthomosaic
```

### 3.2 Topographic Wetness & Slope Modeling

We derive topographic curvature and hydrologic wetness index (TWI) to
locate flood basins:

``` r

# Compute continuous Slope (degrees) and Topographic Wetness Index (TWI)
r_slope <- d4h_slope(dem_raster = path_dem, unit = "degrees")
r_twi   <- d4h_twi(dem_raster = path_dem)
```

### 3.3 Stagnant Turbid Moisture (IRHE) & Vector Stagnation (IEV)

We isolate stagnant turbid moisture pools from active river flow and
compute the integrated Vectorial Stagnation Index (IEV):

``` r

# Compute Stagnant Turbid Moisture (IRHE)
r_irhe <- d4h_irhe(red = path_r, green = path_g)

# Compute Vectorial Stagnation Index (IEV) merging NDWI and Slope
r_ndwi <- d4h_ndwi(green = path_g, nir = path_nir)
r_iev  <- d4h_iev(ndwi = r_ndwi, slope = r_slope)
```

![Hydrologic Accumulation vs Stagnant
Moisture](../reference/figures/case3_swipe_accumulation.png)

*Figure 3.3: Spectro-topographic detection of stagnant micro-basins and
moisture accumulation zones.*

### 3.4 Visual Analytics & Dual-Layer Inspection

We contrast topographic accumulation against stagnant moisture puddles
to verify drainage conditions:

``` r

# Interactive side-by-side swipe comparison
d4h_mapview_swipe(
  x       = r_twi,
  y       = r_irhe,
  col_x   = "viridis",
  col_y   = "magma",
  basemap = TRUE
)
```

### 3.5 Executive Exposure Summary & Basin Indicators

``` r

# Executive multi-moment summary across the surveyed river corridor
pacific_summary <- d4h_executive_summary(r_iev, by = "general")
print(pacific_summary)
```

    #> ── Executive Summary: Pacific Corridor Stagnation & Moisture Exposure ──
    #> Total Corridor Surveyed: 112.8 ha
    #> Mean IEV Index: 0.472 (SD: 0.165)
    #> High Stagnation Zones: 31.4 ha (Slope < 2° & Waterlogged Soil)
    #> Critical Drainage Choke Points: 14 primary confluence sites
