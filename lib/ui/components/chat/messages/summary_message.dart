import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';

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
    // UTC 시간을 현지 시간으로 변환
    final localStartDate = startDate.toLocal();
    final localEndDate = endDate.toLocal();
    final startDateFormatted = dateFormat.format(localStartDate);
    final endDateFormatted = dateFormat.format(localEndDate);

    return Column(
      children: [
        Card.outlined(
          color: AppColors.white80,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
                      const Icon(
                        Icons.chat_outlined,
                        size: AppDimensions.iconSizeSmall,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Text(
                        title!.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: AppDimensions.paddingMedium),

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
                  ),

                const SizedBox(height: AppDimensions.paddingMedium),

                // 세션 기간 - 맨 아래로 이동
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: AppDimensions.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray40,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSmall,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppDimensions.iconSizeSmall,
                        color: AppColors.gray80,
                      ),

                      const SizedBox(width: AppDimensions.paddingMedium),

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

        const SizedBox(height: AppDimensions.paddingMedium),

        CustomPaint(
          painter: DashedLinePainter(),
          size: const Size(double.infinity, 1),
        ),

        const SizedBox(height: AppDimensions.paddingLarge),
      ],
    );
  }
}
