// ============================================================================
// Session 모델 정의 (Local Database 호환)
// ============================================================================
// Local Database의 기본 구조를 베이스로 하되, Backend API 확장 기능 포함

/// 세션 타입 열거형 (Backend 전용, 향후 확장용)
enum SessionType {
  /// 기본 AI 채팅 세션
  chat,

  /// 일정 관리 세션 (swagger_new.json의 Schedule API용)
  schedule,

  /// 인사이트 생성 세션 (swagger_new.json의 Insights API용)
  insights,
}

/// 채팅 세션을 나타내는 통합 모델 클래스
///
/// Local Database와 Backend API 모두에서 사용할 수 있도록 설계되었습니다.
/// 기본 필드는 Local Database와 동일하며, 확장 필드는 Backend에서만 사용됩니다.
class Session {
  // ========================================
  // 기본 필드들 (Local Database 호환)
  // ========================================

  /// 세션의 고유 식별자 (UUID 형식)
  final String id;

  /// 세션 시작 시각 (Local Database에서는 nullable)
  final DateTime? startAt;

  /// 세션 종료 시각 (진행 중인 세션의 경우 null)
  final DateTime? finishAt;

  /// AI가 생성한 세션 제목 (세션 종료 시 자동 생성)
  final String? title;

  /// AI가 생성한 세션 설명 (세션 종료 시 자동 생성)
  final String? description;

  // ========================================
  // Backend 확장 필드들
  // ========================================

  /// 세션 소유자의 사용자 ID (Backend 전용)
  final String? userId;

  /// 세션 타입 (Backend 전용, 향후 다양한 세션 타입 구분용)
  final SessionType type;

  const Session({
    required this.id,
    this.startAt,
    this.finishAt,
    this.title,
    this.description,
    // Backend 확장 필드들
    this.userId,
    this.type = SessionType.chat, // 기본값은 일반 채팅
  });

