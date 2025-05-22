import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'i_backend_repository.dart';

class StubBackendRepository implements IBackendRepository {
  static final StubBackendRepository _instance = StubBackendRepository._internal();
  factory StubBackendRepository() => _instance;

  final Random _random = Random();
  
  // 실제 서비스와 비슷한 네트워크 지연을 시뮬레이션하기 위한 설정
  static const minDelay = Duration(milliseconds: 100);
  static const maxAdditionalDelay = Duration(milliseconds: 300);

  StubBackendRepository._internal();

  @override
  String get baseUrl => 'http://localhost:5000';
  /// 실제 서비스와 비슷한 네트워크 지연을 시뮬레이션합니다.
  Future<void> _simulateNetworkDelay() async {
    debugPrint('[StubBackend] 네트워크 지연 시뮬레이션 시작');
    final additionalMs = _random.nextInt(maxAdditionalDelay.inMilliseconds);
    final totalDelay = minDelay + Duration(milliseconds: additionalMs);
    debugPrint('[StubBackend] 예상 지연 시간: ${totalDelay.inMilliseconds}ms');
    
    await Future.delayed(totalDelay);

    // 10% 확률로 네트워크 오류 발생
    if (_random.nextDouble() < 0.1) {
      debugPrint('[StubBackend] 네트워크 오류 시뮬레이션');
      throw Exception('네트워크 오류가 발생했습니다.');
    }
    debugPrint('[StubBackend] 네트워크 지연 시뮬레이션 완료');
  }

  @override
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken) async {
    debugPrint('[StubBackend] 로그인 요청');
    debugPrint('[StubBackend] 입력 - googleIdToken: ${googleIdToken.substring(0, min(10, googleIdToken.length))}...');
    
    await _simulateNetworkDelay();
    
    // googleIdToken이 비어있으면 오류 발생
    if (googleIdToken.isEmpty) {
      debugPrint('[StubBackend] 오류 - 유효하지 않은 토큰');
      throw Exception('유효하지 않은 Google ID 토큰입니다.');
    }    // 실제와 유사한 응답 데이터 반환
    final response = {
      'user_id': 'user_${_random.nextInt(99999)}',
      'email': '${_generateRandomString(8)}@gmail.com',
      'name': '테스트 사용자 ${_random.nextInt(999)}',
      'profile_image': 'https://picsum.photos/200',  // 실제 이미지 URL 반환
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${_generateRandomString(32)}',
      'refresh_token': 'rt_${_generateRandomString(32)}',
      'expires_in': 3600,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    debugPrint('[StubBackend] 출력 - response: $response');
    return response;
  }

  /// 랜덤 문자열을 생성합니다.
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }
}
