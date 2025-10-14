import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/conversation_models.dart';

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
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'metriagro_kb.db');
    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diseases (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            crop_type TEXT NOT NULL,
            keywords TEXT,
            summary TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE treatments (
            id TEXT PRIMARY KEY,
            disease_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            products_json TEXT,
            steps_json TEXT,
            references TEXT,
            FOREIGN KEY(disease_id) REFERENCES diseases(id)
          );
        ''');
        await _seed(db);
      },
    );
  }

  Future<void> _seed(Database db) async {
    // Seed mínimo; ampliar según necesidades
    final diseases = [
      {
        'id': 'roya_cafe',
        'name': 'Roya del café',
        'crop_type': 'cafe',
        'keywords': 'roya, hojas amarillas, hongo',
        'summary': 'Enfermedad fúngica que causa manchas anaranjadas.',
      },
      {
        'id': 'monilia_cacao',
        'name': 'Monilia del cacao',
        'crop_type': 'cacao',
        'keywords': 'monilia, frutos enfermos, hongo',
        'summary': 'Afecta frutos de cacao con lesiones blanquecinas.',
      },
    ];

    final treatments = [
      {
        'id': 't_royacafe_1',
        'disease_id': 'roya_cafe',
        'title': 'Manejo integrado de Roya del café',
        'description': 'Use variedades tolerantes y aplique fungicidas cuando sea necesario.',
        'products_json': jsonEncode(['Oxicloruro de cobre', 'Triazoles']),
        'steps_json': jsonEncode([
          'Podar ramas afectadas',
          'Mejorar ventilación del cultivo',
          'Aplicar fungicida según recomendación técnica',
        ]),
        'references': 'Manual técnico del café',
      },
      {
        'id': 't_moniliacacao_1',
        'disease_id': 'monilia_cacao',
        'title': 'Manejo de Monilia del cacao',
        'description': 'Remover frutos enfermos y mejorar manejo fitosanitario.',
        'products_json': jsonEncode(['Cobre']),
        'steps_json': jsonEncode([
          'Cosecha sanitaria de frutos afectados',
          'Eliminación de residuos',
          'Aplicación preventiva de cobre',
        ]),
        'references': 'Guía cacao saludable',
      },
    ];

    for (final d in diseases) {
      await db.insert('diseases', d);
    }
    for (final t in treatments) {
      await db.insert('treatments', t);
    }
  }

  @override
  Future<bool> isReady() async => _db != null;

  @override
  Future<TreatmentInfo?> getTreatment(String diseaseId) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query('treatments', where: 'disease_id = ?', whereArgs: [diseaseId], limit: 1);
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

    // Dividir keywords en palabras individuales para búsqueda más flexible
    final words = keywords.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    // Construir query con LIKE para cada palabra
    final conditions = <String>[];
    final args = <dynamic>[];

    for (final word in words) {
      conditions.add('LOWER(keywords) LIKE ?');
      args.add('%$word%');
    }

    String whereClause = conditions.join(' AND ');
    if (cropType != null) {
      whereClause += ' AND crop_type = ?';
      args.add(cropType);
    }

    final rows = await db.query('diseases', where: whereClause, whereArgs: args, orderBy: 'name ASC');

    return rows.map((row) {
      final cropTypeStr = row['crop_type'] as String;
      CropType cropTypeEnum;
      switch (cropTypeStr) {
        case 'cacao':
          cropTypeEnum = CropType.cacao;
          break;
        case 'cafe':
          cropTypeEnum = CropType.cafe;
          break;
        case 'platano':
          cropTypeEnum = CropType.platano;
          break;
        case 'maiz':
          cropTypeEnum = CropType.maiz;
          break;
        default:
          cropTypeEnum = CropType.unknown;
      }

      return DiseaseInfo(
        id: row['id'] as String,
        name: row['name'] as String,
        cropType: cropTypeEnum,
        summary: row['summary'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<TreatmentInfo>> getTreatmentsForDiseases(List<String> diseaseIds) async {
    final db = _db;
    if (db == null || diseaseIds.isEmpty) return [];

    final placeholders = diseaseIds.map((_) => '?').join(',');
    final rows = await db.query(
      'treatments',
      where: 'disease_id IN ($placeholders)',
      whereArgs: diseaseIds,
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
