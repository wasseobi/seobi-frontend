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
    // content 필드 파싱 개선
    String contentText = '';
    final contentField = json['content'];

    try {
      if (contentField is String) {
        // content가 문자열인 경우
        if (contentField.startsWith('{') && contentField.endsWith('}')) {
          // JSON 문자열인 경우 파싱 시도
          try {
            // 문자열을 JSON으로 파싱
            final contentJson = contentField
                .replaceAll("'", '"') // 작은따옴표를 큰따옴표로 변경
                .replaceAll('\\n', '\n'); // 이스케이프 문자 처리

            // 정규식으로 text 값 추출
            final textMatch = RegExp(
              r'"text":\s*"([^"]*)"',
            ).firstMatch(contentJson);
            if (textMatch != null) {
              contentText = textMatch.group(1) ?? '';
            } else {
              // 정규식 실패 시 간단한 방법으로 추출
              final startIndex = contentJson.indexOf('"text":') + 7;
              final textStart = contentJson.indexOf('"', startIndex) + 1;
              final textEnd = contentJson.lastIndexOf('"');
              if (textStart > 0 && textEnd > textStart) {
                contentText = contentJson.substring(textStart, textEnd);
              } else {
                contentText = contentField; // fallback
              }
            }
          } catch (e) {
            // JSON 파싱 실패 시 원본 문자열 사용

            contentText = contentField;
          }
        } else {
          // 일반 문자열인 경우 그대로 사용
          contentText = contentField;
        }
      } else if (contentField is Map<String, dynamic>) {
        // content가 이미 객체인 경우 text 필드 추출
        contentText = contentField['text'] as String? ?? '';
      } else {
        // 다른 형태인 경우 문자열로 변환
        contentText = contentField?.toString() ?? '';
      }

      // 이스케이프 문자들을 실제 문자로 변환
      contentText = contentText
          .replaceAll('\\n', '\n')
          .replaceAll('\\t', '\t')
          .replaceAll('\\"', '"')
          .replaceAll("\\'", "'");
    } catch (e) {
      contentText = contentField?.toString() ?? '';
    }

    return InsightDetailApi(
      id: json['id'] as String,
      title: json['title'] as String,
      content: contentText, // 파싱된 텍스트 사용
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
