import 'package:flutter/material.dart';
import '../components/custom_navigation_bar.dart';
import '../components/custom_drawer.dart';
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
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
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
                  const ChatScreen(),
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
