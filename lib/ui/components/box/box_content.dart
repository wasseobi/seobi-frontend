import 'package:flutter/material.dart';
import 'tasks/task_card_list.dart';
import 'schedules/schedule_card_list.dart';

class BoxContent extends StatelessWidget {
  const BoxContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TaskCardList(width: double.infinity),
            SizedBox(height: 32),
            ScheduleCardList(width: double.infinity),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
