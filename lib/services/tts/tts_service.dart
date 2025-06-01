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

  TtsService() {
    _initTTS();
  }

  // ========================================
  // 상태 확인용 Getter들
  // ========================================

  /// 현재 TTS가 재생 중인지 확인
  bool get isPlaying => _isPlaying;

  /// 현재 TTS가 일시정지 중인지 확인
  bool get isPaused => _isPaused;

  /// 큐에 대기 중인 텍스트가 있는지 확인
  bool get hasQueuedItems => _textQueue.isNotEmpty;

  /// 현재 TTS가 활성 상태인지 확인 (재생 중이거나 큐에 대기 중)
  bool get isActive => _isPlaying || _isPaused || _textQueue.isNotEmpty;

  /// 현재 큐 크기
  int get queueSize => _textQueue.length;

  // ========================================
  // TTS 초기화 및 핸들러
  // ========================================

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
    if (text.trim().isEmpty) {
      debugPrint('[TtsService] 빈 텍스트로 인해 큐 추가 건너뜀');
      return;
    }

    debugPrint(
      '[TtsService] 텍스트 큐에 추가: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"',
    );
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

    _currentText = _textQueue.removeFirst();
    _isPlaying = true;
    debugPrint(
      '[TtsService] 다음 텍스트 재생 시작: "${_currentText!.length > 50 ? '${_currentText!.substring(0, 50)}...' : _currentText!}"',
    );
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
}
