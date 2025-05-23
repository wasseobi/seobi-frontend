import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpHelper {
  final String baseUrl;
  late final Map<String, String> defaultHeaders;
  String? _authToken;

  HttpHelper(this.baseUrl) {
    defaultHeaders = {
      'Content-Type': 'application/json',
      'X-API-Key': dotenv.get('X_API_KEY'),
    };
  }

  /// 인증 토큰을 설정합니다.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// 현재 요청 헤더에 인증 토큰을 포함하여 반환합니다.
  Map<String, String> _getHeaders([Map<String, String>? additionalHeaders]) {
    final headers = {...defaultHeaders};
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  Uri _buildUri(String path) => Uri.parse('$baseUrl$path');
  /// GET 요청을 보내고 JSON 응답을 받습니다.
  Future<T> get<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(
        _buildUri(path),
        headers: _getHeaders(headers),
      );

      debugPrint('GET $path - 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return fromJson(json);
      } else {
        throw Exception('status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('GET $path - 오류 발생: $error');
      rethrow;
    }
  }
  /// GET 요청을 보내고 JSON 배열 응답을 받습니다.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(
        _buildUri(path),
        headers: _getHeaders(headers),
      );

      debugPrint('GET $path - 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('GET $path - 오류 발생: $error');
      rethrow;
    }
  }
  /// POST 요청을 보내고 JSON 응답을 받습니다.
  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
    int expectedStatus = 201,
  }) async {
    try {
      final response = await http.post(
        _buildUri(path),
        headers: _getHeaders(headers),
        body: jsonEncode(body),
      );

      debugPrint('POST $path - 상태 코드: ${response.statusCode}');

      if (response.statusCode == expectedStatus) {
        final json = jsonDecode(response.body);
        return fromJson(json);
      } else {
        throw Exception('status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('POST $path - 오류 발생: $error');
      rethrow;
    }
  }
  /// PUT 요청을 보내고 JSON 응답을 받습니다.
  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.put(
        _buildUri(path),
        headers: _getHeaders(headers),
        body: jsonEncode(body),
      );

      debugPrint('PUT $path - 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return fromJson(json);
      } else {
        throw Exception('status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('PUT $path - 오류 발생: $error');
      rethrow;
    }
  }
  /// DELETE 요청을 보냅니다.
  Future<void> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.delete(
        _buildUri(path),
        headers: _getHeaders(headers),
      );

      debugPrint('DELETE $path - 상태 코드: ${response.statusCode}');

      if (response.statusCode != 204) {
        throw Exception('status ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (error) {
      debugPrint('DELETE $path - 오류 발생: $error');
      rethrow;
    }
  }
}
