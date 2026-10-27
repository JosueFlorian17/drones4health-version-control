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
#' @param houses_proximity Optional \code{sf} or \code{data.frame} of residential dwellings with calculated distance to water and proximity scores (e.g. from \code{d4h_distance_to_water} or buffer analysis). If provided, appends dedicated household distance and proximity exposure sheets to the Excel workbook.
#' @param houses_risk Deprecated alias for \code{houses_proximity}.
#' @param cell_size Numeric. Grid cell size / diameter in meters when generating a new grid for \code{by = "grid"} (default: 50).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: TRUE).
#' @param out_xlsx Character (optional). File path to export a structured multi-sheet Excel workbook (.xlsx). Default: NULL.
#' @param sample_size Integer. Maximum number of sampled pixels for quantile and outlier analysis on large rasters (default: 1000000).
#' @param digits Integer. Number of decimal places to format numerical metrics (default: 3).
#' @return An object of class \code{d4h_executive_summary} (for \code{by = "general"}) or \code{d4h_grid_summary} / \code{data.frame} (for \code{by = "grid"}) containing structured metrics, spatial coverage metadata, outlier diagnostics, and thematic stratum distributions.
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
#'   head(exec_grid)
#' }
#' }
#' @export
d4h_executive_summary <- function(raster_in, by = c("general", "grid"), grid = NULL, houses_proximity = NULL, houses_risk = NULL, cell_size = 50, square = TRUE, out_xlsx = NULL, sample_size = 1000000, digits = 3) {
  by <- match.arg(by)
  if (is.null(houses_proximity) && !is.null(houses_risk)) {
    houses_proximity <- houses_risk
  }

  r <- if (is.character(raster_in) && length(raster_in) == 1L) {
    if (!file.exists(raster_in)) stop(paste("File not found:", raster_in), call. = FALSE)
    terra::rast(raster_in)
  } else if (inherits(raster_in, "SpatRaster")) {
    raster_in
  } else if (is.list(raster_in) && all(vapply(raster_in, function(x) inherits(x, "SpatRaster"), logical(1)))) {
    terra::rast(raster_in)
  } else {
    stop("'raster_in' must be a SpatRaster, a list of SpatRasters, or a valid file path.", call. = FALSE)
  }

  n_layers <- terra::nlyr(r)
  layer_names <- names(r)
  if (is.null(layer_names) || any(layer_names == "")) {
    layer_names <- paste0("layer_", seq_len(n_layers))
    names(r) <- layer_names
  }

  # ============================================================================
  # MODO B: RESUMEN POR GRILLA (UNA FILA POR CELDA)
  # ============================================================================
  if (by == "grid") {
    # 1. Resolver o generar la grilla vectorial
    grid_vect <- if (!is.null(grid)) {
      if (is.character(grid) && length(grid) == 1L) {
        if (!file.exists(grid)) stop(paste("Grid file not found:", grid), call. = FALSE)
        terra::vect(grid)
      } else if (inherits(grid, "sf")) {
        terra::vect(grid)
      } else if (inherits(grid, "SpatVector")) {
        grid
      } else {
        stop("'grid' must be a SpatVector, sf object, or valid file path.", call. = FALSE)
      }
    } else {
      # Crear grilla operativa con d4h_hex_grid o st_make_grid
      boundary_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(r), crs = terra::crs(r)))
      g_sf <- sf::st_make_grid(boundary_sf, cellsize = cell_size, square = square)
      prefix <- if (square) "G%04d" else "H%04d"
      g_sf <- sf::st_sf(
        grid_id = sprintf(prefix, seq_along(g_sf)),
        geometry = g_sf
      )
      terra::vect(g_sf)
    }

    # Asignar ID si la grilla no lo tiene
    if (!"grid_id" %in% names(grid_vect)) {
      grid_vect$grid_id <- sprintf("G%04d", seq_len(nrow(grid_vect)))
    }

    # Extraer valores por celda
    vals_by_cell <- terra::extract(r, grid_vect)
    cell_idx <- vals_by_cell[, 1]

    # Calcular metricas por celda
    grid_rows <- vector("list", nrow(grid_vect))
    grid_ids <- grid_vect$grid_id

    for (k in seq_len(nrow(grid_vect))) {
      row_match <- which(cell_idx == k)
      sub_vals <- vals_by_cell[row_match, -1, drop = FALSE]

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
        raw_vals <- sub_vals[[v_name]]
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

    df_grid_final <- do.call(rbind, grid_rows[!vapply(grid_rows, is.null, logical(1))])
    rownames(df_grid_final) <- NULL
    class(df_grid_final) <- c("d4h_grid_summary", "data.frame")

    # Export to Excel if requested
    if (!is.null(out_xlsx)) {
      dir_out <- dirname(out_xlsx)
      if (!dir.exists(dir_out) && dir_out != "" && dir_out != ".") {
        dir.create(dir_out, recursive = TRUE)
      }

      num_cols <- names(df_grid_final)[vapply(df_grid_final, is.numeric, logical(1))]
      num_cols <- num_cols[!num_cols %in% c("centroid_x", "centroid_y") & !grepl("_media$|_mediana$|_pct_agua_degradado$|_pct_suelo_desnudo$|_pct_vegetacion_densa$", num_cols)]
      res_glob <- lapply(num_cols, function(col_n) {
        vals <- df_grid_final[[col_n]]
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
        Grid_Summary = df_grid_final,
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
        utils::write.csv(df_grid_final, file = csv_fallback, row.names = FALSE)
      }
    }

    h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
    if (!is.null(h_target)) {
      attr(df_grid_final, "houses_proximity") <- h_target
    }

    return(df_grid_final)

    return(df_grid_final)
  }

  # ============================================================================
  # MODO A: RESUMEN GENERAL (INFORME ESCENARIO GLOBAL)
  # ============================================================================
  summaries <- lapply(seq_len(n_layers), function(i) {
    lyr <- r[[i]]
    var_name <- layer_names[i]

    # 1. Metricas espaciales y resolucion
    res_xy <- terra::res(lyr)
    is_lonlat_val <- suppressWarnings(terra::is.lonlat(lyr))
    is_projected <- if (is.na(is_lonlat_val)) TRUE else !is_lonlat_val
    total_cells <- terra::ncell(lyr)

    # Extraer pixeles validos
    vals <- if (total_cells > sample_size) {
      terra::spatSample(lyr, size = sample_size, method = "regular", na.rm = TRUE)[, 1]
    } else {
      terra::values(lyr, mat = FALSE)
    }
    vals <- vals[!is.na(vals) & is.finite(vals) & vals != 0]

    n_valid <- length(vals)
    if (n_valid == 0L) {
      return(list(
        indicator = var_name,
        error = "No valid non-zero data points found in layer."
      ))
    }

    # Calculo de area aproximada
    pixel_area_m2 <- if (is_projected) res_xy[1] * res_xy[2] else (res_xy[1] * 111320) * (res_xy[2] * 110540)
    area_m2 <- n_valid * pixel_area_m2
    area_ha <- area_m2 / 10000

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
      spatial = list(
        res_x = round(res_xy[1] * if (is_projected && res_xy[1] < 1) 100 else 1, 2),
        res_unit = if (is_projected && res_xy[1] < 1) "cm" else if (is_projected) "m" else "deg",
        n_valid = n_valid,
        coverage_pct = round((n_valid / total_cells) * 100, 1),
        area_ha = round(area_ha, 3),
        area_m2 = round(area_m2, 1)
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
  class(summaries) <- "d4h_executive_summary"

  h_target <- if (!is.null(houses_proximity)) houses_proximity else houses_risk
  if (!is.null(h_target)) {
    attr(summaries, "houses_proximity") <- h_target
  }

  # Export to Excel if requested
  if (!is.null(out_xlsx)) {
    d4h_export_summary(summaries, out_xlsx = out_xlsx, houses_proximity = h_target)
  }

  summaries
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
  names(df_agg_cnt)[2] <- "n_casas"
  df_agg_dist <- stats::aggregate(dist_water_m ~ proximity_tier, data = df_casas_export, FUN = function(v) {
    c(mean = round(mean(v, na.rm = TRUE), 1),
      min  = round(min(v, na.rm = TRUE), 1),
      max  = round(max(v, na.rm = TRUE), 1))
  })
  dist_mat <- df_agg_dist$dist_water_m

  df_strat <- data.frame(
    Proximity_Tier    = df_agg_cnt$proximity_tier,
    Household_Count   = df_agg_cnt$n_casas,
    Household_Pct     = round((df_agg_cnt$n_casas / nrow(df_casas_export)) * 100, 1),
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

#' @rdname d4h_executive_summary
#' @export
d4h_report <- d4h_executive_summary

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
  global_rows <- lapply(x, function(item) {
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
  for (item in x) {
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
  outlier_rows <- lapply(x, function(item) {
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
  cat("\n")
  cat(rep("=", 78), "\n", sep = "")
  cat("             DRONES4HEALTH - EXECUTIVE SUMMARY REPORT\n")
  cat(rep("=", 78), "\n\n", sep = "")

  for (i in seq_along(x)) {
    item <- x[[i]]
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
    cat(sprintf("    - Pixel Resolution    : %s %s\n", sp$res_x, sp$res_unit))
    cat(sprintf("    - Surveyed Area       : %s ha (%s m2)\n", format(sp$area_ha, big.mark = ","), format(sp$area_m2, big.mark = ",")))
    cat(sprintf("    - Evaluated Pixels    : %s (%s%% valid footprint coverage)\n\n", format(sp$n_valid, big.mark = ","), sp$coverage_pct))

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
    if (i < length(x)) cat(rep(".", 78), "\n\n", sep = "")
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
  rows <- lapply(x, function(item) {
    if (!is.null(item$error)) return(NULL)
    sp <- item$spatial
    st <- item$stats
    ot <- item$outliers
    tibble::tibble(
      indicator = item$indicator,
      area_ha = sp$area_ha,
      mean = st$mean,
      sd = st$sd,
      cv_pct = st$cv_pct,
      min = st$min,
      max = st$max,
      median = st$median,
      iqr = st$iqr,
      outliers_pct = ot$pct
    )
  })
  do.call(rbind, rows)
}
