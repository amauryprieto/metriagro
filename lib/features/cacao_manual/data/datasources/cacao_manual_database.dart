import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CacaoManualDatabase {
  static const String _databaseName = 'cacao_manual.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  CacaoManualDatabase._();
  static final CacaoManualDatabase instance = CacaoManualDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main manual sections table
    await db.execute('''
      CREATE TABLE manual_sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter TEXT NOT NULL,
        section_title TEXT NOT NULL,
        content TEXT NOT NULL,
        symptoms TEXT,
        treatment TEXT,
        prevention TEXT,
        severity_level INTEGER DEFAULT 1,
        image_examples TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // FTS5 virtual table for full-text search
    await db.execute('''
      CREATE VIRTUAL TABLE manual_fts USING fts5(
        chapter,
        section_title,
        content,
        symptoms,
        treatment,
        prevention,
        content=manual_sections,
        content_rowid=id
      )
    ''');

    // Triggers to keep FTS index in sync
    await db.execute('''
      CREATE TRIGGER manual_sections_ai AFTER INSERT ON manual_sections BEGIN
        INSERT INTO manual_fts(rowid, chapter, section_title, content, symptoms, treatment, prevention)
        VALUES (new.id, new.chapter, new.section_title, new.content, new.symptoms, new.treatment, new.prevention);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER manual_sections_ad AFTER DELETE ON manual_sections BEGIN
        INSERT INTO manual_fts(manual_fts, rowid, chapter, section_title, content, symptoms, treatment, prevention)
        VALUES('delete', old.id, old.chapter, old.section_title, old.content, old.symptoms, old.treatment, old.prevention);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER manual_sections_au AFTER UPDATE ON manual_sections BEGIN
        INSERT INTO manual_fts(manual_fts, rowid, chapter, section_title, content, symptoms, treatment, prevention)
        VALUES('delete', old.id, old.chapter, old.section_title, old.content, old.symptoms, old.treatment, old.prevention);
        INSERT INTO manual_fts(rowid, chapter, section_title, content, symptoms, treatment, prevention)
        VALUES (new.id, new.chapter, new.section_title, new.content, new.symptoms, new.treatment, new.prevention);
      END
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    // Section-Tags relationship (many-to-many)
    await db.execute('''
      CREATE TABLE section_tags (
        section_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (section_id, tag_id),
        FOREIGN KEY (section_id) REFERENCES manual_sections(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // ML classification to manual sections mapping
    await db.execute('''
      CREATE TABLE ml_to_manual_mapping (
        ml_class_id TEXT PRIMARY KEY,
        ml_class_label TEXT NOT NULL,
        section_ids TEXT NOT NULL,
        confidence_threshold REAL DEFAULT 0.7
      )
    ''');

    // Synonyms table for improved search
    await db.execute('''
      CREATE TABLE synonyms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term TEXT NOT NULL,
        synonym TEXT NOT NULL,
        UNIQUE(term, synonym)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sections_chapter ON manual_sections(chapter)');
    await db.execute('CREATE INDEX idx_sections_severity ON manual_sections(severity_level)');
    await db.execute('CREATE INDEX idx_synonyms_term ON synonyms(term)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('section_tags');
    await db.delete('ml_to_manual_mapping');
    await db.delete('synonyms');
    await db.delete('tags');
    await db.delete('manual_sections');
  }
}
