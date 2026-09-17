#' @title Cartographic Visualization with ggplot2
#' @description Plots continuous raster layers (SpatRaster) or zonal grids (SpatVector / sf) using aggregation and geom_raster to prevent sampling artefacts.
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
    total_cells <- terra::ncell(r_layer)

    if (total_cells > max_pixels) {
      agg_fact <- ceiling(sqrt(total_cells / max_pixels))
      r_layer <- terra::aggregate(r_layer, fact = agg_fact, fun = "mean", na.rm = TRUE)
    }

    df_plot <- as.data.frame(r_layer, xy = TRUE, na.rm = TRUE)
    var_name <- names(r_layer)[1]
    colnames(df_plot) <- c("x", "y", "value")

    df_plot <- df_plot[
      !is.na(df_plot$value) &
        !is.nan(df_plot$value) &
        is.finite(df_plot$value) &
        abs(df_plot$value) > 1e-6,
    ]

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
      p <- p + ggplot2::scale_fill_viridis_c(limits = limits, name = col_name)
    } else if (palette == "terrain") {
      p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limits, name = col_name)
    } else {
      p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limits, name = col_name)
    }
  } else {
    stop("'x' must be a SpatRaster, SpatVector, sf object, or valid file path.", call. = FALSE)
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
