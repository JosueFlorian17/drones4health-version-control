# List Available Micro-Environmental and Epidemiological Metrics

Returns a tibble listing the curated drone metrics, resolutions, and
typical applications.

## Usage

``` r
d4h_list_metrics()
```

## Value

A tibble with metric descriptions.

## Examples

``` r
library(drones4health)

# Display the table of available spatial health metrics
metrics_table <- d4h_list_metrics()
print(metrics_table)
#> # A tibble: 5 × 4
#>   category        metric            resolution_cm application                   
#>   <chr>           <chr>                     <dbl> <chr>                         
#> 1 Spectral        NDVI                          5 Vegetation vigor & biomass    
#> 2 Spectral        NDWI                          5 Surface water & moisture dete…
#> 3 Topographic     TWI                          10 Topographic micro-hydrology &…
#> 4 Epidemiological IEV (Stagnation)             10 Vector / snail breeding micro…
#> 5 Epidemiological IMSR (Synthetics)             5 Artificial container & waste …
```
