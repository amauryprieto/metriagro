import '../repositories/cacao_manual_repository.dart';

class GetAllChapters {
  final CacaoManualRepository repository;

  GetAllChapters(this.repository);

  Future<List<String>> call() async {
    return await repository.getAllChapters();
  }
}
