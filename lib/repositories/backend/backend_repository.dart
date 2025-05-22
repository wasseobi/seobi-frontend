import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:convert';

import 'i_backend_repository.dart';

class BackendRepository implements IBackendRepository {
  static final BackendRepository _instance = BackendRepository._internal();
  factory BackendRepository() => _instance;

  BackendRepository._internal();
  @override
  String get baseUrl {
    // Todo: 서버 주소를 올바르게 수정
    
    // 실제 서비스에서 사용하는 경우
    // return 'https://your-production-server.com'; // 실제 서버 주소

    // 개발 단계에서 로컬 서버를 쓰는 경우
    if (kIsWeb || !Platform.isAndroid) {
      return 'http://127.0.0.1:5000'; // 웹 또는 iOS
    } else {
      return 'http://10.0.2.2:5000'; // Android 에뮬레이터
    }
  }

  @override
  Future<Map<String, dynamic>> postUserLogin(String googleIdToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': googleIdToken}),
      );

      debugPrint('응답 상태 코드: ${response.statusCode}');
      debugPrint('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      debugPrint('로그인 요청 중 오류 발생: $error');
      throw Exception('로그인 요청 중 오류가 발생했습니다: $error');
    }
  }
}
