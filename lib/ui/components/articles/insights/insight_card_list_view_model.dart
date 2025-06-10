import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'insight_card_model.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart';
import '../../../../services/insight/insight_service.dart';
import '../../../../services/insight/models/insight_detail_api.dart';

/// InsightCard 리스트를 관리하는 ViewModel
class InsightCardListViewModel extends ChangeNotifier {
  final List<InsightCardModel> _insights = [];
  final InsightService _insightService = InsightService();
  static const String _storageKey = 'insight_cards_state';

  // 상태 관리
  bool _isLoading = false;
  String? _error;

  /// Insight 리스트 getter
  List<InsightCardModel> get insights => _insights;

  /// 로딩 상태 getter
  bool get isLoading => _isLoading;

  /// 에러 상태 getter
  String? get error => _error;

  /// 기본 생성자
  InsightCardListViewModel() {
    _loadInsights();
  }

  /// 특정 Insight 데이터로 초기화하는 생성자
  InsightCardListViewModel.withInsights(List<InsightCardModel> insights) {
    _insights.addAll(insights);
  }

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _insightService.setAuthToken(token);
  }

  /// API에서 인사이트 목록을 로드합니다 (해결방안 2: 키워드 포함)
  Future<void> loadInsightsFromAPI() async {
    if (_isLoading) return; // 중복 호출 방지

    _setLoading(true);
    _setError(null);

    try {
      debugPrint('[ViewModel] API에서 인사이트 목록 로드 시작');

      // 1단계: 목록 조회 (키워드 없음)
      final articles = await _insightService.getUserInsights();
      debugPrint('[ViewModel] 인사이트 목록 조회 완료: ${articles.length}개');

      if (articles.isEmpty) {
        _insights.clear();
        notifyListeners();
        _setLoading(false);
        return;
      }

      // 2단계: 각 아티클의 상세 정보 조회 (키워드 포함)
      debugPrint('[ViewModel] 인사이트 상세 정보 일괄 조회 시작');
      final detailedInsights = await Future.wait(
        articles.map((article) => _insightService.getInsightDetail(article.id)),
      );

      // 3단계: UI 모델로 변환 (키워드 포함)
      final uiModels =
          detailedInsights
              .map((detail) => InsightCardModel.fromApiDetail(detail))
              .toList();

      // 4단계: 상태 업데이트
      _insights.clear();
      _insights.addAll(uiModels);

      // 5단계: 로컬 저장 (캐시용)
      await _saveInsights();

      debugPrint('[ViewModel] API 인사이트 로드 완료: ${_insights.length}개 (키워드 포함)');
    } catch (e) {
      debugPrint('[ViewModel] API 인사이트 로드 실패: $e');
      _setError('인사이트를 불러오는데 실패했습니다: $e');

      // API 실패 시 로컬 캐시 로드 시도
      await _loadInsightsFromLocal();
    } finally {
      _setLoading(false);
    }
  }

  /// 새 인사이트를 생성합니다
  Future<void> generateNewInsight() async {
    if (_isLoading) return;

    _setLoading(true);
    _setError(null);

    try {
      debugPrint('[ViewModel] 새 인사이트 생성 시작');

      final newInsight = await _insightService.generateInsight();
      final newUiModel = InsightCardModel.fromApiDetail(newInsight);

      // 목록 맨 앞에 추가 (최신 순)
      _insights.insert(0, newUiModel);
      await _saveInsights();

      debugPrint('[ViewModel] 새 인사이트 생성 완료: ${newInsight.title}');
    } catch (e) {
      debugPrint('[ViewModel] 인사이트 생성 실패: $e');
      _setError('새 인사이트를 생성하는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 특정 인사이트의 상세 정보를 조회합니다 (바텀시트용)
  Future<InsightDetailApi?> getInsightDetail(String articleId) async {
    try {
      return await _insightService.getInsightDetail(articleId);
    } catch (e) {
      debugPrint('[ViewModel] 인사이트 상세 조회 실패: $e');
      _setError('인사이트 상세 정보를 불러오는데 실패했습니다');
      return null;
    }
  }

  /// 저장된 Insight 상태 불러오기 (자동 API 호출 포함)
  Future<void> _loadInsights() async {
    // 1단계: 로그인 상태 확인
    if (_insightService.isUserLoggedIn) {
      debugPrint('[ViewModel] 로그인 상태 - API에서 실제 데이터 로드 시도');
      try {
        await loadInsightsFromAPI();
        return; // API 성공 시 여기서 종료
      } catch (e) {
        debugPrint('[ViewModel] API 로드 실패, 로컬 캐시로 fallback: $e');
        // API 실패 시 아래 로컬 로드 로직으로 진행
      }
    } else {
      debugPrint('[ViewModel] 비로그인 상태 - 로컬 데이터 사용');
    }

    // 2단계: 로컬 저장소에서 로드 (기존 로직)
    await _loadInsightsFromLocal();
  }

  /// 로컬 저장소에서 인사이트 로드
  Future<void> _loadInsightsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInsights = prefs.getString(_storageKey);

      if (savedInsights != null) {
        final List<dynamic> decodedInsights = jsonDecode(savedInsights);
        _insights.clear();
        _insights.addAll(
          decodedInsights
              .map(
                (insight) =>
                    InsightCardModel.fromMap(insight as Map<String, dynamic>),
              )
              .toList(),
        );
        notifyListeners();
        debugPrint('[ViewModel] 로컬 캐시에서 인사이트 로드: ${_insights.length}개');
      } else {
        _initializeInsights();
      }
    } catch (e) {
      debugPrint('[ViewModel] 로컬 인사이트 로드 실패: $e');
      _initializeInsights();
    }
  }

  /// Insight 상태 저장
  Future<void> _saveInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedInsights = jsonEncode(
        _insights.map((insight) => insight.toMap()).toList(),
      );
      await prefs.setString(_storageKey, encodedInsights);
    } catch (e) {
      debugPrint('Failed to save insights: $e');
    }
  }

  /// 예시 Insight 생성 메서드 (API 실패 시 Fallback)
  void _initializeInsights() {
    _insights.addAll([
      InsightCardModel(
        id: '1',
        title: '주간 업무 분석',
        keywords: ['생산성', '업무패턴', '시간관리'],
        date: '2024.03.15',
      ),
      InsightCardModel(
        id: '2',
        title: '월간 성과 리포트',
        keywords: ['목표달성', '성과지표', '개선점'],
        date: '2024.03.14',
      ),
      InsightCardModel(
        id: '3',
        title: '업무 효율성 분석',
        keywords: ['업무효율', '시간분배', '최적화'],
        date: '2024.03.13',
      ),
    ]);
    notifyListeners();
    debugPrint('[ViewModel] 예시 인사이트 초기화 완료');
  }

  /// Map 형식의 데이터 리스트로 Insight 초기화
  void initWithMapList(List<Map<String, dynamic>> insightList) {
    _insights.addAll(
      insightList.map((map) => InsightCardModel.fromMap(map)).toList(),
    );
    notifyListeners();
  }

  /// 새 Insight 추가
  void addInsight(InsightCardModel insight) {
    _insights.add(insight);
    notifyListeners();
    _saveInsights();
  }

  /// Map 형식으로 새 Insight 추가
  void addInsightFromMap(Map<String, dynamic> insightMap) {
    final insight = InsightCardModel.fromMap(insightMap);
    addInsight(insight);
  }

  /// 특정 Insight 업데이트
  void updateInsight(String id, InsightCardModel updatedInsight) {
    final index = _insights.indexWhere((insight) => insight.id == id);
    if (index != -1) {
      _insights[index] = updatedInsight;
      notifyListeners();
      _saveInsights();
    }
  }

  /// 모든 Insight 삭제
  void clearInsights() {
    _insights.clear();
    notifyListeners();
    _saveInsights();
  }

  /// Insight 카드 클릭 시 바텀시트 표시
  void showInsightBottomSheet(BuildContext context, String articleId) {
    showCommonBottomSheet(
      context: context,
      type: ReportCardType.insight,
      articleId: articleId,
    );
  }

  /// 상태 관리 헬퍼 메서드들
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 클리어
  void clearError() {
    _setError(null);
  }

  /// 리소스 정리
  @override
  void dispose() {
    _insightService.dispose();
    super.dispose();
  }
}
