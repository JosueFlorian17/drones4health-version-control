# Generate Hexagonal Surveillance Grid

Creates an operative hexagonal surveillance grid with unique
alphanumeric identifiers over an Area of Interest (AOI).

## Usage

``` r
d4h_hex_grid(aoi, cell_size = 50)
```

## Arguments

- aoi:

  SpatRaster, SpatVector, sf, or character path defining the spatial
  bounds.

- cell_size:

  Numeric. Hexagon diameter in meters (default: 50).

## Value

A SpatVector containing the hexagonal grid polygons with unique IDs.

## Details

Hexagonal spatial partitions minimize perimeter-to-area ratio and
provide equidistant neighborhood connectivity: \$\$A\_{\text{hex}} =
\frac{3\sqrt{3}}{2} r^2\$\$ Ideal for vector control teams, larviciding
deployments, and spatial health sampling.

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

  # Create hexagonal grid cells with 50-meter diameter
  hex_grid <- d4h_hex_grid(aoi = aoi_file, cell_size = 50)
  plot(hex_grid)
}
# }
```
