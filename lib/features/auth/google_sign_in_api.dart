import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../services/auth_token_service.dart';
import '../../services/local_storage_service.dart';

class GoogleSignInApi {
  static final GoogleSignInApi _instance = GoogleSignInApi._internal();
  factory GoogleSignInApi() => _instance;

  GoogleSignInApi._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final AuthTokenService _authTokenService = AuthTokenService();
  final LocalStorageService _storage = LocalStorageService();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<void> init() async {
    await _storage.init();
    if (_storage.getBool('isLoggedIn') == true) {
      await _signInSilently();
    }
  }

  Future<void> _saveAccountInfo(GoogleSignInAccount account) async {
    await _storage.setBool('isLoggedIn', true);
    await _storage.setString('displayName', account.displayName ?? '');
    await _storage.setString('email', account.email);
    await _storage.setString('photoUrl', account.photoUrl ?? '');
  }

  Future<Map<String, dynamic>> _handleSignIn(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        return {
          'success': false,
          'message': '인증 토큰을 가져오는데 실패했습니다.',
        };
      }

      final jwtResult = await _authTokenService.requestJwtToken(auth.idToken!);
      if (!jwtResult['success']) {
        return jwtResult;
      }

      await _saveAccountInfo(account);
      return {
        'success': true,
        'message': '로그인 성공',
      };
    } catch (error) {
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다: $error',
      };
    }
  }

  Future<Map<String, dynamic>> signInManually() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {
          'success': false,
          'message': '로그인이 취소되었습니다.',
        };
      }
      debugPrint('account: $account');
      debugPrint('account.email: ${account.email}');
      
      return await _handleSignIn(account);
    } catch (error) {
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다: $error',
      };
    }
  }

  Future<Map<String, dynamic>> _signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return {
          'success': false,
          'message': '자동 로그인 실패: 계정을 찾을 수 없습니다.',
        };
      }

      final result = await _handleSignIn(account);
      if (result['success']) {
        result['message'] = '자동 로그인 성공';
      } else {
        result['message'] = '자동 ${result['message']}';
      }
      return result;
    } catch (error) {
      debugPrint('자동 로그인 실패: $error');
      return {
        'success': false,
        'message': '자동 로그인 실패: $error',
      };
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _authTokenService.clearToken();
    await _storage.clear();
  }

  Future<void> refreshUserInfo() async {
    final currentUser = await _googleSignIn.signInSilently();
    if (currentUser != null) {
      await _saveAccountInfo(currentUser);
    }
  }

  Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.idToken;
      }
      return null;
    } catch (error) {
      debugPrint('ID Token 가져오기 실패: $error');
      return null;
    }
  }
}
