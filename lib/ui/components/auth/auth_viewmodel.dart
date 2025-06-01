import 'package:flutter/material.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/auth/models/auth_result.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  AuthViewModel() {
    _isLoggedIn = _authService.isLoggedIn;
    _authService.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    final newLoginState = _authService.isLoggedIn;
    if (_isLoggedIn != newLoginState) {
      _isLoggedIn = newLoginState;
      notifyListeners();
    }
  }

  // 로그인 처리
  Future<AuthResult> signIn() async {
    if (_isLoading) return AuthResult.failure('이미 로그인 처리 중입니다');

    _isLoading = true;
    notifyListeners();

    AuthResult result;
    try {
      result = await _authService.signIn();
    } catch (e) {
      result = AuthResult.failure('로그인 중 오류가 발생했습니다: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return result;
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
