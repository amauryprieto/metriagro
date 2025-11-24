import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacaoManualDatabase {
  static const String _databaseName = 'cacao_manual.db';
  static const String _assetPath = 'assets/database/cacao_manual.db';
  static const String _dbVersionKey = 'cacao_manual_db_version';
  static const String _schemaVersionKey = 'cacao_manual_schema_version';

  /// Increment this when the pre-built database in assets is updated
  static const int _currentDbVersion = 2;

  /// Increment this when schema changes are needed (embedding columns, etc.)
  static const int _currentSchemaVersion = 2;

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

    // Check if we need to copy/update the database from assets
    await _ensureDatabaseFromAssets(path);

    // Open database and run migrations
    final db = await openDatabase(path);
    await _runMigrations(db);

    return db;
  }

  /// Run schema migrations after database is opened
  Future<void> _runMigrations(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final schemaVersion = prefs.getInt(_schemaVersionKey) ?? 1;

    if (schemaVersion < 2) {
      // Migration: Add embedding columns
      await _migrateToV2(db);
      await prefs.setInt(_schemaVersionKey, 2);
      print('[CacaoManualDatabase] Migrated to schema version 2 (embeddings)');
    }
  }

  /// Migration to add embedding columns
  Future<void> _migrateToV2(Database db) async {
    // Check if columns already exist
    final tableInfo = await db.rawQuery('PRAGMA table_info(manual_sections)');
    final columns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!columns.contains('embedding')) {
      await db.execute('ALTER TABLE manual_sections ADD COLUMN embedding BLOB');
    }

    if (!columns.contains('embedding_norm')) {
      await db.execute('ALTER TABLE manual_sections ADD COLUMN embedding_norm REAL');
    }
  }

  /// Copies the pre-built database from assets if needed
  Future<void> _ensureDatabaseFromAssets(String dbPath) async {
    final prefs = await SharedPreferences.getInstance();
    final installedVersion = prefs.getInt(_dbVersionKey) ?? 0;
    final dbFile = File(dbPath);
    final dbExists = await dbFile.exists();

    // Copy database if it doesn't exist or if there's a newer version
    if (!dbExists || installedVersion < _currentDbVersion) {
      // Close existing connection if open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete old database if it exists
      if (dbExists) {
        await dbFile.delete();
      }

      // Ensure the directory exists
      final dbDir = Directory(dirname(dbPath));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      // Copy from assets
      try {
        final ByteData data = await rootBundle.load(_assetPath);
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await dbFile.writeAsBytes(bytes, flush: true);

        // Update installed version
        await prefs.setInt(_dbVersionKey, _currentDbVersion);
      } catch (e) {
        // If asset copy fails, fall back to creating empty database
        // This shouldn't happen in production but provides a safety net
        rethrow;
      }
    }
  }

  /// Force re-copy the database from assets
  /// Useful for debugging or forcing an update
  Future<void> resetFromAssets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dbVersionKey);

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    final dbFile = File(path);

    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    // Re-initialize will copy from assets
    _database = await _initDatabase();
  }

  /// Get the current database version
  Future<int> getInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dbVersionKey) ?? 0;
  }

  /// Check if database needs update
  Future<bool> needsUpdate() async {
    final installedVersion = await getInstalledVersion();
    return installedVersion < _currentDbVersion;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
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
