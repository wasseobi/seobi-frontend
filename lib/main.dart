import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth/auth_service.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 환경 변수 로드
    await dotenv.load();

    // 인증 서비스 초기화
    final authService = AuthService();
    await authService.init();

    runApp(MainApp(
      initialRoute: authService.isLoggedIn ? '/home' : '/signin',
    ));
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
    // 에러 발생 시 로그인 화면으로 이동
    runApp(const MainApp(initialRoute: '/signin'));
  }
}

class MainApp extends StatelessWidget {
  final String initialRoute;
  
  const MainApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: initialRoute,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signin': (context) => const SignInScreen(),
      },
    );
  }
}
