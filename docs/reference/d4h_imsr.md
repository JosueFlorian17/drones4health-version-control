# Synthetic Materials Risk Index (IMSR)

Detects non-natural solid waste materials (plastics, discarded tires,
tarps, and artificial containers) that serve as potential *Aedes
aegypti* oviposition and larval habitats.

## Usage

``` r
d4h_imsr(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001)
```

## Arguments

- red_edge:

  SpatRaster or character. Red Edge band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- veg_threshold:

  Numeric. Threshold to differentiate vegetation from synthetics
  (default: 0.2).

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster containing IMSR values in `[0, 1]` with background masked
to `NA`.

## Details

The Index of Micro-accumulation of Solid Waste (IMSR) evaluates spectral
deviations in the Red Edge - Red transition weighted by Near-Infrared
reflectance: \$\$\text{NDRE}\_{\text{approx}} = \frac{\text{RedEdge} -
\text{Red}}{\text{RedEdge} + \text{Red} + \epsilon}\$\$ \$\$\text{IMSR}
= \|\text{NDRE}\_{\text{approx}} - \theta\_{\text{veg}}\| \times
\text{NIR}\_{\text{norm}}\$\$ where \\\theta\_{\text{veg}}\\ is a
threshold separating natural vegetation from synthetic polymer surfaces.
Output values are clamped between 0 and 1.

## References

World Health Organization. (2020). *Comprehensive guidelines for
prevention and control of dengue and dengue haemorrhagic fever*. WHO
Regional Office for South-East Asia.

Fornace, K. M., Drakeley, C. J., William, T., Espino, F., & Cox, J.
(2014). Mapping infectious disease landscapes: unmanned aerial vehicles
and epidemiology. *Trends in Parasitology*, 30(11), 514-519.
[doi:10.1016/j.pt.2014.09.001](https://doi.org/10.1016/j.pt.2014.09.001)

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  re_file  <- system.file("extdata", "rededge.tif", package = "drones4health")
  red_file <- system.file("extdata", "red.tif", package = "drones4health")
  nir_file <- system.file("extdata", "nir.tif", package = "drones4health")

  # Run IMSR calculation for solid waste / plastics with explicit thresholds
  r_imsr <- d4h_imsr(
    red_edge      = re_file,
    red           = red_file,
    nir           = nir_file,
    veg_threshold = 0.2,
    eps           = 0.001
  )
  head(r_imsr)
}
# }
```
