import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_service.dart';
import 'conversation/conversation_service.dart';
import 'stt/stt_service.dart';
import '../repositories/local_storage/local_storage_repository.dart';
import 'sync_db/pull_db_service.dart';
import 'sync_db/update_db_service.dart';

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
        final sttService = STTService();
        await sttService.initialize();
        debugPrint('[ServiceManager] ✅ STT 서비스 초기화 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ STT 서비스 초기화 실패 (앱 계속 실행): $e');
      }
      
      // 대화 서비스 초기화
      try {
        ConversationService();
        debugPrint('[ServiceManager] ✅ 대화 서비스 초기화 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ 대화 서비스 초기화 실패 (앱 계속 실행): $e');
      }
      
      // 동기화 서비스 초기화
      try {
        PullDbService();
        UpdateDbService();
        debugPrint('[ServiceManager] ✅ 동기화 서비스 초기화 완료');
      } catch (e) {
        debugPrint('[ServiceManager] ⚠️ 동기화 서비스 초기화 실패 (앱 계속 실행): $e');
      }
      
      debugPrint('[ServiceManager] ✅ 모든 서비스 초기화 완료');
      
    } catch (e) {
      debugPrint('[ServiceManager] ❌ 서비스 초기화 실패: $e');
      throw e;
    }
  }
}