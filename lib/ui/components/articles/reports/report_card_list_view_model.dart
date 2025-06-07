import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'report_card_model.dart';
import 'report_card_types.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart' as bottom_sheet;

/// ReportCard 리스트를 관리하는 ViewModel
class ReportCardListViewModel extends ChangeNotifier {
  final List<ReportCardModel> _reports = [];
  static const String _storageKey = 'report_cards_state';

  /// Report 리스트 getter
  List<ReportCardModel> get reports => _reports;

  /// 기본 생성자
  ReportCardListViewModel() {
    _loadReports();
  }

  /// 특정 Report 데이터로 초기화하는 생성자
  ReportCardListViewModel.withReports(List<ReportCardModel> reports) {
    _reports.addAll(reports);
  }

  /// 저장된 Report 상태 불러오기
  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReports = prefs.getString(_storageKey);

      if (savedReports != null) {
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
        _initializeReports();
      }
    } catch (e) {
      _initializeReports();
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
    } catch (e) {
      debugPrint('Failed to save reports: $e');
    }
  }

  /// 예시 Report 생성 메서드
  void _initializeReports() {
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

  /// Report 카드 클릭 시 바텀시트 표시
  void showReportBottomSheet(BuildContext context) {
    showCommonBottomSheet(
      context: context,
      type: bottom_sheet.ReportCardType.report,
    );
  }
}
