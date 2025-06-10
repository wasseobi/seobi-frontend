import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'i_backend_repository.dart';
import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';
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
  Future<Message> postMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
  }) {
    return _http.post(
      '/messages/',
      {
        'session_id': sessionId,
        'user_id': userId,
        'content': content,
        'role': role, // API에는 문자열로 전송
      },
      (json) => Message.fromJson(json), // fromJson에서 MessageRole 변환 처리됨
    );
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
  Future<Message> postMessageLanggraphCompletion({
    required String sessionId,
    required String userId,
    required String content,
  }) {
    return _http.post(
      '/s/$sessionId/complete',
      {'content': content},
      Message.fromJson,
      headers: {'user-id': userId},
    );
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
          headers: {
            'user-id': userId,
            'Accept': 'text/event-stream', // swagger_new.json 명세서에 따른 필수 헤더
          },
        )
        .map((chunk) {
          debugPrint('[BackendRepository] 청크 수신: $chunk');
          return chunk;
        })
        .where((chunk) {
          try {
            final type = chunk['type'];

            // 실제 백엔드 응답 타입에 맞춘 필터링
            switch (type) {
              case 'start':
                // 스트리밍 시작 - UI에서 활용 가능
                return true;

              case 'tool_calls':
                // AI가 도구를 사용할 때 - UI에서 "검색 중..." 표시용
                debugPrint(
                  '[BackendRepository] AI 도구 사용 시작: ${chunk['tool_calls']}',
                );
                return true;

              case 'toolmessage':
                // 도구 실행 결과 - UI에서 "검색 완료" 표시용
                debugPrint('[BackendRepository] 도구 실행 결과 수신');
                return true;

              case 'chunk':
                // AI 응답 텍스트 청크 - 메인 콘텐츠
                final content = chunk['content'];
                final isValid =
                    content != null && content.toString().isNotEmpty;
                if (!isValid) {
                  debugPrint('[BackendRepository] 빈 청크 무시: $chunk');
                }
                return isValid;

              case 'end':
                // 스트리밍 종료 - UI 상태 업데이트용
                return true;

              case 'answer':
                // 전체 답변 (있는 경우) - 백업용
                return chunk['answer'] != null;

              default:
                // 알 수 없는 타입은 로그만 출력하고 무시
                debugPrint('[BackendRepository] 알 수 없는 타입 무시: type=$type');
                return false;
            }
          } catch (e) {
            debugPrint('[BackendRepository] 청크 필터링 오류: $e');
            return false;
          }
        });
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
