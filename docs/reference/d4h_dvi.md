# Difference Vegetation Index (DVI)

Calculates DVI as the simple difference between NIR and Red reflectance.

## Usage

``` r
d4h_dvi(nir, red)
```

## Arguments

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- red:

  SpatRaster or character. Red band or path to file.

## Value

A SpatRaster containing DVI values with background masked to NA.
