# drones4health: Ultra-High Resolution Drone Metrics for Spatial Health Analysis

**`drones4health`** is an R package designed to extract, analyze, and
synthesize ultra-high resolution (centimeter-level) remote sensing
indicators from Unmanned Aerial Vehicle (UAV) orthomosaics within a
**One Health** framework. It bridges micro-environmental landscape
ecology with spatial epidemiology for precision vector control,
environmental health surveillance, and localized pathogen transmission
risk modeling.

------------------------------------------------------------------------

## 1. Installation

You can install the development version of `drones4health` directly from
GitHub:

``` r

# If not yet installed: install.packages("pak")
pak::pak("JosueFlorian17/drones4health-version-control")
```

Or using `remotes` / `devtools`:

``` r

# install.packages("remotes")
remotes::install_github("JosueFlorian17/drones4health-version-control")
```

``` r

library(drones4health)
library(terra)
library(sf)
```

------------------------------------------------------------------------

## 2. Core Functional Modules & Use Cases

`drones4health` provides 7 modular indicator suites tailored for spatial
epidemiology and field operations:

- **Spectral Vegetation & Canopy Indices:** Quantify photosynthetic
  vigor, biomass density, and canopy chlorophyll (e.g.,
  [`d4h_ndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndvi.md),
  [`d4h_msavi2()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_msavi2.md),
  [`d4h_savi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_savi.md),
  [`d4h_ndre()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndre.md),
  [`d4h_gndvi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_gndvi.md),
  [`d4h_vari()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_vari.md),
  [`d4h_evi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_evi.md)).
  Used to map vegetative shading and canopy roosting habitats for adult
  mosquito vectors.
- **Land Cover & Substrate Masks:** Classify discrete land surface
  substrates such as bare soil
  ([`d4h_bare_soil()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_bare_soil.md))
  to delineate unpaved roads, exposed earth, and peridomestic clearing
  boundaries.
- **Hydrological & Micro-Pooling Detection:** Identify open water
  surfaces, irrigation trenches, and standing moisture pools
  ([`d4h_ndwi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ndwi.md))
  that provide aquatic breeding habitats.
- **Micro-Topography & Terrain Wetness:** Model terrain slope
  ([`d4h_slope()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_slope.md))
  and topographic wetness accumulation
  ([`d4h_twi()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_twi.md))
  from UAV Digital Elevation Models (DEM/DSM) to pinpoint natural
  drainage sinks and runoff depressions.
- **Eco-Epidemiological Risk Modeling:** Synthesize multi-band metrics
  to locate solid waste micro-accumulations
  ([`d4h_imsr()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_imsr.md)),
  hydric stagnation risk
  ([`d4h_irhe()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irhe.md),
  [`d4h_iev()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_iev.md)),
  thermal micro-climate refuges
  ([`d4h_irts()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irts.md)),
  and human-forest ecotone interfaces
  ([`d4h_irih()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_irih.md),
  [`d4h_ifeb()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_ifeb.md)).
- **Spatial Zonation & Surveillance Grids:** Tessellate the flight
  footprint into operational hexagonal grids
  ([`d4h_hex_grid()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_hex_grid.md))
  and compute zonal summaries
  ([`d4h_summarize_grid()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_summarize_grid.md))
  for community health teams and larviciding logistics.
- **Executive Reporting & Excel Export:** Generate multi-moment
  descriptive statistics, spatial surface coverage in hectares, and
  Tukey outlier diagnostics with automated multi-sheet Excel workbook
  export
  ([`d4h_executive_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md),
  [`d4h_export_summary()`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_export_summary.md)).

