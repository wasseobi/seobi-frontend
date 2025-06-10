import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../components/navigation/custom_navigation_bar.dart';
import '../components/drawer/custom_drawer.dart';
import '../components/auth/sign_in_bottom_sheet.dart';
import '../../services/auth/auth_service.dart';
import '../components/input_bar/input_bar.dart';
import 'chat_screen.dart';
import 'box_screen.dart';
import 'article_screen.dart';
import '../../services/schedule/schedule_service.dart';
import '../components/box/schedules/schedule_card_list_view_model.dart';
import '../components/box/schedules/schedule_card_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // keepPage: true로 설정하여 페이지 상태 유지
  final PageController _pageController = PageController(keepPage: true);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      debugPrint('IME/키보드 표시됨 - 높이: $bottomInset');
    }

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
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 채팅 화면
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: ChatScreen(),
                        ),

                        // 보관함 화면 (일정 연동)
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: FutureBuilder(
                            future: _loadScheduleViewModel(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    '일정 불러오기 실패: \\${snapshot.error}',
                                  ),
                                );
                              }
                              final viewModel =
                                  snapshot.data as ScheduleCardListViewModel?;
                              return BoxScreen(scheduleViewModel: viewModel);
                            },
                          ),
                        ),

                        // 통계 화면
                        Padding(
                          padding: EdgeInsets.only(bottom: _inputBarHeight),
                          child: const ArticleScreen(),
                        ),
                      ],
                    ),
                  ),
                ],
              ), // 입력 바
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: InputBar(
                  controller: _chatController,
                  focusNode: _focusNode,
                  onHeightChanged: (height) {
                    // 입력 바의 높이가 변경될 때 상태 업데이트
                    if (mounted && height != _inputBarHeight) {
                      setState(() {
                        _inputBarHeight = height;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ScheduleCardListViewModel> _loadScheduleViewModel() async {
    final userId = _authService.userId;
    if (userId == null || userId.isEmpty) {
      // 로그인 안 된 경우 샘플 데이터 사용
      return ScheduleCardListViewModel();
    }
    final schedules = await ScheduleService().fetchSchedules(userId);
    final mapList = ScheduleCardListViewModel.fromScheduleList(schedules);
    final viewModel = ScheduleCardListViewModel.withSchedules(
      mapList.map((e) => ScheduleCardModel.fromMap(e)).toList(),
    );
    viewModel.initWithMapList(mapList);
    return viewModel;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
