#' @title Synthetic Materials Risk Index (IMSR)
#' @description Detects non-natural materials (plastics, rubber, discarded tires) that serve as potential vector breeding containers.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param veg_threshold Numeric. Threshold to differentiate vegetation from synthetics (default: 0.2).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing IMSR values with background masked to NA.
#' @export
d4h_imsr <- function(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001) {
  aligned <- .match_multi(red_edge, red, nir, mask_zeros = TRUE)
  re <- aligned[[1]]
  r  <- aligned[[2]]
  n  <- aligned[[3]]

  ndre_approx <- (re - r) / (re + r + eps)
  res <- abs(ndre_approx - veg_threshold) * n
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IMSR"
  res
}

#' @title Thermal Refuge and Shade Index (IRTS)
#' @description Identifies cool, shaded microhabitats serving as vector microclimate refuges.
#' @param ndre SpatRaster or character. NDRE index layer or path to file.
#' @param lst_local SpatRaster or character. Local Land Surface Temperature or path to file.
#' @param lst_surrounding SpatRaster or character. Focal mean surrounding Land Surface Temperature or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing thermal refuge intensity with background masked to NA.
#' @export
d4h_irts <- function(ndre, lst_local, lst_surrounding, nir, eps = 0.001) {
  aligned <- .match_multi(ndre, lst_local, lst_surrounding, nir, mask_zeros = FALSE)
  re_ndre <- aligned[[1]]
  t_loc   <- aligned[[2]]
  t_surr  <- aligned[[3]]
  n_nir   <- aligned[[4]]

  den <- n_nir + eps
  res <- (re_ndre * (t_surr - t_loc)) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRTS"
  res
}

#' @title Vulnerability Stagnation Indicator (IEV)
#' @description Locates areas where surface water is prone to micro-stagnation by combining surface moisture and micro-topography.
#' @param delta_ndwi SpatRaster or character. Temporal difference in NDWI or base NDWI layer or path to file.
#' @param slope_dsm SpatRaster or character. Slope layer derived from DSM or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing IEV stagnation risk values with background masked to NA.
#' @export
d4h_iev <- function(delta_ndwi, slope_dsm, eps = 0.001) {
  pair <- .match_pair(delta_ndwi, slope_dsm, mask_zeros = FALSE)
  ndwi <- pair$ref
  slp  <- pair$sub

  den <- slp + eps
  res <- ndwi * (1 / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEV"
  res
}

#' @title Breeding Site Stratification Index (IEC)
#' @description Evaluates open water bodies weighted by optimal thermal ranges for larval development.
#' @param gndvi_water SpatRaster or character. GNDVI layer masked to water bodies or path to file.
#' @param lst SpatRaster or character. Land Surface Temperature layer in Celsius or path to file.
#' @param t_opt Numeric. Optimal incubation temperature in degrees Celsius (default: 25).
#' @return A SpatRaster stratifying larval breeding site quality with background masked to NA.
#' @export
d4h_iec <- function(gndvi_water, lst, t_opt = 25) {
  pair <- .match_pair(gndvi_water, lst, mask_zeros = FALSE)
  gw  <- pair$ref
  tmp <- pair$sub

  res <- gw * (1 - (abs(tmp - t_opt) / t_opt))
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEC"
  res
}

#' @title Clearing Stagnation Index (IEAD)
#' @description Detects surface water pooling in recently cleared or deforested areas.
#' @param grad_delta_ndvi SpatRaster or character. Gradient of NDVI change layer or path to file.
#' @param depressions_dsm SpatRaster or character. Topographic depressions layer from DSM or path to file.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @return A SpatRaster highlighting stagnation risk in clearings with background masked to NA.
#' @export
d4h_iead <- function(grad_delta_ndvi, depressions_dsm, red_edge) {
  aligned <- .match_multi(grad_delta_ndvi, depressions_dsm, red_edge, mask_zeros = FALSE)
  g_ndvi <- aligned[[1]]
  d_dsm  <- aligned[[2]]
  re     <- aligned[[3]]

  res <- g_ndvi * d_dsm * re
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEAD"
  res
}

#' @title Spectral Water Retention Index (IRHE)
#' @description Highlights persistent, cold surface water bodies with low evaporation rates.
#' @param green SpatRaster or character. Green band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param lst SpatRaster or character. Land Surface Temperature layer or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing water retention potential with background masked to NA.
#' @export
d4h_irhe <- function(green, nir, lst, eps = 0.001) {
  aligned <- .match_multi(green, nir, lst, mask_zeros = TRUE)
  g <- aligned[[1]]
  n <- aligned[[2]]
  t <- aligned[[3]]

  den_ndwi <- g + n + eps
  ndwi <- (g - n) / den_ndwi
  ndwi[den_ndwi <= 0 | is.nan(ndwi) | is.infinite(ndwi)] <- NA

  den_lst <- t + eps
  res <- ndwi * (1 / den_lst)
  res[den_lst <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRHE"
  res
}

#' @title Fragmentation and Edge Effect Index (IFEB)
#' @description Quantifies ecological transitions and borders between canopy and urban/cleared soil.
#' @param grad_red_edge SpatRaster or character. Focal standard deviation of Red Edge or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster quantifying edge effects with background masked to NA.
#' @export
d4h_ifeb <- function(grad_red_edge, red, nir, eps = 0.001) {
  aligned <- .match_multi(grad_red_edge, red, nir, mask_zeros = TRUE)
  g_re <- aligned[[1]]
  r    <- aligned[[2]]
  n    <- aligned[[3]]

  den <- n + eps
  res <- abs(g_re) * (r / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IFEB"
  res
}

#' @title Human Interface Roughness Index (IRIH)
#' @description Measures canopy structural heterogeneity in the forest-household ecotone interface.
#' @param var_re_nir SpatRaster or character. Local variance of RE/NIR ratio or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param green SpatRaster or character. Green band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing structural roughness with background masked to NA.
#' @export
d4h_irih <- function(var_re_nir, red, green, eps = 0.001) {
  aligned <- .match_multi(var_re_nir, red, green, mask_zeros = TRUE)
  v_ratio <- aligned[[1]]
  r       <- aligned[[2]]
  g       <- aligned[[3]]

  den <- g + eps
  res <- v_ratio * (r / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRIH"
  res
}
