import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

class ReportCardProgressRing extends StatelessWidget {
  final double size;
  final double progress; // 0.0 to 1.0

  const ReportCardProgressRing({
    super.key,
    this.size = 28.0,
    required this.progress,
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
              value: progress.clamp(0.0, 1.0),
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
