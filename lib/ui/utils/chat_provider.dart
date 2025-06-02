import 'package:flutter/material.dart';
import 'dart:async';
import '../../repositories/backend/models/message.dart';
import '../../repositories/local_database/models/message_role.dart';
import '../../services/conversation/conversation_service.dart';
import '../../services/tts/tts_service.dart';
import '../components/messages/assistant/message_types.dart';

/// 채팅 상태를 관리하는 Provider
///
/// Message 모델과 UI 간의 데이터 변환을 담당하며,
/// ConversationService를 통해 실제 AI 대화를 처리합니다.
/// InputBarViewModel과 연결하여 메시지 전송 이벤트를 처리합니다.
class ChatProvider extends ChangeNotifier {
  final ConversationService _conversationService;
  final TtsService _ttsService;

  // ========================================
  // 상태 변수들
  // ========================================

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  // 글로벌 메시지 전송 핸들러 (정적 방법)
  static ChatProvider? _globalInstance;

  // ========================================
  // 생성자
  // ========================================

  ChatProvider({
    ConversationService? conversationService,
    TtsService? ttsService,
  }) : _conversationService = conversationService ?? ConversationService(),
       _ttsService = ttsService ?? TtsService() {
    debugPrint('[ChatProvider] 🎯 ChatProvider 초기화 완료!');
    debugPrint(
      '[ChatProvider] 🎯 ConversationService: ${_conversationService.runtimeType}',
    );
    debugPrint('[ChatProvider] 🎯 TtsService: ${_ttsService.runtimeType}');
    // 글로벌 인스턴스로 설정
    _globalInstance = this;
  }

  // ========================================
  // 글로벌 메시지 전송 핸들러
  // ========================================

  /// 전역에서 접근 가능한 메시지 전송 메서드
  static void sendGlobalMessage(String message) {
    debugPrint('[ChatProvider] 🌍 전역 메시지 수신: "$message"');
    if (_globalInstance != null) {
      debugPrint('[ChatProvider] 🌍 글로벌 인스턴스로 메시지 전달');
      _globalInstance!.sendMessage(message);
    } else {
      debugPrint('[ChatProvider] ❌ 글로벌 인스턴스가 없음!');
    }
  }

  // ========================================
  // Getter들 (UI에서 구독)
  // ========================================

  /// UI에서 사용할 메시지 목록 (Map 형태로 변환됨)
  List<Map<String, dynamic>> get messages =>
      _messages.map(_messageToUIFormat).toList();

  /// 현재 로딩 상태
  bool get isLoading => _isLoading;

  /// 현재 에러 메시지
  String? get error => _error;

  /// 메시지 개수
  int get messageCount => _messages.length;

  /// 현재 세션 ID
  String? get currentSessionId => _currentSessionId;

  /// 대화가 진행 중인지 확인
  bool get hasMessages => _messages.isNotEmpty;

  /// 도구 메시지만 필터링한 목록 (UI용)
  List<Map<String, dynamic>> get toolMessages {
    return _messages
        .where((msg) => msg.extensions?['isToolMessage'] == true)
        .map(_messageToUIFormat)
        .toList();
  }

  /// LLM 응답 메시지만 필터링한 목록 (UI용)
  List<Map<String, dynamic>> get llmResponseMessages {
    return _messages
        .where((msg) => msg.extensions?['messageType'] == 'llm_response')
        .map(_messageToUIFormat)
        .toList();
  }

  /// 최근 사용된 도구 이름 목록 (UI용)
  List<String> get recentToolNames => getRecentlyUsedTools();

  // ========================================
  // 핵심 기능들
  // ========================================

