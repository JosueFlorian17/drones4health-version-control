#' @title Executive Summary of Micro-Environmental and Epidemiological Indicators
#' @description Generates a comprehensive executive report for a given raster layer or multi-band mosaic. It extracts key statistical moments, spatial extent and resolution metrics, Tukey outlier diagnostics, domain-specific bio-physical/epidemiological stratum interpretations, either globally (\code{by = "general"}) or per territorial grid cell (\code{by = "grid"}), and optionally exports a formatted multi-sheet Excel spreadsheet.
#' @details The executive summary computes descriptive moments (mean, standard deviation, coefficient of variation, median, interquartile range) and identifies spatial anomalies using Tukey's IQR outlier fences:
#' \deqn{\text{Lower Fence} = Q_{25} - 1.5 \times \text{IQR}}
#' \deqn{\text{Upper Fence} = Q_{75} + 1.5 \times \text{IQR}}
#' Surface strata are categorized by biophysical domain thresholds and translated into percentage and hectare metrics.
#' When \code{by = "grid"}, each row represents an operational surveillance grid cell with full descriptive moments, Tukey outlier rates, and stratum area percentages.
#' @param raster_in SpatRaster, list of SpatRaster layers, or character file path.
#' @param by Character. Summary aggregation scope: \code{"general"} (default, overall scene report) or \code{"grid"} (zonal summary per grid cell, with one row per cell).
#' @param grid Optional SpatVector, sf, or character path to existing grid polygon boundaries when \code{by = "grid"}. If NULL, automatically generated using \code{cell_size} and \code{square}.
#' @param water SpatVector, sf, or SpatRaster (optional). Segmented water bodies or binary water mask to compute grid water coverage (\code{pct_water}).
#' @param buildings SpatVector, sf, or SpatRaster (optional). Segmented building/roof footprints to compute grid dwelling coverage (\code{pct_houses}).
#' @param houses Deprecated alias for \code{buildings}.
#' @param houses_proximity Optional \code{sf} or \code{data.frame} of residential dwellings with calculated distance to water and proximity scores (e.g. from \code{d4h_distance_to_water} or buffer analysis). If provided, appends dedicated household distance and proximity exposure sheets to the Excel workbook.
#' @param houses_risk Deprecated alias for \code{houses_proximity}.
#' @param cell_size Numeric. Grid cell size / diameter in meters when generating a new grid for \code{by = "grid"} (default: 50).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param out_xlsx Character (optional). File path to export a structured multi-sheet Excel workbook (.xlsx). Default: NULL.
#' @param sample_size Integer. Maximum number of sampled pixels for quantile and outlier analysis on large rasters (default: 1000000).
#' @param digits Integer. Number of decimal places to format numerical metrics (default: 3).
#' @return When \code{by = "grid"}, returns an object of class \code{d4h_grid_summary} containing both \code{$sf} (spatial polygons with geometry) and \code{$df} (clean tabular pure data.frame without geometry), including micro-environmental composition (\code{pct_bare_soil}, \code{pct_houses}, \code{pct_water}, \code{pct_vegetation}, \code{dominant_class}, \code{surveillance_priority}) and descriptive moments. When \code{by = "general"}, returns an object of class \code{d4h_executive_summary} (pure \code{data.frame}).
#' @references
#' Tukey, J. W. (1977). \emph{Exploratory Data Analysis}. Addison-Wesley.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   # Load raster indicator
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'
#'   # 1. Generate general executive report with outlier diagnostics
#'   exec_rep <- d4h_executive_summary(
#'     raster_in   = ndvi_file,
#'     by          = "general",
#'     out_xlsx    = tempfile(fileext = ".xlsx"),
#'     sample_size = 1000000,
#'     digits      = 3
#'   )
#'   print(exec_rep)
#'
#'   # 2. Generate zonal grid executive summary per hexagonal cell
#'   exec_grid <- d4h_executive_summary(
#'     raster_in   = ndvi_file,
#'     by          = "grid",
#'     cell_size   = 50,
#'     square      = FALSE,
#'     out_xlsx    = tempfile(fileext = ".xlsx"),
#'     sample_size = 1000000,
#'     digits      = 3
#'   )
#'   # Always provides both $sf and $df:
#'   head(exec_grid$df)
#'   plot(exec_grid$sf)
#' }
#' }
#' @export
d4h_executive_summary <- function(raster_in, by = c("general", "grid"), grid = NULL,
                                  water = NULL, buildings = NULL, houses = NULL, features = NULL,
                                  houses_proximity = NULL, houses_risk = NULL,
                                  cell_size = 50, square = TRUE, out_xlsx = NULL,
                                  sample_size = 1000000, digits = 3) {
  # Auto-infer 'by' if grid is provided
  if (!is.null(grid) && missing(by)) {
    by <- "grid"
  } else if (missing(by)) {
    by <- "general"
  } else {
    by <- match.arg(by)
  }

  if (is.null(buildings) && !is.null(houses)) {
    buildings <- houses
  }

  # Unpack combined features if provided (e.g. from d4h_combine_features)
  if (!is.null(features)) {
    if (inherits(features, "sf") && "feature_type" %in% names(features)) {
      if (is.null(water)) {
        w_sub <- features[features$feature_type == "Water", ]
        if (nrow(w_sub) > 0) water <- w_sub
      }
      if (is.null(buildings)) {
        b_sub <- features[features$feature_type == "Building", ]
        if (nrow(b_sub) > 0) buildings <- b_sub
      }
    }
  }
  if (is.null(houses_proximity) && !is.null(houses_risk)) {
    houses_proximity <- houses_risk
  }

  raster_layers <- if (is.character(raster_in)) {
    lapply(raster_in, function(p) {
      if (!file.exists(p)) stop(paste("File not found:", p), call. = FALSE)
      terra::rast(p)
    })
  } else if (inherits(raster_in, "SpatRaster")) {
    lapply(seq_len(terra::nlyr(raster_in)), function(i) raster_in[[i]])
  } else if (is.list(raster_in)) {
    unlist(lapply(raster_in, function(item) {
      if (inherits(item, "SpatRaster")) {
        lapply(seq_len(terra::nlyr(item)), function(j) item[[j]])
      } else if (is.character(item) && file.exists(item)) {
        r_temp <- terra::rast(item)
        lapply(seq_len(terra::nlyr(r_temp)), function(j) r_temp[[j]])
      } else {
        stop("Invalid element in 'raster_in' list.", call. = FALSE)
      }
    }), recursive = FALSE)
  } else {
    stop("'raster_in' must be a SpatRaster, a list of SpatRasters, or valid file paths.", call. = FALSE)
  }

  n_layers <- length(raster_layers)
  layer_names <- vapply(seq_len(n_layers), function(i) {
    nm <- names(raster_layers[[i]])[1]
    if (is.null(nm) || is.na(nm) || nm == "") paste0("layer_", i) else nm
  }, character(1))

  # ============================================================================
  # MODO B: RESUMEN POR GRILLA (UNA FILA POR CELDA)
  # ============================================================================
  if (by == "grid") {
    # 1. Resolver o generar la grilla vectorial como sf
    grid_sf <- if (!is.null(grid)) {
      if (is.character(grid) && length(grid) == 1L) {
        if (!file.exists(grid)) stop(paste("Grid file not found:", grid), call. = FALSE)
        sf::st_read(grid, quiet = TRUE)
      } else if (inherits(grid, "SpatVector")) {
        sf::st_as_sf(grid)
      } else if (inherits(grid, "sf")) {
        grid
      } else {
        stop("'grid' must be an sf, SpatVector, or valid file path.", call. = FALSE)
      }
    } else {
      # Usar grilla operativa podada a los datos validos (sf)
      d4h_make_grid(raster_layers[[1]], cell_size = cell_size, square = square, clip_to_footprint = TRUE, as_sf = TRUE)
    }

    # Asignar ID si la grilla no lo tiene
    if (!"grid_id" %in% names(grid_sf)) {
      grid_sf$grid_id <- sprintf("G%04d", seq_len(nrow(grid_sf)))
    }

    grid_vect <- terra::vect(grid_sf)



    # Extraer valores por capa independientemente (con O(1) slice index y auto-resolucion optima)
    extracted_by_layer <- lapply(seq_len(n_layers), function(lyr_idx) {
      lyr <- raster_layers[[lyr_idx]]
      ext_g <- terra::ext(grid_vect)
      ext_r <- terra::ext(lyr)
      if (ext_g$xmin > ext_r$xmin || ext_g$xmax < ext_r$xmax || ext_g$ymin > ext_r$ymin || ext_g$ymax < ext_r$ymax) {
        lyr <- suppressWarnings(terra::crop(lyr, grid_vect))
      }
      rx <- terra::xres(lyr)
      if (rx < 0.20 && cell_size >= 20) {
        fact <- max(1L, as.integer(round(0.50 / rx)))
        if (fact > 1L) lyr <- terra::aggregate(lyr, fact = fact, fun = "mean", na.rm = TRUE)
      }
      vals_ext <- terra::extract(lyr, grid_vect)
      if (nrow(vals_ext) == 0L) {
        return(list(map = integer(0), starts = integer(0), ends = integer(0), vals = numeric(0)))
      }
      rl <- rle(vals_ext[[1]])
      ends <- cumsum(rl$lengths)
      starts <- c(1L, ends[-length(ends)] + 1L)
      map_ids <- match(seq_len(nrow(grid_vect)), rl$values)
      list(
        map = map_ids,
        starts = starts,
        ends = ends,
        vals = vals_ext[[2]]
      )
    })

    # Calcular metricas por celda
    grid_rows <- vector("list", nrow(grid_vect))
    grid_ids <- grid_vect$grid_id

    for (k in seq_len(nrow(grid_vect))) {
      cell_data <- data.frame(
        grid_id = grid_ids[k],
        stringsAsFactors = FALSE
      )

      # Si hay geometria, extraer centroides X/Y
      pts_c <- suppressWarnings(terra::crds(terra::centroids(grid_vect[k, ])))
      if (nrow(pts_c) > 0) {
        cell_data$centroid_x <- round(pts_c[1, 1], 2)
        cell_data$centroid_y <- round(pts_c[1, 2], 2)
      }

      # Procesar cada capa
      has_valid_data <- FALSE
      for (lyr_idx in seq_len(n_layers)) {
        v_name <- layer_names[lyr_idx]
        lyr_pack <- extracted_by_layer[[lyr_idx]]
        m_pos <- lyr_pack$map[k]
        raw_vals <- if (!is.na(m_pos)) lyr_pack$vals[lyr_pack$starts[m_pos]:lyr_pack$ends[m_pos]] else numeric(0)
        v_clean <- raw_vals[!is.na(raw_vals) & is.finite(raw_vals) & raw_vals != 0]

        n_v <- length(v_clean)
        cell_data[[paste0(v_name, "_pixeles")]] <- n_v

        if (n_v > 0) {
          has_valid_data <- TRUE
          m_val  <- mean(v_clean)
          sd_val <- stats::sd(v_clean)
          if (is.na(sd_val)) sd_val <- 0
          cv_val <- if (m_val != 0) (sd_val / abs(m_val)) * 100 else NA_real_

          q_c <- stats::quantile(v_clean, probs = c(0.25, 0.50, 0.75), na.rm = TRUE)
          q25 <- unname(q_c["25%"])
          med <- unname(q_c["50%"])
          q75 <- unname(q_c["75%"])
          iqr <- q75 - q25

          # Outliers Tukey
          l_fence <- q25 - (1.5 * iqr)
          u_fence <- q75 + (1.5 * iqr)
          out_tot <- sum(v_clean < l_fence | v_clean > u_fence)
          out_pct <- (out_tot / n_v) * 100

          cell_data[[paste0(v_name, "_mean")]]         <- round(m_val, digits)
          cell_data[[paste0(v_name, "_sd")]]           <- round(sd_val, digits)
          cell_data[[paste0(v_name, "_cv_pct")]]       <- round(cv_val, 1)
          cell_data[[paste0(v_name, "_min")]]          <- round(min(v_clean), digits)
          cell_data[[paste0(v_name, "_max")]]          <- round(max(v_clean), digits)
          cell_data[[paste0(v_name, "_median")]]       <- round(med, digits)
          cell_data[[paste0(v_name, "_iqr")]]          <- round(iqr, digits)
          cell_data[[paste0(v_name, "_outliers_pct")]] <- round(out_pct, 1)

          # Backward compatibility aliases
          cell_data[[paste0(v_name, "_media")]]        <- round(m_val, digits)
          cell_data[[paste0(v_name, "_mediana")]]      <- round(med, digits)

          # Simplified key stratification
          v_up <- toupper(v_name)
          if (grepl("NDVI|SAVI|GNDVI", v_up)) {
            cell_data[[paste0(v_name, "_pct_water_substrate")]] <- round(mean(v_clean < 0) * 100, 1)
            cell_data[[paste0(v_name, "_pct_bare_soil")]]       <- round(mean(v_clean >= 0 & v_clean < 0.2) * 100, 1)
            cell_data[[paste0(v_name, "_pct_dense_vegetation")]] <- round(mean(v_clean >= 0.5) * 100, 1)
            # Aliases
            cell_data[[paste0(v_name, "_pct_agua_degradado")]]  <- cell_data[[paste0(v_name, "_pct_water_substrate")]]
            cell_data[[paste0(v_name, "_pct_suelo_desnudo")]]    <- cell_data[[paste0(v_name, "_pct_bare_soil")]]
            cell_data[[paste0(v_name, "_pct_vegetacion_densa")]] <- cell_data[[paste0(v_name, "_pct_dense_vegetation")]]
          } else if (grepl("NDWI|IRHE", v_up)) {
            cell_data[[paste0(v_name, "_pct_water_saturated")]] <- round(mean(v_clean > 0) * 100, 1)
          } else if (grepl("IMSR", v_up)) {
            cell_data[[paste0(v_name, "_pct_high_debris_exposure")]] <- round(mean(v_clean >= 0.35) * 100, 1)
          } else if (grepl("TWI|IEV", v_up)) {
            cell_data[[paste0(v_name, "_pct_stagnation_zone")]] <- round(mean(v_clean > 8) * 100, 1)
          }
        } else {
          cell_data[[paste0(v_name, "_mean")]]         <- NA_real_
          cell_data[[paste0(v_name, "_sd")]]           <- NA_real_
          cell_data[[paste0(v_name, "_cv_pct")]]       <- NA_real_
          cell_data[[paste0(v_name, "_min")]]          <- NA_real_
          cell_data[[paste0(v_name, "_max")]]          <- NA_real_
          cell_data[[paste0(v_name, "_median")]]       <- NA_real_
          cell_data[[paste0(v_name, "_iqr")]]          <- NA_real_
          cell_data[[paste0(v_name, "_outliers_pct")]] <- NA_real_
          cell_data[[paste0(v_name, "_media")]]        <- NA_real_
          cell_data[[paste0(v_name, "_mediana")]]      <- NA_real_
        }
      }

      if (has_valid_data) {
        grid_rows[[k]] <- cell_data
      }
    }

    df_grid_stats <- do.call(rbind, grid_rows[!vapply(grid_rows, is.null, logical(1))])
    rownames(df_grid_stats) <- NULL

    # 2. Compute micro-environmental land cover composition (bare soil, houses, water, vegetation)
    idx_ndvi <- grep("NDVI|SAVI|GNDVI", toupper(layer_names))
    r_ndvi_cand <- if (length(idx_ndvi) > 0) raster_layers[[idx_ndvi[1]]] else NULL

    water_cand <- water
    if (is.null(water_cand)) {
      idx_ndwi <- grep("NDWI|IRHE", toupper(layer_names))
      if (length(idx_ndwi) > 0) {
        water_cand <- raster_layers[[idx_ndwi[1]]] > 0
      }
    }

    comp_sf <- d4h_grid_composition(
      grid        = grid_sf,
      water       = water_cand,
      buildings   = buildings,
      ndvi_raster = r_ndvi_cand
    )

    # Merge composition and indicator zonal statistics (avoiding duplicate area_m2)
    stat_cols_to_merge <- names(df_grid_stats)[!names(df_grid_stats) %in% c("area_m2")]
    df_grid_merged <- merge(comp_sf, df_grid_stats[, stat_cols_to_merge, drop = FALSE], by = "grid_id", all.x = TRUE)

    # Build both spatial (sf) and tabular (df) representations
    res_sf <- df_grid_merged
    res_df <- as.data.frame(sf::st_drop_geometry(df_grid_merged), stringsAsFactors = FALSE)

    # Compound result containing BOTH $sf and $df
    res_grid <- list(
      sf = res_sf,
      df = res_df
    )
    class(res_grid) <- c("d4h_grid_summary", "list")

    # Export to Excel if requested
    if (!is.null(out_xlsx)) {
      dir_out <- dirname(out_xlsx)
      if (!dir.exists(dir_out) && dir_out != "" && dir_out != ".") {
        dir.create(dir_out, recursive = TRUE)
      }

      df_clean_export <- as.data.frame(res_df)
      num_cols <- names(df_clean_export)[vapply(df_clean_export, is.numeric, logical(1))]
      num_cols <- num_cols[!num_cols %in% c("centroid_x", "centroid_y") & !grepl("_media$|_mediana$|_pct_agua_degradado$|_pct_suelo_desnudo$|_pct_vegetacion_densa$", num_cols)]
      res_glob <- lapply(num_cols, function(col_n) {
        vals <- df_clean_export[[col_n]]
        vals <- vals[!is.na(vals) & is.finite(vals)]
        if (length(vals) == 0) return(NULL)
        data.frame(
          Variable  = col_n,
          Mean      = round(mean(vals), 3),
          Std_Dev   = round(stats::sd(vals), 3),
          Min       = round(min(vals), 3),
          Median    = round(stats::median(vals), 3),
          Max       = round(max(vals), 3),
          stringsAsFactors = FALSE
        )
      })
      df_glob_grid <- do.call(rbind, res_glob[!vapply(res_glob, is.null, logical(1))])

      sheets_grid <- list(
        Grid_Summary = df_clean_export,
        Global_Grid_Summary = df_glob_grid
      )

      # Append household water proximity sheets if provided
      h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
      if (!is.null(h_target)) {
        h_list <- .build_houses_proximity_sheets(h_target)
        if (!is.null(h_list)) {
          sheets_grid[["Household_Water_Proximity"]]   <- h_list$Household_Water_Proximity
          sheets_grid[["Household_Proximity_Summary"]] <- h_list$Household_Proximity_Summary
        }
      }

      if (requireNamespace("writexl", quietly = TRUE)) {
        writexl::write_xlsx(sheets_grid, path = out_xlsx)
      } else if (requireNamespace("openxlsx", quietly = TRUE)) {
        openxlsx::write.xlsx(sheets_grid, file = out_xlsx)
      } else {
        csv_fallback <- sub("\\.xlsx$", ".csv", out_xlsx)
        utils::write.csv(df_clean_export, file = csv_fallback, row.names = FALSE)
      }
    }

    h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
    if (!is.null(h_target)) {
      attr(res_grid, "houses_proximity") <- h_target
      attr(res_grid$sf, "houses_proximity") <- h_target
      attr(res_grid$df, "houses_proximity") <- h_target
    }

    return(res_grid)
  }

  # ============================================================================
  # MODO A: RESUMEN GENERAL (INFORME ESCENARIO GLOBAL)
  # ============================================================================
  summaries <- lapply(seq_len(n_layers), function(i) {
    lyr <- raster_layers[[i]]
    var_name <- layer_names[i]

    # Ingest spatial and raster metadata internally
    meta <- .d4h_raster_metadata(lyr, quiet = TRUE)

    # 1. Metricas espaciales y resolucion
    res_xy <- c(meta$res_x, meta$res_y)
    is_projected <- meta$is_projected
    total_cells <- meta$total_pixels

    # Extraer pixeles validos
    is_sampled <- total_cells > sample_size
    raw_sample <- if (is_sampled) {
      terra::spatSample(lyr, size = sample_size, method = "regular", na.rm = FALSE)[, 1]
    } else {
      terra::values(lyr, mat = FALSE)
    }
    vals <- raw_sample[!is.na(raw_sample) & is.finite(raw_sample) & raw_sample != 0]

    n_valid <- length(vals)
    n_sample_total <- length(raw_sample)
    if (n_valid == 0L) {
      return(list(
        indicator = var_name,
        error = "No valid non-zero data points found in layer."
      ))
    }

    valid_fraction <- if (n_sample_total > 0) n_valid / n_sample_total else 0
    total_valid_est <- if (is_sampled) round(valid_fraction * total_cells) else n_valid

    # Calculo de area de pixel y huella espacial
    pixel_area_m2 <- if (is_projected) res_xy[1] * res_xy[2] else (res_xy[1] * 111320) * (res_xy[2] * 110540)
    area_m2 <- total_valid_est * pixel_area_m2
    area_ha <- area_m2 / 10000

    # Metadatos del recuadro de la escena (matching metadatos.py)
    ancho_m <- meta$width_m
    alto_m  <- meta$height_m
    bbox_area_m2 <- meta$area_m2
    bbox_area_ha <- meta$area_ha

    # 2. Estadisticas descriptivas y momentos
    mean_val <- mean(vals)
    sd_val   <- stats::sd(vals)
    cv_val   <- if (mean_val != 0) (sd_val / abs(mean_val)) * 100 else NA_real_
    min_val  <- min(vals)
    max_val  <- max(vals)
    range_val <- max_val - min_val

    q <- stats::quantile(vals, probs = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95), na.rm = TRUE, names = TRUE)
    median_val <- unname(q["50%"])
    q25 <- unname(q["25%"])
    q75 <- unname(q["75%"])
    iqr_val <- q75 - q25

    # 3. Diagnostico de Valores Atipicos (Outliers segun Tukey IQR)
    lower_fence <- q25 - (1.5 * iqr_val)
    upper_fence <- q75 + (1.5 * iqr_val)

    outliers_low <- sum(vals < lower_fence)
    outliers_high <- sum(vals > upper_fence)
    outliers_total <- outliers_low + outliers_high
    outliers_pct <- (outliers_total / n_valid) * 100

    outlier_status <- if (outliers_pct < 1) {
      "Homogeneous distribution (extreme values < 1%)"
    } else if (outliers_pct < 5) {
      "Moderate dispersion (localized spatial anomalies)"
    } else {
      "High dispersion / significant anomaly presence or boundary effects"
    }

    # 4. Estratificacion tematica contextualizada por tipo de indice
    var_upper <- toupper(var_name)
    strata <- list()

    if (grepl("NDVI|SAVI|GNDVI|NDRE|EVI|DVI", var_upper)) {
      strata[["Water / Substrate degradation (< 0.0)"]] <- list(pct = mean(vals < 0) * 100, ha = (mean(vals < 0) * area_ha))
      strata[["Bare soil / Sparse canopy [0.0, 0.2)"]] <- list(pct = mean(vals >= 0 & vals < 0.2) * 100, ha = (mean(vals >= 0 & vals < 0.2) * area_ha))
      strata[["Moderate vegetation / Transition [0.2, 0.5)"]] <- list(pct = mean(vals >= 0.2 & vals < 0.5) * 100, ha = (mean(vals >= 0.2 & vals < 0.5) * area_ha))
      strata[["Dense vegetation / High vigor [>= 0.5)"]] <- list(pct = mean(vals >= 0.5) * 100, ha = (mean(vals >= 0.5) * area_ha))
    } else if (grepl("NDWI|IRHE", var_upper)) {
      strata[["Water bodies / Saturated soil (> 0.0)"]] <- list(pct = mean(vals > 0) * 100, ha = (mean(vals > 0) * area_ha))
      strata[["Unsaturated terrestrial surface (<= 0.0)"]] <- list(pct = mean(vals <= 0) * 100, ha = (mean(vals <= 0) * area_ha))
    } else if (grepl("IMSR", var_upper)) {
      strata[["Natural environment / Baseline (< 0.15)"]] <- list(pct = mean(vals < 0.15) * 100, ha = (mean(vals < 0.15) * area_ha))
      strata[["Moderate accumulation / Dispersed debris [0.15, 0.35)"]] <- list(pct = mean(vals >= 0.15 & vals < 0.35) * 100, ha = (mean(vals >= 0.15 & vals < 0.35) * area_ha))
      strata[["High priority / Containers & plastics (>= 0.35)"]] <- list(pct = mean(vals >= 0.35) * 100, ha = (mean(vals >= 0.35) * area_ha))
    } else if (grepl("SLOPE|PENDIENTE", var_upper)) {
      strata[["Flat terrain / Micro-depressions (< 5 deg)"]] <- list(pct = mean(vals < 5) * 100, ha = (mean(vals < 5) * area_ha))
      strata[["Moderate slope [5, 15 deg]"]] <- list(pct = mean(vals >= 5 & vals <= 15) * 100, ha = (mean(vals >= 5 & vals <= 15) * area_ha))
      strata[["Steep terrain (> 15 deg)"]] <- list(pct = mean(vals > 15) * 100, ha = (mean(vals > 15) * area_ha))
    } else if (grepl("TWI|IEV", var_upper)) {
      strata[["Low accumulation potential (< 4.0)"]] <- list(pct = mean(vals < 4) * 100, ha = (mean(vals < 4) * area_ha))
      strata[["Moderate accumulation potential [4.0, 8.0]"]] <- list(pct = mean(vals >= 4 & vals <= 8) * 100, ha = (mean(vals >= 4 & vals <= 8) * area_ha))
      strata[["Critical stagnation zone (> 8.0)"]] <- list(pct = mean(vals > 8) * 100, ha = (mean(vals > 8) * area_ha))
    } else {
      strata[["Low [Min, Q25)"]] <- list(pct = mean(vals < q25) * 100, ha = (mean(vals < q25) * area_ha))
      strata[["Medium-Low [Q25, Median)"]] <- list(pct = mean(vals >= q25 & vals < median_val) * 100, ha = (mean(vals >= q25 & vals < median_val) * area_ha))
      strata[["Medium-High [Median, Q75)"]] <- list(pct = mean(vals >= median_val & vals < q75) * 100, ha = (mean(vals >= median_val & vals < q75) * area_ha))
      strata[["High [Q75, Max]"]] <- list(pct = mean(vals >= q75) * 100, ha = (mean(vals >= q75) * area_ha))
    }

    list(
      indicator = var_name,
      metadata  = meta,
      spatial = list(
        res_x = meta$gsd_cm,
        res_unit = "cm",
        pixel_size_desc = meta$pixel_size_desc,
        crs = meta$crs,
        crs_epsg = meta$epsg,
        width_px = meta$width,
        height_px = meta$height,
        total_pixels = meta$total_pixels,
        dtype = meta$dtype,
        nodata = meta$nodata,
        n_valid = total_valid_est,
        n_sampled = if (is_sampled) n_valid else total_cells,
        is_sampled = is_sampled,
        coverage_pct = round(valid_fraction * 100, 1),
        area_ha = round(area_ha, 3),
        area_m2 = round(area_m2, 1),
        bbox_area_ha = round(bbox_area_ha, 3),
        bbox_area_m2 = round(bbox_area_m2, 1),
        field_width_m = round(ancho_m, 1),
        field_height_m = round(alto_m, 1)
      ),
      stats = list(
        mean = round(mean_val, digits),
        sd = round(sd_val, digits),
        cv_pct = round(cv_val, 1),
        min = round(min_val, digits),
        max = round(max_val, digits),
        range = round(range_val, digits),
        median = round(median_val, digits),
        iqr = round(iqr_val, digits),
        q25 = round(q25, digits),
        q75 = round(q75, digits),
        p05 = round(unname(q["5%"]), digits),
        p95 = round(unname(q["95%"]), digits)
      ),
      outliers = list(
        lower_fence = round(lower_fence, digits),
        upper_fence = round(upper_fence, digits),
        count_low = outliers_low,
        count_high = outliers_high,
        count_total = outliers_total,
        pct = round(outliers_pct, 2),
        diagnosis = outlier_status
      ),
      strata = strata
    )
  })

  names(summaries) <- layer_names

  # Construct clean pure data.frame for executive summary
  valid_items <- summaries[!vapply(summaries, function(x) !is.null(x$error), logical(1))]

  df_general <- if (length(valid_items) > 0) {
    data.frame(
      indicator         = vapply(valid_items, function(x) x$indicator, character(1)),
      resolution        = vapply(valid_items, function(x) if (!is.null(x$spatial$pixel_size_desc)) x$spatial$pixel_size_desc else paste(x$spatial$res_x, x$spatial$res_unit), character(1)),
      scene_dimensions  = vapply(valid_items, function(x) if (!is.null(x$spatial$width_px)) paste0(format(x$spatial$width_px, big.mark = ","), " x ", format(x$spatial$height_px, big.mark = ","), " px") else NA_character_, character(1)),
      scene_bbox_ha     = vapply(valid_items, function(x) if (!is.null(x$spatial$bbox_area_ha)) x$spatial$bbox_area_ha else NA_real_, numeric(1)),
      crs_epsg          = vapply(valid_items, function(x) if (!is.null(x$spatial$crs_epsg) && !is.na(x$spatial$crs_epsg)) paste0("EPSG:", x$spatial$crs_epsg) else "N/A", character(1)),
      area_ha           = vapply(valid_items, function(x) x$spatial$area_ha, numeric(1)),
      valid_pixels      = vapply(valid_items, function(x) x$spatial$n_valid, numeric(1)),
      coverage_pct      = vapply(valid_items, function(x) x$spatial$coverage_pct, numeric(1)),
      mean              = vapply(valid_items, function(x) x$stats$mean, numeric(1)),
      sd                = vapply(valid_items, function(x) x$stats$sd, numeric(1)),
      cv_pct            = vapply(valid_items, function(x) x$stats$cv_pct, numeric(1)),
      min               = vapply(valid_items, function(x) x$stats$min, numeric(1)),
      max               = vapply(valid_items, function(x) x$stats$max, numeric(1)),
      q25               = vapply(valid_items, function(x) x$stats$q25, numeric(1)),
      median            = vapply(valid_items, function(x) x$stats$median, numeric(1)),
      q75               = vapply(valid_items, function(x) x$stats$q75, numeric(1)),
      iqr               = vapply(valid_items, function(x) x$stats$iqr, numeric(1)),
      outliers_count    = vapply(valid_items, function(x) x$outliers$count_total, numeric(1)),
      outliers_pct      = vapply(valid_items, function(x) x$outliers$pct, numeric(1)),
      outlier_diagnosis = vapply(valid_items, function(x) x$outliers$diagnosis, character(1)),
      stringsAsFactors  = FALSE
    )
  } else {
    data.frame(indicator = layer_names, stringsAsFactors = FALSE)
  }

  df_general <- as.data.frame(df_general, stringsAsFactors = FALSE)

  # Build strata dataframe
  strata_rows <- list()
  for (item in summaries) {
    if (!is.null(item$error)) next
    for (st_name in names(item$strata)) {
      st_val <- item$strata[[st_name]]
      strata_rows[[length(strata_rows) + 1L]] <- data.frame(
        Indicator = item$indicator,
        Stratum = st_name,
        Percentage = round(st_val$pct, 2),
        Surface_ha = round(st_val$ha, 4),
        stringsAsFactors = FALSE
      )
    }
  }
  df_strata <- if (length(strata_rows) > 0) do.call(rbind, strata_rows) else data.frame()

  attr(df_general, "raw_summary") <- summaries
  attr(df_general, "strata")      <- df_strata
  attr(df_general, "spatial")     <- lapply(summaries, `[[`, "spatial")
  attr(df_general, "outliers")    <- lapply(summaries, `[[`, "outliers")
  if (length(valid_items) > 0) {
    attr(df_general, "metadata")  <- do.call(rbind, lapply(valid_items, function(x) as.data.frame(x$metadata)))
  }

  h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
  if (!is.null(h_target)) {
    attr(df_general, "houses_proximity") <- h_target
  }

  class(df_general) <- c("d4h_executive_summary", class(df_general))

  # Export to Excel if requested
  if (!is.null(out_xlsx)) {
    d4h_export_summary(df_general, out_xlsx = out_xlsx, houses_proximity = h_target)
  }

  df_general
}

