import 'package:flutter/material.dart';
import 'dart:async';
import '../../repositories/backend/models/message.dart';
import '../../repositories/local_database/models/message_role.dart';
import '../../services/conversation/conversation_service.dart';
import '../../services/tts/tts_service.dart';
import '../components/messages/assistant/message_types.dart';
import 'chat_tts_manager.dart';

/// 채팅 상태를 관리하는 Provider
///
/// **주요 역할:**
/// - Message 모델과 UI 간 데이터 변환
/// - AI 대화 처리 (ConversationService 연동)
/// - 실시간 TTS 스트리밍 관리
/// - 메시지 상태 관리 및 업데이트
///
/// **연동 서비스:**
/// - ConversationService: AI 대화 처리
/// - ChatTtsManager: TTS 기능 관리
/// - InputBarViewModel: 메시지 전송 이벤트 처리
class ChatProvider extends ChangeNotifier {
  final ConversationService _conversationService;
  final ChatTtsManager _ttsManager;

  // ========================================
  // 🗂️ 상태 관리 변수들
  // ========================================

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  // 🌍 글로벌 메시지 전송 핸들러
  static ChatProvider? _globalInstance;

  // ========================================
  // 🏗️ 생성자 및 초기화
  // ========================================

  ChatProvider({
    ConversationService? conversationService,
    TtsService? ttsService,
  }) : _conversationService = conversationService ?? ConversationService(),
       _ttsManager = ChatTtsManager(ttsService: ttsService) {
    debugPrint('[ChatProvider] 🎯 ChatProvider 초기화 완료');
    debugPrint('[ChatProvider] 🎯 서비스: ${_conversationService.runtimeType}');
    debugPrint('[ChatProvider] 🎯 TTS 매니저 연결 완료');
    _globalInstance = this; // 글로벌 인스턴스 설정
  }

  // ========================================
  // 🌍 글로벌 메시지 전송
  // ========================================

  /// **전역 메시지 전송**
  ///
  /// 앱 어디서든 메시지를 전송할 수 있는 정적 메서드
  static void sendGlobalMessage(String message) {
    debugPrint('[ChatProvider] 🌍 전역 메시지 수신: "$message"');
    if (_globalInstance != null) {
      debugPrint('[ChatProvider] 🌍 글로벌 인스턴스로 전달');
      _globalInstance!.sendMessage(message);
    } else {
      debugPrint('[ChatProvider] ❌ 글로벌 인스턴스 없음!');
    }
  }

  // ========================================
  // 📊 상태 확인 프로퍼티들 (UI에서 구독)
  // ========================================

  /// **UI용 메시지 목록** (Map 형태로 변환됨)
  List<Map<String, dynamic>> get messages =>
      _messages.map(_messageToUIFormat).toList();

  /// **현재 로딩 상태**
  bool get isLoading => _isLoading;

  /// **현재 에러 메시지**
  String? get error => _error;

  /// **메시지 개수**
  int get messageCount => _messages.length;

  /// **현재 세션 ID**
  String? get currentSessionId => _currentSessionId;

  /// **대화 진행 여부**
  bool get hasMessages => _messages.isNotEmpty;

  // ========================================
  // 🔧 필터링된 메시지 목록들
  // ========================================

  /// **도구 메시지만 필터링** (UI용)
  List<Map<String, dynamic>> get toolMessages {
    return _messages
        .where((msg) => msg.extensions?['isToolMessage'] == true)
        .map(_messageToUIFormat)
        .toList();
  }

  /// **LLM 응답 메시지만 필터링** (UI용)
  List<Map<String, dynamic>> get llmResponseMessages {
    return _messages
        .where((msg) => msg.extensions?['messageType'] == 'llm_response')
        .map(_messageToUIFormat)
        .toList();
  }

  /// **최근 사용된 도구 이름 목록** (UI용)
  List<String> get recentToolNames => getRecentlyUsedTools();

  // ========================================
  // 🚀 핵심 메시지 처리 기능들
  // ========================================

