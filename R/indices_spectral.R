#' @title Normalized Difference Vegetation Index (NDVI)
#' @description Calculates the Normalized Difference Vegetation Index (NDVI) to quantify photosynthetic activity, biomass density, and vegetative vigor from UAV imagery.
#' @details The Normalized Difference Vegetation Index is computed according to the formula:
#' \deqn{\text{NDVI} = \frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red}}}
#' Pixel values are clamped to \code{[-1, 1]} with background non-data values masked to \code{NA}.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @return A SpatRaster containing NDVI values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Rouse, J. W., Haas, R. H., Schell, J. A., & Deering, D. W. (1974). Monitoring vegetation systems in the Great Plains with ERTS. \emph{NASA Special Publication}, 351, 309-317.
#'
#' Tucker, C. J. (1979). Red and photographic infrared linear combinations for monitoring vegetation. \emph{Remote Sensing of Environment}, 8(2), 127-150. \doi{10.1016/0034-4257(79)90013-0}
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
#' @description Calculates the Difference Vegetation Index (DVI) as the simple linear difference between Near-Infrared and Red reflectance.
#' @details The Difference Vegetation Index is computed as:
#' \deqn{\text{DVI} = \text{NIR} - \text{Red}}
#' Sensitive to variations in canopy biomass and leaf area index (LAI).
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @return A SpatRaster containing DVI values with background masked to \code{NA}.
#' @references
#' Tucker, C. J. (1979). Red and photographic infrared linear combinations for monitoring vegetation. \emph{Remote Sensing of Environment}, 8(2), 127-150.
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

#' @title Soil-Adjusted Vegetation Index (SAVI)
#' @description Calculates the Soil-Adjusted Vegetation Index (SAVI) to minimize soil brightness background effects in sparse or arid vegetation canopies.
#' @details The Soil-Adjusted Vegetation Index is defined as:
#' \deqn{\text{SAVI} = \frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red} + L} \times (1 + L)}
#' where \eqn{L} is a canopy background adjustment factor typically set to \eqn{L = 0.5} for intermediate vegetation densities.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param l_factor Numeric. Soil adjustment factor \eqn{L} (default: 0.5).
#' @return A SpatRaster containing SAVI values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Huete, A. R. (1988). A soil-adjusted vegetation index (SAVI). \emph{Remote Sensing of Environment}, 25(3), 295-309. \doi{10.1016/0034-4257(88)90106-X}
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

