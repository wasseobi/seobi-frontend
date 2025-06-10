import 'package:flutter/material.dart';
import '../../../../repositories/backend/models/auto_task.dart';
import '../../../../services/autotask/auto_task_service.dart';
import 'task_card_model.dart';

/// TaskCard 리스트를 관리하는 ViewModel (AutoTask 기반)
class TaskCardListViewModel extends ChangeNotifier {
  final List<TaskCardModel> _tasks = [];
  bool _isUrgent = false;

  List<TaskCardModel> get tasks => _tasks;
  bool get isUrgent => _isUrgent;

  /// 기본 생성자 (API 연동 X, 수동 초기화용)
  TaskCardListViewModel();

  /// AutoTask 리스트로 초기화하는 생성자
  TaskCardListViewModel.withAutoTasks(List<AutoTask> autoTasks) {
    // 서비스 계층에서 가공된 데이터를 받아 TaskCardModel로 변환
    _tasks.addAll(autoTasks.map((e) => AutoTaskService.toTaskCardModel(e)));
  }

  /// 비동기로 AutoTask 불러와서 초기화
  static Future<TaskCardListViewModel> fromUserId(String userId) async {
    final service = AutoTaskService();
    final activeTasks = await service.fetchActiveTasks(userId);
    final inactiveTasks = await service.fetchInactiveTasks(userId);
    final allTasks = [...activeTasks, ...inactiveTasks];
    return TaskCardListViewModel.withAutoTasks(allTasks);
  }

  /// Task 활성화 상태 토글 (API 연동)
  Future<void> toggleTaskStatus(String id, bool active) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final service = AutoTaskService();
      await service.updateActiveStatus(id, active);
      _tasks[index] = _tasks[index].copyWith(isEnabled: active);
      notifyListeners();
    }
  }

  /// Task 정렬 (임박순/등록순)
  void sortTasks(bool isUrgent) {
    _isUrgent = isUrgent;
    if (isUrgent) {
      _tasks.sort((a, b) {
        final aTime = _parseRemainingTime(a.remainingTime);
        final bTime = _parseRemainingTime(b.remainingTime);
        return aTime.compareTo(bTime);
      });
    } else {
      _tasks.sort((a, b) => a.id.compareTo(b.id));
    }
    notifyListeners();
  }

  int _parseRemainingTime(String timeStr) {
    final hours = int.tryParse(timeStr.split('시간')[0]) ?? 0;
    final minutes = int.tryParse(timeStr.split('시간')[1].split('분')[0]) ?? 0;
    return hours * 60 + minutes;
  }

  void updateTaskProgress(String taskId, double progress) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(progress: progress.clamp(0.0, 1.0));
      notifyListeners();
    }
  }

  void updateRemainingTime(String taskId, String remainingTime) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(remainingTime: remainingTime);
      notifyListeners();
    }
  }
}
