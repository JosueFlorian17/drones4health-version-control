#' @title Continuous Topographic Wetness Index (General Area)
#' @description Calculates continuous TWI from a Digital Elevation Model (DEM) to locate water accumulation zones.
#' @param dem Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing continuous TWI values.
#' @export
d4h_twi_general <- function(dem, eps = 0.001) {
  if (is.character(dem) && length(dem) == 1L) {
    if (!file.exists(dem)) stop(paste("File not found:", dem), call. = FALSE)
    dem <- terra::rast(dem)
  }
  if (!inherits(dem, "SpatRaster")) {
    stop("'dem' must be a file path or a SpatRaster object.", call. = FALSE)
  }

  dem_layer <- dem[[1]]
  slope_rad <- terra::terrain(dem_layer, v = "slope", unit = "radians")
  flow_acc  <- terra::terrain(dem_layer, v = "flowdir")
  twi       <- log((flow_acc + 1) / (tan(slope_rad) + eps))

  twi[is.infinite(twi) | is.nan(twi)] <- NA
  names(twi) <- "TWI"
  twi
}

#' @title Topographic Wetness Index (TWI)
#' @description Calculates Topographic Wetness Index with optional zonal grid summarization.
#' @param dem Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or path to file.
#' @param cell_size Numeric. Optional cell size in meters. If NULL, returns continuous raster (default: NULL).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is numeric).
#' @export
d4h_twi <- function(dem, cell_size = NULL, square = TRUE, eps = 0.001) {
  twi_raster <- d4h_twi_general(dem = dem, eps = eps)

  if (!is.null(cell_size)) {
    return(d4h_summarize_grid(twi_raster, cell_size = cell_size, square = square))
  }

  twi_raster
}
