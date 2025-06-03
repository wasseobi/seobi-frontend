import 'package:flutter_test/flutter_test.dart';
import 'package:seobi_app/repositories/backend/models/message.dart';
import 'package:seobi_app/repositories/backend/models/session.dart';
import 'package:seobi_app/repositories/local_database/models/message_role.dart';
import 'package:seobi_app/services/conversation/conversation_service.dart';
import 'package:seobi_app/services/tts/tts_service.dart';
import 'package:seobi_app/ui/utils/chat_provider.dart';
import 'package:seobi_app/ui/components/messages/assistant/message_types.dart';

// ============================================================================
// MOCK SERVICES
// ============================================================================
// 테스트를 위한 가짜 서비스 구현체들

/// Mock ConversationService
/// AI 대화 서비스의 모든 기능을 시뮬레이션하는 테스트용 구현체
class MockConversationService implements ConversationService {
  // === 내부 상태 관리 ===
  bool _shouldThrowError = false;
  String? _customResponse;

  // === 테스트 설정 메서드 ===
  /// 오류 발생 여부 설정 (오류 처리 테스트용)
  void setThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  /// 커스텀 AI 응답 설정 (특정 응답 테스트용)
  void setCustomResponse(String response) {
    _customResponse = response;
  }

  // === ConversationService 인터페이스 구현 ===
  @override
  Future<Session> createSession({SessionType type = SessionType.chat}) async {
    if (_shouldThrowError) {
      throw Exception('Mock 세션 생성 오류');
    }

    return Session(
      id: 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock_user',
      startAt: DateTime.now(),
      type: type,
    );
  }

  @override
  Future<Message> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    if (_shouldThrowError) {
      throw Exception('Mock 메시지 전송 오류');
    }

    return Message(
      id: 'mock_response_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: _customResponse ?? 'Mock AI 응답: $content에 대한 답변입니다.',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<Message> sendMessageStream({
    required String sessionId,
    required String content,
    required void Function(String partialResponse) onProgress,
    void Function(String toolName)? onToolUse,
    void Function()? onToolComplete,
  }) async {
    if (_shouldThrowError) {
      throw Exception('Mock 메시지 전송 오류');
    }

    String response = _customResponse ?? 'Mock AI 응답: $content에 대한 답변입니다.';

    // 도구 사용 시뮬레이션 (검색 관련 키워드 감지)
    if (content.contains('검색') || content.contains('날씨')) {
      onToolUse?.call('search_web');
      await Future.delayed(Duration(milliseconds: 100));
      onToolComplete?.call();
      response = '검색 결과: $content에 대한 정보입니다. ' + response;
    }

    // 스트리밍 응답 시뮬레이션 (단어별 점진적 전송)
    final words = response.split(' ');
    String currentText = '';

    for (final word in words) {
      currentText += (currentText.isEmpty ? '' : ' ') + word;
      onProgress(currentText);
      await Future.delayed(Duration(milliseconds: 30));
    }

    return Message(
      id: 'mock_response_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: response,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<Session> endSession(String sessionId) async {
    if (_shouldThrowError) {
      throw Exception('Mock 세션 종료 오류');
    }
    return Session(
      id: sessionId,
      userId: 'mock_user',
      startAt: DateTime.now(),
      type: SessionType.chat,
    );
  }

  @override
  Future<List<Message>> getSessionMessages(String sessionId) async {
    if (_shouldThrowError) {
      throw Exception('Mock 메시지 조회 오류');
    }
    return [];
  }

  @override
  Future<List<Session>> getUserSessions() async {
    if (_shouldThrowError) {
      throw Exception('Mock 세션 목록 조회 오류');
    }
    return [];
  }
}

/// Mock TtsService
/// TTS(Text-to-Speech) 서비스의 모든 기능을 시뮬레이션하는 테스트용 구현체
class MockTtsService implements TtsService {
  // === 내부 상태 관리 ===
  final List<String> _queue = [];
  bool _isDisposed = false;
  bool _shouldThrowError = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentText;
  final List<String> _streamedTexts = [];

  // TTS 설정 관련 변수
  String? _language;
  double? _pitch;
  double? _rate;
  double? _volume;

  // === 상태 접근자 ===
  List<String> get queue => List.unmodifiable(_queue);
  bool get isDisposed => _isDisposed;
  String? get currentText => _currentText;
  List<String> get streamedTexts => List.unmodifiable(_streamedTexts);

  // TTS 설정 접근자
  String? get language => _language;
  double? get pitch => _pitch;
  double? get rate => _rate;
  double? get volume => _volume;

