#' @title List Available Micro-Environmental and Epidemiological Metrics
#' @description Dynamically retrieves all available remote sensing indices, terrain metrics, and eco-epidemiological indicators supported by the package, detailing their mathematical formulas, typical spatial resolutions, and vector surveillance applications.
#' @param category Character (optional). Filter metrics by category: "Spectral", "Topographic", "Epidemiological", or NULL to list all.
#' @return A \code{tibble} containing the metric names, corresponding package functions, formulas, and epidemiological applications.
#' @examples
#' library(drones4health)
#'
#' # Display all available spatial health metrics
#' metrics_table <- d4h_list_metrics()
#' print(metrics_table)
#'
#' # Filter only eco-epidemiological indices
#' epi_metrics <- d4h_list_metrics(category = "Epidemiological")
#' print(epi_metrics)
#' @export
d4h_list_metrics <- function(category = NULL) {
  metrics_catalog <- tibble::tribble(
    ~category,          ~metric,      ~function_name,            ~resolution_cm, ~formula,                                              ~application,
    "Spectral",         "NDVI",       "d4h_ndvi",                5,              "(NIR - Red) / (NIR + Red)",                           "Vegetation vigor, biomass density & canopy cover",
    "Spectral",         "DVI",        "d4h_dvi",                 5,              "NIR - Red",                                           "Linear canopy biomass & leaf area index variations",
    "Spectral",         "SAVI",       "d4h_savi",                5,              "((NIR - Red) / (NIR + Red + L)) * (1 + L)",           "Soil-adjusted vegetation index for sparse canopies (L=0.5)",
    "Spectral",         "MSAVI2",     "d4h_msavi2",              5,              "(2*NIR + 1 - sqrt((2*NIR+1)^2 - 8*(NIR-Red))) / 2",   "Self-adjusting vegetation index for arid & degraded soils",
    "Spectral",         "VARI",       "d4h_vari",                5,              "(Green - Red) / (Green + Red - Blue + eps)",          "RGB-only visible atmospherically resistant vegetation index",
    "Spectral",         "EVI",        "d4h_evi",                 5,              "G * ((NIR - Red) / (NIR + C1*Red - C2*Blue + L))",    "Enhanced vegetation index for high-biomass canopies",
    "Spectral",         "NDWI",       "d4h_ndwi",                5,              "(Green - NIR) / (Green + NIR)",                       "Open surface water bodies & localized moisture accumulation",
    "Spectral",         "NDRE",       "d4h_ndre",                5,              "(NIR - RedEdge) / (NIR + RedEdge)",                   "Chlorophyll content in dense vegetation avoiding NDVI saturation",
    "Spectral",         "GNDVI",      "d4h_gndvi",               5,              "(NIR - Green) / (NIR + Green)",                       "Photosynthetic activity & micro-algae in standing water",
    "Spectral",         "CTVI",       "d4h_ctvi",                5,              "(NDVI + 0.5) / sqrt(abs(NDVI + 0.5))",                "Corrected transformed vegetation index normalizing skewness",
    "Spectral",         "Bare_Soil",  "d4h_bare_soil",           5,              "ifel(NDVI < threshold, 1, 0)",                       "Binary mask of bare, exposed or degraded soil",
    "Topographic",      "Slope",      "d4h_slope",               10,             "arctan(sqrt((dz/dx)^2 + (dz/dy)^2))",                 "Micro-terrain slope derived from DSM/DEM in degrees/radians",
    "Topographic",      "TWI",        "d4h_twi",                 10,             "ln((flow_acc + 1) / (tan(slope) + eps))",             "Topographic wetness index & micro-pooling accumulation",
    "Epidemiological",  "IMSR",       "d4h_imsr",                5,              "|NDRE_approx - theta_veg| * NIR_norm",                "Solid waste, plastics & artificial Aedes aegypti breeding sites",
    "Epidemiological",  "IRTS",       "d4h_irts",                10,             "(NDRE * (LST_surr - LST_local)) / (NIR + eps)",       "Thermal refuge & cool shaded resting microhabitats for vectors",
    "Epidemiological",  "IEV",        "d4h_iev",                 10,             "NDWI * (1 / (Slope + eps))",                          "Vulnerability to water stagnation & larval colonization",
    "Epidemiological",  "IEC",        "d4h_iec",                 10,             "GNDVI_water * (1 - (|LST - T_opt| / T_opt))",         "Larval incubation & thermal stratification in water bodies",
    "Epidemiological",  "IEAD",       "d4h_iead",                10,             "grad(delta_NDVI) * Depressions * RedEdge",            "Water pooling in cleared, excavated & deforested micro-zones",
    "Epidemiological",  "IRHE",       "d4h_irhe",                10,             "NDWI * (1 / (LST + eps))",                            "Persistent cold water retention & dry-season vector refugia",
    "Epidemiological",  "IFEB",       "d4h_ifeb",                10,             "|grad(RedEdge)| * (Red / (NIR + eps))",               "Forest-edge ecotone borders & ecological fragmentation",
    "Epidemiological",  "IRIH",       "d4h_irih",                10,             "Var(RedEdge / NIR) * (Red / (Green + eps))",          "Canopy structural roughness in forest-dwelling interface"
  )

  # Dynamic check against package namespace if available
  ns_fns <- tryCatch(getNamespaceExports("drones4health"), error = function(e) character(0))
  if (length(ns_fns) > 0L) {
    keep_mask <- metrics_catalog$function_name %in% ns_fns
    if (any(keep_mask)) {
      metrics_catalog <- metrics_catalog[keep_mask, ]
    }
  }

  if (!is.null(category)) {
    matched_cat <- tolower(trimws(category))
    metrics_catalog <- metrics_catalog[tolower(metrics_catalog$category) == matched_cat, ]
  }

  metrics_catalog
}
