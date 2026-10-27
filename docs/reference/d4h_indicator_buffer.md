# Targeted Focal Indicator Analysis and Plotting around House Buffers

Drastically accelerates computational efficiency and saves memory by
cropping, calculating micro-environmental/epidemiological indicators,
and plotting exclusively within a defined buffer zone (measured in
grid-units or meters) around residential houses from a CSV or spatial
layer.

## Usage

``` r
d4h_indicator_buffer(
  indicator = "NDVI",
  houses,
  radius = 3,
  cell_size = 50,
  radius_in_meters = FALSE,
  nir = NULL,
  red = NULL,
  green = NULL,
  blue = NULL,
  red_edge = NULL,
  dem = NULL,
  lst = NULL,
  raster_in = NULL,
  square = TRUE,
  mask_outside = TRUE,
  house_color = "red",
  house_size = 2.5,
  palette = "viridis",
  limits = NULL,
  title = NULL,
  plot = TRUE
)
```

## Arguments

- indicator:

  Character or Function. Name of the index or function to compute.
  Supported character names: `"NDVI"`, `"NDWI"`, `"SAVI"`, `"DVI"`,
  `"GNDVI"`, `"NDRE"`, `"EVI"`, `"VARI"`, `"TVI"`, `"MSAVI2"`, `"IRHE"`,
  `"IMSR"`, `"IRTS"`, `"slope"`, `"twi"`, `"dsm"`, `"rgb"`.
  Alternatively, pass a custom function `function(...)` or a
  pre-calculated SpatRaster.

- houses:

  Character path, data.frame, SpatVector, or sf object containing house
  coordinates (e.g., CSV with lon/lat or x/y columns).

- radius:

  Numeric. Buffer radius surrounding each house. Defined in number of
  grid cells (default: 3). If `radius_in_meters = TRUE`, interpreted
  directly as meters.

- cell_size:

  Numeric. Grid cell size in meters used to establish grid scale and
  calculate buffer distances (default: 50).

- radius_in_meters:

  Logical. If FALSE (default), total buffer distance is
  `radius * cell_size`. If TRUE, total buffer distance is `radius`.

- nir:

  SpatRaster or character path. Near-Infrared band (optional, required
  for multispectral indices).

- red:

  SpatRaster or character path. Red band (optional).

- green:

  SpatRaster or character path. Green band (optional).

- blue:

  SpatRaster or character path. Blue band (optional).

- red_edge:

  SpatRaster or character path. Red Edge band (optional).

- dem:

  SpatRaster or character path. DEM / DSM raster (optional).

- lst:

  SpatRaster or character path. Land Surface Temperature raster
  (optional).

- raster_in:

  SpatRaster or character path (optional). Directly provides an already
  computed raster or pre-stacked imagery to crop and plot.

- square:

  Logical. If TRUE, creates square grid cells; if FALSE, hexagonal grid
  cells (default: TRUE).

- mask_outside:

  Logical. If TRUE (default), masks pixel values outside the house
  buffer polygons to NA. If FALSE, retains unmasked rectangular cropped
  extent.

- house_color:

  Character. Color for house points on the plot (default: "red").

- house_size:

  Numeric. Size for house points on the plot (default: 2.5).

- palette:

  Character. Color palette name ("viridis", "magma", "terrain",
  "spectral") or custom color vector (default: "viridis").

- limits:

  Numeric vector c(min, max) to fix color scale limits (default: NULL).

- title:

  Character. Custom plot title (optional).

- plot:

  Logical. If TRUE (default), returns a list with the raster, grid
  summary, and ggplot. If FALSE, skips rendering.

## Value

A list containing:

- `raster`: The targeted cropped SpatRaster of the computed indicator.

- `houses`: An `sf` object of the houses intersecting the scene.

- `buffer`: An `sf` polygon of the focal buffer envelope.

- `grid`: An `sf` / `SpatVector` zonal grid summary within the buffer
  zone.

- `plot`: A `ggplot` object visualizing the buffer zone, raster
  indicator, and house points (if `plot = TRUE`).

## Details

In ultra-high resolution drone mapping (100M+ pixels), calculating
continuous indices over the entire scene consumes unnecessary
computational resources. `d4h_indicator_buffer` creates an operational
envelope around houses: \$\$\text{Buffer Distance} = R \times
\text{cell\\size}\$\$ It crops the raw band inputs strictly to the
bounding box of intersecting buffer zones, masks non-focal areas,
computes the specified spectral/terrain/epidemiological index, extracts
grid summaries, and produces an publication-ready ggplot visualization
with house points overlaid.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)
  library(sf)

  # Define paths to bands and house locations
  nir_path   <- system.file("extdata", "nir.tif", package = "drones4health")
  red_path   <- system.file("extdata", "red.tif", package = "drones4health")
  houses_csv <- system.file("extdata", "houses.csv", package = "drones4health")

  # Run focal buffer analysis around houses with full parameterization
  res_buffer <- d4h_indicator_buffer(
    indicator        = "NDVI",
    houses           = houses_csv,
    radius           = 3,
    cell_size        = 50,
    radius_in_meters = FALSE,
    nir              = nir_path,
    red              = red_path,
    square           = FALSE,
    mask_outside     = TRUE,
    house_color      = "red",
    house_size       = 2.5,
    palette          = "viridis",
    limits           = c(0.1, 0.9),
    title            = "Focal Household Buffer (150m) - NDVI Analysis",
    plot             = TRUE
  )
  head(res_buffer$grid)
}
# }
```
