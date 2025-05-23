import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../repositories/backend/backend_repository.dart';
import '../../repositories/backend/models/session.dart';
import '../../repositories/backend/models/message.dart';
import '../../services/auth/auth_service.dart';

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  
  final BackendRepository _backendRepository = BackendRepository();
  final AuthService _authService = AuthService();
  
  factory ConversationService() => _instance;

  ConversationService._internal();

  /// 현재 사용자 정보를 가져오고 인증을 설정합니다.
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }
    
    _backendRepository.setAuthToken(user.accessToken);
    return user.id;
  }

  /// 새로운 대화 세션을 생성합니다.
  ///
  /// [title]과 [description]은 선택적 매개변수입니다.
  Future<Session> createSession() async {
    try {
      final userId = await _getUserIdAndAuthenticate();

      final session = await _backendRepository.postSession(userId);

      debugPrint('새 세션이 생성되었습니다: ${session.id}');
      return session;
    } catch (e) {
      debugPrint('세션 생성 오류: $e');
      rethrow;
    }
  }

  /// 메시지를 보내고 응답을 받습니다.
  ///
  /// [sessionId] 현재 대화 세션 ID
  /// [content] 사용자 메시지 내용
  Future<Message> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      final userId = await _getUserIdAndAuthenticate();
      
      // 사용자 메시지 전송
      final userMessage = await _backendRepository.postMessage(
        sessionId: sessionId,
        userId: userId,
        content: content,
        role: 'user',
      );
      
      debugPrint('사용자 메시지가 전송되었습니다: ${userMessage.id}');
      
      // AI 응답 요청
      final completionMessage = await _backendRepository.postMessageLanggraphCompletion(
        sessionId: sessionId,
        userId: userId,
        content: content,
      );
      return completionMessage;
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 세션의 모든 메시지를 가져옵니다.
  Future<List<Message>> getSessionMessages(String sessionId) async {
    try {
      await _getUserIdAndAuthenticate();
      return await _backendRepository.getMessagesBySessionId(sessionId);
    } catch (e) {
      debugPrint('세션 메시지 조회 오류: $e');
      rethrow;
    }
  }

  /// 대화 세션을 종료합니다.
  ///
  /// [sessionId] 종료할 세션의 ID
  Future<Session> endSession(String sessionId) async {
    try {      
      await _getUserIdAndAuthenticate();
      final session = await _backendRepository.postSessionFinish(sessionId);
      
      debugPrint('세션이 종료되었습니다: $sessionId');
      return session;
    } catch (e) {
      debugPrint('세션 종료 오류: $e');
      rethrow;
    }
  }
  
  /// 사용자의 모든 세션을 가져옵니다.
  Future<List<Session>> getUserSessions() async {
    try {
      final userId = await _getUserIdAndAuthenticate();
      
      return await _backendRepository.getSessionsByUserId(userId);
    } catch (e) {
      debugPrint('사용자 세션 조회 오류: $e');
      rethrow;
    }
  }
}