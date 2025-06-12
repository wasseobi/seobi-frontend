import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'insight_card_model.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart';
import '../../../../services/insight/insight_service.dart';
import '../../../../services/insight/models/insight_detail_api.dart';

/// InsightCard 리스트를 관리하는 ViewModel
///
/// 주요 기능:
/// - 인사이트 목록 로드 및 캐시 관리
/// - 비동기 인사이트 생성 및 대기 상태 관리
/// - 생성 실패 인사이트 필터링
/// - 일주일 기준 자동 생성
class InsightCardListViewModel extends ChangeNotifier {
  // ========================================
  // 상수 및 멤버 변수
  // ========================================

  final List<InsightCardModel> _insights = [];
  final InsightService _insightService = InsightService();

  // 저장소 키
  static const String _storageKey = 'insight_cards_state';
  static const String _generatingKey = 'insight_generating_state';

  // 상태 관리
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  // 생성 실패 키워드 목록
  static const List<String> _failureKeywords = [
    '정보 부족',
    '맞춤형 칼럼 작성 불가',
    '칼럼 작성 불가',
    '어려움',
    '생성 실패',
    '작성할 수 없습니다',
    '충분하지 않습니다',
    '데이터가 부족',
    '분석할 수 없습니다',
  ];

  // ========================================
  // Getters 및 생성자
  // ========================================

  /// Insight 리스트 getter
  List<InsightCardModel> get insights => _insights;

  /// 로딩 상태 getter
  bool get isLoading => _isLoading;

  /// 생성 중 상태 getter
  bool get isGenerating => _isGenerating;

  /// 에러 상태 getter
  String? get error => _error;

