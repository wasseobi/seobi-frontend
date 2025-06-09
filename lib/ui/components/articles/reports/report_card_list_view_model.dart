import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'report_card_model.dart';
import 'report_card_types.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart' as bottom_sheet;
import '../../../../services/report/report_api_service.dart';
import '../../../../services/auth/auth_service.dart';

/// ReportCard 리스트를 관리하는 ViewModel
class ReportCardListViewModel extends ChangeNotifier {
  final List<ReportCardModel> _reports = [];
  static const String _storageKey = 'report_cards_state';

  // API 서비스 및 인증 서비스 인스턴스 추가
  final ReportApiService _apiService = ReportApiService();
  final AuthService _authService = AuthService();

  /// Report 리스트 getter
  List<ReportCardModel> get reports => _reports;

  /// 기본 생성자 - 항상 최신 API 데이터 우선
  ReportCardListViewModel() {
    debugPrint('🏗️ ReportCardListViewModel 생성자 - API 우선 모드');
    refreshReports(); // SharedPreferences 대신 API 우선
  }

  /// 특정 Report 데이터로 초기화하는 생성자
  ReportCardListViewModel.withReports(List<ReportCardModel> reports) {
    _reports.addAll(reports);
  }

  /// 저장된 Report 상태 불러오기 (API 연동 추가)
  Future<void> _loadReports() async {
    debugPrint('🔄 _loadReports() 시작');

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReports = prefs.getString(_storageKey);

      debugPrint(
        '💾 SharedPreferences 확인: ${savedReports != null ? "데이터 있음" : "데이터 없음"}',
      );

      // 1. SharedPreferences에서 먼저 확인
      if (savedReports != null) {
        debugPrint('📦 기존 저장된 데이터 사용 - API 호출 건너뜀');
        final List<dynamic> decodedReports = jsonDecode(savedReports);
        _reports.addAll(
          decodedReports
              .map(
                (report) =>
                    ReportCardModel.fromMap(report as Map<String, dynamic>),
              )
              .toList(),
        );
        notifyListeners();
      } else {
        // 2. SharedPreferences에 없으면 API 호출 시도
        debugPrint('🌐 SharedPreferences에 데이터 없음 - API 호출 시도');
        await _loadFromApi();
      }
    } catch (e) {
      debugPrint('❌ _loadReports 오류: $e');
      _initializeReports();
    }
  }

  /// API에서 리포트 데이터 로드
  Future<void> _loadFromApi() async {
    debugPrint('🚀 _loadFromApi() 시작');

    try {
      // 실제 인증 정보 사용
      final userId = _authService.userId;
      final authToken = await _authService.accessToken;

      debugPrint('👤 사용자 정보: userId=$userId, 로그인상태=${_authService.isLoggedIn}');

      // 로그인 상태 확인
      if (!_authService.isLoggedIn || userId == null) {
        debugPrint('⚠️ 로그인이 필요합니다. 예시 데이터를 사용합니다.');
        _initializeReports();
        return;
      }

      debugPrint('📡 API에서 리포트 데이터를 가져오는 중... User ID: $userId');

      final List<Map<String, dynamic>> apiReports = await _apiService
          .getAllReports(userId: userId, authToken: authToken);

      debugPrint('✅ API 응답: ${apiReports.length}개 리포트');
      debugPrint('📄 API 응답 내용: $apiReports');

      // API 응답을 ReportCardModel로 변환
      final List<ReportCardModel> convertedReports =
          apiReports.map((apiReport) {
            return _convertApiResponseToModel(apiReport);
          }).toList();

      // 필요한 타입이 없는 경우 기본 데이터 추가
      _ensureAllReportTypes(convertedReports);

      _reports.addAll(convertedReports);
      notifyListeners();
      _saveReports(); // API에서 가져온 데이터 저장
    } catch (e) {
      debugPrint('❌ API 호출 실패: $e');
      // API 호출 실패 시 예시 데이터로 fallback
      _initializeReports();
    }
  }

  /// API 응답을 ReportCardModel로 변환
  ReportCardModel _convertApiResponseToModel(Map<String, dynamic> apiResponse) {
    final String type =
        apiResponse['type']?.toString().toLowerCase() ?? 'daily';
    final Map<String, dynamic>? content = apiResponse['content'];
    final String title =
        content?['text']?.toString().substring(0, 20) ?? '${type} 리포트';

    debugPrint(
      'API 응답 변환 중 - Type: $type, Content: ${content != null ? "있음" : "없음"}',
    );

    // 타입별 기본 설정 (content 포함)
    switch (type) {
      case 'daily':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: '오늘의 리포트',
          subtitle: '최신 업데이트됨',
          progress: 0.75,
          imageUrl: 'https://placehold.co/129x178',
          content: content, // content 필드 추가
        );
      case 'weekly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.weekly,
          title: '주간 리포트',
          subtitle: '이번 주 요약',
          activeDots: 5,
          content: content, // content 필드 추가
        );
      case 'monthly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.monthly,
          title: '월간 리포트',
          subtitle: '이번 달 요약',
          activeDots: 3,
          content: content, // content 필드 추가
        );
      default:
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: title,
          subtitle: '업데이트됨',
          progress: 0.5,
          content: content, // content 필드 추가
        );
    }
  }

  /// 모든 리포트 타입이 있는지 확인하고 없으면 기본값 추가
  void _ensureAllReportTypes(List<ReportCardModel> reports) {
    final hasDaily = reports.any((r) => r.type == ReportCardType.daily);
    final hasWeekly = reports.any((r) => r.type == ReportCardType.weekly);
    final hasMonthly = reports.any((r) => r.type == ReportCardType.monthly);

    if (!hasDaily) {
      reports.add(
        ReportCardModel(
          id: 'default-daily',
          type: ReportCardType.daily,
          title: '오늘의 리포트',
          subtitle: '데이터 준비 중',
          progress: 0.0,
        ),
      );
    }

    if (!hasWeekly) {
      reports.add(
        ReportCardModel(
          id: 'default-weekly',
          type: ReportCardType.weekly,
          title: '주간 리포트',
          subtitle: '데이터 준비 중',
          activeDots: 2,
        ),
      );
    }

    if (!hasMonthly) {
      reports.add(
        ReportCardModel(
          id: 'default-monthly',
          type: ReportCardType.monthly,
          title: '월간 리포트',
          subtitle: '데이터 준비 중',
          activeDots: 1,
        ),
      );
    }
  }

  /// 새 리포트 생성 (API 호출)
  Future<void> createDailyReport() async {
    try {
      final userId = _authService.userId;
      final authToken = await _authService.accessToken;

      if (!_authService.isLoggedIn || userId == null) {
        debugPrint('로그인이 필요합니다.');
        return;
      }

      debugPrint('새 데일리 리포트 생성 중...');

      final Map<String, dynamic> newReport = await _apiService
          .createDailyReport(userId: userId, authToken: authToken);

      debugPrint('새 데일리 리포트 생성 완료: ${newReport['text']}');

      // 생성된 리포트를 리스트에 반영하기 위해 다시 로드
      await refreshReports();
    } catch (e) {
      debugPrint('데일리 리포트 생성 실패: $e');
    }
  }

  /// 새 위클리 리포트 생성 (API 호출)
  Future<void> createWeeklyReport() async {
    try {
      final userId = _authService.userId;
      final authToken = await _authService.accessToken;

      if (!_authService.isLoggedIn || userId == null) {
        debugPrint('로그인이 필요합니다.');
        return;
      }

      debugPrint('새 위클리 리포트 생성 중...');

      final Map<String, dynamic> newReport = await _apiService
          .createWeeklyReport(userId: userId, authToken: authToken);

      debugPrint('새 위클리 리포트 생성 완료: ${newReport['text']}');

      // 생성된 리포트를 리스트에 반영하기 위해 다시 로드
      await refreshReports();
    } catch (e) {
      debugPrint('위클리 리포트 생성 실패: $e');
    }
  }

  /// 리포트 목록 새로고침 (API 우선)
  Future<void> refreshReports() async {
    debugPrint('🔄 refreshReports() - 강제 API 호출');
    _reports.clear();
    await _loadFromApi();
  }

  /// Report 상태 저장
  Future<void> _saveReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedReports = jsonEncode(
        _reports.map((report) => report.toMap()).toList(),
      );
      await prefs.setString(_storageKey, encodedReports);
      debugPrint('💾 리포트 데이터 저장 완료');
    } catch (e) {
      debugPrint('Failed to save reports: $e');
    }
  }

  /// 예시 Report 생성 메서드
  void _initializeReports() {
    debugPrint('📝 예시 데이터 생성');
    _reports.addAll([
      ReportCardModel(
        id: '1',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: '6시간 후 업데이트',
        progress: 0.75,
        imageUrl: 'https://placehold.co/129x178',
      ),
      ReportCardModel(
        id: '2',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: '5일 후 업데이트',
        activeDots: 4,
      ),
      ReportCardModel(
        id: '3',
        type: ReportCardType.monthly,
        title: '월간 리포트',
        subtitle: '23일 후 업데이트',
        activeDots: 2,
      ),
    ]);
    notifyListeners();
  }

  /// Map 형식의 데이터 리스트로 Report 초기화
  void initWithMapList(List<Map<String, dynamic>> reportList) {
    _reports.addAll(
      reportList.map((map) => ReportCardModel.fromMap(map)).toList(),
    );
    notifyListeners();
  }

  /// 새 Report 추가
  void addReport(ReportCardModel report) {
    _reports.add(report);
    notifyListeners();
    _saveReports();
  }

  /// Map 형식으로 새 Report 추가
  void addReportFromMap(Map<String, dynamic> reportMap) {
    final report = ReportCardModel.fromMap(reportMap);
    addReport(report);
  }

  /// 특정 Report 업데이트
  void updateReport(String id, ReportCardModel updatedReport) {
    final index = _reports.indexWhere((report) => report.id == id);
    if (index != -1) {
      _reports[index] = updatedReport;
      notifyListeners();
      _saveReports();
    }
  }

  /// 모든 Report 삭제
  void clearReports() {
    _reports.clear();
    notifyListeners();
    _saveReports();
  }

  /// Report 진행 상태 업데이트
  void updateReportProgress(String reportId, double progress) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(progress: progress.clamp(0.0, 1.0));
      notifyListeners();
      _saveReports();
    }
  }

  /// Report 활성 점 업데이트
  void updateActiveDots(String reportId, int activeDots) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(activeDots: activeDots);
      notifyListeners();
      _saveReports();
    }
  }

  /// Report 카드 클릭 시 바텀시트 표시 (실제 content 포함)
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
}
