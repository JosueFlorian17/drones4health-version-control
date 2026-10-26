# Generate publication figures from real drone orthomosaics and data
library(drones4health)
library(terra)
library(sf)
library(ggplot2)
library(tidyterra)
library(readxl)

message("1. Loading rasters, footprints and house points...")
rgb_m     <- rast("img/Ohuay_RGB_masked.tif")
ndvi_m    <- rast("img/salidas/Ohuay_NDVI_masked.tif")
footprint <- st_read("img/ortho_footprint.gpkg", quiet = TRUE)

houses_df  <- readxl::read_excel("nuevas_casas_localizadas.xlsx")
houses_sf  <- st_as_sf(houses_df, coords = c("lon", "lat"), crs = 4326)
houses_utm <- st_transform(houses_sf, 32718)

# -------------------------------------------------------------
# 1. High-resolution RGB Orthomosaic (Transparent Background)
# -------------------------------------------------------------
message("2. Generating RGB Orthomosaic...")
p_rgb <- ggplot() +
  geom_spatraster_rgb(data = rgb_m, r = 1, g = 2, b = 3) +
  coord_sf(crs = 32718, expand = FALSE) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_blank(),
    panel.grid       = element_line(color = "grey90", linewidth = 0.2),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin      = margin(5, 5, 5, 5)
  )

ggsave("output_figures/png/01_orthomosaic_rgb.png", plot = p_rgb, width = 8, height = 5.5, dpi = 300)
ggsave("output_figures/pdf/01_orthomosaic_rgb.pdf", plot = p_rgb, width = 8, height = 5.5)

# -------------------------------------------------------------
# 2. NDVI Metric Map (Clean Edge, No Orange Outside)
# -------------------------------------------------------------
message("3. Generating Clean NDVI Map...")
p_ndvi <- ggplot() +
  geom_spatraster(data = ndvi_m) +
  scale_fill_gradientn(
    name = "NDVI",
    colors = c("#a50026", "#d73027", "#f46d43", "#fdae61", "#fee08b", "#ffffbf", "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850", "#006837"),
    na.value = "transparent",
    limits = c(-0.5, 1)
  ) +
  coord_sf(crs = 32718, expand = FALSE) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_blank(),
    legend.position  = "right",
    legend.key.height = unit(1.2, "cm"),
    legend.key.width  = unit(0.4, "cm"),
    panel.grid       = element_line(color = "grey90", linewidth = 0.2),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin      = margin(5, 5, 5, 5)
  )

ggsave("output_figures/png/02_metric_ndvi.png", plot = p_ndvi, width = 8, height = 5.5, dpi = 300)
ggsave("output_figures/pdf/02_metric_ndvi.pdf", plot = p_ndvi, width = 8, height = 5.5)

# -------------------------------------------------------------
# 3. Hexagonal Grid & Zonal Statistics (Mean NDVI per Cell)
# -------------------------------------------------------------
message("4. Generating Hex Grid & Zonal Statistics...")
grid_hex <- d4h_hex_grid(ndvi_m, cell_size = 50)
zonal_vect <- d4h_summarize_grid(ndvi_m, cell_size = 50, square = FALSE)
zonal_sf <- st_as_sf(zonal_vect)

p_grid <- ggplot() +
  geom_spatraster_rgb(data = rgb_m, r = 1, g = 2, b = 3, alpha = 0.45) +
  geom_sf(data = zonal_sf, aes(fill = NDVI), color = "grey35", linewidth = 0.2, alpha = 0.85) +
  scale_fill_viridis_c(
    name = "Mean NDVI",
    option = "viridis",
    na.value = "transparent"
  ) +
  coord_sf(crs = 32718, expand = FALSE) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_blank(),
    legend.position  = "right",
    legend.key.height = unit(1.2, "cm"),
    legend.key.width  = unit(0.4, "cm"),
    panel.grid       = element_line(color = "grey90", linewidth = 0.2),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin      = margin(5, 5, 5, 5)
  )

ggsave("output_figures/png/03_hexagonal_grid_zonal_ndvi.png", plot = p_grid, width = 8, height = 5.5, dpi = 300)
ggsave("output_figures/pdf/03_hexagonal_grid_zonal_ndvi.pdf", plot = p_grid, width = 8, height = 5.5)

