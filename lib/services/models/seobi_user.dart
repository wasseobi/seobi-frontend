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
      username: backendUser.username,
      email: googleUser.email,
      photoUrl: googleUser.photoUrl,
      accessToken: backendUser.accessToken,
    );
  }

  factory SeobiUser.fromBackendUser(User user) {
    return SeobiUser(
      id: user.id,
      username: user.username,
      email: user.email,
      accessToken: user.accessToken,
      photoUrl: null,
    );
  }

  factory SeobiUser.fromGoogleUser(GoogleUser user, {required String id}) {
    return SeobiUser(
      id: id,
      username: user.displayName ?? user.email,
      email: user.email,
      photoUrl: user.photoUrl,
      accessToken: null,
    );
  }
}
