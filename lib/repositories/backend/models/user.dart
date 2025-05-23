class User {
  final String id;
  final String username;
  final String email;
  final String? accessToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      accessToken: json['access_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'access_token': accessToken,
    };
  }

  // 로컬 저장소 관련 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'accessToken': accessToken,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? map['displayName'] ?? '',
      email: map['email'] ?? '',
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
      username: username ?? this.username,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, accessToken: $accessToken)';
  }
}