  /// 기본 생성자
  InsightCardListViewModel() {
    _loadGeneratingState();
    _loadInsights();
  }

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _insightService.setAuthToken(token);
  }

  // ========================================
  // 메인 API 로드 로직
  // ========================================

  /// API에서 인사이트 목록을 로드합니다
  Future<void> loadInsightsFromAPI() async {
    if (_isLoading) return; // 중복 호출 방지

    _setLoading(true);
    _setError(null);

    try {
      debugPrint('[ViewModel] API에서 인사이트 목록 로드 시작');

      // 1단계: 목록 조회
      final articles = await _insightService.getUserInsights();
      debugPrint('[ViewModel] 인사이트 목록 조회 완료: ${articles.length}개');

      // 2단계: 실패 인사이트 필터링 후 UI 표시
      final validArticles = _filterValidInsights(articles);
      _insights.clear();
      _insights.addAll(validArticles);

      // 3단계: 상세 정보 로드
      _loadDetailedInsights(validArticles);

      notifyListeners();
    } catch (e) {
      debugPrint('[ViewModel] API 인사이트 로드 실패: $e');
      _setError('인사이트를 불러오는데 실패했습니다: $e');
      await _loadInsightsFromLocal();
    } finally {
      _setLoading(false);
    }
  }

  /// 백그라운드에서 상세 정보 조회
  Future<void> _loadDetailedInsights(List<InsightCardModel> basicModels) async {
    try {
      debugPrint('[ViewModel] 백그라운드에서 상세 정보 조회 시작');

      // 상세 정보 조회
      final detailedInsights = await Future.wait(
        basicModels.map((model) => _insightService.getInsightDetail(model.id)),
      );

      // 실패 인사이트 필터링
      final validDetailedInsights =
          detailedInsights
              .where((detail) => !_isFailedInsightDetail(detail))
              .toList();

      if (validDetailedInsights.length != detailedInsights.length) {
        debugPrint(
          '[ViewModel] 상세 조회 중 ${detailedInsights.length - validDetailedInsights.length}개의 실패 인사이트 필터링됨',
        );
      }

      // UI 모델로 변환 및 업데이트
      final detailedUiModels =
          validDetailedInsights
              .map((detail) => InsightCardModel.fromApiDetail(detail))
              .toList();

      _insights.clear();
      _insights.addAll(detailedUiModels);
      _saveInsights();
      notifyListeners();
    } catch (e) {
      debugPrint('[ViewModel] 백그라운드 상세 정보 조회 실패: $e');
    }
  }

  // ========================================
  // 인사이트 생성 로직
  // ========================================

  /// 생성 중 상태 로드
  Future<void> _loadGeneratingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasGenerating = prefs.getBool(_generatingKey) ?? false;

      // 이전에 생성 중이었다면 생성 중 카드만 추가하고 실제 생성 상태는 false로 설정
      if (wasGenerating) {
        _addGeneratingCard();
      }
      _isGenerating = false; // 앱 시작시에는 항상 false로 시작
      await _saveGeneratingState(false);
      notifyListeners();
    } catch (e) {
      debugPrint('[ViewModel] 생성 중 상태 로드 실패: $e');
    }
  }

  /// 생성 중 카드 추가
  void _addGeneratingCard() {
    // 이미 생성 중 카드가 있다면 추가하지 않음
    if (_insights.any((insight) => insight.id == 'generating')) {
      return;
    }

    _insights.insert(
      0,
      InsightCardModel(
        id: 'generating',
        title: '인사이트 생성 중...',
        keywords: ['생성중'],
        date: DateTime.now().toString().substring(0, 10),
      ),
    );
  }

  /// 생성 중 카드 제거
  void _removeGeneratingCard() {
    _insights.removeWhere((insight) => insight.id == 'generating');
  }

  /// 생성 중 카드가 있는지 확인
  bool _hasGeneratingCard() {
    return _insights.any((insight) => insight.id == 'generating');
  }

  /// 생성 중 상태 저장
  Future<void> _saveGeneratingState(bool generating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_generatingKey, generating);
    } catch (e) {
      debugPrint('[ViewModel] 생성 중 상태 저장 실패: $e');
    }
  }

  /// 오늘 생성된 인사이트가 있는지 확인
  bool _hasTodayInsight() {
    final today = DateTime.now().toString().substring(0, 10);
    return _insights.any(
      (insight) => insight.date == today && insight.id != 'generating',
    );
  }

  /// 새 인사이트를 생성합니다
  Future<void> generateNewInsight() async {
    debugPrint('[ViewModel] generateNewInsight 호출됨');

    // 생성 중 카드가 있으면 중복 생성 방지
    if (_hasGeneratingCard()) {
      debugPrint('[ViewModel] 이미 생성 중 카드가 있어서 무시됨');
      return;
    }

    _setGenerating(true);
    await _saveGeneratingState(true);
    _setError(null);

    try {
      debugPrint('[ViewModel] 새 인사이트 생성 시작');

      // 생성 중임을 표시
      _addGeneratingCard();
      notifyListeners();

      debugPrint('[ViewModel] InsightService.generateInsight 호출 시작');
      // 인사이트 생성 요청
      final newInsight = await _insightService.generateInsight();
      debugPrint(
        '[ViewModel] InsightService.generateInsight 호출 완료: ${newInsight.id}',
      );

      // 생성 중 표시 제거
      _removeGeneratingCard();

      // 새 인사이트가 실패한 것이 아니라면 목록에 추가
      if (!_isFailedInsightDetail(newInsight)) {
        _insights.insert(0, InsightCardModel.fromApiDetail(newInsight));
        _saveInsights();
        await _saveGeneratingState(false);
        debugPrint('[ViewModel] 새 인사이트 생성 및 저장 완료');
      } else {
        debugPrint('[ViewModel] 생성된 인사이트가 실패로 판단됨');
        _setError('인사이트 생성에 실패했습니다. 나중에 다시 시도해주세요.');
      }
    } catch (e, stackTrace) {
      debugPrint('[ViewModel] 인사이트 생성 중 에러 발생:');
      debugPrint(e.toString());
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      _removeGeneratingCard();
      _setError('인사이트 생성에 실패했습니다: $e');
    } finally {
      _setGenerating(false);
      notifyListeners();
    }
  }

  // ========================================
  // 생성 실패 필터링 로직
  // ========================================

  /// 인사이트가 생성 실패 메시지를 포함하는지 확인
  bool _isFailedInsight(InsightCardModel insight) {
    final title = insight.title.toLowerCase();

    for (final keyword in _failureKeywords) {
      if (title.contains(keyword.toLowerCase())) {
        debugPrint('[ViewModel] 생성 실패 인사이트 감지: ${insight.title}');
        return true;
      }
    }
    return false;
  }

  /// 인사이트 상세 내용이 생성 실패 메시지를 포함하는지 확인
  bool _isFailedInsightDetail(InsightDetailApi detail) {
    final title = detail.title.toLowerCase();
    final content = detail.content.toLowerCase();

    for (final keyword in _failureKeywords) {
      final lowercaseKeyword = keyword.toLowerCase();
      if (title.contains(lowercaseKeyword) ||
          content.contains(lowercaseKeyword)) {
        debugPrint('[ViewModel] 생성 실패 인사이트 상세 감지: ${detail.title}');
        return true;
      }
    }
    return false;
  }

  /// 인사이트 목록에서 생성 실패한 것들을 필터링
  List<InsightCardModel> _filterValidInsights(List<InsightCardModel> insights) {
    final validInsights =
        insights.where((insight) => !_isFailedInsight(insight)).toList();

    if (validInsights.length != insights.length) {
      debugPrint(
        '[ViewModel] ${insights.length - validInsights.length}개의 실패 인사이트 필터링됨',
      );
    }

    return validInsights;
  }

  // ========================================
  // 로컬 저장소 관리
  // ========================================

  /// 저장된 Insight 상태 불러오기
  Future<void> _loadInsights() async {
    if (_insightService.isUserLoggedIn) {
      debugPrint('[ViewModel] 로그인 상태 - API에서 실제 데이터 로드 시도');
      try {
        await loadInsightsFromAPI();
        return;
      } catch (e) {
        debugPrint('[ViewModel] API 로드 실패, 로컬 캐시로 fallback: $e');
      }
    } else {
      debugPrint('[ViewModel] 비로그인 상태 - 로컬 데이터 사용');
    }

    await _loadInsightsFromLocal();
  }

  /// 로컬 저장소에서 인사이트 로드
  Future<void> _loadInsightsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInsights = prefs.getString(_storageKey);

      if (savedInsights != null) {
        final List<dynamic> decodedInsights = jsonDecode(savedInsights);
        final loadedInsights =
            decodedInsights
                .map(
                  (insight) =>
                      InsightCardModel.fromMap(insight as Map<String, dynamic>),
                )
                .toList();

        // 로컬에서 로드한 인사이트도 필터링 적용
        final validLoadedInsights = _filterValidInsights(loadedInsights);

        _insights.clear();
        _insights.addAll(validLoadedInsights);
        notifyListeners();
        debugPrint(
          '[ViewModel] 로컬 캐시에서 인사이트 로드: ${validLoadedInsights.length}개 (필터링 적용)',
        );
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

  // ========================================
  // UI 상호작용 및 기타
  // ========================================

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

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    if (!generating) {
      _saveGeneratingState(false);
    }
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 리소스 정리
  @override
  void dispose() {
    _insightService.dispose();
    super.dispose();
  }
}
