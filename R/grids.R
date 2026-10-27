#' @title Summarize Raster Indicator by Spatial Grid
#' @description Generates a square or hexagonal spatial grid and extracts zonal summary statistics (mean, quantiles) of raster indicators per grid cell.
#' @details Zonal extraction aggregates high-resolution pixel values into operational territorial units:
#' \deqn{\bar{x}_k = \frac{1}{N_k} \sum_{i \in \text{Cell}_k} x_i}
#' Empty grid cells outside the valid flight footprint are automatically pruned when \code{discard_na = TRUE}.
#' @param raster_in SpatRaster or character. Input raster layer, stack, or path to file.
#' @param cell_size Numeric. Grid cell size / diameter in meters (default: 20).
#' @param square Logical. If TRUE, creates square cells; if FALSE, hexagonal cells (default: TRUE).
#' @param discard_na Logical. If TRUE, removes grid cells outside the valid raster data area (default: TRUE).
#' @return A SpatVector containing the grid cells with extracted mean values.
#' @references
#' Birch, C. P., Oom, S. P., & Beecham, J. A. (2007). Rectangular and hexagonal grids used for observation, experiment and simulation in ecology. \emph{Ecological Modelling}, 206(3-4), 347-359. \doi{10.1016/j.ecolmodel.2007.03.041}
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Load continuous indicator raster
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'
#'   # Aggregate NDVI values into a 50m hexagonal surveillance grid
#'   grid_summary <- d4h_summarize_grid(
#'     raster_in = ndvi_file,
#'     cell_size = 50,
#'     square = FALSE,
#'     discard_na = TRUE
#'   )
#'   head(grid_summary)
#' }
#' }
#' @export
d4h_summarize_grid <- function(raster_in, cell_size = 20, square = TRUE, discard_na = TRUE) {
  r <- if (is.character(raster_in) && length(raster_in) == 1L) {
    if (!file.exists(raster_in)) stop(paste("File not found:", raster_in), call. = FALSE)
    terra::rast(raster_in)
  } else if (inherits(raster_in, "SpatRaster")) {
    raster_in
  } else {
    stop("'raster_in' must be a SpatRaster object or a valid file path string.", call. = FALSE)
  }

  boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(r), crs = terra::crs(r)))
  grid_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = square)

  prefix <- if (square) "G%04d" else "H%04d"
  grid_sf <- sf::st_sf(
    grid_id = sprintf(prefix, seq_along(grid_sf)),
    geometry = grid_sf
  )
  grid_vect <- terra::vect(grid_sf)

  summary_vect <- terra::extract(r, grid_vect, fun = mean, na.rm = TRUE, bind = TRUE)

  if (discard_na) {
    first_layer <- names(r)[1]
    vals <- summary_vect[[first_layer]][, 1]
    summary_vect <- summary_vect[!is.na(vals) & !is.nan(vals) & vals != 0, ]
  }

  summary_vect
}

