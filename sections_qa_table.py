# -*- coding: utf-8 -*-
"""
Preguntas Clave de Examen Técnico y Mega Tabla de drones4health
Actualizado con las funciones activas y optimizadas.
"""

QUESTIONS_AND_ANSWERS = [
    {
        "q": "1. ¿Por qué el paquete modela el riesgo de exposición mediante decaimiento exponencial exp(-d/λ) en lugar de distancia euclidiana lineal?",
        "a": "El vuelo y dispersión de mosquitos (como Aedes aegypti y Anopheles) desde su criadero natal no sigue una relación lineal. La probabilidad de que una hembra llegue a una vivienda decae exponencialmente debido a la mortalidad natural durante el vuelo, la presencia de barreras físicas (muros, árboles) y la satisfacción de su necesidad de alimentación sanguínea en los primeros hospedadores que encuentra. La función exp(-d/λ) es el modelo estándar de dispersión biológica en epidemiología (Guerra et al., WHO). Si d = 0m, el score es 1.0 (riesgo crítico máximo); si d = λ (100m), el score cae a exp(-1) ≈ 0.368; y a distancias > 200m cae por debajo de 0.13. Una distancia lineal penalizaría erróneamente de forma constante cada metro, ignorando que los primeros 50 metros concentran más del 80% del contacto vector-humano."
    },
    {
        "q": "2. ¿Qué ocurre internamente si las bandas de entrada tienen discrepancias en resolución, extensión o número de filas/columnas?",
        "a": "En la mayoría de paquetes de R, realizar álgebra matricial (nir - red) con rásters de geometrías dispares arroja un error fatal inmediato de R: 'different extent or resolution'. drones4health resuelve esto transparentemente mediante los helpers internos '.match_pair()' y '.match_multi()'. Estos helpers ejecutan primero 'terra::compareGeom(stopOnError = FALSE)'. Si detectan diferencias, primero verifican el CRS (y si difieren, proyectan la banda secundaria al CRS de referencia con terra::project) y luego ejecutan 'terra::resample(sub, ref, method = 'bilinear')' para igualar exactamente la resolución y cuadrícula celda por celda antes de realizar cualquier resta o división. Esto garantiza robustez total ante imágenes de cámaras multiespectrales multiobjetivo."
    },
    {
        "q": "3. ¿Por qué se utiliza MSAVI2 en lugar de NDVI en asentamientos rurales o periurbanos con calles de tierra?",
        "a": "El NDVI clásico asume implícitamente que el sustrato de fondo es neutro. Sin embargo, en zonas rurales o comunidades amazónicas/tropicales con baja cobertura vegetal (<30-40%) y predominio de suelo desnudo, arcillas o arena, la reflectancia del suelo altera fuertemente la curva espectral: la 'línea de suelo' desplaza los valores de NDVI haciéndolos parecer más bajos de lo que realmente son o introduciendo artefactos. Mientras que el SAVI requiere un factor empírico 'L' fijo (típicamente 0.5), el MSAVI2 (Modified Soil-Adjusted Vegetation Index 2 de Qi et al., 1994) utiliza una deducción matemática inductiva de segundo orden que ajusta dinámicamente el efecto del brillo del suelo sin requerir calibración manual, permitiendo medir el verdadero verdor peridomiciliario."
    },
    {
        "q": "4. ¿Cómo soluciona el paquete la confusión espectral entre techos de calamina/zinc y cuerpos de agua al calcular NDWI?",
        "a": "Tanto los techos metálicos brillantes (zinc, chapa, calamina galvanizada) como el agua tienen valores de reflectancia muy bajos en el infrarrojo cercano (NIR) en comparación con el visible, lo que genera valores de NDWI positivos o NDVI negativos que engañan a los clasificadores automáticos convencionales. drones4health soluciona este falso positivo crítico mediante un FILTRO ÓPTICO DE OSCURIDAD en 'd4h_segment_water()': el agua natural absorbe fuertemente la luz visible (es oscura, con brillo RGB medio habitualmente < 80-95 en escala de 0 a 255), mientras que los techos de calamina son especulares y altamente reflectantes (brillo RGB > 150-200). La función exige que (NDWI > 0) Y simultáneamente (Brillo_RGB <= max_water_brightness = 95.0), descartando el 100% de los techos brillantes."
    },
    {
        "q": "5. ¿Por qué se aplica una agregación espacial piramidal antes de vectorizar polígonos o ejecutar SAM?",
        "a": "Un ortomosaico de dron con 100 millones de celdas a 3 cm/píxel que contenga micro-ruido de agua o vegetación generaría millones de micro-polígonos de 1 o 2 píxeles si se vectorizara directamente con 'as.polygons()'. Esto provocaría un desbordamiento de memoria RAM C++ (std::bad_alloc) y colapsaría la sesión de R. 'd4h_segment_water()' y 'd4h_segment_buildings()' monitorean el conteo celular: si total_px supera 3 millones (o 100 millones en edificios), calculan un factor de agregación: agg_fact = ceiling(sqrt(total_px / límite)) y ejecutan 'terra::aggregate(fact = agg_fact, fun = 'max')'. Esto fusiona píxeles vecinos en bloques más manejables preservando la topología de los objetos mayores antes de la vectorización en R o la inferencia de tensores en PyTorch."
    },
    {
        "q": "6. ¿Cuál es la diferencia entre un SpatRaster (terra) y un RasterLayer (raster) y por qué se usan ambos?",
        "a": "'SpatRaster' es la clase moderna de 'terra'. No guarda los millones de píxeles en la memoria del intérprete de R, sino que mantiene un puntero en C++ a un archivo virtual o en disco, ejecutando operaciones en C++ de alta velocidad. 'RasterLayer' es la clase antigua de 'raster' (en desuso, lenta y con alto overhead). El paquete utiliza 'SpatRaster' para el 100% de sus cálculos biofísicos y espaciales internos. Sin embargo, paquetes de visualización web como 'mapview' y 'leaflet.extras2' aún no han migrado completamente a 'terra' y esperan internamente un objeto 'RasterLayer'. Por ello, exclusivamente dentro de 'd4h_plot(interactive = TRUE)' y 'd4h_mapview_swipe()', el resultado optimizado se convierte temporalmente con 'raster::raster()' solo para renderizar el widget HTML."
    },
    {
        "q": "7. ¿Qué valores vienen leídos de los metadatos del GeoTIFF y qué variables deben ser calculadas?",
        "a": "Los metadatos del GeoTIFF (leídos por GDAL/terra) contienen exclusivamente propiedades físicas del archivo: dimensiones de la cuadrícula (filas, columnas, ncell), resolución espacial (res), coordenadas de la caja envolvente (ext: xmin, xmax, ymin, ymax), definición de proyección (crs), número de capas (nlyr), tipo de dato numérico (datatype: ej. entero de 16 bits sin signo) y el valor numérico asignado a NoData. Todo lo demás es CALCULADO por drones4health: la calibración a reflectancia (0 a 1), los índices espectrales (NDVI, NDWI, etc.), la pendiente y TWI, las estadísticas descriptivas globales y zonales, los cuartiles y vallas de outliers de Tukey, el área real en hectáreas (multiplicando celdas válidas por el área de píxel), las distancias euclidianas, los scores de riesgo exponencial y los porcentajes de cobertura por celda."
    },
    {
        "q": "8. ¿Cómo logra d4h_indicator_buffer() un ahorro de tiempo y memoria del 90%?",
        "a": "En lugar de calcular el índice espectral (ej. NDVI o TWI) sobre todo el ortomosaico de 100 hectáreas para luego recortar el resultado, 'd4h_indicator_buffer()' invierte el orden del flujo de trabajo: (1) Carga las coordenadas GPS de las casas, (2) calcula el polígono de buffer acumulado (ej. 150m) alrededor de las viviendas, (3) extrae el bounding box del buffer focal, y (4) RECORTA LAS BANDAS CRUDAS INDIVIDUALES (NIR, Red, etc.) con 'terra::crop()' ANTES DE OPERARLAS. El álgebra matricial se ejecuta únicamente sobre una sub-matriz pequeña (ej. 2 hectáreas). Esto reduce la carga matricial en más de un 90%, permitiendo que el análisis tome 2 segundos en lugar de varios minutos."
    },
    {
        "q": "9. ¿Cuál es la base matemática de las vallas de Tukey en d4h_executive_summary() frente a la media ± 3SD?",
        "a": "En teledetección de alta resolución, los datos rara vez siguen una distribución normal gaussiana: suelen ser bimodales o altamente asimétricos (por ejemplo, el NDWI tiene una masa enorme de valores negativos para vegetación/suelo y una cola pequeña de valores positivos para agua). La media y la desviación estándar son extremadamente sensibles a valores extremos: un charco muy frío o una calamina muy brillante arrastran la media y distorsionan la varianza. El método de John Tukey utiliza medidas resistentes basadas en rangos: Q25 (percentil 25), Q75 (percentil 75) y el Rango Intercuartílico IQR = Q75 - Q25. Las vallas Q25 - 1.5*IQR y Q75 + 1.5*IQR detectan anomalías verdaderas de forma robusta e invariante a la forma de la distribución."
    },
    {
        "q": "10. ¿Por qué preferir hexágonos (d4h_hex_grid) sobre cuadrículas rectangulares en vigilancia entomológica?",
        "a": "Primero, por ISOTROPÍA: un hexágono regular tiene 6 vecinos adyacentes a exactamente la misma distancia centroide a centroide (d = 2*apotema), mientras que en un cuadrado los vecinos diagonales están 1.414 veces más lejos que los ortogonales, distorsionando los análisis de autocorrelación espacial o difusión. Segundo, por RELACIÓN PERÍMETRO/ÁREA: el hexágono encierra la mayor superficie con el menor perímetro posible entre todas las teselaciones regulares del plano, minimizando el corte artificial de viviendas o criaderos en los bordes. Tercero, porque la dispersión de mosquitos a partir de un cuerpo de agua es biológicamente omnidireccional (radial), asemejándose a un círculo que se empaqueta óptimamente como hexágonos."
    },
    {
        "q": "11. ¿Para qué sirve el parámetro ε (epsilon = 0.001) en las fórmulas de índices?",
        "a": "En índices como VARI, EVI, TWI, IEV, IMSR, IRTS e IFEB, el denominador incluye sumas, diferencias o pendientes. Si dos bandas tienen valores idénticos o si el terreno es completamente plano (pendiente = 0°), el denominador se vuelve cero exacto. En computación matricial, dividir un número positivo por cero genera infinito (Inf), y dividir cero por cero genera NaN (Not a Number). La adición de una constante minúscula de estabilización (ε = 0.001) previene la discontinuidad por división por cero sin alterar en absoluto el valor biofísico de la métrica en celdas normales."
    },
    {
        "q": "12. ¿Cómo se comunican R y Python cuando se ejecuta method = 'sam' y cómo gestiona los pesos (.pth)?",
        "a": "El paquete utiliza 'reticulate' como puente de interoperabilidad. Cuando el usuario invoca 'method = sam': (1) R localiza los pesos del Vision Transformer mediante '.d4h_get_sam_checkpoint()'; si el usuario no los especificó y no existen localmente, los descarga automáticamente desde los servidores oficiales de Meta (~375 MB) a la carpeta interna de caché persistente de 'drones4health' (tools::R_user_dir('drones4health', 'cache')), liberando al usuario de cualquier configuración manual; (2) inicializa el modelo en CPU o GPU (CUDA) según disponibilidad; (3) convierte el ortomosaico RGB en un array NumPy 3D [H, W, 3] en uint8 [0, 255]; (4) 'SamAutomaticMaskGenerator' procesa los tensores en Python generando máscaras booleanas binarias; (5) R recupera las máscaras, las vectoriza con 'terra::as.polygons()' asignándoles el CRS del ortomosaico, y filtra candidatos usando exclusivamente min_area_m2, max_area_m2 y exclude_buildings."
    },
    {
        "q": "13. ¿Por qué se aplica una erosión perimetral de -15 metros (buffer_m = -15.0) en la segmentación?",
        "a": "En fotogrametría con drones (procesamiento Structure-from-Motion en software como Pix4D, Metashape u OpenDroneMap), los bordes exteriores del ortomosaico tienen un traslape fotográfico muy bajo (overlap < 2 imágenes). Esto genera severos artefactos de stitching, sombras difusas y aberraciones cromáticas que los algoritmos clasifican erróneamente como charcos de agua o estructuras construidas. La función '.d4h_clean_flight_footprint(buffer_m = -15.0)' extrae el polígono global del vuelo y le aplica un buffer negativo (erosión) de 15 metros hacia adentro, eliminando la franja perimetral de baja calidad fotogramétrica y garantizando que solo se reporten objetos en la zona de alta fidelidad."
    },
    {
        "q": "14. ¿Qué estructura multi-hoja generan d4h_export_summary() y d4h_grid_composition() en Excel?",
        "a": "'d4h_export_summary()' genera un libro con hasta 5 pestañas organizadas jerárquicamente: (1) 'Global_Summary': visión panorámica con resolución, área en ha, píxeles válidos, momentos estadísticos completos y percentiles; (2) 'Thematic_Strata': desglose por rangos biofísicos con porcentaje de cobertura y hectáreas netas; (3) 'Outliers_Diagnostics': umbrales de Tukey, conteo de anomalías y diagnóstico; (4) 'Household_Water_Proximity': tabla individualizada por casa con coordenadas, distancia al agua más cercana, ID del charco, score y nivel de riesgo; (5) 'Household_Proximity_Summary': resumen agregado de viviendas por estrato de proximidad. Por su parte, 'd4h_grid_composition()' exporta 'Grid_Composition' (perfil de coberturas por celda), 'Priority_Stratification' (estratificación de vigilancia) y 'Global_Class_Distribution'."
    },
    {
        "q": "15. ¿Cómo se interpreta el índice IEV en relación con la topografía y la ecología de larvas?",
        "a": "El Índice de Vulnerabilidad al Estancamiento (IEV = NDWI × (1 / (Pendiente + ε))) fusiona dos factores ecológicos determinantes: la presencia de agua líquida o humedad superficial (medida espectralmente por NDWI) y la incapacidad gravitacional de escurrimiento (medida topográficamente por la inversa de la pendiente). Si un punto tiene alto contenido de agua pero está en una ladera con 20° de inclinación, el agua escorrentía rápidamente hacia abajo y las larvas son arrastradas o el charco desaparece en horas. En cambio, si el NDWI es alto y la pendiente es menor a 2°, el factor inverso se dispara (1/0.05 = 20), resultando en un valor de IEV altísimo (>8.0). Esto demarca micro-trampas de agua estancada permanente donde el ciclo larval de 7 a 10 días puede completarse con éxito."
    }
]

