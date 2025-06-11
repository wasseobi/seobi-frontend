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
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: AppColors.gray60,
      valueColor: AlwaysStoppedAnimation<Color>(
        isActive ? AppColors.main100 : AppColors.gray100,
      ),
      borderRadius: BorderRadius.circular(TaskCardDimensions.progressBarRadius),
    );
  }
}
