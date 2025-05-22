import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'backend_repository_interface.dart';
import 'models/user.dart';
import 'models/session.dart';
import 'models/message.dart';

class StubBackendRepository implements BackendRepositoryInterface {
  static final StubBackendRepository _instance = StubBackendRepository._internal();
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
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken) async {
    debugPrint('[StubBackend] 로그인 요청');
    debugPrint('[StubBackend] 입력 - googleIdToken: ${googleIdToken.substring(0, min(10, googleIdToken.length))}...');
    
    await _simulateNetworkDelay();
    
    // googleIdToken이 비어있으면 오류 발생
    if (googleIdToken.isEmpty) {
      debugPrint('[StubBackend] 오류 - 유효하지 않은 토큰');
      throw Exception('유효하지 않은 Google ID 토큰입니다.');
    }    // 실제와 유사한 응답 데이터 반환
    final response = {
      'user_id': 'user_${_random.nextInt(99999)}',
      'email': '${_generateRandomString(8)}@gmail.com',
      'name': '테스트 사용자 ${_random.nextInt(999)}',
      'profile_image': 'https://picsum.photos/200',  // 실제 이미지 URL 반환
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${_generateRandomString(32)}',
      'refresh_token': 'rt_${_generateRandomString(32)}',
      'expires_in': 3600,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    debugPrint('[StubBackend] 출력 - response: $response');
    return response;
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

  // 더미 사용자 데이터 생성
  User _createDummyUser(String username, String email) {
    final userId = 'user_${_generateRandomString(8)}';
    return User(
      id: userId,
      username: username,
      email: email,
    );
  }

  // 더미 세션 데이터 생성
  Session _createDummySession(
    String userId, {
    String? title,
    String? description,
  }) {
    final sessionId = 'session_${_generateRandomString(8)}';
    final now = DateTime.now();
    return Session(
      id: sessionId,
      userId: userId,
      startAt: now,
      finishAt: _random.nextBool() ? now.add(Duration(hours: _random.nextInt(4))) : null,
      title: title ?? '세션 ${_generateRandomString(4)}',
      description: description,
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
      vector: role != 'user' ? List.generate(384, (_) => _random.nextDouble()) : null,
    );
  }

  @override
  Future<List<User>> getUsers() async {
    debugPrint('[StubBackend] 사용자 목록 조회');
    await _simulateNetworkDelay();

    // 더미 데이터가 없는 경우 5개 생성
    if (_users.isEmpty) {
      for (var i = 1; i <= 5; i++) {
        final user = _createDummyUser(
          '테스트유저$i',
          'user$i@example.com',
        );
        _users[user.id] = user;
      }
    }

    debugPrint('[StubBackend] 출력 - users: ${_users.values.toList()}');
    return _users.values.toList();
  }

  @override
  Future<User> postUser(String username, String email) async {
    debugPrint('[StubBackend] 사용자 생성');
    debugPrint('[StubBackend] 입력 - username: $username, email: $email');
    
    await _simulateNetworkDelay();

    // 이메일 중복 체크
    if (_users.values.any((user) => user.email == email)) {
      throw Exception('이미 존재하는 이메일입니다.');
    }

    final user = _createDummyUser(username, email);
    _users[user.id] = user;

    debugPrint('[StubBackend] 출력 - user: $user');
    return user;
  }

  @override
  Future<User> getUserById(String id) async {
    debugPrint('[StubBackend] 사용자 조회');
    debugPrint('[StubBackend] 입력 - id: $id');
    
    await _simulateNetworkDelay();

    final user = _users[id];
    if (user == null) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    debugPrint('[StubBackend] 출력 - user: $user');
    return user;
  }

  @override
  Future<User> putUserById(String id, String username, String email) async {
    debugPrint('[StubBackend] 사용자 정보 수정');
    debugPrint('[StubBackend] 입력 - id: $id, username: $username, email: $email');
    
    await _simulateNetworkDelay();

    final user = _users[id];
    if (user == null) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    // 이메일 중복 체크 (자기 자신은 제외)
    if (_users.values.any((u) => u.id != id && u.email == email)) {
      throw Exception('이미 존재하는 이메일입니다.');
    }

    final updatedUser = user.copyWith(
      username: username,
      email: email,
    );
    _users[id] = updatedUser;

    debugPrint('[StubBackend] 출력 - updated user: $updatedUser');
    return updatedUser;
  }

  @override
  Future<void> deleteUserById(String id) async {
    debugPrint('[StubBackend] 사용자 삭제');
    debugPrint('[StubBackend] 입력 - id: $id');
    
    await _simulateNetworkDelay();

    if (!_users.containsKey(id)) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    _users.remove(id);
    debugPrint('[StubBackend] 사용자 삭제 완료');
  }

  @override
  Future<List<Session>> getSessions() async {
    debugPrint('[StubBackend] 세션 목록 조회');
    await _simulateNetworkDelay();

    // 더미 데이터가 없는 경우 3개 생성
    if (_sessions.isEmpty) {
      for (var i = 1; i <= 3; i++) {
        final session = _createDummySession(
          'user_${_generateRandomString(8)}',
          title: '테스트 세션 $i',
          description: '테스트 세션 $i의 설명입니다.',
        );
        _sessions[session.id] = session;
      }
    }

    debugPrint('[StubBackend] 출력 - sessions: ${_sessions.values.toList()}');
    return _sessions.values.toList();
  }

  @override
  Future<Session> postSession(
    String userId, {
    String? title,
    String? description,
  }) async {
    debugPrint('[StubBackend] 세션 생성');
    debugPrint('[StubBackend] 입력 - userId: $userId, title: $title, description: $description');
    
    await _simulateNetworkDelay();

    final session = _createDummySession(
      userId,
      title: title,
      description: description,
    );
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
    debugPrint('[StubBackend] 입력 - sessionId: $sessionId, userId: $userId, content: $content, role: $role');
    
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
  Future<Message> getMessageById(String id) async {
    debugPrint('[StubBackend] 메시지 조회');
    debugPrint('[StubBackend] 입력 - id: $id');
    
    await _simulateNetworkDelay();

    final message = _messages[id];
    if (message == null) {
      throw Exception('메시지를 찾을 수 없습니다.');
    }

    debugPrint('[StubBackend] 출력 - message: $message');
    return message;
  }

  @override
  Future<Message> putMessageById(String id, {String? content, String? role}) async {
    debugPrint('[StubBackend] 메시지 수정');
    debugPrint('[StubBackend] 입력 - id: $id, content: $content, role: $role');
    
    await _simulateNetworkDelay();

    final message = _messages[id];
    if (message == null) {
      throw Exception('메시지를 찾을 수 없습니다.');
    }

    final updatedMessage = message.copyWith(
      content: content,
      role: role,
    );
    _messages[id] = updatedMessage;

    debugPrint('[StubBackend] 출력 - updated message: $updatedMessage');
    return updatedMessage;
  }

  @override
  Future<void> deleteMessageById(String id) async {
    debugPrint('[StubBackend] 메시지 삭제');
    debugPrint('[StubBackend] 입력 - id: $id');
    
    await _simulateNetworkDelay();

    if (!_messages.containsKey(id)) {
      throw Exception('메시지를 찾을 수 없습니다.');
    }

    _messages.remove(id);
    debugPrint('[StubBackend] 메시지 삭제 완료');
  }
}
