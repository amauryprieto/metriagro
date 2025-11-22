import '../models/manual_section_model.dart';
import '../models/ml_mapping_model.dart';
import '../models/tag_model.dart';
import 'cacao_manual_local_datasource.dart';

/// Seeder para la base de datos del Manual de BPA de Cacao
/// Fuente: Compañía Nacional de Chocolates - Tercera Edición (2019)
/// ISBN: 978-958-57845-5-0
class CacaoManualSeeder {
  final CacaoManualLocalDataSource dataSource;

  CacaoManualSeeder(this.dataSource);

  Future<void> seedDatabase() async {
    await _seedTags();
    await _seedSections();
    await _seedMlMappings();
    await _seedSynonyms();
  }

  Future<void> _seedTags() async {
    final tags = [
      const TagModel(id: 0, name: 'bpa'),
      const TagModel(id: 0, name: 'medio_ambiente'),
      const TagModel(id: 0, name: 'higiene'),
      const TagModel(id: 0, name: 'inocuidad'),
      const TagModel(id: 0, name: 'seguridad'),
      const TagModel(id: 0, name: 'salud'),
      const TagModel(id: 0, name: 'registros'),
      const TagModel(id: 0, name: 'trazabilidad'),
      const TagModel(id: 0, name: 'establecimiento'),
      const TagModel(id: 0, name: 'manejo'),
      const TagModel(id: 0, name: 'nutricion'),
      const TagModel(id: 0, name: 'riego'),
      const TagModel(id: 0, name: 'poda'),
      const TagModel(id: 0, name: 'arvenses'),
      const TagModel(id: 0, name: 'mipe'),
      const TagModel(id: 0, name: 'plaga'),
      const TagModel(id: 0, name: 'enfermedad'),
      const TagModel(id: 0, name: 'fitosanitario'),
      const TagModel(id: 0, name: 'cosecha'),
      const TagModel(id: 0, name: 'beneficio'),
      const TagModel(id: 0, name: 'fermentacion'),
      const TagModel(id: 0, name: 'secado'),
      const TagModel(id: 0, name: 'almacenamiento'),
      const TagModel(id: 0, name: 'comercializacion'),
      const TagModel(id: 0, name: 'certificacion'),
    ];

    for (final tag in tags) {
      await dataSource.insertTag(tag);
    }
  }

  Future<void> _seedSections() async {
    final sections = _getManualSections();
    await dataSource.insertSections(sections);
    await _linkSectionsToTags();
  }

  Future<void> _linkSectionsToTags() async {
    // Section 1 (Qué son las BPA) -> bpa
    await dataSource.linkSectionToTag(1, 1);
    // Section 2 (Beneficios BPA) -> bpa
    await dataSource.linkSectionToTag(2, 1);
    // Section 3 (Medio ambiente) -> medio_ambiente, bpa
    await dataSource.linkSectionToTag(3, 1);
    await dataSource.linkSectionToTag(3, 2);
    // Section 4 (Higiene) -> higiene, inocuidad
    await dataSource.linkSectionToTag(4, 3);
    await dataSource.linkSectionToTag(4, 4);
    // Section 5 (SST) -> seguridad, salud
    await dataSource.linkSectionToTag(5, 5);
    await dataSource.linkSectionToTag(5, 6);
    // Section 6 (Historial) -> registros
    await dataSource.linkSectionToTag(6, 7);
    // Section 7 (Registros) -> registros, trazabilidad
    await dataSource.linkSectionToTag(7, 7);
    await dataSource.linkSectionToTag(7, 8);
    // Section 8 (Establecimiento) -> establecimiento
    await dataSource.linkSectionToTag(8, 9);
    // Section 9 (Nutrición) -> nutricion, manejo
    await dataSource.linkSectionToTag(9, 10);
    await dataSource.linkSectionToTag(9, 11);
    // Section 10 (Riego) -> riego, manejo
    await dataSource.linkSectionToTag(10, 10);
    await dataSource.linkSectionToTag(10, 12);
    // Section 11 (Podas) -> poda, manejo
    await dataSource.linkSectionToTag(11, 10);
    await dataSource.linkSectionToTag(11, 13);
    // Section 12 (MIA) -> arvenses, manejo
    await dataSource.linkSectionToTag(12, 10);
    await dataSource.linkSectionToTag(12, 14);
    // Section 13 (MIPE) -> mipe, plaga, enfermedad
    await dataSource.linkSectionToTag(13, 15);
    await dataSource.linkSectionToTag(13, 16);
    await dataSource.linkSectionToTag(13, 17);
    // Section 14 (Fitosanitarios) -> fitosanitario
    await dataSource.linkSectionToTag(14, 18);
    // Section 15 (Cosecha y Beneficio) -> cosecha, beneficio, fermentacion, secado
    await dataSource.linkSectionToTag(15, 19);
    await dataSource.linkSectionToTag(15, 20);
    await dataSource.linkSectionToTag(15, 21);
    await dataSource.linkSectionToTag(15, 22);
    // Section 16 (Comercialización) -> comercializacion, almacenamiento
    await dataSource.linkSectionToTag(16, 23);
    await dataSource.linkSectionToTag(16, 24);
    // Section 17 (Certificación) -> certificacion, bpa
    await dataSource.linkSectionToTag(17, 25);
    await dataSource.linkSectionToTag(17, 1);
  }

