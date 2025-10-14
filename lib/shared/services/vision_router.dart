import 'dart:typed_data';
import '../models/conversation_models.dart';

/// Clasificador de imágenes específico para un tipo de cultivo
abstract class VisionClassifier {
  /// Tipo de cultivo que puede procesar este clasificador
  CropType get supportedCropType;
  
  /// Inicializa el modelo (carga archivos .tflite, etc.)
  Future<void> initialize();
  
  /// Verifica si el modelo está listo para usar
  Future<bool> isReady();
  
  /// Clasifica una imagen y devuelve el resultado
  Future<VisionResult> classify(Uint8List imageData);
  
  /// Libera recursos del modelo
  Future<void> dispose();
  
  /// Nombre del clasificador para debugging
  String get name;
}

/// Router inteligente que selecciona el clasificador apropiado
class VisionRouter {
  final Map<CropType, VisionClassifier> _classifiers = {};
  final VisionClassifier? _fallbackClassifier;
  
  VisionRouter({
    List<VisionClassifier>? classifiers,
    VisionClassifier? fallbackClassifier,
  }) : _fallbackClassifier = fallbackClassifier {
    // Registrar clasificadores por tipo de cultivo
    if (classifiers != null) {
      for (final classifier in classifiers) {
        _classifiers[classifier.supportedCropType] = classifier;
      }
    }
  }
  
  /// Registra un nuevo clasificador para un tipo de cultivo
  void registerClassifier(VisionClassifier classifier) {
    _classifiers[classifier.supportedCropType] = classifier;
  }
  
  /// Inicializa todos los clasificadores registrados
  Future<void> initialize() async {
    final initTasks = <Future<void>>[];
    
    for (final classifier in _classifiers.values) {
      initTasks.add(classifier.initialize());
    }
    
    if (_fallbackClassifier != null) {
      initTasks.add(_fallbackClassifier!.initialize());
    }
    
    await Future.wait(initTasks);
    print('[VisionRouter] Initialized ${_classifiers.length} classifiers');
  }
  
  /// Verifica si al menos un clasificador está listo
  Future<bool> isReady() async {
    if (_classifiers.isEmpty && _fallbackClassifier == null) {
      return false;
    }
    
    // Verificar si algún clasificador está listo
    for (final classifier in _classifiers.values) {
      if (await classifier.isReady()) {
        return true;
      }
    }
    
    if (_fallbackClassifier != null) {
      return await _fallbackClassifier!.isReady();
    }
    
    return false;
  }
  
  /// Clasifica una imagen usando el clasificador apropiado
  Future<VisionResult> classify(
    Uint8List imageData, 
    CropType? expectedCropType,
  ) async {
    VisionClassifier? selectedClassifier;
    
    // 1. Si se especifica un tipo de cultivo, usarlo directamente
    if (expectedCropType != null && _classifiers.containsKey(expectedCropType)) {
      selectedClassifier = _classifiers[expectedCropType];
      
      if (await selectedClassifier!.isReady()) {
        print('[VisionRouter] Using specific classifier for ${expectedCropType}');
        return await selectedClassifier.classify(imageData);
      }
    }
    
    // 2. Si no hay tipo específico, probar todos los clasificadores
    if (expectedCropType == null) {
      for (final entry in _classifiers.entries) {
        final classifier = entry.value;
        if (await classifier.isReady()) {
          print('[VisionRouter] Trying classifier for ${entry.key}');
          final result = await classifier.classify(imageData);
          
          // Si la confianza es alta, usar este resultado
          if (result.confidence > 0.7) {
            return result;
          }
        }
      }
    }
    
    // 3. Como último recurso, usar el clasificador de fallback
    if (_fallbackClassifier != null && await _fallbackClassifier!.isReady()) {
      print('[VisionRouter] Using fallback classifier');
      return await _fallbackClassifier!.classify(imageData);
    }
    
    // 4. Si no hay clasificadores disponibles
    throw Exception('No vision classifier available for processing');
  }
  
  /// Lista los tipos de cultivo soportados
  List<CropType> get supportedCropTypes => _classifiers.keys.toList();
  
