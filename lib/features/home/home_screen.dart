import 'package:flutter/material.dart';
import '../navigation/app_drawer.dart';
import '../auth/sign_in_screen.dart';
import '../../services/auth/auth_service.dart';
import '../chat/chat_screen.dart';
import '../task/task_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../chat/widgets/chat_input_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _initialized = false;
  final _authService = AuthService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // FAB 위치 업데이트를 위해
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Widget _buildScreen() {
    switch (_tabController.index) {
      case 0:
        return const ChatScreen();
      case 1:
        return const TaskScreen();
      case 2:
        return const DashboardScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Seobi App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: '대화'),
            Tab(icon: Icon(Icons.task), text: '작업'),
            Tab(icon: Icon(Icons.dashboard), text: '대시보드'),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(child: _buildScreen()),
              ChatInputWidget(
                onMessageSend: _handleMessageSend,
                onSwitchMode: () {},  // Unused
              ),
            ],
          ),
        ],
      ),
    );
  }
}
