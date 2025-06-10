import '../../services/insight/insight_api_service.dart';
import '../../services/insight/models/insight_article_api.dart';
import '../../services/insight/models/insight_detail_api.dart';
import 'i_insight_repository.dart';

/// Insight Repository의 구현체
/// API 서비스를 통해 실제 데이터 조회 및 조작을 수행합니다
class InsightRepository implements IInsightRepository {
  final InsightApiService _apiService;

  InsightRepository({InsightApiService? apiService})
    : _apiService = apiService ?? InsightApiService();

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  @override
  Future<List<InsightArticleApi>> getUserInsights(String userId) async {
    try {
      return await _apiService.getUserInsights(userId);
    } catch (e) {
      // Repository 레벨에서 추가적인 에러 처리나 로깅 가능
      rethrow; // 현재는 그대로 전달
    }
  }

  @override
  Future<InsightDetailApi> getInsightDetail(String articleId) async {
    try {
      return await _apiService.getInsightDetail(articleId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<InsightDetailApi> generateInsight(String userId) async {
    try {
      return await _apiService.generateInsight(userId);
    } catch (e) {
      rethrow;
    }
  }
}
