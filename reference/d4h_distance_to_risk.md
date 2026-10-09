# Calculate Distance and Vulnerability Risk to Water Sources

Computes the minimum Euclidean distance from each residential building
to the nearest aquatic vector breeding site, calculates an exponential
infection exposure risk score, and stratifies epidemiological
vulnerability levels.

## Usage

``` r
d4h_distance_to_risk(
  buildings,
  sources,
  decay_lambda = 100,
  buffer_breaks = c(50, 100, 200),
  risk_labels = c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)",
    "Bajo (>200m)")
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

## Value

An `sf` object matching `buildings` with appended columns:
`dist_water_m`, `nearest_water_id`, `risk_score` in `[0, 1]`, and
`risk_level`.

## Details

The distance-decay transmission risk score is formulated based on vector
flight dispersion models: \$\$\text{RiskScore}\_i =
\exp\left(-\frac{d\_{\text{min}}(i)}{\lambda}\right)\$\$ where
\\d\_{\text{min}}(i)\\ is the minimum Euclidean distance (in meters)
from building centroid \\i\\ to the closest water polygon, and
\\\lambda\\ is the characteristic dispersal radius of disease vectors
(e.g. \\\lambda = 100\text{ m}\\ for *Aedes aegypti* / *Anopheles*).

## References

World Health Organization. (2020). *Operational framework for building
climate resilient health systems*. World Health Organization.

Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global
extent of malaria in 2005. *Trends in Parasitology*, 22(8), 353-358.
[doi:10.1016/j.pt.2006.06.006](https://doi.org/10.1016/j.pt.2006.06.006)
