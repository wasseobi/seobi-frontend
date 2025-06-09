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
  bool _isLoading = false; // 로딩 상태 추가

  // API 서비스 및 인증 서비스 인스턴스 추가
  final ReportApiService _apiService = ReportApiService();
  final AuthService _authService = AuthService();

  /// Report 리스트 getter
  List<ReportCardModel> get reports => _reports;
  bool get isLoading => _isLoading; // 로딩 상태 getter

  /// 기본 생성자 - 새 리포트 생성 방식
  ReportCardListViewModel() {
    debugPrint('🏗️ ReportCardListViewModel 생성자 - 새 리포트 생성 모드');
    _loadDefaultCards();
    _generateNewReports(); // refreshReports 대신 새 리포트 생성
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

  /// 새 리포트 생성 (옵션 A 구현) - 개별 처리 방식
  Future<void> _generateNewReports() async {
    debugPrint('🚀 새 리포트 생성 시작');

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.userId;
      final authToken = await _authService.accessToken;

      debugPrint('👤 사용자 정보: userId=$userId, 로그인상태=${_authService.isLoggedIn}');

      if (!_authService.isLoggedIn || userId == null) {
        debugPrint('⚠️ 로그인이 필요합니다. 예시 데이터를 사용합니다.');
        _initializeReports();
        return;
      }

      debugPrint('📡 새 리포트 생성 API 호출 시작... User ID: $userId');

      final List<Map<String, dynamic>> successfulReports = [];

      // Daily 리포트 생성 (개별 처리)
      try {
        debugPrint('⏳ Daily 리포트 생성 중...');
        final dailyReport = await _apiService.createDailyReport(
          userId: userId,
          authToken: authToken,
        );
        successfulReports.add(dailyReport);
        debugPrint('✅ Daily 리포트 생성 완료: ${dailyReport.keys}');
      } catch (e) {
        debugPrint('❌ Daily 리포트 생성 실패: $e');
        // Daily 실패해도 계속 진행
      }

      // Weekly 리포트 생성 (개별 처리)
      try {
        debugPrint('⏳ Weekly 리포트 생성 중...');
        final weeklyReport = await _apiService.createWeeklyReport(
          userId: userId,
          authToken: authToken,
        );
        successfulReports.add(weeklyReport);
        debugPrint('✅ Weekly 리포트 생성 완료: ${weeklyReport.keys}');
      } catch (e) {
        debugPrint('❌ Weekly 리포트 생성 실패: $e');
        // Weekly 실패해도 계속 진행
      }

      // 성공한 리포트가 있으면 업데이트
      if (successfulReports.isNotEmpty) {
        debugPrint('🎉 ${successfulReports.length}개 리포트 생성 성공');
        _updateReportsWithGeneratedData(successfulReports);
        await _saveReports();
        debugPrint('💾 생성된 리포트 데이터 저장 완료');
      } else {
        debugPrint('⚠️ 모든 리포트 생성 실패 - 예시 데이터 사용');
        _initializeReports();
      }
    } catch (e) {
      debugPrint('❌ 리포트 생성 전체 실패: $e');
      _initializeReports(); // 실패 시 예시 데이터로 fallback
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ 새 리포트 생성 프로세스 완료');
    }
  }

  /// 생성된 리포트 데이터로 UI 업데이트
  void _updateReportsWithGeneratedData(
    List<Map<String, dynamic>> generatedReports,
  ) {
    debugPrint('🔄 생성된 리포트로 UI 업데이트 시작');

    for (var reportData in generatedReports) {
      final model = _convertGeneratedReportToModel(reportData);

      // 같은 타입의 로딩 카드를 찾아서 교체
      final existingIndex = _reports.indexWhere((r) => r.type == model.type);
      if (existingIndex != -1) {
        _reports[existingIndex] = model;
        debugPrint('📋 ${model.type.name} 리포트 업데이트 완료');
      } else {
        _reports.add(model);
        debugPrint('📋 ${model.type.name} 리포트 새로 추가');
      }
    }

    // Monthly는 아직 생성 API가 없으므로 기본 상태로 설정
    final monthlyIndex = _reports.indexWhere(
      (r) => r.type == ReportCardType.monthly,
    );
    if (monthlyIndex != -1) {
      _reports[monthlyIndex] = _reports[monthlyIndex].copyWith(
        subtitle: '곧 제공될 예정입니다',
        activeDots: 4, // 완료된 것처럼 표시
      );
    }

    notifyListeners();
  }

  /// 생성된 리포트 API 응답을 ReportCardModel로 변환
  ReportCardModel _convertGeneratedReportToModel(
    Map<String, dynamic> generatedReport,
  ) {
    // createDailyReport/createWeeklyReport API 응답 구조에 맞게 변환
    final String? reportType =
        generatedReport['type']?.toString().toLowerCase();
    final Map<String, dynamic>? content =
        generatedReport['content'] ?? generatedReport;

    debugPrint(
      '생성된 리포트 변환 중 - Type: $reportType, Content: ${content != null ? "있음" : "없음"}',
    );

    if (reportType == 'daily' || content?['type'] == 'daily') {
      return ReportCardModel(
        id:
            generatedReport['id']?.toString() ??
            'generated-daily-${DateTime.now().millisecondsSinceEpoch}',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: '방금 생성됨',
        progress: 1.0, // 생성 완료
        imageUrl: 'https://placehold.co/129x178',
        content: content,
      );
    } else if (reportType == 'weekly' || content?['type'] == 'weekly') {
      return ReportCardModel(
        id:
            generatedReport['id']?.toString() ??
            'generated-weekly-${DateTime.now().millisecondsSinceEpoch}',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: '방금 생성됨',
        activeDots: 7, // 생성 완료
        content: content,
      );
    } else {
      // 타입을 명확히 알 수 없는 경우 daily로 기본 설정
      return ReportCardModel(
        id:
            generatedReport['id']?.toString() ??
            'generated-unknown-${DateTime.now().millisecondsSinceEpoch}',
        type: ReportCardType.daily,
        title: '새 리포트',
        subtitle: '방금 생성됨',
        progress: 1.0,
        content: content,
      );
    }
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

    // 타입별 기본 설정 (content 포함) - 완료 시 progress를 1.0(100%)으로 설정
    switch (type) {
      case 'daily':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: '오늘의 리포트',
          subtitle: '최신 업데이트됨',
          progress: 1.0, // 완료 시 100%로 설정
          imageUrl: 'https://placehold.co/129x178',
          content: content, // content 필드 추가
        );
      case 'weekly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.weekly,
          title: '주간 리포트',
          subtitle: '이번 주 요약',
          activeDots: 7, // 완료 시 모든 dot 활성화
          content: content, // content 필드 추가
        );
      case 'monthly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.monthly,
          title: '월간 리포트',
          subtitle: '이번 달 요약',
          activeDots: 4, // 완료 시 모든 dot 활성화
          content: content, // content 필드 추가
        );
      default:
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: title,
          subtitle: '업데이트됨',
          progress: 1.0, // 완료 시 100%로 설정
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
          progress: 1.0, // 완료 시 100%
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
          activeDots: 7, // 완료 시 모든 dot
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
          activeDots: 4, // 완료 시 모든 dot
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

  /// 강제 새로고침 (기존 리포트 가져오기 방식 - 향후 삭제 예정)
  Future<void> refreshReports() async {
    debugPrint('🔄 refreshReports() 시작 - API 우선 호출');

    // 로딩 시작
    _isLoading = true;
    notifyListeners();

    try {
      // AuthService에서 사용자 정보 가져오기
      final authService = AuthService();
      final userId = authService.userId;
      final authToken = await authService.accessToken;

      debugPrint(
        '👤 사용자 정보: userId=$userId, token=${authToken != null ? "있음" : "없음"}',
      );

      if (userId != null) {
        debugPrint('🌐 API 호출 시작');

        // Daily와 Weekly API를 병렬로 호출
        final dailyFuture = _apiService.getDailyReports(
          userId: userId,
          authToken: authToken,
        );
        final weeklyFuture = _apiService.getWeeklyReports(
          userId: userId,
          authToken: authToken,
        );

        final results = await Future.wait([dailyFuture, weeklyFuture]);
        final dailyReports = results[0];
        final weeklyReports = results[1];

        debugPrint('✅ Daily API 응답: ${dailyReports.length}개');
        debugPrint('✅ Weekly API 응답: ${weeklyReports.length}개');

        // 모든 API 응답을 합치기
        final allApiReports = <Map<String, dynamic>>[];
        allApiReports.addAll(dailyReports);
        allApiReports.addAll(weeklyReports);

        if (allApiReports.isNotEmpty) {
          debugPrint('✅ 전체 API 응답: ${allApiReports.length}개 리포트');

          // 기존 카드는 유지하고 실제 데이터로 업데이트
          for (var reportData in allApiReports) {
            final model = _convertApiResponseToModel(reportData);

            // 같은 타입의 기존 카드를 찾아서 교체
            final existingIndex = _reports.indexWhere(
              (r) => r.type == model.type,
            );
            if (existingIndex != -1) {
              _reports[existingIndex] = model;
            } else {
              _reports.add(model);
            }
            debugPrint(
              '📋 리포트 업데이트: ${model.title}, Content: ${model.content != null ? "있음" : "없음"}',
            );
          }

          await _saveReports();
          debugPrint('💾 리포트 데이터 저장 완료');
        } else {
          debugPrint('⚠️ API 응답이 비어있음 - 예시 데이터 로드');
          _loadExampleReports();
        }
      } else {
        debugPrint('❌ 사용자 ID 없음 - 예시 데이터 로드');
        _loadExampleReports();
      }
    } catch (e) {
      debugPrint('💥 API 호출 실패: $e - 예시 데이터 로드');
      _loadExampleReports();
    } finally {
      // 로딩 완료
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ refreshReports() 완료');
    }
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
        subtitle: '23일 후 업데이트',
        activeDots: 4, // 완료 시 모든 dot
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

  /// 예시 Report 데이터 로드
  void _loadExampleReports() {
    debugPrint('📝 예시 데이터로 업데이트');
    // 카드를 완전히 교체하지 않고 업데이트
    for (int i = 0; i < _reports.length; i++) {
      final existingReport = _reports[i];
      _reports[i] = ReportCardModel(
        id: 'example_${existingReport.type.toString().split('.').last}',
        type: existingReport.type,
        title: existingReport.title,
        subtitle:
            existingReport.type == ReportCardType.daily
                ? '오늘의 활동 요약'
                : existingReport.subtitle,
        progress:
            existingReport.type == ReportCardType.daily
                ? 1.0 // 완료 시 100%
                : existingReport.progress,
        activeDots:
            existingReport.type != ReportCardType.daily
                ? (existingReport.type == ReportCardType.weekly
                    ? 7
                    : 4) // 완료 시 모든 dot
                : existingReport.activeDots,
        imageUrl:
            existingReport.type == ReportCardType.daily
                ? 'https://example.com/daily_image.jpg'
                : null,
      );
    }
    notifyListeners();
  }
}
