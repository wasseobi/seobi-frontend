import '../../../../services/insight/models/insight_article_api.dart';
import '../../../../services/insight/models/insight_detail_api.dart';

/// Insight 데이터 모델
class InsightCardModel {
  final String id;
  final String title;
  final List<String> keywords;
  final String date;

  const InsightCardModel({
    required this.id,
    required this.title,
    required this.keywords,
    required this.date,
  });

  /// Map에서 InsightCardModel 객체로 변환하는 팩토리 메소드
  factory InsightCardModel.fromMap(Map<String, dynamic> map) {
    // Convert keywords list safely
    List<String> keywordsList = [];
    if (map['keywords'] != null) {
      keywordsList =
          (map['keywords'] as List)
              .map((keyword) => keyword.toString())
              .toList();
    }

    return InsightCardModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      keywords: keywordsList,
      date: map['date']?.toString() ?? '',
    );
  }

  /// API 목록 응답에서 InsightCardModel로 변환하는 팩토리 메소드
  factory InsightCardModel.fromApiArticle(InsightArticleApi apiModel) {
    return InsightCardModel(
      id: apiModel.id,
      title: apiModel.title,
      keywords: [], // 목록 조회에서는 키워드가 제공되지 않음
      date: _formatDate(apiModel.createdAt),
    );
  }

  /// API 상세 응답에서 InsightCardModel로 변환하는 팩토리 메소드
  factory InsightCardModel.fromApiDetail(InsightDetailApi apiModel) {
    return InsightCardModel(
      id: apiModel.id,
      title: apiModel.title,
      keywords: apiModel.keywords,
      date: _formatDate(apiModel.createdAt),
    );
  }

  /// 날짜를 사용자 친화적 형식으로 변환
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// InsightCardModel을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'keywords': keywords, 'date': date};
  }

  /// InsightCardModel 복사본 생성 (상태 변경용)
  InsightCardModel copyWith({
    String? id,
    String? title,
    List<String>? keywords,
    String? date,
  }) {
    return InsightCardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      keywords: keywords ?? this.keywords,
      date: date ?? this.date,
    );
  }
}
