import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../repositories/report/report_repository.dart';
import '../models/report_card_model.dart';
import '../models/report_card_types.dart';

/*

✅ 비즈니스 로직 처리
✅ 원시 데이터 → UI 모델 변환
✅ 복잡한 데이터 조작
✅ ViewModel이 사용하기 쉬운 형태로 가공
✅ 싱글톤 패턴으로 앱 생명 주기 동안 한 번만 초기화
✅ 날짜 기반 캐시를 영구 저장소에 저장
✅ 날짜 기반 인디케이터 변화를 위한 함수 추가

*/

/// 리포트 비즈니스 로직을 담당하는 Service (싱글톤)
class ReportService {
  // 싱글톤 패턴 구현
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final ReportRepository _repository = ReportRepository();

  // 캐시된 데이터
  List<ReportCardModel>? _cachedReports;
  DateTime? _lastLoadTime;

  // 날짜별 리포트 캐시
  ReportCardModel? _cachedDailyReport;
  ReportCardModel? _cachedWeeklyReport;
  DateTime? _lastDailyGenerationDate;
  DateTime? _lastWeeklyGenerationDate;

  // 캐시 유효 시간 (5분) - 목록 조회용
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // 영구 저장소 키들
  static const String _dailyReportKey = 'cached_daily_report';
  static const String _weeklyReportKey = 'cached_weekly_report';
  static const String _dailyDateKey = 'daily_generation_date';
  static const String _weeklyDateKey = 'weekly_generation_date';

