# Breeding Site Stratification Index (IEC)

Evaluates open water bodies weighted by optimal thermal ranges for
larval development.

## Usage

``` r
d4h_iec(gndvi_water, lst, t_opt = 25)
```

## Arguments

- gndvi_water:

  SpatRaster or character. GNDVI layer masked to water bodies or path to
  file.

- lst:

  SpatRaster or character. Land Surface Temperature layer in Celsius or
  path to file.

- t_opt:

  Numeric. Optimal incubation temperature in degrees Celsius (default:
  25).

## Value

A SpatRaster stratifying larval breeding site quality with background
masked to `NA`.

## Details

The Canopy Exposure & Thermal Incubation Index is defined as:
\$\$\text{IEC} = \text{GNDVI}\_{\text{water}} \times \left(1 -
\frac{\|\text{LST} - T\_{\text{opt}}\|}{T\_{\text{opt}}}\right)\$\$
where \\T\_{\text{opt}}\\ is the optimal incubation temperature
(default: \\T\_{\text{opt}} = 25^\circ\text{C}\\).

## References

Mordecai, E. A., Cohen, J. M., Evans, M. V., Gudapati, P., Johnson, L.
R., Lippi, C. A., ... & Rohr, J. R. (2017). Detecting the impact of
temperature on transmission of Zika, dengue, and chikungunya using
mechanistic models. *PLOS Neglected Tropical Diseases*, 11(4), e0005568.
[doi:10.1371/journal.pntd.0005568](https://doi.org/10.1371/journal.pntd.0005568)

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  nir_file   <- system.file("extdata", "nir.tif", package = "drones4health")
  green_file <- system.file("extdata", "green.tif", package = "drones4health")
  lst_file   <- system.file("extdata", "lst.tif", package = "drones4health")

  r_gndvi <- d4h_gndvi(nir = nir_file, green = green_file)

  # Run IEC calculation with T_opt = 25 C
  r_iec <- d4h_iec(gndvi_water = r_gndvi, lst = lst_file, t_opt = 25)
  head(r_iec)
}
# }
```
