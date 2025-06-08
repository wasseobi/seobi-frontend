import 'package:flutter/material.dart';
import 'tasks/task_card_list.dart';
import 'schedules/schedule_card_list.dart';
import 'schedules/schedule_card_list_view_model.dart';

class BoxContent extends StatelessWidget {
  final ScheduleCardListViewModel? scheduleViewModel;
  const BoxContent({super.key, this.scheduleViewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TaskCardList(width: double.infinity),
            SizedBox(height: 32),
            ScheduleCardList(
              width: double.infinity,
              viewModel: scheduleViewModel,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
