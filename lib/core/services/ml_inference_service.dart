import 'dart:io';
import 'dart:math' as math;

import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

import '../../shared/models/disease_detection_result.dart';
import '../constants/app_constants.dart';

abstract class MlInferenceService {
  Future<DiseaseDetectionResult> analyzeImage(File imageFile);
}

class LocalTfliteInferenceService implements MlInferenceService {
  tfl.Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> _ensureLoaded() async {
    if (_interpreter == null) {
      final modelPath = AppConstants.tfliteModelPath + AppConstants.modelFileName;
      _interpreter = await tfl.Interpreter.fromAsset(
        modelPath,
        options: tfl.InterpreterOptions()..threads = math.max(1, Platform.numberOfProcessors ~/ 2),
      );
    }
    if (_labels == null) {
      try {
        final raw = await rootBundle.loadString(AppConstants.tfliteModelPath + AppConstants.labelsFileName);
        _labels = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
      } catch (_) {
        _labels = null; // opcional
      }
    }
  }

  @override
  Future<DiseaseDetectionResult> analyzeImage(File imageFile) async {
    print('[LocalTfliteInferenceService] Starting image analysis');
    print('[LocalTfliteInferenceService] Image file: ${imageFile.path}');

    try {
      await _ensureLoaded();
      print('[LocalTfliteInferenceService] Model loaded successfully');

      if (_interpreter == null) {
        print('[LocalTfliteInferenceService] ERROR: Interpreter is null after loading');
        throw Exception('TensorFlow Lite interpreter not initialized');
      }

      final interpreter = _interpreter!;
      print('[LocalTfliteInferenceService] Interpreter ready');

      final inputTensor = interpreter.getInputTensors().first;
      final inputShape = inputTensor.shape; // [1, H, W, C]
      print('[LocalTfliteInferenceService] Input tensor shape: $inputShape');

      final h = inputShape[1];
      final w = inputShape[2];
      final c = inputShape.length > 3 ? inputShape[3] : 3;
      print('[LocalTfliteInferenceService] Target dimensions: ${w}x${h}x${c}');

      final bytes = await imageFile.readAsBytes();
      print('[LocalTfliteInferenceService] Image file size: ${bytes.length} bytes');

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        print('[LocalTfliteInferenceService] ERROR: Failed to decode image');
        throw Exception('No se pudo decodificar la imagen');
      }
      print('[LocalTfliteInferenceService] Image decoded: ${decoded.width}x${decoded.height}');

      final resized = img.copyResize(decoded, width: w, height: h, interpolation: img.Interpolation.linear);
      print('[LocalTfliteInferenceService] Image resized to: ${resized.width}x${resized.height}');

      final qIn = inputTensor.params;
      final isQuantIn = qIn.scale != 0.0;
      print(
        '[LocalTfliteInferenceService] Input quantization: $isQuantIn (scale: ${qIn.scale}, zeroPoint: ${qIn.zeroPoint})',
      );

      dynamic input;
      if (!isQuantIn) {
        print('[LocalTfliteInferenceService] Processing float input');
        input = List.generate(
          1,
          (_) => List.generate(
            h,
            (y) => List.generate(w, (x) {
              final p = resized.getPixel(x, y);
              final r = p.r / 255.0;
              final g = p.g / 255.0;
              final b = p.b / 255.0;
              if (c == 1) {
                final gray = 0.2989 * r + 0.5870 * g + 0.1140 * b;
                return [gray];
              }
              return [r, g, b];
            }),
          ),
        );
      } else {
        print('[LocalTfliteInferenceService] Processing quantized input');
        final scale = qIn.scale;
        final zeroPoint = qIn.zeroPoint;
        int q(double v) => (v / 255.0 / scale + zeroPoint).round().clamp(-128, 127);
        input = List.generate(
          1,
          (_) => List.generate(
            h,
            (y) => List.generate(w, (x) {
              final p = resized.getPixel(x, y);
              final r = p.r.toDouble();
              final g = p.g.toDouble();
              final b = p.b.toDouble();
              if (c == 1) {
                final gray = 0.2989 * r + 0.5870 * g + 0.1140 * b;
                return [q(gray)];
              }
              return [q(r), q(g), q(b)];
            }),
          ),
        );
      }

      final outputTensor = interpreter.getOutputTensors().first;
      final outputShape = outputTensor.shape; // [1, 300, 6] para detección
      print('[LocalTfliteInferenceService] Output tensor shape: $outputShape');

      final qOut = outputTensor.params;
      final isQuantOut = qOut.scale != 0.0;
      print(
        '[LocalTfliteInferenceService] Output quantization: $isQuantOut (scale: ${qOut.scale}, zeroPoint: ${qOut.zeroPoint})',
      );

      // Reservar buffer según la forma real del tensor de salida
      dynamic output = List.generate(
        outputShape[0], // 1
        (_) => List.generate(
          outputShape[1], // 300
          (_) => List.filled(outputShape[2], isQuantOut ? 0 : 0.0), // 6
        ),
      );

      print('[LocalTfliteInferenceService] Running inference...');
      interpreter.run(input, output);
      print('[LocalTfliteInferenceService] Inference completed');

      // Procesar detecciones: cada fila es [ymin, xmin, ymax, xmax, score, class_id]
      print('[LocalTfliteInferenceService] Processing detections...');
      final detections = <DiseaseDetection>[];
      final detectionsList = output[0] as List<List<dynamic>>;
      print('[LocalTfliteInferenceService] Found ${detectionsList.length} detection candidates');

      for (int i = 0; i < detectionsList.length; i++) {
        final detection = detectionsList[i];
        if (detection.length >= 6) {
          double score;
          int classId;

          if (isQuantOut) {
            final scale = qOut.scale;
            final zeroPoint = qOut.zeroPoint;
            score = ((detection[4] as int) - zeroPoint) * scale;
            classId = (detection[5] as int) - zeroPoint;
          } else {
            score = (detection[4] as num).toDouble();
            classId = (detection[5] as num).round();
          }

          // Solo considerar detecciones con score > 0.3 (lowered threshold for more detections)
          if (score > 0.3) {
            final label = (_labels != null && classId < _labels!.length) ? _labels![classId] : 'Clase $classId';

            detections.add(DiseaseDetection(
              diseaseName: label,
              confidence: score,
              ymin: (detection[0] as num).toDouble(),
              xmin: (detection[1] as num).toDouble(),
              ymax: (detection[2] as num).toDouble(),
              xmax: (detection[3] as num).toDouble(),
            ));
            print('[LocalTfliteInferenceService] Valid detection $i: class=$classId ($label), score=$score');
          }
        }
      }

      print('[LocalTfliteInferenceService] Valid detections found: ${detections.length}');

      // Ordenar por confianza (mayor a menor)
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));

      // Si no hay detecciones válidas, retornar healthy
      if (detections.isEmpty) {
        print('[LocalTfliteInferenceService] No valid detections, returning healthy');
        return DiseaseDetectionResult(
          hasDisease: false,
          confidence: 0.0,
          diseaseName: 'healthy',
          detections: [],
        );
      }

      // Crear resultado con todas las detecciones
      final bestDetection = detections.first;
      final hasDisease = bestDetection.diseaseName != 'healthy' && bestDetection.confidence > 0.5;

      print('[LocalTfliteInferenceService] Best detection: ${bestDetection.diseaseName} (${bestDetection.confidence})');
      print('[LocalTfliteInferenceService] Total detections: ${detections.length}');

      final result = DiseaseDetectionResult(
        hasDisease: hasDisease,
        confidence: bestDetection.confidence,
        diseaseName: bestDetection.diseaseName,
        detections: detections,
      );
      print('[LocalTfliteInferenceService] Analysis completed successfully');
      return result;
    } catch (e, stackTrace) {
      print('[LocalTfliteInferenceService] ERROR during analysis: $e');
      print('[LocalTfliteInferenceService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
