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
    final bool isLoggedIn = accessToken != null && accessToken!.isNotEmpty;

    return CommonScaffold(
      currentIndex: isLoggedIn ? -1 : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              '앱 정보',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('앱 이름'),
              leading: const Icon(Icons.apps),
              trailing: const Text('PuzzleLog'),
            ),
            const Divider(),
            ListTile(
              title: const Text('앱 버전'),
              leading: const Icon(Icons.info_outline),
              trailing: const Text('v1.0.0'),
            ),
            const Divider(),
            if (userId != null)
              ListTile(
                title: Text('사용자 ID: $userId'),
                leading: const Icon(Icons.perm_identity),
              ),
            const SizedBox(height: 32),
            const Text(
              '프로젝트 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '본 앱은 비트교육센터에서 진행한 최종 프로젝트입니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '팀원 소개',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMemberRow('👑 정원담 (팀장)', Colors.deepPurple),
            _buildMemberRow('✨ 강지현 (부팀장)', Colors.indigo),
            _buildMemberRow('🧩 신소현'),
            _buildMemberRow('🧩 김진우'),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, [Color? highlightColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight:
              highlightColor != null ? FontWeight.bold : FontWeight.normal,
          color: highlightColor ?? Colors.black87,
        ),
      ),
    );
  }
}
