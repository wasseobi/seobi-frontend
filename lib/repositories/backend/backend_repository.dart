import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'i_backend_repository.dart';
import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';
import 'http_helper.dart';

class BackendRepository implements IBackendRepository {
  static final BackendRepository _instance = BackendRepository._internal();
  factory BackendRepository() => _instance;

  late final HttpHelper _http;

  BackendRepository._internal() {
    _http = HttpHelper(baseUrl);
  }

  @override
  String get baseUrl {
    // .env 파일에서 백엔드 URL 설정 읽기
    final useRemoteBackend = dotenv.get('USE_REMOTE_BACKEND', fallback: 'false') == 'true';
    
    if (useRemoteBackend) {
      // 원격 백엔드 사용
      return dotenv.get('REMOTE_BACKEND_URL');
    } else {
      // 로컬 백엔드 사용
      if (kIsWeb || !Platform.isAndroid) {
        return dotenv.get('LOCAL_BACKEND_URL_DEFAULT', fallback: 'http://127.0.0.1:5000');
      } else {
        return dotenv.get('LOCAL_BACKEND_URL_ANDROID', fallback: 'http://10.0.2.2:5000');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken) async {
    return _http.post(
      '/users/login',
      {'id_token': googleIdToken},
      (json) => json,
      expectedStatus: 200,
    );
  }

  // User related methods
  @override
  Future<List<User>> getUsers() {
    return _http.getList('/users', User.fromJson);
  }

  @override
  Future<User> postUser(String username, String email) {
    return _http.post(
      '/users',
      {'username': username, 'email': email},
      User.fromJson,
    );
  }

  @override
  Future<User> getUserById(String id) {
    return _http.get('/users/$id', User.fromJson);
  }

  @override
  Future<User> putUserById(String id, String username, String email) {
    return _http.put(
      '/users/$id',
      {'username': username, 'email': email},
      User.fromJson,
    );
  }

  @override
  Future<void> deleteUserById(String id) {
    return _http.delete('/users/$id');
  }

  // Session related methods
  @override
  Future<List<Session>> getSessions() {
    return _http.getList('/sessions', Session.fromJson);
  }

  @override
  Future<Session> postSession(
    String userId, {
    String? title,
    String? description,
  }) {
    return _http.post(
      '/sessions',
      {
        'user_id': userId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
      Session.fromJson,
    );
  }

  @override
  Future<Session> getSessionById(String id) {
    return _http.get('/sessions/$id', Session.fromJson);
  }

  @override
  Future<void> deleteSessionById(String id) {
    return _http.delete('/sessions/$id');
  }

  // Message related methods
  @override
  Future<List<Message>> getMessages() {
    return _http.getList('/messages', Message.fromJson);
  }

  @override
  Future<Message> postMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
  }) {
    return _http.post(
      '/messages',
      {
        'session_id': sessionId,
        'user_id': userId,
        'content': content,
        'role': role,
      },
      Message.fromJson,
    );
  }

  @override
  Future<Message> getMessageById(String id) {
    return _http.get('/messages/$id', Message.fromJson);
  }

  @override
  Future<Message> putMessageById(String id, {String? content, String? role}) {
    final updates = <String, dynamic>{};
    if (content != null) updates['content'] = content;
    if (role != null) updates['role'] = role;
    
    return _http.put(
      '/messages/$id',
      updates,
      Message.fromJson,
    );
  }

  @override
  Future<void> deleteMessageById(String id) {
    return _http.delete('/messages/$id');
  }
}
