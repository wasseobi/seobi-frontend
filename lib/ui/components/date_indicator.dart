import 'package:flutter/material.dart';

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
                color: Color(0xFF4F4F4F), /* Color-Gray-100 */
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
                color: Color(0xFF4F4F4F), /* Color-Gray-100 */
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
