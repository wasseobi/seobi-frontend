import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';
import '../auth/widgets/google_sign_in_button.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/theme_toggle_button.dart';
import 'widgets/logout_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
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
                  // 환경설정 섹션
                  ListTile(
                    title: const Text(
                      '환경설정',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  // 연결된 확장기능 섹션
                  const ListTile(
                    title: Text(
                      '연결된 컨텐츠',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildExtensionTile('Notion', 'Notion MCP API', true),
                  _buildExtensionTile('Google Calendar', 'Google Calendar', true),
                  _buildExtensionTile('iOS', 'Apple MCP', true),
                  _buildExtensionTile('Obsidian', 'Obsidian API', true),
                ],
              ),
            ),
            if (_isLoggedIn) ...[
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
              const UserProfileCard(),
            ] else
              const GoogleSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionTile(String title, String subtitle, bool isConnected) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isConnected ? Colors.green : Colors.grey,
      ),
    );
  }
}
