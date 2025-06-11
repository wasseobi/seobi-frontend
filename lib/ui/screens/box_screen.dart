import 'package:flutter/material.dart';
import '../components/box/box_content.dart';
import '../components/box/schedules/schedule_card_list_view_model.dart';
import '../components/box/tasks/task_card_list_view_model.dart';
import '../../services/auth/auth_service.dart';

class BoxScreen extends StatelessWidget {
  const BoxScreen({super.key});

  Future<Map<String, dynamic>> _loadViewModels() async {
    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) {
      return {
        'taskViewModel': TaskCardListViewModel(),
        'scheduleViewModel': ScheduleCardListViewModel(),
      };
    }

    // TaskCardListViewModel과 ScheduleCardListViewModel을 동시에 로드
    final results = await Future.wait([
      TaskCardListViewModel.fromUserId(userId),
      ScheduleCardListViewModel.fromUserId(userId),
    ]);

    return {'taskViewModel': results[0], 'scheduleViewModel': results[1]};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadViewModels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('데이터 불러오기 실패: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final taskViewModel = data['taskViewModel'] as TaskCardListViewModel;
        final scheduleViewModel =
            data['scheduleViewModel'] as ScheduleCardListViewModel;

        return BoxContent(
          taskViewModel: taskViewModel,
          scheduleViewModel: scheduleViewModel,
        );
      },
    );
  }
}
