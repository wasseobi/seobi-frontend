import './google_user.dart';

class GoogleSignInResult {
  final bool success;
  final String message;
  final GoogleUser? user;

  const GoogleSignInResult({
    required this.success,
    required this.message,
    this.user,
  });

  factory GoogleSignInResult.success(String message, {required GoogleUser user}) {
    return GoogleSignInResult(
      success: true,
      message: message,
      user: user,
    );
  }

  factory GoogleSignInResult.failure(String message) {
    return GoogleSignInResult(
      success: false,
      message: message,
    );
  }
}
