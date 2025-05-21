import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/speech_recognition_model.dart';

class SpeechService {
  late stt.SpeechToText _speech;
  Function(SpeechRecognitionData)? onResultCallback;
  Function(bool)? onListeningStatusChanged;

  SpeechService() {
    _speech = stt.SpeechToText();
  }

  Future<bool> initialize() async {
    return await _speech.initialize(
      onStatus: (status) {
        bool isListening = status != 'done' && status != 'notListening';
        onListeningStatusChanged?.call(isListening);
      },
      onError: (error) {
        onListeningStatusChanged?.call(false);
      },
    );
  }

  void startListening() {
    if (!_speech.isListening) {
      _speech.listen(
        onResult: (result) {
          if (onResultCallback != null) {
            onResultCallback!(
              SpeechRecognitionData(
                recognizedText: result.recognizedWords,
                isListening: true,
                timestamp: DateTime.now(),
              ),
            );
          }
        },
      );
    }
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }
}
