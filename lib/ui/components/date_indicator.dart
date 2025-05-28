import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

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
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
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
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
