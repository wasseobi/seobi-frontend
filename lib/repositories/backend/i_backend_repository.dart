import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';

abstract class IBackendRepository {
  String get baseUrl;
  Future<User> postUserLogin(String googleIdToken);
  
  // User related methods
  Future<List<User>> getUsers();
  Future<User> postUser(String username, String email);
  Future<User> getUserById(String id);
  Future<User> putUserById(String id, String username, String email);
  Future<void> deleteUserById(String id);

  // Session related methods
  Future<List<Session>> getSessions();
  Future<Session> postSession(String userId, {String? title, String? description});
  Future<Session> getSessionById(String id);
  Future<Session> putSessionById(String id, {String? title, String? description});
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
  Future<Message> getMessageById(String id);
  Future<Message> putMessageById(String id, {String? content, String? role});
  Future<void> deleteMessageById(String id);
  Future<List<Message>> getMessagesBySessionId(String sessionId);
  Future<Map<String, dynamic>> postMessageLanggraphCompletion({
    required String sessionId,
    required String userId,
    required String content,
  });
  Future<List<Message>> getMessagesByUserId(String userId);
}
