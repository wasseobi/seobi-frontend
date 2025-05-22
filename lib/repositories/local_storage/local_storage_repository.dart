import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRepository {
  static final LocalStorageRepository _instance = LocalStorageRepository._internal();
  static late final SharedPreferences _prefs;
  static bool _initialized = false;

  factory LocalStorageRepository() => _instance;

  LocalStorageRepository._internal();

  Future<void> init() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
