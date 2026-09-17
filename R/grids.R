#' @title Summarize Raster Indicator by Spatial Grid
#' @description Generates a square or hexagonal grid and computes the mean value of raster layers per cell, discarding unpopulated areas.
#' @param raster_in SpatRaster. Input raster layer or multi-layer raster stack.
#' @param cell_size Numeric. Grid cell size in meters (default: 20).
#' @param square Logical. If TRUE, creates square cells; if FALSE, hexagonal cells (default: TRUE).
#' @param discard_na Logical. If TRUE, removes grid cells outside the valid raster data area (default: TRUE).
#' @return A SpatVector containing the grid cells with extracted mean values.
#' @export
d4h_summarize_grid <- function(raster_in, cell_size = 20, square = TRUE, discard_na = TRUE) {
  if (!inherits(raster_in, "SpatRaster")) {
    stop("'raster_in' must be a SpatRaster.", call. = FALSE)
  }

  boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(raster_in), crs = terra::crs(raster_in)))
  grid_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = square)

  prefix <- if (square) "G%04d" else "H%04d"
  grid_sf <- sf::st_sf(
    grid_id = sprintf(prefix, seq_along(grid_sf)),
    geometry = grid_sf
  )
  grid_vect <- terra::vect(grid_sf)

  summary_vect <- terra::extract(raster_in, grid_vect, fun = mean, na.rm = TRUE, bind = TRUE)

  if (discard_na) {
    first_layer <- names(raster_in)[1]
    vals <- summary_vect[[first_layer]][, 1]
    summary_vect <- summary_vect[!is.na(vals) & !is.nan(vals) & vals != 0, ]
  }

  summary_vect
}

#' @title Generate Hexagonal Surveillance Grid
#' @description Creates an operative hexagonal grid over an Area of Interest (AOI).
#' @param aoi SpatRaster, SpatVector, or sf object defining the spatial bounds.
#' @param cell_size Numeric. Cell diameter in meters (default: 50).
#' @return A SpatVector containing the hexagonal grid polygons.
#' @export
d4h_hex_grid <- function(aoi, cell_size = 50) {
  if (inherits(aoi, "SpatRaster")) {
    boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(aoi), crs = terra::crs(aoi)))
  } else if (inherits(aoi, "SpatVector")) {
    boundary_sf <- sf::st_as_sf(aoi)
  } else if (inherits(aoi, "sf")) {
    boundary_sf <- aoi
  } else {
    stop("'aoi' must be a SpatRaster, SpatVector, or sf object.", call. = FALSE)
  }

  grid_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = FALSE)
  grid_sf <- sf::st_sf(
    grid_id = sprintf("H%04d", seq_along(grid_sf)),
    geometry = grid_sf
  )
  terra::vect(grid_sf)
}
