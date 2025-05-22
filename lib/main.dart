import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/database_service.dart';
import 'services/local_storage_service.dart';
import 'features/auth/google_sign_in_api.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();

    // Initialize services
    final storageService = LocalStorageService();
    await storageService.init();    // Initialize auth services
    final googleSignInApi = GoogleSignInApi();
    await googleSignInApi.init();
    
    // 로그인 상태 확인
    final isLoggedIn = storageService.getBool('isLoggedIn') ?? false;
    debugPrint('자동 로그인 상태: $isLoggedIn');

    // Initialize database
    await DatabaseService().database;

    runApp(MainApp(
      initialRoute: isLoggedIn ? '/home' : '/sign-in',
    ));
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
    // 에러 발생 시 로그인 화면으로 이동
    runApp(const MainApp(initialRoute: '/sign-in'));
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
        '/sign-in': (context) => const SignInScreen(),
      },
    );
  }
}
