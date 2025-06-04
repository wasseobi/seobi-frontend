import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/tts/tts_service.dart';

/// 채팅에서 사용되는 TTS 기능을 전담하는 매니저 클래스
///
/// **주요 기능:**
/// - 마크다운 → 일반 텍스트 변환
/// - 실시간 스트리밍 TTS 처리
/// - 백그라운드 TTS 실행
/// - TTS 중단 및 상태 관리
///
/// **사용법:**
/// ```dart
/// final ttsManager = ChatTtsManager();
/// ttsManager.processStreamingResponse(partialText);
/// ttsManager.processResponseForTts(fullText);
/// ```
class ChatTtsManager {
  final TtsService _ttsService;
  bool _isDisposed = false;

  // ========================================
  // 🎯 TTS 처리 설정값 (성능 최적화됨)
  // ========================================

  /// 기본 청크 처리 설정
  static const int _minChunkLength = 8; // 최소 청크 길이 (단축됨)
  static const int _maxChunkLength = 100; // 최대 청크 길이

  /// 스트리밍 지연 설정 (빠른 처리)
  static const int _streamingDelayMs = 100; // 일반 처리 지연 (단축됨)
  static const int _fastProcessDelayMs = 50; // 첫 번째 청크 빠른 처리

  /// 첫 번째 청크 특별 처리 설정
  static const int _firstChunkMinLength = 5; // 첫 번째 청크 최소 길이

  // ========================================
  // 🎬 실시간 스트리밍 TTS 상태
  // ========================================

  String _currentStreamingText = ''; // 현재 스트리밍 텍스트
  int _lastProcessedPosition = 0; // 마지막 처리 위치
  Set<String> _processedChunks = {}; // 처리된 텍스트 청크들
  bool _isStreamingActive = false; // 스트리밍 활성 상태
  Timer? _streamingTimer; // 지연 처리용 타이머

  // ========================================
  // 🏗️ 생성자 및 초기화
  // ========================================

  ChatTtsManager({TtsService? ttsService})
    : _ttsService = ttsService ?? TtsService() {
    debugPrint('[ChatTtsManager] 🎯 TTS 매니저 초기화 완료');
    debugPrint('[ChatTtsManager] 🎯 서비스: ${_ttsService.runtimeType}');
  }

  // ========================================
  // 🎮 주요 공개 메서드들
  // ========================================

  /// **TTS 즉시 중단**
  ///
  /// 새로운 메시지 전송 시 기존 TTS를 중단합니다.
  /// 스트리밍 상태도 함께 초기화됩니다.
  Future<void> stopTts() async {
    if (_isDisposed) return;

    try {
      debugPrint('[ChatTtsManager] ⏹️ TTS 중단 시작');
      _resetStreamingState();
      await _ttsService.stop();
      debugPrint('[ChatTtsManager] ✅ TTS 중단 완료');
    } catch (e) {
      debugPrint('[ChatTtsManager] ❌ TTS 중단 오류: $e');
    }
  }

  /// **🚀 실시간 스트리밍 TTS**
  ///
  /// AI 응답이 생성되는 동안 실시간으로 TTS를 처리합니다.
  ///
  /// **특징:**
  /// - 첫 번째 청크: 50ms 지연, 5자부터 처리
  /// - 이후 청크: 100ms 지연, 8자부터 처리
  /// - 자동 문장 감지 및 자연스러운 끊어읽기
  ///
  /// ```dart
  /// onProgress: (partialText) {
  ///   ttsManager.processStreamingResponse(partialText);
  /// }
  /// ```
  void processStreamingResponse(String partialResponse) {
    if (_isDisposed || partialResponse.trim().isEmpty) {
      if (partialResponse.trim().isEmpty) {
        debugPrint('[ChatTtsManager] ⚠️ 빈 응답 무시');
      }
      return;
    }

    // 스트리밍 활성화
    if (!_isStreamingActive) {
      _isStreamingActive = true;
      debugPrint('[ChatTtsManager] 🎬 실시간 TTS 시작');
    }

    _currentStreamingText = partialResponse;
    debugPrint(
      '[ChatTtsManager] 📺 업데이트: ${partialResponse.length}자 (처리위치: $_lastProcessedPosition)',
    );

    _scheduleStreamingProcessing();
  }

