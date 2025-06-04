class User {
  final String id;
  final String? accessToken;

  User({
    required this.id,
    this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      accessToken: json['access_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'access_token': accessToken,
    };
  }

  // 로컬 저장소 관련 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accessToken': accessToken,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      accessToken: map['accessToken'] ?? map['access_token'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? photoUrl,
    String? accessToken,
  }) {
    return User(
      id: id ?? this.id,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, accessToken: $accessToken)';
  }
}