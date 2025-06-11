import 'package:flutter/material.dart';
import '../../../../services/models/report_card_model.dart';
import '../../../../services/models/report_card_types.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart' as bottom_sheet;
import '../../../../services/auth/auth_service.dart';
import '../../../../services/report/report_sevice.dart';

/// ReportCard 리스트를 관리하는 ViewModel
class ReportCardListViewModel extends ChangeNotifier {
  final List<ReportCardModel> _reports = [];
  bool _isLoading = false; // 전체 로딩 상태

  // 개별 리포트 로딩 상태
  bool _isDailyLoading = false;
  bool _isWeeklyLoading = false;

  // dispose 체크를 위한 플래그 추가
  bool _isDisposed = false;

  // Service 인스턴스 - ReportService와 AuthService만 필요
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();

  /// Report 리스트 getter - UI에서 실제 사용
  List<ReportCardModel> get reports {
    return _reports.map((report) {
      if (report.type == ReportCardType.daily) {
        return report.copyWith(
          progress: _reportService.getDailyProgress(),
          subtitle: _reportService.getTimeUntilNextDaily(),
        );
      } else if (report.type == ReportCardType.weekly) {
        final progress = _reportService.getWeeklyProgress();
        final activeDots = (progress * 7).ceil();
        return report.copyWith(
          activeDots: activeDots,
          subtitle: _reportService.getDaysUntilNextWeekly(),
        );
      }
      return report;
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get isDailyLoading => _isDailyLoading;
  bool get isWeeklyLoading => _isWeeklyLoading;

  /// 기본 생성자 - 새 리포트 생성 방식
  ReportCardListViewModel() {
    debugPrint('🏗️ ReportCardListViewModel 생성자 - Service 기반 모드');
    _loadDefaultCards();
    _loadCachedDataFirst();
  }

  /// 기본 로딩 카드들을 먼저 표시
  void _loadDefaultCards() {
    debugPrint('📋 기본 로딩 카드 로드');
    _reports.clear();
    _reports.addAll([
      const ReportCardModel(
        id: 'loading_daily',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: '생성 중...',
        progress: 0.0, // 로딩 중에는 0으로 설정
      ),
      const ReportCardModel(
        id: 'loading_weekly',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: '생성 중...',
        activeDots: 0, // 로딩 중에는 0
      ),
      const ReportCardModel(
        id: 'loading_monthly',
        type: ReportCardType.monthly,
        title: '월간 리포트',
        subtitle: '준비 중...',
        activeDots: 0, // 월간은 아직 미구현
      ),
    ]);
    notifyListeners();
  }

  /// 캐시된 데이터를 먼저 로드하고 필요시 새로 생성
  Future<void> _loadCachedDataFirst() async {
    debugPrint('📋 캐시된 데이터 우선 로드 시작 (날짜 기반 캐시)');

    try {
      final userId = _authService.userId;
      final authToken = await _authService.accessToken;

      debugPrint('👤 사용자 정보: userId=$userId, 로그인상태=${_authService.isLoggedIn}');

      if (!_authService.isLoggedIn || userId == null) {
        debugPrint('⚠️ 로그인이 필요합니다. 예시 데이터를 사용합니다.');
        _initializeReports();
        return;
      }

      // 날짜 기반 캐시를 활용한 리포트 생성/로드
      debugPrint('🚀 날짜 기반 캐시 시스템으로 리포트 로드 시작');
      await _generateReportsWithDateCache();
    } catch (e) {
      debugPrint('❌ 캐시 우선 로드 실패: $e');
      _initializeReports(); // 실패 시 예시 데이터로 fallback
    }
  }

  /// 날짜 기반 캐시를 활용한 리포트 생성/로드
  Future<void> _generateReportsWithDateCache() async {
    debugPrint('🗓️ 날짜 기반 캐시 시스템으로 리포트 처리 시작');

    _isLoading = true;
    _isDailyLoading = true;
    _isWeeklyLoading = true;
    notifyListeners();

    try {
      // Daily와 Weekly를 병렬로 처리하되, 완료되는 즉시 UI 업데이트
      // Daily 리포트 생성/캐시 로드 (날짜 기반)
      _generateDailyReportWithCache();

      // Weekly 리포트 생성/캐시 로드 (주차 기반)
      _generateWeeklyReportWithCache();
    } catch (e) {
      debugPrint('❌ 날짜 기반 리포트 처리 실패: $e');
      _initializeReports(); // 실패 시 예시 데이터로 fallback
      _isDailyLoading = false;
      _isWeeklyLoading = false;
      _isLoading = false;
      notifyListeners();
    }

    debugPrint('✅ 날짜 기반 리포트 처리 프로세스 시작 완료');
  }

  /// Daily 리포트 생성/캐시 로드 (날짜 기반)
  Future<void> _generateDailyReportWithCache() async {
    try {
      debugPrint('⏳ Daily 리포트 처리 중... (날짜 기반 캐시)');

      // Service의 날짜 기반 캐시 시스템 사용
      final dailyModel = await _reportService.generateDailyReport();

      // dispose 체크 추가
      if (!_isDisposed) {
        _updateSingleReport(dailyModel);
        debugPrint('✅ Daily 리포트 처리 완료 및 UI 업데이트');
      }
    } catch (e) {
      debugPrint('❌ Daily 리포트 처리 실패: $e');
      // Daily 실패 시 해당 카드만 에러 상태로 표시
      if (!_isDisposed) {
        _updateDailyReportError();
      }
    } finally {
      if (!_isDisposed) {
        _isDailyLoading = false;
        _checkAndUpdateOverallLoading(); // 전체 로딩 상태 체크
      }
    }
  }

  /// Weekly 리포트 생성/캐시 로드 (주차 기반)
  Future<void> _generateWeeklyReportWithCache() async {
    try {
      debugPrint('⏳ Weekly 리포트 처리 중... (주차 기반 캐시)');

      // Service의 주차 기반 캐시 시스템 사용
      final weeklyModel = await _reportService.generateWeeklyReport();

      // dispose 체크 추가
      if (!_isDisposed) {
        _updateSingleReport(weeklyModel);
        debugPrint('✅ Weekly 리포트 처리 완료 및 UI 업데이트');
      }
    } catch (e) {
      debugPrint('❌ Weekly 리포트 처리 실패: $e');
      // Weekly 실패 시 해당 카드만 에러 상태로 표시
      if (!_isDisposed) {
        _updateWeeklyReportError();
      }
    } finally {
      if (!_isDisposed) {
        _isWeeklyLoading = false;
        _checkAndUpdateOverallLoading(); // 전체 로딩 상태 체크
      }
    }
  }

  /// 전체 로딩 상태 체크 및 업데이트
  void _checkAndUpdateOverallLoading() {
    // dispose 체크 추가
    if (_isDisposed) return;

    // 모든 개별 로딩이 완료되면 전체 로딩도 완료
    if (!_isDailyLoading && !_isWeeklyLoading) {
      _isLoading = false;

      // 월간 리포트가 없으면 추가 (백엔드 미구현이므로)
      final hasMonthlyReport = _reports.any(
        (r) => r.type == ReportCardType.monthly,
      );
      if (!hasMonthlyReport) {
        debugPrint('🗓️ 생성 완료 후 월간 리포트 추가');
        _reports.add(
          const ReportCardModel(
            id: 'monthly_placeholder',
            type: ReportCardType.monthly,
            title: '월간 리포트',
            subtitle: '서비스 준비 중',
            activeDots: 0, // 미구현 상태
          ),
        );
      }

      debugPrint('🎉 모든 리포트 생성 작업 완료');
      notifyListeners();
    }
  }

  /// 단일 리포트 업데이트 (즉시 UI 반영)
  void _updateSingleReport(ReportCardModel newReport) {
    // dispose 체크 추가
    if (_isDisposed) return;

    final existingIndex = _reports.indexWhere((r) => r.type == newReport.type);
    if (existingIndex != -1) {
      _reports[existingIndex] = newReport;
      debugPrint('📋 ${newReport.type.name} 리포트 즉시 업데이트 완료');
    } else {
      _reports.add(newReport);
      debugPrint('📋 ${newReport.type.name} 리포트 새로 추가');
    }

    notifyListeners(); // 즉시 UI 업데이트
    _saveReports(); // 즉시 저장
  }

  /// Daily 리포트 에러 상태 업데이트
  void _updateDailyReportError() {
    // dispose 체크 추가
    if (_isDisposed) return;

    final dailyIndex = _reports.indexWhere(
      (r) => r.type == ReportCardType.daily,
    );
    if (dailyIndex != -1) {
      _reports[dailyIndex] = _reports[dailyIndex].copyWith(
        subtitle: '생성 실패',
        progress: 0.0, // 실패 표시
      );
      notifyListeners();
    }
  }

  /// Weekly 리포트 에러 상태 업데이트
  void _updateWeeklyReportError() {
    // dispose 체크 추가
    if (_isDisposed) return;

    final weeklyIndex = _reports.indexWhere(
      (r) => r.type == ReportCardType.weekly,
    );
    if (weeklyIndex != -1) {
      _reports[weeklyIndex] = _reports[weeklyIndex].copyWith(
        subtitle: '생성 실패',
        activeDots: 0, // 실패 표시
      );
      notifyListeners();
    }
  }

  /// 저장된 Report 상태 불러오기 (Service 사용)
  Future<void> _saveReports() async {
    try {
      // Service를 통해 저장 - 데이터 변환도 Service에서 처리
      await _reportService.saveToLocalStorage(_reports);
      debugPrint('💾 ViewModel: Service를 통해 리포트 데이터 저장 완료');
    } catch (e) {
      debugPrint('❌ ViewModel: Service 저장 실패 - $e');
    }
  }

  /// 예시 Report 생성 메서드
  void _initializeReports() {
    debugPrint('📝 예시 데이터 생성');
    _reports.clear();
    _reports.addAll([
      ReportCardModel(
        id: '1',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: '6시간 후 업데이트',
        progress: 1.0, // 완료 시 100%
        imageUrl: 'https://placehold.co/129x178',
      ),
      ReportCardModel(
        id: '2',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: '5일 후 업데이트',
        activeDots: 7, // 완료 시 모든 dot
      ),
      ReportCardModel(
        id: '3',
        type: ReportCardType.monthly,
        title: '월간 리포트',
        subtitle: '서비스 준비 중',
        activeDots: 0, // 미구현 상태
      ),
    ]);
    notifyListeners();
  }

  /// Report 카드 클릭 시 바텀시트 표시 - UI에서 실제 사용
  void showReportBottomSheet(BuildContext context, String reportId) {
    // 클릭된 리포트 찾기
    final selectedReport = _reports.firstWhere(
      (report) => report.id == reportId,
      orElse: () => _reports.first, // 못 찾으면 첫 번째 리포트
    );

    debugPrint(
      '🎯 바텀시트 표시: ${selectedReport.title}, Content: ${selectedReport.content != null ? "있음" : "없음"}',
    );

    showCommonBottomSheet(
      context: context,
      type: bottom_sheet.ReportCardType.report,
      content: selectedReport.content, // 실제 content 전달
      reportType:
          selectedReport.type.toString().split('.').last, // enum을 문자열로 변환
    );
  }

  /// dispose 메서드 오버라이드
  @override
  void dispose() {
    debugPrint('🗑️ ReportCardListViewModel dispose 시작');
    _isDisposed = true;
    super.dispose();
    debugPrint('✅ ReportCardListViewModel dispose 완료');
  }
}
