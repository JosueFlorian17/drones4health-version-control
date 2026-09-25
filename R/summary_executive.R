#' @title Executive Summary of Micro-Environmental and Epidemiological Indicators
#' @description Generates a comprehensive executive report for a given raster layer or multi-band mosaic. It extracts key statistical moments, spatial extent and resolution metrics, Tukey outlier diagnostics, domain-specific bio-physical/epidemiological stratum interpretations, and optionally exports a formatted multi-sheet Excel spreadsheet.
#' @param raster_in SpatRaster, list of SpatRaster layers, or character file path.
#' @param out_xlsx Character (optional). File path to export a structured multi-sheet Excel workbook (.xlsx). Default: NULL.
#' @param sample_size Integer. Maximum number of sampled pixels for quantile and outlier analysis on large rasters (default: 1000000).
#' @param digits Integer. Number of decimal places to format numerical metrics (default: 3).
#' @return An object of class \code{d4h_executive_summary} containing a structured list of metrics, spatial coverage metadata, outlier diagnostics, and thematic stratum distributions.
#' @export
d4h_executive_summary <- function(raster_in, out_xlsx = NULL, sample_size = 1000000, digits = 3) {
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
      "Distribucion homogenea (valores extremos < 1%)"
    } else if (outliers_pct < 5) {
      "Variabilidad moderada (puntos atipicos localizados)"
    } else {
      "Alta dispersion / presencia significativa de anomalias o bordes"
    }

    # 4. Estratificacion tematica contextualizada por tipo de indice
    var_upper <- toupper(var_name)
    strata <- list()

    if (grepl("NDVI|SAVI|GNDVI|NDRE|EVI|DVI", var_upper)) {
      strata[["Agua / Suelo muy degradado (< 0.0)"]] <- list(pct = mean(vals < 0) * 100, ha = (mean(vals < 0) * area_ha))
      strata[["Suelo desnudo / Escasa vegetacion [0.0, 0.2)"]] <- list(pct = mean(vals >= 0 & vals < 0.2) * 100, ha = (mean(vals >= 0 & vals < 0.2) * area_ha))
      strata[["Vegetacion moderada / Transicion [0.2, 0.5)"]] <- list(pct = mean(vals >= 0.2 & vals < 0.5) * 100, ha = (mean(vals >= 0.2 & vals < 0.5) * area_ha))
      strata[["Vegetacion densa / Alto vigor [>= 0.5)"]] <- list(pct = mean(vals >= 0.5) * 100, ha = (mean(vals >= 0.5) * area_ha))
    } else if (grepl("NDWI|IRHE", var_upper)) {
      strata[["Cuerpos de agua / Suelo saturado (> 0.0)"]] <- list(pct = mean(vals > 0) * 100, ha = (mean(vals > 0) * area_ha))
      strata[["Superficie no saturada (<= 0.0)"]] <- list(pct = mean(vals <= 0) * 100, ha = (mean(vals <= 0) * area_ha))
    } else if (grepl("IMSR", var_upper)) {
      strata[["Entorno natural / Sin riesgo (< 0.15)"]] <- list(pct = mean(vals < 0.15) * 100, ha = (mean(vals < 0.15) * area_ha))
      strata[["Riesgo moderado / Residuos dispersos [0.15, 0.35)"]] <- list(pct = mean(vals >= 0.15 & vals < 0.35) * 100, ha = (mean(vals >= 0.15 & vals < 0.35) * area_ha))
      strata[["Alto riesgo / Contenedores y plasticos (>= 0.35)"]] <- list(pct = mean(vals >= 0.35) * 100, ha = (mean(vals >= 0.35) * area_ha))
    } else if (grepl("SLOPE|PENDIENTE", var_upper)) {
      strata[["Terreno plano / Micro-depresiones (< 5 deg)"]] <- list(pct = mean(vals < 5) * 100, ha = (mean(vals < 5) * area_ha))
      strata[["Pendiente moderada [5, 15 deg]"]] <- list(pct = mean(vals >= 5 & vals <= 15) * 100, ha = (mean(vals >= 5 & vals <= 15) * area_ha))
      strata[["Terreno escarpado (> 15 deg)"]] <- list(pct = mean(vals > 15) * 100, ha = (mean(vals > 15) * area_ha))
    } else if (grepl("TWI|IEV", var_upper)) {
      strata[["Bajo potencial de estancamiento (< 4.0)"]] <- list(pct = mean(vals < 4) * 100, ha = (mean(vals < 4) * area_ha))
      strata[["Riesgo moderado de acumulacion [4.0, 8.0]"]] <- list(pct = mean(vals >= 4 & vals <= 8) * 100, ha = (mean(vals >= 4 & vals <= 8) * area_ha))
      strata[["Zona critica de micro-estancamiento (> 8.0)"]] <- list(pct = mean(vals > 8) * 100, ha = (mean(vals > 8) * area_ha))
    } else {
      strata[["Bajo [Min, Q25)"]] <- list(pct = mean(vals < q25) * 100, ha = (mean(vals < q25) * area_ha))
      strata[["Medio-Bajo [Q25, Mediana)"]] <- list(pct = mean(vals >= q25 & vals < median_val) * 100, ha = (mean(vals >= q25 & vals < median_val) * area_ha))
      strata[["Medio-Alto [Mediana, Q75)"]] <- list(pct = mean(vals >= median_val & vals < q75) * 100, ha = (mean(vals >= median_val & vals < q75) * area_ha))
      strata[["Alto [Q75, Max]"]] <- list(pct = mean(vals >= q75) * 100, ha = (mean(vals >= q75) * area_ha))
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

  # Exportar a Excel si se solicita
  if (!is.null(out_xlsx)) {
    d4h_export_summary(summaries, out_xlsx = out_xlsx)
  }

  summaries
}

