import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _textQueue = Queue<String>();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentText;
  int? _currentWordStartPosition;
  bool _isWaitingForNewMessage = false;

  TtsService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.awaitSpeakCompletion(true);
    debugPrint('[TtsService] TTS 초기화 완료');

    _flutterTts.setProgressHandler((
      String text,
      int startOffset,
      int endOffset,
      String word,
    ) {
      _currentWordStartPosition = startOffset;
      debugPrint(
        '[TtsService] 현재 단어 진행 상태: $word (위치: $startOffset-$endOffset)',
      );
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = null;
      _currentWordStartPosition = null;
      debugPrint('[TtsService] 텍스트 재생 완료');
      _playNext();
    });
  }

  /// 텍스트를 큐에 추가합니다.
  Future<void> addToQueue(String text) async {
    if (text.trim().isEmpty) return; // 빈 텍스트는 무시

    debugPrint('[TtsService] 텍스트 큐에 추가: $text');
    _textQueue.add(text);
    if (!_isPlaying && !_isPaused) {
      _playNext();
    }
  }

  /// 큐의 다음 텍스트를 재생합니다.
  Future<void> _playNext() async {
    if (_textQueue.isEmpty) {
      debugPrint('[TtsService] 재생할 텍스트가 없음');
      return;
    }

    String textToPlay = _textQueue.removeFirst().trim();
    if (textToPlay.isEmpty) {
      _playNext(); // 빈 텍스트면 다음 텍스트 재생 시도
      return;
    }

    _currentText = textToPlay;
    _isPlaying = true;
    debugPrint('[TtsService] 다음 텍스트 재생 시작: $_currentText');
    await _flutterTts.speak(_currentText!);
  }

  /// 현재 재생 중인 음성을 일시 정지합니다.
  Future<void> pause() async {
    if (_isPlaying) {
      debugPrint('[TtsService] 재생 일시 정지');
      await _flutterTts.pause();
      _isPaused = true;
      _isPlaying = false;
    }
  }

  /// 일시 정지된 음성을 다시 재생합니다.
  Future<void> resume() async {
    if (_isPaused &&
        _currentText != null &&
        _currentWordStartPosition != null) {
      String remainingText = _currentText!.substring(
        _currentWordStartPosition!,
      );
      debugPrint('[TtsService] 재생 재개: $remainingText');
      _isPaused = false;
      _isPlaying = true;
      await _flutterTts.speak(remainingText);
    }
  }

  /// 현재 재생 중인 음성을 정지하고 큐를 비웁니다.
  Future<void> stop() async {
    debugPrint('[TtsService] 재생 중지 및 큐 초기화');
    await _flutterTts.stop();
    _textQueue.clear();
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
    _currentWordStartPosition = null;
  }

  /// TTS 엔진의 설정을 변경합니다.
  Future<void> setConfiguration({
    double? volume,
    double? pitch,
    double? rate,
    String? language,
  }) async {
    debugPrint(
      '[TtsService] TTS 설정 변경 - volume: $volume, pitch: $pitch, rate: $rate, language: $language',
    );
    if (volume != null) await _flutterTts.setVolume(volume);
    if (pitch != null) await _flutterTts.setPitch(pitch);
    if (rate != null) await _flutterTts.setSpeechRate(rate);
    if (language != null) await _flutterTts.setLanguage(language);
  }

  /// 서비스를 정리합니다.
  Future<void> dispose() async {
    debugPrint('[TtsService] TTS 서비스 정리');
    await stop();
  }

  /// 새로운 메시지를 받았을 때 호출되는 메서드
  Future<void> handleNewMessage(String text) async {
    if (text.trim().isEmpty) return; // 빈 텍스트는 무시

    debugPrint('[TtsService] 새로운 메시지 수신: $text');

    // 현재 재생 중이 아닐 때만 새로운 텍스트 처리
    if (!_isPlaying) {
      // 현재 재생 중인 TTS를 중지
      await stop();
      // 새로운 메시지를 큐에 추가
      await addToQueue(text);
      _isWaitingForNewMessage = false;
    } else {
      // 재생 중이면 큐에만 추가
      _textQueue.add(text);
    }
  }

  /// 새로운 메시지를 기다리는 상태로 설정
  void setWaitingForNewMessage() {
    debugPrint('[TtsService] 새로운 메시지 대기 상태로 전환');
    _isWaitingForNewMessage = true;
  }

  /// 현재 새로운 메시지를 기다리는 중인지 확인
  bool isWaitingForNewMessage() {
    return _isWaitingForNewMessage;
  }

  // 스트리밍 텍스트 처리를 위한 버퍼링 기능
  String _streamBuffer = '';
  static const int _minBufferSize = 30;
  static final RegExp _sentenceEndPattern = RegExp(r'[.!?]+\s*');

  /// 스트리밍 텍스트를 버퍼에 추가하고 처리
  Future<void> addStreamingText(String newText) async {
    if (newText.trim().isEmpty) return;

    _streamBuffer += newText;
    debugPrint('[TtsService] 스트리밍 텍스트 추가: $newText');
    debugPrint('[TtsService] 현재 버퍼: $_streamBuffer');

    // 버퍼가 충분히 쌓였거나 문장이 완성되면 TTS 실행
    if (_streamBuffer.length >= _minBufferSize ||
        _sentenceEndPattern.hasMatch(_streamBuffer)) {
      await _processBufferedText();
    }
  }

  /// 버퍼에 있는 텍스트를 처리
  Future<void> _processBufferedText() async {
    if (_streamBuffer.isEmpty) return;

    // 문장 단위로 분리하여 처리
    final sentences = _streamBuffer.split(_sentenceEndPattern);
    if (sentences.length > 1) {
      // 완성된 문장들 처리
      final completeText =
          sentences.sublist(0, sentences.length - 1).join('. ').trim() + '.';

      if (completeText.isNotEmpty) {
        debugPrint('[TtsService] 완성된 문장 재생: $completeText');
        await addToQueue(completeText);
      }

      // 마지막 미완성 문장은 버퍼에 유지
      _streamBuffer = sentences.last;
    } else if (_streamBuffer.length >= _minBufferSize * 2) {
      // 버퍼가 너무 크면 강제로 처리
      await addToQueue(_streamBuffer.trim());
      _streamBuffer = '';
    }
  }

  /// 스트리밍 완료 시 버퍼의 남은 텍스트 처리
  Future<void> flushStreamBuffer() async {
    if (_streamBuffer.trim().isNotEmpty) {
      debugPrint('[TtsService] 남은 버퍼 내용 재생: $_streamBuffer');
      await addToQueue(_streamBuffer.trim());
      _streamBuffer = '';
    }
  }

  /// 스트리밍 버퍼 초기화
  void clearStreamBuffer() {
    _streamBuffer = '';
    debugPrint('[TtsService] 스트리밍 버퍼 초기화');
  }
}
