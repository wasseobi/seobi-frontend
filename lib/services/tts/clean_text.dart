import 'package:flutter/foundation.dart';

/// 다양한 텍스트 형식(마크다운, HTML, 일반 텍스트)을 TTS 읽기에 적합한 형태로 변환하는 통합 클래스
class TextCleaner {
  static const String _logTag = 'TextCleaner';
  
  /// 모든 형식의 텍스트를 TTS 읽기에 적합하게 정돈합니다.
  /// 텍스트 형식을 자동으로 감지하고 적절한 처리를 적용합니다.
  static String cleanForTTS(String text) {
    debugPrint('[$_logTag] 텍스트 정돈 시작: ${text.length}자');
    
    if (text.isEmpty) {
      debugPrint('[$_logTag] 빈 텍스트가 입력되었습니다.');
      return '';
    }
    
    String result = text;
    
    // 1. 마크다운 및 HTML 특수 요소 처리
    result = _cleanMarkdownAndHtmlElements(result);
    
    // 2. 일반 텍스트 처리 (모든 형식의 텍스트에 공통으로 적용)
    result = _cleanSpecialCharacters(result);
    
    // 3. 최종 정리 (공백, 줄바꿈 등)
    result = _finalCleanup(result);
    
    debugPrint('[$_logTag] 텍스트 정돈 완료: ${result.length}자');
    return result;
  }

  /// 마크다운 및 HTML 요소를 정돈합니다.
  static String _cleanMarkdownAndHtmlElements(String text) {
    String result = text;
    
    // 이미지 태그 제거 - ![대체 텍스트](이미지 URL) 또는 <img> 태그
    result = result.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
    result = result.replaceAll(RegExp(r'<img[^>]*>'), '');
    
    // 링크 텍스트만 남기고 URL 제거 - [링크 텍스트](URL)
    result = result.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'), 
      (match) => match.group(1) ?? ''
    );
    
    // HTML 태그 제거
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // HTML 엔티티 디코딩 (자주 사용되는 것들)
    final Map<String, String> htmlEntities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': ' ',
    };
    
    htmlEntities.forEach((entity, replacement) {
      result = result.replaceAll(entity, replacement);
    });
    
    // 코드 블록 제거 (```로 둘러싸인 부분)
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    
    // 인라인 코드 제거 (`로 둘러싸인 부분)
    result = result.replaceAll(RegExp(r'`[^`]*`'), '');
    
    // 제목 기호(#) 제거하고 텍스트 유지
    result = result.replaceAll(RegExp(r'#+\s+'), '');
    
    // 목록 기호 처리 (*, -, +)
    result = result.replaceAll(RegExp(r'^\s*[\*\-\+]\s+', multiLine: true), '');
    
    // 숫자 목록 처리 (1., 2. 등)
    result = result.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    
    // 강조 표시 제거 (**, *, __, _)
    result = result.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => match.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'__(.*?)__'), (match) => match.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'_(.*?)_'), (match) => match.group(1) ?? '');
    
    // 인용구 기호(>) 제거
    result = result.replaceAll(RegExp(r'^\s*>\s+', multiLine: true), '');
    
    // 수평선 제거 (---, ___, ***)
    result = result.replaceAll(RegExp(r'^([\*\-_])\1{2,}$', multiLine: true), '');
    
    // 표(테이블) 처리 - 간단히 각 셀의 텍스트를 유지하고 나머지 제거
    result = result.replaceAll(RegExp(r'\|[-:]+\|[-:]+\|'), ''); // 헤더 구분선 제거
    result = result.replaceAllMapped(
      RegExp(r'\|(.*?)\|'), 
      (match) => '${match.group(1)?.trim() ?? ''} '
    );
    
    return result;
  }
  
  /// 특수 문자와 유니코드 관련 처리를 수행합니다.
  static String _cleanSpecialCharacters(String text) {
    String result = text;
    
    // URL 제거 또는 간략화
    result = result.replaceAll(RegExp(r'https?://\S+'), '(링크)');
    
    // 이메일 주소 간략화
    result = result.replaceAll(RegExp(r'\S+@\S+\.\S+'), '(이메일)');
    
    // 특수 유니코드 문자 처리 (이모지 등)
    result = result.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '');  // 이모티콘
    result = result.replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '');  // 기호 및 픽토그램
    result = result.replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '');  // 교통 및 지도 기호
    result = result.replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '');    // 기타 기호    
    
    // 연속된 마침표 등을 하나로 변경
    result = result.replaceAll(RegExp(r'\.{2,}'), '.');
    
    // 불필요한 특수문자 제거 (TTS 읽기에 방해가 되는 특수 기호들)
    // 모든 언어 문자는 보존하고 명시적으로 특정 특수 기호만 제거
    final specialCharsToRemove = [
      '#', '%', '^', '~', '`', '\$', '@', '*', '+', '=',
      '<', '>', '[', ']', '{', '}', '|', '\\', '/', '_',
      '(', ')', ';', ':', '"', '\'',
    ];
    
    for (final char in specialCharsToRemove) {
      result = result.replaceAll(char, ' ');
    }
    
    return result;
  }
  
  /// 최종 텍스트 정리 (공백, 줄바꿈 등)를 수행합니다.
  static String _finalCleanup(String text) {
    String result = text;
    
    // 여러 개의 연속된 공백을 하나로 줄이기
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // 여러 개의 연속된 줄바꿈을 최대 2개로 제한
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // 앞뒤 공백 제거
    result = result.trim();
    
    return result;
  }
  
  /// 텍스트가 마크다운 형식인지 감지합니다. (필요시 사용)
  static bool isMarkdown(String text) {
    final markdownPatterns = [
      RegExp(r'#{1,6}\s+'),           // 제목
      RegExp(r'!\[.*?\]\(.*?\)'),     // 이미지
      RegExp(r'\[.*?\]\(.*?\)'),      // 링크
      RegExp(r'^\s*[\*\-\+]\s+', multiLine: true),  // 목록
      RegExp(r'^>\s+', multiLine: true),           // 인용구
      RegExp(r'`{1,3}'),              // 코드 블록
      RegExp(r'\*\*.*?\*\*'),         // 굵게
      RegExp(r'__.*?__'),             // 굵게
      RegExp(r'\*(?!\s).*?(?<!\s)\*') // 기울임꼴
    ];
    
    for (final pattern in markdownPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 텍스트가 HTML 형식인지 감지합니다. (필요시 사용)
  static bool isHtml(String text) {
    final htmlPattern = RegExp(r'<[a-z][^>]*>.*?</[a-z]>', dotAll: true);
    final selfClosingPattern = RegExp(r'<[a-z][^>]*/>');
    final doctypePattern = RegExp(r'<!DOCTYPE\s+html>', caseSensitive: false);
    
    return htmlPattern.hasMatch(text) || 
           selfClosingPattern.hasMatch(text) ||
           doctypePattern.hasMatch(text);
  }
}