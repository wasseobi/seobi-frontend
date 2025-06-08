import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRepository {
  // ========================================
  // 인증 관련 키
  // ========================================
  static const String KEY_IS_LOGGED_IN = 'isLoggedIn';
  static const String KEY_USER_ID = 'userId';
  static const String KEY_ACCESS_TOKEN = 'accessToken';
  static const String KEY_DISPLAY_NAME = 'displayName';
  static const String KEY_EMAIL = 'email';
  static const String KEY_PHOTO_URL = 'photoUrl';

  // ========================================
  // 세션 관련 키
  // ========================================
  static const String KEY_ACTIVE_SESSION_ID = 'active_session_id';
  static const String KEY_LAST_SESSION_ID = 'last_session_id';
  static const String KEY_SESSION_START_TIME = 'session_start_time';

  // ========================================
  // 앱 설정 관련 키
  // ========================================
  static const String KEY_THEME_MODE = 'theme_mode';
  static const String KEY_LANGUAGE = 'language';
  static const String KEY_TEXT_SIZE = 'text_size';
  static const String KEY_NOTIFICATIONS_ENABLED = 'notifications_enabled';

  // ========================================
  // TTS(Text-to-Speech) 관련 키
  // ========================================
  static const String KEY_TTS_ENABLED = 'tts_enabled';
  static const String KEY_TTS_SPEED = 'tts_speed';
  static const String KEY_TTS_PITCH = 'tts_pitch';
  static const String KEY_TTS_VOLUME = 'tts_volume';

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
