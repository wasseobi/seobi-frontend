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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_at': startAt?.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'title': title,
      'description': description,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      userId: map['user_id'],
      startAt: map['start_at'] != null ? DateTime.parse(map['start_at']) : null,
      finishAt: map['finish_at'] != null ? DateTime.parse(map['finish_at']) : null,
      title: map['title'],
      description: map['description'],
    );
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
