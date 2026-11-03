# Generate Hexagonal Surveillance Grid

Creates an operative hexagonal surveillance grid with unique
alphanumeric identifiers over an Area of Interest (AOI). Sizing can be
strictly configured using exactly one of three mutually exclusive
parameters: `cell_size` (diameter in meters), `area_m2` (individual cell
area in square meters), or `n_cells` (target total number of cells over
the AOI).

## Usage

``` r
d4h_hex_grid(
  aoi,
  cell_size = NULL,
  area_m2 = NULL,
  n_cells = NULL,
  clip_to_footprint = TRUE,
  as_sf = TRUE
)
```

## Arguments

- aoi:

  SpatRaster, SpatVector, sf, or character path defining the spatial
  bounds or mosaic.

- cell_size:

  Numeric (optional). Hexagon diameter in meters (default: 50 if all
  size options are NULL).

- area_m2:

  Numeric (optional). Target cell area in square meters.

- n_cells:

  Numeric / Integer (optional). Desired total number of grid cells
  across the AOI.

- clip_to_footprint:

  Logical. If TRUE (default), restricts grid cells strictly to the valid
  non-NA flight footprint of the input raster or polygon boundaries.

- as_sf:

  Logical. If TRUE (default), returns an `sf` object; if FALSE, returns
  a
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html).

## Value

An `sf` or `SpatVector` containing the hexagonal grid polygons with
unique IDs (`grid_id`).

## Details

Hexagonal spatial partitions minimize perimeter-to-area ratio and
provide equidistant neighborhood connectivity: \$\$A\_{\text{hex}} =
\frac{\sqrt{3}}{2} D^2 \approx 0.866 \times D^2\$\$ Ideal for vector
control teams, larviciding deployments, and spatial health sampling. By
default, cells are clipped strictly to the valid non-NA flight footprint
of the raster or polygon boundaries (`clip_to_footprint = TRUE`) to
prevent artificial bounding-box grid padding outside the surveyed area.

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

  # Define Area of Interest raster
  aoi_file <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")

  # Create hexagonal grid cells with 50-meter diameter clipped to flight footprint
  hex_grid <- d4h_hex_grid(aoi = aoi_file, cell_size = 50, clip_to_footprint = TRUE)
  plot(hex_grid)
}
# }
```
