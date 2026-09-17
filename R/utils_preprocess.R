#' @importFrom terra rast compareGeom project resample clamp datatype spatSample writeRaster extract as.polygons ext crs classify terrain aggregate ncell plot ifel vect same.crs
#' @importFrom ggplot2 ggplot aes geom_raster geom_sf scale_fill_viridis_c scale_fill_gradientn scale_fill_continuous coord_sf theme_minimal theme element_blank labs
#' @importFrom sf st_as_sf st_make_grid st_sf
#' @importFrom tibble tibble as_tibble tribble
NULL

.ensure_raster <- function(x, mask_zeros = FALSE) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) {
      stop(paste("File not found:", x), call. = FALSE)
    }
    x <- terra::rast(x)
  }

  if (!inherits(x, "SpatRaster")) {
    stop("Input must be a terra SpatRaster object or a valid file path string.", call. = FALSE)
  }

  layer <- x[[1]]

  if (mask_zeros) {
    layer[layer <= 0] <- NA
  }

  layer
}

.ensure_spatial <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) {
      stop(paste("File not found:", x), call. = FALSE)
    }
    x <- terra::rast(x)
  }
  x
}

.match_pair <- function(r_ref, r_sub, mask_zeros = FALSE) {
  ref <- .ensure_raster(r_ref, mask_zeros = mask_zeros)
  sub <- .ensure_raster(r_sub, mask_zeros = mask_zeros)

  if (!terra::compareGeom(ref, sub, stopOnError = FALSE)) {
    if (!terra::same.crs(ref, sub)) {
      sub <- terra::project(sub, ref, method = "bilinear")
    }
    sub <- terra::resample(sub, ref, method = "bilinear")
  }

  list(ref = ref, sub = sub)
}

.match_multi <- function(r_ref, ..., mask_zeros = FALSE) {
  ref <- .ensure_raster(r_ref, mask_zeros = mask_zeros)
  others <- list(...)

  aligned <- lapply(others, function(item) {
    sub <- .ensure_raster(item, mask_zeros = mask_zeros)
    if (!terra::compareGeom(ref, sub, stopOnError = FALSE)) {
      if (!terra::same.crs(ref, sub)) {
        sub <- terra::project(sub, ref, method = "bilinear")
      }
      sub <- terra::resample(sub, ref, method = "bilinear")
    }
    sub
  })

  c(list(ref), aligned)
}

#' @title Normalize Digital Numbers to Surface Reflectance
#' @description Scales raw 16-bit or 8-bit digital numbers to a 0-1 reflectance range and masks zeros to NA.
#' @param raster_layer SpatRaster or character. Input band or path to file.
#' @param scale_factor Numeric. Divisor to scale the raster (default: 65535).
#' @return A SpatRaster clamped between 0 and 1 with zeros masked as NA.
#' @export
d4h_normalize_reflectance <- function(raster_layer, scale_factor = 65535) {
  r <- .ensure_raster(raster_layer, mask_zeros = TRUE)
  r <- r / scale_factor
  r <- terra::clamp(r, lower = 0, upper = 1)
  r[r == 0] <- NA
  r
}

#' @title Convert Thermal Band to Celsius
#' @description Calibrates a raw thermal infrared band to Land Surface Temperature (LST) in degrees Celsius.
#' @param thermal_raster SpatRaster or character. Thermal band or path to file.
#' @param gain Numeric. Calibration gain multiplier (default: 0.01).
#' @param offset Numeric. Calibration offset value (default: -273.15).
#' @return A SpatRaster representing temperature in degrees Celsius.
#' @export
d4h_thermal_to_celsius <- function(thermal_raster, gain = 0.01, offset = -273.15) {
  r <- .ensure_raster(thermal_raster, mask_zeros = FALSE)
  r[r <= 0] <- NA
  res <- (r * gain) + offset
  res[is.infinite(res) | is.nan(res)] <- NA
  names(res) <- "LST_Celsius"
  res
}

#' @title Clean Raster Band Artefacts
#' @description Replaces non-finite and zero values with NA and clamps the raster to valid bio-physical limits.
#' @param raster_layer SpatRaster or character. Input band or path to file.
#' @param min_val Numeric. Minimum valid value (default: -1).
#' @param max_val Numeric. Maximum valid value (default: 1).
#' @return A cleaned SpatRaster.
#' @export
d4h_clean_band <- function(raster_layer, min_val = -1, max_val = 1) {
  r <- .ensure_raster(raster_layer, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r) | r == 0] <- NA
  terra::clamp(r, lower = min_val, upper = max_val)
}
