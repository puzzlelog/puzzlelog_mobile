import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../widgets/common_scaffold.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController userPwdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  String gender = 'MALE';
  String message = '';

  Future<void> handleSignup() async {
    if (userIdController.text.isEmpty ||
        userPwdController.text.isEmpty ||
        emailController.text.isEmpty) {
      setState(() => message = '아이디, 비밀번호, 이메일은 필수 입력값입니다.');
      return;
    }

    final uri = Uri.parse('https://api.puzzlelog.me/users');
    final request = http.MultipartRequest('POST', uri);

    final data = {
      'userId': userIdController.text,
      'userPwd': userPwdController.text,
      'email': emailController.text,
      'birthDate': birthDateController.text,
      'gender': gender,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(data),
        contentType: MediaType('application', 'json'),
      ),
    );

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final result = jsonDecode(responseData.body);

      if (response.statusCode == 200 && result['success']) {
        setState(() => message = '회원가입 성공!');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() => message = result['message'] ?? '회원가입 실패');
      }
    } catch (error) {
      setState(() => message = '회원가입 실패: 서버 오류');
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
                    '회원가입',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(userIdController, '아이디'),
                  const SizedBox(height: 12),
                  _buildTextField(userPwdController, '비밀번호', obscure: true),
                  const SizedBox(height: 12),
                  _buildTextField(emailController, '이메일'),
                  const SizedBox(height: 12),
                  _buildTextField(birthDateController, '생년월일 (YYYY-MM-DD)'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    dropdownColor: Colors.deepPurple,
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('남성')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                    ],
                    onChanged: (val) => setState(() => gender = val!),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('성별'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('회원가입'),
                  ),
                  const SizedBox(height: 20),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        color:
                            message.contains('성공')
                                ? Colors.greenAccent
                                : Colors.redAccent,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
