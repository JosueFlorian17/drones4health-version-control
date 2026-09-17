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

#' @title Build Machine Learning Ready Matrix from Zonal Statistics
#' @description Extracts zonal statistics from raster layers across grid cells to prepare feature tables.
#' @param hex_data SpatVector or sf. Hexagonal or square surveillance grid.
#' @param raster_stack SpatRaster. Stack of environmental and epidemiological raster layers.
#' @param funs Character vector. Summary functions to compute (e.g., c("mean", "max")).
#' @return A tibble with grid IDs and extracted features.
#' @export
d4h_build_ml_matrix <- function(hex_data, raster_stack, funs = c("mean", "max")) {
  if (inherits(hex_data, "sf")) {
    hex_data <- terra::vect(hex_data)
  }

  results <- list()
  for (f in funs) {
    fun_impl <- match.fun(f)
    ext_vals <- terra::extract(raster_stack, hex_data, fun = fun_impl, na.rm = TRUE)
    if ("ID" %in% names(ext_vals)) {
      ext_vals$ID <- NULL
    }
    names(ext_vals) <- paste0(names(ext_vals), "_", f)
    results[[f]] <- ext_vals
  }

  df_matrix <- do.call(cbind, results)

  if ("grid_id" %in% names(hex_data)) {
    df_matrix <- cbind(grid_id = hex_data$grid_id, df_matrix)
  }

  tibble::as_tibble(df_matrix)
}
