import 'dart:async';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cron/cron.dart';
import 'workmanager_service.dart';

/// 백그라운드 작업 정보를 담는 클래스
class BackgroundTask {
  final String id;
  final String cronExpression;
  final String taskType;
  final Map<String, dynamic>? params;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;

  BackgroundTask({
    required this.id,
    required this.cronExpression,
    required this.taskType,
    this.params,
    DateTime? createdAt,
    this.isActive = true,
    this.lastExecuted,
    this.nextExecution,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'cronExpression': cronExpression,
        'taskType': taskType,
        'params': params,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isActive': isActive,
        'lastExecuted': lastExecuted?.millisecondsSinceEpoch,
        'nextExecution': nextExecution?.millisecondsSinceEpoch,
      };

  factory BackgroundTask.fromJson(Map<String, dynamic> json) => BackgroundTask(
        id: json['id'],
        cronExpression: json['cronExpression'],
        taskType: json['taskType'],
        params: json['params'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        isActive: json['isActive'] ?? true,
        lastExecuted: json['lastExecuted'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastExecuted'])
            : null,
        nextExecution: json['nextExecution'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['nextExecution'])
            : null,
      );

  BackgroundTask copyWith({
    String? id,
    String? cronExpression,
    String? taskType,
    Map<String, dynamic>? params,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastExecuted,
    DateTime? nextExecution,
  }) =>
      BackgroundTask(
        id: id ?? this.id,
        cronExpression: cronExpression ?? this.cronExpression,
        taskType: taskType ?? this.taskType,
        params: params ?? this.params,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        lastExecuted: lastExecuted ?? this.lastExecuted,
        nextExecution: nextExecution ?? this.nextExecution,
      );
}

/// 백그라운드 작업 실행 결과
class TaskExecutionResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? result;

  TaskExecutionResult({
    required this.success,
    this.error,
    this.result,
  });
}

/// 백그라운드 작업 실행자 함수 타입
typedef TaskExecutor = Future<TaskExecutionResult> Function(
    BackgroundTask task);

/// Cron 표현식을 사용한 백그라운드 작업 예약 서비스
/// 앱 실행 중에는 Cron을 사용하고, 앱 종료 후에도 작업이 필요한 경우 WorkManager를 사용
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final Cron _cron = Cron();
  final WorkManagerService _workManagerService = WorkManagerService();
  final Map<String, BackgroundTask> _activeTasks = {};
  final Map<String, dynamic> _scheduledTasks = {};
  final Map<String, TaskExecutor> _taskExecutors = {};
  final Logger _logger = Logger();
  final String _storageKey = 'background_tasks';

  bool _isInitialized = false;
  /// 백그라운드 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 저장된 작업들 로드
      await _loadStoredTasks();

      // 워크매니저 서비스 초기화
      await _workManagerService.initialize();

      // 기본 작업 실행자들 등록
      _registerDefaultExecutors();

      _isInitialized = true;
      _logger.i('백그라운드 서비스 초기화 완료');
    } catch (e) {
      _logger.e('백그라운드 서비스 초기화 실패: $e');
      throw Exception('백그라운드 서비스 초기화 실패: $e');
    }
  }

  /// 작업 실행자 등록
  void registerTaskExecutor(String taskType, TaskExecutor executor) {
    _taskExecutors[taskType] = executor;
    _logger.i('작업 실행자 등록됨: $taskType');
  }

  /// 백그라운드 작업 예약
  Future<void> scheduleTask({
    required String id,
    required String cronExpression,
    required String taskType,
    Map<String, dynamic>? params,
  }) async {
    try {
      // 기존 작업이 있다면 취소
      await cancelTask(id);

      // 새 작업 생성
      final task = BackgroundTask(
        id: id,
        cronExpression: cronExpression,
        taskType: taskType,
        params: params,
      );

      // Cron 표현식 유효성 검사
      final cronSchedule = Schedule.parse(cronExpression);

      // 다음 실행 시간 계산
      final nextExecution = _calculateNextExecution(cronExpression);

      // 작업 저장
      final updatedTask = task.copyWith(nextExecution: nextExecution);
      _activeTasks[id] = updatedTask;

      // Cron 스케줄링
      final scheduledTask = _cron.schedule(cronSchedule, () async {
        await _executeTask(id);
      });

      _scheduledTasks[id] = scheduledTask;

      // 저장소에 저장
      await _saveTasksToStorage();

      _logger.i('백그라운드 작업 예약됨: $id (다음 실행: $nextExecution)');
    } catch (e) {
      _logger.e('백그라운드 작업 예약 실패: $e');
      throw Exception('백그라운드 작업 예약 실패: $e');
    }
  }

  /// 예약된 백그라운드 작업 조회
  BackgroundTask? getScheduledTask(String id) {
    return _activeTasks[id];
  }

  /// 모든 예약된 작업 조회
  List<BackgroundTask> getAllScheduledTasks() {
    return _activeTasks.values.toList();
  }

  /// 활성 상태인 작업들만 조회
  List<BackgroundTask> getActiveTasks() {
    return _activeTasks.values.where((task) => task.isActive).toList();
  }

  /// 백그라운드 작업 취소
  Future<void> cancelTask(String id) async {
    try {
      // 스케줄링된 작업 취소
      _scheduledTasks[id]?.cancel();
      _scheduledTasks.remove(id);

      // 활성 작업에서 제거
      _activeTasks.remove(id);

      // 저장소에서 제거
      await _saveTasksToStorage();

      _logger.i('백그라운드 작업 취소됨: $id');
    } catch (e) {
      _logger.e('백그라운드 작업 취소 실패: $e');
      throw Exception('백그라운드 작업 취소 실패: $e');
    }
  }

  /// 모든 백그라운드 작업 취소
  Future<void> cancelAllTasks() async {
    try {
      // 모든 스케줄링된 작업 취소
      for (final scheduledTask in _scheduledTasks.values) {
        scheduledTask.cancel();
      }

      _scheduledTasks.clear();
      _activeTasks.clear();

      // 저장소 초기화
      await _saveTasksToStorage();

      _logger.i('모든 백그라운드 작업 취소됨');
    } catch (e) {
      _logger.e('모든 백그라운드 작업 취소 실패: $e');
      throw Exception('모든 백그라운드 작업 취소 실패: $e');
    }
  }

  /// 진정한 백그라운드 실행을 위한 주기적 작업 예약 (앱 종료 후에도 실행)
  Future<void> schedulePersistentPeriodicTask({
    required String id,
    required String taskType,
    required Duration frequency,
    Map<String, dynamic>? params,
    Duration? initialDelay,
  }) async {
    try {
      await _workManagerService.schedulePeriodicTask(
        id: id,
        taskType: taskType,
        frequency: frequency,
        params: params,
        initialDelay: initialDelay,
      );
      
      _logger.i('지속적 주기 작업 예약됨: $id (주기: ${frequency.inMinutes}분)');
    } catch (e) {
      _logger.e('지속적 주기 작업 예약 실패: $e');
      throw Exception('지속적 주기 작업 예약 실패: $e');
    }
  }

  /// 진정한 백그라운드 실행을 위한 일회성 작업 예약 (앱 종료 후에도 실행)
  Future<void> schedulePersistentOneOffTask({
    required String id,
    required String taskType,
    Map<String, dynamic>? params,
    Duration? initialDelay,
  }) async {
    try {
      await _workManagerService.scheduleOneOffTask(
        id: id,
        taskType: taskType,
        params: params,
        initialDelay: initialDelay,
      );
      
      _logger.i('지속적 일회성 작업 예약됨: $id');
    } catch (e) {
      _logger.e('지속적 일회성 작업 예약 실패: $e');
      throw Exception('지속적 일회성 작업 예약 실패: $e');
    }
  }

  /// 지속적 백그라운드 작업 취소
  Future<void> cancelPersistentTask(String id) async {
    try {
      await _workManagerService.cancelTask(id);
      _logger.i('지속적 백그라운드 작업 취소됨: $id');
    } catch (e) {
      _logger.e('지속적 백그라운드 작업 취소 실패: $e');
      throw Exception('지속적 백그라운드 작업 취소 실패: $e');
    }
  }

  /// 모든 지속적 백그라운드 작업 취소
  Future<void> cancelAllPersistentTasks() async {
    try {
      await _workManagerService.cancelAllTasks();
      _logger.i('모든 지속적 백그라운드 작업 취소됨');
    } catch (e) {
      _logger.e('모든 지속적 백그라운드 작업 취소 실패: $e');
      throw Exception('모든 지속적 백그라운드 작업 취소 실패: $e');
    }
  }

  /// 지속적 백그라운드 작업 조회
  List<WorkManagerTask> getAllPersistentTasks() {
    return _workManagerService.getAllScheduledTasks();
  }

  /// 활성 지속적 백그라운드 작업 조회
  List<WorkManagerTask> getActivePersistentTasks() {
    return _workManagerService.getActiveTasks();
  }

  /// 작업 실행
  Future<void> _executeTask(String id) async {
    final task = _activeTasks[id];
    if (task == null || !task.isActive) {
      _logger.w('실행할 작업을 찾을 수 없거나 비활성 상태: $id');
      return;
    }

    final executor = _taskExecutors[task.taskType];
    if (executor == null) {
      _logger.e('작업 실행자를 찾을 수 없음: ${task.taskType}');
      return;
    }

    try {
      _logger.i('백그라운드 작업 실행 시작: $id');

      // 작업 실행
      final result = await executor(task);

      // 실행 결과 로깅
      if (result.success) {
        _logger.i('백그라운드 작업 실행 성공: $id');
      } else {
        _logger.e('백그라운드 작업 실행 실패: $id - ${result.error}');
      }

      // 마지막 실행 시간 업데이트
      final now = DateTime.now();
      final nextExecution = _calculateNextExecution(task.cronExpression);

      final updatedTask = task.copyWith(
        lastExecuted: now,
        nextExecution: nextExecution,
      );

      _activeTasks[id] = updatedTask;

      // 저장소에 저장
      await _saveTasksToStorage();

      // 재예약 로직 (이미 cron에 의해 자동으로 처리됨)
      _logger.i('다음 실행 예정: $id - $nextExecution');
    } catch (e) {
      _logger.e('백그라운드 작업 실행 중 오류: $id - $e');
    }
  }  /// 다음 실행 시간 계산
  DateTime? _calculateNextExecution(String cronExpression) {
    try {
      // 간단한 다음 실행 시간 계산 (cron 패키지에서 직접적인 next 메서드가 없으므로)
      final now = DateTime.now();
      // 다음 분 단위로 계산
      return now.add(const Duration(minutes: 1));
    } catch (e) {
      _logger.e('다음 실행 시간 계산 실패: $e');
      return null;
    }
  }

  /// 저장된 작업들 로드
  Future<void> _loadStoredTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_storageKey);

      if (tasksJson != null) {
        final List<dynamic> tasksList = jsonDecode(tasksJson);
        for (final taskJson in tasksList) {
          final task = BackgroundTask.fromJson(taskJson);
          _activeTasks[task.id] = task;

          // 활성 작업이라면 다시 스케줄링
          if (task.isActive) {
            try {
              final cronSchedule = Schedule.parse(task.cronExpression);
              final scheduledTask = _cron.schedule(cronSchedule, () async {
                await _executeTask(task.id);
              });
              _scheduledTasks[task.id] = scheduledTask;
            } catch (e) {
              _logger.e('작업 재스케줄링 실패: ${task.id} - $e');
            }
          }
        }

        _logger.i('저장된 작업 ${_activeTasks.length}개 로드됨');
      }
    } catch (e) {
      _logger.e('저장된 작업 로드 실패: $e');
    }
  }

  /// 작업들을 저장소에 저장
  Future<void> _saveTasksToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksList = _activeTasks.values.map((task) => task.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(tasksList));
    } catch (e) {
      _logger.e('작업 저장 실패: $e');
    }
  }
  /// 기본 작업 실행자들 등록
  void _registerDefaultExecutors() {
    // 예시: 로그 출력 작업
    registerTaskExecutor('log', (task) async {
      final message = task.params?['message'] ?? '기본 로그 메시지';
      _logger.i('예약된 로그: $message');
      print('DEBUG: 백그라운드 작업 실행 - 로그: $message');
      return TaskExecutionResult(success: true);
    });

    // 예시: 데이터 동기화 작업
    registerTaskExecutor('sync', (task) async {
      try {
        // 여기에 실제 동기화 로직 구현
        await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션
        _logger.i('데이터 동기화 완료');
        print('DEBUG: 백그라운드 작업 실행 - 데이터 동기화 완료');
        return TaskExecutionResult(success: true);
      } catch (e) {
        return TaskExecutionResult(success: false, error: e.toString());
      }
    });

    // 예시: 청소 작업
    registerTaskExecutor('cleanup', (task) async {
      try {
        // 여기에 실제 청소 로직 구현
        await Future.delayed(const Duration(seconds: 1)); // 시뮬레이션
        _logger.i('청소 작업 완료');
        print('DEBUG: 백그라운드 작업 실행 - 청소 작업 완료');
        return TaskExecutionResult(success: true);
      } catch (e) {
        return TaskExecutionResult(success: false, error: e.toString());
      }
    });

    // 알림 작업 실행자 추가
    registerTaskExecutor('notification', (task) async {
      try {
        final title = task.params?['title'] ?? '백그라운드 알림';
        final body = task.params?['body'] ?? '예약된 알림입니다';
        final notificationId = task.params?['notificationId'] ?? 1;
        
        print('DEBUG: 백그라운드 알림 작업 실행 - $title: $body');
        _logger.i('백그라운드 알림 작업 실행: $title');
        
        // NotificationService 인스턴스를 가져와서 알림 표시
        // 여기서는 간단하게 시뮬레이션만 하고, 실제 알림은 호출하는 곳에서 처리
        return TaskExecutionResult(
          success: true,
          result: {
            'title': title,
            'body': body,
            'notificationId': notificationId,
          },
        );
      } catch (e) {
        print('DEBUG: 백그라운드 알림 작업 실패 - $e');
        return TaskExecutionResult(success: false, error: e.toString());
      }
    });
  }
  /// 서비스 종료
  Future<void> dispose() async {
    try {
      _cron.close();
      _scheduledTasks.clear();
      _activeTasks.clear();
      await _workManagerService.dispose();
      _isInitialized = false;
      _logger.i('백그라운드 서비스 종료됨');
    } catch (e) {
      _logger.e('백그라운드 서비스 종료 실패: $e');
    }
  }
}