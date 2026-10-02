#' @title Synthetic Materials Risk Index (IMSR)
#' @description Detects non-natural solid waste materials (plastics, discarded tires, tarps, and artificial containers) that serve as potential *Aedes aegypti* oviposition and larval habitats.
#' @details The Index of Micro-accumulation of Solid Waste (IMSR) evaluates spectral deviations in the Red Edge - Red transition weighted by Near-Infrared reflectance:
#' \deqn{\text{NDRE}_{\text{approx}} = \frac{\text{RedEdge} - \text{Red}}{\text{RedEdge} + \text{Red} + \epsilon}}
#' \deqn{\text{IMSR} = |\text{NDRE}_{\text{approx}} - \theta_{\text{veg}}| \times \text{NIR}_{\text{norm}}}
#' where \eqn{\theta_{\text{veg}}} is a threshold separating natural vegetation from synthetic polymer surfaces. Output values are clamped between 0 and 1.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param veg_threshold Numeric. Threshold to differentiate vegetation from synthetics (default: 0.2).
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing IMSR values in \code{[0, 1]} with background masked to \code{NA}.
#' @references
#' World Health Organization. (2020). \emph{Comprehensive guidelines for prevention and control of dengue and dengue haemorrhagic fever}. WHO Regional Office for South-East Asia.
#'
#' Fornace, K. M., Drakeley, C. J., William, T., Espino, F., & Cox, J. (2014). Mapping infectious disease landscapes: unmanned aerial vehicles and epidemiology. \emph{Trends in Parasitology}, 30(11), 514-519. \doi{10.1016/j.pt.2014.09.001}
#' @export
d4h_imsr <- function(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001) {
  # 1. Alinear enmascarando ceros estrictos de origen
  aligned <- .match_multi(red_edge, red, nir, mask_zeros = TRUE)
  re <- aligned[[1]]
  r  <- aligned[[2]]
  n  <- aligned[[3]]

  # 2. Normalizar NIR si viene en enteros de 16 bits
  max_sample <- max(terra::spatSample(n, size = 100, na.rm = TRUE)[, 1], na.rm = TRUE)
  if (is.finite(max_sample) && max_sample > 1) {
    n <- n / 65535
  }

  # 3. Cálculo de NDRE aproximado y de IMSR
  den_ndre <- re + r + eps
  ndre_approx <- (re - r) / den_ndre
  res <- abs(ndre_approx - veg_threshold) * n

  # 4. Máscara estricta: si cualquiera de las bandas originales fue NA o <= 0, res es NA
  res[is.na(re) | is.na(r) | is.na(n) | is.nan(res) | is.infinite(res)] <- NA
  res[res <= 1e-5] <- NA
  res <- terra::clamp(res, lower = 0, upper = 1)

  names(res) <- "IMSR"
  res
}

#' @title Thermal Refuge and Shade Index (IRTS)
#' @description Identifies cool, shaded microhabitats serving as micro-climatic shelters and resting sites for adult disease vectors during extreme heat hours.
#' @details The Thermal Refuge and Shade Index evaluates the thermal gradient between focal surroundings and localized micro-environments modulated by canopy density:
#' \deqn{\text{IRTS} = \frac{\text{NDRE} \times (\text{LST}_{\text{surrounding}} - \text{LST}_{\text{local}})}{\text{NIR} + \epsilon}}
#' High positive IRTS values highlight cool micro-climatic refuges buffered by dense vegetative cover.
#' @param ndre SpatRaster or character. NDRE index layer or path to file.
#' @param lst_local SpatRaster or character. Local Land Surface Temperature (°C) or path to file.
#' @param lst_surrounding SpatRaster or character. Focal mean surrounding Land Surface Temperature (°C) or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing thermal refuge intensity with background masked to \code{NA}.
#' @references
#' Murdock, C. C., Sternberg, E. D., & Thomas, M. B. (2016). Microclimate determines the infection potential of \emph{Aedes aegypti} for dengue virus. \emph{PLOS Neglected Tropical Diseases}, 10(12), e0005118. \doi{10.1371/journal.pntd.0005118}
#' @export
d4h_irts <- function(ndre, lst_local, lst_surrounding, nir, eps = 0.001) {
  aligned <- .match_multi(ndre, lst_local, lst_surrounding, nir, mask_zeros = FALSE)
  re_ndre <- aligned[[1]]
  t_loc   <- aligned[[2]]
  t_surr  <- aligned[[3]]
  n_nir   <- aligned[[4]]

  den <- n_nir + eps
  res <- (re_ndre * (t_surr - t_loc)) / den
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRTS"
  res
}