# Internal helper to construct household water proximity sheets
.build_houses_proximity_sheets <- function(houses_data) {
  if (is.null(houses_data)) return(NULL)

  # Extract coordinates if sf or SpatVector
  h_sf <- if (inherits(houses_data, "sf")) {
    houses_data
  } else if (inherits(houses_data, "SpatVector")) {
    sf::st_as_sf(houses_data)
  } else if (is.data.frame(houses_data)) {
    houses_data
  } else {
    NULL
  }

  if (is.null(h_sf) || nrow(h_sf) == 0L) return(NULL)

  df_raw <- if (inherits(h_sf, "sf")) {
    coords <- sf::st_coordinates(h_sf)
    df_tmp <- sf::st_drop_geometry(h_sf)
    df_tmp$coord_x <- round(coords[, 1], 2)
    df_tmp$coord_y <- round(coords[, 2], 2)
    df_tmp
  } else {
    as.data.frame(h_sf)
  }

  # 1. House ID
  id_col <- grep("^(house_id|id|casa_id|vivienda_id|codigo)$", names(df_raw), ignore.case = TRUE, value = TRUE)[1]
  house_id <- if (!is.na(id_col)) as.character(df_raw[[id_col]]) else sprintf("H%03d", seq_len(nrow(df_raw)))

  # 2. Distance to water
  dist_col <- grep("^(dist_water_m|dist_water|dist_agua_m|distance|dist_m|dist)$", names(df_raw), ignore.case = TRUE, value = TRUE)[1]
  dist_val <- if (!is.na(dist_col)) as.numeric(df_raw[[dist_col]]) else rep(NA_real_, nrow(df_raw))

  # 3. Nearest water body ID
  near_col <- grep("^(nearest_water_id|near_water_id|cuerpo_agua_cercano)$", names(df_raw), ignore.case = TRUE, value = TRUE)[1]
  near_id <- if (!is.na(near_col)) as.character(df_raw[[near_col]]) else sprintf("W%03d", seq_len(nrow(df_raw)))

  # 4. Proximity score (decay exposure)
  score_col <- grep("^(proximity_score|risk_score|score)$", names(df_raw), ignore.case = TRUE, value = TRUE)[1]
  prox_score <- if (!is.na(score_col)) {
    round(as.numeric(df_raw[[score_col]]), 3)
  } else if (any(!is.na(dist_val))) {
    round(exp(-dist_val / 100.0), 3)
  } else {
    rep(NA_real_, nrow(df_raw))
  }

  # 5. Proximity tier (objective distance strata)
  tier_col <- grep("^(proximity_tier|proximity_level|risk_level|tier)$", names(df_raw), ignore.case = TRUE, value = TRUE)[1]
  prox_tier <- if (!is.na(tier_col)) {
    as.character(df_raw[[tier_col]])
  } else if (any(!is.na(dist_val))) {
    as.character(cut(
      dist_val,
      breaks = c(-Inf, 50, 100, 200, Inf),
      labels = c("Immediate Proximity (<50m)", "High Proximity (50-100m)", "Moderate Proximity (100-200m)", "Distal (>200m)"),
      right = TRUE
    ))
  } else {
    rep("Unclassified", nrow(df_raw))
  }

  # Coordinates X/Y
  cx <- if ("coord_x" %in% names(df_raw)) df_raw$coord_x else if ("lon" %in% names(df_raw)) df_raw$lon else NA_real_
  cy <- if ("coord_y" %in% names(df_raw)) df_raw$coord_y else if ("lat" %in% names(df_raw)) df_raw$lat else NA_real_

  df_casas_export <- data.frame(
    house_id           = house_id,
    coord_x            = cx,
    coord_y            = cy,
    dist_water_m       = round(dist_val, 1),
    nearest_water_id   = near_id,
    proximity_score    = prox_score,
    proximity_tier     = prox_tier,
    stringsAsFactors   = FALSE
  )

  # Aggregated proximity stratification
  df_agg_cnt <- stats::aggregate(house_id ~ proximity_tier, data = df_casas_export, FUN = length)
  names(df_agg_cnt)[2] <- "n_houses"
  df_agg_dist <- stats::aggregate(dist_water_m ~ proximity_tier, data = df_casas_export, FUN = function(v) {
    c(mean = round(mean(v, na.rm = TRUE), 1),
      min  = round(min(v, na.rm = TRUE), 1),
      max  = round(max(v, na.rm = TRUE), 1))
  })
  dist_mat <- df_agg_dist$dist_water_m

  df_strat <- data.frame(
    Proximity_Tier    = df_agg_cnt$proximity_tier,
    Household_Count   = df_agg_cnt$n_houses,
    Household_Pct     = round((df_agg_cnt$n_houses / nrow(df_casas_export)) * 100, 1),
    Mean_Distance_m   = dist_mat[, "mean"],
    Min_Distance_m    = dist_mat[, "min"],
    Max_Distance_m    = dist_mat[, "max"],
    stringsAsFactors  = FALSE
  )

  list(
    Household_Water_Proximity   = df_casas_export,
    Household_Proximity_Summary = df_strat
  )
}

