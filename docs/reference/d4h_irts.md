# Thermal Refuge and Shade Index (IRTS)

Identifies cool, shaded microhabitats serving as vector microclimate
refuges.

## Usage

``` r
d4h_irts(ndre, lst_local, lst_surrounding, nir, eps = 0.001)
```

## Arguments

- ndre:

  SpatRaster or character. NDRE index layer or path to file.

- lst_local:

  SpatRaster or character. Local Land Surface Temperature or path to
  file.

- lst_surrounding:

  SpatRaster or character. Focal mean surrounding Land Surface
  Temperature or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing thermal refuge intensity with background
masked to NA.
