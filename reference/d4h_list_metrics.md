# List Available Micro-Environmental and Epidemiological Metrics

Dynamically retrieves all available remote sensing indices, terrain
metrics, and eco-epidemiological indicators supported by the package,
detailing their mathematical formulas, typical spatial resolutions, and
vector surveillance applications.

## Usage

``` r
d4h_list_metrics(category = NULL)
```

## Arguments

- category:

  Character (optional). Filter metrics by category: "Spectral",
  "Topographic", "Epidemiological", or NULL to list all.

## Value

A pure `data.frame` containing the metric names, corresponding package
functions, formulas, and epidemiological applications.

## Examples

``` r
library(drones4health)

# Display all available spatial health metrics
metrics_table <- d4h_list_metrics()
print(metrics_table)
#>           category    metric function_name resolution_cm
#> 1         Spectral      NDVI      d4h_ndvi             5
#> 2         Spectral       DVI       d4h_dvi             5
#> 3         Spectral      SAVI      d4h_savi             5
#> 4         Spectral    MSAVI2    d4h_msavi2             5
#> 5         Spectral      VARI      d4h_vari             5
#> 6         Spectral       EVI       d4h_evi             5
#> 7         Spectral      NDWI      d4h_ndwi             5
#> 8         Spectral      NDRE      d4h_ndre             5
#> 9         Spectral     GNDVI     d4h_gndvi             5
#> 10        Spectral      CTVI      d4h_ctvi             5
#> 11        Spectral Bare_Soil d4h_bare_soil             5
#> 12     Topographic     Slope     d4h_slope            10
#> 13     Topographic       TWI       d4h_twi            10
#> 14 Epidemiological      IMSR      d4h_imsr             5
#> 15 Epidemiological      IRTS      d4h_irts            10
#> 16 Epidemiological       IEV       d4h_iev            10
#> 17 Epidemiological       IEC       d4h_iec            10
#> 18 Epidemiological      IEAD      d4h_iead            10
#> 19 Epidemiological      IRHE      d4h_irhe            10
#> 20 Epidemiological      IFEB      d4h_ifeb            10
#> 21 Epidemiological      IRIH      d4h_irih            10
#>                                              formula
#> 1                          (NIR - Red) / (NIR + Red)
#> 2                                          NIR - Red
#> 3          ((NIR - Red) / (NIR + Red + L)) * (1 + L)
#> 4  (2*NIR + 1 - sqrt((2*NIR+1)^2 - 8*(NIR-Red))) / 2
#> 5         (Green - Red) / (Green + Red - Blue + eps)
#> 6   G * ((NIR - Red) / (NIR + C1*Red - C2*Blue + L))
#> 7                      (Green - NIR) / (Green + NIR)
#> 8                  (NIR - RedEdge) / (NIR + RedEdge)
#> 9                      (NIR - Green) / (NIR + Green)
#> 10              (NDVI + 0.5) / sqrt(abs(NDVI + 0.5))
#> 11                      ifel(NDVI < threshold, 1, 0)
#> 12               arctan(sqrt((dz/dx)^2 + (dz/dy)^2))
#> 13           ln((flow_acc + 1) / (tan(slope) + eps))
#> 14              |NDRE_approx - theta_veg| * NIR_norm
#> 15     (NDRE * (LST_surr - LST_local)) / (NIR + eps)
#> 16                        NDWI * (1 / (Slope + eps))
#> 17       GNDVI_water * (1 - (|LST - T_opt| / T_opt))
#> 18          grad(delta_NDVI) * Depressions * RedEdge
#> 19                          NDWI * (1 / (LST + eps))
#> 20             |grad(RedEdge)| * (Red / (NIR + eps))
#> 21        Var(RedEdge / NIR) * (Red / (Green + eps))
#>                                                         application
#> 1                  Vegetation vigor, biomass density & canopy cover
#> 2                Linear canopy biomass & leaf area index variations
#> 3        Soil-adjusted vegetation index for sparse canopies (L=0.5)
#> 4         Self-adjusting vegetation index for arid & degraded soils
#> 5       RGB-only visible atmospherically resistant vegetation index
#> 6               Enhanced vegetation index for high-biomass canopies
#> 7       Open surface water bodies & localized moisture accumulation
#> 8  Chlorophyll content in dense vegetation avoiding NDVI saturation
#> 9           Photosynthetic activity & micro-algae in standing water
#> 10      Corrected transformed vegetation index normalizing skewness
#> 11                    Binary mask of bare, exposed or degraded soil
#> 12      Micro-terrain slope derived from DSM/DEM in degrees/radians
#> 13           Topographic wetness index & micro-pooling accumulation
#> 14  Solid waste, plastics & artificial Aedes aegypti breeding sites
#> 15   Thermal refuge & cool shaded resting microhabitats for vectors
#> 16          Vulnerability to water stagnation & larval colonization
#> 17       Larval incubation & thermal stratification in water bodies
#> 18     Water pooling in cleared, excavated & deforested micro-zones
#> 19      Persistent cold water retention & dry-season vector refugia
#> 20           Forest-edge ecotone borders & ecological fragmentation
#> 21         Canopy structural roughness in forest-dwelling interface

# Filter only eco-epidemiological indices
epi_metrics <- d4h_list_metrics(category = "Epidemiological")
print(epi_metrics)
#>           category metric function_name resolution_cm
#> 14 Epidemiological   IMSR      d4h_imsr             5
#> 15 Epidemiological   IRTS      d4h_irts            10
#> 16 Epidemiological    IEV       d4h_iev            10
#> 17 Epidemiological    IEC       d4h_iec            10
#> 18 Epidemiological   IEAD      d4h_iead            10
#> 19 Epidemiological   IRHE      d4h_irhe            10
#> 20 Epidemiological   IFEB      d4h_ifeb            10
#> 21 Epidemiological   IRIH      d4h_irih            10
#>                                          formula
#> 14          |NDRE_approx - theta_veg| * NIR_norm
#> 15 (NDRE * (LST_surr - LST_local)) / (NIR + eps)
#> 16                    NDWI * (1 / (Slope + eps))
#> 17   GNDVI_water * (1 - (|LST - T_opt| / T_opt))
#> 18      grad(delta_NDVI) * Depressions * RedEdge
#> 19                      NDWI * (1 / (LST + eps))
#> 20         |grad(RedEdge)| * (Red / (NIR + eps))
#> 21    Var(RedEdge / NIR) * (Red / (Green + eps))
#>                                                        application
#> 14 Solid waste, plastics & artificial Aedes aegypti breeding sites
#> 15  Thermal refuge & cool shaded resting microhabitats for vectors
#> 16         Vulnerability to water stagnation & larval colonization
#> 17      Larval incubation & thermal stratification in water bodies
#> 18    Water pooling in cleared, excavated & deforested micro-zones
#> 19     Persistent cold water retention & dry-season vector refugia
#> 20          Forest-edge ecotone borders & ecological fragmentation
#> 21        Canopy structural roughness in forest-dwelling interface
```
