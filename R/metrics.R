#' @title List Available Micro-Environmental and Epidemiological Metrics
#' @description Dynamically retrieves all available remote sensing indices, terrain metrics, and eco-epidemiological indicators supported by the package, detailing their mathematical formulas, typical spatial resolutions, and vector surveillance applications.
#' @param category Character (optional). Filter metrics by category: "Spectral", "Topographic", "Epidemiological", or NULL to list all.
#' @return A pure \code{data.frame} containing the metric names, corresponding package functions, formulas, and epidemiological applications.
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
  metrics_catalog <- data.frame(
    category = c(
      "Spectral", "Spectral", "Spectral", "Spectral", "Spectral",
      "Spectral", "Spectral", "Spectral", "Spectral", "Spectral", "Spectral",
      "Topographic", "Topographic",
      "Epidemiological", "Epidemiological", "Epidemiological", "Epidemiological",
      "Epidemiological", "Epidemiological", "Epidemiological", "Epidemiological"
    ),
    metric = c(
      "NDVI", "DVI", "SAVI", "MSAVI2", "VARI",
      "EVI", "NDWI", "NDRE", "GNDVI", "CTVI", "Bare_Soil",
      "Slope", "TWI",
      "IMSR", "IRTS", "IEV", "IEC",
      "IEAD", "IRHE", "IFEB", "IRIH"
    ),
    function_name = c(
      "d4h_ndvi", "d4h_dvi", "d4h_savi", "d4h_msavi2", "d4h_vari",
      "d4h_evi", "d4h_ndwi", "d4h_ndre", "d4h_gndvi", "d4h_ctvi", "d4h_bare_soil",
      "d4h_slope", "d4h_twi",
      "d4h_imsr", "d4h_irts", "d4h_iev", "d4h_iec",
      "d4h_iead", "d4h_irhe", "d4h_ifeb", "d4h_irih"
    ),
    resolution_cm = c(
      5, 5, 5, 5, 5,
      5, 5, 5, 5, 5, 5,
      10, 10,
      5, 10, 10, 10,
      10, 10, 10, 10
    ),
    formula = c(
      "(NIR - Red) / (NIR + Red)",
      "NIR - Red",
      "((NIR - Red) / (NIR + Red + L)) * (1 + L)",
      "(2*NIR + 1 - sqrt((2*NIR+1)^2 - 8*(NIR-Red))) / 2",
      "(Green - Red) / (Green + Red - Blue + eps)",
      "G * ((NIR - Red) / (NIR + C1*Red - C2*Blue + L))",
      "(Green - NIR) / (Green + NIR)",
      "(NIR - RedEdge) / (NIR + RedEdge)",
      "(NIR - Green) / (NIR + Green)",
      "(NDVI + 0.5) / sqrt(abs(NDVI + 0.5))",
      "ifel(NDVI < threshold, 1, 0)",
      "arctan(sqrt((dz/dx)^2 + (dz/dy)^2))",
      "ln((flow_acc + 1) / (tan(slope) + eps))",
      "|NDRE_approx - theta_veg| * NIR_norm",
      "(NDRE * (LST_surr - LST_local)) / (NIR + eps)",
      "NDWI * (1 / (Slope + eps))",
      "GNDVI_water * (1 - (|LST - T_opt| / T_opt))",
      "grad(delta_NDVI) * Depressions * RedEdge",
      "NDWI * (1 / (LST + eps))",
      "|grad(RedEdge)| * (Red / (NIR + eps))",
      "Var(RedEdge / NIR) * (Red / (Green + eps))"
    ),
    application = c(
      "Vegetation vigor, biomass density & canopy cover",
      "Linear canopy biomass & leaf area index variations",
      "Soil-adjusted vegetation index for sparse canopies (L=0.5)",
      "Self-adjusting vegetation index for arid & degraded soils",
      "RGB-only visible atmospherically resistant vegetation index",
      "Enhanced vegetation index for high-biomass canopies",
      "Open surface water bodies & localized moisture accumulation",
      "Chlorophyll content in dense vegetation avoiding NDVI saturation",
      "Photosynthetic activity & micro-algae in standing water",
      "Corrected transformed vegetation index normalizing skewness",
      "Binary mask of bare, exposed or degraded soil",
      "Micro-terrain slope derived from DSM/DEM in degrees/radians",
      "Topographic wetness index & micro-pooling accumulation",
      "Solid waste, plastics & artificial Aedes aegypti breeding sites",
      "Thermal refuge & cool shaded resting microhabitats for vectors",
      "Vulnerability to water stagnation & larval colonization",
      "Larval incubation & thermal stratification in water bodies",
      "Water pooling in cleared, excavated & deforested micro-zones",
      "Persistent cold water retention & dry-season vector refugia",
      "Forest-edge ecotone borders & ecological fragmentation",
      "Canopy structural roughness in forest-dwelling interface"
    ),
    stringsAsFactors = FALSE
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
