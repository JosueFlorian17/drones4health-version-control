# Convert Thermal Band to Celsius

Calibrates a raw thermal infrared band to Land Surface Temperature (LST)
in degrees Celsius.

## Usage

``` r
d4h_thermal_to_celsius(thermal_raster, gain = 0.01, offset = -273.15)
```

## Arguments

- thermal_raster:

  SpatRaster. The thermal band.

- gain:

  Numeric. Calibration gain multiplier.

- offset:

  Numeric. Calibration offset value.

## Value

A SpatRaster representing temperature in Celsius.
