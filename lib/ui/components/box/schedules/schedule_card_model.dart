import 'schedule_types.dart';

/// Schedule 데이터 모델
class ScheduleCardModel {
  final int id;
  final String title;
  final String time;
  final String location;
  final ScheduleType type;
  final String registeredTime;

  ScheduleCardModel({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    this.type = ScheduleType.list,
    required this.registeredTime,
  });

  /// Map에서 ScheduleCardModel 객체로 변환하는 팩토리 메소드
  factory ScheduleCardModel.fromMap(Map<String, dynamic> map) {
    return ScheduleCardModel(
      id: map['id'] as int,
      title: map['title'] as String,
      time: map['time'] as String,
      location: map['location'] as String,
      registeredTime:
          map['registeredTime']?.toString() ?? DateTime.now().toString(),
      type:
          map['type'] != null
              ? ScheduleType.values.firstWhere(
                (e) => e.toString() == 'ScheduleType.${map['type']}',
                orElse: () => ScheduleType.list,
              )
              : ScheduleType.list,
    );
  }

  /// ScheduleCardModel을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'location': location,
      'registeredTime': registeredTime,
      'type': type.toString().split('.').last,
    };
  }

  /// ScheduleCardModel 복사본 생성 (상태 변경용)
  ScheduleCardModel copyWith({
    int? id,
    String? title,
    String? time,
    String? location,
    ScheduleType? type,
    String? registeredTime,
  }) {
    return ScheduleCardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      location: location ?? this.location,
      type: type ?? this.type,
      registeredTime: registeredTime ?? this.registeredTime,
    );
  }
}
