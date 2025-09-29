import 'dart:convert';

class DiseaseDetectionResult {
  final bool hasDisease;
  final double confidence;
  final String? diseaseName;

  const DiseaseDetectionResult({required this.hasDisease, required this.confidence, this.diseaseName});

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      hasDisease: json['hasDisease'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      diseaseName: json['diseaseName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'hasDisease': hasDisease,
    'confidence': confidence,
    if (diseaseName != null) 'diseaseName': diseaseName,
  };

  @override
  String toString() => jsonEncode(toJson());
}
