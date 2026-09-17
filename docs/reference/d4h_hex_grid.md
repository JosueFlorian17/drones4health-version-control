# Generate Hexagonal Surveillance Grid

Creates an operative hexagonal grid over an Area of Interest (AOI).

## Usage

``` r
d4h_hex_grid(aoi, cell_size = 50)
```

## Arguments

- aoi:

  SpatRaster, SpatVector, or sf object defining the spatial bounds.

- cell_size:

  Numeric. Cell diameter in meters (default: 50).

## Value

A SpatVector containing the hexagonal grid polygons.
