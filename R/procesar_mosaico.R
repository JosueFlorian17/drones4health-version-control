# Este script conecta las fases del cálculo, grids y exportación
#' @param nir SpatRaster o ruta a la banda NIR.
#' @param red SpatRaster o ruta a la banda Red.
#' @param tamano_grilla Tamaño de celda en metros (default: 20).
#' @param out_tif Ruta GeoTIFF de salida (opcional).
#' @param out_csv Ruta CSV de salida (opcional).
#' @return Lista con el SpatRaster NDVI y el SpatVector de la grilla.
#' @export
procesar_mosaico_ndvi <- function(nir, red, tamano_grilla = 20,
                                  out_tif = NULL, out_csv = NULL) {
  capa_ndvi <- d4h_ndvi(nir, red) #para cálculo de NDVI
# recibe bandas de cálculo, tamaño de grilla y posibles rutas de exportación de los outputs
  grilla_datos <- resumir_por_grilla(capa_ndvi, tamano_celda = tamano_grilla)

  if (!is.null(out_tif)) {
    terra::writeRaster(capa_ndvi, filename = out_tif, overwrite = TRUE)
  }
  if (!is.null(out_csv)) {
    utils::write.csv(as.data.frame(grilla_datos), file = out_csv, row.names = FALSE)
  }

  return(list(ndvi = capa_ndvi, grilla = grilla_datos))
}

#' Pipeline multivariado: Cálculo conjunto de NDVI y SAVI, grilla zonal y exportación
#' @export
procesar_mosaico_multivariado <- function(nir, red, tamano_grilla = 50, square = FALSE,
                                          out_tif = NULL, out_csv = NULL) {
  # 1. Cálculo calibrado de NDVI y SAVI
  capa_ndvi <- d4h_ndvi(nir, red)
  capa_savi <- d4h_savi(nir, red)

  # 2. Apilar ambas capas en un único SpatRaster
  stack_indicadores <- c(capa_ndvi, capa_savi)
  names(stack_indicadores) <- c("NDVI", "SAVI")

  # 3. Resumir indicadores por grilla
  grilla_datos <- resumir_por_grilla(stack_indicadores, tamano_celda = tamano_grilla, square = square)

  # 4. Exportación opcional a disco
  if (!is.null(out_tif)) {
    terra::writeRaster(stack_indicadores, filename = out_tif, overwrite = TRUE)
  }
  if (!is.null(out_csv)) {
    utils::write.csv(as.data.frame(grilla_datos), file = out_csv, row.names = FALSE)
  }

  return(list(indicadores = stack_indicadores, grilla = grilla_datos))
}
