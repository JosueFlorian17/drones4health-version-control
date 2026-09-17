#' @importFrom terra rast compareGeom project resample clamp datatype spatSample writeRaster extract as.polygons ext crs classify terrain
#' @importFrom ggplot2 ggplot aes geom_tile geom_sf scale_fill_viridis_c scale_fill_gradientn scale_fill_continuous coord_sf theme_minimal theme element_blank labs
#' @importFrom sf st_as_sf st_make_grid st_sf
#' @importFrom tibble tibble as_tibble tribble
NULL

.read_and_calibrate_band <- function(x, scale = NULL) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop(paste("File not found:", x), call. = FALSE)
    x <- terra::rast(x)
  }
  if (!inherits(x, "SpatRaster")) {
    stop("Input must be a file path to a TIFF or a SpatRaster object.", call. = FALSE)
  }

  lyr <- x[[1]]
  lyr <- terra::classify(lyr, cbind(-Inf, 0, NA))

  if (is.null(scale)) {
    type <- terra::datatype(lyr)
    if (grepl("INT2U", type, ignore.case = TRUE)) {
      scale <- 65535
    } else {
      sample_vals <- terra::spatSample(lyr, size = 500, na.rm = TRUE)
      max_val <- if (nrow(sample_vals) > 0) max(sample_vals[, 1], na.rm = TRUE) else 1
      scale <- if (is.finite(max_val) && max_val > 1) 65535 else 1
    }
  }

  if (scale > 1) {
    lyr <- lyr / scale
  }

  lyr
}

.align_two_bands <- function(r1, r2) {
  if (!terra::compareGeom(r1, r2, stopOnError = FALSE)) {
    if (!terra::same.crs(r1, r2)) {
      r2 <- terra::project(r2, r1, method = "bilinear")
    }
    r2 <- terra::resample(r2, r1, method = "bilinear")
  }
  list(r1, r2)
}

#' @title Normalize Digital Numbers to Surface Reflectance
#' @description Scales raw 16-bit or 8-bit digital numbers to a 0-1 reflectance range.
#' @param raster_layer Character or SpatRaster. Raw input band or path to file.
#' @param scale_factor Numeric. Divisor to scale the raster (default: 65535).
#' @return A SpatRaster clamped between 0 and 1.
#' @export
d4h_normalize_reflectance <- function(raster_layer, scale_factor = 65535) {
  r <- .read_and_calibrate_band(raster_layer, scale = scale_factor)
  terra::clamp(r, lower = 0, upper = 1)
}

#' @title Clean Raster Band Artefacts
#' @description Replaces NaN and Infinite values with NA and clamps the raster to physically valid limits.
#' @param raster_layer SpatRaster. Input band to clean.
#' @param min_val Numeric. Minimum valid value (default: -1).
#' @param max_val Numeric. Maximum valid value (default: 1).
#' @return A cleaned SpatRaster.
#' @export
d4h_clean_band <- function(raster_layer, min_val = -1, max_val = 1) {
  raster_layer[is.nan(raster_layer) | is.infinite(raster_layer)] <- NA
  terra::clamp(raster_layer, lower = min_val, upper = max_val)
}
