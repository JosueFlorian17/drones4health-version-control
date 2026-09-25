# Enhanced Vegetation Index (EVI)

Calculates EVI optimized for high biomass canopy regions.

## Usage

``` r
d4h_evi(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

- blue:

  SpatRaster or character. Blue band or path to file.

- g_factor:

  Numeric. Gain factor (default: 2.5).

- c1:

  Numeric. Aerosol resistance coefficient 1 (default: 6).

- c2:

  Numeric. Aerosol resistance coefficient 2 (default: 7.5).

- l_factor:

  Numeric. Canopy background adjustment (default: 1).

## Value

A SpatRaster containing EVI values with background masked to NA.
