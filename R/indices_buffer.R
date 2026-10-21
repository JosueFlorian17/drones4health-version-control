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
#' @param radius Numeric. Buffer radius surrounding each house. Defined in number of grid cells (default: 3). If \code{radius_in_meters = TRUE}, interpreted directly as meters.
#' @param cell_size Numeric. Grid cell size in meters used to establish grid scale and calculate buffer distances (default: 50).
#' @param radius_in_meters Logical. If FALSE (default), total buffer distance is \code{radius * cell_size}. If TRUE, total buffer distance is \code{radius}.
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
#' @param plot Logical. If TRUE (default), returns a list with the raster, grid summary, and ggplot. If FALSE, skips rendering.
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
#'   # Run focal buffer analysis around houses (150m buffer)
#'   res_buffer <- d4h_indicator_buffer(
#'     indicator = "NDVI",
#'     houses    = houses_csv,
#'     radius    = 3,
#'     cell_size = 50,
#'     nir       = nir_path,
#'     red       = red_path,
#'     palette   = "viridis"
#'   )
#'   head(res_buffer$grid)
#' }
#' }
#' @export
d4h_indicator_buffer <- function(indicator = "NDVI",
                                 houses,
                                 radius = 3,
                                 cell_size = 50,
                                 radius_in_meters = FALSE,
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
                                 plot = TRUE) {

  # 1. Calcular distancia de buffer en metros
  buffer_dist_m <- if (isTRUE(radius_in_meters)) as.numeric(radius) else as.numeric(radius) * as.numeric(cell_size)
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
    stop("Debes proporcionar al menos una capa raster (nir, red, dem, green o raster_in) para georreferenciacion.", call. = FALSE)
  }

  target_crs <- sf::st_crs(terra::crs(r_ref))

  # 3. Parsear y reproyectar las casas
  sf_houses <- if (is.character(houses) && length(houses) == 1L) {
    if (grepl("\\.(xlsx|xls)$", houses, ignore.case = TRUE)) {
      df_h <- if (requireNamespace("readxl", quietly = TRUE)) {
        as.data.frame(readxl::read_excel(houses))
      } else if (requireNamespace("openxlsx", quietly = TRUE)) {
        openxlsx::read.xlsx(houses)
      } else {
        stop("Para leer archivos Excel (.xlsx/.xls) instala 'readxl': install.packages('readxl')", call. = FALSE)
      }
      lon_col <- grep("^(lon|lng|long|longitude|x|utm_x|easting)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y|utm_y|northing)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("El archivo Excel no contiene columnas reconocibles de coordenadas (lon/lat, x/y o utm_x/utm_y).", call. = FALSE)
      }
      is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else target_crs
      sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
    } else if (grepl("\\.csv$", houses, ignore.case = TRUE)) {
      df_h <- utils::read.csv(houses)
      lon_col <- grep("^(lon|lng|long|longitude|x|utm_x|easting)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y|utm_y|northing)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("El archivo CSV no contiene columnas reconocibles de coordenadas (lon/lat, x/y o utm_x/utm_y).", call. = FALSE)
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
      stop("El data.frame no contiene columnas reconocibles de coordenadas (lon/lat, x/y o utm_x/utm_y).", call. = FALSE)
    }
    is_ll <- all(abs(houses[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(houses[[lat_col]]) <= 90, na.rm = TRUE)
    init_crs <- if (is_ll) 4326 else target_crs
    sf::st_as_sf(houses, coords = c(lon_col, lat_col), crs = init_crs)
  } else if (inherits(houses, "SpatVector")) {
    sf::st_as_sf(houses)
  } else if (inherits(houses, "sf")) {
    houses
  } else {
    stop("'houses' debe ser un objeto sf, SpatVector, data.frame o ruta a un archivo CSV.", call. = FALSE)
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
      "TVI"    = d4h_tvi(nir = nir_c, red = red_c),
      "MSAVI2" = d4h_msavi2(nir = nir_c, red = red_c),
      "IRHE"   = d4h_irhe(red = red_c, green = green_c),
      "IMSR"   = d4h_imsr(red_edge = red_edge_c, red = red_c, nir = nir_c),
      "IRTS"   = {
        ndre_tmp <- d4h_ndre(nir = nir_c, red_edge = red_edge_c)
        d4h_irts(ndre = ndre_tmp, lst_local = lst_c, lst_surrounding = terra::focal(lst_c, w = 9, fun = "mean"), nir = nir_c)
      },
      "SLOPE"  = d4h_slope(dem_raster = dem_c),
      "TWI"    = d4h_twi(dem_raster = dem_c),
      "DSM"    = dem_c,
      "DEM"    = dem_c,
      stop(sprintf("Indicador '%s' no reconocido. Opciones: NDVI, NDWI, SAVI, DVI, GNDVI, NDRE, EVI, VARI, TVI, MSAVI2, IRHE, IMSR, IRTS, SLOPE, TWI, DSM.", indicator), call. = FALSE)
    )
  } else {
    stop("'indicator' debe ser un nombre de indice (string), funcion de calculo o SpatRaster.", call. = FALSE)
  }

  # 8. Enmascarar exterior del buffer si mask_outside = TRUE
  buf_vect <- terra::vect(buf_sf)
  if (isTRUE(mask_outside)) {
    r_res <- terra::mask(r_res, buf_vect)
  }

  # 9. Extraer resumen zonal por grilla dentro de la zona focal
  grid_focal <- d4h_summarize_grid(r_res, cell_size = cell_size, square = square, discard_na = TRUE)

  # 10. Ploteo especializado con casas y contorno del buffer
  p_out <- NULL
  if (isTRUE(plot)) {
    title_str <- if (!is.null(title)) {
      title
    } else {
      ind_name <- if (is.character(indicator)) toupper(indicator) else "Indicador"
      sprintf("%s en Área de Influencia de Casas (Radio: %g grillas / %g m)", ind_name, radius, round(buffer_dist_m))
    }

    # Renderizar el indicador focal
    p_out <- d4h_plot(
      x           = r_res,
      palette     = palette,
      limits      = limits,
      houses      = sf_houses_focal,
      house_color = house_color,
      house_size  = house_size,
      title       = title_str
    )

    # Agregar borde del buffer delineado
    p_out <- p_out +
      ggplot2::geom_sf(data = buf_sf, fill = NA, color = "black", linetype = "dashed", linewidth = 0.5)
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
  cat("\n=== DRONES4HEALTH: ANALISIS FOCAL POR BUFFER ===\n")
  cat(sprintf("Casas analizadas en el foco : %d viviendas\n", nrow(x$houses)))
  cat(sprintf("Celdas de grilla cubiertas  : %d celdas\n", nrow(x$grid)))
  cat(sprintf("Capa resultante             : %s\n", names(x$raster)[1]))
  print(x$raster)
  if (!is.null(x$plot)) {
    cat("Grafico disponible en $plot (ejecuta print(obj$plot))\n")
  }
  invisible(x)
}
