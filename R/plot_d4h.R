#' @title Cartographic Visualization with ggplot2
#' @description Plots continuous raster layers or zonal grids using aggregation and geom_raster.
#' @param x SpatRaster, SpatVector, sf, or character path to plot.
#' @param grid Optional SpatVector, sf, or character path to overlay grid boundaries.
#' @param palette Character. Color palette name ("viridis", "magma", "terrain") or custom color vector (default: "viridis").
#' @param limits Numeric vector c(min, max) to fix the color scale limits (default: NULL).
#' @param title Character. Plot title (default: NULL).
#' @param max_pixels Integer. Maximum number of pixels to display before regular aggregation (default: 500000).
#' @return A ggplot object.
#' @export
d4h_plot <- function(x, grid = NULL, palette = "viridis", limits = NULL, title = NULL, max_pixels = 500000) {
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop(paste("File not found:", x), call. = FALSE)
    x <- terra::rast(x)
  }

  if (inherits(x, "SpatRaster")) {
    r_layer <- x[[1]]
    var_name <- names(r_layer)[1]

    # 1. Enmascarar ceros absolutos, infinitos y NaNs a NA estructural
    r_layer[is.nan(r_layer) | is.infinite(r_layer) | r_layer == 0] <- NA

    # 2. Filtrar ruidos residuales de interpolación según el tipo de índice
    # IMSR es estrictamente positivo [0, 1]; si es IMSR, eliminamos residuos menores a 1e-4
    if (grepl("IMSR", var_name, ignore.case = TRUE)) {
      r_layer[r_layer < 1e-4] <- NA
    }

    # 3. Agregación espacial para optimizar rendimiento de renderizado
    total_cells <- terra::ncell(r_layer)
    if (total_cells > max_pixels) {
      agg_fact <- ceiling(sqrt(total_cells / max_pixels))
      # na.rm = TRUE promedia datos útiles, pero luego re-enmascaramos con la plantilla
      r_layer_agg <- terra::aggregate(r_layer, fact = agg_fact, fun = "mean", na.rm = TRUE)

      # Crear máscara binaria estricta de presencia de datos
      r_mask <- terra::aggregate(!is.na(r_layer), fact = agg_fact, fun = "mean", na.rm = TRUE)
      # Descartar celdas donde menos del 40% del área agregada tenía datos reales de vuelo
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
