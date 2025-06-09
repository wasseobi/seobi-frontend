import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/services/tts/tts_service.dart';

/// SSE(Server-Sent Events) 이벤트를 처리하는 핸들러
class SseHandler {
  final HistoryService _historyService;
  // TTS 서비스를 직접 생성
  final TtsService _ttsService = TtsService();

  // 현재 처리 중인 메시지의 ID
  String? _currentMessageId;
  // 현재 처리 중인 메시지 타입
  String? _currentMessageType; // Tool Call의 인자들을 누적하는 맵 (인덱스 -> 누적된 인자 문자열)
  final Map<int, String> _toolCallArguments = {};
  // Tool Call ID와 Message ID 매핑
  final Map<String, String> _toolCallIdToMessageId = {};
  // 인덱스와 Message ID 매핑 (index -> messageId)
  final Map<int, String> _indexToMessageId = {};

  // 생성자 - History Service만 주입받음
  SseHandler(this._historyService);

  /// SSE 이벤트 데이터를 처리하는 메서드
  void handleEvent(dynamic data, String sessionId, String userId) {
    final type = data['type'] as String;

    switch (type) {
      case 'user':
        _handleUserMessage(data, sessionId, userId);
      case 'tool_calls':
        _handleToolCallsMessage(data, sessionId);
      case 'toolmessage':
        final toolResults = data['content'] as String;
        _handleToolResultMessage(
          toolResults,
          data['metadata']?['tool_call_id'] as String?,
          sessionId,
        );
      case 'chunk':
        _handleChunkMessage(data, sessionId);
      case 'error':
        _handleErrorMessage(data['error'] as String);
      case 'done':
        _handleEndEvent();
    }
  }

  void _handleUserMessage(
    Map<String, dynamic> data,
    String sessionId,
    String userId,
  ) {
    final content = data['content'] as String;
    final message = Message(
      id:
          data['metadata']?['message_id'] as String? ??
          'msg_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      type: MessageType.user,
      content: content,
      timestamp: DateTime.now(),
    );
    _historyService.clearPendingUserMessage();
    _historyService.addMessageToSession(message);
  }

  void _handleToolCallsMessage(Map<String, dynamic> data, String sessionId) {
    debugPrint('[SseHandler] 도구 호출 메시지 처리 시작');
    final toolCalls = data['tool_calls'] as List<dynamic>;
    String? lastMessageId;

    debugPrint('[SseHandler] 도구 호출 데이터: calls=${toolCalls.length}개');

    for (final toolCall in toolCalls) {
      final toolCallId = toolCall['id'] as String?;
      final index = toolCall['index'] as int;
      final function = toolCall['function'] as Map<String, dynamic>?;
      if (function == null) continue;
      final name = function['name'] as String?;
      final args = function['arguments'] as String? ?? '';

      debugPrint(
        '[SseHandler] 도구 호출 정보: id=$toolCallId, index=$index, name=$name',
      );

      if (toolCallId != null && name != null) {
        debugPrint('[SseHandler] 새로운 도구 호출 메시지 생성');
        // 새로운 tool call 시작
        final messageId = 'tool_${DateTime.now().millisecondsSinceEpoch}';
        final message = Message(
          id: messageId,
          sessionId: sessionId,
          type: MessageType.tool_call,
          title: name,
          content: '''### 도구 호출
```json
$args
```''',
          timestamp: DateTime.now(),
        );

        _historyService.addMessageToSession(message);
        _toolCallIdToMessageId[toolCallId] = messageId;
        _toolCallArguments[index] = args;
        _indexToMessageId[index] = messageId; // 인덱스를 메시지 ID에 매핑
        lastMessageId = messageId;
      } else {
        // 기존 tool call의 후속 청크
        _toolCallArguments[index] = (_toolCallArguments[index] ?? '') + args;

        // 인덱스 기반으로 메시지 ID를 찾음
        String? messageId = _indexToMessageId[index];

        // 인덱스에 매핑된 ID가 없으면 다른 방법으로 시도
        messageId ??=
            toolCallId != null
                ? _toolCallIdToMessageId[toolCallId]
                : lastMessageId ?? _currentMessageId;

        if (messageId == null) continue;

        final message = _historyService.getMessageById(messageId);
        if (message == null) continue; // 모든 인자를 하나의 문자열로 결합
        final allArguments =
            _toolCallArguments.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
        final content = allArguments.map((e) => e.value).join('');

        // 포맷팅된 내용으로 메시지 업데이트
        final formattedContent = '''### 도구 호출
```json
$content
```''';

        _historyService.updateMessageInSession(
          Message(
            id: message.id,
            sessionId: message.sessionId,
            type: MessageType.tool_call,
            title: message.title,
            content: formattedContent,
            timestamp: message.timestamp,
          ),
        );
      }
    }

    // 현재 메시지 컨텍스트 업데이트F
    _currentMessageType = 'tool_calls';
    _currentMessageId = lastMessageId;
  }

