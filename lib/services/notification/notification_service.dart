import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    try {
      // Timezone 초기화
      tz.initializeTimeZones();

      // Android 초기화 설정
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 초기화 설정
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // 전체 초기화 설정
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      // 알림 플러그인 초기화
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android 13+ 권한 요청
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _logger.i('알림 서비스 초기화 완료');
    } catch (e) {
      _logger.e('알림 서비스 초기화 실패: $e');
    }
  }

  /// Android 권한 요청
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// 알림 클릭 처리
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('알림 클릭됨: ${response.payload}');
    // 여기에 알림 클릭 시 수행할 작업 추가
  }

  /// 즉시 알림 표시
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel',
            '기본 알림',
            channelDescription: '일반적인 알림입니다',
            importance: Importance.high,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      _logger.i('알림 표시됨: $title');
    } catch (e) {
      _logger.e('알림 표시 실패: $e');
    }
  }

  /// 예약 알림 (몇 초 후)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_channel',
            '예약 알림',
            channelDescription: '예약된 알림입니다',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _logger.i('예약 알림 설정됨: $title ($seconds초 후)');
    } catch (e) {
      _logger.e('예약 알림 설정 실패: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      _logger.i('모든 알림 취소됨');
    } catch (e) {
      _logger.e('알림 취소 실패: $e');
    }
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      _logger.i('알림 취소됨: ID $id');
    } catch (e) {
      _logger.e('알림 취소 실패: $e');
    }
  }
}
