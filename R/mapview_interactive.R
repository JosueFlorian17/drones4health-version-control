#' @title Interactive Side-by-Side Raster Swipe Viewer
#' @description Renders an interactive leaflet slider comparing two raster layers side-by-side with a single swipe bar over an optional base map.
#' @param x SpatRaster or character path. Left layer to compare (e.g., NDVI, RGB, or orthomosaic).
#' @param y SpatRaster or character path. Right layer to compare (e.g., SAVI, Slope, Thermal, or DSM).
#' @param grid Optional SpatVector, sf, or character path. Zonal grid boundaries to overlay on the map.
#' @param basemap Logical or character. If TRUE, includes satellite (Esri.WorldImagery) and OpenStreetMap base layers. If FALSE or NULL, disables the background map. You can also specify a provider tile name (default: TRUE).
#' @param col_x Character or color vector. Color palette for layer x (default: "viridis"). Options include "viridis", "magma", "terrain", or custom color vectors.
#' @param col_y Character or color vector. Color palette for layer y (default: "magma"). Options include "viridis", "magma", "terrain", or custom color vectors.
#' @param max_pixels Integer. Maximum cell count for fast interactive rendering (default: 500000). Downsample with \code{terra::aggregate()} if exceeded.
#' @return A leaflet / htmlwidget interactive slider widget.
#' @export
d4h_mapview_swipe <- function(x, y, grid = NULL, basemap = TRUE, col_x = "viridis", col_y = "magma", max_pixels = 500000) {
  # 1. Validar dependencias requeridas
  if (!requireNamespace("leaflet", quietly = TRUE) || !requireNamespace("leaflet.extras2", quietly = TRUE) || !requireNamespace("raster", quietly = TRUE)) {
    stop("Para la visualizacion swipe interactiva se requiere instalar: install.packages(c('leaflet', 'leaflet.extras2', 'raster'))", call. = FALSE)
  }

  # 2. Funcion auxiliar interna para procesar, optimizar y reproyectar cada capa
  .prep_swipe_layer <- function(r_in, max_px) {
    r <- .ensure_raster(r_in, mask_zeros = TRUE)

    # Enmascarar ceros, infinitos y NaNs a NA estructural
    r[is.nan(r) | is.infinite(r) | r == 0] <- NA

    # Agregacion/downsampling espacial eficiente si excede max_pixels
    total_cells <- terra::ncell(r)
    if (total_cells > max_px) {
      agg_fact <- ceiling(sqrt(total_cells / max_px))
      r_agg <- terra::aggregate(r, fact = agg_fact, fun = "mean", na.rm = TRUE)
      r_mask <- terra::aggregate(!is.na(r), fact = agg_fact, fun = "mean", na.rm = TRUE)
      r_agg[r_mask < 0.4] <- NA
      r <- r_agg
    }

    # Reproyectar explicitamente a Web Mercator (EPSG:3857)
    if (!is.na(terra::crs(r)) && terra::crs(r) != "") {
      proj_str <- terra::crs(r, proj = TRUE)
      if (!is.na(proj_str) && !grepl("3857", proj_str)) {
        r <- terra::project(r, "EPSG:3857", method = "bilinear")
      }
    } else {
      warning("Input raster lacks CRS definition; assuming EPSG:3857.", call. = FALSE)
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
          error = function(e) grDevices::terrain.colors(256)
        )
      }
    } else if (is.function(pal_def)) {
      pal_def(256)
    } else {
      pal_def
    }
  }

  # 4. Procesar y optimizar capas x e y
  r_x <- .prep_swipe_layer(x, max_pixels)
  r_y <- .prep_swipe_layer(y, max_pixels)

  name_x <- names(r_x)[1]
  name_y <- names(r_y)[1]
  if (is.null(name_x) || name_x == "") name_x <- "Layer X"
  if (is.null(name_y) || name_y == "") name_y <- "Layer Y"

  pal_x <- .resolve_palette(col_x)
  pal_y <- .resolve_palette(col_y)

  # Convertir a objetos RasterLayer del paquete raster
  rx_raster <- raster::raster(r_x)
  ry_raster <- raster::raster(r_y)

  vals_x <- terra::values(r_x, mat = FALSE)
  vals_y <- terra::values(r_y, mat = FALSE)

  # Paletas numericas independientes con na.color transparente
  pal_fn_x <- leaflet::colorNumeric(palette = pal_x, domain = vals_x, na.color = "transparent")
  pal_fn_y <- leaflet::colorNumeric(palette = pal_y, domain = vals_y, na.color = "transparent")

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

  # Leyendas independientes para cada capa
  widget <- widget |>
    leaflet::addLegend(pal = pal_fn_x, values = vals_x, title = name_x, position = "bottomleft") |>
    leaflet::addLegend(pal = pal_fn_y, values = vals_y, title = name_y, position = "bottomright")

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
