Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")

suppressPackageStartupMessages({
  library(drones4health)
  library(terra)
  library(leaflet)
  library(leaflet.extras2)
  library(htmlwidgets)
})

cat("=== 1. Cargando bandas multiespectrales de Ohuay ===\n")
path_nir <- "img/Ohuay_NIR.tif"
path_r   <- "img/Ohuay_R.tif"

cat("=== 2. Calculando indices espectrales con funciones internas ===\n")
r_ndvi   <- d4h_ndvi(nir = path_nir, red = path_r)
r_msavi2 <- d4h_msavi2(nir = path_nir, red = path_r)

# Guardar r_msavi2 si no existe para acelerar reutilizacion
if (!file.exists("img/salidas/Ohuay_MSAVI2.tif")) {
  cat("Guardando Ohuay_MSAVI2.tif para cache futuro...\n")
  terra::writeRaster(r_msavi2, "img/salidas/Ohuay_MSAVI2.tif", overwrite = TRUE)
}

cat("=== 3. Creando visor interactivo swipe con d4h_mapview_swipe ===\n")
visor_swipe <- d4h_mapview_swipe(
  x          = r_ndvi,
  y          = r_msavi2,
  grid       = NULL,
  basemap    = TRUE,
  col_x      = "viridis",
  col_y      = "magma",
  limits_x   = c(-0.1, 0.9),
  limits_y   = c(0.0, 0.8),
  max_pixels = 500000
)

# Exportar HTML
out_dir <- file.path(getwd(), "salidas")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

html_file <- file.path(out_dir, "swipe_ndvi_msavi2.html")
cat("Guardando HTML en:", html_file, "\n")
htmlwidgets::saveWidget(visor_swipe, file = html_file, selfcontained = FALSE)

cat("=== Completado con exito ===\n")
