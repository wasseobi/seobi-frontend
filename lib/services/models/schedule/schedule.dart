class Schedule {
  final String id;
  final String title;
  final String location;
  final DateTime time;
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      time:
          json['time'] != null ? DateTime.parse(json['time']) : DateTime.now(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'time': time.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
