import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../repositories/backend/backend_repository.dart';
import '../../repositories/backend/models/session.dart';
import '../../repositories/backend/models/message.dart';
import '../../services/auth/auth_service.dart';
import '../tts/tts_service.dart';
import 'dart:convert';
import 'dart:math' as math;

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();

  final BackendRepository _backendRepository = BackendRepository();
  final AuthService _authService = AuthService();
  final TtsService _ttsService = TtsService();

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
  /// [title]과 [description]은 선택적 매개변수입니다.
  Future<Session> createSession({bool isAIChat = false}) async {
    try {
      final userId = await _getUserIdAndAuthenticate();
      final session = await _backendRepository.postSession(userId);
      session.isAiChat = isAIChat;
      debugPrint('새 ${isAIChat ? 'AI 채팅' : ''} 세션이 생성되었습니다: ${session.id}');
      return session;
    } catch (e) {
      debugPrint('세션 생성 오류: $e');
      rethrow;
    }
  }

  /// 메시지를 보내고 응답을 받습니다.
  ///
  /// [sessionId] 현재 대화 세션 ID
  /// [content] 사용자 메시지 내용
  /// [isAIChat] AI 채팅 여부
  Future<Message> sendMessage({
    required String sessionId,
    required String content,
    bool isAIChat = false,
  }) async {
    try {
      final userId = await _getUserIdAndAuthenticate();

      // 사용자 메시지 생성 (저장은 백엔드에서 처리)
      final userMessage = Message(
        id: DateTime.now().toIso8601String(),
        sessionId: sessionId,
        userId: userId,
        content: content,
        role: Message.ROLE_USER,
        timestamp: DateTime.now(),
      );

      if (!isAIChat) {
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
        role: Message.ROLE_ASSISTANT,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConversationService] 메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 세션의 모든 메시지를 가져옵니다.
  Future<List<Message>> getSessionMessages(
    String sessionId, {
    bool isAIChat = false,
  }) async {
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
  Future<Message> sendMessageStream({
    required String sessionId,
    required String content,
    required void Function(String partialResponse) onProgress,
    bool enableTts = true,
  }) async {
    try {
      final userId = await _getUserIdAndAuthenticate();
      debugPrint('[ConversationService] AI 응답 스트리밍 시작: $content');

      // TTS 서비스에 새로운 메시지 대기 상태 설정
      if (enableTts) {
        _ttsService.setWaitingForNewMessage();
      }

      final StringBuffer buffer = StringBuffer();

      await for (final chunk in _backendRepository
          .postMessageLanggraphCompletionStream(
            sessionId: sessionId,
            userId: userId,
            content: content,
          )) {
        try {
          final type = chunk['type'] as String;
          debugPrint('[ConversationService] 청크 타입: $type');

          switch (type) {
            case 'tool_calls':
              final toolCalls = chunk['tool_calls'] as List<dynamic>;
              if (toolCalls.isNotEmpty) {
                final toolCall = toolCalls[0];
                final function = toolCall['function'] as Map<String, dynamic>;
                final toolName = function['name'] as String?;

                if (toolName == 'search_web') {
                  final message = '검색 도구를 실행합니다...';
                  onProgress(message);
                  if (enableTts) {
                    await _ttsService.handleNewMessage(message);
                  }
                }
              }
              break;

            case 'toolmessage':
              final searchContent = chunk['content'] as String;
              final results = _extractSearchResults(searchContent);
              if (results != null && results.isNotEmpty) {
                final message = '검색 결과:\n\n$results\n\nAI가 분석을 시작합니다...';
                onProgress(message);
                if (enableTts) {
                  await _ttsService.handleNewMessage(message);
                }
              }
              break;

            case 'chunk':
              final chunkContent = chunk['content'] as String;
              if (chunkContent.isNotEmpty) {
                buffer.write(chunkContent);
                final currentResponse = buffer.toString();
                onProgress(currentResponse);
                if (enableTts && _ttsService.isWaitingForNewMessage()) {
                  await _ttsService.handleNewMessage(currentResponse);
                }
              }
              break;

            case 'answer':
              final answer = chunk['content'] as String;
              if (answer.isNotEmpty) {
                onProgress(answer);
                if (enableTts) {
                  await _ttsService.handleNewMessage(answer);
                }
              }
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

      final response = buffer.toString().trim();
      if (response.isEmpty) {
        throw Exception('AI 응답이 비어있습니다.');
      }

      return Message(
        id: DateTime.now().toIso8601String(),
        sessionId: sessionId,
        userId: 'assistant',
        content: response,
        role: Message.ROLE_ASSISTANT,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ConversationService] 스트리밍 오류: $e');
      rethrow;
    }
  }

  String? _extractSearchResults(String content) {
    try {
      final List<dynamic> results = _parseSearchResults(content);
      if (results.isEmpty) return null;

      final StringBuffer formatted = StringBuffer();
      for (var i = 0; i < math.min(2, results.length); i++) {
        final result = results[i];
        final title = result['title'] as String;
        final content = result['content'] as String;

        // 제목과 내용의 길이를 제한하여 표시
        final truncatedContent =
            content.length > 200 ? '${content.substring(0, 200)}...' : content;

        formatted.writeln('${i + 1}. $title');
        formatted.writeln('$truncatedContent\n');
      }

      return formatted.toString();
    } catch (e) {
      debugPrint('[ConversationService] 검색 결과 추출 오류: $e');
      return null;
    }
  }

  List<dynamic> _parseSearchResults(String content) {
    try {
      // 문자열을 List<Map>으로 파싱
      final results = json.decode(content) as List<dynamic>;
      return results;
    } catch (e) {
      debugPrint('[ConversationService] JSON 파싱 오류: $e');
      return [];
    }
  }
}
