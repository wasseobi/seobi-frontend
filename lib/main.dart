import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth/auth_service.dart';
import 'features/auth/sign_in_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 환경 변수 로드
    await dotenv.load();

    // 인증 서비스 초기화
    final authService = AuthService();
    await authService.init();

    runApp(const MainApp());
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
