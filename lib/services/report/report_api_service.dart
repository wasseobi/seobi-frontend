import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ReportApiService {
  // 환경변수를 기반으로 백엔드 URL 결정
  static String get baseUrl {
    final useRemoteBackend = dotenv.env['USE_REMOTE_BACKEND'] == 'true';

    if (useRemoteBackend) {
      return dotenv.env['REMOTE_BACKEND_URL'] ??
          'https://seobi-backend-edfygbdvh8cfbvev.koreacentral-01.azurewebsites.net/';
    } else {
      // 로컬 백엔드 사용 시 플랫폼에 따라 URL 선택
      if (Platform.isAndroid) {
        return dotenv.env['LOCAL_BACKEND_URL_ANDROID'] ??
            'http://10.0.2.2:5000';
      } else {
        return dotenv.env['LOCAL_BACKEND_URL_DEFAULT'] ??
            'http://127.0.0.1:5000';
      }
    }
  }

  // 공통 헤더 생성
  Map<String, String> _getHeaders({
    required String userId,
    String? authToken,
    String timezone = 'Asia/Seoul',
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'user-id': userId,
      'timezone': timezone,
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // 데일리 리포트 조회
  Future<List<Map<String, dynamic>>> getDailyReports({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/report/d'),
        headers: _getHeaders(userId: userId, authToken: authToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load daily reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching daily reports: $e');
    }
  }

  // 위클리 리포트 조회
  Future<List<Map<String, dynamic>>> getWeeklyReports({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/report/w'),
        headers: _getHeaders(userId: userId, authToken: authToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load weekly reports: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching weekly reports: $e');
    }
  }

  // 전체 리포트 조회
  Future<List<Map<String, dynamic>>> getAllReports({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/report/$userId'),
        headers: _getHeaders(userId: userId, authToken: authToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load all reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all reports: $e');
    }
  }

  // 데일리 리포트 생성
  Future<Map<String, dynamic>> createDailyReport({
    required String userId,
    String? authToken,
  }) async {
    try {
      debugPrint('📤 Daily Report 요청 시작');
      debugPrint('📤 URL: $baseUrl/report/d');
      debugPrint(
        '📤 Headers: ${_getHeaders(userId: userId, authToken: authToken)}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/report/d'),
        headers: _getHeaders(userId: userId, authToken: authToken),
      );

      debugPrint('📥 Daily Response Status: ${response.statusCode}');
      debugPrint('📥 Daily Response Headers: ${response.headers}');
      debugPrint('📥 Daily Response Body Length: ${response.body.length}');
      debugPrint(
        '📥 Daily Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Daily Report JSON 파싱 성공: ${result.keys}');
        return result;
      } else {
        debugPrint('❌ Daily Report 상태 코드 오류: ${response.statusCode}');
        throw Exception(
          'Failed to create daily report: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('💥 Daily Report 생성 상세 에러: $e');
      rethrow;
    }
  }

  // 위클리 리포트 생성
  Future<Map<String, dynamic>> createWeeklyReport({
    required String userId,
    String? authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/report/w'),
        headers: _getHeaders(userId: userId, authToken: authToken),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to create weekly report: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating weekly report: $e');
    }
  }
}
