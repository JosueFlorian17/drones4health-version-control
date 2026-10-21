# Executive Summary of Micro-Environmental and Epidemiological Indicators

Generates a comprehensive executive report for a given raster layer or
multi-band mosaic. It extracts key statistical moments, spatial extent
and resolution metrics, Tukey outlier diagnostics, domain-specific
bio-physical/epidemiological stratum interpretations, either globally
(`by = "general"`) or per territorial grid cell (`by = "grid"`), and
optionally exports a formatted multi-sheet Excel spreadsheet.

## Usage

``` r
d4h_executive_summary(
  raster_in,
  by = c("general", "grid"),
  grid = NULL,
  cell_size = 50,
  square = TRUE,
  out_xlsx = NULL,
  sample_size = 1e+06,
  digits = 3
)

d4h_report(
  raster_in,
  by = c("general", "grid"),
  grid = NULL,
  cell_size = 50,
  square = TRUE,
  out_xlsx = NULL,
  sample_size = 1e+06,
  digits = 3
)
```

## Arguments

- raster_in:

  SpatRaster, list of SpatRaster layers, or character file path.

- by:

  Character. Summary aggregation scope: `"general"` (default, overall
  scene report) or `"grid"` (zonal summary per grid cell, with one row
  per cell).

- grid:

  Optional SpatVector, sf, or character path to existing grid polygon
  boundaries when `by = "grid"`. If NULL, automatically generated using
  `cell_size` and `square`.

- cell_size:

  Numeric. Grid cell size / diameter in meters when generating a new
  grid for `by = "grid"` (default: 50).

- square:

  Logical. If TRUE, square grid; if FALSE, hexagonal grid (default:
  TRUE).

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

An object of class `d4h_executive_summary` (for `by = "general"`) or
`d4h_grid_summary` / `data.frame` (for `by = "grid"`) containing
structured metrics, spatial coverage metadata, outlier diagnostics, and
thematic stratum distributions.

## Details

The executive summary computes descriptive moments (mean, standard
deviation, coefficient of variation, median, interquartile range) and
identifies spatial anomalies using Tukey's IQR outlier fences:
\$\$\text{Lower Fence} = Q\_{25} - 1.5 \times \text{IQR}\$\$
\$\$\text{Upper Fence} = Q\_{75} + 1.5 \times \text{IQR}\$\$ Surface
strata are categorized by biophysical domain thresholds and translated
into percentage and hectare metrics. When `by = "grid"`, each row
represents an operational surveillance grid cell with full descriptive
moments, Tukey outlier rates, and stratum area percentages.

## References

Tukey, J. W. (1977). *Exploratory Data Analysis*. Addison-Wesley.
