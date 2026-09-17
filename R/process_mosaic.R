#' @title End-to-End Drone Mosaic Processing Pipeline
#' @description Computes continuous indices (NDVI, NDWI, TWI), creates zonal grids, and optionally exports results.
#' @param nir Character or SpatRaster. Near-infrared band.
#' @param red Character or SpatRaster. Red band.
#' @param green Character or SpatRaster. Green band (optional).
#' @param dem Character or SpatRaster. DEM/DSM (optional).
#' @param cell_size Numeric. Grid cell size in meters (default: 50).
#' @param square Logical. If TRUE, square grid; if FALSE, hexagonal grid (default: FALSE).
#' @param out_tif Character. Path to output multi-band GeoTIFF file (optional).
#' @param out_csv Character. Path to output CSV file with grid zonal statistics (optional).
#' @return A list containing the SpatRaster stack of indicators and the SpatVector grid summary.
#' @export
d4h_process_mosaic <- function(nir, red, green = NULL, dem = NULL,
                               cell_size = 50, square = FALSE,
                               out_tif = NULL, out_csv = NULL) {
  layers <- list()

  # 1. Spectral indicators
  layers$NDVI <- d4h_ndvi_general(nir, red)

  if (!is.null(green)) {
    layers$NDWI <- d4h_ndwi_general(green, nir)
  }

  if (!is.null(dem)) {
    layers$TWI <- d4h_twi_general(dem)
    if (!is.null(green)) {
      layers$IEV <- d4h_iev_general(ndwi = layers$NDWI, dem = dem)
    }
  }

  # Stack layers
  stack_raster <- terra::rast(layers)

  # 2. Grid zonal summary
  grid_data <- d4h_summarize_grid(stack_raster, cell_size = cell_size, square = square)

  # 3. Export to disk if requested
  if (!is.null(out_tif)) {
    terra::writeRaster(stack_raster, filename = out_tif, overwrite = TRUE)
  }
  if (!is.null(out_csv)) {
    utils::write.csv(as.data.frame(grid_data), file = out_csv, row.names = FALSE)
  }

  list(indicators = stack_raster, grid = grid_data)
}
