import 'package:flutter/material.dart';
import '../../widgets/common_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    try {
      final url = Uri.parse('https://api.puzzlelog.me/users/login');
      final headers = {'Content-Type': 'application/json'};

      final body = jsonEncode({
        'userId': userIdController.text,
        'userPwd': userPwdController.text,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] != null) {
          final prefs = await SharedPreferences.getInstance();

          String userId = result['data']['userId'];
          String? token = result['data']['token'];

          await prefs.setString('userId', userId);

          if (token != null) {
            await prefs.setString('token', token);
          }

          Navigator.pushReplacementNamed(
            context,
            userId.toLowerCase() == 'admin' ? '/adminPage' : '/home',
          );
        } else {
          setState(
            () => message = result['message'] ?? '로그인 실패: 잘못된 로그인 정보입니다.',
          );
        }
      } else if (response.statusCode == 401) {
        setState(() => message = '아이디 또는 비밀번호가 잘못되었습니다.');
      } else {
        setState(() => message = '로그인 실패: 서버 오류(${response.statusCode})');
      }
    } catch (error) {
      setState(() => message = '로그인 실패: 서버 오류 ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
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
                  child: const Text(
                    '로그인',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(message, style: const TextStyle(color: Color(0xFF5A3E2B))),
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
