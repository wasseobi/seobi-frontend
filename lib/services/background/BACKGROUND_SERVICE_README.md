# 백그라운드 서비스 개선 사항

## 개요
앱이 종료된 후에도 예약된 작업이 수행되도록 백그라운드 서비스를 개선했습니다.

## 새로운 기능

### 1. 진정한 백그라운드 실행
- **기존**: 앱 실행 중에만 작업 수행 (`cron` 패키지 사용)
- **개선**: 앱 종료 후에도 작업 수행 (`workmanager` 패키지 추가)

### 2. 두 가지 백그라운드 방식 지원

#### 앱 내 백그라운드 작업 (Cron 기반)
```dart
// 앱이 실행 중일 때만 작동
await backgroundService.scheduleTask(
  id: 'in_app_task',
  cronExpression: '*/1 * * * *', // 매분
  taskType: 'log',
  params: {'message': '앱 내 작업'},
);
```

#### 지속적 백그라운드 작업 (WorkManager 기반)
```dart
// 앱 종료 후에도 작동
await backgroundService.schedulePersistentPeriodicTask(
  id: 'persistent_task',
  taskType: 'sync_task',
  frequency: Duration(minutes: 15), // 15분마다
  params: {'syncType': 'full'},
);
```

### 3. 지원하는 작업 유형
- **로그 작업**: 디버그 로그 출력
- **동기화 작업**: 데이터 백그라운드 동기화
- **청소 작업**: 임시 파일 정리
- **알림 작업**: 예약된 알림 전송

## 사용 방법

### 1. 서비스 초기화
```dart
final backgroundService = BackgroundService();
await backgroundService.initialize();
```

### 2. 주기적 작업 예약
```dart
// 앱 종료 후에도 실행되는 주기적 작업
await backgroundService.schedulePersistentPeriodicTask(
  id: 'daily_sync',
  taskType: 'sync_task',
  frequency: Duration(hours: 24),
  params: {'type': 'daily_backup'},
);
```

### 3. 일회성 작업 예약
```dart
// 앱 종료 후에도 실행되는 일회성 작업
await backgroundService.schedulePersistentOneOffTask(
  id: 'reminder_notification',
  taskType: 'notification_task',
  initialDelay: Duration(hours: 1),
  params: {
    'title': '리마인더',
    'body': '1시간 후 알림',
    'notificationId': 100,
  },
);
```

### 4. 작업 관리
```dart
// 지속적 작업 취소
await backgroundService.cancelPersistentTask('task_id');

// 모든 지속적 작업 취소
await backgroundService.cancelAllPersistentTasks();

// 현재 작업 상태 확인
final tasks = backgroundService.getAllPersistentTasks();
```

## 플랫폼 제한사항

### Android
- WorkManager를 사용하여 백그라운드 작업 수행
- 시스템의 배터리 최적화 설정에 영향을 받을 수 있음
- 최소 실행 간격: 15분 (시스템 제약)

### iOS
- 백그라운드 앱 새로고침이 활성화되어야 함
- 시스템이 백그라운드 실행을 제한할 수 있음
- 앱이 자주 사용될 때 더 잘 작동함

## 테스트 방법

1. 앱에서 백그라운드 서비스 예제 탭으로 이동
2. "지속적 주기 작업 예약" 버튼 클릭
3. 앱을 완전히 종료
4. 15분 후 시스템 로그 확인 또는 알림 확인

## 주의사항

- 백그라운드 작업은 시스템 리소스를 사용하므로 신중하게 사용
- 너무 빈번한 작업은 배터리 소모를 증가시킬 수 있음
- 중요하지 않은 작업은 앱이 활성 상태일 때만 실행하는 것을 권장

## 파일 구조

```
lib/services/background/
├── background_service.dart          # 메인 백그라운드 서비스 (기존 + 새로운 기능)
├── workmanager_service.dart         # WorkManager 기반 백그라운드 서비스
└── background_notification_manager.dart # 기존 알림 관리자

lib/ui/pages/
└── background_service_example.dart  # 백그라운드 서비스 사용 예제 UI
```

## 패키지 의존성

```yaml
dependencies:
  workmanager: ^0.5.2          # 백그라운드 작업 실행
  cron: ^0.6.0                 # 앱 내 스케줄링 (기존)
  flutter_local_notifications: ^19.2.1  # 알림 (기존)
```
