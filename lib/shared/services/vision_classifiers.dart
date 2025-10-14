import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;

import '../../core/services/ml_inference_service.dart';
import '../models/conversation_models.dart';
import 'vision_router.dart';

class TfliteDiseaseClassifier implements VisionClassifier {
  final MlInferenceService _mlService;
  final CropType _supportedCropType;

  TfliteDiseaseClassifier({required MlInferenceService mlService, required CropType supportedCropType})
    : _mlService = mlService,
      _supportedCropType = supportedCropType;

  @override
  CropType get supportedCropType => _supportedCropType;

  @override
  Future<void> initialize() async {
    // LocalTfliteInferenceService carga en primer uso; no requiere init explícito.
  }

  @override
  Future<bool> isReady() async {
    return true;
  }

  @override
  Future<VisionResult> classify(Uint8List imageData) async {
    // Persistir temporalmente para reutilizar la API existente basada en File
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/vision_input_${DateTime.now().millisecondsSinceEpoch}.png');
    final decoded = img.decodeImage(imageData);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen');
    }
    final pngBytes = img.encodePng(decoded);
    await tempFile.writeAsBytes(pngBytes, flush: true);

    final result = await _mlService.analyzeImage(tempFile);

    // Mapear resultado genérico a VisionResult
    final confLevel = result.confidence >= 0.9
        ? ConfidenceLevel.high
        : result.confidence >= 0.7
        ? ConfidenceLevel.medium
        : result.confidence >= 0.5
        ? ConfidenceLevel.low
        : ConfidenceLevel.unknown;

    final name = result.diseaseName ?? 'unknown';
    return VisionResult(
      diseaseId: name.toLowerCase().replaceAll(' ', '_'),
      diseaseName: name,
      cropType: _supportedCropType,
      confidence: result.confidence,
      confidenceLevel: confLevel,
      metadata: {'hasDisease': result.hasDisease},
    );
  }

  @override
  Future<void> dispose() async {}

  @override
  String get name => 'TfliteDiseaseClassifier($_supportedCropType)';
}
