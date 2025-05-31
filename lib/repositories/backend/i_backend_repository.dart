import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';

abstract class IBackendRepository {
  String get baseUrl;
  Future<User> postUserLogin(String googleIdToken);

  // Session related methods
  Future<List<Session>> getSessions();
  Future<Session> postSession(String userId);
  Future<Session> getSessionById(String id);
  Future<Session> putSessionById(String id, Session updatedSession);
  Future<void> deleteSessionById(String id);
  Future<Session> postSessionFinish(String id);
  Future<List<Session>> getSessionsByUserId(String userId);

  // Message related methods
  Future<List<Message>> getMessages();
  Future<Message> postMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
  });
  Future<List<Message>> getMessagesBySessionId(String sessionId);
  Future<List<Message>> getMessagesByUserId(String userId);

  // LangGraph Streaming API
  Future<Message> postMessageLanggraphCompletion({
    required String sessionId,
    required String userId,
    required String content,
  });
  Stream<Map<String, dynamic>> postMessageLanggraphCompletionStream({
    required String sessionId,
    required String userId,
    required String content,
  });

  // ========================================
  // 향후 API 확장 준비 (swagger_new.json 대응)
  // ========================================
  // 새로운 API 스펙이 활성화되면 구현될 예정인 메서드들

  /// 자연어를 일정으로 파싱 (향후 구현)
  /// POST /debug/schedule/parse
  Future<Map<String, dynamic>>? parseScheduleFromText({
    required String userId,
    required String text,
  });

  /// 사용자의 일정 목록 조회 (향후 구현)
  /// GET /debug/schedule/{user_id}
  Future<List<Map<String, dynamic>>>? getUserSchedules(String userId);

  /// AI 인사이트 생성 (향후 구현)
  /// POST /insights/generate
  Future<Map<String, dynamic>>? generateInsight({required String userId});

  /// 인사이트 목록 조회 (향후 구현)
  /// GET /insights/
  Future<List<Map<String, dynamic>>>? getUserInsights(String userId);
}
