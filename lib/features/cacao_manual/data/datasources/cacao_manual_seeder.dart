import '../models/manual_section_model.dart';
import '../models/ml_mapping_model.dart';
import '../models/tag_model.dart';
import 'cacao_manual_local_datasource.dart';

class CacaoManualSeeder {
  final CacaoManualLocalDataSource dataSource;

  CacaoManualSeeder(this.dataSource);

  Future<void> seedDatabase() async {
    // Seed tags first
    await _seedTags();

    // Seed manual sections
    await _seedSections();

    // Seed ML mappings
    await _seedMlMappings();

    // Seed synonyms
    await _seedSynonyms();
  }

  Future<void> _seedTags() async {
    final tags = [
      const TagModel(id: 0, name: 'enfermedad'),
      const TagModel(id: 0, name: 'plaga'),
      const TagModel(id: 0, name: 'hongo'),
      const TagModel(id: 0, name: 'nutricion'),
      const TagModel(id: 0, name: 'deficiencia'),
      const TagModel(id: 0, name: 'manejo'),
      const TagModel(id: 0, name: 'cosecha'),
      const TagModel(id: 0, name: 'fermentacion'),
      const TagModel(id: 0, name: 'secado'),
      const TagModel(id: 0, name: 'poda'),
    ];

    for (final tag in tags) {
      await dataSource.insertTag(tag);
    }
  }

  Future<void> _seedSections() async {
    final sections = _getManualSections();
    await dataSource.insertSections(sections);

    // Link sections to tags (example associations)
    // Section 1 (Moniliasis) -> tags: enfermedad, hongo
    await dataSource.linkSectionToTag(1, 1);
    await dataSource.linkSectionToTag(1, 3);

    // Section 2 (Mazorca Negra) -> tags: enfermedad, hongo
    await dataSource.linkSectionToTag(2, 1);
    await dataSource.linkSectionToTag(2, 3);

    // Section 3 (Escoba de Bruja) -> tags: enfermedad, hongo
    await dataSource.linkSectionToTag(3, 1);
    await dataSource.linkSectionToTag(3, 3);

    // Section 4 (Trips) -> tags: plaga
    await dataSource.linkSectionToTag(4, 2);

    // Section 5 (Monalonion) -> tags: plaga
    await dataSource.linkSectionToTag(5, 2);
  }

