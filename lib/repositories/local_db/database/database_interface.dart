/// 데이터베이스 작업을 위한 추상화된 인터페이스입니다.
abstract class DatabaseInterface {
  Future<void> open(String path);
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  });
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  });
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Future<void> execute(String sql);
  Future<void> close();
  Future<void> transaction(Future<void> Function() action);
  bool get isOpen;
}
