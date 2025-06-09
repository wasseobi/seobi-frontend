import 'package:flutter/material.dart';
import 'package:seobi_app/services/tts/tts_service.dart';
import 'package:seobi_app/services/stt/stt_service.dart';
import 'package:seobi_app/services/conversation/conversation_service2.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

/// 인풋 바의 모드 정의
enum InputBarMode {
  text, // 텍스트 입력 모드
  voice, // 음성 입력 모드
}

/// 메시지 전송 이벤트에 대한 콜백 타입 정의
typedef OnMessageSentCallback = void Function(String message);

class InputBarViewModel extends ChangeNotifier {
  final TtsService _ttsService = TtsService.instance;
  final SttService _sttService = SttService();
  final ConversationService2 _conversationService = ConversationService2();
  final TextEditingController textController;
  final FocusNode focusNode;

  // 메시지 전송 시 알림을 받을 리스너 목록
  final List<OnMessageSentCallback> _onMessageSentListeners = [];

  // 모드와 상태 관리 변수
  InputBarMode _currentMode = InputBarMode.text;
  bool _isRecording = false;
  bool _isSendingAfterTts = false;
  bool _isSending = false; // 메시지 전송 중 상태 추가
  // 게터
  InputBarMode get currentMode => _currentMode;
  bool get isRecording => _isRecording;
  bool get isSendingAfterTts => _isSendingAfterTts;
  bool get isSending => _isSending;
  bool get isEmpty => textController.text.isEmpty;

  // 액션 버튼 상태 게터
  IconData get actionButtonIcon {
    if (_currentMode == InputBarMode.text) {
      return isEmpty ? Icons.mic : Icons.send;
    } else {
      return isRecording ? Icons.stop : Icons.mic;
    }
  }

  Color get actionButtonColor {
    if (_currentMode == InputBarMode.text) {
      return AppColors.main100;
    } else {
      return isRecording ? Colors.red : AppColors.main100;
    }
  }

  String get hintText {
    if (_currentMode == InputBarMode.text) {
      return '메시지를 입력하세요...';
    } else {
      return isRecording ? '듣고 있습니다. 말씀하세요...' : '버튼을 누르고 말해보세요.';
    }
  }

  // 메시지 전송 리스너 추가 메서드
  void addOnMessageSentListener(OnMessageSentCallback listener) {
    _onMessageSentListeners.add(listener);
  }

  // 메시지 전송 리스너 제거 메서드
  void removeOnMessageSentListener(OnMessageSentCallback listener) {
    _onMessageSentListeners.remove(listener);
  }

  InputBarViewModel({required this.textController, required this.focusNode}) {
    _sttService.initialize();
    textController.addListener(notifyListeners);

    // 포커스 리스너 추가 - 텍스트 필드가 포커스를 받으면 텍스트 모드로 전환
    focusNode.addListener(_onFocusChange);

    // TTS 상태 변경 리스너 추가
    _ttsService.stateNotifier.addListener(_onTtsStateChanged);
  }

  @override
  void dispose() {
    textController.removeListener(notifyListeners);
    // 포커스 리스너 제거
    focusNode.removeListener(_onFocusChange);
    // TTS 상태 변경 리스너 제거
    _ttsService.stateNotifier.removeListener(_onTtsStateChanged);
    _ttsService.dispose();
    if (_isRecording) {
      _sttService.stopListening();
    }
    _onMessageSentListeners.clear();
    super.dispose();
  }

  // TTS 상태 변경 시 호출되는 메서드
  void _onTtsStateChanged() {
    final currentState = _ttsService.stateNotifier.value;
    if (currentState == TtsState.idle) {
      debugPrint('[InputBarViewModel] 🔊 TTS 상태 변경 감지: IDLE 상태로 전환됨');
      if (currentMode == InputBarMode.voice) {
        startVoiceInput();
      }
      // idle 상태에서 필요한 추가 작업이 있으면 여기에 구현
    } else if (currentState == TtsState.playing) {
      debugPrint('[InputBarViewModel] 🔊 TTS 상태 변경 감지: PLAYING 상태로 전환됨');
    }
  }

  // 메시지 전송 메서드
  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      debugPrint('[InputBarViewModel] 메시지 전송: "$text"');

