#' @title Continuous Vulnerability Stagnation Indicator (General Area)
#' @description Identifies micro-stagnation areas with high vector breeding suitability by combining moisture (NDWI) and terrain slope.
#' @param ndwi Character or SpatRaster. NDWI layer or path to file.
#' @param dem Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing continuous IEV stagnation risk values.
#' @export
d4h_iev_general <- function(ndwi, dem, eps = 0.001) {
  if (is.character(ndwi) && length(ndwi) == 1L) ndwi <- terra::rast(ndwi)
  if (is.character(dem) && length(dem) == 1L) dem <- terra::rast(dem)

  if (!inherits(ndwi, "SpatRaster") || !inherits(dem, "SpatRaster")) {
    stop("'ndwi' and 'dem' must be SpatRaster objects or valid file paths.", call. = FALSE)
  }

  slope_dem <- terra::terrain(dem[[1]], v = "slope", unit = "degrees")
  aligned   <- .align_two_bands(ndwi[[1]], slope_dem)
  ndwi_lyr  <- aligned[[1]]
  slope_lyr <- aligned[[2]]

  iev <- ndwi_lyr * (1 / (slope_lyr + eps))
  iev[is.infinite(iev) | is.nan(iev)] <- NA
  names(iev) <- "IEV"
  iev
}

#' @title Vulnerability Stagnation Indicator (IEV)
#' @description Calculates Vulnerability Stagnation Indicator with optional zonal grid summarization.
#' @param ndwi Character or SpatRaster. NDWI layer or path to file.
#' @param dem Character or SpatRaster. Digital Elevation/Surface Model (DEM/DSM) or path to file.
#' @param cell_size Numeric. Optional cell size in meters. If NULL, returns continuous raster (default: NULL).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is numeric).
#' @export
d4h_iev <- function(ndwi, dem, cell_size = NULL, square = TRUE, eps = 0.001) {
  iev_raster <- d4h_iev_general(ndwi = ndwi, dem = dem, eps = eps)

  if (!is.null(cell_size)) {
    return(d4h_summarize_grid(iev_raster, cell_size = cell_size, square = square))
  }

  iev_raster
}

#' @title Continuous Synthetic Materials Risk Index (General Area)
#' @description Detects non-natural materials (plastics, rubber, tires) that serve as potential mosquito breeding containers.
#' @param red_edge Character or SpatRaster. Red Edge band or path to file.
#' @param red Character or SpatRaster. Red band or path to file.
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param veg_threshold Numeric. Threshold to differentiate vegetation from synthetics (default: 0.2).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @param scale Numeric. Divisor to normalize pixel values (default: NULL).
#' @return A SpatRaster containing continuous IMSR risk values.
#' @export
d4h_imsr_general <- function(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001, scale = NULL) {
  re <- .read_and_calibrate_band(red_edge, scale = scale)
  r  <- .read_and_calibrate_band(red, scale = scale)
  n  <- .read_and_calibrate_band(nir, scale = scale)

  aligned1 <- .align_two_bands(re, r)
  re <- aligned1[[1]]
  r  <- aligned1[[2]]

  aligned2 <- .align_two_bands(re, n)
  re <- aligned2[[1]]
  n  <- aligned2[[2]]

  ndre_approx <- (re - r) / (re + r + eps)
  imsr        <- abs(ndre_approx - veg_threshold) * n

  imsr[is.infinite(imsr) | is.nan(imsr)] <- NA
  names(imsr) <- "IMSR"
  imsr
}

#' @title Synthetic Materials Risk Index (IMSR)
#' @description Calculates Synthetic Materials Risk Index with optional zonal grid summarization.
#' @param red_edge Character or SpatRaster. Red Edge band or path to file.
#' @param red Character or SpatRaster. Red band or path to file.
#' @param nir Character or SpatRaster. Near-infrared band or path to file.
#' @param veg_threshold Numeric. Threshold to differentiate vegetation from synthetics (default: 0.2).
#' @param cell_size Numeric. Optional cell size in meters. If NULL, returns continuous raster (default: NULL).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @param scale Numeric. Divisor to normalize pixel values (default: NULL).
#' @return A SpatRaster (if cell_size = NULL) or SpatVector (if cell_size is numeric).
#' @export
d4h_imsr <- function(red_edge, red, nir, veg_threshold = 0.2, cell_size = NULL, square = TRUE, eps = 0.001, scale = NULL) {
  imsr_raster <- d4h_imsr_general(
    red_edge = red_edge, red = red, nir = nir,
    veg_threshold = veg_threshold, eps = eps, scale = scale
  )

  if (!is.null(cell_size)) {
    return(d4h_summarize_grid(imsr_raster, cell_size = cell_size, square = square))
  }

  imsr_raster
}
