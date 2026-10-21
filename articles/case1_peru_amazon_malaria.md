# Case Study 1: Malaria & Micro-Hydrology - Peruvian Amazon

## 1. Epidemiological Context & Landscape Ecology

In the **Peruvian Amazon** (e.g., Loreto, Ucayali, Madre de Dios),
*Anopheles darlingi* is the primary vector driving endemic malaria
transmission (*Plasmodium vivax* and *P. falciparum*).

Unlike macro-scale satellite products (MODIS, Landsat) that fail to
detect puddles obscured under dense primary or secondary canopy,
ultra-high resolution drone orthomosaics capture: 1. **Micro-topographic
drainage sinks** and slow-moving stream margins. 2. **Artificial water
depressions** created by illegal gold mining pits (*minería aluvial*)
and fish farming ponds (*piscigranjas*). 3. **Peridomestic vector flight
buffers** ($`100 - 250\text{ m}`$) from riverine indigenous and rural
settlements.

## 2. Targeted Indicator Suite

| Indicator | Implementation | Entomological Significance |
|:---|:---|:---|
| **NDVI / NDRE** | [`d4h_ndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndvi.md), [`d4h_ndre()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndre.md) | Quantifies dense canopy shading that shelters adult *Anopheles* during hot diurnal hours. |
| **NDWI / IRHE** | [`d4h_ndwi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndwi.md), [`d4h_irhe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irhe.md) | Detects open water surfaces and turbid, stagnant water bodies in deforested clearings. |
| **Slope & TWI** | [`d4h_slope()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_slope.md), [`d4h_twi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_twi.md) | Identifies flat terrain ($`\beta < 3^\circ`$) with high wetness accumulation prone to persistent flooding. |
| **Buffer Focal Analysis** | [`d4h_indicator_buffer()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_indicator_buffer.md) | Limits statistical computation to the biologically relevant vector foraging radius around households. |
| **Euclidean Risk Decay** | [`d4h_distance_to_risk()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_distance_to_risk.md) | Computes risk of transmission as an exponential decay function $`R_i = \sum e^{-d_{ij}/\lambda}`$. |

## 3. End-to-End Execution Workflow

``` r

library(drones4health)
library(terra)
library(sf)
library(ggplot2)

# File paths to UAV orthomosaics
img_dir  <- "data/peru_amazon"
path_rgb <- file.path(img_dir, "Ohuay_D.tif")    # Orthomosaic
path_nir <- file.path(img_dir, "Ohuay_NIR.tif")  # Near Infrared
path_r   <- file.path(img_dir, "Ohuay_R.tif")    # Red
path_re  <- file.path(img_dir, "Ohuay_RE.tif")   # Red Edge
xlsx_houses <- "nuevas_casas_localizadas.xlsx"

# Step 1: Focal NDVI Buffer around native riverine houses (150m buffer)
res_buffer <- d4h_indicator_buffer(
  indicator   = "NDVI",
  houses      = xlsx_houses,
  radius      = 3,            # 3 grid cells
  cell_size   = 50,           # 50m cell size = 150m buffer
  nir         = path_nir,
  red         = path_r,
  palette     = "viridis",
  title       = "Malaria Vector Flight Range (150m): Focal NDVI & River Margins"
)

# Step 2: Surface Water Segmentation
r_ndvi <- d4h_ndvi(nir = path_nir, red = path_r)

water_bodies <- d4h_segment_water(
  raster_in            = r_ndvi,
  rgb_raster           = path_rgb,
  max_water_brightness = 90.0,   # Avoid bright metal roofs misclassification
  threshold            = -0.15,
  min_area_m2          = 15.0    # Detect small larvae habitats
)

# Step 3: Proximity Risk from Household to Larval Habitats
casas_riesgo <- d4h_distance_to_risk(
  buildings    = res_buffer$houses,
  sources      = water_bodies,
  decay_lambda = 100.0          # 100m mean dispersal parameter
)

# Summary of exposure
table(casas_riesgo$risk_level)
# Critico (<50m): 30 casas | Alto (50-100m): 16 casas | Moderado: 3 casas | Bajo: 6 casas

# Step 4: Executive Zonal Grid Summary
d4h_export_summary(
  raster_in   = res_buffer$raster,
  output_file = "Reporte_Malaria_Loreto_Perú.xlsx",
  cell_size   = 100
)
```

## 4. Operational Health Decision Support

- **Targeted Larviciding:** Direct field teams with *Bacillus
  thuringiensis israelensis* (BTI) exclusively to water polygons
  classified within the Critical category ($`<50\text{ m}`$).
- **Indoor Residual Spraying (IRS):** Prioritize houses located within
  $`100\text{ m}`$ of flood sinks during the onset of the seasonal river
  recession.
