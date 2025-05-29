import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'i_backend_repository.dart';
import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';

class StubBackendRepository implements IBackendRepository {
  static final StubBackendRepository _instance =
      StubBackendRepository._internal();
  factory StubBackendRepository() => _instance;

  final Random _random = Random();

  // 실제 서비스와 비슷한 네트워크 지연을 시뮬레이션하기 위한 설정
  static const minDelay = Duration(milliseconds: 100);
  static const maxAdditionalDelay = Duration(milliseconds: 300);
  // 더미 사용자 데이터를 저장할 맵
  final Map<String, User> _users = {};

  // 더미 세션 데이터를 저장할 맵
  final Map<String, Session> _sessions = {};

  // 더미 메시지 데이터를 저장할 맵
  final Map<String, Message> _messages = {};

  StubBackendRepository._internal();

  @override
  String get baseUrl => 'http://localhost:5000';

  /// 실제 서비스와 비슷한 네트워크 지연을 시뮬레이션합니다.
  Future<void> _simulateNetworkDelay() async {
    debugPrint('[StubBackend] 네트워크 지연 시뮬레이션 시작');
    final additionalMs = _random.nextInt(maxAdditionalDelay.inMilliseconds);
    final totalDelay = minDelay + Duration(milliseconds: additionalMs);
    debugPrint('[StubBackend] 예상 지연 시간: ${totalDelay.inMilliseconds}ms');

    await Future.delayed(totalDelay);

    // 10% 확률로 네트워크 오류 발생
    if (_random.nextDouble() < 0.1) {
      debugPrint('[StubBackend] 네트워크 오류 시뮬레이션');
      throw Exception('네트워크 오류가 발생했습니다.');
    }
    debugPrint('[StubBackend] 네트워크 지연 시뮬레이션 완료');
  }

  @override
  Future<User> postUserLogin(String googleIdToken) async {
    debugPrint('[StubBackend] 로그인 요청');
    debugPrint(
      '[StubBackend] 입력 - googleIdToken: ${googleIdToken.substring(0, min(10, googleIdToken.length))}...',
    );

    await _simulateNetworkDelay();

    // googleIdToken이 비어있으면 오류 발생
    if (googleIdToken.isEmpty) {
      debugPrint('[StubBackend] 오류 - 유효하지 않은 토큰');
      throw Exception('유효하지 않은 Google ID 토큰입니다.');
    }

    // 더미 유저 데이터 생성
    final userId = 'user_${_random.nextInt(99999)}';
    final user = User(
      id: userId,
      username: '테스트 사용자 ${_random.nextInt(999)}',
      email: '${_generateRandomString(8)}@gmail.com',
      accessToken:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${_generateRandomString(32)}',
    );

    // 생성된 유저 정보를 저장
    _users[userId] = user;

    debugPrint('[StubBackend] 출력 - user: $user');
    return user;
  }

  /// 랜덤 문자열을 생성합니다.
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  // 더미 세션 데이터 생성
  Session _createDummySession(String userId) {
    final sessionId = 'session_${_generateRandomString(8)}';
    final now = DateTime.now();
    return Session(
      id: sessionId,
      userId: userId,
      startAt: now,
      finishAt: null,
      title: '세션 ${_generateRandomString(4)}',
      description: '세션 설명',
    );
  }

