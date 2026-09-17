# Clean Raster Band Artefacts

Replaces NaN and Infinite values with NA and clamps the raster to
physically valid limits.

## Usage

``` r
d4h_clean_band(raster_layer, min_val = -1, max_val = 1)
```

## Arguments

- raster_layer:

  SpatRaster. The input band to clean.

- min_val:

  Numeric. Minimum valid value.

- max_val:

  Numeric. Maximum valid value.

## Value

A cleaned SpatRaster.
