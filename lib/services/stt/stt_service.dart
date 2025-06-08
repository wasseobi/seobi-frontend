import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef OnRecognitionResultCallback = void Function(String text, bool isFinal);

class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  Future<void> startListening({
    required OnRecognitionResultCallback onResult,
    VoidCallback? onSpeechComplete,
    String localeId = 'ko-KR',
  }) async {
    await _speech.listen(
      onResult: (result) {
        final recognizedText =
            result.recognizedWords.isEmpty ? '' : result.recognizedWords;
        onResult(recognizedText, result.finalResult);
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        // 사운드 레벨 변화 감지
      },
      cancelOnError: true,
      partialResults: true,
      localeId: localeId,
    );

    _speech.statusListener = (status) {
      if (status == 'done' && onSpeechComplete != null) {
        onSpeechComplete();
      }
    };
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  /// 리소스 정리
  Future<void> dispose() async {
    if (_speech.isListening) {
      await stopListening();
    }
  }
}