#' @title Export Executive Summary to Multi-Sheet Excel File
#' @description Exports a \code{d4h_executive_summary} object to an Excel workbook (.xlsx) with dedicated sheets for Global Summary, Stratification, Outlier Diagnostics, and optional Household Water Proximity.
#' @param x An object of class \code{d4h_executive_summary}.
#' @param out_xlsx Character. Path where the .xlsx file will be created.
#' @param houses_proximity Optional \code{sf} or \code{data.frame} of residential dwellings with distance to water and proximity attributes.
#' @param houses_risk Deprecated alias for \code{houses_proximity}.
#' @return Invisibly returns the input object \code{x}.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'   library(terra)
#'
#'   ndvi_file <- system.file("extdata", "ndvi.tif", package = "drones4health")
#'   exec_rep  <- d4h_executive_summary(ndvi_file, by = "general")
#'
#'   # Export executive summary object to Excel workbook
#'   out_file <- tempfile(fileext = ".xlsx")
#'   d4h_export_summary(exec_rep, out_xlsx = out_file)
#' }
#' }
#' @export
d4h_export_summary <- function(x, out_xlsx, houses_proximity = NULL, houses_risk = NULL) {
  if (!inherits(x, "d4h_executive_summary")) {
    stop("'x' must be a 'd4h_executive_summary' object produced by d4h_executive_summary().", call. = FALSE)
  }

  h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
  if (is.null(h_target) && !is.null(attr(x, "houses_proximity"))) {
    h_target <- attr(x, "houses_proximity")
  }
  if (is.null(h_target) && !is.null(attr(x, "houses_risk"))) {
    h_target <- attr(x, "houses_risk")
  }

  dir_out <- dirname(out_xlsx)
  if (!dir.exists(dir_out) && dir_out != "" && dir_out != ".") {
    dir.create(dir_out, recursive = TRUE)
  }

  # 1. Sheet 1: Global Summary
  raw_items <- if (!is.null(attr(x, "raw_summary"))) attr(x, "raw_summary") else x
  global_rows <- lapply(raw_items, function(item) {
    if (!is.null(item$error)) return(NULL)
    sp <- item$spatial
    st <- item$stats
    ot <- item$outliers
    data.frame(
      Indicator = item$indicator,
      Resolution = paste(sp$res_x, sp$res_unit),
      Valid_Pixels = sp$n_valid,
      Coverage_Pct = sp$coverage_pct,
      Area_ha = sp$area_ha,
      Area_m2 = sp$area_m2,
      Mean = st$mean,
      Std_Dev = st$sd,
      CV_Pct = st$cv_pct,
      Minimum = st$min,
      Maximum = st$max,
      Range = st$range,
      Median_Q50 = st$median,
      IQR = st$iqr,
      Q25 = st$q25,
      Q75 = st$q75,
      P05 = st$p05,
      P95 = st$p95,
      Outliers_Pct = ot$pct,
      Outlier_Diagnostics = ot$diagnosis,
      stringsAsFactors = FALSE
    )
  })
  df_global <- do.call(rbind, global_rows)

  # 2. Sheet 2: Thematic Stratification
  strata_rows <- list()
  for (item in raw_items) {
    if (!is.null(item$error)) next
    for (st_name in names(item$strata)) {
      st_val <- item$strata[[st_name]]
      strata_rows[[length(strata_rows) + 1L]] <- data.frame(
        Indicator = item$indicator,
        Stratum = st_name,
        Percentage = round(st_val$pct, 2),
        Surface_ha = round(st_val$ha, 4),
        stringsAsFactors = FALSE
      )
    }
  }
  df_strata <- if (length(strata_rows) > 0) do.call(rbind, strata_rows) else data.frame()

  # 3. Sheet 3: Outlier Diagnostics
  outlier_rows <- lapply(raw_items, function(item) {
    if (!is.null(item$error)) return(NULL)
    ot <- item$outliers
    data.frame(
      Indicator = item$indicator,
      Lower_Fence = ot$lower_fence,
      Upper_Fence = ot$upper_fence,
      Low_Outliers = ot$count_low,
      High_Outliers = ot$count_high,
      Total_Outliers = ot$count_total,
      Outlier_Pct = ot$pct,
      Diagnosis = ot$diagnosis,
      stringsAsFactors = FALSE
    )
  })
  df_outliers <- do.call(rbind, outlier_rows)

  sheets <- list(
    Global_Summary = df_global,
    Thematic_Strata = df_strata,
    Outliers_Diagnostics = df_outliers
  )

  # Include Raster_Metadata sheet if ingested metadata exists
  if (!is.null(attr(x, "metadata"))) {
    sheets[["Raster_Metadata"]] <- as.data.frame(attr(x, "metadata"))
  }

  # If household proximity data is present, append sheets 4 and 5
  if (!is.null(h_target)) {
    h_sheets <- .build_houses_proximity_sheets(h_target)
    if (!is.null(h_sheets)) {
      sheets[["Household_Water_Proximity"]]   <- h_sheets$Household_Water_Proximity
      sheets[["Household_Proximity_Summary"]] <- h_sheets$Household_Proximity_Summary
    }
  }

  # Export with writexl or openxlsx
  if (requireNamespace("writexl", quietly = TRUE)) {
    writexl::write_xlsx(sheets, path = out_xlsx)
    message(sprintf("Executive summary successfully exported to Excel: %s", out_xlsx))
  } else if (requireNamespace("openxlsx", quietly = TRUE)) {
    openxlsx::write.xlsx(sheets, file = out_xlsx)
    message(sprintf("Executive summary successfully exported to Excel: %s", out_xlsx))
  } else {
    csv_fallback <- sub("\\.xlsx$", ".csv", out_xlsx)
    utils::write.csv(df_global, file = csv_fallback, row.names = FALSE)
    warning(
      "Neither 'writexl' nor 'openxlsx' is installed. Saved 'Global_Summary' to CSV: ",
      csv_fallback,
      "\nTo export full multi-sheet workbooks (.xlsx), install writexl: install.packages('writexl')",
      call. = FALSE
    )
  }

  invisible(x)
}

