import 'dart:convert';

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

    try {
      if (contentField is String) {
        // 작은따옴표로 된 text 필드 확인
        if (contentField.contains("'text':")) {
          final textStart = contentField.indexOf("'text':") + 7;
          contentText =
              contentField
                  .substring(textStart)
                  .replaceAll(RegExp(r'^\{|\}$'), '') // 시작과 끝의 중괄호 제거
                  .replaceAll("'", '')
                  .replaceAll('\\n', '\n')
                  .trim();
        }
        // 큰따옴표로 된 text 필드 확인
        else if (contentField.contains('"text":')) {
          final textStart = contentField.indexOf('"text":') + 7;
          contentText =
              contentField
                  .substring(textStart)
                  .replaceAll(RegExp(r'^\{|\}$'), '') // 시작과 끝의 중괄호 제거
                  .replaceAll('"', '')
                  .replaceAll('\\n', '\n')
                  .trim();
        } else {
          contentText = contentField;
        }
      } else if (contentField is Map<String, dynamic>) {
        // Map인 경우 text 필드 직접 추출
        contentText = contentField['text']?.toString() ?? '';
      } else {
        // 다른 형태인 경우 문자열로 변환
        contentText = contentField?.toString() ?? '';
      }

      // 최종 텍스트 정리
      contentText =
          contentText
              .replaceAll('\\n', '\n')
              .replaceAll('\\t', '\t')
              .replaceAll('\\"', '"')
              .replaceAll("\\'", "'")
              .trim();
    } catch (e) {
      contentText = contentField?.toString() ?? '';
    }

    return InsightDetailApi(
      id: json['id'] as String,
      title: json['title'] as String,
      content: contentText,
      tags: List<String>.from(json['tags'] as List? ?? []),
      source: json['source'] as String? ?? '',
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
}