#' @title Vulnerability Stagnation Indicator (IEV)
#' @description Locates areas where surface water is prone to micro-stagnation and persistent pooling by synthesizing surface moisture and terrain slope.
#' @details The Entomological Vector Suitability / Stagnation Indicator combines moisture accumulation with micro-topographical slope inverse:
#' \deqn{\text{IEV} = \text{NDWI} \times \frac{1}{\text{Slope} + \epsilon}}
#' High values indicate flat micro-depressions with significant moisture content suitable for mosquito and snail vector colonization.
#' @param delta_ndwi SpatRaster or character. Temporal difference in NDWI or base NDWI layer or path to file.
#' @param slope_dsm SpatRaster or character. Slope layer derived from DSM/DEM or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster containing IEV stagnation risk values with background masked to \code{NA}.
#' @references
#' Hardy, A., Makame, M., Cross, D., Majambere, S., & Msellem, M. (2017). Using low-cost drones to map malaria vector habitats. \emph{Parasites & Vectors}, 10(1), 29. \doi{10.1186/s13071-017-1973-3}
#' @export
d4h_iev <- function(delta_ndwi, slope_dsm, eps = 0.001) {
  pair <- .match_pair(delta_ndwi, slope_dsm, mask_zeros = FALSE)
  ndwi <- pair$ref
  slp  <- pair$sub

  den <- slp + eps
  res <- ndwi * (1 / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEV"
  res
}

#' @title Breeding Site Stratification Index (IEC)
#' @description Evaluates open water bodies weighted by optimal thermal ranges for larval development.
#' @details The Canopy Exposure & Thermal Incubation Index is defined as:
#' \deqn{\text{IEC} = \text{GNDVI}_{\text{water}} \times \left(1 - \frac{|\text{LST} - T_{\text{opt}}|}{T_{\text{opt}}}\right)}
#' where \eqn{T_{\text{opt}}} is the optimal incubation temperature (default: \eqn{T_{\text{opt}} = 25^\circ\text{C}}).
#' @param gndvi_water SpatRaster or character. GNDVI layer masked to water bodies or path to file.
#' @param lst SpatRaster or character. Land Surface Temperature layer in Celsius or path to file.
#' @param t_opt Numeric. Optimal incubation temperature in degrees Celsius (default: 25).
#' @return A SpatRaster stratifying larval breeding site quality with background masked to \code{NA}.
#' @references
#' Mordecai, E. A., Cohen, J. M., Evans, M. V., Gudapati, P., Johnson, L. R., Lippi, C. A., ... & Rohr, J. R. (2017). Detecting the impact of temperature on transmission of Zika, dengue, and chikungunya using mechanistic models. \emph{PLOS Neglected Tropical Diseases}, 11(4), e0005568. \doi{10.1371/journal.pntd.0005568}
#' @export
d4h_iec <- function(gndvi_water, lst, t_opt = 25) {
  pair <- .match_pair(gndvi_water, lst, mask_zeros = FALSE)
  gw  <- pair$ref
  tmp <- pair$sub

  res <- gw * (1 - (abs(tmp - t_opt) / t_opt))
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEC"
  res
}

#' @title Clearing Stagnation Index (IEAD)
#' @description Detects surface water pooling and vector vulnerability in recently cleared, excavated, or deforested micro-zones.
#' @details The Deforestation Micro-Habitat Exposure Index integrates vegetation change gradients, elevation depressions, and Red Edge reflectance:
#' \deqn{\text{IEAD} = \nabla(\Delta\text{NDVI}) \times \text{Depressions}_{\text{DSM}} \times \text{RedEdge}}
#' @param grad_delta_ndvi SpatRaster or character. Gradient of NDVI change layer or path to file.
#' @param depressions_dsm SpatRaster or character. Topographic depressions layer from DSM or path to file.
#' @param red_edge SpatRaster or character. Red Edge band or path to file.
#' @return A SpatRaster highlighting stagnation risk in clearings with background masked to \code{NA}.
#' @references
#' Castro, M. C., Kanamori, S., Kannady, K., Mkude, S., Killeen, G. F., & Fillinger, U. (2010). The importance of drains for the emergence of anopheline mosquitoes in urban Dar es Salaam, Tanzania. \emph{BMC Public Health}, 10, 344.
#' @export
d4h_iead <- function(grad_delta_ndvi, depressions_dsm, red_edge) {
  aligned <- .match_multi(grad_delta_ndvi, depressions_dsm, red_edge, mask_zeros = FALSE)
  g_ndvi <- aligned[[1]]
  d_dsm  <- aligned[[2]]
  re     <- aligned[[3]]

  res <- g_ndvi * d_dsm * re
  res[is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IEAD"
  res
}

#' @title Spectral Water Retention Index (IRHE)
#' @description Highlights persistent, cold surface water bodies with low evaporation rates prone to long-term mosquito colonization.
#' @details The High-Risk Hydric Environment Index is computed as:
#' \deqn{\text{IRHE} = \text{NDWI} \times \frac{1}{\text{LST} + \epsilon}}
#' @param green SpatRaster or character. Green band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param lst SpatRaster or character. Land Surface Temperature layer (°C) or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing water retention potential with background masked to \code{NA}.
#' @references
#' McFeeters, S. K. (1996). The use of the Normalized Difference Water Index (NDWI) in the delineation of open water features. \emph{International Journal of Remote Sensing}, 17(7), 1425-1432.
#' @export
d4h_irhe <- function(green, nir, lst, eps = 0.001) {
  aligned <- .match_multi(green, nir, lst, mask_zeros = TRUE)
  g <- aligned[[1]]
  n <- aligned[[2]]
  t <- aligned[[3]]

  den_ndwi <- g + n + eps
  ndwi <- (g - n) / den_ndwi
  ndwi[den_ndwi <= 0 | is.nan(ndwi) | is.infinite(ndwi)] <- NA

  den_lst <- t + eps
  res <- ndwi * (1 / den_lst)
  res[den_lst <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRHE"
  res
}

#' @title Fragmentation and Edge Effect Index (IFEB)
#' @description Quantifies ecological transitions and ecotone borders between tree canopies and urban or cleared soil substrates.
#' @details The Forest Edge & Environmental Barrier Index is formulated as:
#' \deqn{\text{IFEB} = |\nabla(\text{RedEdge})| \times \frac{\text{Red}}{\text{NIR} + \epsilon}}
#' @param grad_red_edge SpatRaster or character. Focal standard deviation of Red Edge or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster quantifying edge effects with background masked to \code{NA}.
#' @references
#' Laurance, W. F., et al. (2011). The impact of forest fragmentation on disease ecology. \emph{Biological Conservation}, 144(1), 56-68.
#' @export
d4h_ifeb <- function(grad_red_edge, red, nir, eps = 0.001) {
  aligned <- .match_multi(grad_red_edge, red, nir, mask_zeros = TRUE)
  g_re <- aligned[[1]]
  r    <- aligned[[2]]
  n    <- aligned[[3]]

  den <- n + eps
  res <- abs(g_re) * (r / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IFEB"
  res
}

#' @title Human Interface Roughness Index (IRIH)
#' @description Measures canopy structural heterogeneity in the forest-household ecotone interface to model vector flight pathways and peridomestic contact.
#' @details The Index of Human Infection Risk / Roughness is calculated as:
#' \deqn{\text{IRIH} = \text{Var}\left(\frac{\text{RedEdge}}{\text{NIR}}\right) \times \frac{\text{Red}}{\text{Green} + \epsilon}}
#' @param var_re_nir SpatRaster or character. Local variance of RE/NIR ratio or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param green SpatRaster or character. Green band or path to file.
#' @param eps Numeric. Small epsilon to prevent division by zero (default: 0.001).
#' @return A SpatRaster representing structural roughness with background masked to \code{NA}.
#' @references
#' Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global extent of malaria in 2005. \emph{Trends in Parasitology}, 22(8), 353-358. \doi{10.1016/j.pt.2006.06.006}
#' @export
d4h_irih <- function(var_re_nir, red, green, eps = 0.001) {
  aligned <- .match_multi(var_re_nir, red, green, mask_zeros = TRUE)
  v_ratio <- aligned[[1]]
  r       <- aligned[[2]]
  g       <- aligned[[3]]

  den <- g + eps
  res <- v_ratio * (r / den)
  res[den <= 0 | is.nan(res) | is.infinite(res) | res == 0] <- NA
  names(res) <- "IRIH"
  res
}
