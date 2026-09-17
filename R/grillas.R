#' Resumir indicador por grilla
#' @export
# función encargada - recibe capa de raster, tamaño de grilla y descarte de celdas fuera de los márgenes donde voló el drone
resumir_por_grilla <- function(raster_in, tamano_celda = 20, square = TRUE, descartar_na = TRUE) {
  #verifica que sea un tipo adecuado
  if (!inherits(raster_in, "SpatRaster")) {
    stop("raster_in debe ser un SpatRaster.", call. = FALSE)
  }

  limite_sf <- sf::st_as_sf(terra::as.polygons(terra::ext(raster_in), crs = terra::crs(raster_in))) # extrae coordenadas límite del ortomosaico y dentro convierte el área en un polígono, termina convirtiéndolo a objeto sf
  malla_sf <- sf::st_make_grid(limite_sf, cellsize = tamano_celda, square = square) #genera cuadricula de tamaño 20m, son cuadrados, para poner hexágonos square = FALSE

  prefijo <- if (square) "G%04d" else "H%04d"
  malla_sf <- sf::st_sf(
    grid_id = sprintf(prefijo, seq_along(malla_sf)), #asigna id a cada cuadrícula en formato G0001 o H0001
    geometry = malla_sf
  )
  malla_vect <- terra::vect(malla_sf) #convierte el sf a SpatVector para análisis con terra

  resumen_vect <- terra::extract(raster_in, malla_vect, fun = mean, na.rm = TRUE, bind = TRUE) # calcula valores para que obviemos aquellas cuadrículas sin datos del cálculo

  if (descartar_na) {
    nombre_capa <- names(raster_in)[1]
    vals <- resumen_vect[[nombre_capa]][, 1]
    # toma los datos sin info y los excluye del cálculo
    resumen_vect <- resumen_vect[!is.na(vals) & !is.nan(vals) & vals != 0, ]
  }

  return(resumen_vect) #devuelve el objeto limpio para cálculo
}
