// filepath: c:\Projects\seobi-frontend\lib\services\tts\tts_service.dart
import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:seobi_app/services/tts/clean_text.dart';

/// TTS 서비스 상태 열거형
enum TtsState {
  /// 대기 상태
  idle,

  /// 재생 중 상태
  playing,
}

/// TTS 서비스 클래스
///
/// 음성 합성 서비스를 제공하며 싱글톤 패턴으로 구현됨
class TtsService {
  // 싱글톤 인스턴스
  static TtsService? _instance;

  // 싱글톤 인스턴스 접근 getter
  static TtsService get instance {
    _instance ??= TtsService._internal();
    return _instance!;
  }

  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _textQueue = Queue<String>();
  final Queue<String> _tokenQueue = Queue<String>(); // LLM 토큰을 저장하는 큐
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isEnabled = false; // TTS 활성화 상태

  // 상태 관리 및 알림
  TtsState _state = TtsState.idle;
  final ValueNotifier<TtsState> stateNotifier = ValueNotifier<TtsState>(
    TtsState.idle,
  );
  Timer? _idleTimer; // 상태 전환을 위한 타이머

  String? _currentText;
  int? _currentWordStartPosition;
  bool _isCompleted = false; // 완료 처리 중복 방지 플래그
  final String _sentenceEndPattern = r'[.!?]'; // 문장 끝 패턴 (마침표, 느낌표, 물음표)

  // 내부 생성자로 변경
  TtsService._internal();

  // 팩토리 생성자 추가
  factory TtsService() => instance;

  /// TTS 서비스 초기화
  Future<void> initialize() async {
    debugPrint('[TtsService] TTS 서비스 초기화 시작');
    await _initTTS();
    debugPrint('[TtsService] TTS 서비스 초기화 완료');
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

  /// 토큰 큐의 크기
  int get tokenQueueSize => _tokenQueue.length;

  /// 토큰 큐에 토큰이 있는지 확인
  bool get hasTokens => _tokenQueue.isNotEmpty;

  /// TTS가 활성화되어 있는지 확인
  bool get isEnabled => _isEnabled;

  /// 현재 TTS 서비스 상태 확인
  TtsState get state => _state;

  // ========================================
  // 상태 관리 관련 메서드들
  // ========================================

  /// TTS 상태를 설정합니다.
  void _setState(TtsState newState) {
    if (_state != newState) {
      debugPrint('[TtsService] 상태 변경: $_state -> $newState');
      _state = newState;
      stateNotifier.value = newState;
    }
  }

  /// 타이머를 시작하여 일정 시간 후에 상태를 idle로 변경합니다.
  void _startIdleTimer() {
    // 기존 타이머가 있으면 취소
    _idleTimer?.cancel();

    // 1초 후에 큐가 비어있으면 idle 상태로 전환
    _idleTimer = Timer(const Duration(seconds: 1), () {
      if (!_isPlaying &&
          !_isPaused &&
          _textQueue.isEmpty &&
          _tokenQueue.isEmpty) {
        debugPrint('[TtsService] 모든 큐가 비어있어 idle 상태로 전환');
        _setState(TtsState.idle);
      }
    });
  }

  // ========================================
  // 활성화/비활성화 관련 메서드들
  // ========================================

  /// TTS 기능을 활성화합니다.
  void enable() {
    debugPrint('[TtsService] TTS 기능 활성화');
    _isEnabled = true;
  }

  /// TTS 기능을 비활성화합니다.
  void disable() {
    debugPrint('[TtsService] TTS 기능 비활성화');
    _isEnabled = false;
    // 비활성화 시 현재 재생 중인 TTS와 모든 큐를 중지
  }

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

    // TTS가 비활성화 상태이면 큐에 추가하지 않음
    if (!_isEnabled) {
      debugPrint('[TtsService] TTS 비활성화 상태로 큐 추가 무시');
      return;
    }

    // _checkAndProcessCompleteSentence 또는 flush에서 이미 정돈된 텍스트인지 확인
    // 내부에서 호출될 때는 이미 정돈된 텍스트이므로 다시 정돈하지 않음
    String textToAdd = text;

    // 직접 호출된 경우에만 텍스트 정돈 (중복 정돈 방지)
    // _checkAndProcessCompleteSentence 또는 flush에서 직접 호출한 경우가 아니면 정돈
    StackTrace stackTrace = StackTrace.current;
    if (!stackTrace.toString().contains('_checkAndProcessCompleteSentence') &&
        !stackTrace.toString().contains('flush')) {
      textToAdd = MarkdownTextCleaner.cleanText(text);
      debugPrint(
        '[TtsService] 텍스트 정돈 완료: "${textToAdd.length > 50 ? '${textToAdd.substring(0, 50)}...' : textToAdd}"',
      );
    }

    debugPrint(
      '[TtsService] 텍스트 큐에 추가: "${textToAdd.length > 50 ? '${textToAdd.substring(0, 50)}...' : textToAdd}"',
    );
    debugPrint(
      '[TtsService] 현재 상태 - 재생중: $_isPlaying, 일시정지: $_isPaused, 큐 크기: ${_textQueue.length}',
    );

    _textQueue.add(textToAdd);

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

    // 상태를 playing으로 변경
    _setState(TtsState.playing);

    debugPrint('[TtsService] 🎯 큐에서 텍스트 제거 직전 - 큐 크기: ${_textQueue.length}');
    _currentText = _textQueue.removeFirst();
    debugPrint('[TtsService] 🎯 큐에서 텍스트 제거 완료 - 남은 큐 크기: ${_textQueue.length}');

    _isPlaying = true;
    _isCompleted = false; // 새 재생 시작 시 완료 플래그 리셋
    debugPrint(
      '[TtsService] 다음 텍스트 재생 시작: "${_currentText!.length > 50 ? '${_currentText!.substring(0, 50)}...' : _currentText!}"',
    );

    debugPrint('[TtsService] 🚀 TTS 재생 시작');

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
    debugPrint(
      '[TtsService] stop() 호출 - TTS 큐: ${_textQueue.length}, 토큰 큐: ${_tokenQueue.length}',
    );

    debugPrint('[TtsService] 재생 중지 및 큐 초기화');
    await _flutterTts.stop();
    _textQueue.clear();
    _tokenQueue.clear(); // 토큰 큐도 함께 비움
    _isPlaying = false;
    _isPaused = false;
    _currentText = null;
    _currentWordStartPosition = null;
    debugPrint('[TtsService] 중단 완료 - 모든 큐 초기화됨');

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
    _idleTimer?.cancel();
    await stop();
  }

