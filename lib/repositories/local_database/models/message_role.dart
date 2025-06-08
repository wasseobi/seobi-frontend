enum MessageRole {
  user,
  assistant,
  tool,
  system;

  @override
  String toString() => name;

  // String을 MessageRole로 변환하는 팩토리 메서드
  factory MessageRole.fromString(String value) {
    try {
      return MessageRole.values.firstWhere(
        (e) => e.toString().toLowerCase() == value.toLowerCase(),
        orElse: () => MessageRole.user,
      );
    } catch (_) {
      return MessageRole.user;
    }
  }
}
