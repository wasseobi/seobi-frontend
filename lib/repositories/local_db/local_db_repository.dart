import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Directory;
import 'local_db_repository_interface.dart';
import 'models/message.dart';
import 'models/session.dart';
import 'database/database_interface.dart';
import 'database/database_factory.dart';

/// 로컬 데이터베이스 서비스의 구현을 제공하는 클래스입니다.
class LocalDbRepository implements LocalDbRepositoryInterface {
  static final LocalDbRepository _instance = LocalDbRepository._internal();
  factory LocalDbRepository() => _instance;

  DatabaseInterface? _db;
  bool _initialized = false;

  LocalDbRepository._internal();

  @override
  Future<void> init() async {
    if (_initialized) return;

    final dbPath = await _getDatabasePath();
    final db = DatabaseFactory.create();
    await db.open(dbPath);
    _db = db;
    _initialized = true;
  }

  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(path.join(appDir.path, 'Seobi'));
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }
    return path.join(dbDir.path, 'seobi.db');
  }

  DatabaseInterface get database {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  Future<List<Session>> getAllSessions() async {
    final maps = await database.query('sessions');
    return maps.map((map) => Session.fromJson(map)).toList();
  }

  @override
  Future<Session?> getSessionById(String id) async {
    final maps = await database.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Session.fromJson(maps.first);
  }

  @override
  Future<Session> createSession(Session session) async {
    await database.insert('sessions', session.toJson());
    return session;
  }

  @override
  Future<void> updateSession(Session session) async {
    await database.update(
      'sessions',
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<void> deleteSession(String id) async {
    await database.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Message>> getAllMessages() async {
    final maps = await database.query('messages');
    return maps.map((map) => Message.fromJson(map)).toList();
  }

  @override
  Future<List<Message>> getMessagesBySessionId(String sessionId) async {
    final maps = await database.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return maps.map((map) => Message.fromJson(map)).toList();
  }

  @override
  Future<Message?> getMessageById(String id) async {
    final maps = await database.query(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Message.fromJson(maps.first);
  }

  @override
  Future<Message> createMessage(Message message) async {
    await database.insert('messages', message.toJson());
    return message;
  }

  @override
  Future<void> updateMessage(Message message) async {
    await database.update(
      'messages',
      message.toJson(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  @override
  Future<void> deleteMessage(String id) async {
    await database.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _initialized = false;
    }
  }
}