  /// Local Database용 Map 변환 (기본 필드만)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_at': startAt?.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'title': title,
      'description': description,
    };
  }

  /// Local Database용 Map에서 생성 (기본 필드만)
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      startAt: map['start_at'] != null ? DateTime.parse(map['start_at']) : null,
      finishAt:
          map['finish_at'] != null ? DateTime.parse(map['finish_at']) : null,
      title: map['title'],
      description: map['description'],
    );
  }

  /// Backend API용 JSON 변환 (모든 필드 포함)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_at': startAt?.toIso8601String(),
      'finish_at': finishAt?.toIso8601String(),
      'title': title,
      'description': description,
      // Backend 확장 필드들 (값이 있을 때만 포함)
      if (userId != null) 'user_id': userId,
      'type': type.name, // enum의 name 사용
      // 하위 호환성을 위해 is_ai_chat도 포함
      'is_ai_chat': type == SessionType.chat,
    };
  }

  /// Backend API용 JSON에서 생성 (모든 필드 포함)
  factory Session.fromJson(Map<String, dynamic> json) {
    // 백엔드 호환성을 위해 기존 is_ai_chat도 지원
    SessionType sessionType = SessionType.chat; // 기본값

    if (json.containsKey('type')) {
      // 새로운 type 필드 우선 처리
      final typeString = json['type'] as String?;
      sessionType = _parseSessionType(typeString) ?? SessionType.chat;
    } else if (json.containsKey('is_ai_chat')) {
      // 기존 is_ai_chat 필드 지원 (하위 호환성)
      sessionType = SessionType.chat;
    }

    return Session(
      id: json['id'] as String,
      startAt:
          json['start_at'] != null
              ? DateTime.parse(json['start_at'] as String)
              : null,
      finishAt:
          json['finish_at'] != null
              ? DateTime.parse(json['finish_at'] as String)
              : null,
      title: json['title'] as String?,
      description: json['description'] as String?,
      // Backend 확장 필드들
      userId: json['user_id'] as String?,
      type: sessionType,
    );
  }

  /// 세션 타입 문자열을 SessionType enum으로 변환하는 헬퍼
  static SessionType? _parseSessionType(String? typeString) {
    if (typeString == null) return null;

    for (final type in SessionType.values) {
      if (type.name == typeString) return type;
    }

    return null;
  }

  /// Session 인스턴스의 일부 필드를 변경한 새 인스턴스를 생성
  Session copyWith({
    String? id,
    DateTime? startAt,
    DateTime? finishAt,
    String? title,
    String? description,
    String? userId,
    SessionType? type,
  }) {
    return Session(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      type: type ?? this.type,
    );
  }

  // ========================================
  // 편의 메서드들
  // ========================================

  /// 세션이 현재 진행 중인지 확인
  bool get isActive => finishAt == null;

  /// 세션이 종료되었는지 확인
  bool get isFinished => finishAt != null;

  /// 세션의 지속 시간을 계산
  Duration get duration {
    if (startAt == null) return Duration.zero;
    final endTime = finishAt ?? DateTime.now();
    return endTime.difference(startAt!);
  }

  /// 세션 지속 시간을 사람이 읽기 쉬운 형태로 반환
  String get durationText {
    if (startAt == null) return '알 수 없음';

    final endTime = finishAt ?? DateTime.now();
    final duration = endTime.difference(startAt!);

    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return '${duration.inDays}일${hours > 0 ? ' $hours시간' : ''}';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}시간${minutes > 0 ? ' $minutes분' : ''}';
    } else {
      return '${duration.inMinutes}분';
    }
  }

  /// 세션에 제목이 설정되어 있는지 확인
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// 세션에 설명이 설정되어 있는지 확인
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// 세션에 AI가 생성한 요약 정보가 있는지 확인
  bool get hasSummary => hasTitle && hasDescription;

  /// 표시용 제목 반환
  String get displayTitle {
    if (hasTitle) return title!;
    if (isActive) return '진행 중인 대화';
    if (startAt != null) return '${startAt!.month}/${startAt!.day} 대화';
    return '대화';
  }

  /// 세션 상태를 나타내는 텍스트 반환
  String get statusText => isActive ? '진행 중' : '완료';

  /// 세션이 오늘 시작되었는지 확인
  bool get isToday {
    if (startAt == null) return false;
    final now = DateTime.now();
    return _isSameDay(startAt!, now);
  }

  /// 세션이 어제 시작되었는지 확인
  bool get isYesterday {
    if (startAt == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(startAt!, yesterday);
  }

  /// 세션 시작 시각을 사람이 읽기 쉬운 형태로 반환
  String get startTimeText {
    if (startAt == null) return '알 수 없음';

    final now = DateTime.now();

    // 오늘인지 확인
    if (_isSameDay(startAt!, now)) {
      final timeStr = _formatTime(startAt!);
      return '오늘 $timeStr';
    }

    // 어제인지 확인
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(startAt!, yesterday)) {
      final timeStr = _formatTime(startAt!);
      return '어제 $timeStr';
    }

    // 그 외의 경우
    final timeStr = _formatTime(startAt!);
    return '${startAt!.month}/${startAt!.day} $timeStr';
  }

  /// 세션 타입을 한국어로 반환
  String get typeDisplayName {
    switch (type) {
      case SessionType.chat:
        return 'AI 채팅';
      case SessionType.schedule:
        return '일정 관리';
      case SessionType.insights:
        return '인사이트';
    }
  }

  /// 두 DateTime이 같은 날인지 확인하는 내부 헬퍼 메서드
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 시간을 HH:MM 형식으로 포맷하는 내부 헬퍼 메서드
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Session(id: $id, startAt: $startAt, finishAt: $finishAt, '
        'title: $title, type: $type, status: $statusText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ========================================
  // AI 도구 사용 관련 헬퍼 메서드들
  // ========================================

  /// 현재 세션 타입이 도구 사용이 가능한지 확인
  bool get canUseTools {
    switch (type) {
      case SessionType.chat:
        return true; // 일반 채팅에서 웹 검색 등 도구 사용 가능
      case SessionType.schedule:
        return true; // 일정 관리에서 캘린더 API 등 사용 가능
      case SessionType.insights:
        return true; // 인사이트에서 데이터 분석 도구 사용 가능
    }
  }

  /// 세션 타입에 따른 기본 사용 가능 도구 목록
  List<String> get availableTools {
    switch (type) {
      case SessionType.chat:
        return ['search_web', 'general_assistant'];
      case SessionType.schedule:
        return [
          'parse_schedule',
          'create_schedule',
          'get_calendar',
          'search_web',
        ];
      case SessionType.insights:
        return ['generate_insight', 'analyze_data', 'search_web'];
    }
  }

  /// 세션 타입에 따른 주요 기능 설명
  String get typeDescription {
    switch (type) {
      case SessionType.chat:
        return 'AI와 자유롭게 대화하고 웹 검색을 통한 실시간 정보를 받을 수 있습니다.';
      case SessionType.schedule:
        return '자연어로 일정을 등록하고 관리할 수 있습니다. "6월 7일 오후 4시에 회의"와 같이 말해보세요.';
      case SessionType.insights:
        return '대화 기록을 분석하여 개인화된 인사이트와 추천을 제공합니다.';
    }
  }

  /// 세션 타입에 따른 아이콘 반환
  String get typeIcon {
    switch (type) {
      case SessionType.chat:
        return '💬';
      case SessionType.schedule:
        return '📅';
      case SessionType.insights:
        return '🔍';
    }
  }

  /// 세션이 특정 도구를 지원하는지 확인
  bool supportsToolName(String toolName) {
    return availableTools.contains(toolName);
  }

  /// swagger_new.json API 활성화 여부에 따른 세션 가용성
  bool get isAvailableInCurrentAPI {
    switch (type) {
      case SessionType.chat:
        return true; // 항상 사용 가능
      case SessionType.schedule:
        // swagger_new.json의 Schedule API가 활성화되어야 함
        return false; // TODO: API 활성화 시 true로 변경
      case SessionType.insights:
        // swagger_new.json의 Insights API가 활성화되어야 함
        return false; // TODO: API 활성화 시 true로 변경
    }
  }

  /// 사용 불가능한 세션 타입에 대한 안내 메시지
  String? get unavailabilityReason {
    if (isAvailableInCurrentAPI) return null;

    switch (type) {
      case SessionType.schedule:
        return '일정 관리 기능은 곧 출시될 예정입니다.';
      case SessionType.insights:
        return '인사이트 기능은 곧 출시될 예정입니다.';
      case SessionType.chat:
        return null; // 항상 사용 가능
    }
  }
}
