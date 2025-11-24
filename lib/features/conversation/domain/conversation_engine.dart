import '../../../shared/models/conversation_models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
// no-op
import '../../../shared/services/vision_router.dart';
import '../../../shared/services/audio_transcriber.dart';
import '../../../shared/services/local_knowledge_base.dart';
import '../../../shared/services/offline_mode_service.dart';
import '../../cacao_manual/data/datasources/vector_search_datasource.dart';

/// Interfaz principal del motor conversacional
/// Permite intercambiar implementaciones online/offline de forma transparente
abstract class ConversationEngine {
  Future<ConversationResponse> processConversation(ConversationRequest request);

  /// Indica si este motor está disponible actualmente
  Future<bool> isAvailable();

  /// Inicializa el motor (carga modelos, conecta servicios, etc.)
  Future<void> initialize();

  /// Limpia recursos
  Future<void> dispose();

  /// Nombre del motor para debugging
  String get name;
}

/// Router que decide automáticamente entre online/offline
/// Respeta la preferencia del usuario si ha activado el modo offline forzado
class ConversationRouter implements ConversationEngine {
  final ConversationEngine _onlineEngine;
  final ConversationEngine _offlineEngine;
  final ConnectivityService _connectivityService;
  final OfflineModeService _offlineModeService;

  ConversationRouter({
    required ConversationEngine onlineEngine,
    required ConversationEngine offlineEngine,
    required ConnectivityService connectivityService,
    required OfflineModeService offlineModeService,
  }) : _onlineEngine = onlineEngine,
       _offlineEngine = offlineEngine,
       _connectivityService = connectivityService,
       _offlineModeService = offlineModeService;

  @override
  String get name => 'ConversationRouter';

  @override
  Future<void> initialize() async {
    // Inicializar ambos motores en paralelo
    await Future.wait([_onlineEngine.initialize(), _offlineEngine.initialize()]);
  }

  @override
  Future<bool> isAvailable() async {
    final isOnline = await _connectivityService.isConnected();

    if (isOnline && await _onlineEngine.isAvailable()) {
      return true;
    }

    return await _offlineEngine.isAvailable();
  }

  @override
  Future<ConversationResponse> processConversation(ConversationRequest request) async {
    try {
      // Check if user has forced offline mode
      final forceOffline = _offlineModeService.isOfflineMode;

      // For image processing, always use offline engine to leverage local ML
      if (request.hasImage) {
        print('[ConversationRouter] Using offline engine for image processing');
        return await _offlineEngine.processConversation(request);
      }

      // If user has forced offline mode, always use offline engine
      if (forceOffline) {
        print('[ConversationRouter] Using offline engine (user preference)');
        return await _offlineEngine.processConversation(request);
      }

      // For text-only requests, decide based on connectivity
      final isOnline = await _connectivityService.isConnected();

      if (isOnline && await _onlineEngine.isAvailable()) {
        print('[ConversationRouter] Using online engine for text request');
        return await _onlineEngine.processConversation(request);
      } else {
        print('[ConversationRouter] Using offline engine for text request');
        return await _offlineEngine.processConversation(request);
      }
    } catch (e) {
      // Si falla el motor online, intentar con offline como fallback
      if (await _offlineEngine.isAvailable()) {
        print('[ConversationRouter] Fallback to offline engine due to error: $e');
        return await _offlineEngine.processConversation(request);
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await Future.wait([_onlineEngine.dispose(), _offlineEngine.dispose()]);
  }
}

/// Servicio para detectar conectividad
abstract class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> get connectivityStream;
}

/// Implementación del servicio de conectividad usando connectivity_plus
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    final hasInterface =
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
    if (!hasInterface) return false;
    try {
      final lookup = await InternetAddress.lookup('example.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream async* {
    yield await isConnected();
    yield* _connectivity.onConnectivityChanged.asyncMap((_) => isConnected());
  }
}

/// Motor conversacional online (usa APIs externas)
class OnlineConversationService implements ConversationEngine {
  // Aquí conectarías con tu API externa

  @override
  String get name => 'OnlineConversationService';

