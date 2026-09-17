#' @title Topographic Slope
#' @description Derives terrain slope from a Digital Elevation Model (DEM).
#' @param dem_raster SpatRaster. Digital Elevation Model.
#' @param unit Character. Output unit ("degrees" or "radians").
#' @return A SpatRaster representing terrain slope.
#' @export
d4h_slope <- function(dem_raster, unit = "degrees") {
  terra::terrain(dem_raster, v = "slope", unit = unit)
}

#' @title Topographic Wetness Index (TWI)
#' @description Calculates TWI to identify potential water accumulation areas based on terrain.
#' @param dem_raster SpatRaster. Digital Elevation Model.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster containing TWI values.
#' @export
d4h_twi <- function(dem_raster, eps = 0.001) {
  slope_rad <- terra::terrain(dem_raster, v = "slope", unit = "radians")
  flow_acc  <- terra::terrain(dem_raster, v = "flowdir")
  log((flow_acc + 1) / (tan(slope_rad) + eps))
}
