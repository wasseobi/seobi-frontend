import 'package:flutter/foundation.dart';
import '../../repositories/insight/insight_repository.dart';
import '../../repositories/insight/i_insight_repository.dart';
import '../../ui/components/articles/insights/insight_card_model.dart';
import '../../services/auth/auth_service.dart';
import 'models/insight_article_api.dart';
import 'models/insight_detail_api.dart';

/// Insight 관련 비즈니스 로직을 담당하는 서비스 클래스
class InsightService {
  final IInsightRepository _repository;
  final AuthService _authService = AuthService();

  InsightService({IInsightRepository? repository})
    : _repository = repository ?? InsightRepository();

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    if (_repository is InsightRepository) {
      (_repository as InsightRepository).setAuthToken(token);
    }
  }

  /// 사용자 인증 정보를 가져옵니다
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    // Repository에 인증 토큰 설정
    setAuthToken(user.accessToken);
    return user.id;
  }

  /// 현재 사용자의 인사이트 목록을 UI 모델로 변환하여 반환합니다 (AuthService 사용)
  ///
  /// Returns: UI에서 사용할 수 있는 InsightCardModel 목록
  /// Throws: Exception when API call fails or user not logged in
  Future<List<InsightCardModel>> getUserInsights() async {
    try {
      // 인증 확인 및 사용자 ID 가져오기
      final userId = await _getUserIdAndAuthenticate();
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
      // 인증 확인
      await _getUserIdAndAuthenticate();
      debugPrint('[InsightService] 인사이트 상세 조회 시작: $articleId');

      final detail = await _repository.getInsightDetail(articleId);

      debugPrint('[InsightService] 인사이트 상세 조회 완료: ${detail.title}');
      return detail;
    } catch (e) {
      debugPrint('[InsightService] 인사이트 상세 조회 실패: $e');
      throw Exception('인사이트 상세 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 데이터를 기반으로 새로운 인사이트를 생성합니다
  Future<InsightDetailApi> generateInsight() async {
    try {
      debugPrint('[InsightService] generateInsight 호출됨');
      // 인증 확인 및 사용자 ID 가져오기
      final userId = await _getUserIdAndAuthenticate();
      debugPrint('[InsightService] 인증 확인 완료, userId: $userId');

      final newInsight = await _repository.generateInsight(userId);
      debugPrint('[InsightService] 인사이트 생성 완료: ${newInsight.id}');
      return newInsight;
    } catch (e, stackTrace) {
      debugPrint('[InsightService] 인사이트 생성 중 에러 발생:');
      debugPrint(e.toString());
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      throw Exception('인사이트 생성에 실패했습니다: $e');
    }
  }

  /// 인사이트를 UI 모델로 변환합니다 (상세 정보 포함)
  ///
  /// [apiModel] API에서 받은 상세 정보
  /// Returns: UI에서 사용할 수 있는 InsightCardModel
  InsightCardModel convertToUiModel(InsightDetailApi apiModel) {
    return InsightCardModel.fromApiDetail(apiModel);
  }

  /// 사용자 인증 상태 확인
  bool get isUserLoggedIn => _authService.isLoggedIn;

  /// 사용자 ID 가져오기
  String? get userId => _authService.userId;

  /// 서비스 정리 (필요한 경우)
  void dispose() {
    debugPrint('[InsightService] 서비스 정리 완료');
  }
}
