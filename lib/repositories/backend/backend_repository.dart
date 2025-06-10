import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'i_backend_repository.dart';
import 'package:seobi_app/repositories/backend/models/user.dart';
import 'package:seobi_app/repositories/backend/models/session.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'http_helper.dart';
import 'models/schedule.dart';

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
        return dotenv.get(
          'LOCAL_BACKEND_URL_ANDROID',
          fallback: 'http://10.0.2.2:5000',
        );
      }
    }
  }

  @override
  Future<User> postUserLogin(String email, String? displayName) async {
    return _http.post(
      '/auth/sign',
      {'email': email, if (displayName != null) 'username': displayName},
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
    // swagger_new.json에 따른 올바른 API 호출: POST /s/open
    return _http.post(
      '/s/open',
      {}, // 빈 본문
      (json) {
        // SessionResponse는 session_id만 포함하므로 Session 객체로 변환
        final sessionId = json['session_id'] as String;
        return Session(
          id: sessionId,
          userId: userId,
          startAt: DateTime.now(),
          type: SessionType.chat, // 기본값
        );
      },
      headers: {'user-id': userId}, // user-id를 헤더로 전송
      expectedStatus: 201, // 명세서에 따른 정확한 상태 코드
    );
  }

  @override
  Future<Session> getSessionById(String id) {
    return _http.get('/s/$id', Session.fromJson);
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
      '/s/$id/close',
      {},
      Session.fromJson,
      expectedStatus: 200,
    );
  }

  @override
  Future<List<Session>> getSessionsByUserId(String userId) {
    return _http.getList('/s/$userId', Session.fromJson);
  }
  //========================================
  // 메시지 관련 메서드들
  //========================================

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
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? extensions,
  }) {
    final payload = {
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'role': role,
      if (metadata != null) 'metadata': metadata,
      if (extensions != null) 'extensions': extensions,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return _http.post(
      '/messages/',
      payload,
      Message.fromJson,
      expectedStatus: 201,
    );
  }

  @override
  Future<List<Message>> getMessagesBySessionId(String sessionId) {
    return _http.getList('/s/$sessionId/m', Message.fromJson);
  }

  @override
  Future<List<Message>> getMessagesByUserId(String userId) {
    return _http.getList('/m/$userId', Message.fromJson);
  }

  @override
  Stream<dynamic> postSendMessage({
    required String sessionId,
    required String userId,
    required String content,
  }) {
    final endpoint = '/s/$sessionId/send';
    debugPrint('[BackendRepository] postSendMessage 시작: $endpoint');

    final payload = {
      'content': content,
      'metadata': {
        'client_timestamp': DateTime.now().toIso8601String(),
        'client_version': '1.0.0',
      },
    };
    debugPrint('[BackendRepository] 요청 본문: $payload');

    return _http.postSse(
      endpoint,
      payload,
      headers: {
        'user-id': userId,
        'accept': 'text/event-stream',
        'content-type': 'application/json',
      },
    );
  }

  // ========================================
  // 향후 API 확장 준비 (swagger_new.json 대응)
  // ========================================
  // 아래 메서드들은 새로운 API 스펙이 활성화되면 구현될 예정입니다.
  // 현재는 인터페이스만 정의하여 확장성을 확보합니다.

  /// 자연어를 일정으로 파싱 (향후 구현 예정)
  ///
  /// 새로운 API: `POST /debug/schedule/parse`
  /// 예: "6월 7일 오후 6시에 영화관에서 쇼케이스 보러가는 거 기억해줘"
  @override
  Future<Map<String, dynamic>>? parseScheduleFromText({
    required String userId,
    required String text,
  }) {
    // TODO: swagger_new.json 활성화 시 구현
    debugPrint('[BackendRepository] Schedule API는 아직 미구현 상태입니다.');
    return null;
  }

  /// 사용자의 일정 목록 조회 (향후 구현 예정)
  ///
  /// 새로운 API: `GET /debug/schedule/{user_id}`
  @override
  Future<List<Map<String, dynamic>>>? getUserSchedules(String userId) {
    // TODO: swagger_new.json 활성화 시 구현
    debugPrint('[BackendRepository] Schedule API는 아직 미구현 상태입니다.');
    return null;
  }

  /// AI 인사이트 생성 (향후 구현 예정)
  ///
  /// 새로운 API: `POST /insights/generate`
  /// 사용자의 대화 기록을 분석하여 인사이트 생성
  @override
  Future<Map<String, dynamic>>? generateInsight({required String userId}) {
    // TODO: swagger_new.json 활성화 시 구현
    debugPrint('[BackendRepository] Insights API는 아직 미구현 상태입니다.');
    return null;
  }

  /// 인사이트 목록 조회 (향후 구현 예정)
  ///
  /// 새로운 API: `GET /insights/`
  @override
  Future<List<Map<String, dynamic>>>? getUserInsights(String userId) {
    // TODO: swagger_new.json 활성화 시 구현
    debugPrint('[BackendRepository] Insights API는 아직 미구현 상태입니다.');
    return null;
  }

  Future<List<Schedule>> getSchedulesByUserId(
    String userId, {
    String? accessToken,
  }) async {
    return _http.getList(
      '/schedule/$userId',
      (json) => Schedule.fromJson(json),
      headers:
          accessToken != null && accessToken.isNotEmpty
              ? {'Authorization': 'Bearer $accessToken'}
              : {},
    );
  }
}
