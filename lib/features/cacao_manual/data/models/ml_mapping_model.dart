import 'dart:convert';
import '../../domain/entities/ml_mapping.dart';

class MlMappingModel extends MlMapping {
  const MlMappingModel({
    required super.mlClassId,
    required super.mlClassLabel,
    required super.sectionIds,
    super.confidenceThreshold,
  });

  factory MlMappingModel.fromMap(Map<String, dynamic> map) {
    return MlMappingModel(
      mlClassId: map['ml_class_id'] as String,
      mlClassLabel: map['ml_class_label'] as String,
      sectionIds: List<int>.from(jsonDecode(map['section_ids'] as String)),
      confidenceThreshold: map['confidence_threshold'] as double? ?? 0.7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ml_class_id': mlClassId,
      'ml_class_label': mlClassLabel,
      'section_ids': jsonEncode(sectionIds),
      'confidence_threshold': confidenceThreshold,
    };
  }

  factory MlMappingModel.fromEntity(MlMapping entity) {
    return MlMappingModel(
      mlClassId: entity.mlClassId,
      mlClassLabel: entity.mlClassLabel,
      sectionIds: entity.sectionIds,
      confidenceThreshold: entity.confidenceThreshold,
    );
  }
}
