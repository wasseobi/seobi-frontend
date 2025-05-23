import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef OnRecognitionResultCallback = void Function(String text, bool isFinal);

class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  Future<void> startListening({
    required OnRecognitionResultCallback onResult,
    String localeId = 'ko-KR',
  }) async {
    await _speech.listen(
      onResult: (result) {
        final recognizedText =
            result.recognizedWords.isEmpty ? '' : result.recognizedWords;
        onResult(recognizedText, result.finalResult);
      },
      partialResults: true,
      localeId: localeId,
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