  void _handleToolResultMessage(
    dynamic toolResults,
    String? toolCallId,
    String sessionId,
  ) {
    debugPrint('[SseHandler] 도구 실행 결과 처리 시작: toolCallId=$toolCallId');
    if (toolCallId == null) return;

    final messageId = _toolCallIdToMessageId[toolCallId];
    debugPrint('[SseHandler] 도구 호출 메시지 ID 조회: messageId=$messageId');
    if (messageId == null) return;

    final message = _historyService.getMessageById(messageId);
    debugPrint(
      '[SseHandler] 원본 메시지 조회: messageId=$messageId, type=${message?.type}',
    );
    if (message == null) return;

    // 결과가 JSON 문자열이 아닌 경우 (객체나 리스트인 경우) 처리
    String formattedResults;
    if (toolResults is String) {
      formattedResults = toolResults;
    } else {
      try {
        // Maps와 Lists를 포맷팅하여 가독성 좋게 표시
        formattedResults = const JsonEncoder.withIndent(
          '  ',
        ).convert(toolResults);
      } catch (e) {
        debugPrint('[SseHandler] JSON 인코딩 실패: $e');
        formattedResults = toolResults.toString();
      }
    }

    // 마크다운 형식에 맞게 결과 포맷팅
    String codeBlock;
    if (formattedResults.trim().startsWith('{') ||
        formattedResults.trim().startsWith('[')) {
      codeBlock = '```json\n$formattedResults\n```';
    } else {
      // 일반 텍스트인 경우 코드 블록 없이 표시
      codeBlock = formattedResults;
    }

    final updatedContent = '''${message.content}
### 도구 실행 결과
$codeBlock''';

    _historyService.updateMessageInSession(
      Message(
        id: message.id,
        sessionId: message.sessionId,
        type: MessageType.tool_result,
        title: message.title,
        content: updatedContent,
        timestamp: message.timestamp,
      ),
    );
  }

  void _handleChunkMessage(Map<String, dynamic> data, String sessionId) {
    final content = data['content'] as String;

    if (_currentMessageType != 'chunk') {
      // 새로운 assistant 메시지 시작
      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        type: MessageType.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

      _historyService.addMessageToSession(message);
      _currentMessageId = message.id;
      _currentMessageType = 'chunk';
    } else {
      // 기존 메시지에 청크 추가
      final message = _historyService.getMessageById(_currentMessageId!);
      if (message == null) return;

      _historyService.updateMessageInSession(
        Message(
          id: message.id,
          sessionId: message.sessionId,
          type: message.type,
          title: message.title,
          content: message.content + content,
          timestamp: message.timestamp,
        ),
      );
    }
    // TTS가 활성화되어 있다면, 각 청크를 TTS 서비스에 전송
    debugPrint('[SseHandler] 청크를 TTS 서비스에 전송: "$content"');
    _ttsService.addToken(content);
  }

  // ========================================

  void _handleErrorMessage(String error) {
    // 항상 새로운 오류 메시지 생성
    final errorContent = '''### 오류 발생
```
$error
```''';

    _historyService.addMessageToSession(
      Message(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        sessionId:
            _currentMessageId != null
                ? _historyService
                        .getMessageById(_currentMessageId!)
                        ?.sessionId ??
                    ''
                : '',
        type: MessageType.error,
        title: '오류',
        content: errorContent,
        timestamp: DateTime.now(),
      ),
    );

    // 컨텍스트 초기화
    _currentMessageId = null;
    _currentMessageType = null;
  }

  void _handleEndEvent() {
    // TTS가 활성화되어 있다면, 종료 시점에 토큰 큐를 비우고 남은 텍스트 모두 재생
    debugPrint('[SseHandler] 응답 종료: 남은 토큰 모두 TTS로 전송');
    _ttsService.flush();

    _currentMessageId = null;
    _currentMessageType = null;
    _toolCallArguments.clear();
    _toolCallIdToMessageId.clear();
    _indexToMessageId.clear();
  }
}
