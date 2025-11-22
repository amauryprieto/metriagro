import 'dart:convert';

/// Individual disease detection
class DiseaseDetection {
  final String diseaseName;
  final double confidence;
  final double? ymin;
  final double? xmin;
  final double? ymax;
  final double? xmax;

  const DiseaseDetection({
    required this.diseaseName,
    required this.confidence,
    this.ymin,
    this.xmin,
    this.ymax,
    this.xmax,
  });

  factory DiseaseDetection.fromJson(Map<String, dynamic> json) {
    return DiseaseDetection(
      diseaseName: json['diseaseName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      ymin: (json['ymin'] as num?)?.toDouble(),
      xmin: (json['xmin'] as num?)?.toDouble(),
      ymax: (json['ymax'] as num?)?.toDouble(),
      xmax: (json['xmax'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'diseaseName': diseaseName,
    'confidence': confidence,
    if (ymin != null) 'ymin': ymin,
    if (xmin != null) 'xmin': xmin,
    if (ymax != null) 'ymax': ymax,
    if (xmax != null) 'xmax': xmax,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// Result containing multiple disease detections
class DiseaseDetectionResult {
  final bool hasDisease;
  final double confidence;
  final String? diseaseName;
  final List<DiseaseDetection> detections;

  const DiseaseDetectionResult({
    required this.hasDisease,
    required this.confidence,
    this.diseaseName,
    this.detections = const [],
  });

  /// Get the best detection (highest confidence)
  DiseaseDetection? get bestDetection => detections.isNotEmpty
      ? detections.reduce((a, b) => a.confidence > b.confidence ? a : b)
      : null;

  /// Get all detections above a confidence threshold
  List<DiseaseDetection> getDetectionsAboveThreshold(double threshold) {
    return detections.where((d) => d.confidence >= threshold).toList();
  }

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    final detectionsList = json['detections'] as List<dynamic>? ?? [];
    final detections = detectionsList
        .map((d) => DiseaseDetection.fromJson(d as Map<String, dynamic>))
        .toList();

    return DiseaseDetectionResult(
      hasDisease: json['hasDisease'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      diseaseName: json['diseaseName'] as String?,
      detections: detections,
    );
  }

  Map<String, dynamic> toJson() => {
    'hasDisease': hasDisease,
    'confidence': confidence,
    if (diseaseName != null) 'diseaseName': diseaseName,
    'detections': detections.map((d) => d.toJson()).toList(),
  };

  @override
  String toString() => jsonEncode(toJson());
}
