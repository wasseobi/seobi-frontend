import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';

abstract class IBackendRepository {
  String get baseUrl;
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken);
  
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
  Future<void> deleteSessionById(String id);

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
}