  /// **사용자 메시지 전송 및 AI 응답 요청**
  ///
  /// **처리 흐름:**
  /// 1. 입력 검증 및 TTS 중단
  /// 2. 세션 생성/확인
  /// 3. 사용자 메시지 추가
  /// 4. AI 스트리밍 응답 처리
  /// 5. 도구 사용 처리
  /// 6. 최종 TTS 처리
  Future<void> sendMessage(String text) async {
    debugPrint('[ChatProvider] 🚀 메시지 전송 시작: "$text"');

    if (text.trim().isEmpty) {
      debugPrint('[ChatProvider] ⚠️ 빈 메시지는 전송 불가');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // 1️⃣ TTS 즉시 중단 (가장 먼저 실행)
      await _ttsManager.stopTts();

      // 2️⃣ 세션 확인/생성
      await _ensureSessionExists();

      // 3️⃣ 사용자 메시지 추가
      final userMessage = _createUserMessage(text);
      _addMessage(userMessage);

      // 4️⃣ AI 스트리밍 응답 처리
      final aiResponse = await _processAiStreamingResponse(text);

      // 5️⃣ 최종 TTS 처리
      await _processFinalTts(aiResponse);

      // 6️⃣ 도구 사용 분석 (디버깅)
      _analyzeToolUsage();
    } catch (e) {
      _setError('메시지 전송 실패: $e');
      debugPrint('[ChatProvider] ❌ 메시지 전송 오류: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// **세션 존재 확인 및 생성**
  Future<void> _ensureSessionExists() async {
    if (_currentSessionId == null) {
      debugPrint('[ChatProvider] 🆕 새 세션 생성 중...');
      final session = await _conversationService.createSession();
      _currentSessionId = session.id;
      debugPrint('[ChatProvider] ✅ 새 세션 생성: $_currentSessionId');
    }
  }

  /// **사용자 메시지 생성**
  Message _createUserMessage(String text) {
    return Message(
      id: _generateMessageId(),
      sessionId: _currentSessionId!,
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// **AI 스트리밍 응답 처리**
  Future<dynamic> _processAiStreamingResponse(String text) async {
    // 메시지 ID들 (각 타입별 별도 메시지)
    String? toolCallMessageId;
    String? toolResponseMessageId;
    String? llmResponseMessageId;

    // 중복 방지 플래그들
    bool hasToolCallMessage = false;
    String? lastToolName;

    debugPrint('[ChatProvider] 🤖 AI 스트리밍 응답 시작...');

    final aiResponse = await _conversationService.sendMessageStream(
      sessionId: _currentSessionId!,
      content: text,
      onProgress: (partialResponse) {
        llmResponseMessageId = _handleLlmResponse(
          llmResponseMessageId,
          partialResponse,
        );
        _ttsManager.processStreamingResponse(partialResponse); // 🚀 실시간 TTS
      },
      onToolUse: (toolName) {
        final result = _handleToolUse(
          toolName,
          hasToolCallMessage,
          lastToolName,
        );
        if (result != null) {
          toolCallMessageId = result['messageId'];
          hasToolCallMessage = result['hasMessage'];
          lastToolName = result['toolName'];
        }
      },
      onToolComplete: () {
        toolResponseMessageId = _handleToolComplete(toolResponseMessageId);
      },
    );

    return aiResponse;
  }

  /// **LLM 응답 메시지 처리**
  String? _handleLlmResponse(String? messageId, String partialResponse) {
    if (messageId == null) {
      // 첫 번째 청크일 때 LLM 응답 메시지 생성
      final newMessageId = _generateMessageId();
      final llmMessage = Message(
        id: newMessageId,
        sessionId: _currentSessionId!,
        content: partialResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        extensions: {'messageType': 'llm_response'},
      );
      _addMessage(llmMessage);
      debugPrint('[ChatProvider] 📝 LLM 응답 메시지 생성: ${partialResponse.length}자');
      return newMessageId;
    } else {
      // 기존 LLM 응답 메시지 업데이트
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(content: partialResponse);
        notifyListeners();
        debugPrint('[ChatProvider] 📝 LLM 응답 업데이트: ${partialResponse.length}자');
      }
      return messageId;
    }
  }

  /// **도구 사용 처리**
  Map<String, dynamic>? _handleToolUse(
    String toolName,
    bool hasToolCallMessage,
    String? lastToolName,
  ) {
    debugPrint('[ChatProvider] 🔧 도구 사용 신호: "$toolName"');

    // 중복 도구 호출 방지
    if (hasToolCallMessage && lastToolName == toolName) {
      debugPrint('[ChatProvider] ⚠️ 중복 도구 호출 방지: $toolName');
      return null;
    }

    // 도구명 검증
    final cleanedToolName = _validateToolName(toolName);
    if (cleanedToolName == null) return null;

    // 도구 호출 메시지 생성
    final messageId = _generateMessageId();
    final toolMessage = Message(
      id: messageId,
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
    _addMessage(toolMessage);

    debugPrint('[ChatProvider] ✅ 도구 호출 메시지 생성: $cleanedToolName');

    return {
      'messageId': messageId,
      'hasMessage': true,
      'toolName': cleanedToolName,
    };
  }

  /// **도구명 검증**
  String? _validateToolName(String toolName) {
    final cleanedName = toolName.trim();

    if (cleanedName.isEmpty ||
        cleanedName == 'null' ||
        cleanedName == '도구' ||
        cleanedName == '알 수 없는 도구' ||
        cleanedName.length < 3) {
      debugPrint('[ChatProvider] ⚠️ 유효하지 않은 도구명 무시: "$toolName"');
      return null;
    }

    return cleanedName;
  }

  /// **도구 완료 처리**
  String? _handleToolComplete(String? messageId) {
    debugPrint('[ChatProvider] ✅ 도구 사용 완료');

    if (messageId == null) {
      final newMessageId = _generateMessageId();
      final toolResponseMessage = Message(
        id: newMessageId,
        sessionId: _currentSessionId!,
        content: '✅ 도구 실행이 완료되었습니다. 답변을 생성하는 중입니다...',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        extensions: {'messageType': 'tool_response', 'isToolMessage': true},
      );
      _addMessage(toolResponseMessage);
      debugPrint('[ChatProvider] ✅ 도구 응답 메시지 생성');
      return newMessageId;
    } else {
      debugPrint('[ChatProvider] ⚠️ 도구 응답 메시지 이미 존재 - 중복 방지');
      return messageId;
    }
  }

  /// **최종 TTS 처리**
  Future<void> _processFinalTts(dynamic aiResponse) async {
    if (aiResponse.content != null && aiResponse.content!.isNotEmpty) {
      final finalContent = aiResponse.content!.trim();
      debugPrint(
        '[ChatProvider] 🎤 AI 응답 완료 - TTS 시작: ${finalContent.length}자',
      );
      _ttsManager.processResponseForTts(finalContent);
    }
  }

  /// **도구 사용 현황 분석** (디버깅용)
  void _analyzeToolUsage() {
    analyzeToolMessages();
    final usedTools = getRecentlyUsedTools();
    if (usedTools.isNotEmpty) {
      debugPrint('[ChatProvider] 🔧 사용된 도구들: $usedTools');
    } else {
      debugPrint('[ChatProvider] 🔧 도구 사용 없음');
    }
  }

  // ========================================
  // 🗂️ 메시지 관리 메서드들
  // ========================================

  /// **메시지 목록 초기화** (새 대화 시작)
  void clearMessages() {
    _messages.clear();
    _currentSessionId = null;
    _clearError();
    debugPrint('[ChatProvider] 🧹 메시지 목록 초기화');
    notifyListeners();
  }

  /// **특정 메시지 삭제**
  void removeMessage(String messageId) {
    final originalLength = _messages.length;
    _messages.removeWhere((message) => message.id == messageId);

    if (_messages.length != originalLength) {
      debugPrint('[ChatProvider] 🗑️ 메시지 삭제: $messageId');
      notifyListeners();
    }
  }

  /// **샘플 메시지 로드** (테스트용)
  void loadSampleMessages() {
    _messages.clear();
    _currentSessionId = null; // 실제 전송 시 새 세션 생성

    final sampleMessages = _generateSampleMessages();
    _messages.addAll(sampleMessages);

    debugPrint('[ChatProvider] 📋 ${sampleMessages.length}개 샘플 메시지 로드');
    notifyListeners();
  }

  /// **외부 UI 메시지 설정**
  ///
  /// home_screen에서 생성된 샘플 메시지를 받아서 설정합니다.
  void setMessages(List<Map<String, dynamic>> uiMessages) {
    _messages.clear();
    _currentSessionId = null; // 실제 전송 시 새 세션 생성

    // UI 형태 → Message 객체 변환
    for (final uiMessage in uiMessages) {
      final message = _uiFormatToMessage(uiMessage);
      _messages.add(message);
    }

    debugPrint('[ChatProvider] 📥 ${uiMessages.length}개 메시지 설정 완료');
    notifyListeners();
  }

  // ========================================
  // 🔄 데이터 변환 메서드들
  // ========================================

  /// **Message → UI Map 변환**
  Map<String, dynamic> _messageToUIFormat(Message message) {
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
      'messageSubType':
          messageTypeFromExtensions, // tool_call, tool_response, llm_response 등
      'isToolMessage': isToolMessage,
      'toolName': message.extensions?['toolName'],
    };
  }

  /// **Message에서 MessageType enum 추출**
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

  /// **UI Map → Message 변환**
  Message _uiFormatToMessage(Map<String, dynamic> uiMessage) {
    final isUser = uiMessage['isUser'] as bool? ?? false;
    final text = uiMessage['text'] as String? ?? '';
    final messageType =
        uiMessage['messageType'] as MessageType? ?? MessageType.text;

    // 기존 메시지 수만큼 이전 시간으로 설정
    final parsedTimestamp = DateTime.now().subtract(
      Duration(minutes: _messages.length),
    );

    // extensions 생성
    final extensions = <String, dynamic>{
      'messageType': messageType.toString().split('.').last,
    };

    if (uiMessage.containsKey('actions')) {
      extensions['actions'] = uiMessage['actions'];
    }
    if (uiMessage.containsKey('card')) {
      extensions['card'] = uiMessage['card'];
    }

    return Message(
      id: _generateMessageId(),
      sessionId:
          'temp_session_${DateTime.now().millisecondsSinceEpoch}', // 임시 세션 ID
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
    debugPrint('[ChatProvider] ➕ 메시지 추가: ${message.contentPreview}');
  }

  /// 로딩 상태 변경
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      debugPrint('[ChatProvider] ⏳ 로딩 상태: $loading');
    }
  }

  /// 에러 상태 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
    debugPrint('[ChatProvider] ❌ 에러 설정: $error');
  }

  /// 에러 상태 지우기
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
      debugPrint('[ChatProvider] ✅ 에러 상태 클리어');
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
  // 📋 샘플 데이터 생성 (테스트용)
  // ========================================

  /// **테스트용 샘플 메시지들 생성**
  List<Message> _generateSampleMessages() {
    final now = DateTime.now();
    final tempSessionId =
        'sample_session_${DateTime.now().millisecondsSinceEpoch}';
    final messages = <Message>[];

    // 🙋‍♂️ 사용자 메시지 1
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '안녕하세요, 오늘 날씨가 어때요?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    );

    // 🤖 AI 텍스트 응답
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

    // 🙋‍♂️ 사용자 메시지 2
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘 뭐하지?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    );

    // 🤖 AI 액션 응답
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

    // 🙋‍♂️ 사용자 메시지 3
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: tempSessionId,
        content: '오늘 일정 알려줘',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    );

    // 🤖 AI 카드 응답
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
  // 🔍 디버깅 및 분석 메서드들
  // ========================================

  /// **현재 메시지 목록에서 도구 관련 메시지들을 분석**
  void analyzeToolMessages() {
    debugPrint('[ChatProvider] ===== 🔧 도구 메시지 분석 시작 =====');

    final toolMessages =
        _messages
            .where(
              (msg) =>
                  msg.extensions?['isToolMessage'] == true ||
                  msg.extensions?['messageType'] != null,
            )
            .toList();

    debugPrint(
      '[ChatProvider] 📊 전체: ${_messages.length}, 도구 관련: ${toolMessages.length}',
    );

    for (int i = 0; i < toolMessages.length; i++) {
      final msg = toolMessages[i];
      final messageType = msg.extensions?['messageType'];
      final toolName = msg.extensions?['toolName'];
      final isToolMessage = msg.extensions?['isToolMessage'];

      debugPrint('[ChatProvider] 🔧 도구 메시지 ${i + 1}:');
      debugPrint('  - ID: ${msg.id}');
      debugPrint(
        '  - 내용: "${msg.content?.substring(0, msg.content!.length > 50 ? 50 : msg.content!.length)}..."',
      );
      debugPrint('  - 타입: $messageType');
      debugPrint('  - 도구명: $toolName');
      debugPrint('  - 도구메시지: $isToolMessage');
      debugPrint('  - 역할: ${msg.role}');
    }

    // 도구별 사용 횟수 통계
    final toolUsageMap = <String, int>{};
    for (final msg in toolMessages) {
      final toolName = msg.extensions?['toolName'] as String?;
      if (toolName != null) {
        toolUsageMap[toolName] = (toolUsageMap[toolName] ?? 0) + 1;
      }
    }

    debugPrint('[ChatProvider] 📈 도구 사용 통계:');
    for (final entry in toolUsageMap.entries) {
      debugPrint('  - ${entry.key}: ${entry.value}회');
    }

    debugPrint('[ChatProvider] ===== 🔧 도구 메시지 분석 완료 =====');
  }

  /// **최근 대화에서 사용된 도구 목록 반환**
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

  /// **도구 이름에 따른 호출 메시지 생성**
  String _getToolCallMessage(String toolName) {
    final cleanedName = toolName.trim().toLowerCase();

    debugPrint('[ChatProvider] 🔧 도구 메시지 생성: "$toolName" → "$cleanedName"');

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
        debugPrint('[ChatProvider] ⚠️ 빈 도구명 - 기본 메시지 사용');
        return '🔧 AI가 도구를 사용하고 있습니다...';
      default:
        debugPrint('[ChatProvider] ⚠️ 알 수 없는 도구명: "$cleanedName"');
        return '🔧 AI가 "$toolName" 도구를 사용하고 있습니다...';
    }
  }

  // ========================================
  // 🧹 리소스 정리
  // ========================================

  @override
  void dispose() {
    debugPrint('[ChatProvider] 🧹 리소스 정리 시작');
    _ttsManager.dispose();
    super.dispose();
    debugPrint('[ChatProvider] ✅ 정리 완료');
  }
}
