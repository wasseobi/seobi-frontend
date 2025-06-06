import 'package:flutter/foundation.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/repositories/backend/backend_repository.dart';
import 'models/session.dart' as local_session;
import 'models/message.dart';
import 'package:seobi_app/repositories/local_database/models/message_role.dart';

/// 대화 서비스 v2 - Auth와 History 서비스를 통합 관리
class ConversationService2 {
  static final ConversationService2 _instance =
      ConversationService2._internal();
  factory ConversationService2() => _instance;

  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();
  final BackendRepository _backendRepository = BackendRepository();

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
            : null;    // 활성 세션이 있고 열려있다면 반환
    if (activeSession != null && activeSession.isActive) {
      debugPrint('[ConversationService2] 기존 활성 세션 사용: ${activeSession.id}');
      
      // 세션이 로드되지 않았다면 로드된 상태로 변경
      if (!activeSession.isLoaded) {
        final loadedSession = activeSession.copyWith(isLoaded: true);
        _historyService.updateSession(loadedSession);
        return loadedSession;
      }
      
      return activeSession;
    }// 새 세션 생성
    debugPrint('[ConversationService2] 새 세션 생성 중...');
    final backendSession = await _backendRepository.postSession(userId);
    final newSession = local_session.Session.fromBackendSession(backendSession).copyWith(
      isLoaded: true, // 새로 생성된 세션은 로드된 상태로 설정
    );

    // History Service에 새 세션 추가
    _historyService.addSession(newSession);

    debugPrint('[ConversationService2] 새 세션 생성 완료: ${newSession.id}');
    return newSession;
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

      debugPrint('[ConversationService2] 메시지 전송 시작');
      debugPrint('[ConversationService2] 세션 ID: ${session.id}');
      debugPrint('[ConversationService2] 사용자 ID: $userId');
      debugPrint('[ConversationService2] 메시지 내용: $content');

      // 현재 AI 응답 메시지 추적용 변수들
      String? currentAssistantMessageId;
      final List<String> assistantContentChunks = [];

      // 4. 서버로 메시지 전송 및 스트림 처리
      await for (final chunk in _backendRepository.postSendMessage(
        sessionId: session.id,
        userId: userId,
        content: content,
      )) {
        debugPrint('[ConversationService2] 수신된 청크: $chunk');

        final type = chunk['type'] as String?;

        switch (type) {          case 'user':
            // 사용자 메시지 추가
            final userMessage = Message(
              id: chunk['metadata']?['message_id'] ?? _generateMessageId(),
              sessionId: session.id,
              userId: userId,
              content: [chunk['content'] as String],
              role: MessageRole.user,
              timestamp: DateTime.now(),
              extensions: chunk['metadata'],
            );

            // 세션에 사용자 메시지 추가
            final updatedMessages = [...session.messages, userMessage];
            session = session.copyWith(messages: updatedMessages);
            _updateSessionInHistory(session);

            // 사용자 메시지가 서버에서 처리되었으므로 대기 중인 메시지 클리어
            _historyService.clearPendingUserMessage();

            debugPrint('[ConversationService2] 사용자 메시지 추가: ${userMessage.id}');
            break;

          case 'chunk':
            // AI 응답 청크 처리
            final chunkContent = chunk['content'] as String?;
            if (chunkContent != null && chunkContent.isNotEmpty) {
              if (currentAssistantMessageId == null) {
                // 새 AI 메시지 생성
                currentAssistantMessageId = _generateMessageId();
                assistantContentChunks.clear();

                final newAssistantMessage = Message(
                  id: currentAssistantMessageId,
                  sessionId: session.id,
                  userId: userId,
                  content: [],
                  role: MessageRole.assistant,
                  timestamp: DateTime.now(),
                  extensions: chunk['metadata'],
                );

                // 세션에 새 AI 메시지 추가
                final updatedMessages = [
                  ...session.messages,
                  newAssistantMessage,
                ];
                session = session.copyWith(messages: updatedMessages);
                _updateSessionInHistory(session);

                debugPrint(
                  '[ConversationService2] 새 AI 메시지 생성: $currentAssistantMessageId',
                );
              }

              // 청크를 목록에 추가
              assistantContentChunks.add(chunkContent);

              // 기존 AI 메시지 업데이트
              final messageIndex = session.messages.indexWhere(
                (msg) => msg.id == currentAssistantMessageId,
              );

              if (messageIndex != -1) {
                final updatedMessage = session.messages[messageIndex].copyWith(
                  content: List<String>.from(assistantContentChunks),
                );

                final updatedMessages = List<Message>.from(session.messages);
                updatedMessages[messageIndex] = updatedMessage;
                session = session.copyWith(messages: updatedMessages);
                _updateSessionInHistory(session);

                debugPrint(
                  '[ConversationService2] AI 메시지 업데이트: ${assistantContentChunks.length}개 청크',
                );
              }
            }
            break;

          case 'tool_calls':
            // 도구 호출 메시지 추가
            final toolMessage = Message(
              id: _generateMessageId(),
              sessionId: session.id,
              userId: userId,
              content: ['도구 사용 중...'],
              role: MessageRole.tool,
              timestamp: DateTime.now(),
              extensions: {
                'messageType': 'tool_calls',
                'tool_calls': chunk['tool_calls'],
                ...?chunk['metadata'],
              },
            );

            final updatedMessages = [...session.messages, toolMessage];
            session = session.copyWith(messages: updatedMessages);
            _updateSessionInHistory(session);

            debugPrint('[ConversationService2] 도구 호출 메시지 추가');
            break;

          case 'toolmessage':
            // 도구 실행 결과 메시지 추가
            final toolResultMessage = Message(
              id: _generateMessageId(),
              sessionId: session.id,
              userId: userId,
              content: [chunk['content'] as String? ?? '도구 실행 완료'],
              role: MessageRole.tool,
              timestamp: DateTime.now(),
              extensions: {'messageType': 'toolmessage', ...?chunk['metadata']},
            );

            final updatedMessages = [...session.messages, toolResultMessage];
            session = session.copyWith(messages: updatedMessages);
            _updateSessionInHistory(session);

            debugPrint('[ConversationService2] 도구 결과 메시지 추가');
            break;

          case 'end':
            // 스트림 종료 - 컨텍스트 저장 완료
            debugPrint(
              '[ConversationService2] 스트림 종료, 컨텍스트 저장: ${chunk['context_saved']}',
            );
            break;

          case 'error':
            // 오류 발생
            debugPrint('[ConversationService2] 서버 오류: ${chunk['error']}');
            throw Exception(chunk['error']);

          default:
            debugPrint('[ConversationService2] 알 수 없는 청크 타입: $type');
            break;
        }
      }

      // 5. 전송 완료 후 대기 중인 메시지 클리어
      _historyService.clearPendingUserMessage();

      debugPrint('[ConversationService2] 메시지 전송 완료');
    } catch (e) {
      // 오류 발생 시 대기 중인 메시지 클리어
      _historyService.clearPendingUserMessage();

      debugPrint('[ConversationService2] 메시지 전송 오류: $e');
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
}
