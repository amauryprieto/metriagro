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
    final numClasses = outputTensor.shape.last;
    final output = [List.filled(numClasses, 0)];

    interpreter.run(input, output);

    final qOut = outputTensor.params;
    final isQuantOut = qOut.scale != 0.0;

    late final List<double> logits;
    if (isQuantOut) {
      final scale = qOut.scale;
      final zeroPoint = qOut.zeroPoint;

      logits = (output[0] as List).map<double>((e) => ((e as int) - zeroPoint) * scale).toList();
    } else {
      logits = (output[0] as List).map<double>((e) => (e as num).toDouble()).toList();
    }

    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxLogit)).toList();
    final sumExp = exps.fold<double>(0, (a, b) => a + b);
    final probs = exps.map((e) => e / sumExp).toList();

    var argMax = 0;
    var best = -1.0;
    for (var i = 0; i < probs.length; i++) {
      if (probs[i] > best) {
        best = probs[i];
        argMax = i;
      }
    }

    final label = (_labels != null && argMax < _labels!.length) ? _labels![argMax] : 'Clase $argMax';

    return DiseaseDetectionResult(
      hasDisease: best > 0.5, // Threshold for disease detection
      confidence: best,
      diseaseName: label,
    );
  }
}
