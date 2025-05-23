import 'package:flutter/material.dart';
import 'package:seobi_app/features/auth/widgets/google_sign_in_button.dart';
import 'package:seobi_app/features/settings/settings_screen.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/models/seobi_user.dart';
import 'package:seobi_app/features/debug/debug_screen.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/theme_toggle_button.dart';
import 'widgets/logout_button.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;
  SeobiUser? _user;
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
    final user = await _authService.getUserInfo();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _user = user;
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
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('디버그'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_isLoggedIn && _user != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [LogoutButton(), ThemeToggleButton()],
                ),
              ),
              UserProfileCard(user: _user!),
            ] else
              const GoogleSignInButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
