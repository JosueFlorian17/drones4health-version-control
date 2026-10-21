#' @title Cartographic Visualization with ggplot2
#' @description Plots continuous raster layers or zonal grids using aggregation and geom_raster.
#' @param x SpatRaster, SpatVector, sf, or character path to plot.
#' @param grid Optional SpatVector, sf, or character path to overlay grid boundaries.
#' @param palette Character. Color palette name ("viridis", "magma", "terrain") or custom color vector (default: "viridis").
#' @param houses Optional sf, data.frame, SpatVector, or character path to CSV containing house coordinates. Automatically plotted as red points (or customizable color/size).
#' @param houses_filter_extent Logical. If TRUE, filters houses to only those intersecting the raster extent / footprint. If FALSE (default), shows all houses including surrounding ones.
#' @param house_color Character. Color for house points (default: "red").
#' @param house_size Numeric. Size for house points (default: 2.0).
#' @param rgb_bands Numeric vector of length 3 (e.g. c(1, 2, 3)). If x is a multi-band raster and rgb_bands is specified, renders in true/false RGB.
#' @return A ggplot object.
#' @export
d4h_plot <- function(x, grid = NULL, houses = NULL, houses_filter_extent = FALSE, house_color = "red", house_size = 2.0, rgb_bands = NULL, palette = "viridis", limits = NULL, title = NULL, max_pixels = 500000) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop(paste("File not found:", x), call. = FALSE)
    x <- terra::rast(x)
  }

  if (inherits(x, "SpatRaster")) {
    is_rgb <- !is.null(rgb_bands) || (terra::nlyr(x) >= 3 && is.null(palette))

    if (is_rgb) {
      bands <- if (!is.null(rgb_bands)) rgb_bands else c(1, 2, 3)
      r_rgb <- x[[bands]]

      total_cells <- terra::ncell(r_rgb)
      if (total_cells > max_pixels) {
        agg_fact <- ceiling(sqrt(total_cells / max_pixels))
        r_rgb <- terra::aggregate(r_rgb, fact = agg_fact, fun = "mean", na.rm = TRUE)
      }

      if (requireNamespace("tidyterra", quietly = TRUE)) {
        p <- ggplot2::ggplot() +
          tidyterra::geom_spatraster_rgb(data = r_rgb, r = 1, g = 2, b = 3, max_col_value = 255)
      } else {
        # Fallback si tidyterra no esta presente: calcular RGB a colores hex
        df_rgb <- as.data.frame(r_rgb, xy = TRUE, na.rm = TRUE)
        colnames(df_rgb)[3:5] <- c("r", "g", "b")
        df_rgb$r <- pmin(pmax(df_rgb$r, 0), 255)
        df_rgb$g <- pmin(pmax(df_rgb$g, 0), 255)
        df_rgb$b <- pmin(pmax(df_rgb$b, 0), 255)
        df_rgb$hex <- grDevices::rgb(df_rgb$r, df_rgb$g, df_rgb$b, maxColorValue = 255)

        p <- ggplot2::ggplot() +
          ggplot2::geom_raster(data = df_rgb, ggplot2::aes(x = x, y = y, fill = hex)) +
          ggplot2::scale_fill_identity()
      }

    } else {
      r_layer <- x[[1]]
      var_name <- names(r_layer)[1]

      # 1. Enmascarar ceros absolutos, infinitos y NaNs a NA estructural
      r_layer[is.nan(r_layer) | is.infinite(r_layer) | r_layer == 0] <- NA

      # 2. Filtrar ruidos residuales de interpolación según el tipo de índice
      if (grepl("IMSR", var_name, ignore.case = TRUE)) {
        r_layer[r_layer < 1e-4] <- NA
      }

      # 3. Agregación espacial para optimizar rendimiento de renderizado
      total_cells <- terra::ncell(r_layer)
      if (total_cells > max_pixels) {
        agg_fact <- ceiling(sqrt(total_cells / max_pixels))
        r_layer_agg <- terra::aggregate(r_layer, fact = agg_fact, fun = "mean", na.rm = TRUE)
        r_mask <- terra::aggregate(!is.na(r_layer), fact = agg_fact, fun = "mean", na.rm = TRUE)
        r_layer_agg[r_mask < 0.4] <- NA
        r_layer <- r_layer_agg
      }

      df_plot <- as.data.frame(r_layer, xy = TRUE, na.rm = TRUE)
      colnames(df_plot) <- c("x", "y", "value")

      # 4. Limpieza final de filas no válidas en la tabla de dibujo
      df_plot <- df_plot[!is.na(df_plot$value) & is.finite(df_plot$value), ]
      if (grepl("IMSR", var_name, ignore.case = TRUE)) {
        df_plot <- df_plot[df_plot$value >= 1e-4, ]
      }

      p <- ggplot2::ggplot() +
        ggplot2::geom_raster(data = df_plot, ggplot2::aes(x = x, y = y, fill = value))

      if (palette == "viridis") {
        p <- p + ggplot2::scale_fill_viridis_c(limits = limits, na.value = "transparent", name = var_name)
      } else if (palette == "magma") {
        p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limits, na.value = "transparent", name = var_name)
      } else if (palette == "terrain") {
        p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limits, na.value = "transparent", name = var_name)
      } else if (is.character(palette) && length(palette) > 1) {
        p <- p + ggplot2::scale_fill_gradientn(colors = palette, limits = limits, na.value = "transparent", name = var_name)
      } else {
        p <- p + ggplot2::scale_fill_continuous(limits = limits, na.value = "transparent", name = var_name)
      }
    }

    if (!is.null(grid)) {
      if (is.character(grid) && length(grid) == 1L) grid <- terra::vect(grid)
      if (inherits(grid, "SpatVector")) grid <- sf::st_as_sf(grid)
      p <- p + ggplot2::geom_sf(data = grid, fill = NA, color = "black", linewidth = 0.25)
    }

  } else if (inherits(x, "SpatVector") || inherits(x, "sf")) {
    sf_obj <- if (inherits(x, "SpatVector")) sf::st_as_sf(x) else x
    col_name <- colnames(sf_obj)[2]

    p <- ggplot2::ggplot(data = sf_obj) +
      ggplot2::geom_sf(ggplot2::aes(fill = .data[[col_name]]), color = "black", linewidth = 0.2)

    if (palette == "viridis") {
      p <- p + ggplot2::scale_fill_viridis_c(limits = limits, na.value = "transparent", name = col_name)
    } else if (palette == "terrain") {
      p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limits, na.value = "transparent", name = col_name)
    } else {
      p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limits, na.value = "transparent", name = col_name)
    }
  } else if (is.data.frame(x) && "indicator" %in% names(x) && "mean" %in% names(x)) {
    has_quantiles <- all(c("q25", "q75") %in% names(x))

    p <- ggplot2::ggplot(data = x, ggplot2::aes(x = indicator, y = mean, fill = indicator)) +
      ggplot2::geom_col(width = 0.45, alpha = 0.85, color = "black", linewidth = 0.3)

    if (has_quantiles) {
      p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = q25, ymax = q75), width = 0.18, color = "black", linewidth = 0.6)
    }

    if (palette == "viridis") {
      p <- p + ggplot2::scale_fill_viridis_d(option = "viridis")
    } else if (palette == "magma") {
      p <- p + ggplot2::scale_fill_viridis_d(option = "magma")
    }

    p <- p +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        legend.position = "none",
        axis.title.x = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank()
      ) +
      ggplot2::labs(
        title = if (!is.null(title)) title else "Global Mosaic Indicator Summary",
        subtitle = if (has_quantiles) "Mean with Interquartile Range (Q25 - Q75)" else "Mean value",
        y = "Mean Value"
      )

    return(p)

  } else {
    stop("'x' must be a SpatRaster, SpatVector, sf object, summary data.frame, or valid file path.", call. = FALSE)
  }

  # 5. Capa de Casas (Puntos rojos u otros estilos configurables)
  if (!is.null(houses)) {
    # Soporta path a CSV, data.frame con lon/lat o x/y, SpatVector o sf
    sf_houses <- if (is.character(houses) && length(houses) == 1L) {
      if (grepl("\\.csv$", houses, ignore.case = TRUE)) {
        df_h <- utils::read.csv(houses)
        # Identificar columnas de longitud y latitud o x/y
        lon_col <- grep("^(lon|lng|long|longitude|x)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
        lat_col <- grep("^(lat|latitude|y)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
        if (is.na(lon_col) || is.na(lat_col)) {
          stop("El archivo CSV no contiene columnas reconocibles de coordenadas (lon/lat o x/y).", call. = FALSE)
        }
        # Asumir EPSG:4326 si son coordenadas geograficas
        is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
        init_crs <- if (is_ll) 4326 else terra::crs(x)
        sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
      } else {
        terra::vect(houses)
      }
    } else if (is.data.frame(houses) && !inherits(houses, "sf")) {
      lon_col <- grep("^(lon|lng|long|longitude|x)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("El data.frame no contiene columnas reconocibles de coordenadas (lon/lat o x/y).", call. = FALSE)
      }
      is_ll <- all(abs(houses[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(houses[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else terra::crs(x)
      sf::st_as_sf(houses, coords = c(lon_col, lat_col), crs = init_crs)
    } else if (inherits(houses, "SpatVector")) {
      sf::st_as_sf(houses)
    } else if (inherits(houses, "sf")) {
      houses
    } else {
      stop("'houses' debe ser un objeto sf, SpatVector, data.frame o ruta a un archivo CSV.", call. = FALSE)
    }

    # Reproyectar a la referencia del mapa si es necesario
    if (inherits(x, "SpatRaster") || inherits(x, "SpatVector")) {
      target_crs <- sf::st_crs(terra::crs(x))
      if (!is.na(target_crs) && sf::st_crs(sf_houses) != target_crs) {
        sf_houses <- sf::st_transform(sf_houses, target_crs)
      }
      if (isTRUE(houses_filter_extent)) {
        ext_poly <- sf::st_as_sfc(sf::st_bbox(terra::ext(x), crs = target_crs))
        sf_houses <- sf::st_filter(sf_houses, ext_poly)
      }
    } else if (inherits(x, "sf")) {
      target_crs <- sf::st_crs(x)
      if (!is.na(target_crs) && sf::st_crs(sf_houses) != target_crs) {
        sf_houses <- sf::st_transform(sf_houses, target_crs)
      }
      if (isTRUE(houses_filter_extent)) {
        ext_poly <- sf::st_as_sfc(sf::st_bbox(x))
        sf_houses <- sf::st_filter(sf_houses, ext_poly)
      }
    }

    p <- p +
      ggplot2::geom_sf(data = sf_houses, color = house_color, size = house_size, shape = 21, fill = house_color, alpha = 0.9)
  }

  p <- p +
    ggplot2::coord_sf() +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      panel.background = ggplot2::element_rect(fill = "transparent", color = NA),
      plot.background = ggplot2::element_rect(fill = "transparent", color = NA)
    )

  if (!is.null(title)) p <- p + ggplot2::labs(title = title)

  p
}
