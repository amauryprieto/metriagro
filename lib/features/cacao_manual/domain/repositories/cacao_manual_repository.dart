import '../entities/manual_section.dart';
import '../entities/search_result.dart';
import '../entities/ml_mapping.dart';
import '../entities/tag.dart';

abstract class CacaoManualRepository {
  /// Search manual sections using FTS5 full-text search
  Future<List<SearchResult>> searchManual(String query, {int limit = 10});

  /// Get sections mapped to a specific ML classification
  Future<List<ManualSection>> getSectionsByMlClass(String mlClassId);

  /// Get a specific section by ID
  Future<ManualSection?> getSectionById(int id);

  /// Get all sections in a chapter
  Future<List<ManualSection>> getSectionsByChapter(String chapter);

  /// Get sections by tag
  Future<List<ManualSection>> getSectionsByTag(String tagName);

  /// Get all available chapters
  Future<List<String>> getAllChapters();

  /// Get all tags
  Future<List<Tag>> getAllTags();

  /// Get ML mapping for a class
  Future<MlMapping?> getMlMapping(String mlClassId);

  /// Combined search: ML classification + text query
  Future<List<SearchResult>> getCombinedResults({
    String? mlClassId,
    double? mlConfidence,
    String? textQuery,
    int limit = 10,
  });
}