  /// **응답 완료 후 TTS 처리**
  ///
  /// 마크다운을 일반 텍스트로 변환 후 TTS 큐에 추가합니다.
  /// 스트리밍이 활성화된 경우 최종 정리를 수행합니다.
  void processResponseForTts(String content) {
    if (_isDisposed || content.trim().isEmpty) {
      if (content.trim().isEmpty) {
        debugPrint('[ChatTtsManager] ⚠️ 빈 내용 무시');
      }
      return;
    }

    if (_isStreamingActive) {
      debugPrint('[ChatTtsManager] 🏁 스트리밍 완료 - 최종 처리');
      _currentStreamingText = content;
      _processFinalStreamingContent();
      _resetStreamingState();
    } else {
      debugPrint('[ChatTtsManager] 🎤 완성된 응답 처리: ${content.length}자');
      _processTtsInBackground(content);
    }
  }

  /// **스트리밍 TTS 강제 완료**
  ///
  /// 현재 진행 중인 스트리밍을 즉시 완료 처리합니다.
  void finishStreamingTts() {
    if (_isDisposed || !_isStreamingActive) return;

    debugPrint('[ChatTtsManager] ⏹️ 스트리밍 강제 완료');
    _processFinalStreamingContent();
    _resetStreamingState();
  }

  // ========================================
  // 📊 상태 확인 프로퍼티들
  // ========================================

  /// TTS 매니저가 정리되었는지 확인
  bool get isDisposed => _isDisposed;

  /// 현재 스트리밍 TTS가 활성 상태인지 확인
  bool get isStreamingActive => _isStreamingActive;

  /// **리소스 정리**
  ///
  /// TTS 서비스와 스트리밍 상태를 모두 정리합니다.
  void dispose() {
    if (_isDisposed) return;

    debugPrint('[ChatTtsManager] 🧹 리소스 정리 시작');
    _resetStreamingState();
    _isDisposed = true;
    _ttsService.dispose();
    debugPrint('[ChatTtsManager] ✅ 정리 완료');
  }

  // ========================================
  // 🔧 내부 핵심 메서드들
  // ========================================

  /// **백그라운드 TTS 처리** (빠른 실행)
  void _processTtsInBackground(String content) {
    if (_isDisposed) return;

    // UI 차단 없이 백그라운드에서 비동기 실행
    Future.microtask(() async {
      if (_isDisposed) return; // 비동기 중에도 dispose 체크

      try {
        final ttsText = _convertMarkdownToTtsText(content);
        debugPrint('[ChatTtsManager] 🧹 변환 완료: ${ttsText.length}자');
        debugPrint(
          '[ChatTtsManager] 📝 텍스트: "${ttsText.length > 50 ? '${ttsText.substring(0, 50)}...' : ttsText}"',
        );

        if (ttsText.isNotEmpty && !_isDisposed) {
          _ttsService.addToQueue(ttsText);
          debugPrint('[ChatTtsManager] 🚀 큐 추가 완료');
        } else if (ttsText.isEmpty) {
          debugPrint('[ChatTtsManager] ⚠️ 변환 후 텍스트가 비어있음');
        }
      } catch (e) {
        debugPrint('[ChatTtsManager] ❌ 백그라운드 처리 오류: $e');
      }
    });
  }

