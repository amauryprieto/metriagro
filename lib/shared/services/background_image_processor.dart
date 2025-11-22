import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../models/conversation_models.dart';
import '../../core/services/ml_inference_service.dart';

/// Service for processing images in background isolates
class BackgroundImageProcessor {
  /// Process image data - optimized image processing in isolate, ML on main thread
  static Future<VisionResult> processImage(Uint8List imageData, CropType cropType) async {
    // First, optimize the image in background isolate
    final optimizedData = await compute(_optimizeImageInIsolate, imageData);

    // Then run ML processing on main thread (since it needs Flutter bindings)
    return await _runMLProcessing(optimizedData, cropType);
  }

  /// Optimize image in background isolate
  static Future<Uint8List> _optimizeImageInIsolate(Uint8List imageData) async {
    print('[BackgroundImageProcessor-Isolate] Optimizing image in background');
    print('[BackgroundImageProcessor-Isolate] Image size: ${imageData.length} bytes');

    try {
      // If image is small enough, return as-is
      if (imageData.length <= 500 * 1024) {
        print('[BackgroundImageProcessor-Isolate] Image already optimized');
        return imageData;
      }

      // Decode and optimize
      final decoded = img.decodeImage(imageData);
      if (decoded == null) {
        print('[BackgroundImageProcessor-Isolate] Failed to decode image, returning original');
        return imageData;
      }

      // Resize if too large
      img.Image resized = decoded;
      if (decoded.width > 800 || decoded.height > 600) {
        resized = img.copyResize(decoded, width: 800, height: 600, interpolation: img.Interpolation.linear);
        print('[BackgroundImageProcessor-Isolate] Resized image to ${resized.width}x${resized.height}');
      }

      // Re-encode with compression
      final compressedBytes = img.encodeJpg(resized, quality: 80);
      print('[BackgroundImageProcessor-Isolate] Compressed image: ${compressedBytes.length} bytes');
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('[BackgroundImageProcessor-Isolate] Error optimizing image: $e');
      return imageData;
    }
  }

  /// Run ML processing on main thread
  static Future<VisionResult> _runMLProcessing(Uint8List optimizedData, CropType cropType) async {
    print('[BackgroundImageProcessor] Running ML processing on main thread');

    try {
      // Create temp file for ML processing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ml_input_${DateTime.now().millisecondsSinceEpoch}.png');

      try {
        // Write optimized image to temp file
        await tempFile.writeAsBytes(optimizedData);
        print('[BackgroundImageProcessor] Temp file created: ${tempFile.path}');

        // Initialize ML service on main thread
        final mlService = LocalTfliteInferenceService();
        print('[BackgroundImageProcessor] Running ML inference...');

        // Run ML analysis
        final result = await mlService.analyzeImage(tempFile);
        print('[BackgroundImageProcessor] ML result: ${result.diseaseName} (${result.confidence})');
        print('[BackgroundImageProcessor] Total detections: ${result.detections.length}');

        // Map result to VisionResult
        final confLevel = result.confidence >= 0.9
            ? ConfidenceLevel.high
            : result.confidence >= 0.7
            ? ConfidenceLevel.medium
            : result.confidence >= 0.5
            ? ConfidenceLevel.low
            : ConfidenceLevel.unknown;

        final name = result.diseaseName ?? 'unknown';
        final visionResult = VisionResult(
          diseaseId: name.toLowerCase().replaceAll(' ', '_'),
          diseaseName: name,
          cropType: cropType,
          confidence: result.confidence,
          confidenceLevel: confLevel,
          metadata: {
            'hasDisease': result.hasDisease,
            'processing_method': 'hybrid_isolate_main',
            'original_size': optimizedData.length,
            'optimized_size': optimizedData.length,
            'total_detections': result.detections.length,
            'all_detections': result.detections.map((d) => {
              'diseaseName': d.diseaseName,
              'confidence': d.confidence,
              'ymin': d.ymin,
              'xmin': d.xmin,
              'ymax': d.ymax,
              'xmax': d.xmax,
            }).toList(),
          },
        );

        print('[BackgroundImageProcessor] ML processing completed successfully');
        return visionResult;
      } finally {
        // Clean up temp file
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
            print('[BackgroundImageProcessor] Temp file cleaned up');
          }
        } catch (e) {
          print('[BackgroundImageProcessor] Error cleaning up temp file: $e');
        }
      }
    } catch (e) {
      print('[BackgroundImageProcessor] Error during ML processing: $e');
      print('[BackgroundImageProcessor] Falling back to mock result');

      // Fallback to a basic result if ML processing fails
      return VisionResult(
        diseaseId: 'analysis_failed',
        diseaseName: 'Análisis no disponible',
        cropType: cropType,
        confidence: 0.0,
        confidenceLevel: ConfidenceLevel.unknown,
        metadata: {
          'hasDisease': false,
          'processing_method': 'fallback',
          'error': e.toString(),
          'original_size': optimizedData.length,
        },
      );
    }
  }
}
