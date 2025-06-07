import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'insight_card_model.dart';
import '../../bottom_sheet/bottom_sheet.dart';
import '../../bottom_sheet/bottom_sheet_types.dart';

/// InsightCard 리스트를 관리하는 ViewModel
class InsightCardListViewModel extends ChangeNotifier {
  final List<InsightCardModel> _insights = [];
  static const String _storageKey = 'insight_cards_state';

  /// Insight 리스트 getter
  List<InsightCardModel> get insights => _insights;

  /// 기본 생성자
  InsightCardListViewModel() {
    _loadInsights();
  }

  /// 특정 Insight 데이터로 초기화하는 생성자
  InsightCardListViewModel.withInsights(List<InsightCardModel> insights) {
    _insights.addAll(insights);
  }

  /// 저장된 Insight 상태 불러오기
  Future<void> _loadInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInsights = prefs.getString(_storageKey);

      if (savedInsights != null) {
        final List<dynamic> decodedInsights = jsonDecode(savedInsights);
        _insights.addAll(
          decodedInsights
              .map(
                (insight) =>
                    InsightCardModel.fromMap(insight as Map<String, dynamic>),
              )
              .toList(),
        );
        notifyListeners();
      } else {
        _initializeInsights();
      }
    } catch (e) {
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

  /// 예시 Insight 생성 메서드
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
  void showInsightBottomSheet(BuildContext context) {
    showCommonBottomSheet(context: context, type: ReportCardType.insight);
  }
}
