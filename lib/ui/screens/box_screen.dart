import 'package:flutter/material.dart';
import '../components/box/box_content.dart';
import '../components/box/schedules/schedule_card_list_view_model.dart';
import '../components/box/tasks/task_card_list_view_model.dart';
import '../../services/auth/auth_service.dart';

class BoxScreen extends StatefulWidget {
  const BoxScreen({super.key});

  @override
  State<BoxScreen> createState() => _BoxScreenState();
}

class _BoxScreenState extends State<BoxScreen> {
  late TaskCardListViewModel _taskViewModel;
  late ScheduleCardListViewModel _scheduleViewModel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeViewModels();
  }

  Future<void> _initializeViewModels() async {
    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) {
      _taskViewModel = TaskCardListViewModel();
      _scheduleViewModel = ScheduleCardListViewModel();
    } else {
      final results = await Future.wait([
        TaskCardListViewModel.fromUserId(userId),
        ScheduleCardListViewModel.fromUserId(userId),
      ]);
      _taskViewModel = results[0] as TaskCardListViewModel;
      _scheduleViewModel = results[1] as ScheduleCardListViewModel;
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return BoxContent(
      taskViewModel: _taskViewModel,
      scheduleViewModel: _scheduleViewModel,
    );
  }
}
