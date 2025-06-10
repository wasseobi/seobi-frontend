import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

enum ProgressDotsType {
  weekly, // 7 dots, each representing a day
  monthly, // 4 dots, each representing a week
}

class ReportCardProgressDots extends StatelessWidget {
  final ProgressDotsType type;
  final int activeDots;
  final double largeDotSize;
  final double smallDotSize;
  final double spacing;
  final bool isLoading;

  const ReportCardProgressDots({
    super.key,
    required this.type,
    required this.activeDots,
    this.largeDotSize = 18.0,
    this.smallDotSize = 10.0,
    this.spacing = 2.0,
    this.isLoading = false,
  });

  int get totalDots => type == ProgressDotsType.weekly ? 7 : 4;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: largeDotSize,
        height: largeDotSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.green100),
          strokeCap: StrokeCap.round,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(totalDots, (index) {
        final isLargeDot = index == 0;
        final isActive = index >= totalDots - activeDots;

        return Padding(
          padding: EdgeInsets.only(right: index < totalDots - 1 ? spacing : 0),
          child: Container(
            width: isLargeDot ? largeDotSize : smallDotSize,
            height: isLargeDot ? largeDotSize : smallDotSize,
            decoration: ShapeDecoration(
              color: isActive ? AppColors.green100 : AppColors.gray40,
              shape: const OvalBorder(),
            ),
          ),
        );
      }),
    );
  }
}
