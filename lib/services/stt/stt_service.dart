import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef OnRecognitionResultCallback = void Function(String text, bool isFinal);

class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<stt.LocaleName>? _locales;

  Future<bool> initialize() async {
    final isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('[STTService] Error: $error'),
      debugLogging: true,
    );
    if (isInitialized) {
      _locales = await _speech.locales();
      // 사용 가능한 언어 확인
      debugPrint(
        '[STTService] Available locales: ${_locales?.map((e) => e.localeId)}',
      );
    }
    return isInitialized;
  }

  Future<void> startListening({
    required OnRecognitionResultCallback onResult,
    VoidCallback? onSpeechComplete,
  }) async {
    if (_locales == null) {
      await initialize();
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final recognizedText =
              result.recognizedWords.isEmpty ? '' : result.recognizedWords;
          onResult(recognizedText, result.finalResult);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          // 사운드 레벨 변화 감지
        },
        cancelOnError: true,
        partialResults: true,
        localeId: 'ko-KR',
      );

      _speech.statusListener = (status) {
        if (status == 'done' && onSpeechComplete != null) {
          onSpeechComplete();
        }
      };
    } catch (e) {
      debugPrint('[STTService] Error while starting listening: $e');
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
