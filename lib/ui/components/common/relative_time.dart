import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class RelativeTime extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const RelativeTime({
    super.key,
    required this.dateTime,
    this.style,
  });

  @override
  State<RelativeTime> createState() => _RelativeTimeState();
}

class _RelativeTimeState extends State<RelativeTime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1분마다 갱신
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }  String _getRelativeTimeText() {
    try {
      final now = DateTime.now();
      // UTC 시간을 로컬 시간으로 변환
      final localDateTime = widget.dateTime.toLocal();
      final difference = now.difference(localDateTime);
      
      // 상대 시간 계산 (방금 전, n분 전, n시간 전, n일 전, n년 전)
      String relativeTime;
      if (difference.inMinutes < 1) {
        relativeTime = '방금 전';
      } else if (difference.inHours < 1) {
        relativeTime = '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        relativeTime = '${difference.inHours}시간 전';
      } else if (difference.inDays < 365) {
        relativeTime = '${difference.inDays}일 전';
      } else {
        final years = (difference.inDays / 365).floor();
        relativeTime = '${years}년 전';
      }
      
      // 실제 시간 계산
      String actualTime;
      // 날짜가 같은지 확인
      bool isSameDay = now.year == localDateTime.year && 
                      now.month == localDateTime.month && 
                      now.day == localDateTime.day;
      
      if (isSameDay) {
        // 같은 날짜면 시간만
        actualTime = DateFormat('HH:mm').format(localDateTime);
      } else if (localDateTime.year == now.year) {
        // 날짜는 다르지만 같은 년도면 월일+시간
        actualTime = DateFormat('MM월 dd일 HH:mm').format(localDateTime);
      } else {
        // 년도까지 다르면 연월일+시간
        actualTime = DateFormat('yyyy년 MM월 dd일 HH:mm').format(localDateTime);
      }
      
      // 상대 시간과 실제 시간 조합
      return '$relativeTime, $actualTime';
      
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return widget.dateTime.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_getRelativeTimeText(), style: widget.style);
  }
}
