import 'package:sqflite/sqflite.dart' as sqflite;
import 'database_interface.dart';

/// 모바일 플랫폼을 위한 sqflite 기반 데이터베이스 구현체입니다.
class MobileDatabase implements DatabaseInterface {
  sqflite.Database? _db;

  @override
  Future<void> open(String path) async {
    _db = await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_at INTEGER,
        finish_at INTEGER,
        title TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        content TEXT,
        role TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    _checkDatabase();
    return _db!.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    _checkDatabase();
    return _db!.insert(table, values, 
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _checkDatabase();
    return _db!.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    _checkDatabase();
    return _db!.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> execute(String sql) async {
    _checkDatabase();
    await _db!.execute(sql);
  }

  @override
  Future<void> transaction(Future<void> Function() action) async {
    _checkDatabase();
    await _db!.transaction((txn) async {
      await action();
    });
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  @override
  bool get isOpen => _db?.isOpen ?? false;

  void _checkDatabase() {
    if (_db == null) {
      throw StateError('Database not opened. Call open() first.');
    }
  }
}
