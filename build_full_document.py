# -*- coding: utf-8 -*-
"""
Ensamblador final de la Guía de Estudio Maestra drones4health.
Genera el archivo final: Guia_de_Estudio_drones4health.docx
"""
import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

from build_full_guide import create_guide
from sections_content import FUNCTIONS_DATA
from sections_qa_table import QUESTIONS_AND_ANSWERS, MEGA_TABLE_DATA

def main():
    print("Iniciando construccion del documento Word completo...")
    doc, helpers = create_guide()
    
    add_h1 = helpers['add_h1']
    add_h2 = helpers['add_h2']
    add_h3 = helpers['add_h3']
    add_p = helpers['add_p']
    add_bullet = helpers['add_bullet']
    add_callout = helpers['add_callout']
    add_table_styled = helpers['add_table_styled']

    # =========================================================================
    # SECCIÓN 5: CATÁLOGO DETALLADO FUNCIÓN POR FUNCIÓN
    # =========================================================================
    add_h1("5. Catálogo Detallado de Funciones (Análisis Profundo Función por Función)")
    add_p("En esta sección se analiza minuciosamente cada función del paquete, detallando sus argumentos de entrada, objetos de salida retornados en R, flujo algorítmico interno, fórmulas matemáticas subyacentes y decisiones críticas de diseño de software.")

    # Agrupar funciones por categoría
    current_cat = None
    for fn in FUNCTIONS_DATA:
        cat = fn['category']
        if cat != current_cat:
            current_cat = cat
            add_h2(f"Subgrupo: {cat}")
        
        add_h3(fn['name'])
        add_p(fn['purpose'], bold_prefix="Propósito Epidemiológico / Operativo: ")
        
        # Entradas y Salidas
        add_p(fn['inputs'], bold_prefix="Entradas (Inputs / Argumentos): ")
        add_p(fn['outputs'], bold_prefix="Salida en R (Output / Objeto): ")
        
        # Proceso interno
        add_p(fn['process'], bold_prefix="Procesamiento Interno (Paso a Paso): ")
        
        # Matemática
        add_p(fn['math'], bold_prefix="Fórmula Matemática / Algorítmica: ")
        
        # Notas y decisiones
        add_callout(fn['notes'], title="DECISIÓN DE DISEÑO / NOTA DE DEFRENSA:")

    # =========================================================================
    # SECCIÓN 6: MEGA TABLA MAESTRA DE CONSULTA RÁPIDA
    # =========================================================================
    add_h1("6. Mega Tabla Maestra de Entradas, Salidas, Clases en R y Fórmulas")
    add_p("Esta tabla consolida en un formato de consulta rápida todas las funciones del paquete drones4health, permitiendo al usuario identificar de un solo vistazo el objeto de entrada requerido, la clase de objeto que se genera en R, la ecuación matemática aplicada y la función que cumple en el marco de la salud pública:")

    mega_headers = ["Función", "Entrada Principal", "Parámetros Clave", "Clase en R Retornada", "Fórmula / Lógica Nuclear", "Aplicación Sanitaria"]
    col_widths = [Inches(1.3), Inches(1.0), Inches(1.0), Inches(1.1), Inches(1.4), Inches(1.2)]
    
    add_table_styled(mega_headers, MEGA_TABLE_DATA, col_widths)

    # =========================================================================
    # SECCIÓN 7: BALOTARIO DE PREGUNTAS Y RESPUESTAS TÉCNICAS
    # =========================================================================
    add_h1("7. Balotario de Preguntas Clave para Defensa Técnica y Examen")
    add_p("A continuación se presentan 15 preguntas de alta exigencia metodológica y conceptual que suelen formular comités de evaluación, jurados de tesis, revisores de código o directores de salud pública, acompañadas de sus respuestas técnicas exhaustivas sustentadas en el código fuente de drones4health:")

    for item in QUESTIONS_AND_ANSWERS:
        add_h3(item['q'])
        add_p(item['a'], bold_prefix="Respuesta Técnica Sustentada: ", space_after=6)

    # Conclusión
    add_h2("8. Conclusiones y Consideraciones para la Implementación en Campo")
    add_p("El paquete drones4health establece un puente riguroso entre la fotogrametría aérea moderna y la toma de decisiones operativas en salud pública. Sus decisiones de arquitectura —el uso exclusivo de 'terra' y 'sf' para minimizar el uso de memoria, el recorte preventivo en buffers de viviendas, el filtrado óptico para evitar falsos positivos de agua en techos metálicos, el modelado exponencial del vuelo de vectores y la zonificación en teselaciones hexagonales isotrópicas— resuelven los cuellos de botella que históricamente limitaban el uso de drones en vigilancia epidemiológica de rutina.")

    output_filename = "Guia_de_Estudio_drones4health.docx"
    try:
        doc.save(output_filename)
        print(f"Documento guardado exitosamente como: {output_filename}")
    except PermissionError:
        output_filename = "Guia_de_Estudio_drones4health_v2.docx"
        doc.save(output_filename)
        print(f"Archivo original bloqueado por Word. Guardado exitosamente como: {output_filename}")
    
    file_size_kb = os.path.getsize(output_filename) / 1024
    print(f"Tamano del archivo generado: {file_size_kb:.1f} KB")

if __name__ == "__main__":
    main()