#' @title Generate Hexagonal Surveillance Grid
#' @description Creates an operative hexagonal surveillance grid with unique alphanumeric identifiers over an Area of Interest (AOI).
#' @details Hexagonal spatial partitions minimize perimeter-to-area ratio and provide equidistant neighborhood connectivity:
#' \deqn{A_{\text{hex}} = \frac{3\sqrt{3}}{2} r^2}
#' Ideal for vector control teams, larviciding deployments, and spatial health sampling.
#' By default, cells are clipped strictly to the valid non-NA flight footprint of the raster or polygon boundaries (\code{clip_to_footprint = TRUE})
#' to prevent artificial bounding-box grid padding outside the surveyed area.
#' @param aoi SpatRaster, SpatVector, sf, or character path defining the spatial bounds or mosaic.
#' @param cell_size Numeric. Hexagon diameter in meters (default: 50).
#' @param clip_to_footprint Logical. If TRUE (default), restricts grid cells strictly to the valid non-NA flight footprint of the input raster or polygon boundaries.
#' @return A SpatVector containing the hexagonal grid polygons with unique IDs.
#' @references
#' Carr, D. B., Olsen, A. R., & White, D. (1992). Hexagon mosaic maps for display of univariate and bivariate data. \emph{Cartography and Geographic Information Systems}, 19(4), 228-236. \doi{10.1559/152304092783721231}
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Define Area of Interest raster
#'   aoi_file <- system.file("extdata", "ortho_rgb.tif", package = "drones4health")
#'
#'   # Create hexagonal grid cells with 50-meter diameter clipped to flight footprint
#'   hex_grid <- d4h_hex_grid(aoi = aoi_file, cell_size = 50, clip_to_footprint = TRUE)
#'   plot(hex_grid)
#' }
#' }
#' @export
d4h_hex_grid <- function(aoi, cell_size = 50, clip_to_footprint = TRUE) {
  if (is.character(aoi) && length(aoi) == 1L) {
    if (!file.exists(aoi)) stop(paste("File not found:", aoi), call. = FALSE)
    aoi <- tryCatch(sf::st_read(aoi, quiet = TRUE), error = function(e) terra::rast(aoi))
  }

  boundary_sf <- NULL

  if (inherits(aoi, "SpatRaster")) {
    if (isTRUE(clip_to_footprint)) {
      r1 <- aoi[[1]]
      if (terra::ncell(r1) > 2000000) {
        fact <- ceiling(sqrt(terra::ncell(r1) / 500000))
        r_mask <- terra::aggregate(r1, fact = fact, fun = function(v, ...) any(!is.na(v) & !is.nan(v) & v != 0))
      } else {
        r_mask <- !is.na(r1) & !is.nan(r1) & r1 != 0
      }
      r_mask[r_mask == 0] <- NA
      poly <- terra::as.polygons(r_mask, dissolve = TRUE)
      boundary_sf <- sf::st_make_valid(sf::st_as_sf(poly))
    } else {
      boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(aoi), crs = terra::crs(aoi)))
    }
  } else if (inherits(aoi, "SpatVector")) {
    boundary_sf <- sf::st_make_valid(sf::st_as_sf(aoi))
  } else if (inherits(aoi, "sf")) {
    boundary_sf <- sf::st_make_valid(aoi)
  } else {
    stop("'aoi' must be a SpatRaster, SpatVector, sf object, or valid file path.", call. = FALSE)
  }

  grid_raw <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = FALSE)
  grid_sf <- sf::st_sf(geometry = grid_raw)

  if (isTRUE(clip_to_footprint) && !is.null(boundary_sf)) {
    inter <- sf::st_intersects(grid_sf, boundary_sf, sparse = FALSE)
    keep <- apply(inter, 1, any)
    grid_sf <- grid_sf[keep, ]
  }

  grid_sf$grid_id <- sprintf("H%04d", seq_len(nrow(grid_sf)))
  terra::vect(grid_sf)
}

