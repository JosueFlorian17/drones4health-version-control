# Human Interface Roughness Index (IRIH)

Measures canopy structural heterogeneity in the forest-household ecotone
interface to model vector flight pathways and peridomestic contact.

## Usage

``` r
d4h_irih(var_re_nir, red, green, eps = 0.001)
```

## Arguments

- var_re_nir:

  SpatRaster or character. Local variance of RE/NIR ratio or path to
  file.

- red:

  SpatRaster or character. Red band or path to file.

- green:

  SpatRaster or character. Green band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing structural roughness with background masked to
`NA`.

## Details

The Index of Human Infection Risk / Roughness is calculated as:
\$\$\text{IRIH} =
\text{Var}\left(\frac{\text{RedEdge}}{\text{NIR}}\right) \times
\frac{\text{Red}}{\text{Green} + \epsilon}\$\$

## References

Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global
extent of malaria in 2005. *Trends in Parasitology*, 22(8), 353-358.
[doi:10.1016/j.pt.2006.06.006](https://doi.org/10.1016/j.pt.2006.06.006)
