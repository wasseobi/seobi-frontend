class GoogleSignInResult {
  final bool success;
  final String message;
  final GoogleUserInfo? user;

  const GoogleSignInResult({
    required this.success,
    required this.message,
    this.user,
  });

  factory GoogleSignInResult.success(String message, {required GoogleUserInfo user}) {
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

class GoogleUserInfo {
  final String? displayName;
  final String email;
  final String? photoUrl;
  final String? idToken;

  const GoogleUserInfo({
    this.displayName,
    required this.email,
    this.photoUrl,
    this.idToken,
  });
}