#' @title Summarize Raster Indicator for the General Mosaic Footprint
#' @description Computes the overall mean value of raster layers across the entire area of interest (AOI) as a single spatial vector polygon (SpatVector), formatted identically to zonal grid summaries for consistent map plotting.
#' @param raster_in SpatRaster or character. Input raster layer, stack, or path to file.
#' @param exact_boundary Logical. If TRUE, traces the exact outer boundary of valid non-NA flight data; if FALSE, uses the bounding box extent (default: TRUE).
#' @return A SpatVector with a single polygon containing the overall mean value(s).
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Load environmental index raster
#'   twi_file <- system.file("extdata", "twi.tif", package = "drones4health")
#'
#'   # Extract overall mean across the flight mosaic footprint
#'   gen_summary <- d4h_summarize_general(raster_in = twi_file, exact_boundary = TRUE)
#'   print(gen_summary)
#' }
#' }
#' @export
d4h_summarize_general <- function(raster_in, exact_boundary = TRUE) {
  r <- if (is.character(raster_in) && length(raster_in) == 1L) {
    if (!file.exists(raster_in)) stop(paste("File not found:", raster_in), call. = FALSE)
    terra::rast(raster_in)
  } else if (inherits(raster_in, "SpatRaster")) {
    raster_in
  } else {
    stop("'raster_in' must be a SpatRaster object or a valid file path string.", call. = FALSE)
  }

  boundary_vect <- if (exact_boundary) {
    r1 <- r[[1]]
    total_cells <- terra::ncell(r1)
    agg_fact <- if (total_cells > 100000) ceiling(sqrt(total_cells / 50000)) else 1
    r_agg <- if (agg_fact > 1) {
      terra::aggregate(!is.na(r1) & r1 != 0, fact = agg_fact, fun = "max", na.rm = TRUE)
    } else {
      !is.na(r1) & r1 != 0
    }
    poly <- terra::as.polygons(r_agg, dissolve = TRUE)
    poly <- poly[poly[[1]][, 1] == 1, ]
    sf_poly <- sf::st_as_sf(poly)
    sf_poly <- sf::st_sf(grid_id = "GENERAL", geometry = sf::st_geometry(sf_poly))
    terra::vect(sf_poly)
  } else {
    boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(r), crs = terra::crs(r)))
    sf_poly <- sf::st_sf(grid_id = "GENERAL", geometry = sf::st_geometry(boundary_sf))
    terra::vect(sf_poly)
  }

  summary_vect <- terra::extract(r, boundary_vect, fun = mean, na.rm = TRUE, bind = TRUE)
  summary_vect
}

#' @title Convert Raster Indicator to General Homogeneous Mosaic
#' @description Creates a continuous SpatRaster matching the exact spatial footprint of the input raster where all valid pixels are assigned the overall global mean value.
#' @param raster_in SpatRaster or character. Input raster layer, stack, or path to file.
#' @return A SpatRaster with the mosaic footprint filled with the global mean value.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Load index raster
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'
#'   # Generate homogeneous mosaic filled with global mean value
#'   r_homo <- d4h_raster_general(raster_in = ndvi_file)
#'   plot(r_homo)
#' }
#' }
#' @export
d4h_raster_general <- function(raster_in) {
  r <- if (is.character(raster_in) && length(raster_in) == 1L) {
    if (!file.exists(raster_in)) stop(paste("File not found:", raster_in), call. = FALSE)
    terra::rast(raster_in)
  } else if (inherits(raster_in, "SpatRaster")) {
    raster_in
  } else {
    stop("'raster_in' must be a SpatRaster object or a valid file path string.", call. = FALSE)
  }

  r_out <- r
  for (i in seq_len(terra::nlyr(r))) {
    lyr <- r[[i]]
    m_val <- as.numeric(terra::global(lyr, "mean", na.rm = TRUE)[, 1])
    r_out[[i]] <- terra::ifel(!is.na(lyr) & lyr != 0, m_val, NA)
  }
  names(r_out) <- names(r)
  r_out
}


