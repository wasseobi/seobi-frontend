import 'package:flutter/material.dart';
import '../../repositories/report/report_repository.dart';
import '../models/report_card_model.dart';
import '../models/report_card_types.dart';

/*

✅ 비즈니스 로직 처리
✅ 원시 데이터 → UI 모델 변환
✅ 복잡한 데이터 조작
✅ ViewModel이 사용하기 쉬운 형태로 가공
✅ 싱글톤 패턴으로 앱 생명 주기 동안 한 번만 초기화

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

  // 캐시 유효 시간 (5분)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // 초기화 상태 추적
  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🏗️ ReportService 싱글톤 초기화 시작');
    try {
      // 필요한 초기화 작업이 있다면 여기에 추가
      _isInitialized = true;
      debugPrint('✅ ReportService 싱글톤 초기화 완료');
    } catch (e) {
      debugPrint('❌ ReportService 초기화 실패: $e');
      rethrow;
    }
  }

  /// 캐시된 데이터가 유효한지 확인
  bool get _isCacheValid {
    if (_cachedReports == null || _lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  /// Daily 리포트 생성 및 모델 변환
  Future<ReportCardModel> generateDailyReport() async {
    debugPrint('🔧 Service: Daily 리포트 생성 시작');

    try {
      final dailyReportData = await _repository.createDailyReport();

      // API 응답을 UI 모델로 변환
      final dailyModel = ReportCardModel(
        id:
            dailyReportData['id']?.toString() ??
            'generated-daily-${DateTime.now().millisecondsSinceEpoch}',
        type: ReportCardType.daily,
        title: '오늘의 리포트',
        subtitle: '방금 생성됨',
        progress: 1.0, // 생성 완료
        imageUrl: 'https://placehold.co/129x178',
        content: dailyReportData,
      );

      debugPrint('✅ Service: Daily 리포트 생성 및 변환 완료');
      return dailyModel;
    } catch (e) {
      debugPrint('❌ Service: Daily 리포트 생성 실패 - $e');
      rethrow; // 에러를 상위로 전달
    }
  }

  /// Weekly 리포트 생성 및 모델 변환
  Future<ReportCardModel> generateWeeklyReport() async {
    debugPrint('🔧 Service: Weekly 리포트 생성 시작');

    try {
      final weeklyReportData = await _repository.createWeeklyReport();

      // API 응답을 UI 모델로 변환
      final weeklyModel = ReportCardModel(
        id:
            weeklyReportData['id']?.toString() ??
            'generated-weekly-${DateTime.now().millisecondsSinceEpoch}',
        type: ReportCardType.weekly,
        title: '주간 리포트',
        subtitle: '방금 생성됨',
        activeDots: 7, // 생성 완료
        content: weeklyReportData,
      );

      debugPrint('✅ Service: Weekly 리포트 생성 및 변환 완료');
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
  void clearCache() {
    debugPrint('🗑️ Service: 캐시 클리어');
    _cachedReports = null;
    _lastLoadTime = null;
  }

  /// 사용자 로그인 상태 확인
  bool get isUserLoggedIn => _repository.isUserLoggedIn;

  /// 서비스 정리
  Future<void> dispose() async {
    debugPrint('🗑️ ReportService 정리 시작');
    clearCache();
    // 필요한 정리 작업이 있다면 여기에 추가
    debugPrint('✅ ReportService 정리 완료');
  }
}