  /// 사용자 메시지 전송 및 AI 응답 요청
  Future<void> sendMessage(String text) async {
    debugPrint('[ChatProvider] 🚀 ===== SEND MESSAGE 시작 ===== "$text"');

    if (text.trim().isEmpty) {
      debugPrint('[ChatProvider] 빈 메시지는 전송할 수 없습니다');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[ChatProvider] 메시지 전송 시작: "$text"');

      // **즉시 TTS 중단 (가장 먼저 실행)**
      debugPrint('[ChatProvider] ===== TTS STOP 호출 직전 =====');
      await _ttsService.stop();
      debugPrint('[ChatProvider] 새 메시지 전송으로 인한 TTS 즉시 중단 완료');
      debugPrint('[ChatProvider] ===== TTS STOP 호출 완료 =====');

      // 세션이 없으면 새로 생성
      if (_currentSessionId == null) {
        debugPrint('[ChatProvider] 새 세션 생성 중...');
        final session = await _conversationService.createSession();
        _currentSessionId = session.id;
        debugPrint('[ChatProvider] 새 세션 생성 완료: $_currentSessionId');
      }

      // 1. 사용자 메시지 즉시 추가
      final userMessage = Message(
        id: _generateMessageId(),
        sessionId: _currentSessionId!,
        content: text,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      _addMessage(userMessage);

      // 2. 스트리밍 응답 처리 - 각 타입별로 별도 메시지 생성
      String? toolCallMessageId; // 도구 호출 메시지 ID
      String? toolResponseMessageId; // 도구 응답 메시지 ID
      String? llmResponseMessageId; // LLM 응답 메시지 ID

      // 중복 도구 호출 방지를 위한 플래그
      bool hasToolCallMessage = false;
      String? lastToolName; // 마지막 도구명 추적

      debugPrint('[ChatProvider] AI 응답 스트리밍 시작...');
      final aiResponse = await _conversationService.sendMessageStream(
        sessionId: _currentSessionId!,
        content: text,
        onProgress: (partialResponse) {
          // **LLM 응답 메시지 생성 및 업데이트**
          if (llmResponseMessageId == null) {
            // 첫 번째 청크일 때 LLM 응답 메시지 생성
            llmResponseMessageId = _generateMessageId();
            final llmResponseMessage = Message(
              id: llmResponseMessageId!,
              sessionId: _currentSessionId!,
              content: partialResponse,
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
              extensions: {'messageType': 'llm_response'},
            );
            _addMessage(llmResponseMessage);
            debugPrint(
              '[ChatProvider] 📝 LLM 응답 메시지 생성: ${partialResponse.length}자',
            );
          } else {
            // 기존 LLM 응답 메시지 업데이트
            final index = _messages.indexWhere(
              (msg) => msg.id == llmResponseMessageId,
            );
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                content: partialResponse,
              );
              notifyListeners();
              debugPrint(
                '[ChatProvider] 📝 LLM 응답 업데이트: ${partialResponse.length}자',
              );
            }
          }
        },
        onToolUse: (toolName) {
          debugPrint('[ChatProvider] 🔧 AI 도구 사용 신호 수신: "$toolName"');

          // **중복 도구 호출 메시지 생성 방지**
          if (hasToolCallMessage && lastToolName == toolName) {
            debugPrint('[ChatProvider] ⚠️ 중복 도구 호출 메시지 생성 방지: $toolName');
            return;
          }

          // **도구명 정리 및 검증**
          final cleanedToolName = toolName.trim();
          if (cleanedToolName.isEmpty ||
              cleanedToolName == 'null' ||
              cleanedToolName == '도구' ||
              cleanedToolName == '알 수 없는 도구' ||
              cleanedToolName.length < 3) {
            // 너무 짧은 도구명 제외
            debugPrint('[ChatProvider] ⚠️ 유효하지 않은 도구명 무시: "$toolName"');
            return;
          }

          // **도구 호출 메시지 생성 (별도 메시지)**
          toolCallMessageId = _generateMessageId();
          final toolCallMessage = Message(
            id: toolCallMessageId!,
            sessionId: _currentSessionId!,
            content: _getToolCallMessage(cleanedToolName),
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            extensions: {
              'messageType': 'tool_call',
              'toolName': cleanedToolName,
              'isToolMessage': true,
            },
          );
          _addMessage(toolCallMessage);

          // 플래그 설정
          hasToolCallMessage = true;
          lastToolName = cleanedToolName;

          debugPrint('[ChatProvider] ✅ 도구 호출 메시지 생성 완료: $cleanedToolName');
        },
        onToolComplete: () {
          debugPrint('[ChatProvider] ✅ AI 도구 사용 완료');

          // **도구 응답 메시지 생성 (한 번만)**
          if (toolResponseMessageId == null) {
            toolResponseMessageId = _generateMessageId();
            final toolResponseMessage = Message(
              id: toolResponseMessageId!,
              sessionId: _currentSessionId!,
              content: '✅ 도구 실행이 완료되었습니다. 답변을 생성하는 중입니다...',
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
              extensions: {
                'messageType': 'tool_response',
                'isToolMessage': true,
              },
            );
            _addMessage(toolResponseMessage);
            debugPrint('[ChatProvider] ✅ 도구 응답 메시지 생성 완료');
          } else {
            debugPrint('[ChatProvider] ⚠️ 도구 응답 메시지 이미 존재함 - 중복 생성 방지');
          }
        },
      );

      // 3. **AI 응답 완료 후 TTS 처리**
      if (aiResponse.content != null && aiResponse.content!.isNotEmpty) {
        final finalContent = aiResponse.content!.trim();
        debugPrint(
          '[ChatProvider] 🎤 AI 응답 완료 - 즉시 TTS 시작: ${finalContent.length}자',
        );
        _processTtsInBackground(finalContent);
      }

      debugPrint('[ChatProvider] AI 응답 완료: "${aiResponse.contentPreview}"');

      // **도구 사용 현황 분석 (디버깅용)**
      analyzeToolMessages();
      final usedTools = getRecentlyUsedTools();
      if (usedTools.isNotEmpty) {
        debugPrint('[ChatProvider] 🔧 이번 대화에서 사용된 도구들: $usedTools');
      } else {
        debugPrint('[ChatProvider] 🔧 이번 대화에서 도구가 사용되지 않았습니다.');
      }
    } catch (e) {
      _setError('메시지 전송 실패: $e');
      debugPrint('[ChatProvider] 메시지 전송 오류: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 메시지 목록 지우기 (새 대화 시작)
  void clearMessages() {
    _messages.clear();
    _currentSessionId = null;
    _clearError();
    debugPrint('[ChatProvider] 메시지 목록 초기화');
    notifyListeners();
  }

  /// 특정 메시지 삭제
  void removeMessage(String messageId) {
    final originalLength = _messages.length;
    _messages.removeWhere((message) => message.id == messageId);

    if (_messages.length != originalLength) {
      debugPrint('[ChatProvider] 메시지 삭제: $messageId');
      notifyListeners();
    }
  }

  /// 샘플 메시지들로 초기화 (테스트용)
  void loadSampleMessages() {
    _messages.clear();
    // 실제 세션 생성은 첫 메시지 전송 시에만 수행
    _currentSessionId = null;

    // 샘플 메시지들 생성 (임시 세션 ID 사용)
    final sampleMessages = _generateSampleMessages();
    _messages.addAll(sampleMessages);

    debugPrint('[ChatProvider] ${sampleMessages.length}개 샘플 메시지 로드 (세션 미생성)');
    notifyListeners();
  }

  /// 외부에서 생성된 UI 형태의 메시지 리스트를 설정
  /// (home_screen에서 생성된 샘플 메시지 사용)
  void setMessages(List<Map<String, dynamic>> uiMessages) {
    _messages.clear();
    _currentSessionId = null; // 실제 메시지 전송 시 백엔드에서 새 세션 생성

    // UI 형태의 메시지를 Message 객체로 변환
    for (final uiMessage in uiMessages) {
      final message = _uiFormatToMessage(uiMessage);
      _messages.add(message);
    }

    debugPrint('[ChatProvider] ${uiMessages.length}개 메시지 설정 완료 (세션 미생성)');
    notifyListeners();
  }

  // ========================================
  // 내부 헬퍼 메서드들
  // ========================================

  /// Message 객체를 UI에서 사용하는 Map 형태로 변환
  Map<String, dynamic> _messageToUIFormat(Message message) {
    // 새로운 메시지 타입 확인
    final messageTypeFromExtensions =
        message.extensions?['messageType'] as String?;
    final isToolMessage =
        message.extensions?['isToolMessage'] as bool? ?? false;

    return {
      'isUser': message.role == MessageRole.user,
      'text': message.content ?? '',
      'messageType': _extractMessageType(message),
      'timestamp': message.formattedTimestamp,
      'actions': message.extensions?['actions'],
      'card': message.extensions?['card'],
      // 추가 정보들
      'id': message.id,
      'sessionId': message.sessionId,
      // 새로운 메시지 타입 정보 추가
      'messageSubType':
          messageTypeFromExtensions, // tool_call, tool_response, llm_response 등
      'isToolMessage': isToolMessage,
      'toolName': message.extensions?['toolName'],
    };
  }

  /// Message에서 MessageType enum 추출
  MessageType _extractMessageType(Message message) {
    final typeString = message.extensions?['messageType'] as String?;

    switch (typeString) {
      case 'text':
        return MessageType.text;
      case 'action':
        return MessageType.action;
      case 'card':
        return MessageType.card;
      default:
        return MessageType.text; // 기본값
    }
  }

  /// UI Map 형태를 Message 객체로 변환
  Message _uiFormatToMessage(Map<String, dynamic> uiMessage) {
    final isUser = uiMessage['isUser'] as bool? ?? false;
    final text = uiMessage['text'] as String? ?? '';
    final messageType =
        uiMessage['messageType'] as MessageType? ?? MessageType.text;

    // timestamp 문자열을 DateTime으로 파싱 (간단하게 현재 시간 사용)
    final parsedTimestamp = DateTime.now().subtract(
      Duration(minutes: _messages.length), // 기존 메시지 수만큼 이전 시간
    );

    // extensions 생성
    final extensions = <String, dynamic>{
      'messageType': messageType.toString().split('.').last,
    };

    // actions가 있으면 추가
    if (uiMessage.containsKey('actions')) {
      extensions['actions'] = uiMessage['actions'];
    }

    // card가 있으면 추가
    if (uiMessage.containsKey('card')) {
      extensions['card'] = uiMessage['card'];
    }

    return Message(
      id: _generateMessageId(),
      sessionId:
          'temp_session_${DateTime.now().millisecondsSinceEpoch}', // 임시 세션 ID (실제 전송 시 변경됨)
      content: text,
      role: isUser ? MessageRole.user : MessageRole.assistant,
      timestamp: parsedTimestamp,
      extensions: extensions,
    );
  }

  /// 새 메시지 추가 및 UI 업데이트
  void _addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
    debugPrint('[ChatProvider] 메시지 추가: ${message.contentPreview}');
  }

  /// 로딩 상태 변경
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      debugPrint('[ChatProvider] 로딩 상태: $loading');
    }
  }

  /// 에러 상태 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
    debugPrint('[ChatProvider] 에러 설정: $error');
  }

  /// 에러 상태 지우기
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
      debugPrint('[ChatProvider] 에러 상태 클리어');
    }
  }

  /// 고유한 메시지 ID 생성
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';
  }

  /// 고유한 세션 ID 생성
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ========================================
  // 샘플 데이터 생성 (테스트용)
  // ========================================

  /// 테스트용 샘플 메시지들 생성
  List<Message> _generateSampleMessages() {
    final now = DateTime.now();
    final tempSessionId =
        'sample_session_${DateTime.now().millisecondsSinceEpoch}'; // 임시 세션 ID
    final messages = <Message>[];

    // 사용자 메시지 1
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '안녕하세요, 오늘 날씨가 어때요?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    );

    // AI 텍스트 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '안녕하세요! 오늘 서울 날씨는 맑고 기온은 22도입니다.',
        role: MessageRole.assistant,
        timestamp: now.subtract(const Duration(minutes: 4)),
        extensions: {'messageType': 'text'},
      ),
    );

    // 사용자 메시지 2
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘 뭐하지?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    );

    // AI 액션 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘은 어떤 활동을 하고 싶으신가요?',
        role: MessageRole.assistant,
        timestamp: now.subtract(const Duration(minutes: 2)),
        extensions: {
          'messageType': 'action',
          'actions': [
            {'icon': '📚', 'text': '독서하기'},
            {'icon': '🎬', 'text': '영화 보기'},
            {'icon': '🏃', 'text': '운동하기'},
            {'icon': '👨‍🍳', 'text': '요리하기'},
          ],
        },
      ),
    );

    // 사용자 메시지 3
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘 일정 알려줘',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    );

    // AI 카드 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘 일정은 다음과 같습니다:',
        role: MessageRole.assistant,
        timestamp: now,
        extensions: {
          'messageType': 'card',
          'card': {
            'title': '프로젝트 회의',
            'time': '오후 2:00 - 3:30',
            'location': '회의실 3층',
          },
          'actions': [
            {'icon': '📝', 'text': '메모 추가하기'},
            {'icon': '🔔', 'text': '알림 설정하기'},
          ],
        },
      ),
    );

    return messages;
  }

  // ========================================
  // 디버깅 및 분석 메서드들
  // ========================================

  /// 현재 메시지 목록에서 도구 관련 메시지들을 분석
  void analyzeToolMessages() {
    debugPrint('[ChatProvider] ===== 도구 메시지 분석 시작 =====');

    final toolMessages =
        _messages
            .where(
              (msg) =>
                  msg.extensions?['isToolMessage'] == true ||
                  msg.extensions?['messageType'] != null,
            )
            .toList();

    debugPrint('[ChatProvider] 전체 메시지 수: ${_messages.length}');
    debugPrint('[ChatProvider] 도구 관련 메시지 수: ${toolMessages.length}');

    for (int i = 0; i < toolMessages.length; i++) {
      final msg = toolMessages[i];
      final messageType = msg.extensions?['messageType'];
      final toolName = msg.extensions?['toolName'];
      final isToolMessage = msg.extensions?['isToolMessage'];

      debugPrint('[ChatProvider] 도구 메시지 ${i + 1}:');
      debugPrint('  - ID: ${msg.id}');
      debugPrint(
        '  - 내용: "${msg.content?.substring(0, msg.content!.length > 50 ? 50 : msg.content!.length)}..."',
      );
      debugPrint('  - 메시지 타입: $messageType');
      debugPrint('  - 도구명: $toolName');
      debugPrint('  - 도구 메시지 여부: $isToolMessage');
      debugPrint('  - 역할: ${msg.role}');
      debugPrint('  - 타임스탬프: ${msg.timestamp}');
    }

    // 도구별 사용 횟수 통계
    final toolUsageMap = <String, int>{};
    for (final msg in toolMessages) {
      final toolName = msg.extensions?['toolName'] as String?;
      if (toolName != null) {
        toolUsageMap[toolName] = (toolUsageMap[toolName] ?? 0) + 1;
      }
    }

    debugPrint('[ChatProvider] 도구 사용 통계:');
    for (final entry in toolUsageMap.entries) {
      debugPrint('  - ${entry.key}: ${entry.value}회 사용');
    }

    debugPrint('[ChatProvider] ===== 도구 메시지 분석 완료 =====');
  }

  /// 최근 대화에서 사용된 도구 목록 반환
  List<String> getRecentlyUsedTools() {
    final toolMessages =
        _messages.where((msg) => msg.extensions?['toolName'] != null).toList();

    final toolNames =
        toolMessages
            .map((msg) => msg.extensions?['toolName'] as String?)
            .where((name) => name != null)
            .cast<String>()
            .toSet()
            .toList();

    return toolNames;
  }

  // ========================================
  // 메시지 분리를 위한 헬퍼 메서드들
  // ========================================

  /// 도구 이름에 따른 호출 메시지 생성
  String _getToolCallMessage(String toolName) {
    // 도구명 정리 및 검증
    final cleanedName = toolName.trim().toLowerCase();

    debugPrint(
      '[ChatProvider] 도구 메시지 생성 - 원본: "$toolName", 정리된 이름: "$cleanedName"',
    );

    switch (cleanedName) {
      case 'search_web':
      case 'websearch':
      case 'web_search':
        return '🔍 웹 검색을 시작합니다...';
      case 'parse_schedule':
      case 'schedule_parse':
        return '📅 일정을 분석하고 있습니다...';
      case 'create_schedule':
      case 'schedule_create':
        return '✨ 새로운 일정을 생성하고 있습니다...';
      case 'generate_insight':
      case 'insight_generate':
        return '💡 인사이트를 생성하고 있습니다...';
      case 'get_calendar':
      case 'calendar_get':
        return '📆 캘린더 정보를 조회하고 있습니다...';
      case '':
      case 'null':
      case 'undefined':
        debugPrint('[ChatProvider] ⚠️ 빈 도구명 감지 - 기본 메시지 사용');
        return '🔧 AI가 도구를 사용하고 있습니다...';
      default:
        debugPrint('[ChatProvider] ⚠️ 알 수 없는 도구명: "$cleanedName" - 기본 메시지 사용');
        return '🔧 AI가 "$toolName" 도구를 사용하고 있습니다...';
    }
  }

  // ========================================
  // 백그라운드 TTS 처리
  // ========================================

  /// 백그라운드에서 마크다운 변환 및 TTS 처리 (빠른 실행)
  void _processTtsInBackground(String content) {
    // 백그라운드에서 비동기 실행 (UI 차단 없음)
    Future.microtask(() async {
      try {
        // **빠른 마크다운 변환**
        final ttsText = _convertMarkdownToTtsText(content);

        debugPrint('[ChatProvider] 🧹 마크다운 변환 완료: ${ttsText.length}자');
        debugPrint(
          '[ChatProvider] 📝 TTS 텍스트: "${ttsText.length > 50 ? '${ttsText.substring(0, 50)}...' : ttsText}"',
        );

        // **즉시 TTS 큐에 추가 (await 없이)**
        if (ttsText.isNotEmpty) {
          _ttsService.addToQueue(ttsText);
          debugPrint('[ChatProvider] 🚀 TTS 백그라운드 실행 완료');
        } else {
          debugPrint('[ChatProvider] ⚠️ 마크다운 정리 후 텍스트가 비어있음');
        }
      } catch (e) {
        debugPrint('[ChatProvider] ❌ 백그라운드 TTS 처리 오류: $e');
      }
    });
  }

  // ========================================
  // TTS용 마크다운 정리 헬퍼 메서드
  // ========================================

  /// 마크다운 텍스트를 TTS에 적합한 일반 텍스트로 변환 (최적화됨)
  String _convertMarkdownToTtsText(String markdown) {
    String text = markdown;

    // 1. 링크 처리: [텍스트](URL) → 텍스트
    final linkRegex = RegExp(r'\[([^\]]+)\]\([^)]+\)');
    text = text.replaceAllMapped(linkRegex, (match) => match.group(1) ?? '');

    // 2. 단독 URL 제거
    text = text.replaceAll(RegExp(r'https?://[^\s\n]+'), '');

    // 3. 볼드 처리: **텍스트** → 텍스트
    final boldRegex = RegExp(r'\*\*([^*\n]+?)\*\*');
    text = text.replaceAllMapped(boldRegex, (match) => match.group(1) ?? '');

    // 4. 이탤릭 처리: *텍스트* → 텍스트
    final italicRegex = RegExp(r'(?<!\s)\*([^*\n\s][^*\n]*?)\*(?!\s)');
    text = text.replaceAllMapped(italicRegex, (match) => match.group(1) ?? '');

    // 5. 헤딩 처리: ### 텍스트 → 텍스트
    final headingRegex = RegExp(r'^#{1,6}\s*(.+)$', multiLine: true);
    text = text.replaceAllMapped(headingRegex, (match) => match.group(1) ?? '');

    // 6. 리스트 마커 제거
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '');

    // 7. 코드 블록 제거
    text = text.replaceAll(RegExp(r'```[^`]*```', dotAll: true), '');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), '');

    // 8. 기타 정리
    text = text.replaceAll(RegExp(r'\*+'), ''); // 남은 * 제거
    text = text.replaceAll(RegExp(r'\$\d+'), ''); // 정규식 잔여물 제거
    text = text.replaceAll(RegExp(r'\s+'), ' '); // 공백 정리
    text = text.trim();

    return text;
  }

  // ========================================
  // 정리
  // ========================================

  @override
  void dispose() {
    debugPrint('[ChatProvider] dispose 호출');
    _ttsService.dispose();
    super.dispose();
  }
}
