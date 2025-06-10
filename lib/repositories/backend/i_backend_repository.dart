import 'package:seobi_app/repositories/backend/models/user.dart';
import 'package:seobi_app/repositories/backend/models/session.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';

//========================================
// 사용자 인증 관련
//========================================
abstract class IBackendRepository {
  String get baseUrl;
  Future<User> postUserLogin(String email, String? displayName);

  //========================================
  // 세션 관련
  //========================================
  Future<List<Session>> getSessions();
  Future<Session> postSession(String userId);
  Future<Session> getSessionById(String id);
  Future<Session> putSessionById(String id, Session updatedSession);
  Future<void> deleteSessionById(String id);
  Future<Session> postSessionFinish(String id);
  Future<List<Session>> getSessionsByUserId(String userId);

  //========================================
  // 메시지 관련
  //========================================
  Future<List<Message>> getMessages();
  Future<Message> postMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? extensions,
  });
  Future<List<Message>> getMessagesBySessionId(String sessionId);
  Future<List<Message>> getMessagesByUserId(String userId);
  Stream<dynamic> postSendMessage({
    required String sessionId,
    required String userId,
    required String content,
  });

  //========================================
  // 확장 기능 (추후 구현)
  //========================================
  Future<Map<String, dynamic>>? parseScheduleFromText({
    required String userId,
    required String text,
  });
  Future<List<Map<String, dynamic>>>? getUserSchedules(String userId);
  Future<Map<String, dynamic>>? generateInsight({required String userId});
  Future<List<Map<String, dynamic>>>? getUserInsights(String userId);
}
