import 'package:shared_preferences/shared_preferences.dart';
import '../models/messages.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _apiService;
  static const String _sessionIdKey = 'current_session_id';
  static const String _userIdKey = 'current_user_id';

  MessageService({required ApiService apiService}) : _apiService = apiService;

  Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<Message> createMessage(String content) async {
    String? sessionId = await getCurrentSessionId();
    String? userId = await getCurrentUserId();

    if (sessionId == null || userId == null) {
      throw Exception('세션 ID 또는 사용자 ID가 없습니다. 먼저 로그인이 필요합니다.');
    }

    return await _apiService.createMessage(
      sessionId: sessionId,
      userId: userId,
      content: content,
      role: 'user',
    );
  }
}
