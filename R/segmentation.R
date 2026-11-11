#' @title Segment Water Bodies and Surface Moisture Pools
#' @description Detects, delineates, and vectorizes surface water bodies, irrigation trenches, and micro-pooling zones from multispectral indices (NDWI / NDVI) or RGB orthomosaics using spectral thresholding or Deep Learning (SAM).
#' @details Water bodies are extracted using two alternative methodologies:
#' \itemize{
#'   \item \strong{Spectral Thresholding (\code{method = "spectral"}):} Combines negative NDVI or positive NDWI signatures with an optical darkness constraint:
#'     \deqn{\text{WaterMask} = \begin{cases} 1 & \text{if } (\text{NDWI} > \theta_{\text{water}} \text{ or } \text{NDVI} < \theta_{\text{veg}}) \text{ and } \text{Brightness} \le \theta_{\text{dark}} \\ 0 & \text{otherwise} \end{cases}}
#'     \strong{Automatic Detection:} When \code{is_ndwi = NULL} (default), the function inspects the layer name or filepath. If an NDWI/water index is detected, it applies \eqn{\text{threshold} = 0.0} (\eqn{> 0}); if an NDVI/vegetation index is detected, it applies \eqn{\text{threshold} = -0.05} (\eqn{< -0.05}). Users can explicitly override \code{is_ndwi = TRUE/FALSE} and \code{threshold}.
#'   \item \strong{Deep Learning (\code{method = "sam"}):} Utilizes Meta's Segment Anything Model (SAM) via \code{reticulate}. Operates on natural visible RGB imagery (\code{rgb_raster}) to delineate precise morphological water boundaries. Spectral parameters (\code{threshold}, \code{is_ndwi}, \code{max_water_brightness}) are bypassed in favor of visual feature extraction, filtering candidates exclusively by \code{min_area_m2}, \code{max_area_m2}, and \code{exclude_buildings}. Model weights (\code{sam_checkpoint}) are automatically resolved and cached locally on first use.
#' }
#' Extracted pixel clusters are converted to vector polygons (\code{sf}), with calculated surface area (\eqn{\text{m}^2}) and perimeter.
#' @param raster_in SpatRaster or character path. Input NDWI, NDVI, or multispectral raster layer.
#' @param rgb_raster SpatRaster or character path (optional). RGB orthomosaic to enforce optical darkness constraint (water absorbs visible light, while shiny metal/calamina roofs reflect high brightness).
#' @param threshold Numeric (optional). Spectral threshold for water delineation. If \code{NULL} (default), automatically set to \code{0.0} when \code{is_ndwi = TRUE} or \code{-0.05} when \code{is_ndwi = FALSE}.
#' @param is_ndwi Logical (optional). If \code{TRUE}, treats values \eqn{> \text{threshold}} as water. If \code{FALSE}, treats values \eqn{< \text{threshold}} as water (NDVI convention). If \code{NULL} (default), automatically detected from the layer names or filename of \code{raster_in}.
#' @param max_water_brightness Numeric. Maximum allowable mean RGB brightness \eqn{[0, 255]} for water (default: 95.0). Prevents metal roofs and concrete from being classified as water.
#' @param min_area_m2 Numeric. Minimum water body surface area in square meters to retain (default: 2.0). Filters out single-pixel noise.
#' @param max_area_m2 Numeric. Maximum water body surface area in square meters to retain (default: 50000.0).
#' @param method Character. Segmentation algorithm: \code{"spectral"} (default, 100% native R Object-Based GeoAI) or \code{"sam"} (Meta Segment Anything Model via reticulate/Python). When \code{method = "sam"}, delineation is driven by SAM on RGB imagery and filtered by \code{min_area_m2}, \code{max_area_m2}, and \code{exclude_buildings}.
#' @param sam_checkpoint Character path (optional). Path to SAM model weights (.pth) when \code{method = "sam"}. If \code{NULL} (default), automatically checks the internal package cache and downloads Meta's official ViT-B model (~375 MB) on first use.
#' @param exclude_buildings \code{sf} POLYGON object (optional). Residential buildings, roofs, or structures to strictly exclude from water bodies to prevent metal/calamina roofs from being misclassified as water.
#' @return An \code{sf} POLYGON object with columns: \code{water_id}, \code{area_m2}, \code{perimeter_m}, and spatial geometry.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'   library(sf)
#'
#'   # Define paths to NDWI, RGB orthomosaic, and building exclusion layers
#'   ndwi_file  <- system.file("extdata", "ndwi.tif", package = "drones4health")
#'   rgb_file   <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")
#'   houses_sf  <- st_read(system.file("extdata", "buildings.gpkg", package = "drones4health"))
#'
#'   # Segment surface water bodies with brightness filtering and building exclusion
#'   # (is_ndwi and threshold are auto-detected from ndwi_file)
#'   water_sf <- d4h_segment_water(
#'     raster_in            = ndwi_file,
#'     rgb_raster           = rgb_file,
#'     max_water_brightness = 95.0,
#'     min_area_m2          = 2.0,
#'     max_area_m2          = 50000.0,
#'     method               = "spectral",
#'     exclude_buildings    = houses_sf
#'   )
#'   print(water_sf)
#' }
#' }
#' @export
d4h_segment_water <- function(raster_in = NULL, rgb_raster = NULL, threshold = NULL, is_ndwi = NULL, max_water_brightness = 95.0, min_area_m2 = 2.0, max_area_m2 = 50000.0, method = c("spectral", "sam"), sam_checkpoint = NULL, exclude_buildings = NULL) {
  method <- match.arg(method)

  # Check method-specific parameter exceptions and issue informative warnings
  if (method == "sam") {
    if (!is.null(threshold) || !is.null(is_ndwi) || !missing(max_water_brightness)) {
      warning("When method = 'sam', spectral parameters ('threshold', 'is_ndwi', 'max_water_brightness') are ignored. SAM performs deep learning segmentation directly on RGB visual features.", call. = FALSE)
    }
  } else if (method == "spectral") {
    if (!is.null(sam_checkpoint)) {
      warning("When method = 'spectral', SAM parameters ('sam_checkpoint') are ignored. Spectral segmentation uses index and optical brightness thresholds.", call. = FALSE)
    }
  }

  if (is.null(raster_in) && !is.null(rgb_raster)) {
    raster_in <- rgb_raster
  }
  if (is.null(raster_in)) {
    stop("You must provide 'raster_in' (NDWI/NDVI or RGB) or 'rgb_raster'.", call. = FALSE)
  }

  r <- .ensure_raster(raster_in, mask_zeros = FALSE)
  r[is.nan(r) | is.infinite(r)] <- NA

  if (method == "sam") {
    r_sam <- if (!is.null(rgb_raster)) .ensure_raster(rgb_raster, mask_zeros = FALSE) else r
    poly_sf <- .d4h_run_sam(
      r_img = r_sam,
      sam_checkpoint = sam_checkpoint,
      min_area_m2 = min_area_m2,
      max_area_m2 = max_area_m2,
      points_per_side = 16L
    )
    if (nrow(poly_sf) == 0L) {
      warning("No water bodies found by SAM with specified parameters.", call. = FALSE)
      return(sf::st_sf(water_id = character(0), area_m2 = numeric(0), perimeter_m = numeric(0), geometry = sf::st_sfc(crs = sf::st_crs(terra::crs(r_sam)))))
    }

    # Exclude buildings if provided
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

  # Intelligent autodetection of spectral polarity (is_ndwi) and threshold for spectral method
  if (is.null(is_ndwi)) {
    layer_names <- tolower(names(r))
    path_str <- if (is.character(raster_in)) tolower(basename(raster_in)) else ""
    combo_str <- paste(c(layer_names, path_str), collapse = " ")

    if (grepl("ndwi|mndwi|water|moisture|aweish|aweinsh", combo_str)) {
      is_ndwi <- TRUE
    } else if (grepl("ndvi|evi|savi|msavi|vari|ctvi|gndvi|dvi|ndre|veg", combo_str)) {
      is_ndwi <- FALSE
    } else {
      is_ndwi <- TRUE
      message("ℹ 'is_ndwi' not specified and could not be inferred from layer names ('", names(r)[1], "'). Defaulting to NDWI (water > threshold). Set 'is_ndwi = FALSE' if supplying an NDVI/vegetation index.")
    }
  }

  if (is.null(threshold)) {
    threshold <- if (isTRUE(is_ndwi)) 0.0 else -0.05
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
#' @details Buildings are extracted using two alternative methodologies:
#' \itemize{
#'   \item \strong{Spectral OBIA (\code{method = "spectral"}):} Combines high surface brightness (corrugated metal/calamina roofs, \eqn{\text{RGB}_{\text{mean}} \ge \theta_{\text{bright}}}) and red-clay tile chromatic signatures with vegetation exclusion constraints (\eqn{\text{NDVI} < \theta_{\text{ndvi}}}):
#'     \deqn{\text{BuildingCandidate} = \begin{cases} 1 & \text{if } (\text{Brightness} \ge \theta_{\text{bright}} \lor \text{RedTile}) \text{ and } \text{NDVI} < \theta_{\text{ndvi}} \\ 0 & \text{otherwise} \end{cases}}
#'   \item \strong{Deep Learning (\code{method = "sam"}):} Utilizes Meta's Segment Anything Model (SAM) via \code{reticulate}. Delineates geometric regular roof boundaries directly from the 3-band visible RGB orthomosaic. Spectral thresholds (\code{brightness_min}, \code{ndvi_max}) are bypassed, filtering candidates exclusively by \code{min_area_m2} and \code{max_area_m2}. Model weights are automatically managed in the internal package cache.
#' }
#' Vectorized candidates are filtered by residential building footprints (\eqn{12\text{ m}^2 \le \text{Area} \le 600\text{ m}^2}), with centroid coordinates computed.
#' @param rgb_raster SpatRaster or character path. Ultra-high resolution 3-band RGB orthomosaic.
#' @param ndvi_raster SpatRaster or character path (optional). NDVI layer to exclude green vegetation canopies.
#' @param min_area_m2 Numeric. Minimum building footprint surface area in square meters (default: 12.0).
#' @param max_area_m2 Numeric. Maximum building footprint surface area in square meters (default: 500.0).
#' @param brightness_min Numeric. Minimum mean RGB brightness threshold \code{[0, 255]} (default: 155.0).
#' @param ndvi_max Numeric. Maximum NDVI threshold to exclude tree canopies over roofs (default: 0.18).
#' @param method Character. Segmentation method: \code{"spectral"} (default, fast native R) or \code{"sam"} (Meta Segment Anything Model). When \code{method = "sam"}, delineation is driven by SAM on RGB imagery and filtered by \code{min_area_m2} and \code{max_area_m2}.
#' @param sam_checkpoint Character path (optional). Model weights path when \code{method = "sam"}. If \code{NULL} (default), automatically checks the internal package cache and downloads Meta's official ViT-B model (~375 MB) on first use.
#' @return An \code{sf} POLYGON object with columns: \code{building_id}, \code{area_m2}, \code{centroid_x}, \code{centroid_y}, and spatial geometry.
#' @references
#' Blaschke, T. (2010). Object based image analysis for remote sensing. \emph{ISPRS Journal of Photogrammetry and Remote Sensing}, 65(1), 2-16. \doi{10.1016/j.isprsjprs.2009.06.004}
#'
#' Kirillov, A., et al. (2023). Segment anything. \emph{arXiv preprint arXiv:2304.02643}.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Define paths to RGB orthomosaic and optional NDVI layer
#'   rgb_file  <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'
#'   # Extract building footprints with optical brightness thresholds and vegetation masking
#'   buildings_sf <- d4h_segment_buildings(
#'     rgb_raster     = rgb_file,
#'     ndvi_raster    = ndvi_file,
#'     min_area_m2    = 12.0,
#'     max_area_m2    = 600.0,
#'     brightness_min = 135.0,
#'     ndvi_max       = 0.25,
#'     method         = "spectral"
#'   )
#'   print(buildings_sf)
#' }
#' }
#' @export
d4h_segment_buildings <- function(rgb_raster, ndvi_raster = NULL, min_area_m2 = 12.0, max_area_m2 = 600.0, brightness_min = 135.0, ndvi_max = 0.25, method = c("spectral", "sam"), sam_checkpoint = NULL) {
  method <- match.arg(method)

  # Check method-specific parameter exceptions and issue informative warnings
  if (method == "sam") {
    if (!is.null(ndvi_raster) || !missing(brightness_min) || !missing(ndvi_max)) {
      warning("When method = 'sam', spectral threshold arguments ('brightness_min', 'ndvi_max', 'ndvi_raster') are ignored. SAM uses prompt-based foundational computer vision on RGB imagery.", call. = FALSE)
    }
  } else if (method == "spectral") {
    if (!is.null(sam_checkpoint)) {
      warning("When method = 'spectral', SAM parameters ('sam_checkpoint') are ignored. Spectral segmentation uses biophysical index and optical brightness thresholding.", call. = FALSE)
    }
  }

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
    r_low <- if (r_fact > 1) terra::aggregate(r[[1]], fact = r_fact, fun = "max", na.rm = TRUE) else r[[1]]
    mask_val <- terra::ifel(r_low > 10 & !is.na(r_low), 1, NA)
    poly_fp <- terra::as.polygons(mask_val, dissolve = TRUE)
    if (length(poly_fp) == 0) return(NULL)
    fp_sf <- suppressWarnings(sf::st_as_sf(poly_fp))
    fp_eroded <- suppressWarnings(sf::st_buffer(fp_sf, dist = buffer_m))
    fp_eroded
  }, error = function(e) NULL)
}

# Helper para resolver o descargar automáticamente el modelo SAM
.d4h_get_sam_checkpoint <- function(sam_checkpoint = NULL) {
  if (!is.null(sam_checkpoint) && file.exists(sam_checkpoint)) {
    return(normalizePath(sam_checkpoint))
  }

  cache_dir <- tools::R_user_dir("drones4health", which = "cache")
  model_cache_file <- file.path(cache_dir, "models", "sam_vit_b_01ec64.pth")

  candidates <- c(
    sam_checkpoint,
    model_cache_file,
    file.path("models", "sam_vit_b_01ec64.pth"),
    file.path("models", "sam_vit_l_0b3195.pth"),
    file.path("models", "sam_vit_h_4b8939.pth"),
    file.path(getwd(), "models", "sam_vit_b_01ec64.pth"),
    system.file("models", "sam_vit_b_01ec64.pth", package = "drones4health")
  )
  candidates <- candidates[!is.null(candidates) & nzchar(candidates)]
  found <- candidates[file.exists(candidates)]

  if (length(found) > 0) {
    return(normalizePath(found[1]))
  }

  # Intelligent automatic download to internal package cache
  target_dir <- file.path(cache_dir, "models")
  if (!dir.exists(target_dir)) {
    dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  }
  target_file <- file.path(target_dir, "sam_vit_b_01ec64.pth")

  url <- "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth"
  message("ℹ SAM model weights not found locally.")
  message("ℹ Downloading official Meta SAM weights (ViT-B, ~375 MB) to package cache directory:")
  message("  ", target_file)
  message("  (This download runs once and remains permanently stored in cache)...")

  tryCatch({
    utils::download.file(url, destfile = target_file, mode = "wb", quiet = FALSE)
    if (file.exists(target_file)) {
      message("✓ Download completed successfully.")
      return(normalizePath(target_file))
    }
  }, error = function(e) {
    stop("Could not automatically download SAM weights: ", conditionMessage(e),
         "\nYou can manually download from: ", url,
         "\nand place it at: ", target_file, call. = FALSE)
  })

  if (!file.exists(target_file)) {
    stop("SAM weights (.pth) could not be found or downloaded.", call. = FALSE)
  }
  normalizePath(target_file)
}

# SAM via reticulate
.d4h_run_sam <- function(r_img, sam_checkpoint = NULL, min_area_m2 = 10.0, max_area_m2 = 50000.0, points_per_side = 16L) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Using 'method = sam' requires the R package 'reticulate'. Install with install.packages('reticulate').", call. = FALSE)
  }

  if (!reticulate::py_available(initialize = FALSE)) {
    py_cands <- c("C:/Python313/python.exe", Sys.which("python.exe"), Sys.which("python"))
    py_cands <- py_cands[file.exists(py_cands)]
    if (length(py_cands) > 0) {
      reticulate::use_python(py_cands[1], required = FALSE)
    }
  }

  sam_checkpoint <- .d4h_get_sam_checkpoint(sam_checkpoint)

  message(sprintf("Initializing Meta Segment Anything (SAM) from: %s ...", sam_checkpoint))
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
  message(sprintf("SAM [%s] running on: %s", model_type, toupper(dev_str)))

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
    message(sprintf("Optimizing resolution for SAM inference (aggregation %dx%d)...", agg_f, agg_f))
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
  py_mod$mask_gen <- mask_gen
  reticulate::py_run_string("
import numpy as np
raw = np.asarray(arr, dtype=np.float32)
img_np = raw.reshape((h_dim, w_dim, 3), order='F')
img_np = np.ascontiguousarray(np.clip(img_np, 0, 255), dtype=np.uint8)
masks = mask_gen.generate(img_np)
")
  masks <- py_mod$masks
  num_masks <- length(masks)
  message(sprintf("SAM detected %d masks.", num_masks))

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
#' @param proximity_labels Character vector (optional). Custom names for each stratified proximity tier (alternative to \code{risk_labels}).
#' @return An \code{sf} object matching \code{buildings} with appended columns: \code{dist_water_m}, \code{nearest_water_id}, \code{proximity_score} in \code{[0, 1]}, and \code{proximity_level}.
#' @references
#' World Health Organization. (2020). \emph{Operational framework for building climate resilient health systems}. World Health Organization.
#'
#' Guerra, C. A., Snow, R. W., & Hay, S. I. (2006). Mapping the global extent of malaria in 2005. \emph{Trends in Parasitology}, 22(8), 353-358. \doi{10.1016/j.pt.2006.06.006}
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(sf)
#'
#'   # Load building and water source polygons
#'   houses_sf <- st_read(system.file("extdata", "buildings.gpkg", package = "drones4health"))
#'   water_sf  <- st_read(system.file("extdata", "water_bodies.gpkg", package = "drones4health"))
#'
#'   # Calculate Euclidean distance and vector proximity scores with custom tiers
#'   proximity_sf <- d4h_distance_to_water(
#'     buildings        = houses_sf,
#'     sources          = water_sf,
#'     decay_lambda     = 100.0,
#'     buffer_breaks    = c(50, 100, 200),
#'     proximity_labels = c("Immediate (<50m)", "High (50-100m)", "Moderate (100-200m)", "Distal (>200m)")
#'   )
#'   head(proximity_sf)
#' }
#' }
#' @export
d4h_distance_to_water <- function(buildings, sources, decay_lambda = 100.0, buffer_breaks = c(50, 100, 200), risk_labels = c("Critico (<50m)", "Alto (50-100m)", "Moderado (100-200m)", "Bajo (>200m)"), proximity_labels = NULL) {
  if (!is.null(proximity_labels)) {
    risk_labels <- proximity_labels
  }

  if (is.character(buildings) && length(buildings) == 1L) {
    if (grepl("\\.(xlsx|xls)$", buildings, ignore.case = TRUE)) {
      df_b <- as.data.frame(readxl::read_excel(buildings))
      lon_c <- grep("^(lon|lng|long|longitude|x)$", names(df_b), ignore.case = TRUE, value = TRUE)[1]
      lat_c <- grep("^(lat|latitude|y)$", names(df_b), ignore.case = TRUE, value = TRUE)[1]
      buildings <- sf::st_as_sf(df_b, coords = c(lon_c, lat_c), crs = 4326)
    } else if (grepl("\\.csv$", buildings, ignore.case = TRUE)) {
      df_b <- utils::read.csv(buildings)
      lon_c <- grep("^(lon|lng|long|longitude|x)$", names(df_b), ignore.case = TRUE, value = TRUE)[1]
      lat_c <- grep("^(lat|latitude|y)$", names(df_b), ignore.case = TRUE, value = TRUE)[1]
      buildings <- sf::st_as_sf(df_b, coords = c(lon_c, lat_c), crs = 4326)
    } else {
      buildings <- sf::st_read(buildings, quiet = TRUE)
    }
  } else if (is.data.frame(buildings) && !inherits(buildings, "sf")) {
    lon_c <- grep("^(lon|lng|long|longitude|x)$", names(buildings), ignore.case = TRUE, value = TRUE)[1]
    lat_c <- grep("^(lat|latitude|y)$", names(buildings), ignore.case = TRUE, value = TRUE)[1]
    buildings <- sf::st_as_sf(buildings, coords = c(lon_c, lat_c), crs = 4326)
  }

  if (inherits(sources, "SpatVector")) {
    sources <- sf::st_as_sf(sources)
  } else if (is.character(sources) && length(sources) == 1L) {
    sources <- sf::st_read(sources, quiet = TRUE)
  }

  if (!inherits(buildings, "sf") || !inherits(sources, "sf")) {
    stop("'buildings' and 'sources' must be sf spatial objects or valid spatial filepaths.", call. = FALSE)
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
  res_sf$proximity_score <- res_sf$risk_score
  res_sf$proximity_level <- res_sf$risk_level

  res_sf
}

#' @title Continuous Euclidean Distance Raster from Risk Sources
#' @description Computes a continuous Euclidean distance surface raster (heat map) measuring proximity to water bodies, breeding sites, or waste clusters across the entire flight extent.
#' @param sources \code{sf} or \code{SpatVector} spatial object containing risk source polygons/points.
#' @param raster_ref SpatRaster or character path. Reference raster layer defining spatial grid dimensions and CRS.
#' @return A SpatRaster where each pixel represents the Euclidean distance in meters to the nearest risk source.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'   library(sf)
#'
#'   # Reference flight raster and water polygon sources
#'   ref_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'   water_sf <- st_read(system.file("extdata", "water_bodies.gpkg", package = "drones4health"))
#'
#'   # Compute continuous distance-to-water risk surface
#'   r_dist <- d4h_raster_distance(sources = water_sf, raster_ref = ref_file)
#'   plot(r_dist)
#' }
#' }
#' @export
d4h_raster_distance <- function(sources, raster_ref = NULL, template_raster = NULL, max_dist_m = NULL) {
  if (is.null(raster_ref) && !is.null(template_raster)) {
    raster_ref <- template_raster
  }
  if (is.null(raster_ref)) {
    stop("You must provide 'raster_ref' or 'template_raster'.", call. = FALSE)
  }
  r_ref <- .ensure_raster(raster_ref, mask_zeros = FALSE)

  if (terra::ncell(r_ref) > 1000000) {
    fact <- ceiling(sqrt(terra::ncell(r_ref) / 1000000))
    r_ref <- terra::aggregate(r_ref, fact = fact, fun = "mean", na.rm = TRUE)
  }

  sources_vect <- if (inherits(sources, "sf")) terra::vect(sources) else sources

  r_rasterized <- terra::rasterize(sources_vect, r_ref, field = 1, background = NA)
  dist_raster <- terra::distance(r_rasterized)

  # Mask continuous distance surface to valid pixels of reference raster (crop outer NA areas)
  dist_raster <- terra::mask(dist_raster, r_ref)

  if (!is.null(max_dist_m) && is.numeric(max_dist_m)) {
    dist_raster <- terra::clamp(dist_raster, lower = 0, upper = max_dist_m)
  }

  names(dist_raster) <- "dist_to_source_m"
  dist_raster
}

#' @title Combine and Summarize Physical Water and Building Features
#' @description Merges segmented water bodies and residential building footprints into a harmonized spatial feature collection, calculating overall counts, total surface areas, and printing an executive summary report.
#' @details Combines vector outputs from \code{\link{d4h_segment_water}} and \code{\link{d4h_segment_buildings}} into an unified \code{sf} object with columns \code{feature_id}, \code{feature_type} (\code{"Water"} or \code{"Building"}), and \code{area_m2}.
#' The returned object can be passed directly to \code{\link{d4h_plot}} for overlay onto drone orthomosaics, or to \code{\link{d4h_executive_summary}} for automatic zonal grid aggregation.
#'
#' @param water \code{sf}, \code{SpatVector}, or character path. Segmented water body polygons (e.g. from \code{d4h_segment_water}).
#' @param buildings \code{sf}, \code{SpatVector}, or character path. Segmented dwelling/building footprints (e.g. from \code{d4h_segment_buildings}).
#' @param houses Deprecated alias for \code{buildings}.
#' @param quiet Logical. If TRUE, suppresses console summary printing (default: FALSE).
#' @return An \code{sf} object of class \code{c("d4h_features", "sf", "data.frame")} containing the combined features with attributes \code{feature_id}, \code{feature_type}, \code{area_m2}, and a detailed summary attribute.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'
#'   # Combine segmented water and building layers
#'   features <- d4h_combine_features(
#'     water     = water_sf,
#'     buildings = buildings_sf
#'   )
#'   print(features)
#' }
#' }
#' @export
d4h_combine_features <- function(water = NULL, buildings = NULL, houses = NULL, quiet = FALSE) {
  if (is.null(buildings) && !is.null(houses)) {
    buildings <- houses
  }

  water_sf <- if (!is.null(water)) {
    if (is.character(water) && length(water) == 1L) sf::st_read(water, quiet = TRUE)
    else if (inherits(water, "SpatVector")) sf::st_as_sf(water)
    else if (inherits(water, "sf")) water
    else NULL
  } else NULL

  bld_sf <- if (!is.null(buildings)) {
    if (is.character(buildings) && length(buildings) == 1L) sf::st_read(buildings, quiet = TRUE)
    else if (inherits(buildings, "SpatVector")) sf::st_as_sf(buildings)
    else if (inherits(buildings, "sf")) buildings
    else NULL
  } else NULL

  if (is.null(water_sf) && is.null(bld_sf)) {
    stop("You must provide at least one feature layer ('water' or 'buildings').", call. = FALSE)
  }

  # Harmonize CRS
  if (!is.null(water_sf) && !is.null(bld_sf)) {
    if (sf::st_crs(water_sf) != sf::st_crs(bld_sf)) {
      bld_sf <- sf::st_transform(bld_sf, sf::st_crs(water_sf))
    }
  }

  feature_list <- list()

  if (!is.null(water_sf) && nrow(water_sf) > 0) {
    w_clean <- water_sf
    w_clean$feature_id <- if ("water_id" %in% names(w_clean)) w_clean$water_id else sprintf("W%04d", seq_len(nrow(w_clean)))
    w_clean$feature_type <- "Water"
    if (!"area_m2" %in% names(w_clean)) {
      w_clean$area_m2 <- round(as.numeric(sf::st_area(w_clean)), 2)
    }
    feature_list[[length(feature_list) + 1L]] <- w_clean[, c("feature_id", "feature_type", "area_m2", "geometry")]
  }

  if (!is.null(bld_sf) && nrow(bld_sf) > 0) {
    b_clean <- bld_sf
    b_clean$feature_id <- if ("building_id" %in% names(b_clean)) b_clean$building_id else sprintf("B%04d", seq_len(nrow(b_clean)))
    b_clean$feature_type <- "Building"
    if (!"area_m2" %in% names(b_clean)) {
      b_clean$area_m2 <- round(as.numeric(sf::st_area(b_clean)), 2)
    }
    feature_list[[length(feature_list) + 1L]] <- b_clean[, c("feature_id", "feature_type", "area_m2", "geometry")]
  }

  res_features <- do.call(rbind, feature_list)
  rownames(res_features) <- NULL
  class(res_features) <- c("d4h_features", class(res_features))

  # Compute summary statistics
  n_water <- if (!is.null(water_sf)) nrow(water_sf) else 0L
  area_water_m2 <- if (!is.null(water_sf) && n_water > 0) sum(water_sf$area_m2, na.rm = TRUE) else 0
  n_bld <- if (!is.null(bld_sf)) nrow(bld_sf) else 0L
  area_bld_m2 <- if (!is.null(bld_sf) && n_bld > 0) sum(bld_sf$area_m2, na.rm = TRUE) else 0

  summary_data <- list(
    water_count       = n_water,
    water_area_m2     = round(area_water_m2, 2),
    water_area_ha     = round(area_water_m2 / 10000, 3),
    water_mean_m2     = if (n_water > 0) round(mean(water_sf$area_m2, na.rm = TRUE), 2) else 0,
    buildings_count   = n_bld,
    buildings_area_m2 = round(area_bld_m2, 2),
    buildings_area_ha = round(area_bld_m2 / 10000, 3),
    buildings_mean_m2 = if (n_bld > 0) round(mean(bld_sf$area_m2, na.rm = TRUE), 2) else 0
  )
  attr(res_features, "summary_data") <- summary_data

  if (!quiet) {
    cat("\n")
    cat(rep("=", 78), "\n", sep = "")
    cat("             DRONES4HEALTH - PHYSICAL FEATURES DETECTION SUMMARY\n")
    cat(rep("=", 78), "\n\n", sep = "")
    cat(" 1. SURFACE WATER BODIES:\n")
    cat(sprintf("    - Total features detected   : %d pools / bodies\n", n_water))
    cat(sprintf("    - Total water surface area  : %s m2 (%s ha)\n",
                format(round(area_water_m2, 1), big.mark = ","), round(area_water_m2 / 10000, 3)))
    cat(sprintf("    - Mean pool surface area    : %.1f m2\n\n",
                summary_data$water_mean_m2))

    cat(" 2. RESIDENTIAL DWELLINGS / ROOFS:\n")
    cat(sprintf("    - Total structures detected : %d buildings\n", n_bld))
    cat(sprintf("    - Total built roof area     : %s m2 (%s ha)\n",
                format(round(area_bld_m2, 1), big.mark = ","), round(area_bld_m2 / 10000, 3)))
    cat(sprintf("    - Mean dwelling roof area   : %.1f m2\n",
                summary_data$buildings_mean_m2))
    cat(rep("=", 78), "\n\n", sep = "")
  }

  res_features
}

#' @rdname d4h_combine_features
#' @export
d4h_add_features <- d4h_combine_features

#' @export
print.d4h_features <- function(x, ...) {
  s <- attr(x, "summary_data")
  if (!is.null(s)) {
    cat(sprintf("d4h_features: %d water bodies (%.2f ha) | %d buildings (%.2f ha)\n",
                s$water_count, s$water_area_ha, s$buildings_count, s$buildings_area_ha))
  }
  NextMethod()
}
