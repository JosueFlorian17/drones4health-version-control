# Thermal Refuge and Shade Index (IRTS)

Identifies cool, shaded microhabitats serving as micro-climatic shelters
and resting sites for adult disease vectors during extreme heat hours.

## Usage

``` r
d4h_irts(ndre, lst_local, lst_surrounding, nir, eps = 0.001)
```

## Arguments

- ndre:

  SpatRaster or character. NDRE index layer or path to file.

- lst_local:

  SpatRaster or character. Local Land Surface Temperature (°C) or path
  to file.

- lst_surrounding:

  SpatRaster or character. Focal mean surrounding Land Surface
  Temperature (°C) or path to file.

- nir:

  SpatRaster or character. Near-infrared band or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero (default: 0.001).

## Value

A SpatRaster representing thermal refuge intensity with background
masked to `NA`.

## Details

The Thermal Refuge and Shade Index evaluates the thermal gradient
between focal surroundings and localized micro-environments modulated by
canopy density: \$\$\text{IRTS} = \frac{\text{NDRE} \times
(\text{LST}\_{\text{surrounding}} -
\text{LST}\_{\text{local}})}{\text{NIR} + \epsilon}\$\$ High positive
IRTS values highlight cool micro-climatic refuges buffered by dense
vegetative cover.

## References

Murdock, C. C., Sternberg, E. D., & Thomas, M. B. (2016). Microclimate
determines the infection potential of *Aedes aegypti* for dengue virus.
*PLOS Neglected Tropical Diseases*, 10(12), e0005118.
[doi:10.1371/journal.pntd.0005118](https://doi.org/10.1371/journal.pntd.0005118)
