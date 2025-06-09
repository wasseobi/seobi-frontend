import 'package:flutter/material.dart';
import '../components/box/box_content.dart';
import '../components/box/schedules/schedule_card_list_view_model.dart';
import '../components/box/tasks/task_card_list_view_model.dart';
import '../../services/auth/auth_service.dart';

class BoxScreen extends StatelessWidget {
  final ScheduleCardListViewModel? scheduleViewModel;
  const BoxScreen({super.key, this.scheduleViewModel});

  Future<TaskCardListViewModel> _loadTaskViewModel() async {
    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) {
      return TaskCardListViewModel();
    }
    return await TaskCardListViewModel.fromUserId(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskCardListViewModel>(
      future: _loadTaskViewModel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('자동업무 불러오기 실패: \\${snapshot.error}'));
        }
        final taskViewModel = snapshot.data;
        return BoxContent(
          taskViewModel: taskViewModel,
          scheduleViewModel: scheduleViewModel,
        );
      },
    );
  }
}
