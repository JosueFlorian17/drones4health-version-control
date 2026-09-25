#' @title List Available Micro-Environmental and Epidemiological Metrics
#' @description Returns a tibble listing the curated drone metrics, resolutions, and typical applications.
#' @return A tibble with metric descriptions.
#' @export
d4h_list_metrics <- function() {
  tibble::tribble(
    ~category,          ~metric,            ~resolution_cm, ~application,
    "Spectral",         "NDVI",             5,              "Vegetation vigor & biomass",
    "Spectral",         "NDWI",             5,              "Surface water & moisture detection",
    "Topographic",      "TWI",              10,             "Topographic micro-hydrology & pooling",
    "Epidemiological",  "IEV (Stagnation)", 10,             "Vector / snail breeding micro-depressions",
    "Epidemiological",  "IMSR (Synthetics)",5,              "Artificial container & waste risk sites"
  )
}

#' @title Global Statistical Summary of Raster Indicators
#' @description Calculates descriptive statistics (mean, standard deviation, min, max, and quantiles) across the entire extent of one or multiple SpatRaster indicator layers.
#' @param raster_in SpatRaster, list of SpatRaster layers, or character path to a raster file.
#' @param na.rm Logical. If TRUE, removes NA/infinite/NaN values from computation (default: TRUE).
#' @param quantiles Logical. If TRUE, includes 25th percentile, median (50th percentile), and 75th percentile (default: TRUE).
#' @param digits Numeric. Number of decimal places to round results. If NULL, values are not rounded (default: 4).
#' @return A tibble data frame containing summary statistics per layer.
#' @export
d4h_summarize_global <- function(raster_in, na.rm = TRUE, quantiles = TRUE, digits = 4) {
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

  layer_names <- names(r)
  if (is.null(layer_names) || any(layer_names == "")) {
    layer_names <- paste0("layer_", seq_len(terra::nlyr(r)))
    names(r) <- layer_names
  }

  mean_v <- as.numeric(terra::global(r, "mean", na.rm = na.rm)[, 1])
  sd_v   <- as.numeric(terra::global(r, "sd", na.rm = na.rm)[, 1])
  min_v  <- as.numeric(terra::global(r, "min", na.rm = na.rm)[, 1])
  max_v  <- as.numeric(terra::global(r, "max", na.rm = na.rm)[, 1])

  res <- tibble::tibble(
    indicator = layer_names,
    mean      = mean_v,
    sd        = sd_v,
    min       = min_v,
    max       = max_v
  )

  if (quantiles) {
    q_list <- lapply(seq_len(terra::nlyr(r)), function(i) {
      lyr <- r[[i]]
      vals <- if (terra::ncell(lyr) > 2000000) {
        terra::spatSample(lyr, size = 1000000, method = "regular", na.rm = na.rm)[, 1]
      } else {
        terra::values(lyr, mat = FALSE)
      }
      vals <- vals[!is.na(vals) & is.finite(vals)]
      if (length(vals) == 0L) {
        c(q25 = NA_real_, median = NA_real_, q75 = NA_real_)
      } else {
        q <- stats::quantile(vals, probs = c(0.25, 0.50, 0.75), na.rm = TRUE, names = FALSE)
        c(q25 = q[1], median = q[2], q75 = q[3])
      }
    })
    q_mat <- do.call(rbind, q_list)
    res$q25    <- as.numeric(q_mat[, "q25"])
    res$median <- as.numeric(q_mat[, "median"])
    res$q75    <- as.numeric(q_mat[, "q75"])
  }

  if (!is.null(digits) && is.numeric(digits)) {
    stat_cols <- names(res)[names(res) != "indicator"]
    for (col in stat_cols) {
      res[[col]] <- round(res[[col]], digits)
    }
  }

  res
}

#' @rdname d4h_summarize_global
#' @export
d4h_global_summary <- d4h_summarize_global
