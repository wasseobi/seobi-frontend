import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/database_service.dart';
import 'features/auth/google_sign_in_api.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();

    // Initialize auth service and try auto sign in
    final authService = GoogleSignInApi();
    await authService.init();
    
    // 이미 로그인되어 있는지 확인
    final prefs = authService.prefs;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    debugPrint('자동 로그인 상태: $isLoggedIn');

    // Initialize database
    await DatabaseService().database;

    runApp(MainApp(initialRoute: '/home'));
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
    runApp(const MainApp(initialRoute: '/home'));
  }
}

class MainApp extends StatelessWidget {
  final String initialRoute;
  
  const MainApp({
    super.key,
    this.initialRoute = '/home',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/sign-in') {
          return MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          );
        }
        return null;
      },
    );
  }
}
