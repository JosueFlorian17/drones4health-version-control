# Clean Raster Band Artefacts

Replaces non-finite and zero values with NA and clamps the raster to
valid bio-physical limits.

## Usage

``` r
d4h_clean_band(raster_layer, min_val = -1, max_val = 1)
```

## Arguments

- raster_layer:

  SpatRaster or character. Input band or path to file.

- min_val:

  Numeric. Minimum valid value (default: -1).

- max_val:

  Numeric. Maximum valid value (default: 1).

## Value

A cleaned SpatRaster.
