import 'package:flutter/material.dart';
import '../components/custom_navigation_bar.dart';
import '../components/message_list.dart'; // ChatMessageList import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // 예시 메시지 데이터
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
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomNavigationBar(
              selectedTabIndex: _selectedIndex,
              onTabChanged: _onTabTapped,
              onMenuPressed: () {
                // TODO: 햄버거 메뉴 처리
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  // ✅ ChatMessageList가 채팅 화면에 들어감
                  ChatMessageList(messages: _messages),
                  Center(child: Text('보관함 화면')),
                  Center(child: Text('통계 화면')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