  @override
  Future<void> initialize() async {
    print('[OnlineConversationService] Initialized');
  }

  @override
  Future<bool> isAvailable() async {
    // Verificar que el servicio online esté disponible
    return true; // Stub
  }

  @override
  Future<ConversationResponse> processConversation(ConversationRequest request) async {
    // TODO: Implementar llamada a API externa
    return ConversationResponse(
      responseText: '🌐 Respuesta del servicio online (stub)',
      isFromOnlineService: true,
      timestamp: DateTime.now(),
      debugInfo: {'engine': name},
    );
  }

  @override
  Future<void> dispose() async {
    print('[OnlineConversationService] Disposed');
  }
}

/// Motor conversacional offline (usa ML local + BD local + búsqueda semántica)
class OfflineConversationService implements ConversationEngine {
  final AudioTranscriber? _audioTranscriber;
  final VisionRouter _visionRouter;
  final LocalKnowledgeBase _localKB;
  final VectorSearchDataSource? _vectorSearch;

  OfflineConversationService({
    AudioTranscriber? audioTranscriber,
    required VisionRouter visionRouter,
    required LocalKnowledgeBase localKB,
    VectorSearchDataSource? vectorSearch,
  }) : _audioTranscriber = audioTranscriber,
       _visionRouter = visionRouter,
       _localKB = localKB,
       _vectorSearch = vectorSearch;

  @override
  String get name => 'OfflineConversationService';

  @override
  Future<void> initialize() async {
    await _localKB.initialize();
    await _visionRouter.initialize();
    await _audioTranscriber?.initialize();
    print('[OfflineConversationService] Initialized');
  }

  @override
  Future<bool> isAvailable() async {
    return await _localKB.isReady() && await _visionRouter.isReady();
  }

  @override
  Future<ConversationResponse> processConversation(ConversationRequest request) async {
    print('[OfflineConversationService] Processing conversation request');
    print(
      '[OfflineConversationService] Request details: hasText=${request.hasText}, hasAudio=${request.hasAudio}, hasImage=${request.hasImage}',
    );
    print('[OfflineConversationService] Expected crop type: ${request.expectedCropType}');

    String? transcribedText = request.textInput;
    VisionResult? visionResult;
    TreatmentInfo? treatmentInfo;
    List<TreatmentInfo> alternativeTreatments = [];
    CropType? extractedHint;
    bool hasContextMismatch = false;

    // 1. Transcribir audio si existe
    if (request.hasAudio && _audioTranscriber != null) {
      print('[OfflineConversationService] Transcribing audio...');
      try {
        transcribedText = await _audioTranscriber.transcribe(request.audioData!);
        print('[OfflineConversationService] Audio transcribed: $transcribedText');
      } catch (e) {
        print('[OfflineConversationService] Error transcribing audio: $e');
      }
    }

    // 2. Extraer hint de cultivo del texto/audio
    if (transcribedText != null && transcribedText.isNotEmpty) {
      extractedHint = _extractCropTypeHint(transcribedText);
      print('[OfflineConversationService] Extracted crop hint: $extractedHint');
    }

    // 3. Combinar hint extraído con expectedCropType (priorizar selector manual)
    // Default to cacao if no crop type is specified
    CropType? finalCropType = request.expectedCropType ?? extractedHint ?? CropType.cacao;
    print('[OfflineConversationService] Final crop type: $finalCropType');

    // 4. Procesar imagen si existe
    if (request.hasImage) {
      print('[OfflineConversationService] Processing image with size: ${request.imageData?.length} bytes');
      try {
        visionResult = await _visionRouter.classify(request.imageData!, finalCropType);
        print(
          '[OfflineConversationService] Image classification successful: ${visionResult.diseaseName} (${visionResult.confidence})',
        );
        print('[OfflineConversationService] Vision result details: ${visionResult.metadata}');
      } catch (e) {
        print('[OfflineConversationService] Error classifying image: $e');
        print('[OfflineConversationService] Stack trace: ${StackTrace.current}');

        // Don't rethrow, create a fallback result instead
        visionResult = VisionResult(
          diseaseId: 'error_occurred',
          diseaseName: 'Error en el análisis',
          cropType: finalCropType,
          confidence: 0.0,
          confidenceLevel: ConfidenceLevel.unknown,
          metadata: {'hasDisease': false, 'error': e.toString()},
        );
        print('[OfflineConversationService] Using fallback vision result');
      }
    }

    // 5. Buscar tratamiento principal en BD local
    if (visionResult != null) {
      treatmentInfo = await _localKB.getTreatment(visionResult.diseaseId);
    }

    // 6. Búsqueda semántica vectorial
    List<VectorSearchResult> semanticResults = [];
    if (transcribedText != null && transcribedText.isNotEmpty) {
      // Validación cruzada
      hasContextMismatch =
          extractedHint != null && extractedHint != visionResult?.cropType && extractedHint != CropType.unknown;

      // Usar búsqueda semántica si está disponible
      if (_vectorSearch != null) {
        try {
          print('[OfflineConversationService] Performing semantic search for: $transcribedText');
          semanticResults = await _vectorSearch.search(
            transcribedText,
            topK: 3,
            minSimilarity: 0.4,
          );
          print('[OfflineConversationService] Found ${semanticResults.length} semantic results');
        } catch (e) {
          print('[OfflineConversationService] Semantic search error: $e');
        }
      }
    }

    // 7. Generar respuesta
    final responseText = _generateResponse(
      text: transcribedText,
      visionResult: visionResult,
      treatmentInfo: treatmentInfo,
      userContext: transcribedText,
      extractedHint: extractedHint,
      alternatives: alternativeTreatments,
      hasContextMismatch: hasContextMismatch,
      semanticResults: semanticResults,
    );

    return ConversationResponse(
      responseText: responseText,
      visionResult: visionResult,
      treatmentInfo: treatmentInfo,
      alternativeTreatments: alternativeTreatments.isNotEmpty ? alternativeTreatments : null,
      detectedCropTypeHint: extractedHint,
      hasContextMismatch: hasContextMismatch,
      userContext: transcribedText,
      isFromOnlineService: false,
      timestamp: DateTime.now(),
      debugInfo: {
        'engine': name,
        'hasAudio': request.hasAudio,
        'hasImage': request.hasImage,
        'transcribedText': transcribedText,
        'extractedHint': extractedHint?.toString(),
        'hasContextMismatch': hasContextMismatch,
      },
    );
  }

