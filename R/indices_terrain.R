#' @title Topographic Slope
#' @description Derives terrain slope in degrees or radians from a Digital Elevation Model (DEM) or Digital Surface Model (DSM).
#' @param dem_raster SpatRaster or character. Input DEM/DSM or path to file.
#' @param unit Character. Slope unit: "degrees" or "radians" (default: "degrees").
#' @return A SpatRaster containing slope values with background masked to NA.
#' @export
d4h_slope <- function(dem_raster, unit = "degrees") {
  dem <- .ensure_raster(dem_raster, mask_zeros = FALSE)
  dem[is.nan(dem) | is.infinite(dem)] <- NA

  slp <- terra::terrain(dem, v = "slope", unit = unit)
  slp[is.nan(slp) | is.infinite(slp)] <- NA
  names(slp) <- paste0("slope_", unit)
  slp
}

#' @title Topographic Wetness Index (TWI)
#' @description Calculates Topographic Wetness Index to model micro-scale hydrological accumulation zones.
#' @param dem_raster SpatRaster or character. Input DEM/DSM or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero in flat areas (default: 0.001).
#' @return A SpatRaster containing TWI values with background masked to NA.
#' @export
d4h_twi <- function(dem_raster, eps = 0.001) {
  dem <- .ensure_raster(dem_raster, mask_zeros = FALSE)
  dem[is.nan(dem) | is.infinite(dem)] <- NA

  slope_rad <- terra::terrain(dem, v = "slope", unit = "radians")
  flow_acc  <- terra::terrain(dem, v = "flowdir")

  twi <- log((flow_acc + 1) / (tan(slope_rad) + eps))
  twi[is.nan(twi) | is.infinite(twi)] <- NA
  names(twi) <- "TWI"
  twi
}
