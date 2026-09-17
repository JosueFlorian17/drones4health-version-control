#' @title Normalized Difference Vegetation Index (NDVI)
#' @description Calculates NDVI to measure vegetation vigor.
#' @param nir SpatRaster. Near-infrared band.
#' @param red SpatRaster. Red band.
#' @return A SpatRaster containing NDVI values.
#' @export
d4h_ndvi <- function(nir, red) {
  (nir - red) / (nir + red)
}

#' @title Soil Adjusted Vegetation Index (SAVI)
#' @description Calculates SAVI, correcting for soil brightness.
#' @param nir SpatRaster. Near-infrared band.
#' @param red SpatRaster. Red band.
#' @param l_factor Numeric. Soil brightness correction factor.
#' @return A SpatRaster containing SAVI values.
#' @export
d4h_savi <- function(nir, red, l_factor = 0.5) {
  ((nir - red) / (nir + red + l_factor)) * (1 + l_factor)
}

#' @title Enhanced Vegetation Index (EVI)
#' @description Calculates EVI for areas with dense canopy background.
#' @param nir SpatRaster. Near-infrared band.
#' @param red SpatRaster. Red band.
#' @param blue SpatRaster. Blue band.
#' @param g_factor Numeric. Gain factor.
#' @param c1 Numeric. Aerosol resistance coefficient 1.
#' @param c2 Numeric. Aerosol resistance coefficient 2.
#' @param l_factor Numeric. Canopy background adjustment.
#' @return A SpatRaster containing EVI values.
#' @export
d4h_evi <- function(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1) {
  g_factor * ((nir - red) / (nir + (c1 * red) - (c2 * blue) + l_factor))
}

#' @title Normalized Difference Water Index (NDWI)
#' @description Calculates NDWI to identify water bodies and surface moisture.
#' @param green SpatRaster. Green band.
#' @param nir SpatRaster. Near-infrared band.
#' @return A SpatRaster containing NDWI values.
#' @export
d4h_ndwi <- function(green, nir) {
  (green - nir) / (green + nir)
}

#' @title Normalized Difference Red Edge Index (NDRE)
#' @description Calculates NDRE using the Red Edge band.
#' @param nir SpatRaster. Near-infrared band.
#' @param red_edge SpatRaster. Red Edge band.
#' @return A SpatRaster containing NDRE values.
#' @export
d4h_ndre <- function(nir, red_edge) {
  (nir - red_edge) / (nir + red_edge)
}

#' @title Green Normalized Difference Vegetation Index (GNDVI)
#' @description Calculates GNDVI for chlorophyll concentration estimation.
#' @param nir SpatRaster. Near-infrared band.
#' @param green SpatRaster. Green band.
#' @return A SpatRaster containing GNDVI values.
#' @export
d4h_gndvi <- function(nir, green) {
  (nir - green) / (nir + green)
}

#' @title Difference Vegetation Index (DVI)
#' @description Calculates DVI.
#' @param nir SpatRaster. Near-infrared band.
#' @param red SpatRaster. Red band.
#' @return A SpatRaster containing DVI values.
#' @export
d4h_dvi <- function(nir, red) {
  nir - red
}

#' @title Corrected Transformed Vegetation Index (CTVI)
#' @description Calculates CTVI to normalize vegetation distributions.
#' @param ndvi_raster SpatRaster. NDVI input layer.
#' @return A SpatRaster containing CTVI values.
#' @export
d4h_ctvi <- function(ndvi_raster) {
  (ndvi_raster + 0.5) / sqrt(abs(ndvi_raster + 0.5))
}

#' @title Bare Soil Mask
#' @description Generates a binary mask of bare or exposed soil based on an NDVI threshold.
#' @param ndvi_raster SpatRaster. NDVI input layer.
#' @param threshold Numeric. Value below which pixels are classified as bare soil.
#' @return A binary SpatRaster (1 = bare soil, 0 = vegetation/water).
#' @export
d4h_bare_soil <- function(ndvi_raster, threshold = 0.15) {
  terra::ifel(ndvi_raster < threshold, 1, 0)
}