  // === 테스트 설정 메서드 ===
  /// 오류 발생 여부 설정 (오류 처리 테스트용)
  void setThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  // === TtsService 인터페이스 구현 ===
  @override
  bool get hasQueuedItems => _queue.isNotEmpty;

  @override
  bool get isActive => _isPlaying || _isPaused || _queue.isNotEmpty;

  @override
  bool get isPaused => _isPaused;

  @override
  bool get isPlaying => _isPlaying;

  @override
  int get queueSize => _queue.length;

  @override
  Future<void> addToQueue(String text) async {
    if (_shouldThrowError) {
      throw Exception('Mock TTS 큐 추가 오류');
    }
    _queue.add(text);
    _currentText = text;
    _streamedTexts.add(text);
  }

  @override
  Future<void> stop() async {
    if (_shouldThrowError) {
      throw Exception('Mock TTS 중단 오류');
    }
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _queue.clear();
    _streamedTexts.clear();
    _currentText = null;
  }

  @override
  Future<void> pause() async {
    if (_shouldThrowError) {
      throw Exception('Mock TTS 일시정지 오류');
    }
    _isPaused = true;
    _isPlaying = false;
  }

  @override
  Future<void> resume() async {
    if (_shouldThrowError) {
      throw Exception('Mock TTS 재개 오류');
    }
    _isPaused = false;
    _isPlaying = true;
  }

  @override
  Future<void> setConfiguration({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
  }) async {
    if (_shouldThrowError) {
      throw Exception('Mock TTS 설정 오류');
    }
    _language = language;
    _pitch = pitch;
    _rate = rate;
    _volume = volume;
  }
}

// ============================================================================
// MAIN TEST SUITE
// ============================================================================

