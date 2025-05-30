import 'package:flutter/foundation.dart';
import '../../repositories/backend/models/message.dart';
import '../../repositories/backend/models/session.dart';
import '../auth/auth_service.dart';
import '../tts/tts_service.dart';
import '../stt/stt_service.dart';
import 'conversation_service.dart';

typedef OnMessageCallback = void Function(Message message);
typedef OnErrorCallback = void Function(String error);

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ConversationService _conversationService = ConversationService();
  final AuthService _authService = AuthService();
  final TtsService _ttsService = TtsService();
  final STTService _sttService = STTService();

  Session? _currentSession;
  bool _isInitialized = false;

  // 콜백 함수들
  OnMessageCallback? _onMessageReceived;
  OnErrorCallback? _onError;

  /// 채팅 서비스 초기화
  Future<bool> initialize({
    OnMessageCallback? onMessageReceived,
    OnErrorCallback? onError,
  }) async {
    _onMessageReceived = onMessageReceived;
    _onError = onError;

    try {
      // 인증 체크
      if (!_authService.isLoggedIn) {
        _onError?.call('사용자 인증이 필요합니다.');
        return false;
      }

      // TTS 초기화
      await _ttsService.setConfiguration(language: 'ko-KR', volume: 1.0);

      // STT 초기화
      final sttAvailable = await _sttService.initialize();
      if (!sttAvailable) {
        debugPrint('[ChatService] STT를 사용할 수 없습니다.');
      }

      // 세션 생성
      _currentSession = await _conversationService.createSession(
        isAIChat: true,
      );
      debugPrint('[ChatService] 채팅 서비스 초기화 완료');

      _isInitialized = true;
      return true;
    } catch (e) {
      _onError?.call('채팅 초기화 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 메시지 전송
  Future<void> sendMessage(String content) async {
    if (!_isInitialized || _currentSession == null) {
      _onError?.call('채팅 서비스가 초기화되지 않았습니다.');
      return;
    }

    if (content.trim().isEmpty) {
      _onError?.call('메시지를 입력해주세요.');
      return;
    }

    final userId = _authService.userId;
    if (userId == null) {
      _onError?.call('사용자 인증이 필요합니다.');
      return;
    }

    try {
      // TTS 중지
      await _ttsService.stop();

      // 사용자 메시지 생성
      final userMessage = Message(
        id: DateTime.now().toIso8601String(),
        sessionId: _currentSession!.id,
        userId: userId,
        content: content,
        role: Message.ROLE_USER,
        timestamp: DateTime.now(),
      );
      _onMessageReceived?.call(userMessage);

      // AI 응답 메시지 초기화
      final aiMessage = Message(
        id: 'streaming',
        sessionId: _currentSession!.id,
        userId: userId,
        content: '',
        role: Message.ROLE_ASSISTANT,
        timestamp: DateTime.now(),
      );
      _onMessageReceived?.call(aiMessage);

      // 스트리밍 응답 처리
      String bufferedText = '';
      _ttsService.clearStreamBuffer(); // 스트리밍 시작 전 버퍼 초기화

      final response = await _conversationService.sendMessageStream(
        sessionId: _currentSession!.id,
        content: content,
        onProgress: (partialResponse) async {
          if (partialResponse.length > bufferedText.length) {
            final newText = partialResponse.substring(bufferedText.length);
            bufferedText = partialResponse;

            final updatedAiMessage = aiMessage.copyWith(content: bufferedText);
            _onMessageReceived?.call(updatedAiMessage);

            // 새로운 텍스트를 TTS 스트리밍 버퍼에 추가
            await _ttsService.addStreamingText(newText);
          }
        },
      );

      // 최종 AI 응답
      final finalAiMessage = aiMessage.copyWith(
        id: DateTime.now().toIso8601String(),
        content: response.content,
      );
      _onMessageReceived?.call(finalAiMessage);

      // 스트리밍 완료 후 남은 버퍼 처리
      await _ttsService.flushStreamBuffer();
    } catch (e) {
      _onError?.call('메시지 전송 중 오류가 발생했습니다: $e');
    }
  }

  /// 음성 인식 시작/중지
  Future<void> toggleVoiceRecognition({
    required Function(String text, bool isFinal) onResult,
    VoidCallback? onSpeechComplete,
  }) async {
    // TTS 중지
    await _ttsService.stop();

    if (_sttService.isListening) {
      await _sttService.stopListening();
    } else {
      await _sttService.startListening(
        onResult: onResult,
        onSpeechComplete: onSpeechComplete,
      );
    }
  }

  /// TTS 재생
  Future<void> playTTS(String text) async {
    await _ttsService.stop();
    await _ttsService.addToQueue(text);
  }

  /// TTS 중지
  Future<void> stopTTS() async {
    await _ttsService.stop();
  }

  /// 세션 메시지 가져오기
  Future<List<Message>> getSessionMessages() async {
    if (_currentSession == null) {
      return [];
    }

    try {
      return await _conversationService.getSessionMessages(
        _currentSession!.id,
        isAIChat: true,
      );
    } catch (e) {
      _onError?.call('메시지 로드 중 오류가 발생했습니다: $e');
      return [];
    }
  }

  /// 리소스 정리
  Future<void> dispose() async {
    if (_currentSession != null) {
      await _conversationService.endSession(_currentSession!.id);
    }
    await _ttsService.dispose();
    if (_sttService.isListening) {
      await _sttService.stopListening();
    }
    _isInitialized = false;
    debugPrint('[ChatService] 리소스 정리 완료');
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _sttService.isListening;
  Session? get currentSession => _currentSession;
}
