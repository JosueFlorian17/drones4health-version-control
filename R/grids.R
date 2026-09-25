#' @title Summarize Raster Indicator by Spatial Grid
#' @description Generates a square or hexagonal grid and computes the mean value of raster layers per cell, discarding unpopulated areas.
#' @param raster_in SpatRaster or character. Input raster layer, stack, or path to file.
#' @param cell_size Numeric. Grid cell size in meters (default: 20).
#' @param square Logical. If TRUE, creates square cells; if FALSE, hexagonal cells (default: TRUE).
#' @param discard_na Logical. If TRUE, removes grid cells outside the valid raster data area (default: TRUE).
#' @return A SpatVector containing the grid cells with extracted mean values.
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
#' @description Creates an operative hexagonal grid over an Area of Interest (AOI).
#' @param aoi SpatRaster, SpatVector, sf, or character path defining the spatial bounds.
#' @param cell_size Numeric. Cell diameter in meters (default: 50).
#' @return A SpatVector containing the hexagonal grid polygons with unique IDs.
#' @export
d4h_hex_grid <- function(aoi, cell_size = 50) {
  if (is.character(aoi) && length(aoi) == 1L) {
    if (!file.exists(aoi)) stop(paste("File not found:", aoi), call. = FALSE)
    aoi <- terra::rast(aoi)
  }

  if (inherits(aoi, "SpatRaster")) {
    boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(aoi), crs = terra::crs(aoi)))
  } else if (inherits(aoi, "SpatVector")) {
    boundary_sf <- sf::st_as_sf(aoi)
  } else if (inherits(aoi, "sf")) {
    boundary_sf <- aoi
  } else {
    stop("'aoi' must be a SpatRaster, SpatVector, sf object, or valid file path.", call. = FALSE)
  }

  grid_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = FALSE)
  grid_sf <- sf::st_sf(
    grid_id = sprintf("H%04d", seq_along(grid_sf)),
    geometry = grid_sf
  )
  terra::vect(grid_sf)
}

#' @title Summarize Raster Indicator for the General Mosaic Footprint
#' @description Computes the overall mean value of raster layers across the entire area of interest (AOI) as a single spatial vector polygon (SpatVector), formatted identically to zonal grid summaries for consistent map plotting.
#' @param raster_in SpatRaster or character. Input raster layer, stack, or path to file.
#' @param exact_boundary Logical. If TRUE, traces the exact outer boundary of valid non-NA flight data; if FALSE, uses the bounding box extent (default: TRUE).
#' @return A SpatVector with a single polygon containing the overall mean value(s).
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
