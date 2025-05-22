abstract class IBackendRepository {
  String get baseUrl;
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken);
}
