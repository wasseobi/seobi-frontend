import 'package:seobi_app/repositories/backend/backend_repository.dart';
import 'package:seobi_app/services/models/seobi_user.dart';

import '../../repositories/gcp/google_sign_in_repository.dart';
import '../../repositories/local_storage/local_storage_repository.dart';
import '../../repositories/backend/i_backend_repository.dart';
import './models/auth_result.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../report/report_sevice.dart';
import '../conversation/history_service.dart';
import '../conversation/conversation_service2.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final GoogleSignInRepository _googleSignIn = GoogleSignInRepository();
  final LocalStorageRepository _storage = LocalStorageRepository();
  final IBackendRepository _backend = BackendRepository();
  bool get isLoggedIn => _storage.getBool('isLoggedIn') ?? false;
  String? get userEmail => _storage.getString('email');
  String? get displayName => _storage.getString('displayName');
  String? get photoUrl => _storage.getString('photoUrl');
  String? get userId => _storage.getString('userId');
  Future<String?> get accessToken =>
      Future.value(_storage.getString('accessToken'));

  bool _isInitialized = false;

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
    if (_isInitialized) return;

    await _storage.init();
    if (isLoggedIn) {
      debugPrint('로그인 유지되는 중');
    }

    final user = await getUserInfo();
    debugPrint('[JWT] ${user?.accessToken}');

    _isInitialized = true;
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
        debugPrint(
          '[Google Sign In] ${googleUser.email} ${googleUser.displayName}',
        );
        final user = await _backend.postUserLogin(
          googleUser.email,
          googleUser.displayName,
        );
        debugPrint('[JWT] ${user.accessToken}');

        final seobiUser = SeobiUser.fromGoogleAndBackendUser(
          googleUser: googleUser,
          backendUser: user,
        );
        await _saveUserInfo(seobiUser);

        // 사용자 정보 저장 후 상태 변화 알림
        notifyListeners();
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

    // Article 캐시 삭제
    await _clearArticleCaches();

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

  /// Article 및 대화 관련 캐시들을 모두 삭제합니다
  Future<void> _clearArticleCaches() async {
    try {
      debugPrint('[AuthService] 🗑️ Article 및 대화 캐시 삭제 시작');

      // 1. Report 캐시 삭제 (ReportService 사용)
      final reportService = ReportService();
      await reportService.clearCache();

      // 2. Insight 캐시 삭제 (SharedPreferences 직접 사용)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('insight_cards_state');

      // 3. 채팅 관련 캐시 삭제
      await _clearConversationCaches(prefs);

      debugPrint('[AuthService] ✅ Article 및 대화 캐시 삭제 완료');
    } catch (e) {
      debugPrint('[AuthService] ⚠️ Article 및 대화 캐시 삭제 실패: $e');
      // 실패해도 로그아웃은 계속 진행
    }
  }

  /// 대화 관련 캐시들을 삭제합니다
  Future<void> _clearConversationCaches(SharedPreferences prefs) async {
    try {
      debugPrint('[AuthService] 💬 대화 캐시 삭제 시작');

      // 1. 대화 서비스 리소스 정리
      try {
        final conversationService = ConversationService2();
        await conversationService.dispose();
        debugPrint('[AuthService] ✅ ConversationService2 정리 완료');
      } catch (e) {
        debugPrint('[AuthService] ⚠️ ConversationService2 정리 실패: $e');
      }

      // 2. 히스토리 서비스의 대기 메시지 클리어
      try {
        final historyService = HistoryService();
        if (historyService.hasPendingUserMessage) {
          historyService.clearPendingUserMessage();
        }
        debugPrint('[AuthService] ✅ HistoryService 대기 메시지 클리어 완료');
      } catch (e) {
        debugPrint('[AuthService] ⚠️ HistoryService 정리 실패: $e');
      }

      // 3. SharedPreferences의 세션 관련 키들 삭제
      await prefs.remove('active_session_id');
      await prefs.remove('last_session_id');
      await prefs.remove('session_start_time');

      // 4. TTS 관련 사용자 설정 삭제 (사용자별 개인 설정)
      await prefs.remove('tts_enabled');
      await prefs.remove('tts_speed');
      await prefs.remove('tts_pitch');
      await prefs.remove('tts_volume');

      // 5. 대기 중인 인사이트 생성 요청도 삭제 (추가)
      await prefs.remove('pending_insight_request');

      debugPrint('[AuthService] ✅ 대화 관련 SharedPreferences 삭제 완료');
    } catch (e) {
      debugPrint('[AuthService] ⚠️ 대화 캐시 삭제 실패: $e');
    }
  }

  /// 리소스 정리
  @override
  Future<void> dispose() async {
    debugPrint('[AuthService] 🧹 리소스 정리 시작');

    try {
      // 구글 로그인 정리
      await _googleSignIn.signOut();

      // 로컬 스토리지 정리
      await _storage.remove('isLoggedIn');
      await _storage.remove('email');
      await _storage.remove('displayName');
      await _storage.remove('photoUrl');
      await _storage.remove('userId');
      await _storage.remove('accessToken');

      // 부모 클래스의 dispose 호출
      super.dispose();

      debugPrint('[AuthService] ✅ 리소스 정리 완료');
    } catch (e) {
      debugPrint('[AuthService] ⚠️ 리소스 정리 실패: $e');
      rethrow;
    }
  }
}
