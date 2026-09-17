#' @title Normalize Digital Numbers to Surface Reflectance
#' @description Scales raw 16-bit or 8-bit digital numbers to a 0-1 reflectance range.
#' @param raster_layer SpatRaster. The raw input band.
#' @param scale_factor Numeric. The divisor to scale the raster (default: 65535).
#' @return A SpatRaster clamped between 0 and 1.
#' @export
d4h_normalize_reflectance <- function(raster_layer, scale_factor = 65535) {
  terra::clamp(raster_layer / scale_factor, lower = 0, upper = 1)
}

#' @title Convert Thermal Band to Celsius
#' @description Calibrates a raw thermal infrared band to Land Surface Temperature (LST) in degrees Celsius.
#' @param thermal_raster SpatRaster. The thermal band.
#' @param gain Numeric. Calibration gain multiplier.
#' @param offset Numeric. Calibration offset value.
#' @return A SpatRaster representing temperature in Celsius.
#' @export
d4h_thermal_to_celsius <- function(thermal_raster, gain = 0.01, offset = -273.15) {
  (thermal_raster * gain) + offset
}

#' @title Clean Raster Band Artefacts
#' @description Replaces NaN and Infinite values with NA and clamps the raster to physically valid limits.
#' @param raster_layer SpatRaster. The input band to clean.
#' @param min_val Numeric. Minimum valid value.
#' @param max_val Numeric. Maximum valid value.
#' @return A cleaned SpatRaster.
#' @export
d4h_clean_band <- function(raster_layer, min_val = -1, max_val = 1) {
  raster_layer[is.nan(raster_layer) | is.infinite(raster_layer)] <- NA
  terra::clamp(raster_layer, lower = min_val, upper = max_val)
}
