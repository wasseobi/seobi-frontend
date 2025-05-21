import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInApi {
  static final GoogleSignInApi _instance = GoogleSignInApi._internal();
  factory GoogleSignInApi() => _instance;

  GoogleSignInApi._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  late SharedPreferences prefs;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') == true) {
      await _signInSilently();
    }
  }

  _saveAccountInfo(GoogleSignInAccount account) async {
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('displayName', account.displayName ?? '');
    await prefs.setString('email', account.email);
    await prefs.setString('photoUrl', account.photoUrl ?? '');
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
      
      final auth = await account.authentication;
      debugPrint('auth: $auth');
      if (auth.accessToken == null || auth.idToken == null) {
        return {
          'success': false,
          'message': '인증 토큰을 가져오는데 실패했습니다.',
        };
      }

      _saveAccountInfo(account);

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

  Future<Map<String, dynamic>> _signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return {
          'success': false,
          'message': '자동 로그인 실패: 계정을 찾을 수 없습니다.',
        };
      }
      
      await _saveAccountInfo(account);
      return {
        'success': true,
        'message': '자동 로그인 성공',
      };
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
    await prefs.clear();
  }

  Future<void> refreshUserInfo() async {
    final currentUser = await _googleSignIn.signInSilently();
    if (currentUser != null) {
      await prefs.setString('displayName', currentUser.displayName ?? '');
      await prefs.setString('email', currentUser.email);
      await prefs.setString('photoUrl', currentUser.photoUrl ?? '');
    }
  }

  Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.idToken;
      }
    } catch (error) {
      debugPrint('ID Token 가져오기 실패: $error');
    }
    return null;
  }
}
