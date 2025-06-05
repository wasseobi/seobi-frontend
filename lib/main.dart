import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/auth/auth_service.dart';
import 'services/background/background_notification_manager.dart';
import 'services/background/background_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/utils/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 먼저 환경 변수를 로드해야 다른 서비스가 참조할 수 있음
    await dotenv.load();

    // 환경 변수 로드 후 AuthService 인스턴스 생성
    final authService = AuthService();
    await authService.init();    // 백그라운드 알림 관리자 초기화 (선택적 - 홈 화면에서도 초기화됨)
    try {
      final backgroundManager = BackgroundNotificationManager();
      await backgroundManager.initialize();
      debugPrint('백그라운드 알림 관리자 초기화 완료');
    } catch (e) {
      debugPrint('백그라운드 알림 관리자 초기화 실패: $e');
    }

    // 백그라운드 서비스 초기화
    try {
      final backgroundService = BackgroundService();
      await backgroundService.initialize();
      debugPrint('백그라운드 서비스 초기화 완료');
    } catch (e) {
      debugPrint('백그라운드 서비스 초기화 실패: $e');
    }
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
