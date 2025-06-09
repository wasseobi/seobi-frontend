import '../../../../services/models/auto_task.dart';

/// Task 데이터 모델 (AutoTask 기반)
class TaskCardModel {
  final String id;
  final String title;
  final String remainingTime;
  final String schedule;
  final bool isEnabled;
  final List<Map<String, String>> actions;
  final double progress;

  const TaskCardModel({
    required this.id,
    required this.title,
    required this.remainingTime,
    required this.schedule,
    required this.isEnabled,
    required this.actions,
    this.progress = 0.0,
  });

  /// AutoTask 객체에서 TaskCardModel로 변환
  factory TaskCardModel.fromAutoTask(AutoTask autoTask) {
    // 남은 시간(meta.remaining_time) 파싱
    String remaining = autoTask.meta?['remaining_time']?.toString() ?? '-';
    // 반복/스케줄 정보
    String schedule = autoTask.repeat ?? '';
    // 활성화 상태
    bool isEnabled = autoTask.active;
    // 액션 리스트 (task_list)
    List<Map<String, String>> actions = [];
    if (autoTask.taskList is List) {
      actions =
          (autoTask.taskList as List)
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v.toString())))
              .toList();
    }
    // 진행률(progress) 계산: 남은 시간 기반(예시)
    double progress = _calcProgress(remaining);
    return TaskCardModel(
      id: autoTask.id,
      title: autoTask.title,
      remainingTime: _formatRemainingTime(remaining),
      schedule: schedule,
      isEnabled: isEnabled,
      actions: actions,
      progress: progress,
    );
  }

  static double _calcProgress(String remaining) {
    // 예시: 1:00:00 -> 0.5, 0:00:00 -> 1.0 (완료)
    if (remaining == '-' || remaining.isEmpty) return 0.0;
    final parts = remaining.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      final total = h * 3600 + m * 60 + s;
      // 예시: 2시간(7200초) 기준, 남은 시간/7200으로 progress 계산
      const maxSeconds = 7200.0;
      return 1.0 - (total / maxSeconds).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  static String _formatRemainingTime(String raw) {
    if (raw == '-' || raw.isEmpty) return '-';
    final parts = raw.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return '${h}시간 ${m}분 ${s}초 남음';
    }
    return raw;
  }

  /// Map에서 TaskCardModel 객체로 변환하는 팩토리 메소드
  factory TaskCardModel.fromMap(Map<String, dynamic> map) {
    // Convert actions list safely
    List<Map<String, String>> actionsList = [];
    if (map['actions'] != null) {
      actionsList =
          (map['actions'] as List).map((action) {
            if (action is Map) {
              return Map<String, String>.from(
                action.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              );
            }
            return <String, String>{};
          }).toList();
    }

    return TaskCardModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      remainingTime: map['remainingTime']?.toString() ?? '',
      schedule: map['schedule']?.toString() ?? '',
      isEnabled: map['isEnabled'] as bool? ?? false,
      actions: actionsList,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// TaskCardModel을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'remainingTime': remainingTime,
      'schedule': schedule,
      'isEnabled': isEnabled,
      'actions': actions,
      'progress': progress,
    };
  }

  /// TaskCardModel 복사본 생성 (상태 변경용)
  TaskCardModel copyWith({
    String? id,
    String? title,
    String? remainingTime,
    String? schedule,
    bool? isEnabled,
    List<Map<String, String>>? actions,
    double? progress,
  }) {
    return TaskCardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      remainingTime: remainingTime ?? this.remainingTime,
      schedule: schedule ?? this.schedule,
      isEnabled: isEnabled ?? this.isEnabled,
      actions: actions ?? this.actions,
      progress: progress ?? this.progress,
    );
  }

  /// Task가 활성 상태인지 확인
  bool get isActive => isEnabled;
}
