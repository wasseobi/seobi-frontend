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
      content: content,
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
    debugPrint('[StubBackend] 메시지 목록 조회');
    await _simulateNetworkDelay();

    // 더미 데이터가 없는 경우 5개 생성
    if (_messages.isEmpty) {
      final sessionId = 'session_${_generateRandomString(8)}';
      final userId = 'user_${_generateRandomString(8)}';

      // 시스템 메시지
      final systemMessage = _createDummyMessage(
        sessionId: sessionId,
        userId: userId,
        content: '새로운 대화를 시작합니다.',
        role: 'system',
      );
      _messages[systemMessage.id] = systemMessage;

      // 사용자와 어시스턴트의 대화
      for (var i = 1; i <= 2; i++) {
        // 사용자 메시지
        final userMessage = _createDummyMessage(
          sessionId: sessionId,
          userId: userId,
          content: '테스트 질문 $i입니다.',
          role: 'user',
        );
        _messages[userMessage.id] = userMessage;

        // 어시스턴트 응답
        final assistantMessage = _createDummyMessage(
          sessionId: sessionId,
          userId: userId,
          content: '테스트 응답 $i입니다.',
          role: 'assistant',
        );
        _messages[assistantMessage.id] = assistantMessage;
      }
    }

    debugPrint('[StubBackend] 출력 - messages: ${_messages.values.toList()}');
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
      content: content,
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

    final sessionMessages =
        _messages.values.where((message) => message.sessionId == sessionId).toList();

    debugPrint('[StubBackend] 출력 - messages: $sessionMessages');
    return sessionMessages;
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
  Future<List<Message>> getMessagesByUserId(String userId) async {
    debugPrint('[StubBackend] 사용자별 메시지 목록 조회');
    debugPrint('[StubBackend] 입력 - userId: $userId');

    await _simulateNetworkDelay();

    final userMessages =
        _messages.values.where((message) => message.userId == userId).toList();

    debugPrint('[StubBackend] 출력 - messages: $userMessages');
    return userMessages;
  }
}
