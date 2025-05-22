import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/messages.dart';
import '../models/user.dart';
import '../models/session.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // 사용자 생성
  Future<User> createUser({
    required String username,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/users/');
    print('Creating user at: $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        '사용자 생성에 실패했습니다. 상태 코드: ${response.statusCode}, 응답: ${response.body}',
      );
    }
  }

  // 세션 생성
  Future<Session> createSession({
    required String userId,
    String? title,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': title ?? '음성 인식 세션',
        'description': description ?? '음성 인식을 통한 대화 세션',
      }),
    );

    if (response.statusCode == 201) {
      return Session.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('세션 생성에 실패했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  // 메시지 생성
  Future<Message> createMessage({
    required String sessionId,
    required String userId,
    required String content,
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/session/$sessionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'user_id': userId,
        'content': content,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        '메시지 생성에 실패했습니다. 상태 코드: ${response.statusCode}, 응답: ${response.body}',
      );
    }
  }
}
