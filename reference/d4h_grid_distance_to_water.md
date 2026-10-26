# Spatial Grid Proximity and Exposure Modeling to Water Bodies

Computes the minimum Euclidean distance from each operational grid cell
(square or hexagonal) to the nearest water body or aquatic habitat,
calculates exponential proximity exposure scores in 0, 1, and stratifies
grid units into operational priority tiers.

## Usage

``` r
d4h_grid_distance_to_water(
  grid,
  water_bodies,
  decay_lambda = 100,
  buffer_breaks = c(50, 100, 200),
  proximity_labels = c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)",
    "Low (>200m)")
)
```

## Arguments

- grid:

  SpatVector, sf, or character path. Operational surveillance grid (e.g.
  generated via `d4h_hex_grid` or `d4h_summarize_grid`).

- water_bodies:

  SpatVector, sf, or character path. Water polygons or aquatic vector
  features.

- decay_lambda:

  Numeric. Exponential decay half-distance parameter in meters (default:
  100.0).

- buffer_breaks:

  Numeric vector. Distance cutoffs in meters for stratified tiers
  (default: `c(50, 100, 200)`).

- proximity_labels:

  Character vector. Names for each stratified priority tier (default:
  `c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)", "Low (>200m)")`).

## Value

An `sf` object containing the grid cells with appended columns:
`dist_water_m`, `nearest_water_id`, `proximity_score`, and
`proximity_level`.

## Details

Evaluates spatial exposure at the operational territorial level:
\$\$\text{Proximity Score} =
\exp\left(-\frac{\text{Distance}}{\lambda}\right)\$\$ Grid cells
directly intersecting or located in close proximity to standing water
bodies receive high priority scores (\\\to 1.0\\), enabling health
brigades to prioritize interventions by territorial sectors rather than
individual dwellings alone.

## References

World Health Organization. (2020). *Operational framework for building
climate resilient health systems*. World Health Organization.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)
  library(sf)

  # Generate surveillance grid and load water features
  ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
  grid_hex  <- d4h_hex_grid(ndvi_file, cell_size = 50)
  water_sf  <- st_read(system.file("extdata", "water_bodies.gpkg", package = "drones4health"))

  # Score grid units by proximity to water
  grid_scored <- d4h_grid_distance_to_water(
    grid         = grid_hex,
    water_bodies = water_sf,
    decay_lambda = 100.0
  )
  head(grid_scored)
}
# }
```
