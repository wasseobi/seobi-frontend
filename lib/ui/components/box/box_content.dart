import 'package:flutter/material.dart';
import 'tasks/task_card_list.dart';
import 'tasks/task_card_list_view_model.dart';
import 'schedules/schedule_card_list.dart';
import 'schedules/schedule_card_list_view_model.dart';

class BoxContent extends StatefulWidget {
  final TaskCardListViewModel? taskViewModel;
  final ScheduleCardListViewModel? scheduleViewModel;
  const BoxContent({super.key, this.taskViewModel, this.scheduleViewModel});

  @override
  State<BoxContent> createState() => _BoxContentState();
}

class _BoxContentState extends State<BoxContent>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TaskCardList(
              width: double.infinity,
              viewModel: widget.taskViewModel,
            ),
            SizedBox(height: 32),
            ScheduleCardList(
              width: double.infinity,
              viewModel: widget.scheduleViewModel,
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
