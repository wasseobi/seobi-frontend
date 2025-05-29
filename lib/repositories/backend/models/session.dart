class Session {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime? finishAt;
  final String? title;
  final String? description;
  bool isAiChat;

  Session({
    required this.id,
    required this.userId,
    required this.startAt,
    this.finishAt,
    this.title,
    this.description,
    this.isAiChat = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      finishAt:
          json['finish_at'] != null
              ? DateTime.parse(json['finish_at'] as String)
              : null,
      title: json['title'] as String?,
      description: json['description'] as String?,
      isAiChat: json['is_ai_chat'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_at': startAt.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'title': title,
      'description': description,
      'is_ai_chat': isAiChat,
    };
  }

  Session copyWith({
    String? id,
    String? userId,
    DateTime? startAt,
    DateTime? finishAt,
    String? title,
    String? description,
    bool? isAiChat,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      title: title ?? this.title,
      description: description ?? this.description,
      isAiChat: isAiChat ?? this.isAiChat,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, userId: $userId, startAt: $startAt, finishAt: $finishAt, title: $title, description: $description, isAiChat: $isAiChat)';
  }
}