#' @rdname d4h_executive_summary
#' @export
d4h_report <- d4h_executive_summary

#' @title Export Executive Summary to Multi-Sheet Excel File
#' @description Exports a \code{d4h_executive_summary} object to an Excel workbook (.xlsx) with dedicated sheets for Global Summary, Stratification, and Outlier Diagnostics.
#' @param x An object of class \code{d4h_executive_summary}.
#' @param out_xlsx Character. Path where the .xlsx file will be created.
#' @return Invisibly returns the input object \code{x}.
#' @export
d4h_export_summary <- function(x, out_xlsx) {
  if (!inherits(x, "d4h_executive_summary")) {
    stop("'x' must be a 'd4h_executive_summary' object produced by d4h_executive_summary().", call. = FALSE)
  }

  dir_out <- dirname(out_xlsx)
  if (!dir.exists(dir_out) && dir_out != "" && dir_out != ".") {
    dir.create(dir_out, recursive = TRUE)
  }

  # 1. Hoja 1: Resumen Global
  global_rows <- lapply(x, function(item) {
    if (!is.null(item$error)) return(NULL)
    sp <- item$spatial
    st <- item$stats
    ot <- item$outliers
    data.frame(
      Indicador = item$indicator,
      Resolucion = paste(sp$res_x, sp$res_unit),
      Pixeles_Validos = sp$n_valid,
      Cobertura_Pct = sp$coverage_pct,
      Area_ha = sp$area_ha,
      Area_m2 = sp$area_m2,
      Media = st$mean,
      Desv_Estandar = st$sd,
      CV_Pct = st$cv_pct,
      Minimo = st$min,
      Maximo = st$max,
      Rango = st$range,
      Mediana_Q50 = st$median,
      IQR = st$iqr,
      Q25 = st$q25,
      Q75 = st$q75,
      P05 = st$p05,
      P95 = st$p95,
      Outliers_Pct = ot$pct,
      Diagnostico_Outliers = ot$diagnosis,
      stringsAsFactors = FALSE
    )
  })
  df_global <- do.call(rbind, global_rows)

  # 2. Hoja 2: Estratificacion Tematica
  strata_rows <- list()
  for (item in x) {
    if (!is.null(item$error)) next
    for (st_name in names(item$strata)) {
      st_val <- item$strata[[st_name]]
      strata_rows[[length(strata_rows) + 1L]] <- data.frame(
        Indicador = item$indicator,
        Estrato = st_name,
        Porcentaje = round(st_val$pct, 2),
        Superficie_ha = round(st_val$ha, 4),
        stringsAsFactors = FALSE
      )
    }
  }
  df_strata <- if (length(strata_rows) > 0) do.call(rbind, strata_rows) else data.frame()

  # 3. Hoja 3: Detalle de Outliers
  outlier_rows <- lapply(x, function(item) {
    if (!is.null(item$error)) return(NULL)
    ot <- item$outliers
    data.frame(
      Indicador = item$indicator,
      Limite_Inferior = ot$lower_fence,
      Limite_Superior = ot$upper_fence,
      Atipicos_Bajos = ot$count_low,
      Atipicos_Altos = ot$count_high,
      Total_Atipicos = ot$count_total,
      Porcentaje_Atipicos = ot$pct,
      Diagnostico = ot$diagnosis,
      stringsAsFactors = FALSE
    )
  })
  df_outliers <- do.call(rbind, outlier_rows)

  sheets <- list(
    Resumen_Global = df_global,
    Estratificacion = df_strata,
    Outliers_Detalle = df_outliers
  )

  # Escribir con writexl u openxlsx
  if (requireNamespace("writexl", quietly = TRUE)) {
    writexl::write_xlsx(sheets, path = out_xlsx)
    message(sprintf("Resumen ejecutivo exportado exitosamente a Excel: %s", out_xlsx))
  } else if (requireNamespace("openxlsx", quietly = TRUE)) {
    openxlsx::write.xlsx(sheets, file = out_xlsx)
    message(sprintf("Resumen ejecutivo exportado exitosamente a Excel: %s", out_xlsx))
  } else {
    csv_fallback <- sub("\\.xlsx$", ".csv", out_xlsx)
    utils::write.csv(df_global, file = csv_fallback, row.names = FALSE)
    warning(
      "No se encontro 'writexl' ni 'openxlsx' instalado. Se exporto 'Resumen_Global' a CSV: ",
      csv_fallback,
      "\nPara exportar libros completos con multiples hojas (.xlsx), instala writexl ejecutando: install.packages('writexl')",
      call. = FALSE
    )
  }

  invisible(x)
}

