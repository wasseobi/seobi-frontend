import 'package:flutter/material.dart';
import '../../../../services/tts/tts_service.dart';
import '../../../../services/stt/stt_service.dart';

/// 메시지 전송 이벤트에 대한 콜백 타입 정의
typedef OnMessageSentCallback = void Function(String message);

class InputBarViewModel extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  final STTService _sttService = STTService();
  final TextEditingController textController;
  final FocusNode focusNode;
  
  // 메시지 전송 시 알림을 받을 리스너 목록
  final List<OnMessageSentCallback> _onMessageSentListeners = [];
  
  bool _isRecording = false;
  bool _isSendingAfterTts = false;
  
  bool get isRecording => _isRecording;
  bool get isSendingAfterTts => _isSendingAfterTts;
  bool get isEmpty => textController.text.isEmpty;
  
  // 메시지 전송 리스너 추가 메서드
  void addOnMessageSentListener(OnMessageSentCallback listener) {
    _onMessageSentListeners.add(listener);
  }
  
  // 메시지 전송 리스너 제거 메서드
  void removeOnMessageSentListener(OnMessageSentCallback listener) {
    _onMessageSentListeners.remove(listener);
  }

  InputBarViewModel({
    required this.textController,
    required this.focusNode,
  }) {
    _sttService.initialize();
    textController.addListener(notifyListeners);
  }
  @override
  void dispose() {
    textController.removeListener(notifyListeners);
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

  void handleButtonPress() {
    if (textController.text.isEmpty) {
      startVoiceInput();
    } else {
      sendMessage();
    }
  }
  
  void clearText() {
    textController.clear();
    notifyListeners();
  }
  
  Future<void> startVoiceInput() async {
    _isRecording = true;
    notifyListeners();

    await _sttService.startListening(
      onResult: (text, isFinal) {
        textController.text = text;

        if (isFinal) {
          _isRecording = false;
          _isSendingAfterTts = true;
          notifyListeners();

          // TTS로 음성 피드백
          _ttsService.addToQueue('음성 인식이 완료되었습니다. "${text}" 전송합니다.');

          // TTS가 끝나면 자동으로 메시지 전송
          Future.delayed(const Duration(seconds: 2), () {
            if (_isSendingAfterTts) {
              sendMessage();
              _isSendingAfterTts = false;
              notifyListeners();
            }
          });
        }
      },
      onSpeechComplete: () {
        _isRecording = false;
        notifyListeners();
      },
    );
  }
}
