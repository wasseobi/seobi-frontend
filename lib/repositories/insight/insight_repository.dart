import '../../services/insight/insight_api_service.dart';
import '../../services/insight/models/insight_article_api.dart';
import '../../services/insight/models/insight_detail_api.dart';
import '../../services/auth/auth_service.dart';
import 'i_insight_repository.dart';

/// Insight Repository의 구현체
/// API 서비스를 통해 실제 데이터 조회 및 조작을 수행합니다
class InsightRepository implements IInsightRepository {
  final InsightApiService _apiService;
  final AuthService _authService = AuthService();

  InsightRepository({InsightApiService? apiService})
    : _apiService = apiService ?? InsightApiService();

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  /// 사용자 인증 정보를 가져오고 API 서비스에 설정합니다
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    // API 서비스에 인증 토큰 설정
    _apiService.setAuthToken(user.accessToken);
    return user.id;
  }

  @override
  Future<List<InsightArticleApi>> getUserInsights(String userId) async {
    try {
      // 인증 확인 및 토큰 설정
      await _getUserIdAndAuthenticate();

      return await _apiService.getUserInsights(userId);
    } catch (e) {
      // Repository 레벨에서 추가적인 에러 처리나 로깅 가능
      rethrow; // 현재는 그대로 전달
    }
  }

  @override
  Future<InsightDetailApi> getInsightDetail(String articleId) async {
    try {
      // 인증 확인 및 토큰 설정
      await _getUserIdAndAuthenticate();

      return await _apiService.getInsightDetail(articleId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<InsightDetailApi> generateInsight(String userId) async {
    try {
      // 인증 확인 및 토큰 설정
      await _getUserIdAndAuthenticate();

      return await _apiService.generateInsight(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자 인증 상태 확인
  bool get isUserLoggedIn => _authService.isLoggedIn;

  /// 사용자 ID 가져오기
  String? get userId => _authService.userId;
}
