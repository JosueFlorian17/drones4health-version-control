#' @title End-to-End Drone Mosaic Processing Pipeline
#' @description Computes continuous indices (NDVI, NDWI, TWI, IEV), creates zonal grids, and optionally exports results.
#' @param nir SpatRaster or character. Near-infrared band or path to file.
#' @param red SpatRaster or character. Red band or path to file.
#' @param green SpatRaster or character. Green band or path to file (optional).
#' @param dem SpatRaster or character. DEM/DSM or path to file (optional).
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

  layers$NDVI <- d4h_ndvi(nir, red)

  if (!is.null(green)) {
    layers$NDWI <- d4h_ndwi(green, nir)
  }

  if (!is.null(dem)) {
    layers$TWI <- d4h_twi(dem)
    if (!is.null(green)) {
      layers$IEV <- d4h_iev(delta_ndwi = layers$NDWI, slope_dsm = d4h_slope(dem))
    }
  }

  stack_raster <- terra::rast(layers)
  grid_data <- d4h_summarize_grid(stack_raster, cell_size = cell_size, square = square)

  if (!is.null(out_tif)) {
    terra::writeRaster(stack_raster, filename = out_tif, overwrite = TRUE)
  }
  if (!is.null(out_csv)) {
    utils::write.csv(as.data.frame(grid_data), file = out_csv, row.names = FALSE)
  }

  list(indicators = stack_raster, grid = grid_data)
}
