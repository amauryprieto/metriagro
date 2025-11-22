import '../entities/search_result.dart';
import '../repositories/cacao_manual_repository.dart';

class GetCombinedDiagnosis {
  final CacaoManualRepository repository;

  GetCombinedDiagnosis(this.repository);

  Future<CombinedDiagnosisResult> call(CombinedDiagnosisParams params) async {
    final results = await repository.getCombinedResults(
      mlClassId: params.mlClassId,
      mlConfidence: params.mlConfidence,
      textQuery: params.textQuery,
      limit: params.limit,
    );

    return CombinedDiagnosisResult(
      results: results,
      hasMlResults: results.any((r) => r.source == SearchResultSource.mlMapping),
      hasSearchResults: results.any((r) => r.source == SearchResultSource.ftsSearch),
    );
  }
}

class CombinedDiagnosisParams {
  final String? mlClassId;
  final double? mlConfidence;
  final String? textQuery;
  final int limit;

  const CombinedDiagnosisParams({
    this.mlClassId,
    this.mlConfidence,
    this.textQuery,
    this.limit = 10,
  });
}

class CombinedDiagnosisResult {
  final List<SearchResult> results;
  final bool hasMlResults;
  final bool hasSearchResults;

  const CombinedDiagnosisResult({
    required this.results,
    required this.hasMlResults,
    required this.hasSearchResults,
  });

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
}
