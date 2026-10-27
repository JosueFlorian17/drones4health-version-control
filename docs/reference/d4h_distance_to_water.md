# Calculate Distance and Proximity to Water Sources

Computes the minimum Euclidean distance from each residential building
to the nearest water body or aquatic site.

## Usage

``` r
d4h_distance_to_water(
  buildings,
  sources,
  decay_lambda = 100,
  buffer_breaks = c(50, 100, 200),
  risk_labels = c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)",
    "Bajo (>200m)"),
  proximity_labels = NULL
)
```

## Arguments

- buildings:

  `sf` POLYGON or POINT object representing houses or human settlements.

- sources:

  `sf` POLYGON or POINT object representing water bodies, puddles, or
  waste accumulation sites.

- decay_lambda:

  Numeric. Flight dispersal decay parameter in meters (default: 100.0).

- buffer_breaks:

  Numeric vector. Distance cutoffs in meters for risk tier
  stratification (default: `c(50, 100, 200)`).

- risk_labels:

  Character vector. Names for each stratified risk tier (default:
  `c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)", "Bajo (>200m)")`).

- proximity_labels:

  Character vector (optional). Custom names for each stratified
  proximity tier (alternative to `risk_labels`).

## Value

An `sf` object with distance to water, nearest water ID, and proximity
score columns.
