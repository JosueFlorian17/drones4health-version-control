# Generate Operational Spatial Surveillance Grid (Square or Hexagonal)

Creates an operational spatial surveillance grid with unique
alphanumeric identifiers over an Area of Interest (AOI). Sizing can be
strictly configured using exactly one of three mutually exclusive
parameters: `cell_size` (diameter/width in meters), `area_m2`
(individual cell area in square meters), or `n_cells` (target total
number of cells over the AOI).

## Usage

``` r
d4h_make_grid(
  aoi,
  cell_size = NULL,
  area_m2 = NULL,
  n_cells = NULL,
  square = FALSE,
  clip_to_footprint = TRUE,
  as_sf = TRUE
)
```

## Arguments

- aoi:

  SpatRaster, SpatVector, sf, or character path defining the spatial
  bounds or mosaic.

- cell_size:

  Numeric (optional). Cell size / diameter in meters (e.g. 50).

- area_m2:

  Numeric (optional). Target cell area in square meters (e.g. 2500 for a
  50x50m equivalent cell).

- n_cells:

  Numeric / Integer (optional). Desired total number of grid cells
  distributed across the AOI footprint.

- square:

  Logical. If TRUE, creates square cells; if FALSE, creates regular
  hexagonal cells (default: FALSE).

- clip_to_footprint:

  Logical. If TRUE (default), restricts grid cells strictly to the valid
  non-NA flight footprint of the input raster or polygon boundaries.

- as_sf:

  Logical. If TRUE (default), returns an `sf` object; if FALSE, returns
  a
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html).

## Value

An `sf` or `SpatVector` containing the grid polygons with unique IDs
(`grid_id`) and individual cell area (`area_m2`).

## Details

Hexagonal spatial partitions minimize perimeter-to-area ratio and
provide equidistant neighborhood connectivity: \$\$A\_{\text{hex}} =
\frac{\sqrt{3}}{2} D^2 \approx 0.866 \times D^2\$\$ where \\D\\ is the
flat-to-flat diameter (`cell_size`). Square partitions use
\\A\_{\text{sq}} = D^2\\. By default, cells are clipped strictly to the
valid non-NA flight footprint of the raster or polygon boundaries
(`clip_to_footprint = TRUE`) to prevent artificial bounding-box grid
padding outside the surveyed area.

## References

Carr, D. B., Olsen, A. R., & White, D. (1992). Hexagon mosaic maps for
display of univariate and bivariate data. *Cartography and Geographic
Information Systems*, 19(4), 228-236.
[doi:10.1559/152304092783721231](https://doi.org/10.1559/152304092783721231)

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  aoi_file <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")

  # Option 1: By diameter/cell_size (50 meters)
  grid1 <- d4h_make_grid(aoi = aoi_file, cell_size = 50, square = FALSE)

  # Option 2: By target cell area (2,500 m2 per cell)
  grid2 <- d4h_make_grid(aoi = aoi_file, area_m2 = 2500, square = FALSE)

  # Option 3: By desired total number of cells (~100 cells)
  grid3 <- d4h_make_grid(aoi = aoi_file, n_cells = 100, square = FALSE)
}
# }
```