MEGA_TABLE_DATA = [
    ["d4h_read_stack()", "file_path (str/SpatRaster)", "required_bands, band_names", "terra::SpatRaster", "Validación conjuntista y verificación nlyr > 0", "Ingestión y control de calidad"],
    ["d4h_normalize_reflectance()", "raster_layer (SpatRaster/str)", "scale_factor = 65535", "terra::SpatRaster", "clamp(DN / scale_factor, 0, 1)", "Calibración radiométrica"],
    ["d4h_thermal_to_celsius()", "thermal_raster (SpatRaster/str)", "gain = 0.01, offset = -273.15", "terra::SpatRaster", "(DN × gain) + offset", "Conversión LST térmica"],
    ["d4h_ndvi()", "nir, red (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "(NIR - Red) / (NIR + Red)", "Biomasa y vigor vegetal"],
    ["d4h_dvi()", "nir, red (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "NIR - Red", "Diferencia lineal de vegetación"],
    ["d4h_savi()", "nir, red (SpatRaster/str)", "l_factor = 0.5", "terra::SpatRaster", "((NIR - Red)/(NIR + Red + L)) × (1 + L)", "Vegetación en suelo descubierto"],
    ["d4h_msavi2()", "nir, red (SpatRaster/str)", "Ninguno (auto-16bit)", "terra::SpatRaster", "(2NIR + 1 - √((2NIR+1)² - 8(NIR-Red))) / 2", "Canopia en áreas semiáridas"],
    ["d4h_vari()", "green, red, blue (SpatRaster/str)", "eps = 0.001", "terra::SpatRaster", "(Green - Red) / (Green + Red - Blue + ε)", "Vegetación visible RGB"],
    ["d4h_evi()", "nir, red, blue (SpatRaster/str)", "g=2.5, c1=6, c2=7.5, l=1", "terra::SpatRaster", "G × ((NIR - Red)/(NIR + C1*Red - C2*Blue + L))", "Canopia de alta densidad"],
    ["d4h_ndwi()", "green, nir (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "(Green - NIR) / (Green + NIR)", "Detección de agua superficial"],
    ["d4h_ndre()", "nir, red_edge (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "(NIR - RedEdge) / (NIR + RedEdge)", "Clorofila en dosel maduro"],
    ["d4h_gndvi()", "nir, green (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "(NIR - Green) / (NIR + Green)", "Clorofila y micro-algas en agua"],
    ["d4h_ctvi()", "ndvi_raster (SpatRaster/str)", "Ninguno", "terra::SpatRaster", "(NDVI + 0.5) / √( |NDVI + 0.5| )", "Normalización asimétrica"],
    ["d4h_bare_soil()", "ndvi_raster (SpatRaster/str)", "threshold = 0.15", "terra::SpatRaster (binario)", "ifel(NDVI < threshold, 1, 0)", "Máscara de suelo desnudo"],
    ["d4h_slope()", "dem_raster (SpatRaster/str)", "unit = 'degrees'/'radians'", "terra::SpatRaster", "arctan( √((∂z/∂x)² + (∂z/∂y)²) )", "Micro-pendiente del terreno"],
    ["d4h_twi()", "dem_raster (SpatRaster/str)", "eps = 0.001", "terra::SpatRaster", "ln( (flow_acc + 1) / (tan(slope) + ε) )", "Potencial de encharcamiento"],
    ["d4h_imsr()", "red_edge, red, nir", "veg_threshold = 0.2", "terra::SpatRaster", "|NDRE_approx - θ_veg| × NIR_norm", "Residuos plásticos y criaderos"],
    ["d4h_irts()", "ndre, lst_local, lst_surr, nir", "eps = 0.001", "terra::SpatRaster", "(NDRE × (LST_surr - LST_loc)) / (NIR + ε)", "Refugios térmicos y sombra"],
    ["d4h_iev()", "delta_ndwi, slope_dsm", "eps = 0.001", "terra::SpatRaster", "NDWI × (1 / (Slope + ε))", "Vulnerabilidad a estancamiento"],
    ["d4h_iec()", "gndvi_water, lst", "t_opt = 25", "terra::SpatRaster", "GNDVI_agua × (1 - (|LST - T_opt|/T_opt))", "Estratificación térmica larvaria"],
    ["d4h_iead()", "grad_delta_ndvi, depr, red_edge", "Ninguno", "terra::SpatRaster", "∇(ΔNDVI) × Depresiones × RedEdge", "Estancamiento en desmonte"],
    ["d4h_irhe()", "green, nir, lst", "eps = 0.001", "terra::SpatRaster", "NDWI × (1 / (LST + ε))", "Retención hídrica en época seca"],
    ["d4h_ifeb()", "grad_red_edge, red, nir", "eps = 0.001", "terra::SpatRaster", "|∇(RedEdge)| × (Red / (NIR + ε))", "Efecto de borde y ecotonos"],
    ["d4h_irih()", "var_re_nir, red, green", "eps = 0.001", "terra::SpatRaster", "Var(RedEdge/NIR) × (Red / (Green + ε))", "Rugosidad en interfaz bosque-casa"],
    ["d4h_segment_water()", "raster_in (NDWI/NDVI)", "rgb_raster, threshold=NULL, is_ndwi=NULL, sam", "sf (POLYGON)", "Autodetección NDWI/NDVI + Brillo ≤ 95 + OBIA/SAM", "Delineación vectorial de agua"],
    ["d4h_segment_buildings()", "rgb_raster (RGB 3 bandas)", "ndvi_raster, min/max_area", "sf (POLYGON)", "Brillo ≥ 135 + Teja_Rojo + NDVI < 0.25", "Delineación vectorial de casas"],
    ["d4h_distance_to_water()", "buildings (sf), sources (sf)", "decay_lambda = 100, breaks", "sf (POLYGON/POINT)", "exp( - Distancia_Euclidiana / λ )", "Exposición y distancia a agua"],
    ["d4h_raster_distance()", "sources (sf), raster_ref", "Ninguno", "terra::SpatRaster", "Transformada de distancia euclidiana C++", "Superficie continua de proximidad"],
    ["d4h_hex_grid()", "aoi (SpatRaster/sf/str)", "cell_size = 50, clip=TRUE", "terra::SpatVector", "sf::st_make_grid(square = FALSE)", "Malla hexagonal de vigilancia"],
    ["d4h_summarize_grid()", "raster_in (SpatRaster)", "cell_size = 20, square, general", "terra::SpatVector", "Media zonal celular o huella general", "Estadísticas zonales o comunales"],
    ["d4h_grid_distance_to_water()", "grid (sf/SpatVector), water", "decay_lambda = 100", "sf (POLYGON)", "exp( - Distancia_Borde_Celda / λ )", "Prioridad sectorial de celdas"],
    ["d4h_grid_composition()", "grid, water, buildings, ndvi", "veg_th=0.3, soil_th=0.15", "sf (POLYGON)", "Intersección espacial de áreas en m² (%)", "Perfil porcentual de coberturas"],
    ["d4h_indicator_buffer()", "houses (CSV/sf), indicator", "radius=3, cell_size=50", "d4h_buffer_analysis (S3)", "Crop(Bandas, BBox(Buffer)) + Cálculo", "Análisis focal acelerado 90%"],
    ["d4h_list_metrics()", "category (opcional)", "Filtra dinámicamente namespace", "tbl_df (tibble)", "Catálogo dinámico de 21 métricas", "Inspección interactiva de métricas"],
    ["d4h_executive_summary()", "raster_in, by='general'/'grid'", "grid, houses, out_xlsx", "d4h_executive_summary (S3)", "Tukey Fences (1.5*IQR) + Estratos (ha)", "Informe ejecutivo y Excel multi-hoja"],
    ["d4h_export_summary()", "x (d4h_executive_summary)", "out_xlsx", "Invisibly x", "writexl / openxlsx (5 pestañas)", "Exportación a libro Excel"],
    ["d4h_plot()", "x, y=NULL, interactive, general", "water, houses/buildings, ortho, grid", "ggplot / mapview (htmlwidget)", "ggplot2 + tidyterra / leaflet swipe multicapa", "Visualización multicapa integrada (orto + agua + casas)"],
    ["d4h_mapview_swipe()", "x, y, grid, basemap", "limits_x, limits_y, max_px", "htmlwidget (leaflet)", "addSidebyside(leftId, rightId) + JS Hook", "Visor interactivo swipe slider"]
]

print(f"Cargadas {len(QUESTIONS_AND_ANSWERS)} preguntas y {len(MEGA_TABLE_DATA)} filas de mega tabla optimizada.")
