import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/dimensions/message_dimensions.dart';
import '../constants/app_fonts.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white100,
        borderRadius: BorderRadius.circular(MessageDimensions.radius),
        border: Border.all(color: AppColors.gray40),
      ),
      padding: EdgeInsets.all(MessageDimensions.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: PretendardStyles.semiBold16.copyWith(
                  color: AppColors.black100,
                ),
              ),
              Text(
                time,
                style: PretendardStyles.regular12.copyWith(
                  color: AppColors.gray80,
                ),
              ),
            ],
          ),
          SizedBox(height: MessageDimensions.spacing * 1.5),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: MessageDimensions.iconSize,
                color: AppColors.gray60,
              ),
              SizedBox(width: MessageDimensions.spacing),
              Text(
                location,
                style: PretendardStyles.regular12.copyWith(
                  color: AppColors.gray100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