*(For full mathematical formulations and derivations, see the individual
function pages under the
[Reference](https://JosueFlorian17.github.io/drones4health-version-control/reference/index.html)
tab).*

------------------------------------------------------------------------

## 3. Practical Workflow: From Raw Orthomosaics to Risk Metrics

All indicator functions accept
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects or direct file paths, automatically handle spatial
co-registration, and mask background NoData to `NA`:

``` r

library(drones4health)
library(terra)

# 1. Define paths to UAV multispectral and elevation bands
path_nir <- "data/Ohuay_NIR.tif"
path_r   <- "data/Ohuay_R.tif"
path_re  <- "data/Ohuay_RE.tif"
path_dem <- "data/Ohuay_D.tif"

# 2. Compute vegetation indices and discrete soil substrate masks
r_ndvi      <- d4h_ndvi(nir = path_nir, red = path_r)
r_msavi2    <- d4h_msavi2(nir = path_nir, red = path_r)
r_bare_soil <- d4h_bare_soil(ndvi_raster = r_ndvi, threshold = 0.15)

# 3. Compute micro-terrain slope and topographic wetness
r_slope     <- d4h_slope(dem_raster = path_dem, unit = "degrees")
r_twi       <- d4h_twi(dem_raster = path_dem)

# 4. Extract artificial waste micro-accumulation risk (IMSR)
r_imsr      <- d4h_imsr(red_edge = path_re, red = path_r, nir = path_nir)
```

------------------------------------------------------------------------

## 4. Surveillance Zonation & Hexagonal Grids

Partition high-resolution flight footprints into operational units
(e.g., 25m or 50m diameter hexagons) for targeted vector intervention:

``` r

# Generate 50m surveillance hexagonal grid
grid_hex <- d4h_hex_grid(aoi = r_ndvi, cell_size = 50)

# Compute zonal statistics per operational hexagon
grid_summary <- d4h_summarize_grid(
  raster_in = r_ndvi,
  cell_size = 50,
  square    = FALSE
)
```

------------------------------------------------------------------------

## 5. Executive Reporting & Multi-Sheet Excel Export

Generate statistical moments, spatial extent in hectares, Tukey outlier
fences, and domain-specific thematic stratum distributions exported
directly into structured `.xlsx` workbooks:

``` r

# Multi-band executive report with direct Excel export
resumen_ejecutivo <- d4h_executive_summary(
  raster_in = c(r_ndvi, r_msavi2, r_imsr),
  out_xlsx  = "salidas/Resumen_Ejecutivo_Drones.xlsx"
)

# Print executive summary to console
print(resumen_ejecutivo)
```

------------------------------------------------------------------------

## 6. Visualization & Interactive Mapping

`drones4health` provides both static publication-ready cartography via
`ggplot2` and interactive Leaflet side-by-side swipe comparison viewers
(`d4h_mapview_swipe`).

### A. Interactive Side-by-Side Swipe Viewer

Compare continuous indices, discrete binary masks, and hexagonal grids
with a single slider bar and dynamic contrast stretching:

``` r

# Highlight bare soil pixels (value 1) as teal over MSAVI2 in magma palette
r_solo_suelo <- terra::ifel(r_bare_soil == 1, 1, NA)
names(r_solo_suelo) <- "Bare_Soil"

visor_swipe <- d4h_mapview_swipe(
  x        = r_solo_suelo,
  y        = r_msavi2,
  grid     = NULL,                      # Optional: pass grid_hex to overlay polygons
  basemap  = FALSE,                     # FALSE = neutral / TRUE = satellite imagery
  col_x    = "#2a9d8f",                 # Teal discrete color for bare soil
  col_y    = "magma",                   # Magma continuous palette for MSAVI2
  limits_y = c(0, 0.8)                  # Dynamic contrast range
)

visor_swipe
```

#### Visual Outputs:

![Interactive Swipe Viewer - Bare Soil vs
MSAVI2](reference/figures/swipe_bare_soil_msavi2.png)  
*Figure 1: Interactive side-by-side swipe comparison between Discrete
Bare Soil Mask (teal, left) and MSAVI2 (magma, right) with categorical
and continuous legends.*

![Hexagonal Grid Surveillance
Overlay](reference/figures/swipe_hex_grid.png)  
*Figure 2: Operative hexagonal surveillance grid (50 m) overlaid on the
swipe viewer.*

### B. Static Cartographic Mapping with `ggplot2`

``` r

# Continuous index plot with transparent background
d4h_plot(r_ndvi, palette = "viridis", title = "NDVI Vegetation Vigor")

# Zonal grid map
d4h_plot(grid_summary, palette = "magma", title = "Hexagonal Surveillance Grid (50m)")
```

------------------------------------------------------------------------

## 7. References

1.  **Beven, K. J., & Kirkby, M. J.** (1979). A physically based,
    variable contributing area model of basin hydrology. *Hydrological
    Sciences Bulletin*, 24(1), 43-69.
2.  **Fornace, K. M., et al.** (2014). Mapping infectious disease
    landscapes: unmanned aerial vehicles and epidemiology. *Trends in
    Parasitology*, 30(11), 514-519.
3.  **Huete, A. R.** (1988). A soil-adjusted vegetation index (SAVI).
    *Remote Sensing of Environment*, 25(3), 295-309.
4.  **Qi, J., et al.** (1994). A modified soil adjusted vegetation
    index. *Remote Sensing of Environment*, 48(2), 119-126.
5.  **Rouse, J. W., et al.** (1974). Monitoring vegetation systems in
    the Great Plains with ERTS. *NASA Special Publication*, 351,
    309-317.
6.  **World Health Organization.** (2020). *Operational framework for
    building climate resilient health systems*. WHO.
