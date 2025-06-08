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
  }

  String _getRelativeTimeText() {
    try {
      final now = DateTime.now();
      final difference = now.difference(widget.dateTime);
      
      final formatter = DateFormat('HH:mm');
      final timeStr = formatter.format(widget.dateTime);
      
      // 1분 미만
      if (difference.inMinutes < 1) {
        return '방금 전, $timeStr';
      }
      
      // 1시간 미만
      if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전, $timeStr';
      }
      
      // 24시간 미만
      if (difference.inHours < 24) {
        return '${difference.inHours}시간 전, $timeStr';
      }
      
      // 같은 년도
      if (widget.dateTime.year == now.year) {
        final dateFormatter = DateFormat('MM월 dd일 HH:mm');
        return dateFormatter.format(widget.dateTime);
      }
      
      // 다른 년도
      final fullFormatter = DateFormat('yyyy년 MM월 dd일 HH:mm');
      return fullFormatter.format(widget.dateTime);
      
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
