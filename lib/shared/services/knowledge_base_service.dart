import 'dart:math' as math;
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

class KnowledgeSearchService {
  final Database db;
  KnowledgeSearchService(this.db);

  // Calcula similitud coseno entre dos vectores float32
  double _cosine(Uint8List aBytes, Float32List q, double? aNorm) {
    final a = aBytes.buffer.asFloat32List();
    if (a.isEmpty || q.isEmpty) return 0.0;
    double dot = 0.0;
    for (int i = 0; i < math.min(a.length, q.length); i++) {
      dot += a[i] * q[i];
    }
    final denom = (aNorm ?? _l2(a)) * _l2(q);
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  double _l2(List<double> v) {
    double sum = 0.0;
    for (final x in v) sum += x * x;
    return math.sqrt(sum);
  }

  Future<List<Map<String, Object?>>> searchHybrid({
    required String queryText,
    Float32List? queryEmbedding,
    int ftsLimit = 150,
    int topK = 10,
    String crop = 'cacao',
  }) async {
    // 1) FTS5 candidatos
    final ftsRows = await db.rawQuery('SELECT rowid FROM documents_fts WHERE documents_fts MATCH ? LIMIT ?;', [
      queryText,
      ftsLimit,
    ]);
    final rowIds = ftsRows.map((r) => r['rowid'] as int).toList();
    if (rowIds.isEmpty) return [];

    final placeholders = List.filled(rowIds.length, '?').join(',');
    final docs = await db.rawQuery(
      'SELECT rowid, id, title, section_path, category, crop, content, embedding, embedding_norm '
      'FROM documents WHERE rowid IN ($placeholders) AND crop = ?;',
      [...rowIds, crop],
    );

    // 2) Re-ranking por coseno si hay embedding de consulta
    if (queryEmbedding != null) {
      final scored = docs.map((d) {
        final emb = d['embedding'] as Uint8List?;
        final norm = d['embedding_norm'] as double?;
        final score = (emb != null && emb.isNotEmpty) ? _cosine(emb, queryEmbedding, norm) : 0.0;
        return {...d, 'score': score};
      }).toList();
      scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      return scored.take(topK).toList();
    }

    // Si no hay embedding de consulta, devolver por FTS
    return docs.take(topK).toList();
  }
}
