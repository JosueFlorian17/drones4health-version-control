# Breeding Site Stratification Index (IEC)

Evaluates open water bodies weighted by optimal thermal ranges for
larval development.

## Usage

``` r
d4h_iec(gndvi_water, lst, t_opt = 25)
```

## Arguments

- gndvi_water:

  SpatRaster or character. GNDVI layer masked to water bodies or path to
  file.

- lst:

  SpatRaster or character. Land Surface Temperature layer in Celsius or
  path to file.

- t_opt:

  Numeric. Optimal incubation temperature in degrees Celsius (default:
  25).

## Value

A SpatRaster stratifying larval breeding site quality with background
masked to NA.
