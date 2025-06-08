import 'package:seobi_app/repositories/backend/models/session.dart' as backend_session;
import 'package:seobi_app/repositories/backend/models/message.dart';

/// 세션 데이터 모델
class Session {
  /// 세션의 고유 식별자 (UUID)
  final String id;

  /// 세션 시작 시각
  final DateTime? startAt;

  /// 세션 종료 시각 (진행 중인 세션의 경우 null)
  final DateTime? finishAt;

  /// AI가 생성한 세션 제목
  final String? title;

  /// AI가 생성한 세션 설명
  final String? description;

  /// 세션 소유자의 사용자 ID
  final String? userId;
  /// 세션에 포함된 메시지 리스트
  final List<Message> messages;

  /// 세션이 로드되었는지 여부
  final bool isLoaded;

  const Session({
    required this.id,
    this.startAt,
    this.finishAt,
    this.title,
    this.description,
    this.userId,
    this.messages = const [],
    this.isLoaded = false,
  });
  /// Backend Session 모델에서 변환
  factory Session.fromBackendSession(backend_session.Session backendSession) {
    return Session(
      id: backendSession.id,
      startAt: backendSession.startAt,
      finishAt: backendSession.finishAt,
      title: backendSession.title,
      description: backendSession.description,
      userId: backendSession.userId,
      messages: [], // 초기에는 빈 리스트로 설정
      isLoaded: false, // 처음에는 로드되지 않은 상태
    );
  }
  /// 세션이 로드되었는지 확인 (메시지가 로드되었는지 여부)
  bool get hasMessages => isLoaded;

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
  Session copyWith({
    String? id,
    DateTime? startAt,
    DateTime? finishAt,
    String? title,
    String? description,
    String? userId,
    List<Message>? messages,
    bool? isLoaded,
  }) {
    return Session(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      finishAt: finishAt ?? this.finishAt,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startAt == other.startAt &&
          finishAt == other.finishAt &&
          title == other.title &&
          description == other.description &&
          userId == other.userId &&
          messages == other.messages &&
          isLoaded == other.isLoaded;

  @override
  int get hashCode =>
      id.hashCode ^
      startAt.hashCode ^
      finishAt.hashCode ^
      title.hashCode ^
      description.hashCode ^
      userId.hashCode ^
      messages.hashCode ^
      isLoaded.hashCode;
  @override
  String toString() {
    return 'Session{id: $id, startAt: $startAt, finishAt: $finishAt, title: $title, description: $description, userId: $userId, messagesCount: ${messages.length}, isLoaded: $isLoaded}';
  }
}
