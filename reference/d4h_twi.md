# Topographic Wetness Index (TWI)

Calculates the Topographic Wetness Index (TWI) to model micro-scale
hydrological accumulation and water-pooling potential from elevation
data.

## Usage

``` r
d4h_twi(dem_raster, eps = 0.001)
```

## Arguments

- dem_raster:

  SpatRaster or character. Input DEM/DSM or path to file.

- eps:

  Numeric. Small epsilon to prevent division by zero in completely flat
  areas (default: 0.001).

## Value

A SpatRaster containing TWI values with background masked to `NA`.

## Details

The Topographic Wetness Index is defined as: \$\$\text{TWI} =
\ln\left(\frac{a}{\tan(\beta) + \epsilon}\right)\$\$ where \\a\\ is the
specific contributing drainage area (catchment area per unit contour
length), \\\beta\\ is the local slope in radians, and \\\epsilon\\ is a
small numerical stabilization parameter. Higher TWI values indicate
low-lying areas and micro-depressions with high susceptibility to
surface water accumulation and vector larval breeding.

## References

Beven, K. J., & Kirkby, M. J. (1979). A physically based, variable
contributing area model of basin hydrology. *Hydrological Sciences
Bulletin*, 24(1), 43-69.
[doi:10.1080/02626667909491834](https://doi.org/10.1080/02626667909491834)

Sorensen, R., Zinko, U., & Seibert, J. (2006). On the calculation of the
topographic wetness index: evaluation of different methods based on
field observations. *Hydrology and Earth System Sciences*, 10(1),
101-112.
[doi:10.5194/hess-10-101-2006](https://doi.org/10.5194/hess-10-101-2006)
