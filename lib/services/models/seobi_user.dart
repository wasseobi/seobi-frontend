import 'package:seobi_app/repositories/backend/models/user.dart';
import 'package:seobi_app/repositories/gcp/models/google_user.dart';

class SeobiUser {
  final String id;
  final String username;
  final String email;
  final String? photoUrl;
  final String? accessToken;

  const SeobiUser({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    this.accessToken,
  });

  factory SeobiUser.fromGoogleAndBackendUser({
    required GoogleUser googleUser,
    required User backendUser,
  }) {
    return SeobiUser(
      id: backendUser.id,
      username: googleUser.displayName ?? googleUser.email,
      email: googleUser.email,
      photoUrl: googleUser.photoUrl,
      accessToken: backendUser.accessToken,
    );
  }
}
