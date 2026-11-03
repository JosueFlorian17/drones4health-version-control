#' @importFrom terra rast compareGeom project resample clamp datatype spatSample writeRaster extract as.polygons ext crs classify terrain aggregate ncell plot ifel vect same.crs global
#' @importFrom ggplot2 ggplot aes geom_raster geom_sf geom_col geom_errorbar scale_fill_viridis_c scale_fill_viridis_d scale_fill_gradientn scale_fill_continuous coord_sf theme_minimal theme element_blank element_rect labs
#' @importFrom sf st_as_sf st_make_grid st_sf
#' @importFrom stats quantile
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

  # Normalización radiométrica automática si una banda es 8-bit (0-255) y la otra es 16-bit (0-65535)
  max_ref <- suppressWarnings(terra::minmax(ref)[2, 1])
  max_sub <- suppressWarnings(terra::minmax(sub)[2, 1])
  if (is.na(max_ref) || is.infinite(max_ref) || is.na(max_sub) || is.infinite(max_sub)) {
    s_ref <- terra::spatSample(ref, size = 500, na.rm = TRUE)
    s_sub <- terra::spatSample(sub, size = 500, na.rm = TRUE)
    max_ref <- if (nrow(s_ref) > 0) max(s_ref[, 1], na.rm = TRUE) else 1
    max_sub <- if (nrow(s_sub) > 0) max(s_sub[, 1], na.rm = TRUE) else 1
  }

  if (max_ref > 1000 && max_sub <= 255) {
    # ref es 16-bit, sub es 8-bit -> normalizar sub a la escala de ref
    sub <- sub * (max_ref / 255)
  } else if (max_sub > 1000 && max_ref <= 255) {
    # sub es 16-bit, ref es 8-bit -> normalizar ref a la escala de sub
    ref <- ref * (max_sub / 255)
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
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Path to raw 16-bit digital number raster band
#'   raw_nir <- system.file("extdata", "nir_raw16.tif", package = "drones4health")
#'
#'   # Normalize pixel values to 0-1 reflectance scale
#'   r_norm <- d4h_normalize_reflectance(raster_layer = raw_nir, scale_factor = 65535)
#'   print(r_norm)
#' }
#' }
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
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Path to raw radiometric thermal band
#'   therm_file <- system.file("extdata", "thermal_raw.tif", package = "drones4health")
#'
#'   # Calibrate raw thermal digital numbers to Celsius Land Surface Temperature
#'   r_lst <- d4h_thermal_to_celsius(thermal_raster = therm_file, gain = 0.01, offset = -273.15)
#'   print(r_lst)
#' }
#' }
#' @export
d4h_thermal_to_celsius <- function(thermal_raster, gain = 0.01, offset = -273.15) {
  r <- .ensure_raster(thermal_raster, mask_zeros = FALSE)
  r[r <= 0] <- NA
  res <- (r * gain) + offset
  res[is.infinite(res) | is.nan(res)] <- NA
  names(res) <- "LST_Celsius"
  res
}
