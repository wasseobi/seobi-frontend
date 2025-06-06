import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 종료된 세션의 요약 정보를 표시하는 위젯
class SessionSummary extends StatelessWidget {
  final String sessionId;
  final String? title;
  final String? description;
  final DateTime? startAt;
  final DateTime? finishAt;

  const SessionSummary({
    super.key,
    required this.sessionId,
    this.title,
    this.description,
    this.startAt,
    this.finishAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 세션 제목
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4.0),
          ],

          // 세션 설명
          if (description != null && description!.isNotEmpty) ...[
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
          ],

          // 시간 정보
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14.0,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 4.0),
              Text(
                _buildTimeInfo(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 시간 정보를 생성하는 헬퍼 메서드
  String _buildTimeInfo() {
    if (startAt == null) return '시간 정보 없음';

    final formatter = DateFormat('MM/dd HH:mm');
    final startTime = formatter.format(startAt!);

    if (finishAt == null) return '$startTime 시작';

    final endTime = formatter.format(finishAt!);
    final duration = _formatDuration(finishAt!.difference(startAt!));

    return '$startTime ~ $endTime ($duration)';
  }

  /// 지속 시간을 포맷팅하는 헬퍼 메서드
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }
}