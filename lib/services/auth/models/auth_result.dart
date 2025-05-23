class AuthResult {
  final bool success;
  final String message;

  const AuthResult({required this.success, required this.message});

  factory AuthResult.success(String message) {
    return AuthResult(success: true, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }

  Map<String, dynamic> toMap() {
    return {'success': success, 'message': message};
  }
}
