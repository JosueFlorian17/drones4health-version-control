# Export Executive Summary to Multi-Sheet Excel File

Exports a `d4h_executive_summary` object to an Excel workbook (.xlsx)
with dedicated sheets for Global Summary, Stratification, Outlier
Diagnostics, and optional Household Water Proximity.

## Usage

``` r
d4h_export_summary(x, out_xlsx, houses_proximity = NULL, houses_risk = NULL)
```

## Arguments

- x:

  An object of class `d4h_executive_summary`.

- out_xlsx:

  Character. Path where the .xlsx file will be created.

- houses_proximity:

  Optional `sf` or `data.frame` of residential dwellings with distance
  to water and proximity attributes.

- houses_risk:

  Deprecated alias for `houses_proximity`.

## Value

Invisibly returns the input object `x`.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
  exec_rep  <- d4h_executive_summary(ndvi_file, by = "general")

  # Export executive summary object to Excel workbook
  out_file <- tempfile(fileext = ".xlsx")
  d4h_export_summary(exec_rep, out_xlsx = out_file)
}
# }
```