  // ========================================
  // 내부 헬퍼 메서드들
  // ========================================
  /// 공통 완료 처리 메서드
  void _handleCompletion() {
    debugPrint('[TtsService] ===== _handleCompletion 시작 =====');
    debugPrint(
      '[TtsService] 🔍 완료 처리 시작 시점 큐 크기: ${_textQueue.length}',
    ); // _currentText를 null로 만들기 전에 저장
    final completedText = _currentText ?? "unknown";
    debugPrint('[TtsService] 완료된 텍스트: "$completedText"');

    _isPlaying = false;
    _currentText = null;
    _currentWordStartPosition = null;
    _isCompleted = false; // 다음 재생을 위해 리셋

    debugPrint('[TtsService] ✅ 텍스트 재생 완료 - 상태 초기화됨');
    debugPrint('[TtsService] 🔍 상태 초기화 후 큐 크기: ${_textQueue.length}');

    // 큐 상태 다시 확인
    if (_textQueue.isEmpty) {
      debugPrint('[TtsService] ⚠️ 큐가 비어있음 - 모든 재생 완료');

      // 토큰 큐도 비어있다면 일정 시간 후 idle 상태로 전환
      if (_tokenQueue.isEmpty) {
        debugPrint('[TtsService] 토큰 큐도 비어있음 - 타이머 시작');
        _startIdleTimer();
      } else {
        debugPrint('[TtsService] 토큰 큐에 항목이 남아있음: ');
      }
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

  // ========================================
  // LLM 토큰 처리 관련 메서드들
  // ========================================  /// LLM에서 생성된 토큰을 토큰 큐에 추가합니다.
  Future<void> addToken(String token) async {
    debugPrint('[TtsService] 토큰 추가: "$token"');

    if (token.trim().isEmpty) {
      debugPrint('[TtsService] 빈 토큰으로 인해 추가 건너뜀');
      return;
    }

    // TTS가 비활성화 상태이면 토큰을 추가하지 않음
    if (!_isEnabled) {
      debugPrint('[TtsService] TTS 비활성화 상태로 토큰 추가 무시');
      return;
    }

    // 토큰이 추가되면 상태를 playing으로 변경
    _setState(TtsState.playing);

    // 아이들 타이머가 실행 중이면 취소
    _idleTimer?.cancel();

    _tokenQueue.add(token);
    debugPrint('[TtsService] 토큰 큐 크기: ${_tokenQueue.length}');

    // 토큰을 추가한 후 완성된 문장이 있는지 확인
    await _checkAndProcessCompleteSentence();
  }

  /// 토큰 큐에 완성된 문장이 있는지 확인하고 처리합니다.
  Future<void> _checkAndProcessCompleteSentence() async {
    if (_tokenQueue.isEmpty) return;

    // 큐의 모든 토큰을 하나의 문자열로 합칩니다.
    final combinedText = _tokenQueue.join('');

    // 정규식을 사용하여 문장의 끝을 찾습니다. (마침표, 느낌표, 물음표)
    final RegExp sentenceEndRegex = RegExp(_sentenceEndPattern);
    final match = sentenceEndRegex.firstMatch(combinedText);

    if (match != null) {
      // 문장이 완성된 경우 (마침표, 느낌표, 물음표가 발견된 경우)
      final endIndex = match.end;
      final completeSentence = combinedText.substring(0, endIndex);
      debugPrint('[TtsService] 완성된 문장 발견: "$completeSentence"');

      // 완성된 문장을 정돈
      final cleanedSentence = MarkdownTextCleaner.cleanText(completeSentence);

      // 정돈된 문장을 TTS 큐에 추가
      if (cleanedSentence.isNotEmpty) {
        debugPrint('[TtsService] 정돈된 문장 추가: "$cleanedSentence"');
        await addToQueue(cleanedSentence);
      } else {
        debugPrint('[TtsService] 정돈된 문장이 비어있어 추가하지 않음');
      }

      // 토큰 큐를 비우고 남은 토큰을 다시 큐에 넣습니다.
      _tokenQueue.clear();

      // 처리한 문장 이후의 토큰이 있으면 다시 토큰 큐에 추가
      if (endIndex < combinedText.length) {
        final remainingText = combinedText.substring(endIndex);
        if (remainingText.isNotEmpty) {
          _tokenQueue.add(remainingText);
          debugPrint('[TtsService] 남은 토큰 다시 큐에 추가: "$remainingText"');

          // 남은 토큰으로 다시 문장 완성 여부 확인
          await _checkAndProcessCompleteSentence();
        }
      }
    }
  }

  /// 토큰 큐의 모든 내용을 TTS 큐로 전달합니다.
  Future<void> flush() async {
    if (_tokenQueue.isEmpty) {
      debugPrint('[TtsService] 토큰 큐가 비어있어 flush 작업 없음');
      return;
    } // 큐의 모든 토큰을 하나의 문자열로 합치기
    final combinedText = _tokenQueue.join('');
    debugPrint('[TtsService] flush: 토큰 큐의 모든 내용을 TTS로 전송: "$combinedText"');

    // 토큰 큐 비우기
    _tokenQueue.clear();

    // 텍스트 정돈
    final cleanedText = MarkdownTextCleaner.cleanText(combinedText);
    debugPrint('[TtsService] flush: 정돈된 텍스트: "$cleanedText"');

    // TTS 큐에 추가
    if (cleanedText.trim().isNotEmpty) {
      await addToQueue(cleanedText);
    } else {
      debugPrint('[TtsService] flush: 정돈된 텍스트가 비어있어 추가하지 않음');
    }
  }
}
