import 'dart:convert';
import '../../domain/entities/manual_section.dart';

class ManualSectionModel extends ManualSection {
  const ManualSectionModel({
    required super.id,
    required super.chapter,
    required super.sectionTitle,
    required super.content,
    super.symptoms,
    super.treatment,
    super.prevention,
    super.severityLevel,
    super.imageExamples,
    super.createdAt,
  });

  factory ManualSectionModel.fromMap(Map<String, dynamic> map) {
    return ManualSectionModel(
      id: map['id'] as int,
      chapter: map['chapter'] as String,
      sectionTitle: map['section_title'] as String,
      content: map['content'] as String,
      symptoms: map['symptoms'] as String?,
      treatment: map['treatment'] as String?,
      prevention: map['prevention'] as String?,
      severityLevel: map['severity_level'] as int? ?? 1,
      imageExamples: map['image_examples'] != null
          ? List<String>.from(jsonDecode(map['image_examples'] as String))
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter': chapter,
      'section_title': sectionTitle,
      'content': content,
      'symptoms': symptoms,
      'treatment': treatment,
      'prevention': prevention,
      'severity_level': severityLevel,
      'image_examples': imageExamples != null ? jsonEncode(imageExamples) : null,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  factory ManualSectionModel.fromEntity(ManualSection entity) {
    return ManualSectionModel(
      id: entity.id,
      chapter: entity.chapter,
      sectionTitle: entity.sectionTitle,
      content: entity.content,
      symptoms: entity.symptoms,
      treatment: entity.treatment,
      prevention: entity.prevention,
      severityLevel: entity.severityLevel,
      imageExamples: entity.imageExamples,
      createdAt: entity.createdAt,
    );
  }
}
