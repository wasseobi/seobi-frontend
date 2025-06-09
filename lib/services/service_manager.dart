import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:seobi_app/services/tts/tts_service.dart';
import 'auth/auth_service.dart';
import 'conversation/conversation_service2.dart';
import 'stt/stt_service.dart';
import '../repositories/local_storage/local_storage_repository.dart';

/// 모든 서비스 초기화 관리자
class ServiceManager {
  ServiceManager._();

  /// 모든 서비스 초기화
  static Future<void> initialize() async {
    debugPrint('[ServiceManager] 🚀 서비스 초기화 시작');

    try {
      // 환경변수 로드
      await dotenv.load();
      debugPrint('[ServiceManager] ✅ 환경변수 로드 완료');

      // 로컬 저장소 초기화
      final storage = LocalStorageRepository();
      await storage.init();
      debugPrint('[ServiceManager] ✅ 로컬 저장소 초기화 완료');

      // 인증 서비스 초기화
      final authService = AuthService();
      await authService.init();
      debugPrint('[ServiceManager] ✅ 인증 서비스 초기화 완료');

      // STT 서비스 초기화
      try {
        final sttService = SttService();
        await sttService.initialize();
        debugPrint('[ServiceManager] ✅ STT 서비스 초기화 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ STT 서비스 초기화 실패 (앱 계속 실행): $e');
      }

      // TTS 서비스 초기화
      try {
        final ttsService = TtsService();
        await ttsService.initialize();
        debugPrint('[ServiceManager] ✅ TTS 서비스 초기화 완료 (가상)');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ TTS 서비스 초기화 실패 (앱 계속 실행): $e');
      }

      // 대화 서비스 초기화
      try {
        final conversationService = ConversationService2();
        await conversationService.initialize();
        debugPrint('[ServiceManager] ✅ 대화 서비스 초기화 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ 대화 서비스 초기화 실패 (앱 계속 실행): $e');
      }

      debugPrint('[ServiceManager] ✅ 모든 서비스 초기화 완료');
    } catch (e) {
      debugPrint('[ServiceManager] ❌ 서비스 초기화 실패: $e');
      rethrow;
    }
  }

  /// 모든 서비스 정리
  static Future<void> dispose() async {
    debugPrint('[ServiceManager] 🧹 서비스 정리 시작');

    try {
      // TTS 서비스 정리
      try {
        final ttsService = TtsService();
        await ttsService.dispose();
        debugPrint('[ServiceManager] ✅ TTS 서비스 정리 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ TTS 서비스 정리 실패: $e');
      }

      // STT 서비스 정리
      try {
        final sttService = SttService();
        await sttService.dispose();
        debugPrint('[ServiceManager] ✅ STT 서비스 정리 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ STT 서비스 정리 실패: $e');
      }

      // 대화 서비스 정리
      try {
        final conversationService = ConversationService2();
        await conversationService.dispose();
        debugPrint('[ServiceManager] ✅ 대화 서비스 정리 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ 대화 서비스 정리 실패: $e');
      }

      // 인증 서비스 정리
      final authService = AuthService();
      await authService.dispose();
      debugPrint('[ServiceManager] ✅ 인증 서비스 정리 완료');

      debugPrint('[ServiceManager] ✅ 모든 서비스 정리 완료');
    } catch (e) {
      debugPrint('[ServiceManager] ❌ 서비스 정리 중 오류 발생: $e');
      rethrow;
    }
  }
}
