import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _textQueue = Queue<String>();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentText;
  int? _currentWordStartPosition;
  Timer? _completionBackupTimer; // completion handler 백업 타이머
  bool _isCompleted = false; // 완료 처리 중복 방지 플래그

  TtsService() {
    debugPrint('[TtsService] 🎤 TtsService 초기화 시작!');
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

      // **Progress Handler에서는 완료 감지 하지 않고 단순히 진행 상태만 로깅**
      // Completion Handler만으로 완료 처리
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('[TtsService] ===== COMPLETION HANDLER 시작 =====');
      debugPrint(
        '[TtsService] 🎯 Completion Handler 호출 시점 큐 상태: ${_textQueue.length}개',
      );
      if (!_isCompleted) {
        debugPrint('[TtsService] completion handler에서 완료 처리');
        _isCompleted = true;
        _handleCompletion();
      } else {
        debugPrint('[TtsService] 이미 완료 처리됨 - 중복 실행 방지');
      }
    });
  }

  /// 텍스트를 큐에 추가합니다.
  Future<void> addToQueue(String text) async {
    debugPrint('[TtsService] 🔥 ===== ADD TO QUEUE 호출 ===== "$text"');

    if (text.trim().isEmpty) {
      debugPrint('[TtsService] 빈 텍스트로 인해 큐 추가 건너뜀');
      return;
    }

    debugPrint(
      '[TtsService] 텍스트 큐에 추가: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"',
    );
    debugPrint(
      '[TtsService] 현재 상태 - 재생중: $_isPlaying, 일시정지: $_isPaused, 큐 크기: ${_textQueue.length}',
    );

    _textQueue.add(text);

    // 현재 재생 중이 아니고 일시정지 상태도 아니라면 즉시 재생 시작
    if (!_isPlaying && !_isPaused) {
      debugPrint('[TtsService] 즉시 재생 시작');
      _playNext();
    } else {
      debugPrint('[TtsService] 현재 재생 중이므로 큐에 대기 (큐 크기: ${_textQueue.length})');
    }
  }

  /// 큐의 다음 텍스트를 재생합니다.
  Future<void> _playNext() async {
    debugPrint('[TtsService] ===== _playNext 호출 직전 =====');
    debugPrint('[TtsService] _playNext 호출 - 큐 크기: ${_textQueue.length}');

    if (_textQueue.isEmpty) {
      debugPrint('[TtsService] ✅ 모든 재생 완료');
      return;
    }

    debugPrint('[TtsService] 🎯 큐에서 텍스트 제거 직전 - 큐 크기: ${_textQueue.length}');
    _currentText = _textQueue.removeFirst();
    debugPrint('[TtsService] 🎯 큐에서 텍스트 제거 완료 - 남은 큐 크기: ${_textQueue.length}');

    _isPlaying = true;
    _isCompleted = false; // 새 재생 시작 시 완료 플래그 리셋

    debugPrint(
      '[TtsService] 다음 텍스트 재생 시작: "${_currentText!.length > 50 ? '${_currentText!.substring(0, 50)}...' : _currentText!}"',
    );

    // 백업 타이머 제거 - completion handler만 사용
    _completionBackupTimer?.cancel();
    debugPrint('[TtsService] 🚀 백업 타이머 없이 순수 TTS 재생 시작');

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
    debugPrint('[TtsService] ===== STOP() 메서드 호출 =====');
    debugPrint('[TtsService] stop() 호출 - 큐 크기: ${_textQueue.length}');

    // 백업 타이머 취소
    _completionBackupTimer?.cancel();

    debugPrint('[TtsService] 재생 중지 및 큐 초기화');
    await _flutterTts.stop();
    _textQueue.clear();
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
    _currentWordStartPosition = null;
    debugPrint('[TtsService] 중단 완료 - 큐 초기화됨: ${_textQueue.length}');

    debugPrint('[TtsService] ===== STOP() 메서드 완료 =====');
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
    _completionBackupTimer?.cancel();
    await stop();
  }

  // ========================================
  // 내부 헬퍼 메서드들
  // ========================================

  /// 공통 완료 처리 메서드
  void _handleCompletion() {
    debugPrint('[TtsService] ===== _handleCompletion 시작 =====');
    debugPrint('[TtsService] 🔍 완료 처리 시작 시점 큐 크기: ${_textQueue.length}');

    // _currentText를 null로 만들기 전에 저장
    final completedText = _currentText ?? "unknown";
    debugPrint('[TtsService] 완료된 텍스트: "$completedText"');

    // 백업 타이머 취소
    _completionBackupTimer?.cancel();

    _isPlaying = false;
    _currentText = null;
    _currentWordStartPosition = null;
    _isCompleted = false; // 다음 재생을 위해 리셋

    debugPrint('[TtsService] ✅ 텍스트 재생 완료 - 상태 초기화됨');
    debugPrint('[TtsService] 🔍 상태 초기화 후 큐 크기: ${_textQueue.length}');

    // 큐 상태 다시 확인
    if (_textQueue.isEmpty) {
      debugPrint('[TtsService] ⚠️ 큐가 비어있음 - 모든 재생 완료');
    } else {
      debugPrint('[TtsService] ✅ 큐에 ${_textQueue.length}개 항목 남아있음');
      debugPrint(
        '[TtsService] 🚀 큐에 남은 첫 번째 항목: "${_textQueue.first.length > 30 ? '${_textQueue.first.substring(0, 30)}...' : _textQueue.first}"',
      );
    }

    // 즉시 다음 재생 (백업 타이머 없이)
    if (_textQueue.isNotEmpty) {
      debugPrint('[TtsService] 🚀 즉시 다음 항목 재생 시작');
      _playNext();
    } else {
      debugPrint('[TtsService] ✅ 모든 재생 완료');
    }
  }
}
