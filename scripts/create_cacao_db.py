#!/usr/bin/env python3
"""
Script to create and seed the cacao_manual.db SQLite database.
This generates a pre-built database that can be shipped with the app.
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'database', 'cacao_manual.db')

def create_schema(conn):
    """Create database schema with FTS5 support."""
    cursor = conn.cursor()

    # Main manual sections table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS manual_sections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chapter TEXT NOT NULL,
            section_title TEXT NOT NULL,
            content TEXT NOT NULL,
            symptoms TEXT,
            treatment TEXT,
            prevention TEXT,
            severity_level INTEGER DEFAULT 1,
            image_examples TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # FTS5 virtual table for full-text search
    cursor.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS manual_fts USING fts5(
            chapter,
            section_title,
            content,
            symptoms,
            treatment,
            prevention,
            content=manual_sections,
            content_rowid=id
        )
    ''')

    # Triggers to keep FTS index in sync
    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS manual_sections_ai AFTER INSERT ON manual_sections BEGIN
            INSERT INTO manual_fts(rowid, chapter, section_title, content, symptoms, treatment, prevention)
            VALUES (new.id, new.chapter, new.section_title, new.content, new.symptoms, new.treatment, new.prevention);
        END
    ''')

    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS manual_sections_ad AFTER DELETE ON manual_sections BEGIN
            INSERT INTO manual_fts(manual_fts, rowid, chapter, section_title, content, symptoms, treatment, prevention)
            VALUES('delete', old.id, old.chapter, old.section_title, old.content, old.symptoms, old.treatment, old.prevention);
        END
    ''')

    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS manual_sections_au AFTER UPDATE ON manual_sections BEGIN
            INSERT INTO manual_fts(manual_fts, rowid, chapter, section_title, content, symptoms, treatment, prevention)
            VALUES('delete', old.id, old.chapter, old.section_title, old.content, old.symptoms, old.treatment, old.prevention);
            INSERT INTO manual_fts(rowid, chapter, section_title, content, symptoms, treatment, prevention)
            VALUES (new.id, new.chapter, new.section_title, new.content, new.symptoms, new.treatment, new.prevention);
        END
    ''')

    # Tags table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )
    ''')

    # Section-Tags relationship (many-to-many)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS section_tags (
            section_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (section_id, tag_id),
            FOREIGN KEY (section_id) REFERENCES manual_sections(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        )
    ''')

    # ML classification to manual sections mapping
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS ml_to_manual_mapping (
            ml_class_id TEXT PRIMARY KEY,
            ml_class_label TEXT NOT NULL,
            section_ids TEXT NOT NULL,
            confidence_threshold REAL DEFAULT 0.7
        )
    ''')

    # Synonyms table for improved search
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS synonyms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            term TEXT NOT NULL,
            synonym TEXT NOT NULL,
            UNIQUE(term, synonym)
        )
    ''')

    # Create indexes for better performance
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_sections_chapter ON manual_sections(chapter)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_sections_severity ON manual_sections(severity_level)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_synonyms_term ON synonyms(term)')

    conn.commit()

def seed_sections(conn):
    """Seed manual sections from BPA manual (CNC 3rd Edition 2019)."""
    cursor = conn.cursor()

    sections = [
        # Section 1: Introducción
        {
            'chapter': 'Introducción',
            'section_title': 'El cultivo del cacao en Colombia',
            'content': '''El cacao (Theobroma cacao L.) es uno de los cultivos más importantes para la economía campesina colombiana. Colombia cuenta con condiciones agroecológicas ideales para la producción de cacao fino y de aroma, reconocido internacionalmente por su calidad. Las principales zonas productoras incluyen Santander, Arauca, Antioquia, Huila, Tolima y Nariño. El cultivo requiere temperaturas entre 23-28°C, precipitación de 1500-2500 mm anuales bien distribuidos, humedad relativa del 70-80% y suelos profundos con buen drenaje. El cacao se desarrolla óptimamente bajo sombra parcial (30-50%), lo que permite sistemas agroforestales que contribuyen a la conservación ambiental y diversificación de ingresos.''',
            'symptoms': None,
            'treatment': None,
            'prevention': None,
            'severity_level': 1,
            'image_examples': '["cacao_plantation.jpg", "cacao_regions_map.jpg"]'
        },
        # Section 2: Aspectos Generales BPA
        {
            'chapter': 'Aspectos Generales de las Buenas Prácticas Agrícolas',
            'section_title': 'Requisitos generales del predio',
            'content': '''Las Buenas Prácticas Agrícolas (BPA) según NTC 5811 establecen requisitos para garantizar la inocuidad, calidad y trazabilidad del cacao. El predio debe contar con: planificación de actividades documentada, evaluación de riesgos físicos, químicos y biológicos, historial de uso del lote, análisis de suelos y agua, identificación clara de linderos, áreas de almacenamiento adecuadas, instalaciones sanitarias para trabajadores, manejo integrado de residuos, plan de fertilización basado en análisis de suelo, registro de todas las labores realizadas, capacitación continua del personal, y programa de salud ocupacional.''',
            'symptoms': None,
            'treatment': None,
            'prevention': None,
            'severity_level': 1,
            'image_examples': '["bpa_certification.jpg", "farm_planning.jpg"]'
        },
        # Section 3: Establecimiento del Cultivo
        {
            'chapter': 'Manejo del Cultivo',
            'section_title': 'Establecimiento y siembra del cacao',
            'content': '''El establecimiento exitoso del cultivo de cacao requiere una planificación cuidadosa. La preparación del terreno incluye: análisis de suelo para determinar fertilidad y pH óptimo (6.0-7.0), diseño del sistema de siembra considerando densidad (3x3m o 4x4m según variedad), establecimiento previo de sombra temporal (plátano, papaya) y permanente (maderables como cedro, nogal). El vivero debe producir plántulas de calidad usando semillas de clones productivos certificados o injertos. El trasplante se realiza al inicio de lluvias cuando las plantas tienen 4-6 meses. El hoyo de siembra debe ser de 40x40x40 cm, incorporando materia orgánica y correctivos según análisis de suelo.''',
            'symptoms': None,
            'treatment': None,
            'prevention': 'Seleccionar terrenos con buen drenaje, establecer cortinas rompevientos, usar material vegetal certificado libre de enfermedades.',
            'severity_level': 1,
            'image_examples': '["vivero_cacao.jpg", "siembra_cacao.jpg", "sombrio_temporal.jpg"]'
        },
        # Section 4: Nutrición y Fertilización
        {
            'chapter': 'Manejo del Cultivo',
            'section_title': 'Nutrición y fertilización del cacao',
            'content': '''La fertilización del cacao debe basarse en análisis de suelo y foliar para determinar las necesidades específicas. Los requerimientos principales son: Nitrógeno (N) para crecimiento vegetativo, Fósforo (P) para desarrollo radicular y floración, Potasio (K) para calidad del grano y resistencia a enfermedades, Calcio (Ca) y Magnesio (Mg) para estructura celular, y micronutrientes como Zinc, Boro y Cobre. Se recomienda aplicar materia orgánica (compost, gallinaza) 2-4 kg/árbol/año y fertilizantes químicos fraccionados en 2-3 aplicaciones durante época de lluvias. Los árboles en producción requieren aproximadamente 150-200 g de un fertilizante completo (15-15-15 o similar) por aplicación.''',
            'symptoms': 'Hojas amarillentas (deficiencia N), hojas pequeñas y oscuras (deficiencia P), necrosis en bordes de hojas (deficiencia K), deformación de hojas nuevas (deficiencia B).',
            'treatment': 'Aplicar fertilizantes según deficiencia identificada. Corregir pH del suelo si está fuera de rango. Aplicar enmiendas calcáreas si hay deficiencia de Ca o Mg.',
            'prevention': 'Realizar análisis de suelo cada 2 años, mantener cobertura vegetal, incorporar materia orgánica regularmente, evitar erosión.',
            'severity_level': 2,
            'image_examples': '["deficiencia_nitrogeno.jpg", "fertilizacion_cacao.jpg"]'
        },
        # Section 5: Podas
        {
            'chapter': 'Manejo del Cultivo',
            'section_title': 'Podas del cacao',
            'content': '''Las podas son fundamentales para mantener la arquitectura productiva del árbol y el control fitosanitario. Tipos de poda: 1) Poda de formación: en árboles jóvenes (1-3 años) para establecer la estructura básica con 3-4 ramas principales bien distribuidas. 2) Poda de mantenimiento: eliminar chupones, ramas entrecruzadas, enfermas o improductivas, se realiza 2-3 veces al año. 3) Poda de rehabilitación: en árboles viejos o abandonados, renovación drástica manteniendo el tronco principal. 4) Poda fitosanitaria: remoción de tejidos enfermos (ramas con escoba de bruja, frutos momificados con monilia). Las herramientas deben desinfectarse con hipoclorito al 2% o alcohol entre cortes. Los cortes se hacen en bisel y se sellan con pasta cicatrizante.''',
            'symptoms': None,
            'treatment': None,
            'prevention': 'Podar en época seca para evitar propagación de enfermedades, desinfectar herramientas, eliminar y quemar material enfermo fuera del lote.',
            'severity_level': 2,
            'image_examples': '["poda_formacion.jpg", "poda_mantenimiento.jpg", "herramientas_poda.jpg"]'
        },
        # Section 6: Manejo de Sombra
        {
            'chapter': 'Manejo del Cultivo',
            'section_title': 'Manejo de sombra y sistemas agroforestales',
            'content': '''El cacao es una especie que requiere sombra para su óptimo desarrollo. El manejo adecuado de sombra incluye: Sombra temporal (primeros 2-3 años): plátano, papaya, yuca a 2.5x2.5m, proporciona 60-70% de sombra inicial. Sombra permanente: árboles maderables (cedro, caoba, nogal cafetero, teca) o frutales (aguacate, cítricos) a 12-15m de distancia, proporcionando 25-35% de sombra en producción. La regulación de sombra es crítica: exceso de sombra (>50%) reduce producción y favorece enfermedades; poca sombra (<25%) causa estrés, quema de hojas y frutos. Se debe realizar raleo de sombra en época seca. Los sistemas agroforestales diversifican ingresos, mejoran el microclima, aumentan materia orgánica y capturan carbono.''',
            'symptoms': 'Exceso de sombra: árboles etiolados, poca floración, alta incidencia de Phytophthora. Falta de sombra: hojas quemadas, frutos con manchas solares, estrés hídrico.',
            'treatment': 'Raleo de árboles de sombra si hay exceso, siembra de sombra adicional si hay déficit.',
            'prevention': 'Planificar el sistema agroforestal desde el establecimiento, seleccionar especies de sombra compatibles, realizar podas regulares de los árboles de sombra.',
            'severity_level': 2,
            'image_examples': '["sombra_platano.jpg", "sistema_agroforestal.jpg"]'
        },
        # Section 7: Moniliasis
        {
            'chapter': 'Sanidad del Cultivo',
            'section_title': 'Moniliasis (Moniliophthora roreri)',
            'content': '''La moniliasis o monilia es la enfermedad más limitante del cacao en Colombia, causada por el hongo Moniliophthora roreri. Puede causar pérdidas del 40-100% de la producción si no se controla. El hongo afecta exclusivamente los frutos en cualquier estado de desarrollo. La infección ocurre en frutos jóvenes (<3 meses) siendo más susceptibles. Las esporas se dispersan por viento, lluvia, herramientas e insectos. El ciclo de la enfermedad dura 45-90 días. Condiciones favorables: alta humedad (>80%), temperaturas 22-28°C, época de lluvias.''',
            'symptoms': 'Puntos aceitosos o manchas oscuras irregulares en frutos jóvenes. Gibas o protuberancias (jorobas) en la superficie del fruto. Maduración prematura y desigual del fruto. Pudrición interna del fruto con masa de micelio blanco. En etapa avanzada: esporulación abundante (polvo cremoso-blanquecino) en la superficie del fruto. Momificación del fruto que permanece adherido al árbol.',
            'treatment': 'Remoción semanal de frutos enfermos (REMOCIÓN SANITARIA es la práctica más importante). Los frutos removidos deben enterrarse a 30cm de profundidad o depositarse en fosas de descomposición cubiertas. Aplicación de fungicidas cúpricos (hidróxido de cobre, oxicloruro de cobre) de manera preventiva en época de mayor floración. Frecuencia de remoción: cada 7 días en época de lluvias, cada 15 días en época seca.',
            'prevention': 'Realizar podas frecuentes para mejorar aireación. Regulación adecuada de sombra (25-35%). Cosechar frecuentemente los frutos maduros. No dejar frutos sobremaduros o enfermos en el árbol. Fertilización balanceada para mantener árboles vigorosos. Usar clones tolerantes (ICS-95, CCN-51, TSH-565).',
            'severity_level': 5,
            'image_examples': '["monilia_inicial.jpg", "monilia_gibas.jpg", "monilia_esporulacion.jpg", "monilia_momificado.jpg"]'
        },
        # Section 8: Escoba de Bruja
        {
            'chapter': 'Sanidad del Cultivo',
            'section_title': 'Escoba de Bruja (Moniliophthora perniciosa)',
            'content': '''La escoba de bruja es causada por el hongo Moniliophthora perniciosa (antes Crinipellis perniciosa). Es una enfermedad sistémica que afecta tejidos en crecimiento activo: brotes vegetativos, cojines florales y frutos. El hongo penetra por tejidos meristemáticos y causa hipertrofia (crecimiento anormal). Los basidiocarpos (estructuras reproductivas tipo sombrero rosado) se forman en escobas secas durante épocas húmedas y liberan millones de basidiosporas. Condiciones favorables: alta humedad, temperaturas 22-26°C, tejidos jóvenes en crecimiento.''',
            'symptoms': 'En brotes vegetativos: proliferación anormal de brotes laterales formando una "escoba" verde que luego se seca y se torna marrón. En cojines florales: engrosamiento anormal del cojín (escoba de cojín), flores anormales que no forman frutos. En frutos: deformación tipo "zanahoria" o "fresa", maduración irregular, frutos partenocárpicos (chirimoyas). Las escobas secas permanecen en el árbol por años liberando esporas.',
            'treatment': 'Poda fitosanitaria: cortar escobas verdes y secas 15-20 cm por debajo del punto de infección. Remover cojines florales y frutos afectados. El material removido debe sacarse del lote y quemarse o enterrarse profundamente. Aplicación de fungicidas cúpricos después de la poda. Realizar 4-5 rondas de remoción de escobas al año.',
            'prevention': 'Realizar podas de mantenimiento regulares para estimular brotación uniforme. Regular sombra adecuadamente. Usar clones resistentes o tolerantes. Fertilización balanceada. No podar durante períodos húmedos prolongados. Desinfectar herramientas de poda.',
            'severity_level': 4,
            'image_examples': '["escoba_bruja_verde.jpg", "escoba_bruja_seca.jpg", "escoba_cojin.jpg", "fruto_chirimoya.jpg"]'
        },
        # Section 9: Mazorca Negra
        {
            'chapter': 'Sanidad del Cultivo',
            'section_title': 'Mazorca Negra (Phytophthora spp.)',
            'content': '''La mazorca negra es causada principalmente por Phytophthora palmivora y P. megakarya. Afecta frutos, troncos, ramas y raíces. Es favorecida por alta humedad, exceso de sombra, drenaje deficiente y heridas en tejidos. El patógeno produce zoosporas que se dispersan por salpique de lluvia, escorrentía e insectos. El hongo sobrevive en el suelo y en tejidos infectados. Causa pudrición rápida de frutos en cualquier estado de desarrollo.''',
            'symptoms': 'En frutos: manchas pardas o chocolate que avanzan rápidamente cubriendo todo el fruto en 10-15 días. La pudrición es firme, no blanda. Micelio blanquecino en superficie en condiciones húmedas. En tallo (cáncer del tronco): lesiones hundidas, oscuras, exudado rojizo o marrón, corteza se desprende. En raíces: pudrición que causa marchitez y muerte del árbol.',
            'treatment': 'Remoción de frutos enfermos cada 7-10 días. Aplicación de fungicidas cúpricos de manera preventiva y curativa. Para cáncer del tronco: raspar el tejido enfermo hasta encontrar tejido sano, aplicar pasta cúprica. Mejorar drenaje del lote. Eliminar exceso de sombra.',
            'prevention': 'No plantar en suelos mal drenados o encharcables. Regular sombra al 25-35%. Evitar heridas en troncos y ramas. Realizar podas en época seca. Mantener el suelo con cobertura vegetal para evitar salpique. No dejar frutos en contacto con el suelo. Usar clones tolerantes (IMC-67, PA-169).',
            'severity_level': 4,
            'image_examples': '["mazorca_negra_inicial.jpg", "mazorca_negra_avanzada.jpg", "cancer_tronco.jpg"]'
        },
        # Section 10: Plagas del Cacao
        {
            'chapter': 'Sanidad del Cultivo',
            'section_title': 'Principales plagas del cacao',
            'content': '''Las principales plagas del cacao incluyen: 1) Hormiga arriera (Atta spp.): defolia árboles jóvenes y adultos, corta hojas y flores. 2) Chinches (Monalonion spp.): causan lesiones necróticas en frutos jóvenes y brotes, favorecen entrada de patógenos. 3) Trips (Selenothrips rubrocinctus): raspan tejido de hojas y frutos causando bronceado. 4) Áfidos: transmiten virus, causan enrollamiento de brotes. 5) Barrenadores del tallo (Xyleborus spp.): perforan tronco y ramas. 6) Ardillas y pájaros: dañan frutos maduros. El Manejo Integrado de Plagas (MIP) combina prácticas culturales, control biológico y químico selectivo.''',
            'symptoms': 'Hormiga: defoliación severa, caminos y nidos visibles. Chinche: manchas necróticas circulares hundidas en frutos, deformación de brotes. Trips: hojas y frutos con aspecto bronceado o plateado. Barrenadores: orificios en tronco con aserrín.',
            'treatment': 'Hormiga: destrucción de nidos con insecticidas granulados, cebos tóxicos. Chinche: aplicación focalizada de insecticidas (lambda-cyhalotrina, imidacloprid). Trips: productos sistémicos en ataques severos. Control biológico con hongos entomopatógenos (Beauveria, Metarhizium).',
            'prevention': 'Monitoreo regular de poblaciones. Mantener biodiversidad para favorecer enemigos naturales. Eliminar residuos de cosecha. Usar trampas de monitoreo. Barreras físicas contra hormigas (grasa en troncos).',
            'severity_level': 3,
            'image_examples': '["hormiga_arriera.jpg", "dano_chinche.jpg", "trips_hoja.jpg"]'
        },
        # Section 11: Cosecha
        {
            'chapter': 'Postcosecha',
            'section_title': 'Cosecha del cacao',
            'content': '''La cosecha correcta es fundamental para la calidad del cacao. Los frutos alcanzan madurez fisiológica 5-6 meses después de la polinización. La frecuencia de cosecha debe ser cada 15-20 días para obtener frutos en óptimo estado de madurez. La cosecha inoportuna (frutos verdes o sobremaduros) afecta la calidad de fermentación y sabor final.''',
            'symptoms': None,
            'treatment': None,
            'prevention': None,
            'severity_level': 1,
            'image_examples': '["cosecha_cacao.jpg", "mazorca_madura.jpg"]'
        },
        # Section 12: Indicadores de Madurez
        {
            'chapter': 'Postcosecha',
            'section_title': 'Indicadores de madurez del fruto',
            'content': '''Los indicadores de madurez varían según el tipo de cacao: Cacao Criollo y Trinitario: cambio de color de verde a amarillo o de rojo a anaranjado. Cacao Forastero y algunos híbridos: el cambio es menos evidente, de verde oscuro a verde amarillento. Indicadores adicionales: sonido hueco al golpear el fruto, surcos más pronunciados, desprendimiento fácil del pedúnculo. NO cosechar frutos pintones (inicio de cambio de color) ni sobremaduros (granos germinando internamente). El corte se realiza con tijera o machete desinfectado, dejando un pequeño pedúnculo en el fruto. Las herramientas deben limpiarse al pasar de un árbol a otro para evitar diseminar enfermedades.''',
            'symptoms': None,
            'treatment': None,
            'prevention': 'Cosechar solo frutos maduros, nunca pintones o sobremaduros. Evitar daños mecánicos al fruto durante la cosecha.',
            'severity_level': 1,
            'image_examples': '["madurez_cacao_amarillo.jpg", "madurez_cacao_rojo.jpg", "corte_mazorca.jpg"]'
        },
        # Section 13: Fermentación
        {
            'chapter': 'Postcosecha',
            'section_title': 'Fermentación del cacao',
            'content': '''La fermentación es el proceso más crítico para desarrollar los precursores del sabor y aroma del chocolate. Debe iniciarse máximo 24 horas después de la partida de frutos. Se realiza en cajones de madera escalonados o montones cubiertos con hojas de plátano. El proceso dura 5-7 días para cacao criollo/trinitario y 6-8 días para forastero. La temperatura debe alcanzar 45-50°C en el centro de la masa. Se realizan volteos cada 24-48 horas para homogenizar la fermentación y oxigenar. Fases de la fermentación: 1) Fase anaeróbica (0-48h): levaduras convierten azúcares en alcohol, muerte del embrión. 2) Fase aeróbica (48h-final): bacterias acéticas oxidan alcohol a ácido acético, desarrollo de precursores de sabor.''',
            'symptoms': 'Fermentación deficiente: granos violetas o pizarrosos en prueba de corte, sabor astringente y amargo. Sobrefermentación: granos muy oscuros, olor a amoníaco, sabor pútrido.',
            'treatment': 'Ajustar tiempos y frecuencia de volteos según las características observadas.',
            'prevention': 'Usar frutos maduros y sanos. Iniciar fermentación el mismo día de la partida. Proteger de lluvia. Usar cajones de madera de especies no resinosas. Realizar volteos regulares. Monitorear temperatura.',
            'severity_level': 3,
            'image_examples': '["fermentacion_cajones.jpg", "volteo_cacao.jpg", "prueba_corte.jpg"]'
        },
        # Section 14: Secado
        {
            'chapter': 'Postcosecha',
            'section_title': 'Secado del cacao',
            'content': '''El secado reduce la humedad del grano del 55% al 7-8% para garantizar conservación y evitar desarrollo de hongos. El secado debe ser gradual para completar reacciones bioquímicas iniciadas en fermentación. Métodos: 1) Secado solar (preferido): en patios de cemento, marquesinas o secadores tipo Elba, requiere 5-8 días de sol. 2) Secado artificial: usando aire caliente a máximo 60°C, útil en zonas lluviosas. El espesor de la capa de granos debe ser 5-7 cm, removiendo 3-4 veces al día. El cacao debe protegerse de la lluvia y el rocío nocturno. Indicadores de secado correcto: grano quebradizo, cascarilla se desprende fácilmente, color marrón uniforme.''',
            'symptoms': 'Secado deficiente: granos con humedad >8%, susceptibles a hongos. Secado excesivo o muy rápido: cascarilla agrietada, granos frágiles, acidez encapsulada.',
            'treatment': 'Almacenar solo cacao con humedad <8%. Si hay exceso de humedad, continuar secado.',
            'prevention': 'Secar en capas delgadas, remover frecuentemente, proteger de lluvia, verificar humedad antes de almacenar.',
            'severity_level': 2,
            'image_examples': '["secado_solar.jpg", "secador_elba.jpg", "grano_seco.jpg"]'
        },
        # Section 15: Almacenamiento
        {
            'chapter': 'Postcosecha',
            'section_title': 'Almacenamiento del cacao',
            'content': '''El almacenamiento adecuado preserva la calidad del cacao hasta su comercialización. El grano debe almacenarse con humedad máxima del 7-8%. El lugar de almacenamiento debe ser fresco, seco, ventilado, libre de olores extraños y protegido de plagas. Usar sacos de fique o yute (no plástico) que permitan respiración del grano. Los sacos se colocan sobre estibas de madera a 10-15 cm del piso y separados de las paredes. No almacenar junto a agroquímicos, combustibles o productos con olores fuertes. Rotar inventario usando primero el cacao más antiguo (FIFO). El cacao bien almacenado mantiene calidad por 6-12 meses.''',
            'symptoms': 'Granos con hongos visibles, olor a moho, pérdida de peso, daño de insectos (polilla, gorgojos).',
            'treatment': 'Separar lotes afectados, secar nuevamente si hay humedad excesiva, fumigar bodega si hay plagas.',
            'prevention': 'Verificar humedad antes de almacenar (<8%), inspeccionar periódicamente, mantener limpieza de bodega, control de roedores e insectos.',
            'severity_level': 2,
            'image_examples': '["almacenamiento_cacao.jpg", "estibas_sacos.jpg"]'
        },
        # Section 16: Clasificación y Calidad
        {
            'chapter': 'Comercialización',
            'section_title': 'Clasificación y estándares de calidad',
            'content': '''La calidad del cacao determina su precio en el mercado. La norma NTC 1252 establece los requisitos de calidad para cacao en grano en Colombia. Clasificación por grados: Premio (máximo 1% defectuosos, >85% fermentado), Corriente (máximo 4% defectuosos, >65% fermentado), Pasilla (>4% defectuosos, granos planos, partidos, múltiples). La prueba de corte evalúa fermentación: se cortan 100 granos longitudinalmente y se clasifican por color interno (bien fermentado: marrón, parcialmente fermentado: violeta parcial, sin fermentar: violeta/pizarra). Defectos evaluados: mohoso, ahumado, germinado, dañado por insectos, pizarroso, violeta, plano, partido.''',
            'symptoms': None,
            'treatment': None,
            'prevention': 'Fermentar y secar correctamente, clasificar antes de vender, separar granos defectuosos.',
            'severity_level': 1,
            'image_examples': '["prueba_corte.jpg", "clasificacion_granos.jpg", "defectos_cacao.jpg"]'
        },
        # Section 17: Trazabilidad
        {
            'chapter': 'Comercialización',
            'section_title': 'Trazabilidad y registros',
            'content': '''La trazabilidad permite rastrear el producto desde la finca hasta el consumidor final, es requisito para certificaciones y mercados especiales. Registros requeridos: identificación del lote/finca, fecha de cosecha, proceso de beneficio (fermentación y secado), análisis de calidad, fecha y destino de venta. Cada lote debe identificarse con código único que incluya: código de productor, año de cosecha, número de lote. Los registros deben conservarse mínimo 2 años. La trazabilidad facilita identificar y corregir problemas de calidad, acceder a mercados diferenciados (comercio justo, orgánico, origen), cumplir requisitos de compradores internacionales.''',
            'symptoms': None,
            'treatment': None,
            'prevention': 'Mantener registros actualizados de todas las labores, etiquetar cada lote, conservar documentación organizada.',
            'severity_level': 1,
            'image_examples': '["registro_trazabilidad.jpg", "etiqueta_lote.jpg"]'
        }
    ]

    for section in sections:
        cursor.execute('''
            INSERT INTO manual_sections
            (chapter, section_title, content, symptoms, treatment, prevention, severity_level, image_examples)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            section['chapter'],
            section['section_title'],
            section['content'],
            section['symptoms'],
            section['treatment'],
            section['prevention'],
            section['severity_level'],
            section['image_examples']
        ))

    conn.commit()
    print(f"Seeded {len(sections)} manual sections")

def seed_tags(conn):
    """Seed tags for categorization."""
    cursor = conn.cursor()

    tags = [
        'enfermedad', 'hongo', 'plaga', 'insecto', 'cosecha', 'postcosecha',
        'fermentación', 'secado', 'calidad', 'poda', 'fertilización', 'nutrición',
        'sombra', 'agroforestal', 'BPA', 'certificación', 'trazabilidad', 'NTC',
        'monilia', 'escoba', 'fitoptora', 'mazorca_negra', 'manejo_cultural',
        'control_químico', 'almacenamiento'
    ]

    tag_ids = {}
    for tag in tags:
        cursor.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', (tag,))
        cursor.execute('SELECT id FROM tags WHERE name = ?', (tag,))
        tag_ids[tag] = cursor.fetchone()[0]

    # Section-tag mappings
    section_tags = {
        1: ['BPA'],  # Introducción
        2: ['BPA', 'certificación', 'NTC', 'trazabilidad'],  # Requisitos BPA
        3: ['manejo_cultural', 'sombra'],  # Establecimiento
        4: ['nutrición', 'fertilización', 'manejo_cultural'],  # Nutrición
        5: ['poda', 'manejo_cultural'],  # Podas
        6: ['sombra', 'agroforestal', 'manejo_cultural'],  # Sombra
        7: ['enfermedad', 'hongo', 'monilia', 'control_químico', 'manejo_cultural'],  # Monilia
        8: ['enfermedad', 'hongo', 'escoba', 'poda', 'manejo_cultural'],  # Escoba de Bruja
        9: ['enfermedad', 'hongo', 'fitoptora', 'mazorca_negra', 'control_químico'],  # Mazorca Negra
        10: ['plaga', 'insecto', 'control_químico', 'manejo_cultural'],  # Plagas
        11: ['cosecha', 'postcosecha'],  # Cosecha
        12: ['cosecha', 'calidad'],  # Indicadores madurez
        13: ['postcosecha', 'fermentación', 'calidad'],  # Fermentación
        14: ['postcosecha', 'secado', 'calidad'],  # Secado
        15: ['postcosecha', 'almacenamiento', 'calidad'],  # Almacenamiento
        16: ['calidad', 'NTC', 'certificación'],  # Clasificación
        17: ['trazabilidad', 'BPA', 'certificación'],  # Trazabilidad
    }

    for section_id, tag_names in section_tags.items():
        for tag_name in tag_names:
            if tag_name in tag_ids:
                cursor.execute(
                    'INSERT OR IGNORE INTO section_tags (section_id, tag_id) VALUES (?, ?)',
                    (section_id, tag_ids[tag_name])
                )

    conn.commit()
    print(f"Seeded {len(tags)} tags with section mappings")

def seed_ml_mappings(conn):
    """Seed ML classification to manual section mappings."""
    cursor = conn.cursor()

    ml_mappings = [
        {'ml_class_id': 'monilia', 'ml_class_label': 'Moniliasis', 'section_ids': '7', 'threshold': 0.7},
        {'ml_class_id': 'escoba_bruja', 'ml_class_label': 'Escoba de Bruja', 'section_ids': '8', 'threshold': 0.7},
        {'ml_class_id': 'mazorca_negra', 'ml_class_label': 'Mazorca Negra / Phytophthora', 'section_ids': '9', 'threshold': 0.7},
        {'ml_class_id': 'fitoptora', 'ml_class_label': 'Phytophthora (cáncer tallo)', 'section_ids': '9', 'threshold': 0.7},
        {'ml_class_id': 'hormiga', 'ml_class_label': 'Hormiga Arriera', 'section_ids': '10', 'threshold': 0.6},
        {'ml_class_id': 'chinche', 'ml_class_label': 'Chinche (Monalonion)', 'section_ids': '10', 'threshold': 0.6},
        {'ml_class_id': 'trips', 'ml_class_label': 'Trips', 'section_ids': '10', 'threshold': 0.6},
        {'ml_class_id': 'fruto_sano', 'ml_class_label': 'Fruto Sano', 'section_ids': '11,12', 'threshold': 0.8},
        {'ml_class_id': 'hoja_sana', 'ml_class_label': 'Hoja Sana', 'section_ids': '4,6', 'threshold': 0.8},
    ]

    for mapping in ml_mappings:
        cursor.execute('''
            INSERT OR REPLACE INTO ml_to_manual_mapping
            (ml_class_id, ml_class_label, section_ids, confidence_threshold)
            VALUES (?, ?, ?, ?)
        ''', (mapping['ml_class_id'], mapping['ml_class_label'],
              mapping['section_ids'], mapping['threshold']))

    conn.commit()
    print(f"Seeded {len(ml_mappings)} ML mappings")

def seed_synonyms(conn):
    """Seed synonyms for improved FTS search."""
    cursor = conn.cursor()

    synonyms = [
        ('monilia', 'moniliasis'), ('monilia', 'pudrición'), ('monilia', 'hongo'),
        ('escoba', 'escoba de bruja'), ('escoba', 'witches broom'), ('escoba', 'crinipellis'),
        ('mazorca negra', 'phytophthora'), ('mazorca negra', 'pudrición'), ('mazorca negra', 'black pod'),
        ('poda', 'podar'), ('poda', 'cortar'), ('poda', 'deschuponar'),
        ('fermentación', 'fermentar'), ('fermentación', 'beneficio'),
        ('secado', 'secar'), ('secado', 'deshidratar'),
        ('plaga', 'insecto'), ('plaga', 'hormiga'), ('plaga', 'chinche'),
        ('enfermedad', 'patógeno'), ('enfermedad', 'hongo'), ('enfermedad', 'infección'),
        ('síntoma', 'señal'), ('síntoma', 'signo'), ('síntoma', 'indicador'),
        ('tratamiento', 'control'), ('tratamiento', 'manejo'), ('tratamiento', 'combatir'),
        ('prevención', 'prevenir'), ('prevención', 'evitar'), ('prevención', 'proteger'),
        ('fertilización', 'abonar'), ('fertilización', 'nutrir'), ('fertilización', 'fertilizante'),
        ('sombra', 'sombrío'), ('sombra', 'sombreadero'), ('sombra', 'shade'),
        ('calidad', 'grado'), ('calidad', 'clasificación'), ('calidad', 'NTC'),
        ('trazabilidad', 'rastreo'), ('trazabilidad', 'registro'), ('trazabilidad', 'seguimiento'),
        ('cosecha', 'cosechar'), ('cosecha', 'recolección'), ('cosecha', 'tumba'),
        ('grano', 'semilla'), ('grano', 'almendra'), ('grano', 'haba'),
    ]

    for term, synonym in synonyms:
        cursor.execute(
            'INSERT OR IGNORE INTO synonyms (term, synonym) VALUES (?, ?)',
            (term, synonym)
        )

    conn.commit()
    print(f"Seeded {len(synonyms)} synonyms")

def main():
    """Create and seed the database."""
    # Ensure directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    # Remove existing database
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f"Removed existing database at {DB_PATH}")

    # Create new database
    conn = sqlite3.connect(DB_PATH)
    print(f"Creating database at {DB_PATH}")

    try:
        create_schema(conn)
        print("Schema created successfully")

        seed_sections(conn)
        seed_tags(conn)
        seed_ml_mappings(conn)
        seed_synonyms(conn)

        # Verify data
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM manual_sections")
        sections_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM tags")
        tags_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM ml_to_manual_mapping")
        ml_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM synonyms")
        synonyms_count = cursor.fetchone()[0]

        print(f"\nDatabase created successfully!")
        print(f"  - Sections: {sections_count}")
        print(f"  - Tags: {tags_count}")
        print(f"  - ML Mappings: {ml_count}")
        print(f"  - Synonyms: {synonyms_count}")
        print(f"\nDatabase saved to: {DB_PATH}")

    finally:
        conn.close()

if __name__ == '__main__':
    main()
