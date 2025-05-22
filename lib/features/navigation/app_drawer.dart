import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';
import '../auth/widgets/google_sign_in_button.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/theme_toggle_button.dart';
import 'widgets/logout_button.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/models/auth_result.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;
  UserInfo? _userInfo;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    final isLoggedIn = _authService.isLoggedIn;
    final userInfo = await _authService.getUserInfo();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userInfo = userInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('설정'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_isLoggedIn && _userInfo != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LogoutButton(),
                    ThemeToggleButton(),
                  ],
                ),
              ),
              UserProfileCard(userInfo: _userInfo!),
            ] else
              const GoogleSignInButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