#' @title Modified Soil-Adjusted Vegetation Index 2 (MSAVI2)
#' @description Computes the Modified Soil-Adjusted Vegetation Index 2 (MSAVI2) for evaluating vegetation cover in sparse, arid, or degraded landscapes without requiring an empirical soil adjustment factor.
#' @details The Modified Soil-Adjusted Vegetation Index 2 utilizes an inductive equation based on the soil line:
#' \deqn{\text{MSAVI2} = \frac{2 \cdot \text{NIR} + 1 - \sqrt{(2 \cdot \text{NIR} + 1)^2 - 8 \cdot (\text{NIR} - \text{Red})}}{2}}
#' It dynamically adjusts for soil brightness variations across complex terrain.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @return A SpatRaster containing MSAVI2 values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Qi, J., Chehbouni, A., Huete, A. R., Kerr, Y. H., & Sorooshian, S. (1994). A modified soil adjusted vegetation index. \emph{Remote Sensing of Environment}, 48(2), 119-126. \doi{10.1016/0034-4257(94)90134-1}
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
#' @description Computes the Visible Atmospherically Resistant Index (VARI) to estimate vegetation fraction from visible RGB channels with minimal sensitivity to atmospheric aerosols and illumination differences.
#' @details The Visible Atmospherically Resistant Index is formulated as:
#' \deqn{\text{VARI} = \frac{\text{Green} - \text{Red}}{\text{Green} + \text{Red} - \text{Blue} + \epsilon}}
#' where \eqn{\epsilon} is a small numerical stabilization constant.
#' @param green SpatRaster or character. Green band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param blue SpatRaster or character. Blue band (or Red Edge / NIR if Blue unavailable) or path to file.
#' @param eps Numeric. Small epsilon to prevent zero division (default: 0.001).
#' @return A SpatRaster containing VARI values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Gitelson, A. A., Kaufman, Y. J., Stark, R., & Rundquist, D. (2002). Novel algorithms for remote estimation of vegetation fraction. \emph{Remote Sensing of Environment}, 80(1), 76-87. \doi{10.1016/S0034-4257(01)00289-9}
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
#' @description Calculates the Enhanced Vegetation Index (EVI) optimized for high-biomass canopy regions with improved atmospheric resistance.
#' @details The Enhanced Vegetation Index is computed as:
#' \deqn{\text{EVI} = G \times \frac{\text{NIR} - \text{Red}}{\text{NIR} + C_1 \cdot \text{Red} - C_2 \cdot \text{Blue} + L}}
#' where \eqn{G = 2.5} is the gain factor, \eqn{C_1 = 6.0} and \eqn{C_2 = 7.5} are aerosol resistance coefficients, and \eqn{L = 1.0} is the canopy background factor.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param blue SpatRaster or character. Blue band or path to file.
#' @param g_factor Numeric. Gain factor \eqn{G} (default: 2.5).
#' @param c1 Numeric. Aerosol resistance coefficient 1 \eqn{C_1} (default: 6.0).
#' @param c2 Numeric. Aerosol resistance coefficient 2 \eqn{C_2} (default: 7.5).
#' @param l_factor Numeric. Canopy background adjustment \eqn{L} (default: 1.0).
#' @return A SpatRaster containing EVI values with background masked to \code{NA}.
#' @references
#' Huete, A., Didan, K., Miura, T., Rodriguez, E. P., Gao, X., & Ferreira, L. G. (2002). Overview of the radiometric and biophysical performance of the MODIS vegetation indices. \emph{Remote Sensing of Environment}, 83(1-2), 195-213. \doi{10.1016/S0034-4257(02)00096-2}
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
#' @description Calculates the Normalized Difference Water Index (NDWI) to identify open surface water bodies, irrigation canals, and localized moisture pooling.
#' @details The Normalized Difference Water Index is calculated as:
#' \deqn{\text{NDWI} = \frac{\text{Green} - \text{NIR}}{\text{Green} + \text{NIR}}}
#' Positive values (\eqn{\text{NDWI} > 0}) typically demarcate water surfaces, while negative values represent terrestrial vegetation and dry bare soil.
#' @param green SpatRaster or character. Green band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @return A SpatRaster containing NDWI values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' McFeeters, S. K. (1996). The use of the Normalized Difference Water Index (NDWI) in the delineation of open water features. \emph{International Journal of Remote Sensing}, 17(7), 1425-1432. \doi{10.1080/01431169608948714}
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
#' @description Calculates the Normalized Difference Red Edge Index (NDRE) using the Red Edge band to evaluate canopy chlorophyll content and late-stage vegetative health.
#' @details The Normalized Difference Red Edge Index is formulated as:
#' \deqn{\text{NDRE} = \frac{\text{NIR} - \text{RedEdge}}{\text{NIR} + \text{RedEdge}}}
#' Useful in dense vegetation where standard NDVI experiences saturation.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @return A SpatRaster containing NDRE values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Barnes, E. M., Clarke, T. R., Richards, S. E., Colaizzi, P. D., Sloan, J., Moran, M. S., ... & Pinter, P. J. (2000). Coincident detection of crop water stress, nitrogen status and canopy density using ground-based multispectral data. \emph{Proceedings of the 5th International Conference on Precision Agriculture}, 16, 1-15.
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
#' @description Calculates the Green Normalized Difference Vegetation Index (GNDVI) for assessing chlorophyll concentration and photosynthetic activity.
#' @details The Green Normalized Difference Vegetation Index is defined as:
#' \deqn{\text{GNDVI} = \frac{\text{NIR} - \text{Green}}{\text{NIR} + \text{Green}}}
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param green SpatRaster or character. Green band or path to file.
#' @return A SpatRaster containing GNDVI values in \code{[-1, 1]} with background masked to \code{NA}.
#' @references
#' Gitelson, A. A., Merzlyak, M. N., & Lichtenthaler, H. K. (1996). Detection of red edge position and chlorophyll content by reflectance spectra. \emph{Journal of Plant Physiology}, 148(3-4), 494-508. \doi{10.1016/S0176-1617(96)80285-9}
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
#' @description Calculates the Corrected Transformed Vegetation Index (CTVI) to normalize skewed NDVI distributions.
#' @details The Corrected Transformed Vegetation Index is given by:
#' \deqn{\text{CTVI} = \frac{\text{NDVI} + 0.5}{\sqrt{|\text{NDVI} + 0.5|}}}
#' @param ndvi_raster SpatRaster or character. Input NDVI layer or path to file.
#' @return A SpatRaster containing CTVI values with background masked to \code{NA}.
#' @references
#' Perry, C. R., & Lautenschlager, L. F. (1984). Functional equivalence of spectral vegetation indices. \emph{Remote Sensing of Environment}, 14(1-3), 169-182. \doi{10.1016/0034-4257(84)90013-0}
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
#' @description Generates a binary mask of bare, exposed, or degraded soil based on an NDVI threshold.
#' @details The Bare Soil Mask is computed as a binary classification:
#' \deqn{\text{BareSoilMask} = \begin{cases} 1 & \text{if } \text{NDVI} < \theta \\ 0 & \text{otherwise} \end{cases}}
#' where \eqn{\theta} is an empirical threshold (default: \eqn{\theta = 0.15}).
#' @param ndvi_raster SpatRaster or character. Input NDVI layer or path to file.
#' @param threshold Numeric. Value below which pixels are classified as bare soil (default: 0.15).
#' @return A binary SpatRaster (1 = bare soil, 0 = vegetation/water) with background masked to \code{NA}.
#' @references
#' Montandon, L. M., & Small, E. E. (2008). The impact of soil reflectance on the quantification of green vegetation fraction in arid and semi-arid environments. \emph{Remote Sensing of Environment}, 112(2), 635-645. \doi{10.1016/j.rse.2007.05.016}
#' @export
d4h_bare_soil <- function(ndvi_raster, threshold = 0.15) {
  r <- .ensure_raster(ndvi_raster, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r) | r == 0] <- NA
  mask <- terra::ifel(r < threshold, 1, 0)
  mask[is.na(r)] <- NA
  names(mask) <- "Bare_Soil"
  mask
}
