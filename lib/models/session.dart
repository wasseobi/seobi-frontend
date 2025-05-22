class Session {
  final String id;
  final String userId;
  final String? title;
  final String? description;
  final DateTime? startAt;
  final DateTime? finishAt;

  Session({
    required this.id,
    required this.userId,
    this.title,
    this.description,
    this.startAt,
    this.finishAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      startAt:
          json['start_at'] != null ? DateTime.parse(json['start_at']) : null,
      finishAt:
          json['finish_at'] != null ? DateTime.parse(json['finish_at']) : null,
    );
  }
}
