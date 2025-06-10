import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule/schedule.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';

class ScheduleService {
  final String baseUrl = dotenv.env['REMOTE_BACKEND_URL'] ?? '';

  Future<List<Schedule>> fetchSchedules(String userId) async {
    final url = Uri.parse('$baseUrl/schedule/$userId');
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
      return data.map((e) => Schedule.fromJson(e)).toList();
    } else {
      throw Exception('일정 불러오기 실패: \\${response.statusCode}');
    }
  }
}
