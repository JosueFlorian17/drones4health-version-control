#' @title List Available Micro-Environmental and Epidemiological Metrics
#' @description Returns a tibble listing the curated drone metrics, resolutions, and typical applications.
#' @return A tibble with metric descriptions.
#' @export
d4h_list_metrics <- function() {
  tibble::tribble(
    ~category,          ~metric,            ~resolution_cm, ~application,
    "Spectral",         "NDVI",             5,              "Vegetation vigor & biomass",
    "Spectral",         "NDWI",             5,              "Surface water & moisture detection",
    "Topographic",      "TWI",              10,             "Topographic micro-hydrology & pooling",
    "Epidemiological",  "IEV (Stagnation)", 10,             "Vector / snail breeding micro-depressions",
    "Epidemiological",  "IMSR (Synthetics)",5,              "Artificial container & waste risk sites"
  )
}
