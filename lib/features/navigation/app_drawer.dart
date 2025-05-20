import 'package:flutter/material.dart';
import 'package:seobi_app/features/settings/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 프로필 섹션
          UserAccountsDrawerHeader(
            accountName: const Text('홍길동'),
            accountEmail: const Text('##############@gmail.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('홍'),
            ),
            decoration: BoxDecoration(color: Colors.grey[400]),
          ),

          // 환경설정 섹션
          ListTile(
            title: const Text(
              '환경설정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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
          const Divider(),

          // 연결 가능한 확장기능 섹션
          const ListTile(
            title: Text(
              '연결 가능한 컨텐츠',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildExtensionTile('카카오맵', 'KakaoMap-MCP', false),
          _buildExtensionTile('네이버지도', 'NaverMap-MCP', false),
        ],
      ),
    );
  }

  Widget _buildExtensionTile(String title, String subtitle, bool isConnected) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Text(title[0]),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isConnected,
        onChanged: (bool value) {
          // TODO: Implement connection toggle
        },
      ),
    );
  }
}