  List<ManualSectionModel> _getManualSections() {
    return [
      // ENFERMEDADES
      const ManualSectionModel(
        id: 0,
        chapter: 'Enfermedades',
        sectionTitle: 'Moniliasis (Moniliophthora roreri)',
        content: '''
La moniliasis es una de las enfermedades más devastadoras del cacao en América Latina.
Es causada por el hongo Moniliophthora roreri y puede causar pérdidas de hasta el 80% de la producción.

CICLO DE LA ENFERMEDAD:
El hongo produce esporas que son dispersadas por el viento, la lluvia y los insectos.
Las esporas germinan sobre la superficie de los frutos jóvenes y penetran directamente a través de la cutícula.
El período de incubación varía entre 3 a 8 semanas dependiendo de las condiciones ambientales.

CONDICIONES FAVORABLES:
- Humedad relativa superior al 80%
- Temperaturas entre 22-28°C
- Alta densidad de siembra
- Falta de podas de mantenimiento
- Exceso de sombra

IDENTIFICACIÓN VISUAL:
Los frutos afectados presentan inicialmente pequeñas manchas de color marrón claro que se expanden rápidamente.
En estados avanzados, el fruto se cubre de una masa blanquecina de esporas que luego se torna crema o café.
Los frutos momificados permanecen en el árbol y son fuente de inóculo para nuevas infecciones.
''',
        symptoms: 'Manchas pardas en frutos, deformación, pudrición interna, masa blanquecina de esporas, frutos momificados',
        treatment: '''
CONTROL CULTURAL:
1. Remoción semanal de frutos infectados (cosecha sanitaria)
2. Los frutos removidos deben enterrarse a 30cm de profundidad o quemarse
3. Evitar dejar frutos momificados en el árbol

CONTROL QUÍMICO:
1. Aplicación de fungicidas cúpricos (hidróxido de cobre, oxicloruro de cobre)
2. Aplicar cada 15 días durante la época de mayor producción
3. Dosis: 2-3 kg/ha de producto comercial

CONTROL BIOLÓGICO:
1. Aplicación de Trichoderma harzianum
2. Bacillus subtilis
''',
        prevention: '''
1. Podas de mantenimiento cada 4-6 meses
2. Regulación de sombra (30-50%)
3. Drenaje adecuado del suelo
4. Distancias de siembra apropiadas (3x3m mínimo)
5. Uso de clones tolerantes (CCN-51, ICS-95)
6. Cosechas frecuentes (cada 7-15 días)
''',
        severityLevel: 5,
      ),

      const ManualSectionModel(
        id: 0,
        chapter: 'Enfermedades',
        sectionTitle: 'Mazorca Negra (Phytophthora spp.)',
        content: '''
La mazorca negra es causada por varias especies del género Phytophthora, siendo P. palmivora y P. megakarya las más importantes.
Está presente en todas las regiones cacaoteras del mundo y puede afectar frutos, troncos, ramas y hojas.

CICLO DE LA ENFERMEDAD:
El patógeno sobrevive en el suelo y en frutos infectados.
Las esporas son dispersadas por salpicaduras de lluvia desde el suelo hacia los frutos.
La infección es más severa en frutos cercanos al suelo.

CONDICIONES FAVORABLES:
- Lluvias frecuentes y prolongadas
- Humedad del suelo elevada
- Mal drenaje
- Frutos en contacto con el suelo
- Temperaturas entre 20-25°C

IDENTIFICACIÓN VISUAL:
Manchas de color marrón oscuro a negro que inician en cualquier parte del fruto.
Las manchas avanzan rápidamente cubriendo todo el fruto en 10-14 días.
En condiciones húmedas se observa un micelio blanquecino sobre las lesiones.
''',
        symptoms: 'Manchas negras en frutos, pudrición rápida, micelio blanquecino, olor desagradable, frutos momificados negros',
        treatment: '''
CONTROL CULTURAL:
1. Cosecha sanitaria frecuente
2. Eliminación de frutos infectados
3. Mejorar el drenaje del suelo
4. Evitar acumulación de hojarasca

CONTROL QUÍMICO:
1. Fungicidas a base de metalaxyl + mancozeb
2. Fosetil aluminio
3. Aplicaciones preventivas cada 21 días en época lluviosa
4. Dosis según recomendación del producto

CONTROL BIOLÓGICO:
1. Trichoderma spp.
2. Aplicación de compost enriquecido con microorganismos antagonistas
''',
        prevention: '''
1. Drenaje adecuado del terreno
2. Evitar encharcamientos
3. Podas que favorezcan la aireación
4. No dejar frutos en contacto con el suelo
5. Desinfección de herramientas
6. Uso de material genético tolerante
''',
        severityLevel: 4,
      ),

      const ManualSectionModel(
        id: 0,
        chapter: 'Enfermedades',
        sectionTitle: 'Escoba de Bruja (Moniliophthora perniciosa)',
        content: '''
La escoba de bruja es causada por el hongo Moniliophthora perniciosa (antes Crinipellis perniciosa).
Afecta brotes vegetativos, cojines florales y frutos, causando malformaciones características.

CICLO DE LA ENFERMEDAD:
El hongo produce basidiocarpos (pequeños hongos en forma de sombrilla) sobre tejidos secos infectados.
Las basidiosporas son liberadas durante la noche con alta humedad y dispersadas por el viento.
La infección ocurre en tejidos meristemáticos en crecimiento activo.

CONDICIONES FAVORABLES:
- Alta humedad relativa (>80%)
- Temperaturas entre 24-28°C
- Presencia de tejido en crecimiento activo
- Lluvias frecuentes

IDENTIFICACIÓN VISUAL:
En brotes: proliferación anormal de yemas laterales formando estructuras similares a "escobas"
En frutos: deformación, forma de "fresa" o "zanahoria", maduración prematura falsa
Los tejidos infectados eventualmente se secan y toman color marrón oscuro
''',
        symptoms: 'Escobas vegetativas, frutos deformados tipo fresa o chirimoya, cojines florales hipertrofiados, brotes secos',
        treatment: '''
CONTROL CULTURAL:
1. Poda fitosanitaria de escobas secas (remoción completa)
2. Realizar podas durante época seca
3. Quemar o enterrar el material removido
4. Remover frutos deformados

CONTROL QUÍMICO:
1. Aplicación de fungicidas cúpricos post-poda
2. Proteger heridas de poda con pasta bordelesa
3. Triazoles en casos severos (bajo supervisión técnica)

CONTROL BIOLÓGICO:
1. Aplicación de Trichoderma stromaticum
2. Este hongo parasita los basidiocarpos del patógeno
''',
        prevention: '''
1. Podas frecuentes de formación y mantenimiento
2. Remoción oportuna de escobas verdes (antes de que sequen)
3. Selección de material genético tolerante
4. Nutrición balanceada para evitar brotación excesiva
5. Regulación de sombra
''',
        severityLevel: 4,
      ),

      // PLAGAS
      const ManualSectionModel(
        id: 0,
        chapter: 'Plagas',
        sectionTitle: 'Trips del Cacao (Selenothrips rubrocinctus)',
        content: '''
Los trips son insectos pequeños (1-2mm) que causan daño al alimentarse de hojas jóvenes y frutos.
Selenothrips rubrocinctus es la especie más común en cacao.

BIOLOGÍA:
- Ciclo de vida: 20-30 días
- Huevos insertados en el tejido vegetal
- Estados: huevo, 2 instares larvales, prepupa, pupa, adulto
- Alta capacidad reproductiva

CONDICIONES FAVORABLES:
- Época seca prolongada
- Altas temperaturas
- Baja humedad relativa
- Falta de sombra
- Estrés hídrico de las plantas

DAÑO:
- Raspado de la epidermis de hojas y frutos
- Hojas con apariencia bronceada o plateada
- Frutos con manchas oscuras y rugosas
- Reducción de la capacidad fotosintética
''',
        symptoms: 'Hojas bronceadas o plateadas, manchas oscuras en frutos, frutos rugosos, defoliación en casos severos',
        treatment: '''
CONTROL CULTURAL:
1. Mantener adecuada sombra (30-50%)
2. Riego durante época seca
3. Nutrición balanceada

CONTROL QUÍMICO:
1. Aplicación de insecticidas solo en casos severos
2. Productos a base de spinosad
3. Imidacloprid (usar con precaución por efecto en polinizadores)
4. Rotar productos para evitar resistencia

CONTROL BIOLÓGICO:
1. Conservación de enemigos naturales (chinches predadores, crisopas)
2. Hongos entomopatógenos (Beauveria bassiana)
''',
        prevention: '''
1. Mantenimiento de sombra adecuada
2. Evitar estrés hídrico
3. Monitoreo frecuente durante época seca
4. Diversificación del agroecosistema
5. Conservación de vegetación acompañante
''',
        severityLevel: 3,
      ),

      const ManualSectionModel(
        id: 0,
        chapter: 'Plagas',
        sectionTitle: 'Monalonion (Monalonion dissimulatum)',
        content: '''
Monalonion es una chinche (Hemiptera: Miridae) que causa daños severos en frutos jóvenes de cacao.
Es considerada una de las plagas más importantes en algunas regiones cacaoteras.

BIOLOGÍA:
- Insecto de 8-10mm de longitud
- Color verde amarillento con manchas oscuras
- Ciclo de vida: 40-60 días
- Ninfas y adultos causan daño

CONDICIONES FAVORABLES:
- Exceso de sombra
- Alta humedad
- Presencia de frutos jóvenes durante todo el año
- Ausencia de enemigos naturales

DAÑO:
- Picaduras en frutos jóvenes causan deformación
- Manchas necróticas hundidas
- Aborto de frutos pequeños
- Pérdidas de hasta 50% de la cosecha
''',
        symptoms: 'Frutos con picaduras y manchas hundidas, frutos deformados, aborto de frutos pequeños, presencia visible de insectos',
        treatment: '''
CONTROL CULTURAL:
1. Regulación de sombra (reducir exceso)
2. Podas de aireación
3. Eliminación de hospederos alternos

CONTROL QUÍMICO:
1. Aplicación localizada de insecticidas
2. Productos a base de lambda-cihalotrina
3. Aplicar temprano en la mañana cuando los insectos son menos activos
4. Evitar aplicaciones generalizadas

CONTROL BIOLÓGICO:
1. Conservación de avispas parasitoides
2. Chinches predadores (Zelus, Heza)
3. Arañas
''',
        prevention: '''
1. Monitoreo constante de la población
2. Regulación adecuada de sombra
3. Eliminación de plantas hospederas alternativas
4. Cosechas frecuentes para reducir disponibilidad de frutos susceptibles
5. Mantenimiento de la biodiversidad funcional
''',
        severityLevel: 4,
      ),

      // NUTRICIÓN
      const ManualSectionModel(
        id: 0,
        chapter: 'Nutrición',
        sectionTitle: 'Deficiencia de Nitrógeno',
        content: '''
El nitrógeno es esencial para el crecimiento vegetativo y la producción de clorofila.
Es uno de los nutrientes más demandados por el cultivo de cacao.

FUNCIONES DEL NITRÓGENO:
- Componente de proteínas y ácidos nucleicos
- Esencial para la síntesis de clorofila
- Promueve el crecimiento vegetativo
- Influye en la producción de flores y frutos

SÍNTOMAS DE DEFICIENCIA:
- Clorosis (amarillamiento) generalizada de hojas maduras
- Las hojas más viejas se afectan primero
- Reducción del tamaño de hojas nuevas
- Crecimiento lento y raquítico
- Caída prematura de hojas
- Reducción de la producción

CAUSAS COMUNES:
- Suelos pobres en materia orgánica
- Lixiviación por exceso de lluvia
- pH inadecuado (menor a 5.5 o mayor a 7.0)
- Competencia con malezas
''',
        symptoms: 'Hojas amarillentas uniformemente, hojas viejas afectadas primero, crecimiento lento, hojas pequeñas, defoliación',
        treatment: '''
CORRECCIÓN INMEDIATA:
1. Aplicación de urea foliar (1-2%)
2. Nitrato de amonio al suelo

FERTILIZACIÓN:
1. Aplicar 60-100 kg N/ha/año fraccionado
2. Primera aplicación al inicio de lluvias
3. Segunda aplicación a mitad del período lluvioso
4. Tercera aplicación al final de lluvias

FUENTES DE NITRÓGENO:
- Urea (46% N)
- Sulfato de amonio (21% N)
- Nitrato de amonio (33% N)
- Abonos orgánicos (compost, gallinaza)
''',
        prevention: '''
1. Análisis de suelo cada 2 años
2. Incorporación de materia orgánica
3. Uso de leguminosas como sombra
4. Aplicación de abonos orgánicos
5. Plan de fertilización balanceado
6. Control de malezas
''',
        severityLevel: 3,
      ),

      // MANEJO DEL CULTIVO
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Poda de Formación y Mantenimiento',
        content: '''
La poda es una práctica fundamental para el manejo del cacao que influye directamente en la sanidad y productividad.

TIPOS DE PODA:

1. PODA DE FORMACIÓN (Año 1-3):
- Selección de 3-4 ramas principales bien distribuidas
- Eliminar chupones del tronco principal
- Formar la arquitectura básica del árbol
- Altura de horqueta: 0.8-1.2m

2. PODA DE MANTENIMIENTO (Anual):
- Eliminar ramas secas, enfermas o improductivas
- Remover chupones
- Abrir el centro del árbol para mejor aireación
- Reducir altura excesiva (máximo 4m)

3. PODA FITOSANITARIA:
- Remoción de escobas de bruja
- Corte de ramas con cáncer del tallo
- Eliminar tejido enfermo
- Desinfectar herramientas entre cortes

ÉPOCA DE PODA:
- Preferiblemente en época seca
- Evitar podas fuertes durante floración principal
- Poda sanitaria todo el año según necesidad
''',
        symptoms: 'N/A - Este es contenido de manejo, no de síntomas de problemas',
        treatment: '''
PROCEDIMIENTO DE PODA:

1. HERRAMIENTAS:
- Tijeras de podar
- Sierra curva
- Machete afilado
- Pasta cicatrizante

2. TÉCNICA:
- Cortes limpios y al ras
- No dejar tocones
- Aplicar pasta en cortes mayores a 3cm
- Desinfectar herramientas con hipoclorito al 5%

3. FRECUENCIA:
- Poda de mantenimiento: 2-3 veces/año
- Poda sanitaria: según necesidad
- Deschuponado: mensual
''',
        prevention: '''
1. Planificar arquitectura desde la siembra
2. Intervenciones tempranas y frecuentes
3. Uso de herramientas adecuadas y desinfectadas
4. Proteger heridas de poda
5. Evitar podas drásticas
6. Capacitación continua del personal
''',
        severityLevel: 1,
      ),

      const ManualSectionModel(
        id: 0,
        chapter: 'Postcosecha',
        sectionTitle: 'Fermentación del Cacao',
        content: '''
La fermentación es el proceso más importante para desarrollar los precursores del sabor y aroma del chocolate.
Un proceso de fermentación inadecuado resulta en cacao de baja calidad.

OBJETIVOS DE LA FERMENTACIÓN:
1. Matar el embrión de la semilla
2. Desarrollar precursores del sabor
3. Reducir amargor y astringencia
4. Facilitar el desprendimiento del mucílago

PROCESO:
1. Cosecha de mazorcas maduras
2. Quiebre y extracción de granos con mucílago (máximo 24h post-cosecha)
3. Colocación en cajones o montones de fermentación
4. Fermentación por 5-7 días dependiendo del tipo de cacao
5. Volteos cada 24-48 horas

FASES DE FERMENTACIÓN:
1. Fase anaeróbica (0-48h): degradación de azúcares a etanol
2. Fase aeróbica (48h-final): oxidación de etanol a ácido acético
3. Muerte del embrión y desarrollo de precursores

INDICADORES DE BUENA FERMENTACIÓN:
- Temperatura alcanza 45-50°C
- Color interno marrón uniforme
- Olor a vinagre que cambia a chocolate
- Cotiledones se separan fácilmente de la testa
''',
        symptoms: 'N/A - Este es contenido de postcosecha, no de síntomas de problemas',
        treatment: '''
SOLUCIÓN A PROBLEMAS COMUNES:

1. FERMENTACIÓN INCOMPLETA:
- Aumentar tiempo de fermentación
- Verificar tamaño de masa (mínimo 50kg)
- Mejorar aislamiento térmico

2. SOBRE-FERMENTACIÓN:
- Reducir tiempo
- Aumentar frecuencia de volteos
- Mejorar drenaje

3. GRANOS MOHOSOS:
- Mejorar ventilación
- Reducir humedad ambiente
- Secar más rápidamente después de fermentar

4. OLOR AMONIACAL:
- Indicador de putrefacción
- Mejorar manejo de la masa
- No exceder tiempo de fermentación
''',
        prevention: '''
1. Cosechar solo mazorcas maduras
2. Quiebre el mismo día de cosecha
3. No mezclar granos de diferentes días
4. Usar cajones de madera bien construidos
5. Cubrir la masa durante fermentación
6. Volteos regulares y completos
7. Capacitación constante del personal
8. Registros de temperatura y tiempo
''',
        severityLevel: 1,
      ),
    ];
  }

  Future<void> _seedMlMappings() async {
    final mappings = [
      const MlMappingModel(
        mlClassId: 'moniliasis',
        mlClassLabel: 'Moniliasis detectada',
        sectionIds: [1],
        confidenceThreshold: 0.6,
      ),
      const MlMappingModel(
        mlClassId: 'black_pod',
        mlClassLabel: 'Mazorca Negra detectada',
        sectionIds: [2],
        confidenceThreshold: 0.6,
      ),
      const MlMappingModel(
        mlClassId: 'witches_broom',
        mlClassLabel: 'Escoba de Bruja detectada',
        sectionIds: [3],
        confidenceThreshold: 0.6,
      ),
      const MlMappingModel(
        mlClassId: 'thrips',
        mlClassLabel: 'Daño por Trips detectado',
        sectionIds: [4],
        confidenceThreshold: 0.7,
      ),
      const MlMappingModel(
        mlClassId: 'monalonion',
        mlClassLabel: 'Daño por Monalonion detectado',
        sectionIds: [5],
        confidenceThreshold: 0.7,
      ),
      const MlMappingModel(
        mlClassId: 'nitrogen_deficiency',
        mlClassLabel: 'Deficiencia de Nitrógeno detectada',
        sectionIds: [6],
        confidenceThreshold: 0.65,
      ),
      const MlMappingModel(
        mlClassId: 'healthy',
        mlClassLabel: 'Planta saludable',
        sectionIds: [7], // Poda de mantenimiento como recomendación general
        confidenceThreshold: 0.8,
      ),
    ];

    for (final mapping in mappings) {
      await dataSource.insertMlMapping(mapping);
    }
  }

  Future<void> _seedSynonyms() async {
    final synonyms = {
      'enfermedad': ['patología', 'infección', 'padecimiento'],
      'hongo': ['fungus', 'micosis', 'fungal'],
      'plaga': ['insecto', 'pest', 'infestación'],
      'síntoma': ['signo', 'indicador', 'manifestación'],
      'tratamiento': ['control', 'manejo', 'solución', 'cura'],
      'prevención': ['prevenir', 'evitar', 'protección'],
      'moniliasis': ['monilia', 'pudrición'],
      'mazorca': ['fruto', 'cacao', 'pod'],
      'negra': ['negro', 'oscuro', 'black'],
      'escoba': ['broom', 'malformación'],
      'bruja': ['witch', 'witches'],
      'poda': ['corte', 'podar', 'pruning'],
      'fermentación': ['fermentar', 'fermented'],
      'nutrición': ['nutriente', 'fertilización', 'abono'],
      'deficiencia': ['carencia', 'falta', 'deficiency'],
      'nitrógeno': ['nitrogen', 'n'],
      'amarillo': ['clorosis', 'amarillamiento', 'yellow'],
      'mancha': ['lesión', 'spot', 'marca'],
    };

    for (final entry in synonyms.entries) {
      for (final synonym in entry.value) {
        await dataSource.insertSynonym(entry.key, synonym);
        // Also add reverse synonym
        await dataSource.insertSynonym(synonym, entry.key);
      }
    }
  }
}
