/// API에서 받아오는 Insight Article 응답 모델
class InsightArticleApi {
  final String id;
  final String title;
  final DateTime createdAt;

  const InsightArticleApi({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  /// API JSON 응답을 InsightArticleApi 객체로 변환
  factory InsightArticleApi.fromJson(Map<String, dynamic> json) {
    return InsightArticleApi(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'InsightArticleApi(id: $id, title: $title, createdAt: $createdAt)';
  }
}
