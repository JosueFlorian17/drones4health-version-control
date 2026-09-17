# Helpers internos para validación, carga y alineación automática
.ensure_raster <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop(paste("File does not exist:", x), call. = FALSE)
    x <- terra::rast(x)
  }
  if (!inherits(x, "SpatRaster")) {
    stop("Input must be a SpatRaster object or a valid file path.", call. = FALSE)
  }
  x[[1]]
}

.match_pair <- function(r_ref, r_sub) {
  r_ref <- .ensure_raster(r_ref)
  r_sub <- .ensure_raster(r_sub)

  if (!terra::compareGeom(r_ref, r_sub, stopOnError = FALSE)) {
    if (!terra::same.crs(r_ref, r_sub)) {
      r_sub <- terra::project(r_sub, r_ref, method = "bilinear")
    }
    r_sub <- terra::resample(r_sub, r_ref, method = "bilinear")
  }
  list(ref = r_ref, sub = r_sub)
}

#' @title Normalized Difference Vegetation Index (NDVI)
#' @description Calculates NDVI from SpatRaster objects or file paths, auto-aligning geometries.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param red SpatRaster or character. Red band.
#' @return A SpatRaster containing NDVI values.
#' @export
d4h_ndvi <- function(nir, red) {
  pair <- .match_pair(nir, red)
  n <- pair$ref
  r <- pair$sub

  den <- n + r
  res <- (n - r) / den
  res[den <= 0 | is.infinite(res) | is.nan(res)] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDVI"
  res
}

#' @title Soil Adjusted Vegetation Index (SAVI)
#' @description Calculates SAVI, correcting for soil brightness with automatic band alignment.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param red SpatRaster or character. Red band.
#' @param l_factor Numeric. Soil brightness correction factor (default: 0.5).
#' @return A SpatRaster containing SAVI values.
#' @export
d4h_savi <- function(nir, red, l_factor = 0.5) {
  pair <- .match_pair(nir, red)
  n <- pair$ref
  r <- pair$sub

  den <- n + r + l_factor
  res <- ((n - r) / den) * (1 + l_factor)
  res[den <= 0 | is.infinite(res) | is.nan(res)] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "SAVI"
  res
}

#' @title Enhanced Vegetation Index (EVI)
#' @description Calculates EVI for dense canopy backgrounds with automatic band alignment.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param red SpatRaster or character. Red band.
#' @param blue SpatRaster or character. Blue band.
#' @param g_factor Numeric. Gain factor (default: 2.5).
#' @param c1 Numeric. Aerosol resistance coefficient 1 (default: 6).
#' @param c2 Numeric. Aerosol resistance coefficient 2 (default: 7.5).
#' @param l_factor Numeric. Canopy background adjustment (default: 1).
#' @return A SpatRaster containing EVI values.
#' @export
d4h_evi <- function(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1) {
  p1 <- .match_pair(nir, red)
  p2 <- .match_pair(p1$ref, blue)

  n <- p1$ref
  r <- p1$sub
  b <- p2$sub

  den <- n + (c1 * r) - (c2 * b) + l_factor
  res <- g_factor * ((n - r) / den)
  res[is.infinite(res) | is.nan(res)] <- NA
  names(res) <- "EVI"
  res
}

#' @title Normalized Difference Water Index (NDWI)
#' @description Calculates NDWI to identify water bodies and moisture with automatic alignment.
#' @param green SpatRaster or character. Green band.
#' @param nir SpatRaster or character. Near-infrared band.
#' @return A SpatRaster containing NDWI values.
#' @export
d4h_ndwi <- function(green, nir) {
  pair <- .match_pair(green, nir)
  g <- pair$ref
  n <- pair$sub

  den <- g + n
  res <- (g - n) / den
  res[den <= 0 | is.infinite(res) | is.nan(res)] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDWI"
  res
}

#' @title Normalized Difference Red Edge Index (NDRE)
#' @description Calculates NDRE using the Red Edge band with automatic alignment.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param red_edge SpatRaster or character. Red Edge band.
#' @return A SpatRaster containing NDRE values.
#' @export
d4h_ndre <- function(nir, red_edge) {
  pair <- .match_pair(nir, red_edge)
  n  <- pair$ref
  re <- pair$sub

  den <- n + re
  res <- (n - re) / den
  res[den <= 0 | is.infinite(res) | is.nan(res)] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDRE"
  res
}

#' @title Green Normalized Difference Vegetation Index (GNDVI)
#' @description Calculates GNDVI for chlorophyll concentration estimation with automatic alignment.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param green SpatRaster or character. Green band.
#' @return A SpatRaster containing GNDVI values.
#' @export
d4h_gndvi <- function(nir, green) {
  pair <- .match_pair(nir, green)
  n <- pair$ref
  g <- pair$sub

  den <- n + g
  res <- (n - g) / den
  res[den <= 0 | is.infinite(res) | is.nan(res)] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "GNDVI"
  res
}

#' @title Difference Vegetation Index (DVI)
#' @description Calculates DVI with automatic band alignment.
#' @param nir SpatRaster or character. Near-infrared band.
#' @param red SpatRaster or character. Red band.
#' @return A SpatRaster containing DVI values.
#' @export
d4h_dvi <- function(nir, red) {
  pair <- .match_pair(nir, red)
  res <- pair$ref - pair$sub
  names(res) <- "DVI"
  res
}

#' @title Corrected Transformed Vegetation Index (CTVI)
#' @description Calculates CTVI to normalize vegetation distributions.
#' @param ndvi_raster SpatRaster or character. NDVI input layer or path.
#' @return A SpatRaster containing CTVI values.
#' @export
d4h_ctvi <- function(ndvi_raster) {
  r <- .ensure_raster(ndvi_raster)
  res <- (r + 0.5) / sqrt(abs(r + 0.5))
  names(res) <- "CTVI"
  res
}

#' @title Bare Soil Mask
#' @description Generates a binary mask of bare or exposed soil based on an NDVI threshold.
#' @param ndvi_raster SpatRaster or character. NDVI input layer or path.
#' @param threshold Numeric. Value below which pixels are classified as bare soil (default: 0.15).
#' @return A binary SpatRaster (1 = bare soil, 0 = vegetation/water).
#' @export
d4h_bare_soil <- function(ndvi_raster, threshold = 0.15) {
  r <- .ensure_raster(ndvi_raster)
  terra::ifel(r < threshold, 1, 0)
}
