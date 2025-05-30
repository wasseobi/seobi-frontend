import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../components/card_schedule.dart';
import '../components/button_switch.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.lightBG),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '알림 설정',
                style: PretendardStyles.regular12.copyWith(
                  color: AppColors.textLightPrimary,
                ),
              ),
              CustomToggleSwitch(
                initialValue: true,
                onChanged: (value) {
                  // Handle toggle change
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScheduleCard(title: '팀 미팅', time: '14:00', location: '회의실 A'),
        ],
      ),
    );
  }
}
