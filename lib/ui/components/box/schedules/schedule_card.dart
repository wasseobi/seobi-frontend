import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_fonts.dart';
import 'schedule_card_model.dart';
import 'schedule_types.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleCardModel schedule;
  final VoidCallback? onTap;

  const ScheduleCard({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: PretendardStyles.semiBold14.copyWith(
                    color: AppColors.black100,
                  ),
                ),
                Spacer(),
                if (schedule.type == ScheduleType.list) ...[
                  SizedBox(width: AppDimensions.paddingSmall),
                  Icon(
                    Icons.open_in_new,
                    size: AppDimensions.iconSizeSmall,
                    color: AppColors.gray60,
                  ),
                ],
              ],
            ),

            SizedBox(height: AppDimensions.paddingSmall),

            Text(
              schedule.time,
              style: PretendardStyles.medium10.copyWith(
                color: AppColors.gray80,
              ),
            ),

            SizedBox(height: AppDimensions.paddingSmall),

            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: AppDimensions.iconSizeSmall),

                SizedBox(width: AppDimensions.paddingExtraSmall),

                Text(
                  schedule.location.isNotEmpty ? schedule.location : '장소 미정',
                  style: PretendardStyles.medium12.copyWith(
                    color: AppColors.gray100,
                  ),
                ),
              ],
            ),

            if (schedule.type == ScheduleType.list) ...[
              SizedBox(height: AppDimensions.paddingSmall),
              Text(
                schedule.registeredTime,
                style: PretendardStyles.medium10.copyWith(
                  color: AppColors.gray60,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
