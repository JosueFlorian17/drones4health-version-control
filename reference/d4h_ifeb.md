# Fragmentation and Edge Effect Index (IFEB)

Quantifies ecological transitions and ecotone borders between tree
canopies and urban or cleared soil substrates.

## Usage

``` r
d4h_ifeb(grad_red_edge, red, nir, eps = 0.001)
```

## Arguments

- grad_red_edge:

  SpatRaster or character. Focal standard deviation of Red Edge or path
  to file.

- red:

  SpatRaster or character. Red band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster quantifying edge effects with background masked to `NA`.

## Details

The Forest Edge & Environmental Barrier Index is formulated as:
\$\$\text{IFEB} = \|\nabla(\text{RedEdge})\| \times
\frac{\text{Red}}{\text{NIR} + \epsilon}\$\$

## References

Laurance, W. F., et al. (2011). The impact of forest fragmentation on
disease ecology. *Biological Conservation*, 144(1), 56-68.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  re_file  <- system.file("extdata", "rededge.tif", package = "drones4health")
  red_file <- system.file("extdata", "red.tif", package = "drones4health")
  nir_file <- system.file("extdata", "nir.tif", package = "drones4health")

  r_grad_re <- terra::terrain(terra::rast(re_file), v = "slope")

  # Run IFEB fragmentation and edge effect calculation
  r_ifeb <- d4h_ifeb(grad_red_edge = r_grad_re, red = red_file, nir = nir_file)
  head(r_ifeb)
}
# }
```