  /// Extrae hint de tipo de cultivo del texto del usuario
  CropType? _extractCropTypeHint(String? text) {
    if (text == null || text.isEmpty) return null;

    final lowerText = text.toLowerCase();

    // Keywords para cacao
    if (lowerText.contains('cacao') || lowerText.contains('cacaotal')) {
      return CropType.cacao;
    }

    // Keywords para café
    if (lowerText.contains('café') || lowerText.contains('cafe') || lowerText.contains('cafetal')) {
      return CropType.cafe;
    }

    // Keywords para plátano
    if (lowerText.contains('plátano') ||
        lowerText.contains('platano') ||
        lowerText.contains('platanera') ||
        lowerText.contains('banano')) {
      return CropType.platano;
    }

    // Keywords para maíz
    if (lowerText.contains('maíz') || lowerText.contains('maiz') || lowerText.contains('maizal')) {
      return CropType.maiz;
    }

    return null;
  }

  String _generateResponse({
    String? text,
    VisionResult? visionResult,
    TreatmentInfo? treatmentInfo,
    String? userContext,
    CropType? extractedHint,
    List<TreatmentInfo>? alternatives,
    bool hasContextMismatch = false,
    List<VectorSearchResult>? semanticResults,
  }) {
    final buffer = StringBuffer();

    // Si hay resultados semánticos, mostrarlos primero para consultas de texto
    if (semanticResults != null && semanticResults.isNotEmpty && visionResult == null) {
      buffer.writeln('📚 **Información encontrada:**');
      buffer.writeln();

      for (var i = 0; i < semanticResults.length; i++) {
        final result = semanticResults[i];
        final relevance = (result.similarity * 100).toStringAsFixed(0);

        buffer.writeln('**${i + 1}. ${result.sectionTitle}** (${relevance}% relevante)');
        buffer.writeln();
        buffer.writeln(result.snippet);

        if (result.treatment != null && result.treatment!.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('💊 **Tratamiento:** ${result.treatment}');
        }

        if (result.prevention != null && result.prevention!.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('🛡️ **Prevención:** ${result.prevention}');
        }

        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }

      return buffer.toString().trim();
    }

    // Encabezado para análisis con imagen
    buffer.writeln('🔍 **Análisis completado**');
    buffer.writeln();

    // Contexto del usuario
    if (userContext != null && userContext.isNotEmpty) {
      buffer.writeln('📝 Tu descripción: "$userContext"');
      buffer.writeln();
    }

    // Validación cruzada
    if (hasContextMismatch && extractedHint != null && visionResult != null) {
      buffer.writeln('⚠️ **Nota importante:**');
      buffer.writeln(
        'Mencionaste "${_cropTypeToString(extractedHint)}" pero la imagen parece ser "${_cropTypeToString(visionResult.cropType)}"',
      );
      buffer.writeln('¿Quieres que analice como "${_cropTypeToString(extractedHint)}" en su lugar?');
      buffer.writeln();
    } else if (extractedHint != null && visionResult != null && extractedHint == visionResult.cropType) {
      buffer.writeln('✅ Confirmado: Cultivo de ${_cropTypeToString(visionResult.cropType)} detectado');
      buffer.writeln();
    }

    // Resultado principal
    if (visionResult != null) {
      // Verificar si hay enfermedad presente
      final hasDisease = visionResult.metadata?['hasDisease'] as bool? ?? false;

      if (hasDisease) {
        buffer.writeln('🚨 **ENFERMEDAD DETECTADA**');
        buffer.writeln('📱 Nombre: **${visionResult.diseaseName}**');
        buffer.writeln('🌱 Cultivo: ${_cropTypeToString(visionResult.cropType)}');
        buffer.writeln('📊 Confianza: ${(visionResult.confidence * 100).toStringAsFixed(1)}%');
        buffer.writeln();

        // Tratamiento principal
        if (treatmentInfo != null) {
          buffer.writeln('💊 **Tratamiento recomendado:**');
          buffer.writeln(treatmentInfo.description);
          buffer.writeln();
          buffer.writeln('🛠 **Pasos a seguir:**');
          for (final step in treatmentInfo.steps) {
            buffer.writeln('• $step');
          }
          buffer.writeln();
        } else {
          buffer.writeln('⚠️ No encontré información de tratamiento en la base de datos local.');
          buffer.writeln();
        }
      } else {
        buffer.writeln('✅ **SIN ENFERMEDAD DETECTADA**');
        buffer.writeln('🌱 Cultivo: ${_cropTypeToString(visionResult.cropType)}');
        buffer.writeln('📊 Confianza: ${(visionResult.confidence * 100).toStringAsFixed(1)}%');
        buffer.writeln();
        buffer.writeln('🎉 Tu cultivo parece estar saludable. Continúa con el cuidado preventivo.');
        buffer.writeln();
      }
    } else {
      buffer.writeln('🤖 Procesé tu consulta offline pero necesito más información.');
      buffer.writeln();
    }

    // Tratamientos alternativos
    if (alternatives != null && alternatives.isNotEmpty) {
      buffer.writeln('🔗 **También encontré** (basado en tu descripción):');
      for (final alt in alternatives.take(3)) {
        // Limitar a 3 alternativas
        buffer.writeln('• ${alt.title}');
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  String _cropTypeToString(CropType cropType) {
    switch (cropType) {
      case CropType.cacao:
        return 'Cacao';
      case CropType.cafe:
        return 'Café';
      case CropType.platano:
        return 'Plátano';
      case CropType.maiz:
        return 'Maíz';
      case CropType.unknown:
        return 'Desconocido';
    }
  }

  @override
  Future<void> dispose() async {
    await _audioTranscriber?.dispose();
    await _visionRouter.dispose();
    await _localKB.dispose();
    print('[OfflineConversationService] Disposed');
  }
}

// VisionRouter y servicios auxiliares se importan desde shared/services
