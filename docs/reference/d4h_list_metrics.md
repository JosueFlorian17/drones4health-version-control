# List Available Micro-Environmental and Epidemiological Metrics

Dynamically retrieves all available remote sensing indices, terrain
metrics, and eco-epidemiological indicators supported by the package,
detailing their mathematical formulas, typical spatial resolutions, and
vector surveillance applications.

## Usage

``` r
d4h_list_metrics(category = NULL)
```

## Arguments

- category:

  Character (optional). Filter metrics by category: "Spectral",
  "Topographic", "Epidemiological", or NULL to list all.

## Value

A `tibble` containing the metric names, corresponding package functions,
formulas, and epidemiological applications.

## Examples

``` r
library(drones4health)

# Display all available spatial health metrics
metrics_table <- d4h_list_metrics()
print(metrics_table)
#> # A tibble: 21 × 6
#>    category metric function_name resolution_cm formula               application
#>    <chr>    <chr>  <chr>                 <dbl> <chr>                 <chr>      
#>  1 Spectral NDVI   d4h_ndvi                  5 (NIR - Red) / (NIR +… Vegetation…
#>  2 Spectral DVI    d4h_dvi                   5 NIR - Red             Linear can…
#>  3 Spectral SAVI   d4h_savi                  5 ((NIR - Red) / (NIR … Soil-adjus…
#>  4 Spectral MSAVI2 d4h_msavi2                5 (2*NIR + 1 - sqrt((2… Self-adjus…
#>  5 Spectral VARI   d4h_vari                  5 (Green - Red) / (Gre… RGB-only v…
#>  6 Spectral EVI    d4h_evi                   5 G * ((NIR - Red) / (… Enhanced v…
#>  7 Spectral NDWI   d4h_ndwi                  5 (Green - NIR) / (Gre… Open surfa…
#>  8 Spectral NDRE   d4h_ndre                  5 (NIR - RedEdge) / (N… Chlorophyl…
#>  9 Spectral GNDVI  d4h_gndvi                 5 (NIR - Green) / (NIR… Photosynth…
#> 10 Spectral CTVI   d4h_ctvi                  5 (NDVI + 0.5) / sqrt(… Corrected …
#> # ℹ 11 more rows

# Filter only eco-epidemiological indices
epi_metrics <- d4h_list_metrics(category = "Epidemiological")
print(epi_metrics)
#> # A tibble: 8 × 6
#>   category        metric function_name resolution_cm formula         application
#>   <chr>           <chr>  <chr>                 <dbl> <chr>           <chr>      
#> 1 Epidemiological IMSR   d4h_imsr                  5 |NDRE_approx -… Solid wast…
#> 2 Epidemiological IRTS   d4h_irts                 10 (NDRE * (LST_s… Thermal re…
#> 3 Epidemiological IEV    d4h_iev                  10 NDWI * (1 / (S… Vulnerabil…
#> 4 Epidemiological IEC    d4h_iec                  10 GNDVI_water * … Larval inc…
#> 5 Epidemiological IEAD   d4h_iead                 10 grad(delta_NDV… Water pool…
#> 6 Epidemiological IRHE   d4h_irhe                 10 NDWI * (1 / (L… Persistent…
#> 7 Epidemiological IFEB   d4h_ifeb                 10 |grad(RedEdge)… Forest-edg…
#> 8 Epidemiological IRIH   d4h_irih                 10 Var(RedEdge / … Canopy str…
```
