import 'package:flutter/material.dart';
import 'package:seobi_app/services/tts/tts_service.dart';
import 'package:seobi_app/services/stt/stt_service.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

/// 인풋 바의 모드 정의
enum InputBarMode {
  text, // 텍스트 입력 모드
  voice, // 음성 입력 모드
}

/// 메시지 전송 이벤트에 대한 콜백 타입 정의
typedef OnMessageSentCallback = void Function(String message);

class InputBarViewModel extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  final STTService _sttService = STTService();
  final TextEditingController textController;
  final FocusNode focusNode;

  // 메시지 전송 시 알림을 받을 리스너 목록
  final List<OnMessageSentCallback> _onMessageSentListeners = [];

  // 모드와 상태 관리 변수
  InputBarMode _currentMode = InputBarMode.text;
  bool _isRecording = false;
  bool _isSendingAfterTts = false;

  // 게터
  InputBarMode get currentMode => _currentMode;
  bool get isRecording => _isRecording;
  bool get isSendingAfterTts => _isSendingAfterTts;
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
  }

  @override
  void dispose() {
    textController.removeListener(notifyListeners);
    // 포커스 리스너 제거
    focusNode.removeListener(_onFocusChange);
    _ttsService.dispose();
    if (_isRecording) {
      _sttService.stopListening();
    }
    _onMessageSentListeners.clear();
    super.dispose();
  }

  // 메시지 전송 메서드
  void sendMessage() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      // 메시지 전송 이벤트 발생 (단순 텍스트만 전달)
      for (final listener in _onMessageSentListeners) {
        listener(text);
      }

      // 메시지 전송 후 텍스트 필드 초기화
      textController.clear();
      notifyListeners();
    }
  }
  // 모드 전환 메서드
  void switchToVoiceMode() {
    _currentMode = InputBarMode.voice;
    debugPrint('InputBar: 음성 모드로 전환');
    textController.clear(); // 음성 모드로 전환 시 텍스트 필드 내용 초기화
    focusNode.unfocus(); // 음성 모드로 전환 시 텍스트 필드 포커스 해제
    startVoiceInput(); // 음성 입력 시작
    notifyListeners();
  }

  void switchToTextMode() {
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
    _isRecording = true;
    debugPrint('InputBar: 음성 인식 시작');
    notifyListeners();

    await _sttService.startListening(
      onResult: (text, isFinal) {
        textController.text = text;        if (isFinal) {
          _isRecording = false;
          _isSendingAfterTts = true;
          debugPrint('InputBar: 음성 인식 결과 최종 확정 - "${text}"');
          notifyListeners();

          // TTS로 음성 피드백
          _ttsService.addToQueue('음성 인식이 완료되었습니다. "${text}" 전송합니다.');          // TTS가 끝나면 자동으로 메시지 전송만 하고 텍스트 모드로는 전환하지 않음
          Future.delayed(const Duration(seconds: 2), () {
            if (_isSendingAfterTts) {
              sendMessage();
              _isSendingAfterTts = false;
              notifyListeners();
            }
          });
        }
      },      onSpeechComplete: () {
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
