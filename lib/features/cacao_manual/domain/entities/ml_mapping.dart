import 'package:equatable/equatable.dart';

class MlMapping extends Equatable {
  final String mlClassId;
  final String mlClassLabel;
  final List<int> sectionIds;
  final double confidenceThreshold;

  const MlMapping({
    required this.mlClassId,
    required this.mlClassLabel,
    required this.sectionIds,
    this.confidenceThreshold = 0.7,
  });

  @override
  List<Object?> get props => [mlClassId, mlClassLabel, sectionIds, confidenceThreshold];
}