# -------------------------------------------------------------
# 4. Water Bodies Segmentation & Grid Intersections
# -------------------------------------------------------------
message("5. Generating Water Segmentation & Grid Count...")
water_bodies <- d4h_segment_water(ndvi_m, threshold = -0.15, min_area = 500)
water_inter <- st_intersects(zonal_sf, water_bodies)
zonal_sf$water_count <- lengths(water_inter)

p_water <- ggplot() +
  geom_spatraster_rgb(data = rgb_m, r = 1, g = 2, b = 3, alpha = 0.6) +
  geom_sf(data = zonal_sf, fill = NA, color = "grey40", linewidth = 0.2, linetype = "dashed") +
  geom_sf(data = water_bodies, aes(color = "Water Body"), fill = "#0077b6", alpha = 0.85, linewidth = 0.4) +
  scale_color_manual(name = "Features", values = c("Water Body" = "#00509d")) +
  coord_sf(crs = 32718, expand = FALSE) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_blank(),
    legend.position  = "right",
    panel.grid       = element_line(color = "grey90", linewidth = 0.2),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin      = margin(5, 5, 5, 5)
  )

ggsave("output_figures/png/04_water_segmentation.png", plot = p_water, width = 8, height = 5.5, dpi = 300)
ggsave("output_figures/pdf/04_water_segmentation.pdf", plot = p_water, width = 8, height = 5.5)

# -------------------------------------------------------------
# 5. Focal Household Buffer (150m) & Indicator Map
# -------------------------------------------------------------
message("6. Generating Focal Household Buffer (150m) with NDVI & Water Proximity...")

# 150m buffer surrounding each house
buf_150 <- st_buffer(houses_utm, dist = 150)
buf_union <- st_union(buf_150)
buf_crop <- st_intersection(buf_union, footprint)
buf_sf <- st_sf(geometry = buf_crop)

# Crop & mask NDVI strictly within the 150m house buffers
ndvi_focal <- mask(crop(ndvi_m, vect(buf_sf)), vect(buf_sf))

# Distance to water and epidemiological / proximity classification
houses_prox <- d4h_distance_to_water(
  houses_utm, water_bodies,
  risk_labels = c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)", "Low (>200m)")
)

p_focal_buffer <- ggplot() +
  # 1. Base orthomosaic over entire scene
  geom_spatraster_rgb(data = rgb_m, r = 1, g = 2, b = 3) +
  # 2. Focal NDVI rendered strictly inside the 150m buffer envelope
  geom_spatraster(data = ndvi_focal, alpha = 0.82) +
  scale_fill_viridis_c(
    name = "Focal NDVI",
    option = "viridis",
    na.value = "transparent",
    limits = c(-0.5, 0.9)
  ) +
  # 3. Outer buffer boundary line
  geom_sf(data = buf_sf, fill = NA, color = "black", linewidth = 0.65, linetype = "dashed") +
  # 4. Household points colored by water proximity level
  geom_sf(data = houses_prox, aes(color = proximity_level), size = 2.7) +
  scale_color_manual(
    name = "Epidemiological Priority",
    values = c(
      "Critical (<50m)"     = "#d90429",
      "High (50-100m)"      = "#f48c06",
      "Moderate (100-200m)" = "#ffd166",
      "Low (>200m)"         = "#2b9348"
    ),
    drop = FALSE
  ) +
  coord_sf(crs = 32718, expand = FALSE) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_blank(),
    legend.position  = "right",
    legend.box       = "vertical",
    legend.key.height = unit(1.0, "cm"),
    legend.key.width  = unit(0.4, "cm"),
    panel.grid       = element_line(color = "grey90", linewidth = 0.2),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin      = margin(5, 5, 5, 5)
  )

ggsave("output_figures/png/05_focal_houses_buffer_ndvi.png", plot = p_focal_buffer, width = 9.5, height = 6.5, dpi = 300)
ggsave("output_figures/pdf/05_focal_houses_buffer_ndvi.pdf", plot = p_focal_buffer, width = 9.5, height = 6.5)

# Keep alias for case 4
file.copy("output_figures/png/05_focal_houses_buffer_ndvi.png", "output_figures/png/05_houses_buffers_proximity.png", overwrite = TRUE)
file.copy("output_figures/pdf/05_focal_houses_buffer_ndvi.pdf", "output_figures/pdf/05_houses_buffers_proximity.pdf", overwrite = TRUE)

message("All figures created successfully!")
