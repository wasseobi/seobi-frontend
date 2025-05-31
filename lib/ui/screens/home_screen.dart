import 'package:flutter/material.dart';
import '../components/custom_navigation_bar.dart';
import '../components/custom_drawer.dart';
import '../components/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../components/input_bar.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  // 입력창 관련
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // InputBar 관련 높이 설정
  final double inputBarHeight = 64;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '일정이 등록되었습니다.',
      'type': 'card',
      'card': {'title': '치과예약', 'time': '5월 12일 오후 6시', 'location': '김이안치과'},
      'actions': [
        {'icon': '📝', 'text': '노션에 저장했어요'},
        {'icon': '🔔', 'text': '알림 설정함'},
      ],
      'timestamp': '2025.05.12 05:29 전송됨',
    },
    {'isUser': true, 'text': '치과 일정 등록해줘'},
  ];
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    // 위젯이 빌드된 후에 로그인 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AuthService는 main에서 이미 초기화되었으므로 여기서는 상태만 확인합니다
      if (!_authService.isLoggedIn && mounted) {
        _showSignInBottomSheet();
      }
    });
  }

  void _showSignInBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // 사용자가 임의로 닫을 수 없도록 함
      enableDrag: false, // 드래그로 닫기 방지
      builder: (context) => const SignInBottomSheet(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleSend() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      print("보낸 메시지: $message");
      setState(() {
        _messages.insert(0, {'isUser': true, 'text': message});
      });
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomNavigationBar(
                  selectedTabIndex: _selectedIndex,
                  onTabChanged: _onTabTapped,
                  onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: inputBarHeight),
                        child: ChatScreen(messages: _messages),
                      ),
                      const Center(child: Text('보관함 화면')),
                      const Center(child: Text('통계 화면')),
                    ],
                  ),
                ),
              ],
            ),

            // 입력 바
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InputBar(
                controller: _chatController,
                focusNode: _focusNode,
                onSend: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
