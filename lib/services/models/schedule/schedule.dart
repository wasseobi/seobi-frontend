class Schedule {
  final String id;
  final String title;
  final String location;
  final DateTime? startAt;
  final DateTime? createdAt;

  Schedule({
    required this.id,
    required this.title,
    required this.location,
    required this.startAt,
    required this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      startAt:
          json['start_at'] != null ? DateTime.parse(json['start_at']) : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'start_at': startAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