  List<ManualSectionModel> _getManualSections() {
    return [
      // 1. QUÉ SON LAS BPA
      const ManualSectionModel(
        id: 0,
        chapter: 'Introducción',
        sectionTitle: '¿Qué son las BPA?',
        content: '''
Las Buenas Prácticas Agrícolas (BPA), según FAO/OMS, "consisten en la aplicación del conocimiento disponible a la utilización sostenible de los recursos naturales básicos para la producción, en forma benévola, de productos agrícolas alimentarios y no alimentarios, inocuos y saludables, a la vez que se procura la viabilidad económica y la estabilidad social".

Las Buenas Práctica Agrícolas o BPA abarcan un conjunto de principios, normas y recomendaciones técnicas, buscando mejorar todas aquellas labores o actividades que se desarrollan día a día en nuestras fincas o explotaciones agrícolas, con el objetivo de producir alimentos sanos, inocuos, de alta calidad, proteger el medio ambiente y brindar mejores condiciones (bienestar) a los trabajadores y sus familias.

La certificación en BPA traerá a los productores de cacao grandes beneficios como el acceso a nuevos mercados que posibilitan negociar el producto a mejores precios. De igual manera puede tener mayor facilidad de acceder a otros trámites de certificación para mercados especiales en cacao a nivel nacional e internacional.

PILARES DE LAS BPA:
- Medio ambiente
- Calidad
- Bienestar y seguridad
''',
        symptoms: null,
        treatment: null,
        prevention: null,
        severityLevel: 1,
      ),

      // 2. BENEFICIOS DE LAS BPA
      const ManualSectionModel(
        id: 0,
        chapter: 'Introducción',
        sectionTitle: 'Beneficios de las BPA',
        content: '''
¿CUÁLES SON LOS BENEFICIOS DE LAS BPA?

• Mejorar la calidad e inocuidad de los productos.
• Bienestar para los productores y la comunidad.
• Proteger el medio ambiente (minimizando el impacto ambiental negativo).
• Mejorar la eficiencia en la producción (organización y mayor producción a menor costo).
• Lograr la diferenciación en precios al comercializar el producto.
• Reducción de plagas y enfermedades en el cultivo.
• Identificar peligros o prácticas inadecuadas para su prevención y control (prácticas o procesos más adecuados) buscando el cumplimiento de los tres principios (medio ambiente, calidad, bienestar y seguridad).
''',
        symptoms: null,
        treatment: null,
        prevention: null,
        severityLevel: 1,
      ),

      // 3.1 MEDIO AMBIENTE
      const ManualSectionModel(
        id: 0,
        chapter: 'Aspectos Generales BPA',
        sectionTitle: 'Medio Ambiente',
        content: '''
Para reducir el impacto sobre el medio ambiente se recomienda:

• Definir un plan de manejo integrado de residuos sólidos, con lineamientos para evitar, reducir, reutilizar y reciclar ciertos productos. En el caso de los residuos líquidos cómo el mucilago del cacao, se puede esparcir sobre las cáscaras del cacao o buscar usos alternativos como por ejemplo en el manejo de arvenses (herbicida).

• Disponer de puntos ecológicos, para realizar una correcta disposición de los residuos.

• Realizar disposición adecuada de empaques de agroquímicos (triple lavado y perforado, no reutilizar y entregar al programa de manejo de residuos de la zona).

• Usar agroquímicos que estén registrados ante el ICA. No utilizar productos vencidos o en mal estado.

• Contar con pozos sépticos en las viviendas.

• Utilizar sistemas agroforestales, lo cual favorece la biodiversidad en el cultivo y disminuye el impacto del cambio climático.

• Realizar un manejo integrado de plagas y enfermedades (MIPE) que reduzca y garantice un uso adecuado de agroquímicos.

• No contaminar fuentes de agua.

• Evitar la erosión y pérdida de nutrientes del suelo.

• Definir un plan de manejo del cultivo, para realizar un adecuado uso de fertilizantes y agroquímicos.

• Usar la cantidad de agua necesaria para el ahorro y cuidado del cultivo.
''',
        symptoms: null,
        treatment: '''
ACCIONES CORRECTIVAS:
1. Implementar puntos ecológicos para separación de residuos
2. Establecer programa de triple lavado para envases de agroquímicos
3. Verificar registro ICA de todos los productos utilizados
4. Instalar pozos sépticos donde no existan
5. Implementar sistemas agroforestales
''',
        prevention: '''
1. Capacitar al personal en manejo de residuos
2. Mantener inventario actualizado de agroquímicos
3. Respetar zonas de protección de fuentes de agua
4. Implementar barreras vivas y coberturas vegetales
5. Realizar análisis de suelo periódicamente
''',
        severityLevel: 2,
      ),

      // 3.2 HIGIENE E INOCUIDAD
      const ManualSectionModel(
        id: 0,
        chapter: 'Aspectos Generales BPA',
        sectionTitle: 'Higiene e Inocuidad del Producto',
        content: '''
REQUISITOS DE HIGIENE E INOCUIDAD:

• El predio debe contar con procedimientos de higiene y señalización, en especial en las áreas críticas. Estos deben ser socializados con todo el personal para garantizar el correcto funcionamiento y cumplimiento.

• Los recipientes en los que se colocan los granos (masa fresca) y se transportan al fermentador, deben tener condiciones adecuadas de limpieza y su uso debe ser exclusivo para este. No se recomiendan utensilios metálicos.

• Al desgranar la mazorca, separar la placenta y no mezclar granos de cacao sanos con enfermos. Durante la fermentación no se deben mezclar granos provenientes de diferentes días de desgrane.

• Se debe contar con disponibilidad de lavamanos en campo para asegurar la limpieza de las manos antes de manipular el producto y después de ir al baño.

• El área de beneficio y los vehículos para el transporte interno del cacao, deben contar con un programa de limpieza, con frecuencias, métodos y registros definidos.

• El área de fermentación, secado y herramientas deben ser exclusivas para el beneficio del cacao.

• El área de beneficio debe estar delimitada por una barrera física, esto con el objetivo de evitar el acceso de animales domésticos o de la finca que puedan generar una contaminación cruzada.

• El sitio de almacenamiento del cacao en grano debe ser seguro y garantizar que no ingresen animales que puedan contaminar el grano. No debe haber infestación de roedores ni plagas y para ello se debe contar con un programa para el control de roedores.

• Los granos de cacao se deben empacar en sacos de fique que se encuentren limpios, secos, en buen estado y que sean destinados exclusivamente para almacenar cacao.

• Se debe evitar la contaminación con desechos orgánicos, cáscaras, productos químicos, combustibles, materiales extraños (vidrio, madera, clavos, piedras, otros) y la presencia de animales y plagas durante la cosecha, fermentación, secado, almacenamiento y transporte.

• El vehículo empleado para el transporte de cacao debe estar limpio, libre de materiales extraños y contaminantes. El producto se debe proteger del sol, la lluvia, el polvo, entre otros.

• La labor de cargue y descargue de los bultos de cacao se realiza de tal manera que minimice los riesgos sanitarios sobre el grano. Además de garantizar la salud y el bienestar del trabajador.

• Deben garantizarse las características de calidad basadas en Norma Técnica Colombiana del Icontec (NTC 1252).
''',
        symptoms: 'Contaminación del grano, presencia de materiales extraños, granos con moho, olores desagradables, infestación de plagas',
        treatment: '''
ACCIONES CORRECTIVAS:
1. Limpiar y desinfectar áreas afectadas
2. Separar lotes contaminados
3. Implementar programa de control de roedores
4. Reemplazar recipientes y utensilios en mal estado
5. Capacitar al personal en procedimientos de higiene
''',
        prevention: '''
1. Establecer programa de limpieza con frecuencias definidas
2. Instalar lavamanos en puntos estratégicos
3. Delimitar áreas de beneficio con barreras físicas
4. Usar exclusivamente sacos de fique limpios y en buen estado
5. Mantener registros de limpieza actualizados
''',
        severityLevel: 3,
      ),

      // 3.3 SEGURIDAD Y SALUD EN EL TRABAJO
      const ManualSectionModel(
        id: 0,
        chapter: 'Aspectos Generales BPA',
        sectionTitle: 'Seguridad y Salud en el Trabajo (SST)',
        content: '''
REQUISITOS DE SEGURIDAD Y SALUD EN EL TRABAJO:

• Hacer una evaluación de riesgos que permita identificarlos y mitigarlos.

• Los operarios deben ser capacitados en las actividades que van a realizar. Se debe llevar registros de capacitación.

Los trabajadores se deben capacitar en los siguientes temas:
- Enfermedades transmisibles
- Aseo personal e higiene
- Comportamiento personal
- Manipulación de productos químicos, desinfectantes, productos fitosanitarios, biosidas u otras sustancias peligrosas
- Operación de equipos complejos o peligrosos
- Manejo de extintores

El predio debe contar con instrucciones documentadas y visibles en cuanto a la higiene las cuales deben ser informadas a los trabajadores durante la inducción. Las instrucciones incluyen al menos:
- Limpieza de manos
- Tratamiento de cortes en la piel
- Notificación de infecciones o problema de salud
- Uso de ropa de protección adecuada

• Se debe contar con un botiquín, un plan de primeros auxilios y al menos una persona capacitada.

• Se debe velar por la seguridad del trabajador, dotándolo de los elementos de protección personal necesarios para la labor a desempeñar, por ejemplo, gafas, guantes, botas, uniforme, entre otros. Se debe llevar el registro de entrega de EPP por cada operario.

• Se debe contar con servicios sanitarios y lavamanos en buen estado, limpios y que garanticen el acceso de los trabajadores a las instalaciones sanitarias.

• Se debe contar con un lugar apropiado para consumir alimentos.

• Se debe hacer chequeos de salud periódicos a los operarios.

• Todos los trabajadores deben llevar puesta vestimenta externa limpia y en condiciones aptas para el trabajo.

• Deben destinarse áreas específicas para fumar, comer y beber, restringiéndose en áreas de manipulación o almacenamiento del producto.

PROCEDIMIENTOS DE EMERGENCIA:
Los procedimientos en caso de accidente deben estar claramente señalizados en ubicaciones accesibles y visibles. Se debe identificar:
- Dirección de la finca o ubicación en el mapa
- Persona(s) a contactar y su número telefónico
- Lugar dónde se encuentra el medio de comunicación más cercano
- Lista actualizada de números telefónicos relevantes (policía, ambulancia, hospital, bomberos)
- Cómo y dónde contactar a los servicios médicos locales
- Interruptores de emergencia de electricidad, gas y agua

• Se debe contar con instrucciones documentadas y las hojas de seguridad de los productos en caso de un derrame de agroquímicos.

• Se debe tener en cuenta las fichas técnicas y de seguridad para la aplicación de un agroquímico o fertilizante.
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Realizar evaluación de riesgos anual
2. Mantener registros de capacitación actualizados
3. Dotar de EPP a todos los trabajadores
4. Mantener botiquín de primeros auxilios completo
5. Programar chequeos médicos periódicos
6. Señalizar procedimientos de emergencia
''',
        severityLevel: 2,
      ),

      // 3.4 HISTORIAL DEL CULTIVO
      const ManualSectionModel(
        id: 0,
        chapter: 'Aspectos Generales BPA',
        sectionTitle: 'Historial del Cultivo',
        content: '''
El historial del cultivo permite:

• Saber qué se ha sembrado antes en la finca.
• Saber qué uso tenía la tierra.
• Saber qué productos químicos se han utilizado.
• Saber qué plagas, enfermedades y malezas están presentes en la zona.
• Identificar posibles contaminaciones de terrenos vecinos.
• Registrar los sucesos más importantes que se han presentado en la finca (siembras, cosechas, construcciones y adecuaciones).
• Registrar los eventos de perturbación (Inundaciones, sequías, ataque de plagas severos).

Conociendo su finca en un mapa usted puede responder inquietudes como:
- ¿Dónde está usted?
- ¿Cuánto terreno tiene?
- ¿Cuánto puede cultivar?
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Elaborar croquis o mapa de la finca
2. Documentar uso histórico del terreno
3. Mantener registro de productos aplicados
4. Registrar eventos climáticos significativos
5. Documentar incidencia de plagas y enfermedades
''',
        severityLevel: 1,
      ),

      // 3.5 MANEJO DE REGISTROS Y TRAZABILIDAD
      const ManualSectionModel(
        id: 0,
        chapter: 'Aspectos Generales BPA',
        sectionTitle: 'Manejo de Registros y Trazabilidad',
        content: '''
Llevar registros de la finca tales como:

• Información de la finca (área, número de lotes, cantidad de árboles, otros).
• Ingresos y gastos.
• Producción y ventas.
• Aplicación de productos (fertilizantes, insecticidas, herbicidas, fungicidas, fitohormonas, otros).
• Actividades en campo (siembra, poda, control sanitario, otros).
• Inventarios de fertilizantes, insecticidas, fungicidas, herbicidas, entre otros.
• Formato de quejas y reclamos sobre el producto.
• Formato para el mantenimiento de maquinaria y equipos.

Los registros se pueden llevar en cuadernos, hojas, formatos o libretas. Estos ayudan a:
• Medir y hacer seguimiento a las actividades de la finca.
• Conocer la rentabilidad de la finca.
• Elaborar cronograma anual de labores y actividades de la finca.
• Identificar la procedencia de un producto utilizando la trazabilidad.

NOTA: La trazabilidad son todas las actividades realizadas (el histórico de los procesos) para la transformación del producto. Esto nos permite reconstruir el historial o trayectoria de un producto mediante los registros que se diligencian en la cadena de producción.

EJEMPLO DE REGISTROS MÁS UTILIZADOS:
• Registro de producción y venta (Fecha, Lote, Kg en baba, Kg secos, Calidad, Precio, Valor total)
• Registro de aplicación de productos sanitarios (Lote, Producto, Casa comercial, Ingrediente activo, Registro ICA, Control/beneficio, Dosis, Fecha ingreso, Período de carencia, Operario)
• Registro de actividades (Fecha, Lote, Actividad, Horas, Jornales)
• Registro de limpieza de áreas (Fecha, Área, Descripción, Observaciones)
• Registro del control Fitosanitario (Fecha, Lote, Número de mazorcas afectadas por Phytophthora, Monilia, Animales, Ramas y/o cojines con Escoba Bruja)
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Implementar sistema de registros desde el inicio
2. Capacitar al personal en diligenciamiento de formatos
3. Revisar registros periódicamente
4. Mantener archivo organizado y accesible
5. Actualizar inventarios constantemente
''',
        severityLevel: 1,
      ),

      // 3.6 ESTABLECIMIENTO DEL CULTIVO
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Establecimiento del Cultivo',
        content: '''
REQUISITOS PARA EL ESTABLECIMIENTO DEL CULTIVO:

• Se debe utilizar clones de cacao recomendados para la zona de acuerdo con su adaptación, productividad, manejo, calidad del grano, tolerancia a plagas y enfermedades.

• Las semillas, yemas o plántulas deben ser adquiridas en viveros o fincas con jardín clonal registrados ante el ICA.

• Se recomienda establecer clones de cacao autocompatibles (AC) para garantizar una buena producción, independiente de las condiciones ambientales.

• Se debe seleccionar los lotes respetando los retiros de las fuentes de agua.

• Se debe respetar las zonas de reserva natural o zonas de conservación, así como también dar cumplimiento al Plan de Ordenamiento Territorial de la localidad.

• El lote debe reunir las condiciones óptimas para el cultivo:
  - Temperatura media entre 23 y 28 °C
  - Precipitación media anual entre 1.800 y 2.600 mm (importante una buena distribución de las lluvias)
  - Profundidad del suelo no menor a 1 metro
  - Altura sobre el nivel del mar entre 0 y 1.200 m
  - Se debe tener en cuenta las características específicas del lote (pendiente, textura, drenaje)

• Se debe evitar la erosión del suelo y pérdida de nutrientes, a través de cobertura vegetal, residuos de podas, barreras vivas, drenajes, entre otras.

• El productor debe guardar y mantener los registros de los métodos de siembra, la densidad de siembra y las fechas de las mismas, diseño o distribución de los cultivares utilizados, además debe tener información sobre las condiciones y parámetros técnicos de siembra.

• Se debe tener en cuenta la pendiente del terreno para el trazado de los cultivos.

• Es ideal que la finca cuente con sistema de riego para el establecimiento y sostenimiento del cultivo.
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Verificar registro ICA del proveedor de material vegetal
2. Seleccionar clones adaptados a la zona
3. Respetar retiros de fuentes de agua
4. Realizar análisis de suelo antes de establecer
5. Implementar sistema de riego cuando sea posible
6. Documentar toda la información de siembra
''',
        severityLevel: 2,
      ),

      // 3.7 MANEJO DEL CULTIVO - NUTRICIÓN
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Nutrición del Cultivo',
        content: '''
MANEJO DE LA NUTRICIÓN:

• Realizar análisis de suelo y foliar (si es factible) para establecer un programa de nutrición adecuado.

• Seguir las recomendaciones de los técnicos en cuanto a la dosis, método y frecuencia de aplicación.

• No se deben aplicar fertilizantes cerca de las fuentes de agua.

• Se recomienda utilizar abonos orgánicos únicamente bien compostados.

ALMACENAMIENTO DE FERTILIZANTES:
Los fertilizantes se deben almacenar correctamente de la siguiente manera:
• Separados de otros agroquímicos y cacao en grano, en un lugar seguro, fresco y ventilado, protegidos de la intemperie.
• En una zona sin residuos que no promueva la presencia de roedores.
• Donde puedan limpiarse los derrames y fugas.
• Almacenados bajo acceso restringido sólo a personal autorizado.
• Utilizando estibas y separados de la pared.
• Se debe mantener un inventario actualizado.
• En caso de que sobre fertilizantes, se debe marcar adecuadamente.
''',
        symptoms: 'Hojas amarillentas, crecimiento lento, baja producción, hojas pequeñas, defoliación prematura',
        treatment: '''
CORRECCIÓN DE DEFICIENCIAS:
1. Realizar análisis de suelo para identificar deficiencias
2. Aplicar fertilizantes según recomendación técnica
3. Considerar aplicaciones foliares para corrección rápida
4. Incorporar materia orgánica compostada
5. Ajustar pH del suelo si es necesario
''',
        prevention: '''
1. Análisis de suelo cada 2 años
2. Plan de fertilización basado en análisis
3. Aplicaciones fraccionadas durante el año
4. Uso de abonos orgánicos compostados
5. Control de malezas para reducir competencia
''',
        severityLevel: 2,
      ),

