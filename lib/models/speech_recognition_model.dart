class SpeechRecognitionData {
  final String recognizedText;
  final bool isListening;
  final DateTime timestamp;

  SpeechRecognitionData({
    required this.recognizedText,
    required this.isListening,
    required this.timestamp,
  });

  SpeechRecognitionData copyWith({
    String? recognizedText,
    bool? isListening,
    DateTime? timestamp,
  }) {
    return SpeechRecognitionData(
      recognizedText: recognizedText ?? this.recognizedText,
      isListening: isListening ?? this.isListening,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
