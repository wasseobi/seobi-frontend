import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/ui/utils/chat_tts_manager.dart';

/// MockTtsService for testing - TtsService 인터페이스를 구현
class MockTtsService {
  List<String> addedTexts = [];
  bool isStopCalled = false;
  bool isDisposeCalled = false;

  Future<void> addToQueue(String text) async {
    addedTexts.add(text);
  }

  Future<void> stop() async {
    isStopCalled = true;
  }

  Future<void> dispose() async {
    isDisposeCalled = true;
  }

  void reset() {
    addedTexts.clear();
    isStopCalled = false;
    isDisposeCalled = false;
  }
}

void main() {
  group('ChatTtsManager 기본 기능 테스트', () {
    late ChatTtsManager ttsManager;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      // 실제 TtsService를 사용하지만 플러그인 호출 없이 기본 기능만 테스트
    });

    tearDown(() {
      if (ttsManager != null) {
        ttsManager.dispose();
      }
    });

    test('ChatTtsManager 초기화 테스트', () {
      // 기본 생성자로 초기화 (실제 환경에서는 작동하지 않지만 구조적 테스트 가능)
      expect(() => ChatTtsManager(), returnsNormally);
    });

    test('유틸리티 메서드 테스트 - 마크다운 변환 확인', () {
      ttsManager = ChatTtsManager();

      // isValidForTts 테스트
      expect(ttsManager.isValidForTts('안녕하세요'), isTrue);
      expect(ttsManager.isValidForTts('a'), isFalse);
      expect(ttsManager.isValidForTts(''), isFalse);
      expect(ttsManager.isValidForTts('   '), isFalse);

      // containsMarkdown 테스트
      expect(ttsManager.containsMarkdown('**볼드 텍스트**'), isTrue);
      expect(ttsManager.containsMarkdown('*이탤릭*'), isTrue);
      expect(ttsManager.containsMarkdown('[링크](http://example.com)'), isTrue);
      expect(ttsManager.containsMarkdown('일반 텍스트'), isFalse);

      // getTtsPreview 테스트
      final longText = '아주 긴 텍스트입니다. ' * 10;
      final preview = ttsManager.getTtsPreview(longText, maxLength: 50);
      expect(preview.length, lessThanOrEqualTo(53)); // '...' 포함

      final shortText = '짧은 텍스트';
      final shortPreview = ttsManager.getTtsPreview(shortText);
      expect(shortPreview, equals(shortText));
    });

    test('스트리밍 상태 관리 테스트', () {
      ttsManager = ChatTtsManager();

      // 초기 상태
      expect(ttsManager.isDisposed, isFalse);
      expect(ttsManager.isStreamingActive, isFalse);

      // 스트리밍 시작 (실제 TTS 호출 없이 상태만 확인)
      ttsManager.processStreamingResponse('테스트 응답입니다.');
      expect(ttsManager.isStreamingActive, isTrue);

      // 스트리밍 강제 완료
      ttsManager.finishStreamingTts();
      expect(ttsManager.isStreamingActive, isFalse);
    });

    test('빈 내용 처리 테스트', () {
      ttsManager = ChatTtsManager();

      // 빈 내용들이 정상적으로 무시되는지 확인 (예외 발생하지 않아야 함)
      expect(() => ttsManager.processResponseForTts(''), returnsNormally);
      expect(() => ttsManager.processResponseForTts('   '), returnsNormally);
      expect(() => ttsManager.processStreamingResponse(''), returnsNormally);
      expect(() => ttsManager.processStreamingResponse('   '), returnsNormally);
    });

    test('dispose 상태 관리 테스트', () {
      ttsManager = ChatTtsManager();

      expect(ttsManager.isDisposed, isFalse);

      ttsManager.dispose();
      expect(ttsManager.isDisposed, isTrue);
      expect(ttsManager.isStreamingActive, isFalse);
    });

    test('🚀 첫 번째 청크 빠른 처리 설정값 테스트', () {
      ttsManager = ChatTtsManager();

      // 짧은 응답으로 스트리밍 시작
      ttsManager.processStreamingResponse('안녕');
      expect(ttsManager.isStreamingActive, isTrue);

      // 더 긴 응답 추가
      ttsManager.processStreamingResponse('안녕하세요! 반갑습니다.');
      expect(ttsManager.isStreamingActive, isTrue);
    });

    test('마크다운 텍스트 변환 시뮬레이션', () {
      ttsManager = ChatTtsManager();

      // 다양한 마크다운 패턴 확인
      const markdownSamples = [
        '**볼드 텍스트** 입니다.',
        '*이탤릭* 텍스트입니다.',
        '[링크](https://example.com) 텍스트입니다.',
        '`코드` 텍스트입니다.',
        '# 헤딩 텍스트',
        '- 리스트 아이템',
        '일반 텍스트입니다.',
      ];

      for (final markdown in markdownSamples) {
        final preview = ttsManager.getTtsPreview(markdown);
        // 마크다운 마커들이 제거되었는지 확인
        expect(preview.contains('**'), isFalse);
        expect(preview.contains('*'), isFalse);
        expect(preview.contains('['), isFalse);
        expect(preview.contains(']('), isFalse);
        expect(preview.contains('`'), isFalse);
        expect(preview.contains('#'), isFalse);
        expect(preview.contains('- '), isFalse);
      }
    });
  });
}