  /// Libera recursos de todos los clasificadores
  Future<void> dispose() async {
    final disposeTasks = <Future<void>>[];
    
    for (final classifier in _classifiers.values) {
      disposeTasks.add(classifier.dispose());
    }
    
    if (_fallbackClassifier != null) {
      disposeTasks.add(_fallbackClassifier!.dispose());
    }
    
    await Future.wait(disposeTasks);
    _classifiers.clear();
    print('[VisionRouter] Disposed all classifiers');
  }
}

/// Clasificador para cacao usando el modelo existente
class CacaoVisionClassifier implements VisionClassifier {
  bool _isInitialized = false;
  
  @override
  CropType get supportedCropType => CropType.cacao;
  
  @override
  String get name => 'CacaoVisionClassifier';
  
  @override
  Future<void> initialize() async {
    // TODO: Cargar tu modelo TensorFlow Lite existente para cacao
    // Ejemplo:
    // _interpreter = await tfl.Interpreter.fromAsset('assets/models/cacao_model.tflite');
    // _interpreter.allocateTensors();
    
    _isInitialized = true;
    print('[CacaoVisionClassifier] Model loaded successfully');
  }
  
  @override
  Future<bool> isReady() async {
    return _isInitialized;
  }
  
  @override
  Future<VisionResult> classify(Uint8List imageData) async {
    if (!_isInitialized) {
      throw StateError('CacaoVisionClassifier not initialized');
    }
    
    // TODO: Implementar clasificación real con tu modelo
    // 1. Preprocesar imagen (resize, normalize, etc.)
    // 2. Ejecutar inferencia con el modelo
    // 3. Post-procesar resultados
    
    // Stub temporal - reemplaza con tu lógica real
    await Future.delayed(Duration(milliseconds: 500)); // Simular procesamiento
    
    return VisionResult(
      diseaseId: 'cacao_black_pod_rot',
      diseaseName: 'Pudrición negra de la mazorca',
      cropType: CropType.cacao,
      confidence: 0.85,
      confidenceLevel: ConfidenceLevel.high,
      metadata: {
        'model': name,
        'processing_time_ms': 500,
        'image_size': imageData.length,
      },
    );
  }
  
  @override
  Future<void> dispose() async {
    // TODO: Liberar recursos del modelo TensorFlow Lite
    // _interpreter?.close();
    
    _isInitialized = false;
    print('[CacaoVisionClassifier] Resources disposed');
  }
}

/// Clasificador genérico que puede detectar el tipo de cultivo primero
class GenericVisionClassifier implements VisionClassifier {
  bool _isInitialized = false;
  
  @override
  CropType get supportedCropType => CropType.unknown; // Puede procesar cualquier tipo
  
  @override
  String get name => 'GenericVisionClassifier';
  
  @override
  Future<void> initialize() async {
    // TODO: Cargar un modelo más general que pueda detectar diferentes cultivos
    _isInitialized = true;
    print('[GenericVisionClassifier] Model loaded successfully');
  }
  
  @override
  Future<bool> isReady() async {
    return _isInitialized;
  }
  
  @override
  Future<VisionResult> classify(Uint8List imageData) async {
    if (!_isInitialized) {
      throw StateError('GenericVisionClassifier not initialized');
    }
    
    // TODO: Implementar detección genérica
    // 1. Detectar tipo de cultivo primero
    // 2. Clasificar enfermedad según el cultivo detectado
    
    // Stub temporal
    await Future.delayed(Duration(milliseconds: 800));
    
    return VisionResult(
      diseaseId: 'generic_disease',
      diseaseName: 'Enfermedad no específica',
      cropType: CropType.unknown,
      confidence: 0.45,
      confidenceLevel: ConfidenceLevel.low,
      metadata: {
        'model': name,
        'processing_time_ms': 800,
      },
    );
  }
  
  @override
  Future<void> dispose() async {
    _isInitialized = false;
    print('[GenericVisionClassifier] Resources disposed');
  }
}

/// Factory para crear y configurar el VisionRouter
class VisionRouterFactory {
  static VisionRouter createDefault() {
    final classifiers = <VisionClassifier>[
      CacaoVisionClassifier(),
      // Aquí puedes agregar más clasificadores específicos:
      // CafeVisionClassifier(),
      // PlatanoVisionClassifier(),
    ];
    
    final fallbackClassifier = GenericVisionClassifier();
    
    return VisionRouter(
      classifiers: classifiers,
      fallbackClassifier: fallbackClassifier,
    );
  }
}