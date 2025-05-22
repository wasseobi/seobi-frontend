import '../../repositories/gcp/google_sign_in_repository.dart';
import '../../repositories/gcp/models/google_sign_in_result.dart';
import '../../repositories/local_storage/local_storage_repository.dart';
import '../../repositories/backend/backend_repository_factory.dart';
import '../../repositories/backend/backend_repository_interface.dart';
import './models/auth_result.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final GoogleSignInRepository _googleSignIn = GoogleSignInRepository();
  final LocalStorageRepository _storage = LocalStorageRepository();
  final BackendRepositoryInterface _backend = BackendRepositoryFactory.instance;

  bool get isLoggedIn => _storage.getBool('isLoggedIn') ?? false;
  String? get userEmail => _storage.getString('email');
  String? get displayName => _storage.getString('displayName');
  String? get photoUrl => _storage.getString('photoUrl');
  Future<String?> get accessToken => Future.value(_storage.getString('access_token'));

  Future<UserInfo?> getUserInfo() async {
    if (!isLoggedIn) return null;
    
    return UserInfo(
      displayName: displayName,
      email: userEmail ?? '',
      photoUrl: photoUrl,
      idToken: await accessToken,
    );
  }

  Future<void> init() async {
    await _storage.init();
    if (isLoggedIn) {
      await _signInSilently();
    }
  }

  AuthResult _convertGoogleResult(GoogleSignInResult result) {
    if (!result.success) {
      return AuthResult.failure(result.message);
    }
    return AuthResult.success(
      result.message,
      user: result.user == null ? null : UserInfo(
        displayName: result.user!.displayName,
        email: result.user!.email,
        photoUrl: result.user!.photoUrl,
        idToken: result.user!.idToken,
      ),
    );
  }

  Future<AuthResult> _signInSilently() async {
    try {
      final result = await _googleSignIn.signInSilently();
      final authResult = _convertGoogleResult(result);
      if (authResult.user != null) {
        await _handleLoginSuccess(authResult.user!);
      }
      return authResult;
    } catch (error) {
      return AuthResult.failure('자동 로그인 실패: $error');
    }
  }

  Future<AuthResult> signInManually() async {
    try {
      final result = await _googleSignIn.signInManually();
      final authResult = _convertGoogleResult(result);
      if (authResult.user != null) {
        await _handleLoginSuccess(authResult.user!);
        notifyListeners();
      }
      return authResult;
    } catch (error) {
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $error');
    }
  }

  Future<void> _handleLoginSuccess(UserInfo userInfo) async {
    await _saveUserInfo(userInfo);
    if (userInfo.idToken != null) {
      await _requestJwtToken(userInfo.idToken!);
    }
    notifyListeners();
  }

  Future<AuthResult> _requestJwtToken(String idToken) async {
    try {
      final response = await _backend.postUserLogin(idToken);
      if (response.containsKey('access_token')) {
        await _storage.setString('access_token', response['access_token']);
        return AuthResult.success('JWT 토큰이 성공적으로 저장되었습니다.');
      } else {
        return AuthResult.failure('JWT 토큰이 응답에 없습니다.');
      }
    } catch (error) {
      debugPrint('JWT 토큰 요청 중 오류: $error');
      return AuthResult.failure(error.toString());
    }
  }

  Future<void> _saveUserInfo(UserInfo userInfo) async {
    await _storage.setBool('isLoggedIn', true);
    await _storage.setString('displayName', userInfo.displayName ?? '');
    await _storage.setString('email', userInfo.email);
    await _storage.setString('photoUrl', userInfo.photoUrl ?? '');
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
    await _storage.setString('access_token', '');
  }
}