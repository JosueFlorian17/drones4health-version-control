#' @title Extract Multiple Biophysical and Environmental Indicators
#' @description Simultaneously computes, extracts, and summarizes multiple biophysical, vegetation, water, and terrain indicators across drone orthomosaics, operational surveillance grids, and physical features.
#' Always provides both a spatial representation (\code{$sf}) with polygons and a clean tabular data frame (\code{$df}) without geometry, including micro-environmental land cover composition (\code{pct_bare_soil}, \code{pct_houses}, \code{pct_water}, \code{pct_vegetation}, \code{dominant_class}, \code{surveillance_priority}).
#' @details Provides a flexible, unified pipeline for automated batch extraction of biophysical indices.
#' The function operates directly on drone orthomosaics or multispectral bands without requiring a manual region input.
#' If an operational grid is not provided via \code{grid}, an operative surveillance grid is automatically generated across the valid flight footprint
#' using \code{cell_size} (default: 50 m), \code{area_m2}, or \code{n_cells}.
#'
#' @param raster Optional SpatRaster, character path to orthomosaic, or spatial grid.
#' @param bands Character vector. Indicators to compute and extract (default: \code{c("ndvi", "ndwi")}).
#' Supported codes include:
#' \itemize{
#'   \item \code{"ndvi"}: Normalized Difference Vegetation Index \eqn{\frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red}}}
#'   \item \code{"ndwi"}: Normalized Difference Water Index \eqn{\frac{\text{Green} - \text{NIR}}{\text{Green} + \text{NIR}}}
#'   \item \code{"gndvi"}: Green Normalized Difference Vegetation Index \eqn{\frac{\text{NIR} - \text{Green}}{\text{NIR} + \text{Green}}}
#'   \item \code{"savi"}: Soil-Adjusted Vegetation Index
#'   \item \code{"dvi"}: Difference Vegetation Index \eqn{\text{NIR} - \text{Red}}
#'   \item \code{"msavi2"}: Modified Soil-Adjusted Vegetation Index 2
#'   \item \code{"vari"}: Visible Atmospherically Resistant Index (RGB)
#'   \item \code{"ndre"}: Normalized Difference Red Edge
#'   \item \code{"evi"}: Enhanced Vegetation Index
#'   \item \code{"imsr"}: Micro-Surface Roughness / Debris Exposure Index
#'   \item \code{"slope"}: Terrain slope in degrees (requires \code{dem})
#'   \item \code{"twi"}: Topographic Wetness Index (requires \code{dem})
#' }
#' @param grid Optional spatial grid (\code{sf}, \code{SpatVector}, or file path). If NULL, an operational grid is automatically generated across the flight footprint.
#' @param cell_size Numeric (optional). Grid cell size / diameter in meters (default: 50 if all sizing options are NULL and \code{grid} is NULL).
#' @param area_m2 Numeric (optional). Target cell area in square meters.
#' @param n_cells Numeric / Integer (optional). Desired total number of grid units.
#' @param square Logical. If TRUE, square grid cells; if FALSE, regular hexagonal cells (default: FALSE).
#' @param nir SpatRaster or character path. Near-Infrared band.
#' @param red SpatRaster or character path. Red band.
#' @param green SpatRaster or character path. Green band.
#' @param blue SpatRaster or character path. Blue band.
#' @param red_edge SpatRaster or character path. Red Edge band.
#' @param dem SpatRaster or character path. Digital Elevation / Surface Model.
#' @param lst SpatRaster or character path. Land Surface Temperature raster.
#' @param water SpatVector, sf, or SpatRaster (optional). Water body features or binary water mask. If NULL and NDWI is computed, water pixels (\eqn{\text{NDWI} > 0}) are automatically identified.
#' @param buildings SpatVector, sf, or SpatRaster (optional). Building / dwelling footprints or binary roof mask.
#' @param houses Deprecated alias for \code{buildings}.
#' @param stat Character. Summary statistic per grid unit. One of \code{"mean"} (default), \code{"median"}, \code{"min"}, \code{"max"}, \code{"sd"}.
#' @param scale Named numeric vector or numeric value. Optional multiplier scale factor applied to indicator values (default: 1).
#' @param quiet Logical. If TRUE, suppresses console progress messages (default: FALSE).
#' @param orthomosaic Alias for \code{raster}.
#' @param aoi Alias for \code{raster}.
#' @param region Alias for \code{raster} or \code{grid}.
#' @param ... Additional arguments passed to internal functions.
#' @return An object of class \code{d4h_indicators_summary} and \code{d4h_grid_summary} containing:
#' \itemize{
#'   \item \code{$sf}: Spatial \code{sf} polygons with geometry, indicator statistics, and land cover composition.
#'   \item \code{$df}: Tabular pure \code{data.frame} without geometry, containing all zonal metrics and land cover percentages (\code{pct_bare_soil}, \code{pct_houses}, \code{pct_water}, \code{pct_vegetation}, \code{dominant_class}, \code{surveillance_priority}).
#' }
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Define bands
#'   path_nir <- system.file("extdata", "nir.tif", package = "drones4health")
#'   path_r   <- system.file("extdata", "red.tif", package = "drones4health")
#'   path_g   <- system.file("extdata", "green.tif", package = "drones4health")
#'
#'   # Extract multiple indicators directly without requiring a manual region
#'   res <- d4h_extract_indicators(
#'     bands     = c("ndvi", "ndwi"),
#'     nir       = path_nir,
#'     red       = path_r,
#'     green     = path_g,
#'     cell_size = 50
#'   )
#'
#'   # Access both the clean tabular data frame and spatial sf
#'   head(res$df)
#'   plot(res$sf)
#' }
#' }
#' @export
d4h_extract_indicators <- function(raster = NULL,
                                   bands = c("ndvi", "ndwi"),
                                   grid = NULL,
                                   cell_size = NULL,
                                   area_m2 = NULL,
                                   n_cells = NULL,
                                   square = FALSE,
                                   nir = NULL,
                                   red = NULL,
                                   green = NULL,
                                   blue = NULL,
                                   red_edge = NULL,
                                   dem = NULL,
                                   lst = NULL,
                                   water = NULL,
                                   buildings = NULL,
                                   houses = NULL,
                                   stat = "mean",
                                   scale = 1,
                                   quiet = FALSE,
                                   orthomosaic = NULL,
                                   aoi = NULL,
                                   region = NULL,
                                   ...) {
  # 1. Resolve aliases
  if (is.null(buildings) && !is.null(houses)) {
    buildings <- houses
  }
  if (is.null(raster)) {
    if (!is.null(orthomosaic)) {
      raster <- orthomosaic
    } else if (!is.null(aoi)) {
      raster <- aoi
    } else if (!is.null(region)) {
      if (inherits(region, c("sf", "sfc", "SpatVector"))) {
        grid <- region
      } else {
        raster <- region
      }
    }
  }

  # Pipe support: if first argument is a spatial grid
  if (inherits(raster, c("sf", "sfc", "SpatVector"))) {
    grid <- raster
    raster <- NULL
  } else if (is.character(raster) && length(raster) > 1 && all(tolower(raster) %in% c("ndvi", "ndwi", "gndvi", "savi", "dvi", "msavi2", "vari", "ndre", "evi", "imsr", "slope", "twi"))) {
    bands <- raster
    raster <- NULL
  }

  bands <- tolower(bands)

  # 2. Extract bands from multi-band raster if provided
  if (!is.null(raster)) {
    r_in <- if (is.character(raster) && length(raster) == 1L) {
      if (!file.exists(raster)) stop(paste("File not found:", raster), call. = FALSE)
      terra::rast(raster)
    } else if (inherits(raster, "SpatRaster")) {
      raster
    } else {
      NULL
    }

    if (!is.null(r_in)) {
      r_names <- tolower(names(r_in))

      if (is.null(nir)) {
        nir_idx <- grep("^(nir|near_infrared|b8|b5|nir_band)", r_names)
        if (length(nir_idx) > 0) nir <- r_in[[nir_idx[1]]]
      }
      if (is.null(red)) {
        red_idx <- grep("^(red|r|b4|b3|red_band)", r_names)
        if (length(red_idx) > 0) red <- r_in[[red_idx[1]]]
      }
      if (is.null(green)) {
        green_idx <- grep("^(green|g|b3|b2|green_band)", r_names)
        if (length(green_idx) > 0) green <- r_in[[green_idx[1]]]
      }
      if (is.null(blue)) {
        blue_idx <- grep("^(blue|b|b2|b1|blue_band)", r_names)
        if (length(blue_idx) > 0) blue <- r_in[[blue_idx[1]]]
      }
      if (is.null(red_edge)) {
        re_idx <- grep("^(red_edge|rededge|re|b5|b6)", r_names)
        if (length(re_idx) > 0) red_edge <- r_in[[re_idx[1]]]
      }

      # Fallback to positional indices for standard RGB / multispectral
      if (is.null(red) && terra::nlyr(r_in) >= 1) red <- r_in[[1]]
      if (is.null(green) && terra::nlyr(r_in) >= 2) green <- r_in[[2]]
      if (is.null(blue) && terra::nlyr(r_in) >= 3) blue <- r_in[[3]]
    }
  }

  # 3. Compute requested indicator layers
  computed_layers <- list()

  for (b in bands) {
    if (!quiet) message(sprintf("Calculating indicator: %s...", toupper(b)))
    lyr <- switch(b,
      "ndvi" = {
        if (is.null(nir) || is.null(red)) stop("Indicator 'ndvi' requires 'nir' and 'red' bands.", call. = FALSE)
        d4h_ndvi(nir = nir, red = red)
      },
      "ndwi" = {
        if (is.null(green) || is.null(nir)) stop("Indicator 'ndwi' requires 'green' and 'nir' bands.", call. = FALSE)
        d4h_ndwi(green = green, nir = nir)
      },
      "gndvi" = {
        if (is.null(nir) || is.null(green)) stop("Indicator 'gndvi' requires 'nir' and 'green' bands.", call. = FALSE)
        d4h_gndvi(nir = nir, green = green)
      },
      "savi" = {
        if (is.null(nir) || is.null(red)) stop("Indicator 'savi' requires 'nir' and 'red' bands.", call. = FALSE)
        d4h_savi(nir = nir, red = red)
      },
      "dvi" = {
        if (is.null(nir) || is.null(red)) stop("Indicator 'dvi' requires 'nir' and 'red' bands.", call. = FALSE)
        d4h_dvi(nir = nir, red = red)
      },
      "msavi2" = {
        if (is.null(nir) || is.null(red)) stop("Indicator 'msavi2' requires 'nir' and 'red' bands.", call. = FALSE)
        d4h_msavi2(nir = nir, red = red)
      },
      "vari" = {
        if (is.null(green) || is.null(red) || is.null(blue)) stop("Indicator 'vari' requires 'green', 'red', and 'blue' bands.", call. = FALSE)
        d4h_vari(green = green, red = red, blue = blue)
      },
      "ndre" = {
        if (is.null(nir) || is.null(red_edge)) stop("Indicator 'ndre' requires 'nir' and 'red_edge' bands.", call. = FALSE)
        d4h_ndre(nir = nir, red_edge = red_edge)
      },
      "evi" = {
        if (is.null(nir) || is.null(red) || is.null(blue)) stop("Indicator 'evi' requires 'nir', 'red', and 'blue' bands.", call. = FALSE)
        d4h_evi(nir = nir, red = red, blue = blue)
      },
      "imsr" = {
        if (is.null(red_edge) || is.null(red) || is.null(nir)) stop("Indicator 'imsr' requires 'red_edge', 'red', and 'nir' bands.", call. = FALSE)
        d4h_imsr(red_edge = red_edge, red = red, nir = nir)
      },
      "slope" = {
        if (is.null(dem)) stop("Indicator 'slope' requires 'dem' raster.", call. = FALSE)
        d4h_slope(dem_raster = dem)
      },
      "twi" = {
        if (is.null(dem)) stop("Indicator 'twi' requires 'dem' raster.", call. = FALSE)
        d4h_twi(dem_raster = dem)
      },
      stop(sprintf("Indicator '%s' not recognized. Supported: ndvi, ndwi, gndvi, savi, dvi, msavi2, vari, ndre, evi, imsr, slope, twi.", b), call. = FALSE)
    )

    # Apply scale factor if provided
    s_val <- 1
    if (is.numeric(scale)) {
      if (!is.null(names(scale)) && b %in% names(scale)) {
        s_val <- scale[[b]]
      } else if (is.null(names(scale)) && length(scale) == 1) {
        s_val <- scale
      }
    }
    if (s_val != 1) {
      lyr <- lyr * s_val
    }

    names(lyr) <- b
    computed_layers[[b]] <- lyr
  }

  # 4. Resolve reference raster for spatial georeferencing and grid generation
  r_ref <- if (!is.null(raster) && inherits(raster, "SpatRaster")) {
    raster
  } else if (!is.null(raster) && is.character(raster) && file.exists(raster)) {
    terra::rast(raster)
  } else if (length(computed_layers) > 0) {
    computed_layers[[1]]
  } else {
    stop("No valid raster or bands available for spatial processing.", call. = FALSE)
  }

  grid_sf <- if (!is.null(grid)) {
    if (is.character(grid) && length(grid) == 1L) {
      if (!file.exists(grid)) stop(paste("Grid file not found:", grid), call. = FALSE)
      sf::st_read(grid, quiet = TRUE)
    } else if (inherits(grid, "SpatVector")) {
      sf::st_as_sf(grid)
    } else if (inherits(grid, "sf")) {
      grid
    } else {
      stop("'grid' must be an sf object, SpatVector, or valid file path.", call. = FALSE)
    }
  } else {
    # Auto-generate surveillance grid over the orthomosaic footprint
    d4h_make_grid(
      aoi               = r_ref,
      cell_size         = cell_size,
      area_m2           = area_m2,
      n_cells           = n_cells,
      square            = square,
      clip_to_footprint = TRUE,
      as_sf             = TRUE
    )
  }

  if (!"grid_id" %in% names(grid_sf)) {
    grid_sf$grid_id <- sprintf("G%04d", seq_len(nrow(grid_sf)))
  }

  target_crs <- sf::st_crs(terra::crs(r_ref))
  if (sf::st_crs(grid_sf) != target_crs) {
    grid_sf <- sf::st_transform(grid_sf, target_crs)
  }

  # 5. Extract zonal statistics for each indicator
  use_exact <- requireNamespace("exactextractr", quietly = TRUE)

  for (b in bands) {
    lyr <- computed_layers[[b]]
    lyr_crs <- sf::st_crs(terra::crs(lyr))
    grid_for_lyr <- if (lyr_crs != target_crs) sf::st_transform(grid_sf, lyr_crs) else grid_sf
    grid_vect_for_lyr <- terra::vect(grid_for_lyr)

    for (s in stat) {
      col_name <- if (length(stat) == 1) b else paste0(b, "_", s)
      if (use_exact) {
        fun_exact <- switch(s, "median" = "median", "min" = "min", "max" = "max", "sd" = "stdev", "mean")
        vals <- exactextractr::exact_extract(lyr, grid_for_lyr, fun_exact, progress = FALSE)
      } else {
        fun_terra <- switch(s, "median" = stats::median, "min" = min, "max" = max, "sd" = stats::sd, mean)
        ext_mat <- terra::extract(lyr, grid_vect_for_lyr, fun = fun_terra, na.rm = TRUE)
        vals <- ext_mat[, 2]
      }
      vals <- as.numeric(vals)
      vals[is.nan(vals) | is.infinite(vals)] <- NA_real_
      grid_sf[[col_name]] <- round(vals, 4)
    }
  }

  # 6. Compute micro-environmental land cover composition (bare soil, houses, water, vegetation)
  idx_ndvi <- which(bands %in% c("ndvi", "savi", "gndvi"))
  r_ndvi_cand <- if (length(idx_ndvi) > 0) computed_layers[[bands[idx_ndvi[1]]]] else NULL

  water_cand <- water
  if (is.null(water_cand)) {
    idx_ndwi <- which(bands %in% c("ndwi", "irhe"))
    if (length(idx_ndwi) > 0) {
      water_cand <- computed_layers[[bands[idx_ndwi[1]]]] > 0
    }
  }

  comp_sf <- d4h_grid_composition(
    grid        = grid_sf,
    water       = water_cand,
    buildings   = buildings,
    ndvi_raster = r_ndvi_cand
  )

  # Merge composition metrics onto grid_sf
  comp_cols <- c("pct_bare_soil", "pct_houses", "pct_water", "pct_vegetation",
                 "n_houses", "n_water_bodies", "dominant_class", "surveillance_priority")
  comp_cols_avail <- intersect(comp_cols, names(comp_sf))

  for (col_n in comp_cols_avail) {
    grid_sf[[col_n]] <- comp_sf[[col_n]]
  }

  # Ensure centroid columns are present
  if (!"centroid_x" %in% names(grid_sf)) {
    pts_c <- suppressWarnings(terra::crds(terra::centroids(terra::vect(grid_sf))))
    if (nrow(pts_c) > 0) {
      grid_sf$centroid_x <- round(pts_c[, 1], 2)
      grid_sf$centroid_y <- round(pts_c[, 2], 2)
    }
  }

  # 7. Build both spatial (sf) and tabular (df) representations
  res_sf <- grid_sf
  res_df <- as.data.frame(sf::st_drop_geometry(grid_sf))

  if (!quiet) {
    message(sprintf("✔ Extracted %d indicators across %d grid units | Both $sf and $df available",
                    length(bands), nrow(res_sf)))
  }

  res <- list(
    sf = res_sf,
    df = res_df
  )
  class(res) <- c("d4h_indicators_summary", "d4h_grid_summary", "list")
  res
}

