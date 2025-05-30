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

      await for (final chunk in _backendRepository
          .postMessageLanggraphCompletionStream(
            sessionId: sessionId,
            userId: userId,
            content: content,
          )) {
        final chunkContent = Message.getContentFromChunk(chunk);
        if (chunkContent != null) {
          buffer.write(chunkContent);
        }
      }

      final aiResponse = buffer.toString().trim();
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
      debugPrint('메시지 전송 오류: $e');
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
      if (e.toString().contains('404')) {
        return [];
      }
      debugPrint('세션 메시지 조회 오류: $e');
      rethrow;
    }
  }

  /// 대화 세션을 종료합니다.
  ///
  /// [sessionId] 종료할 세션의 ID
  Future<Session> endSession(String sessionId) async {
    try {
      await _getUserIdAndAuthenticate();
      return await _backendRepository.postSessionFinish(sessionId);
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

      final StringBuffer buffer = StringBuffer();
      String accumulatedArguments = '';
      bool toolCallsInProgress = false;
      bool searchExecuted = false;

      await for (final chunk in _backendRepository
          .postMessageLanggraphCompletionStream(
            sessionId: sessionId,
            userId: userId,
            content: content,
          )) {
        try {
          final type = chunk['type'] as String;

          switch (type) {
            case 'tool_calls':
              final toolCalls = chunk['tool_calls'] as List<dynamic>;
              if (toolCalls.isNotEmpty) {
                final toolCall = toolCalls[0];
                final function = toolCall['function'] as Map<String, dynamic>;
                final toolName = function['name'] as String?;
                final arguments = function['arguments'] as String?;

                if (toolName == 'search_web') {
                  searchExecuted = true;
                }

                if (arguments != null) {
                  accumulatedArguments += arguments;
                }

                if (toolName != null && !toolCallsInProgress) {
                  if (toolName == 'search_web') {
                    String message = '🔍 웹 검색을 시작합니다';
                    onProgress(message);
                    toolCallsInProgress = true;
                  } else {
                    final message = '🛠️ $toolName 도구를 실행 중...';
                    onProgress(message);
                    toolCallsInProgress = true;
                  }
                }

                if (toolCallsInProgress &&
                    toolName == 'search_web' &&
                    accumulatedArguments.isNotEmpty &&
                    _isValidJson(accumulatedArguments)) {
                  try {
                    final argMap =
                        json.decode(accumulatedArguments)
                            as Map<String, dynamic>;
                    final query = argMap['query'] as String?;
                    if (query != null && query.isNotEmpty) {
                      final message = '🔍 "$query" 검색 중...';
                      onProgress(message);
                    }
                  } catch (e) {
                    debugPrint('arguments 파싱 오류: $e');
                  }
                }
              }
              break;

            case 'toolmessage':
              final searchContent = chunk['content'] as String;
              toolCallsInProgress = false;
              accumulatedArguments = '';

              if (searchContent.isNotEmpty) {
                final results = _extractSearchResults(searchContent);
                if (results != null && results.isNotEmpty) {
                  final resultCount =
                      results
                          .split('\n')
                          .where((line) => line.trim().isNotEmpty)
                          .length;
                  final message =
                      '✅ $resultCount개의 검색 결과를 찾았습니다.\n\n서비가 답변을 준비 중...';
                  onProgress(message);
                } else {
                  if (searchContent.length > 50) {
                    final message = '✅ 검색 결과를 찾았습니다.\n\n서비가 답변을 준비 중...';
                    onProgress(message);
                  } else {
                    final message = '⚠️ 검색 결과를 처리하고 있습니다...';
                    onProgress(message);
                  }
                }
              } else {
                final message = '⚠️ 검색을 다시 시도하고 있습니다...';
                onProgress(message);
              }
              break;

            case 'chunk':
              final chunkContent = chunk['content'] as String;
              if (chunkContent.isNotEmpty) {
                // 원본 텍스트는 표시용으로 사용
                buffer.write(chunkContent);
                final currentResponse = buffer.toString();
                onProgress(currentResponse);

                if (enableTts) {
                  // 첫 번째 실제 콘텐츠 청크에서 인터럽트 해제
                  if (_ttsService.isInterrupted &&
                      chunkContent.trim().isNotEmpty) {
                    debugPrint(
                      '[ConversationService] 첫 번째 콘텐츠 청크 - TTS 인터럽트 해제',
                    );
                    await _ttsService.resumeAfterInterrupt();
                  }

                  // 스트리밍 텍스트 처리 (원본 텍스트 사용, 정리는 TTS에서 처리)
                  await _ttsService.addStreamingText(chunkContent);
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
          }
        } catch (e) {
          debugPrint('청크 처리 오류: $e');
          continue;
        }
      }

      // 스트리밍 완료 후 TTS 버퍼 정리
      if (enableTts) {
        await _ttsService.flushStreamBuffer();
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
      debugPrint('스트리밍 오류: $e');

      // 오류 발생 시에도 TTS 버퍼 정리
      if (enableTts) {
        try {
          await _ttsService.flushStreamBuffer();
        } catch (ttsError) {
          debugPrint('TTS 버퍼 정리 오류: $ttsError');
        }
      }

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

        final truncatedContent =
            content.length > 200 ? '${content.substring(0, 200)}...' : content;

        formatted.writeln('${i + 1}. $title');
        formatted.writeln('$truncatedContent\n');
      }

      return formatted.toString();
    } catch (e) {
      debugPrint('검색 결과 추출 오류: $e');
      return null;
    }
  }

  List<dynamic> _parseSearchResults(String content) {
    try {
      try {
        final results = json.decode(content) as List<dynamic>;
        return results;
      } catch (e) {
        // 표준 JSON 파싱 실패 시 Python 형태 파싱 시도
      }

      String jsonContent = content.trim();
      jsonContent = _cleanUnicodeEscapes(jsonContent);
      jsonContent = _convertPythonToJson(jsonContent);

      final results = json.decode(jsonContent) as List<dynamic>;
      return results;
    } catch (e) {
      debugPrint('검색 결과 파싱 오류: $e');
      return [];
    }
  }

  String _cleanUnicodeEscapes(String content) {
    content = content.replaceAll(r'\xa0', ' ');
    content = content.replaceAll(r'\x20', ' ');
    content = content.replaceAll(r'\x09', '\t');
    content = content.replaceAll(r'\x0a', '\n');
    content = content.replaceAll(r'\x0d', '\r');
    return content;
  }

  String _convertPythonToJson(String content) {
    content = content
        .replaceAll("'", '"')
        .replaceAll('True', 'true')
        .replaceAll('False', 'false')
        .replaceAll('None', 'null');
    return content;
  }

  bool _isValidJson(String content) {
    try {
      json.decode(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}
