# Convert Thermal Band to Celsius

Calibrates a raw thermal infrared band to Land Surface Temperature (LST)
in degrees Celsius.

## Usage

``` r
d4h_thermal_to_celsius(thermal_raster, gain = 0.01, offset = -273.15)
```

## Arguments

- thermal_raster:

  SpatRaster or character. Thermal band or path to file.

- gain:

  Numeric. Calibration gain multiplier (default: 0.01).

- offset:

  Numeric. Calibration offset value (default: -273.15).

## Value

A SpatRaster representing temperature in degrees Celsius.

## Examples

``` r
# \donttest{
if (interactive()) {
  library(drones4health)
  library(terra)

  # Path to raw radiometric thermal band
  therm_file <- system.file("extdata", "thermal_raw.tif", package = "drones4health")

  # Calibrate raw thermal digital numbers to Celsius Land Surface Temperature
  r_lst <- d4h_thermal_to_celsius(thermal_raster = therm_file, gain = 0.01, offset = -273.15)
  print(r_lst)
}
# }
```
