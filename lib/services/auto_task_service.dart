import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_service.dart';
import 'models/auto_task.dart';

class AutoTaskService {
  final String baseUrl = dotenv.env['REMOTE_BACKEND_URL'] ?? '';

  Future<List<AutoTask>> fetchActiveTasks(String userId) async {
    final url = Uri.parse('$baseUrl/autotask/$userId/active');
    final accessToken = await AuthService().accessToken;
    final response = await http.get(
      url,
      headers:
          accessToken != null && accessToken.isNotEmpty
              ? {'Authorization': 'Bearer $accessToken'}
              : {},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => AutoTask.fromJson(e)).toList();
    } else {
      throw Exception('자동업무(활성) 불러오기 실패: \\${response.statusCode}');
    }
  }

  Future<List<AutoTask>> fetchInactiveTasks(String userId) async {
    final url = Uri.parse('$baseUrl/autotask/$userId/inactive');
    final accessToken = await AuthService().accessToken;
    final response = await http.get(
      url,
      headers:
          accessToken != null && accessToken.isNotEmpty
              ? {'Authorization': 'Bearer $accessToken'}
              : {},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => AutoTask.fromJson(e)).toList();
    } else {
      throw Exception('자동업무(비활성) 불러오기 실패: \\${response.statusCode}');
    }
  }

  Future<void> updateActiveStatus(String id, bool active) async {
    final url = Uri.parse('$baseUrl/autotask/$id/active?active=$active');
    final accessToken = await AuthService().accessToken;
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('자동업무 활성/비활성 변경 실패: \\${response.statusCode}');
    }
  }
}
