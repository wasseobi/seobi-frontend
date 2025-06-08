import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/repositories/backend/backend_repository.dart';
import 'models/session.dart' as local_session;

/// 대화 서비스 v2 - Auth와 History 서비스를 통합 관리
class ConversationService2 {
  static final ConversationService2 _instance =
      ConversationService2._internal();
  factory ConversationService2() => _instance;

  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();
  final BackendRepository _backendRepository = BackendRepository();

  // 세션 자동 종료를 위한 타이머
  Timer? _sessionTimer;
  // 세션 자동 종료 시간 (3분)
  static const Duration _sessionTimeout = Duration(minutes: 3);

  // 현재 처리 중인 메시지의 ID
  String? _currentMessageId;
  // 현재 처리 중인 메시지 타입
  String? _currentMessageType;

  ConversationService2._internal();

  /// 초기화
  Future<void> initialize() async {
    // AuthService 초기화
    await _authService.init();

    // HistoryService 초기화
    await _historyService.initialize();

    debugPrint('[ConversationService2] 서비스 초기화 완료');
  }

  /// 현재 사용자 정보를 가져오고 인증 설정
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    _backendRepository.setAuthToken(user.accessToken);
    return user.id;
  }

  /// 가장 최근 세션을 가져오거나 새로 생성
  Future<local_session.Session> _getOrCreateLatestSession() async {
    final userId = await _getUserIdAndAuthenticate();

    // History Service에서 세션 목록 가져오기
    final sessions = _historyService.sessions;

    // 활성 세션이 있는지 확인
    final activeSession =
        sessions.isNotEmpty
            ? sessions.firstWhere(
              (session) => session.isActive,
              orElse: () => sessions.first,
            )
            : null; // 활성 세션이 있고 열려있다면 반환
    if (activeSession != null && activeSession.isActive) {
      debugPrint('[ConversationService2] 기존 활성 세션 사용: ${activeSession.id}');

      // 세션이 로드되지 않았다면 로드된 상태로 변경
      if (!activeSession.isLoaded) {
        final loadedSession = activeSession.copyWith(isLoaded: true);
        _historyService.updateSession(loadedSession);
        return loadedSession;
      }

      return activeSession;
    } // 새 세션 생성
    debugPrint('[ConversationService2] 새 세션 생성 중...');
    final backendSession = await _backendRepository.postSession(userId);
    final newSession = local_session.Session.fromBackendSession(
      backendSession,
    ).copyWith(
      isLoaded: true, // 새로 생성된 세션은 로드된 상태로 설정
    );

    // History Service에 새 세션 추가
    _historyService.addSession(newSession);

    debugPrint('[ConversationService2] 새 세션 생성 완료: ${newSession.id}');
    return newSession;
  }

  /// Message 객체를 생성하거나 업데이트
  Message _createOrUpdateMessage({
    required String sessionId,
    required String userId,
    required String content,
    required Map<String, dynamic> data,
    String? existingMessageId,
  }) {
    final type = data['type'] as String?;
    final metadata = data['metadata'] as Map<String, dynamic>?;
    final timestamp =
        metadata?['timestamp'] != null
            ? DateTime.parse(metadata!['timestamp'] as String)
            : DateTime.now();

    MessageType messageType;
    String? title;

    switch (type) {
      case 'user':
        messageType = MessageType.user;
        break;
      case 'tool_calls':
        messageType = MessageType.tool_call;
        final toolCalls = data['tool_calls'] as List<dynamic>?;
        if (toolCalls != null && toolCalls.isNotEmpty) {
          final firstTool = toolCalls.first as Map<String, dynamic>;
          title = firstTool['function']?['name'] as String?;
        }
        break;
      case 'toolmessage':
        messageType = MessageType.tool_result;
        title = metadata?['tool_name'] as String?;
        break;
      case 'chunk':
        messageType = MessageType.assistant;
        break;
      default:
        messageType = MessageType.error;
    }

    return Message(
      id: existingMessageId ?? _generateMessageId(),
      sessionId: sessionId,
      type: messageType,
      title: title,
      content: content,
      timestamp: timestamp,
    );
  }

  /// 세션에서 특정 메시지 업데이트 또는 새 메시지 추가
  local_session.Session _updateOrAddMessage(
    local_session.Session session,
    Message message, {
    bool isUpdate = false,
  }) {
    if (isUpdate) {
      final updatedMessages =
          session.messages.map((m) {
            if (m.id == message.id) {
              return message;
            }
            return m;
          }).toList();

      return session.copyWith(messages: updatedMessages);
    } else {
      return session.copyWith(messages: [...session.messages, message]);
    }
  }

  /// 메시지 전송 및 세션 업데이트
  Future<void> sendMessage(String content) async {
    try {
      // 1. 사용자 정보 확인 및 인증
      final userId = await _getUserIdAndAuthenticate();

      // 2. 대기 중인 메시지 설정
      _historyService.setPendingUserMessage(content);

      // 3. 최근 세션 가져오기 또는 새로 생성
      var session = await _getOrCreateLatestSession();
      debugPrint('[ConversationService2] ⌨️ 사용자 메시지 전송 시작:');
      debugPrint('[ConversationService2] 📤 "$content"');

      // 타이머 재설정
      _resetSessionTimer(session.id);

      // 현재 메시지 관련 변수들
      String currentContent = '';

      // 4. 서버로 메시지 전송 및 스트림 처리
      await for (final chunk in _backendRepository.postSendMessage(
        sessionId: session.id,
        userId: userId,
        content: content,
      )) {
        debugPrint('[ConversationService2] 수신된 청크: $chunk');

        final type = chunk['type'] as String?;
        switch (type) {
          case 'user':
            // 사용자 메시지는 항상 새로운 메시지
            _currentMessageId = null;
            _currentMessageType = null;

            final message = _createOrUpdateMessage(
              sessionId: session.id,
              userId: userId,
              content: chunk['content'] as String? ?? '',
              data: chunk,
            );

            session = _updateOrAddMessage(session, message);
            _updateSessionInHistory(session);
            _historyService.clearPendingUserMessage();
            break;

          case 'tool_calls':
            // 이전 assistant 메시지가 있다면 먼저 처리
            if (currentContent.isNotEmpty && _currentMessageType == null) {
              final message = _createOrUpdateMessage(
                sessionId: session.id,
                userId: userId,
                content: currentContent,
                data: {'type': 'chunk'},
                existingMessageId: _currentMessageId,
              );

              session = _updateOrAddMessage(
                session,
                message,
                isUpdate: _currentMessageId != null,
              );
              _updateSessionInHistory(session);
              currentContent = '';
              _currentMessageId = null;
            }

            final toolCalls = chunk['tool_calls'] as List<dynamic>?;
            if (toolCalls != null && toolCalls.isNotEmpty) {
              final firstTool = toolCalls.first as Map<String, dynamic>;
              final functionName = firstTool['function']?['name'] as String?;
              final arguments = firstTool['function']?['arguments'] as String? ?? '';

              // 새로운 tool_calls 메시지 시작
              if (_currentMessageType != 'tool_calls') {
                _currentMessageId = _generateMessageId();
                _currentMessageType = 'tool_calls';

                final message = Message(
                  id: _currentMessageId!,
                  sessionId: session.id,
                  type: MessageType.tool_call,
                  title: functionName,
                  content: arguments,
                  timestamp: DateTime.now(),
                );

                session = _updateOrAddMessage(session, message);
                _updateSessionInHistory(session);
              } else {
                // 기존 tool_calls 메시지에 arguments 추가
                final existingMessage = session.messages.lastWhere(
                  (m) => m.id == _currentMessageId && m.type == MessageType.tool_call,
                  orElse: () => throw Exception('현재 tool_calls 메시지를 찾을 수 없습니다.'),
                );

                final message = Message(
                  id: existingMessage.id,
                  sessionId: session.id,
                  type: MessageType.tool_call,
                  title: functionName ?? existingMessage.title,
                  content: existingMessage.content + arguments,
                  timestamp: existingMessage.timestamp,
                );

                session = _updateOrAddMessage(session, message, isUpdate: true);
                _updateSessionInHistory(session);
              }
            }
            break;

          case 'toolmessage':
            // 이전 assistant 메시지가 있다면 먼저 처리
            if (currentContent.isNotEmpty && _currentMessageType == null) {
              final message = _createOrUpdateMessage(
                sessionId: session.id,
                userId: userId,
                content: currentContent,
                data: {'type': 'chunk'},
                existingMessageId: _currentMessageId,
              );

              session = _updateOrAddMessage(
                session,
                message,
                isUpdate: _currentMessageId != null,
              );
              _updateSessionInHistory(session);
              currentContent = '';
              _currentMessageId = null;
            }

            // 이전 type과 관계없이 항상 새로운 메시지로 처리
            _currentMessageId = _generateMessageId();
            _currentMessageType = 'toolmessage';

            final content = chunk['content'] as String? ?? '';
            try {
              // content가 JSON 형식인지 확인하고 예쁘게 포맷팅
              final dynamic jsonData = content.isNotEmpty ? json.decode(content) : {};
              final prettyContent = JsonEncoder.withIndent('  ').convert(jsonData);

              final message = Message(
                id: _currentMessageId!,
                sessionId: session.id,
                type: MessageType.tool_result,
                title: chunk['metadata']?['tool_name'] as String?,
                content: prettyContent,
                timestamp: DateTime.now(),
              );

              session = _updateOrAddMessage(session, message);
              _updateSessionInHistory(session);
              // toolmessage 처리 후 상태 초기화
              _currentMessageId = null;
              _currentMessageType = null;
            } catch (e) {
              // JSON 파싱에 실패한 경우 원본 내용 그대로 표시
              final message = Message(
                id: _currentMessageId!,
                sessionId: session.id,
                type: MessageType.tool_result,
                title: chunk['metadata']?['tool_name'] as String?,
                content: content,
                timestamp: DateTime.now(),
              );

              session = _updateOrAddMessage(session, message);
              _updateSessionInHistory(session);
              // toolmessage 처리 후 상태 초기화
              _currentMessageId = null;
              _currentMessageType = null;
            }
            break;

          case 'chunk':
            if (_currentMessageType == null) {
              // 일반 assistant 청크는 누적
              currentContent += chunk['content'] as String? ?? '';
              
              // 누적된 내용으로 메시지 업데이트 또는 생성
              final message = _createOrUpdateMessage(
                sessionId: session.id,
                userId: userId,
                content: currentContent,
                data: {'type': 'chunk'},
                existingMessageId: _currentMessageId,
              );

              session = _updateOrAddMessage(
                session,
                message,
                isUpdate: _currentMessageId != null,
              );
              _updateSessionInHistory(session);
              
              // 다음 assistant 청크를 위해 메시지 ID 저장
              _currentMessageId = message.id;
            } else if (_currentMessageType == 'toolmessage') {
              // toolmessage는 이미 처리됨, 무시
            } else if (_currentMessageType == 'tool_calls') {
              // tool_calls의 추가 청크는 이전 메시지에 추가
              try {
                final existingMessage = session.messages.lastWhere(
                  (m) => m.id == _currentMessageId && m.type == MessageType.tool_call,
                );

                final message = Message(
                  id: existingMessage.id,
                  sessionId: session.id,
                  type: MessageType.tool_call,
                  title: existingMessage.title,
                  content: existingMessage.content + (chunk['content'] as String? ?? ''),
                  timestamp: existingMessage.timestamp,
                );

                session = _updateOrAddMessage(session, message, isUpdate: true);
                _updateSessionInHistory(session);
              } catch (e) {
                debugPrint('[ConversationService2] tool_calls 메시지 업데이트 실패: $e');
              }
            }
            break;

          case 'end':
            // 남은 누적 내용이 있다면 메시지로 생성
            if (currentContent.isNotEmpty) {
              final message = _createOrUpdateMessage(
                sessionId: session.id,
                userId: userId,
                content: currentContent,
                data: {'type': 'chunk'},
                existingMessageId: _currentMessageId,
              );

              session = _updateOrAddMessage(
                session,
                message,
                isUpdate: _currentMessageId != null,
              );
              _updateSessionInHistory(session);
              currentContent = '';
            }

            _currentMessageId = null;
            _currentMessageType = null;

            debugPrint(
              '[ConversationService2] 스트림 종료, 컨텍스트 저장: ${chunk['context_saved']}',
            );
            debugPrint('[ConversationService2] ✅ 메시지 전송 완료');
            break;

          case 'error':
            _currentMessageId = null;
            _currentMessageType = null;

            final errorMessage = _createOrUpdateMessage(
              sessionId: session.id,
              userId: userId,
              content: chunk['error'] as String? ?? '알 수 없는 오류가 발생했습니다.',
              data: {'type': 'error'},
            );

            session = _updateOrAddMessage(session, errorMessage);
            _updateSessionInHistory(session);

            debugPrint('[ConversationService2] ❌ 오류: ${chunk['error']}');
            throw Exception(chunk['error']);

          default:
            debugPrint('[ConversationService2] ❓ 알 수 없는 청크 타입: $type');
            break;
        }
      }

      // 5. 전송 완료 후 대기 중인 메시지 클리어
      _historyService.clearPendingUserMessage();
    } catch (e) {
      // 오류 발생 시 대기 중인 메시지 클리어
      _historyService.clearPendingUserMessage();

      debugPrint('[ConversationService2] ❌ 메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 현재 대기 중인 사용자 메시지 확인
  String? get pendingUserMessage => _historyService.pendingUserMessage;

  /// 대기 중인 사용자 메시지가 있는지 확인
  bool get hasPendingUserMessage => _historyService.hasPendingUserMessage;

  /// 세션 목록 조회
  List<local_session.Session> get sessions => _historyService.sessions;

  /// 특정 세션 조회
  local_session.Session? getSessionById(String sessionId) {
    return _historyService.getSessionById(sessionId);
  }

  /// 메시지 ID 생성
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// History Service의 세션 목록에서 해당 세션을 업데이트
  void _updateSessionInHistory(local_session.Session updatedSession) {
    _historyService.updateSession(updatedSession);
  }

  /// 타이머 시작 또는 재설정
  void _resetSessionTimer(String sessionId) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () => _autoFinishSession(sessionId));
  }

  /// 세션 자동 종료
  Future<void> _autoFinishSession(String sessionId) async {
    debugPrint('[ConversationService2] ⏰ 세션 자동 종료 시작: $sessionId');

    try {
      // 백엔드에서 세션 종료
      await _backendRepository.postSessionFinish(sessionId);

      // 로컬 세션 상태 업데이트
      final session = _historyService.getSessionById(sessionId);
      if (session != null && session.isActive) {
        final finishedSession = session.copyWith(finishAt: DateTime.now());
        _historyService.updateSession(finishedSession);
        debugPrint('[ConversationService2] ✅ 세션 자동 종료 완료: $sessionId');
      }
    } catch (e) {
      debugPrint('[ConversationService2] ⚠️ 세션 자동 종료 실패: $e');
    }
  }

  /// 리소스 정리
  Future<void> dispose() async {
    debugPrint('[ConversationService2] 🧹 리소스 정리 시작');

    try {
      // 0. 타이머 정리
      _sessionTimer?.cancel();
      _sessionTimer = null;

      // 1. 활성 세션이 있다면 종료
      final activeSession =
          _historyService.sessions.isNotEmpty
              ? _historyService.sessions.firstWhere(
                (session) => session.isActive,
                orElse: () => _historyService.sessions.first,
              )
              : null;

      if (activeSession != null && activeSession.isActive) {
        try {
          // 백엔드에서 세션 종료
          await _backendRepository.postSessionFinish(activeSession.id);
          debugPrint('[ConversationService2] ✅ 활성 세션 종료: ${activeSession.id}');

          // 로컬에서도 세션 상태 업데이트
          final finishedSession = activeSession.copyWith(
            finishAt: DateTime.now(),
          );
          _historyService.updateSession(finishedSession);
        } catch (e) {
          debugPrint('[ConversationService2] ⚠️ 활성 세션 종료 실패: $e');
        }
      }

      // 2. 대기 중인 사용자 메시지 정리
      if (hasPendingUserMessage) {
        _historyService.clearPendingUserMessage();
        debugPrint('[ConversationService2] ✅ 대기 중인 메시지 정리 완료');
      }

      // 3. 히스토리 서비스 정리
      (_historyService as ChangeNotifier).dispose();
      debugPrint('[ConversationService2] ✅ 히스토리 서비스 정리 완료');
    } catch (e) {
      debugPrint('[ConversationService2] ❌ 리소스 정리 중 오류 발생: $e');
      rethrow;
    }

    debugPrint('[ConversationService2] ✅ 모든 리소스 정리 완료');
  }
}
