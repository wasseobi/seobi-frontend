import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter/foundation.dart';
import 'database_interface.dart';

/// 데스크톱 플랫폼을 위한 sqlite3 기반 데이터베이스 구현체입니다.
class DesktopDatabase implements DatabaseInterface {
  sqlite.Database? _db;
  bool _inTransaction = false;

  @override
  Future<void> open(String path) async {
    _db = sqlite.sqlite3.open(path);
    await _onCreate();
  }

  Future<void> _onCreate() async {
    if (!_tableExists('sessions')) {
      await execute('''
        CREATE TABLE sessions(
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          start_at INTEGER,
          finish_at INTEGER,
          title TEXT,
          description TEXT
        )
      ''');
    }

    if (!_tableExists('messages')) {
      await execute('''
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
  }
  bool _tableExists(String tableName) {
    try {
      final stmt = _db!.prepare(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?"
      );
      try {
        final result = stmt.select([tableName]);
        return result.isNotEmpty;
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      debugPrint('테이블 존재 여부 확인 중 오류 발생: $e');
      rethrow;
    }
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

    final columnsStr = columns?.join(', ') ?? '*';
    var sql = 'SELECT $columnsStr FROM $table';

    if (where != null) {
      sql += ' WHERE $where';
    }

    if (orderBy != null) {
      sql += ' ORDER BY $orderBy';
    }

    final result = _db!.select(sql, whereArgs ?? []);
    return result.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        map[result.columnNames[i]] = row[i];
      }
      return map;
    }).toList();
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    _checkDatabase();

    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final sql =
        'INSERT OR REPLACE INTO $table ($columns) VALUES ($placeholders)';

    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(values.values.toList());
      return _db!.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

  /// 마지막으로 영향받은 행의 수를 반환합니다.
  int _getChanges() {
    final result = _db!.select('SELECT changes()');
    return result.first[0] as int;
  }

  /// 현재 트랜잭션 상태를 반환합니다.
  bool get isInTransaction => _inTransaction;

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _checkDatabase();
    
    final setClauses = values.keys.map((key) => '$key = ?').join(', ');
    var sql = 'UPDATE $table SET $setClauses';
    
    if (where != null) {
      sql += ' WHERE $where';
    }

    final stmt = _db!.prepare(sql);
    try {
      final params = [...values.values, ...(whereArgs ?? [])];
      stmt.execute(params);
      return _getChanges();
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    _checkDatabase();
    
    var sql = 'DELETE FROM $table';
    if (where != null) {
      sql += ' WHERE $where';
    }

    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(whereArgs ?? []);
      return _getChanges();
    } finally {
      stmt.dispose();
    }
  }
  @override
  Future<void> execute(String sql) async {
    _checkDatabase();
    try {
      _db!.execute(sql);
    } catch (e) {
      debugPrint('SQL 실행 오류: $e\nSQL: $sql');
      rethrow;
    }
  }

  @override
  Future<void> transaction(Future<void> Function() action) async {
    _checkDatabase();

    // 중첩 트랜잭션 처리
    if (_inTransaction) {
      await action();
      return;
    }

    _inTransaction = true;
    await execute('BEGIN TRANSACTION');

    try {
      await action();
      await execute('COMMIT');
    } catch (e) {
      await execute('ROLLBACK');
      rethrow;
    } finally {
      _inTransaction = false;
    }
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      _db!.dispose();
      _db = null;
    }
  }

  @override
  bool get isOpen => _db != null;

  void _checkDatabase() {
    if (_db == null) {
      throw StateError('Database not opened. Call open() first.');
    }
  }
}
