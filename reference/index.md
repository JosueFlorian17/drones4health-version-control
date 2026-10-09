# Package index

## Spectral Vegetation Indices & Land Cover Masks

Functions to calculate multispectral vegetation vigor, canopy
chlorophyll, moisture accumulation, and binary bare soil substrate
masks.

- [`d4h_ndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndvi.md)
  : Normalized Difference Vegetation Index (NDVI)
- [`d4h_msavi2()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_msavi2.md)
  : Modified Soil-Adjusted Vegetation Index 2 (MSAVI2)
- [`d4h_savi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_savi.md)
  : Soil-Adjusted Vegetation Index (SAVI)
- [`d4h_bare_soil()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_bare_soil.md)
  : Bare Soil Mask
- [`d4h_vari()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_vari.md)
  : Visible Atmospherically Resistant Index (VARI)
- [`d4h_ndre()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndre.md)
  : Normalized Difference Red Edge Index (NDRE)
- [`d4h_gndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_gndvi.md)
  : Green Normalized Difference Vegetation Index (GNDVI)
- [`d4h_ndwi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndwi.md)
  : Normalized Difference Water Index (NDWI)
- [`d4h_evi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_evi.md)
  : Enhanced Vegetation Index (EVI)
- [`d4h_dvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_dvi.md)
  : Difference Vegetation Index (DVI)
- [`d4h_ctvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ctvi.md)
  : Corrected Transformed Vegetation Index (CTVI)

## Micro-Terrain Topography & Hydrology

Elevation derivatives and terrain moisture modeling from UAV Digital
Elevation Models (DEM/DSM).

- [`d4h_slope()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_slope.md)
  : Topographic Slope
- [`d4h_twi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_twi.md)
  : Topographic Wetness Index (TWI)

## Eco-Epidemiological Risk Indices (One Health)

Spatial modeling of localized vector-borne disease transmission risks,
solid waste micro-accumulation, and hydric breeding suitability.

- [`d4h_imsr()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_imsr.md)
  : Synthetic Materials Risk Index (IMSR)
- [`d4h_irhe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irhe.md)
  : Spectral Water Retention Index (IRHE)
- [`d4h_irih()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irih.md)
  : Human Interface Roughness Index (IRIH)
- [`d4h_irts()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irts.md)
  : Thermal Refuge and Shade Index (IRTS)
- [`d4h_iev()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_iev.md)
  : Vulnerability Stagnation Indicator (IEV)
- [`d4h_iec()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_iec.md)
  : Breeding Site Stratification Index (IEC)
- [`d4h_ifeb()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ifeb.md)
  : Fragmentation and Edge Effect Index (IFEB)
- [`d4h_iead()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_iead.md)
  : Clearing Stagnation Index (IEAD)

## Feature Segmentation & Spatial Proximity Risk

Automated object segmentation of water bodies and residential building
footprints from ultra-high resolution RGB imagery, with Euclidean
distance risk modeling.

- [`d4h_segment_water()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_water.md)
  : Segment Water Bodies and Surface Moisture Pools
- [`d4h_segment_buildings()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_buildings.md)
  : Segment House Roofs and Building Footprints
- [`d4h_distance_to_risk()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_distance_to_risk.md)
  : Calculate Distance and Vulnerability Risk to Water Sources
- [`d4h_raster_distance()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_raster_distance.md)
  : Continuous Euclidean Distance Raster from Risk Sources

## Spatial Grids & Zonation

Operational surveillance grids (hexagons/squares) and zonal summary
statistics extraction.

- [`d4h_hex_grid()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_hex_grid.md)
  : Generate Hexagonal Surveillance Grid
- [`d4h_summarize_grid()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_summarize_grid.md)
  : Summarize Raster Indicator by Spatial Grid
- [`d4h_summarize_general()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_summarize_general.md)
  : Summarize Raster Indicator for the General Mosaic Footprint
- [`d4h_raster_general()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_raster_general.md)
  : Convert Raster Indicator to General Homogeneous Mosaic
- [`d4h_summarize_global()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_summarize_global.md)
  [`d4h_global_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_summarize_global.md)
  : Global Statistical Summary of Raster Indicators

## Interactive Mapping & Cartography

Interactive swipe comparison viewers with dynamic contrast tuning and
static publication-quality ggplot2 cartography.

- [`d4h_mapview_swipe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_mapview_swipe.md)
  : Interactive Side-by-Side Raster Swipe Viewer
- [`d4h_plot()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_plot.md)
  : Cartographic Visualization with ggplot2

## Executive Reporting & Excel Export

Multi-moment statistical summaries, Tukey outlier diagnostics, and
direct multi-sheet Excel (.xlsx) workbook export.

- [`d4h_executive_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md)
  [`d4h_report()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md)
  : Executive Summary of Micro-Environmental and Epidemiological
  Indicators
- [`d4h_export_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_export_summary.md)
  : Export Executive Summary to Multi-Sheet Excel File

## Preprocessing, Calibration & Utilities

Surface reflectance scaling, thermal calibration to Celsius Land Surface
Temperature, raster cleaning, and batch mosaic workflows.

- [`d4h_normalize_reflectance()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_normalize_reflectance.md)
  : Normalize Digital Numbers to Surface Reflectance
- [`d4h_thermal_to_celsius()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_thermal_to_celsius.md)
  : Convert Thermal Band to Celsius
- [`d4h_clean_band()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_clean_band.md)
  : Clean Raster Band Artefacts
- [`d4h_process_mosaic()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_process_mosaic.md)
  : End-to-End Drone Mosaic Processing Pipeline
- [`d4h_list_metrics()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_list_metrics.md)
  : List Available Micro-Environmental and Epidemiological Metrics
