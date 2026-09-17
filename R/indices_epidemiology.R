#' @title Synthetic Materials Risk Index (IMSR)
#' @description Detects non-natural materials (plastics, rubber, tires) that can serve as vector breeding sites.
#' @param red_edge SpatRaster. Red Edge band.
#' @param red SpatRaster. Red band.
#' @param nir SpatRaster. Near-infrared band.
#' @param veg_threshold Numeric. Threshold to differentiate vegetation from synthetics.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster highlighting synthetic materials.
#' @export
d4h_imsr <- function(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001) {
  ndre_approx <- (red_edge - red) / (red_edge + red + eps)
  abs(ndre_approx - veg_threshold) * nir
}

#' @title Thermal Refuge and Shade Index (IRTS)
#' @description Identifies cool, shaded microhabitats serving as vector refuges.
#' @param ndre SpatRaster. NDRE index layer.
#' @param lst_local SpatRaster. Local Land Surface Temperature.
#' @param lst_surrounding SpatRaster. Focal mean surrounding Land Surface Temperature.
#' @param nir SpatRaster. Near-infrared band.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster representing thermal refuges.
#' @export
d4h_irts <- function(ndre, lst_local, lst_surrounding, nir, eps = 0.001) {
  (ndre * (lst_surrounding - lst_local)) / (nir + eps)
}

#' @title Vulnerability Stagnation Indicator (IEV)
#' @description Locates areas where surface water is likely to stagnate due to micro-depressions.
#' @param delta_ndwi SpatRaster. Temporal difference in NDWI or base NDWI.
#' @param slope_dsm SpatRaster. Slope derived from the Digital Surface Model.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster highlighting stagnation risk.
#' @export
d4h_iev <- function(delta_ndwi, slope_dsm, eps = 0.001) {
  delta_ndwi * (1 / (slope_dsm + eps))
}

#' @title Breeding Site Stratification Index (IEC)
#' @description Evaluates water bodies weighted by optimal thermal ranges for larval development.
#' @param gndvi_water SpatRaster. GNDVI masked strictly to water bodies.
#' @param lst SpatRaster. Land Surface Temperature in Celsius.
#' @param t_opt Numeric. Optimal incubation temperature.
#' @return A SpatRaster stratifying breeding site quality.
#' @export
d4h_iec <- function(gndvi_water, lst, t_opt = 25) {
  gndvi_water * (1 - (abs(lst - t_opt) / t_opt))
}

#' @title Clearing Stagnation Index (IEAD)
#' @description Detects puddles in recently cleared or deforested areas.
#' @param grad_delta_ndvi SpatRaster. Gradient of NDVI change.
#' @param depressions_dsm SpatRaster. Topographic depressions from DSM.
#' @param red_edge SpatRaster. Red Edge band.
#' @return A SpatRaster highlighting stagnation in clearings.
#' @export
d4h_iead <- function(grad_delta_ndvi, depressions_dsm, red_edge) {
  grad_delta_ndvi * depressions_dsm * red_edge
}

#' @title Spectral Water Retention Index (IRHE)
#' @description Highlights stable, cold water bodies with low evaporation rates.
#' @param green SpatRaster. Green band.
#' @param nir SpatRaster. Near-infrared band.
#' @param lst SpatRaster. Land Surface Temperature.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster representing water retention potential.
#' @export
d4h_irhe <- function(green, nir, lst, eps = 0.001) {
  ndwi <- (green - nir) / (green + nir + eps)
  ndwi * (1 / (lst + eps))
}

#' @title Fragmentation and Edge Effect Index (IFEB)
#' @description Quantifies ecological transitions and borders between vegetation and urban/cleared soil.
#' @param grad_red_edge SpatRaster. Focal standard deviation of the Red Edge band.
#' @param red SpatRaster. Red band.
#' @param nir SpatRaster. Near-infrared band.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster quantifying edge effects.
#' @export
d4h_ifeb <- function(grad_red_edge, red, nir, eps = 0.001) {
  abs(grad_red_edge) * (red / (nir + eps))
}

#' @title Human Interface Roughness Index (IRIH)
#' @description Measures canopy structural heterogeneity in the forest-household interface.
#' @param var_re_nir SpatRaster. Local variance of the RE/NIR ratio.
#' @param red SpatRaster. Red band.
#' @param green SpatRaster. Green band.
#' @param eps Numeric. Small epsilon to prevent division by zero.
#' @return A SpatRaster representing structural roughness.
#' @export
d4h_irih <- function(var_re_nir, red, green, eps = 0.001) {
  var_re_nir * (red / (green + eps))
}
