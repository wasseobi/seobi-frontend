class AuthResult {
  final bool success;
  final String message;
  final UserInfo? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });

  factory AuthResult.success(String message, {UserInfo? user}) {
    return AuthResult(
      success: true,
      message: message,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'user': user?.toMap(),
    };
  }
}

class UserInfo {
  final String? displayName;
  final String email;
  final String? photoUrl;
  final String? idToken;

  const UserInfo({
    this.displayName,
    required this.email,
    this.photoUrl,
    this.idToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'idToken': idToken,
    };
  }

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      displayName: map['displayName'],
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      idToken: map['idToken'],
    );
  }
}
