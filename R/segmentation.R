#' @title Segment Water Bodies and Surface Moisture Pools
#' @description Detects, delineates, and vectorizes surface water bodies, irrigation trenches, and micro-pooling zones from multispectral indices (NDWI / NDVI) or RGB orthomosaics.
#' @details Water bodies are extracted by isolating negative NDVI or positive NDWI spectral signatures:
#' \deqn{\text{WaterMask} = \begin{cases} 1 & \text{if } \text{NDWI} > \theta_{\text{water}} \text{ or } \text{NDVI} < \theta_{\text{veg}} \\ 0 & \text{otherwise} \end{cases}}
#' Extracted pixel clusters are converted to vector polygons (\code{sf}), with calculated surface area (\eqn{\text{m}^2}) and perimeter.
#' @param raster_in SpatRaster or character path. Input NDWI, NDVI, or multispectral raster layer.
#' @param threshold Numeric. Spectral threshold for water delineation (default: -0.05 for NDVI, 0.0 for NDWI).
#' @param is_ndwi Logical. If TRUE, treats values \eqn{> \text{threshold}} as water; if FALSE (default for NDVI), treats values \eqn{< \text{threshold}} as water.
#' @param min_area_m2 Numeric. Minimum water body surface area in square meters to retain (default: 2.0). Filters out single-pixel noise.
#' @param max_area_m2 Numeric. Maximum water body surface area in square meters to retain (default: 50000.0).
#' @return An \code{sf} POLYGON object with columns: \code{water_id}, \code{area_m2}, \code{perimeter_m}, and spatial geometry.
#' @references
#' McFeeters, S. K. (1996). The use of the Normalized Difference Water Index (NDWI) in the delineation of open water features. \emph{International Journal of Remote Sensing}, 17(7), 1425-1432. \doi{10.1080/01431169608948714}
#' @export
d4h_segment_water <- function(raster_in, threshold = -0.05, is_ndwi = FALSE, min_area_m2 = 2.0, max_area_m2 = 50000.0) {
  r <- .ensure_raster(raster_in, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r)] <- NA

  w_mask <- if (isTRUE(is_ndwi)) {
    terra::ifel(r > threshold, 1, NA)
  } else {
    terra::ifel(r < threshold, 1, NA)
  }

  total_px <- terra::ncell(w_mask)
  if (total_px > 3000000) {
    agg_f <- ceiling(sqrt(total_px / 3000000))
    w_mask <- terra::aggregate(w_mask, fact = agg_f, fun = "max", na.rm = TRUE)
  }

  poly <- terra::as.polygons(w_mask, dissolve = TRUE)
  poly_sf <- sf::st_as_sf(poly)
  poly_sf <- suppressWarnings(sf::st_cast(poly_sf, "POLYGON", warn = FALSE))

  if (nrow(poly_sf) == 0L) {
    warning("No water bodies found matching the specified thresholds.", call. = FALSE)
    return(sf::st_sf(water_id = character(0), area_m2 = numeric(0), perimeter_m = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$area_m2 <- as.numeric(sf::st_area(poly_sf))
  poly_sf$perimeter_m <- as.numeric(lwgeom_len <- sf::st_length(sf::st_cast(poly_sf, "MULTILINESTRING", warn = FALSE)))

  poly_sf <- poly_sf[poly_sf$area_m2 >= min_area_m2 & poly_sf$area_m2 <= max_area_m2, ]
  if (nrow(poly_sf) == 0L) {
    warning("All detected water candidates were filtered out by the area constraints.", call. = FALSE)
    return(sf::st_sf(water_id = character(0), area_m2 = numeric(0), perimeter_m = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$water_id <- sprintf("W%04d", seq_len(nrow(poly_sf)))
  poly_sf[, c("water_id", "area_m2", "perimeter_m", "geometry")]
}

#' @title Segment House Roofs and Building Footprints
#' @description Identifies, delineates, and vectorizes residential houses, roofs, and man-made structures from ultra-high resolution RGB orthomosaics and vegetation masks.
#' @details Buildings are extracted by combining high surface brightness / spectral contrast in visible RGB bands with non-vegetated constraints (\eqn{\text{NDVI} < \theta_{\text{ndvi}}}):
#' \deqn{\text{BuildingCandidate} = \begin{cases} 1 & \text{if } \text{RGB}_{\text{mean}} \ge \theta_{\text{bright}} \text{ and } \text{NDVI} < \theta_{\text{ndvi}} \\ 0 & \text{otherwise} \end{cases}}
#' Vectorized candidates are filtered by residential building footprints (\eqn{10\text{ m}^2 \le \text{Area} \le 500\text{ m}^2}).
#' @param rgb_raster SpatRaster or character path. Ultra-high resolution 3-band RGB orthomosaic.
#' @param ndvi_raster SpatRaster or character path (optional). NDVI layer to exclude green vegetation canopies.
#' @param min_area_m2 Numeric. Minimum building footprint surface area in square meters (default: 12.0).
#' @param max_area_m2 Numeric. Maximum building footprint surface area in square meters (default: 500.0).
#' @param brightness_min Numeric. Minimum mean RGB brightness threshold \code{[0, 255]} (default: 155.0).
#' @param ndvi_max Numeric. Maximum NDVI threshold to exclude tree canopies over roofs (default: 0.18).
#' @return An \code{sf} POLYGON object with columns: \code{building_id}, \code{area_m2}, \code{centroid_x}, \code{centroid_y}, and spatial geometry.
#' @references
#' Blaschke, T. (2010). Object based image analysis for remote sensing. \emph{ISPRS Journal of Photogrammetry and Remote Sensing}, 65(1), 2-16. \doi{10.1016/j.isprsjprs.2009.06.004}
#' @export
d4h_segment_buildings <- function(rgb_raster, ndvi_raster = NULL, min_area_m2 = 12.0, max_area_m2 = 500.0, brightness_min = 155.0, ndvi_max = 0.18) {
  rgb <- if (is.character(rgb_raster) && length(rgb_raster) == 1L) terra::rast(rgb_raster) else rgb_raster

  # Brillo medio en RGB
  r_bright <- if (terra::nlyr(rgb) >= 3) {
    (rgb[[1]] + rgb[[2]] + rgb[[3]]) / 3
  } else {
    rgb[[1]]
  }

  # Restriccion opcional con NDVI
  b_mask <- if (!is.null(ndvi_raster)) {
    ndvi <- .ensure_raster(ndvi_raster, mask_zeros = FALSE)
    if (!terra::compareGeom(r_bright, ndvi, stopOnError = FALSE)) {
      ndvi <- terra::resample(ndvi, r_bright, method = "bilinear")
    }
    terra::ifel(r_bright >= brightness_min & ndvi < ndvi_max, 1, NA)
  } else {
    terra::ifel(r_bright >= brightness_min, 1, NA)
  }

  total_px <- terra::ncell(b_mask)
  if (total_px > 3000000) {
    agg_f <- ceiling(sqrt(total_px / 3000000))
    b_mask <- terra::aggregate(b_mask, fact = agg_f, fun = "max", na.rm = TRUE)
  }

  poly <- terra::as.polygons(b_mask, dissolve = TRUE)
  poly_sf <- sf::st_as_sf(poly)
  poly_sf <- suppressWarnings(sf::st_cast(poly_sf, "POLYGON", warn = FALSE))

  if (nrow(poly_sf) == 0L) {
    warning("No building footprints found matching the specified parameters.", call. = FALSE)
    return(sf::st_sf(building_id = character(0), area_m2 = numeric(0), centroid_x = numeric(0), centroid_y = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$area_m2 <- as.numeric(sf::st_area(poly_sf))
  poly_sf <- poly_sf[poly_sf$area_m2 >= min_area_m2 & poly_sf$area_m2 <= max_area_m2, ]

  if (nrow(poly_sf) == 0L) {
    warning("All detected building candidates were filtered out by the area bounds.", call. = FALSE)
    return(sf::st_sf(building_id = character(0), area_m2 = numeric(0), centroid_x = numeric(0), centroid_y = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$building_id <- sprintf("B%04d", seq_len(nrow(poly_sf)))

  # Calcular centroides
  cents <- suppressWarnings(sf::st_coordinates(sf::st_centroid(poly_sf)))
  poly_sf$centroid_x <- round(cents[, 1], 2)
  poly_sf$centroid_y <- round(cents[, 2], 2)

  poly_sf[, c("building_id", "area_m2", "centroid_x", "centroid_y", "geometry")]
}

#' @title Calculate Distance and Vulnerability Risk to Water Sources
#' @description Computes the minimum Euclidean distance from each residential building to the nearest aquatic vector breeding site, calculates an exponential infection exposure risk score, and stratifies epidemiological vulnerability levels.
#' @details The distance-decay transmission risk score is formulated based on vector flight dispersion models:
#' \deqn{\text{RiskScore}_i = \exp\left(-\frac{d_{\text{min}}(i)}{\lambda}\right)}
#' where \eqn{d_{\text{min}}(i)} is the minimum Euclidean distance (in meters) from building centroid \eqn{i} to the closest water polygon, and \eqn{\lambda} is the characteristic dispersal radius of disease vectors (e.g. \eqn{\lambda = 100\text{ m}} for \emph{Aedes aegypti} / \emph{Anopheles}).
#' @param buildings \code{sf} POLYGON or POINT object representing houses or human settlements.
#' @param sources \code{sf} POLYGON or POINT object representing water bodies, puddles, or waste accumulation sites.
#' @param decay_lambda Numeric. Flight dispersal decay parameter in meters (default: 100.0).
#' @param buffer_breaks Numeric vector. Distance cutoffs in meters for risk tier stratification (default: \code{c(50, 100, 200)}).
#' @param risk_labels Character vector. Names for each stratified risk tier (default: \code{c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)", "Bajo (>200m)")}).
#' @return An \code{sf} object matching \code{buildings} with appended columns: \code{dist_water_m}, \code{nearest_water_id}, \code{risk_score} in \code{[0, 1]}, and \code{risk_level}.
#' @references
#' World Health Organization. (2020). \emph{Operational framework for building climate resilient health systems}. World Health Organization.
#'
#' Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global extent of malaria in 2005. \emph{Trends in Parasitology}, 22(8), 353-358. \doi{10.1016/j.pt.2006.06.006}
#' @export
d4h_distance_to_risk <- function(buildings, sources, decay_lambda = 100.0, buffer_breaks = c(50, 100, 200), risk_labels = c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)", "Bajo (>200m)")) {
  if (!inherits(buildings, "sf") || !inherits(sources, "sf")) {
    stop("'buildings' and 'sources' must be sf spatial objects.", call. = FALSE)
  }

  if (nrow(buildings) == 0L || nrow(sources) == 0L) {
    stop("'buildings' and 'sources' must contain at least one feature.", call. = FALSE)
  }

  # Asegurar misma proyeccion espacial
  if (sf::st_crs(buildings) != sf::st_crs(sources)) {
    sources <- sf::st_transform(sources, sf::st_crs(buildings))
  }

  b_cents <- suppressWarnings(sf::st_centroid(buildings))
  dists_matrix <- sf::st_distance(b_cents, sources)

  min_dists <- apply(dists_matrix, 1, min)
  nearest_idx <- apply(dists_matrix, 1, which.min)

  source_id_col <- if ("water_id" %in% names(sources)) "water_id" else names(sources)[1]

  res_sf <- buildings
  res_sf$dist_water_m <- round(as.numeric(min_dists), 1)
  res_sf$nearest_water_id <- sources[[source_id_col]][nearest_idx]
  res_sf$risk_score <- round(exp(-res_sf$dist_water_m / decay_lambda), 3)

  breaks_all <- c(-Inf, buffer_breaks, Inf)
  res_sf$risk_level <- cut(
    res_sf$dist_water_m,
    breaks = breaks_all,
    labels = risk_labels,
    include.lowest = TRUE
  )

  res_sf
}

#' @title Continuous Euclidean Distance Raster from Risk Sources
#' @description Computes a continuous Euclidean distance surface raster (heat map) measuring proximity to water bodies, breeding sites, or waste clusters across the entire flight extent.
#' @param sources \code{sf} or \code{SpatVector} spatial object containing risk source polygons/points.
#' @param raster_ref SpatRaster or character path. Reference raster layer defining spatial grid dimensions and CRS.
#' @return A SpatRaster where each pixel represents the Euclidean distance in meters to the nearest risk source.
#' @export
d4h_raster_distance <- function(sources, raster_ref) {
  r_ref <- .ensure_raster(raster_ref, mask_zeros = FALSE)

  sources_vect <- if (inherits(sources, "sf")) terra::vect(sources) else sources

  r_rasterized <- terra::rasterize(sources_vect, r_ref, field = 1, background = NA)
  dist_raster <- terra::distance(r_rasterized)

  names(dist_raster) <- "dist_to_source_m"
  dist_raster
}
