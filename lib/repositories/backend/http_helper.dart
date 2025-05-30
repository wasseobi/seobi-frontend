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
    String incompleteJson = ''; // 불완전한 JSON을 저장할 버퍼

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
          final jsonStr = line.substring(6).trim(); // 'data: ' 제거 및 공백 정리
          if (jsonStr == '[DONE]') continue; // 스트림 종료 신호 무시

          // 이전에 불완전했던 JSON과 합치기
          String fullJsonStr = incompleteJson + jsonStr;

          try {
            final Map<String, dynamic> jsonData = jsonDecode(fullJsonStr);
            debugPrint('[HttpHelper] 파싱된 청크: $jsonData');
            incompleteJson = ''; // 성공적으로 파싱되면 불완전 버퍼 초기화

            // 내용이 불완전한 단어로 끝나는지 체크
            if (jsonData['type'] == 'chunk') {
              final content = jsonData['content'] as String?;
              if (content != null && content.isNotEmpty) {
                // 단어가 중간에 끊어졌는지 확인 (영어나 한글이 불완전)
                final lastChar = content[content.length - 1];
                final isIncompleteWord = _isIncompleteWord(content);

                if (!isIncompleteWord) {
                  yield jsonData;
                } else {
                  // 불완전한 단어인 경우 다음 청크와 합쳐질 때까지 대기
                  debugPrint('[HttpHelper] 불완전한 단어 감지, 다음 청크 대기: $content');
                  // 임시로 저장하지 말고 바로 전송 (TTS에서 처리)
                  yield jsonData;
                }
              } else {
                yield jsonData;
              }
            } else {
              yield jsonData;
            }
          } catch (e) {
            debugPrint('[HttpHelper] 청크 파싱 오류: $e - JSON: $fullJsonStr');

            // JSON 파싱 실패 시 불완전한 JSON으로 간주하고 다음 청크와 합치기
            if (fullJsonStr.length < 10000) {
              // 버퍼 크기 제한
              incompleteJson = fullJsonStr;
              debugPrint('[HttpHelper] 불완전한 JSON으로 판단, 다음 청크와 합치기 위해 저장');
            } else {
              // 너무 큰 데이터는 버리고 다시 시작
              incompleteJson = '';
              debugPrint('[HttpHelper] JSON 버퍼가 너무 커서 초기화');
            }
            continue;
          }
        } else if (line.trim().isNotEmpty) {
          // data: 없이 들어오는 JSON 처리 (일부 서버에서 발생)
          String fullJsonStr = incompleteJson + line;

          try {
            final Map<String, dynamic> jsonData = jsonDecode(fullJsonStr);
            debugPrint('[HttpHelper] 직접 JSON 파싱: $jsonData');
            incompleteJson = ''; // 성공적으로 파싱되면 불완전 버퍼 초기화
            yield jsonData;
          } catch (e) {
            debugPrint('[HttpHelper] 직접 JSON 파싱 실패: $e - 라인: $fullJsonStr');

            // JSON 파싱 실패 시 불완전한 JSON으로 간주
            if (fullJsonStr.length < 10000) {
              // 버퍼 크기 제한
              incompleteJson = fullJsonStr;
            } else {
              incompleteJson = '';
            }
            continue;
          }
        }
      }
    }

    // 버퍼에 남은 데이터 처리
    if (buffer.trim().isNotEmpty) {
      final remainingData = buffer.trim();

      if (remainingData.startsWith('data: ')) {
        final jsonStr = remainingData.substring(6).trim();
        if (jsonStr != '[DONE]' && jsonStr.isNotEmpty) {
          String fullJsonStr = incompleteJson + jsonStr;

          try {
            final Map<String, dynamic> jsonData = jsonDecode(fullJsonStr);
            debugPrint('[HttpHelper] 마지막 청크 파싱: $jsonData');
            yield jsonData;
          } catch (e) {
            debugPrint('[HttpHelper] 마지막 청크 파싱 오류: $e - JSON: $fullJsonStr');
          }
        }
      } else if (remainingData.isNotEmpty) {
        // data: 없이 남은 JSON 처리
        String fullJsonStr = incompleteJson + remainingData;

        try {
          final Map<String, dynamic> jsonData = jsonDecode(fullJsonStr);
          debugPrint('[HttpHelper] 마지막 직접 JSON 파싱: $jsonData');
          yield jsonData;
        } catch (e) {
          debugPrint('[HttpHelper] 마지막 직접 JSON 파싱 실패: $e - 데이터: $fullJsonStr');
        }
      }
    }
  }

  /// 단어가 불완전한지 확인 (백엔드에서 단어 중간에 끊어서 전송되는 경우 감지)
  bool _isIncompleteWord(String content) {
    if (content.isEmpty) return false;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    // 영어 단어가 불완전한지 확인 (자음으로만 끝나거나 너무 짧은 경우)
    final englishPattern = RegExp(r'[A-Za-z]+$');
    final match = englishPattern.firstMatch(trimmed);
    if (match != null) {
      final word = match.group(0)!;
      // 알려진 불완전 패턴들
      if (word == 'Healt' ||
          word == 'iPhon' ||
          word == 'Appl' ||
          word == 'Watch' && !trimmed.endsWith('Watch ')) {
        return true;
      }

      // 일반적으로 3글자 이하의 영어 단어는 불완전할 가능성이 높음 (완성된 단어 제외)
      if (word.length <= 3 &&
          ![
            'app',
            'get',
            'use',
            'run',
            'set',
            'new',
            'old',
            'big',
            'top',
          ].contains(word.toLowerCase())) {
        return true;
      }
    }

    // 한글의 경우는 음절이 완성되지 않은 경우는 거의 없으므로 검사하지 않음

    return false;
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
