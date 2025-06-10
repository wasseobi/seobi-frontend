import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';
// import 'models/auto_task.dart'; // 중복 방지: repositories/backend/models/auto_task.dart만 사용
import '../../ui/components/box/tasks/task_card_model.dart';
import '../../repositories/backend/backend_repository.dart';
import '../../repositories/backend/models/auto_task.dart';

class AutoTaskService {
  final String baseUrl = dotenv.env['REMOTE_BACKEND_URL'] ?? '';
  final BackendRepository _repo = BackendRepository();

  Future<List<AutoTask>> fetchActiveTasks(
    String userId, {
    String? accessToken,
  }) async {
    return await _repo.getActiveAutoTasksByUserId(
      userId,
      accessToken: accessToken,
    );
  }

  Future<List<AutoTask>> fetchInactiveTasks(
    String userId, {
    String? accessToken,
  }) async {
    return await _repo.getInactiveAutoTasksByUserId(
      userId,
      accessToken: accessToken,
    );
  }

  Future<void> updateActiveStatus(
    String id,
    bool active, {
    String? accessToken,
  }) async {
    await _repo.updateAutoTaskActiveStatus(
      id,
      active,
      accessToken: accessToken,
    );
  }

  /// AutoTask를 TaskCardModel로 변환 (비즈니스 로직 포함)
  static TaskCardModel toTaskCardModel(AutoTask autoTask) {
    // 남은 시간(meta.remaining_time) 파싱
    String remaining = autoTask.meta?['remaining_time']?.toString() ?? '-';
    // 반복/스케줄 정보 (cron -> 자연어 변환)
    String schedule = cronToKorean(autoTask.repeat ?? '');
    // 활성화 상태
    bool isEnabled = autoTask.active;
    // 액션 리스트 (task_list)
    List<Map<String, String>> actions = [];
    if (autoTask.taskList is List) {
      actions =
          (autoTask.taskList as List)
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v.toString())))
              .toList();
    }
    // 진행률(progress) 계산: 남은 시간 기반(예시)
    double progress = _calcProgress(remaining);
    return TaskCardModel(
      id: autoTask.id,
      title: autoTask.title,
      remainingTime: _formatRemainingTime(remaining),
      schedule: schedule,
      isEnabled: isEnabled,
      actions: actions,
      progress: progress,
    );
  }

  /// cron 문자열을 한국어로 변환
  static String cronToKorean(String cron) {
    // 요일 매핑
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    final parts = cron.split(' ');
    if (parts.length == 5) {
      final minute = parts[0];
      final hour = parts[1];
      final dayOfMonth = parts[2];
      final month = parts[3];
      final dayOfWeek = parts[4];

      // 시간 변환
      String minuteStr = minute.padLeft(2, '0');
      int hourInt = int.tryParse(hour) ?? 0;
      String ampm = hourInt < 12 ? '오전' : '오후';
      int displayHour = hourInt % 12 == 0 ? 12 : hourInt % 12;
      if (hourInt == 0 && minute == '0') {
        ampm = '';
        displayHour = 0;
        return '매일 자정';
      } else if (hourInt == 12 && minute == '0') {
        ampm = '';
        displayHour = 12;
        return '매일 정오';
      }

      // 매주 ~요일 ~시
      if (dayOfWeek != '*' && int.tryParse(dayOfWeek) != null) {
        final dayIdx = int.parse(dayOfWeek);
        if (dayIdx >= 0 && dayIdx <= 6) {
          return '매주 ${days[dayIdx]}요일 $ampm $displayHour시${minute != '0' ? ' $minuteStr분' : ''}';
        }
      }
      // 매달 n일 ~시
      if (dayOfMonth != '*' && int.tryParse(dayOfMonth) != null) {
        return '매달 $dayOfMonth일 $ampm $displayHour시${minute != '0' ? ' $minuteStr분' : ''}';
      }
      // 매일 ~시
      if (dayOfWeek == '*' && dayOfMonth == '*') {
        return '매일 $ampm $displayHour시${minute != '0' ? ' $minuteStr분' : ''}';
      }
    }
    if (cron.isEmpty) return '';
    // fallback
    return cron;
  }

  static double _calcProgress(String remaining) {
    // 예시: 1:00:00 -> 0.5, 0:00:00 -> 1.0 (완료)
    if (remaining == '-' || remaining.isEmpty) return 0.0;
    final parts = remaining.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      final total = h * 3600 + m * 60 + s;
      // 예시: 2시간(7200초) 기준, 남은 시간/7200으로 progress 계산
      const maxSeconds = 7200.0;
      return 1.0 - (total / maxSeconds).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  static String _formatRemainingTime(String raw) {
    if (raw == '-' || raw.isEmpty) return '-';
    final parts = raw.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return '${h}시간 ${m}분 ${s}초 남음';
    }
    return raw;
  }
}
