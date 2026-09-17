#' @title Cartographic Visualization with ggplot2
#' @description Plots continuous raster layers (SpatRaster) or zonal grids (SpatVector / sf) with ggplot2.
#' @param x SpatRaster, SpatVector, or sf object to plot.
#' @param grid Optional SpatVector or sf object to overlay grid borders.
#' @param palette Character. Color palette ("viridis", "magma", "terrain" or custom colors vector).
#' @param limits Numeric vector c(min, max) to fix the color scale limits.
#' @param title Character. Plot title.
#' @param max_pixels Integer. Maximum number of pixels to sample for fast rendering (default: 500000).
#' @return A ggplot object.
#' @export
d4h_plot <- function(x, grid = NULL, palette = "viridis", limits = NULL, title = NULL, max_pixels = 500000) {
  if (inherits(x, "SpatRaster")) {
    r_layer <- x[[1]]

    if (terra::ncell(r_layer) > max_pixels) {
      df_plot <- terra::spatSample(r_layer, size = max_pixels, method = "regular", na.rm = TRUE, xy = TRUE, as.df = TRUE)
    } else {
      df_plot <- as.data.frame(r_layer, xy = TRUE, na.rm = TRUE)
    }

    var_name <- names(r_layer)[1]
    colnames(df_plot) <- c("x", "y", "value")

    df_plot <- df_plot[
      !is.na(df_plot$value) &
        !is.nan(df_plot$value) &
        is.finite(df_plot$value) &
        abs(df_plot$value) > 1e-6,
    ]

    p <- ggplot2::ggplot() +
      ggplot2::geom_tile(data = df_plot, ggplot2::aes(x = x, y = y, fill = value))

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
      if (inherits(grid, "SpatVector")) grid <- sf::st_as_sf(grid)
      p <- p + ggplot2::geom_sf(data = grid, fill = NA, color = "black", linewidth = 0.25)
    }

  } else if (inherits(x, "SpatVector") || inherits(x, "sf")) {
    sf_obj <- if (inherits(x, "SpatVector")) sf::st_as_sf(x) else x
    col_name <- colnames(sf_obj)[2]

    p <- ggplot2::ggplot(data = sf_obj) +
      ggplot2::geom_sf(ggplot2::aes(fill = .data[[col_name]]), color = "black", linewidth = 0.2)

    if (palette == "viridis") {
      p <- p + ggplot2::scale_fill_viridis_c(limits = limits, name = col_name)
    } else if (palette == "terrain") {
      p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limits, name = col_name)
    } else {
      p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limits, name = col_name)
    }
  } else {
    stop("'x' must be a SpatRaster, SpatVector, or sf object.", call. = FALSE)
  }

  p <- p +
    ggplot2::coord_sf() +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank()
    )

  if (!is.null(title)) p <- p + ggplot2::labs(title = title)

  p
}