  /// **마크다운 → TTS 텍스트 변환** (최적화됨)
  String _convertMarkdownToTtsText(String markdown) {
    String text = markdown;

    // 1️⃣ 링크 처리: [텍스트](URL) → 텍스트
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 2️⃣ URL 제거
    text = text.replaceAll(RegExp(r'https?://[^\s\n]+'), '');

    // 3️⃣ 볼드: **텍스트** → 텍스트
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*\n]+?)\*\*'),
      (match) => match.group(1) ?? '',
    );

    // 4️⃣ 이탤릭: *텍스트* → 텍스트
    text = text.replaceAllMapped(
      RegExp(r'(?<!\s)\*([^*\n\s][^*\n]*?)\*(?!\s)'),
      (match) => match.group(1) ?? '',
    );

    // 5️⃣ 헤딩: ### 텍스트 → 텍스트
    text = text.replaceAllMapped(
      RegExp(r'^#{1,6}\s*(.+)$', multiLine: true),
      (match) => match.group(1) ?? '',
    );

    // 6️⃣ 리스트 마커 제거
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '');

    // 7️⃣ 코드 블록 제거
    text = text.replaceAll(RegExp(r'```[^`]*```', dotAll: true), '');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), '');

    // 8️⃣ 최종 정리
    text = text.replaceAll(RegExp(r'\*+'), ''); // 남은 * 제거
    text = text.replaceAll(RegExp(r'\$\d+'), ''); // 정규식 잔여물 제거
    text = text.replaceAll(RegExp(r'\s+'), ' '); // 공백 정리

    return text.trim();
  }

  // ========================================
  // 🛠️ 유틸리티 메서드들
  // ========================================

  /// **TTS 적합성 검증**
  bool isValidForTts(String text) {
    final cleanText = text.trim();
    return cleanText.isNotEmpty && cleanText.length >= 2;
  }

  /// **마크다운 포함 여부 확인**
  bool containsMarkdown(String text) {
    return text.contains(RegExp(r'[*#`\[\]()]'));
  }

  /// **TTS 텍스트 미리보기** (디버깅용)
  String getTtsPreview(String markdown, {int maxLength = 100}) {
    final ttsText = _convertMarkdownToTtsText(markdown);
    return ttsText.length > maxLength
        ? '${ttsText.substring(0, maxLength)}...'
        : ttsText;
  }

  // ========================================
  // 🎬 실시간 스트리밍 TTS 처리 로직
  // ========================================

  /// **스트리밍 상태 초기화**
  void _resetStreamingState() {
    _currentStreamingText = '';
    _lastProcessedPosition = 0;
    _processedChunks.clear();
    _isStreamingActive = false;
    _streamingTimer?.cancel();
    _streamingTimer = null;
    debugPrint('[ChatTtsManager] 🔄 스트리밍 상태 초기화');
  }

  /// **스트리밍 처리 스케줄링** (디바운싱)
  void _scheduleStreamingProcessing() {
    if (_isDisposed || !_isStreamingActive) return;

    _streamingTimer?.cancel(); // 기존 타이머 취소

    // 🚀 첫 번째 청크는 더 빠르게 처리
    final isFirstChunk =
        _lastProcessedPosition == 0 && _processedChunks.isEmpty;
    final delay = isFirstChunk ? _fastProcessDelayMs : _streamingDelayMs;

    if (isFirstChunk) {
      debugPrint('[ChatTtsManager] ⚡ 첫 청크 빠른 처리: ${delay}ms');
    }

    _streamingTimer = Timer(Duration(milliseconds: delay), () {
      _processStreamingContent();
    });
  }

  /// **실시간 스트리밍 콘텐츠 처리** (핵심 로직)
  void _processStreamingContent() {
    if (_isDisposed || !_isStreamingActive) return;

    try {
      final newContent = _currentStreamingText;
      if (newContent.length <= _lastProcessedPosition) {
        debugPrint('[ChatTtsManager] 📊 새 콘텐츠 없음');
        return;
      }

      final unprocessedText = newContent.substring(_lastProcessedPosition);
      final isFirstChunk =
          _lastProcessedPosition == 0 && _processedChunks.isEmpty;

      debugPrint(
        '[ChatTtsManager] 🔍 처리 대상: "${_truncateText(unprocessedText, 30)}" (첫청크: $isFirstChunk)',
      );

      // 🚀 첫 번째 청크 우선 처리
      if (isFirstChunk && unprocessedText.length >= _firstChunkMinLength) {
        final firstWord = _extractFirstCompleteWord(unprocessedText);
        if (firstWord.isNotEmpty && firstWord.length >= _firstChunkMinLength) {
          debugPrint('[ChatTtsManager] ⚡ 첫 청크 긴급 처리: "$firstWord"');
          _processSentenceForTts(firstWord);
          return;
        }
      }

      // 1️⃣ 완성된 문장 찾기 (최우선)
      final completedSentences = _extractCompletedSentences(unprocessedText);
      if (completedSentences.isNotEmpty) {
        for (final sentence in completedSentences) {
          _processSentenceForTts(sentence);
        }
        return;
      }

      // 2️⃣ 긴 텍스트의 자연스러운 끊는 지점
      if (unprocessedText.length > _maxChunkLength) {
        final naturalBreakPoint = _findNaturalBreakPoint(unprocessedText);
        if (naturalBreakPoint > _minChunkLength) {
          final chunk = unprocessedText.substring(0, naturalBreakPoint);
          _processSentenceForTts(chunk);
          return;
        }
      }

      // 3️⃣ 조건 완화: 충분한 길이가 되면 처리
      if (unprocessedText.length >= _minChunkLength + 5) {
        final earlyBreakPoint = _findEarlyBreakPoint(unprocessedText);
        if (earlyBreakPoint > 0) {
          final chunk = unprocessedText.substring(0, earlyBreakPoint);
          debugPrint(
            '[ChatTtsManager] 🏃 조건 완화 처리: "${_truncateText(chunk, 20)}"',
          );
          _processSentenceForTts(chunk);
          return;
        }
      }

      debugPrint('[ChatTtsManager] ⏳ 처리 조건 미충족 - 대기');
    } catch (e) {
      debugPrint('[ChatTtsManager] ❌ 스트리밍 처리 오류: $e');
    }
  }

  /// **스트리밍 최종 처리** (응답 완료 시)
  void _processFinalStreamingContent() {
    if (_isDisposed) return;

    try {
      final remainingText = _currentStreamingText.substring(
        _lastProcessedPosition,
      );
      if (remainingText.trim().isNotEmpty) {
        debugPrint(
          '[ChatTtsManager] 🏁 최종 미처리: "${_truncateText(remainingText, 30)}"',
        );
        _processSentenceForTts(remainingText);
      }
      debugPrint('[ChatTtsManager] ✅ 스트리밍 최종 처리 완료');
    } catch (e) {
      debugPrint('[ChatTtsManager] ❌ 최종 처리 오류: $e');
    }
  }

  // ========================================
  // 🔍 텍스트 분석 및 분할 메서드들
  // ========================================

  /// **완성된 문장 추출**
  List<String> _extractCompletedSentences(String text) {
    final sentences = <String>[];
    final sentenceEndRegex = RegExp(r'[.!?።፡፣]+(?:\s+|$)');
    final matches = sentenceEndRegex.allMatches(text);

    int lastEnd = 0;
    for (final match in matches) {
      final sentence = text.substring(lastEnd, match.end).trim();
      final isFirstSentence = sentences.isEmpty && _processedChunks.isEmpty;
      final minLength =
          isFirstSentence ? _firstChunkMinLength : _minChunkLength;

      if (sentence.length >= minLength) {
        sentences.add(sentence);
        lastEnd = match.end;
        debugPrint(
          '[ChatTtsManager] ✅ 완성 문장: "${_truncateText(sentence, 20)}" (${sentence.length}자, 첫문장: $isFirstSentence)',
        );
      }
    }

    if (sentences.isNotEmpty && lastEnd > 0) {
      debugPrint(
        '[ChatTtsManager] 📍 문장 추출: ${sentences.length}개, 위치: $lastEnd',
      );
    }
    return sentences;
  }

  /// **자연스러운 끊는 지점 찾기**
  int _findNaturalBreakPoint(String text) {
    final breakPatterns = [
      ', ', // 쉼표
      ' 그리고 ', ' 또한 ', ' 따라서 ', ' 그러나 ', ' 하지만 ', // 한국어 접속어
      ' 때문에 ', ' 경우 ', ' 상황에서 ', // 연결구
      ' 것이다', ' 것입니다', ' 습니다', ' 니다', // 한국어 어미
      ' and ', ' but ', ' however ', ' therefore ', // 영어 접속어
    ];

    int bestBreakPoint = -1;
    int maxScore = 0;

    for (final pattern in breakPatterns) {
      final index = text.lastIndexOf(pattern);
      if (index > _minChunkLength && index < text.length - 5) {
        final score = _calculateBreakPointScore(text, index + pattern.length);
        if (score > maxScore) {
          maxScore = score;
          bestBreakPoint = index + pattern.length;
        }
      }
    }

    if (bestBreakPoint > 0) {
      debugPrint(
        '[ChatTtsManager] 🎯 자연스러운 끊는 지점: $bestBreakPoint (점수: $maxScore)',
      );
    }
    return bestBreakPoint;
  }

  /// **끊는 지점 점수 계산** (자연스러움 평가)
  int _calculateBreakPointScore(String text, int position) {
    int score = 0;

    // 길이 적합성 (50-80자가 최적)
    if (position >= 50 && position <= 80) {
      score += 10;
    } else if (position >= 30 && position <= 100) {
      score += 5;
    }

    // 단어 경계 확인
    if (position < text.length && text[position] == ' ') {
      score += 5;
    }

    // 문장 부호 확인
    final beforeChar = position > 0 ? text[position - 1] : '';
    if ([',', '.', '!', '?'].contains(beforeChar)) {
      score += 8;
    }

    return score;
  }

  /// **🚀 첫 번째 완성된 단어 추출** (빠른 시작용)
  String _extractFirstCompleteWord(String text) {
    final wordMatch = RegExp(
      r'(\S+(?:\s+\S+)*?)(?:\s|[,.]|$)',
    ).firstMatch(text);
    if (wordMatch != null) {
      final word = wordMatch.group(1)?.trim() ?? '';
      if (word.length >= _firstChunkMinLength) {
        return word;
      }
    }
    return '';
  }

  /// **🎯 조기 끊는 지점 찾기** (조건 완화 처리용)
  int _findEarlyBreakPoint(String text) {
    final earlyBreakPatterns = [
      ', ', // 쉼표 (가장 기본)
      ' ', // 공백 (단어 경계)
    ];

    int bestBreakPoint = -1;

    // 역순 탐색하여 가장 뒤의 적절한 지점 찾기
    for (final pattern in earlyBreakPatterns) {
      final index = text.lastIndexOf(pattern, _minChunkLength + 3);
      if (index > _minChunkLength && index < text.length - 2) {
        bestBreakPoint = index + pattern.length;
        break; // 첫 번째 발견 지점 사용
      }
    }

    if (bestBreakPoint > 0) {
      debugPrint('[ChatTtsManager] 🎯 조기 끊는 지점: $bestBreakPoint');
    }
    return bestBreakPoint;
  }

  /// **개별 문장/청크를 TTS로 처리**
  void _processSentenceForTts(String sentence) {
    if (_isDisposed || sentence.trim().isEmpty) return;

    final cleanSentence = sentence.trim();

    // 🔧 중복 방지 로직
    if (_isDuplicateChunk(cleanSentence)) return;

    // 위치 기반 중복 방지
    if (_isAlreadyProcessedPosition(cleanSentence)) return;

    // 처리된 청크로 등록 및 위치 업데이트
    _registerProcessedChunk(cleanSentence);

    debugPrint(
      '[ChatTtsManager] 🎵 문장 처리: "${_truncateText(cleanSentence, 25)}" (${cleanSentence.length}자, 위치: $_lastProcessedPosition)',
    );

    // 마크다운 변환 후 TTS 큐에 추가
    _processTtsInBackground(cleanSentence);
  }

  /// **중복 청크 검사**
  bool _isDuplicateChunk(String cleanSentence) {
    // 1️⃣ 정확한 텍스트 중복 체크
    if (_processedChunks.contains(cleanSentence)) {
      debugPrint(
        '[ChatTtsManager] ⚠️ 중복 문장 건너뜀: "${_truncateText(cleanSentence, 25)}"',
      );
      return true;
    }

    // 2️⃣ 부분 포함 관계 체크
    for (final processedChunk in _processedChunks) {
      if (processedChunk.contains(cleanSentence) ||
          cleanSentence.contains(processedChunk)) {
        final lengthDiff = (processedChunk.length - cleanSentence.length).abs();
        if (lengthDiff < cleanSentence.length * 0.3) {
          // 30% 유사도 기준
          debugPrint(
            '[ChatTtsManager] ⚠️ 유사 문장 중복 방지: "${_truncateText(cleanSentence, 25)}"',
          );
          return true;
        }
      }
    }

    return false;
  }

  /// **이미 처리된 위치 검사**
  bool _isAlreadyProcessedPosition(String cleanSentence) {
    final expectedPosition = _lastProcessedPosition;
    final currentTextPosition = _currentStreamingText.indexOf(
      cleanSentence,
      expectedPosition,
    );

    if (currentTextPosition >= 0 && currentTextPosition < expectedPosition) {
      debugPrint(
        '[ChatTtsManager] ⚠️ 이미 처리된 위치: $currentTextPosition < $expectedPosition',
      );
      return true;
    }
    return false;
  }

  /// **처리된 청크 등록 및 위치 업데이트**
  void _registerProcessedChunk(String cleanSentence) {
    _processedChunks.add(cleanSentence);

    final currentTextPosition = _currentStreamingText.indexOf(
      cleanSentence,
      _lastProcessedPosition,
    );
    if (currentTextPosition >= 0) {
      _lastProcessedPosition = currentTextPosition + cleanSentence.length;
    } else {
      _lastProcessedPosition += cleanSentence.length;
    }
  }

  /// **텍스트 자르기** (로그용)
  String _truncateText(String text, int maxLength) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }
}