#' @export
print.d4h_executive_summary <- function(x, ...) {
  raw_items <- if (!is.null(attr(x, "raw_summary"))) attr(x, "raw_summary") else x

  cat("\n")
  cat(rep("=", 78), "\n", sep = "")
  cat("             DRONES4HEALTH - EXECUTIVE SUMMARY REPORT\n")
  cat(rep("=", 78), "\n\n", sep = "")

  for (i in seq_along(raw_items)) {
    item <- raw_items[[i]]
    if (!is.null(item$error)) {
      cat(sprintf("Indicator: %s [ERROR: %s]\n\n", item$indicator, item$error))
      next
    }

    sp <- item$spatial
    st <- item$stats
    ot <- item$outliers

    cat(sprintf(" INDICATOR: %s\n", toupper(item$indicator)))
    cat(rep("-", 78), "\n", sep = "")

    cat(" 1. SPATIAL COVERAGE AND RESOLUTION:\n")
    if (!is.null(sp$pixel_size_desc)) {
      cat(sprintf("    - Pixel Resolution    : %s\n", sp$pixel_size_desc))
    } else {
      cat(sprintf("    - Pixel Resolution    : %s %s\n", sp$res_x, sp$res_unit))
    }
    if (!is.null(sp$width_px)) {
      cat(sprintf("    - Scene Dimensions    : %s px x %s px (%s total pixels, %s)\n",
                  format(sp$width_px, big.mark = ","), format(sp$height_px, big.mark = ","),
                  format(sp$total_pixels, big.mark = ","), sp$dtype))
    }
    if (!is.null(sp$bbox_area_ha)) {
      cat(sprintf("    - Scene Bounding Box  : %s ha (%s m2 | %s m x %s m)\n",
                  format(sp$bbox_area_ha, big.mark = ","), format(sp$bbox_area_m2, big.mark = ","),
                  format(sp$field_width_m, big.mark = ","), format(sp$field_height_m, big.mark = ",")))
    }
    if (!is.null(sp$crs_epsg) && !is.na(sp$crs_epsg) && sp$crs_epsg != "N/A") {
      cat(sprintf("    - Coordinate System   : EPSG:%s (%s)\n", sp$crs_epsg, sp$crs))
    }
    cat(sprintf("    - Surveyed Area       : %s ha (%s m2)\n", format(sp$area_ha, big.mark = ","), format(sp$area_m2, big.mark = ",")))
    if (isTRUE(sp$is_sampled)) {
      cat(sprintf("    - Evaluated Pixels    : %s sampled (~%s valid total, %s%% footprint coverage)\n\n",
                  format(sp$n_sampled, big.mark = ","), format(sp$n_valid, big.mark = ","), sp$coverage_pct))
    } else {
      cat(sprintf("    - Evaluated Pixels    : %s (%s%% valid footprint coverage)\n\n",
                  format(sp$n_valid, big.mark = ","), sp$coverage_pct))
    }

    cat(" 2. GLOBAL DESCRIPTIVE STATISTICAL MOMENTS:\n")
    cat(sprintf("    - Arithmetic Mean     : %s (+/- %s SD)\n", st$mean, st$sd))
    cat(sprintf("    - Coeff. of Variation : %s %%\n", st$cv_pct))
    cat(sprintf("    - Overall Range [Min,Max]: [%s, %s] (Span: %s)\n", st$min, st$max, st$range))
    cat(sprintf("    - Median (Q50)        : %s\n", st$median))
    cat(sprintf("    - Interquartile Range : [%s, %s] (IQR: %s)\n", st$q25, st$q75, st$iqr))
    cat(sprintf("    - Central 90%% Span    : [%s, %s] (P05 - P95)\n\n", st$p05, st$p95))

    cat(" 3. SPATIAL OUTLIER DIAGNOSTICS (TUKEY IQR):\n")
    cat(sprintf("    - Tukey IQR Fences    : Lower < %s | Upper > %s\n", ot$lower_fence, ot$upper_fence))
    cat(sprintf("    - Outliers Detected   : %s pixels (%s%% of valid pixels)\n", format(ot$count_total, big.mark = ","), ot$pct))
    cat(sprintf("    - Spatial Diagnostics : %s\n\n", ot$diagnosis))

    cat(" 4. THEMATIC STRATIFICATION & SPATIAL EXTENT:\n")
    for (st_name in names(item$strata)) {
      st_info <- item$strata[[st_name]]
      cat(sprintf("    - %-42s: %5.1f %% (%6.2f ha)\n", st_name, st_info$pct, st_info$ha))
    }
    cat("\n")
    if (i < length(raw_items)) cat(rep(".", 78), "\n\n", sep = "")
  }

  # 5. Section for household proximity if provided
  hp <- attr(x, "houses_proximity")
  if (is.null(hp)) hp <- attr(x, "houses_risk")
  if (!is.null(hp)) {
    h_sheets <- .build_houses_proximity_sheets(hp)
    if (!is.null(h_sheets)) {
      df_c <- h_sheets$Household_Water_Proximity
      df_s <- h_sheets$Household_Proximity_Summary

      cat(rep("-", 78), "\n", sep = "")
      cat(" 5. HOUSEHOLD WATER PROXIMITY & EXPOSURE ASSESSMENT:\n")
      cat(sprintf("    - Total Households Evaluated : %d dwellings\n", nrow(df_c)))
      if (any(!is.na(df_c$dist_water_m))) {
        d_clean <- df_c$dist_water_m[!is.na(df_c$dist_water_m)]
        cat(sprintf("    - Euclidean Distance to Water: Mean = %.1f m (Min = %.1f m, Max = %.1f m)\n\n",
                    mean(d_clean), min(d_clean), max(d_clean)))
      }
      cat("    - Proximity Exposure Stratification:\n")
      for (k in seq_len(nrow(df_s))) {
        cat(sprintf("      * %-28s: %3d houses (%5.1f%%) | Mean dist: %5.1f m\n",
                    df_s$Proximity_Tier[k], df_s$Household_Count[k], df_s$Household_Pct[k], df_s$Mean_Distance_m[k]))
      }
      cat("\n")
    }
  }

  cat(rep("=", 78), "\n\n", sep = "")
  invisible(x)
}

