import '../../domain/entities/manual_section.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/ml_mapping.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/cacao_manual_repository.dart';
import '../datasources/cacao_manual_local_datasource.dart';

class CacaoManualRepositoryImpl implements CacaoManualRepository {
  final CacaoManualLocalDataSource localDataSource;

  CacaoManualRepositoryImpl({required this.localDataSource});

  @override
  Future<List<SearchResult>> searchManual(String query, {int limit = 10}) async {
    final sections = await localDataSource.searchSections(query, limit: limit);

    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      // Simple relevance score based on position (FTS5 already orders by BM25)
      final relevanceScore = 1.0 - (index / sections.length);

      return SearchResult(
        section: section,
        relevanceScore: relevanceScore,
        matchedSnippet: _extractSnippet(section.content, query),
        source: SearchResultSource.ftsSearch,
      );
    }).toList();
  }

  String? _extractSnippet(String content, String query) {
    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final terms = lowerQuery.split(RegExp(r'\s+'));

    for (final term in terms) {
      final index = lowerContent.indexOf(term);
      if (index != -1) {
        final start = (index - 50).clamp(0, content.length);
        final end = (index + term.length + 100).clamp(0, content.length);
        var snippet = content.substring(start, end);

        if (start > 0) snippet = '...$snippet';
        if (end < content.length) snippet = '$snippet...';

        return snippet;
      }
    }
    return null;
  }

  @override
  Future<List<ManualSection>> getSectionsByMlClass(String mlClassId) async {
    final mapping = await localDataSource.getMlMapping(mlClassId);
    if (mapping == null) return [];

    return await localDataSource.getSectionsByIds(mapping.sectionIds);
  }

  @override
  Future<ManualSection?> getSectionById(int id) async {
    return await localDataSource.getSectionById(id);
  }

  @override
  Future<List<ManualSection>> getSectionsByChapter(String chapter) async {
    return await localDataSource.getSectionsByChapter(chapter);
  }

  @override
  Future<List<ManualSection>> getSectionsByTag(String tagName) async {
    return await localDataSource.getSectionsByTag(tagName);
  }

  @override
  Future<List<String>> getAllChapters() async {
    return await localDataSource.getAllChapters();
  }

  @override
  Future<List<Tag>> getAllTags() async {
    return await localDataSource.getAllTags();
  }

  @override
  Future<MlMapping?> getMlMapping(String mlClassId) async {
    return await localDataSource.getMlMapping(mlClassId);
  }

  @override
  Future<List<SearchResult>> getCombinedResults({
    String? mlClassId,
    double? mlConfidence,
    String? textQuery,
    int limit = 10,
  }) async {
    final results = <SearchResult>[];
    final seenSectionIds = <int>{};

    // Priority 1: ML-mapped sections (if confidence is above threshold)
    if (mlClassId != null) {
      final mapping = await localDataSource.getMlMapping(mlClassId);
      if (mapping != null) {
        final effectiveConfidence = mlConfidence ?? 1.0;
        if (effectiveConfidence >= mapping.confidenceThreshold) {
          final mlSections = await localDataSource.getSectionsByIds(mapping.sectionIds);

          for (final section in mlSections) {
            if (!seenSectionIds.contains(section.id)) {
              seenSectionIds.add(section.id);
              results.add(SearchResult(
                section: section,
                relevanceScore: effectiveConfidence,
                source: SearchResultSource.mlMapping,
              ));
            }
          }
        }
      }
    }

    // Priority 2: FTS search results
    if (textQuery != null && textQuery.isNotEmpty) {
      final searchResults = await searchManual(textQuery, limit: limit);

      for (final result in searchResults) {
        if (!seenSectionIds.contains(result.section.id)) {
          seenSectionIds.add(result.section.id);
          results.add(result);
        }
      }
    }

    // Sort by relevance and limit
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(limit).toList();
  }
}
