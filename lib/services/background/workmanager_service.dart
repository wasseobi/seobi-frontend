import 'dart:async';
import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 워크매니저 콜백 함수
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    
    try {
      logger.i('백그라운드 작업 실행: $task');
      
      switch (task) {
        case 'log_task':
          await _executeLogTask(inputData, logger);
          break;
        case 'sync_task':
          await _executeSyncTask(inputData, logger);
          break;
        case 'cleanup_task':
          await _executeCleanupTask(inputData, logger);
          break;
        case 'notification_task':
          await _executeNotificationTask(inputData, logger);
          break;
        default:
          logger.w('알 수 없는 작업 타입: $task');
      }
      
      // 작업 완료 시간 기록
      await _updateLastExecution(inputData?['taskId'], logger);
      
      return Future.value(true);
    } catch (e) {
      logger.e('백그라운드 작업 실행 실패: $e');
      return Future.value(false);
    }
  });
}

/// 로그 작업 실행
Future<void> _executeLogTask(Map<String, dynamic>? inputData, Logger logger) async {
  final message = inputData?['message'] ?? '기본 로그 메시지';
  logger.i('예약된 로그: $message');
  print('WORKMANAGER: 백그라운드 작업 실행 - 로그: $message');
}

/// 동기화 작업 실행
Future<void> _executeSyncTask(Map<String, dynamic>? inputData, Logger logger) async {
  // 여기에 실제 동기화 로직 구현
  await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션
  logger.i('데이터 동기화 완료');
  print('WORKMANAGER: 백그라운드 작업 실행 - 데이터 동기화 완료');
}

/// 청소 작업 실행
Future<void> _executeCleanupTask(Map<String, dynamic>? inputData, Logger logger) async {
  // 여기에 실제 청소 로직 구현
  await Future.delayed(const Duration(seconds: 1)); // 시뮬레이션
  logger.i('청소 작업 완료');
  print('WORKMANAGER: 백그라운드 작업 실행 - 청소 작업 완료');
}

/// 알림 작업 실행
Future<void> _executeNotificationTask(Map<String, dynamic>? inputData, Logger logger) async {
  try {
    final title = inputData?['title'] ?? '백그라운드 알림';
    final body = inputData?['body'] ?? '예약된 알림입니다';
    final notificationId = inputData?['notificationId'] ?? 1;
    
    // 플러그인 초기화
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // 알림 표시
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'background_channel',
      'Background Tasks',
      channelDescription: '백그라운드 작업 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
    );
    
    print('WORKMANAGER: 백그라운드 알림 작업 실행 - $title: $body');
    logger.i('백그라운드 알림 작업 실행: $title');
  } catch (e) {
    print('WORKMANAGER: 백그라운드 알림 작업 실패 - $e');
    logger.e('백그라운드 알림 작업 실패: $e');
  }
}

/// 마지막 실행 시간 업데이트
Future<void> _updateLastExecution(String? taskId, Logger logger) async {
  if (taskId == null) return;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('workmanager_tasks');
    
    if (tasksJson != null) {
      final Map<String, dynamic> tasks = jsonDecode(tasksJson);
      if (tasks.containsKey(taskId)) {
        tasks[taskId]['lastExecuted'] = DateTime.now().millisecondsSinceEpoch;
        await prefs.setString('workmanager_tasks', jsonEncode(tasks));
        logger.i('작업 실행 시간 업데이트: $taskId');
      }
    }
  } catch (e) {
    logger.e('작업 실행 시간 업데이트 실패: $e');
  }
}

/// 워크매니저 백그라운드 작업 정보
class WorkManagerTask {
  final String id;
  final String taskType;
  final Map<String, dynamic>? params;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastExecuted;
  final Duration? frequency;
  final Duration? initialDelay;

  WorkManagerTask({
    required this.id,
    required this.taskType,
    this.params,
    DateTime? createdAt,
    this.isActive = true,
    this.lastExecuted,
    this.frequency,
    this.initialDelay,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskType': taskType,
        'params': params,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isActive': isActive,
        'lastExecuted': lastExecuted?.millisecondsSinceEpoch,
        'frequency': frequency?.inMilliseconds,
        'initialDelay': initialDelay?.inMilliseconds,
      };

  factory WorkManagerTask.fromJson(Map<String, dynamic> json) => WorkManagerTask(
        id: json['id'],
        taskType: json['taskType'],
        params: json['params'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        isActive: json['isActive'] ?? true,
        lastExecuted: json['lastExecuted'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastExecuted'])
            : null,
        frequency: json['frequency'] != null
            ? Duration(milliseconds: json['frequency'])
            : null,
        initialDelay: json['initialDelay'] != null
            ? Duration(milliseconds: json['initialDelay'])
            : null,
      );

  WorkManagerTask copyWith({
    String? id,
    String? taskType,
    Map<String, dynamic>? params,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastExecuted,
    Duration? frequency,
    Duration? initialDelay,
  }) =>
      WorkManagerTask(
        id: id ?? this.id,
        taskType: taskType ?? this.taskType,
        params: params ?? this.params,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        lastExecuted: lastExecuted ?? this.lastExecuted,
        frequency: frequency ?? this.frequency,
        initialDelay: initialDelay ?? this.initialDelay,
      );
}

/// 워크매니저를 사용한 진정한 백그라운드 작업 서비스
class WorkManagerService {
  static final WorkManagerService _instance = WorkManagerService._internal();
  factory WorkManagerService() => _instance;
  WorkManagerService._internal();

  final Map<String, WorkManagerTask> _activeTasks = {};
  final Logger _logger = Logger();
  final String _storageKey = 'workmanager_tasks';

  bool _isInitialized = false;

  /// 워크매니저 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 워크매니저 초기화
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // 디버그 모드에서만 true
      );

      // 저장된 작업들 로드
      await _loadStoredTasks();

      _isInitialized = true;
      _logger.i('워크매니저 서비스 초기화 완료');
    } catch (e) {
      _logger.e('워크매니저 서비스 초기화 실패: $e');
      throw Exception('워크매니저 서비스 초기화 실패: $e');
    }
  }

