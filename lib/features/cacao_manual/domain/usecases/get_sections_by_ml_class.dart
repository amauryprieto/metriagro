import '../entities/manual_section.dart';
import '../repositories/cacao_manual_repository.dart';

class GetSectionsByMlClass {
  final CacaoManualRepository repository;

  GetSectionsByMlClass(this.repository);

  Future<List<ManualSection>> call(String mlClassId) async {
    return await repository.getSectionsByMlClass(mlClassId);
  }
}
