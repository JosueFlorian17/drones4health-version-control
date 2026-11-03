# Internal Raster Metadata Extraction Utility
# Ingested internally by existing analytical functions (e.g., d4h_executive_summary, d4h_read_stack)

#' Extract and Display Structured Raster Metadata (Internal)
#' @description Inspects one or more drone orthomosaics or raster layers and extracts comprehensive spatial metadata, including dimensions, data type, spatial resolution (GSD), georeferencing, bounding box, physical scene dimensions, and coordinate reference systems.
#' @param x Character file path, \code{terra::SpatRaster}, or list of file paths/SpatRasters.
#' @param quiet Logical. If \code{FALSE}, prints a structured executive summary block to the console. If \code{TRUE} (default), suppresses printing.
#' @return A data frame containing metadata attributes per raster layer or file.
#' @keywords internal
#' @noRd
.d4h_raster_metadata <- function(x, quiet = TRUE) {
  # Normalize input into a list of targets
  items <- if (is.character(x)) {
    as.list(x)
  } else if (inherits(x, "SpatRaster")) {
    list(x)
  } else if (is.list(x)) {
    x
  } else {
    stop("'x' must be a character file path, a SpatRaster, or a list thereof.", call. = FALSE)
  }

  meta_rows <- lapply(items, function(item) {
    if (is.character(item)) {
      if (!file.exists(item)) {
        warning(paste("File does not exist:", item), call. = FALSE)
        return(NULL)
      }
      r <- terra::rast(item)
      src_name <- basename(item)
    } else if (inherits(item, "SpatRaster")) {
      r <- item
      src_name <- terra::sources(r)[1]
      if (is.null(src_name) || is.na(src_name) || src_name == "") {
        src_name <- names(r)[1]
      } else {
        src_name <- basename(src_name)
      }
    } else {
      warning("Unsupported item type in .d4h_raster_metadata; skipping.", call. = FALSE)
      return(NULL)
    }

    # 1. Dimensions and Structure
    w <- terra::ncol(r)
    h <- terra::nrow(r)
    tot_px <- as.numeric(w) * as.numeric(h)
    nb <- terra::nlyr(r)
    dt <- terra::datatype(r)[1]
    nd <- suppressWarnings(terra::NAflag(r))

    # 2. Spatial Resolution (GSD)
    rx <- terra::xres(r)
    ry <- terra::yres(r)
    is_lonlat_val <- suppressWarnings(terra::is.lonlat(r))
    es_proyectado <- if (is.na(is_lonlat_val)) TRUE else !is_lonlat_val
    unidad <- if (es_proyectado) "m" else "deg"

    gsd_val_cm <- if (es_proyectado) rx * 100 else rx * 111320 * 100
    if (es_proyectado && rx < 1.0) {
      res_desc <- sprintf("%.2f cm x %.2f cm (or %.4f m)", rx * 100, ry * 100, rx)
    } else {
      res_desc <- sprintf("%.4f %s x %.4f %s", rx, unidad, ry, unidad)
    }

    # 3. Georeferencing and CRS
    crs_desc <- terra::crs(r, describe = TRUE)
    epsg_code <- if (!is.null(crs_desc$code) && !is.na(crs_desc$code)) as.integer(crs_desc$code) else NA_integer_
    crs_name <- if (!is.null(crs_desc$name) && !is.na(crs_desc$name)) crs_desc$name else terra::crs(r)

    # 4. Spatial Bounds & Scene Area
    e <- terra::ext(r)
    xmin_val <- e$xmin
    xmax_val <- e$xmax
    ymin_val <- e$ymin
    ymax_val <- e$ymax

    ancho_m <- if (es_proyectado) (xmax_val - xmin_val) else (xmax_val - xmin_val) * 111320
    alto_m  <- if (es_proyectado) (ymax_val - ymin_val) else (ymax_val - ymin_val) * 110540
    area_m2 <- ancho_m * alto_m
    area_ha <- area_m2 / 10000

    data.frame(
      file            = src_name,
      width           = w,
      height          = h,
      total_pixels    = tot_px,
      nbands          = nb,
      dtype           = dt,
      nodata          = if (length(nd) == 0 || is.na(nd)) "None" else as.character(nd),
      res_x           = rx,
      res_y           = ry,
      gsd_cm          = round(gsd_val_cm, 2),
      pixel_size_desc = res_desc,
      crs             = crs_name,
      epsg            = epsg_code,
      is_projected    = es_proyectado,
      xmin            = xmin_val,
      xmax            = xmax_val,
      ymin            = ymin_val,
      ymax            = ymax_val,
      width_m         = round(ancho_m, 1),
      height_m        = round(alto_m, 1),
      area_m2         = round(area_m2, 1),
      area_ha         = round(area_ha, 3),
      stringsAsFactors = FALSE
    )
  })

  df_meta <- do.call(rbind, meta_rows[!vapply(meta_rows, is.null, logical(1))])
  df_meta <- as.data.frame(df_meta, stringsAsFactors = FALSE)
  class(df_meta) <- c("d4h_raster_metadata", "data.frame")

  if (!quiet) {
    print(df_meta)
  }

  invisible(df_meta)
}

