#' @title Targeted Focal Indicator Analysis and Plotting around House Buffers
#' @description Drastically accelerates computational efficiency and saves memory by cropping, calculating micro-environmental/epidemiological indicators, and plotting exclusively within a defined buffer zone (measured in grid-units or meters) around residential houses from a CSV or spatial layer.
#' @details In ultra-high resolution drone mapping (100M+ pixels), calculating continuous indices over the entire scene consumes unnecessary computational resources.
#' \code{d4h_indicator_buffer} creates an operational envelope around houses:
#' \deqn{\text{Buffer Distance} = R \times \text{cell\_size}}
#' It crops the raw band inputs strictly to the bounding box of intersecting buffer zones, masks non-focal areas, computes the specified spectral/terrain/epidemiological index, extracts grid summaries, and produces an publication-ready ggplot visualization with house points overlaid.
#'
#' @param indicator Character or Function. Name of the index or function to compute.
#' Supported character names: \code{"NDVI"}, \code{"NDWI"}, \code{"SAVI"}, \code{"DVI"}, \code{"GNDVI"}, \code{"NDRE"}, \code{"EVI"}, \code{"VARI"}, \code{"TVI"}, \code{"MSAVI2"}, \code{"IRHE"}, \code{"IMSR"}, \code{"IRTS"}, \code{"slope"}, \code{"twi"}, \code{"dsm"}, \code{"rgb"}.
#' Alternatively, pass a custom function \code{function(...)} or a pre-calculated SpatRaster.
#' @param houses Character path, data.frame, SpatVector, or sf object containing house coordinates (e.g., CSV with lon/lat or x/y columns).
#' @param radius_m Numeric (optional). Buffer radius surrounding each house in meters (e.g., \code{radius_m = 150}). Mutually exclusive with \code{radius_grids}.
#' @param radius_grids Numeric (optional). Buffer radius surrounding each house measured in number of grid units (e.g., \code{radius_grids = 3}). Mutually exclusive with \code{radius_m}.
#' @param radius Numeric (deprecated alias for radius distance).
#' @param cell_size Numeric. Grid cell size in meters used to establish grid scale and calculate buffer distances (default: 50).
#' @param radius_in_meters Logical (deprecated, use \code{radius_m} directly).
#' @param meters Alias for \code{radius_m}.
#' @param grids Alias for \code{radius_grids}.
#' @param grid SpatVector, sf, or character path (optional). An already existing spatial grid (e.g. from \code{d4h_hex_grid}). When provided, grid cells intersecting the household buffers are automatically extracted, and \code{cell_size} / \code{square} are automatically inferred.
#' @param nir SpatRaster or character path. Near-Infrared band (optional, required for multispectral indices).
#' @param red SpatRaster or character path. Red band (optional).
#' @param green SpatRaster or character path. Green band (optional).
#' @param blue SpatRaster or character path. Blue band (optional).
#' @param red_edge SpatRaster or character path. Red Edge band (optional).
#' @param dem SpatRaster or character path. DEM / DSM raster (optional).
#' @param lst SpatRaster or character path. Land Surface Temperature raster (optional).
#' @param raster_in SpatRaster or character path (optional). Directly provides an already computed raster or pre-stacked imagery to crop and plot.
#' @param square Logical. If TRUE, creates square grid cells; if FALSE, hexagonal grid cells (default: TRUE).
#' @param mask_outside Logical. If TRUE (default), masks pixel values outside the house buffer polygons to NA. If FALSE, retains unmasked rectangular cropped extent.
#' @param house_color Character. Color for house points on the plot (default: "red").
#' @param house_size Numeric. Size for house points on the plot (default: 2.5).
#' @param palette Character. Color palette name ("viridis", "magma", "terrain", "spectral") or custom color vector (default: "viridis").
#' @param limits Numeric vector c(min, max) to fix color scale limits (default: NULL).
#' @param title Character. Custom plot title (optional).
#' @param plot Logical. If TRUE (default), returns a list with the raster, grid summary, and ggplot / mapview. If FALSE, skips rendering.
#' @param interactive Logical. If TRUE, generates an interactive WebGIS mapview widget. If FALSE (default), generates a publication-ready ggplot2 graphic.
#' @param bbox Logical. If TRUE (default), keeps default plot coordinate bounding box and gridlines. If FALSE, tightly fits geometry without extra margins.
#' @return A list containing:
#' \itemize{
#'   \item \code{raster}: The targeted cropped SpatRaster of the computed indicator.
#'   \item \code{houses}: An \code{sf} object of the houses intersecting the scene.
#'   \item \code{buffer}: An \code{sf} polygon of the focal buffer envelope.
#'   \item \code{grid}: An \code{sf} / \code{SpatVector} zonal grid summary within the buffer zone.
#'   \item \code{plot}: A \code{ggplot} object visualizing the buffer zone, raster indicator, and house points (if \code{plot = TRUE}).
#' }
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'   library(sf)
#'
#'   # Define paths to bands and house locations
#'   nir_path   <- system.file("extdata", "nir.tif", package = "drones4health")
#'   red_path   <- system.file("extdata", "red.tif", package = "drones4health")
#'   houses_csv <- system.file("extdata", "houses.csv", package = "drones4health")
#'
#'   # Run focal buffer analysis around houses with full parameterization
#'   res_buffer <- d4h_indicator_buffer(
#'     indicator        = "NDVI",
#'     houses           = houses_csv,
#'     radius           = 3,
#'     cell_size        = 50,
#'     radius_in_meters = FALSE,
#'     nir              = nir_path,
#'     red              = red_path,
#'     square           = FALSE,
#'     mask_outside     = TRUE,
#'     house_color      = "red",
#'     house_size       = 2.5,
#'     palette          = "viridis",
#'     limits           = c(0.1, 0.9),
#'     title            = "Focal Household Buffer (150m) - NDVI Analysis",
#'     plot             = TRUE
#'   )
#'   head(res_buffer$grid)
#' }
#' }
#' @export
d4h_indicator_buffer <- function(indicator = "NDVI",
                                 houses,
                                 radius_m = NULL,
                                 radius_grids = NULL,
                                 radius = NULL,
                                 cell_size = 50,
                                 radius_in_meters = FALSE,
                                 meters = NULL,
                                 grids = NULL,
                                 grid = NULL,
                                 nir = NULL,
                                 red = NULL,
                                 green = NULL,
                                 blue = NULL,
                                 red_edge = NULL,
                                 dem = NULL,
                                 lst = NULL,
                                 raster_in = NULL,
                                 square = TRUE,
                                 mask_outside = TRUE,
                                 house_color = "red",
                                 house_size = 2.5,
                                 palette = "viridis",
                                 limits = NULL,
                                 title = NULL,
                                 plot = TRUE,
                                 interactive = FALSE,
                                 bbox = TRUE,
                                 scale_bar = TRUE,
                                 north_arrow = TRUE,
                                 scale_pos = "bl",
                                 north_pos = "tr") {

  # 1. Resolver y unificar grilla preexistente si se proporciona
  sf_grid_input <- NULL
  if (!is.null(grid)) {
    if (is.list(grid) && !inherits(grid, c("sf", "SpatVector")) && !is.null(grid$sf)) {
      grid <- grid$sf
    }
    sf_grid_input <- if (inherits(grid, "SpatVector")) {
      sf::st_as_sf(grid)
    } else if (inherits(grid, "sf")) {
      grid
    } else {
      sf::st_read(grid, quiet = TRUE)
    }

    if (missing(cell_size) || is.null(cell_size)) {
      if ("area_m2" %in% names(sf_grid_input)) {
        a_m2 <- mean(sf_grid_input$area_m2, na.rm = TRUE)
        cell_size <- round(sqrt(a_m2 / (sqrt(3) / 2)), 1)
      } else {
        a_m2 <- as.numeric(mean(sf::st_area(sf_grid_input), na.rm = TRUE))
        cell_size <- round(sqrt(a_m2), 1)
      }
    }
    if (missing(square)) {
      square <- FALSE
    }
  }

  # Resolver aliases de metros y grillas
  if (is.null(radius_m) && !is.null(meters)) radius_m <- meters
  if (is.null(radius_grids) && !is.null(grids)) radius_grids <- grids

  # Mapear argumento historico 'radius' si se especifico
  if (!is.null(radius)) {
    if (isTRUE(radius_in_meters)) {
      if (is.null(radius_m)) radius_m <- radius
    } else {
      if (is.null(radius_grids)) radius_grids <- radius
    }
  }

  # Validacion de exclusividad mutua entre metros y grillas
  if (!is.null(radius_m) && !is.null(radius_grids)) {
    stop("Arguments 'radius_m' (meters) and 'radius_grids' (grids) are mutually exclusive. Please specify either meters or grids, not both.", call. = FALSE)
  }

  # Calculo de distancia e impresion explicativa bidireccional
  buffer_dist_m <- 150.0
  if (!is.null(radius_m)) {
    buffer_dist_m <- as.numeric(radius_m)
    equiv_grids <- round(buffer_dist_m / as.numeric(cell_size), 1)
    message(sprintf("✔ Buffer radius: %.1f m (enclosing ~%.1f grid cells of %.1f m)", buffer_dist_m, equiv_grids, as.numeric(cell_size)))
  } else if (!is.null(radius_grids)) {
    buffer_dist_m <- as.numeric(radius_grids) * as.numeric(cell_size)
    message(sprintf("✔ Buffer radius: %g grid cells (enclosing %.1f m at %.1f m cell size)", as.numeric(radius_grids), buffer_dist_m, as.numeric(cell_size)))
  } else {
    buffer_dist_m <- 150.0
    equiv_grids <- round(buffer_dist_m / as.numeric(cell_size), 1)
    message(sprintf("✔ Buffer radius: %.1f m (enclosing ~%.1f grid cells of %.1f m)", buffer_dist_m, equiv_grids, as.numeric(cell_size)))
  }
  if (buffer_dist_m <= 0) buffer_dist_m <- 1.0

  # 2. Identificar el raster de referencia inicial para CRS y resolucion
  r_ref <- if (!is.null(raster_in)) {
    .ensure_raster(raster_in, mask_zeros = FALSE)
  } else if (!is.null(nir)) {
    .ensure_raster(nir, mask_zeros = FALSE)
  } else if (!is.null(red)) {
    .ensure_raster(red, mask_zeros = FALSE)
  } else if (!is.null(dem)) {
    .ensure_raster(dem, mask_zeros = FALSE)
  } else if (!is.null(green)) {
    .ensure_raster(green, mask_zeros = FALSE)
  } else {
    stop("You must provide at least one raster layer (nir, red, dem, green or raster_in) for georeferencing.", call. = FALSE)
  }

  target_crs <- sf::st_crs(terra::crs(r_ref))

  # 3. Parse and reproject houses
  sf_houses <- if (is.character(houses) && length(houses) == 1L) {
    if (grepl("\\.(xlsx|xls)$", houses, ignore.case = TRUE)) {
      df_h <- if (requireNamespace("readxl", quietly = TRUE)) {
        as.data.frame(readxl::read_excel(houses))
      } else if (requireNamespace("openxlsx", quietly = TRUE)) {
        openxlsx::read.xlsx(houses)
      } else {
        stop("To read Excel files (.xlsx/.xls) install 'readxl': install.packages('readxl')", call. = FALSE)
      }
      lon_col <- grep("^(lon|lng|long|longitude|x|utm_x|easting)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y|utm_y|northing)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("The Excel file does not contain recognizable coordinate columns (lon/lat, x/y or utm_x/utm_y).", call. = FALSE)
      }
      is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else target_crs
      sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
    } else if (grepl("\\.csv$", houses, ignore.case = TRUE)) {
      df_h <- utils::read.csv(houses)
      lon_col <- grep("^(lon|lng|long|longitude|x|utm_x|easting)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y|utm_y|northing)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("The CSV file does not contain recognizable coordinate columns (lon/lat, x/y or utm_x/utm_y).", call. = FALSE)
      }
      is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else target_crs
      sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
    } else {
      sf::st_as_sf(terra::vect(houses))
    }
  } else if (is.data.frame(houses) && !inherits(houses, "sf")) {
    lon_col <- grep("^(lon|lng|long|longitude|x|utm_x|easting)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
    lat_col <- grep("^(lat|latitude|y|utm_y|northing)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
    if (is.na(lon_col) || is.na(lat_col)) {
      stop("The data.frame does not contain recognizable coordinate columns (lon/lat, x/y or utm_x/utm_y).", call. = FALSE)
    }
    is_ll <- all(abs(houses[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(houses[[lat_col]]) <= 90, na.rm = TRUE)
    init_crs <- if (is_ll) 4326 else target_crs
    sf::st_as_sf(houses, coords = c(lon_col, lat_col), crs = init_crs)
  } else if (inherits(houses, "SpatVector")) {
    sf::st_as_sf(houses)
  } else if (inherits(houses, "sf")) {
    houses
  } else {
    stop("'houses' must be an sf object, SpatVector, data.frame, or valid file path (.csv, .xlsx, .shp, .gpkg).", call. = FALSE)
  }

  if (sf::st_crs(sf_houses) != target_crs) {
    sf_houses <- sf::st_transform(sf_houses, target_crs)
  }

  # 4. Filtrar casas que caen dentro o en la vecindad de la escena raster
  ext_scene <- sf::st_as_sfc(sf::st_bbox(terra::ext(r_ref), crs = target_crs))
  # Permitir casas cuyo buffer intersecta con la escena
  sf_houses_buf <- sf::st_buffer(sf_houses, dist = buffer_dist_m)
  inter_idx <- which(lengths(sf::st_intersects(sf_houses_buf, ext_scene)) > 0)

  if (length(inter_idx) == 0L) {
    stop("Ninguna casa del conjunto proporcionado (ni su buffer de influencia) intersecta con el raster.", call. = FALSE)
  }

  sf_houses_focal <- sf_houses[inter_idx, ]
  buf_focal <- sf::st_union(sf_houses_buf[inter_idx, ])
  buf_sf <- sf::st_as_sf(data.frame(id = 1), geometry = buf_focal)

  # 5. Obtener bounding box del buffer focal intersecado con la escena
  focal_bbox <- sf::st_bbox(sf::st_intersection(buf_focal, ext_scene))
  e_crop <- terra::ext(focal_bbox$xmin, focal_bbox$xmax, focal_bbox$ymin, focal_bbox$ymax)

  # 6. Helper para recortar bandas crudas antes de calcular (AHORRO RADICAL DE RECURSOS)
  .crop_raw <- function(b) {
    if (is.null(b)) return(NULL)
    r_b <- .ensure_raster(b, mask_zeros = FALSE)
    terra::crop(r_b, e_crop)
  }

  nir_c      <- .crop_raw(nir)
  red_c      <- .crop_raw(red)
  green_c    <- .crop_raw(green)
  blue_c     <- .crop_raw(blue)
  red_edge_c <- .crop_raw(red_edge)
  dem_c      <- .crop_raw(dem)
  lst_c      <- .crop_raw(lst)

  # 7. Computar o recortar el indicador especificado en la zona focal
  r_res <- if (!is.null(raster_in)) {
    r_in <- .ensure_raster(raster_in, mask_zeros = FALSE)
    terra::crop(r_in, e_crop)
  } else if (is.function(indicator)) {
    # Funcion personalizada
    indicator(nir = nir_c, red = red_c, green = green_c, blue = blue_c, red_edge = red_edge_c, dem = dem_c, lst = lst_c)
  } else if (is.character(indicator)) {
    ind_up <- toupper(indicator)
    switch(ind_up,
      "NDVI"   = d4h_ndvi(nir = nir_c, red = red_c),
      "NDWI"   = d4h_ndwi(green = green_c, nir = nir_c),
      "SAVI"   = d4h_savi(nir = nir_c, red = red_c),
      "DVI"    = d4h_dvi(nir = nir_c, red = red_c),
      "GNDVI"  = d4h_gndvi(nir = nir_c, green = green_c),
      "NDRE"   = d4h_ndre(nir = nir_c, red_edge = red_edge_c),
      "EVI"    = d4h_evi(nir = nir_c, red = red_c, blue = blue_c),
      "VARI"   = d4h_vari(green = green_c, red = red_c, blue = blue_c),
      "TVI"    = if (!is.null(dem_c)) d4h_twi(dem_raster = dem_c) else d4h_ndvi(nir = nir_c, red = red_c),
      "MSAVI2" = d4h_msavi2(nir = nir_c, red = red_c),
      "IRHE"   = if (!is.null(green_c) && !is.null(nir_c) && !is.null(lst_c)) d4h_irhe(green = green_c, nir = nir_c, lst = lst_c) else d4h_ndwi(green = green_c, nir = nir_c),
      "IMSR"   = d4h_imsr(red_edge = red_edge_c, red = red_c, nir = nir_c),
      "IRTS"   = {
        ndre_tmp <- d4h_ndre(nir = nir_c, red_edge = red_edge_c)
        d4h_irts(ndre = ndre_tmp, lst_local = lst_c, lst_surrounding = terra::focal(lst_c, w = 9, fun = "mean"), nir = nir_c)
      },
      "SLOPE"  = d4h_slope(dem_raster = dem_c),
      "TWI"    = d4h_twi(dem_raster = dem_c),
      "DSM"    = dem_c,
      "DEM"    = dem_c,
      stop(sprintf("Indicator '%s' not recognized. Supported options: NDVI, NDWI, SAVI, DVI, GNDVI, NDRE, EVI, VARI, TVI, MSAVI2, IRHE, IMSR, IRTS, SLOPE, TWI, DSM.", indicator), call. = FALSE)
    )
  } else {
    stop("'indicator' must be an index name (string), calculation function, or SpatRaster.", call. = FALSE)
  }

  # 8. Enmascarar exterior del buffer si mask_outside = TRUE
  buf_vect <- terra::vect(buf_sf)
  if (isTRUE(mask_outside)) {
    r_res <- terra::mask(r_res, buf_vect)
  }

  # 9. Extraer resumen zonal por grilla dentro de la zona focal
  grid_focal <- if (!is.null(sf_grid_input)) {
    if (sf::st_crs(sf_grid_input) != target_crs) {
      sf_grid_input <- sf::st_transform(sf_grid_input, target_crs)
    }
    inter_cells <- which(lengths(sf::st_intersects(sf_grid_input, buf_sf)) > 0)
    if (length(inter_cells) > 0) {
      grid_sub <- sf_grid_input[inter_cells, ]
      sum_res <- d4h_executive_summary(raster_in = r_res, grid = grid_sub, out_xlsx = NULL)
      if (is.list(sum_res) && !is.null(sum_res$sf)) sum_res$sf else sum_res
    } else {
      sf_grid_input[0, ]
    }
  } else {
    d4h_summarize_grid(r_res, cell_size = cell_size, square = square, discard_na = TRUE)
  }

  # 10. Ploteo especializado con casas y contorno del buffer
  p_out <- NULL
  if (isTRUE(plot)) {
    title_str <- if (!is.null(title)) {
      title
    } else {
      ind_name <- if (is.character(indicator)) toupper(indicator) else "Indicator"
      sprintf("%s in Household Catchment Area (Radius %g m - ~%.1f grids)", ind_name, round(buffer_dist_m), round(buffer_dist_m / as.numeric(cell_size), 1))
    }

    # Render focal indicator
    p_out <- d4h_plot(
      x           = list(raster = r_res, houses = sf_houses_focal, buffer = buf_sf, grid = if (!is.null(sf_grid_input)) grid_focal else NULL),
      interactive = interactive,
      palette     = palette,
      limits      = limits,
      house_color = house_color,
      house_size  = house_size,
      title       = title_str,
      bbox        = bbox,
      scale_bar   = scale_bar,
      north_arrow = north_arrow,
      scale_pos   = scale_pos,
      north_pos   = north_pos
    )
  }

  out <- list(
    raster   = r_res,
    houses   = sf_houses_focal,
    buffer   = buf_sf,
    grid     = grid_focal,
    plot     = p_out
  )

  class(out) <- "d4h_buffer_analysis"
  out
}

#' @export
print.d4h_buffer_analysis <- function(x, ...) {
  cat("\n=== DRONES4HEALTH: FOCAL BUFFER ANALYSIS ===\n")
  cat(sprintf("Houses analyzed in focus area : %d buildings\n", nrow(x$houses)))
  n_cells <- if (inherits(x$grid, "sf") || inherits(x$grid, "data.frame")) {
    nrow(x$grid)
  } else if (is.list(x$grid) && !is.null(x$grid$sf)) {
    nrow(x$grid$sf)
  } else {
    0L
  }
  cat(sprintf("Grid cells covered            : %d cells\n", n_cells))
  cat(sprintf("Resulting raster layer        : %s\n", names(x$raster)[1]))
  print(x$raster)
  if (!is.null(x$plot)) {
    cat("Plot available in $plot (run print(obj$plot))\n")
  }
  invisible(x)
}
