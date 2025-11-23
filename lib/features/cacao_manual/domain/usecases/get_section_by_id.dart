import '../entities/manual_section.dart';
import '../repositories/cacao_manual_repository.dart';

class GetSectionById {
  final CacaoManualRepository repository;

  GetSectionById(this.repository);

  Future<ManualSection?> call(int id) async {
    return await repository.getSectionById(id);
  }
}
