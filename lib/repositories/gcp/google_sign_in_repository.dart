import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'models/google_sign_in_result.dart';

class GoogleSignInRepository {
  static final GoogleSignInRepository _instance = GoogleSignInRepository._internal();
  factory GoogleSignInRepository() => _instance;

  GoogleSignInRepository._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInResult> signInManually() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return GoogleSignInResult.failure('로그인이 취소되었습니다.');
      }
      return await _handleSignIn(account);
    } catch (error) {
      return GoogleSignInResult.failure('로그인 중 오류가 발생했습니다: $error');
    }
  }

  Future<GoogleSignInResult> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        return GoogleSignInResult.failure('자동 로그인 실패: 계정을 찾을 수 없습니다.');
      }
      return await _handleSignIn(account);
    } catch (error) {
      debugPrint('자동 로그인 실패: $error');
      return GoogleSignInResult.failure('자동 로그인 실패: $error');
    }
  }

  Future<GoogleSignInResult> _handleSignIn(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        return GoogleSignInResult.failure('인증 토큰을 가져오는데 실패했습니다.');
      }

      return GoogleSignInResult.success(
        '로그인 성공',
        user: GoogleUserInfo(
          displayName: account.displayName,
          email: account.email,
          photoUrl: account.photoUrl,
          idToken: auth.idToken,
        ),
      );
    } catch (error) {
      return GoogleSignInResult.failure('로그인 중 오류가 발생했습니다: $error');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<GoogleUserInfo?> getCurrentUser() async {
    final account = _googleSignIn.currentUser;
    if (account != null) {
      final auth = await account.authentication;
      return GoogleUserInfo(
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );
    }
    return null;
  }
}