  /// 주기적 백그라운드 작업 예약
  Future<void> schedulePeriodicTask({
    required String id,
    required String taskType,
    required Duration frequency,
    Map<String, dynamic>? params,
    Duration? initialDelay,
  }) async {
    try {
      // 기존 작업이 있다면 취소
      await cancelTask(id);

      // 새 작업 생성
      final task = WorkManagerTask(
        id: id,
        taskType: taskType,
        params: params,
        frequency: frequency,
        initialDelay: initialDelay,
      );

      // 워크매니저에 주기적 작업 등록
      await Workmanager().registerPeriodicTask(
        id,
        taskType,
        frequency: frequency,
        initialDelay: initialDelay ?? Duration.zero,
        inputData: {
          'taskId': id,
          ...?params,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );

      // 작업 저장
      _activeTasks[id] = task;
      await _saveTasksToStorage();

      _logger.i('주기적 백그라운드 작업 예약됨: $id (주기: ${frequency.inMinutes}분)');
    } catch (e) {
      _logger.e('주기적 백그라운드 작업 예약 실패: $e');
      throw Exception('주기적 백그라운드 작업 예약 실패: $e');
    }
  }

  /// 일회성 백그라운드 작업 예약
  Future<void> scheduleOneOffTask({
    required String id,
    required String taskType,
    Map<String, dynamic>? params,
    Duration? initialDelay,
  }) async {
    try {
      // 기존 작업이 있다면 취소
      await cancelTask(id);

      // 새 작업 생성
      final task = WorkManagerTask(
        id: id,
        taskType: taskType,
        params: params,
        initialDelay: initialDelay,
      );

      // 워크매니저에 일회성 작업 등록
      await Workmanager().registerOneOffTask(
        id,
        taskType,
        initialDelay: initialDelay ?? Duration.zero,
        inputData: {
          'taskId': id,
          ...?params,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );

      // 작업 저장
      _activeTasks[id] = task;
      await _saveTasksToStorage();

      _logger.i('일회성 백그라운드 작업 예약됨: $id');
    } catch (e) {
      _logger.e('일회성 백그라운드 작업 예약 실패: $e');
      throw Exception('일회성 백그라운드 작업 예약 실패: $e');
    }
  }

  /// 예약된 백그라운드 작업 조회
  WorkManagerTask? getScheduledTask(String id) {
    return _activeTasks[id];
  }

  /// 모든 예약된 작업 조회
  List<WorkManagerTask> getAllScheduledTasks() {
    return _activeTasks.values.toList();
  }

  /// 활성 상태인 작업들만 조회
  List<WorkManagerTask> getActiveTasks() {
    return _activeTasks.values.where((task) => task.isActive).toList();
  }

  /// 백그라운드 작업 취소
  Future<void> cancelTask(String id) async {
    try {
      // 워크매니저에서 작업 취소
      await Workmanager().cancelByUniqueName(id);

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
      // 워크매니저의 모든 작업 취소
      await Workmanager().cancelAll();

      _activeTasks.clear();

      // 저장소 초기화
      await _saveTasksToStorage();

      _logger.i('모든 백그라운드 작업 취소됨');
    } catch (e) {
      _logger.e('모든 백그라운드 작업 취소 실패: $e');
      throw Exception('모든 백그라운드 작업 취소 실패: $e');
    }
  }

  /// 저장된 작업들 로드
  Future<void> _loadStoredTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_storageKey);

      if (tasksJson != null) {
        final Map<String, dynamic> taskMap = jsonDecode(tasksJson);
        taskMap.forEach((key, value) {
          final task = WorkManagerTask.fromJson(value);
          _activeTasks[task.id] = task;
        });

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
      final taskMap = <String, dynamic>{};
      
      _activeTasks.forEach((key, value) {
        taskMap[key] = value.toJson();
      });
      
      await prefs.setString(_storageKey, jsonEncode(taskMap));
    } catch (e) {
      _logger.e('작업 저장 실패: $e');
    }
  }

  /// 서비스 종료
  Future<void> dispose() async {
    try {
      await Workmanager().cancelAll();
      _activeTasks.clear();
      _isInitialized = false;
      _logger.i('워크매니저 서비스 종료됨');
    } catch (e) {
      _logger.e('워크매니저 서비스 종료 실패: $e');
    }
  }
}
