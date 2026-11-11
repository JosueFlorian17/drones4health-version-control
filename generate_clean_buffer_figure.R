library(drones4health)
library(terra)
library(sf)
library(ggplot2)
library(tidyterra)
library(readxl)
library(ggspatial)

cat("1. Loading layers...\n")
rgb_m <- rast("img/Ohuay_RGB_masked.tif")
footprint <- st_read("img/ortho_footprint.gpkg", quiet = TRUE)
houses_df <- readxl::read_excel("nuevas_casas_localizadas.xlsx")
houses_sf <- st_as_sf(houses_df, coords = c("lon", "lat"), crs = 4326)
houses_utm <- st_transform(houses_sf, 32718)
r_ndvi <- rast("img/salidas/Ohuay_NDVI_masked.tif")

cat("2. Generating 75m buffer (half of 150m) and masking...\n")
buf_75 <- st_buffer(houses_utm, dist = 75)
buf_union <- st_union(buf_75)
buf_crop <- st_intersection(buf_union, footprint)
buf_sf <- st_sf(geometry = buf_crop)

ndvi_focal <- mask(crop(r_ndvi, vect(buf_sf)), vect(buf_sf))

cat("3. Calculating water proximity...\n")
water_bodies <- d4h_segment_water(r_ndvi, threshold = -0.15, min_area = 500)
houses_prox <- d4h_distance_to_water(
  houses_utm, water_bodies,
  risk_labels = c("Critical (<50m)", "High (50-100m)", "Moderate (100-200m)", "Low (>200m)")
)

cat("4. Building ggplot with no bounding box...\n")
p_focal_buffer <- ggplot() +
  geom_spatraster_rgb(data = rgb_m, r = 1, g = 2, b = 3) +
  geom_spatraster(data = ndvi_focal) +
  scale_fill_viridis_c(
    name = "Focal NDVI",
    option = "viridis",
    na.value = "transparent",
    limits = c(-0.5, 0.9)
  ) +
  geom_sf(data = buf_sf, fill = NA, color = "black", linewidth = 0.65, linetype = "dashed") +
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
  ) +
  annotation_north_arrow(
    location = "tr", which_north = "true",
    style = north_arrow_fancy_orienteering(text_size = 8),
    height = unit(1.2, "cm"), width = unit(1.2, "cm"),
    pad_x = unit(0.3, "cm"), pad_y = unit(0.3, "cm")
  ) +
  annotation_scale(
    location = "bl", width_hint = 0.25,
    pad_x = unit(0.3, "cm"), pad_y = unit(0.3, "cm")
  )

cat("5. Saving to 05_focal_houses_buffer_ndvi.png...\n")
ggsave("man/figures/05_focal_houses_buffer_ndvi.png", plot = p_focal_buffer, width = 9.5, height = 6.5, dpi = 300)
ggsave("docs/reference/figures/05_focal_houses_buffer_ndvi.png", plot = p_focal_buffer, width = 9.5, height = 6.5, dpi = 300)
cat("Done successfully!\n")
