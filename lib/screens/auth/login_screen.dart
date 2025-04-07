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
  bool isLoading = false;

  Future<void> handleLogin() async {
    final userId = userIdController.text.trim();
    final userPwd = userPwdController.text.trim();

    if (userId.isEmpty || userPwd.isEmpty) {
      _showSnackbar('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('https://api.puzzlelog.me/users/login');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'userId': userId, 'userPwd': userPwd});

      final response = await http.post(url, headers: headers, body: body);

      final decoded = utf8.decode(response.bodyBytes);
      final result = jsonDecode(decoded);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        final prefs = await SharedPreferences.getInstance();

        final token = data['token'] as String?;
        final role =
            data['role'] ??
            (userId.toLowerCase() == 'admin' ? 'ADMIN' : 'USER');

        await prefs.setString('userId', userId);
        if (token != null) await prefs.setString('accessToken', token);
        await prefs.setString('role', role);

        final redirectRoute = role == 'ADMIN' ? '/adminPage' : '/';
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          redirectRoute,
          (route) => false,
        );
      } else {
        final serverMsg = result['message'] ?? '로그인에 실패했습니다.';
        _showSnackbar(serverMsg);
      }
    } catch (e) {
      _showSnackbar('로그인 중 오류가 발생했습니다. ($e)');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      currentIndex: null,
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
                  _buildTextField(userIdController, '아이디'),
                  const SizedBox(height: 16),
                  _buildTextField(userPwdController, '비밀번호', obscure: true),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
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
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('로그인'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
