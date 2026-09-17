# Generate Hexagonal Grid Over Area of Interest

Creates an operative hexagonal grid for active epidemiological
surveillance.

## Usage

``` r
d4h_hex_grid(aoi, cell_size = 50)
```

## Arguments

- aoi:

  SpatRaster, SpatVector, or sf object defining the area of interest.

- cell_size:

  Numeric. Cell size in meters (default: 50).

## Value

A SpatVector containing the hexagonal grid polygons with unique IDs.
