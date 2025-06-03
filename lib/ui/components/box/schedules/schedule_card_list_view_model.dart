import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'schedule_card_model.dart';

/// ScheduleCard 리스트를 관리하는 ViewModel
class ScheduleCardListViewModel extends ChangeNotifier {
  List<ScheduleCardModel> _schedules = [];
  bool _isUrgentFirst = false;
  static const String _storageKey = 'schedule_cards_state';
  static const String _sortingKey = 'schedule_sorting_state';

  /// Schedule 리스트 getter
  List<ScheduleCardModel> get schedules => _schedules;

  /// 현재 정렬 상태 getter
  bool get isUrgentFirst => _isUrgentFirst;

  /// 기본 생성자
  ScheduleCardListViewModel() {
    _loadSchedules();
    _loadSortingState();
  }

  /// 특정 Schedule 데이터로 초기화하는 생성자
  ScheduleCardListViewModel.withSchedules(List<ScheduleCardModel> schedules) {
    _schedules = schedules;
  }

  /// 저장된 Schedule 상태 불러오기
  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSchedules = prefs.getString(_storageKey);

      if (savedSchedules != null) {
        final List<dynamic> decodedSchedules = jsonDecode(savedSchedules);
        _schedules =
            decodedSchedules
                .map(
                  (schedule) => ScheduleCardModel.fromMap(
                    schedule as Map<String, dynamic>,
                  ),
                )
                .toList();
        notifyListeners();
      } else {
        _generateSampleSchedules();
      }
    } catch (e) {
      _generateSampleSchedules();
    }
  }

  /// 정렬 상태 불러오기
  Future<void> _loadSortingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isUrgentFirst = prefs.getBool(_sortingKey) ?? false;
      notifyListeners();
    } catch (e) {
      _isUrgentFirst = false;
    }
  }

  /// 정렬 상태 저장
  Future<void> _saveSortingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sortingKey, _isUrgentFirst);
    } catch (e) {
      debugPrint('Failed to save sorting state: $e');
    }
  }

  /// Schedule 상태 저장
  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedSchedules = jsonEncode(
        _schedules.map((schedule) => schedule.toMap()).toList(),
      );
      await prefs.setString(_storageKey, encodedSchedules);
    } catch (e) {
      debugPrint('Failed to save schedules: $e');
    }
  }

  /// 예시 Schedule 생성 메서드
  void _generateSampleSchedules() {
    _schedules = [
      ScheduleCardModel(
        id: 1,
        title: '팀 미팅',
        time: '14:00',
        location: '회의실 A',
        registeredTime: '2024-03-20 10:00',
      ),
      ScheduleCardModel(
        id: 2,
        title: '프로젝트 리뷰',
        time: '16:00',
        location: '온라인',
        registeredTime: '2024-03-20 11:30',
      ),
    ];
    notifyListeners();
  }

  /// Map 형식의 데이터 리스트로 Schedule 초기화
  void initWithMapList(List<Map<String, dynamic>> scheduleList) {
    _schedules =
        scheduleList.map((map) => ScheduleCardModel.fromMap(map)).toList();
    notifyListeners();
  }

  /// 새 Schedule 추가
  void addSchedule(ScheduleCardModel schedule) {
    _schedules.add(schedule);
    notifyListeners();
    _saveSchedules();
  }

  /// Map 형식으로 새 Schedule 추가
  void addScheduleFromMap(Map<String, dynamic> scheduleMap) {
    final schedule = ScheduleCardModel.fromMap(scheduleMap);
    addSchedule(schedule);
  }

  /// 특정 Schedule 업데이트
  void updateSchedule(int id, ScheduleCardModel updatedSchedule) {
    final index = _schedules.indexWhere((schedule) => schedule.id == id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
      notifyListeners();
      _saveSchedules();
    }
  }

  /// 모든 Schedule 삭제
  void clearSchedules() {
    _schedules.clear();
    notifyListeners();
    _saveSchedules();
  }

  /// Schedule 정렬 (시간순/등록순)
  void sortSchedules(bool isUrgentFirst) {
    _isUrgentFirst = isUrgentFirst;
    if (isUrgentFirst) {
      // 시간 순으로 정렬 (임박순)
      _schedules.sort((a, b) {
        // Convert time strings to DateTime for proper comparison
        final timeA = _parseTimeString(a.time);
        final timeB = _parseTimeString(b.time);
        return timeA.compareTo(timeB);
      });
    } else {
      // 등록 순으로 정렬
      _schedules.sort((a, b) {
        // Convert registeredTime strings to DateTime for proper comparison
        final timeA = DateTime.parse(a.registeredTime);
        final timeB = DateTime.parse(b.registeredTime);
        return timeB.compareTo(timeA); // Most recent first
      });
    }
    notifyListeners();
    _saveSortingState();
  }

  /// Helper method to parse time string to DateTime
  DateTime _parseTimeString(String timeStr) {
    final now = DateTime.now();
    final timeParts = timeStr.split(':');
    if (timeParts.length != 2) return now;

    try {
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return now;
    }
  }
}
