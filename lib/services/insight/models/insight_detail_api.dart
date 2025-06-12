import 'dart:convert'; // JSON 디코딩을 위한 import 추가
import 'package:flutter/foundation.dart'; // debugPrint를 위한 import 추가

/// API에서 받아오는 Insight Article 상세 정보 응답 모델
class InsightDetailApi {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String source;
  final String type;
  final DateTime createdAt;
  final List<String> keywords;
  final List<String> interestIds;

  const InsightDetailApi({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.source,
    required this.type,
    required this.createdAt,
    required this.keywords,
    required this.interestIds,
  });

  /// API JSON 응답을 InsightDetailApi 객체로 변환
  factory InsightDetailApi.fromJson(Map<String, dynamic> json) {
    String contentText = '';
    final contentField = json['content'];
    var sourceField = json['source'];

    debugPrint('Source 필드 원본: $sourceField (${sourceField.runtimeType})');

    // source 필드 전처리
    if (sourceField is String) {
      sourceField =
          sourceField
              .replaceAll(RegExp(r'^\{|\}$'), '') // 시작과 끝의 중괄호 제거
              .trim();
    }

    try {
      if (contentField is String) {
        if (contentField.contains("'text':")) {
          // 단순하게 문자열 처리로 변경
          final textStart = contentField.indexOf("'text':") + 7;
          contentText =
              contentField
                  .substring(textStart)
                  .replaceAll('{', '')
                  .replaceAll('}', '')
                  .replaceAll("'", '')
                  .replaceAll('\\n', '\n')
                  .trim();
        } else {
          contentText = contentField;
        }
      } else if (contentField is Map<String, dynamic>) {
        contentText = contentField['text']?.toString() ?? '';
      }

      // 최종 텍스트 정리
      contentText = contentText.replaceAll('\\n', '\n').trim();
    } catch (e) {
      debugPrint('Content 파싱 에러: $e');
      contentText = contentField?.toString() ?? '';
    }

    return InsightDetailApi(
      id: json['id'] as String,
      title: json['title'] as String,
      content: contentText,
      tags: List<String>.from(json['tags'] as List? ?? []),
      source: sourceField,
      type: json['type'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      keywords: List<String>.from(json['keywords'] as List? ?? []),
      interestIds: List<String>.from(json['interest_ids'] as List? ?? []),
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'InsightDetailApi(id: $id, title: $title, keywords: ${keywords.length} items)';
  }

  // 마크다운 전처리 함수
  static String _preprocessMarkdown(String text) {
    if (text.isEmpty) return text;

    var processed = text;

    // 1. 이스케이프된 줄바꿈 처리
    processed = processed.replaceAll('\\n', '\n').replaceAll('\n\n\n', '\n\n');

    // 2. 마크다운 헤더 정리
    processed = processed.replaceAll(RegExp(r'^###\s*'), '## ');

    // 3. 불필요한 중괄호 제거
    processed = processed.replaceAll(RegExp(r'^\{|\}$'), '');

    // 4. 따옴표 정리
    processed = processed.replaceAll('\\"', '"').replaceAll("\\'", "'");

    // 5. 불필요한 공백 정리
    processed = processed.trim();

    return processed;
  }
}
