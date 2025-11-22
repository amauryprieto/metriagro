import 'package:equatable/equatable.dart';

class ManualSection extends Equatable {
  final int id;
  final String chapter;
  final String sectionTitle;
  final String content;
  final String? symptoms;
  final String? treatment;
  final String? prevention;
  final int severityLevel;
  final List<String>? imageExamples;
  final DateTime? createdAt;

  const ManualSection({
    required this.id,
    required this.chapter,
    required this.sectionTitle,
    required this.content,
    this.symptoms,
    this.treatment,
    this.prevention,
    this.severityLevel = 1,
    this.imageExamples,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        chapter,
        sectionTitle,
        content,
        symptoms,
        treatment,
        prevention,
        severityLevel,
        imageExamples,
        createdAt,
      ];
}
