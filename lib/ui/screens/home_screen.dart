import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import '../components/navigation/custom_navigation_bar.dart';
import '../components/drawer/custom_drawer.dart';
import '../components/auth/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../components/input_bar/input_bar.dart';
import '../utils/measure_size.dart';
import '../utils/chat_provider.dart';
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

  // InputBar 관련 높이를 동적으로 추적하기 위한 변수
  double _inputBarHeight = 64; // 기본값 설정

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ChatProvider에서 샘플 메시지를 로드
      context.read<ChatProvider>().loadSampleMessages();

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
    return KeyboardDismissOnTap(
      child: Scaffold(
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
                        // 채팅 화면
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const ChatScreen(),
                        ),

                        // 보관함 화면
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const Center(child: Text('보관함 화면')),
                        ),

                        // 통계 화면
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const Center(child: Text('통계 화면')),
                        ),
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
                child: MeasureSize(
                  onChange: (size) {
                    // 입력 바의 높이가 변경될 때 상태 업데이트
                    if (mounted && size.height != _inputBarHeight) {
                      setState(() {
                        _inputBarHeight = size.height;
                      });
                    }
                  },
                  child: InputBar(
                    controller: _chatController,
                    focusNode: _focusNode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
