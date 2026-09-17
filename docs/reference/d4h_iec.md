# Breeding Site Stratification Index (IEC)

Evaluates water bodies weighted by optimal thermal ranges for larval
development.

## Usage

``` r
d4h_iec(gndvi_water, lst, t_opt = 25)
```

## Arguments

- gndvi_water:

  SpatRaster. GNDVI masked strictly to water bodies.

- lst:

  SpatRaster. Land Surface Temperature in Celsius.

- t_opt:

  Numeric. Optimal incubation temperature.

## Value

A SpatRaster stratifying breeding site quality.