#' @title Spatial Grid Proximity and Exposure Modeling to Water Bodies
#' @description Computes the minimum Euclidean distance from each operational grid cell (square or hexagonal) to the nearest water body or aquatic habitat, calculates exponential proximity exposure scores in [0, 1], and stratifies grid units into operational priority tiers.
#' @details Evaluates spatial exposure at the operational territorial level:
#' \deqn{\text{Proximity Score} = \exp\left(-\frac{\text{Distance}}{\lambda}\right)}
#' Grid cells directly intersecting or located in close proximity to standing water bodies receive high priority scores (\eqn{\to 1.0}), enabling health brigades to prioritize interventions by territorial sectors rather than individual dwellings alone.
#' @param grid SpatVector, sf, or character path. Operational surveillance grid (e.g. generated via \code{d4h_hex_grid} or \code{d4h_summarize_grid}).
#' @param water_bodies SpatVector, sf, or character path. Water polygons or aquatic vector features.
#' @param decay_lambda Numeric. Exponential decay half-distance parameter in meters (default: 100.0).
#' @param buffer_breaks Numeric vector. Distance cutoffs in meters for stratified tiers (default: \code{c(50, 100, 200)}).
#' @param proximity_labels Character vector. Names for each stratified priority tier (default: \code{c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)", "Low (>200m)")}).
#' @return An \code{sf} object containing the grid cells with appended columns: \code{dist_water_m}, \code{nearest_water_id}, \code{proximity_score}, and \code{proximity_level}.
#' @references
#' World Health Organization. (2020). \emph{Operational framework for building climate resilient health systems}. World Health Organization.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'   library(sf)
#'
#'   # Generate surveillance grid and load water features
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'   grid_hex  <- d4h_hex_grid(ndvi_file, cell_size = 50)
#'   water_sf  <- st_read(system.file("extdata", "water_bodies.gpkg", package = "drones4health"))
#'
#'   # Score grid units by proximity to water
#'   grid_scored <- d4h_grid_distance_to_water(
#'     grid         = grid_hex,
#'     water_bodies = water_sf,
#'     decay_lambda = 100.0
#'   )
#'   head(grid_scored)
#' }
#' }
#' @export
d4h_grid_distance_to_water <- function(grid, water_bodies, decay_lambda = 100.0,
                                       buffer_breaks = c(50, 100, 200),
                                       proximity_labels = c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)", "Low (>200m)")) {

  # 1. Validar y convertir grid a sf
  grid_sf <- if (is.character(grid) && length(grid) == 1L) {
    if (!file.exists(grid)) stop(paste("File not found:", grid), call. = FALSE)
    sf::st_read(grid, quiet = TRUE)
  } else if (inherits(grid, "SpatVector")) {
    sf::st_as_sf(grid)
  } else if (inherits(grid, "sf")) {
    grid
  } else {
    stop("'grid' must be an sf, SpatVector, or valid file path.", call. = FALSE)
  }

  # 2. Validar y convertir water_bodies a sf
  water_sf <- if (is.character(water_bodies) && length(water_bodies) == 1L) {
    if (!file.exists(water_bodies)) stop(paste("File not found:", water_bodies), call. = FALSE)
    sf::st_read(water_bodies, quiet = TRUE)
  } else if (inherits(water_bodies, "SpatVector")) {
    sf::st_as_sf(water_bodies)
  } else if (inherits(water_bodies, "sf")) {
    water_bodies
  } else {
    stop("'water_bodies' must be an sf, SpatVector, or valid file path.", call. = FALSE)
  }

  if (nrow(grid_sf) == 0L || nrow(water_sf) == 0L) {
    stop("'grid' and 'water_bodies' must contain at least one feature.", call. = FALSE)
  }

  # 3. Homologar CRS
  if (sf::st_crs(grid_sf) != sf::st_crs(water_sf)) {
    water_sf <- sf::st_transform(water_sf, sf::st_crs(grid_sf))
  }

  # 4. Calcular distancia minima desde el poligono de cada celda a los cuerpos de agua
  dists_matrix <- sf::st_distance(grid_sf, water_sf)
  min_dists <- apply(dists_matrix, 1, min)
  nearest_idx <- apply(dists_matrix, 1, which.min)

  water_id_col <- if ("water_id" %in% names(water_sf)) "water_id" else names(water_sf)[1]

  res_sf <- grid_sf
  res_sf$dist_water_m <- round(as.numeric(min_dists), 1)
  res_sf$nearest_water_id <- as.character(water_sf[[water_id_col]][nearest_idx])

  # Score de proximidad exponencial en [0, 1]
  res_sf$proximity_score <- round(exp(-res_sf$dist_water_m / as.numeric(decay_lambda)), 3)

  # Estratificacion por categorias operativas
  breaks <- c(-Inf, buffer_breaks, Inf)
  res_sf$proximity_level <- cut(
    res_sf$dist_water_m,
    breaks = breaks,
    labels = proximity_labels,
    include.lowest = TRUE
  )

  # Compatibilidad backward
  res_sf$risk_score <- res_sf$proximity_score
  res_sf$risk_level <- res_sf$proximity_level

  res_sf
}

