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

        try {
          final Map<String, dynamic> jsonData = jsonDecode(line);
          debugPrint('[HttpHelper] 파싱된 청크: $jsonData');
          yield jsonData;
        } catch (e) {
          debugPrint('[HttpHelper] 청크 파싱 오류: $e');
          continue;
        }
      }
    }

    // 버퍼에 남은 데이터 처리
    if (buffer.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(buffer);
        debugPrint('[HttpHelper] 마지막 청크 파싱: $jsonData');
        yield jsonData;
      } catch (e) {
        debugPrint('[HttpHelper] 마지막 청크 파싱 오류: $e');
      }
    }
  }

  /// POST 요청을 보내고 스트림 응답을 받습니다.
  Stream<Map<String, dynamic>> postStream(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async* {
    try {
      final uri = _buildUri(path);
      final requestHeaders = {
        ..._getHeaders(headers),
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      };

      debugPrint('[HttpHelper] 스트리밍 요청 시작: $uri');
      debugPrint('[HttpHelper] 헤더: $requestHeaders');
      debugPrint('[HttpHelper] 요청 본문: $body');

      final request = http.Request('POST', uri);
      request.headers.addAll(requestHeaders);
      request.body = jsonEncode(body);

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      debugPrint('[HttpHelper] 스트림 연결 성공');
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        debugPrint('[HttpHelper] 데이터 수신: $chunk');

        // SSE 형식 처리 (data: {...} 형태)
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final Map<String, dynamic> data = jsonDecode(jsonStr);
              debugPrint('[HttpHelper] 파싱된 데이터: $data');

              // 청크 타입별 처리
              final type = data['type'] as String?;
              if (type == 'chunk' && data['content'] != null) {
                yield {'type': 'chunk', 'content': data['content']};
              } else if (type == 'end') {
                yield {'type': 'end'};
              } else if (type == 'answer' && data['answer'] != null) {
                yield {'type': 'answer', 'answer': data['answer']};
              }
            } catch (e) {
              debugPrint('[HttpHelper] JSON 파싱 오류: $e');
              continue;
            }
          }
        }
      }

      // 버퍼에 남은 데이터 처리
      if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
        final jsonStr = buffer.substring(6).trim();
        if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
          try {
            final Map<String, dynamic> data = jsonDecode(jsonStr);
            if (data['type'] == 'chunk' && data['content'] != null) {
              yield {'type': 'chunk', 'content': data['content']};
            }
          } catch (e) {
            debugPrint('[HttpHelper] 최종 청크 파싱 오류: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[HttpHelper] 스트리밍 오류: $e');
      rethrow;
    }
  }
}
