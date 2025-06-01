import 'package:flutter/material.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/local_database/models/message_role.dart';
import '../../services/conversation/conversation_service.dart';
import '../../services/tts/tts_service.dart';
import '../components/messages/assistant/message_types.dart';

/// 채팅 상태를 관리하는 Provider
///
/// Message 모델과 UI 간의 데이터 변환을 담당하며,
/// ConversationService를 통해 실제 AI 대화를 처리합니다.
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

  // ========================================
  // 생성자
  // ========================================

  ChatProvider({
    ConversationService? conversationService,
    TtsService? ttsService,
  }) : _conversationService = conversationService ?? ConversationService(),
       _ttsService = ttsService ?? TtsService() {
    debugPrint('[ChatProvider] 초기화 완료');
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

  // ========================================
  // 핵심 기능들
  // ========================================

  /// 사용자 메시지 전송 및 AI 응답 요청
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      debugPrint('[ChatProvider] 빈 메시지는 전송할 수 없습니다');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[ChatProvider] 메시지 전송 시작: "$text"');

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

      // 2. AI 응답을 위한 빈 메시지 생성 (실시간 업데이트용)
      final aiMessageId = _generateMessageId();
      final aiMessage = Message(
        id: aiMessageId,
        sessionId: _currentSessionId!,
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);

      // 3. 기존 TTS 정지 (새 응답을 위해)
      await _ttsService.stop();

      // 4. 스트리밍 응답 요청 (실시간 UI 업데이트만)
      debugPrint('[ChatProvider] AI 응답 스트리밍 시작...');
      final aiResponse = await _conversationService.sendMessageStream(
        sessionId: _currentSessionId!,
        content: text,
        onProgress: (partialResponse) {
          // AI 메시지 내용 실시간 업데이트 (UI용만)
          final index = _messages.indexWhere((msg) => msg.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: partialResponse,
            );
            notifyListeners();
          }
          debugPrint('[ChatProvider] 실시간 업데이트: ${partialResponse.length}자');
        },
        onToolUse: (toolName) {
          debugPrint('[ChatProvider] AI 도구 사용 중: $toolName');
        },
        onToolComplete: () {
          debugPrint('[ChatProvider] AI 도구 사용 완료');
        },
      );

      // 5. 최종 AI 메시지로 업데이트
      final finalIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (finalIndex != -1) {
        _messages[finalIndex] = aiResponse.copyWith(id: aiMessageId);
        notifyListeners();
      }

      // 6. 완료된 AI 응답을 TTS로 읽기 (한 번에 전체)
      if (aiResponse.content != null && aiResponse.content!.isNotEmpty) {
        await _ttsService.addToQueue(aiResponse.content!);
        debugPrint(
          '[ChatProvider] AI 응답 TTS 시작: "${aiResponse.contentPreview}"',
        );
      }

      debugPrint('[ChatProvider] AI 응답 완료: "${aiResponse.contentPreview}"');
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
    _currentSessionId = _generateSessionId();

    // 샘플 메시지들 생성
    final sampleMessages = _generateSampleMessages();
    _messages.addAll(sampleMessages);

    debugPrint('[ChatProvider] ${sampleMessages.length}개 샘플 메시지 로드');
    notifyListeners();
  }

  /// 외부에서 생성된 UI 형태의 메시지 리스트를 설정
  /// (home_screen에서 생성된 샘플 메시지 사용)
  void setMessages(List<Map<String, dynamic>> uiMessages) {
    _messages.clear();
    _currentSessionId = null; // 실제 메시지 전송 시 백엔드에서 세션 생성

    // UI 형태의 메시지를 Message 객체로 변환
    for (final uiMessage in uiMessages) {
      final message = _uiFormatToMessage(uiMessage);
      _messages.add(message);
    }

    debugPrint('[ChatProvider] ${uiMessages.length}개 메시지 설정 완료');
    notifyListeners();
  }

  // ========================================
  // 내부 헬퍼 메서드들
  // ========================================

  /// Message 객체를 UI에서 사용하는 Map 형태로 변환
  Map<String, dynamic> _messageToUIFormat(Message message) {
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
      sessionId: _currentSessionId ?? 'temp_session', // 임시 세션 ID (실제 전송 시 변경됨)
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
    final sessionId = _currentSessionId!;
    final messages = <Message>[];

    // 사용자 메시지 1
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
        content: '안녕하세요, 오늘 날씨가 어때요?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    );

    // AI 텍스트 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
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
        sessionId: sessionId,
        content: '오늘 뭐하지?',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    );

    // AI 액션 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
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
        sessionId: sessionId,
        content: '오늘 일정 알려줘',
        role: MessageRole.user,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    );

    // AI 카드 응답
    messages.add(
      Message(
        id: _generateMessageId(),
        sessionId: sessionId,
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
  // 정리
  // ========================================

  @override
  void dispose() {
    debugPrint('[ChatProvider] dispose 호출');
    _ttsService.dispose();
    super.dispose();
  }
}
