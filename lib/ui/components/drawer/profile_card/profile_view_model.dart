import 'package:flutter/foundation.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/models/seobi_user.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  
  // 사용자 정보 상태
  bool _isLoggedIn = false;
  String? _name;
  String? _email;
  String? _profileImageUrl;
  String? _role = '일반';

  // 생성자
  ProfileViewModel({AuthService? authService}) : 
    _authService = authService ?? AuthService() {
    loadUserData();
    _authService.addListener(_onAuthChanged);
  }

  // getter
  bool get isLoggedIn => _isLoggedIn;
  String? get name => _name;
  String? get email => _email;
  String? get profileImageUrl => _profileImageUrl;
  String? get role => _role;

  // 사용자 데이터 로드
  void loadUserData() {
    _isLoggedIn = _authService.isLoggedIn;
    _name = _authService.displayName;
    _email = _authService.userEmail;
    _profileImageUrl = _authService.photoUrl;
    
    notifyListeners();
  }
  
  // AuthService의 변경 사항을 감지하고 반영
  void _onAuthChanged() {
    loadUserData();
  }

  // 로그인 시도
  Future<bool> signIn() async {
    final result = await _authService.signIn();
    return result.success;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // 사용자 정보 가져오기
  Future<SeobiUser?> getUserInfo() async {
    return _authService.getUserInfo();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
