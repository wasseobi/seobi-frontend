import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'local_storage_service.dart';

class AuthTokenService {
  static final AuthTokenService _instance = AuthTokenService._internal();
  factory AuthTokenService() => _instance;

  AuthTokenService._internal();

  final LocalStorageService _storage = LocalStorageService();

  String get _baseUrl {
    if (kIsWeb || !Platform.isAndroid) {
      return 'http://127.0.0.1:5000'; // 웹 또는 iOS
    } else {
      return 'http://10.0.2.2:5000'; // Android 에뮬레이터
    }
  }

  Future<Map<String, dynamic>> requestJwtToken(String idToken) async {
    try {
      debugPrint('JWT 토큰 요청 시작: $_baseUrl/users/login');
      final response = await http.post(
        Uri.parse('$_baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      debugPrint('응답 상태 코드: ${response.statusCode}');
      debugPrint('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.setString('access_token', data['access_token']);
        return {'success': true, 'message': 'JWT 토큰이 성공적으로 저장되었습니다.'};
      } else {
        return {
          'success': false,
          'message':
              'JWT 토큰 요청 실패: ${response.statusCode} ${response.reasonPhrase}',
        };
      }
    } catch (error) {
      debugPrint('JWT 토큰 요청 중 오류 발생: $error');
      return {'success': false, 'message': 'JWT 토큰 요청 중 오류가 발생했습니다: $error'};
    }
  }

  Future<String?> getAccessToken() async {
    return _storage.getString('access_token');
  }

  Future<void> clearToken() async {
    await _storage.remove('access_token');
  }
}
