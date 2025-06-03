import 'package:flutter/foundation.dart';

import '../../repositories/backend/i_backend_repository.dart';
import '../../repositories/local_database/local_database_repository.dart';
import '../../services/auth/auth_service.dart';
import '../../repositories/backend/backend_repository.dart';

class UpdateDbService {
  static final UpdateDbService _instance = UpdateDbService._internal();
  factory UpdateDbService() => _instance;
  final LocalDatabaseRepository _localDb = LocalDatabaseRepository();
  final IBackendRepository _backend = BackendRepository();
  final BackendRepository _backendImpl = BackendRepository();
  final AuthService _authService = AuthService();

  UpdateDbService._internal();

  /// 현재 사용자 정보를 가져오고 인증을 설정합니다.
  Future<void> _authenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }
    
    _backendImpl.setAuthToken(user.accessToken);
  }

  /// 로컬 DB에서 세션들을 삭제한 뒤 원격 DB에서도 해당 세션들을 삭제합니다.
  /// 
  /// [sessionIds] 삭제할 세션들의 ID 리스트
  Future<void> deleteSessions(List<String> sessionIds) async {
    try {
      debugPrint('[UpdateDbService] 세션 삭제 시작');
      debugPrint('[UpdateDbService] 삭제할 세션 ID 목록: $sessionIds');

      // 사용자 인증 처리
      await _authenticate();

      // 로컬 DB에서 세션들 삭제
      await _localDb.deleteSessions(sessionIds);
      debugPrint('[UpdateDbService] 로컬 DB에서 세션 삭제 완료');

      // 원격 DB에서 세션들 삭제
      for (var sessionId in sessionIds) {
        await _backend.deleteSessionById(sessionId);
      }
      debugPrint('[UpdateDbService] 원격 DB에서 세션 삭제 완료');

    } catch (e) {
      debugPrint('[UpdateDbService] 세션 삭제 중 오류 발생: $e');
      rethrow;
    }
  }
}