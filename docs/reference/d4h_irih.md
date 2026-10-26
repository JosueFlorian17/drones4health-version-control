# Human Interface Roughness Index (IRIH)

Measures canopy structural heterogeneity in the forest-household ecotone
interface to model vector flight pathways and peridomestic contact.

## Usage

``` r
d4h_irih(var_re_nir, red, green, eps = 0.001)
```

## Arguments

- var_re_nir:

  SpatRaster or character. Local variance of RE/NIR ratio or path to
  file.

- red:

  SpatRaster or character. Red band or path to file.

- green:

  SpatRaster or character. Green band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing structural roughness with background masked to
`NA`.

## Details

The Index of Human Infection Risk / Roughness is calculated as:
\$\$\text{IRIH} =
\text{Var}\left(\frac{\text{RedEdge}}{\text{NIR}}\right) \times
\frac{\text{Red}}{\text{Green} + \epsilon}\$\$

## References

Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global
extent of malaria in 2005. *Trends in Parasitology*, 22(8), 353-358.
[doi:10.1016/j.pt.2006.06.006](https://doi.org/10.1016/j.pt.2006.06.006)

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  re_file    <- system.file("extdata", "rededge.tif", package = "drones4health")
  nir_file   <- system.file("extdata", "nir.tif", package = "drones4health")
  red_file   <- system.file("extdata", "red.tif", package = "drones4health")
  green_file <- system.file("extdata", "green.tif", package = "drones4health")

  r_ratio <- terra::rast(re_file) / (terra::rast(nir_file) + 0.001)
  r_var   <- terra::focal(r_ratio, w = 5, fun = "var", na.rm = TRUE)

  # Run IRIH human interface roughness calculation
  r_irih <- d4h_irih(var_re_nir = r_var, red = red_file, green = green_file)
  head(r_irih)
}
# }
```
