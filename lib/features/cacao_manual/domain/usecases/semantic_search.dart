import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/vector_search_datasource.dart';

/// Use case for semantic search in the cacao manual.
class SemanticSearch {
  final VectorSearchDataSource _vectorSearch;

  SemanticSearch(this._vectorSearch);

  /// Execute semantic search with the given parameters.
  Future<Either<Failure, List<VectorSearchResult>>> call(
    SemanticSearchParams params,
  ) async {
    try {
      final results = await _vectorSearch.search(
        params.query,
        topK: params.topK,
        minSimilarity: params.minSimilarity,
      );

      return Right(results);
    } catch (e) {
      return Left(SemanticSearchFailure(e.toString()));
    }
  }
}

/// Parameters for semantic search.
class SemanticSearchParams {
  final String query;
  final int topK;
  final double minSimilarity;

  SemanticSearchParams({
    required this.query,
    this.topK = 5,
    this.minSimilarity = 0.3,
  });
}

/// Failure for semantic search operations.
class SemanticSearchFailure extends Failure {
  final String message;

  SemanticSearchFailure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'SemanticSearchFailure: $message';
}
