import 'dart:typed_data';
import 'dart:collection';

/// LRU cache for embedding vectors.
/// Caches query embeddings to avoid redundant computation.
class EmbeddingCache {
  final int maxSize;
  final LinkedHashMap<String, Float32List> _cache = LinkedHashMap();

  EmbeddingCache({this.maxSize = 100});

  /// Get embedding from cache
  Float32List? get(String query) {
    final normalizedQuery = _normalizeQuery(query);
    final value = _cache[normalizedQuery];

    if (value != null) {
      // Move to end (most recently used)
      _cache.remove(normalizedQuery);
      _cache[normalizedQuery] = value;
    }

    return value;
  }

  /// Put embedding in cache
  void put(String query, Float32List embedding) {
    final normalizedQuery = _normalizeQuery(query);

    // Remove if exists to update position
    _cache.remove(normalizedQuery);

    // Evict oldest if at capacity
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[normalizedQuery] = embedding;
  }

  /// Check if query is in cache
  bool contains(String query) {
    return _cache.containsKey(_normalizeQuery(query));
  }

  /// Normalize query for better cache hit rate
  String _normalizeQuery(String query) {
    return query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Clear all cached embeddings
  void clear() {
    _cache.clear();
  }

  /// Number of cached embeddings
  int get size => _cache.length;

  /// Cache statistics
  Map<String, dynamic> get stats => {
        'size': _cache.length,
        'maxSize': maxSize,
        'utilization': _cache.length / maxSize,
      };
}
