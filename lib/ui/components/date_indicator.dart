import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class DateIndicator extends StatelessWidget {
  final String date;
  final String dayOfWeek;

  const DateIndicator({super.key, required this.date, required this.dayOfWeek});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              date,
              textAlign: TextAlign.right,
              style: PretendardStyles.bold12.copyWith(
                color: AppColors.textLight,
                letterSpacing: -0.06,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 78,
            child: Text(
              dayOfWeek,
              textAlign: TextAlign.right,
              style: PretendardStyles.regular12.copyWith(
                color: AppColors.textLight,
                letterSpacing: -0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
