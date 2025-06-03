/// Task 데이터 모델
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
