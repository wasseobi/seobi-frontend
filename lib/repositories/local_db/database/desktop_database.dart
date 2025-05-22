import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'database_interface.dart';

/// 데스크톱 플랫폼을 위한 sqlite3 기반 데이터베이스 구현체입니다.
class DesktopDatabase implements DatabaseInterface {
  sqlite.Database? _db;

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
    final result = _db!.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
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
    final sql = 'INSERT OR REPLACE INTO $table ($columns) VALUES ($placeholders)';
    
    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(values.values.toList());
      return _db!.lastInsertRowId;
    } finally {
      stmt.dispose();
    }
  }

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
      return _db!.changes;
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
      return _db!.changes;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<void> execute(String sql) async {
    _checkDatabase();
    _db!.execute(sql);
  }

  @override
  Future<void> transaction(Future<void> Function() action) async {
    _checkDatabase();
    await execute('BEGIN TRANSACTION');
    try {
      await action();
      await execute('COMMIT');
    } catch (e) {
      await execute('ROLLBACK');
      rethrow;
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
