import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/dimensions/task_card_dimensions.dart';

class TaskCardProgressBar extends StatelessWidget {
  final bool isActive;
  final double progress;

  const TaskCardProgressBar({
    super.key,
    required this.isActive,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: TaskCardDimensions.progressBarHeight,
      decoration: BoxDecoration(color: AppColors.gray40),
      child: Stack(
        children: [
          // Background track
          Positioned(
            left: TaskCardDimensions.progressBarLeftPadding,
            top: 0,
            child: Container(
              width: TaskCardDimensions.progressBarWidth,
              height: TaskCardDimensions.progressBarHeight,
              decoration: ShapeDecoration(
                color: AppColors.gray60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    TaskCardDimensions.progressBarRadius,
                  ),
                ),
              ),
            ),
          ),
          // Progress track
          Positioned(
            left: TaskCardDimensions.progressBarLeftPadding,
            top: 0,
            child: Container(
              width: TaskCardDimensions.progressBarWidth * progress,
              height: TaskCardDimensions.progressBarHeight,
              decoration: ShapeDecoration(
                color: isActive ? AppColors.main100 : AppColors.gray100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    TaskCardDimensions.progressBarRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
