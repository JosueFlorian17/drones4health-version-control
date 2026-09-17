# Continuous Normalized Difference Vegetation Index (General Area)

Computes continuous NDVI for the entire survey extent without grid
aggregation.

## Usage

``` r
d4h_ndvi_general(nir, red, scale = NULL)
```

## Arguments

- nir:

  Character or SpatRaster. Near-infrared band or path to file.

- red:

  Character or SpatRaster. Red band or path to file.

- scale:

  Numeric. Divisor to normalize pixel values to 0-1 (default:
  auto-detected or 65535).

## Value

A SpatRaster containing continuous NDVI values bounded in -1, 1.
