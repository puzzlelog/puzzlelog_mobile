import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userPwdController = TextEditingController();
  String message = '';

  Future<void> handleLogin() async {
    final url = Uri.parse('http://api.puzzlelog.me/users/login');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'userId': userIdController.text,
      'userPwd': userPwdController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        setState(() => message = '로그인 성공!');

        // 토큰과 userId 로컬에 저장 로직 구현 필요
        String token = result['data']['token'];
        String userId = result['data']['userId'];
        String role = result['data']['role'] ??
            (userId.toLowerCase() == 'admin' ? 'ADMIN' : 'USER');

        if (role == 'ADMIN') {
          Navigator.pushReplacementNamed(context, '/adminPage');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() => message = result['message'] ?? '로그인 실패: 잘못된 로그인 정보입니다.');
      }
    } catch (error) {
      setState(() => message = '로그인 실패: 서버 오류');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: const Text('조각 모음집'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5A3E2B),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('로그인', style: TextStyle(color: Color(0xFF5A3E2B))),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: const Text('회원가입', style: TextStyle(color: Color(0xFFC69C6D))),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3E2B),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: userPwdController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC69C6D),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('로그인', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFF5A3E2B)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '© 2025 조각 모음집. All rights reserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5A3E2B)),
        ),
      ),
    );
  }
}