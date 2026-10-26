#' @title Unified Cartographic and Interactive Visualization
#' @description Unified visualization function for drone rasters, grids, vector features, and comparative dual-layer analysis.
#' When comparing two layers (\code{x} and \code{y}):
#' \itemize{
#'   \item If \code{interactive = TRUE}, renders an interactive side-by-side swipe slider widget (powered by \code{mapview} and \code{leaflet.extras2}).
#'   \item If \code{interactive = FALSE} (default), outputs a publication-ready static comparative panel via \code{ggplot2} and \code{cowplot}.
#' }
#' For a single layer: \code{interactive = TRUE} produces an interactive \code{mapview} web map, while \code{interactive = FALSE} produces a static \code{ggplot2} map.
#'
#' @param x SpatRaster, SpatVector, sf, summary data.frame, or character file path to plot (or left layer in comparative mode).
#' @param y Optional SpatRaster, SpatVector, sf, or character path. Right layer for comparative visualization (e.g., comparing NDVI vs NDWI, or Pre vs Post intervention).
#' @param interactive Logical. If \code{FALSE} (default), outputs a static \code{ggplot2} plot (or dual-panel comparison if \code{y} is provided). If \code{TRUE}, outputs an interactive swipe slider (when \code{y} is provided) or interactive \code{mapview} web map (when single layer).
#' @param grid Optional SpatVector, sf, or character path to overlay grid boundaries.
#' @param houses Optional sf, data.frame, SpatVector, or character path to CSV/Excel containing house coordinates. Automatically plotted as points.
#' @param houses_filter_extent Logical. If TRUE, filters houses to only those intersecting the raster extent / footprint. If FALSE (default), retains all houses.
#' @param house_color Character. Color for house points (default: "red").
#' @param house_size Numeric. Size for house points (default: 2.0).
#' @param rgb_bands Numeric vector of length 3 (e.g. c(1, 2, 3)). If x is a multi-band raster and rgb_bands is specified, renders in true/false RGB.
#' @param palette Character. Color palette name ("viridis", "magma", "terrain", "spectral") or custom color vector (default: "viridis"). For dual comparison, specifies palette for layer x.
#' @param palette_y Character. Color palette for layer y in dual comparative mode (default: "magma").
#' @param limits Numeric vector c(min, max) to fix color scale limits for layer x.
#' @param limits_y Numeric vector c(min, max) to fix color scale limits for layer y.
#' @param title Character. Custom plot title.
#' @param max_pixels Numeric. Maximum number of pixels to render before spatial aggregation (default: 500000).
#' @param zcol Character. Optional column name to color/fill spatial vector features (e.g., \code{"proximity_level"}, \code{"risk_level"}, or \code{"dist_water_m"}).
#' @param ortho SpatRaster or character path. Optional high-resolution RGB orthomosaic to render as an underlay base layer beneath grids, vectors, or point features.
#' @return A \code{ggplot} object (if \code{interactive = FALSE}) or an interactive \code{mapview} / \code{leaflet} slider widget (if \code{interactive = TRUE}).
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'   ndre_file <- system.file("extdata", "ndre.tif", package = "drones4health")
#'
#'   # 1. Comparative dual-indicator: interactive mapview swipe slider
#'   d4h_plot(x = ndvi_file, y = ndre_file, interactive = TRUE)
#'
#'   # 2. Comparative dual-indicator: static publication panel
#'   p_dual <- d4h_plot(x = ndvi_file, y = ndre_file, interactive = FALSE)
#'   print(p_dual)
#'
#'   # 3. Single indicator: static map
#'   p_single <- d4h_plot(x = ndvi_file, interactive = FALSE)
#'   print(p_single)
#' }
#' }
#' @export
d4h_plot <- function(x, y = NULL, interactive = FALSE, grid = NULL, houses = NULL,
                     houses_filter_extent = FALSE, house_color = "red", house_size = 2.0,
                     rgb_bands = NULL, palette = "viridis", palette_y = "magma",
                     limits = NULL, limits_y = NULL, title = NULL, max_pixels = 500000,
                     zcol = NULL, ortho = NULL) {

  # ============================================================================
  # MODO 1: COMPARACION DE DOS INDICADORES (x e y presentes)
  # ============================================================================
  if (!is.null(y)) {
    if (isTRUE(interactive)) {
      # MODO INTERACTIVO: SLIDER COMPARATIVO ROBUSTO CON LEAFLET.EXTRAS2 WRAPPED EN MAPVIEW
      if (!requireNamespace("leaflet", quietly = TRUE) || !requireNamespace("leaflet.extras2", quietly = TRUE) || !requireNamespace("raster", quietly = TRUE)) {
        stop("For interactive swipe slider ('interactive = TRUE'), install leaflet, leaflet.extras2, and raster: install.packages(c('leaflet', 'leaflet.extras2', 'raster'))", call. = FALSE)
      }

      # 1. Preparar capas raster
      r_x <- .ensure_raster(x, mask_zeros = FALSE)
      r_y <- .ensure_raster(y, mask_zeros = FALSE)

      name_x <- if (!is.null(title)) title else if (is.character(x) && length(x) == 1L) tools::file_path_sans_ext(basename(x)) else names(r_x)[1]
      name_y <- if (is.character(y) && length(y) == 1L) tools::file_path_sans_ext(basename(y)) else names(r_y)[1]

      # 2. Re-alinear y muestrear de forma segura para visualizacion web fluida
      .prep_interactive_raster <- function(r_in, max_px) {
        r_in[is.nan(r_in) | is.infinite(r_in) | r_in == 0] <- NA
        tot <- terra::ncell(r_in)
        if (tot > max_px) {
          fact <- ceiling(sqrt(tot / max_px))
          r_in <- terra::aggregate(r_in, fact = fact, fun = "mean", na.rm = TRUE)
        }
        if (!is.na(terra::crs(r_in)) && terra::crs(r_in) != "") {
          r_in <- terra::project(r_in, "EPSG:3857", method = "bilinear")
        }
        r_rast <- raster::raster(r_in)
        if (raster::ncell(r_rast) > 400000) {
          r_rast <- raster::sampleRegular(r_rast, size = 400000, asRaster = TRUE)
        }
        r_rast
      }

      rx_prep <- .prep_interactive_raster(r_x, max_pixels)
      ry_prep <- .prep_interactive_raster(r_y, max_pixels)

      # 3. Construir paletas de color Leaflet
      .build_pal <- function(pal_name, r_layer, custom_lims) {
        vals <- raster::values(r_layer)
        vals_fin <- vals[!is.na(vals) & is.finite(vals)]
        rng <- if (!is.null(custom_lims)) custom_lims else stats::quantile(vals_fin, probs = c(0.02, 0.98), na.rm = TRUE)
        if (rng[1] == rng[2]) rng <- c(rng[1] - 0.5, rng[2] + 0.5)

        leaflet_pal <- if (pal_name == "viridis") {
          "viridis"
        } else if (pal_name == "magma") {
          "magma"
        } else if (pal_name == "spectral") {
          "Spectral"
        } else if (pal_name == "terrain") {
          grDevices::terrain.colors(10)
        } else if (length(pal_name) > 1) {
          pal_name
        } else {
          "viridis"
        }

        list(
          fn  = leaflet::colorNumeric(palette = leaflet_pal, domain = rng, na.color = "transparent"),
          rng = rng
        )
      }

      pal_x_info <- .build_pal(palette, rx_prep, limits)
      pal_y_info <- .build_pal(palette_y, ry_prep, limits_y)

      # 4. Crear mapa interactivo con control sidebyside y panes separados
      m <- leaflet::leaflet() |>
        leaflet::addMapPane("leftPane", zIndex = 410) |>
        leaflet::addMapPane("rightPane", zIndex = 420) |>
        leaflet::addProviderTiles("OpenStreetMap", group = "OpenStreetMap") |>
        leaflet::addProviderTiles("Esri.WorldImagery", group = "Satellite") |>
        leaflet::addLayersControl(baseGroups = c("OpenStreetMap", "Satellite"), position = "topright") |>
        leaflet::addRasterImage(
          rx_prep,
          colors = pal_x_info$fn,
          layerId = "left_layer",
          group = name_x,
          options = leaflet::gridOptions(pane = "leftPane")
        ) |>
        leaflet::addRasterImage(
          ry_prep,
          colors = pal_y_info$fn,
          layerId = "right_layer",
          group = name_y,
          options = leaflet::gridOptions(pane = "rightPane")
        ) |>
        leaflet.extras2::addSidebyside(
          layerId = "swipe_slider",
          leftId = "left_layer",
          rightId = "right_layer"
        ) |>
        leaflet::addLegend(
          pal = pal_x_info$fn,
          values = pal_x_info$rng,
          title = paste0(name_x, " (Left)"),
          position = "bottomleft"
        ) |>
        leaflet::addLegend(
          pal = pal_y_info$fn,
          values = pal_y_info$rng,
          title = paste0(name_y, " (Right)"),
          position = "bottomright"
        )

      # JS Hook para reconectar y sincronizar el swipe en el cliente
      js_hook <- htmlwidgets::JS(
        "function(el, x) {",
        "  var map = this;",
        "  var leftLayer = map.layerManager.getLayer('image', 'left_layer');",
        "  var rightLayer = map.layerManager.getLayer('image', 'right_layer');",
        "  var ctrl = map.controls.get('swipe_slider');",
        "  if (ctrl) {",
        "    if (leftLayer) ctrl.setLeftLayers(leftLayer);",
        "    if (rightLayer) ctrl.setRightLayers(rightLayer);",
        "  }",
        "}"
      )
      m <- htmlwidgets::onRender(m, js_hook)

      # Superposicion opcional de grilla o casas
      if (!is.null(grid)) {
        sf_grid <- if (inherits(grid, "SpatVector")) sf::st_as_sf(grid) else if (inherits(grid, "sf")) grid else sf::st_read(grid, quiet = TRUE)
        sf_grid_wgs <- sf::st_transform(sf_grid, 4326)
        m <- m |> leaflet::addPolygons(data = sf_grid_wgs, color = "black", weight = 1.2, fill = FALSE, opacity = 0.85)
      }

      if (!is.null(houses)) {
        sf_h <- .d4h_prepare_houses_sf(houses, r_x, houses_filter_extent)
        sf_h_wgs <- sf::st_transform(sf_h, 4326)
        m <- m |> leaflet::addCircleMarkers(data = sf_h_wgs, color = house_color, radius = house_size * 2, fillOpacity = 0.9)
      }

      # Retornar objeto clase mapview
      if (requireNamespace("mapview", quietly = TRUE)) {
        return(methods::new("mapview", object = list(), map = m))
      } else {
        return(m)
      }

    } else {
      # MODO ESTATICO: PANEL COMPARATIVO SIDE-BY-SIDE VIA GGPLOT2
      name_x <- if (is.character(x) && length(x) == 1L) tools::file_path_sans_ext(basename(x)) else "Layer X"
      name_y <- if (is.character(y) && length(y) == 1L) tools::file_path_sans_ext(basename(y)) else "Layer Y"

      if (inherits(x, "SpatRaster")) name_x <- names(x)[1]
      if (inherits(y, "SpatRaster")) name_y <- names(y)[1]

      p1 <- d4h_plot(
        x                    = x,
        interactive          = FALSE,
        grid                 = grid,
        houses               = houses,
        houses_filter_extent = houses_filter_extent,
        house_color          = house_color,
        house_size           = house_size,
        palette              = palette,
        limits               = limits,
        title                = name_x,
        max_pixels           = max_pixels
      )

      p2 <- d4h_plot(
        x                    = y,
        interactive          = FALSE,
        grid                 = grid,
        houses               = houses,
        houses_filter_extent = houses_filter_extent,
        house_color          = house_color,
        house_size           = house_size,
        palette              = palette_y,
        limits               = limits_y,
        title                = name_y,
        max_pixels           = max_pixels
      )

      p_combined <- if (requireNamespace("cowplot", quietly = TRUE)) {
        cowplot::plot_grid(p1, p2, ncol = 2, align = "hv")
      } else if (requireNamespace("gridExtra", quietly = TRUE)) {
        gridExtra::grid.arrange(p1, p2, ncol = 2)
      } else {
        warning("Packages 'cowplot' or 'gridExtra' recommended for multi-panel static plots.", call. = FALSE)
        p1
      }

      if (!is.null(title)) {
        p_combined <- if (requireNamespace("cowplot", quietly = TRUE)) {
          title_p <- cowplot::ggdraw() + cowplot::draw_label(title, fontface = "bold", size = 13, hjust = 0.5)
          cowplot::plot_grid(title_p, p_combined, ncol = 1, rel_heights = c(0.1, 1))
        } else {
          p_combined
        }
      }

      return(p_combined)
    }
  }

  # ============================================================================
  # MODO 2: VISUALIZACION DE UNA SOLA CAPA
  # ============================================================================
  # 1. Resolver entrada si es ruta de archivo
  if (is.character(x) && length(x) == 1L) {
    if (!file.exists(x)) stop(paste("File not found:", x), call. = FALSE)
    x <- terra::rast(x)
  }

  # Submodo 2A: Interactivo para una sola capa (mapview)
  if (isTRUE(interactive)) {
    if (!requireNamespace("mapview", quietly = TRUE) || !requireNamespace("raster", quietly = TRUE)) {
      stop("For interactive visualization ('interactive = TRUE'), install mapview and raster: install.packages(c('mapview', 'raster'))", call. = FALSE)
    }

    col_fun <- if (palette == "viridis") {
      viridisLite::viridis
    } else if (palette == "magma") {
      viridisLite::magma
    } else if (palette == "spectral") {
      if (requireNamespace("RColorBrewer", quietly = TRUE)) {
        grDevices::colorRampPalette(RColorBrewer::brewer.pal(11, "Spectral"))
      } else {
        grDevices::colorRampPalette(c("#9e0142", "#d53e4f", "#f46d43", "#fdae61", "#fee08b", "#e6f598", "#abdda4", "#66c2a5", "#3288bd", "#5e4fa2"))
      }
    } else if (palette == "terrain") {
      grDevices::terrain.colors
    } else if (is.character(palette) && length(palette) > 1) {
      grDevices::colorRampPalette(palette)
    } else {
      viridisLite::viridis
    }

    m <- if (inherits(x, "SpatRaster")) {
      r_work <- x[[1]]
      var_name <- if (!is.null(title)) title else names(r_work)[1]
      r_work[is.nan(r_work) | is.infinite(r_work) | r_work == 0] <- NA

      total_cells <- terra::ncell(r_work)
      if (total_cells > max_pixels) {
        agg_fact <- ceiling(sqrt(total_cells / max_pixels))
        r_work <- terra::aggregate(r_work, fact = agg_fact, fun = "mean", na.rm = TRUE)
      }
      clean_basemaps <- c("OpenStreetMap", "Esri.WorldImagery")
      r_raster <- raster::raster(r_work)
      if (!is.null(limits)) {
        at_vals <- seq(limits[1], limits[2], length.out = 20)
        mapview::mapview(r_raster, col.regions = col_fun, layer.name = var_name, at = at_vals, map.types = clean_basemaps)
      } else {
        mapview::mapview(r_raster, col.regions = col_fun, layer.name = var_name, map.types = clean_basemaps)
      }
    } else if (inherits(x, "SpatVector") || inherits(x, "sf")) {
      clean_basemaps <- c("OpenStreetMap", "Esri.WorldImagery")
      sf_x <- if (inherits(x, "SpatVector")) sf::st_as_sf(x) else x
      fill_c <- if (!is.null(zcol)) {
        zcol
      } else if ("proximity_level" %in% names(sf_x)) {
        "proximity_level"
      } else if ("risk_level" %in% names(sf_x)) {
        "risk_level"
      } else if ("proximity_score" %in% names(sf_x)) {
        "proximity_score"
      } else {
        num_cols <- names(sf_x)[sapply(sf_x, is.numeric)]
        setdiff(num_cols, c("id", "grid_id", "row", "col"))[1]
      }

      if (!is.null(fill_c) && !is.na(fill_c) && fill_c %in% names(sf_x)) {
        mapview::mapview(sf_x, zcol = fill_c, layer.name = if (!is.null(title)) title else fill_c, map.types = clean_basemaps)
      } else {
        mapview::mapview(sf_x, layer.name = if (!is.null(title)) title else "Spatial Layer", map.types = clean_basemaps)
      }
    } else {
      stop("Interactive mapview requires a SpatRaster, SpatVector, or sf object.", call. = FALSE)
    }

    if (!is.null(grid)) {
      sf_grid <- if (inherits(grid, "SpatVector")) sf::st_as_sf(grid) else if (inherits(grid, "sf")) grid else sf::st_read(grid, quiet = TRUE)
      m <- m + mapview::mapview(sf_grid, color = "black", alpha.regions = 0, lwd = 1.2, layer.name = "Grid", map.types = clean_basemaps)
    }

    if (!is.null(houses)) {
      sf_h <- .d4h_prepare_houses_sf(houses, x, houses_filter_extent)
      m <- m + mapview::mapview(sf_h, col.regions = house_color, cex = house_size * 2, layer.name = "Houses", map.types = clean_basemaps)
    }

    return(m)
  }

  # Submodo 2B: Estatico para una sola capa (ggplot2)
  p <- ggplot2::ggplot()

  if (inherits(x, "SpatRaster")) {
    if (!requireNamespace("tidyterra", quietly = TRUE)) {
      stop("Package 'tidyterra' is required for static raster plotting with ggplot2.", call. = FALSE)
    }

    # Case A: True/False Color RGB
    if (!is.null(rgb_bands) && length(rgb_bands) >= 3) {
      p <- p + tidyterra::geom_spatraster_rgb(data = x, r = rgb_bands[1], g = rgb_bands[2], b = rgb_bands[3])
    } else {
      # Case B: Continuous Single-Band
      r_work <- x[[1]]
      var_name <- names(r_work)[1]
      r_work[is.nan(r_work) | is.infinite(r_work) | r_work == 0] <- NA

      p <- p + tidyterra::geom_spatraster(data = r_work)

      if (palette == "viridis") {
        p <- p + ggplot2::scale_fill_viridis_c(name = var_name, option = "viridis", na.value = "transparent", limits = limits)
      } else if (palette == "magma") {
        p <- p + ggplot2::scale_fill_viridis_c(name = var_name, option = "magma", na.value = "transparent", limits = limits)
      } else if (palette == "spectral") {
        p <- p + ggplot2::scale_fill_gradientn(
          name = var_name,
          colors = c("#9e0142", "#d53e4f", "#f46d43", "#fdae61", "#fee08b", "#ffffbf", "#e6f598", "#abdda4", "#66c2a5", "#3288bd", "#5e4fa2"),
          na.value = "transparent",
          limits = limits
        )
      } else if (palette == "terrain") {
        p <- p + ggplot2::scale_fill_gradientn(name = var_name, colors = grDevices::terrain.colors(10), na.value = "transparent", limits = limits)
      } else if (is.character(palette) && length(palette) > 1) {
        p <- p + ggplot2::scale_fill_gradientn(name = var_name, colors = palette, na.value = "transparent", limits = limits)
      } else {
        p <- p + ggplot2::scale_fill_viridis_c(name = var_name, option = "viridis", na.value = "transparent", limits = limits)
      }
    }

    # Overlay optional grid
    if (!is.null(grid)) {
      sf_grid <- if (inherits(grid, "SpatVector")) sf::st_as_sf(grid) else if (inherits(grid, "sf")) grid else sf::st_read(grid, quiet = TRUE)
      p <- p + ggplot2::geom_sf(data = sf_grid, fill = NA, color = "black", linewidth = 0.3)
    }

  } else if (inherits(x, "SpatVector") || inherits(x, "sf")) {
    sf_obj <- if (inherits(x, "SpatVector")) sf::st_as_sf(x) else x

    # Underlay high-resolution orthomosaic if provided
    has_ortho <- FALSE
    if (!is.null(ortho)) {
      r_ortho <- if (is.character(ortho)) terra::rast(ortho) else ortho
      if (requireNamespace("tidyterra", quietly = TRUE)) {
        if (terra::nlyr(r_ortho) >= 3) {
          p <- p + tidyterra::geom_spatraster_rgb(data = r_ortho, r = 1, g = 2, b = 3)
        } else {
          p <- p + tidyterra::geom_spatraster(data = r_ortho[[1]])
        }
        has_ortho <- TRUE
      }
    }

    fill_col <- if (!is.null(zcol)) {
      zcol
    } else if ("proximity_level" %in% names(sf_obj)) {
      "proximity_level"
    } else if ("risk_level" %in% names(sf_obj)) {
      "risk_level"
    } else if ("proximity_score" %in% names(sf_obj)) {
      "proximity_score"
    } else {
      num_cols <- names(sf_obj)[sapply(sf_obj, is.numeric)]
      setdiff(num_cols, c("id", "grid_id", "row", "col"))[1]
    }

    poly_alpha <- if (has_ortho) 0.55 else 0.85

    if (!is.null(fill_col) && !is.na(fill_col) && fill_col %in% names(sf_obj)) {
      if (fill_col %in% c("proximity_level", "risk_level")) {
        p <- p +
          ggplot2::geom_sf(data = sf_obj, ggplot2::aes(fill = .data[[fill_col]]), color = "black", linewidth = 0.25, alpha = poly_alpha) +
          ggplot2::scale_fill_manual(
            name = if (!is.null(title)) title else "Surveillance Priority\n(Proximity to Water)",
            values = c(
              "Critical (<50m)"     = "#D50000",
              "High (50-100m)"      = "#FF6D00",
              "Moderate (100-200m)" = "#FFD600",
              "Low (>200m)"         = "#00E676"
            ),
            drop = FALSE
          )
      } else if (is.numeric(sf_obj[[fill_col]])) {
        p <- p +
          ggplot2::geom_sf(data = sf_obj, ggplot2::aes(fill = .data[[fill_col]]), color = "grey35", linewidth = 0.25, alpha = poly_alpha) +
          ggplot2::scale_fill_viridis_c(name = if (!is.null(title)) title else fill_col, option = palette, na.value = "transparent", limits = limits)
      } else {
        p <- p +
          ggplot2::geom_sf(data = sf_obj, ggplot2::aes(fill = .data[[fill_col]]), color = "grey35", linewidth = 0.25, alpha = poly_alpha) +
          ggplot2::scale_fill_viridis_d(name = if (!is.null(title)) title else fill_col, option = palette)
      }
    } else {
      p <- p + ggplot2::geom_sf(data = sf_obj, fill = "lightblue", color = "grey30", linewidth = 0.25, alpha = poly_alpha)
    }

  } else if (is.data.frame(x)) {
    if (!"indicator" %in% names(x) || !"mean" %in% names(x)) {
      stop("Data frame summary must contain columns 'indicator' and 'mean'.", call. = FALSE)
    }
    has_quantiles <- all(c("q25", "q75") %in% names(x))

    p <- ggplot2::ggplot(x, ggplot2::aes(x = .data[["indicator"]], y = .data[["mean"]], fill = .data[["indicator"]])) +
      ggplot2::geom_col(width = 0.6, alpha = 0.85)

    if (has_quantiles) {
      p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = .data[["q25"]], ymax = .data[["q75"]]), width = 0.2, color = "black")
    }

    p <- p +
      ggplot2::scale_fill_viridis_d(option = "viridis") +
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

  # Overlay optional houses
  if (!is.null(houses)) {
    sf_houses <- .d4h_prepare_houses_sf(houses, x, houses_filter_extent)
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

# Helper interno para procesar coordenadas de casas
.d4h_prepare_houses_sf <- function(houses, ref_layer, filter_extent = FALSE) {
  sf_houses <- if (is.character(houses) && length(houses) == 1L) {
    if (grepl("\\.(xlsx|xls)$", houses, ignore.case = TRUE)) {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("Package 'readxl' is required to read Excel house coordinate files.", call. = FALSE)
      }
      df_h <- as.data.frame(readxl::read_excel(houses))
      lon_col <- grep("^(lon|lng|long|longitude|x)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("Excel file does not contain recognizable coordinate columns (lon/lat or x/y).", call. = FALSE)
      }
      is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else terra::crs(ref_layer)
      sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
    } else if (grepl("\\.csv$", houses, ignore.case = TRUE)) {
      df_h <- utils::read.csv(houses)
      lon_col <- grep("^(lon|lng|long|longitude|x)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      lat_col <- grep("^(lat|latitude|y)$", names(df_h), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(lon_col) || is.na(lat_col)) {
        stop("CSV file does not contain recognizable coordinate columns (lon/lat or x/y).", call. = FALSE)
      }
      is_ll <- all(abs(df_h[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(df_h[[lat_col]]) <= 90, na.rm = TRUE)
      init_crs <- if (is_ll) 4326 else terra::crs(ref_layer)
      sf::st_as_sf(df_h, coords = c(lon_col, lat_col), crs = init_crs)
    } else {
      terra::vect(houses)
    }
  } else if (is.data.frame(houses) && !inherits(houses, "sf")) {
    lon_col <- grep("^(lon|lng|long|longitude|x)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
    lat_col <- grep("^(lat|latitude|y)$", names(houses), ignore.case = TRUE, value = TRUE)[1]
    if (is.na(lon_col) || is.na(lat_col)) {
      stop("data.frame does not contain recognizable coordinate columns (lon/lat or x/y).", call. = FALSE)
    }
    is_ll <- all(abs(houses[[lon_col]]) <= 180, na.rm = TRUE) && all(abs(houses[[lat_col]]) <= 90, na.rm = TRUE)
    init_crs <- if (is_ll) 4326 else terra::crs(ref_layer)
    sf::st_as_sf(houses, coords = c(lon_col, lat_col), crs = init_crs)
  } else if (inherits(houses, "SpatVector")) {
    sf::st_as_sf(houses)
  } else if (inherits(houses, "sf")) {
    houses
  } else {
    stop("'houses' must be an sf, SpatVector, data.frame, or path to a CSV/Excel file.", call. = FALSE)
  }

  if (inherits(ref_layer, "SpatRaster") || inherits(ref_layer, "SpatVector")) {
    target_crs <- sf::st_crs(terra::crs(ref_layer))
    if (!is.na(target_crs) && sf::st_crs(sf_houses) != target_crs) {
      sf_houses <- sf::st_transform(sf_houses, target_crs)
    }
    if (isTRUE(filter_extent)) {
      ext_poly <- sf::st_as_sfc(sf::st_bbox(terra::ext(ref_layer), crs = target_crs))
      sf_houses <- sf::st_filter(sf_houses, ext_poly)
    }
  } else if (inherits(ref_layer, "sf")) {
    target_crs <- sf::st_crs(ref_layer)
    if (!is.na(target_crs) && sf::st_crs(sf_houses) != target_crs) {
      sf_houses <- sf::st_transform(sf_houses, target_crs)
    }
    if (isTRUE(filter_extent)) {
      ext_poly <- sf::st_as_sfc(sf::st_bbox(ref_layer))
      sf_houses <- sf::st_filter(sf_houses, ext_poly)
    }
  }

  sf_houses
}
