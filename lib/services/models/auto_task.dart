class AutoTask {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final dynamic taskList; // object | array | null
  final String? repeat;
  final DateTime createdAt;
  final DateTime? startAt;
  final DateTime? finishAt;
  final DateTime? preferredAt;
  final bool active;
  final String? tool;
  final String? linkedService;
  final String? currentStep;
  final String status;
  final dynamic output; // object | array | string | null
  final Map<String, dynamic>? meta;

  AutoTask({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.taskList,
    this.repeat,
    required this.createdAt,
    this.startAt,
    this.finishAt,
    this.preferredAt,
    required this.active,
    this.tool,
    this.linkedService,
    this.currentStep,
    required this.status,
    this.output,
    this.meta,
  });

  factory AutoTask.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value != null ? DateTime.tryParse(value) : null;
    return AutoTask(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      taskList: json['task_list'],
      repeat: json['repeat']?.toString(),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      startAt: parseDate(json['start_at']),
      finishAt: parseDate(json['finish_at']),
      preferredAt: parseDate(json['preferred_at']),
      active: json['active'] == true || json['active'] == 'true',
      tool: json['tool']?.toString(),
      linkedService: json['linked_service']?.toString(),
      currentStep: json['current_step']?.toString(),
      status: json['status']?.toString() ?? 'undone',
      output: json['output'],
      meta:
          json['meta'] is Map<String, dynamic>
              ? json['meta']
              : (json['meta'] != null
                  ? Map<String, dynamic>.from(json['meta'])
                  : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'task_list': taskList,
      'repeat': repeat,
      'created_at': createdAt.toIso8601String(),
      'start_at': startAt?.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'preferred_at': preferredAt?.toIso8601String(),
      'active': active,
      'tool': tool,
      'linked_service': linkedService,
      'current_step': currentStep,
      'status': status,
      'output': output,
      'meta': meta,
    };
  }
}
