import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../models/session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final _uuid = const Uuid();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'seobi.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      singleInstance: true, // 동일한 데이터베이스에 대해 단일 인스턴스 유지
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    
    await db.execute('''
      CREATE TABLE session (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_at TEXT,
        finish_at TEXT,
        title TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE message (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        content TEXT,
        role TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES session (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_message_timestamp ON message(timestamp)');
  }

  // Session CRUD operations
  Future<String> createSession(String userId) async {
    final db = await database;
    final id = _uuid.v4();
    
    await db.insert(
      'session',
      Session(
        id: id,
        userId: userId,
        startAt: DateTime.now(),
      ).toMap(),
    );
    
    return id;
  }

  Future<Session?> getSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<List<Session>> getSessions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_at DESC',
    );

    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    await db.update(
      'session',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'session',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message CRUD operations
  Future<String> createMessage(Message message) async {
    final db = await database;
    final id = _uuid.v4();
    
    final messageMap = message.copyWith(id: id).toMap();
    await db.insert('message', messageMap);
    
    return id;
  }

  Future<Message?> getMessage(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'message',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Message.fromMap(maps.first);
  }

  Future<List<Message>> getSessionMessages(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'message',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<void> updateMessage(Message message) async {
    final db = await database;
    await db.update(
      'message',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'message',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
