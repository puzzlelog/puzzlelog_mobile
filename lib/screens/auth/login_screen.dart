import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userPwdController = TextEditingController();
  String message = '';

  Future<void> handleLogin() async {
    setState(() => message = '');

    try {
      final url = Uri.parse('https://api.puzzlelog.me/users/login');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'userId': userIdController.text.trim(),
        'userPwd': userPwdController.text.trim(),
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] != null) {
          final prefs = await SharedPreferences.getInstance();

          String userId = result['data']['userId'];
          String? token = result['data']['token'];
          String role =
              result['data']['role'] ??
              (userId.toLowerCase() == 'admin' ? 'ADMIN' : 'USER');

          await prefs.setString('userId', userId);
          if (token != null) await prefs.setString('accessToken', token);
          await prefs.setString('role', role);

          Navigator.pushNamedAndRemoveUntil(
            context,
            role == 'ADMIN' ? '/adminPage' : '/',
            (route) => false,
          );
        } else {
          setState(
            () => message = result['message'] ?? '로그인 실패: 잘못된 로그인 정보입니다.',
          );
        }
      } else if (response.statusCode == 401) {
        setState(() => message = '아이디 또는 비밀번호가 잘못되었습니다.');
      } else {
        setState(() => message = '로그인 실패: 서버 오류 (${response.statusCode})');
      }
    } catch (error) {
      setState(() => message = '로그인 실패: 서버 오류 ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: 0,
      onTap: (_) {},
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e1b4b), Color(0xFF3b0764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PuzzleLog',
                    style: TextStyle(fontSize: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: userIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userPwdController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: Colors.white.withOpacity(0.3),
                    ),
                    child: const Text('로그인'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: Colors.white.withOpacity(0.3),
                    ),
                    child: const Text('회원가입'),
                  ),
                  const SizedBox(height: 12),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        color:
                            message.contains('성공') ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
