# Executive Summary of Micro-Environmental and Epidemiological Indicators

Generates a comprehensive executive report for a given raster layer or
multi-band mosaic. It extracts key statistical moments, spatial extent
and resolution metrics, Tukey outlier diagnostics, domain-specific
bio-physical/epidemiological stratum interpretations, and optionally
exports a formatted multi-sheet Excel spreadsheet.

## Usage

``` r
d4h_executive_summary(
  raster_in,
  out_xlsx = NULL,
  sample_size = 1e+06,
  digits = 3
)

d4h_report(raster_in, out_xlsx = NULL, sample_size = 1e+06, digits = 3)
```

## Arguments

- raster_in:

  SpatRaster, list of SpatRaster layers, or character file path.

- out_xlsx:

  Character (optional). File path to export a structured multi-sheet
  Excel workbook (.xlsx). Default: NULL.

- sample_size:

  Integer. Maximum number of sampled pixels for quantile and outlier
  analysis on large rasters (default: 1000000).

- digits:

  Integer. Number of decimal places to format numerical metrics
  (default: 3).

## Value

An object of class `d4h_executive_summary` containing a structured list
of metrics, spatial coverage metadata, outlier diagnostics, and thematic
stratum distributions.
