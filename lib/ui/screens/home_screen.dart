import 'package:flutter/material.dart';
import '../components/custom_navigation_bar.dart';
import '../components/custom_drawer.dart';
import '../components/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../../services/conversation/chat_service.dart';
import '../components/fab.dart';
import '../../repositories/backend/models/message.dart';
import 'chat_screen.dart';
import '../constants/app_colors.dart';

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
  final ChatService _chatService = ChatService();
  final GlobalKey<ChatScreenState> _chatScreenKey =
      GlobalKey<ChatScreenState>();

  bool _isChatExpanded = false;
  bool _isUserInteracting = false;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // FAB 관련 높이 설정
  final double collapsedChatHeight = 88;
  final double expandedChatHeight = 205;
  final double fabMarginBottom = 28;

  @override
  void initState() {
    super.initState();
    _initializeChatService();

    // 포커스 상태 감지
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _isUserInteracting = true);
      }
    });

    // 텍스트 입력 상태 감지
    _chatController.addListener(() {
      if (_chatController.text.isNotEmpty) {
        setState(() => _isUserInteracting = true);
      }
    });
  }

  Future<void> _initializeChatService() async {
    if (_authService.isLoggedIn) {
      await _chatService.initialize(
        onMessageReceived: _handleMessageReceived,
        onError: _showError,
      );
    }
  }

  void _handleMessageReceived(Message message) {
    if (_chatScreenKey.currentState != null) {
      _chatScreenKey.currentState!.addMessage(message);

      // 사용자 메시지 전송 후에만 채팅창 접기
      if (message.role == Message.ROLE_USER) {
        _collapseChat();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    _chatService.dispose();
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

  void _showSignInBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SignInBottomSheet(),
    );
  }

  Future<void> _toggleChat() async {
    // 로그인 상태 체크
    if (!_authService.isLoggedIn) {
      _showSignInBottomSheet();
      return;
    }

    // ChatService 초기화 확인
    if (!_chatService.isInitialized) {
      await _initializeChatService();
    }

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
    setState(() {
      _isChatExpanded = false;
      _isUserInteracting = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _handleMessageSent(Message message) {
    // ChatService를 통해 처리되므로 여기서는 UI 상태만 관리
    _handleMessageReceived(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double chatBarHeight =
        (_isChatExpanded ? expandedChatHeight : collapsedChatHeight) +
        fabMarginBottom;

    return GestureDetector(
      onTap: () {
        if (_isChatExpanded && !_isUserInteracting) _collapseChat();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.lightBG),
          child: SafeArea(
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
                            child: ChatScreen(key: _chatScreenKey),
                          ),
                          const Center(
                            child: Text(
                              'Dashboard 화면',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLightPrimary,
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              '통계 화면',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLightPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IgnorePointer(
                  ignoring: !_isChatExpanded,
                  child: GestureDetector(
                    onTap: () {
                      if (!_isUserInteracting) _collapseChat();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                ChatFloatingBar(
                  isExpanded: _isChatExpanded,
                  onToggle: _toggleChat,
                  onCollapse: _collapseChat,
                  onMessageSent: _handleMessageSent,
                  controller: _chatController,
                  focusNode: _focusNode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
