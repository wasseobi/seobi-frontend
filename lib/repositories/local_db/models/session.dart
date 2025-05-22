/// 세션 모델 클래스입니다.
class Session {
  final String id;
  final String userId;
  final DateTime? startAt;
  final DateTime? finishAt;
  final String? title;
  final String? description;

  Session({
    required this.id,
    required this.userId,
    this.startAt,
    this.finishAt,
    this.title,
    this.description,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startAt: json['start_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['start_at'] as int)
          : null,
      finishAt: json['finish_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finish_at'] as int)
          : null,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_at': startAt?.millisecondsSinceEpoch,
      'finish_at': finishAt?.millisecondsSinceEpoch,
      'title': title,
      'description': description,
    };
  }

  Session copyWith({
    String? id,
    String? userId,
    DateTime? startAt,
    DateTime? finishAt,
    String? title,
    String? description,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}
