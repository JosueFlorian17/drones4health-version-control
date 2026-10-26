#' @title Read and Validate Multi-Band Stack Raster
#' @description Loads a multi-band raster stack from a file or SpatRaster, verifies that required spectral or terrain bands are present, and throws an informative error if any required band is missing.
#' @details In drone remote sensing pipelines, multi-band orthomosaics often combine optical (Red, Green, Blue), Red Edge, Near-Infrared (NIR), and digital elevation (DEM/DSM) channels into a single stacked GeoTIFF.
#' \code{d4h_read_stack} reads the multi-layer raster, assigns or verifies layer names, and strictly validates that all bands required for downstream metric calculations (such as NDVI or NDWI) exist in the stack.
#' If a required band is absent, execution halts immediately with an informative error listing the missing band(s) and currently available layers.
#'
#' @param file_path Character path or SpatRaster. File path to a multi-band GeoTIFF/raster file, or an existing SpatRaster object.
#' @param required_bands Character vector (optional). Names of bands that must be present in the stack (e.g. \code{c("NIR", "Red")}). Matching is case-insensitive.
#' @param band_names Character vector (optional). Layer names to assign or override on the raster stack. Must match the number of layers if provided.
#' @return A \code{terra::SpatRaster} object with validated layers and band names.
#' @examples
#' \donttest{
#' if (interactive()) {
#'   library(drones4health)
#'
#'   # Define path to multi-band drone raster stack
#'   stack_file <- system.file("extdata", "ortho_multiband.tif", package = "drones4health")
#'
#'   # Read stack and assert presence of NIR and Red bands
#'   r_stack <- d4h_read_stack(
#'     file_path      = stack_file,
#'     required_bands = c("NIR", "Red")
#'   )
#'   print(r_stack)
#' }
#' }
#' @export
d4h_read_stack <- function(file_path, required_bands = NULL, band_names = NULL) {
  # 1. Ingest raster file or validate SpatRaster
  r <- if (is.character(file_path) && length(file_path) == 1L) {
    if (!file.exists(file_path)) {
      stop(paste("Raster file not found:", file_path), call. = FALSE)
    }
    terra::rast(file_path)
  } else if (inherits(file_path, "SpatRaster")) {
    file_path
  } else {
    stop("'file_path' must be a valid file path string or SpatRaster object.", call. = FALSE)
  }

  n_layers <- terra::nlyr(r)
  if (n_layers == 0L) {
    stop("The provided raster stack contains 0 layers.", call. = FALSE)
  }

  # 2. Assign custom band names if provided
  if (!is.null(band_names)) {
    if (length(band_names) != n_layers) {
      stop(sprintf("Length of 'band_names' (%d) does not match the number of raster layers (%d).",
                   length(band_names), n_layers), call. = FALSE)
    }
    names(r) <- band_names
  }

  # 3. Check for required bands
  if (!is.null(required_bands) && length(required_bands) > 0L) {
    curr_names <- names(r)
    curr_lower <- tolower(curr_names)

    missing_bands <- character(0)
    for (req in required_bands) {
      req_clean <- tolower(trimws(req))
      is_match <- (req_clean %in% curr_lower) ||
        any(grepl(paste0("\\b", req_clean, "\\b"), curr_lower)) ||
        any(grepl(req_clean, curr_lower))
      if (!is_match) {
        missing_bands <- c(missing_bands, req)
      }
    }

    if (length(missing_bands) > 0L) {
      stop(sprintf("Missing required band(s) in stack: [%s]. Available bands: [%s].",
                   paste(missing_bands, collapse = ", "),
                   paste(curr_names, collapse = ", ")), call. = FALSE)
    }
  }

  r
}

#' @title Load Multi-Band Raster Stack (Alias)
#' @rdname d4h_read_stack
#' @export
d4h_load_stack <- d4h_read_stack
