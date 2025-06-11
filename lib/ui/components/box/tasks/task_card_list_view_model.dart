import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../repositories/backend/models/auto_task.dart';
import '../../../../services/autotask/auto_task_service.dart';
import '../../../../services/auth/auth_service.dart';
import 'task_card_model.dart';

/// TaskCard 리스트를 관리하는 ViewModel (AutoTask 기반)
class TaskCardListViewModel extends ChangeNotifier {
  final List<TaskCardModel> _tasks = [];
  bool _isUrgent = false;
  Timer? _refreshTimer;
  String? _userId;
  final AuthService _authService = AuthService();

  List<TaskCardModel> get tasks => _tasks;
  bool get isUrgent => _isUrgent;

  /// 기본 생성자 (API 연동 X, 수동 초기화용)
  TaskCardListViewModel();

  /// AutoTask 리스트로 초기화하는 생성자
  TaskCardListViewModel.withAutoTasks(List<AutoTask> autoTasks) {
    // 서비스 계층에서 가공된 데이터를 받아 TaskCardModel로 변환
    _tasks.addAll(autoTasks.map((e) => AutoTaskService.toTaskCardModel(e)));
  }

  /// 비동기로 AutoTask 불러와서 초기화 + 자동 refresh 시작
  static Future<TaskCardListViewModel> fromUserId(String userId) async {
    final service = AutoTaskService();
    final activeTasks = await service.fetchActiveTasks(userId);
    final inactiveTasks = await service.fetchInactiveTasks(userId);
    final allTasks = [...activeTasks, ...inactiveTasks];
    final viewModel = TaskCardListViewModel.withAutoTasks(allTasks);
    viewModel._userId = userId;
    viewModel.startAutoRefresh(); // 자동 refresh 시작
    return viewModel;
  }

  /// 30초마다 자동 refresh 시작
  void startAutoRefresh() {
    _refreshTimer?.cancel(); // 기존 타이머가 있다면 취소
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshTasks();
    });
  }

  /// 자동 refresh 중지
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Task 목록 새로고침
  Future<void> refreshTasks() async {
    if (_userId == null) return;

    try {
      final service = AutoTaskService();
      final token = await _authService.accessToken;
      final activeTasks = await service.fetchActiveTasks(
        _userId!,
        accessToken: token,
      );
      final inactiveTasks = await service.fetchInactiveTasks(
        _userId!,
        accessToken: token,
      );
      final allTasks = [...activeTasks, ...inactiveTasks];

      _tasks.clear();
      _tasks.addAll(allTasks.map((e) => AutoTaskService.toTaskCardModel(e)));

      // 현재 정렬 상태 유지
      if (_isUrgent) {
        sortTasks(true);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AutoTask refresh 오류: $e');
    }
  }

  /// Task 활성화 상태 토글 (API 연동)
  Future<void> toggleTaskStatus(String id, bool active) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final service = AutoTaskService();
      final token = await _authService.accessToken;
      await service.updateActiveStatus(id, active, accessToken: token);
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

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Timer 정리
    super.dispose();
  }
}
