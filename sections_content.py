# -*- coding: utf-8 -*-
"""
Contenido detallado para las Secciones 5, 6 y 7 de la Guía de Estudio drones4health.
Actualizado tras la optimización y limpieza de funciones redundantes.
"""

FUNCTIONS_DATA = [
    # -------------------------------------------------------------
    # GRUPO 1: PREPROCESAMIENTO E INGESTIÓN
    # -------------------------------------------------------------
    {
        "name": "d4h_read_stack(file_path, required_bands = NULL, band_names = NULL)",
        "category": "Preprocesamiento e Ingestión",
        "purpose": "Carga un archivo GeoTIFF multicapa o valida un objeto SpatRaster existente en R, renombra capas de forma controlada y valida estrictamente que existan las bandas espectrales mínimas para cálculos posteriores (ej. NIR y Red).",
        "inputs": "• file_path: Cadena con la ruta al GeoTIFF o un objeto terra::SpatRaster.\n• required_bands: Vector de caracteres opcional (ej. c('NIR', 'Red')). Búsqueda insensible a mayúsculas/minúsculas con coincidencia exacta o regex parcial.\n• band_names: Vector de caracteres opcional para renombrar las capas. Debe coincidir exactamente con el número de capas (nlyr).",
        "outputs": "Un objeto de clase 'terra::SpatRaster' validado con los nombres de capa estandarizados.",
        "process": "1. Comprueba si 'file_path' es cadena (verifica file.exists() y carga con terra::rast()) o si ya es un SpatRaster.\n2. Valida que el número de capas sea > 0.\n3. Si se proporciona 'band_names', verifica que length(band_names) == nlyr(r) y renombra names(r).\n4. Si se especifican 'required_bands', itera sobre cada requerimiento limpiando espacios y comparando en minúsculas contra names(r). Si falta alguna banda, detiene la ejecución inmediatamente (stop) con un mensaje informativo que lista las bandas faltantes y las disponibles.",
        "math": "Verificación de pertenencia conjuntista:\nBandasRequeridas ⊆ NombresCapasRaster",
        "notes": "Decisión de diseño: El fallo inmediato (fail-fast) evita que cálculos complejos posteriores fallen a mitad de camino por falta de una banda, ahorrando minutos de procesamiento en ortomosaicos pesados."
    },
    {
        "name": "d4h_normalize_reflectance(raster_layer, scale_factor = 65535)",
        "category": "Preprocesamiento e Ingestión",
        "purpose": "Escala números digitales (DN) enteros crudos de 16 bits (0 a 65535) o de 8 bits (0 a 255) a reflectancia de superficie física en el rango continuo de 0.0 a 1.0, enmascarando ceros artificiales como NA.",
        "inputs": "• raster_layer: Objeto SpatRaster o ruta a archivo de una sola banda.\n• scale_factor: Numérico divisor (por defecto 65535 para cámaras multiespectrales de 16 bits, ej. MicaSense RedEdge o DJI P4 Multispectral).",
        "outputs": "Un SpatRaster monocapa con valores numéricos flotantes en [0, 1] y ceros enmascarados como NA.",
        "process": "1. Pasa el raster por .ensure_raster(mask_zeros = TRUE).\n2. Divide matricialmente la capa entre scale_factor.\n3. Aplica terra::clamp(lower = 0, upper = 1) para restringir ruidos radiométricos.\n4. Fuerza r[r == 0] <- NA para eliminar el fondo de vuelo sin datos.",
        "math": "Reflectancia = clamp(DN / FactorEscala, 0, 1)",
        "notes": "Fórmulas de índices como MSAVI2 o EVI dependen de reflectancias reales entre 0 y 1. Si se aplican sobre enteros de 16 bits sin normalizar, los resultados colapsan a valores extremos o NaN."
    },
    {
        "name": "d4h_thermal_to_celsius(thermal_raster, gain = 0.01, offset = -273.15)",
        "category": "Preprocesamiento e Ingestión",
        "purpose": "Convierte números digitales radiométricos de sensores infrarrojos térmicos (LWIR) a Temperatura de Superficie Terrestre (LST) en grados Celsius (°C).",
        "inputs": "• thermal_raster: SpatRaster o ruta a archivo térmico (ej. FLIR Tau2, DJI Zenmuse H20T o Mavic 2/3 Enterprise Thermal).\n• gain: Multiplicador de calibración lineal (defecto: 0.01 para datos en centi-Kelvin).\n• offset: Desplazamiento lineal (defecto: -273.15 para convertir Kelvin a Celsius).",
        "outputs": "Un SpatRaster monocapa con nombre 'LST_Celsius' representando la temperatura en grados Celsius (°C).",
        "process": "1. Valida el ráster con .ensure_raster().\n2. Enmascara valores <= 0 como NA.\n3. Aplica la transformación lineal: res = (r * gain) + offset.\n4. Enmascara valores infinitos o NaN.\n5. Asigna el nombre 'LST_Celsius' a la capa.",
        "math": "LST_(°C) = (DN × Ganancia) + Offset\nPara centi-Kelvin: LST_(°C) = (DN × 0.01) - 273.15",
        "notes": "Fundamental para evaluar micro-refugios térmicos donde mosquitos adultos reposan durante las horas de calor extremo del mediodía para evitar la desecación."
    },
    {
        "name": "Helpers Internos: .ensure_raster(), .match_pair(), .match_multi()",
        "category": "Preprocesamiento e Ingestión",
        "purpose": "Módulos de infraestructura interna que garantizan coherencia de tipos y armonización espacial entre bandas antes de cualquier operación algebraica.",
        "inputs": "• .ensure_raster(x, mask_zeros): Verifica que x sea SpatRaster o ruta a archivo y extrae la primera capa ([[1]]).\n• .match_pair(r_ref, r_sub): Compara geometría entre dos capas.\n• .match_multi(r_ref, ...): Armoniza múltiples capas respecto a una capa de referencia.",
        "outputs": "Listas de objetos SpatRaster estrictamente alineados (mismo CRS, misma extensión y misma resolución píxel a píxel).",
        "process": "1. Comprueba terra::compareGeom(ref, sub, stopOnError = FALSE).\n2. Si el CRS no coincide (terra::same.crs), proyecta 'sub' hacia el CRS de 'ref' mediante interpolación bilineal ('bilinear').\n3. Si la extensión o resolución no coinciden, ejecuta terra::resample(sub, ref, method = 'bilinear').",
        "math": "Armonización espacial: Matriz_Sub' = Resample_Bilineal(Proyecto(Matriz_Sub, CRS_Ref), Geometría_Ref)",
        "notes": "Decisión clave: En vuelos de dron, cámaras como MicaSense capturan cada banda a través de una lente físicamente distinta. Aunque el software fotogramétrico alinee las bandas, a menudo hay discrepancias microscópicas en dimensiones de fila/columna. Sin este helper, las operaciones algebraicas en R fallarían con 'different geometries'."
    },

    # -------------------------------------------------------------
    # GRUPO 2: ÍNDICES ESPECTRALES DE COBERTURA Y HUMEDAD
    # -------------------------------------------------------------
    {
        "name": "d4h_ndvi(nir, red)",
        "category": "Índices Espectrales",
        "purpose": "Calcula el Índice de Vegetación de Diferencia Normalizada para cuantificar la densidad de clorofila, biomasa activa y vigor de la vegetación que sirve de micro-hábitat o sombra a vectores.",
        "inputs": "• nir: SpatRaster o ruta de banda infrarroja cercana (NIR).\n• red: SpatRaster o ruta de banda roja visible (Red).",
        "outputs": "SpatRaster monocapa nombrado 'NDVI' clamped en [-1, 1] con fondo enmascarado como NA.",
        "process": "1. Alinea bandas con .match_pair(nir, red, mask_zeros = TRUE).\n2. Calcula denominador den = nir + red.\n3. res = (nir - red) / den.\n4. Enmascara celdas donde den <= 0, nan, infinito o res == 0.\n5. Aplica terra::clamp(lower = -1, upper = 1).",
        "math": "NDVI = (NIR - Red) / (NIR + Red)",
        "notes": "Valores < 0 indican cuerpos de agua; 0 a 0.2 suelo desnudo o calles; 0.2 a 0.5 vegetación arbustiva peridomiciliaria; > 0.5 copas densas de árboles."
    },
    {
        "name": "d4h_dvi(nir, red)",
        "category": "Índices Espectrales",
        "purpose": "Calcula la Diferencia Simple de Vegetación sensible a cambios lineales en la biomasa foliar y área foliar (LAI).",
        "inputs": "• nir: Banda Infrarroja Cercana.\n• red: Banda Roja.",
        "outputs": "SpatRaster monocapa nombrado 'DVI' con fondo NoData en NA.",
        "process": "1. Alinea las bandas enmascarando ceros.\n2. res = nir - red.\n3. Enmascara valores infinitos, NaN y ceros a NA.",
        "math": "DVI = NIR - Red",
        "notes": "Al no tener denominador de normalización, no se satura tan rápido como el NDVI en canopias ultra-densas de bosques tropicales."
    },
    {
        "name": "d4h_savi(nir, red, l_factor = 0.5)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Vegetación Ajustado al Suelo. Minimiza la distorsión del brillo del suelo de fondo en zonas con vegetación dispersa o rala (ej. zonas periurbanas con patios de tierra).",
        "inputs": "• nir: Banda NIR.\n• red: Banda Red.\n• l_factor: Factor de ajuste de suelo L (por defecto 0.5 para densidades intermedias; 1.0 para vegetación muy baja; 0.25 para densa).",
        "outputs": "SpatRaster monocapa nombrado 'SAVI' clamped en [-1, 1].",
        "process": "1. Alinea bandas con .match_pair().\n2. den = nir + red + l_factor.\n3. res = ((nir - red) / den) * (1 + l_factor).\n4. Enmascara divisiones inválidas y clampa a [-1, 1].",
        "math": "SAVI = ((NIR - Red) / (NIR + Red + L)) × (1 + L)",
        "notes": "Huete (1988) demostró que cuando la cobertura vegetal es menor al 40%, el suelo desnudo refleja radiación que altera el NDVI. El factor L corrige las líneas de suelo."
    },
    {
        "name": "d4h_msavi2(nir, red)",
        "category": "Índices Espectrales",
        "purpose": "Índice Modificado de Vegetación Ajustado al Suelo 2. Evalúa cobertura vegetal en paisajes degradados o áridos sin requerir definir manualmente un factor L empírico.",
        "inputs": "• nir: Banda NIR.\n• red: Banda Red.",
        "outputs": "SpatRaster monocapa nombrado 'MSAVI2' clamped en [-1, 1].",
        "process": "1. Alinea bandas.\n2. Muestrea 100 píxeles; si el máximo es > 1, divide ambas bandas entre 65535 automáticamente.\n3. Calcula término cuadrático bajo la raíz: term = (2*nir + 1)^2 - 8*(nir - red).\n4. Enmascara term < 0 a NA.\n5. res = (2*nir + 1 - sqrt(term)) / 2.\n6. Clampa a [-1, 1].",
        "math": "MSAVI2 = (2 × NIR + 1 - √((2 × NIR + 1)² - 8 × (NIR - Red))) / 2",
        "notes": "Decisión clave en el código: La auto-detección y escalado automático de 16 bits evita raíces negativas que producirían números complejos (NaN)."
    },
    {
        "name": "d4h_vari(green, red, blue, eps = 0.001)",
        "category": "Índices Espectrales",
        "purpose": "Índice Visible Resistente a la Atmósfera. Estima fracción vegetal usando exclusivamente canales visibles RGB con resistencia a diferencias de iluminación y sombras.",
        "inputs": "• green: Banda Verde.\n• red: Banda Roja.\n• blue: Banda Azul.\n• eps: Constante numérica de estabilización (defecto: 0.001).",
        "outputs": "SpatRaster monocapa nombrado 'VARI' clamped en [-1, 1].",
        "process": "1. Alinea las 3 bandas RGB con .match_multi().\n2. den = green + red - blue + eps.\n3. res = (green - red) / den.\n4. Clampa a [-1, 1].",
        "math": "VARI = (Green - Red) / (Green + Red - Blue + ε)",
        "notes": "Vital para drones económicos que solo portan cámaras RGB convencionales (DJI Mavic 3, Phantom 4 Pro) sin sensores multiespectrales."
    },
    {
        "name": "d4h_evi(nir, red, blue, g_factor = 2.5, c1 = 6, c2 = 7.5, l_factor = 1)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Vegetación Mejorado. Optimizado para regiones de alta biomasa vegetal con corrección de aerosoles atmosféricos y resistencia al desacople por brillo de suelo.",
        "inputs": "• nir: Banda NIR.\n• red: Banda Red.\n• blue: Banda Azul.\n• g_factor: Ganancia (2.5).\n• c1, c2: Coeficientes de resistencia a aerosoles (6.0 y 7.5).\n• l_factor: Ajuste de canopia (1.0).",
        "outputs": "SpatRaster monocapa nombrado 'EVI'.",
        "process": "1. Alinea las 3 bandas.\n2. den = nir + (c1 * red) - (c2 * blue) + l_factor.\n3. res = g_factor * ((nir - red) / den).\n4. Enmascara valores den <= 0 y ceros a NA.",
        "math": "EVI = G × ((NIR - Red) / (NIR + C₁ × Red - C₂ × Blue + L))",
        "notes": "El canal azul corrige la dispersión de Rayleigh residual en la banda roja, desacoplando la señal de la canopia del ruido de fondo."
    },
    {
        "name": "d4h_ndwi(green, nir)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Diferencia Normalizada de Agua (McFeeters). Identifica cuerpos de agua superficial abierta, charcos, canales de drenaje y acumulación de humedad.",
        "inputs": "• green: Banda Verde.\n• nir: Banda Infrarroja Cercana.",
        "outputs": "SpatRaster monocapa nombrado 'NDWI' clamped en [-1, 1].",
        "process": "1. Alinea bandas.\n2. den = green + nir.\n3. res = (green - nir) / den.\n4. Clampa a [-1, 1].",
        "math": "NDWI = (Green - NIR) / (Green + NIR)",
        "notes": "El agua absorbe fuertemente en el NIR y refleja en el Verde; por ende, valores NDWI > 0 representan agua libre o suelo saturado, mientras que valores negativos representan vegetación y suelo seco."
    },
    {
        "name": "d4h_ndre(nir, red_edge)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Diferencia Normalizada de Borde Rojo. Evalúa clorofila en copas densas donde el NDVI clásico se satura.",
        "inputs": "• nir: Banda NIR.\n• red_edge: Banda Red Edge (típicamente 705-740 nm).",
        "outputs": "SpatRaster monocapa nombrado 'NDRE' clamped en [-1, 1].",
        "process": "1. Alinea bandas.\n2. den = nir + red_edge.\n3. res = (nir - red_edge) / den.\n4. Clampa a [-1, 1].",
        "math": "NDRE = (NIR - RedEdge) / (NIR + RedEdge)",
        "notes": "La radiación Red Edge penetra más profundamente en la estructura del follaje que la luz roja visible, permitiendo detectar micro-hábitats en estratos medios del dosel."
    },
    {
        "name": "d4h_gndvi(nir, green)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Vegetación de Diferencia Normalizada Verde. Mide concentración de clorofila foliar con mayor sensibilidad a cambios en etapas maduras.",
        "inputs": "• nir: Banda NIR.\n• green: Banda Verde.",
        "outputs": "SpatRaster monocapa nombrado 'GNDVI' clamped en [-1, 1].",
        "process": "1. Alinea bandas.\n2. den = nir + green.\n3. res = (nir - green) / den.\n4. Clampa a [-1, 1].",
        "math": "GNDVI = (NIR - Green) / (NIR + Green)",
        "notes": "Se utiliza también en el índice epidemiológico IEC para estratificar micro-algas en cuerpos de agua que sirven de alimento a larvas."
    },
    {
        "name": "d4h_ctvi(ndvi_raster)",
        "category": "Índices Espectrales",
        "purpose": "Índice de Vegetación Transformado Corregido. Normaliza distribuciones asimétricas de NDVI para modelado estadístico y econométrico.",
        "inputs": "• ndvi_raster: Capa NDVI calculada previamente.",
        "outputs": "SpatRaster monocapa nombrado 'CTVI'.",
        "process": "1. Ingiere el ráster NDVI.\n2. res = (ndvi + 0.5) / sqrt(abs(ndvi + 0.5)).\n3. Enmascara no finitos a NA.",
        "math": "CTVI = (NDVI + 0.5) / √( |NDVI + 0.5| )",
        "notes": "Corrige la asimetría negativa típica del NDVI cuando coexisten grandes masas de agua o suelo estéril."
    },
    {
        "name": "d4h_bare_soil(ndvi_raster, threshold = 0.15)",
        "category": "Índices Espectrales",
        "purpose": "Genera una máscara booleana binaria de suelo desnudo, expuesto o erosionado a partir de un umbral de NDVI.",
        "inputs": "• ndvi_raster: Capa NDVI.\n• threshold: Umbral de corte (defecto: 0.15).",
        "outputs": "SpatRaster binario (1 = suelo desnudo, 0 = vegetación/agua) nombrado 'Bare_Soil'.",
        "process": "1. Ingiere NDVI.\n2. mask = terra::ifel(r < threshold, 1, 0).\n3. Preserva máscara de NA original.",
        "math": "SueloDesnudo = { 1 si NDVI < θ_suelo ; 0 en otro caso }",
        "notes": "El suelo desnudo en el peridomicilio incrementa el riesgo de arrastre y encharcamiento pluvial hacia las viviendas."
    },

    # -------------------------------------------------------------
    # GRUPO 3: MICRO-RELIEVE Y TOPOGRAFÍA
    # -------------------------------------------------------------
    {
        "name": "d4h_slope(dem_raster, unit = 'degrees')",
        "category": "Micro-Topografía",
        "purpose": "Calcula la pendiente topográfica a micro-escala a partir de un Modelo Digital de Elevación (DEM) o Modelo Digital de Superficie (DSM) fotogramétrico.",
        "inputs": "• dem_raster: Capa DEM/DSM de alta resolución (m).\n• unit: Unidad de pendiente ('degrees' o 'radians').",
        "outputs": "SpatRaster monocapa nombrado 'slope_degrees' o 'slope_radians'.",
        "process": "1. Ingiere DEM y limpia no finitos.\n2. Ejecuta terra::terrain(dem, v = 'slope', unit = unit).\n3. Enmascara bordes no finitos.",
        "math": "β = arctan( √((∂z/∂x)² + (∂z/∂y)²) )",
        "notes": "Pendientes casi planas (< 3° a 5°) identifican micro-depresiones donde el drenaje pluvial se interrumpe, creando charcos estancados ideales para la oviposición de mosquitos."
    },
    {
        "name": "d4h_twi(dem_raster, eps = 0.001)",
        "category": "Micro-Topografía",
        "purpose": "Índice Topográfico de Humedad (Beven & Kirkby). Modela la acumulación hidrológica micro-espacial y la susceptibilidad al encharcamiento superficial.",
        "inputs": "• dem_raster: DEM/DSM fotogramétrico.\n• eps: Constante de estabilización para evitar división por cero en terrenos llanos (0.001).",
        "outputs": "SpatRaster monocapa nombrado 'TWI'.",
        "process": "1. Calcula pendiente en radianes: slope_rad = terra::terrain(dem, v = 'slope', unit = 'radians').\n2. Calcula dirección de flujo / acumulación aproximada: flow_acc = terra::terrain(dem, v = 'flowdir').\n3. twi = log((flow_acc + 1) / (tan(slope_rad) + eps)).\n4. Enmascara no finitos a NA.",
        "math": "TWI = ln( (a + 1) / (tan(β) + ε) )\ndonde 'a' es el área de contribución por longitud de contorno y β es la pendiente en radianes.",
        "notes": "Valores altos de TWI (> 8.0) demarcan puntos críticos de drenaje bloqueado y acumulación larvaria que no son visibles en fotografías RGB aéreas normales."
    },

    # -------------------------------------------------------------
    # GRUPO 4: ÍNDICES ECO-EPIDEMIOLÓGICOS ESPECIALIZADOS
    # -------------------------------------------------------------
    {
        "name": "d4h_imsr(red_edge, red, nir, veg_threshold = 0.2, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Micro-acumulación de Residuos Sólidos y Materiales Sintéticos. Detecta plásticos, lonas, neumáticos y recipientes artificiales descartados que actúan como criaderos de Aedes aegypti.",
        "inputs": "• red_edge, red, nir: Bandas multiespectrales.\n• veg_threshold: Umbral para diferenciar vegetación natural de polímeros sintéticos (0.2).\n• eps: Estabilizador numérico.",
        "outputs": "SpatRaster nombrado 'IMSR' en [0, 1] con fondo enmascarado.",
        "process": "1. Alinea bandas con .match_multi(mask_zeros = TRUE).\n2. Si NIR > 1, divide entre 65535.\n3. ndre_approx = (red_edge - red) / (red_edge + red + eps).\n4. res = abs(ndre_approx - veg_threshold) * nir.\n5. Enmascara res <= 1e-5 y clampa a [0, 1].",
        "math": "NDRE_approx = (RedEdge - Red) / (RedEdge + Red + ε)\nIMSR = |NDRE_approx - θ_veg| × NIR_norm",
        "notes": "Los plásticos y cauchos presentan curvas espectrales anómalas en la transición Red-Edge y baja absorción en NIR respecto a la vegetación. El producto ponderado aísla recipientes artificiales."
    },
    {
        "name": "d4h_irts(ndre, lst_local, lst_surrounding, nir, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Refugio Térmico y Sombra. Identifica micro-ambientes frescos bajo canopia que sirven de descanso y refugio microclimático para vectores adultos durante horas de calor extremo.",
        "inputs": "• ndre: Capa NDRE.\n• lst_local: Temperatura superficial local (°C).\n• lst_surrounding: Media focal de temperatura circundante (terra::focal w=9).\n• nir: Banda NIR.\n• eps: Estabilizador numérico.",
        "outputs": "SpatRaster nombrado 'IRTS'.",
        "process": "1. Alinea las 4 capas con .match_multi().\n2. den = nir + eps.\n3. res = (ndre * (lst_surrounding - lst_local)) / den.\n4. Enmascara ceros y valores no finitos a NA.",
        "math": "IRTS = (NDRE × (LST_circundante - LST_local)) / (NIR + ε)",
        "notes": "Un gradiente térmico positivo (entorno caliente, punto focal frío) potenciado por vigor de clorofila (NDRE) define el hábitat de reposo donde el mosquito evita la muerte térmica."
    },
    {
        "name": "d4h_iev(delta_ndwi, slope_dsm, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Indicador de Estancamiento y Vulnerabilidad de Vectores. Localiza micro-depresiones donde el agua superficial no escurre y permanece estancada.",
        "inputs": "• delta_ndwi: Diferencia temporal de NDWI o capa NDWI actual.\n• slope_dsm: Capa de pendiente derivada del DSM/DEM.\n• eps: Estabilizador.",
        "outputs": "SpatRaster nombrado 'IEV'.",
        "process": "1. Alinea NDWI y Pendiente.\n2. den = slope_dsm + eps.\n3. res = delta_ndwi * (1 / den).\n4. Enmascara denominadores <= 0 y ceros a NA.",
        "math": "IEV = NDWI × (1 / (Pendiente + ε))",
        "notes": "Combina alta presencia de agua (NDWI alto) con pendiente casi nula (1/(slope+ε) muy grande), multiplicando la señal en charcos duraderos."
    },
    {
        "name": "d4h_iec(gndvi_water, lst, t_opt = 25)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Exposición de Canopia e Incubación Térmica Larvaria. Estratifica cuerpos de agua según su temperatura óptima de desarrollo larvario.",
        "inputs": "• gndvi_water: GNDVI enmascarado a cuerpos de agua.\n• lst: Temperatura superficial (°C).\n• t_opt: Temperatura óptima de incubación (defecto: 25°C para culícidos).",
        "outputs": "SpatRaster nombrado 'IEC'.",
        "process": "1. Alinea GNDVI y LST.\n2. res = gndvi_water * (1 - (abs(lst - t_opt) / t_opt)).\n3. Enmascara valores no finitos a NA.",
        "math": "IEC = GNDVI_agua × (1 - (|LST - T_opt| / T_opt))",
        "notes": "Mordecai et al. (2017) demostraron que la tasa de desarrollo de Aedes y Anopheles tiene forma de campana térmica centrada en 25°C. El factor penaliza cuerpos de agua demasiado fríos (<18°C) o hiper-calientes (>35°C)."
    },
    {
        "name": "d4h_iead(grad_delta_ndvi, depressions_dsm, red_edge)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Estancamiento en Áreas de Desmonte / Deforestación reciente. Identifica charcos en zanjas abiertas por maquinaria o tala reciente.",
        "inputs": "• grad_delta_ndvi: Gradiente espacial de cambio de NDVI.\n• depressions_dsm: Capa de depresiones topográficas.\n• red_edge: Banda Red Edge.",
        "outputs": "SpatRaster nombrado 'IEAD'.",
        "process": "1. Alinea las 3 capas.\n2. res = grad_delta_ndvi * depressions_dsm * red_edge.\n3. Enmascara no finitos a NA.",
        "math": "IEAD = ∇(ΔNDVI) × Depresiones_DSM × RedEdge",
        "notes": "Relevante en fronteras agrícolas y obras civiles peridomiciliarias donde la remoción de tierra crea criaderos no naturales."
    },
    {
        "name": "d4h_irhe(green, nir, lst, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Retención Hídrica Espectral y Frío. Identifica cuerpos de agua profundos o resguardados con baja evaporación que perduran en época seca.",
        "inputs": "• green, nir: Bandas verde y NIR.\n• lst: Temperatura (°C).\n• eps: Estabilizador.",
        "outputs": "SpatRaster nombrado 'IRHE'.",
        "process": "1. Alinea bandas.\n2. ndwi = (green - nir) / (green + nir + eps).\n3. res = ndwi * (1 / (lst + eps)).\n4. Enmascara no finitos a NA.",
        "math": "IRHE = NDWI × (1 / (LST + ε))",
        "notes": "Agua persistente fría = criadero de reservorio inter-estacional de vectores."
    },
    {
        "name": "d4h_ifeb(grad_red_edge, red, nir, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Fragmentación y Efecto de Borde. Cuantifica ecotonos de transición entre bordes de bosque y claros urbanizados.",
        "inputs": "• grad_red_edge: Gradiente focal de Red Edge.\n• red, nir: Bandas roja y NIR.\n• eps: Estabilizador.",
        "outputs": "SpatRaster nombrado 'IFEB'.",
        "process": "1. Alinea capas.\n2. res = abs(grad_red_edge) * (red / (nir + eps)).\n3. Enmascara no finitos a NA.",
        "math": "IFEB = |∇(RedEdge)| × (Red / (NIR + ε))",
        "notes": "Las zonas de borde de fragmentos de bosque concentran mayor tasa de picaduras que el interior de la selva virgen."
    },
    {
        "name": "d4h_irih(var_re_nir, red, green, eps = 0.001)",
        "category": "Índices Eco-Epidemiológicos",
        "purpose": "Índice de Rugosidad de Interfaz Humana e Infección. Mide heterogeneidad estructural de la canopia en el límite bosque-vivienda.",
        "inputs": "• var_re_nir: Varianza focal de la razón RedEdge/NIR.\n• red, green: Bandas roja y verde.\n• eps: Estabilizador.",
        "outputs": "SpatRaster nombrado 'IRIH'.",
        "process": "1. Alinea capas.\n2. res = var_re_nir * (red / (green + eps)).\n3. Enmascara no finitos a NA.",
        "math": "IRIH = Var(RedEdge / NIR) × (Red / (Green + ε))",
        "notes": "Modela los corredores de vuelo por los cuales los mosquitos penetran desde el dosel vegetal hacia los dormitorios humanos."
    },

    # -------------------------------------------------------------
    # GRUPO 5: SEGMENTACIÓN DE OBJETOS Y GEOAI
    # -------------------------------------------------------------
    {
        "name": "d4h_segment_water(raster_in, rgb_raster = NULL, threshold = NULL, is_ndwi = NULL, max_water_brightness = 95.0, min_area_m2 = 2.0, max_area_m2 = 50000.0, method = c('spectral', 'sam'), sam_checkpoint = NULL, exclude_buildings = NULL)",
        "category": "Segmentación OBIA / GeoAI",
        "purpose": "Detecta, delinea y vectoriza cuerpos de agua, charcos y canales con autodetección inteligente de polaridad espectral (NDWI vs NDVI), filtrado óptico de brillo para descartar falsos positivos y soporte para Deep Learning (SAM con auto-descarga de pesos).",
        "inputs": "• raster_in: Capa NDWI, MNDWI o NDVI (SpatRaster o ruta).\n• rgb_raster: Ortomosaico RGB opcional (en SAM es la imagen principal de segmentación; en spectral es filtro óptico).\n• threshold: Umbral espectral opcional. Si es NULL, se calibra automáticamente (0.0 para NDWI, -0.05 para NDVI).\n• is_ndwi: Booleano opcional (autodetectado si es NULL).\n• max_water_brightness: Brillo RGB medio máximo permitido (95.0, usado en spectral).\n• min_area_m2, max_area_m2: Filtro de área de polígonos (usado en ambos métodos).\n• method: 'spectral' (R nativo rápido) o 'sam' (Meta Segment Anything).\n• sam_checkpoint: Ruta al modelo (.pth). Si es NULL, se busca en caché o se descarga automáticamente desde Meta al directorio interno del paquete.\n• exclude_buildings: Capa sf de casas para excluir techos (usado en ambos métodos).",
        "outputs": "Objeto 'sf' POLYGON con columnas: water_id (W0001, W0002...), area_m2, perimeter_m y geometry.",
        "process": "1. Si method = 'sam': corre SAM sobre rgb_raster (o raster_in) utilizando pesos auto-resueltos/descargados por .d4h_get_sam_checkpoint(); filtra directamente por [min_area_m2, max_area_m2] y resta exclude_buildings.\n2. Si method = 'spectral': autodetecta si la entrada es NDWI o NDVI y calibra threshold.\n3. Genera máscara binaria espectral y aplica filtro óptico de brillo si se proporciona rgb_raster (brillo <= max_water_brightness).\n4. Si total_px > 3 millones, aplica agregación piramidal para evitar desbordes de memoria.\n5. Vectoriza con terra::as.polygons(dissolve = TRUE) y convierte a sf.\n6. Si se provee exclude_buildings, sustrae con sf::st_difference(st_buffer(union, 1.0)).\n7. Filtra por [min_area, max_area], recorta contra la huella de vuelo erosionada (-15m) y numera IDs.",
        "math": "Spectral: MáscaraAgua = { 1 si (NDWI > 0 ∨ NDVI < θ) ∧ Brillo_RGB ≤ 95.0 ∧ Área ∈ [2, 50000] m² ; NA en otro caso }\nSAM: Máscaras_ViT(RGB) filtradas por Área ∈ [2, 50000] m² ∖ Viviendas",
        "notes": "SIMPLIFICACIÓN PARA EL USUARIO EN SAM: Cuando se activa method = 'sam', el usuario no necesita configurar umbrales espectrales ni rutas complejas de pesos .pth. La función utiliza preferentemente el ortomosaico visible RGB, descarga automáticamente el modelo oficial de Meta (~375 MB) a la carpeta de caché del paquete en el primer uso y aplica únicamente los filtros espaciales críticos: tamaño de área [min, max] y exclusión de edificaciones."
    },
    {
        "name": "d4h_segment_buildings(rgb_raster, ndvi_raster = NULL, min_area_m2 = 12.0, max_area_m2 = 600.0, brightness_min = 135.0, ndvi_max = 0.25, method = c('spectral', 'sam'), sam_checkpoint = NULL)",
        "category": "Segmentación OBIA / GeoAI",
        "purpose": "Detecta y vectoriza huellas de techos y viviendas residenciales a partir de contraste espectral/textural en RGB o mediante Deep Learning con SAM.",
        "inputs": "• rgb_raster: Ortomosaico RGB de 3 bandas (usado en ambos métodos).\n• ndvi_raster: Opcional, para descartar canopia sobre techos (usado en spectral).\n• min_area_m2, max_area_m2: Límites de tamaño habitacional (12 a 600 m², usado en ambos métodos).\n• brightness_min: Umbral de brillo para calaminas (usado en spectral).\n• ndvi_max: Límite máximo de vegetación en techos (usado en spectral).\n• method: 'spectral' o 'sam'.\n• sam_checkpoint: Ruta al modelo (.pth). Si es NULL, se gestiona y descarga automáticamente a la caché del paquete.",
        "outputs": "Objeto 'sf' POLYGON con columnas: building_id (B0001...), area_m2, centroid_x, centroid_y y geometry.",
        "process": "1. Si method = 'sam': ejecuta SAM sobre rgb_raster con pesos resueltos automáticamente por .d4h_get_sam_checkpoint(), filtrando polígonos exclusivamente por [min_area_m2, max_area_m2].\n2. Si method = 'spectral': calcula brillo medio RGB y aplica discriminador dual (calaminas brillo >= brightness_min o tejas rojas).\n3. Enmascara zonas con ndvi >= ndvi_max si se suministra ndvi_raster.\n4. Vectoriza con as.polygons(), convierte a sf POLYGON y filtra por área [12, 600] m².\n5. Filtra contra la huella de vuelo erosionada (-15m).\n6. Extrae centroides UTM (centroid_x, centroid_y) redondeados a 2 decimales para vincular directamente con análisis epidemiológico.",
        "math": "Spectral: TechoCandidato = { 1 si (Brillo ≥ 135 ∨ Teja_Rojo) ∧ NDVI < 0.25 ∧ Área ∈ [12, 600] m² ; NA en otro caso }\nSAM: Máscaras_ViT(RGB) filtradas por Área ∈ [12, 600] m²",
        "notes": "DISEÑO ZERO-OVERHEAD EN SAM: Al seleccionar method = 'sam', se ignoran los parámetros espectrales de brillo y NDVI, enfocando el procesamiento en los límites morfológicos de las estructuras y gestionando la descarga y almacenamiento de los pesos de la red de manera totalmente transparente."
    },

    # -------------------------------------------------------------
    # GRUPO 6: MODELADO DE DISTANCIAS Y EXPOSICIÓN
    # -------------------------------------------------------------
    {
        "name": "d4h_distance_to_water(buildings, sources, decay_lambda = 100.0, buffer_breaks = c(50, 100, 200), risk_labels = ...)",
        "category": "Modelado de Distancias y Riesgo",
        "purpose": "Calcula la distancia euclidiana mínima en metros desde cada vivienda al cuerpo de agua más cercano, calcula un score de exposición exponencial y clasifica en estratos de prioridad.",
        "inputs": "• buildings: Objeto sf de puntos o polígonos de viviendas.\n• sources: Objeto sf de polígonos de agua o fuentes de riesgo.\n• decay_lambda: Constante de decaimiento del vuelo del vector en metros (100.0 m).\n• buffer_breaks: Puntos de corte en metros (c(50, 100, 200)).\n• risk_labels / proximity_labels: Nombres de estratos.",
        "outputs": "Objeto 'sf' idéntico a buildings con columnas añadidas: dist_water_m, nearest_water_id, proximity_score (en [0, 1]) y proximity_level.",
        "process": "1. Verifica CRS y proyecta 'sources' al CRS métrico de 'buildings' si difieren.\n2. Extrae centroides de viviendas: b_cents = sf::st_centroid(buildings).\n3. Calcula matriz de distancias: dists_matrix = sf::st_distance(b_cents, sources).\n4. Extrae mínimo por fila y el índice del cuerpo de agua más cercano (which.min).\n5. Calcula score de riesgo exponencial: exp(-dist_water_m / decay_lambda).\n6. Categoriza distancias con cut() según buffer_breaks.",
        "math": "RiskScore_i = exp( - d_min(i) / λ )\ndonde d_min es la distancia euclidiana en metros y λ = 100 m es el radio de dispersión característico.",
        "notes": "La función st_distance calcula la distancia exacta al borde perimetral del polígono de agua, no a su centroide, lo cual es biofísicamente correcto porque el mosquito emerge en la orilla."
    },
    {
        "name": "d4h_raster_distance(sources, raster_ref)",
        "category": "Modelado de Distancias y Riesgo",
        "purpose": "Genera una superficie continua ráster (mapa de calor) de distancia euclidiana en metros a la fuente de riesgo más cercana en toda la escena.",
        "inputs": "• sources: Objeto sf o SpatVector con polígonos/puntos de riesgo.\n• raster_ref: Ráster de referencia para heredar CRS, resolución y extensión.",
        "outputs": "SpatRaster monocapa nombrado 'dist_to_source_m' donde el valor de cada celda es la distancia euclidiana en metros a la fuente más próxima.",
        "process": "1. Rasteriza los polígonos de riesgo sobre la rejilla de referencia asignando 1 a las fuentes y NA al fondo.\n2. Ejecuta el algoritmo de transformada de distancia euclidiana en C++: terra::distance(r_rasterized).\n3. Asigna nombre 'dist_to_source_m'.",
        "math": "D(x, y) = min_(i) √( (x - x_i)² + (y - y_i)² )",
        "notes": "Permite visualizar el gradiente continuo de peligro para planificar barreras de fumigación espacial o zonas de exclusión."
    },

    # -------------------------------------------------------------
    # GRUPO 7: ZONIFICACIÓN Y COMPOSICIÓN SECTORIAL
    # -------------------------------------------------------------
    {
        "name": "d4h_hex_grid(aoi, cell_size = 50, clip_to_footprint = TRUE)",
        "category": "Zonificación Territorial",
        "purpose": "Genera una malla hexagonal regular sobre el área de interés (AOI) con identificadores únicos (H0001, H0002...) y recorte opcional a la huella de vuelo válida.",
        "inputs": "• aoi: SpatRaster, SpatVector, sf o ruta a archivo.\n• cell_size: Diámetro exterior del hexágono en metros (defecto: 50).\n• clip_to_footprint: Booleano para podar hexágonos fuera del vuelo (defecto: TRUE).",
        "outputs": "Objeto 'terra::SpatVector' con las geometrías hexagonales y columna 'grid_id'.",
        "process": "1. Ingiere AOI. Si es ráster y clip_to_footprint = TRUE, agrega celdas para crear máscara rápida (!is.na & !=0) y vectoriza su envolvente con terra::as.polygons().\n2. Genera grilla hexagonal con sf::st_make_grid(boundary_sf, cellsize = cell_size, square = FALSE).\n3. Si clip_to_footprint = TRUE, filtra solo los hexágonos que intersectan la huella con sf::st_intersects().\n4. Asigna IDs correlativos 'H%04d' y retorna como SpatVector.",
        "math": "Diámetro = cell_size ; Lado r = cell_size / 2 ; Área_Hex = (3√3 / 2) × r²",
        "notes": "El recorte dinámico con agregación previa acelera la creación de grillas en un 95% respecto a hacer intersecciones con el ráster sin agregar."
    },
    {
        "name": "d4h_summarize_grid(raster_in, cell_size = 20, square = TRUE, discard_na = TRUE, general = FALSE, exact_boundary = TRUE)",
        "category": "Zonificación Territorial",
        "purpose": "Extrae estadísticas zonales (media aritmética) por celda de grilla (cuadrada o hexagonal). Si 'general = TRUE', extrae la media global de todo el mosaico en un único polígono vectorial de referencia (SpatVector con grid_id='GENERAL').",
        "inputs": "• raster_in: SpatRaster monocapa o multicapa.\n• cell_size: Tamaño de celda en metros (20 m).\n• square: TRUE para cuadrados, FALSE para hexágonos.\n• discard_na: Elimina celdas fuera de los datos reales.\n• general: Si TRUE, fusiona la funcionalidad de resumen general de toda la escena.\n• exact_boundary: Si general=TRUE, traza el contorno exacto de datos válidos.",
        "outputs": "Objeto 'terra::SpatVector' con geometrías de celda (o polígono único 'GENERAL') y columnas de media para cada capa ráster.",
        "process": "1. Si general=TRUE: agrega datos válidos, vectoriza la huella de vuelo, asigna grid_id='GENERAL', extrae medias globales y retorna el SpatVector de referencia.\n2. Si general=FALSE: crea grilla con sf::st_make_grid() sobre la extensión, asigna IDs correlativos ('G%04d' o 'H%04d'), extrae medias zonales con terra::extract(bind=TRUE) y poda celdas vacías si discard_na=TRUE.",
        "math": "MediaZonal_k = (1 / N_k) ∑_(p ∈ Celda_k) Valor_p",
        "notes": "FUSIÓN ARQUITECTURAL: La integración de 'general = TRUE' dentro de d4h_summarize_grid unifica la extracción territorial por celdas y la extracción global de toda la comunidad en una sola función consistente."
    },
    {
        "name": "d4h_grid_distance_to_water(grid, water_bodies, decay_lambda = 100.0, buffer_breaks = c(50, 100, 200), ...)",
        "category": "Zonificación Territorial",
        "purpose": "Evalúa el nivel de riesgo y proximidad a agua a nivel de celda territorial completa (no solo casas), priorizando sectores de intervención.",
        "inputs": "• grid: sf o SpatVector de celdas.\n• water_bodies: sf o SpatVector de agua.\n• decay_lambda: 100.0 m.",
        "outputs": "Objeto 'sf' con dist_water_m (distancia mínima de celda a agua), nearest_water_id, proximity_score y proximity_level.",
        "process": "1. Homologa CRS entre grilla y agua.\n2. Calcula st_distance(grid_sf, water_sf).\n3. Extrae distancias mínimas y calcula score exponencial exp(-d/λ).\n4. Clasifica en estratos operativos ('Critical (<50m)', 'High (50-100m)', etc.).",
        "math": "ScoreCelda = exp( - DistanciaBordeCeldaABordeAgua / λ )",
        "notes": "Permite priorizar qué cuadrante territorial debe fumigarse primero, integrando el riesgo de terrenos baldíos con agua."
    },
    {
        "name": "d4h_grid_composition(grid, water = NULL, buildings = NULL, ndvi_raster = NULL, veg_threshold = 0.3, soil_threshold = 0.15, out_xlsx = NULL)",
        "category": "Zonificación Territorial",
        "purpose": "Calcula el perfil porcentual de coberturas físicas (pct_houses, pct_water, pct_vegetation, pct_bare_soil), conteo de entidades y clase dominante por cada celda de grilla.",
        "inputs": "• grid: sf o SpatVector.\n• water: Capa de agua.\n• buildings: Capa de casas.\n• ndvi_raster: NDVI para discriminar vegetación y suelo.\n• veg_threshold: 0.3 ; soil_threshold: 0.15.\n• out_xlsx: Ruta opcional para exportar Excel estructurado de 3 hojas.",
        "outputs": "Objeto 'sf' con pct_houses, pct_water, pct_vegetation, pct_bare_soil, n_houses, n_water_bodies, dominant_class y surveillance_priority.",
        "process": "1. Calcula área en m² de cada celda con st_area().\n2. Intersecta polígonos de agua con grilla (st_intersection), suma áreas por celda y calcula pct_water = (area_agua / area_celda) * 100.\n3. Intersecta polígonos de casas y calcula pct_houses y n_houses.\n4. Extrae píxeles de NDVI por celda: clasifica en vegetación (NDVI >= 0.3) y suelo desnudo (NDVI < 0.15). Distribuye el área remanente proporcionalmente para que la suma total sea exactamente 100%.\n5. Determina dominant_class mediante which.max().\n6. Clasifica en prioridad epidemiológica: 'Critical' si coexisten casas y agua (w_pct>=5% & b_pct>=5% o n_water>=1 & n_casas>=1).\n7. Si se pide out_xlsx, exporta 3 hojas: Grid_Composition, Priority_Stratification y Global_Class_Distribution.",
        "math": "Pct_Clase = ( ∑ Área(Polígonos_Clase ∩ Celda_k) / Área_Celda_k ) × 100",
        "notes": "La clasificación de prioridad detecta la co-ocurrencia espacial: un charco en medio de la selva es hábitat natural, pero un charco dentro de la misma celda de 50m que contiene dos viviendas es una emergencia sanitaria crítica."
    },
    {
        "name": "d4h_raster_general(raster_in)",
        "category": "Zonificación Territorial",
        "purpose": "Crea un SpatRaster continuo donde todos los píxeles válidos toman la media global de la escena. Nota: En la versión actual, 'd4h_plot(..., general = TRUE)' renderiza este mapa de base directamente sin requerir generar un ráster intermedio.",
        "inputs": "• raster_in: SpatRaster monocapa o multicapa.",
        "outputs": "SpatRaster continuo con la media global asignada a cada píxel válido.",
        "process": "Extrae la media global con terra::global(mean) y la proyecta matricialmente sobre la máscara de celdas válidas.",
        "math": "Pixel_Homogéneo = MediaGlobal(Ráster)",
        "notes": "Utilizado primordialmente en mapas swipe interactivos para comparar celdas heterogéneas contra el promedio de toda la comunidad."
    },

    # -------------------------------------------------------------
    # GRUPO 8: ANÁLISIS FOCAL PERIDOMICILIARIO
    # -------------------------------------------------------------
    {
        "name": "d4h_indicator_buffer(indicator = 'NDVI', houses, radius = 3, cell_size = 50, radius_in_meters = FALSE, ..., mask_outside = TRUE, plot = TRUE)",
        "category": "Optimización Focal Peridomiciliaria",
        "purpose": "Acelera radicalmente la computación recortando y calculando indicadores EXCLUSIVAMENTE dentro del área de influencia (buffer en metros o celdas) alrededor de viviendas GPS, generando un mapa ggplot2 listo para publicación.",
        "inputs": "• indicator: Nombre de índice ('NDVI', 'SAVI', etc.), función personalizada o SpatRaster.\n• houses: CSV, Excel, data.frame, sf o SpatVector con coordenadas de casas (lon/lat o x/y).\n• radius: Radio de buffer (defecto: 3 celdas = 150m).\n• cell_size: 50m.\n• radius_in_meters: FALSE (interpreta radius como celdas; distancia = radius * cell_size).\n• nir, red, green, blue, red_edge, dem, lst: Bandas crudas.\n• mask_outside: Enmascara el exterior del buffer como NA.\n• plot: Genera gráfico ggplot2.",
        "outputs": "Objeto de clase S3 'd4h_buffer_analysis' (lista con: $raster recortado, $houses filtradas, $buffer envolvente, $grid zonal, $plot ggplot).",
        "process": "1. Distancia de buffer = radius * cell_size (si radius_in_meters=FALSE).\n2. Parsea coordenadas de casas (soporta lon/lat, utm_x/utm_y de Excel o CSV) y transforma al CRS del ráster.\n3. Genera buffer con sf::st_buffer() y une polígonos con sf::st_union().\n4. Extrae bounding box del buffer y RECORTA LAS BANDAS CRUDAS CON terra::crop() ANTES DE CUALQUIER CÁLCULO.\n5. Ejecuta la fórmula del índice solo sobre la sub-matriz recortada (ahorro de 90% de tiempo y RAM).\n6. Si mask_outside=TRUE, enmascara con terra::mask().\n7. Extrae resumen de grilla y renderiza d4h_plot() con casas en rojo y línea discontinua del buffer.",
        "math": "DistanciaBuffer = { Radio × TamañoCelda si no en metros ; Radio en metros }\nMatriz_Focal = Crop(Ráster_Crudo, BBox(Buffer_Casas))",
        "notes": "DECISIÓN ARQUITECTURAL MAESTRA: En un vuelo de 150 millones de píxeles, calcular un índice sobre toda la escena toma 40 segundos. Si las casas están agrupadas en 2 hectáreas, recortar las bandas antes de operar toma menos de 2 segundos. Permite escalabilidad masiva."
    },

    # -------------------------------------------------------------
    # GRUPO 9: ESTADÍSTICA, REPORTES Y EXPORTACIÓN
    # -------------------------------------------------------------
    {
        "name": "d4h_list_metrics(category = NULL)",
        "category": "Estadística y Reportes",
        "purpose": "Catálogo dinámico e interactivo de métricas. Inspecciona en tiempo real las funciones activas del paquete y retorna una tabla (tibble) con los 21 índices espectrales, topográficos y epidemiológicos, sus fórmulas matemáticas y aplicaciones en salud pública.",
        "inputs": "• category: Filtro opcional ('Spectral', 'Topographic', 'Epidemiological', o NULL para todas).",
        "outputs": "Un 'tibble' con columnas: category, metric, function_name, resolution_cm, formula, application.",
        "process": "1. Define el catálogo completo de métricas soportadas.\n2. Comprueba dinámicamente getNamespaceExports('drones4health') para reflejar las funciones activas del namespace.\n3. Filtra por categoría si el usuario lo especifica y retorna el tibble.",
        "math": "Catálogo Dinámico: Métricas_Activas = Catálogo ∩ NamespaceExports",
        "notes": "Actualizada y dinámica: a diferencia de las versiones estáticas anteriores, ahora refleja con precisión la totalidad de los índices disponibles en el paquete."
    },
    {
        "name": "d4h_executive_summary(raster_in, by = c('general', 'grid'), grid = NULL, houses_proximity = NULL, cell_size = 50, square = TRUE, out_xlsx = NULL, ...)",
        "category": "Estadística y Reportes",
        "purpose": "Genera el informe ejecutivo integral del proyecto: diagnóstico de outliers espaciales según Tukey IQR, estratificación biofísica por umbrales, superficie en hectáreas y análisis de viviendas, ya sea a nivel global (by='general') o celda por celda (by='grid').",
        "inputs": "• raster_in: SpatRaster monocapa o multicapa.\n• by: 'general' (informe de toda la escena) o 'grid' (una fila por celda de grilla).\n• grid: Opcional, grilla preexistente.\n• houses_proximity: sf de casas con distancia a agua.\n• cell_size: 50m ; square: TRUE.\n• out_xlsx: Ruta de exportación Excel.\n• sample_size: 1,000,000 celdas.\n• digits: 3.",
        "outputs": "Objeto de clase 'd4h_executive_summary' (lista estructurada por capa para by='general') o 'd4h_grid_summary' (data.frame de una fila por celda para by='grid').",
        "process": "EN MODO GENERAL (by='general'):\n1. Calcula resolución y área de celda (res_x * res_y), número de píxeles válidos (n_valid) y cobertura útil del vuelo.\n2. Muestra píxeles y calcula media, sd, cv_pct (coeficiente de variación), rango, cuantiles (P05, P10, Q25, Q50, Q75, P90, P95) y rango intercuartílico (IQR = Q75 - Q25).\n3. DIAGNÓSTICO DE TUKEY: Valla inferior = Q25 - 1.5*IQR; Valla superior = Q75 + 1.5*IQR. Cuenta outliers bajos y altos, porcentaje total y diagnóstico cualitativo de dispersión.\n4. ESTRATIFICACIÓN TEMÁTICA: Clasifica los píxeles según el tipo de índice (ej. para NDVI: Agua <0, Suelo [0, 0.2), Moderado [0.2, 0.5), Denso >=0.5) y calcula tanto el porcentaje (%) como la superficie real en hectáreas (ha).\n5. Si se provee houses_proximity, agrega resumen de exposición de viviendas.\n6. Si out_xlsx está definido, exporta a libro Excel estructurado mediante d4h_export_summary().\n\nEN MODO GRILLA (by='grid'):\n1. Recorta el ráster a la grilla y extrae valores con terra::extract().\n2. Para cada celda calcula: píxeles válidos, media, sd, cv%, min, max, mediana, IQR, porcentaje de outliers de Tukey y porcentajes de estratos.\n3. Si out_xlsx está definido, genera hojas 'Grid_Summary' y 'Global_Grid_Summary'.",
        "math": "IQR = Q_75 - Q_25\nValla_Inferior = Q_25 - 1.5 × IQR\nValla_Superior = Q_75 + 1.5 × IQR\nCV_(%) = (SD / |Media|) × 100\nSuperficie_(ha) = (PíxelesVálidos × res_x × res_y) / 10,000",
        "notes": "MÉTODO S3 COMPLETO: Posee métodos print.d4h_executive_summary() (que imprime un reporte de consola formateado con caracteres ASCII), as.data.frame.d4h_executive_summary() y d4h_export_summary()."
    },
    {
        "name": "d4h_export_summary(x, out_xlsx, houses_proximity = NULL)",
        "category": "Estadística y Reportes",
        "purpose": "Exporta un objeto 'd4h_executive_summary' a un archivo Excel multi-hoja profesional (.xlsx) utilizando writexl u openxlsx.",
        "inputs": "• x: Objeto d4h_executive_summary.\n• out_xlsx: Ruta del archivo .xlsx a crear.\n• houses_proximity: Opcional, datos de viviendas.",
        "outputs": "Retorna 'x' de forma invisible y escribe el archivo en disco.",
        "process": "Construye data.frames para:\n1. Hoja 'Global_Summary': Métricas espaciales, resolución, área en ha, píxeles válidos, momentos estadísticos, percentiles y diagnóstico de outliers.\n2. Hoja 'Thematic_Strata': Estratificación biofísica con porcentaje y hectáreas por estrato.\n3. Hoja 'Outliers_Diagnostics': Vallas de Tukey, conteo y porcentaje de anomalías.\n4. Hoja 'Household_Water_Proximity': Detalle de cada vivienda (ID, coordenadas X/Y, distancia en metros al agua, ID del cuerpo de agua más cercano, score de proximidad y nivel de riesgo).\n5. Hoja 'Household_Proximity_Summary': Conteo de viviendas, porcentaje y distancias media/mín/máx agrupadas por estrato de proximidad.\nEscribe con writexl::write_xlsx o openxlsx::write.xlsx. Si ninguno está instalado, guarda la primera hoja en CSV.",
        "math": "N/A",
        "notes": "Estructura multi-pestaña diseñada para presentar informes ejecutivos directamente ante ministerios de salud o comités técnicos."
    },

    # -------------------------------------------------------------
    # GRUPO 10: VISUALIZACIÓN CARTOGRÁFICA E INTERACTIVA
    # -------------------------------------------------------------
    {
        "name": "d4h_plot(x = NULL, y = NULL, interactive = FALSE, grid = NULL, houses = NULL, buildings = NULL, water = NULL, water_color = '#00B0FF', rgb_bands = NULL, palette = 'viridis', limits = NULL, ..., ortho = NULL, general = FALSE)",
        "category": "Visualización Cartográfica",
        "purpose": "Función unificada de ploteo. Soporta capas simples o comparativas duales (x e y), superposición integral de cuerpos de agua ('water'), edificaciones ('houses'/'buildings') y grillas sobre ortomosaicos RGB ('ortho'). Renderiza gráficos estáticos de publicación (ggplot2 + tidyterra) o mapas interactivos web (mapview/leaflet con swipe). Incorpora 'general = TRUE' para mapear la línea base homogénea comunal.",
        "inputs": "• x: Capa principal (SpatRaster, SpatVector, sf, data.frame o ruta). Soporta resolver nombres de columna si se pasa x = 'dist_water_m'.\n• y: Capa secundaria para comparación (ej. NDVI vs NDWI).\n• interactive: FALSE (gráfico estático ggplot2) o TRUE (mapa web interactivo).\n• grid: Grilla para superponer contornos celulares.\n• houses / buildings: Casas o techos para superponer (puntos o polígonos sf).\n• water: Cuerpos de agua o charcos segmentados (sf POLYGON) para superponer en color celeste (#00B0FF).\n• water_color: Color de relleno para agua (default: '#00B0FF').\n• rgb_bands: Vector c(1, 2, 3) para componer RGB color verdadero/falso.\n• palette, palette_y: Paletas ('viridis', 'magma', 'spectral', 'terrain').\n• limits, limits_y: Límites manuales de escala de color.\n• zcol: Columna numérica o categórica para colorear polígonos (ej. 'risk_level' o 'dist_water_m').\n• ortho: Ortomosaico RGB de fondo para poner bajo vectores.\n• general: Si TRUE, transforma rásters a mosaicos homogéneos de la media global antes de ploteo.",
        "outputs": "Un objeto 'ggplot' (si interactive = FALSE) o un widget htmlwidget / objeto 'mapview' (si interactive = TRUE).",
        "process": "1. Resuelve alias (buildings -> houses) y si x es un string correspondiente a una columna de houses/water, reasigna automáticamente zcol = x y x = houses.\n2. Si general=TRUE, transforma rásters a mosaico continuo de la media global de la escena.\n3. Si ortho existe, dibuja primero el ortomosaico RGB de fondo con tidyterra::geom_spatraster_rgb().\n4. Si water existe, superpone los cuerpos de agua en color celeste (#00B0FF).\n5. Dibuja las edificaciones o grilla coloreadas según zcol o estrato semafórico ('Critico', 'Alto', 'Moderado', 'Bajo').\n6. Si interactive=TRUE, compone las capas interactivamente en mapview.",
        "math": "Mosaico General si general=TRUE: x' = ifel(!is.na(x) & x!=0, MediaGlobal(x), NA)",
        "notes": "DISEÑO MULTICAPA RESILIENTE: Soporta capas simultáneas (ortomosaico + cuerpos de agua + viviendas estratificadas) en una sola llamada sin requerir armar capas de ggplot2 manualmente."
    },
    {
        "name": "d4h_mapview_swipe(x, y, grid = NULL, basemap = TRUE, col_x = 'viridis', col_y = 'magma', limits_x = NULL, limits_y = NULL, max_pixels = 500000)",
        "category": "Visualización Cartográfica",
        "purpose": "Crea un visor interactivo de cortina deslizante (swipe slider) de lado a lado en Leaflet/Mapview para contrastar dos ortomosaicos ráster sobre mapas base de satélite o calles.",
        "inputs": "• x, y: Capas izquierda y derecha.\n• grid: Grilla opcional.\n• basemap: Activa satélite Esri y OpenStreetMap (TRUE).\n• col_x, col_y: Paletas de color.\n• limits_x, limits_y: Límites de corte cuantitativo (o cuantiles 2%-98% automáticos).\n• max_pixels: Límite de resolución para fluidez en el navegador (500,000 celdas).",
        "outputs": "Un widget interactivo htmlwidget / leaflet con control deslizante horizontal.",
        "process": "1. Ingiere y valida capas x e y con .prep_swipe_layer().\n2. Si celdas > max_pixels, aplica agregación piramidal con terra::aggregate() para que el navegador no se congele.\n3. Reproyecta explícitamente a Web Mercator EPSG:3857 con método bilineal.\n4. Detecta si la capa es binaria (0 y 1, ej. suelo desnudo) o continua; si es continua, calcula cuantiles robustos al 2% y 98% para evitar que outliers estiren la paleta.\n5. Clampa rásters a los límites y convierte a raster::raster().\n6. Crea mapa leaflet con addMapPane para izquierda y derecha, agrega imágenes ráster, inserta el control swipe con addSidebyside(), y añade dos leyendas independientes (izquierda y derecha).",
        "math": "Límites Robustos Automáticos: Límite_Inf = Cuantil(0.02) ; Límite_Sup = Cuantil(0.98)",
        "notes": "La barra deslizante permite a epidemiólogos inspeccionar visualmente si una zona clasificada como 'suelo desnudo' o 'agua estancada' coincide exactamente con la fotografía aérea real moviendo el ratón."
    }
]

print(f"Definidas {len(FUNCTIONS_DATA)} funciones activas y optimizadas en FUNCTIONS_DATA.")