  // 더미 메시지 데이터 생성
  Message _createDummyMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
  }) {
    final messageId = 'message_${_generateRandomString(8)}';
    return Message(
      id: messageId,
      sessionId: sessionId,
      userId: userId,
      content: content ?? '', // null일 경우 빈 문자열 사용
      role: role,
      timestamp: DateTime.now(),
      vector:
          role != 'user'
              ? List.generate(384, (_) => _random.nextDouble())
              : null,
    );
  }

  @override
  Future<List<Session>> getSessions() async {
    debugPrint('[StubBackend] 세션 목록 조회');
    await _simulateNetworkDelay();

    // 더미 데이터가 없는 경우 3개 생성
    if (_sessions.isEmpty) {
      for (var i = 1; i <= 3; i++) {
        final session = _createDummySession('user_${_generateRandomString(8)}');
        _sessions[session.id] = session;
      }
    }

    debugPrint('[StubBackend] 출력 - sessions: ${_sessions.values.toList()}');
    return _sessions.values.toList();
  }

  @override
  Future<Session> postSession(String userId) async {
    debugPrint('[StubBackend] 세션 생성');
    debugPrint('[StubBackend] 입력 - userId: $userId');

    await _simulateNetworkDelay();

    final session = _createDummySession(userId);
    _sessions[session.id] = session;

    debugPrint('[StubBackend] 출력 - session: $session');
    return session;
  }

  @override
  Future<Session> getSessionById(String id) async {
    debugPrint('[StubBackend] 세션 조회');
    debugPrint('[StubBackend] 입력 - id: $id');

    await _simulateNetworkDelay();

    final session = _sessions[id];
    if (session == null) {
      throw Exception('세션을 찾을 수 없습니다.');
    }

    debugPrint('[StubBackend] 출력 - session: $session');
    return session;
  }

  @override
  Future<Session> putSessionById(String id, Session updatedSession) async {
    debugPrint('[StubBackend] 세션 업데이트');
    debugPrint('[StubBackend] 입력 - id: $id, updatedSession: $updatedSession');

    await _simulateNetworkDelay();

    if (!_sessions.containsKey(id)) {
      throw Exception('세션을 찾을 수 없습니다.');
    }

    _sessions[id] = updatedSession;
    debugPrint('[StubBackend] 출력 - updated session: $updatedSession');
    return updatedSession;
  }

  @override
  Future<void> deleteSessionById(String id) async {
    debugPrint('[StubBackend] 세션 삭제');
    debugPrint('[StubBackend] 입력 - id: $id');

    await _simulateNetworkDelay();

    if (!_sessions.containsKey(id)) {
      throw Exception('세션을 찾을 수 없습니다.');
    }

    _sessions.remove(id);
    debugPrint('[StubBackend] 세션 삭제 완료');
  }

  @override
  Future<List<Message>> getMessages() async {
    debugPrint('[StubBackend] 전체 메시지 목록 조회');
    await _simulateNetworkDelay();
    return _messages.values.toList();
  }

  @override
  Future<Message> postMessage({
    required String sessionId,
    required String userId,
    String? content,
    required String role,
  }) async {
    debugPrint('[StubBackend] 메시지 생성');
    debugPrint(
      '[StubBackend] 입력 - sessionId: $sessionId, userId: $userId, content: $content, role: $role',
    );

    await _simulateNetworkDelay();

    final message = _createDummyMessage(
      sessionId: sessionId,
      userId: userId,
      content: content ?? '', // null일 경우 빈 문자열 사용
      role: role,
    );
    _messages[message.id] = message;

    debugPrint('[StubBackend] 출력 - message: $message');
    return message;
  }

  @override
  Future<Session> postSessionFinish(String id) async {
    debugPrint('[StubBackend] 세션 종료');
    debugPrint('[StubBackend] 입력 - id: $id');

    await _simulateNetworkDelay();

    final session = _sessions[id];
    if (session == null) {
      throw Exception('세션을 찾을 수 없습니다.');
    }

    final updatedSession = session.copyWith(finishAt: DateTime.now());
    _sessions[id] = updatedSession;

    debugPrint('[StubBackend] 출력 - finished session: $updatedSession');
    return updatedSession;
  }

  @override
  Future<List<Session>> getSessionsByUserId(String userId) async {
    debugPrint('[StubBackend] 사용자별 세션 목록 조회');
    debugPrint('[StubBackend] 입력 - userId: $userId');

    await _simulateNetworkDelay();

    final userSessions =
        _sessions.values.where((session) => session.userId == userId).toList();

    debugPrint('[StubBackend] 출력 - sessions: $userSessions');
    return userSessions;
  }

  @override
  Future<List<Message>> getMessagesBySessionId(String sessionId) async {
    debugPrint('[StubBackend] 세션별 메시지 목록 조회');
    debugPrint('[StubBackend] 입력 - sessionId: $sessionId');

    await _simulateNetworkDelay();

    final messages =
        _messages.values
            .where((message) => message.sessionId == sessionId)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    debugPrint('[StubBackend] 출력 - messages: $messages');
    return messages;
  }

  @override
  Future<List<Message>> getMessagesByUserId(String userId) async {
    debugPrint('[StubBackend] 사용자별 메시지 목록 조회');
    debugPrint('[StubBackend] 입력 - userId: $userId');

    await _simulateNetworkDelay();

    final messages =
        _messages.values.where((message) => message.userId == userId).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    debugPrint('[StubBackend] 출력 - messages: $messages');
    return messages;
  }

  @override
  Future<Message> postMessageLanggraphCompletion({
    required String sessionId,
    required String userId,
    required String content,
  }) async {
    debugPrint('[StubBackend] 랭그래프 완료 요청');
    debugPrint(
      '[StubBackend] 입력 - sessionId: $sessionId, userId: $userId, content: $content',
    );

    await _simulateNetworkDelay();

    // 사용자 메시지 추가
    final userMessage = _createDummyMessage(
      sessionId: sessionId,
      userId: userId,
      content: content,
      role: 'user',
    );
    _messages[userMessage.id] = userMessage;

    // 어시스턴트 응답 생성
    final assistantMessage = _createDummyMessage(
      sessionId: sessionId,
      userId: userId,
      content: '이것은 AI 어시스턴트의 응답입니다: ${_generateRandomString(20)}',
      role: 'assistant',
    );
    _messages[assistantMessage.id] = assistantMessage;

    final response = {
      'user_message': userMessage,
      'assistant_message': assistantMessage,
    };

    debugPrint('[StubBackend] 출력 - response: $response');
    return assistantMessage;
  }

  @override
  Stream<Map<String, dynamic>> postMessageLanggraphCompletionStream({
    required String sessionId,
    required String userId,
    required String content,
  }) async* {
    debugPrint('[StubBackend] LangGraph 스트리밍 시작');
    debugPrint('[StubBackend] 입력 - sessionId: $sessionId, userId: $userId');
    debugPrint('[StubBackend] 입력 - content: $content');

    // 시작 청크 전송
    yield {
      'type': 'start',
      'user_message': {'content': content},
    };

    // 더미 응답 텍스트
    const dummyResponse = '''
안녕하세요! 저는 AI 어시스턴트입니다.
제가 도움을 드릴 수 있는 부분이 있다면 말씀해 주세요.
저는 다음과 같은 작업을 도와드릴 수 있습니다:

1. 질문에 대한 답변
2. 정보 검색 및 요약
3. 코드 관련 도움
4. 일상적인 대화
''';

    // 메타데이터 템플릿
    final metadata = {
      'langgraph_step': 0,
      'langgraph_node': 'agent',
      'langgraph_triggers': [
        '__start__',
        'branch:agent:state_conditional:agent',
        'tool',
      ],
      'langgraph_path': ['__pregel_pull', 'agent'],
      'langgraph_checkpoint_ns': 'agent:${_generateRandomString(32)}',
      'checkpoint_ns': 'agent:${_generateRandomString(32)}',
      'ls_provider': 'azure',
      'ls_model_name': 'o4-mini',
      'ls_model_type': 'chat',
      'ls_temperature': null,
    };

    // 응답을 한 글자씩 스트리밍
    for (var i = 0; i < dummyResponse.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));

      yield {
        'type': 'chunk',
        'content': dummyResponse[i],
        'metadata': metadata,
      };
    }

    // 전체 응답 전송
    yield {'type': 'answer', 'answer': dummyResponse};

    // 종료 청크 전송
    yield {'type': 'end', 'context_saved': true};

    debugPrint('[StubBackend] LangGraph 스트리밍 완료');
  }
}
