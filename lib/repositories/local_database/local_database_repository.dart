import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import 'models/message.dart';
import 'models/session.dart';

class LocalDatabaseRepository {
  static final LocalDatabaseRepository _instance =
      LocalDatabaseRepository._internal();
  static Database? _database;

  factory LocalDatabaseRepository() {
    return _instance;
  }

  LocalDatabaseRepository._internal();

  /// 테스트용 초기화 메서드
  Future<void> initialize([String? databasePath]) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await _initPlatformSpecific();

    final String path =
        databasePath ?? join(await getDatabasesPath(), 'seobi.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  /// 데이터베이스 연결 종료
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _initPlatformSpecific() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Windows와 Linux에서는 FFI 초기화가 필요
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (Platform.isMacOS) {
      // macOS에서도 FFI 사용
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not supported by this database implementation',
      );
    }
    // Android와 iOS는 기본 구현을 사용하므로 추가 초기화가 필요없음
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');

    await db.execute('''
      CREATE TABLE session (
        id TEXT PRIMARY KEY,
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
        content TEXT,
        role TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES session (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_message_timestamp ON message(timestamp)',
    );
  }

  // Session operations
  Future<void> insertSession(Session session) async {
    final db = await database;
    await db.insert('session', session.toMap());
  }

  Future<void> insertSessions(List<Session> sessions) async {
    final db = await database;
    final batch = db.batch();

    for (var session in sessions) {
      batch.insert('session', session.toMap());
    }

    await batch.commit(noResult: true);
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

  Future<List<Session>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session',
      orderBy: 'start_at DESC',
    );

    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('session', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSessions(List<String> ids) async {
    final db = await database;
    final batch = db.batch();

    for (var id in ids) {
      batch.delete('session', where: 'id = ?', whereArgs: [id]);
    }

    await batch.commit(noResult: true);
  }

  // Message operations
  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert('message', message.toMap());
  }

  Future<void> insertMessages(List<Message> messages) async {
    final db = await database;
    final batch = db.batch();

    for (var message in messages) {
      batch.insert('message', message.toMap());
    }

    await batch.commit(noResult: true);
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
}