void main() {
  group('ChatProvider 테스트', () {
    // === 테스트 공통 변수 ===
    late ChatProvider chatProvider;
    late MockConversationService mockConversationService;
    late MockTtsService mockTtsService;

    // === 테스트 설정/정리 ===
    setUp(() {
      mockConversationService = MockConversationService();
      mockTtsService = MockTtsService();
      chatProvider = ChatProvider(
        conversationService: mockConversationService,
        ttsService: mockTtsService,
      );
    });

    tearDown(() {
      chatProvider.dispose();
    });

    // ========================================================================
    // 기본 기능 테스트 그룹
    // ========================================================================
    group('📱 기본 기능 테스트', () {
      test('초기 상태 확인', () {
        // Given: ChatProvider 인스턴스 생성
        // When: 초기 상태 검증
        // Then: 모든 상태가 초기값으로 설정되어야 함
        expect(chatProvider.messages, isEmpty);
        expect(chatProvider.isLoading, isFalse);
        expect(chatProvider.error, isNull);
        expect(chatProvider.messageCount, equals(0));
        expect(chatProvider.currentSessionId, isNull);
        expect(chatProvider.hasMessages, isFalse);
      });

      test('메시지 전송 및 AI 응답 수신', () async {
        // Given: 사용자 메시지
        const userMessage = '안녕하세요';

        // When: 메시지 전송
        await chatProvider.sendMessage(userMessage);

        // Then: 사용자 메시지와 AI 응답이 모두 저장되어야 함
        expect(chatProvider.messageCount, equals(2)); // 사용자 + AI 응답
        expect(chatProvider.currentSessionId, isNotNull);
        expect(chatProvider.messages.first['isUser'], isTrue);
        expect(chatProvider.messages.first['text'], equals(userMessage));
      });

      test('메시지 타입 변환 확인', () async {
        // Given: 테스트 메시지
        await chatProvider.sendMessage('테스트 메시지');

        // When: 메시지 타입 확인
        final messages = chatProvider.messages;
        expect(messages, isNotEmpty);

        // Then: 메시지 타입이 올바르게 설정되어야 함
        final userMessage = messages.firstWhere((msg) => msg['isUser'] == true);
        expect(userMessage['messageType'], equals(MessageType.text));

        final aiMessage = messages.firstWhere((msg) => msg['isUser'] == false);
        expect(aiMessage['messageType'], equals(MessageType.text));
      });
    });

    // ========================================================================
    // 메시지 관리 테스트 그룹
    // ========================================================================
    group('💬 메시지 관리 테스트', () {
      test('메시지 전체 삭제', () async {
        // Given: 메시지가 있는 상태
        await chatProvider.sendMessage('테스트 메시지');
        expect(chatProvider.messages, isNotEmpty);

        // When: 메시지 전체 삭제
        chatProvider.clearMessages();

        // Then: 모든 메시지와 세션 정보가 삭제되어야 함
        expect(chatProvider.messages, isEmpty);
        expect(chatProvider.currentSessionId, isNull);
        expect(chatProvider.error, isNull);
      });

      test('개별 메시지 삭제', () async {
        // Given: 메시지 전송
        await chatProvider.sendMessage('삭제될 메시지');
        expect(chatProvider.messages, isNotEmpty);
        final messageId = chatProvider.messages.first['id'];

        // When: 특정 메시지 삭제
        chatProvider.removeMessage(messageId);

        // Then: 해당 메시지만 삭제되고 AI 응답은 남아있어야 함
        expect(
          chatProvider.messages.where((msg) => msg['id'] == messageId).isEmpty,
          isTrue,
        );
        expect(chatProvider.messages, isNotEmpty); // AI 응답은 남아있어야 함
      });

      test('샘플 메시지 로드', () {
        // Given: 빈 메시지 상태
        expect(chatProvider.messages, isEmpty);

        // When: 샘플 메시지 로드
        chatProvider.loadSampleMessages();

        // Then: 다양한 타입의 샘플 메시지가 로드되어야 함
        expect(chatProvider.hasMessages, isTrue);
        expect(chatProvider.messages, isNotEmpty);
        expect(
          chatProvider.messages.any(
            (msg) => msg['messageType'] == MessageType.action,
          ),
          isTrue,
        );
        expect(
          chatProvider.messages.any(
            (msg) => msg['messageType'] == MessageType.card,
          ),
          isTrue,
        );
      });

      test('메시지 확장 정보 검증', () async {
        // Given: 메시지 전송
        await chatProvider.sendMessage('테스트 메시지');

        // When: 메시지 확장 정보 확인
        final messages = chatProvider.messages;
        expect(messages, isNotEmpty);

        // Then: AI 메시지의 확장 정보가 올바르게 설정되어야 함
        final aiMessage = messages.firstWhere((msg) => msg['isUser'] == false);
        expect(aiMessage['messageSubType'], equals('llm_response'));
        expect(aiMessage['isToolMessage'], isFalse);
      });
    });

    // ========================================================================
    // 도구 사용 테스트 그룹
    // ========================================================================
    group('🔧 도구 사용 테스트', () {
      test('도구 호출 및 응답 메시지 생성', () async {
        // Given: 도구 사용을 트리거하는 메시지
        await chatProvider.sendMessage('날씨 검색해줘');

        // When: 도구 메시지 확인
        final toolMessages = chatProvider.toolMessages;

        // Then: 도구 호출과 응답 메시지가 모두 생성되어야 함
        expect(toolMessages, isNotEmpty);
        expect(
          toolMessages.any((msg) => msg['messageSubType'] == 'tool_call'),
          isTrue,
        );
        expect(
          toolMessages.any((msg) => msg['messageSubType'] == 'tool_response'),
          isTrue,
        );
      });

      test('도구 사용 통계 수집', () async {
        // Given: 여러 도구 사용 시나리오
        await chatProvider.sendMessage('날씨 검색해줘');
        await chatProvider.sendMessage('일정 확인해줘');

        // When: 도구 사용 통계 확인
        final usedTools = chatProvider.recentToolNames;

        // Then: 사용된 도구가 통계에 반영되어야 함
        expect(usedTools, isNotEmpty);
        expect(usedTools.contains('search_web'), isTrue);
      });
    });

    // ========================================================================
    // TTS 기능 테스트 그룹
    // ========================================================================
    group('🔊 TTS 기능 테스트', () {
      test('TTS 큐 기본 동작', () async {
        // Given: TTS 테스트 메시지
        await chatProvider.sendMessage('TTS 테스트');

        // When: TTS 처리 완료 대기
        await Future.delayed(Duration(milliseconds: 100));

        // Then: TTS 큐에 텍스트가 추가되어야 함
        expect(mockTtsService.queue, isNotEmpty);
        expect(mockTtsService.isDisposed, isFalse);
      });

      test('TTS 설정 적용 및 검증', () async {
        // Given: TTS 설정값
        const testLanguage = 'ko-KR';
        const testPitch = 1.0;
        const testRate = 1.0;
        const testVolume = 1.0;

        // When: TTS 설정 적용
        await mockTtsService.setConfiguration(
          language: testLanguage,
          pitch: testPitch,
          rate: testRate,
          volume: testVolume,
        );

        // Then: 설정이 올바르게 저장되어야 함
        expect(mockTtsService.language, equals(testLanguage));
        expect(mockTtsService.pitch, equals(testPitch));
        expect(mockTtsService.rate, equals(testRate));
        expect(mockTtsService.volume, equals(testVolume));

        // When: 메시지 전송으로 TTS 동작 확인
        await chatProvider.sendMessage('TTS 설정 테스트 메시지');
        await Future.delayed(const Duration(milliseconds: 50));

        // Then: TTS가 정상 동작해야 함
        expect(
          mockTtsService.queue,
          isNotEmpty,
          reason: "메시지 전송 후 TTS 큐가 비어있으면 안 됩니다.",
        );
        expect(
          mockTtsService.currentText,
          isNotNull,
          reason: "메시지 전송 후 TTS currentText가 null이면 안 됩니다.",
        );
        expect(
          mockTtsService.currentText,
          contains('TTS 설정 테스트 메시지'),
          reason: "TTS로 전달된 텍스트에 원본 메시지 내용이 포함되어야 합니다.",
        );
      });

      test('실시간 TTS 스트리밍', () async {
        // Given: 긴 메시지 (스트리밍 효과 테스트용)
        final longMessage =
            '안녕하세요. 이것은 실시간 TTS 스트리밍 테스트를 위한 긴 메시지입니다. '
            '이 메시지는 여러 문장으로 구성되어 있어 스트리밍 효과를 더 잘 볼 수 있습니다. '
            '각 문장이 하나씩 TTS로 변환되어 재생되어야 합니다.';

        // When: 메시지 전송 및 스트리밍 처리 완료 대기
        await chatProvider.sendMessage(longMessage);
        await Future.delayed(const Duration(milliseconds: 100));

        // Then: TTS 스트리밍이 정상 동작해야 함
        expect(
          mockTtsService.queue,
          isNotEmpty,
          reason: "TTS 큐에 아이템이 있어야 합니다.",
        );
        expect(
          mockTtsService.currentText,
          isNotNull,
          reason: "현재 TTS 텍스트가 설정되어야 합니다.",
        );

        // TTS 텍스트 내용 검증
        if (mockTtsService.streamedTexts.isNotEmpty) {
          final finalTtsText = mockTtsService.streamedTexts.last;
          expect(
            finalTtsText,
            contains('Mock AI 응답'),
            reason: "최종 TTS 텍스트에 AI 응답이 포함되어야 합니다.",
          );
          expect(
            finalTtsText,
            contains(longMessage),
            reason: "최종 TTS 텍스트에 원본 메시지가 포함되어야 합니다.",
          );
        } else {
          expect(
            mockTtsService.currentText,
            contains('Mock AI 응답'),
            reason: "현재 TTS 텍스트에 AI 응답이 포함되어야 합니다.",
          );
        }
      });
    });

    // ========================================================================
    // 글로벌 기능 및 설정 테스트 그룹
    // ========================================================================
    group('🌍 글로벌 기능 테스트', () {
      test('글로벌 메시지 전송', () async {
        // Given: 빈 메시지 상태
        expect(chatProvider.messages, isEmpty);

        // When: 글로벌 메시지 전송 (정적 메서드 호출)
        ChatProvider.sendGlobalMessage('글로벌 테스트 메시지');

        // 비동기 처리 완료 대기 (AI 응답 포함)
        await Future.delayed(const Duration(milliseconds: 500));

        // Then: 사용자 메시지와 AI 응답이 모두 생성되어야 함
        expect(
          chatProvider.messages.length,
          equals(2),
          reason: "글로벌 메시지 전송 후 사용자 메시지와 AI 응답 메시지가 모두 있어야 합니다.",
        );

        // 사용자 메시지 검증
        expect(chatProvider.messages[0]['text'], equals('글로벌 테스트 메시지'));
        expect(chatProvider.messages[0]['isUser'], isTrue);

        // AI 응답 메시지 검증
        expect(chatProvider.messages[1]['text'], contains('Mock AI 응답'));
        expect(chatProvider.messages[1]['text'], contains('글로벌 테스트 메시지'));
        expect(chatProvider.messages[1]['isUser'], isFalse);
      });
    });

    // ========================================================================
    // 오류 처리 테스트 그룹
    // ========================================================================
    group('⚠️ 오류 처리 테스트', () {
      test('네트워크 오류 및 예외 처리', () async {
        // Given: 오류 발생 설정
        mockConversationService.setThrowError(true);

        // When: 오류 상황에서 메시지 전송
        await chatProvider.sendMessage('에러 테스트');

        // Then: 오류가 적절히 처리되어야 함
        expect(chatProvider.error, isNotNull);
        expect(chatProvider.isLoading, isFalse);
      });
    });
  });
}
