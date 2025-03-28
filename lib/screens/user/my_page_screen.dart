import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../widgets/common_scaffold.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await Dio().get(
        'https://api.puzzlelog.me/users',
        queryParameters: {'userId': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success']) {
        setState(() => user = response.data['data']['users'][0]);
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/login');
    } finally {
      setState(() => loading = false);
    }
  }

  void handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('사용자 정보를 불러오지 못했습니다.'))
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      user!['profileImg'] ??
                          'https://via.placeholder.com/150?text=👤',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user!['nickname']} 님',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text('아이디: ${user!['userId']}'),
                  Text('이메일: ${user!['email']}'),
                  Text('생년월일: ${user!['birthDate'] ?? "정보 없음"}'),
                  Text(
                    '성별: ${user!['gender'] == 'MALE'
                        ? '남성'
                        : user!['gender'] == 'FEMALE'
                        ? '여성'
                        : "정보 없음"}',
                  ),
                  Text('알람 설정: ${user!['isAlarm'] ? "ON" : "OFF"}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {}, // 정보 수정 로직 추가
                    child: const Text('정보 수정'),
                  ),
                  TextButton(
                    onPressed: handleLogout,
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
    );
  }
}