# Internal alias
.get_raster_metadata <- .d4h_raster_metadata

#' @export
print.d4h_raster_metadata <- function(x, ...) {
  df <- as.data.frame(x)
  if (nrow(df) == 0L) {
    cat("Empty raster metadata object.\n")
    return(invisible(x))
  }

  for (i in seq_len(nrow(df))) {
    row <- df[i, ]
    cat("\n")
    cat(rep("=", 68), "\n", sep = "")
    cat(sprintf(" RASTER METADATA SUMMARY: %s\n", row$file))
    cat(rep("=", 68), "\n\n", sep = "")

    cat("[+] DIMENSIONS AND STRUCTURE:\n")
    cat(sprintf("  - Width (Columns)      : %s px\n", format(row$width, big.mark = ",")))
    cat(sprintf("  - Height (Rows)        : %s px\n", format(row$height, big.mark = ",")))
    cat(sprintf("  - Total Pixels         : %s px\n", format(row$total_pixels, big.mark = ",")))
    cat(sprintf("  - Number of Bands      : %d\n", row$nbands))
    cat(sprintf("  - Data Type (dtype)    : %s\n", row$dtype))
    cat(sprintf("  - NoData Value         : %s\n\n", row$nodata))

    cat("[+] SPATIAL RESOLUTION (PIXEL SIZE / GSD):\n")
    cat(sprintf("  - Resolution X         : %.6f %s\n", row$res_x, if (row$is_projected) "m" else "deg"))
    cat(sprintf("  - Resolution Y         : %.6f %s\n", row$res_y, if (row$is_projected) "m" else "deg"))
    cat(sprintf("  - Pixel Size (GSD)     : %s\n\n", row$pixel_size_desc))

    cat("[+] GEO-REFERENCING AND COORDINATE SYSTEM:\n")
    cat(sprintf("  - CRS                  : %s\n", row$crs))
    cat(sprintf("  - EPSG Code            : EPSG:%s\n", if (is.na(row$epsg)) "N/A" else as.character(row$epsg)))
    cat(sprintf("  - Projected (Meters)   : %s\n\n", if (row$is_projected) "Yes" else "No"))

    cat("[+] SPATIAL BOUNDS (BOUNDING BOX):\n")
    cat(sprintf("  - X Min (West)         : %s\n", format(round(row$xmin, 2), big.mark = ",")))
    cat(sprintf("  - X Max (East)         : %s\n", format(round(row$xmax, 2), big.mark = ",")))
    cat(sprintf("  - Y Min (South)        : %s\n", format(round(row$ymin, 2), big.mark = ",")))
    cat(sprintf("  - Y Max (North)        : %s\n", format(round(row$ymax, 2), big.mark = ",")))
    cat(sprintf("  - Field Dimensions     : %s m x %s m\n", format(row$width_m, big.mark = ","), format(row$height_m, big.mark = ",")))
    cat(sprintf("  - Bounding Box Area    : %s ha (%s m2)\n", format(row$area_ha, big.mark = ","), format(row$area_m2, big.mark = ",")))
    cat(rep("=", 68), "\n\n", sep = "")
  }

  invisible(x)
}
