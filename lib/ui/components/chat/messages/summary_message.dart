import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 점선을 그리기 위한 CustomPainter 클래스
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// 세션 정보를 요약해서 보여주는 카드 형태의 메시지 컴포넌트
class SummaryMessage extends StatelessWidget {
  /// 세션 제목
  final String? title;

  /// 세션 요약 설명
  final String? description;

  /// 세션 시작 날짜
  final DateTime startDate;

  /// 세션 종료 날짜
  final DateTime endDate;

  const SummaryMessage({
    super.key,
    this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required List<String> content,
  });
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH시 mm분');
    final startDateFormatted = dateFormat.format(startDate);
    final endDateFormatted = dateFormat.format(endDate);

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 세션 제목
                // 제목이 없으면 빈 위젯을 반환
                if (title == null || title!.isEmpty)
                  const SizedBox.shrink()
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        title!.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // 세션 요약(설명)
                // 설명이 없으면 빈 위젯을 반환
                if (description == null || description!.isEmpty)
                  const SizedBox.shrink()
                else
                  Text(
                    description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                  ),

                const SizedBox(height: 12),

                // 세션 기간 - 맨 아래로 이동
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            '대화 시작: $startDateFormatted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '대화 종료: $endDateFormatted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CustomPaint(
            painter: DashedLinePainter(),
            size: const Size(double.infinity, 1),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}
