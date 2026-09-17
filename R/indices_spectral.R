#' @title Continuous Normalized Difference Vegetation Index (General Area)
#' @description Computes continuous NDVI for the entire survey extent without grid aggregation.
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param red Character or SpatRaster. Red band or path to file.
#' @param scale Numeric. Divisor to normalize pixel values to 0-1 (default: auto-detected or 65535).
#' @return A SpatRaster containing continuous NDVI values bounded in [-1, 1].
#' @export
d4h_ndvi_general <- function(nir, red, scale = NULL) {
  n <- .read_and_calibrate_band(nir, scale = scale)
  r <- .read_and_calibrate_band(red, scale = scale)

  aligned <- .align_two_bands(n, r)
  n <- aligned[[1]]
  r <- aligned[[2]]

  denominator <- n + r
  numerator   <- n - r
  ndvi        <- numerator / denominator

  ndvi[denominator <= 0 | is.infinite(ndvi) | is.nan(ndvi) | is.na(n) | is.na(r)] <- NA
  ndvi <- terra::clamp(ndvi, lower = -1, upper = 1)
  ndvi[ndvi == 0] <- NA

  ndvi <- terra::mask(ndvi, n)
  ndvi <- terra::mask(ndvi, r)

  names(ndvi) <- "NDVI"
  ndvi
}

#' @title Normalized Difference Vegetation Index (NDVI)
#' @description Calculates NDVI with optional zonal grid summarization (square or hexagonal).
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param red Character or SpatRaster. Red band or path to file.
#' @param cell_size Numeric. Optional cell size in meters. If NULL, returns continuous raster (default: NULL).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param scale Numeric. Divisor to normalize pixel values (default: NULL).
#' @return A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is numeric).
#' @export
d4h_ndvi <- function(nir, red, cell_size = NULL, square = TRUE, scale = NULL) {
  ndvi_raster <- d4h_ndvi_general(nir = nir, red = red, scale = scale)

  if (!is.null(cell_size)) {
    return(d4h_summarize_grid(ndvi_raster, cell_size = cell_size, square = square))
  }

  ndvi_raster
}

#' @title Continuous Normalized Difference Water Index (General Area)
#' @description Computes continuous NDWI for the entire survey extent to identify surface water and moisture.
#' @param green Character or SpatRaster. Green band or path to file.
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param scale Numeric. Divisor to normalize pixel values (default: auto-detected or 65535).
#' @return A SpatRaster containing continuous NDWI values bounded in [-1, 1].
#' @export
d4h_ndwi_general <- function(green, nir, scale = NULL) {
  g <- .read_and_calibrate_band(green, scale = scale)
  n <- .read_and_calibrate_band(nir, scale = scale)

  aligned <- .align_two_bands(g, n)
  g <- aligned[[1]]
  n <- aligned[[2]]

  denominator <- g + n
  numerator   <- g - n
  ndwi        <- numerator / denominator

  ndwi[denominator <= 0 | is.infinite(ndwi) | is.nan(ndwi) | is.na(g) | is.na(n)] <- NA
  ndwi <- terra::clamp(ndwi, lower = -1, upper = 1)
  ndwi[ndwi == 0] <- NA

  ndwi <- terra::mask(ndwi, g)
  ndwi <- terra::mask(ndwi, n)

  names(ndwi) <- "NDWI"
  ndwi
}

#' @title Normalized Difference Water Index (NDWI)
#' @description Calculates NDWI with optional zonal grid summarization (square or hexagonal).
#' @param green Character or SpatRaster. Green band or path to file.
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param cell_size Numeric. Optional cell size in meters. If NULL, returns continuous raster (default: NULL).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param scale Numeric. Divisor to normalize pixel values (default: NULL).
#' @return A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is numeric).
#' @export
d4h_ndwi <- function(green, nir, cell_size = NULL, square = TRUE, scale = NULL) {
  ndwi_raster <- d4h_ndwi_general(green = green, nir = nir, scale = scale)

  if (!is.null(cell_size)) {
    return(d4h_summarize_grid(ndwi_raster, cell_size = cell_size, square = square))
  }

  ndwi_raster
}