  // 초기화 상태 추적
  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🏗️ ReportService 싱글톤 초기화 시작');
    try {
      // 영구 저장소에서 캐시 로드
      await _loadCacheFromStorage();
      _isInitialized = true;
      debugPrint('✅ ReportService 싱글톤 초기화 완료');
    } catch (e) {
      debugPrint('❌ ReportService 초기화 실패: $e');
      rethrow;
    }
  }

  /// 영구 저장소에서 캐시 로드
  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Daily 리포트 캐시 로드
      final dailyReportJson = prefs.getString(_dailyReportKey);
      final dailyDateString = prefs.getString(_dailyDateKey);

      if (dailyReportJson != null && dailyDateString != null) {
        _cachedDailyReport = ReportCardModel.fromMap(
          jsonDecode(dailyReportJson),
        );
        _lastDailyGenerationDate = DateTime.parse(dailyDateString);
        debugPrint('📱 영구 저장소에서 Daily 리포트 캐시 로드 완료');
      }

      // Weekly 리포트 캐시 로드
      final weeklyReportJson = prefs.getString(_weeklyReportKey);
      final weeklyDateString = prefs.getString(_weeklyDateKey);

      if (weeklyReportJson != null && weeklyDateString != null) {
        _cachedWeeklyReport = ReportCardModel.fromMap(
          jsonDecode(weeklyReportJson),
        );
        _lastWeeklyGenerationDate = DateTime.parse(weeklyDateString);
        debugPrint('📱 영구 저장소에서 Weekly 리포트 캐시 로드 완료');
      }

      debugPrint('✅ 영구 저장소 캐시 로드 완료');
    } catch (e) {
      debugPrint('❌ 영구 저장소 캐시 로드 실패: $e');
      // 실패해도 앱은 계속 실행
    }
  }

  /// 영구 저장소에 캐시 저장
  Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Daily 리포트 캐시 저장
      if (_cachedDailyReport != null && _lastDailyGenerationDate != null) {
        await prefs.setString(
          _dailyReportKey,
          jsonEncode(_cachedDailyReport!.toMap()),
        );
        await prefs.setString(
          _dailyDateKey,
          _lastDailyGenerationDate!.toIso8601String(),
        );
        debugPrint('💾 Daily 리포트 캐시 영구 저장 완료');
      }

      // Weekly 리포트 캐시 저장
      if (_cachedWeeklyReport != null && _lastWeeklyGenerationDate != null) {
        await prefs.setString(
          _weeklyReportKey,
          jsonEncode(_cachedWeeklyReport!.toMap()),
        );
        await prefs.setString(
          _weeklyDateKey,
          _lastWeeklyGenerationDate!.toIso8601String(),
        );
        debugPrint('💾 Weekly 리포트 캐시 영구 저장 완료');
      }
    } catch (e) {
      debugPrint('❌ 영구 저장소 캐시 저장 실패: $e');
      // 실패해도 앱은 계속 실행
    }
  }

  /// 캐시된 데이터가 유효한지 확인 (목록 조회용)
  bool get _isCacheValid {
    if (_cachedReports == null || _lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  /// 오늘 날짜와 비교하여 데일리 리포트 재생성 필요 여부 확인
  bool get _shouldGenerateNewDailyReport {
    if (_cachedDailyReport == null || _lastDailyGenerationDate == null)
      return true;

    final now = DateTime.now();
    final lastGeneration = _lastDailyGenerationDate!;

    // 날짜가 다르면 새로 생성 필요
    return now.year != lastGeneration.year ||
        now.month != lastGeneration.month ||
        now.day != lastGeneration.day;
  }

  /// 이번 주와 비교하여 주간 리포트 재생성 필요 여부 확인
  bool get _shouldGenerateNewWeeklyReport {
    if (_cachedWeeklyReport == null || _lastWeeklyGenerationDate == null)
      return true;

    final now = DateTime.now();
    final lastGeneration = _lastWeeklyGenerationDate!;

    // 주차가 다르면 새로 생성 필요 (월요일 기준)
    final nowWeekStart = _getWeekStart(now);
    final lastWeekStart = _getWeekStart(lastGeneration);

    return nowWeekStart.difference(lastWeekStart).inDays != 0;
  }

  /// 주의 시작일(월요일) 계산
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1(월) ~ 7(일)
    final daysToSubtract = weekday - 1; // 월요일까지 뺄 일수
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// 월의 몇 번째 주인지 계산 (더 정확한 방법)
  int _getWeekOfMonth(DateTime date) {
    // 단순히 날짜를 7로 나누어 주차 계산 (더 직관적)
    return ((date.day - 1) ~/ 7) + 1;
  }

  /// 생성 시각 기준 다음 데일리 리포트까지 남은 시간 계산
  String getTimeUntilNextDaily() {
    if (_lastDailyGenerationDate == null) return '';
    final now = DateTime.now();
    final end = _lastDailyGenerationDate!.add(const Duration(hours: 24));
    final difference = end.difference(now);
    if (difference.isNegative) return '업데이트 가능';
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    if (hours > 0) {
      return '${hours}시간 후 업데이트';
    } else {
      return '${minutes}분 후 업데이트';
    }
  }

  /// 생성 시각 기준 다음 주간 리포트까지 남은 일수 계산
  String getDaysUntilNextWeekly() {
    if (_lastWeeklyGenerationDate == null) return '';
    final now = DateTime.now();
    final end = _lastWeeklyGenerationDate!.add(const Duration(days: 7));
    final difference = end.difference(now);
    if (difference.isNegative) return '업데이트 가능';
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    if (days > 0) {
      return '${days}일 후 업데이트';
    } else {
      return '${hours}시간 후 업데이트';
    }
  }

  /// Daily 리포트 생성 및 모델 변환 (날짜 기반 캐시 적용)
  Future<ReportCardModel> generateDailyReport() async {
    debugPrint('🔧 Service: Daily 리포트 생성 시작 (날짜 기반 캐시)');

    // 오늘 이미 생성된 리포트가 있으면 캐시 반환
    if (!_shouldGenerateNewDailyReport) {
      debugPrint('✅ Service: 오늘 이미 생성된 Daily 리포트 반환 (캐시)');
      return _cachedDailyReport!.copyWith(subtitle: getTimeUntilNextDaily());
    }

    try {
      debugPrint('🚀 Service: 새 Daily 리포트 생성 중...');
      final dailyReportData = await _repository.createDailyReport();

      // API 응답을 UI 모델로 변환
      final now = DateTime.now();
      final dailyModel = ReportCardModel(
        id:
            dailyReportData['id']?.toString() ??
            'generated-daily-${now.millisecondsSinceEpoch}',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: getTimeUntilNextDaily(),
        progress: 1.0, // 생성 완료
        imageUrl: 'https://placehold.co/129x178',
        content: dailyReportData,
      );

      // 캐시 업데이트
      _cachedDailyReport = dailyModel;
      _lastDailyGenerationDate = DateTime.now();

      // 영구 저장소에 저장
      await _saveCacheToStorage();

      debugPrint('✅ Service: Daily 리포트 생성 및 캐시 저장 완료');
      return dailyModel;
    } catch (e) {
      debugPrint('❌ Service: Daily 리포트 생성 실패 - $e');
      rethrow; // 에러를 상위로 전달
    }
  }

  /// Weekly 리포트 생성 및 모델 변환 (주차 기반 캐시 적용)
  Future<ReportCardModel> generateWeeklyReport() async {
    debugPrint('🔧 Service: Weekly 리포트 생성 시작 (주차 기반 캐시)');

    // 이번 주 이미 생성된 리포트가 있으면 캐시 반환
    if (!_shouldGenerateNewWeeklyReport) {
      debugPrint('✅ Service: 이번 주 이미 생성된 Weekly 리포트 반환 (캐시)');
      return _cachedWeeklyReport!.copyWith(subtitle: getDaysUntilNextWeekly());
    }

    try {
      debugPrint('🚀 Service: 새 Weekly 리포트 생성 중...');
      final weeklyReportData = await _repository.createWeeklyReport();

      // API 응답을 UI 모델로 변환
      final now = DateTime.now();
      final weeklyModel = ReportCardModel(
        id:
            weeklyReportData['id']?.toString() ??
            'generated-weekly-${now.millisecondsSinceEpoch}',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: getDaysUntilNextWeekly(),
        activeDots: 7, // 생성 완료
        content: weeklyReportData,
      );

      // 캐시 업데이트
      _cachedWeeklyReport = weeklyModel;
      _lastWeeklyGenerationDate = DateTime.now();

      // 영구 저장소에 저장
      await _saveCacheToStorage();

      debugPrint('✅ Service: Weekly 리포트 생성 및 캐시 저장 완료');
      return weeklyModel;
    } catch (e) {
      debugPrint('❌ Service: Weekly 리포트 생성 실패 - $e');
      rethrow; // 에러를 상위로 전달
    }
  }

  /// 기존 리포트 목록 조회 및 모델 변환 (캐시 적용)
  Future<List<ReportCardModel>> loadAllReports({
    bool forceRefresh = false,
  }) async {
    debugPrint('🔧 Service: 리포트 목록 로드 시작 (캐시 체크)');

    // 캐시가 유효하고 강제 새로고침이 아니면 캐시된 데이터 반환
    if (!forceRefresh && _isCacheValid) {
      debugPrint('✅ Service: 캐시된 리포트 데이터 반환 (${_cachedReports!.length}개)');
      return List.from(_cachedReports!);
    }

    try {
      final reportsData = await _repository.getAllReports();

      // API 응답을 UI 모델 리스트로 변환
      final convertedReports =
          reportsData.map((reportData) {
            return _convertApiResponseToModel(reportData);
          }).toList();

      // 캐시 업데이트
      _cachedReports = convertedReports;
      _lastLoadTime = DateTime.now();

      debugPrint('✅ Service: 리포트 목록 로드 및 변환 완료 (${convertedReports.length}개)');
      return convertedReports;
    } catch (e) {
      debugPrint('❌ Service: 리포트 목록 로드 실패 - $e');

      // API 실패 시 캐시된 데이터가 있으면 반환
      if (_cachedReports != null) {
        debugPrint('⚠️ Service: API 실패, 캐시된 데이터 반환');
        return List.from(_cachedReports!);
      }

      rethrow; // 에러를 상위로 전달
    }
  }

  /// 로컬 저장소에서 리포트 로드 및 모델 변환
  Future<List<ReportCardModel>?> loadFromLocalStorage() async {
    debugPrint('🔧 Service: 로컬 저장소에서 로드 시작');

    try {
      final savedReportsData = await _repository.loadFromLocalStorage();

      if (savedReportsData != null) {
        final models =
            savedReportsData
                .map(
                  (report) =>
                      ReportCardModel.fromMap(report as Map<String, dynamic>),
                )
                .toList();

        debugPrint('✅ Service: 로컬 저장소에서 로드 완료 (${models.length}개)');
        return models;
      }

      debugPrint('💾 Service: 로컬 저장소에 데이터 없음');
      return null;
    } catch (e) {
      debugPrint('❌ Service: 로컬 저장소 로드 실패 - $e');
      return null;
    }
  }

  /// 리포트 모델 리스트를 로컬 저장소에 저장
  Future<void> saveToLocalStorage(List<ReportCardModel> reports) async {
    debugPrint('🔧 Service: 로컬 저장소에 저장 시작');

    try {
      final reportsMap = reports.map((report) => report.toMap()).toList();
      await _repository.saveToLocalStorage(reportsMap);
      debugPrint('✅ Service: 로컬 저장소에 저장 완료');
    } catch (e) {
      debugPrint('❌ Service: 로컬 저장소 저장 실패 - $e');
    }
  }

  /// API 응답을 ReportCardModel로 변환 (비즈니스 로직)
  ReportCardModel _convertApiResponseToModel(Map<String, dynamic> apiResponse) {
    final String type =
        apiResponse['type']?.toString().toLowerCase() ?? 'daily';
    final Map<String, dynamic>? content = apiResponse['content'];

    debugPrint('🔄 Service: API 응답 변환 중 - Type: $type');

    // 타입별 변환 로직
    switch (type) {
      case 'daily':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: '오늘의 리포트',
          subtitle: '최신 업데이트됨',
          progress: 1.0,
          imageUrl: 'https://placehold.co/129x178',
          content: content,
        );
      case 'weekly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.weekly,
          title: '주간 리포트',
          subtitle: '이번 주 요약',
          activeDots: 7,
          content: content,
        );
      case 'monthly':
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.monthly,
          title: '월간 리포트',
          subtitle: '이번 달 요약',
          activeDots: 4,
          content: content,
        );
      default:
        return ReportCardModel(
          id: apiResponse['id']?.toString() ?? '',
          type: ReportCardType.daily,
          title: '새 리포트',
          subtitle: '업데이트됨',
          progress: 1.0,
          content: content,
        );
    }
  }

  /// 캐시 클리어
  Future<void> clearCache() async {
    debugPrint('🗑️ Service: 캐시 클리어');
    _cachedReports = null;
    _lastLoadTime = null;
    _cachedDailyReport = null;
    _cachedWeeklyReport = null;
    _lastDailyGenerationDate = null;
    _lastWeeklyGenerationDate = null;

    // 영구 저장소에서도 삭제
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyReportKey);
      await prefs.remove(_weeklyReportKey);
      await prefs.remove(_dailyDateKey);
      await prefs.remove(_weeklyDateKey);
      debugPrint('🗑️ 영구 저장소 캐시 삭제 완료');
    } catch (e) {
      debugPrint('❌ 영구 저장소 캐시 삭제 실패: $e');
    }
  }

  /// 특정 타입 캐시만 클리어
  Future<void> clearReportCache(ReportCardType type) async {
    debugPrint('🗑️ Service: ${type.name} 리포트 캐시 클리어');

    try {
      final prefs = await SharedPreferences.getInstance();

      switch (type) {
        case ReportCardType.daily:
          _cachedDailyReport = null;
          _lastDailyGenerationDate = null;
          await prefs.remove(_dailyReportKey);
          await prefs.remove(_dailyDateKey);
          break;
        case ReportCardType.weekly:
          _cachedWeeklyReport = null;
          _lastWeeklyGenerationDate = null;
          await prefs.remove(_weeklyReportKey);
          await prefs.remove(_weeklyDateKey);
          break;
        case ReportCardType.monthly:
          // 월간은 아직 구현되지 않음
          break;
      }
      debugPrint('🗑️ ${type.name} 영구 저장소 캐시 삭제 완료');
    } catch (e) {
      debugPrint('❌ ${type.name} 영구 저장소 캐시 삭제 실패: $e');
    }
  }

  /// 사용자 로그인 상태 확인
  bool get isUserLoggedIn => _repository.isUserLoggedIn;

  /// 서비스 정리
  Future<void> dispose() async {
    debugPrint('🗑️ ReportService 정리 시작');

    // 현재 캐시를 영구 저장소에 저장
    await _saveCacheToStorage();

    // 필요한 정리 작업이 있다면 여기에 추가
    debugPrint('✅ ReportService 정리 완료');
  }

  /// 오늘의 리포트 남은 시간 비율 (0.0~1.0, 생성 시각 기준 24시간)
  double getDailyProgress() {
    if (_lastDailyGenerationDate == null) return 1.0;
    final now = DateTime.now();
    final start = _lastDailyGenerationDate!;
    final end = start.add(const Duration(hours: 24));
    final total = end.difference(start).inSeconds;
    final remain = end.difference(now).inSeconds;
    if (remain <= 0) return 0.0;
    if (remain >= total) return 1.0;
    return remain / total;
  }

  /// 주간 리포트 남은 시간 비율 (0.0~1.0, 생성 시각 기준 7일)
  double getWeeklyProgress() {
    if (_lastWeeklyGenerationDate == null) return 1.0;
    final now = DateTime.now();
    final start = _lastWeeklyGenerationDate!;
    final end = start.add(const Duration(days: 7));
    final total = end.difference(start).inSeconds;
    final remain = end.difference(now).inSeconds;
    if (remain <= 0) return 0.0;
    if (remain >= total) return 1.0;
    return remain / total;
  }
}