#' @title Grid-Level Land Cover Percentage Composition and Feature Segmentation
#' @description Computes the percentage composition of physical features (houses/buildings, water bodies, vegetation canopy, bare soil) across each operational grid cell, providing granular sectoral profiles for micro-environmental surveillance.
#' @details Intersects vector feature boundaries or raster masks with square/hexagonal grid cells:
#' \deqn{\text{Pct}_{\text{class}} = \frac{\text{Area}_{\text{class} \cap \text{Cell}_k}}{\text{Area}_{\text{Cell}_k}} \times 100}
#' Computes individual coverage metrics (\code{pct_houses}, \code{pct_water}, \code{pct_vegetation}, \code{pct_bare_soil}), identifies the dominant land cover class, and assigns sectoral priority tiers based on the co-occurrence of dwellings and standing water habitats.
#' @param grid SpatVector, sf, or character path. Operational surveillance grid (e.g. from \code{d4h_hex_grid} or \code{d4h_summarize_grid}).
#' @param water SpatVector, sf, or SpatRaster (optional). Segmented water body polygons or binary water raster.
#' @param buildings SpatVector, sf, or SpatRaster (optional). Segmented dwelling/building footprints or binary roof raster.
#' @param ndvi_raster SpatRaster or character path (optional). NDVI continuous raster to determine vegetation and bare soil cover.
#' @param veg_threshold Numeric. NDVI threshold above which pixels are categorized as vegetation (default: 0.3).
#' @param soil_threshold Numeric. NDVI upper threshold below which non-water pixels are categorized as bare soil (default: 0.15).
#' @param out_xlsx Character (optional). File path to export a structured Excel spreadsheet.
#' @return An \code{sf} object with appended columns: \code{area_m2}, \code{pct_houses}, \code{pct_water}, \code{pct_vegetation}, \code{pct_bare_soil}, \code{n_houses}, \code{n_water_bodies}, \code{dominant_class}, and \code{surveillance_priority}.
#' @export
d4h_grid_composition <- function(grid,
                                 water = NULL,
                                 buildings = NULL,
                                 ndvi_raster = NULL,
                                 veg_threshold = 0.3,
                                 soil_threshold = 0.15,
                                 out_xlsx = NULL) {
  # 1. Validar y convertir grid a sf
  grid_sf <- if (is.character(grid) && length(grid) == 1L) {
    if (!file.exists(grid)) stop(paste("File not found:", grid), call. = FALSE)
    sf::st_read(grid, quiet = TRUE)
  } else if (inherits(grid, "SpatVector")) {
    sf::st_as_sf(grid)
  } else if (inherits(grid, "sf")) {
    grid
  } else {
    stop("'grid' must be an sf, SpatVector, or valid file path.", call. = FALSE)
  }

  if (nrow(grid_sf) == 0L) {
    stop("'grid' must contain at least one feature.", call. = FALSE)
  }

  if (!"grid_id" %in% names(grid_sf)) {
    grid_sf$grid_id <- sprintf("G%04d", seq_len(nrow(grid_sf)))
  }

  # Calcular area total de cada celda en m2
  grid_sf$area_m2 <- round(as.numeric(sf::st_area(grid_sf)), 1)
  target_crs <- sf::st_crs(grid_sf)

  # 2. Interseccion y calculo porcentual de Agua
  pct_water_vec <- numeric(nrow(grid_sf))
  n_water_vec <- integer(nrow(grid_sf))

  if (!is.null(water)) {
    water_sf <- if (is.character(water) && length(water) == 1L) {
      sf::st_read(water, quiet = TRUE)
    } else if (inherits(water, "SpatVector")) {
      sf::st_as_sf(water)
    } else if (inherits(water, "sf")) {
      water
    } else {
      NULL
    }

    if (!is.null(water_sf) && nrow(water_sf) > 0L) {
      if (sf::st_crs(water_sf) != target_crs) {
        water_sf <- sf::st_transform(water_sf, target_crs)
      }
      water_valid <- suppressWarnings(sf::st_make_valid(water_sf))
      grid_valid <- suppressWarnings(sf::st_make_valid(grid_sf))

      inter_w <- suppressWarnings(sf::st_intersection(water_valid, grid_valid))
      if (nrow(inter_w) > 0L) {
        inter_w$w_area <- as.numeric(sf::st_area(inter_w))
        agg_w <- stats::aggregate(w_area ~ grid_id, data = inter_w, FUN = sum)
        agg_cnt <- stats::aggregate(w_area ~ grid_id, data = inter_w, FUN = length)
        names(agg_cnt)[2] <- "w_count"

        m_w <- match(grid_sf$grid_id, agg_w$grid_id)
        m_cnt <- match(grid_sf$grid_id, agg_cnt$grid_id)

        w_areas <- ifelse(is.na(m_w), 0, agg_w$w_area[m_w])
        pct_water_vec <- round(pmin(100, (w_areas / grid_sf$area_m2) * 100), 1)
        n_water_vec <- ifelse(is.na(m_cnt), 0L, as.integer(agg_cnt$w_count[m_cnt]))
      }
    }
  }

  # 3. Interseccion y calculo porcentual de Casas / Edificaciones
  pct_bld_vec <- numeric(nrow(grid_sf))
  n_bld_vec <- integer(nrow(grid_sf))

  if (!is.null(buildings)) {
    bld_sf <- if (is.character(buildings) && length(buildings) == 1L) {
      sf::st_read(buildings, quiet = TRUE)
    } else if (inherits(buildings, "SpatVector")) {
      sf::st_as_sf(buildings)
    } else if (inherits(buildings, "sf")) {
      buildings
    } else {
      NULL
    }

    if (!is.null(bld_sf) && nrow(bld_sf) > 0L) {
      if (sf::st_crs(bld_sf) != target_crs) {
        bld_sf <- sf::st_transform(bld_sf, target_crs)
      }
      bld_valid <- suppressWarnings(sf::st_make_valid(bld_sf))
      grid_valid <- suppressWarnings(sf::st_make_valid(grid_sf))

      inter_b <- suppressWarnings(sf::st_intersection(bld_valid, grid_valid))
      if (nrow(inter_b) > 0L) {
        inter_b$b_area <- as.numeric(sf::st_area(inter_b))
        agg_b <- stats::aggregate(b_area ~ grid_id, data = inter_b, FUN = sum)
        agg_bcnt <- stats::aggregate(b_area ~ grid_id, data = inter_b, FUN = length)
        names(agg_bcnt)[2] <- "b_count"

        m_b <- match(grid_sf$grid_id, agg_b$grid_id)
        m_bcnt <- match(grid_sf$grid_id, agg_bcnt$grid_id)

        b_areas <- ifelse(is.na(m_b), 0, agg_b$b_area[m_b])
        pct_bld_vec <- round(pmin(100, (b_areas / grid_sf$area_m2) * 100), 1)
        n_bld_vec <- ifelse(is.na(m_bcnt), 0L, as.integer(agg_bcnt$b_count[m_bcnt]))
      }
    }
  }

  # 4. Proporciones de Vegetacion y Suelo Desnudo
  pct_veg_vec <- numeric(nrow(grid_sf))
  pct_soil_vec <- numeric(nrow(grid_sf))

  if (!is.null(ndvi_raster)) {
    r_ndvi <- if (is.character(ndvi_raster) && length(ndvi_raster) == 1L) {
      terra::rast(ndvi_raster)
    } else if (inherits(ndvi_raster, "SpatRaster")) {
      ndvi_raster
    } else {
      NULL
    }

    if (!is.null(r_ndvi)) {
      grid_v <- terra::vect(grid_sf)
      ex_vals <- suppressWarnings(terra::extract(r_ndvi[[1]], grid_v))
      cell_col <- names(ex_vals)[1]
      val_col  <- names(ex_vals)[2]

      for (idx in seq_len(nrow(grid_sf))) {
        c_vals <- ex_vals[[val_col]][ex_vals[[cell_col]] == idx]
        c_clean <- c_vals[!is.na(c_vals) & is.finite(c_vals) & c_vals != 0]

        if (length(c_clean) > 0L) {
          raw_veg  <- mean(c_clean >= veg_threshold) * 100
          raw_soil <- mean(c_clean >= 0 & c_clean < soil_threshold) * 100

          rem_avail <- pmax(0, 100 - (pct_water_vec[idx] + pct_bld_vec[idx]))
          sum_raw <- raw_veg + raw_soil
          if (sum_raw > 0) {
            pct_veg_vec[idx]  <- round(pmin(rem_avail, rem_avail * (raw_veg / sum_raw)), 1)
            pct_soil_vec[idx] <- round(pmax(0, rem_avail - pct_veg_vec[idx]), 1)
          } else {
            pct_veg_vec[idx]  <- round(rem_avail * 0.7, 1)
            pct_soil_vec[idx] <- round(rem_avail * 0.3, 1)
          }
        } else {
          rem_avail <- pmax(0, 100 - (pct_water_vec[idx] + pct_bld_vec[idx]))
          pct_veg_vec[idx]  <- round(rem_avail * 0.65, 1)
          pct_soil_vec[idx] <- round(pmax(0, rem_avail - pct_veg_vec[idx]), 1)
        }
      }
    }
  } else {
    for (idx in seq_len(nrow(grid_sf))) {
      rem_avail <- pmax(0, 100 - (pct_water_vec[idx] + pct_bld_vec[idx]))
      pct_veg_vec[idx]  <- round(rem_avail * 0.65, 1)
      pct_soil_vec[idx] <- round(pmax(0, rem_avail - pct_veg_vec[idx]), 1)
    }
  }

  # Normalizacion para suma <= 100
  for (idx in seq_len(nrow(grid_sf))) {
    tot <- pct_water_vec[idx] + pct_bld_vec[idx] + pct_veg_vec[idx] + pct_soil_vec[idx]
    if (tot > 100) {
      excess <- tot - 100
      pct_soil_vec[idx] <- pmax(0, round(pct_soil_vec[idx] - excess, 1))
    }
  }

  # 5. Determine dominant land cover class
  dominant_vec <- character(nrow(grid_sf))
  classes_matrix <- cbind(
    Houses = pct_bld_vec,
    Water = pct_water_vec,
    Vegetation = pct_veg_vec,
    Bare_Soil = pct_soil_vec
  )

  for (idx in seq_len(nrow(grid_sf))) {
    vals_row <- classes_matrix[idx, ]
    max_idx <- which.max(vals_row)
    dominant_vec[idx] <- colnames(classes_matrix)[max_idx]
  }

  # 6. Sectoral surveillance priority stratification
  priority_vec <- character(nrow(grid_sf))
  for (idx in seq_len(nrow(grid_sf))) {
    w_p <- pct_water_vec[idx]
    b_p <- pct_bld_vec[idx]
    w_c <- n_water_vec[idx]
    b_c <- n_bld_vec[idx]

    priority_vec[idx] <- if ((w_p >= 5.0 && b_p >= 5.0) || (w_c >= 1L && b_c >= 1L)) {
      "Critical (Water & Household Co-occurrence)"
    } else if (b_p >= 15.0 || b_c >= 2L) {
      "High Priority (Residential Density)"
    } else if (w_p >= 15.0 || w_c >= 1L) {
      "Aquatic Focus Priority"
    } else if (w_p > 0 || b_p > 0) {
      "Moderate Surveillance / Peridomestic"
    } else {
      "Baseline (Natural Canopy Cover)"
    }
  }

  # 7. Assign columns to sf (English standard with backward-compatible aliases)
  grid_sf$pct_houses            <- pct_bld_vec
  grid_sf$pct_water             <- pct_water_vec
  grid_sf$pct_vegetation        <- pct_veg_vec
  grid_sf$pct_bare_soil         <- pct_soil_vec
  grid_sf$n_houses              <- n_bld_vec
  grid_sf$n_water_bodies        <- n_water_vec
  grid_sf$dominant_class        <- dominant_vec
  grid_sf$surveillance_priority <- priority_vec

  # Backward compatibility aliases
  grid_sf$pct_casas            <- pct_bld_vec
  grid_sf$pct_agua             <- pct_water_vec
  grid_sf$pct_vegetacion       <- pct_veg_vec
  grid_sf$pct_suelo_desnudo    <- pct_soil_vec
  grid_sf$n_casas              <- n_bld_vec
  grid_sf$n_cuerpos_agua       <- n_water_vec
  grid_sf$clase_dominante      <- dominant_vec
  grid_sf$prioridad_vigilancia <- priority_vec

  # 8. Export to multi-sheet Excel if requested
  if (!is.null(out_xlsx)) {
    dir_out <- dirname(out_xlsx)
    if (!dir.exists(dir_out) && dir_out != "" && dir_out != ".") {
      dir.create(dir_out, recursive = TRUE)
    }

    # Clean English export dataframe
    df_clean <- data.frame(
      grid_id               = grid_sf$grid_id,
      area_m2               = grid_sf$area_m2,
      pct_houses            = grid_sf$pct_houses,
      pct_water             = grid_sf$pct_water,
      pct_vegetation        = grid_sf$pct_vegetation,
      pct_bare_soil         = grid_sf$pct_bare_soil,
      n_houses              = grid_sf$n_houses,
      n_water_bodies        = grid_sf$n_water_bodies,
      dominant_class        = grid_sf$dominant_class,
      surveillance_priority = grid_sf$surveillance_priority,
      stringsAsFactors      = FALSE
    )

    df_prio <- stats::aggregate(
      cbind(cell_count = area_m2) ~ surveillance_priority,
      data = df_clean,
      FUN = length
    )
    df_prio$cell_pct <- round((df_prio$cell_count / nrow(df_clean)) * 100, 1)

    df_means <- data.frame(
      Land_Cover_Class = c("Residential / Buildings", "Water Bodies", "Vegetation Canopy", "Bare Soil / Ground"),
      Mean_Percentage = c(
        round(mean(grid_sf$pct_houses), 1),
        round(mean(grid_sf$pct_water), 1),
        round(mean(grid_sf$pct_vegetation), 1),
        round(mean(grid_sf$pct_bare_soil), 1)
      ),
      stringsAsFactors = FALSE
    )

    sheets_comp <- list(
      Grid_Composition           = df_clean,
      Priority_Stratification    = df_prio,
      Global_Class_Distribution  = df_means
    )

    if (requireNamespace("writexl", quietly = TRUE)) {
      writexl::write_xlsx(sheets_comp, path = out_xlsx)
    } else if (requireNamespace("openxlsx", quietly = TRUE)) {
      openxlsx::write.xlsx(sheets_comp, file = out_xlsx)
    } else {
      utils::write.csv(df_clean, file = sub("\\.xlsx$", ".csv", out_xlsx), row.names = FALSE)
    }
  }

  grid_sf
}
