import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/conversation_models.dart';
import 'knowledge_base_loader.dart';

abstract class LocalKnowledgeBase {
  Future<void> initialize();
  Future<bool> isReady();
  Future<TreatmentInfo?> getTreatment(String diseaseId);
  Future<List<DiseaseInfo>> searchDiseasesByKeywords(String keywords, {String? cropType});
  Future<List<TreatmentInfo>> getTreatmentsForDiseases(List<String> diseaseIds);
  Future<void> dispose();
}

class SqliteKnowledgeBase implements LocalKnowledgeBase {
  Database? _db;

  @override
  Future<void> initialize() async {
    // Cargar BD de prueba desde assets (para desarrollo). En prod la BD vendrá del API.
    _db = await KnowledgeBaseLoader.loadTestDatabase();
  }

  // Seed eliminado: la BD ahora proviene de assets/API

  @override
  Future<bool> isReady() async => _db != null;

  @override
  Future<TreatmentInfo?> getTreatment(String diseaseId) async {
    final db = _db;
    if (db == null) return null;
    // Nuevo esquema: treatments.target_type/target_id
    final rows = await db.query(
      'treatments',
      where: 'target_type = ? AND target_id = ?',
      whereArgs: ['disease', diseaseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    final products = (r['products_json'] as String?) != null
        ? List<String>.from(jsonDecode(r['products_json'] as String))
        : <String>[];
    final steps = (r['steps_json'] as String?) != null
        ? List<String>.from(jsonDecode(r['steps_json'] as String))
        : <String>[];
    return TreatmentInfo(
      treatmentId: r['id'] as String,
      title: r['title'] as String,
      description: r['description'] as String,
      products: products,
      steps: steps,
      additionalInfo: r['references'] != null ? {'references': r['references'] as String} : null,
    );
  }

  @override
  Future<List<DiseaseInfo>> searchDiseasesByKeywords(String keywords, {String? cropType}) async {
    final db = _db;
    if (db == null) return [];
    // Esquema de prueba: no hay keywords/crop_type. Buscar por nombre LIKE.
    final q = '%${keywords.toLowerCase()}%';
    final rows = await db.rawQuery('SELECT id, name FROM diseases WHERE LOWER(name) LIKE ? ORDER BY name ASC', [q]);
    return rows
        .map(
          (r) => DiseaseInfo(
            id: r['id'] as String,
            name: r['name'] as String,
            cropType: CropType.cacao, // BD de cacao
            summary: null,
          ),
        )
        .toList();
  }

  @override
  Future<List<TreatmentInfo>> getTreatmentsForDiseases(List<String> diseaseIds) async {
    final db = _db;
    if (db == null || diseaseIds.isEmpty) return [];

    final placeholders = diseaseIds.map((_) => '?').join(',');
    final rows = await db.query(
      'treatments',
      where: 'target_type = ? AND target_id IN ($placeholders)',
      whereArgs: ['disease', ...diseaseIds],
      orderBy: 'title ASC',
    );

    return rows.map((row) {
      final products = (row['products_json'] as String?) != null
          ? List<String>.from(jsonDecode(row['products_json'] as String))
          : <String>[];
      final steps = (row['steps_json'] as String?) != null
          ? List<String>.from(jsonDecode(row['steps_json'] as String))
          : <String>[];

      return TreatmentInfo(
        treatmentId: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        products: products,
        steps: steps,
        additionalInfo: row['references'] != null ? {'references': row['references'] as String} : null,
      );
    }).toList();
  }

  @override
  Future<void> dispose() async {
    await _db?.close();
  }
}
