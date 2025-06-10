import 'package:flutter/foundation.dart';
import '../../repositories/insight/insight_repository.dart';
import '../../repositories/insight/i_insight_repository.dart';
import '../../ui/components/articles/insights/insight_card_model.dart';
import 'models/insight_article_api.dart';
import 'models/insight_detail_api.dart';

/// Insight 관련 비즈니스 로직을 담당하는 서비스 클래스
class InsightService {
  final IInsightRepository _repository;

  InsightService({IInsightRepository? repository})
    : _repository = repository ?? InsightRepository();

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    if (_repository is InsightRepository) {
      (_repository as InsightRepository).setAuthToken(token);
    }
  }

  /// 특정 사용자의 인사이트 목록을 UI 모델로 변환하여 반환합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: UI에서 사용할 수 있는 InsightCardModel 목록
  /// Throws: Exception when API call fails
  Future<List<InsightCardModel>> getUserInsights(String userId) async {
    try {
      debugPrint('[InsightService] 사용자 인사이트 목록 조회 시작: $userId');

      final apiInsights = await _repository.getUserInsights(userId);

      final uiModels =
          apiInsights
              .map((apiModel) => InsightCardModel.fromApiArticle(apiModel))
              .toList();

      debugPrint('[InsightService] 인사이트 목록 조회 완료: ${uiModels.length}개');
      return uiModels;
    } catch (e) {
      debugPrint('[InsightService] 인사이트 목록 조회 실패: $e');
      throw Exception('인사이트 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 인사이트의 상세 정보를 조회합니다
  ///
  /// [articleId] 인사이트 아티클 UUID
  /// Returns: 인사이트 상세 정보
  /// Throws: Exception when API call fails or article not found
  Future<InsightDetailApi> getInsightDetail(String articleId) async {
    try {
      debugPrint('[InsightService] 인사이트 상세 조회 시작: $articleId');

      final detail = await _repository.getInsightDetail(articleId);

      debugPrint('[InsightService] 인사이트 상세 조회 완료: ${detail.title}');
      return detail;
    } catch (e) {
      debugPrint('[InsightService] 인사이트 상세 조회 실패: $e');
      throw Exception('인사이트 상세 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자의 데이터를 기반으로 새로운 인사이트를 생성합니다
  ///
  /// [userId] 사용자 UUID
  /// Returns: 생성된 인사이트 상세 정보
  /// Throws: Exception when API call fails or generation fails
  Future<InsightDetailApi> generateInsight(String userId) async {
    try {
      debugPrint('[InsightService] 새 인사이트 생성 시작: $userId');

      final newInsight = await _repository.generateInsight(userId);

      debugPrint('[InsightService] 새 인사이트 생성 완료: ${newInsight.title}');
      return newInsight;
    } catch (e) {
      debugPrint('[InsightService] 인사이트 생성 실패: $e');
      throw Exception('새로운 인사이트를 생성하는데 실패했습니다: $e');
    }
  }

  /// 인사이트를 UI 모델로 변환합니다 (상세 정보 포함)
  ///
  /// [apiModel] API에서 받은 상세 정보
  /// Returns: UI에서 사용할 수 있는 InsightCardModel
  InsightCardModel convertToUiModel(InsightDetailApi apiModel) {
    return InsightCardModel.fromApiDetail(apiModel);
  }

  /// 서비스 정리 (필요한 경우)
  void dispose() {
    debugPrint('[InsightService] 서비스 정리 완료');
  }
}
