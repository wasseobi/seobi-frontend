import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

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
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
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
        return jsonList
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
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
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
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
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      debugPrint('PUT $path - 오류 발생: $error');
      rethrow;
    }
  }

  /// DELETE 요청을 보냅니다.
  Future<void> delete(String path, {Map<String, String>? headers}) async {
    try {
      final response = await http.delete(
        _buildUri(path),
        headers: _getHeaders(headers),
      );

      debugPrint('DELETE $path - 상태 코드: ${response.statusCode}');

      if (response.statusCode != 204) {
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      debugPrint('DELETE $path - 오류 발생: $error');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> handleStreamingResponse(
    Stream<List<int>> byteStream,
  ) async* {
    String buffer = '';

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer += chunk;
      debugPrint('[HttpHelper] 수신된 청크 데이터: $chunk');

      // 각 줄별로 처리
      while (buffer.contains('\n')) {
        final index = buffer.indexOf('\n');
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);

        if (line.isEmpty) continue;

        // SSE 형식 처리
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6); // 'data: ' 제거
          if (jsonStr == '[DONE]') continue; // 스트림 종료 신호 무시

          try {
            final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
            debugPrint('[HttpHelper] 파싱된 청크: $jsonData');
            yield jsonData;
          } catch (e) {
            debugPrint('[HttpHelper] 청크 파싱 오류: $e');
            continue;
          }
        }
      }
    }

    // 버퍼에 남은 데이터 처리
    if (buffer.isNotEmpty) {
      if (buffer.startsWith('data: ')) {
        final jsonStr = buffer.substring(6);
        if (jsonStr != '[DONE]') {
          try {
            final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
            debugPrint('[HttpHelper] 마지막 청크 파싱: $jsonData');
            yield jsonData;
          } catch (e) {
            debugPrint('[HttpHelper] 마지막 청크 파싱 오류: $e');
          }
        }
      }
    }
  }

  /// 스트리밍 POST 요청을 보내고 응답을 스트림으로 받습니다.
  Stream<Map<String, dynamic>> postStream(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async* {
    try {
      final client = http.Client();
      final request = http.Request('POST', _buildUri(path));

      // 타임아웃 설정
      const timeout = Duration(minutes: 2);

      request.headers.addAll(
        _getHeaders({
          ...?headers,
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        }),
      );

      request.body = jsonEncode(body);

      debugPrint('[HttpHelper] 스트리밍 요청 시작: ${request.url}');
      debugPrint('[HttpHelper] 헤더: ${request.headers}');
      debugPrint('[HttpHelper] 요청 본문: $body');

      final response = await client
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('스트리밍 요청이 $timeout 후 시간 초과되었습니다.');
            },
          );

      if (response.statusCode == 200) {
        debugPrint('[HttpHelper] 스트림 연결 성공');

        final streamWithTimeout = response.stream.timeout(
          timeout,
          onTimeout:
              (sink) => sink.addError(
                TimeoutException('스트림 데이터 수신이 $timeout 후 시간 초과되었습니다.'),
              ),
        );

        await for (final chunk in handleStreamingResponse(streamWithTimeout)) {
          yield chunk;
        }
      } else {
        throw Exception('status ${response.statusCode}: Connection failed');
      }
    } catch (error) {
      debugPrint('[HttpHelper] 스트리밍 요청 오류: $error');
      rethrow;
    }
  }
}
