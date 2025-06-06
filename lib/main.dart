import 'package:flutter/material.dart';
import 'services/service_manager.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // ServiceManager를 사용하여 모든 서비스 초기화
    debugPrint('[Main] 🚀 앱 초기화 시작');
    await ServiceManager.initialize();
    debugPrint('[Main] ✅ 모든 서비스 초기화 완료');
    
  } catch (e) {
    debugPrint('[Main] ❌ 서비스 초기화 중 오류 발생: $e');
    
    // 네트워크 관련 오류인지 확인
    if (e.toString().contains('Connection') || 
        e.toString().contains('ClientException') ||
        e.toString().contains('SocketException')) {
      debugPrint('[Main] 🌐 네트워크 연결 오류 - 오프라인 모드로 실행');
    }
    
    // 초기화 실패 시에도 앱은 실행되도록 함 (기본 기능은 사용 가능)
    debugPrint('[Main] 📱 기본 기능으로 앱 실행 계속');
  }

  runApp(const MainApp());
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
