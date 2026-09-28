#' @title Interactive Side-by-Side Raster Swipe Viewer
#' @description Renders an interactive leaflet slider comparing two raster layers side-by-side with a single swipe bar over an optional base map.
#' @param x SpatRaster or character path. Left layer to compare (e.g., NDVI, RGB, Bare Soil Mask, or orthomosaic).
#' @param y SpatRaster or character path. Right layer to compare (e.g., MSAVI2, SAVI, NDRE, Slope, Thermal, or DSM).
#' @param grid Optional SpatVector, sf, or character path. Zonal grid boundaries to overlay on the map. Default: NULL (no grid).
#' @param basemap Logical or character. If TRUE, includes satellite (Esri.WorldImagery) and OpenStreetMap base layers. If FALSE or NULL, disables the background map. You can also specify a provider tile name (default: TRUE).
#' @param col_x Character or color vector. Color palette for layer x (default: "viridis"). Options include "viridis", "magma", "terrain", or custom color vectors like \code{"#2a9d8f"}.
#' @param col_y Character or color vector. Color palette for layer y (default: "magma"). Options include "viridis", "magma", "terrain", or custom color vectors.
#' @param limits_x Numeric vector c(min, max). Explicit color scale limits for layer x. If NULL (default), robust 2%-98% quantiles are used for continuous layers.
#' @param limits_y Numeric vector c(min, max). Explicit color scale limits for layer y (e.g., c(0, 0.8)). If NULL (default), robust 2%-98% quantiles are used for continuous layers.
#' @param max_pixels Integer. Maximum cell count for fast interactive rendering (default: 500000). Downsample with \code{terra::aggregate()} if exceeded.
#' @return A leaflet / htmlwidget interactive slider widget.
#' @export
d4h_mapview_swipe <- function(x, y, grid = NULL, basemap = TRUE, col_x = "viridis", col_y = "magma", limits_x = NULL, limits_y = NULL, max_pixels = 500000) {
  # 1. Validar dependencias requeridas
  if (!requireNamespace("leaflet", quietly = TRUE) || !requireNamespace("leaflet.extras2", quietly = TRUE) || !requireNamespace("raster", quietly = TRUE)) {
    stop("Para la visualizacion swipe interactiva se requiere instalar: install.packages(c('leaflet', 'leaflet.extras2', 'raster'))", call. = FALSE)
  }

  # 2. Funcion auxiliar interna para procesar, optimizar y reproyectar cada capa
  .prep_swipe_layer <- function(r_in, max_px, label) {
    r <- .ensure_raster(r_in, mask_zeros = FALSE)

    # Enmascarar infinitos y NaNs a NA estructural
    r[is.nan(r) | is.infinite(r)] <- NA

    # Validar que existan pixeles con datos
    vals_raw <- terra::values(r, mat = FALSE)
    vals_raw_fin <- vals_raw[!is.na(vals_raw) & is.finite(vals_raw)]
    if (length(vals_raw_fin) == 0L) {
      stop(sprintf("La capa '%s' no contiene datos validos (todos los pixeles son NA o no coinciden en extension).", label), call. = FALSE)
    }

    # Agregacion/downsampling espacial eficiente si excede max_pixels
    total_cells <- terra::ncell(r)
    if (total_cells > max_px) {
      agg_fact <- ceiling(sqrt(total_cells / max_px))
      is_bin <- length(unique(vals_raw_fin)) <= 2 && all(vals_raw_fin %in% c(0, 1))
      r_agg <- if (is_bin) {
        terra::aggregate(r, fact = agg_fact, fun = "max", na.rm = TRUE)
      } else {
        terra::aggregate(r, fact = agg_fact, fun = "mean", na.rm = TRUE)
      }
      r_mask <- terra::aggregate(!is.na(r), fact = agg_fact, fun = "mean", na.rm = TRUE)
      r_agg[r_mask < 0.3] <- NA
      r <- r_agg
    }

    # Reproyectar explicitamente a Web Mercator (EPSG:3857)
    if (!is.na(terra::crs(r)) && terra::crs(r) != "") {
      proj_str <- terra::crs(r, proj = TRUE)
      if (!is.na(proj_str) && !grepl("3857", proj_str)) {
        r <- terra::project(r, "EPSG:3857", method = "bilinear")
      }
    } else {
      warning(sprintf("La capa '%s' no tiene CRS definido; asumiendo EPSG:3857.", label), call. = FALSE)
    }

    r
  }

  # 3. Funcion auxiliar para resolver paletas de colores
  .resolve_palette <- function(pal_def) {
    if (is.character(pal_def) && length(pal_def) == 1L) {
      if (pal_def == "viridis") {
        if (requireNamespace("viridisLite", quietly = TRUE)) {
          viridisLite::viridis(256)
        } else {
          grDevices::hcl.colors(256, "Viridis")
        }
      } else if (pal_def == "magma") {
        if (requireNamespace("viridisLite", quietly = TRUE)) {
          viridisLite::magma(256)
        } else {
          grDevices::hcl.colors(256, "Magma")
        }
      } else if (pal_def == "terrain" || pal_def == "terrain.colors") {
        grDevices::terrain.colors(256)
      } else if (pal_def == "spectral") {
        grDevices::hcl.colors(256, "Spectral")
      } else {
        tryCatch(
          grDevices::hcl.colors(256, pal_def),
          error = function(e) pal_def
        )
      }
    } else if (is.function(pal_def)) {
      pal_def(256)
    } else {
      pal_def
    }
  }

  # 4. Procesar y optimizar capas x e y
  r_x <- .prep_swipe_layer(x, max_pixels, "x (izquierda)")
  r_y <- .prep_swipe_layer(y, max_pixels, "y (derecha)")

  name_x <- names(r_x)[1]
  name_y <- names(r_y)[1]
  if (is.null(name_x) || name_x == "") name_x <- "Layer X"
  if (is.null(name_y) || name_y == "") name_y <- "Layer Y"

  vals_x <- terra::values(r_x, mat = FALSE)
  vals_y <- terra::values(r_y, mat = FALSE)

  vals_x_fin <- vals_x[!is.na(vals_x) & is.finite(vals_x)]
  vals_y_fin <- vals_y[!is.na(vals_y) & is.finite(vals_y)]

  uniq_x <- sort(unique(vals_x_fin))
  is_bin_x <- (length(uniq_x) <= 2 && all(uniq_x %in% c(0, 1))) || (length(uniq_x) == 1 && uniq_x == 1)

  uniq_y <- sort(unique(vals_y_fin))
  is_bin_y <- (length(uniq_y) <= 2 && all(uniq_y %in% c(0, 1))) || (length(uniq_y) == 1 && uniq_y == 1)

  # --- Configuracion de Capa X (Izquierda) ---
  if (is_bin_x) {
    col_x_hex <- if (is.character(col_x) && length(col_x) >= 1) col_x[length(col_x)] else "#2a9d8f"
    if (col_x_hex %in% c("viridis", "magma", "terrain")) col_x_hex <- "#2a9d8f"
    
    if (length(uniq_x) == 1 && uniq_x == 1) {
      pal_fn_x <- leaflet::colorFactor(palette = col_x_hex, domain = 1, na.color = "transparent")
      legend_type_x <- "factor_single"
    } else {
      col0 <- if (length(col_x) >= 2) col_x[1] else "transparent"
      pal_fn_x <- leaflet::colorFactor(palette = c(col0, col_x_hex), domain = c(0, 1), na.color = "transparent")
      legend_type_x <- if (col0 == "transparent" || col0 == "#ffffff00") "factor_single" else "factor_double"
    }
    rx_raster <- raster::raster(r_x)
  } else {
    pal_x <- .resolve_palette(col_x)
    rng_x <- if (!is.null(limits_x)) {
      limits_x
    } else if (length(vals_x_fin) > 100) {
      unname(stats::quantile(vals_x_fin, probs = c(0.02, 0.98), na.rm = TRUE))
    } else {
      range(vals_x_fin)
    }
    if (rng_x[1] == rng_x[2]) rng_x <- c(rng_x[1] - 0.5, rng_x[2] + 0.5)

    r_x_clamped <- terra::clamp(r_x, lower = rng_x[1], upper = rng_x[2])
    rx_raster <- raster::raster(r_x_clamped)
    pal_fn_x <- leaflet::colorNumeric(palette = pal_x, domain = c(rng_x[1] - 1e-4, rng_x[2] + 1e-4), na.color = "transparent")
    legend_type_x <- "numeric"
  }

  # --- Configuracion de Capa Y (Derecha) ---
  if (is_bin_y) {
    col_y_hex <- if (is.character(col_y) && length(col_y) >= 1) col_y[length(col_y)] else "#d95f02"
    if (col_y_hex %in% c("viridis", "magma", "terrain")) col_y_hex <- "#d95f02"

    if (length(uniq_y) == 1 && uniq_y == 1) {
      pal_fn_y <- leaflet::colorFactor(palette = col_y_hex, domain = 1, na.color = "transparent")
      legend_type_y <- "factor_single"
    } else {
      col0_y <- if (length(col_y) >= 2) col_y[1] else "transparent"
      pal_fn_y <- leaflet::colorFactor(palette = c(col0_y, col_y_hex), domain = c(0, 1), na.color = "transparent")
      legend_type_y <- if (col0_y == "transparent" || col0_y == "#ffffff00") "factor_single" else "factor_double"
    }
    ry_raster <- raster::raster(r_y)
  } else {
    pal_y <- .resolve_palette(col_y)
    rng_y <- if (!is.null(limits_y)) {
      limits_y
    } else if (length(vals_y_fin) > 100) {
      unname(stats::quantile(vals_y_fin, probs = c(0.02, 0.98), na.rm = TRUE))
    } else {
      range(vals_y_fin)
    }
    if (rng_y[1] == rng_y[2]) rng_y <- c(rng_y[1] - 0.5, rng_y[2] + 0.5)

    r_y_clamped <- terra::clamp(r_y, lower = rng_y[1], upper = rng_y[2])
    ry_raster <- raster::raster(r_y_clamped)
    pal_fn_y <- leaflet::colorNumeric(palette = pal_y, domain = c(rng_y[1] - 1e-4, rng_y[2] + 1e-4), na.color = "transparent")
    legend_type_y <- "numeric"
  }

  # 5. Construir widget leaflet con panes independientes
  widget <- leaflet::leaflet() |>
    leaflet::addMapPane("leftPane", zIndex = 410) |>
    leaflet::addMapPane("rightPane", zIndex = 420)

  # Manejo del mapa base segun parametro basemap
  if (isTRUE(basemap)) {
    widget <- widget |>
      leaflet::addProviderTiles("Esri.WorldImagery", group = "Satelite") |>
      leaflet::addProviderTiles("OpenStreetMap", group = "OpenStreetMap") |>
      leaflet::addLayersControl(baseGroups = c("Satelite", "OpenStreetMap"), position = "topright")
  } else if (is.character(basemap) && length(basemap) == 1L) {
    widget <- widget |>
      leaflet::addProviderTiles(basemap, group = basemap)
  }

  # Agregar imagenes raster en sus respectivos panes
  widget <- widget |>
    leaflet::addRasterImage(
      rx_raster,
      colors = pal_fn_x,
      layerId = "left_img",
      group = "swipe_left",
      opacity = 0.9,
      options = leaflet::gridOptions(pane = "leftPane")
    ) |>
    leaflet::addRasterImage(
      ry_raster,
      colors = pal_fn_y,
      layerId = "right_img",
      group = "swipe_right",
      opacity = 0.9,
      options = leaflet::gridOptions(pane = "rightPane")
    ) |>
    leaflet.extras2::addSidebyside(
      layerId = "sidebyside_ctrl",
      leftId = "left_img",
      rightId = "right_img"
    )

  # JS Hook para enlazar las capas al control sidebyside existente (1 solo slider)
  js_sidebyside_hook <- htmlwidgets::JS(
    "function(el, x) {",
    "  var map = this;",
    "  var leftLayer = map.layerManager.getLayer('image', 'left_img') || map.layerManager.getLayer('tile', 'left_img');",
    "  var rightLayer = map.layerManager.getLayer('image', 'right_img') || map.layerManager.getLayer('tile', 'right_img');",
    "  var ctrl = map.controls.get('sidebyside_ctrl');",
    "  if (ctrl) {",
    "    if (leftLayer) ctrl.setLeftLayers(leftLayer);",
    "    if (rightLayer) ctrl.setRightLayers(rightLayer);",
    "  }",
    "}"
  )

  widget <- htmlwidgets::onRender(widget, js_sidebyside_hook)

  # Leyenda capa X (Izquierda)
  if (legend_type_x == "factor_single") {
    lbl_x <- if (grepl("bare|suelo", name_x, ignore.case = TRUE)) "Suelo desnudo (1)" else "Presencia (1)"
    widget <- widget |> leaflet::addLegend(colors = col_x_hex, labels = lbl_x, title = name_x, opacity = 1, position = "bottomleft")
  } else if (legend_type_x == "factor_double") {
    lbl0 <- "Ausencia (0)"
    lbl1 <- if (grepl("bare|suelo", name_x, ignore.case = TRUE)) "Suelo desnudo (1)" else "Presencia (1)"
    widget <- widget |> leaflet::addLegend(colors = c(col0, col_x_hex), labels = c(lbl0, lbl1), title = name_x, opacity = 1, position = "bottomleft")
  } else {
    widget <- widget |> leaflet::addLegend(pal = pal_fn_x, values = rng_x, title = name_x, position = "bottomleft")
  }

  # Leyenda capa Y (Derecha)
  if (legend_type_y == "factor_single") {
    lbl_y <- if (grepl("bare|suelo", name_y, ignore.case = TRUE)) "Suelo desnudo (1)" else "Presencia (1)"
    widget <- widget |> leaflet::addLegend(colors = col_y_hex, labels = lbl_y, title = name_y, opacity = 1, position = "bottomright")
  } else if (legend_type_y == "factor_double") {
    lbl0_y <- "Ausencia (0)"
    lbl1_y <- if (grepl("bare|suelo", name_y, ignore.case = TRUE)) "Suelo desnudo (1)" else "Presencia (1)"
    widget <- widget |> leaflet::addLegend(colors = c(col0_y, col_y_hex), labels = c(lbl0_y, lbl1_y), title = name_y, opacity = 1, position = "bottomright")
  } else {
    widget <- widget |> leaflet::addLegend(pal = pal_fn_y, values = rng_y, title = name_y, position = "bottomright")
  }

  # 6. Superposicion opcional de grilla (SpatVector o sf)
  if (!is.null(grid)) {
    grid_sf <- if (is.character(grid) && length(grid) == 1L) {
      sf::st_read(grid, quiet = TRUE)
    } else if (inherits(grid, "SpatVector")) {
      sf::st_as_sf(grid)
    } else if (inherits(grid, "sf")) {
      grid
    } else {
      warning("'grid' must be a SpatVector, sf, or file path. Grid overlay skipped.", call. = FALSE)
      NULL
    }

    if (!is.null(grid_sf)) {
      grid_sf_wgs <- sf::st_transform(grid_sf, 4326)
      widget <- leaflet::addPolygons(
        map = widget,
        data = grid_sf_wgs,
        fill = FALSE,
        color = "black",
        weight = 1.2,
        opacity = 0.85
      )
    }
  }

  widget
}
