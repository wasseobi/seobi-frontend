import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HttpHelper {
  final String baseUrl;
  late final Map<String, String> defaultHeaders;
  String? _authToken;

  HttpHelper(this.baseUrl) {
    defaultHeaders = {
      'Content-Type': 'application/json',
      'Connection': 'Keep-Alive',
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
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('GET $path - 재시도 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        final response = await http
            .get(_buildUri(path), headers: _getHeaders(headers))
            .timeout(timeout);

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
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 재시도 가능한 오류인지 확인
        if (_isRetryableError(error) && attempt < maxRetries) {
          debugPrint('GET $path - 재시도 가능한 오류 감지: $error');
          continue;
        }

        // 구체적인 오류 처리
        if (error.toString().contains('TimeoutException') ||
            error.toString().contains('Connection timed out')) {
          debugPrint('GET $path - 연결 시간 초과: 서버가 응답하지 않습니다');
          throw Exception('서버 연결 시간 초과 - 백엔드 서버가 실행 중인지 확인해주세요');
        }

        if (error.toString().contains(
              'Connection closed while receiving data',
            ) ||
            error.toString().contains('ClientException')) {
          debugPrint('GET $path - 연결 끊김: 데이터 수신 중 연결이 끊어졌습니다');
          throw Exception('서버 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        debugPrint('GET $path - 오류 발생: $error');
        rethrow;
      }
    }

    throw lastException ?? Exception('알 수 없는 오류가 발생했습니다');
  }

  /// 재시도 가능한 오류인지 확인
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection closed') ||
        errorString.contains('clientexception') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection reset') ||
        errorString.contains('broken pipe');
  }

  /// GET 요청을 보내고 JSON 배열 응답을 받습니다.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('GET $path - 재시도 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        final response = await http
            .get(_buildUri(path), headers: _getHeaders(headers))
            .timeout(timeout);

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
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 재시도 가능한 오류인지 확인
        if (_isRetryableError(error) && attempt < maxRetries) {
          debugPrint('GET $path - 재시도 가능한 오류 감지: $error');
          continue;
        }

        // 구체적인 오류 처리
        if (error.toString().contains('TimeoutException') ||
            error.toString().contains('Connection timed out')) {
          debugPrint('GET $path - 연결 시간 초과: 서버가 응답하지 않습니다');
          throw Exception('서버 연결 시간 초과 - 백엔드 서버가 실행 중인지 확인해주세요');
        }

        if (error.toString().contains(
              'Connection closed while receiving data',
            ) ||
            error.toString().contains('ClientException')) {
          debugPrint('GET $path - 연결 끊김: 데이터 수신 중 연결이 끊어졌습니다');
          throw Exception('서버 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        debugPrint('GET $path - 오류 발생: $error');
        rethrow;
      }
    }

    throw lastException ?? Exception('알 수 없는 오류가 발생했습니다');
  }

  /// POST 요청을 보내고 JSON 응답을 받습니다.
  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
    int expectedStatus = 201,
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('POST $path - 재시도 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        final response = await http
            .post(
              _buildUri(path),
              headers: _getHeaders(headers),
              body: jsonEncode(body),
            )
            .timeout(timeout);

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
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 재시도 가능한 오류인지 확인
        if (_isRetryableError(error) && attempt < maxRetries) {
          debugPrint('POST $path - 재시도 가능한 오류 감지: $error');
          continue;
        }

        // 구체적인 오류 처리
        if (error.toString().contains('TimeoutException') ||
            error.toString().contains('Connection timed out')) {
          debugPrint('POST $path - 연결 시간 초과: 서버가 응답하지 않습니다');
          throw Exception('서버 연결 시간 초과 - 백엔드 서버가 실행 중인지 확인해주세요');
        }

        if (error.toString().contains(
              'Connection closed while receiving data',
            ) ||
            error.toString().contains('ClientException')) {
          debugPrint('POST $path - 연결 끊김: 데이터 수신 중 연결이 끊어졌습니다');
          throw Exception('서버 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        debugPrint('POST $path - 오류 발생: $error');
        rethrow;
      }
    }

    throw lastException ?? Exception('알 수 없는 오류가 발생했습니다');
  }

  /// PUT 요청을 보내고 JSON 응답을 받습니다.
  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, String>? headers,
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('PUT $path - 재시도 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

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
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 재시도 가능한 오류인지 확인
        if (_isRetryableError(error) && attempt < maxRetries) {
          debugPrint('PUT $path - 재시도 가능한 오류 감지: $error');
          continue;
        }

        // 구체적인 오류 처리
        if (error.toString().contains(
              'Connection closed while receiving data',
            ) ||
            error.toString().contains('ClientException')) {
          debugPrint('PUT $path - 연결 끊김: 데이터 수신 중 연결이 끊어졌습니다');
          throw Exception('서버 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        debugPrint('PUT $path - 오류 발생: $error');
        rethrow;
      }
    }

    throw lastException ?? Exception('알 수 없는 오류가 발생했습니다');
  }

  /// DELETE 요청을 보냅니다.
  Future<void> delete(
    String path, {
    Map<String, String>? headers,
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('DELETE $path - 재시도 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

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
        return; // 성공 시 바로 반환
      } catch (error) {
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 재시도 가능한 오류인지 확인
        if (_isRetryableError(error) && attempt < maxRetries) {
          debugPrint('DELETE $path - 재시도 가능한 오류 감지: $error');
          continue;
        }

        // 구체적인 오류 처리
        if (error.toString().contains(
              'Connection closed while receiving data',
            ) ||
            error.toString().contains('ClientException')) {
          debugPrint('DELETE $path - 연결 끊김: 데이터 수신 중 연결이 끊어졌습니다');
          throw Exception('서버 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        debugPrint('DELETE $path - 오류 발생: $error');
        rethrow;
      }
    }

    throw lastException ?? Exception('알 수 없는 오류가 발생했습니다');
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

  /// 스트림 재시도 가능한 오류인지 확인
  bool _isRetryableStreamError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection closed') ||
        errorString.contains('connection reset') ||
        errorString.contains('broken pipe') ||
        (errorString.contains('clientexception') &&
            !errorString.contains('bad certificate'));
  }

  /// POST SSE 요청을 보내고 들어오는 청크를 JSON(Map) 형태로 반환합니다.
  Stream<dynamic> postSse(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async* {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('[HttpHelper] SSE 재연결 시도 $attempt/$maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }

        final uri = _buildUri(path);
        final requestHeaders = {
          ..._getHeaders(headers),
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        };

        debugPrint('[HttpHelper] POST SSE 요청 시작: $uri');
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

        debugPrint('[HttpHelper] POST SSE 연결 성공');
        String buffer = '';

        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          debugPrint('[HttpHelper] 수신된 청크: $chunk');

          // 각 줄별로 처리
          while (buffer.contains('\n')) {
            final index = buffer.indexOf('\n');
            final line = buffer.substring(0, index).trim();
            buffer = buffer.substring(index + 1);

            if (line.isEmpty) continue;

            // SSE data: 접두사 제거
            String jsonStr = line;
            if (line.startsWith('data: ')) {
              jsonStr = line.substring(6).trim();
            }

            if (jsonStr.isEmpty) {
              continue;
            }

            if (jsonStr == '[DONE]') {
              debugPrint('[HttpHelper] SSE 스트림 종료 신호 수신');
              yield {'type': 'done'};
              continue;
            }

            try {
              final dynamic jsonData = jsonDecode(jsonStr);
              debugPrint('[HttpHelper] 파싱된 청크: $jsonData');
              yield jsonData;
            } catch (e) {
              debugPrint('[HttpHelper] 청크 파싱 오류: $e, 원본: $jsonStr');
              continue;
            }
          }
        }

        // 버퍼에 남은 데이터 처리
        if (buffer.isNotEmpty) {
          String jsonStr = buffer.trim();
          if (jsonStr.startsWith('data: ')) {
            jsonStr = jsonStr.substring(6).trim();
          }

          if (jsonStr.isEmpty) {
            continue;
          }

          if (jsonStr == '[DONE]') {
            debugPrint('[HttpHelper] SSE 스트림 종료 신호 수신');
            yield {'type': 'done'};
            continue;
          }

          if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
            try {
              final dynamic jsonData = jsonDecode(jsonStr);
              debugPrint('[HttpHelper] 마지막 청크 파싱: $jsonData');
              yield jsonData;
            } catch (e) {
              debugPrint('[HttpHelper] 마지막 청크 파싱 오류: $e');
            }
          }
        }

        // 성공적으로 완료되면 반복문을 빠져나감
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // 재시도 가능한 SSE 오류인지 확인
        if (_isRetryableStreamError(e) && attempt < maxRetries) {
          debugPrint('[HttpHelper] SSE 재시도 가능한 오류: $e');
          continue;
        }

        debugPrint('[HttpHelper] POST SSE 오류: $e');

        // 연결 끊김 오류에 대한 구체적인 처리
        if (e.toString().contains('Connection closed') ||
            e.toString().contains('ClientException')) {
          throw Exception('SSE 연결이 끊어졌습니다 - 네트워크 상태를 확인해주세요');
        }

        rethrow;
      }
    }

    throw lastException ?? Exception('SSE 연결에 실패했습니다');
  }
}
