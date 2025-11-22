import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/manual_section_model.dart';
import '../models/ml_mapping_model.dart';
import '../models/tag_model.dart';
import 'cacao_manual_database.dart';

abstract class CacaoManualLocalDataSource {
  Future<List<ManualSectionModel>> searchSections(String query, {int limit = 10});
  Future<ManualSectionModel?> getSectionById(int id);
  Future<List<ManualSectionModel>> getSectionsByChapter(String chapter);
  Future<List<ManualSectionModel>> getSectionsByIds(List<int> ids);
  Future<List<ManualSectionModel>> getSectionsByTag(String tagName);
  Future<List<String>> getAllChapters();
  Future<List<TagModel>> getAllTags();
  Future<MlMappingModel?> getMlMapping(String mlClassId);
  Future<int> insertSection(ManualSectionModel section);
  Future<void> insertSections(List<ManualSectionModel> sections);
  Future<int> insertTag(TagModel tag);
  Future<void> linkSectionToTag(int sectionId, int tagId);
  Future<void> insertMlMapping(MlMappingModel mapping);
  Future<void> insertSynonym(String term, String synonym);
  Future<List<String>> getSynonyms(String term);
}

class CacaoManualLocalDataSourceImpl implements CacaoManualLocalDataSource {
  final CacaoManualDatabase _databaseHelper;

  CacaoManualLocalDataSourceImpl({CacaoManualDatabase? databaseHelper})
      : _databaseHelper = databaseHelper ?? CacaoManualDatabase.instance;

  Future<Database> get _db => _databaseHelper.database;

  @override
  Future<List<ManualSectionModel>> searchSections(String query, {int limit = 10}) async {
    final db = await _db;

    // Expand query with synonyms
    final expandedTerms = await _expandQueryWithSynonyms(query);
    final searchQuery = expandedTerms.join(' OR ');

    // FTS5 search with BM25 ranking
    final results = await db.rawQuery('''
      SELECT ms.*, bm25(manual_fts) as rank
      FROM manual_sections ms
      JOIN manual_fts ON ms.id = manual_fts.rowid
      WHERE manual_fts MATCH ?
      ORDER BY rank
      LIMIT ?
    ''', [searchQuery, limit]);

    return results.map((map) => ManualSectionModel.fromMap(map)).toList();
  }

  Future<List<String>> _expandQueryWithSynonyms(String query) async {
    final db = await _db;
    final terms = query.toLowerCase().split(RegExp(r'\s+'));
    final expandedTerms = <String>{};

    for (final term in terms) {
      expandedTerms.add(term);
      final synonyms = await db.query(
        'synonyms',
        columns: ['synonym'],
        where: 'term = ?',
        whereArgs: [term],
      );
      for (final row in synonyms) {
        expandedTerms.add(row['synonym'] as String);
      }
    }

    return expandedTerms.toList();
  }

  @override
  Future<ManualSectionModel?> getSectionById(int id) async {
    final db = await _db;
    final results = await db.query(
      'manual_sections',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return ManualSectionModel.fromMap(results.first);
  }

  @override
  Future<List<ManualSectionModel>> getSectionsByChapter(String chapter) async {
    final db = await _db;
    final results = await db.query(
      'manual_sections',
      where: 'chapter = ?',
      whereArgs: [chapter],
      orderBy: 'section_title ASC',
    );

    return results.map((map) => ManualSectionModel.fromMap(map)).toList();
  }

  @override
  Future<List<ManualSectionModel>> getSectionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.rawQuery(
      'SELECT * FROM manual_sections WHERE id IN ($placeholders)',
      ids,
    );

    return results.map((map) => ManualSectionModel.fromMap(map)).toList();
  }

  @override
  Future<List<ManualSectionModel>> getSectionsByTag(String tagName) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT ms.* FROM manual_sections ms
      JOIN section_tags st ON ms.id = st.section_id
      JOIN tags t ON st.tag_id = t.id
      WHERE t.name = ?
      ORDER BY ms.section_title ASC
    ''', [tagName]);

    return results.map((map) => ManualSectionModel.fromMap(map)).toList();
  }

  @override
  Future<List<String>> getAllChapters() async {
    final db = await _db;
    final results = await db.rawQuery(
      'SELECT DISTINCT chapter FROM manual_sections ORDER BY chapter ASC',
    );

    return results.map((row) => row['chapter'] as String).toList();
  }

  @override
  Future<List<TagModel>> getAllTags() async {
    final db = await _db;
    final results = await db.query('tags', orderBy: 'name ASC');

    return results.map((map) => TagModel.fromMap(map)).toList();
  }

  @override
  Future<MlMappingModel?> getMlMapping(String mlClassId) async {
    final db = await _db;
    final results = await db.query(
      'ml_to_manual_mapping',
      where: 'ml_class_id = ?',
      whereArgs: [mlClassId],
    );

    if (results.isEmpty) return null;
    return MlMappingModel.fromMap(results.first);
  }

  @override
  Future<int> insertSection(ManualSectionModel section) async {
    final db = await _db;
    return await db.insert('manual_sections', section.toInsertMap());
  }

  @override
  Future<void> insertSections(List<ManualSectionModel> sections) async {
    final db = await _db;
    final batch = db.batch();

    for (final section in sections) {
      batch.insert('manual_sections', section.toInsertMap());
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<int> insertTag(TagModel tag) async {
    final db = await _db;
    return await db.insert(
      'tags',
      tag.toInsertMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> linkSectionToTag(int sectionId, int tagId) async {
    final db = await _db;
    await db.insert(
      'section_tags',
      {'section_id': sectionId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> insertMlMapping(MlMappingModel mapping) async {
    final db = await _db;
    await db.insert(
      'ml_to_manual_mapping',
      mapping.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> insertSynonym(String term, String synonym) async {
    final db = await _db;
    await db.insert(
      'synonyms',
      {'term': term.toLowerCase(), 'synonym': synonym.toLowerCase()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<List<String>> getSynonyms(String term) async {
    final db = await _db;
    final results = await db.query(
      'synonyms',
      columns: ['synonym'],
      where: 'term = ?',
      whereArgs: [term.toLowerCase()],
    );

    return results.map((row) => row['synonym'] as String).toList();
  }
}