#' @export
as.data.frame.d4h_indicators_summary <- function(x, ...) {
  if (!is.null(x$df)) as.data.frame(x$df) else NextMethod()
}

#' @export
st_as_sf.d4h_indicators_summary <- function(x, ...) {
  if (!is.null(x$sf)) x$sf else NextMethod()
}

#' @export
`$.d4h_indicators_summary` <- function(x, name) {
  if (name %in% c("sf", "df", "summary", "composition")) {
    return(.subset2(x, name))
  }
  df_obj <- .subset2(x, "df")
  if (!is.null(df_obj) && name %in% names(df_obj)) {
    return(df_obj[[name]])
  }
  sf_obj <- .subset2(x, "sf")
  if (!is.null(sf_obj) && name %in% names(sf_obj)) {
    return(sf_obj[[name]])
  }
  .subset2(x, name)
}

#' @export
`[[.d4h_indicators_summary` <- function(x, i, ...) {
  if (is.character(i) && !i %in% c("sf", "df", "summary", "composition")) {
    df_obj <- .subset2(x, "df")
    if (!is.null(df_obj) && i %in% names(df_obj)) {
      return(df_obj[[i]])
    }
  }
  NextMethod()
}

#' @export
print.d4h_indicators_summary <- function(x, ...) {
  cat("\n==============================================================================\n")
  cat("             DRONES4HEALTH - MULTI-INDICATOR SURVEILLANCE SUMMARY            \n")
  cat("==============================================================================\n")
  cat(sprintf(" Evaluated Units : %d grid cells | Total attributes: %d\n", nrow(x$df), ncol(x$df)))
  cat(" Structure       : Both spatial ($sf) and tabular ($df) representations provided.\n")
  cat(" Available parts : $sf (sf polygons with geometry) | $df (clean tabular data.frame)\n")
  cat(" Included fields : Micro-environmental composition (pct_bare_soil, pct_houses,\n")
  cat("                   pct_water, pct_vegetation, dominant_class, surveillance_priority)\n")
  cat("                   and extracted indicator values.\n")
  cat("------------------------------------------------------------------------------\n")
  print(head(x$df, 6))
  cat("==============================================================================\n\n")
  invisible(x)
}