#' @export
print.d4h_executive_summary <- function(x, ...) {
  cat("\n")
  cat(rep("=", 78), "\n", sep = "")
  cat("             DRONES4HEALTH - INFORME RESUMEN EJECUTIVO\n")
  cat(rep("=", 78), "\n\n", sep = "")

  for (i in seq_along(x)) {
    item <- x[[i]]
    if (!is.null(item$error)) {
      cat(sprintf("Indicador: %s [ERROR: %s]\n\n", item$indicator, item$error))
      next
    }

    sp <- item$spatial
    st <- item$stats
    ot <- item$outliers

    cat(sprintf(" INDICADOR: %s\n", toupper(item$indicator)))
    cat(rep("-", 78), "\n", sep = "")

    cat(" 1. COBERTURA Y RESOLUCION ESPACIAL:\n")
    cat(sprintf("    - Resolucion de pixel : %s %s\n", sp$res_x, sp$res_unit))
    cat(sprintf("    - Area util cubierta  : %s ha (%s m2)\n", format(sp$area_ha, big.mark = ","), format(sp$area_m2, big.mark = ",")))
    cat(sprintf("    - Pixeles evaluados   : %s (%s%% de la escena util)\n\n", format(sp$n_valid, big.mark = ","), sp$coverage_pct))

    cat(" 2. ESTADISTICAS DESCRIPTIVAS GLOBALES:\n")
    cat(sprintf("    - Promedio (Media)    : %s (+/- %s SD)\n", st$mean, st$sd))
    cat(sprintf("    - Coef. de Variacion  : %s %%\n", st$cv_pct))
    cat(sprintf("    - Rango total [Min,Max]: [%s, %s] (Amplitud: %s)\n", st$min, st$max, st$range))
    cat(sprintf("    - Mediana (Q50)       : %s\n", st$median))
    cat(sprintf("    - Rango Intercuartil  : [%s, %s] (IQR: %s)\n", st$q25, st$q75, st$iqr))
    cat(sprintf("    - Intervalo 90%% central: [%s, %s] (P5 - P95)\n\n", st$p05, st$p95))

    cat(" 3. DIAGNOSTICO DE VALORES ATIPICOS (OUTLIERS):\n")
    cat(sprintf("    - Limites Tukey (IQR) : Inferior < %s | Superior > %s\n", ot$lower_fence, ot$upper_fence))
    cat(sprintf("    - Atipicos detectados : %s pixeles (%s%% del total)\n", format(ot$count_total, big.mark = ","), ot$pct))
    cat(sprintf("    - Diagnostico         : %s\n\n", ot$diagnosis))

    cat(" 4. ESTRATIFICACION TEMATICA Y SUPERFICIES:\n")
    for (st_name in names(item$strata)) {
      st_info <- item$strata[[st_name]]
      cat(sprintf("    - %-42s: %5.1f %% (%6.2f ha)\n", st_name, st_info$pct, st_info$ha))
    }
    cat("\n")
    if (i < length(x)) cat(rep(".", 78), "\n\n", sep = "")
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
