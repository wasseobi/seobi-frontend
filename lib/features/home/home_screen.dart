import 'package:flutter/material.dart';
import '../navigation/app_drawer.dart';
import '../auth/sign_in_screen.dart';
import '../../services/auth/auth_service.dart';
import '../stt/stt_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    if (!_authService.isLoggedIn && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    } else {
      setState(() {
        _initialized = true;
      });
    }
  }

  void _handleMessageSend(String message) {
    // TODO: 백엔드에 메시지 전송하는 로직 구현
    print('메시지 전송: $message');
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Seobi App')),
      body: STTScreen(onMessageSend: _handleMessageSend),
    );
  }
}
