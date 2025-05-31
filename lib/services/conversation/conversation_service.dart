import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../repositories/backend/backend_repository.dart';
import '../../repositories/backend/models/session.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/local_database/models/message_role.dart';
import '../../services/auth/auth_service.dart';

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();

  final BackendRepository _backendRepository = BackendRepository();
  final AuthService _authService = AuthService();

  factory ConversationService() => _instance;

  ConversationService._internal();

  /// 현재 사용자 정보를 가져오고 인증을 설정합니다.
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

  /// 새로운 대화 세션을 생성합니다.
  ///
  /// Seobi는 AI 음성 어시스턴트 앱이므로 기본적으로 모든 세션이 AI 채팅입니다.
  /// [type] 매개변수를 통해 향후 일정 관리나 인사이트 생성 세션도 지원합니다.
  Future<Session> createSession({SessionType type = SessionType.chat}) async {
    try {
      final userId = await _getUserIdAndAuthenticate();
      final session = await _backendRepository.postSession(userId);
      final updatedSession = session.copyWith(type: type);
      debugPrint(
        '새 ${type.toString().split('.').last} 세션이 생성되었습니다: ${updatedSession.id}',
      );
      return updatedSession;
    } catch (e) {
      debugPrint('세션 생성 오류: $e');
      rethrow;
    }
  }

  /// 메시지를 보내고 응답을 받습니다.
  ///
  /// [sessionId] 현재 대화 세션 ID
  /// [content] 사용자 메시지 내용
  /// 세션 타입에 따라 적절한 AI 응답을 처리합니다.
  Future<Message> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      final userId = await _getUserIdAndAuthenticate();

      // 사용자 메시지 생성 (저장은 백엔드에서 처리)
      final userMessage = Message(
        id: DateTime.now().toIso8601String(),
        sessionId: sessionId,
        userId: userId,
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      // 세션 정보를 가져와서 타입 확인
      final session = await _backendRepository.getSessionById(sessionId);

      // AI 채팅 세션이 아니면 사용자 메시지만 반환
      if (session.type != SessionType.chat) {
        return userMessage;
      }

      // AI 응답 생성 및 저장
      final StringBuffer buffer = StringBuffer();
      debugPrint('[ConversationService] AI 응답 스트리밍 시작');

      await for (final chunk in _backendRepository
          .postMessageLanggraphCompletionStream(
            sessionId: sessionId,
            userId: userId,
            content: content,
          )) {
        final chunkContent = Message.getContentFromChunk(chunk);
        if (chunkContent != null) {
          buffer.write(chunkContent);
          debugPrint('[ConversationService] 청크 수신: $chunkContent');
        }
      }

      final aiResponse = buffer.toString().trim();
      debugPrint('[ConversationService] AI 응답 완료: $aiResponse');

      if (aiResponse.isEmpty) {
        throw Exception('AI 응답이 비어있습니다.');
      }

      // AI 응답 메시지 생성 (저장은 백엔드에서 처리)
      return Message(
        id: DateTime.now().toIso8601String(),
        sessionId: sessionId,
        userId: 'assistant',
        content: aiResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConversationService] 메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 세션의 모든 메시지를 가져옵니다.
  Future<List<Message>> getSessionMessages(String sessionId) async {
    try {
      await _getUserIdAndAuthenticate();
      return await _backendRepository.getMessagesBySessionId(sessionId);
    } catch (e) {
      debugPrint('세션 메시지 조회 오류: $e');
      // 404 에러인 경우 빈 메시지 배열 반환
      if (e.toString().contains('404')) {
        return [];
      }
      rethrow;
    }
  }

  /// 대화 세션을 종료합니다.
  ///
  /// [sessionId] 종료할 세션의 ID
  Future<Session> endSession(String sessionId) async {
    try {
      await _getUserIdAndAuthenticate();
      final session = await _backendRepository.postSessionFinish(sessionId);

      debugPrint('세션이 종료되었습니다: $sessionId');
      return session;
    } catch (e) {
      debugPrint('세션 종료 오류: $e');
      rethrow;
    }
  }

  /// 사용자의 모든 세션을 가져옵니다.
  Future<List<Session>> getUserSessions() async {
    try {
      final userId = await _getUserIdAndAuthenticate();

      return await _backendRepository.getSessionsByUserId(userId);
    } catch (e) {
      debugPrint('사용자 세션 조회 오류: $e');
      rethrow;
    }
  }

  /// 스트리밍 방식으로 메시지를 전송하고 응답을 받습니다.
  ///
  /// [sessionId] 현재 대화 세션 ID
  /// [content] 사용자 메시지 내용
  /// [onProgress] 스트리밍 응답을 받을 때마다 호출되는 콜백
  /// [onToolUse] AI가 도구를 사용할 때 호출되는 콜백 (선택적)
  Future<Message> sendMessageStream({
    required String sessionId,
    required String content,
    required void Function(String partialResponse) onProgress,
    void Function(String toolName)? onToolUse,
    void Function()? onToolComplete,
  }) async {
    final StringBuffer buffer = StringBuffer();
    String? finalAnswer;

    try {
      final userId = await _getUserIdAndAuthenticate();
      debugPrint('[ConversationService] AI 응답 스트리밍 시작');

      await for (final chunk in _backendRepository
          .postMessageLanggraphCompletionStream(
            sessionId: sessionId,
            userId: userId,
            content: content,
          )) {
        try {
          final type = chunk['type'] as String;

          switch (type) {
            case 'start':
              debugPrint('[ConversationService] 스트리밍 시작');
              break;

            case 'tool_calls':
              // AI가 도구 사용 시작 - UI에 "검색 중..." 표시
              final toolCalls = chunk['tool_calls'] as List?;
              if (toolCalls?.isNotEmpty == true) {
                final toolName = toolCalls![0]['function']['name'] ?? '도구';
                debugPrint('[ConversationService] AI 도구 사용: $toolName');
                onToolUse?.call(toolName);
              }
              break;

            case 'toolmessage':
              // 도구 실행 완료 - UI에 "검색 완료" 표시
              debugPrint('[ConversationService] 도구 실행 완료');
              onToolComplete?.call();
              break;

            case 'chunk':
              final chunkContent = chunk['content'] as String;
              if (chunkContent.isNotEmpty) {
                buffer.write(chunkContent);
                onProgress(buffer.toString()); // 누적된 전체 텍스트 전달
                debugPrint('[ConversationService] 청크 처리: $chunkContent');
              }
              break;

            case 'answer':
              finalAnswer = chunk['answer'] as String;
              debugPrint('[ConversationService] 전체 응답 수신: $finalAnswer');
              break;

            case 'end':
              debugPrint('[ConversationService] 스트리밍 종료');
              break;

            default:
              debugPrint('[ConversationService] 알 수 없는 청크 타입: $type');
              break;
          }
        } catch (e) {
          debugPrint('[ConversationService] 청크 처리 오류: $e');
          continue;
        }
      }

      final aiResponse = buffer.toString().trim();
      debugPrint('[ConversationService] 최종 응답: $aiResponse');

      if (aiResponse.isEmpty && finalAnswer == null) {
        throw Exception('AI 응답이 비어있습니다.');
      }

      return Message(
        id: DateTime.now().toIso8601String(),
        sessionId: sessionId,
        userId: 'assistant',
        content: finalAnswer ?? aiResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConversationService] 스트리밍 오류: $e');
      rethrow;
    }
  }
}
