# Thermal Refuge and Shade Index (IRTS)

Identifies cool, shaded microhabitats serving as vector refuges.

## Usage

``` r
d4h_irts(ndre, lst_local, lst_surrounding, nir, eps = 0.001)
```

## Arguments

- ndre:

  SpatRaster. NDRE index layer.

- lst_local:

  SpatRaster. Local Land Surface Temperature.

- lst_surrounding:

  SpatRaster. Focal mean surrounding Land Surface Temperature.

- nir:

  SpatRaster. Near-infrared band.

- eps:

  Numeric. Small epsilon to prevent division by zero.

## Value

A SpatRaster representing thermal refuges.
