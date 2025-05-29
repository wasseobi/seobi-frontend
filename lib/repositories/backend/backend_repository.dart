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

  /// 인증 토큰을 설정합니다.
  void setAuthToken(String? token) {
    _http.setAuthToken(token);
  }

  @override
  String get baseUrl {
    // .env 파일에서 백엔드 URL 설정 읽기
    final useRemoteBackend =
        dotenv.get('USE_REMOTE_BACKEND', fallback: 'false') == 'true';

    if (useRemoteBackend) {
      // 원격 백엔드 사용
      return dotenv.get('REMOTE_BACKEND_URL');
    } else {
      // 로컬 백엔드 사용
      if (kIsWeb || !Platform.isAndroid) {
        return dotenv.get(
          'LOCAL_BACKEND_URL_DEFAULT',
          fallback: 'http://127.0.0.1:5000',
        );
      } else {
        // Android 에뮬레이터에서는 10.0.2.2를 사용
        return dotenv.get(
          'LOCAL_BACKEND_URL_ANDROID',
          fallback: 'http://10.0.2.2:5000',
        );
      }
    }
  }

  @override
  Future<User> postUserLogin(String googleIdToken) async {
    return _http.post(
      '/users/login',
      {'id_token': googleIdToken},
      User.fromJson,
      expectedStatus: 200,
    );
  }

  // Session related methods
  @override
  Future<List<Session>> getSessions() {
    return _http.getList('/sessions/', Session.fromJson);
  }

  @override
  Future<Session> postSession(String userId) {
    return _http.post('/sessions/', {'user_id': userId}, Session.fromJson);
  }

  @override
  Future<Session> getSessionById(String id) {
    return _http.get('/sessions/$id', Session.fromJson);
  }

  @override
  Future<Session> putSessionById(String id, Session updatedSession) {
    return _http.put(
      '/sessions/$id',
      updatedSession.toJson(),
      Session.fromJson,
    );
  }

  @override
  Future<void> deleteSessionById(String id) {
    return _http.delete('/sessions/$id');
  }

  @override
  Future<Session> postSessionFinish(String id) {
    return _http.post(
      '/sessions/$id/finish',
      {},
      Session.fromJson,
      expectedStatus: 200,
    );
  }

  @override
  Future<List<Session>> getSessionsByUserId(String userId) {
    return _http.getList('/sessions/user/$userId', Session.fromJson);
  }

  // Message related methods
  @override
  Future<List<Message>> getMessages() {
    return _http.getList('/messages', Message.fromJson);
  }

  @override
  Future<List<Message>> getMessagesBySessionId(String sessionId) {
    return _http.getList('/messages/session/$sessionId', Message.fromJson);
  }

  @override
  Future<List<Message>> getMessagesByUserId(String userId) {
    return _http.getList('/messages/user/$userId', Message.fromJson);
  }

  @override
  Stream<Map<String, dynamic>> postMessageLanggraphCompletionStream({
    required String sessionId,
    required String userId,
    required String content,
  }) {
    final endpoint = '/s/$sessionId/send';
    debugPrint('[BackendRepository] 메시지 전송 시작: $endpoint');
    debugPrint(
      '[BackendRepository] 요청 본문: {user_id: $userId, content: $content}',
    );

    return _http
        .postStream(
          endpoint,
          {'content': content},
          headers: {'user-id': userId},
        )
        .map((chunk) {
          debugPrint('[BackendRepository] 청크 수신: $chunk');
          if (chunk is! Map<String, dynamic>) {
            throw FormatException('잘못된 청크 형식: $chunk');
          }
          return chunk;
        })
        .where((chunk) {
          try {
            final type = chunk['type'];
            if (type == 'answer') return true;
            if (type == 'end') return true;

            final content = chunk['content'];
            final isValid = type == 'chunk' && content != null;

            if (!isValid) {
              debugPrint(
                '[BackendRepository] 무시된 청크: type=$type, content=$content',
              );
            }
            return isValid;
          } catch (e) {
            debugPrint('[BackendRepository] 청크 필터링 오류: $e');
            return false;
          }
        });
  }
}
