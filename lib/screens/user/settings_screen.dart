import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/common_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? userId;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      accessToken = prefs.getString('accessToken');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: -1,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              '설정',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('로그아웃'),
              leading: const Icon(Icons.logout),
              onTap: _logout,
            ),
            const Divider(),
            ListTile(
              title: const Text('앱 버전'),
              leading: const Icon(Icons.info_outline),
              trailing: const Text('v1.0.0'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              title: const Text('테마 설정'),
              leading: const Icon(Icons.color_lens),
              onTap: () {
                // 추후 테마 설정 추가
              },
            ),
            const Divider(),
            if (userId != null)
              ListTile(
                title: Text('사용자 ID: $userId'),
                leading: const Icon(Icons.perm_identity),
              ),
          ],
        ),
      ),
    );
  }
}
