import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

class TitleCard extends StatelessWidget {
  final String section;
  final String sectionKr;
  final int count;

  const TitleCard({
    super.key,
    required this.section,
    required this.sectionKr,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left section with title
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: ShapeDecoration(
            color: AppColors.white80,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.gray100),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section,
                  style: PretendardStyles.bold16.copyWith(
                    color: AppColors.gray100,
                  ),
                ),
                Text(
                  sectionKr,
                  style: PretendardStyles.regular12.copyWith(
                    color: AppColors.gray100,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right section with count
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: ShapeDecoration(
            color: AppColors.gray100,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: PretendardStyles.bold28.copyWith(
                color: AppColors.white100,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
