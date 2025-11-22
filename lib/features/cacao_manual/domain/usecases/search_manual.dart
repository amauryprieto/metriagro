import '../entities/search_result.dart';
import '../repositories/cacao_manual_repository.dart';

class SearchManual {
  final CacaoManualRepository repository;

  SearchManual(this.repository);

  Future<List<SearchResult>> call(SearchManualParams params) async {
    return await repository.searchManual(
      params.query,
      limit: params.limit,
    );
  }
}

class SearchManualParams {
  final String query;
  final int limit;

  const SearchManualParams({
    required this.query,
    this.limit = 10,
  });
}
