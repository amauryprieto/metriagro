import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Utilidad para cargar una BD de prueba desde assets en almacenamiento local
class KnowledgeBaseLoader {
  static const String assetSqlPath = 'assets/db/test_cacao_kb.sql';

  /// Crea una BD temporal y ejecuta el fixture SQL de assets
  static Future<Database> loadTestDatabase() async {
    final tempDir = await getDatabasesPath();
    final dbPath = p.join(tempDir, 'test_cacao_kb.db');

    // Si existe, eliminar para partir limpio
    if (await File(dbPath).exists()) {
      await deleteDatabase(dbPath);
    }

    final db = await openDatabase(dbPath, version: 1);
    final sql = await rootBundle.loadString(assetSqlPath);
    final batch = db.batch();

    // Separar por ';' cuidando líneas vacías
    for (final stmt in sql.split(';')) {
      final s = stmt.trim();
      if (s.isEmpty) continue;
      batch.execute('$s;');
    }
    await batch.commit(noResult: true);
    return db;
  }
}
