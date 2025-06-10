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
  static const String _pendingRequestKey = 'pending_insight_request';

  // 상태 관리
  bool _isLoading = false;
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

  /// 에러 상태 getter
  String? get error => _error;

  /// 기본 생성자
  InsightCardListViewModel() {
    _loadInsights();
  }

  /// 인증 토큰을 설정합니다
  void setAuthToken(String? token) {
    _insightService.setAuthToken(token);
  }

  // ========================================
  // 메인 API 로드 로직
  // ========================================

  /// API에서 인사이트 목록을 로드합니다 (비동기 생성 패턴 적용)
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

      // 3단계: 대기 중인 생성 요청 처리
      await _checkPendingGenerationRequests(validArticles.length);
      notifyListeners();

      // 4단계: 백그라운드에서 상세 정보 조회 및 자동 생성
      _loadDetailedInsightsAndAutoGenerate(validArticles);
    } catch (e) {
      debugPrint('[ViewModel] API 인사이트 로드 실패: $e');
      _setError('인사이트를 불러오는데 실패했습니다: $e');
      await _loadInsightsFromLocal();
    } finally {
      _setLoading(false);
    }
  }

  /// 백그라운드에서 상세 정보 조회 및 자동 생성 처리
  Future<void> _loadDetailedInsightsAndAutoGenerate(
    List<InsightCardModel> basicModels,
  ) async {
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

      _updateInsightsWithGeneration(detailedUiModels);

      // 자동 생성 체크
      await _checkAndGenerateWeeklyInsight();
    } catch (e) {
      debugPrint('[ViewModel] 백그라운드 상세 정보 조회 실패: $e');
      try {
        await _checkAndGenerateWeeklyInsight();
      } catch (autoGenError) {
        debugPrint('[ViewModel] 자동 생성도 실패: $autoGenError');
      }
    }
  }

  /// 생성 중 카드를 유지하면서 인사이트 목록 업데이트
  void _updateInsightsWithGeneration(List<InsightCardModel> newInsights) {
    final generatingCards =
        _insights.where((insight) => insight.id == 'generating').toList();

    _insights.clear();
    if (generatingCards.isNotEmpty) {
      _insights.add(generatingCards.first);
    }
    _insights.addAll(newInsights);

    _saveInsights();
    notifyListeners();
    debugPrint('[ViewModel] 상세 정보 조회 완료 및 UI 업데이트: ${_insights.length}개');
  }

  // ========================================
  // 비동기 인사이트 생성 관리
  // ========================================

  /// 대기 중인 생성 요청 확인 및 처리
  Future<void> _checkPendingGenerationRequests(int currentInsightCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString(_pendingRequestKey);
      if (pendingData == null) return;

      final pendingInfo = jsonDecode(pendingData);
      final requestDate = DateTime.parse(pendingInfo['requestDate']);
      final expectedCount = pendingInfo['expectedCount'] as int;
      final daysSinceRequest = DateTime.now().difference(requestDate).inDays;

      debugPrint(
        '[ViewModel] 대기 중인 요청 확인: ${daysSinceRequest}일 전 (일주일 기준), 예상 개수: $expectedCount, 현재 개수: $currentInsightCount',
      );

      if (currentInsightCount > expectedCount) {
        // 새 인사이트가 생성됨 - 대기 상태 해제
        debugPrint('[ViewModel] 새 인사이트 생성 완료 - 대기 상태 해제');
        await prefs.remove(_pendingRequestKey);
      } else if (daysSinceRequest >= 7) {
        // 일주일 지남 - 재요청
        debugPrint('[ViewModel] 일주일 지났지만 생성 안됨 - 재요청 시작');
        await _retryInsightGeneration();
      } else {
        // 대기 중 - 생성 중 카드 표시
        debugPrint('[ViewModel] 생성 대기 중 - 생성 중 카드 표시');
        _showGeneratingCard();
      }
    } catch (e) {
      debugPrint('[ViewModel] 대기 요청 확인 실패: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingRequestKey);
    }
  }

  /// 생성 중 카드를 표시합니다
  void _showGeneratingCard() {
    final hasGeneratingCard = _insights.any(
      (insight) => insight.id == 'generating',
    );
    if (!hasGeneratingCard) {
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
  }

  /// 인사이트 생성을 재시도합니다
  Future<void> _retryInsightGeneration() async {
    try {
      debugPrint('[ViewModel] 인사이트 생성 재시도 시작');
      _showGeneratingCard();
      notifyListeners();
      await _requestInsightGenerationAsync();
    } catch (e) {
      debugPrint('[ViewModel] 인사이트 생성 재시도 실패: $e');
    }
  }

  /// 비동기 인사이트 생성 요청
  Future<void> _requestInsightGenerationAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 짧은 타임아웃으로 생성 요청 (10초)
      await _insightService.generateInsight().timeout(
        const Duration(seconds: 10),
      );

      // 10초 안에 완료되면 성공 처리
      debugPrint('[ViewModel] 인사이트 생성 즉시 완료');
      await prefs.remove(_pendingRequestKey);
      await loadInsightsFromAPI();
    } catch (e) {
      // 타임아웃이거나 실패해도 "생성 중"으로 처리
      debugPrint('[ViewModel] 인사이트 생성 비동기 처리: $e');

      final prefs = await SharedPreferences.getInstance();
      final pendingInfo = {
        'requestDate': DateTime.now().toIso8601String(),
        'expectedCount': _insights.where((i) => i.id != 'generating').length,
      };

      await prefs.setString(_pendingRequestKey, jsonEncode(pendingInfo));
      debugPrint('[ViewModel] 생성 요청 기록 완료 - 일주일 후 확인 예정');
    }
  }

  /// 새 인사이트를 생성합니다 (비동기 패턴)
  Future<void> generateNewInsight() async {
    if (_isLoading) return;

    debugPrint('[ViewModel] 새 인사이트 생성 시작 (비동기 패턴)');
    _showGeneratingCard();
    notifyListeners();
    await _requestInsightGenerationAsync();
  }

  // ========================================
  // 자동 생성 로직 (일주일 기준)
  // ========================================

  /// 마지막 인사이트 생성 날짜 확인 및 자동 생성 (일주일 기준)
  Future<void> _checkAndGenerateWeeklyInsight() async {
    if (_insights.isEmpty) return;

    try {
      final realInsights =
          _insights.where((insight) => insight.id != 'generating').toList();

      if (realInsights.isEmpty) {
        // 인사이트가 없으면 첫 인사이트 생성
        debugPrint('[ViewModel] 인사이트 없음 - 첫 인사이트 생성 (비동기)');
        await _requestInsightGenerationAsync();
        return;
      }

      // 가장 최근 인사이트의 날짜 확인
      final latestInsight = realInsights.first;
      final latestDate = _parseDate(latestInsight.date);

      if (latestDate == null) {
        debugPrint('[ViewModel] 날짜 파싱 실패: ${latestInsight.date}');
        return;
      }

      final now = DateTime.now();
      final daysDifference = now.difference(latestDate).inDays;

      debugPrint(
        '[ViewModel] 마지막 인사이트 날짜: ${latestInsight.date}, 차이: ${daysDifference}일',
      );

      // 일주일 이상 차이나면 자동 생성
      if (daysDifference >= 7) {
        debugPrint(
          '[ViewModel] 마지막 인사이트가 ${daysDifference}일 전 생성됨 - 새 인사이트 자동 생성 시작 (비동기)',
        );
        await _requestInsightGenerationAsync();
      } else {
        debugPrint('[ViewModel] 아직 일주일이 지나지 않음 - 자동 생성 스킵');
      }
    } catch (e) {
      debugPrint('[ViewModel] 날짜 기반 자동 생성 체크 실패: $e');
    }
  }

  /// 날짜 문자열을 DateTime으로 파싱 ("2024.03.15" → DateTime)
  DateTime? _parseDate(String dateString) {
    try {
      final normalizedDate = dateString.replaceAll('.', '-');
      return DateTime.parse(normalizedDate);
    } catch (e) {
      debugPrint('[ViewModel] 날짜 파싱 오류: $dateString - $e');
      return null;
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

  /// 저장된 Insight 상태 불러오기 (자동 API 호출 포함)
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
