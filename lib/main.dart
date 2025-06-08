import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/auth/auth_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/utils/chat_provider.dart';
import 'ui/components/messages/message_list_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 먼저 환경 변수를 로드해야 다른 서비스가 참조할 수 있음
    await dotenv.load();

    // 환경 변수 로드 후 AuthService 인스턴스 생성
    final authService = AuthService();
    await authService.init();
  } catch (e) {
    debugPrint('초기화 중 오류 발생: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<ChatProvider, MessageListViewModel>(
          create:
              (context) => MessageListViewModel(
                chatProvider: Provider.of<ChatProvider>(context, listen: false),
              ),
          update: (context, chatProvider, previous) {
            if (chatProvider == null) return previous!;
            return MessageListViewModel(chatProvider: chatProvider);
          },
        ),
      ],
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
