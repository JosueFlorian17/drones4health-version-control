#' @title Normalized Difference Vegetation Index (NDVI)
#' @description Calculates NDVI to quantify photosynthetic activity and vegetation vigor from SpatRaster objects or file paths.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @return A SpatRaster containing NDVI values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_ndvi <- function(nir, red) {
  pair <- .match_pair(nir, red, mask_zeros = TRUE)
  n <- pair$ref
  r <- pair$sub

  den <- n + r
  res <- (n - r) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDVI"
  res
}

#' @title Difference Vegetation Index (DVI)
#' @description Calculates DVI as the simple difference between NIR and Red reflectance.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @return A SpatRaster containing DVI values with background masked to NA.
#' @export
d4h_dvi <- function(nir, red) {
  pair <- .match_pair(nir, red, mask_zeros = TRUE)
  n <- pair$ref
  r <- pair$sub

  res <- n - r
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA

  names(res) <- "DVI"
  res
}

#' @title Soil Adjusted Vegetation Index (SAVI)
#' @description Calculates SAVI to minimize soil brightness influences in sparse canopy areas.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param l_factor Numeric. Soil adjustment factor (default: 0.5).
#' @return A SpatRaster containing SAVI values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_savi <- function(nir, red, l_factor = 0.5) {
  pair <- .match_pair(nir, red, mask_zeros = TRUE)
  n <- pair$ref
  r <- pair$sub

  den <- n + r + l_factor
  res <- ((n - r) / den) * (1 + l_factor)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "SAVI"
  res
}

#' @title Modified Soil Adjusted Vegetation Index 2 (MSAVI2)
#' @description Computes MSAVI2 to evaluate vegetation cover in sparse or arid canopies without requiring an empirical soil adjustment factor.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @return A SpatRaster containing MSAVI2 values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_msavi2 <- function(nir, red) {
  pair <- .match_pair(nir, red, mask_zeros = TRUE)
  n <- pair$ref
  r <- pair$sub

  # Normalizacion a reflectancia [0, 1] si viene en enteros de 16 bits
  max_sample <- max(terra::spatSample(n, size = 100, na.rm = TRUE)[, 1], na.rm = TRUE)
  if (is.finite(max_sample) && max_sample > 1) {
    n <- n / 65535
    r <- r / 65535
  }

  term_sqrt <- (2 * n + 1)^2 - 8 * (n - r)
  term_sqrt[term_sqrt < 0] <- NA

  res <- (2 * n + 1 - sqrt(term_sqrt)) / 2
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)

  names(res) <- "MSAVI2"
  res
}

#' @title Visible Atmospherically Resistant Index (VARI)
#' @description Computes VARI to assess vegetation fraction while minimizing atmospheric and illumination sensitivity.
#' @param green SpatRaster or character. Green band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param blue SpatRaster or character. Blue band (or Red Edge / NIR if Blue unavailable) or path to file.
#' @param eps Numeric. Small epsilon to prevent zero division (default: 0.001).
#' @return A SpatRaster containing VARI values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_vari <- function(green, red, blue, eps = 0.001) {
  aligned <- .match_multi(green, red, blue, mask_zeros = TRUE)
  g <- aligned[[1]]
  r <- aligned[[2]]
  b <- aligned[[3]]

  den <- g + r - b + eps
  res <- (g - r) / den
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)

  names(res) <- "VARI"
  res
}

#' @title Enhanced Vegetation Index (EVI)
#' @description Calculates EVI optimized for high biomass canopy regions.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param blue SpatRaster or character. Blue band or path to file.
#' @param g_factor Numeric. Gain factor (default: 2.5).
#' @param c1 Numeric. Aerosol resistance coefficient 1 (default: 6).
#' @param c2 Numeric. Aerosol resistance coefficient 2 (default: 7.5).
#' @param l_factor Numeric. Canopy background adjustment (default: 1).
#' @return A SpatRaster containing EVI values with background masked to NA.
#' @export
d4h_evi <- function(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1) {
  aligned <- .match_multi(nir, red, blue, mask_zeros = TRUE)
  n <- aligned[[1]]
  r <- aligned[[2]]
  b <- aligned[[3]]

  den <- n + (c1 * r) - (c2 * b) + l_factor
  res <- g_factor * ((n - r) / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "EVI"
  res
}

#' @title Normalized Difference Water Index (NDWI)
#' @description Calculates NDWI to detect open surface water bodies and moisture accumulation.
#' @param green SpatRaster or character. Green band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @return A SpatRaster containing NDWI values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_ndwi <- function(green, nir) {
  pair <- .match_pair(green, nir, mask_zeros = TRUE)
  g <- pair$ref
  n <- pair$sub

  den <- g + n
  res <- (g - n) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDWI"
  res
}

#' @title Normalized Difference Red Edge Index (NDRE)
#' @description Calculates NDRE to assess canopy chlorophyll content and plant health using the Red Edge band.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @return A SpatRaster containing NDRE values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_ndre <- function(nir, red_edge) {
  pair <- .match_pair(nir, red_edge, mask_zeros = TRUE)
  n  <- pair$ref
  re <- pair$sub

  den <- n + re
  res <- (n - re) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "NDRE"
  res
}

#' @title Green Normalized Difference Vegetation Index (GNDVI)
#' @description Calculates GNDVI for estimating chlorophyll concentration.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param green SpatRaster or character. Green band or path to file.
#' @return A SpatRaster containing GNDVI values in \code{[-1, 1]} with background masked to NA.
#' @export
d4h_gndvi <- function(nir, green) {
  pair <- .match_pair(nir, green, mask_zeros = TRUE)
  n <- pair$ref
  g <- pair$sub

  den <- n + g
  res <- (n - g) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  res <- terra::clamp(res, lower = -1, upper = 1)
  names(res) <- "GNDVI"
  res
}

#' @title Corrected Transformed Vegetation Index (CTVI)
#' @description Calculates CTVI to normalize vegetation index distributions.
#' @param ndvi_raster SpatRaster or character. Input NDVI layer or path to file.
#' @return A SpatRaster containing CTVI values with background masked to NA.
#' @export
d4h_ctvi <- function(ndvi_raster) {
  r <- .ensure_raster(ndvi_raster, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r) | r == 0] <- NA
  res <- (r + 0.5) / sqrt(abs(r + 0.5))
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "CTVI"
  res
}

#' @title Bare Soil Mask
#' @description Generates a binary mask of bare or exposed soil based on an NDVI threshold.
#' @param ndvi_raster SpatRaster or character. Input NDVI layer or path to file.
#' @param threshold Numeric. Value below which pixels are classified as bare soil (default: 0.15).
#' @return A binary SpatRaster (1 = bare soil, 0 = vegetation/water) with background masked to NA.
#' @export
d4h_bare_soil <- function(ndvi_raster, threshold = 0.15) {
  r <- .ensure_raster(ndvi_raster, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r) | r == 0] <- NA
  mask <- terra::ifel(r < threshold, 1, 0)
  mask[is.na(r)] <- NA
  names(mask) <- "bare_soil_mask"
  mask
}
