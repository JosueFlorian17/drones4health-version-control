# Export Executive Summary to Multi-Sheet Excel File

Exports a `d4h_executive_summary` object to an Excel workbook (.xlsx)
with dedicated sheets for Global Summary, Stratification, and Outlier
Diagnostics.

## Usage

``` r
d4h_export_summary(x, out_xlsx)
```

## Arguments

- x:

  An object of class `d4h_executive_summary`.

- out_xlsx:

  Character. Path where the .xlsx file will be created.

## Value

Invisibly returns the input object `x`.
