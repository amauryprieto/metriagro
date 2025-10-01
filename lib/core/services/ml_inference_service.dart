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
    await _ensureLoaded();
    final interpreter = _interpreter!;

    final inputTensor = interpreter.getInputTensors().first;
    final inputShape = inputTensor.shape; // [1, H, W, C]
    final h = inputShape[1];
    final w = inputShape[2];
    final c = inputShape.length > 3 ? inputShape[3] : 3;

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen');
    }
    final resized = img.copyResize(decoded, width: w, height: h, interpolation: img.Interpolation.linear);

    final qIn = inputTensor.params;
    final isQuantIn = qIn.scale != 0.0;

    dynamic input;
    if (!isQuantIn) {
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
    final qOut = outputTensor.params;
    final isQuantOut = qOut.scale != 0.0;

    // Reservar buffer según la forma real del tensor de salida
    dynamic output = List.generate(
      outputShape[0], // 1
      (_) => List.generate(
        outputShape[1], // 300
        (_) => List.filled(outputShape[2], isQuantOut ? 0 : 0.0), // 6
      ),
    );

    interpreter.run(input, output);

    // Procesar detecciones: cada fila es [ymin, xmin, ymax, xmax, score, class_id]
    final detections = <Map<String, dynamic>>[];
    final detectionsList = output[0] as List<List<dynamic>>;

    for (final detection in detectionsList) {
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

        // Solo considerar detecciones con score > 0.5
        if (score > 0.5) {
          detections.add({
            'ymin': detection[0],
            'xmin': detection[1],
            'ymax': detection[2],
            'xmax': detection[3],
            'score': score,
            'classId': classId,
          });
        }
      }
    }

    // Encontrar la detección con mayor score
    if (detections.isEmpty) {
      return DiseaseDetectionResult(hasDisease: false, confidence: 0.0, diseaseName: 'healthy');
    }

    detections.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final bestDetection = detections.first;
    final bestScore = bestDetection['score'] as double;
    final classId = bestDetection['classId'] as int;

    final label = (_labels != null && classId < _labels!.length) ? _labels![classId] : 'Clase $classId';

    return DiseaseDetectionResult(hasDisease: bestScore > 0.5, confidence: bestScore, diseaseName: label);
  }
}