      // 3.7 MANEJO DEL CULTIVO - RIEGO
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Riego',
        content: '''
MANEJO DEL RIEGO:

• Respetar las concesiones de agua. Llevar registro de la cantidad de litros o metros cúbicos que son captados a diario.

• No utilizar aguas residuales, aguas negras o industriales.

• Sólo usar el agua necesaria en el momento necesario.

• Utilizar sistemas de riego de bajo consumo de agua (por ejemplo, microaspersión o goteo).

• Hacer un manejo adecuado de las aguas utilizadas en los procesos de la finca, evitando al máximo la contaminación de fuentes de agua.

• Demostrar, por medio de análisis de laboratorio, que el agua cumple con lo establecido en la legislación nacional vigente para agua de riego.
''',
        symptoms: 'Marchitez, hojas caídas, estrés hídrico, reducción de floración, aborto de frutos',
        treatment: '''
CORRECCIÓN:
1. Implementar sistema de riego apropiado
2. Programar riegos según necesidad del cultivo
3. Verificar calidad del agua de riego
4. Reparar fugas en el sistema
''',
        prevention: '''
1. Instalar sistema de riego eficiente
2. Monitorear necesidades hídricas del cultivo
3. Mantener registros de consumo de agua
4. Realizar análisis de calidad de agua periódicamente
''',
        severityLevel: 2,
      ),

      // 3.7 MANEJO DEL CULTIVO - PODAS
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Podas',
        content: '''
MANEJO DE PODAS:

• Las podas permiten al árbol expresar su capacidad productiva, a través de la regulación de su estructura, facilidad en el manejo agronómico e incidencia en la fisiología del árbol.

• Las podas se deben hacer cuando el árbol tiene pocos frutos pequeños, al final de los picos de cosecha, en épocas de baja floración y al final de períodos secos e inicio de las lluvias.

• La poda facilita las labores culturales del cultivo, regula y favorece la entrada de luz, sincroniza la fructificación, facilita el manejo integrado de plagas y enfermedades, permitiendo disminuir costos de producción.

• Se debe emplear herramientas adecuadas, hacer cortes limpios y cicatrizar cuando sea necesario.

• Cuando se trate de poda de formación se deben tener en cuenta aspectos con relación a la edad de las plantas y la conformación adecuada para la vida adulta del árbol.

TIPOS DE PODA:
1. PODA DE FORMACIÓN (Año 1-3): Selección de ramas principales, eliminar chupones, formar arquitectura básica
2. PODA DE MANTENIMIENTO: Eliminar ramas secas, enfermas o improductivas, remover chupones
3. PODA FITOSANITARIA: Remoción de escobas de bruja, tejido enfermo
''',
        symptoms: null,
        treatment: '''
PROCEDIMIENTO DE PODA:
1. Usar herramientas adecuadas (tijeras, sierra curva, machete afilado)
2. Hacer cortes limpios y al ras
3. No dejar tocones
4. Aplicar pasta cicatrizante en cortes mayores a 3cm
5. Desinfectar herramientas entre árboles
''',
        prevention: '''
1. Planificar podas según calendario
2. Capacitar al personal en técnicas de poda
3. Mantener herramientas en buen estado
4. Realizar podas preventivas periódicamente
''',
        severityLevel: 1,
      ),

      // 3.7 MANEJO DEL CULTIVO - MIA
      const ManualSectionModel(
        id: 0,
        chapter: 'Manejo del Cultivo',
        sectionTitle: 'Manejo Integrado de Arvenses (MIA)',
        content: '''
MANEJO INTEGRADO DE ARVENSES (MIA):

Consiste en la combinación oportuna y adecuada de diferentes prácticas, como el manejo mecánico, químico, manual, cultural y biológico, con el fin de reducir la interferencia de las arvenses.

Se debe tener en cuenta que la conservación de algunas arvenses contribuye a minimizar el riesgo de erosión del suelo y propagación de arvenses agresivas, es por ello que se pueden favorecer o introducir especies de baja interferencia (arvenses nobles).

• El MIA se ejecuta en diferentes épocas a lo largo del año, para esto se realiza un cronograma de labores previo a la ejecución, con el objetivo de garantizar un control idóneo de las plantas no deseadas evitando afectaciones sobre la productividad del cultivo de cacao.

• Independiente al tipo de manejo, en cada ciclo de control se debe realizar un plateo (consiste en eliminar de manera manual todas las arvenses o "plantas indeseables" que están alrededor de la planta de interés), con el objetivo de garantizar que no se presenten daños al cultivo en la ejecución de la labor.

MÉTODOS DE CONTROL:
1. Control manual (plateo, deshierba)
2. Control mecánico (guadaña)
3. Control químico (herbicidas)
4. Control cultural (coberturas)
5. Control biológico
''',
        symptoms: 'Competencia por nutrientes, agua y luz; refugio de plagas; dificultad para labores culturales',
        treatment: '''
CONTROL:
1. Realizar plateo alrededor de cada árbol
2. Combinar métodos de control según necesidad
3. Favorecer arvenses nobles de baja interferencia
4. Usar herbicidas solo cuando sea necesario
''',
        prevention: '''
1. Establecer cronograma de control de arvenses
2. Mantener coberturas vegetales beneficiosas
3. Capacitar al personal en identificación de arvenses
4. Usar EPP en aplicación de herbicidas
''',
        severityLevel: 2,
      ),

      // 3.8 MIPE
      const ManualSectionModel(
        id: 0,
        chapter: 'Sanidad del Cultivo',
        sectionTitle: 'Manejo Integrado de Plagas y Enfermedades (MIPE)',
        content: '''
MANEJO INTEGRADO DE PLAGAS Y ENFERMEDADES (MIPE):

• La persona con responsabilidad técnica del cultivo debe demostrar su competencia en el manejo integrado de plagas y enfermedades, a través de su experiencia, capacitación formal y documentada.

• Deben implementarse métodos de cultivo que reduzcan la incidencia e intensidad de ataques de plagas y enfermedades, tales como labores de poda, control de sombrío y buena nutrición.

• Es importante realizar monitoreo permanente de la incidencia y severidad de plagas y enfermedades llevando un adecuado manejo de los registros de esta actividad. Con esta información se determina el umbral económico de daño (UED) para así tomar una decisión del uso o no de agroquímicos para la prevención o control de la plaga o enfermedad.

PRINCIPALES PLAGAS Y ENFERMEDADES DEL CACAO EN COLOMBIA:

PLAGAS:
• Hormiga arriera (Atta spp)
• Perforador de la mazorca (Carmenta foraseminis)
• Monalonion (Monalonion spp)

ENFERMEDADES:
• Monilia (Moniliophthora roreri)
• Escoba de bruja (Moniliophthora perniciosa)
• Fitóptora / Mazorca negra (Phytophthora spp)

ESTRATEGIAS DE CONTROL:
1. Control cultural (podas, regulación de sombra, nutrición)
2. Control mecánico (remoción de material enfermo)
3. Control biológico (enemigos naturales, hongos antagonistas)
4. Control químico (último recurso, productos registrados)
''',
        symptoms: 'Manchas en frutos, deformaciones, pudriciones, daños en hojas, presencia de insectos, escobas en ramas',
        treatment: '''
MANEJO:
1. Identificar correctamente la plaga o enfermedad
2. Determinar nivel de daño económico
3. Implementar control cultural como primera opción
4. Usar control químico solo si es necesario
5. Registrar todas las aplicaciones
''',
        prevention: '''
1. Monitoreo permanente del cultivo
2. Podas sanitarias frecuentes
3. Regulación adecuada de sombra (30-50%)
4. Nutrición balanceada
5. Cosecha sanitaria (remoción de frutos enfermos)
6. Uso de material genético tolerante
''',
        severityLevel: 4,
      ),

      // 3.9 MANEJO DE PRODUCTOS FITOSANITARIOS
      const ManualSectionModel(
        id: 0,
        chapter: 'Sanidad del Cultivo',
        sectionTitle: 'Manejo de Productos Fitosanitarios',
        content: '''
MANEJO DE PRODUCTOS FITOSANITARIOS:

• Se deben identificar las plagas o enfermedades, determinar el impacto económico de su daño y definir su manejo integrado, que incluye control cultural, mecánico, biológico y como último recurso, control químico.

• Los productos aplicados deben estar registrados ante el ICA.

• Seguir las recomendaciones de las etiquetas de los productos.

• Disponer de equipos de medición adecuados (gramera y dosificadores) para asegurar el cumplimiento de las indicaciones de la etiqueta.

EQUIPO DE PROTECCIÓN PERSONAL (EPP):
• Monogafas
• Careta Media Cara con filtro de gases y vapores orgánicos
• Gorra con capucha
• Camisa y pantalón (antifluido), debajo camiseta y pantalón en algodón
• Botas de PVC
• Guantes de nitrilo

• Los equipos de aplicación deben ser los adecuados y deben estar en buen estado, sin fugas y calibrados.

• Durante las aplicaciones de agroquímicos no deben ingerir alimentos, bebidas, ni fumar.

• La ropa usada para realizar las aplicaciones debe estar limpia antes de iniciar y lavarse al finalizar junto con todos los EPP. Los operarios deben ducharse con abundante agua y jabón.

• Registrar el uso de agroquímicos y mantener una lista actualizada de los productos existentes (inventario).

• Respetar los periodos de reingreso (P.R) y de carencia (P.C) de los agroquímicos.

• Hacer uso adecuado de los diferentes empaques y residuos de agroquímicos. A todos los recipientes se debe hacer triple lavado y perforado. Entregar a los entes encargados para su recolección.

ALMACENAMIENTO:
• Lugar firme, fresco y ventilado
• Seguro, cerrado con llave
• Protegido de la intemperie
• Acceso restringido a personal autorizado
• Productos líquidos debajo de productos en polvo
• Productos en envases originales
• Eliminar productos caducados por canal autorizado
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Capacitar operarios en manejo seguro de agroquímicos
2. Mantener EPP completo y en buen estado
3. Calibrar equipos de aplicación regularmente
4. Respetar periodos de carencia y reingreso
5. Realizar triple lavado de envases
6. Almacenar productos correctamente
7. Mantener registros de aplicaciones actualizados
''',
        severityLevel: 3,
      ),

      // 3.10 COSECHA, BENEFICIO, ALMACENAMIENTO Y TRANSPORTE
      const ManualSectionModel(
        id: 0,
        chapter: 'Postcosecha',
        sectionTitle: 'Cosecha, Beneficio, Almacenamiento y Transporte',
        content: '''
COSECHA:
• Se deben utilizar recipientes y herramientas adecuadas y para uso exclusivo de la cosecha y beneficio del cacao.

• Recolectar las mazorcas que tengan plena madurez fisiológica (maduras) y sanas, si se realiza beneficio de mazorcas enfermas debe ser por separado.

• Desgranar la mazorca utilizando una herramienta que no cause daños al grano o lesiones al operario, tales como el caballete.

• Evitar lesionar los cojines florales durante la recolección, empleando herramientas adecuadas. Todas las mazorcas a altura de la mano deben recolectarse con tijera de mano.

• Disponer de un programa de manejo para las cáscaras resultantes del proceso de desgrane; estas pueden permanecer en el lote o ser utilizadas en la fabricación de compost.

FERMENTACIÓN:
• La fermentación se debe realizar en cajones de madera con orificios en el fondo, para la salida de los lixiviados.
• Este proceso tarda entre 5 y 6 días generalmente.
• Se deben hacer volteos, para oxigenar la masa de cacao, después de las 48 horas de iniciado el proceso.
• Los lixiviados no se vierten a fuentes de agua. Pueden ser aplicados a los residuos orgánicos durante el proceso de compostaje.
• No mezclar granos provenientes de días diferentes de recolección.

SECADO:
• El secado se debe hacer sobre superficies de madera, al sol, evitando que los granos se humedezcan con la lluvia o se contaminen.
• Durante los dos primeros días secar máximo 4 a 5 horas en capas de 4 a 5 centímetros de grosor.
• Los granos deben estar con un porcentaje de humedad inferior al 7,5% antes de su almacenamiento.

LIMPIEZA Y CLASIFICACIÓN:
• Se debe limpiar y clasificar el grano, eliminando impurezas y separando de acuerdo con su calidad (premio, corriente o pasilla).
• La calidad del grano se rige por la Norma Técnica Colombiana (NTC) 1252 del Icontec.
• Es conveniente usar zarandas para la limpieza del cacao.

ALMACENAMIENTO:
• Se debe tener un control de aves y roedores en la bodega.
• Almacenar los bultos en lugares secos, ventilados, aseados, separados de las paredes y sobre estibas de madera.
• No almacenar ni transportar cacao junto con combustibles o agroquímicos.
• Prevenir la infestación por plagas y hongos, asegurando una alta rotación del grano. No se recomienda utilizar plaguicidas.
''',
        symptoms: 'Granos mal fermentados, granos con moho, humedad excesiva, presencia de plagas, olores desagradables',
        treatment: '''
CORRECCIÓN DE PROBLEMAS:
1. Fermentación incompleta: aumentar tiempo, verificar masa mínima 50kg
2. Sobre-fermentación: reducir tiempo, aumentar volteos
3. Granos mohosos: mejorar ventilación y secado
4. Olor amoniacal: indica putrefacción, mejorar manejo
''',
        prevention: '''
1. Cosechar solo mazorcas maduras
2. Desgranar el mismo día de cosecha
3. No mezclar granos de diferentes días
4. Usar cajones de madera bien construidos
5. Realizar volteos cada 24-48 horas
6. Secar hasta humedad menor a 7.5%
7. Almacenar sobre estibas en lugar seco
''',
        severityLevel: 3,
      ),

      // 3.11 COMERCIALIZACIÓN
      const ManualSectionModel(
        id: 0,
        chapter: 'Comercialización',
        sectionTitle: 'Comercialización del Cacao',
        content: '''
COMERCIALIZACIÓN:

• Se debe llevar registros de las compras y ventas de grano, así como también de los demás gastos relacionados con la comercialización (arrendamiento, servicios, empleados, otros).

REQUISITOS DE LAS BODEGAS DE ACOPIO:
• Estar en buen estado y limpias.
• Estar libres de filtraciones y/o humedades en pisos, paredes y techos.
• Los desagües deben tener rejillas y los pisos estar sin grietas.
• Las lámparas deben tener protección para evitar contaminación por rupturas.
• Contar con un manejo adecuado de residuos.

• El grano se debe almacenar dentro de la bodega, sobre estibas en buen estado y separado de las paredes.

• El grano se debe empacar en sacos de fique de 50 kg.

• Contar con servicios sanitarios y lavamanos en buen estado y limpios.

• La balanza debe estar calibrada.

• El grano debe cumplir con la NTC 1252.

• Contar con un plan de control de aves y roedores.

• Evitar la aplicación de productos químicos.

• Controlar la rotación de cacao.

CALIDADES SEGÚN NTC 1252:
• Premio: Grano de mejor calidad, bien fermentado
• Corriente: Calidad estándar
• Pasilla: Granos defectuosos, menor valor
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Mantener bodegas limpias y en buen estado
2. Calibrar balanzas periódicamente
3. Implementar control de roedores
4. Usar exclusivamente sacos de fique
5. Garantizar cumplimiento de NTC 1252
6. Llevar registros de compras y ventas
''',
        severityLevel: 2,
      ),

      // 3.12 PROCESO DE CERTIFICACIÓN
      const ManualSectionModel(
        id: 0,
        chapter: 'Certificación',
        sectionTitle: 'Proceso de Certificación BPA',
        content: '''
PROCESO DE CERTIFICACIÓN EN BPA:

1. SOLICITUD DE CERTIFICACIÓN Y DIAGNÓSTICO INICIAL
En primer lugar, la finca que se desee certificar debe contactar al ente certificador (ICA, ICONTEC o Global GAP) para realizar la solicitud de certificación y visita para la revisión y diagnóstico inicial.

2. PLAN DE ACCIÓN Y SOLUCIÓN DE NO CONFORMIDADES
La finca elabora y ejecuta un plan de acción con el fin de solucionar las no conformidades resultantes del diagnóstico inicial, para lo cual se debe:
• Identificar los requisitos de la norma.
• Corregir las no conformidades.
• Definir el plazo y los responsables.
• Realizar auditorías internas para evaluar el avance de los cumplimientos.

3. AUDITORÍA DE CERTIFICACIÓN
Finalmente, cuando se hayan solucionado las no conformidades encontradas en la auditoría inicial, la finca solicita la auditoría de certificación.

ENTES CERTIFICADORES:
• ICA (Instituto Colombiano Agropecuario)
• ICONTEC
• Global GAP

NORMA DE REFERENCIA:
NTC 5811 - Buenas Prácticas Agrícolas para Cacao. Requisitos generales.
''',
        symptoms: null,
        treatment: null,
        prevention: '''
1. Conocer los requisitos de la norma NTC 5811
2. Implementar BPA de forma sistemática
3. Mantener todos los registros al día
4. Realizar auditorías internas periódicas
5. Corregir no conformidades oportunamente
''',
        severityLevel: 1,
      ),
    ];
  }

  Future<void> _seedMlMappings() async {
    final mappings = [
      // Enfermedades
      const MlMappingModel(
        mlClassId: 'moniliasis',
        mlClassLabel: 'Monilia (Moniliophthora roreri)',
        sectionIds: [13, 15], // MIPE + Cosecha/Beneficio
        confidenceThreshold: 0.6,
      ),
      const MlMappingModel(
        mlClassId: 'black_pod',
        mlClassLabel: 'Mazorca Negra (Phytophthora spp)',
        sectionIds: [13, 15],
        confidenceThreshold: 0.6,
      ),
      const MlMappingModel(
        mlClassId: 'witches_broom',
        mlClassLabel: 'Escoba de Bruja (Moniliophthora perniciosa)',
        sectionIds: [13, 11], // MIPE + Podas
        confidenceThreshold: 0.6,
      ),
      // Plagas
      const MlMappingModel(
        mlClassId: 'monalonion',
        mlClassLabel: 'Monalonion (Monalonion spp)',
        sectionIds: [13, 14], // MIPE + Fitosanitarios
        confidenceThreshold: 0.65,
      ),
      const MlMappingModel(
        mlClassId: 'atta',
        mlClassLabel: 'Hormiga Arriera (Atta spp)',
        sectionIds: [13, 14],
        confidenceThreshold: 0.7,
      ),
      const MlMappingModel(
        mlClassId: 'carmenta',
        mlClassLabel: 'Perforador de Mazorca (Carmenta foraseminis)',
        sectionIds: [13, 15],
        confidenceThreshold: 0.65,
      ),
      // Deficiencias nutricionales
      const MlMappingModel(
        mlClassId: 'nutrient_deficiency',
        mlClassLabel: 'Deficiencia Nutricional',
        sectionIds: [9], // Nutrición
        confidenceThreshold: 0.6,
      ),
      // Estado saludable
      const MlMappingModel(
        mlClassId: 'healthy',
        mlClassLabel: 'Planta Saludable',
        sectionIds: [11, 9], // Podas + Nutrición (mantenimiento)
        confidenceThreshold: 0.8,
      ),
      // Problemas de fermentación
      const MlMappingModel(
        mlClassId: 'fermentation_issue',
        mlClassLabel: 'Problema de Fermentación',
        sectionIds: [15], // Cosecha y Beneficio
        confidenceThreshold: 0.65,
      ),
    ];

    for (final mapping in mappings) {
      await dataSource.insertMlMapping(mapping);
    }
  }

  Future<void> _seedSynonyms() async {
    final synonyms = {
      // BPA
      'bpa': ['buenas prácticas', 'buenas practicas', 'certificación', 'certificacion'],
      'inocuidad': ['seguridad alimentaria', 'calidad', 'higiene'],

      // Enfermedades
      'monilia': ['moniliasis', 'moniliophthora roreri', 'pudrición', 'podredumbre'],
      'fitoptora': ['phytophthora', 'mazorca negra', 'pudrición negra'],
      'escoba': ['escoba de bruja', 'moniliophthora perniciosa', 'witches broom'],

      // Plagas
      'hormiga': ['hormiga arriera', 'atta', 'zompopo'],
      'monalonion': ['chinche', 'miridae'],
      'carmenta': ['perforador', 'barrenador', 'pasador'],

      // Manejo
      'poda': ['podar', 'corte', 'raleo', 'formación'],
      'fertilización': ['nutrición', 'abono', 'fertilizante', 'abonamiento'],
      'riego': ['agua', 'irrigación', 'hidratación'],
      'arvenses': ['malezas', 'malas hierbas', 'arvense', 'hierba'],

      // Postcosecha
      'fermentación': ['fermentar', 'beneficio', 'transformación'],
      'secado': ['secar', 'deshidratación', 'secamiento'],
      'almacenamiento': ['bodega', 'almacenar', 'guardar', 'acopio'],

      // General
      'enfermedad': ['patología', 'infección', 'padecimiento', 'problema fitosanitario'],
      'plaga': ['insecto', 'pest', 'infestación', 'ataque'],
      'síntoma': ['signo', 'indicador', 'manifestación', 'señal'],
      'tratamiento': ['control', 'manejo', 'solución', 'remedio'],
      'prevención': ['prevenir', 'evitar', 'protección', 'preventivo'],
      'mazorca': ['fruto', 'cacao', 'pod', 'bellota'],
      'grano': ['semilla', 'almendra', 'bean'],
      'clon': ['variedad', 'cultivar', 'material genético'],
    };

    for (final entry in synonyms.entries) {
      for (final synonym in entry.value) {
        await dataSource.insertSynonym(entry.key, synonym);
        await dataSource.insertSynonym(synonym, entry.key);
      }
    }
  }
}
