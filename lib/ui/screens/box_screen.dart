import 'package:flutter/material.dart';
import '../components/box/box_content.dart';
import '../components/box/schedules/schedule_card_list_view_model.dart';

class BoxScreen extends StatelessWidget {
  final ScheduleCardListViewModel? scheduleViewModel;
  const BoxScreen({super.key, this.scheduleViewModel});

  @override
  Widget build(BuildContext context) {
    return BoxContent(scheduleViewModel: scheduleViewModel);
  }
}
