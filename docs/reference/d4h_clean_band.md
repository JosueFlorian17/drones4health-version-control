# Clean Raster Band Artefacts

Replaces NaN and Infinite values with NA and clamps the raster to
physically valid limits.

## Usage

``` r
d4h_clean_band(raster_layer, min_val = -1, max_val = 1)
```

## Arguments

- raster_layer:

  SpatRaster. Input band to clean.

- min_val:

  Numeric. Minimum valid value (default: -1).

- max_val:

  Numeric. Maximum valid value (default: 1).

## Value

A cleaned SpatRaster.
