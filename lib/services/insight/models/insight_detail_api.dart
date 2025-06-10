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
    return InsightDetailApi(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
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
