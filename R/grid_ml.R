#' @title List Available Micro-Environmental and Epidemiological Metrics
#' @description Returns a tibble listing available metrics, resolutions, and typical applications.
#' @return A tibble with metric metadata.
#' @export
d4h_list_metrics <- function() {
  tibble::tribble(
    ~category,          ~metric,            ~resolution_cm, ~application,
    "Topographic",      "Slope",            10,             "Runoff prediction",
    "Topographic",      "TWI",              10,             "Micro-hydrology",
    "Spectral",         "NDVI",             5,              "Vegetation vigor",
    "Spectral",         "SAVI",             5,              "Soil-adjusted vegetation",
    "Spectral",         "EVI",              5,              "Dense canopy vigor",
    "Spectral",         "NDWI",             5,              "Surface water / moisture",
    "Spectral",         "NDRE",             5,              "Chlorophyll / Red Edge",
    "Spectral",         "GNDVI",            5,              "Chlorophyll concentration",
    "Spectral",         "DVI",              5,              "Difference vegetation",
    "Spectral",         "CTVI",             5,              "Transformed vegetation",
    "Spectral",         "LST (°C)",         30,             "Thermal mapping",
    "Epidemiological",  "Bare Soil Mask",   5,              "Zoonotic/fecalism risk",
    "Epidemiological",  "IMSR (Synthetics)",5,              "Aedes breeding sites",
    "Epidemiological",  "IRTS (Refuge)",    10,             "Vector microclimate refuge",
    "Epidemiological",  "IEV (Stagnation)", 10,             "Snail/mosquito habitat",
    "Epidemiological",  "IEC (Breeding)",   10,             "Larval development stratification",
    "Epidemiological",  "IEAD (Clearings)", 10,             "Deforestation puddle risk",
    "Epidemiological",  "IRHE (Retention)", 10,             "Cold water persistence",
    "Epidemiological",  "IFEB (Edge)",      10,             "Ecotone / border interface",
    "Epidemiological",  "IRIH (Roughness)", 10,             "Forest-household interface"
  )
}

#' @title Generate Hexagonal Grid Over Area of Interest
#' @description Creates an operative hexagonal grid for active epidemiological surveillance.
#' @param aoi SpatRaster, SpatVector, or sf object defining the area of interest.
#' @param cell_size Numeric. Cell size in meters (default: 50).
#' @return A SpatVector containing the hexagonal grid polygons with unique IDs.
#' @export
d4h_hex_grid <- function(aoi, cell_size = 50) {
  if (inherits(aoi, "SpatRaster")) {
    boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(aoi), crs = terra::crs(aoi)))
  } else if (inherits(aoi, "SpatVector")) {
    boundary_sf <- sf::st_as_sf(aoi)
  } else if (inherits(aoi, "sf")) {
    boundary_sf <- aoi
  } else {
    stop("'aoi' must be a SpatRaster, SpatVector, or sf object.", call. = FALSE)
  }

  grid_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = FALSE)
  grid_sf <- sf::st_sf(
    grid_id = sprintf("H%04d", seq_along(grid_sf)),
    geometry = grid_sf
  )
  terra::vect(grid_sf)
}

#' @title Build Machine Learning Ready Matrix from Zonal Statistics
#' @description Extracts zonal statistics from raster layers across grid cells to prepare feature tables.
#' @param hex_data SpatVector or sf. Hexagonal or square surveillance grid.
#' @param raster_stack SpatRaster. Stack of environmental and epidemiological raster layers.
#' @param funs Character vector. Summary functions to compute (e.g., c("mean", "max")).
#' @return A data.frame or tibble with grid IDs and extracted features.
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
