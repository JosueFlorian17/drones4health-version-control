# Bare Soil Mask

Generates a binary mask of bare, exposed, or degraded soil based on an
NDVI threshold.

## Usage

``` r
d4h_bare_soil(ndvi_raster, threshold = 0.15)
```

## Arguments

- ndvi_raster:

  SpatRaster or character. Input NDVI layer or path to file.

- threshold:

  Numeric. Value below which pixels are classified as bare soil
  (default: 0.15).

## Value

A binary SpatRaster (1 = bare soil, 0 = vegetation/water) with
background masked to `NA`.

## Details

The Bare Soil Mask is computed as a binary classification:
\$\$\text{BareSoilMask} = \begin{cases} 1 & \text{if } \text{NDVI} \<
\theta \\ 0 & \text{otherwise} \end{cases}\$\$ where \\\theta\\ is an
empirical threshold (default: \\\theta = 0.15\\).

## References

Montandon, L. M., & Small, E. E. (2008). The impact of soil reflectance
on the quantification of green vegetation fraction in arid and semi-arid
environments. *Remote Sensing of Environment*, 112(2), 635-645.
[doi:10.1016/j.rse.2007.05.016](https://doi.org/10.1016/j.rse.2007.05.016)

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  nir_file <- system.file("extdata", "nir.tif", package = "drones4health")
  red_file <- system.file("extdata", "red.tif", package = "drones4health")
  r_ndvi   <- d4h_ndvi(nir = nir_file, red = red_file)

  # Run Bare Soil mask classification
  r_soil <- d4h_bare_soil(ndvi_raster = r_ndvi, threshold = 0.15)
  head(r_soil)
}
# }
```
