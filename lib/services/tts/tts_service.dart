import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _textQueue = Queue<String>();
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isInterrupted = false;
  String? _currentText;
  int? _currentWordStartPosition;

  // 스트리밍 텍스트 처리를 위한 버퍼링 기능
  String _streamBuffer = '';
  static const int _minBufferSize = 200; // 더 긴 단위로 처리
  static const int _firstSentenceMinSize = 50; // 첫 문장은 더 빨리 처리 (80 → 50으로 낮춤)
  static final RegExp _sentenceEndPattern = RegExp(r'[.!?]+\s*');
  bool _isFirstTtsStarted = false; // 첫 번째 TTS가 시작되었는지 추적

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initTTS();
      _isInitialized = true;
    }
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

  /// 마크다운 텍스트를 TTS에 적합한 형태로 정리
  String _cleanTextForTTS(String text) {
    String cleanedText = text.trim();
    if (cleanedText.isEmpty) return '';

    // 1. 템플릿 변수 및 플레이스홀더 제거 (강화된 패턴)
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\$+\d+'),
      '',
    ); // $1, $$1, $2 등
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\${[^}]*}'),
      '',
    ); // ${variable} 형태
    cleanedText = cleanedText.replaceAll(RegExp(r'\$\w+'), ''); // $word 형태
    cleanedText = cleanedText.replaceAll(RegExp(r'\$'), ''); // 남은 $ 기호 모두 제거

    // 2. 마크다운 헤더 제거 (공백 확보 중요!)
    cleanedText = cleanedText.replaceAll(RegExp(r'^#{1,6}\s*'), ' '); // 시작 헤더
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\n#{1,6}\s*'),
      ' ',
    ); // 줄 중간 헤더

    // 3. 마크다운 문법 제거 (중요: 모든 패턴 처리) - raw string 사용
    // Bold 처리 - 완전한 패턴과 불완전한 패턴 모두 처리
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\*\*([^*]+)\*\*'),
      r'$1',
    ); // **bold** → 내용만 유지
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\*\*([^*]*)\*\*'),
      r'$1',
    ); // **incomplete** 처리
    cleanedText = cleanedText.replaceAll(RegExp(r'\*\*'), ''); // 남은 ** 제거

    // Italic 처리
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\*([^*]+)\*'),
      r'$1',
    ); // *italic* → 내용만 유지
    cleanedText = cleanedText.replaceAll(RegExp(r'\*'), ''); // 남은 * 제거

    // 기타 마크다운
    cleanedText = cleanedText.replaceAll(
      RegExp(r'`([^`]+)`'),
      r'$1',
    ); // `code` → 내용만 유지
    cleanedText = cleanedText.replaceAll(RegExp(r'`'), ''); // 남은 ` 제거
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      r'$1',
    ); // [text](url) → 텍스트만 유지

    // 4. 기본적인 리스트 마커 제거 (공백 확보)
    cleanedText = cleanedText.replaceAll(
      RegExp(r'^\s*[-*+]\s+'),
      '',
    ); // - * + 리스트
    cleanedText = cleanedText.replaceAll(
      RegExp(r'^\s*\d+\.\s+'),
      '',
    ); // 1. 2. 번호 리스트
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\n\s*[-*+]\s+'),
      ' ',
    ); // 줄 중간 리스트
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\n\s*\d+\.\s+'),
      ' ',
    ); // 줄 중간 번호 리스트

    // 5. URL 제거 (읽기에 부적절)
    cleanedText = cleanedText.replaceAll(
      RegExp(r'https?://[^\s\]]+'),
      '',
    ); // URL 제거
    cleanedText = cleanedText.replaceAll(
      RegExp(r'www\.[^\s\]]+'),
      '',
    ); // www URL 제거

    // 6. 이모지 제거
    cleanedText = cleanedText.replaceAll(
      RegExp(r'[🔍🛠️✅⚠️📋⭐🎯💡📊🌟🚀💻📱🎬🎵📺🎮]'),
      '',
    );

    // 7. 불완전한 단어 수정 (자주 발생하는 패턴들)
    // 영어 단어 수정
    cleanedText = cleanedText.replaceAll(RegExp(r'\bHealt\b'), 'Health');
    cleanedText = cleanedText.replaceAll(RegExp(r'\biPhon\b'), 'iPhone');
    cleanedText = cleanedText.replaceAll(RegExp(r'\bAppl\b'), 'Apple');

    // 한글 분리된 단어 복원
    cleanedText = cleanedText.replaceAll(RegExp(r'기\s+기'), '기기');
    cleanedText = cleanedText.replaceAll(RegExp(r'모\s+델'), '모델');
    cleanedText = cleanedText.replaceAll(RegExp(r'사\s+용'), '사용');
    cleanedText = cleanedText.replaceAll(RegExp(r'운\s+동'), '운동');
    cleanedText = cleanedText.replaceAll(RegExp(r'기\s+능'), '기능');

    // 8. 줄바꿈과 공백 정리 (자연스러운 호흡 추가)
    // 줄바꿈을 자연스러운 휴지부로 변환
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\n\s*\n+'),
      '. ',
    ); // 빈 줄은 문장 구분으로
    cleanedText = cleanedText.replaceAll(RegExp(r'\n+'), ' '); // 일반 줄바꿈은 공백으로

    // 연속된 공백 정리 (여러 번 수행)
    cleanedText = cleanedText.replaceAll(RegExp(r'\s+'), ' '); // 모든 연속 공백을 하나로

    // 문장 부호 주변 정리
    cleanedText = cleanedText.replaceAll(RegExp(r'\s*([,.!?;:])\s*'), r'$1 ');

    // 한글과 영어 사이 띄어쓰기 보정
    cleanedText = cleanedText.replaceAll(
      RegExp(r'([가-힣])([A-Z])'),
      r'$1 $2',
    ); // 한글+대문자
    cleanedText = cleanedText.replaceAll(
      RegExp(r'([a-z])([가-힣])'),
      r'$1 $2',
    ); // 소문자+한글

    // 9. 최종 정리
    cleanedText = cleanedText.trim();

    // 다시 한번 연속 공백 정리
    cleanedText = cleanedText.replaceAll(RegExp(r'\s+'), ' ');

    return cleanedText;
  }

  /// 중간 처리 메시지인지 확인
  bool _isIntermediateMessage(String message) {
    if (message.trim().isEmpty) return true;

    // 1. 마크다운 헤더만 있는 메시지
    if (RegExp(r'^#{1,6}\s*[^#]*$').hasMatch(message.trim()) &&
        message.trim().length < 10) {
      return true;
    }

    // 2. 검색 관련 메시지
    if (message.contains('검색') &&
        (message.contains('🔍') ||
            message.contains('찾았습니다') ||
            message.contains('결과'))) {
      return true;
    }

    // 3. 도구 실행 메시지
    if (message.contains('도구를 실행') ||
        message.contains('tool') ||
        message.contains('실행 중')) {
      return true;
    }

    // 4. 상태 메시지
    if ((message.contains('서비가') && message.contains('준비 중')) ||
        message.contains('처리하고 있습니다') ||
        message.contains('분석 중') ||
        message.contains('로딩') ||
        message.contains('대기 중')) {
      return true;
    }

    // 5. 매우 짧은 메시지 (정리 후 3글자 이하)
    final cleanedForLength = _cleanTextForTTS(
      message,
    ).replaceAll(RegExp(r'[^\w가-힣]'), '');
    if (cleanedForLength.length <= 3) {
      return true;
    }

    // 6. 리스트 번호만 있는 메시지
    if (RegExp(r'^\s*[\d$]+[.:]\s*$').hasMatch(message.trim())) {
      return true;
    }

    // 7. 특수 문자만 있는 메시지
    if (RegExp(r'^[^\w가-힣\s]+$').hasMatch(message.trim())) {
      return true;
    }

    // 8. Bold나 마크다운만 있고 실제 내용이 없는 메시지
    final withoutMarkdown =
        message
            .replaceAll(RegExp(r'\*\*.*?\*\*'), '')
            .replaceAll(RegExp(r'\*.*?\*'), '')
            .replaceAll(RegExp(r'#{1,6}\s*'), '')
            .trim();
    if (withoutMarkdown.isEmpty || withoutMarkdown.length <= 2) {
      return true;
    }

    return false;
  }

  /// 텍스트를 큐에 추가합니다.
  Future<void> addToQueue(String text) async {
    await _ensureInitialized();
    if (text.trim().isEmpty) return;

    // 이미 정리된 텍스트를 받는 경우와 외부에서 직접 호출하는 경우를 구분
    String textToAdd;
    if (text.contains('###') ||
        text.contains('**') ||
        text.contains('`') ||
        text.contains('\$')) {
      // 정리되지 않은 텍스트인 경우 정리 수행
      textToAdd = _cleanTextForTTS(text);
      if (textToAdd.isEmpty || _isIntermediateMessage(textToAdd)) {
        debugPrint('[TtsService] 중간 처리 메시지 스킵: $text');
        return;
      }
    } else {
      // 이미 정리된 텍스트인 경우 그대로 사용
      textToAdd = text.trim();
    }

    debugPrint('[TtsService] 텍스트 큐에 추가: $textToAdd');
    _textQueue.add(textToAdd);
    if (!_isPlaying && !_isPaused && !_isInterrupted) {
      _playNext();
    }
  }

  /// 큐의 다음 텍스트를 재생합니다.
  Future<void> _playNext() async {
    if (_textQueue.isEmpty || _isInterrupted) {
      debugPrint('[TtsService] 재생할 텍스트가 없거나 인터럽트 상태');
      return;
    }

    String textToPlay = _textQueue.removeFirst().trim();
    if (textToPlay.isEmpty) {
      _playNext();
      return;
    }

    _currentText = textToPlay;
    _isPlaying = true;
    debugPrint('[TtsService] 다음 텍스트 재생 시작: $_currentText');
    await _flutterTts.speak(_currentText!);
  }

  /// 현재 재생 중인 음성을 일시 정지합니다.
  Future<void> pause() async {
    await _ensureInitialized();
    if (_isPlaying) {
      debugPrint('[TtsService] 재생 일시 정지');
      await _flutterTts.pause();
      _isPaused = true;
      _isPlaying = false;
    }
  }

  /// 일시 정지된 음성을 다시 재생합니다.
  Future<void> resume() async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    debugPrint('[TtsService] 재생 중지 및 큐 초기화');
    await _flutterTts.stop();
    _textQueue.clear();
    _isPlaying = false;
    _isPaused = false;
    _isInterrupted = false;
    _currentText = null;
    _currentWordStartPosition = null;
  }

  /// TTS를 인터럽트하고 완전히 멈춥니다 (STT나 새 메시지 입력 시 호출)
  Future<void> interrupt() async {
    await _ensureInitialized();
    debugPrint(
      '[TtsService] interrupt() 호출됨 - 현재 상태: isPlaying=$_isPlaying, isPaused=$_isPaused, isInterrupted=$_isInterrupted',
    );

    // 무조건 인터럽트 상태로 설정
    _isInterrupted = true;

    if (_isPlaying || _isPaused) {
      debugPrint('[TtsService] TTS 인터럽트 - 완전 정지 실행');
      await _flutterTts.stop();
      _textQueue.clear(); // 큐도 비움
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      _currentWordStartPosition = null;
      _streamBuffer = ''; // 스트리밍 버퍼도 초기화
      debugPrint(
        '[TtsService] TTS 인터럽트 완료 - 새로운 상태: isPlaying=$_isPlaying, isPaused=$_isPaused, isInterrupted=$_isInterrupted',
      );
    } else {
      debugPrint('[TtsService] TTS가 재생 중이 아니지만 인터럽트 상태로 설정');
      _textQueue.clear(); // 큐도 비움
      _streamBuffer = ''; // 스트리밍 버퍼도 초기화
    }
  }

  /// 인터럽트된 TTS를 재시작합니다 (새로운 AI 응답 시작 시 호출)
  Future<void> resumeAfterInterrupt() async {
    debugPrint('[TtsService] 인터럽트 해제 - 새로운 응답으로 TTS 재시작');
    _isInterrupted = false;
    _streamBuffer = ''; // 스트리밍 버퍼 초기화
    _isFirstTtsStarted = false; // 첫 TTS 플래그 리셋
    // 새로운 스트리밍이 시작되면 자동으로 TTS 시작됨
  }

  /// 현재 TTS가 인터럽트 상태인지 확인
  bool get isInterrupted => _isInterrupted;

  /// 현재 TTS가 재생 중인지 확인
  bool get isPlaying => _isPlaying;

  /// 현재 TTS가 일시정지 상태인지 확인
  bool get isPaused => _isPaused;

  /// 스트리밍 버퍼에 텍스트가 있는지 확인
  bool get hasStreamingContent => _streamBuffer.isNotEmpty;

  /// 첫 번째 TTS가 시작되었는지 확인
  bool get isFirstTtsStarted => _isFirstTtsStarted;

  /// TTS 큐에 대기 중인 텍스트가 있는지 확인
  bool get hasQueuedText => _textQueue.isNotEmpty;

  /// TTS 엔진의 설정을 변경합니다.
  Future<void> setConfiguration({
    double? volume,
    double? pitch,
    double? rate,
    String? language,
  }) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    if (text.trim().isEmpty) return;

    final cleanedText = _cleanTextForTTS(text);
    if (cleanedText.isEmpty || _isIntermediateMessage(cleanedText)) return;

    debugPrint('[TtsService] 새로운 메시지 수신: $cleanedText');

    // 인터럽트 상태가 아닐 때만 새로운 텍스트 처리
    if (!_isInterrupted) {
      await addToQueue(cleanedText);
    }
  }

  /// 스트리밍 텍스트를 버퍼에 추가하고 처리
  Future<void> addStreamingText(String newText) async {
    await _ensureInitialized();
    if (newText.trim().isEmpty || _isInterrupted) return;

    // 새로운 스트리밍이 시작되면 인터럽트 상태 해제 및 첫 TTS 플래그 초기화
    if (_isInterrupted && _streamBuffer.isEmpty) {
      debugPrint('[TtsService] 새로운 스트리밍 시작 - 인터럽트 해제');
      _isInterrupted = false;
      _isFirstTtsStarted = false; // 새로운 스트리밍에서는 첫 TTS 플래그 리셋
    }

    _streamBuffer += newText;
    debugPrint('[TtsService] 스트리밍 텍스트 추가: $newText');
    debugPrint('[TtsService] 현재 버퍼 길이: ${_streamBuffer.length}');

    // 불완전한 단어가 있는지 확인
    bool hasIncompleteWord = _hasIncompleteWordAtEnd(_streamBuffer);
    debugPrint('[TtsService] 불완전한 단어 체크: $hasIncompleteWord');

    // 완성된 문장이 있는지 확인
    bool hasCompleteSentence = _hasCompleteSentence(_streamBuffer);
    debugPrint('[TtsService] 완성된 문장 체크: $hasCompleteSentence');

    // 첫 번째 TTS 시작 조건 확인
    bool shouldStartFirstTts =
        !_isFirstTtsStarted &&
        !hasIncompleteWord &&
        _streamBuffer.length >= _firstSentenceMinSize &&
        hasCompleteSentence;

    debugPrint(
      '[TtsService] 첫 TTS 시작 조건: isFirstStarted=${_isFirstTtsStarted}, hasIncomplete=$hasIncompleteWord, length=${_streamBuffer.length}>=$_firstSentenceMinSize, hasComplete=$hasCompleteSentence → result=$shouldStartFirstTts',
    );

    // 후속 TTS 조건 확인 (첫 TTS 이후)
    bool hasCompleteSentences =
        _isFirstTtsStarted && _hasMultipleCompleteSentences(_streamBuffer);

    // 첫 번째 문장은 빠르게 시작, 이후는 그룹핑해서 처리
    if (!hasIncompleteWord && (shouldStartFirstTts || hasCompleteSentences)) {
      if (shouldStartFirstTts) {
        debugPrint('[TtsService] 첫 번째 TTS 시작 - 빠른 응답');
        _isFirstTtsStarted = true;
      }
      await _processBufferedText();
    } else if (_streamBuffer.length >= _minBufferSize * 4) {
      // 버퍼가 너무 크면 불완전한 단어가 있어도 처리 (과도한 지연 방지)
      debugPrint('[TtsService] 버퍼가 너무 커서 강제 처리 (길이: ${_streamBuffer.length})');
      await _processBufferedText();
    } else {
      debugPrint(
        '[TtsService] 조건 미충족으로 TTS 대기 중 - 버퍼 길이: ${_streamBuffer.length}',
      );
    }
  }

  /// 완성된 문장이 있는지 확인 (더 관대한 조건)
  bool _hasCompleteSentence(String text) {
    // 1. 기본 문장 끝 패턴
    if (RegExp(r'[.!?]+\s+').hasMatch(text)) return true;

    // 2. 한국어 문장 끝 패턴 (공백 없이도 OK)
    if (RegExp(r'다\.|습니다\.|요\.|니다\.|었습니다\.|있습니다\.').hasMatch(text)) return true;

    // 3. 문장 끝이 마침표로 끝나는 경우 (공백 없어도 OK)
    if (RegExp(r'[.!?]+$').hasMatch(text.trim())) return true;

    // 4. 충분히 긴 텍스트에서 쉼표 후 공백이 있는 경우도 임시 문장으로 처리
    if (text.length >= 100 && RegExp(r',\s+').hasMatch(text)) return true;

    return false;
  }

  /// 불완전한 단어 감지를 더 관대하게 수정
  bool _hasIncompleteWordAtEnd(String text) {
    if (text.isEmpty) return false;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // 마지막 단어 추출
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.isEmpty) return false;

    final lastWord = words.last.trim();

    // 알려진 불완전 패턴들만 엄격하게 체크
    if (lastWord == 'Healt' || lastWord == 'iPhon' || lastWord == 'Appl') {
      debugPrint('[TtsService] 확실한 불완전 단어 감지: $lastWord');
      return true;
    }

    // 너무 엄격한 조건들을 완화 - 짧은 영어 단어 체크 제거
    // 대부분의 경우 TTS 시작을 막지 않도록 함

    return false;
  }

  /// 완성된 문장이 여러 개 있는지 확인 (더 긴 단위로 처리하기 위해)
  bool _hasMultipleCompleteSentences(String text) {
    // 한국어 문장 끝 패턴들을 고려
    final koreanSentencePattern = RegExp(
      r'[.!?]+\s+|다\.\s+|습니다\.\s+|요\.\s+|니다\.\s+|었습니다\.\s+|있습니다\.\s+',
    );
    final matches = koreanSentencePattern.allMatches(text);

    // 첫 TTS 이후에는 2개 이상의 완성된 문장이 있거나, 충분히 긴 문장일 때 처리
    return matches.length >= 2 ||
        (matches.length >= 1 && text.length >= _minBufferSize);
  }

  /// 버퍼에 있는 텍스트를 처리
  Future<void> _processBufferedText() async {
    if (_streamBuffer.isEmpty || _isInterrupted) {
      debugPrint('[TtsService] _processBufferedText 조기 종료 - 버퍼 비어있음 또는 인터럽트');
      return;
    }

    debugPrint(
      '[TtsService] _processBufferedText 시작 - 버퍼 길이: ${_streamBuffer.length}',
    );

    // 먼저 마크다운 정리
    String cleanedBuffer = _cleanTextForTTS(_streamBuffer);
    debugPrint('[TtsService] 정리된 버퍼: $cleanedBuffer');

    // 정리된 텍스트가 너무 짧거나 중간 메시지면 스킵
    if (cleanedBuffer.isEmpty || _isIntermediateMessage(cleanedBuffer)) {
      debugPrint('[TtsService] 정리된 버퍼가 비어있거나 중간 메시지로 스킵');
      _streamBuffer = '';
      return;
    }

    // 한국어 문장 끝을 고려한 패턴으로 분리
    final sentencePattern = RegExp(
      r'(?:다\.|습니다\.|요\.|니다\.|었습니다\.|있습니다\.|[.!?]+)[\s\n]*',
    );
    final sentenceMatches = sentencePattern.allMatches(cleanedBuffer).toList();

    if (sentenceMatches.isNotEmpty) {
      // 완성된 문장들을 추출
      List<String> completedSentences = [];
      int lastEnd = 0;

      for (var match in sentenceMatches) {
        if (match.end < cleanedBuffer.length) {
          // 마지막이 아닌 완성된 문장들만
          final sentence = cleanedBuffer.substring(lastEnd, match.end).trim();
          if (sentence.isNotEmpty && !_isIntermediateMessage(sentence)) {
            completedSentences.add(sentence);
          }
          lastEnd = match.end;
        }
      }

      // 첫 번째 TTS인 경우 첫 문장만 바로 처리, 이후는 그룹핑
      if (!_isFirstTtsStarted && completedSentences.isNotEmpty) {
        // 첫 번째 문장만 빠르게 처리
        final firstSentence = completedSentences.first;
        debugPrint('[TtsService] 첫 번째 문장 빠른 재생: $firstSentence');
        await addToQueue(firstSentence);

        // 첫 번째 문장 이후의 완성된 문장들이 있으면 그룹핑 처리
        if (completedSentences.length > 1) {
          final remainingSentences = completedSentences.skip(1).toList();
          debugPrint(
            '[TtsService] 나머지 문장들 그룹핑 처리: ${remainingSentences.length}개',
          );
          await _processRemainingSentences(remainingSentences);
        }
      } else if (_isFirstTtsStarted) {
        // 첫 TTS 이후에는 그룹핑해서 처리
        debugPrint('[TtsService] 후속 문장들 그룹핑 처리: ${completedSentences.length}개');
        await _processRemainingSentences(completedSentences);
      }

      // 미완성 문장은 버퍼에 남겨둠
      if (sentenceMatches.isNotEmpty) {
        final lastMatch = sentenceMatches.last;
        if (lastMatch.end < cleanedBuffer.length) {
          // 원본 버퍼에서 미완성 부분 찾기
          final remainingStart = _streamBuffer.lastIndexOf(
            cleanedBuffer.substring(lastMatch.end),
          );
          if (remainingStart != -1) {
            _streamBuffer = _streamBuffer.substring(remainingStart);
          } else {
            _streamBuffer = cleanedBuffer.substring(lastMatch.end);
          }
        } else {
          _streamBuffer = '';
        }
      }
    } else if (cleanedBuffer.length >= _minBufferSize * 2) {
      // 버퍼가 너무 크면 강제로 처리
      if (!_isIntermediateMessage(cleanedBuffer)) {
        debugPrint('[TtsService] 버퍼 강제 처리: $cleanedBuffer');
        await addToQueue(cleanedBuffer);
      }
      _streamBuffer = '';
    }
  }

  /// 나머지 문장들을 그룹핑해서 처리
  Future<void> _processRemainingSentences(List<String> sentences) async {
    if (sentences.isEmpty) return;

    // 문장들을 200-300자 단위로 묶어서 처리 (자연스러운 호흡 단위)
    List<String> sentenceGroups = [];
    String currentGroup = '';

    for (String sentence in sentences) {
      if (currentGroup.isEmpty) {
        currentGroup = sentence;
      } else if ((currentGroup + ' ' + sentence).length <= 300) {
        currentGroup += ' ' + sentence;
      } else {
        // 현재 그룹을 저장하고 새 그룹 시작
        sentenceGroups.add(currentGroup);
        currentGroup = sentence;
      }
    }

    // 마지막 그룹 추가
    if (currentGroup.isNotEmpty) {
      sentenceGroups.add(currentGroup);
    }

    // 각 그룹을 TTS 큐에 추가
    for (String group in sentenceGroups) {
      debugPrint('[TtsService] 문장 그룹 재생: $group');
      await addToQueue(group);
    }
  }

  /// 스트리밍 버퍼를 초기화합니다
  void clearStreamBuffer() {
    debugPrint('[TtsService] 스트리밍 버퍼 초기화');
    _streamBuffer = '';
    _isFirstTtsStarted = false; // 첫 TTS 플래그도 리셋
  }

  /// 스트리밍 버퍼에 남은 내용을 처리합니다
  Future<void> flushStreamBuffer() async {
    if (_streamBuffer.isNotEmpty && !_isInterrupted) {
      final textToProcess = _cleanTextForTTS(_streamBuffer);
      if (textToProcess.isNotEmpty && !_isIntermediateMessage(textToProcess)) {
        debugPrint('[TtsService] 스트리밍 버퍼 마지막 처리: $textToProcess');
        await addToQueue(textToProcess);
      }
      _streamBuffer = '';
    }
  }
}
