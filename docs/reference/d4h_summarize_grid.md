# Summarize Raster Indicator by Spatial Grid

Generates a square or hexagonal spatial grid and extracts zonal summary
statistics (mean, quantiles) of raster indicators per grid cell.

## Usage

``` r
d4h_summarize_grid(raster_in, cell_size = 20, square = TRUE, discard_na = TRUE)
```

## Arguments

- raster_in:

  SpatRaster or character. Input raster layer, stack, or path to file.

- cell_size:

  Numeric. Grid cell size / diameter in meters (default: 20).

- square:

  Logical. If TRUE, creates square cells; if FALSE, hexagonal cells
  (default: TRUE).

- discard_na:

  Logical. If TRUE, removes grid cells outside the valid raster data
  area (default: TRUE).

## Value

A SpatVector containing the grid cells with extracted mean values.

## Details

Zonal extraction aggregates high-resolution pixel values into
operational territorial units: \$\$\bar{x}\_k = \frac{1}{N_k} \sum\_{i
\in \text{Cell}\_k} x_i\$\$ Empty grid cells outside the valid flight
footprint are automatically pruned when `discard_na = TRUE`.

## References

Birch, C. P., Oom, S. P., & Beecham, J. A. (2007). Rectangular and
hexagonal grids used for observation, experiment and simulation in
ecology. *Ecological Modelling*, 206(3-4), 347-359.
[doi:10.1016/j.ecolmodel.2007.03.041](https://doi.org/10.1016/j.ecolmodel.2007.03.041)
