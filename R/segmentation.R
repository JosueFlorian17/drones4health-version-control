#' @title Segment Water Bodies and Surface Moisture Pools
#' @description Detects, delineates, and vectorizes surface water bodies, irrigation trenches, and micro-pooling zones from multispectral indices (NDWI / NDVI) or RGB orthomosaics using spectral thresholding or Deep Learning (SAM).
#' @details Water bodies are extracted by isolating negative NDVI or positive NDWI spectral signatures combined with low optical reflectance:
#' \deqn{\text{WaterMask} = \begin{cases} 1 & \text{if } (\text{NDWI} > \theta_{\text{water}} \text{ or } \text{NDVI} < \theta_{\text{veg}}) \text{ and } \text{Brightness} \le \theta_{\text{dark}} \\ 0 & \text{otherwise} \end{cases}}
#' Extracted pixel clusters are converted to vector polygons (\code{sf}), with calculated surface area (\eqn{\text{m}^2}) and perimeter.
#' @param raster_in SpatRaster or character path. Input NDWI, NDVI, or multispectral raster layer.
#' @param rgb_raster SpatRaster or character path (optional). RGB orthomosaic to enforce optical darkness constraint (water absorbs visible light, while shiny metal/calamina roofs reflect high brightness).
#' @param threshold Numeric. Spectral threshold for water delineation (default: -0.05 for NDVI, 0.0 for NDWI).
#' @param is_ndwi Logical. If TRUE, treats values \eqn{> \text{threshold}} as water; if FALSE (default for NDVI), treats values \eqn{< \text{threshold}} as water.
#' @param max_water_brightness Numeric. Maximum allowable mean RGB brightness \eqn{[0, 255]} for water (default: 95.0). Prevents metal roofs and concrete from being classified as water.
#' @param min_area_m2 Numeric. Minimum water body surface area in square meters to retain (default: 2.0). Filters out single-pixel noise.
#' @param max_area_m2 Numeric. Maximum water body surface area in square meters to retain (default: 50000.0).
#' @param method Character. Segmentation algorithm: \code{"spectral"} (default, 100% native R Object-Based GeoAI) or \code{"sam"} (Meta Segment Anything Model via reticulate/Python).
#' @param sam_checkpoint Character path (optional). Path to SAM model weights (.pth) when \code{method = "sam"}.
#' @param exclude_buildings \code{sf} POLYGON object (optional). Residential buildings, roofs, or structures to strictly exclude from water bodies to prevent metal/calamina roofs from being misclassified as water.
#' @return An \code{sf} POLYGON object with columns: \code{water_id}, \code{area_m2}, \code{perimeter_m}, and spatial geometry.
#' @export
d4h_segment_water <- function(raster_in, rgb_raster = NULL, threshold = -0.05, is_ndwi = FALSE, max_water_brightness = 95.0, min_area_m2 = 2.0, max_area_m2 = 50000.0, method = c("spectral", "sam"), sam_checkpoint = NULL, exclude_buildings = NULL) {
  method <- match.arg(method)

  r <- .ensure_raster(raster_in, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r)] <- NA

  if (method == "sam") {
    poly_sf <- .d4h_run_sam(
      r_img = r,
      sam_checkpoint = sam_checkpoint,
      min_area_m2 = min_area_m2,
      max_area_m2 = max_area_m2,
      points_per_side = 16L
    )
    if (nrow(poly_sf) == 0L) {
      warning("No water bodies found by SAM with specified parameters.", call. = FALSE)
      return(sf::st_sf(water_id = character(0), area_m2 = numeric(0), perimeter_m = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(terra::crs(r)))))
    }

    # Excluir viviendas si se proporcionan
    if (!is.null(exclude_buildings) && inherits(exclude_buildings, "sf") && nrow(exclude_buildings) > 0) {
      if (sf::st_crs(poly_sf) != sf::st_crs(exclude_buildings)) {
        exclude_buildings <- sf::st_transform(exclude_buildings, sf::st_crs(poly_sf))
      }
      poly_sf <- suppressWarnings(sf::st_difference(poly_sf, sf::st_union(exclude_buildings)))
      poly_sf <- suppressWarnings(sf::st_cast(poly_sf, "POLYGON", warn = FALSE))
      poly_sf$area_m2 <- as.numeric(sf::st_area(poly_sf))
      poly_sf <- poly_sf[poly_sf$area_m2 >= min_area_m2, ]
    }

    poly_sf$water_id <- sprintf("W%04d", seq_len(nrow(poly_sf)))
    poly_sf$perimeter_m <- as.numeric(sf::st_length(sf::st_cast(poly_sf, "MULTILINESTRING", warn = FALSE)))
    return(poly_sf[, c("water_id", "area_m2", "perimeter_m", "geometry")])
  }

  w_mask <- if (isTRUE(is_ndwi)) {
    terra::ifel(r > threshold, 1, NA)
  } else {
    terra::ifel(r < threshold, 1, NA)
  }

  # Filtro óptico de oscuridad: El agua real siempre es oscura (baja reflectancia)
  if (!is.null(rgb_raster)) {
    rgb_r <- if (is.character(rgb_raster) && length(rgb_raster) == 1L) terra::rast(rgb_raster) else rgb_raster
    r_bright <- if (terra::nlyr(rgb_r) >= 3) {
      (rgb_r[[1]] + rgb_r[[2]] + rgb_r[[3]]) / 3
    } else {
      rgb_r[[1]]
    }
    if (!terra::compareGeom(w_mask, r_bright, stopOnError = FALSE)) {
      r_bright <- terra::resample(r_bright, w_mask, method = "bilinear")
    }
    # Agua debe ser oscura (descartar calaminas brillantes y concreto con brillo > max_water_brightness)
    w_mask <- terra::ifel(w_mask == 1 & r_bright <= max_water_brightness, 1, NA)
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

  # Excluir viviendas para que ningun techo o patio se clasifique como agua
  if (!is.null(exclude_buildings) && inherits(exclude_buildings, "sf") && nrow(exclude_buildings) > 0) {
    if (sf::st_crs(poly_sf) != sf::st_crs(exclude_buildings)) {
      exclude_buildings <- sf::st_transform(exclude_buildings, sf::st_crs(poly_sf))
    }
    b_union <- sf::st_buffer(sf::st_union(exclude_buildings), dist = 1.0)
    poly_sf <- suppressWarnings(sf::st_difference(poly_sf, b_union))
    poly_sf <- suppressWarnings(sf::st_cast(poly_sf, "POLYGON", warn = FALSE))
  }

  poly_sf$area_m2 <- as.numeric(sf::st_area(poly_sf))
  poly_sf$perimeter_m <- as.numeric(sf::st_length(sf::st_cast(poly_sf, "MULTILINESTRING", warn = FALSE)))

  poly_sf <- poly_sf[poly_sf$area_m2 >= min_area_m2 & poly_sf$area_m2 <= max_area_m2, ]

  # Filtrar estrictamente dentro del ortomosaico erosionando bordes
  fp_clean <- .d4h_clean_flight_footprint(r, buffer_m = -15.0)
  if (!is.null(fp_clean) && nrow(fp_clean) > 0) {
    poly_sf <- suppressWarnings(sf::st_filter(poly_sf, fp_clean, .predicate = sf::st_within))
  }

  if (nrow(poly_sf) == 0L) {
    warning("All detected water candidates were filtered out by the area/boundary constraints.", call. = FALSE)
    return(sf::st_sf(water_id = character(0), area_m2 = numeric(0), perimeter_m = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$water_id <- sprintf("W%04d", seq_len(nrow(poly_sf)))
  poly_sf[, c("water_id", "area_m2", "perimeter_m", "geometry")]
}


#' @title Segment House Roofs and Building Footprints
#' @description Identifies, delineates, and vectorizes residential houses, roofs, and man-made structures from ultra-high resolution RGB orthomosaics using spectral-geometric OBIA or Segment Anything (SAM).
#' @details Buildings are extracted by combining high surface brightness / spectral contrast in visible RGB bands with non-vegetated constraints (\eqn{\text{NDVI} < \theta_{\text{ndvi}}}):
#' \deqn{\text{BuildingCandidate} = \begin{cases} 1 & \text{if } \text{RGB}_{\text{mean}} \ge \theta_{\text{bright}} \text{ and } \text{NDVI} < \theta_{\text{ndvi}} \\ 0 & \text{otherwise} \end{cases}}
#' Vectorized candidates are filtered by residential building footprints (\eqn{10\text{ m}^2 \le \text{Area} \le 500\text{ m}^2}).
#' @param rgb_raster SpatRaster or character path. Ultra-high resolution 3-band RGB orthomosaic.
#' @param ndvi_raster SpatRaster or character path (optional). NDVI layer to exclude green vegetation canopies.
#' @param min_area_m2 Numeric. Minimum building footprint surface area in square meters (default: 12.0).
#' @param max_area_m2 Numeric. Maximum building footprint surface area in square meters (default: 500.0).
#' @param brightness_min Numeric. Minimum mean RGB brightness threshold \code{[0, 255]} (default: 155.0).
#' @param ndvi_max Numeric. Maximum NDVI threshold to exclude tree canopies over roofs (default: 0.18).
#' @param method Character. Segmentation method: \code{"spectral"} (default, fast native R) or \code{"sam"} (Meta Segment Anything Model).
#' @param sam_checkpoint Character path (optional). Model weights path when \code{method = "sam"}.
#' @return An \code{sf} POLYGON object with columns: \code{building_id}, \code{area_m2}, \code{centroid_x}, \code{centroid_y}, and spatial geometry.
#' @references
#' Blaschke, T. (2010). Object based image analysis for remote sensing. \emph{ISPRS Journal of Photogrammetry and Remote Sensing}, 65(1), 2-16. \doi{10.1016/j.isprsjprs.2009.06.004}
#'
#' Kirillov, A., et al. (2023). Segment anything. \emph{arXiv preprint arXiv:2304.02643}.
#' @export
d4h_segment_buildings <- function(rgb_raster, ndvi_raster = NULL, min_area_m2 = 12.0, max_area_m2 = 600.0, brightness_min = 135.0, ndvi_max = 0.25, method = c("spectral", "sam"), sam_checkpoint = NULL) {
  method <- match.arg(method)

  rgb <- if (is.character(rgb_raster) && length(rgb_raster) == 1L) terra::rast(rgb_raster) else rgb_raster

  if (method == "sam") {
    poly_sf <- .d4h_run_sam(
      r_img = rgb,
      sam_checkpoint = sam_checkpoint,
      min_area_m2 = min_area_m2,
      max_area_m2 = max_area_m2,
      points_per_side = 16L
    )
    if (nrow(poly_sf) == 0L) {
      warning("No building footprints found by SAM with specified parameters.", call. = FALSE)
      return(sf::st_sf(building_id = character(0), area_m2 = numeric(0), centroid_x = numeric(0), centroid_y = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(terra::crs(rgb)))))
    }
    poly_sf$building_id <- sprintf("B%04d", seq_len(nrow(poly_sf)))
    cents <- suppressWarnings(sf::st_coordinates(sf::st_centroid(poly_sf)))
    poly_sf$centroid_x <- round(cents[, 1], 2)
    poly_sf$centroid_y <- round(cents[, 2], 2)
    return(poly_sf[, c("building_id", "area_m2", "centroid_x", "centroid_y", "geometry")])
  }

  # Optimización de resolución para vectorización estable
  r_work <- rgb
  total_px <- terra::ncell(r_work)
  if (total_px > 100000000) {
    r_work <- terra::aggregate(r_work, fact = 2, fun = "mean", na.rm = TRUE)
  }

  is_multiband <- terra::nlyr(r_work) >= 3
  r_bright <- if (is_multiband) {
    (r_work[[1]] + r_work[[2]] + r_work[[3]]) / 3
  } else {
    r_work[[1]]
  }

  # Discriminación espectral:
  roof_cand <- if (is_multiband) {
    r_red   <- r_work[[1]]
    r_green <- r_work[[2]]
    r_blue  <- r_work[[3]]
    is_calamina <- r_bright >= brightness_min
    is_teja     <- (r_red >= 115) & (r_red > 1.12 * r_green) & (r_red > 1.18 * r_blue)
    terra::ifel(is_calamina | is_teja, 1, NA)
  } else {
    terra::ifel(r_bright >= brightness_min, 1, NA)
  }

  b_mask <- if (!is.null(ndvi_raster)) {
    ndvi <- .ensure_raster(ndvi_raster, mask_zeros = FALSE)
    if (!terra::compareGeom(r_bright, ndvi, stopOnError = FALSE)) {
      ndvi <- terra::resample(ndvi, r_bright, method = "bilinear")
    }
    terra::ifel(roof_cand == 1 & (ndvi < ndvi_max | is.na(ndvi)), 1, NA)
  } else {
    roof_cand
  }

  b_mask <- terra::aggregate(b_mask, fact = 2, fun = "max", na.rm = TRUE)

  poly <- terra::as.polygons(b_mask, dissolve = TRUE)
  poly_sf <- sf::st_as_sf(poly)
  poly_sf <- suppressWarnings(sf::st_cast(poly_sf, "POLYGON", warn = FALSE))

  if (nrow(poly_sf) == 0L) {
    warning("No building footprints found matching the specified parameters.", call. = FALSE)
    return(sf::st_sf(building_id = character(0), area_m2 = numeric(0), centroid_x = numeric(0), centroid_y = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$area_m2 <- as.numeric(sf::st_area(poly_sf))
  poly_sf <- poly_sf[poly_sf$area_m2 >= min_area_m2 & poly_sf$area_m2 <= max_area_m2, ]


  fp_clean <- .d4h_clean_flight_footprint(rgb, buffer_m = -15.0)
  if (!is.null(fp_clean) && nrow(fp_clean) > 0) {
    poly_sf <- suppressWarnings(sf::st_filter(poly_sf, fp_clean, .predicate = sf::st_within))
  }

  if (nrow(poly_sf) == 0L) {
    warning("All detected building candidates were filtered out by the area bounds.", call. = FALSE)
    return(sf::st_sf(building_id = character(0), area_m2 = numeric(0), centroid_x = numeric(0), centroid_y = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(poly_sf))))
  }

  poly_sf$building_id <- sprintf("B%04d", seq_len(nrow(poly_sf)))

  cents <- suppressWarnings(sf::st_coordinates(sf::st_centroid(poly_sf)))
  poly_sf$centroid_x <- round(cents[, 1], 2)
  poly_sf$centroid_y <- round(cents[, 2], 2)

  poly_sf[, c("building_id", "area_m2", "centroid_x", "centroid_y", "geometry")]
}

.d4h_clean_flight_footprint <- function(r, buffer_m = -15.0) {
  tryCatch({
    r_fact <- ceiling(max(terra::nrow(r), terra::ncol(r)) / 600)
    r_low <- terra::aggregate(r[[1]], fact = r_fact, fun = "max", na.rm = TRUE)
    mask_val <- terra::ifel(r_low > 10 & !is.na(r_low), 1, NA)
    poly_fp <- terra::as.polygons(mask_val, dissolve = TRUE)
    if (length(poly_fp) == 0) return(NULL)
    fp_sf <- suppressWarnings(sf::st_as_sf(poly_fp))
    fp_eroded <- suppressWarnings(sf::st_buffer(fp_sf, dist = buffer_m))
    fp_eroded
  }, error = function(e) NULL)
}

# SAM via reticulate
.d4h_run_sam <- function(r_img, sam_checkpoint = NULL, min_area_m2 = 10.0, max_area_m2 = 50000.0, points_per_side = 16L) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Para usar 'method = sam' se requiere el paquete R 'reticulate'. Instálalo con install.packages('reticulate').", call. = FALSE)
  }

  if (!reticulate::py_available(initialize = FALSE)) {
    py_cands <- c("C:/Python313/python.exe", Sys.which("python.exe"), Sys.which("python"))
    py_cands <- py_cands[file.exists(py_cands)]
    if (length(py_cands) > 0) {
      reticulate::use_python(py_cands[1], required = FALSE)
    }
  }

  if (is.null(sam_checkpoint)) {
    candidates <- c(
      "models/sam_vit_b_01ec64.pth",
      "models/sam_vit_l_0b3195.pth",
      "models/sam_vit_h_4b8939.pth",
      file.path(getwd(), "models", "sam_vit_b_01ec64.pth")
    )
    found <- candidates[file.exists(candidates)]
    if (length(found) > 0) {
      sam_checkpoint <- found[1]
    } else {
      stop("No se encontró el archivo de pesos SAM (.pth). Especifica 'sam_checkpoint = \"ruta/al/modelo.pth\"'.", call. = FALSE)
    }
  }

  if (!file.exists(sam_checkpoint)) {
    stop(sprintf("El archivo de pesos '%s' no existe.", sam_checkpoint), call. = FALSE)
  }

  message(sprintf("Inicializando Meta Segment Anything (SAM) desde: %s ...", sam_checkpoint))
  sam_mod <- reticulate::import("segment_anything")
  torch_mod <- reticulate::import("torch")

  model_type <- if (grepl("vit_h", sam_checkpoint, ignore.case = TRUE)) {
    "vit_h"
  } else if (grepl("vit_l", sam_checkpoint, ignore.case = TRUE)) {
    "vit_l"
  } else {
    "vit_b"
  }

  sam_builder <- sam_mod[[paste0("build_sam_", model_type)]]
  sam <- sam_builder(checkpoint = normalizePath(sam_checkpoint))

  dev_str <- if (torch_mod$cuda$is_available()) "cuda" else "cpu"
  sam$to(torch_mod$device(dev_str))
  message(sprintf("SAM [%s] ejecutando en: %s", model_type, toupper(dev_str)))

  mask_gen <- sam_mod$SamAutomaticMaskGenerator(
    sam,
    points_per_side = as.integer(points_per_side),
    pred_iou_thresh = 0.85,
    stability_score_thresh = 0.90,
    min_mask_region_area = 30L
  )

  r_work <- r_img
  total_px <- terra::ncell(r_work)
  if (total_px > 1500000) {
    agg_f <- ceiling(sqrt(total_px / 1500000))
    message(sprintf("Optimizando resolución para inferencia SAM (agregación %dx%d)...", agg_f, agg_f))
    r_work <- terra::aggregate(r_work, fact = agg_f, fun = "mean", na.rm = TRUE)
  }

  arr <- if (terra::nlyr(r_work) >= 3) terra::as.array(r_work[[1:3]]) else terra::as.array(c(r_work[[1]], r_work[[1]], r_work[[1]]))
  arr[is.na(arr)] <- 0
  if (max(arr, na.rm = TRUE) <= 1.0) arr <- arr * 255
  arr <- pmax(0, pmin(255, arr))

  py_mod <- reticulate::import_main()
  py_mod$arr <- as.vector(arr)
  py_mod$h_dim <- as.integer(terra::nrow(r_work))
  py_mod$w_dim <- as.integer(terra::ncol(r_work))
  py_mod$c_dim <- as.integer(if (terra::nlyr(r_work) >= 3) 3L else 1L)
  py_mod$mask_gen <- mask_gen
  reticulate::py_run_string("
import numpy as np
raw = np.asarray(arr, dtype=np.float32)
if c_dim == 3:
    img_np = raw.reshape((h_dim, w_dim, 3), order='F')
else:
    img_2d = raw.reshape((h_dim, w_dim), order='F')
    img_np = np.stack([img_2d, img_2d, img_2d], axis=-1)

img_np = np.ascontiguousarray(np.clip(img_np, 0, 255), dtype=np.uint8)
masks = mask_gen.generate(img_np)
")
  masks <- py_mod$masks
  num_masks <- length(masks)
  message(sprintf("SAM detectó %d máscaras.", num_masks))

  target_crs <- sf::st_crs(terra::crs(r_img))
  if (num_masks == 0L) {
    return(sf::st_sf(geometry = sf::st_sfc(crs = target_crs)))
  }

  polys_list <- list()
  for (i in seq_len(num_masks)) {
    m_data <- masks[[i]]$segmentation
    m_r <- terra::rast(r_work[[1]])
    terra::values(m_r) <- as.vector(t(m_data))
    m_poly <- terra::as.polygons(terra::ifel(m_r == 1, 1, NA), dissolve = TRUE)
    if (length(m_poly) > 0) {
      m_sf <- suppressWarnings(sf::st_as_sf(m_poly))
      m_sf <- suppressWarnings(sf::st_cast(m_sf, "POLYGON", warn = FALSE))
      if (nrow(m_sf) > 0) {
        polys_list[[length(polys_list) + 1]] <- m_sf
      }
    }
  }

  if (length(polys_list) == 0L) {
    return(sf::st_sf(geometry = sf::st_sfc(crs = target_crs)))
  }

  all_sf <- do.call(rbind, polys_list)
  all_sf$area_m2 <- as.numeric(sf::st_area(all_sf))
  all_sf <- all_sf[all_sf$area_m2 >= min_area_m2 & all_sf$area_m2 <= max_area_m2, ]

  fp_clean <- .d4h_clean_flight_footprint(r_img, buffer_m = -15.0)
  if (!is.null(fp_clean) && nrow(fp_clean) > 0) {
    all_sf <- suppressWarnings(sf::st_filter(all_sf, fp_clean, .predicate = sf::st_within))
  }
  all_sf
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
