# Global Statistical Summary of Raster Indicators

Calculates descriptive statistics (mean, standard deviation, min, max,
and quantiles) across the entire extent of one or multiple SpatRaster
indicator layers.

## Usage

``` r
d4h_summarize_global(raster_in, na.rm = TRUE, quantiles = TRUE, digits = 4)

d4h_global_summary(raster_in, na.rm = TRUE, quantiles = TRUE, digits = 4)
```

## Arguments

- raster_in:

  SpatRaster, list of SpatRaster layers, or character path to a raster
  file.

- na.rm:

  Logical. If TRUE, removes NA/infinite/NaN values from computation
  (default: TRUE).

- quantiles:

  Logical. If TRUE, includes 25th percentile, median (50th percentile),
  and 75th percentile (default: TRUE).

- digits:

  Numeric. Number of decimal places to round results. If NULL, values
  are not rounded (default: 4).

## Value

A tibble data frame containing summary statistics per layer.
