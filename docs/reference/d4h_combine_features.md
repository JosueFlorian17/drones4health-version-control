# Combine and Summarize Physical Water and Building Features

Merges segmented water bodies and residential building footprints into a
harmonized spatial feature collection, calculating overall counts, total
surface areas, and printing an executive summary report.

## Usage

``` r
d4h_combine_features(
  water = NULL,
  buildings = NULL,
  houses = NULL,
  quiet = FALSE
)

d4h_add_features(water = NULL, buildings = NULL, houses = NULL, quiet = FALSE)
```

## Arguments

- water:

  `sf`, `SpatVector`, or character path. Segmented water body polygons
  (e.g. from `d4h_segment_water`).

- buildings:

  `sf`, `SpatVector`, or character path. Segmented dwelling/building
  footprints (e.g. from `d4h_segment_buildings`).

- houses:

  Deprecated alias for `buildings`.

- quiet:

  Logical. If TRUE, suppresses console summary printing (default:
  FALSE).

## Value

An `sf` object of class `c("d4h_features", "sf", "data.frame")`
containing the combined features with attributes `feature_id`,
`feature_type`, `area_m2`, and a detailed summary attribute.

## Details

Combines vector outputs from
[`d4h_segment_water`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_water.md)
and
[`d4h_segment_buildings`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_segment_buildings.md)
into an unified `sf` object with columns `feature_id`, `feature_type`
(`"Water"` or `"Building"`), and `area_m2`. The returned object can be
passed directly to
[`d4h_plot`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_plot.md)
for overlay onto drone orthomosaics, or to
[`d4h_executive_summary`](https://josueflorian17.github.io/drones4health-version-control/reference/d4h_executive_summary.md)
for automatic zonal grid aggregation.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)

  # Combine segmented water and building layers
  features <- d4h_combine_features(
    water     = water_sf,
    buildings = buildings_sf
  )
  print(features)
}
# }
```
