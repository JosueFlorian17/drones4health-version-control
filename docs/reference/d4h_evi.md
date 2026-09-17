# Enhanced Vegetation Index (EVI)

Calculates EVI for areas with dense canopy background.

## Usage

``` r
d4h_evi(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1)
```

## Arguments

- nir:

  SpatRaster. Near-infrared band.

- red:

  SpatRaster. Red band.

- blue:

  SpatRaster. Blue band.

- g_factor:

  Numeric. Gain factor.

- c1:

  Numeric. Aerosol resistance coefficient 1.

- c2:

  Numeric. Aerosol resistance coefficient 2.

- l_factor:

  Numeric. Canopy background adjustment.

## Value

A SpatRaster containing EVI values.
