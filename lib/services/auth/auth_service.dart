import 'package:seobi_app/services/models/seobi_user.dart';

import '../../repositories/gcp/google_sign_in_repository.dart';
import '../../repositories/local_storage/local_storage_repository.dart';
import '../../repositories/backend/backend_repository_factory.dart';
import '../../repositories/backend/i_backend_repository.dart';
import './models/auth_result.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final GoogleSignInRepository _googleSignIn = GoogleSignInRepository();
  final LocalStorageRepository _storage = LocalStorageRepository();
  final IBackendRepository _backend = BackendRepositoryFactory.instance;
  bool get isLoggedIn => _storage.getBool('isLoggedIn') ?? false;
  String? get userEmail => _storage.getString('email');
  String? get displayName => _storage.getString('displayName');
  String? get photoUrl => _storage.getString('photoUrl');
  String? get userId => _storage.getString('userId');
  Future<String?> get accessToken =>
      Future.value(_storage.getString('accessToken'));

  Future<SeobiUser?> getUserInfo() async {
    if (!isLoggedIn) return null;

    return SeobiUser(
      id: userId ?? '',
      username: displayName ?? '',
      email: userEmail ?? '',
      photoUrl: photoUrl,
      accessToken: await accessToken,
    );
  }

  Future<void> init() async {
    await _storage.init();
    if (isLoggedIn) {
      // await signIn(silently: true);
      debugPrint('로그인 유지되는 중');
    }
    
    // TODO: 아래 디버그 코드를 지우세요.
    final user = await getUserInfo();
    debugPrint('[JWT] ${user?.accessToken}');
  }

  Future<AuthResult> signIn({bool silently = false}) async {
    try {
      final result =
          silently
              ? await _googleSignIn.signInSilently()
              : await _googleSignIn.signInManually();
      if (!result.success) {
        return AuthResult.failure(result.message);
      }

      final googleUser = result.user;
      if (googleUser == null) {
        return AuthResult.failure('구글 사용자 정보가 없습니다.');
      }

      try {
        final user = await _backend.postUserLogin(googleUser.idToken);

        final seobiUser = SeobiUser.fromGoogleAndBackendUser(
          googleUser: googleUser,
          backendUser: user,
        );
        _saveUserInfo(seobiUser);
      } catch (error) {
        return AuthResult.failure('서버와의 통신 중 오류가 발생했습니다: $error');
      }

      notifyListeners();

      return AuthResult.success('로그인 성공');
    } catch (error) {
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $error');
    }
  }

  Future<void> _saveUserInfo(SeobiUser user) async {
    await _storage.setBool('isLoggedIn', true);
    await _storage.setString('displayName', user.username);
    await _storage.setString('email', user.email);
    await _storage.setString('photoUrl', user.photoUrl ?? '');
    await _storage.setString('userId', user.id);
    if (user.accessToken != null) {
      await _storage.setString('accessToken', user.accessToken!);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _removeAuthInfoFromStorage();
    notifyListeners();
  }

  Future<void> _removeAuthInfoFromStorage() async {
    await _storage.setBool('isLoggedIn', false);
    await _storage.setString('displayName', '');
    await _storage.setString('email', '');
    await _storage.setString('photoUrl', '');
    await _storage.setString('accessToken', '');
    await _storage.setString('userId', '');
  }
}
