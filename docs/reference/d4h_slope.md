# Topographic Slope

Derives terrain slope in degrees or radians from a Digital Elevation
Model (DEM) or Digital Surface Model (DSM).

## Usage

``` r
d4h_slope(dem_raster, unit = "degrees")
```

## Arguments

- dem_raster:

  SpatRaster or character. Input DEM/DSM or path to file.

- unit:

  Character. Slope unit: "degrees" or "radians" (default: "degrees").

## Value

A SpatRaster containing slope values with background masked to NA.
