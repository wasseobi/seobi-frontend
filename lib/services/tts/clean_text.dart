// filepath: c:\Projects\seobi-frontend\lib\services\tts\clean_text.dart
import 'package:flutter/foundation.dart';

/// 마크다운 텍스트를 TTS 읽기에 적합한 텍스트로 변환하는 클래스
class MarkdownTextCleaner {
  /// 마크다운 텍스트를 정돈하여 TTS가 읽기 적합한 텍스트로 변환합니다.
  static String cleanMarkdownForTTS(String markdownText) {
    debugPrint('[MarkdownTextCleaner] 마크다운 텍스트 정돈 시작: ${markdownText.length}자');
    String result = markdownText;
    
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
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'), 
      (match) => match.group(1) ?? ''
    );
    
    result = result.replaceAllMapped(
      RegExp(r'\*(.*?)\*'), 
      (match) => match.group(1) ?? ''
    );
    
    result = result.replaceAllMapped(
      RegExp(r'__(.*?)__'), 
      (match) => match.group(1) ?? ''
    );
    
    result = result.replaceAllMapped(
      RegExp(r'_(.*?)_'), 
      (match) => match.group(1) ?? ''
    );
    
    // 인용구 기호(>) 제거
    result = result.replaceAll(RegExp(r'^\s*>\s+', multiLine: true), '');
    
    // 수평선 제거 (---, ___, ***)
    result = result.replaceAll(RegExp(r'^([\*\-_])\1{2,}$', multiLine: true), '');
    
    // 표(테이블) 처리 - 간단히 각 셀의 텍스트를 유지하고 나머지 제거
    result = result.replaceAll(RegExp(r'\|[-:]+\|[-:]+\|'), ''); // 헤더 구분선 제거
    result = result.replaceAllMapped(
      RegExp(r'\|(.*?)\|'), 
      (match) => (match.group(1)?.trim() ?? '') + ' '
    );
    
    // 여러 개의 연속된 공백을 하나로 줄이기
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // 여러 개의 연속된 줄바꿈을 최대 2개로 제한
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // 앞뒤 공백 제거
    result = result.trim();
    
    debugPrint('[MarkdownTextCleaner] 마크다운 텍스트 정돈 완료: ${result.length}자');
    return result;
  }

  /// HTML 태그가 포함된 텍스트를 정돈하여 TTS가 읽기 적합한 텍스트로 변환합니다.
  static String cleanHtmlForTTS(String htmlText) {
    debugPrint('[MarkdownTextCleaner] HTML 텍스트 정돈 시작: ${htmlText.length}자');
    String result = htmlText;
    
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
    
    // 여러 개의 연속된 공백을 하나로 줄이기
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // 앞뒤 공백 제거
    result = result.trim();
    
    debugPrint('[MarkdownTextCleaner] HTML 텍스트 정돈 완료: ${result.length}자');
    return result;
  }
  
  /// 일반 텍스트를 정돈하여 TTS가 읽기 적합하게 변환합니다.
  static String cleanPlainTextForTTS(String text) {
    debugPrint('[MarkdownTextCleaner] 일반 텍스트 정돈 시작: ${text.length}자');
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
    
    // 불필요한 특수문자 제거 (TTS 읽기에 방해가 되는 것들)
    result = result.replaceAll(RegExp(r'[^\w\s\.\,\?\!]'), ' ');
    
    // 여러 개의 연속된 공백을 하나로 줄이기
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // 앞뒤 공백 제거
    result = result.trim();
    
    debugPrint('[MarkdownTextCleaner] 일반 텍스트 정돈 완료: ${result.length}자');
    return result;
  }
  
  /// 텍스트 유형을 감지하여 적절한 정돈 메서드를 호출합니다.
  static String cleanText(String text) {
    // 마크다운 여부 확인
    bool isMarkdown = _detectMarkdown(text);
    
    // HTML 여부 확인
    bool isHtml = _detectHtml(text);
    
    if (isMarkdown) {
      return cleanMarkdownForTTS(text);
    } else if (isHtml) {
      return cleanHtmlForTTS(text);
    } else {
      return cleanPlainTextForTTS(text);
    }
  }
  
  /// 텍스트가 마크다운 형식인지 감지합니다.
  static bool _detectMarkdown(String text) {
    // 마크다운의 일반적인 패턴 확인
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
  
  /// 텍스트가 HTML 형식인지 감지합니다.
  static bool _detectHtml(String text) {
    // HTML 태그 확인
    final htmlPattern = RegExp(r'<[a-z][^>]*>.*?</[a-z]>', dotAll: true);
    final selfClosingPattern = RegExp(r'<[a-z][^>]*/>');
    final doctypePattern = RegExp(r'<!DOCTYPE\s+html>', caseSensitive: false);
    
    return htmlPattern.hasMatch(text) || 
           selfClosingPattern.hasMatch(text) ||
           doctypePattern.hasMatch(text);
  }
}