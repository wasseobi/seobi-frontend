import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/dimensions/schedule_card_dimensions.dart';
import '../../constants/app_fonts.dart';
import '../box/schedules/schedule_card_model.dart';
import '../box/schedules/schedule_types.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleCardModel schedule;
  final VoidCallback? onTap;

  const ScheduleCard({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white100,
        borderRadius: BorderRadius.circular(ScheduleCardDimensions.radius),
        border: Border.all(
          color: AppColors.gray40,
          width: ScheduleCardDimensions.borderWidth,
        ),
      ),
      padding: EdgeInsets.only(
        top: ScheduleCardDimensions.paddingTop,
        left: ScheduleCardDimensions.paddingLeft,
        right: ScheduleCardDimensions.paddingRight,
        bottom: ScheduleCardDimensions.paddingBottom,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: PretendardStyles.semiBold16.copyWith(
                          color: AppColors.black100,
                        ),
                      ),
                      SizedBox(height: ScheduleCardDimensions.spacingSmall),
                      Text(
                        schedule.time,
                        style: PretendardStyles.medium12.copyWith(
                          color: AppColors.gray80,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScheduleCardDimensions.spacingLarge),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: ScheduleCardDimensions.iconSize,
                        color: AppColors.gray60,
                      ),
                      SizedBox(width: ScheduleCardDimensions.spacingMedium),
                      Text(
                        schedule.location,
                        style: PretendardStyles.medium12.copyWith(
                          color: AppColors.gray100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ScheduleCardDimensions.spacingMedium),
              if (schedule.type == ScheduleType.list)
                Text(
                  _formatRegisteredTime(schedule.registeredTime),
                  textAlign: TextAlign.center,
                  style: PretendardStyles.medium10.copyWith(
                    color: AppColors.gray60,
                  ),
                ),
            ],
          ),
          if (schedule.type == ScheduleType.list)
            Container(
              width: ScheduleCardDimensions.iconContainerSize,
              height: ScheduleCardDimensions.iconContainerSize,
              child: Icon(
                Icons.open_in_new,
                size: ScheduleCardDimensions.iconSize,
                color: AppColors.gray60,
              ),
            ),
        ],
      ),
    );
  }

  String _formatRegisteredTime(String registeredTime) {
    // ISO 8601 문자열(2025-06-08T20:00:48.904Z 등)에서 연-월-일 시:분만 추출
    try {
      final dt = DateTime.parse(registeredTime);
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    } catch (_) {
      // 파싱 실패 시 앞 16글자만 자름 (2025-06-08 20:00)
      return registeredTime.length >= 16
          ? registeredTime.substring(0, 16)
          : registeredTime;
    }
  }
}
