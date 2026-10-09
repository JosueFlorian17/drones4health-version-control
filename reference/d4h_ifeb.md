# Fragmentation and Edge Effect Index (IFEB)

Quantifies ecological transitions and ecotone borders between tree
canopies and urban or cleared soil substrates.

## Usage

``` r
d4h_ifeb(grad_red_edge, red, nir, eps = 0.001)
```

## Arguments

- grad_red_edge:

  SpatRaster or character. Focal standard deviation of Red Edge or path
  to file.

- red:

  SpatRaster or character. Red band or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster quantifying edge effects with background masked to `NA`.

## Details

The Forest Edge & Environmental Barrier Index is formulated as:
\$\$\text{IFEB} = \|\nabla(\text{RedEdge})\| \times
\frac{\text{Red}}{\text{NIR} + \epsilon}\$\$

## References

Laurance, W. F., et al. (2011). The impact of forest fragmentation on
disease ecology. *Biological Conservation*, 144(1), 56-68.
