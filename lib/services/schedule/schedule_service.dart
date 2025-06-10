import '../../repositories/backend/backend_repository.dart';
import '../auth/auth_service.dart';
import '../../repositories/backend/models/schedule.dart';

class ScheduleService {
  final BackendRepository _repository = BackendRepository();

  Future<List<Schedule>> fetchSchedules(String userId) async {
    final accessToken = await AuthService().accessToken;
    return _repository.getSchedulesByUserId(userId, accessToken: accessToken);
  }
}
