import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class ReportCardProgressRing extends StatelessWidget {
  final double size;
  final double progress; // 0.0 to 1.0
  final bool isLoading; // 로딩 상태 추가

  const ReportCardProgressRing({
    super.key,
    this.size = 28.0,
    required this.progress,
    this.isLoading = false, // 기본값은 false (기존 호환성 유지)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: AppColors.white100,
        shape: const OvalBorder(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: size,
            height: size,
            decoration: ShapeDecoration(
              color: AppColors.gray40,
              shape: const OvalBorder(),
            ),
          ),
          // Progress Ring
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(1.5),
            child: CircularProgressIndicator(
              value:
                  isLoading
                      ? null
                      : progress.clamp(0.0, 1.0), // 로딩 중이면 null (무한 애니메이션)
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green100),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}
