# -*- coding: utf-8 -*-
"""
Constructor integral de la Guía de Estudio Maestra del paquete drones4health
Genera el archivo: Guia_de_Estudio_drones4health.docx
"""
import sys
import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

def create_guide():
    doc = docx.Document()
    
    # 1. Configuración de página y márgenes
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.5)
        section.page_height = Inches(11.0)
        
        # Header y Footer
        hp = section.header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("drones4health | Guía de Estudio y Manual Técnico")
        hrun.font.name = "Calibri"
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = RGBColor(120, 120, 120)
        
        fp = section.footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        frun = fp.add_run("Vigilancia Eco-Epidemiológica de Precisión con VANT/Drones - Manual de Examen y Referencia")
        frun.font.name = "Calibri"
        frun.font.size = Pt(8.5)
        frun.font.color.rgb = RGBColor(140, 140, 140)

    # Colores
    C_NAVY = RGBColor(27, 54, 93)      # #1B365D
    C_TEAL = RGBColor(0, 128, 128)     # #008080
    C_SLATE = RGBColor(46, 91, 136)    # #2E5B88
    C_DARK = RGBColor(34, 34, 34)      # #222222
    
    HEX_LIGHT_BG = "F4F6F9"
    HEX_CALLOUT_BORDER = "1B365D"
    HEX_HEADER_BG = "1B365D"
    HEX_ZEBRA = "F8F9FA"

    # Funciones de apoyo para tipografía y estructura
    def add_title(text, subtitle=None):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(20)
        p.paragraph_format.space_after = Pt(4)
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(24)
        run.font.bold = True
        run.font.color.rgb = C_NAVY
        
        if subtitle:
            p_sub = doc.add_paragraph()
            p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_sub.paragraph_format.space_before = Pt(2)
            p_sub.paragraph_format.space_after = Pt(20)
            run_sub = p_sub.add_run(subtitle)
            run_sub.font.name = "Calibri"
            run_sub.font.size = Pt(12)
            run_sub.font.italic = True
            run_sub.font.color.rgb = C_SLATE

    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(16)
        run.font.bold = True
        run.font.color.rgb = C_NAVY

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(13)
        run.font.bold = True
        run.font.color.rgb = C_SLATE

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(11)
        run.font.bold = True
        run.font.color.rgb = C_TEAL

    def add_p(text, bold_prefix=None, space_after=4):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_pre = p.add_run(bold_prefix)
            r_pre.font.name = "Calibri"
            r_pre.font.size = Pt(10)
            r_pre.font.bold = True
            r_pre.font.color.rgb = C_DARK
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(10)
        run.font.color.rgb = C_DARK
        return p

    def add_bullet(text, bold_prefix=None):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_before = Pt(1)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_pre = p.add_run(bold_prefix)
            r_pre.font.name = "Calibri"
            r_pre.font.size = Pt(10)
            r_pre.font.bold = True
            r_pre.font.color.rgb = C_DARK
        run = p.add_run(text)
        run.font.name = "Calibri"
        run.font.size = Pt(10)
        run.font.color.rgb = C_DARK
        return p

    def add_callout(text, title="DECISIÓN DE DISEÑO / NOTA CRÍTICA:"):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        
        tcPr = cell._tc.get_or_add_tcPr()
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{HEX_LIGHT_BG}"/>')
        tcPr.append(shd)
        
        tcBorders = parse_xml(f'''
            <w:tcBorders {nsdecls("w")}>
                <w:top w:val="none"/>
                <w:left w:val="single" w:sz="24" w:space="0" w:color="{HEX_CALLOUT_BORDER}"/>
                <w:bottom w:val="none"/>
                <w:right w:val="none"/>
            </w:tcBorders>
        ''')
        tcPr.append(tcBorders)
        
        tcMar = parse_xml(f'''
            <w:tcMar {nsdecls("w")}>
                <w:top w:w="100" w:type="dxa"/>
                <w:bottom w:w="100" w:type="dxa"/>
                <w:left w:w="150" w:type="dxa"/>
                <w:right w:w="150" w:type="dxa"/>
            </w:tcMar>
        ''')
        tcPr.append(tcMar)
        
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.15
        
        r_title = p.add_run(f"{title} ")
        r_title.font.name = "Calibri"
        r_title.font.size = Pt(9.5)
        r_title.font.bold = True
        r_title.font.color.rgb = C_NAVY
        
        r_body = p.add_run(text)
        r_body.font.name = "Calibri"
        r_body.font.size = Pt(9.5)
        r_body.font.color.rgb = C_DARK
        
        p_post = doc.add_paragraph()
        p_post.paragraph_format.space_before = Pt(0)
        p_post.paragraph_format.space_after = Pt(4)

    def add_table_styled(headers, rows, col_widths=None):
        table = doc.add_table(rows=len(rows) + 1, cols=len(headers))
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        
        hdr_cells = table.rows[0].cells
        for i, header_text in enumerate(headers):
            cell = hdr_cells[i]
            cell.text = header_text
            tcPr = cell._tc.get_or_add_tcPr()
            shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{HEX_HEADER_BG}"/>')
            tcPr.append(shd)
            
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(4)
            p.paragraph_format.space_after = Pt(4)
            for r in p.runs:
                r.font.name = "Calibri"
                r.font.size = Pt(9)
                r.font.bold = True
                r.font.color.rgb = RGBColor(255, 255, 255)
            
            if col_widths and i < len(col_widths):
                cell.width = col_widths[i]
        
        for r_idx, row_data in enumerate(rows):
            row_cells = table.rows[r_idx + 1].cells
            bg_color = HEX_ZEBRA if (r_idx % 2 == 1) else "FFFFFF"
            for c_idx, cell_value in enumerate(row_data):
                cell = row_cells[c_idx]
                cell.text = str(cell_value)
                tcPr = cell._tc.get_or_add_tcPr()
                if bg_color != "FFFFFF":
                    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{bg_color}"/>')
                    tcPr.append(shd)
                
                bdr = parse_xml(f'''
                    <w:tcBorders {nsdecls("w")}>
                        <w:top w:val="none"/>
                        <w:left w:val="none"/>
                        <w:bottom w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>
                        <w:right w:val="none"/>
                    </w:tcBorders>
                ''')
                tcPr.append(bdr)
                
                tcMar = parse_xml(f'''
                    <w:tcMar {nsdecls("w")}>
                        <w:top w:w="60" w:type="dxa"/>
                        <w:bottom w:w="60" w:type="dxa"/>
                        <w:left w:w="80" w:type="dxa"/>
                        <w:right w:w="80" w:type="dxa"/>
                    </w:tcMar>
                ''')
                tcPr.append(tcMar)
                
                p = cell.paragraphs[0]
                p.paragraph_format.space_before = Pt(2)
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.line_spacing = 1.1
                for r in p.runs:
                    r.font.name = "Calibri"
                    r.font.size = Pt(8.5)
                    r.font.color.rgb = C_DARK
                
                if col_widths and c_idx < len(col_widths):
                    cell.width = col_widths[c_idx]
        
        p_post = doc.add_paragraph()
        p_post.paragraph_format.space_before = Pt(0)
        p_post.paragraph_format.space_after = Pt(6)

    print("Iniciando redaccion del documento...")

    # =========================================================================
    # PORTADA
    # =========================================================================
    add_title(
        "GUÍA MAESTRA DE ESTUDIO Y DEFRENSA TÉCNICA",
        "Paquete R 'drones4health': Ultra-High Resolution Drone Metrics for Spatial Health Analysis"
    )
    
    # Cuadro resumen de metadatos del paquete
    meta_headers = ["Atributo del Paquete", "Detalle Técnico y Configuración"]
    meta_rows = [
        ["Nombre Oficial", "drones4health (Versión 0.1.0)"],
        ["Propósito Central", "Cálculo y extracción de métricas de teledetección de ultra-alta resolución (UAV/drones) para epidemiología espacial y vigilancia de precisión de vectores."],
        ["Autor y Mantenedor", "Josue Florian (josue.florian@example.com)"],
        ["Licencia", "MIT + file LICENSE"],
        ["Dependencias Principales (Imports)", "terra (>= 1.7), sf (>= 1.0), ggplot2 (>= 3.4), tibble (>= 3.2)"],
        ["Dependencias Sugeridas (Suggests)", "leaflet, leaflet.extras2, mapview, raster, openxlsx, writexl, viridisLite, leafsync"],
        ["Soporte Deep Learning (GeoAI)", "Meta Segment Anything Model (SAM) vía reticulate y PyTorch (CPU/CUDA)"],
        ["Resolución de Trabajo Típica", "GSD de 2 a 10 cm/píxel (UAV multiespectral, térmico y RGB fotogramétrico)"]
    ]
    add_table_styled(meta_headers, meta_rows, [Inches(2.2), Inches(4.3)])

    add_p("Esta guía de estudio recopila, analiza y desglosa exhaustivamente todas las decisiones de diseño de software, fundamentos matemáticos, fórmulas biofísicas, flujo de datos (inputs/outputs), clases de objetos en R, metadatos raster vs. variables calculadas, y teoría espacial que sustentan el paquete drones4health. Ha sido estructurada para servir como manual de consulta y defensa técnica rigurosa ante cualquier evaluación académica, técnica o profesional.")

    # =========================================================================
    # SECCIÓN 1: INTRODUCCIÓN Y ARQUITECTURA GENERAL
    # =========================================================================
    add_h1("1. Introducción y Arquitectura General del Paquete")
    
    add_h2("1.1 ¿Por qué nace drones4health? El reto de la teledetección satelital vs. UAV")
    add_p("En la epidemiología de enfermedades transmitidas por vectores (como el Dengue, Zika, Chikungunya transmitidos por Aedes aegypti; la Malaria por Anopheles; o la Esquistosomiasis por caracoles dulceacuícolas), la ecología de transmisión ocurre a una micro-escala espacial de entre 1 y 50 metros. Los sensores satelitales clásicos de libre acceso (Landsat con 30 metros de resolución espacial, o Sentinel-2 con 10 metros por píxel) sufren del problema de 'píxel mixto': un solo píxel de 10x10 metros promedia simultáneamente un tejado de calamina, un charco de agua estancada, un árbol y un patio de tierra desnuda. Por lo tanto, los satélites son ciegos ante criaderos larvales pequeños, neumáticos desechados, micro-depresiones topográficas y acumulaciones plásticas peridomiciliarias.")
    add_p("Los vehículos aéreos no tripulados (VANT o drones) resuelven este problema al volar a baja altitud (50 a 120 metros), generando ortomosaicos con una resolución espacial ultra-alta (GSD de 2 a 5 cm por píxel). A esta escala, un charco de 50 cm de diámetro está cubierto por más de 100 píxeles individuales, permitiendo una detección biofísica precisa.")
    
    add_h2("1.2 El desafío computacional de los drones y la elección de 'terra' sobre 'raster'")
    add_p("El reverso de la ultra-alta resolución es el volumen masivo de datos: una escena pequeña de 10 hectáreas a 3 cm/píxel contiene más de 110 millones de celdas por banda. Procesar múltiples bandas (Red, Green, Blue, Red Edge, NIR, Térmico, DEM) desborda fácilmente la memoria RAM tradicional de R.")
    add_callout(
        "El paquete 'drones4health' está construido nativamente sobre la biblioteca 'terra' (C++ con punteros SpatRaster), abandonando el paquete legacy 'raster'. A diferencia de 'raster', 'terra' implementa evaluación perezosa (lazy evaluation), lectura por bloques secuenciales en disco sin cargar toda la matriz en RAM, y paralelización interna en C++. Esto evita errores de 'std::bad_alloc' y acelera los cálculos entre 5x y 25x.",
        "ARQUITECTURA DE RENDIMIENTO:"
    )

    add_h2("1.3 Pipeline de Procesamiento en 6 Fases")
    add_p("El paquete organiza el flujo de trabajo en seis fases estrictas e interconectadas:")
    add_bullet("Ingestión, validación estricta de nombres y verificación de bandas mínimas requeridas.", "Fase 1 (Ingestión y Normalización): ")
    add_bullet("Cálculo de índices espectrales, micro-topográficos (DEM) y eco-epidemiológicos combinados.", "Fase 2 (Generación de Métricas): ")
    add_bullet("Segmentación de agua y techos de viviendas mediante umbralización espectral con filtros ópticos de brillo o Deep Learning (SAM).", "Fase 3 (Extracción de Objetos / OBIA): ")
    add_bullet("Cálculo de distancias euclidianas mínimas dwelling-to-water y modelos de decaimiento exponencial del riesgo de picadura.", "Fase 4 (Modelado Espacial de Exposición): ")
    add_bullet("Teselación regular (cuadrada o hexagonal) de 20m a 50m, recorte a la huella de vuelo real y agregación zonal de estadísticas.", "Fase 5 (Zonificación Operativa): ")
    add_bullet("Extracción focal peridomiciliaria (buffers), diagnóstico de outliers con vallas de Tukey, tablas multi-hoja en Excel y cartografía estática/interactiva (leaflet/mapview).", "Fase 6 (Reportes y Visualización): ")

    # =========================================================================
    # SECCIÓN 2: DICCIONARIO TÉCNICO Y CONCEPTOS ESENCIALES
    # =========================================================================
    add_h1("2. Diccionario Técnico Exhaustivo ('Cosas a Saber')")
    add_p("Para responder con solvencia cualquier interrogante sobre el paquete, es imperativo dominar los siguientes conceptos tecnológicos, geoespaciales y estadísticos utilizados en el código:")

    terms = [
        ("sf (Simple Features for R)", 
         "Estándar internacional ISO 19125 de Open Geospatial Consortium (OGC) implementado en R. Representa datos vectoriales (puntos, líneas, polígonos) dentro de un data.frame nativo, donde los atributos tabulares son columnas estándar y la información espacial reside en una columna especial de lista llamada 'geometry' (clase sfc). Permite usar funciones de manipulación de datos estándar (dplyr, subsetting base) manteniendo la topología espacial calculada por la librería C++ GEOS. En el paquete se utiliza para viviendas, cuerpos de agua segmentados, buffers peridomiciliarios y grillas de vigilancia."),
        
        ("terra", 
         "Paquete moderno de R creado por Robert Hijmans para el análisis espacial masivo de datos ráster y vectoriales. Reemplazó al paquete 'raster'. Sus clases principales son 'SpatRaster' (matrices celulares georreferenciadas con una o más capas) y 'SpatVector' (geometrías vectoriales optimizadas en C++). 'terra' se comunica directamente con las librerías de sistema GDAL y PROJ sin puentes intermedios, ofreciendo una velocidad de ejecución drásticamente superior y soporte para rásters de gigabytes."),
        
        ("raster (Paquete Legacy)", 
         "El predecesor de 'terra'. Aunque ya no se recomienda para nuevos desarrollos por su lentitud y alto consumo de RAM, 'drones4health' lo incluye en 'Suggests' debido a una restricción técnica externa: los paquetes de mapas web interactivos 'leaflet' y 'mapview' históricamente exigen objetos de clase 'RasterLayer' para su renderizado. Por ello, funciones como 'd4h_plot(interactive = TRUE)' y 'd4h_mapview_swipe()' convierten temporalmente el 'SpatRaster' optimizado a 'raster::raster()' solo en el momento final de visualización en el navegador."),
        
        ("GeoTIFF (.tif)", 
         "Formato estándar de facto en teledetección. Es una imagen TIFF extendida que incluye 'GeoKeys' en sus metadatos (etiquetas de cabecera). Estas claves codifican el Sistema de Referencia de Coordenadas (CRS), las coordenadas de las esquinas en el terreno (bounding box), la resolución espacial por celda y el valor representativo de ausencia de datos (NoData). Puede contener desde una banda en escala de grises hasta decenas de bandas espectrales en formato flotante o entero."),
        
        ("CRS (Coordinate Reference System), Proyecciones y Datums", 
         "Un CRS define cómo la superficie esférica o elipsoidal de la Tierra se proyecta sobre un plano bidimensional. Se dividen en: (1) Geográficas (ej. WGS84, EPSG:4326), expresadas en grados sexagesimales (latitud/longitud); y (2) Proyectadas (ej. UTM Zona 18S, EPSG:32718), expresadas en metros lineales. CRÍTICO: En drones4health, todas las funciones de distancias, áreas, grillas y buffers EXIGEN coordenadas proyectadas métricas (UTM), porque en coordenadas geográficas un grado no equivale a una distancia fija (1° varía con la latitud)."),
        
        ("EPSG:3857 (Web Mercator)", 
         "Sistema de proyección conforme utilizado universalmente por Google Maps, OpenStreetMap y Leaflet. Preserva ángulos pero distorsiona áreas en latitudes altas. En 'd4h_mapview_swipe()', el paquete reproyecta automáticamente las capas a EPSG:3857 mediante interpolación bilineal para garantizar que el ráster se alinee perfectamente sobre los mosaicos satelitales de fondo."),
        
        ("GDAL y PROJ", 
         "GDAL (Geospatial Data Abstraction Library) es el motor universal en C/C++ para lectura, escritura y transformación de más de 200 formatos ráster y vectoriales. PROJ es la librería estándar para transformaciones cartográficas y reproyecciones geodésicas. 'terra' y 'sf' son interfaces de alto nivel en R construidas sobre GDAL y PROJ."),
        
        ("OBIA (Object-Based Image Analysis)", 
         "Análisis de Imágenes Basado en Objetos. En lugar de clasificar píxeles aislados (que a 3 cm/píxel generan un ruido 'sal y pimienta' inservible), OBIA agrupa píxeles contiguos con propiedades espectrales similares en objetos vectoriales discretos (polígonos). Permite calcular atributos geométricos imposibles a nivel de píxel: área real en m², perímetro, relación forma/alargamiento y distancia euclidiana a otros objetos."),
        
        ("SAM (Segment Anything Model de Meta AI)", 
         "Modelo fundacional de visión por computadora desarrollado por Meta AI basado en una arquitectura Vision Transformer (ViT). Permite segmentación zero-shot guiada por prompts automáticos ('points_per_side = 16'). En 'd4h_segment_water()' y 'd4h_segment_buildings()', el paquete se conecta con SAM mediante 'reticulate' y PyTorch, convirtiendo las máscaras booleanas de tensores de Python directamente en polígonos 'sf' en R."),
        
        ("MAUP (Modifiable Areal Unit Problem)", 
         "Sesgo estadístico bien documentado en geografía: cuando datos puntuales o continuos se agregan en unidades territoriales artificiales, los resultados estadísticos (medias, correlaciones) pueden cambiar drásticamente según la escala elegida (efecto de escala) o la forma de los límites (efecto de zonificación). drones4health aborda el MAUP permitiendo controlar con precisión el 'cell_size' y promoviendo el uso de hexágonos regulares que reducen el sesgo direccional."),
        
        ("Vallas de Outliers de Tukey (Exploratory Data Analysis)", 
         "Método estadístico robusto no paramétrico para detectar valores atípicos espaciales propuesto por John Tukey. A diferencia del método clásico de la media y 3 desviaciones estándar (que asume erróneamente normalidad y es vulnerable a distorsiones por valores extremos), Tukey define vallas basadas en cuartiles: Q25 - 1.5*IQR y Q75 + 1.5*IQR. Ideal para detectar anomalías ambientales reales (focos térmicos extremos o zonas de hiper-vegetación)."),
        
        ("Interpolación Bilineal vs. Vecino Más Cercano (Nearest Neighbor)", 
         "Métodos de resampleo espacial. El 'Vecino Más Cercano' asigna el valor del píxel original más próximo sin alterarlo (obligatorio para datos categóricos o máscaras binarias de 0 y 1). La 'Interpolación Bilineal' calcula una media ponderada por distancia entre los 4 píxeles circundantes (ideal para variables continuas suaves como NDVI, elevación DEM o temperatura). En el preprocesamiento, 'drones4health' usa interpolación bilineal para alinear bandas que difieren ligeramente en geometría.")
    ]

    for term, desc in terms:
        add_p(desc, bold_prefix=f"{term}: ")

    # =========================================================================
    # SECCIÓN 3: METADATOS DEL TIFF VS VARIABLES CALCULADAS
    # =========================================================================
    add_h1("3. Metadatos Extraídos del GeoTIFF vs. Variables Calculadas")
    add_p("Una de las preguntas más comunes en auditorías técnicas y defensas de código es: ¿Qué valores vienen directamente del archivo GeoTIFF y cuáles son calculados numéricamente por los algoritmos del paquete?")
    add_p("El archivo GeoTIFF contiene una cabecera con metadatos de estructura física y espacial. Sin embargo, toda la interpretación biofísica, momentos estadísticos y modelado epidemiológico son producto de procesamiento algorítmico interno:")

    meta_comp_headers = ["Tipo de Información", "Origen", "Función en R / Comando", "Detalle de la Variable"]
    meta_comp_rows = [
        ["Dimensiones de Matriz", "Metadato de Cabecera", "terra::nrow(), ncol(), ncell()", "Número exacto de filas, columnas y celdas totales de la cuadrícula ráster."],
        ["Resolución Espacial", "Metadato de Cabecera", "terra::res(r)", "Tamaño del píxel en unidades del CRS (ej. 0.045 m = 4.5 cm de GSD)."],
        ["Extensión Espacial (BBox)", "Metadato de Cabecera", "terra::ext(r)", "Coordenadas mínimas y máximas de los bordes: xmin, xmax, ymin, ymax."],
        ["Sistema de Referencia (CRS)", "Metadato de Cabecera", "terra::crs(r)", "Definición WKT/PROJ del elipsoide, datum y proyección cartográfica (ej. UTM)."],
        ["Número de Capas / Bandas", "Metadato de Cabecera", "terra::nlyr(r)", "Cantidad de canales presentes en el GeoTIFF multicapa (ej. 5 capas)."],
        ["Profundidad de Bits (Datatype)", "Metadato de Cabecera", "terra::datatype(r)", "Tipo de dato en disco: INT2U (entero 16-bit 0-65535), INT1U (8-bit), FLT4S (float)."],
        ["Valor de NoData", "Metadato de Cabecera", "terra::sources(r)", "Valor asignado al fondo sin captura (ej. -9999, 0 o NaN)."],
        ["Reflectancia Normalizada (0-1)", "Calculado por d4h", "d4h_normalize_reflectance()", "División de números digitales crudos (DN / 65535) y clamping a [0, 1]."],
        ["Temperatura Superficial (°C)", "Calculado por d4h", "d4h_thermal_to_celsius()", "Calibración radiométrica de sensor térmico: (DN * 0.01) - 273.15."],
        ["Índices Espectrales (NDVI, etc.)", "Calculado por d4h", "d4h_ndvi(), msavi2(), etc.", "Operaciones algebraicas no lineales píxel a píxel combinando canales."],
        ["Micro-Pendiente y TWI", "Calculado por d4h", "d4h_slope(), d4h_twi()", "Cálculo de derivadas espaciales de elevación (gradientes dz/dx, dz/dy)."],
        ["Superficie Real (ha y m²)", "Calculado por d4h", "d4h_executive_summary()", "Píxeles válidos multiplicado por (res_x * res_y), excluyendo fondo NoData."],
        ["Porcentaje de Cobertura Útil", "Calculado por d4h", "d4h_executive_summary()", "Ratio: (n_valid / total_cells) * 100. Mide eficiencia del plan de vuelo."],
        ["Vallas de Outliers de Tukey", "Calculado por d4h", "d4h_executive_summary()", "Límites estadísticos: Q25 - 1.5*IQR (inferior) y Q75 + 1.5*IQR (superior)."],
        ["Polígonos de Huella de Vuelo", "Calculado por d4h", ".d4h_clean_flight_footprint()", "Agregación piramidal, umbralización de datos válidos y vectorización."],
        ["Distancia Euclidiana Mínima", "Calculado por d4h", "d4h_distance_to_water()", "Distancia geométrica del centroide de vivienda al borde de agua más cercano."],
        ["Score de Riesgo Exponencial", "Calculado por d4h", "d4h_distance_to_water()", "Modelado de dispersión de vectores: exp(-distancia / lambda)."],
        ["Composición de Coberturas (%)", "Calculado por d4h", "d4h_grid_composition()", "Intersección geométrica de polígonos por celda para calcular % casas y agua."]
    ]
    add_table_styled(meta_comp_headers, meta_comp_rows, [Inches(1.8), Inches(1.2), Inches(1.5), Inches(2.0)])

    # =========================================================================
    # SECCIÓN 4: TEORÍA Y SIGNIFICADO DE LAS GRILLAS Y CELL_SIZE
    # =========================================================================
    add_h1("4. Teoría Espacial de las Grillas y el Tamaño de Celda ('cell_size')")
    
    add_h2("4.1 ¿Qué significa físicamente 'cell_size'?")
    add_p("El parámetro 'cell_size' (por defecto 50 en la mayoría de funciones de drones4health) define la dimensión métrica característica de cada celda de la grilla de vigilancia:")
    add_bullet("En grillas cuadradas (square = TRUE): 'cell_size' representa la longitud del lado del cuadrado en metros (ancho = alto = cell_size). Un cell_size = 50 genera celdas cuadradas de 50 m x 50 m = 2,500 m² (0.25 hectáreas).", "Celdas Cuadradas: ")
    add_bullet("En grillas hexagonales (square = FALSE): 'cell_size' en 'sf::st_make_grid()' representa la distancia entre vértices paralelos o diámetro exterior del hexágono. Un cell_size = 50 genera un hexágono con área de aproximadamente 2,165 m².", "Celdas Hexagonales: ")

    add_h2("4.2 Justificación Epidemiológica del cell_size = 50 metros")
    add_p("¿Por qué 50 metros y no 5 metros o 500 metros? La decisión de ingeniería epidemiológica responde a dos principios biológicos fundamentales:")
    add_bullet("Los estudios de marcado, liberación y recaptura (MRR) de Aedes aegypti demuestran que las hembras adultas pasan la mayor parte de su vida a menos de 50 a 100 metros del criadero donde emergieron. Por tanto, un radio de 50 metros delimita el ecosistema de transmisión directa o 'peridomicilio'.", "1. Radio de dispersión de vuelo del vector: ")
    add_bullet("Una cuadrícula de 50 metros es una unidad de intervención perfectamente manejable por una brigada de control larvario en un turno operativo: permite inspeccionar todas las viviendas contenidas en ella, aplicar larvicidas y verificar depósitos de agua sin fatiga excesiva.", "2. Capacidad operativa de brigadas de salud: ")

    add_h2("4.3 Grilla Cuadrada vs. Grilla Hexagonal: ¿Por qué preferir hexágonos?")
    add_p("La literatura científica en ecología espacial y el paquete drones4health recomiendan fuertemente el uso de mallas hexagonales (square = FALSE) sobre cuadrículas por las siguientes razones matemáticas:")
    
    add_bullet("En una cuadrícula, cada celda tiene 4 vecinos ortogonales que comparten arista (a distancia d) y 4 vecinos diagonales que solo comparten un vértice (a distancia d * sqrt(2) ≈ 1.414 d). Esto introduce una asimetría direccional artificial. En un hexágono regular, los 6 vecinos contiguos comparten aristas idénticas y la distancia centroide a centroide es estrictamente constante (d = 2 * apotema) en las seis direcciones (60° entre sí).", "Isotropía de Vecindad: ")
    add_bullet("El hexágono es la teselación regular que minimiza el cociente perímetro/área en el plano euclidiano. Esto reduce el número de viviendas o criaderos que quedan 'partidos' en los bordes de la celda.", "Minimización del Efecto de Borde: ")
    add_bullet("La dispersión de mosquitos a partir de un criadero es un proceso de difusión radial (isotrópico). La geometría circular del vuelo se aproxima infinitamente mejor mediante hexágonos que mediante cuadrados.", "Correspondencia con la Difusión Biológica: ")

    add_h2("4.4 Fórmulas Matemáticas de la Geometría Hexagonal")
    add_p("Si se define el radio del círculo circunscrito como 'r' (distancia del centro a cualquier vértice), y el diámetro transversal como D = cell_size:")
    add_bullet("r = D / 2", "Radio Circunscrito: ")
    add_bullet("a = r * cos(30°) = r * (sqrt(3) / 2)", "Apotema (distancia del centro al punto medio del lado): ")
    add_bullet("A = (Perímetro * Apotema) / 2 = 6 * r * a / 2 = (3 * sqrt(3) / 2) * r² ≈ 2.598 * r²", "Área del Hexágono Regular: ")

    add_h2("4.5 Algoritmo de Poda de Huella de Vuelo ('discard_na' y 'clip_to_footprint')")
    add_callout(
        "Los vuelos de dron siguen líneas de transecto poligonales que rara vez coinciden con un rectángulo perfecto. Al generar una cuadrícula tradicional basada en la caja envolvente (Bounding Box), hasta el 70-80% de las celdas caen fuera de los datos reales sobre el fondo NoData. 'drones4health' resuelve esto mediante dos mecanismos: (1) En 'd4h_hex_grid()', la bandera 'clip_to_footprint = TRUE' extrae la huella real de datos válidos con agregación rápida y poda las celdas exteriores. (2) En 'd4h_summarize_grid()', la opción 'discard_na = TRUE' elimina todas las celdas donde el valor medio del indicador sea NA, NaN o cero exacto, reduciendo el consumo de memoria en un 75%.",
        "ELIMINACIÓN DE CELDAS VACÍAS (PODA DE GRILLA):"
    )

    # Guardar estado intermedio
    print("Secciones 1 a 4 completadas.")
    return doc, {
        'add_title': add_title, 'add_h1': add_h1, 'add_h2': add_h2, 'add_h3': add_h3,
        'add_p': add_p, 'add_bullet': add_bullet, 'add_callout': add_callout,
        'add_table_styled': add_table_styled
    }

if __name__ == "__main__":
    doc, h = create_guide()
    doc.save("test_part1.docx")
    print("Parte 1 guardada.")
