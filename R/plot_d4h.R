#' Visualización cartográfica con ggplot2
#'
#' Grafica capas ráster (SpatRaster) o grillas zonales (SpatVector / sf) con ggplot2.
#' Omite el área fuera del vuelo del dron y permite superponer grillas.
#'
#' @param x Objeto SpatRaster o SpatVector a graficar.
#' @param grilla Objeto SpatVector o sf opcional para superponer bordes de malla.
#' @param paleta Opciones: "viridis", "magma", "terrain" o vector de colores.
#' @param limites Vector numérico c(min, max) para fijar la escala de color.
#' @param titulo Título del gráfico.
#' @param max_pixels Número máximo de píxeles a muestrear para visualización ágil (default: 500000).
#' @return Objeto ggplot.
#' @export
d4h_plot <- function(x, grilla = NULL, paleta = "viridis", limites = NULL, titulo = NULL, max_pixels = 500000) {
  if (inherits(x, "SpatRaster")) {
    r_capa <- x[[1]]

    # Extraer coordenadas descartando NAs de origen
    if (terra::ncell(r_capa) > max_pixels) {
      df_plot <- terra::spatSample(r_capa, size = max_pixels, method = "regular", na.rm = TRUE, xy = TRUE, as.df = TRUE)
    } else {
      df_plot <- as.data.frame(r_capa, xy = TRUE, na.rm = TRUE)
    }

    nombre_var <- names(r_capa)[1]
    colnames(df_plot) <- c("x", "y", "valor")

    # Filtrar formalmente celdas no válidas y descartar el relleno fotogramétrico (ceros)
    df_plot <- df_plot[
      !is.na(df_plot$valor) &
        !is.nan(df_plot$valor) &
        is.finite(df_plot$valor) &
        abs(df_plot$valor) > 1e-6,
    ]

    p <- ggplot2::ggplot() +
      ggplot2::geom_tile(data = df_plot, ggplot2::aes(x = x, y = y, fill = valor))

    if (paleta == "viridis") {
      p <- p + ggplot2::scale_fill_viridis_c(limits = limites, na.value = "transparent", name = nombre_var)
    } else if (paleta == "magma") {
      p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limites, na.value = "transparent", name = nombre_var)
    } else if (paleta == "terrain") {
      p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limites, na.value = "transparent", name = nombre_var)
    } else if (is.character(paleta) && length(paleta) > 1) {
      p <- p + ggplot2::scale_fill_gradientn(colors = paleta, limits = limites, na.value = "transparent", name = nombre_var)
    } else {
      p <- p + ggplot2::scale_fill_continuous(limits = limites, na.value = "transparent", name = nombre_var)
    }

    if (!is.null(grilla)) {
      if (inherits(grilla, "SpatVector")) grilla <- sf::st_as_sf(grilla)
      p <- p + ggplot2::geom_sf(data = grilla, fill = NA, color = "black", linewidth = 0.25)
    }

  } else if (inherits(x, "SpatVector") || inherits(x, "sf")) {
    sf_obj <- if (inherits(x, "SpatVector")) sf::st_as_sf(x) else x
    nombre_col <- colnames(sf_obj)[2]

    p <- ggplot2::ggplot(data = sf_obj) +
      ggplot2::geom_sf(ggplot2::aes(fill = .data[[nombre_col]]), color = "black", linewidth = 0.2)

    if (paleta == "viridis") {
      p <- p + ggplot2::scale_fill_viridis_c(limits = limites, name = nombre_col)
    } else if (paleta == "terrain") {
      p <- p + ggplot2::scale_fill_gradientn(colors = grDevices::terrain.colors(50), limits = limites, name = nombre_col)
    } else {
      p <- p + ggplot2::scale_fill_viridis_c(option = "magma", limits = limites, name = nombre_col)
    }
  } else {
    stop("x debe ser un SpatRaster, SpatVector o sf.", call. = FALSE)
  }

  p <- p +
    ggplot2::coord_sf() +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank()
    )

  if (!is.null(titulo)) p <- p + ggplot2::labs(title = titulo)

  return(p)
}
