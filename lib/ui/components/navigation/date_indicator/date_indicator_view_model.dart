import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateIndicatorViewModel extends ChangeNotifier {
  DateTime _currentDate;
  Timer? _timer;

  DateIndicatorViewModel({DateTime? initialDate}) 
    : _currentDate = initialDate ?? DateTime.now() {
    // 매일 자정에 날짜 업데이트를 위한 타이머 설정
    _setupDailyTimer();
  }

  String get formattedDate {
    return DateFormat('MM월 dd일').format(_currentDate);
  }

  String get dayOfWeek {
    // 한국어 요일 반환
    final List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    // DateTime에서 weekday는 1(월요일)부터 7(일요일)까지 반환
    int dayIndex = _currentDate.weekday - 1;
    return '${weekdays[dayIndex]}요일';
  }

  void updateToCurrentDate() {
    _currentDate = DateTime.now();
    notifyListeners();
  }

  // 다음 날 자정에 날짜 업데이트하는 타이머 설정
  void _setupDailyTimer() {
    // 현재 타이머가 있으면 취소
    _timer?.cancel();

    // 다음 날 자정 계산
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // 자정에 업데이트하는 타이머 설정
    _timer = Timer(timeUntilMidnight, () {
      updateToCurrentDate();
      _setupDailyTimer(); // 다음 날을 위해 재설정
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
