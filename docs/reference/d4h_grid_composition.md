# Grid-Level Land Cover Percentage Composition and Feature Segmentation

Computes the percentage composition of physical features
(houses/buildings, water bodies, vegetation canopy, bare soil) across
each operational grid cell, providing granular sectoral profiles for
micro-environmental surveillance.

## Usage

``` r
d4h_grid_composition(
  grid,
  water = NULL,
  buildings = NULL,
  ndvi_raster = NULL,
  veg_threshold = 0.3,
  soil_threshold = 0.15,
  out_xlsx = NULL
)
```

## Arguments

- grid:

  SpatVector, sf, or character path. Operational surveillance grid (e.g.
  from `d4h_hex_grid` or `d4h_summarize_grid`).

- water:

  SpatVector, sf, or SpatRaster (optional). Segmented water body
  polygons or binary water raster.

- buildings:

  SpatVector, sf, or SpatRaster (optional). Segmented dwelling/building
  footprints or binary roof raster.

- ndvi_raster:

  SpatRaster or character path (optional). NDVI continuous raster to
  determine vegetation and bare soil cover.

- veg_threshold:

  Numeric. NDVI threshold above which pixels are categorized as
  vegetation (default: 0.3).

- soil_threshold:

  Numeric. NDVI upper threshold below which non-water pixels are
  categorized as bare soil (default: 0.15).

- out_xlsx:

  Character (optional). File path to export a structured Excel
  spreadsheet.

## Value

An `sf` object with appended columns: `area_m2`, `pct_casas`,
`pct_agua`, `pct_vegetacion`, `pct_suelo_desnudo`, `n_casas`,
`n_cuerpos_agua`, `clase_dominante`, and `prioridad_vigilancia`.

## Details

Intersects vector feature boundaries or raster masks with
square/hexagonal grid cells: \$\$\text{Pct}\_{\text{class}} =
\frac{\text{Area}\_{\text{class} \cap
\text{Cell}\_k}}{\text{Area}\_{\text{Cell}\_k}} \times 100\$\$ Computes
individual coverage metrics (`pct_casas`, `pct_agua`, `pct_vegetacion`,
`pct_suelo_desnudo`), identifies the dominant land cover class, and
assigns intervention priority tiers based on the co-occurrence of
dwellings and standing water habitats.
