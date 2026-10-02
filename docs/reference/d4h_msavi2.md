# Modified Soil Adjusted Vegetation Index 2 (MSAVI2)

Computes MSAVI2 to evaluate vegetation cover in sparse or arid canopies
without requiring an empirical soil adjustment factor.

## Usage

``` r
d4h_msavi2(nir, red)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

## Value

A SpatRaster containing MSAVI2 values in `[-1, 1]` with background
masked to NA.
