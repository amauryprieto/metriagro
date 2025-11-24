import 'dart:typed_data';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../../../core/services/text_embedding_service.dart';
import '../../../../shared/services/embedding_cache.dart';
import 'cacao_manual_database.dart';

/// Data source for vector similarity search on manual sections.
class VectorSearchDataSource {
  final CacaoManualDatabase _database;
  final TextEmbeddingService _embeddingService;
  final EmbeddingCache _cache;

  VectorSearchDataSource({
    required CacaoManualDatabase database,
    required TextEmbeddingService embeddingService,
    required EmbeddingCache cache,
  })  : _database = database,
        _embeddingService = embeddingService,
        _cache = cache;

  /// Search sections by semantic similarity.
  ///
  /// [query] - Natural language query
  /// [topK] - Number of results to return
  /// [minSimilarity] - Minimum cosine similarity threshold (0-1)
  Future<List<VectorSearchResult>> search(
    String query, {
    int topK = 5,
    double minSimilarity = 0.3,
  }) async {
    final db = await _database.database;

    // 1. Get query embedding (from cache or compute)
    Float32List queryEmbedding;
    if (_cache.contains(query)) {
      queryEmbedding = _cache.get(query)!;
    } else {
      queryEmbedding = await _embeddingService.encode(query);
      _cache.put(query, queryEmbedding);
    }

    // 2. Get all sections with embeddings
    final sections = await db.query(
      'manual_sections',
      columns: [
        'id',
        'chapter',
        'section_title',
        'content',
        'symptoms',
        'treatment',
        'prevention',
        'severity_level',
        'embedding',
        'embedding_norm'
      ],
      where: 'embedding IS NOT NULL',
    );

    // 3. Calculate similarity for each section
    final results = <VectorSearchResult>[];

    for (final section in sections) {
      final embeddingBytes = section['embedding'] as Uint8List?;
      if (embeddingBytes == null) continue;

      final sectionEmbedding = _bytesToFloat32List(embeddingBytes);
      final norm = (section['embedding_norm'] as num?)?.toDouble() ?? 1.0;

      final similarity = _cosineSimilarity(queryEmbedding, sectionEmbedding, norm);

      if (similarity >= minSimilarity) {
        results.add(VectorSearchResult(
          id: section['id'] as int,
          chapter: section['chapter'] as String,
          sectionTitle: section['section_title'] as String,
          content: section['content'] as String,
          symptoms: section['symptoms'] as String?,
          treatment: section['treatment'] as String?,
          prevention: section['prevention'] as String?,
          severityLevel: section['severity_level'] as int? ?? 1,
          similarity: similarity,
        ));
      }
    }

    // 4. Sort by similarity (descending) and return top-K
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    return results.take(topK).toList();
  }

  /// Find sections similar to a given section.
  Future<List<VectorSearchResult>> findSimilar(
    int sectionId, {
    int topK = 5,
    double minSimilarity = 0.5,
  }) async {
    final db = await _database.database;

    // Get the source section's embedding
    final sourceSection = await db.query(
      'manual_sections',
      columns: ['embedding'],
      where: 'id = ?',
      whereArgs: [sectionId],
    );

    if (sourceSection.isEmpty || sourceSection.first['embedding'] == null) {
      return [];
    }

    final sourceEmbedding = _bytesToFloat32List(
      sourceSection.first['embedding'] as Uint8List,
    );

    // Get all other sections
    final sections = await db.query(
      'manual_sections',
      columns: [
        'id',
        'chapter',
        'section_title',
        'content',
        'symptoms',
        'treatment',
        'prevention',
        'severity_level',
        'embedding',
        'embedding_norm'
      ],
      where: 'embedding IS NOT NULL AND id != ?',
      whereArgs: [sectionId],
    );

    final results = <VectorSearchResult>[];

    for (final section in sections) {
      final embeddingBytes = section['embedding'] as Uint8List?;
      if (embeddingBytes == null) continue;

      final sectionEmbedding = _bytesToFloat32List(embeddingBytes);
      final norm = (section['embedding_norm'] as num?)?.toDouble() ?? 1.0;

      final similarity = _cosineSimilarity(sourceEmbedding, sectionEmbedding, norm);

      if (similarity >= minSimilarity) {
        results.add(VectorSearchResult(
          id: section['id'] as int,
          chapter: section['chapter'] as String,
          sectionTitle: section['section_title'] as String,
          content: section['content'] as String,
          symptoms: section['symptoms'] as String?,
          treatment: section['treatment'] as String?,
          prevention: section['prevention'] as String?,
          severityLevel: section['severity_level'] as int? ?? 1,
          similarity: similarity,
        ));
      }
    }

    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results.take(topK).toList();
  }

  /// Calculate cosine similarity between two vectors.
  double _cosineSimilarity(Float32List a, Float32List b, double bNorm) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double aNormSq = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      aNormSq += a[i] * a[i];
    }

    final aNorm = sqrt(aNormSq);

    if (aNorm == 0 || bNorm == 0) return 0.0;

    return dotProduct / (aNorm * bNorm);
  }

  /// Convert bytes to Float32List.
  Float32List _bytesToFloat32List(Uint8List bytes) {
    return bytes.buffer.asFloat32List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 4);
  }
}

/// Result of a vector similarity search.
class VectorSearchResult {
  final int id;
  final String chapter;
  final String sectionTitle;
  final String content;
  final String? symptoms;
  final String? treatment;
  final String? prevention;
  final int severityLevel;
  final double similarity;

  VectorSearchResult({
    required this.id,
    required this.chapter,
    required this.sectionTitle,
    required this.content,
    this.symptoms,
    this.treatment,
    this.prevention,
    required this.severityLevel,
    required this.similarity,
  });

  /// Get a snippet of the content (first 200 chars).
  String get snippet {
    if (content.length <= 200) return content;
    return '${content.substring(0, 200)}...';
  }

  /// Get similarity as percentage string.
  String get similarityPercent => '${(similarity * 100).toStringAsFixed(0)}%';

  @override
  String toString() {
    return 'VectorSearchResult(id: $id, title: $sectionTitle, similarity: $similarityPercent)';
  }
}
