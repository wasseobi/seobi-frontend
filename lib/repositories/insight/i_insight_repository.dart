import '../../services/insight/models/insight_article_api.dart';
import '../../services/insight/models/insight_detail_api.dart';

/// Insight 데이터 액세스를 위한 Repository 인터페이스
abstract class IInsightRepository {
  /// 특정 사용자의 모든 인사이트 아티클 목록을 조회합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: 인사이트 아티클 목록
  /// Throws: Exception when API call fails
  Future<List<InsightArticleApi>> getUserInsights(String userId);

  /// 특정 인사이트 아티클의 상세 정보를 조회합니다
  ///
  /// [articleId] 인사이트 아티클 UUID
  /// Returns: 인사이트 상세 정보
  /// Throws: Exception when API call fails or article not found
  Future<InsightDetailApi> getInsightDetail(String articleId);

  /// 사용자의 데이터를 기반으로 새로운 인사이트 아티클을 생성합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: 생성된 인사이트 상세 정보
  /// Throws: Exception when API call fails or generation fails
  Future<InsightDetailApi> generateInsight(String userId);
}
