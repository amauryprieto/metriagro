import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../core/services/ml_inference_service.dart';
import '../models/conversation_models.dart';
import 'vision_router.dart';
import 'background_image_processor.dart';

class TfliteDiseaseClassifier implements VisionClassifier {
  final CropType _supportedCropType;

  TfliteDiseaseClassifier({required MlInferenceService mlService, required CropType supportedCropType})
    : _supportedCropType = supportedCropType;

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
    print('[TfliteDiseaseClassifier] Starting image classification for ${_supportedCropType}');
    print('[TfliteDiseaseClassifier] Image data size: ${imageData.length} bytes');

    try {
      // Use the optimized background processor
      print('[TfliteDiseaseClassifier] Processing image in background isolate...');
      final result = await BackgroundImageProcessor.processImage(imageData, _supportedCropType);

      print('[TfliteDiseaseClassifier] Classification completed successfully');
      return result;
    } catch (e, stackTrace) {
      print('[TfliteDiseaseClassifier] Error during classification: $e');
      print('[TfliteDiseaseClassifier] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  String get name => 'TfliteDiseaseClassifier($_supportedCropType)';
}
