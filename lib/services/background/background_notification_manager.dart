import 'package:logger/logger.dart';
import '../notification/notification_service.dart';
import 'background_service.dart';

/// 백그라운드 서비스와 알림 서비스를 연동하는 관리자 클래스
class BackgroundNotificationManager {
  static final BackgroundNotificationManager _instance = 
      BackgroundNotificationManager._internal();
  factory BackgroundNotificationManager() => _instance;
  BackgroundNotificationManager._internal();

  final BackgroundService _backgroundService = BackgroundService();
  final NotificationService _notificationService = NotificationService();
  final Logger _logger = Logger();

  bool _isInitialized = false;

  /// 32비트 정수 범위 내의 알림 ID 생성
  int _generateNotificationId() {
    // DateTime의 millisecondsSinceEpoch를 32비트 정수 범위로 변환
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // 2^31 - 1 = 2147483647 (32비트 정수 최대값)
    return (timestamp % 2147483647).toInt();
  }

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 백그라운드 서비스 초기화
      await _backgroundService.initialize();
      
      // 알림 서비스 초기화
      await _notificationService.initialize();

      // 알림 작업 실행자 등록
      _backgroundService.registerTaskExecutor('notification', (task) async {
        try {
          final title = task.params?['title'] ?? '백그라운드 알림';
          final body = task.params?['body'] ?? '예약된 알림입니다';
          final notificationId = task.params?['notificationId'] ?? 1;
          
          print('DEBUG: 백그라운드 알림 작업 실행 시작 - $title: $body');
          _logger.i('백그라운드 알림 작업 실행: $title');
          
          // 실제 알림 표시
          await _notificationService.showNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: 'background_notification_${task.id}',
          );
          
          print('DEBUG: 백그라운드 알림 표시 완료 - ID: $notificationId');
          
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
          _logger.e('백그라운드 알림 작업 실패: $e');
          return TaskExecutionResult(success: false, error: e.toString());
        }
      });

      _isInitialized = true;
      _logger.i('백그라운드 알림 관리자 초기화 완료');
    } catch (e) {
      _logger.e('백그라운드 알림 관리자 초기화 실패: $e');
      throw Exception('백그라운드 알림 관리자 초기화 실패: $e');
    }
  }
  /// 즉시 알림 표시
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    int? notificationId,
  }) async {
    try {
      final id = notificationId ?? _generateNotificationId();
      
      print('DEBUG: 즉시 알림 표시 - $title: $body');
      
      await _notificationService.showNotification(
        id: id,
        title: title,
        body: body,
        payload: 'immediate_notification_$id',
      );
      
      print('DEBUG: 즉시 알림 표시 완료 - ID: $id');
    } catch (e) {
      print('DEBUG: 즉시 알림 표시 실패 - $e');
      _logger.e('즉시 알림 표시 실패: $e');
    }
  }
  /// 예약 알림 (초 단위)
  Future<void> scheduleNotificationAfterSeconds({
    required String title,
    required String body,
    required int seconds,
    int? notificationId,
  }) async {
    try {
      final id = notificationId ?? _generateNotificationId();
      
      print('DEBUG: $seconds초 후 알림 예약 - $title: $body');
      
      await _notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        seconds: seconds,
        payload: 'scheduled_notification_$id',
      );
      
      print('DEBUG: 예약 알림 설정 완료 - ID: $id, ${seconds}초 후 실행');
    } catch (e) {
      print('DEBUG: 예약 알림 설정 실패 - $e');
      _logger.e('예약 알림 설정 실패: $e');
    }
  }
  /// 백그라운드 작업을 통한 반복 알림 예약
  Future<void> scheduleBackgroundNotification({
    required String taskId,
    required String cronExpression,
    required String title,
    required String body,
    int? notificationId,
  }) async {
    try {
      final id = notificationId ?? _generateNotificationId();
      
      print('DEBUG: 백그라운드 반복 알림 예약 - $taskId: $title');
      
      await _backgroundService.scheduleTask(
        id: taskId,
        cronExpression: cronExpression,
        taskType: 'notification',
        params: {
          'title': title,
          'body': body,
          'notificationId': id,
        },
      );
      
      print('DEBUG: 백그라운드 반복 알림 예약 완료 - $taskId');
    } catch (e) {
      print('DEBUG: 백그라운드 반복 알림 예약 실패 - $e');
      _logger.e('백그라운드 반복 알림 예약 실패: $e');
    }
  }

  /// 백그라운드 작업 취소
  Future<void> cancelBackgroundTask(String taskId) async {
    try {
      print('DEBUG: 백그라운드 작업 취소 - $taskId');
      
      await _backgroundService.cancelTask(taskId);
      
      print('DEBUG: 백그라운드 작업 취소 완료 - $taskId');
    } catch (e) {
      print('DEBUG: 백그라운드 작업 취소 실패 - $e');
      _logger.e('백그라운드 작업 취소 실패: $e');
    }
  }

  /// 모든 백그라운드 작업 취소
  Future<void> cancelAllBackgroundTasks() async {
    try {
      print('DEBUG: 모든 백그라운드 작업 취소');
      
      await _backgroundService.cancelAllTasks();
      
      print('DEBUG: 모든 백그라운드 작업 취소 완료');
    } catch (e) {
      print('DEBUG: 모든 백그라운드 작업 취소 실패 - $e');
      _logger.e('모든 백그라운드 작업 취소 실패: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      print('DEBUG: 모든 알림 취소');
      
      await _notificationService.cancelAllNotifications();
      
      print('DEBUG: 모든 알림 취소 완료');
    } catch (e) {
      print('DEBUG: 모든 알림 취소 실패 - $e');
      _logger.e('모든 알림 취소 실패: $e');
    }
  }

  /// 예약된 작업 목록 조회
  List<BackgroundTask> getScheduledTasks() {
    return _backgroundService.getAllScheduledTasks();
  }

  /// 특정 작업 조회
  BackgroundTask? getTask(String taskId) {
    return _backgroundService.getScheduledTask(taskId);
  }
}
