import 'package:flutter/material.dart';
import '../components/custom_drawer.dart';
import '../components/sign_in_bottom_sheet.dart';
import '../components/custom_navigation_bar.dart';
import '../../services/auth/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  late final TabController _tabController;
  bool _initialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final isLoggedIn = await _authService.checkLoginStatus();
      if (!mounted) return;

      if (!isLoggedIn) {
        _showSignInBottomSheet();
      }

      setState(() {
        _initialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '초기화 중 오류가 발생했습니다: $e',
            style: PretendardStyles.regular12.copyWith(
              color: AppColors.white100,
            ),
          ),
          backgroundColor: AppColors.gray100,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSignInBottomSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder:
          (context) => SignInBottomSheet(
            onSignInComplete: () {
              setState(() {
                _initialized = true;
              });
              Navigator.of(context).pop();
            },
          ),
    );
  }

  Widget _buildScreen() {
    switch (_tabController.index) {
      case 0:
        return const ChatScreen();
      case 1:
        return const Center(child: Text('보관함 화면'));
      case 2:
        return const Center(child: Text('통계 화면'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.lightBG),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.main100),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomNavigationBar(
          selectedTabIndex: _tabController.index,
          onTabChanged: (index) {
            _tabController.animateTo(index);
          },
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.lightBG),
        child: TabBarView(
          controller: _tabController,
          children: [
            const ChatScreen(),
            Center(
              child: Text(
                '보관함 화면',
                style: PretendardStyles.regular12.copyWith(
                  color: AppColors.textLightSecondary,
                ),
              ),
            ),
            Center(
              child: Text(
                '통계 화면',
                style: PretendardStyles.regular12.copyWith(
                  color: AppColors.textLightSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
