import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'task_card_model.dart';
import 'package:flutter/foundation.dart';

/// TaskCard 리스트를 관리하는 ViewModel
class TaskCardListViewModel extends ChangeNotifier {
  final List<TaskCardModel> _tasks = [];
  static const String _storageKey = 'task_cards_state';
  bool _isUrgent = false;

  /// Task 리스트 getter
  List<TaskCardModel> get tasks => _tasks;
  bool get isUrgent => _isUrgent;

  /// 기본 생성자
  TaskCardListViewModel() {
    _loadTasks();
  }

  /// 특정 Task 데이터로 초기화하는 생성자
  TaskCardListViewModel.withTasks(List<TaskCardModel> tasks) {
    _tasks.addAll(tasks);
  }

  /// 저장된 Task 상태 불러오기
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTasks = prefs.getString(_storageKey);

      if (savedTasks != null) {
        final List<dynamic> decodedTasks = jsonDecode(savedTasks);
        _tasks.addAll(
          decodedTasks
              .map(
                (task) => TaskCardModel.fromMap(task as Map<String, dynamic>),
              )
              .toList(),
        );
        notifyListeners();
      } else {
        _initializeTasks();
      }
    } catch (e) {
      _initializeTasks();
    }
  }

  /// Task 상태 저장
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedTasks = jsonEncode(
        _tasks.map((task) => task.toMap()).toList(),
      );
      await prefs.setString(_storageKey, encodedTasks);
    } catch (e) {
      debugPrint('Failed to save tasks: $e');
    }
  }

  /// 예시 Task 생성 메서드
  void _initializeTasks() {
    _tasks.addAll([
      TaskCardModel(
        id: '1',
        title: '데이터 백업',
        remainingTime: '2시간 30분 남음',
        schedule: '매일 오후 3시',
        isEnabled: true,
        progress: 0.7,
        actions: [
          {'service': 'Google Drive', 'action': '에 업로드'},
        ],
      ),
      TaskCardModel(
        id: '2',
        title: '시스템 업데이트',
        remainingTime: '1시간 15분 남음',
        schedule: '매주 월요일',
        isEnabled: false,
        progress: 0.3,
        actions: [
          {'service': 'Windows Update', 'action': '실행'},
          {'service': '보안 패치', 'action': '적용'},
        ],
      ),
    ]);
    notifyListeners();
  }

  /// Map 형식의 데이터 리스트로 Task 초기화
  void initWithMapList(List<Map<String, dynamic>> taskList) {
    _tasks.addAll(taskList.map((map) => TaskCardModel.fromMap(map)).toList());
    notifyListeners();
  }

  /// 새 Task 추가
  void addTask(TaskCardModel task) {
    _tasks.add(task);
    notifyListeners();
    _saveTasks();
  }

  /// Map 형식으로 새 Task 추가
  void addTaskFromMap(Map<String, dynamic> taskMap) {
    final task = TaskCardModel.fromMap(taskMap);
    addTask(task);
  }

  /// 특정 Task 업데이트
  void updateTask(String id, TaskCardModel updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      _saveTasks();
    }
  }

  /// Task 활성화 상태 토글
  void toggleTaskStatus(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(isEnabled: !task.isEnabled);
      notifyListeners();
      _saveTasks();
    }
  }

  /// 모든 Task 삭제
  void clearTasks() {
    _tasks.clear();
    notifyListeners();
    _saveTasks();
  }

  /// Task 정렬 (임박순/등록순)
  void sortTasks(bool isUrgent) {
    _isUrgent = isUrgent;
    if (isUrgent) {
      _tasks.sort((a, b) {
        // Sort by remaining time (assuming format: "X시간 Y분 남음")
        final aTime = _parseRemainingTime(a.remainingTime);
        final bTime = _parseRemainingTime(b.remainingTime);
        return aTime.compareTo(bTime);
      });
    } else {
      // Sort by registration time (using ID as proxy)
      _tasks.sort((a, b) => a.id.compareTo(b.id));
    }
    notifyListeners();
  }

  int _parseRemainingTime(String timeStr) {
    // Convert "X시간 Y분 남음" to total minutes
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
