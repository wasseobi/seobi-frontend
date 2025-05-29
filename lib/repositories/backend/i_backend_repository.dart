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
  Future<List<Message>> getMessagesBySessionId(String sessionId);
  Future<List<Message>> getMessagesByUserId(String userId);

  // LangGraph Streaming API
  Stream<Map<String, dynamic>> postMessageLanggraphCompletionStream({
    required String sessionId,
    required String userId,
    required String content,
  });
}
