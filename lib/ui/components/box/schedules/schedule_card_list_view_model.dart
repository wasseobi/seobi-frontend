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
        DateTime? aStart = _parseDateTime(a.time);
        DateTime? bStart = _parseDateTime(b.time);
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return aStart.compareTo(bStart);
      });
    } else {
      // 등록 순으로 정렬
      _schedules.sort((a, b) {
        DateTime? aReg = _parseDateTime(a.registeredTime);
        DateTime? bReg = _parseDateTime(b.registeredTime);
        if (aReg == null && bReg == null) return 0;
        if (aReg == null) return 1;
        if (bReg == null) return -1;
        return aReg.compareTo(bReg);
      });
    }
    notifyListeners();
    _saveSortingState();
  }

  /// 문자열을 DateTime으로 파싱 (yyyy-MM-dd 또는 yyyy-MM-dd 등록함 등 지원)
  DateTime? _parseDateTime(String str) {
    try {
      final dateStr = str.split(' ')[0];
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// API에서 받아온 Schedule 리스트를 ScheduleCardModel용 Map 리스트로 변환
  static List<Map<String, dynamic>> fromScheduleList(List schedules) {
    return schedules.map((schedule) {
      return {
        'id':
            schedule.id is int
                ? schedule.id
                : schedule.id.hashCode, // id가 String이면 hashCode 사용
        'title': schedule.title,
        'time':
            schedule.startAt is DateTime
                ? _formatDateTime(schedule.startAt)
                : schedule.startAt,
        'location': schedule.location,
        'registeredTime':
            schedule.createdAt is DateTime
                ? _formatRegisteredTime(schedule.createdAt)
                : schedule.createdAt,
        'type': 'list',
      };
    }).toList();
  }

  /// DateTime을 'M월 d일 오전/오후 h시' 포맷 문자열로 변환
  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final month = dateTime.month;
    final day = dateTime.day;
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final isAm = hour < 12;
    final displayHour =
        hour == 0
            ? 12
            : hour > 12
            ? hour - 12
            : hour;
    final ampm = isAm ? '오전' : '오후';
    if (minute == 0) {
      return '${month}월 ${day}일 $ampm ${displayHour}시';
    } else {
      return '${month}월 ${day}일 $ampm ${displayHour}시 ${minute}분';
    }
  }

  /// DateTime을 'yyyy-MM-dd 등록함' 포맷 문자열로 변환
  static String _formatRegisteredTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    // 날짜만 추출해서 'yyyy-MM-dd 등록함' 포맷으로 반환
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} 등록함';
  }
}
