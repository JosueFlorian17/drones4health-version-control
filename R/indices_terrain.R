#' @title Topographic Slope
#' @description Derives micro-terrain slope in degrees or radians from a high-resolution Digital Elevation Model (DEM) or Digital Surface Model (DSM).
#' @details Topographic slope represents the rate of maximum elevation change:
#' \deqn{\beta = \arctan\left(\sqrt{\left(\frac{\partial z}{\partial x}\right)^2 + \left(\frac{\partial z}{\partial y}\right)^2}\right)}
#' Flat terrains (\eqn{\beta < 5^\circ}) are critical in spatial epidemiology as they favor persistent micro-pooling and water stagnation.
#' @param dem_raster SpatRaster or character. Input DEM/DSM or path to file.
#' @param unit Character. Slope unit: "degrees" or "radians" (default: "degrees").
#' @return A SpatRaster containing slope values with background masked to \code{NA}.
#' @references
#' Burrough, P. A., & McDonnell, R. A. (1998). \emph{Principles of Geographical Information Systems}. Oxford University Press.
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
#' @description Calculates the Topographic Wetness Index (TWI) to model micro-scale hydrological accumulation and water-pooling potential from elevation data.
#' @details The Topographic Wetness Index is defined as:
#' \deqn{\text{TWI} = \ln\left(\frac{a}{\tan(\beta) + \epsilon}\right)}
#' where \eqn{a} is the specific contributing drainage area (catchment area per unit contour length), \eqn{\beta} is the local slope in radians, and \eqn{\epsilon} is a small numerical stabilization parameter.
#' Higher TWI values indicate low-lying areas and micro-depressions with high susceptibility to surface water accumulation and vector larval breeding.
#' @param dem_raster SpatRaster or character. Input DEM/DSM or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero in completely flat areas (default: 0.001).
#' @return A SpatRaster containing TWI values with background masked to \code{NA}.
#' @references
#' Beven, K. J., & Kirkby, M. J. (1979). A physically based, variable contributing area model of basin hydrology. \emph{Hydrological Sciences Bulletin}, 24(1), 43-69. \doi{10.1080/02626667909491834}
#'
#' Sorensen, R., Zinko, U., & Seibert, J. (2006). On the calculation of the topographic wetness index: evaluation of different methods based on field observations. \emph{Hydrology and Earth System Sciences}, 10(1), 101-112. \doi{10.5194/hess-10-101-2006}
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
