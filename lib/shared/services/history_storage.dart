import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class ConversationSummary {
  final String id;
  final String title;
  final DateTime updatedAt;
  final int messageCount;

  ConversationSummary({required this.id, required this.title, required this.updatedAt, required this.messageCount});
}

class ConversationMessage {
  final String id;
  final String conversationId;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final String type; // text|response|media

  ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.isUser,
    required this.text,
    required this.timestamp,
    required this.type,
  });
}

abstract class HistoryStorage {
  Future<void> initialize();
  Future<String> createConversation({required String title});
  Future<void> addMessage({
    required String conversationId,
    required bool isUser,
    required String text,
    required DateTime timestamp,
    required String type,
  });
  Future<List<ConversationSummary>> listConversations();
  Future<List<ConversationMessage>> listMessages(String conversationId);
}

class SqliteHistoryStorage implements HistoryStorage {
  Database? _db;

  @override
  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'metriagro_history.db');
    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE conversations (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
        await db.execute('''
        CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          is_user INTEGER NOT NULL,
          text TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          type TEXT NOT NULL,
          FOREIGN KEY(conversation_id) REFERENCES conversations(id)
        );
      ''');
      },
    );
  }

  @override
  Future<String> createConversation({required String title}) async {
    final db = _db!;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    await db.insert('conversations', {'id': id, 'title': title, 'updated_at': now.millisecondsSinceEpoch});
    return id;
  }

  @override
  Future<void> addMessage({
    required String conversationId,
    required bool isUser,
    required String text,
    required DateTime timestamp,
    required String type,
  }) async {
    final db = _db!;
    final id = '${conversationId}_${timestamp.millisecondsSinceEpoch}';
    await db.insert('messages', {
      'id': id,
      'conversation_id': conversationId,
      'is_user': isUser ? 1 : 0,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
    });
    await db.update(
      'conversations',
      {
        'updated_at': timestamp.millisecondsSinceEpoch,
        'title': text.isNotEmpty ? text.substring(0, text.length > 40 ? 40 : text.length) : 'Conversación',
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  @override
  Future<List<ConversationSummary>> listConversations() async {
    final db = _db!;
    final rows = await db.rawQuery('''
      SELECT c.id, c.title, c.updated_at, COUNT(m.id) as msg_count
      FROM conversations c
      LEFT JOIN messages m ON m.conversation_id = c.id
      GROUP BY c.id
      ORDER BY c.updated_at DESC
    ''');
    return rows
        .map(
          (r) => ConversationSummary(
            id: r['id'] as String,
            title: r['title'] as String,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
            messageCount: (r['msg_count'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<ConversationMessage>> listMessages(String conversationId) async {
    final db = _db!;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows
        .map(
          (r) => ConversationMessage(
            id: r['id'] as String,
            conversationId: r['conversation_id'] as String,
            isUser: (r['is_user'] as int) == 1,
            text: r['text'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
            type: r['type'] as String,
          ),
        )
        .toList();
  }
}