#' @export
as.data.frame.d4h_executive_summary <- function(x, ...) {
  if (is.data.frame(x)) {
    df <- as.data.frame(unclass(x))
    # Remove raw list attributes for pure data.frame printing if desired
    attr(df, "raw_summary") <- NULL
    attr(df, "strata") <- NULL
    df
  } else {
    raw_items <- if (!is.null(attr(x, "raw_summary"))) attr(x, "raw_summary") else x
    rows <- lapply(raw_items, function(item) {
      if (!is.null(item$error)) return(NULL)
      sp <- item$spatial
      st <- item$stats
      ot <- item$outliers
      data.frame(
        indicator = item$indicator,
        area_ha = sp$area_ha,
        mean = st$mean,
        sd = st$sd,
        cv_pct = st$cv_pct,
        min = st$min,
        max = st$max,
        median = st$median,
        iqr = st$iqr,
        outliers_pct = ot$pct,
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, rows)
  }
}

#' @export
as.data.frame.d4h_grid_summary <- function(x, ...) {
  if (!is.null(x$df)) as.data.frame(x$df) else NextMethod()
}

#' @export
st_as_sf.d4h_grid_summary <- function(x, ...) {
  if (!is.null(x$sf)) x$sf else NextMethod()
}

#' @export
`$.d4h_grid_summary` <- function(x, name) {
  if (name %in% c("sf", "df", "summary", "composition")) {
    return(.subset2(x, name))
  }
  df_obj <- .subset2(x, "df")
  if (!is.null(df_obj) && name %in% names(df_obj)) {
    return(df_obj[[name]])
  }
  sf_obj <- .subset2(x, "sf")
  if (!is.null(sf_obj) && name %in% names(sf_obj)) {
    return(sf_obj[[name]])
  }
  .subset2(x, name)
}

#' @export
`[[.d4h_grid_summary` <- function(x, i, ...) {
  if (is.character(i) && !i %in% c("sf", "df", "summary", "composition")) {
    df_obj <- .subset2(x, "df")
    if (!is.null(df_obj) && i %in% names(df_obj)) {
      return(df_obj[[i]])
    }
  }
  NextMethod()
}

#' @export
print.d4h_grid_summary <- function(x, ...) {
  cat("\n==============================================================================\n")
  cat("             DRONES4HEALTH - OPERATIONAL GRID SURVEILLANCE SUMMARY            \n")
  cat("==============================================================================\n")
  cat(sprintf(" Evaluated Units : %d grid cells | Attributes: %d\n", nrow(x$df), ncol(x$df)))
  cat(" Structure       : Both spatial ($sf) and tabular ($df) representations provided.\n")
  cat(" Available parts : $sf (sf polygons with geometry) | $df (clean tabular data.frame)\n")
  cat(" Included fields : Micro-environmental composition (pct_bare_soil, pct_houses,\n")
  cat("                   pct_water, pct_vegetation, dominant_class, surveillance_priority)\n")
  cat("                   and descriptive indicator moments (mean, sd, median, outliers).\n")
  cat("------------------------------------------------------------------------------\n")
  print(head(x$df, 6))
  cat("==============================================================================\n\n")
  invisible(x)
}
