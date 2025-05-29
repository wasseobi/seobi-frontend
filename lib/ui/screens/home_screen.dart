import 'package:flutter/material.dart';
import '../components/custom_navigation_bar.dart';
import '../components/custom_drawer.dart';
import '../components/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../components/fab.dart';
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

  // 예시 메시지 데이터

  bool _isChatExpanded = false;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // FAB 관련 높이 설정
  final double collapsedChatHeight = 88;
  final double expandedChatHeight = 205;
  final double fabMarginBottom = 28;

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

  void _toggleChat() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
    });

    if (_isChatExpanded) {
      Future.delayed(const Duration(milliseconds: 300), () {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _collapseChat() {
    setState(() => _isChatExpanded = false);
    FocusScope.of(context).unfocus();
  }

  void _handleSend() {
    print("보낸 메시지: ${_chatController.text}");
    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final double chatBarHeight =
        (_isChatExpanded ? expandedChatHeight : collapsedChatHeight) +
        fabMarginBottom;

    return GestureDetector(
      onTap: () {
        if (_isChatExpanded) _collapseChat(); // 외부 탭하면 닫힘
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        body: SafeArea(
          // SafeArea를 Stack 밖으로 빼서 화면 전체를 안전 영역으로 감쌈
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
                          padding: EdgeInsets.only(bottom: chatBarHeight),
                          child: ChatScreen(messages: _messages),
                        ),
                        const Center(child: Text('보관함 화면')),
                        const Center(child: Text('통계 화면')),
                      ],
                    ),
                  ),
                ],
              ),

              // 투명한 영역 클릭 시 닫힘 처리
              IgnorePointer(
                ignoring: !_isChatExpanded,
                child: GestureDetector(
                  onTap: _collapseChat,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // FAB (채팅 플로팅바)
              ChatFloatingBar(
                isExpanded: _isChatExpanded,
                onToggle: _toggleChat,
                onCollapse: _collapseChat,
                onSend: _handleSend,
                controller: _chatController,
                focusNode: _focusNode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