      try {
        _isSending = true;
        notifyListeners();

        // **새로운 메시지 전송 시 기존 TTS 중단**
        _ttsService.stop();
        debugPrint('[InputBarViewModel] 새 메시지 전송으로 인한 TTS 중단');

        // ConversationService2로 메시지 전송
        _conversationService.sendMessage(text);
        debugPrint('[InputBarViewModel] 메시지 전송 완료');

        // 기존 리스너들에게도 알림 (호환성 유지)
        for (final listener in _onMessageSentListeners) {
          listener(text);
        }

        // 메시지 전송 후 텍스트 필드 초기화
        textController.clear();
      } catch (e) {
        debugPrint('[InputBarViewModel] 메시지 전송 오류: $e');
        // 에러 처리 - UI에 에러 표시할 수 있음
      } finally {
        _isSending = false;
        notifyListeners();
      }
    }
  }

  // 모드 전환 메서드
  void switchToVoiceMode() {
    // **음성 모드 전환 시 기존 TTS 중단**
    if (!_ttsService.isEnabled) {
      _ttsService.enable();
    }
    _ttsService.stop();

    debugPrint('[InputBarViewModel] 음성 모드 전환으로 인한 TTS 중단');

    _currentMode = InputBarMode.voice;
    debugPrint('InputBar: 음성 모드로 전환');
    textController.clear(); // 음성 모드로 전환 시 텍스트 필드 내용 초기화
    focusNode.unfocus(); // 음성 모드로 전환 시 텍스트 필드 포커스 해제
    startVoiceInput(); // 음성 입력 시작
    notifyListeners();
  }

  void switchToTextMode() {
    if (_ttsService.isEnabled) {
      _ttsService.disable();
    }

    _currentMode = InputBarMode.text;
    debugPrint('InputBar: 텍스트 모드로 전환');
    stopVoiceInput(); // 텍스트 모드로 전환 시 음성 입력 중지
    notifyListeners();
  }

  // 액션 버튼 핸들러
  void handleButtonPress() {
    if (_currentMode == InputBarMode.text) {
      // 텍스트 모드에서의 동작
      if (isEmpty) {
        switchToVoiceMode();
      } else {
        // 비동기 메시지 전송
        sendMessage();
      }
    } else {
      // 음성 모드에서의 동작
      if (isRecording) {
        stopVoiceInput();
      } else {
        startVoiceInput();
      }
    }
  }

  void clearText() {
    textController.clear();
    notifyListeners();
  }

  Future<void> startVoiceInput() async {
    // **음성 입력 시작 시 기존 TTS 중단 (추가 보장)**
    await _ttsService.stop();
    debugPrint('[InputBarViewModel] 음성 입력 시작으로 인한 TTS 중단');

    _isRecording = true;
    debugPrint('InputBar: 음성 인식 시작');
    notifyListeners();

    await _sttService.startListening(
      onResult: (text, isFinal) {
        textController.text = text;
        if (isFinal) {
          _isRecording = false;
          _isSendingAfterTts = true;
          debugPrint('[InputBarViewModel]: 음성 인식 결과 최종 확정 - "${text}"');
          notifyListeners();

          // **STT 완료 시 기존 TTS 중단 후 피드백 제공**
          _ttsService.stop().then((_) {
            // TTS 피드백 후 메시지 전송
            Future.delayed(const Duration(seconds: 2), () async {
              if (_isSendingAfterTts) {
                await sendMessage(); // 비동기 메서드로 변경
                _isSendingAfterTts = false;
                notifyListeners();
              }
            });
          });
        }
      },
      onSpeechComplete: () {
        _isRecording = false;
        debugPrint('InputBar: 음성 인식 완료');
        notifyListeners();
      },
    );
  }

  // 음성 입력 중지
  void stopVoiceInput() {
    if (_isRecording) {
      _sttService.stopListening();
      _isRecording = false;
      debugPrint('InputBar: 음성 인식 중지');
      notifyListeners();
    }
  }

  // 포커스 변경 시 호출되는 메서드
  void _onFocusChange() {
    // 음성 모드일 때 텍스트 필드가 포커스를 받으면 텍스트 모드로 전환
    if (focusNode.hasFocus && _currentMode == InputBarMode.voice) {
      switchToTextMode();
    }
  }

  // 텍스트 필드 터치 핸들러 - 음성 모드에서 텍스트 모드로 전환
  void handleTextFieldTap() {
    if (_currentMode == InputBarMode.voice) {
      switchToTextMode();
    }
  }
}
