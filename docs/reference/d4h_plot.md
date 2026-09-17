# Visualización cartográfica con ggplot2

Grafica capas ráster (SpatRaster) o grillas zonales (SpatVector / sf)
con ggplot2. Omite el área fuera del vuelo del dron y permite superponer
grillas.

## Usage

``` r
d4h_plot(
  x,
  grilla = NULL,
  paleta = "viridis",
  limites = NULL,
  titulo = NULL,
  max_pixels = 5e+05
)
```

## Arguments

- x:

  Objeto SpatRaster o SpatVector a graficar.

- grilla:

  Objeto SpatVector o sf opcional para superponer bordes de malla.

- paleta:

  Opciones: "viridis", "magma", "terrain" o vector de colores.

- limites:

  Vector numérico c(min, max) para fijar la escala de color.

- titulo:

  Título del gráfico.

- max_pixels:

  Número máximo de píxeles a muestrear para visualización ágil (default:
  500000).

## Value

Objeto ggplot.
